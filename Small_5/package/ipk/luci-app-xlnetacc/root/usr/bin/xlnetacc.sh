#!/bin/sh

# 聲明常量
readonly packageName='com.xunlei.vip.swjsq'
readonly protocolVersion=300
readonly businessType=68
readonly sdkVersion='3.1.2.185150'
readonly clientVersion='2.7.2.0'
readonly agent_xl="android-ok-http-client/xl-acc-sdk/version-$sdkVersion"
readonly agent_down='okhttp/3.9.1'
readonly agent_up='android-async-http/xl-acc-sdk/version-1.0.0.1'
readonly client_type_down='android-swjsq'
readonly client_type_up='android-uplink'

# 聲明全局變量
_bind_ip=
_http_cmd=
_peerid=
_devicesign=
_userid=
_loginkey=
_sessionid=
_portal_down=
_portal_up=
_dial_account=
access_url=
http_args=
user_agent=
link_cn=
lasterr=
sequence_xl=1000000
sequence_down=$(( $(date +%s) / 6 ))
sequence_up=$sequence_down

# 包含用於解析 JSON 格式返回值的函數
. /usr/share/libubox/jshn.sh

# 讀取 UCI 設定相關函數
uci_get_by_name(){
	local ret=$(uci -q get $NAME.$1.$2)
	echo -n ${ret:=$3}
}

uci_get_by_bool(){
	case $(uci_get_by_name "$1" "$2" "$3") in
		1|on|true|yes|enabled)echo -n 1;;
		*)echo -n 0;;
	esac
}

# 日志和狀態欄輸出。1 日志文件, 2 系統日志, 4 詳細模式, 8 下行狀態欄, 16 上行狀態欄, 32 失敗狀態
_log(){
	local msg=$1 flag=$2 timestamp=$(date +'%Y/%m/%d %H:%M:%S')
	[ -z "$msg" ] && return
	[ -z "$flag" ] && flag=1

	[ $logging = 0 -a $(( $flag & 1 )) -ne 0 ] && flag=$(( $flag ^ 1 ))
	if [ $verbose = 0 -a $(( $flag & 4 )) -ne 0 ];then
		[ $(( $flag & 1 )) -ne 0 ] && flag=$(( $flag ^ 1 ))
		[ $(( $flag & 2 )) -ne 0 ] && flag=$(( $flag ^ 2 ))
	fi
	if [ $down_acc = 0 -a $(( $flag & 8 )) -ne 0 ];then
		flag=$(( $flag ^ 8 ))
		[ $up_acc -ne 0 ] && flag=$(( $flag | 16 ))
	fi
	if [ $up_acc = 0 -a $(( $flag & 16 )) -ne 0 ];then
		flag=$(( $flag ^ 16 ))
		[ $down_acc -ne 0 ] && flag=$(( $flag | 8 ))
	fi

	[ $(( $flag & 1 )) -ne 0 ] && echo "$timestamp $msg" >> $LOGFILE 2> /dev/null
	[ $(( $flag & 2 )) -ne 0 ] && logger -p "daemon.info" -t "$NAME" "$msg"

	[ $(( $flag & 32 )) = 0 ] && local color="green" || local color="red"
	[ $(( $flag & 8 )) -ne 0 ] && echo -n "<font color=$color>$timestamp $msg</font>" > $down_state_file 2> /dev/null
	[ $(( $flag & 16 )) -ne 0 ] && echo -n "<font color=$color>$timestamp $msg</font>" > $up_state_file 2> /dev/null
}

# 清理日志
clean_log(){
	[ $logging = 1 -a -f "$LOGFILE" ] || return
	[ $(wc -l "$LOGFILE" | awk '{print $1}') -le 800 ] && return
	_log "清理日志文件"
	local logdata=$(tail -n 500 "$LOGFILE")
	echo "$logdata" > $LOGFILE 2> /dev/null
	unset logdata
}

# 獲取接口IP位址
get_bind_ip(){
	network=$(uci get xlnetacc.general.network 2> /dev/null)
	json_cleanup;json_load "$(ubus call network.interface.$network status 2> /dev/null)" >/dev/null 2>&1
	json_select "ipv4-address" >/dev/null 2>&1;json_select 1 >/dev/null 2>&1
	json_get_var _bind_ip "address"
	if [ -z "$_bind_ip" -o "$_bind_ip" = "0.0.0.0" ];then
		_log "獲取網路 $network IP地址失敗"
		return 1
	else
		_log "繫結IP位址: $_bind_ip"
		return 0
	fi
}

# 生成設備標識
gen_device_sign(){
	local ifname macaddr
	while :;do
		ifname=$(uci get network.$network.device 2> /dev/null || uci get network.$network.ifname 2> /dev/null)
		[ "${ifname:0:1}" = @ ] && network="${ifname:1}" || break
	done
	[ -z "$ifname" ] && { _log "獲取網路 $network 資訊出錯";return;}
	json_cleanup;json_load "$(ubus call network.device status {\"name\":\"$ifname\"} 2> /dev/null)" >/dev/null 2>&1
	json_get_var macaddr "macaddr"
	[ -z "$macaddr" ] && { _log "獲取網路 $network MAC地址出錯";return;}
	macaddr=$(echo -n "$macaddr" | awk '{print toupper($0)}')

	# 計算peerID
	local fake_peerid=$(awk -F- '{print toupper($5)}' '/proc/sys/kernel/random/uuid')
	readonly _peerid="${fake_peerid}004V"
	_log "_peerid is $_peerid" $(( 1 | 4 ))

	# 計算devicesign
	# sign = div.10?.device_id + md5(sha1(packageName + businessType + md5(a protocolVersion specific GUID)))
	local fake_device_id=$(echo -n "${macaddr//:/}" | openssl dgst -md5 | awk '{print $2}')
	local fake_device_sign=$(echo -n "${fake_device_id}${packageName}${businessType}c7f21687eed3cdb400ca11fc2263c998" \
		| openssl dgst -sha1 | awk '{print $2}')
	readonly _devicesign="div101.${fake_device_id}"$(echo -n "$fake_device_sign" | openssl dgst -md5 | awk '{print $2}')
	_log "_devicesign is $_devicesign" $(( 1 | 4 ))
}

# 快鳥帳號通用參數
swjsq_json(){
	let sequence_xl++
	# 生成POST資料
	json_init
	json_add_string protocolVersion "$protocolVersion"
	json_add_string sequenceNo "$sequence_xl"
	json_add_string platformVersion '10'
	json_add_string isCompressed '0'
	json_add_string appid "$businessType"
	json_add_string clientVersion "$clientVersion"
	json_add_string peerID "$_peerid"
	json_add_string appName "ANDROID-$packageName"
	json_add_string sdkVersion "${sdkVersion##*.}"
	json_add_string devicesign "$_devicesign"
	json_add_string netWorkType 'WIFI'
	json_add_string providerName 'OTHER'
	json_add_string deviceModel 'MI'
	json_add_string deviceName 'Xiaomi Mi'
	json_add_string OSVersion "7.1.1"
}

# 帳號登錄
swjsq_login(){
	swjsq_json
	if [ -z "$_userid" -o -z "$_loginkey" ];then
		access_url='https://mobile-login.xunlei.com/login'
		json_add_string userName "$username"
		json_add_string passWord "$password"
		json_add_string verifyKey
		json_add_string verifyCode
		json_add_string isMd5Pwd '0'
	else
		access_url='https://mobile-login.xunlei.com/loginkey'
		json_add_string userName "$_userid"
		json_add_string loginKey "$_loginkey"
	fi
	json_close_object

	local ret=$($_http_cmd -A "$agent_xl" -d "$(json_dump)" "$access_url")
	case $? in
		0)_log "login is $ret" $(( 1 | 4 ));json_cleanup;json_load "$ret" >/dev/null 2>&1;json_get_var lasterr "errorCode";;
		2)lasterr=-2;;
		28)lasterr=-3;;
		*)lasterr=-1;;
	esac

	case ${lasterr:=-1} in
		0)json_get_var _userid "userID";json_get_var _loginkey "loginKey";json_get_var _sessionid "sessionID";_log "_sessionid is $_sessionid" $(( 1 | 4 ));local outmsg="帳號登錄成功";_log "$outmsg" $(( 1 | 8 ));;
		15)_userid=;_loginkey=;;# 身分資訊已失效
		-1)local outmsg="帳號登錄失敗。迅雷伺服器未響應，請稍候";_log "$outmsg";;
		-2)local outmsg="cURL 參數解析錯誤，請更新 cURL";_log "$outmsg" $(( 1 | 8 | 32 ));;
		-3)local outmsg="cURL 網路通訊失敗，請稍候";_log "$outmsg";;
		*)local errorDesc;json_get_var errorDesc "errorDesc";local outmsg="帳號登錄失敗。錯誤代碼: ${lasterr}";[ -n "$errorDesc" ] && outmsg="${outmsg}，原因: $errorDesc";_log "$outmsg" $(( 1 | 8 | 32 ));;
	esac

	[ $lasterr = 0 ] && return 0 || return 1
}

# 帳號注銷
swjsq_logout(){
	swjsq_json
	json_add_string userID "$_userid"
	json_add_string sessionID "$_sessionid"
	json_close_object

	local ret=$($_http_cmd -A "$agent_xl" -d "$(json_dump)" 'https://mobile-login.xunlei.com/logout')
	_log "logout is $ret" $(( 1 | 4 ))
	json_cleanup;json_load "$ret" >/dev/null 2>&1
	json_get_var lasterr "errorCode"

	case ${lasterr:=-1} in
		0)_sessionid=;local outmsg="帳號注銷成功";_log "$outmsg" $(( 1 | 8 ));;
		-1)local outmsg="帳號注銷失敗。迅雷伺服器未響應，請稍候";_log "$outmsg";;
		*)local errorDesc;json_get_var errorDesc "errorDesc";local outmsg="帳號注銷失敗。錯誤代碼: ${lasterr}";[ -n "$errorDesc" ] && outmsg="${outmsg}，原因: $errorDesc";_log "$outmsg" $(( 1 | 8 | 32 ));;
	esac

	[ $lasterr = 0 ] && return 0 || return 1
}

# 獲取用戶資訊
swjsq_getuserinfo(){
	local _vasid vasid_down=14 vasid_up=33 outmsg
	[ $down_acc -ne 0 ] && _vasid="${_vasid}${vasid_down},";[ $up_acc -ne 0 ] && _vasid="${_vasid}${vasid_up},"
	swjsq_json
	json_add_string userID "$_userid"
	json_add_string sessionID "$_sessionid"
	json_add_string vasid "$_vasid"
	json_close_object

	local ret=$($_http_cmd -A "$agent_xl" -d "$(json_dump)" 'https://mobile-login.xunlei.com/getuserinfo')
	_log "getuserinfo is $ret" $(( 1 | 4 ))
	json_cleanup;json_load "$ret" >/dev/null 2>&1
	json_get_var lasterr "errorCode"

	case ${lasterr:=-1} in
		0)local index=1 can_down=0 vasid isVip isYear expireDate;json_select "vipList" >/dev/null 2>&1
			while :;do
				json_select $index >/dev/null 2>&1
				[ $? -ne 0 ] && break
				json_get_var vasid "vasid"
				json_get_var isVip "isVip"
				json_get_var isYear "isYear"
				json_get_var expireDate "expireDate"
				json_select ".." >/dev/null 2>&1
				let index++
				case ${vasid:-0} in
					2)[ $down_acc -ne 0 ] && outmsg="迅雷超級會員" || continue;;
					$vasid_down)outmsg="迅雷快鳥會員";;
					$vasid_up)outmsg="上行提速會員";;
					*)continue;;
				esac
				if [ ${isVip:-0} = 1 -o ${isYear:-0} = 1 ];then
					outmsg="${outmsg}有效。會員到期時間：${expireDate:0:4}-${expireDate:4:2}-${expireDate:6:2}"
					[ $vasid = $vasid_up ] && _log "$outmsg" $(( 1 | 16 )) || _log "$outmsg" $(( 1 | 8 ))
					[ $vasid -ne $vasid_up ] && can_down=$(( $can_down | 1 ))
				else
					if [ ${#expireDate} -ge 8 ];then
						outmsg="${outmsg}已到期。會員到期時間：${expireDate:0:4}-${expireDate:4:2}-${expireDate:6:2}"
					else
						outmsg="${outmsg}無效"
					fi
					[ $vasid = $vasid_up ] && _log "$outmsg" $(( 1 | 16 | 32 )) || _log "$outmsg" $(( 1 | 8 | 32 ))
					[ $vasid = $vasid_up ] && up_acc=0
				fi
			done
			[ $can_down = 0 ] && down_acc=0;;
		-1)outmsg="獲取迅雷會員資訊失敗。迅雷伺服器未響應，請稍候";_log "$outmsg";;
		*)local errorDesc;json_get_var errorDesc "errorDesc";outmsg="獲取迅雷會員資訊失敗。錯誤代碼: ${lasterr}";[ -n "$errorDesc" ] && outmsg="${outmsg}，原因: $errorDesc";_log "$outmsg" $(( 1 | 8 | 32 ));;
	esac

	[ $lasterr = 0 ] && return 0 || return 1
}

# 登錄時間更新
swjsq_renewal(){
	xlnetacc_var 1
	local limitdate=$(date +%Y%m%d -d "1970.01.01-00:00:$(( $(date +%s) + 30 * 24 * 60 * 60 ))")

	access_url='http://api.ext.swjsq.vip.xunlei.com'
	local ret=$($_http_cmd -A "$user_agent" "$access_url/renewal?${http_args%&dial_account=*}&limitdate=$limitdate")
	_log "renewal is $ret" $(( 1 | 4 ))
	json_cleanup;json_load "$ret" >/dev/null 2>&1
	json_get_var lasterr "errno"

	case ${lasterr:=-1} in
		0)local outmsg="更新登錄時間成功。帳號登錄展期：${limitdate:0:4}-${limitdate:4:2}-${limitdate:6:2}";_log "$outmsg";;
		-1)local outmsg="更新登錄時間失敗。迅雷伺服器未響應，請稍候";_log "$outmsg";;
		*)local message;json_get_var message "richmessage";local outmsg="更新登錄時間失敗。錯誤代碼: ${lasterr}";[ -n "$message" ] && outmsg="${outmsg}，原因: $message";_log "$outmsg" $(( 1 | 8 | 32 ));;
	esac

	[ $lasterr = 0 ] && return 0 || return 1
}

# 獲取提速入口
swjsq_portal(){
	xlnetacc_var $1

	[ $1 = 1 ] && access_url='http://api.portal.swjsq.vip.xunlei.com:81/v2/queryportal' || \
		access_url='http://api.upportal.swjsq.vip.xunlei.com/v2/queryportal'
	local ret=$($_http_cmd -A "$user_agent" "$access_url")
	_log "portal $1 is $ret" $(( 1 | 4 ))
	json_cleanup;json_load "$ret" >/dev/null 2>&1
	json_get_var lasterr "errno"

	case ${lasterr:=-1} in
		0)local interface_ip interface_port province sp;json_get_var interface_ip "interface_ip";json_get_var interface_port "interface_port";json_get_var province "province_name";json_get_var sp "sp_name"
			if [ $1 = 1 ];then
				_portal_down="http://$interface_ip:$interface_port/v2"
				_log "_portal_down is $_portal_down" $(( 1 | 4 ))
			else
				_portal_up="http://$interface_ip:$interface_port/v2"
				_log "_portal_up is $_portal_up" $(( 1 | 4 ))
			fi
			local outmsg="獲取${link_cn}提速入口成功";[ -n "$province" -a -n "$sp" ] && outmsg="${outmsg}。運營商：${province}${sp}";_log "$outmsg" $(( 1 | $1 * 8 ));;
		-1)local outmsg="獲取${link_cn}提速入口失敗。迅雷伺服器未響應，請稍候";_log "$outmsg";;
		*)local message;json_get_var message "message";local outmsg="獲取${link_cn}提速入口失敗。錯誤代碼: ${lasterr}";[ -n "$message" ] && outmsg="${outmsg}，原因: $message";_log "$outmsg" $(( 1 | $1 * 8 | 32 ));;
	esac

	[ $lasterr = 0 ] && return 0 || return 1
}

# 獲取網路帶寬資訊
isp_bandwidth(){
	xlnetacc_var $1

	local ret=$($_http_cmd -A "$user_agent" "$access_url/bandwidth?${http_args%&dial_account=*}")
	_log "bandwidth $1 is $ret" $(( 1 | 4 ))
	json_cleanup;json_load "$ret" >/dev/null 2>&1
	json_get_var lasterr "errno"

	case ${lasterr:=-1} in
		# 獲取帶寬資訊
		0)local can_upgrade bind_dial_account dial_account stream cur_bandwidth max_bandwidth;[ $1 = 1 ] && stream="downstream" || stream="upstream";json_get_var can_upgrade "can_upgrade"
			json_get_var bind_dial_account "bind_dial_account";json_get_var dial_account "dial_account";json_select;json_select "bandwidth" >/dev/null 2>&1;json_get_var cur_bandwidth "$stream"
			json_select;json_select "max_bandwidth" >/dev/null 2>&1;json_get_var max_bandwidth "$stream";json_select;cur_bandwidth=$(( ${cur_bandwidth:-0} / 1024 ));max_bandwidth=$(( ${max_bandwidth:-0} / 1024 ))
			if [ -n "$bind_dial_account" -a "$bind_dial_account" != "$dial_account" ];then
				local outmsg="繫結寬帶賬號 $bind_dial_account 與當前寬帶賬號 $dial_account 不一致，請聯系迅雷客服解綁（每月僅一次）";_log "$outmsg" $(( 1 | 8 | 32 ))
				down_acc=0;up_acc=0
			elif [ $can_upgrade = 0 ];then
				local message;json_get_var message "richmessage";[ -z "$message" ] && json_get_var message "message"
				local outmsg="${link_cn}無法提速";[ -n "$message" ] && outmsg="${outmsg}，原因: $message";_log "$outmsg" $(( 1 | $1 * 8 | 32 ))
				[ $1 = 1 ] && down_acc=0 || up_acc=0
			elif [ $cur_bandwidth -ge $max_bandwidth ];then
				local outmsg="${link_cn}無需提速。當前帶寬 ${cur_bandwidth}M，超過最大可提升帶寬 ${max_bandwidth}M";_log "$outmsg" $(( 1 | $1 * 8 ))
				[ $1 = 1 ] && down_acc=0 || up_acc=0
			else
				if [ -z "$_dial_account" -a -n "$dial_account" ];then
					_dial_account=$dial_account
					_log "_dial_account is $_dial_account" $(( 1 | 4 ))
				fi
				local outmsg="${link_cn}可以提速。當前帶寬 ${cur_bandwidth}M，可提升至 ${max_bandwidth}M";_log "$outmsg" $(( 1 | $1 * 8 ))
			fi;;
		# 724 賬號存在異常
		724)lasterr=-2;local outmsg="獲取${link_cn}網路帶寬資訊失敗。原因: 您的賬號存在異常，請聯系迅雷客服反饋";_log "$outmsg" $(( 1 | $1 * 8 | 32 ));;
		# 3103 線路暫不支援
		3103)lasterr=0;local province sp;json_get_var province "province_name";json_get_var sp "sp_name";local outmsg="${link_cn}無法提速。原因: ${province}${sp}線路暫不支援";_log "$outmsg" $(( 1 | $1 * 8 | 32 ))
			[ $1 = 1 ] && down_acc=0 || up_acc=0;;
		-1)local outmsg="獲取${link_cn}網路帶寬資訊失敗。運營商伺服器未響應，請稍候";_log "$outmsg";;
		*)local message;json_get_var message "richmessage";[ -z "$message" ] && json_get_var message "message"
			local outmsg="獲取${link_cn}網路帶寬資訊失敗。錯誤代碼: ${lasterr}";[ -n "$message" ] && outmsg="${outmsg}，原因: $message";_log "$outmsg" $(( 1 | $1 * 8 | 32 ));;
	esac

	[ $lasterr = 0 ] && return 0 || return 1
}

# 發送帶寬提速訊號
isp_upgrade(){
	xlnetacc_var $1

	local ret=$($_http_cmd -A "$user_agent" "$access_url/upgrade?$http_args")
	_log "upgrade $1 is $ret" $(( 1 | 4 ))
	json_cleanup;json_load "$ret" >/dev/null 2>&1
	json_get_var lasterr "errno"

	case ${lasterr:=-1} in
		0)local bandwidth;json_select "bandwidth" >/dev/null 2>&1;json_get_var bandwidth "downstream";bandwidth=$(( ${bandwidth:-0} / 1024 ))
			local outmsg="${link_cn}提速成功，帶寬已提升到 ${bandwidth}M";_log "$outmsg" $(( 1 | $1 * 8 ));[ $1 = 1 ] && down_acc=2 || up_acc=2;;
		# 812 已處於提速狀態
		812)lasterr=0;local outmsg="${link_cn}提速成功，當前寬帶已處於提速狀態";_log "$outmsg" $(( 1 | $1 * 8 ));[ $1 = 1 ] && down_acc=2 || up_acc=2;;
		# 724 賬號存在異常
		724)lasterr=-2;local outmsg="${link_cn}提速失敗。原因: 您的賬號存在異常，請聯系迅雷客服反饋";_log "$outmsg" $(( 1 | $1 * 8 | 32 ));;
		-1)local outmsg="${link_cn}提速失敗。運營商伺服器未響應，請稍候";_log "$outmsg";;
		*)local message;json_get_var message "richmessage";[ -z "$message" ] && json_get_var message "message"
			local outmsg="${link_cn}提速失敗。錯誤代碼: ${lasterr}";[ -n "$message" ] && outmsg="${outmsg}，原因: $message";_log "$outmsg" $(( 1 | $1 * 8 | 32 ));;
	esac

	[ $lasterr = 0 ] && return 0 || return 1
}

# 發送提速心跳訊號
isp_keepalive(){
	xlnetacc_var $1

	local ret=$($_http_cmd -A "$user_agent" "$access_url/keepalive?$http_args")
	_log "keepalive $1 is $ret" $(( 1 | 4 ))
	json_cleanup;json_load "$ret" >/dev/null 2>&1
	json_get_var lasterr "errno"

	case ${lasterr:=-1} in
		0)local outmsg="${link_cn}心跳訊號返回正常";_log "$outmsg";;
		# 513 提速通道不存在
		513)lasterr=-2;local outmsg="${link_cn}提速超時，提速通道不存在";_log "$outmsg" $(( 1 | $1 * 8 | 32 ));;
		-1)local outmsg="${link_cn}心跳訊號發送失敗。運營商伺服器未響應，請稍候";_log "$outmsg";;
		*)local message;json_get_var message "richmessage";[ -z "$message" ] && json_get_var message "message"
			local outmsg="${link_cn}提速失效。錯誤代碼: ${lasterr}";[ -n "$message" ] && outmsg="${outmsg}，原因: $message";_log "$outmsg" $(( 1 | $1 * 8 | 32 ));;
	esac

	[ $lasterr = 0 ] && return 0 || return 1
}

# 發送帶寬恢覆訊號
isp_recover(){
	xlnetacc_var $1

	local ret=$($_http_cmd -A "$user_agent" "$access_url/recover?$http_args")
	_log "recover $1 is $ret" $(( 1 | 4 ))
	json_cleanup;json_load "$ret" >/dev/null 2>&1
	json_get_var lasterr "errno"

	case ${lasterr:=-1} in
		0)local outmsg="${link_cn}帶寬已恢覆";_log "$outmsg" $(( 1 | $1 * 8 ));[ $1 = 1 ] && down_acc=1 || up_acc=1;;
		-1)local outmsg="${link_cn}帶寬恢覆失敗。運營商伺服器未響應，請稍候";_log "$outmsg";;
		*)local message;json_get_var message "richmessage";[ -z "$message" ] && json_get_var message "message"
			local outmsg="${link_cn}帶寬恢覆失敗。錯誤代碼: ${lasterr}";[ -n "$message" ] && outmsg="${outmsg}，原因: $message";_log "$outmsg" $(( 1 | $1 * 8 | 32 ));;
	esac

	[ $lasterr = 0 ] && return 0 || return 1
}

# 查詢提速資訊，未使用
isp_query(){
	xlnetacc_var $1

	local ret=$($_http_cmd -A "$user_agent" "$access_url/query_try_info?$http_args")
	_log "query_try_info $1 is $ret" $(( 1 | 4 ))
	json_cleanup;json_load "$ret" >/dev/null 2>&1
	json_get_var lasterr "errno"

	[ $lasterr = 0 ] && return 0 || return 1
}

# 設定參數變量
xlnetacc_var(){
	if [ $1 = 1 ];then
		let sequence_down++
		access_url=$_portal_down
		http_args="sequence=${sequence_down}&client_type=${client_type_down}-${clientVersion}&client_version=${client_type_down//-/}-${clientVersion}&chanel=umeng-10900011&time_and=$(date +%s)000"
		user_agent=$agent_down
		link_cn="下行"
	else
		let sequence_up++
		access_url=$_portal_up
		http_args="sequence=${sequence_up}&client_type=${client_type_up}-${clientVersion}&client_version=${client_type_up//-/}-${clientVersion}"
		user_agent=$agent_down
		link_cn="上行"
	fi
	http_args="${http_args}&peerid=${_peerid}&userid=${_userid}&sessionid=${_sessionid}&user_type=1&os=android-7.1.1"
	[ -n "$_dial_account" ] && http_args="${http_args}&dial_account=${_dial_account}"
}

# 重試循環
xlnetacc_retry(){
	if [ $# -ge 3 ];then
		if [ $3 -ne 0 ];then
			[ $2 = 1 -a $down_acc -ne $3 ] && return 0
			[ $2 = 2 -a $up_acc -ne $3 ] && return 0
		fi
	fi
	local retry=1
	while :;do
		lasterr=
		eval $1 $2 && break # 成功
		[ $# -ge 4 -a $retry -ge $4 ] && break || let retry++ # 重試超時
		case $lasterr in
			-1)sleep 5s;;# 伺服器未響應
			-2)break;;# 嚴重錯誤
			*)sleep 3s;;# 其它錯誤
		esac
	done

	[ ${lasterr:-0} = 0 ] && return 0 || return 1
}

# 注銷已登錄帳號
xlnetacc_logout(){
	[ -z "$_sessionid" ] && return 2
	[ $# -ge 1 ] && local retry=$1 || local retry=1

	xlnetacc_retry 'isp_recover' 1 2 $retry
	xlnetacc_retry 'isp_recover' 2 2 $retry
	xlnetacc_retry 'swjsq_logout' 0 0 $retry
	[ $down_acc -ne 0 ] && down_acc=1;[ $up_acc -ne 0 ] && up_acc=1
	_sessionid=;_dial_account=

	[ $lasterr = 0 ] && return 0 || return 1
}

# 中止訊號處理
sigterm(){
	_log "trap sigterm, exit" $(( 1 | 4 ))
	xlnetacc_logout
	rm -f "$down_state_file" "$up_state_file"
	exit 0
}

# 初始化
xlnetacc_init(){
	[ "$1" != "--start" ] && return 1

	# 防止重複啟動
	[ -f /var/lock/xlnetacc.lock ] && return 1
	touch /var/lock/xlnetacc.lock

	# 讀取設定
	readonly NAME=xlnetacc
	readonly LOGFILE=/var/log/${NAME}.log
	readonly down_state_file=/var/state/${NAME}_down_state
	readonly up_state_file=/var/state/${NAME}_up_state
	down_acc=$(uci_get_by_bool "general" "down_acc" 0)
	up_acc=$(uci_get_by_bool "general" "up_acc" 0)
	readonly logging=$(uci_get_by_bool "general" "logging" 1)
	readonly verbose=$(uci_get_by_bool "general" "verbose" 0)
	network=$(uci_get_by_name "general" "network" "wan")
	keepalive=$(uci_get_by_name "general" "keepalive" 10)
	relogin=$(uci_get_by_name "general" "relogin" 0)
	readonly username=$(uci_get_by_name "general" "account")
	readonly password=$(uci_get_by_name "general" "password")
	local enabled=$(uci_get_by_bool "general" "enabled" 0)
	([ $enabled = 0 ] || [ $down_acc = 0 -a $up_acc = 0 ] || [ -z "$username" -o -z "$password" -o -z "$network" ]) && return 2
	([ -z "$keepalive" -o -n "${keepalive//[0-9]/}" ] || [ $keepalive -lt 5 -o $keepalive -gt 60 ]) && keepalive=10
	readonly keepalive=$(( $keepalive ))
	([ -z "$relogin" -o -n "${relogin//[0-9]/}" ] || [ $relogin -gt 48 ]) && relogin=0
	readonly relogin=$(( $relogin * 60 * 60 ))

	[ $logging = 1 ] && [ ! -d /var/log ] && mkdir -p /var/log
	[ -f "$LOGFILE" ] && _log "------------------------------"
	_log "迅雷快鳥正在啟動..."

	# 檢查外部調用工具
	command -v curl >/dev/null || { _log "cURL 未安裝";return 3;}
	local opensslchk=$(echo -n 'openssl' | openssl dgst -sha1 | awk '{print $2}')
	[ "$opensslchk" != 'c898fa1e7226427010e329971e82c669f8d8abb4' ] && { _log "openssl-util 未安裝或計算錯誤";return 3;}

	# 捕獲中止訊號
	trap 'sigterm' INT # Ctrl-C
	trap 'sigterm' QUIT # Ctrl-\
	trap 'sigterm' TERM # kill

	# 生成設備標識
	gen_device_sign
	[ ${#_peerid} -ne 16 -o ${#_devicesign} -ne 71 ] && return 4

	clean_log
	[ -d /var/state ] || mkdir -p /var/state
	rm -f "$down_state_file" "$up_state_file"
	return 0
}

# 程式主體
xlnetacc_main(){
	while :;do
		# 獲取外網IP位址
		xlnetacc_retry 'get_bind_ip'
		_http_cmd="curl -Lfs -m 5 --interface $_bind_ip"

		# 注銷快鳥帳號
		xlnetacc_logout 3 && sleep 3s

		# 登錄快鳥帳號
		while :;do
			lasterr=
			swjsq_login
			case $lasterr in
				0)break;;# 登錄成功
				-1)sleep 5s;;# 伺服器未響應
				-2)return 7;;# cURL 參數解析錯誤
				-3)sleep 3s;;# cURL 網路通訊失敗
				6)sleep 130m;;# 需要輸入驗證碼
				8)sleep 3m;;# 伺服器系統維護
				15)sleep 1s;;# 身分資訊已失效
				*)return 5;;# 登錄失敗
			esac
		done

		# 獲取用戶資訊
		xlnetacc_retry 'swjsq_getuserinfo'
		[ $down_acc = 0 -a $up_acc = 0 ] && break
		# 登錄時間更新
		xlnetacc_retry 'swjsq_renewal'
		# 獲取提速入口
		xlnetacc_retry 'swjsq_portal' 1 1
		xlnetacc_retry 'swjsq_portal' 2 1
		# 獲取帶寬資訊
		xlnetacc_retry 'isp_bandwidth' 1 1 10 || { sleep 3m;continue;}
		xlnetacc_retry 'isp_bandwidth' 2 1 10 || { sleep 3m;continue;}
		[ $down_acc = 0 -a $up_acc = 0 ] && break
		# 帶寬提速
		xlnetacc_retry 'isp_upgrade' 1 1 10 || { sleep 3m;continue;}
		xlnetacc_retry 'isp_upgrade' 2 1 10 || { sleep 3m;continue;}

		# 心跳保持
		local timer=$(date +%s)
		while :;do
			clean_log # 清理日誌
			sleep ${keepalive}m
			[ $relogin -ne 0 -a $(( $(date +%s) - $timer )) -ge $relogin ] && break # 登錄超時
			xlnetacc_retry 'isp_keepalive' 1 2 5 || break
			xlnetacc_retry 'isp_keepalive' 2 2 5 || break
		done
	done
	xlnetacc_logout
	_log "無法提速，迅雷快鳥已停止。"
	return 6
}

# 程式入口
xlnetacc_init "$@" && xlnetacc_main
exit $?
