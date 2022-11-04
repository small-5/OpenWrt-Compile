module("luci.controller.overwall",package.seeall)
local fs=require"nixio.fs"
local http=require"luci.http"
CALL=luci.sys.call
EXEC=luci.sys.exec
A="/usr/share/overwall/curl"
function index()
	if not nixio.fs.access("/etc/config/overwall") then
		return
	end
	local e=entry({"admin","services","overwall"},firstchild(),_("Overwall"),2)
	e.dependent=false
	e.acl_depends={"luci-app-overwall"}
	entry({"admin","services","overwall","base"},cbi("overwall/base"),_("Base Setting"),1).leaf=true
	entry({"admin","services","overwall","servers"},arcombine(cbi("overwall/servers",{autoapply=true}),cbi("overwall/client-config")),_("Severs Nodes"),2).leaf=true
	entry({"admin","services","overwall","shunt"},cbi("overwall/shunt"),_("Shunt Setting"),3).leaf=true
	entry({"admin","services","overwall","control"},cbi("overwall/control"),_("Access Control"),4).leaf=true
	entry({"admin","services","overwall","domain"},cbi("overwall/domain"),_("Domain List"),5).leaf=true
	entry({"admin","services","overwall","advanced"},cbi("overwall/advanced"),_("Advanced Settings"),6).leaf=true
	if luci.sys.call("which ssr-server >/dev/null")==0 or luci.sys.call("which ss-server >/dev/null")==0 or luci.sys.call("which microsocks >/dev/null")==0 then
		entry({"admin","services","overwall","server"},arcombine(cbi("overwall/server"),cbi("overwall/server-config")),_("Overwall Server"),7).leaf=true
	end
	entry({"admin","services","overwall","auth"},cbi("overwall/auth"),_("Authorization Code"),8).leaf=true
	entry({"admin","services","overwall","log"},form("overwall/log"),_("Log"),9).leaf=true
	if luci.sys.call("/usr/share/overwall/curl A")==0 then
		entry({"admin","services","overwall","auth_page"},form("overwall/auth_page"),_("Auth Page"),10).leaf=true
	end
	entry({"admin","services","overwall","status"},call("status"))
	entry({"admin","services","overwall","check"},call("check"))
	entry({"admin","services","overwall","ip"},call("ip"))
	entry({"admin","services","overwall","refresh"},call("refresh"))
	entry({"admin","services","overwall","subscribe"},call("subscribe"))
	entry({"admin","services","overwall","checksrv"},call("checksrv"))
	entry({"admin","services","overwall","ping"},call("ping"))
	entry({"admin","services","overwall","getlog"},call("getlog"))
	entry({"admin","services","overwall","dellog"},call("dellog"))
	entry({"admin","services","overwall","hard_code"},call("hard_code"))
	entry({"admin","services","overwall","getlog_auth"},call("getlog_auth"))
	entry({"admin","services","overwall","dellog_auth"},call("dellog_auth"))
	entry({"admin","services","overwall","decrypt"},call("decrypt"))
	entry({"admin","services","overwall","encrypt"},call("encrypt"))
	entry({"admin","services","overwall","hc_list"},call("hc_list"))
	entry({"admin","services","overwall","add_code"},call("add_code"))
	entry({"admin","services","overwall","rp_code"},call("rp_code"))
	entry({"admin","services","overwall","del_code"},call("del_code"))
	entry({"admin","services","overwall","get_code"},call("get_code"))
	entry({"admin","services","overwall","ref"},call("ref"))
end

function status()
	local e={}
	e.tcp=CALL("ps -w | grep overwall-tcp | grep -qv grep")==0
	e.udp=CALL("ps -w | grep overwall-udp | grep -qv grep")==0
	e.yb=CALL("ps -w | grep overwall.*yb | grep -qv grep")==0
	e.nf=CALL("ps -w | grep overwall.*nf | grep -qv grep")==0
	e.cu=CALL("ps -w | grep overwall.*cu | grep -qv grep")==0
	e.tg=CALL("ps -w | grep overwall.*tg | grep -qv grep")==0
	e.dns=CALL("pidof smartdns >/dev/null")==0
	e.ng=CALL("pidof chinadns-ng >/dev/null")==0
	e.socks5=CALL("ps -w | grep overwall.*socks5 | grep -qv grep")==0
	e.srv=CALL("ps -w | grep overwall-server | grep -qv grep")==0
	e.kcp=CALL("pidof kcptun-client >/dev/null")==0
	http.prepare_content("application/json")
	http.write_json(e)
end

function check()
	local r=0
	local u=http.formvalue("url")
	if u=="1" then
		u="www.jd.com"
	else
		u="www.google.com/generate_204"
	end
	if CALL("curl -m 5 -so /dev/null https://"..u)==0 then
		r=EXEC("curl -m 5 -o /dev/null -sw %{time_starttransfer} http://"..u.." | awk '{printf ($1*1000/2)}'")
		if r~="0" then
			r=EXEC("echo -n "..r.." | sed 's/\\..*//'")
			if r=="0" then r="1" end
		end
	end
	http.prepare_content("application/json")
	http.write_json({ret=r})
end

function ip()
	local r
	if http.formvalue("set")=="0" then
		r=EXEC("cat /tmp/etc/overwall.include | grep -Eo '[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}' | sed -n 1p")
	else
		r=EXEC("curl -Lsm 5 https://www.cloudflare.com/cdn-cgi/trace | grep ip= | cut -d = -f2")
	end
	http.prepare_content("application/json")
	http.write_json({ret=r})
end

function refresh()
	local set=http.formvalue("set")
	local i=0
	local r
	if set=="0" then
		if CALL(A..' 0 Overwall/rules/gfw /tmp/gfw.b64 "--retry 3 --retry-all-errors -Lfso"')==0 then
			EXEC("/usr/share/overwall/gfw")
			i=EXEC("cat /tmp/gfwnew.txt | wc -l")
			if tonumber(i)>1000 then
				if CALL("cmp -s /tmp/gfwnew.txt /tmp/overwall/gfw.list")==0 then
					r="0"
				else
					EXEC("cp -f /tmp/gfwnew.txt /tmp/overwall/gfw.list && /etc/init.d/overwall restart >/dev/null 2>&1")
					r=tostring(tonumber(i))
				end
			else
				r="-1"
			end
		else
			r="-1"
		end
		EXEC("rm -f /tmp/gfwnew.txt")
	elseif set=="1" then
		if CALL(A..' 0 Overwall/rules/IPv4 /tmp/ipv4.tmp "--retry 3 --retry-all-errors -Lfso"')==0 then
			EXEC("cat /tmp/ipv4.tmp | base64 -d > /tmp/ipv4.txt")
			i=EXEC("cat /tmp/ipv4.txt | wc -l")
			if tonumber(i)>1000 then
				if CALL("cmp -s /tmp/ipv4.txt /tmp/overwall/ipv4.txt")==0 then
					r="0"
				else
					EXEC("cp -f /tmp/ipv4.txt /tmp/overwall/ipv4.txt && ipset list over_v4 >/dev/null 2>&1 && /usr/share/overwall/ipset")
					r=tostring(tonumber(i))
				end
			else
				r="-1"
			end
		else
			r="-1"
		end
		EXEC("rm -f /tmp/ipv4.txt /tmp/ipv4.tmp")
	elseif set=="2" then
		if CALL(A..' 0 Overwall/rules/IPv6 /tmp/ipv6.tmp "--retry 3 --retry-all-errors -Lfso"')==0 then
			EXEC("cat /tmp/ipv6.tmp | base64 -d > /tmp/ipv6.txt")
			i=EXEC("cat /tmp/ipv6.txt | wc -l")
			if tonumber(i)>1000 then
				if CALL("cmp -s /tmp/ipv6.txt /tmp/overwall/ipv6.txt")==0 then
					r="0"
				else
					EXEC("cp -f /tmp/ipv6.txt /tmp/overwall/ipv6.txt && ipset list over_v6 >/dev/null 2>&1 && /usr/share/overwall/ipset v6")
					r=tostring(tonumber(i))
				end
			else
				r="-1"
			end
		else
			r="-1"
		end
		EXEC("rm -f /tmp/ipv6.txt /tmp/ipv6.tmp")
	end
	http.prepare_content("application/json")
	http.write_json({ret=r})
end

function subscribe()
	CALL("/usr/share/overwall/subscribe")
	http.prepare_content("application/json")
	http.write_json({ret=1})
end

function checksrv()
	local r="<br/>"
	local s,n
	luci.model.uci.cursor():foreach("overwall","servers",function(s)
		if s.alias then
			n=s.alias
		elseif s.server and s.server_port then
			n="%s:%s"%{s.server,s.server_port}
		end
		local dp=EXEC("netstat -unl | grep -q :5336 && echo -n 5336 || echo -n 53")
		local ip=EXEC("echo "..s.server.." | grep -E ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$ || \\\
		nslookup "..s.server.." 127.0.0.1:"..dp.." 2>/dev/null | grep Address | awk -F' ' '{print$NF}' | grep -E ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$ | sed -n 1p")
		ip=EXEC("echo -n "..ip)
		local iret=CALL("ipset add over_wan_ac "..ip.." 2>/dev/null")
		local t=EXEC(string.format("tcping -q -c 1 -i 1 -t 2 -p %s %s 2>&1 | grep -o 'time=[0-9]*' | awk -F '=' '{print $2}'",s.server_port,ip))
		if t~='' then
			if tonumber(t)<100 then
				col='#2dce89'
			elseif tonumber(t)<200 then
				col='#fb9a05'
			else
				col='#fb6340'
			end
			r=r..'<font color="'..col..'">['..string.upper(s.type)..'] ['..n..'] '..t..' ms</font><br/>'
		else
			r=r..'<font color="red">['..string.upper(s.type)..'] ['..n..'] ERROR</font><br/>'
		end
		if iret==0 then CALL("ipset del over_wan_ac "..ip) end
	end)
	http.prepare_content("application/json")
	http.write_json({ret=r})
end

function ping()
	local e={}
	local domain=http.formvalue("domain")
	local port=http.formvalue("port")
	local dp=EXEC("netstat -unl | grep -q :5336 && echo -n 5336 || echo -n 53")
	local ip=EXEC("echo "..domain.." | grep -E ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$ || \\\
	nslookup "..domain.." 127.0.0.1:"..dp.." 2>/dev/null | grep Address | awk -F' ' '{print$NF}' | grep -E ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$ | sed -n 1p")
	ip=EXEC("echo -n "..ip)
	local iret=CALL("ipset add over_wan_ac "..ip.." 2>/dev/null")
	e.ping=EXEC(string.format("tcping -q -c 1 -i 1 -t 2 -p %s %s 2>&1 | grep -o 'time=[0-9]*' | awk -F '=' '{print $2}'",port,ip))
	if (iret==0) then
		CALL("ipset del over_wan_ac "..ip)
	end
	http.prepare_content("application/json")
	http.write_json(e)
end

function getlog()
	logfile="/tmp/overwall.log"
	if not fs.access(logfile) then
		http.write('')
		return
	end
	local f=io.open(logfile,"r")
	local a=f:read("*a") or ""
	f:close()
	a=string.gsub(a,"\n$","")
	http.prepare_content("text/plain;charset=utf-8")
	http.write(a)
end

function dellog()
	fs.writefile("/tmp/overwall.log","")
	http.write('')
end

function hard_code()
	CALL(A.." 3")
	getlog()
end

function getlog_auth()
	logfile="/tmp/overauth.log"
	if not fs.access(logfile) then
		http.write('')
		return
	end
	local f=io.open(logfile,"r")
	local a=f:read("*a") or ""
	f:close()
	a=string.gsub(a,"\n$","")
	http.prepare_content("text/plain;charset=utf-8")
	http.write(a)
end

function dellog_auth()
	fs.writefile("/tmp/overauth.log","")
	http.write('')
end

function decrypt()
	CALL(A.." 4")
	getlog_auth()
end

function encrypt()
	CALL(A.." 5 '"..http.formvalue("code").."'")
	getlog_auth()
end

function hc_list()
	CALL(A.." 6")
	getlog_auth()
end

function add_code()
	CALL(A.." 7 '"..http.formvalue("code").."'")
	getlog_auth()
end

function rp_code()
	CALL(A.." 8 '"..http.formvalue("a").." "..http.formvalue("b").."'")
	getlog_auth()
end

function del_code()
	CALL(A.." 9 '"..http.formvalue("code").."'")
	getlog_auth()
end

function get_code()
	CALL(A.." a '"..http.formvalue("code").."'")
	getlog_auth()
end

function ref()
	CALL(A.." b")
	getlog_auth()
end
