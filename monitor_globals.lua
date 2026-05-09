setmetatable(_G,{__newindex=function(t,n,v)
	local info=debug.getinfo(2)
	local at=info.what
	if info.currentline then 
		at=string.format("%s:%s",info.source or at,info.currentline):gsub("^@","")
	end
	print(string.format("WARNING: modify global %s=%s at %s",n,v,at))
	rawset(t,n,v)
	return v
end})
