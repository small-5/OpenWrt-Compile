#!/bin/sh

ddns=`uci get openvpn.myvpn.ddns`
port=`uci get openvpn.myvpn.port`
proto=`uci get openvpn.myvpn.proto`
ciphers=`uci get openvpn.myvpn.data_ciphers`
OVPN=`cat /etc/openvpn/ovpnadd/ovpnadd.conf 2>/dev/null`
RETRY=`uci -q get openvpn.myvpn.retry`
echo $proto | grep -q 6 && proto=${proto%6} || proto=${proto}4

cat > /tmp/my.ovpn  <<EOF
client
dev tun
proto $proto
remote $ddns $port
resolv-retry infinite
nobind
persist-key
persist-tun
verb 3
auth-nocache
connect-retry $RETRY
cipher $ciphers
data-ciphers $ciphers
tls-version-min 1.3
EOF
uci -q get openvpn.myvpn.remote_cert_tls >/dev/null && echo remote-cert-tls server >> /tmp/my.ovpn
uci -q get openvpn.myvpn.tls_auth >/dev/null && status=1 && echo key-direction 1 >> /tmp/my.ovpn
uci -q get openvpn.myvpn.auth_user_pass_verify >/dev/null && echo auth-user-pass >> /tmp/my.ovpn
uci -q get openvpn.myvpn.float >/dev/null && echo float >> /tmp/my.ovpn
echo '<ca>' >> /tmp/my.ovpn
cat /etc/openvpn/ca.crt >> /tmp/my.ovpn
echo '</ca>' >> /tmp/my.ovpn
[ $(uci -q get openvpn.myvpn.verify_client_cert) ] || {
echo '<cert>' >> /tmp/my.ovpn
cat /etc/openvpn/client.crt >> /tmp/my.ovpn
echo '</cert>' >> /tmp/my.ovpn
echo '<key>' >> /tmp/my.ovpn
cat /etc/openvpn/client.key >> /tmp/my.ovpn
echo '</key>' >> /tmp/my.ovpn
}
[ $status ] && {
echo '<tls-auth>' >> /tmp/my.ovpn
cat /etc/openvpn/ta.key >> /tmp/my.ovpn
echo '</tls-auth>' >> /tmp/my.ovpn
}
[ "$OVPN" ] && cat /etc/openvpn/ovpnadd/ovpnadd.conf >> /tmp/my.ovpn
