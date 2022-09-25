local m,s,o
m=Map("https-dns-proxy")
m.title=translate("HTTPS DNS Proxy")
m.description=translate("HTTPS DNS Proxy is a light-weight DNS<-->HTTPS, non-caching translation proxy for the RFC 8484 DNS-over-HTTPS standard. It receives regular (UDP) DNS requests and issues them via DoH")
m:section(SimpleSection).template="https-dns-proxy/status"
s=m:section(TypedSection,"base",translate("HTTPS DNS Proxy Settings"))
s.anonymous=true
o=s:option(Flag,"enabled",translate("Enable"))
o.default=0
o=s:option(Value,"url",translate("Resolver URL"),
translate("For example https://dns.google/dns-query"))
o.default="https://dns.alidns.com/dns-query"
o:value("https://dns.alidns.com/dns-query","https://dns.alidns.com/dns-query ("..translate("Ali").." DoH)")
o:value("https://doh.pub/dns-query","https://doh.pub/dns-query (Dnspod DoH)")
o:value("https://doh.360.cn/dns-query","https://doh.360.cn/dns-query (360 DoH)")
o:value("https://dns.google/dns-query","https://dns.google/dns-query ("..translate("Google").." DoH)")
o:value("https://cloudflare-dns.com/dns-query","https://cloudflare-dns.com/dns-query (Cloudflare DoH)")
o:value("https://doh.opendns.com/dns-query","https://doh.opendns.com/dns-query (OpenDNS DoH)")
o:value("https://dns.quad9.net/dns-query","https://dns.quad9.net/dns-query (Quad9 DoH)")
o=s:option(Value,"dns",translate("DNS Server"),
translate("DNS Server for resolving DoH domain names,The format is addr:port.Use commas to separate<br/>When specifying a port for IPv6,enclose the address in []<br/>For example 8.8.8.8,8.8.4.4:53,2001:4860:4860::8888,[2001:4860:4860::8844]:53"))
o:value("223.5.5.5,223.6.6.6","223.5.5.5,223.6.6.6 (" .. translate("Ali") .. " DNS)")
o:value("119.29.29.29,182.254.116.116","119.29.29.29,182.254.116.116 (Dnspod DNS)")
o:value("8.8.8.8,8.8.4.4","8.8.8.8,8.8.4.4 (" .. translate("Google") .. " DNS)")
o:value("1.1.1.1,1.0.0.1","1.1.1.1,1.0.0.1 (Cloudflare DNS)")
o:value("208.67.222.222,208.67.220.220","208.67.222.222,208.67.220.220 (OpenDNS)")
o:value("9.9.9.9,149.112.112.112","9.9.9.9,149.112.112.112 (Quad9 DNS)")
o=s:option(Value,"ip",translate("Local IPv4/v6 address to bind to (Default 127.0.0.1)"))
o.datatype="ipaddr"
o.placeholder="127.0.0.1"
o.rmempty=true
o=s:option(Value,"port",translate("Local port to bind to (Default 5053)"))
o.datatype="port"
o.placeholder=5053
o.rmempty=true
o=s:option(Value,"proxy",translate("Proxy server"),
translate("Proxy server(optional)<br/>Supported Protocols: http, https, socks4a, socks5h<br/>For example: socks5://127.0.0.1:1080, http://127.0.0.1:8080"))
o.rmempty=true
o=s:option(Flag,"mode",translate("Dnsmasq upstream server"),
translate("Run as Dnsmasq upstream server"))
o.default=1
o=s:option(Flag,"ipv4",translate("Use IPv4 communication"),
translate("Connect to DoH server using IPv4"))
o.default=0
return m
