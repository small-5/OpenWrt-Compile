#!/bin/sh

# 檢查傳入參數
[ -z "$username" ] && write_log 14 "Configuration error! [User name] cannot be empty"
[ -z "$password" ] && write_log 14 "Configuration error! [Password] cannot be empty"

# 檢查外部調用工具
[ -n "$CURL_SSL" ] || write_log 13 "Huawei communication require cURL with SSL support. Please install"
[ -n "$CURL_PROXY" ] || write_log 13 "cURL: libcurl compiled without Proxy support"
command -v openssl >/dev/null 2>&1 || write_log 13 "Openssl-util support is required to use Huawei API, please install first"

# 變量聲明
local __TMP __I __N __APIHOST __HOST __DOMAIN __TYPE __CMDBASE __POST __POST1 __RECIP __RECID __TTL __CNT __A
__APIHOST=dns.myhuaweicloud.com

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

# 生成URL
URL(){
	local A B C D E
	A=$(date -u '+%Y%m%dT%H%M%SZ')
	B="$1\n$2/\n$3\ncontent-type:application/json\nhost:$__APIHOST\nx-sdk-date:$A\n\ncontent-type;host;x-sdk-date\n$(echo -n $4 | sha256sum | awk '{print $1}')"
	C="SDK-HMAC-SHA256\n$A\n$(echo -en $B | sha256sum | awk '{print $1}')"
	D="SDK-HMAC-SHA256 Access=$username, SignedHeaders=content-type;host;x-sdk-date, Signature=$(echo -en $C | openssl dgst -sha256 -mac HMAC -macopt key:$password | awk '{print $2}')"
	E="-H 'Authorization: $D' -H 'X-Sdk-Date: $A' -H 'content-type: application/json' $([ -n "$4" ] && echo -d \'$4\') $([ $1 = PUT ] && echo -X PUT)"
	__A="$__CMDBASE $E 'https://$__APIHOST$2$([ -n "$3" ] && echo ?$3)'"
}

# 處理JSON
JSON(){
	echo "$(jsonfilter -s "$__TMP" -e "$1")"
}

# Huawei API的通訊函數
huawei_transfer(){
	__CNT=0
	case $1 in
		0)URL GET /v2/zones "" "";;
		1)URL GET /v2/recordsets "name=$domain&search_mode=equal&type=$__TYPE" "";;
		2)URL POST /v2/zones/$__ZONE_ID/recordsets "" "$__POST}";;
		3)URL PUT /v2/zones/$__ZONE_ID/recordsets/$__RECID "" "$__POST1";;
	esac

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
	__ERR=`JSON @.error_code`
	[ $__ERR ] || return 0
	case $__ERR in
		APIGW.0301)printf "%s\n" " $(date +%H%M%S)       : AK/SK錯誤,簽名驗證失敗或時戳錯誤,2秒後重試" >> $LOGFILE && return 1;;
		*)__TMP=`JSON @.error_msg`;;
	esac
	local A="$(date +%H%M%S) ERROR : [$__TMP] - 終止進程"
	logger -p user.err -t ddns-scripts[$$] $SECTION_ID: ${A:15}
	printf "%s\n" " $A" >> $LOGFILE
	exit 1
}

# 添加解析紀錄
add_domain(){
	while ! huawei_transfer 2;do sleep 2;done
	printf "%s\n" " $(date +%H%M%S)       : 添加解析紀錄成功: [$domain],[IP:$__IP]" >> $LOGFILE
	return 0
}

# 修改解析紀錄
update_domain(){
	while ! huawei_transfer 3;do sleep 2;done
	printf "%s\n" " $(date +%H%M%S)       : 修改解析紀錄成功: [$domain],[IP:$__IP],[TTL:$__TTL]" >> $LOGFILE
	return 0
}

# 獲取域名解析紀錄
describe_domain(){
	while ! huawei_transfer 0;do sleep 2;done
	__N=0
	for __I in $(JSON @.zones[@].name | sed 's/\.$//');do
		if echo $domain | grep -wq $__I;then __DOMAIN=$__I;__ZONE_ID=$(JSON @.zones[$__N].id);break;fi
		let __N++
	done
	if [ ! $__DOMAIN ];then
		local A="$(date +%H%M%S) ERROR : [無效域名] - 終止進程"
		logger -p user.err -t ddns-scripts[$$] $SECTION_ID: ${A:15}
		printf "%s\n" " $A" >> $LOGFILE
		exit 1
	fi
	ret=0
	__POST="{\"name\":\"$domain\",\"type\":\"$__TYPE\",\"records\":[\"$__IP\"]"
	while ! huawei_transfer 1;do sleep 2;done
	if [ $(JSON @.metadata.total_count) = 0 ];then
		printf "%s\n" " $(date +%H%M%S)       : 解析紀錄不存在: [$domain]" >> $LOGFILE
		ret=1
	else
		__RECIP=`JSON @.recordsets[@].records[@]`
		if [ "$__RECIP" != "$__IP" ];then
			__RECID=`JSON @.recordsets[@].id`
			__TTL=`JSON @.recordsets[@].ttl`
			__POST1="$__POST,\"ttl\":\"$__TTL\"}"
			printf "%s\n" " $(date +%H%M%S)       : 解析紀錄需要更新: [解析紀錄IP:$__RECIP] [本地IP:$__IP]" >> $LOGFILE
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
	printf "%s\n" " $(date +%H%M%S)       : 解析紀錄不需要更新: [解析紀錄IP:$__RECIP] [本地IP:$__IP]" >> $LOGFILE
fi

return 0
