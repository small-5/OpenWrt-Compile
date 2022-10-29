module("luci.controller.adblock",package.seeall)
CALL=luci.sys.call
EXEC=luci.sys.exec
function index()
	if not nixio.fs.access("/etc/config/adblock") then
		return
	end
	local e=entry({"admin","services","adblock"},firstchild(),_("Adblock Plus+"),1)
	e.dependent=false
	e.acl_depends={"luci-app-adblock-plus"}
	entry({"admin","services","adblock","base"},cbi("adblock/base"),_("Base Setting"),1).leaf=true
	entry({"admin","services","adblock","white"},form("adblock/white"),_("White Domain List"),2).leaf=true
	entry({"admin","services","adblock","black"},form("adblock/black"),_("Block Domain List"),3).leaf=true
	entry({"admin","services","adblock","ip"},form("adblock/ip"),_("Block IP List"),4).leaf=true
	entry({"admin","services","adblock","log"},form("adblock/log"),_("Update Log"),5).leaf=true
	entry({"admin","services","adblock","run"},call("act_status"))
	entry({"admin","services","adblock","refresh"},call("refresh_data"))
end

function act_status()
	local e={}
	e.running=CALL("[ -s /tmp/dnsmasq.adblock/adblock.conf ]")==0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function refresh_data()
local set=luci.http.formvalue("set")
local i=0

if set=="0" then
	if CALL("/usr/share/overwall/curl 0 ad-rules/dnsmasq.adblock /tmp/ad.conf '-Lfsm 20 -o'")==0 then
		CALL("/usr/share/adblock/adblock gen")
		i=EXEC("cat /tmp/ad.conf | wc -l")
		if tonumber(i)>0 then
			if CALL("cmp -s /tmp/ad.conf /tmp/adblock/adblock.conf")==0 then
				r=0
			else
				EXEC("mv -f /tmp/ad.conf /tmp/adblock/adblock.conf")
				EXEC("/etc/init.d/dnsmasq restart &")
				r=tostring(math.ceil(tonumber(i)))
			end
			CALL("echo `date +'%Y-%m-%d %H:%M:%S'` > /tmp/adblock/adblock.updated")
		else
			r="-1"
		end
		EXEC("rm -f /tmp/ad.conf")
	else
		r="-1"
	end
else
	EXEC("/usr/share/adblock/adblock down")
	i=EXEC("find /tmp/ad_tmp/3rd -name 3* -exec cat {} \\; 2>/dev/null | wc -l")
	if tonumber(i)>0 then
		if CALL("cmp -s /tmp/ad_tmp/3rd/3rd.conf /tmp/adblock/3rd/3rd.conf")==0 then
			r=0
		else
			EXEC("[ -h /tmp/adblock/3rd/url ] && (rm -f /etc/adblock/3rd/*;cp -a /tmp/ad_tmp/3rd /etc/adblock) || (rm -f /tmp/adblock/3rd/*;cp -a /tmp/ad_tmp/3rd /tmp/adblock)")
			EXEC("/etc/init.d/adblock restart &")
			r=tostring(math.ceil(tonumber(i)))
		end
		CALL("echo `date +'%Y-%m-%d %H:%M:%S'` > /tmp/adblock/adblock.updated")
	else
		r="-1"
	end
	EXEC("rm -rf /tmp/ad_tmp")
end
	luci.http.prepare_content("application/json")
	luci.http.write_json({ret=r,retcount=i})
end
