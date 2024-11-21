module("luci.controller.n2n-supernode",package.seeall)
function index()
	if not nixio.fs.access("/etc/config/n2n-supernode") then
		return
	end
	entry({"admin","vpn"},firstchild(),"VPN",45).dependent=false
	local e=entry({"admin","vpn","n2n-supernode"},firstchild(),_("N2N Supernode"),2)
	e.dependent=false
	e.acl_depends={"luci-app-n2n-supernode"}
	entry({"admin","vpn","n2n-supernode"},cbi("n2n-supernode"),_("N2N Supernode"),1)
	entry({"admin","vpn","n2n-supernode","run"},call("act_status")).leaf=true
end

function act_status()
	local e={}
	e.running=luci.sys.call("pidof supernode >/dev/null")==0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
