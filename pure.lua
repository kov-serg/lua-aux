function pure(body,env)
	return assert(load("return function(_ENV) return "..body.." end"))
	()(env or {})
end

function isolated(s)
	if type(s)=="string" then return pure(s) end
	return function(body) return pure(body,s) end
end

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
