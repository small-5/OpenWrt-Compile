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
local icount=0

if set=="0" then
	a=EXEC("echo -n $(lua /usr/share/adblock/auth A)/ad-rules")
	b=EXEC("echo -n $(lua /usr/share/adblock/auth B)")
	c=EXEC("echo -n $(lua /usr/share/adblock/auth C)")
	sret=CALL("curl -m 20 -Lfso /tmp/ad.conf -A \""..b.."\" "..a.."/dnsmasq.adblock"..c)
	if sret==0 then
		CALL("/usr/share/adblock/adblock gen")
		icount=EXEC("cat /tmp/ad.conf | wc -l")
		if tonumber(icount)>0 then
			oldcount=EXEC("cat /tmp/adblock/adblock.conf | wc -l")
			if tonumber(icount) ~= tonumber(oldcount) then
				EXEC("mv -f /tmp/ad.conf /tmp/adblock/adblock.conf")
				EXEC("/etc/init.d/dnsmasq restart &")
				retstring=tostring(math.ceil(tonumber(icount)))
			else
				retstring=0
			end
			CALL("echo `date +'%Y-%m-%d %H:%M:%S'` > /tmp/adblock/adblock.updated")
		else
			retstring="-1"
		end
		EXEC("rm -f /tmp/ad.conf")
	else
		retstring="-1"
	end
else
	EXEC("/usr/share/adblock/adblock down")
	icount=EXEC("find /tmp/ad_tmp/3rd -name 3* -exec cat {} \\; 2>/dev/null | wc -l")
	if tonumber(icount)>0 then
		oldcount=EXEC("find /tmp/adblock/3rd -name 3* -exec cat {} \\; 2>/dev/null | wc -l")
		if tonumber(icount) ~= tonumber(oldcount) then
			EXEC("[ -h /tmp/adblock/3rd/url ] && (rm -f /etc/adblock/3rd/*;cp -a /tmp/ad_tmp/3rd /etc/adblock) || (rm -f /tmp/adblock/3rd/*;cp -a /tmp/ad_tmp/3rd /tmp/adblock)")
			EXEC("/etc/init.d/adblock restart &")
			retstring=tostring(math.ceil(tonumber(icount)))
		else
			retstring=0
		end
		CALL("echo `date +'%Y-%m-%d %H:%M:%S'` > /tmp/adblock/adblock.updated")
	else
		retstring="-1"
	end
	EXEC("rm -rf /tmp/ad_tmp")
end
	luci.http.prepare_content("application/json")
	luci.http.write_json({ret=retstring,retcount=icount})
end
