local m,s,o,kcp_enable
local ov="overwall"
local sid=arg[1]
local uuid=luci.sys.exec("cat /proc/sys/kernel/random/uuid")
local A=luci.sys.call("which obfs-local >/dev/null")
local B=luci.sys.call("which xray-plugin >/dev/null")

local encrypt_methods={
"none",
"table",
"rc4",
"rc4-md5",
"rc4-md5-6",
"aes-128-cfb",
"aes-192-cfb",
"aes-256-cfb",
"aes-128-ctr",
"aes-192-ctr",
"aes-256-ctr",
"bf-cfb",
"camellia-128-cfb",
"camellia-192-cfb",
"camellia-256-cfb",
"cast5-cfb",
"des-cfb",
"idea-cfb",
"rc2-cfb",
"seed-cfb",
"salsa20",
"chacha20",
"chacha20-ietf"
}

local encrypt_methods_ss={
"aes-128-gcm",
"aes-192-gcm",
"aes-256-gcm",
"chacha20-ietf-poly1305",
"xchacha20-ietf-poly1305"
}

local protocol={
"origin",
"auth_sha1",
"auth_sha1_v2",
"auth_sha1_v4",
"auth_aes128_md5",
"auth_aes128_sha1",
"auth_chain_a",
"auth_chain_b",
"auth_chain_c",
"auth_chain_d",
"auth_chain_e",
"auth_chain_f",
}

local obfs={
"plain",
"http_simple",
"http_post",
"tls1.2_ticket_auth",
}

local securitys={
"none",
"aes-128-gcm",
"chacha20-poly1305"
}

local flows={
"xtls-rprx-splice",
"xtls-rprx-splice-udp443",
"xtls-rprx-direct",
"xtls-rprx-direct-udp443",
"xtls-rprx-origin",
"xtls-rprx-origin-udp443"
}

m=Map(ov,translate("Edit Overwall Server"))
m.redirect=luci.dispatcher.build_url("admin/services/overwall/servers")
if m.uci:get(ov,sid)~="servers" then
	luci.http.redirect(m.redirect)
	return
end

s=m:section(NamedSection,sid,"servers")
s.anonymous=true
s.addremove=false

o=s:option(DummyValue,"url","SS/SSR/VMess/VLESS/TROJAN URL")
o.rawhtml=true
o.template="overwall/url"
o.value=sid

o=s:option(ListValue,"type",translate("Server Node Type"))
if luci.sys.call("which ss-redir >/dev/null")==0 then
o:value("ss",translate("Shadowsocks New Version"))
end
if luci.sys.call("which ssr-redir >/dev/null")==0 then
o:value("ssr",translate("ShadowsocksR"))
end
if luci.sys.call("which xray >/dev/null")==0 then
o:value("vmess",translate("VMess"))
o:value("vless",translate("VLESS"))
end
if luci.sys.call("which trojan-plus >/dev/null")==0 then
o:value("trojan",translate("Trojan"))
end
if luci.sys.call("which naive >/dev/null")==0 then
o:value("naiveproxy",translate("NaiveProxy"))
end
if luci.sys.call("which redsocks2 >/dev/null")==0 then
o:value("socks5",translate("Socks5"))
o:value("tun",translate("Network Tunnel"))
end
o.description=translate("Using incorrect encryption mothod may causes service fail to start")

o=s:option(Value,"alias",translate("Alias(optional)"))

o=s:option(ListValue,"iface",translate("Network interface to use"))
for _,e in ipairs(luci.sys.net.devices()) do if e~="lo" then o:value(e) end end
o:depends("type","tun")
o.description=translate("Redirect traffic to this network interface")

o=s:option(Value,"server",translate("Server Address"))
o.datatype="host"
o.rmempty=false
o:depends("type","ssr")
o:depends("type","ss")
o:depends("type","vmess")
o:depends("type","vless")
o:depends("type","trojan")
o:depends("type","naiveproxy")
o:depends("type","socks5")

o=s:option(Value,"server_port",translate("Server Port"))
o.datatype="port"
o.rmempty=false
o:depends("type","ssr")
o:depends("type","ss")
o:depends("type","vmess")
o:depends("type","vless")
o:depends("type","trojan")
o:depends("type","naiveproxy")
o:depends("type","socks5")

o=s:option(Flag,"auth_enable",translate("Enable Authentication"))
o:depends("type","socks5")

o=s:option(Value,"username",translate("Username"))
o:depends("type","naiveproxy")
o:depends("auth_enable",1)

o=s:option(Value,"password",translate("Password"))
o.password=true
o:depends("type","ssr")
o:depends("type","ss")
o:depends("type","trojan")
o:depends("type","naiveproxy")
o:depends("auth_enable",1)

o=s:option(ListValue,"encrypt_method",translate("Encrypt Method"))
for _,v in ipairs(encrypt_methods) do o:value(v) end
o:depends("type","ssr")

o=s:option(ListValue,"encrypt_method_ss",translate("Encrypt Method"))
for _,v in ipairs(encrypt_methods_ss) do o:value(v) end
o:depends("type","ss")

if A==0 or B==0 then
o=s:option(ListValue,"plugin",translate("Plugin"))
o:value("",translate("Disable"))
if A==0 then
o:value("obfs-local",translate("simple-obfs"))
end
if B==0 then
o:value("xray-plugin",translate("xray-plugin"))
end
o:depends("type","ss")
end

o=s:option(Value,"plugin_opts",translate("Plugin Opts"))
o:depends("plugin","obfs-local")
o:depends("plugin","xray-plugin")

o=s:option(ListValue,"protocol",translate("Protocol"))
for _,v in ipairs(protocol) do o:value(v) end
o:depends("type","ssr")

o=s:option(Value,"protocol_param",translate("Protocol param(optional)"))
o:depends("type","ssr")

o=s:option(ListValue,"obfs",translate("Obfs"))
for _,v in ipairs(obfs) do o:value(v) end
o:depends("type","ssr")

o=s:option(Value,"obfs_param",translate("Obfs param(optional)"))
o:depends("type","ssr")

o=s:option(Value,"alter_id",translate("AlterId"))
o.datatype="port"
o.placeholder=0
o:depends("type","vmess")

o=s:option(Value,"uuid",translate("Vmess/VLESS ID (UUID)"))
o.default=uuid
o:depends("type","vmess")
o:depends("type","vless")

o=s:option(Value,"vless_encryption",translate("VLESS Encryption"))
o.default="none"
o:depends("type","vless")

o=s:option(ListValue,"security",translate("Encrypt Method"))
o:value("","AUTO")
for _,v in ipairs(securitys) do o:value(v,v:upper()) end
o:depends("type","vmess")

o=s:option(ListValue,"transport",translate("Transport"))
o:value("tcp","TCP")
o:value("kcp","mKCP")
o:value("ws","WebSocket")
o:value("h2","HTTP/2")
o:value("quic","QUIC")
o:value("grpc","gRPC")
o:depends("type","vmess")
o:depends("type","vless")

o=s:option(ListValue,"tcp_guise",translate("Camouflage Type"))
o:value("none",translate("None"))
o:value("http","HTTP")
o:depends("transport","tcp")

o=s:option(Value,"http_host",translate("HTTP Host"))
o:depends("tcp_guise","http")

o=s:option(Value,"http_path",translate("HTTP Path"))
o:depends("tcp_guise","http")

o=s:option(Value,"ws_host",translate("WebSocket Host"))
o:depends("transport","ws")

o=s:option(Value,"ws_path",translate("WebSocket Path"))
o:depends("transport","ws")

o=s:option(Value,"h2_host",translate("HTTP/2 Host"))
o:depends("transport","h2")

o=s:option(Value,"h2_path",translate("HTTP/2 Path"))
o:depends("transport","h2")

o=s:option(ListValue,"quic_security",translate("QUIC Security"))
o:value("none",translate("None"))
o:value("aes-128-gcm",translate("aes-128-gcm"))
o:value("chacha20-poly1305",translate("chacha20-poly1305"))
o:depends("transport","quic")

o=s:option(Value,"quic_key",translate("QUIC Key"))
o:depends("transport","quic")

o=s:option(ListValue,"quic_guise",translate("Header"))
o:value("none",translate("None"))
o:value("srtp",translate("VideoCall (SRTP)"))
o:value("utp",translate("BitTorrent (uTP)"))
o:value("wechat-video",translate("WechatVideo"))
o:value("dtls","DTLS 1.2")
o:value("wireguard","WireGuard")
o:depends("transport","quic")

o=s:option(Value,"grpc_serviceName","ServiceName")
o:depends("transport","grpc")

o=s:option(ListValue,"kcp_guise",translate("Camouflage Type"))
o:value("none",translate("None"))
o:value("srtp",translate("VideoCall (SRTP)"))
o:value("utp",translate("BitTorrent (uTP)"))
o:value("wechat-video",translate("WechatVideo"))
o:value("dtls","DTLS 1.2")
o:value("wireguard","WireGuard")
o:depends("transport","kcp")

o=s:option(Value,"mtu",translate("MTU"))
o.datatype="uinteger"
o.default=1350
o:depends("transport","kcp")

o=s:option(Value,"tti",translate("TTI"))
o.datatype="uinteger"
o.default=50
o:depends("transport","kcp")

o=s:option(Value,"uplink_capacity",translate("Uplink Capacity"))
o.datatype="uinteger"
o.default=5
o:depends("transport","kcp")

o=s:option(Value,"downlink_capacity",translate("Downlink Capacity"))
o.datatype="uinteger"
o.default=20
o:depends("transport","kcp")

o=s:option(Value,"read_buffer_size",translate("Read Buffer Size"))
o.datatype="uinteger"
o.default=2
o:depends("transport","kcp")

o=s:option(Value,"write_buffer_size",translate("Write Buffer Size"))
o.datatype="uinteger"
o.default=2
o:depends("transport","kcp")

o=s:option(Value,"seed",translate("Obfuscate password (optional)"))
o:depends({type="vmess",transport="kcp"})
o:depends({type="vless",transport="kcp"})

o=s:option(Flag,"congestion",translate("Congestion"))
o:depends("transport","kcp")

o=s:option(Flag,"tls",translate("TLS"))
o:depends("type","vmess")
o:depends({type="vless",xtls=0})

o=s:option(Flag,"xtls",translate("XTLS"))
o:depends({type="vless",tls=0})

o=s:option(Value,"tls_host",translate("TLS Host"))
o:depends("type","trojan")
o:depends("tls",1)
o:depends("xtls",1)

o=s:option(ListValue,"fingerprint",translate("TLS Fingerprint"))
o:value("",translate("None"))
o:value("chrome","Chrome")
o:value("firefox","Firefox")
o:value("safari","Safari")
o:value("randomized","Randomized")
o:depends("tls",1)
o:depends("xtls",1)

o=s:option(ListValue,"vless_flow",translate("Flow"))
for _,v in ipairs(flows) do o:value(v,v) end
o.default="xtls-rprx-splice"
o:depends({type="vless",xtls=1})

o=s:option(ListValue,"vless_flow_tls",translate("Flow"))
o:value("",translate("None"))
o:value("xtls-rprx-vision","xtls-rprx-vision")
o:depends({type="vless",tls=1})

o=s:option(Flag,"insecure",translate("allowInsecure"))
o.description=translate("Allowing insecure connection will not check the validity of the TLS certificate provided by the remote host")
o:depends("type","trojan")
o:depends("tls",1)
o:depends("xtls",1)

o=s:option(Flag,"certificate",translate("Self-signed Certificate"))
o.description=translate("If you have a self-signed certificate,please check the box")
o:depends({type="trojan",insecure=0})
o:depends({tls=1,insecure=0})
o:depends({xtls=1,insecure=0})

o=s:option(DummyValue,"upload",translate("upload"))
o.template="overwall/certupload"
o:depends("certificate",1)

cert_dir="/etc/ssl/private/"
local path

luci.http.setfilehandler(
	function(meta,chunk,eof)
		if not fd then
			if (not meta) or (not meta.name) or (not meta.file) then return end
			fd=nixio.open(cert_dir..meta.file,"w")
			if not fd then
				path=translate("Create upload file error")
				return
			end
		end
		if chunk and fd then
			fd:write(chunk)
		end
		if eof and fd then
			fd:close()
			fd=nil
			path='/etc/ssl/private/'..meta.file..''
		end
	end
)

if luci.http.formvalue("upload") then
	local f=luci.http.formvalue("ulfile")
	if #f<=0 then
		path=translate("No specify upload file")
	end
end

o=s:option(Value,"certpath",translate("Current Certificate Path"))
o.default=cert_dir
o.description=translate("Please confirm the current certificate path")
o:value(cert_dir)
o:depends("certificate",1)

o=s:option(Flag,"mux",translate("Mux"))
o:depends("type","vmess")
o:depends({type="vless",xtls=0})

o=s:option(Value,"concurrency",translate("Concurrency"))
o.datatype="uinteger"
o.default=8
o:depends("mux",1)

o=s:option(Flag,"fast_open",translate("TCP Fast Open"))
o:depends("type","ssr")
o:depends("type","ss")
o:depends("type","trojan")

o=s:option(Flag,"switch_enable",translate("Enable Auto Switch"))

o=s:option(Value,"local_port",translate("Local Port"))
o.datatype="port"
o.placeholder=1234

if nixio.fs.access("/usr/bin/kcptun-client") then
o=s:option(Flag,"kcp_enable",translate("KcpTun Enable"))
o:depends("type","ssr")
o:depends("type","ss")

o=s:option(Value,"kcp_port",translate("KcpTun Port"))
o.datatype="port"
o.default=4000
o:depends("kcp_enable",1)

o=s:option(Value,"kcp_password",translate("KcpTun Password"))
o.password=true
o:depends("kcp_enable",1)

o=s:option(Value,"kcp_param",translate("KcpTun Param"))
o.default="--nocomp"
o:depends("kcp_enable",1)
end

return m
