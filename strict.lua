function strict(s) s=s or {}
	return setmetatable({},{
		__index=function(t,n) 
			if s[n]==nil then error("no "..n.." defined") end
			return s[n]
		end,
		__newindex=function(t,n,v)
			if s[n]==nil then error("no "..n.." defined") end
			s[n]=v
		end,
	})
end
