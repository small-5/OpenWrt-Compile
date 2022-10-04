local m,s,o
local ov="overwall"
local uci=luci.model.uci.cursor()
local server_count=0
local SYS=require"luci.sys"

uci:foreach(ov,"servers",function(s)
	server_count=server_count+1
end)

m=Map(ov,translate("Servers subscription and manage"))
s=m:section(TypedSection,"server_subscribe")
s.anonymous=true

o=s:option(Flag,"auto_update",translate("Auto Update"))
o.description=translate("Auto Update CHN route and GFW list")

o=s:option(Flag,"auto_update_s",translate("Auto Update"))
o.description=translate("Auto Update Server subscription")

o=s:option(ListValue,"auto_update_time",translate("Update time (every day)"))
for t=0,23 do
	o:value(t,t..":00")
end
o.default=2
o.rmempty=false

o=s:option(DynamicList,"subscribe_url",translate("Subscribe URL"))
o.rmempty=true
o.description=translate("Support SS/SSR/VMESS/VLESS/TROJAN")

o=s:option(ListValue,"filter_mode",translate("Filter Words Mode"))
o:value("",translate("Discard Mode"))
o:value(1,translate("Keep Mode"))

o=s:option(Value,"filter_words",translate("Subscribe Filter Words"))
o.rmempty=true
o.description=translate("Filter Words splited by /")

o=s:option(Flag,"switch",translate("Subscribe Default Auto-Switch"))
o.description=translate("Subscribe new add server default Auto-Switch on")

o=s:option(Flag,"proxy",translate("Through proxy update"))
o.description=translate("Through proxy update list,Not Recommended")

o=s:option(Button,"update_Sub",translate("Update Subscribe Settings"))
o.inputstyle="reload"
o.description=translate("After modify the subscribe URL and settings,click this button first")
o.write=function()
	SYS.call("touch /var/lock/overwall-uci.lock")
	uci:commit(ov)
	luci.http.redirect(luci.dispatcher.build_url("admin","services",ov,"servers"))
end

o=s:option(Button,"subscribe",translate("Update All Subscribe Severs"))
o.rawhtml=true
o.template="overwall/subscribe"

o=s:option(Button,"delete",translate("Delete All Subscribe Severs"))
o.inputstyle="reset"
o.description=string.format(translate("Server Count")..": %d",server_count)
o.write=function()
	uci:delete_all(ov,"servers",function(s)
		if s.hashkey or s.isSubscribe then
			return true
		else
			return false
		end
	end)
	SYS.call("touch /var/lock/overwall-uci.lock")
	uci:commit(ov)
	if SYS.call("uci -q get overwall."..SYS.exec("echo -n $(uci -q get overwall.@global[0].global_server)")..".server >/dev/null")==1 then
		SYS.exec("/etc/init.d/overwall stop &")
	end
	luci.http.redirect(luci.dispatcher.build_url("admin","services",ov,"servers"))
end

s=m:section(TypedSection,"servers")
s.anonymous=true
s.addremove=true
s.template="cbi/tblsection"
s.sortable=true
s.extedit=luci.dispatcher.build_url("admin","services",ov,"servers","%s")
function s.create(...)
	local sid=TypedSection.create(...)
	if sid then
		uci:set(ov,sid,'switch_enable',1)
		luci.http.redirect(s.extedit%sid)
		return
	end
end

o=s:option(DummyValue,"type",translate("Type"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) and string.upper(Value.cfgvalue(...))
end

o=s:option(DummyValue,"alias",translate("Alias"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

o=s:option(DummyValue,"server_port",translate("Server Port"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "N/A"
end

o=s:option(DummyValue,"server",translate("TCPing Latency"))
o.template="overwall/server"
o.width="10%"

o=s:option(DummyValue,"server_port",translate("Result"))
o.template="overwall/port"
o.width="10%"

o=s:option(Button,"apply_node",translate("Apply"))
o.inputstyle="apply"
o.write=function(self,section)
	uci:set(ov,'@global[0]','global_server',section)
	uci:commit(ov)
	luci.http.redirect(luci.dispatcher.build_url("admin","services",ov,"base"))
end

o=s:option(Flag,"switch_enable",translate("Auto Switch"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or 0
end

m:append(Template("overwall/server_list"))

return m
