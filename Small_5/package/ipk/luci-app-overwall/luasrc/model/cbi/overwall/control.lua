local m,s,o

m=Map("overwall",translate("IP Access Control"))
s=m:section(TypedSection,"access_control")
s.anonymous=true

s:tab("wan_ac",translate("WAN IP AC"))

o=s:taboption("wan_ac",DynamicList,"wan_bp_ips",translate("WAN White List IP"))
o.datatype="ip4addr"

o=s:taboption("wan_ac",DynamicList,"wan_fw_ips",translate("Proxy IP by Main Server"))
o.datatype="ip4addr"

s:tab("lan_ac",translate("LAN IP AC"))

o=s:taboption("lan_ac",ListValue,"lan_ac_mode",translate("LAN Access Control"))
o:value("w",translate("Allow listed only"))
o:value("b",translate("Allow all except listed"))
o.rmempty=false

o=s:taboption("lan_ac",DynamicList,"lan_ac_ips",translate("LAN Host List"))
o.datatype="ipmask"
luci.ip.neighbors({family=0},function(entry)
	if entry.reachable then
		o:value(entry.dest:string())
	end
end)
o:depends("lan_ac_mode","w")
o:depends("lan_ac_mode","b")

o=s:taboption("lan_ac",DynamicList,"lan_fp_ips",translate("LAN Force Proxy Host List"))
o.datatype="ipaddr"
luci.ip.neighbors({family=4},function(entry)
	if entry.reachable then
		o:value(entry.dest:string())
	end
end)

o=s:taboption("lan_ac",DynamicList,"lan_gm_ips",translate("Game Mode Host List"))
o.datatype="ipaddr"
luci.ip.neighbors({family=4},function(entry)
	if entry.reachable then
		o:value(entry.dest:string())
	end
end)

s:tab("yb_ac",translate("Youtube IP AC"))

o=s:taboption("yb_ac",DynamicList,"yb_fw_ips",translate("Proxy IP by Youtube Server"))
o.datatype="ip4addr"

s:tab("nf_ac",translate("Netflix IP AC"))

o=s:taboption("nf_ac",DynamicList,"nf_fw_ips",translate("Proxy IP by Netflix Server"))
o.datatype="ip4addr"

s:tab("cu_ac",translate("Custom IP AC"))

o=s:taboption("cu_ac",DynamicList,"cu_fw_ips",translate("Proxy IP by Custom Server"))
o.datatype="ip4addr"

s:tab("tg_ac",translate("Telegram IP AC"))

o=s:taboption("tg_ac",DynamicList,"tg_fw_ips",translate("Proxy IP by Telegram Server")
,translate("Telegram IP ranges has been proxied by default,No need to add"))
o.datatype="ip4addr"

return m
