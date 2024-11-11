#!/bin/sh

# 檢查傳入參數
[ -z "$username" ] && write_log 14 "Configuration error! The 'username' that holds the Alibaba Cloud API access account cannot be empty"
[ -z "$password" ] && write_log 14 "Configuration error! The 'password' that holds the Alibaba Cloud API access account cannot be empty"

# 檢查外部調用工具
[ -n "$CURL_SSL" ] || write_log 13 "Alibaba Cloud API communication require cURL with SSL support. Please install"
[ -n "$CURL_PROXY" ] || write_log 13 "cURL: libcurl compiled without Proxy support"
command -v sed >/dev/null 2>&1 || write_log 13 "Sed support is required to use Alibaba Cloud API, please install first"
command -v openssl >/dev/null 2>&1 || write_log 13 "Openssl-util support is required to use Alibaba Cloud API, please install first"

# 變量聲明
local __TMP __I __HOST __DOMAIN __TYPE __CMDBASE __RECID __TTL

# 設定紀錄類型
[ $use_ipv6 = 0 ] && __TYPE=A || __TYPE=AAAA

# 構造基本通訊命令
build_command(){
	__CMDBASE="$CURL -Ssm 5"
	# 綁定用於通訊的主機/IP
	if [ -n "$bind_network" ];then
		local __DEVICE
		network_get_device __DEVICE $bind_network || write_log 13 "Can not detect local device using 'network_get_device $bind_network' - Error: '$?'"
		write_log 7 "Force communication via device '$__DEVICE'"
		__CMDBASE="$__CMDBASE --interface $__DEVICE"
	fi
	# 強制設定IP版本
	if [ $force_ipversion = 1 ];then
		[ $use_ipv6 = 0 ] && __CMDBASE="$__CMDBASE -4" || __CMDBASE="$__CMDBASE -6"
	fi
	# 設定CA憑證參數
	if [ $use_https = 1 ];then
		if [ "$cacert" = IGNORE ];then
			__CMDBASE="$__CMDBASE --insecure"
		elif [ -f "$cacert" ];then
			__CMDBASE="$__CMDBASE --cacert $cacert"
		elif [ -d "$cacert" ];then
			__CMDBASE="$__CMDBASE --capath $cacert"
		elif [ -n "$cacert" ];then
			write_log 14 "No valid certificate(s) found at '$cacert' for HTTPS communication"
		fi
	fi
	# 如果沒有設定，禁用代理 (這可能是 .wgetrc 或環境設定錯誤)
	[ -z "$proxy" ] && __CMDBASE="$__CMDBASE --noproxy '*'"
}

# 百分號編碼
percentEncode(){
	if [ -z "${1//[A-Za-z0-9_.~-]/}" ];then
		echo -n "$1"
	else
		local string=$1;local i=0;local ret chr
		while [ $i -lt ${#string} ];do
			chr=${string:$i:1}
			[ -z "${chr#[^A-Za-z0-9_.~-]}" ] && chr=$(printf '%%%02X' "'$chr")
			ret="$ret$chr"
			i=$(( $i + 1 ))
		done
		echo -n "$ret"
	fi
}

# 處理JSON
JSON(){
	echo $(jsonfilter -s "$__TMP" -e "$1")
}

# 阿里雲API的通訊函數
aliyun_transfer(){
	__CNT=0;__URLARGS=
	[ $# = 0 ] && write_log 12 "'aliyun_transfer()' Error - wrong number of parameters"
	# 添加請求參數
	for string in $*;do
		case "${string%%=*}" in
			Format|Version|AccessKeyId|SignatureMethod|Timestamp|SignatureVersion|SignatureNonce|Signature);; # 過濾公共參數
			*)__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}");;
		esac
	done
	__URLARGS="${__URLARGS:1}"
	# 附加公共參數
	string="Format=JSON";__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="Version=2015-01-09";__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="AccessKeyId=$username";__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="SignatureMethod=HMAC-SHA1";__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="Timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ');__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="SignatureVersion=1.0";__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="SignatureNonce="$(cat '/proc/sys/kernel/random/uuid');__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="Line=default";__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	# 對請求參數進行排序，用於生成簽名
	string=$(echo -n "$__URLARGS" | sed 's/\'"&"'/\n/g' | sort | sed ':label; N; s/\n/\'"&"'/g; b label')
	# 構造用於計算簽名的字符串
	string="GET&"$(percentEncode "/")"&"$(percentEncode "$string")
	# 字符串計算簽名值
	local signature=$(echo -n "$string" | openssl dgst -sha1 -hmac "$password&" -binary | openssl base64)
	# 附加簽名參數
	string="Signature=$signature";__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	__A="$__CMDBASE 'https://alidns.aliyuncs.com/?$__URLARGS'"
	# write_log 7 "#> $__A"
	while ! __TMP=`eval $__A 2>&1`;do
		write_log 3 "[$__TMP]"
		if [ $VERBOSE -gt 1 ];then
			write_log 4 "Transfer failed - detailed mode: $VERBOSE - Do not try again after an error"
			return 1
		fi
		__CNT=$(( $__CNT + 1 ))
		[ $retry_max_count -gt 0 -a $__CNT -gt $retry_max_count ] && write_log 14 "Transfer failed after $retry_max_count retries"
		write_log 4 "Transfer failed - $__CNT Try again in $RETRY_SECONDS seconds"
		sleep $RETRY_SECONDS &
		PID_SLEEP=$!
		wait $PID_SLEEP
		PID_SLEEP=0
	done
	__ERR=`JSON @.Code`
	[ $__ERR ] || return 0
	case $__ERR in
		LastOperationNotFinished)printf "%s\n" " $(date +%H%M%S)       : 最後一次操作未完成,2秒後重試" >> $LOGFILE;return 1;;
		InvalidTimeStamp.Expired)printf "%s\n" " $(date +%H%M%S)       : 時戳錯誤,2秒後重試" >> $LOGFILE;return 1;;
		InvalidAccessKeyId.NotFound)__ERR="無效AccessKey ID";;
		SignatureDoesNotMatch)__ERR="無效AccessKey Secret";;
		InvalidDomainName.NoExist)__ERR="無效域名";;
		Forbidden.RAM)__ERR="RAM權限不足";;
	esac
	local A="$(date +%H%M%S) ERROR : [$__ERR] - 終止進程"
	logger -p user.err -t ddns-scripts[$$] $SECTION_ID: ${A:15}
	printf "%s\n" " $A" >> $LOGFILE
	exit 1
}

# 添加解析紀錄
add_domain(){
	while ! aliyun_transfer "Action=AddDomainRecord" "DomainName=$__DOMAIN" "RR=$__HOST" "Type=$__TYPE" "Value=$__IP";do sleep 2;done
	printf "%s\n" " $(date +%H%M%S)       : 添加解析紀錄成功: [$([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN],[IP:$__IP]" >> $LOGFILE
}

# 啟用解析紀錄
enable_domain(){
	while ! aliyun_transfer "Action=SetDomainRecordStatus" "RecordId=$__RECID" "Status=Enable";do sleep 2;done
	printf "%s\n" " $(date +%H%M%S)       : 啟用解析紀錄成功" >> $LOGFILE
}

# 修改解析紀錄
update_domain(){
	while ! aliyun_transfer "Action=UpdateDomainRecord" "RecordId=$__RECID" "RR=$__HOST" "Type=$__TYPE" "Value=$__IP" "TTL=$__TTL";do sleep 2;done
	printf "%s\n" " $(date +%H%M%S)       : 修改解析紀錄成功: [$([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN],[IP:$__IP],[TTL:$__TTL]" >> $LOGFILE
}

# 獲取域名解析紀錄
describe_domain(){
	while ! aliyun_transfer "Action=DescribeDomains" "PageSize=100";do sleep 2;done
	for __I in $(JSON @.Domains.Domain[@].PunyCode);do
		if echo $domain | grep -wq $__I;then __DOMAIN=$__I;break;fi
	done
	if [ ! $__DOMAIN ];then
		local A="$(date +%H%M%S) ERROR : [無效域名] - 終止進程"
		logger -p user.err -t ddns-scripts[$$] $SECTION_ID: ${A:15}
		printf "%s\n" " $A" >> $LOGFILE
		exit 1
	fi
	__HOST=$(echo $domain | sed -e "s/$__DOMAIN//" -e 's/\.$//')
	[ $__HOST ] || __HOST=@
	ret=0
	while ! aliyun_transfer "Action=DescribeSubDomainRecords" "SubDomain=$__HOST.$__DOMAIN" "Type=$__TYPE";do sleep 2;done
	__TMP=`JSON @.DomainRecords.Record[@]`
	if [ -z "$__TMP" ];then
		printf "%s\n" " $(date +%H%M%S)       : 解析紀錄不存在: [$([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN]" >> $LOGFILE
		ret=1
	else
		__STATUS=`JSON @.Status`
		__RECIP=`JSON @.Value`
		if [ "$__STATUS" != ENABLE ];then
			printf "%s\n" " $(date +%H%M%S)       : 解析紀錄被禁用" >> $LOGFILE
			ret=$(( $ret | 2 ))
		fi
		if [ "$__RECIP" != "$__IP" ];then
			__TTL=`JSON @.TTL`
			printf "%s\n" " $(date +%H%M%S)       : 解析紀錄需要更新: [解析紀錄IP:$__RECIP] [本地IP:$__IP]" >> $LOGFILE
			ret=$(( $ret | 4 ))
		fi
	fi
}

build_command
describe_domain
if [ $ret = 0 ];then
	printf "%s\n" " $(date +%H%M%S)       : 解析紀錄不需要更新: [解析紀錄IP:$__RECIP] [本地IP:$__IP]" >> $LOGFILE
elif [ $ret = 1 ];then
	sleep 3
	add_domain
else
	__RECID=`JSON @.RecordId`
	[ $(( $ret & 2 )) -ne 0 ] && sleep 3 && enable_domain
	[ $(( $ret & 4 )) -ne 0 ] && sleep 3 && update_domain
fi

return 0
