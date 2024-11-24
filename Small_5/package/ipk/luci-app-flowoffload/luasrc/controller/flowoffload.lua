module("luci.controller.flowoffload",package.seeall)
function index()
	if not nixio.fs.access("/etc/config/flowoffload") then
		return
	end
	local e=entry({"admin","network","flowoffload"},cbi("flowoffload"),_("Turbo ACC Center"))
	e.dependent=false
	e.acl_depends={"luci-app-flowoffload"}
	entry({"admin","network","flowoffload","status"},call("act_status"))
end

local function is_1()
	return luci.sys.call("[ `cat /sys/module/nft_flow_offload/refcnt 2>/dev/null` -gt 0 ] 2>/dev/null")==0
end

local function is_2()
	return luci.sys.call("[ `cat /sys/module/nft_fullcone/refcnt 2>/dev/null` -gt 0 ] 2>/dev/null")==0
end

local function is_3()
	return luci.sys.call("sysctl net.ipv4.tcp_congestion_control | grep bbr >/dev/null")==0
end

function act_status()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		state_1=is_1(),
		state_2=is_2(),
		state_3=is_3()
	})
end
