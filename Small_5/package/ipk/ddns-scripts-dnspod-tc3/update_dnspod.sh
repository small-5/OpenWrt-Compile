#!/bin/sh

# 檢查傳入參數
[ -z "$username" ] && write_log 14 "Configuration error! [User name] cannot be empty"
[ -z "$password" ] && write_log 14 "Configuration error! [Password] cannot be empty"

# 檢查外部調用工具
[ -n "$CURL_SSL" ] || write_log 13 "Dnspod communication require cURL with SSL support. Please install"
[ -n "$CURL_PROXY" ] || write_log 13 "cURL: libcurl compiled without Proxy support"
command -v openssl >/dev/null 2>&1 || write_log 13 "Openssl-util support is required to use Dnspod API, please install first"

# 變量聲明
local __TMP __I __APIHOST __HOST __DOMAIN __TYPE __CMDBASE __POST __POST1 __POST2 __POST3 __RECIP __RECID __TTL __CNT __A
__APIHOST=dnspod.tencentcloudapi.com

# 設定記錄類型
[ $use_ipv6 = 0 ] && __TYPE=A || __TYPE=AAAA

# 構造基本通訊命令
build_command(){
	__CMDBASE="$CURL -Ss"
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
	# 設定CA證書參數
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
	__CMDBASE="$__CMDBASE -d"
}

# 生成簽名
HMAC(){
	echo -en $1 | openssl dgst -sha256 -mac HMAC -macopt hexkey:$2 | awk '{print $2}'
}

# 生成URL
URL(){
	local A B C D E F G
	A=$(date -u +%Y-%m-%d)
	B=$(date +%s)
	C="POST\n/\n\ncontent-type:application/json\nhost:$__APIHOST\n\ncontent-type;host\n$(echo -n $1 | sha256sum | awk '{print $1}')"
	D="TC3-HMAC-SHA256\n$B\n$A/dnspod/tc3_request\n$(echo -en $C | sha256sum | awk '{print $1}')"
	E=$(HMAC tc3_request $(HMAC dnspod $(echo -n $A | openssl dgst -sha256 -hmac TC3$password | awk '{print $2}')))
	F="TC3-HMAC-SHA256 Credential=$username/$A/dnspod/tc3_request,SignedHeaders=content-type;host,Signature=$(HMAC $D $E)"
	G="-H 'Authorization: $F' -H 'X-TC-Timestamp: $B' -H 'Content-Type: application/json' -H 'X-TC-Version: 2021-03-23' -H 'X-TC-Language: zh-CN'"
	__A="$__CMDBASE '$1' $G -H 'X-TC-Action: $2' https://$__APIHOST"
}

# 處理JSON
JSON(){
	echo $(ddnsjson -k "$__TMP" -x "$1")
}

# Dnspod API的通訊函数
dnspod_transfer(){
	__CNT=0
	case $1 in
		0)URL "{}" DescribeDomainList;;
		1)URL $__POST1 DescribeRecordList;;
		2)URL $__POST2 CreateRecord;;
		3)__POST3="${__POST2%\}*},\"RecordId\":$__RECID,\"TTL\":$__TTL}";URL $__POST3 ModifyRecord;;
	esac

	# write_log 7 "#> $(echo -e "$__A" | sed "s/默认/Default/g")"
	while ! __TMP=`eval $__A 2>&1`;do
		write_log 3 "[$__TMP]"
		if [ $VERBOSE -gt 1 ];then
			write_log 4 "Transfer failed - detailed mode: $VERBOSE - Do not try again after an error"
			return 1
		fi
		__CNT=$(( $__CNT + 1 ))
		[ $retry_count -gt 0 -a $__CNT -gt $retry_count ] && write_log 14 "Transfer failed after $retry_count retries"
		write_log 4 "Transfer failed - $__CNT Try again in $RETRY_SECONDS seconds"
		sleep $RETRY_SECONDS &
		PID_SLEEP=$!
		wait $PID_SLEEP
		PID_SLEEP=0
	done
	__ERR=`JSON @.Response.Error.Code`
	[ $__ERR ] || return 0
	case $__ERR in
		ResourceNotFound.NoDataOfRecord)return 0;;
		AuthFailure.SignatureExpire)printf "%s\n" " $(date +%H%M%S)       : 時戳錯誤,2秒後重試" >> $LOGFILE && return 1;;
		AuthFailure.SignatureFailure)__TMP="SecretKey錯誤,簽名驗證失敗";;
		*)__TMP=`JSON @.Response.Error.Message`;;
	esac
	local A="$(date +%H%M%S) ERROR : [$__TMP] - 終止進程"
	logger -p user.err -t ddns-scripts[$$] $SECTION_ID: ${A:15}
	printf "%s\n" " $A" >> $LOGFILE
	exit 1
}

# 添加解析記錄
add_domain(){
	while ! dnspod_transfer 2;do sleep 2;done
	printf "%s\n" " $(date +%H%M%S)       : 添加解析記錄成功: [$([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN],[IP:$__IP]" >> $LOGFILE
	return 0
}

# 修改解析記錄
update_domain(){
	while ! dnspod_transfer 3;do sleep 2;done
	printf "%s\n" " $(date +%H%M%S)       : 修改解析記錄成功: [$([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN],[IP:$__IP],[TTL:$__TTL]" >> $LOGFILE
	return 0
}

# 獲取域名解析記錄
describe_domain(){
	while ! dnspod_transfer 0;do sleep 2;done
	for __I in $(JSON @.Response.DomainList[@].Punycode);do
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
	__POST="{\"Domain\":\"$__DOMAIN\""
	__POST1="$__POST,\"Subdomain\":\"$__HOST\"}"
	__POST2="$__POST,\"SubDomain\":\"$__HOST\",\"Value\":\"$__IP\",\"RecordType\":\"$__TYPE\",\"RecordLine\":\"默认\"}"
	while ! dnspod_transfer 1;do sleep 2;done
	__TMP=`JSON "@.Response.RecordList[@.Type='$__TYPE' && @.Line='默认']"`
	if [ -z "$__TMP" ];then
		printf "%s\n" " $(date +%H%M%S)       : 解析記錄不存在: [$([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN]" >> $LOGFILE
		ret=1
	else
		__RECIP=`JSON @.Value`
		if [ "$__RECIP" != "$__IP" ];then
			__RECID=`JSON @.RecordId`
			__TTL=`JSON @.TTL`
			printf "%s\n" " $(date +%H%M%S)       : 解析記錄需要更新: [解析記錄IP:$__RECIP] [本地IP:$__IP]" >> $LOGFILE
			ret=2
		fi
	fi
}

build_command
describe_domain
if [ $ret = 1 ];then
	sleep 3
	add_domain
elif [ $ret = 2 ];then
	sleep 3
	update_domain
else
	printf "%s\n" " $(date +%H%M%S)       : 解析記錄不需要更新: [解析記錄IP:$__RECIP] [本地IP:$__IP]" >> $LOGFILE
fi

return 0
