local m,s,o
local ov="overwall"
local sid=arg[1]
local A=luci.sys.call("which obfs-server >/dev/null")
local B=luci.sys.call("which xray-plugin >/dev/null")
local C=luci.sys.call("which ss-server >/dev/null")
local D=luci.sys.call("which xray >/dev/null")

local encrypt_methods_ss={
"aes-128-gcm",
"aes-192-gcm",
"aes-256-gcm",
"chacha20-ietf-poly1305",
"xchacha20-ietf-poly1305"
}

local encrypt_methods_ss2022={
"2022-blake3-aes-128-gcm",
"2022-blake3-aes-256-gcm",
"2022-blake3-chacha20-poly1305"
}

local encrypt_methods={
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

local protocol={
"origin",
}

local obfs={
"plain",
"http_simple",
"http_post",
"tls1.2_ticket_auth",
}

m=Map(ov,translate("Edit Overwall Server"))
m.redirect=luci.dispatcher.build_url("admin/services/overwall/server")
if m.uci:get(ov,sid)~="server_config" then
	luci.http.redirect(m.redirect)
	return
end

s=m:section(NamedSection,sid,"server_config")
s.anonymous=true
s.addremove=false

o=s:option(Flag,"enable",translate("Enable"))

o=s:option(ListValue,"type",translate("Server Type"))
if C==0 or D==0 then
	o:value("ss",translate("Shadowsocks"))
end
if luci.sys.call("which ssr-server >/dev/null")==0 then
	o:value("ssr",translate("ShadowsocksR"))
end
if luci.sys.call("which microsocks >/dev/null")==0 then
o:value("socks5",translate("Socks5"))
end

o=s:option(Value,"server_port",translate("Server Port"))
o.datatype="port"
math.randomseed(tostring(os.time()):reverse():sub(1,7))
o.default=math.random(10240,20480)
o.rmempty=false
o.description=translate("Warning! Please do not reuse the port!")

o=s:option(Flag,"auth_enable",translate("Enable Authentication"))
o:depends("type","socks5")

o=s:option(Flag,"auth_once",translate("Enable Once Auth Mode"),
translate("Enable Once Auth,the client IP that passed the authentication will be added to the whitelist address, this IP no longer needs to be verified"))
o:depends("auth_enable",1)

o=s:option(Value,"username",translate("Username"))
o:depends("auth_enable",1)

o=s:option(Value,"password",translate("Password"))
o.password=true
o:depends("type","ssr")
o:depends("type","ss")
o:depends("auth_enable",1)

o=s:option(ListValue,"encrypt_method_ss",translate("Encrypt Method"))
if C==0 then
for _,v in ipairs(encrypt_methods_ss) do o:value(v) end
end
if D==0 then
for _,v in ipairs(encrypt_methods_ss2022) do o:value(v) end
end
o:depends("type","ss")

if A==0 or B==0 then
o=s:option(ListValue,"plugin",translate("Plugin"))
o:value("",translate("Disable"))
if A==0 then
o:value("obfs-server",translate("simple-obfs"))
end
if B==0 then
o:value("xray-plugin",translate("xray-plugin"))
end
o:depends("type","ss")
end

o=s:option(Value,"plugin_opts",translate("Plugin Opts"))
o:depends("plugin","obfs-server")
o:depends("plugin","xray-plugin")

o=s:option(ListValue,"encrypt_method",translate("Encrypt Method"))
for _,v in ipairs(encrypt_methods) do o:value(v) end
o:depends("type","ssr")

o=s:option(ListValue,"protocol",translate("Protocol"))
for _,v in ipairs(protocol) do o:value(v) end
o:depends("type","ssr")

o=s:option(ListValue,"obfs",translate("Obfs"))
for _,v in ipairs(obfs) do o:value(v) end
o:depends("type","ssr")

o=s:option(Value,"obfs_param",translate("Obfs param(optional)"))
o:depends("type","ssr")

o=s:option(Value,"timeout",translate("Connection Timeout"))
o.datatype="uinteger"
o.placeholder=60
o:depends("type","ss")
o:depends("type","ssr")

o=s:option(Flag,"fast_open",translate("TCP Fast Open"))
o:depends("type","ss")
o:depends("type","ssr")

return m
