function seq(fn)
	local th=coroutine.create(function() return fn(coroutine.yield) end)
	return function(ctx,prev)
		local res=table.pack(coroutine.resume(th))
		return res[1] and table.unpack(res,2) or nil
	end
end
