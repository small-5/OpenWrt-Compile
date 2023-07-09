#!/bin/sh
# 防止重複啟動
[ -f /var/lock/openvpncert.lock ] && exit 1
export EASYRSA="/tmp/easyrsa3"
export EASYRSA_VARS_FILE="/etc/easy-rsa/vars"
export EASYRSA_BATCH=1
D=/tmp/easyrsa3/pki

gen(){
	easyrsa init-pki >/dev/null 2>&1 || return 1
	easyrsa build-ca nopass >/dev/null 2>&1 || return 1
	easyrsa gen-req server nopass >/dev/null 2>&1 || return 1
	easyrsa sign server server >/dev/null 2>&1 || return 1
	easyrsa gen-req client nopass >/dev/null 2>&1 || return 1
	easyrsa sign client client >/dev/null 2>&1 || return 1
	if [ -n "$(uci -q get openvpn.myvpn.tls_auth)" ];then
		openvpn --genkey secret /etc/openvpn/ta.key >/dev/null 2>&1 || return 1
	fi
	cp $D/ca.crt /etc/openvpn || return 1
	cp $D/issued/server.crt /etc/openvpn || return 1
	cp $D/private/server.key /etc/openvpn || return 1
	cp $D/issued/client.crt /etc/openvpn || return 1
	cp $D/private/client.key /etc/openvpn || return 1
}

touch /var/lock/openvpncert.lock
rm -rf /tmp/easyrsa3
gen
[ $? = 0 ] && echo "OpenVPN Cert generate successfull" || echo "OpenVPN Cert generate failed"
rm -rf /tmp/easyrsa3 /var/lock/openvpncert.lock
