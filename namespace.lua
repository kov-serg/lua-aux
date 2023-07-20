function namespace(name,env)
	env=env or _ENV local ns=env
	name:gsub("[^%.]+",function(name)
		if ns[name]==nil then ns[name]={} end
		ns=ns[name]
	end)
	return setmetatable(ns,{__index=env})
end

--[[ usage:
x=10
print(1,x)
do local _ENV=namespace "ns1"
	x=20
	print(2,x)
	do local _ENV=namespace "ns2.utils"
		x=30
		print(3,x)
	end
	print(4,x,ns2.utils.x)
end
print(5,x,ns1.x,ns1.ns2.utils.x)
-- output:
-- 1	10
-- 2	20
-- 3	30
-- 4	20	30
-- 5	10	20	30
]]
