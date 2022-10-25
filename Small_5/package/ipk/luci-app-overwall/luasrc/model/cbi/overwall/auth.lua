m=Map("overwall")

s=m:section(TypedSection,"global")
s.anonymous=true

o=s:option(Value,"auth_1",translate("Encrypted Code"))

o=s:option(Value,"auth_2",translate("Authorization Code"))

return m
