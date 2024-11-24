m=Map("flowoffload")
m.title=translate("Turbo ACC Acceleration Settings")
m.description=translate("Opensource Linux Flow Offload driver (Fast Path or HWNAT)")
m:append(Template("flowoffload/status"))

s=m:section(TypedSection,"flowoffload")
s.addremove=false
s.anonymous=true

o=s:option(Flag,"bbr",translate("Enable BBR"))
o.description=translate("Bottleneck Bandwidth and Round-trip propagation time (BBR)")

return m
