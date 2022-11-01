local fs=require"nixio.fs"
local f,t
f=SimpleForm("logview")
f.reset=false
f.submit=false
t=f:field(TextValue,"conf")
t.rmempty=true
t.rows=20
t.template="overwall/auth_page"
t.readonly="readonly"

return f
