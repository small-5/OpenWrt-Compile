m=Map("openvpn")
m.title=translate("OpenVPN Server")
m.description=translate("An easy config OpenVPN Server Web-UI")
m:section(SimpleSection).template="openvpn-server/openvpn_status"

s=m:section(TypedSection,"openvpn")
s.anonymous=true

o=s:option(Flag,"enabled")
o.title=translate("Enable")
o.default=0
o.rmempty=false

o=s:option(Value,"ddns",translate("Address"))
o.description=translate("DDNS domain or IP of the WAN interface")
o.datatype="host"
o.default="exmple.com"
o.rmempty=false
o.password=true

o=s:option(Value,"port",translate("Port"))
o.datatype="range(1,65535)"
o.rmempty=false

o=s:option(ListValue,"proto",translate("Proto"))
o:value("tcp",translate("TCP"))
o:value("udp",translate("UDP"))
o:value("tcp6",translate("TCP Over IPv6"))
o:value("udp6",translate("UDP Over IPv6"))
o.rmempty=false

o=s:option(Value,"server",translate("Client Network"))
o.datatype="string"
o.description=translate("VPN Client Network IP with subnet")

o=s:option(ListValue,"d_ipv6",translate("IPv6 Mode"))
o:value("0",translate("Helper Mode"))
o:value("1",translate("Expanded Mode"))
o.description=translate("Select mode of IPv6 client Network")
o.rmempty=false

o=s:option(Value,"server_ipv6",translate("IPV6 Address"))
o.datatype="ip6addr"
o.description=translate("For example: fd80::1 or fd80::1/64<br/>The default prefix length is 64<br/>The length between 64-112 is supported<br/>This mode does not need to set the IPV6 address pool")
o:depends("d_ipv6","0")
o.placeholder="fd80::1"

o=s:option(Value,"ifconfig_ipv6",translate("IPV6 Address"))
o.datatype="string"
o.description=translate("For example: fd80::1 fd80::1 or fd80::1/64 fd80::1<br/>2 IPv6 addresses need to be set in this mode<br/>The default prefix length is 64<br/>The length between 64-112 is supported<br/>This mode need to set the IPV6 address pool")
o:depends("d_ipv6","1")
o.placeholder="fd80::1 fd80::1"

o=s:option(Value,"ifconfig_ipv6_pool",translate("IPv6 Pool"))
o.datatype="ip6addr"
o.description=translate("If the server IPv6 address is fd80::1 ,it needs to be set to fd80::2 or higher")
o:depends("d_ipv6","1")
o.placeholder="fd80::2"

o=s:option(Value,"max_clients",translate("Max-clients"))
o.datatype="range(1,255)"
o.description=translate("Set maximum number of connections")

o=s:option(ListValue,"data_ciphers",translate("Data Ciphers"))
o.description=translate("AES-256-GCM is the default encryption method")
o:value("aes-128-gcm","AES-128-GCM")
o:value("aes-256-gcm","AES-256-GCM")
o:value("chacha20-poly1305","CHACHA20-POLY1305")

o=s:option(ListValue,"remote_cert_tls",translate("Remote-cert-tls"))
o.description=translate("Check remote certificate to prevent man-in-the-middle attacks<br/>Recommended to enable")
o:value("",translate("Disable"))
o:value("client",translate("Enable"))

o=s:option(ListValue,"tls_crypt",translate("TLS-Crypt"))
o.description=translate("Encrypt and authenticate all control channel packets")
o:value("",translate("Disable"))
o:value("/etc/openvpn/ta.key",translate("Enable"))

o=s:option(Flag,"float",translate("Float"))
o.description=translate("Allow the remote host to change its IP address or port")

o=s:option(Flag,"duplicate_cn",translate("Duplicate-cn"))
o.description=translate("Allow multiple clients with the same name or the same client certificate to connect to the server at the same time")

o=s:option(ListValue,"auth_user_pass_verify",translate("Auth-user-pass-verify"))
o.description=translate("Enable username/password for authentication")
o:value("",translate("Disable"))
o:value("/usr/share/openvpn/checkpsw.sh via-file",translate("Enable"))

o=s:option(Flag,"username_as_common_name",translate("Username-as-common-name"))
o.description=translate("For enable username/password verification,use the authenticated username as the common name, rather than the common name from the client cert")
o:depends("auth_user_pass_verify","/usr/share/openvpn/checkpsw.sh via-file")

o=s:option(ListValue,"verify_client_cert",translate("Verify Client Cert"))
o.description=translate("If the certificate authentication is disabled,the client authentication only uses the user name/password,and the remote certificate checking function will be invalid")
o:depends("auth_user_pass_verify","/usr/share/openvpn/checkpsw.sh via-file")
o:value("",translate("Enable"))
o:value("none",translate("Disable"))

o=s:option(ListValue,"tmp_dir",translate("Tmp dir"))
o.description=translate("Password verification file temporary directory")
o:value("/tmp")
o:depends("auth_user_pass_verify","/usr/share/openvpn/checkpsw.sh via-file")

o=s:option(ListValue,"retry",translate("Connect-retry"))
o.description=translate("Set client reconnection interval (seconds)<br/>Need to re-download the .ovpn file after modification")
for s=0,60 do
o:value(s)
end
o.rmempty=false

o=s:option(ListValue,"verb",translate("Log level"))
o.description=translate("Set the log level,the larger the number,the more detailed the record content")
for s=0,11 do
o:value(s)
end
o.default=1
o.rmempty=false

o=s:option(DynamicList,"push")
o.title=translate("Client Push Settings")
o.datatype="string"
o.description=translate("Choose global routing and modify DNS according to the actual situation<br/>Global routing cannot be selected multiple times")
o:value("redirect-gateway def1 bypass-dhcp",translate("Only IPv4 Global Routing"))
o:value("redirect-gateway ipv6 !ipv4 bypass-dhcp",translate("Only IPv6 Global Routing"))
o:value("redirect-gateway def1 ipv6 bypass-dhcp",translate("Both IPv4 and IPv6 Global Routing"))
o:value("block-outside-dns",translate("Block Outside DNS"))

function Download()
	local t,e,z
	t=nixio.open("/tmp/my.ovpn","r")
	nixio.fs.remove("/tmp/my.ovpn")
	z=luci.sys.exec("echo -n $(uci -q get system.@system[0].hostname)")
	if z=="" then z="my" end
	luci.http.header('Content-Disposition','attachment;filename="'..z..'.ovpn"')
	luci.http.prepare_content("application/octet-stream")
	while true do
		e=t:read(nixio.const.buffersize)
		if(not e)or(#e==0)then
			break
		else
			luci.http.write(e)
		end
	end
	t:close()
	luci.http.close()
end

o=s:option(Button,"certificate",translate("OpenVPN Client config file"))
o.inputtitle=translate("Download .ovpn file")
o.description=translate("If you are using iOS client, download this .ovpn file and send it via Email to your iOS device<br/>After modifying the configuration, you need to download the .ovpn file again<br/>Re-download the .ovpn file after generating the certificate")
o.inputstyle="reload"
o.write=function()
	luci.sys.call("/usr/share/openvpn/genovpn.sh 2>&1 >/dev/null")
	Download()
end

o=s:option(Button,"gencert",translate("Generate certificate"))
o.description=translate("<font color=\"red\">Generate certificate before running for the first time<br/>After modifying the certificate option, you need to regenerate the certificate to take effect<br/>The certificate may take a long time to generate<br/>After the certificate is generated, the VPN service needs to be restarted to take effect</font>")
o.inputstyle="apply"
o.write=function()
	luci.sys.call("/usr/share/openvpn/openvpncert.sh 2>&1 >/dev/null &")
end

o=s:option(Button,"delcert",translate("Delete certificate"))
o.description=translate("<font color=\"red\">Delete the certificate,proceed with caution!</font>")
o.inputstyle="reload"
o.write=function()
	luci.sys.call("rm -f /etc/openvpn/ca.crt /etc/openvpn/client.* /etc/openvpn/server.*")
	luci.http.redirect(luci.dispatcher.build_url("admin","vpn","openvpn-server"))
end

return m
