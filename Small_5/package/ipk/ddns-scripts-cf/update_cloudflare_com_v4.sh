#!/bin/sh

# 检查传入参数
[ -z "$username" ] && write_log 14 "Configuration error! [User name] cannot be empty"
[ -z "$password" ] && write_log 14 "Configuration error! [Password] cannot be empty"

# 检查外部调用工具
[ -n "$CURL_SSL" ] || write_log 13 "Cloudflare communication require cURL with SSL support. Please install"
[ -n "$CURL_PROXY" ] || write_log 13 "cURL: libcurl compiled without Proxy support"

# 变量声明
local __TMP __I __DOMAIN __TYPE __CMDBASE __ZONEID __POST __POST2 __RECIP __RECID __TTL __CNT __A

# 设置记录类型
[ $use_ipv6 = 0 ] && __TYPE=A || __TYPE=AAAA

# 构造基本通信命令
build_command(){
	__CMDBASE="$CURL -Ss"
	# 绑定用于通信的主机/IP
	if [ -n "$bind_network" ];then
		local __DEVICE
		network_get_device __DEVICE $bind_network || write_log 13 "Can not detect local device using 'network_get_device $bind_network' - Error: '$?'"
		write_log 7 "Force communication via device '$__DEVICE'"
		__CMDBASE="$__CMDBASE --interface $__DEVICE"
	fi
	# 强制设定IP版本
	if [ $force_ipversion = 1 ];then
		[ $use_ipv6 = 0 ] && __CMDBASE="$__CMDBASE -4" || __CMDBASE="$__CMDBASE -6"
	fi
	# 设置CA证书参数
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
	# 如果没有设置，禁用代理 (这可能是 .wgetrc 或环境设置错误)
	[ -z "$proxy" ] && __CMDBASE="$__CMDBASE --noproxy '*'"
}

# 生成链接
URL(){
	local A="$2 -H 'Content-Type: application/json'"
	if [ "$username" = Bearer ];then
		A="$A -H 'Authorization: Bearer $password'"
	else
		A="$A -H 'X-Auth-Email: $username' -H 'X-Auth-Key: $password'"
	fi
	__A="$__CMDBASE $A 'https://api.cloudflare.com/client/v4/zones$1'"
}

# 处理JSON
JSON(){
	echo $(ddnsjson -k "$__TMP" -x "$1")
}

# 用于Cloudflare API的通信函数
cloudflare_transfer(){
	__CNT=0
	case $1 in
		0)URL "?&per_page=50";;
		1)URL "?name=$__DOMAIN";;
		2)URL "$__POST?name=$domain&type=$__TYPE";;
		3)URL "$__POST" "$__POST2:60}'";;
		4)URL "$__POST/$__RECID" "-X PUT $__POST2:$__TTL}'";;
	esac

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
	__ERR=`JSON @.success`
	[ $__ERR = true ] && return 0
	local A="$(date +%H%M%S) ERROR : [$(JSON @.errors[*].message)] - 终止进程"
	logger -p user.err -t ddns-scripts[$$] $SECTION_ID: ${A:15}
	printf "%s\n" " $A" >> $LOGFILE
	exit 1
}

# 添加解析记录
add_domain(){
	while ! cloudflare_transfer 3;do sleep 2;done
	printf "%s\n" " $(date +%H%M%S)       : 添加解析记录成功: [$domain],[IP:$__IP]" >> $LOGFILE
	return 0
}

# 修改解析记录
update_domain(){
	while ! cloudflare_transfer 4;do sleep 2;done
	printf "%s\n" " $(date +%H%M%S)       : 修改解析记录成功: [$domain],[IP:$__IP],[TTL:$__TTL]" >> $LOGFILE
	return 0
}

# 获取域名解析记录
describe_domain(){
	while ! cloudflare_transfer 0;do sleep 2;done
	for __I in $(JSON @.result[@].name);do
		if echo $domain | grep -wq $__I;then __DOMAIN=$__I;break;fi
	done
	if [ ! $__DOMAIN ];then
		local A="$(date +%H%M%S) ERROR : [无效域名] - 终止进程"
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
		printf "%s\n" " $(date +%H%M%S)       : 解析记录不存在: [$domain]" >> $LOGFILE
		ret=1
	else
		if [ "$__RECIP" != "$__IP" ];then
			__RECID=`JSON @.id`
			__TTL=`JSON @.ttl`
			printf "%s\n" " $(date +%H%M%S)       : 解析记录需要更新: [解析记录IP:$__RECIP] [本地IP:$__IP]" >> $LOGFILE
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
	printf "%s\n" " $(date +%H%M%S)       : 解析记录不需要更新: [解析记录IP:$__RECIP] [本地IP:$__IP]" >> $LOGFILE
fi

return 0
