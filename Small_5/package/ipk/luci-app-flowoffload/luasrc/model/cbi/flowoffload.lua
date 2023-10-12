m=Map("flowoffload")
m.title=translate("Turbo ACC Acceleration Settings")
m.description=translate("Opensource Linux Flow Offload driver (Fast Path or HWNAT)<br/>FULLCONE NAT needs to be set on the firewall page")
m:append(Template("flowoffload/status"))

s=m:section(TypedSection,"flowoffload")
s.addremove=false
s.anonymous=true

o=s:option(Flag,"enabled",translate("Enable"))
o.description=translate("Enable software flow offloading for connections. (decrease cpu load / increase routing throughput)")

o=s:option(Flag,"hw",translate("HWNAT"))
o.description=translate("Enable Hardware NAT (Requires hardware NAT support)")
o:depends("enabled",1)

o=s:option(Flag,"bbr",translate("Enable BBR"))
o.description=translate("Bottleneck Bandwidth and Round-trip propagation time (BBR)")

return m
