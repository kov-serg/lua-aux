function pure(body,env)
	return assert(load("return function(_ENV) return "..body.." end"))
	()(env or {})
end
--
-- x=1
-- local y=2
-- fn=pure[[function(print)
--   x=10
--   y=20 
--   print(x,y)
-- end]]
-- fn(print)
-- print(x,y)

function isolated(s)
	if type(s)=="string" then return pure(s) end
	return function(body) return pure(body,s) end
end
--
-- x=1 fn=isolated{x=10,print=print}[[ function() print(x) end ]] fn(print) print(x)

function pure_check()
	local i,r,n,v,f	
	i=0 r={} f=debug.getinfo(2,"f").func
	while true do
		i=i+1 n,v=debug.getupvalue(f,i)
		if n==nil then break end
		if n~="_ENV" then table.insert(r,n) end
	end
	if #r>0 then
		error("pure_check fail: you must define\n\tlocal "..table.concat(r,","),2)
	end
end
--[[
global_a="global_a"
local upvalue_a="upvalue_a"
function test(v1) pure_check() local _ENV={G=_G}
	-- local upvalue_a
	upvalue_a="local_a"
	local z=upvalue_a..v1
	G.print(z,G.global_a)
end
test "error"
]]
