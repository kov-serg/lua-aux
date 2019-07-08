function for_scope(body)
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
	local function defer(fn) auto(fn){true} end
	local ok,err=pcall(function() res={body(auto,defer)} end)
	for i=#list,1,-1 do list[i].fn(list[i].arg) end
	if not ok then
		if type(err)~='string' then error(err,2)
		else error("scope error\nlua: "..err,2) end
	end
	if #res>0 then return res end
end

-- usage:
--
-- function test()
--   for t in for_scope,function(auto,defer) -- scope.begin
--     local f,err=auto(io.close,"weak") { io.open "test2.txt" }
--     print(f,err)
--     defer(function() print "defer" end)
--     return auto(){ io.open "readme.txt" }:read()
--   end do return table.unpack(t) end -- scope.end
-- end
-- print(test())
--
