function scope(body)
	local list,res={}
	local function auto(close,msg)
		return function(t)
			if type(t)~='table' then error("need table: { expression }",2) end
			if t[1] then table.insert(list,{ arg=t[1], fn=close or io.close })
			else
				if msg=='weak' then return table.unpack(t) end
				error(msg or t[2] or "no resource",2) 
			end
			return table.unpack(t)
		end
	end
	local ok,err=pcall(function() res={body(auto)} end)
	for i=#list,1,-1 do list[i].fn(list[i].arg) end
	if not ok then
		if type(err)~='string' then error(err,2)
		else error("scope error\nlua: "..err,2) end
	end
	return table.unpack(res)
end

-- usage:
-- scope(function(auto)
--   local f=auto(io.close){ io.open "text.txt" }
--   local g,err=auto(io.close,"weak") { io.open "test2.txt" }
--   print( f:read() )
-- end)
