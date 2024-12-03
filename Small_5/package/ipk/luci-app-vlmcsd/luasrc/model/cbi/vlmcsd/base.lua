m=Map("vlmcsd")
m.title=translate("KMS Server Settings")
m.description=translate("A KMS Serever Emulator to active your Windows or Office<br/>Current Version").."<b><font color=\"green\">: "..luci.sys.exec("vlmcsd -V | awk '{print $2}' | sed -n 1p | sed 's/,$//'").."</font></b>"
m:section(SimpleSection).template="vlmcsd/vlmcsd_status"

s=m:section(TypedSection,"vlmcsd")
s.anonymous=true

o=s:option(Flag,"enabled")
o.title=translate("Enable")
o.default=1
o.rmempty=false

o=s:option(Flag,"auto")
o.title=translate("Auto activate")
o.default=1
o.rmempty=false

o=s:option(Flag,"conf")
o.title=translate("Use Config File")
o.rmempty=false

o=s:option(ListValue,"log",translate("Empty Log File"))
o.default=7
for i,v in pairs({[7]="disable",[0]="Sun",[1]="Mon",[2]="Tue",[3]="Wed",[4]="Thu",[5]="Fri",[6]="Sat"}) do
	if v~="disable" then
		o:value(i,translate("Every")..translate(v))
	else
		o:value(i,translate(v))
	end
end

o=s:option(Value,"port")
o.title=translate("Local Port")
o.datatype="port"
o.placeholder=1688

return m
