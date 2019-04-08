function const(c)
	return setmetatable({},{__index=c,
		__newindex=function(t,n,v) error "const is read only" end
	})
end
