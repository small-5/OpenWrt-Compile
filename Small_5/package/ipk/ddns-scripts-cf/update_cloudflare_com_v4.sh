#!/bin/sh

# 檢查傳入參數
[ -z "$username" ] && write_log 14 "Configuration error! [User name] cannot be empty"
[ -z "$password" ] && write_log 14 "Configuration error! [Password] cannot be empty"

# 檢查外部調用工具
[ -n "$CURL_SSL" ] || write_log 13 "Cloudflare communication require cURL with SSL support. Please install"
[ -n "$CURL_PROXY" ] || write_log 13 "cURL: libcurl compiled without Proxy support"

# 變量聲明
local __TMP __I __DOMAIN __TYPE __CMDBASE __ZONEID __POST __POST2 __RECIP __RECID __TTL __CNT __A

# 設定紀錄類型
[ $use_ipv6 = 0 ] && __TYPE=A || __TYPE=AAAA

# 構造基本通訊命令
build_command(){
	__CMDBASE="$CURL -Ssm 5"
	# 繫結用於通訊的主機/IP
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
	local A="$2 -H 'Content-Type: application/json'"
	if [ "$username" = Bearer ];then
		A="$A -H 'Authorization: Bearer $password'"
	else
		A="$A -H 'X-Auth-Email: $username' -H 'X-Auth-Key: $password'"
	fi
	__A="$__CMDBASE $A 'https://api.cloudflare.com/client/v4/zones$1'"
}

# 處理JSON
JSON(){
	echo $(jsonfilter -s "$__TMP" -e "$1")
}

# Cloudflare API的通訊函數
cloudflare_transfer(){
	__CNT=0
	case $1 in
		0)URL "?&per_page=50";;
		1)URL "?name=$__DOMAIN";;
		2)URL "$__POST?name=$domain&type=$__TYPE";;
		3)URL "$__POST" "$__POST2:60}'";;
		4)URL "$__POST/$__RECID" "-X PUT $__POST2:$__TTL,\"comment\":\"$__COMMENT\"}'";;
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
	__ERR=`JSON @.success`
	[ $__ERR = true ] && return 0
	local A="$(date +%H%M%S) ERROR : [$(JSON @.errors[*].message)] - 終止進程"
	logger -p user.err -t ddns-scripts[$$] $SECTION_ID: ${A:15}
	printf "%s\n" " $A" >> $LOGFILE
	exit 1
}

# 添加解析紀錄
add_domain(){
	while ! cloudflare_transfer 3;do sleep 2;done
	printf "%s\n" " $(date +%H%M%S)       : 添加解析紀錄成功: [$domain],[IP:$__IP]" >> $LOGFILE
	return 0
}

# 修改解析紀錄
update_domain(){
	while ! cloudflare_transfer 4;do sleep 2;done
	printf "%s\n" " $(date +%H%M%S)       : 修改解析紀錄成功: [$domain],[IP:$__IP],[TTL:$__TTL]" >> $LOGFILE
	return 0
}

# 獲取域名解析紀錄
describe_domain(){
	while ! cloudflare_transfer 0;do sleep 2;done
	for __I in $(JSON @.result[@].name);do
		if echo $domain | grep -wq $__I;then __DOMAIN=$__I;break;fi
	done
	if [ ! $__DOMAIN ];then
		local A="$(date +%H%M%S) ERROR : [無效域名] - 終止進程"
		logger -p user.err -t ddns-scripts[$$] $SECTION_ID: ${A:15}
		printf "%s\n" " $A" >> $LOGFILE
		exit 1
	fi
	while ! cloudflare_transfer 1;do sleep 2;done
	__ZONEID=$(JSON @.result[@].id)
	domain=$(echo $domain | sed 's/@/./')
	ret=0
	__POST="/$__ZONEID/dns_records"
	__POST2="-d '{\"type\":\"$__TYPE\",\"name\":\"$domain\",\"content\":\"$__IP\",\"ttl\""
	while ! cloudflare_transfer 2;do sleep 2;done
	__TMP=`JSON @.result[@]`
	__RECIP=`JSON @.content 2>/dev/null`
	if [ -z "$__RECIP" ];then
		printf "%s\n" " $(date +%H%M%S)       : 解析紀錄不存在: [$domain]" >> $LOGFILE
		ret=1
	else
		if [ "$__RECIP" != "$__IP" ];then
			__RECID=`JSON @.id`
			__TTL=`JSON @.ttl`
			__COMMENT=`JSON @.comment`
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
