local fs=require "nixio.fs"
local m,s,o
local white_f=string.format("/etc/overwall/white.list")
local di_f=string.format("/etc/overwall/direct.list")
local main_f=string.format("/etc/overwall/black.list")
local yb_f=string.format("/etc/overwall/youtube.list")
local nf_f=string.format("/etc/overwall/netflix.list")
local cu_f=string.format("/etc/overwall/custom.list")
local ov_f=string.format("/etc/overwall/oversea.list")
local ex_f=string.format("/etc/overwall/excluded.list")
local pre_f=string.format("/etc/overwall/preload.list")
local cname_f=string.format("/etc/overwall/cname.list")

m=Map("overwall",translate("Domain List"))
s=m:section(TypedSection,"global")
s.anonymous=true

m.apply_on_parse=true
function m.on_apply(self)
	luci.sys.exec("/etc/init.d/overwall reload &")
end

s:tab("white",translate("Direct Domain List"))

o=s:taboption("white",TextValue,"white_f","",translate("Direct Domain List"))
o.rows=15
o.wrap="off"
o.cfgvalue=function(self,section) return fs.readfile(white_f) or "" end
o.write=function(self,section,value) fs.writefile(white_f,value:gsub("\r\n","\n")) end
o.remove=function(self,section,value) fs.writefile(white_f,"") end
o.validate=function(self,value)
    local hosts={}
    string.gsub(value,'[^'.."\r\n"..']+',function(w) table.insert(hosts,w) end)
    for index,host in ipairs(hosts) do
        if not datatypes.hostname(host) then
            return nil,host.." "..translate("Not valid domain name!")
        end
    end
    return value
end

s:tab("direct",translate("Direct Domain List(For Vmess/Vless/SS2022)"))

o=s:taboption("direct",TextValue,"di_f","",translate("When using Vmess/VLESS/SS2022, this list is used first and clear the Direct Domain List"))
o.rows=15
o.wrap="off"
o.cfgvalue=function(self,section) return fs.readfile(di_f) or "" end
o.write=function(self,section,value) fs.writefile(di_f,value:gsub("\r\n","\n")) end
o.remove=function(self,section,value) fs.writefile(di_f,"") end
o.validate=function(self,value)
    local hosts={}
    string.gsub(value,'[^'.."\r\n"..']+',function(w) table.insert(hosts,w) end)
    for index,host in ipairs(hosts) do
        if not datatypes.hostname(host) then
            return nil,host.." "..translate("Not valid domain name!")
        end
    end
    return value
end

s:tab("main",translate("Main Server Domain List"))

o=s:taboption("main",TextValue,"main_f","",translate("Main Server Domain List"))
o.rows=15
o.wrap="off"
o.cfgvalue=function(self,section) return fs.readfile(main_f) or "" end
o.write=function(self,section,value) fs.writefile(main_f,value:gsub("\r\n","\n")) end
o.remove=function(self,section,value) fs.writefile(main_f,"") end
o.validate=function(self,value)
    local hosts={}
    string.gsub(value,'[^'.."\r\n"..']+',function(w) table.insert(hosts,w) end)
    for index,host in ipairs(hosts) do
        if not datatypes.hostname(host) then
            return nil,host.." "..translate("Not valid domain name!")
        end
    end
    return value
end

s:tab("yb",translate("Youtube Domain List"))

o=s:taboption("yb",TextValue,"yb_f","",translate("Youtube Domain List"))
o.rows=15
o.wrap="off"
o.cfgvalue=function(self,section) return fs.readfile(yb_f) or "" end
o.write=function(self,section,value) fs.writefile(yb_f,value:gsub("\r\n","\n")) end
o.remove=function(self,section,value) fs.writefile(yb_f,"") end
o.validate=function(self,value)
    local hosts={}
    string.gsub(value,'[^'.."\r\n"..']+',function(w) table.insert(hosts,w) end)
    for index,host in ipairs(hosts) do
        if not datatypes.hostname(host) then
            return nil,host.." "..translate("Not valid domain name!")
        end
    end
    return value
end

s:tab("nf",translate("Netflix Domain List"))

o=s:taboption("nf",TextValue,"nf_f","",translate("Netflix Domain List"))
o.rows=15
o.wrap="off"
o.cfgvalue=function(self,section) return fs.readfile(nf_f) or "" end
o.write=function(self,section,value) fs.writefile(nf_f,value:gsub("\r\n","\n")) end
o.remove=function(self,section,value) fs.writefile(nf_f,"") end
o.validate=function(self,value)
    local hosts={}
    string.gsub(value,'[^'.."\r\n"..']+',function(w) table.insert(hosts,w) end)
    for index,host in ipairs(hosts) do
        if not datatypes.hostname(host) then
            return nil,host.." "..translate("Not valid domain name!")
        end
    end
    return value
end

s:tab("cu",translate("Custom Domain List"))

o=s:taboption("cu",TextValue,"cu_f","",translate("Custom Domain List"))
o.rows=15
o.wrap="off"
o.cfgvalue=function(self,section) return fs.readfile(cu_f) or "" end
o.write=function(self,section,value) fs.writefile(cu_f,value:gsub("\r\n","\n")) end
o.remove=function(self,section,value) fs.writefile(cu_f,"") end
o.validate=function(self,value)
    local hosts={}
    string.gsub(value,'[^'.."\r\n"..']+',function(w) table.insert(hosts,w) end)
    for index,host in ipairs(hosts) do
        if not datatypes.hostname(host) then
            return nil,host.." "..translate("Not valid domain name!")
        end
    end
    return value
end

s:tab("ov",translate("Oversea Domain List"))

o=s:taboption("ov",TextValue,"ov_f","",translate("Oversea Domain List"))
o.rows=15
o.wrap="off"
o.cfgvalue=function(self,section) return fs.readfile(ov_f) or "" end
o.write=function(self,section,value) fs.writefile(ov_f,value:gsub("\r\n","\n")) end
o.remove=function(self,section,value) fs.writefile(ov_f,"") end
o.validate=function(self,value)
    local hosts={}
    string.gsub(value,'[^'.."\r\n"..']+',function(w) table.insert(hosts,w) end)
    for index,host in ipairs(hosts) do
        if not datatypes.hostname(host) then
            return nil,host.." "..translate("Not valid domain name!")
        end
    end
    return value
end

s:tab("ex",translate("Excluded Domain List(For Vmess/Vless/SS2022)"))

o=s:taboption("ex",TextValue,"ex_f","",translate("Excluded Domain List(For Vmess/Vless/SS2022)"))
o.rows=15
o.wrap="off"
o.cfgvalue=function(self,section) return fs.readfile(ex_f) or "" end
o.write=function(self,section,value) fs.writefile(ex_f,value:gsub("\r\n","\n")) end
o.remove=function(self,section,value) fs.writefile(ex_f,"") end
o.validate=function(self,value)
    local hosts={}
    string.gsub(value,'[^'.."\r\n"..']+',function(w) table.insert(hosts,w) end)
    for index,host in ipairs(hosts) do
        if not datatypes.hostname(host) then
            return nil,host.." "..translate("Not valid domain name!")
        end
    end
    return value
end

s:tab("pre",translate("Preload Domain List(GFW Only)"))

o=s:taboption("pre",TextValue,"pre_f","",translate("Preload Domain List(GFW Only)"))
o.rows=15
o.wrap="off"
o.cfgvalue=function(self,section) return fs.readfile(pre_f) or "" end
o.write=function(self,section,value) fs.writefile(pre_f,value:gsub("\r\n","\n")) end
o.remove=function(self,section,value) fs.writefile(pre_f,"") end
o.validate=function(self,value)
    local hosts={}
    string.gsub(value,'[^'.."\r\n"..']+',function(w) table.insert(hosts,w) end)
    for index,host in ipairs(hosts) do
        if not datatypes.hostname(host) then
            return nil,host.." "..translate("Not valid domain name!")
        end
    end
    return value
end

s:tab("cname",translate("CNAME Domain List"))

o=s:taboption("cname",TextValue,"cname_f","",translate("Use domestic dns to resolve a domain name to another domain name<br/>For example, point a.com to b.com: /a.com/b.com"))
o.rows=15
o.wrap="off"
o.cfgvalue=function(self,section) return fs.readfile(cname_f) or "" end
o.write=function(self,section,value) fs.writefile(cname_f,value:gsub("\r\n","\n")) end
o.remove=function(self,section,value) fs.writefile(cname_f,"") end

return m
