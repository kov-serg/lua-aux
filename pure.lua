function pure(body,env)
	return assert(load("return function(_ENV) return "..body.." end"))
	()(env or {})
end

function isolated(s)
	if type(s)=="string" then return pure(s) end
	return function(body) return pure(body,s) end
end
