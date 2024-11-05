module("luci.controller.vlmcsd",package.seeall)
fs=require"nixio.fs"
http=require"luci.http"
function index()
	if not nixio.fs.access("/etc/config/vlmcsd") then
		return
	end
	local e=entry({"admin","services","vlmcsd"},firstchild(),_("KMS Server"),100)
	e.dependent=false
	e.acl_depends={"luci-app-vlmcsd"}
	entry({"admin","services","vlmcsd","base"},cbi("vlmcsd/base"),_("Base Setting"),10).leaf=true
	entry({"admin","services","vlmcsd","config"},form("vlmcsd/config"),_("Config File"),20).leaf=true
	entry({"admin","services","vlmcsd","log"},form("vlmcsd/log"),_("Log"),30).leaf=true
	entry({"admin","services","vlmcsd","run"},call("act_status"))
	entry({"admin","services","vlmcsd","getlog"},call("getlog"))
	entry({"admin","services","vlmcsd","dellog"},call("dellog"))
end

function act_status()
	local e={}
	e.running=luci.sys.call("pgrep /usr/bin/vlmcsd >/dev/null")==0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function getlog()
	logfile="/var/log/vlmcsd"
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
	fs.writefile("/var/log/vlmcsd","")
	http.write('')
end
