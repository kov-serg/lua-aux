local complex_m={ __index={} }
local complex_mt={ type='complex',scalar=true, __index={} }
complex=setmetatable({},complex_m)
complex_m.__call=function(m,x)
	if type(x)=='number' then return setmetatable( { x,0 },complex_mt ) end
	local mt=getmetatable(x)
	if mt and mt.type~='complex' then error("unable to create complex number from "..mt.type) end
	local r={ x[1] or 0,x[2] or 0 }
	if type(r[1])~='number' or type(r[2])~='number' then error("need numbers") end
	return setmetatable(r,complex_mt )
end
complex_m.__index.conj=function(x) local t=complex(x) return complex{t[1],-t[2]} end
complex_m.__index.re=function(x) local t=complex(x) return x[1] end
complex_m.__index.im=function(x) local t=complex(x) return x[2] end
complex_m.__index.norm=function(x) local t=complex(x) return t[1]*t[1]+t[2]*t[2] end
complex_m.__index.len=function(x) local t=complex(x) return math.sqrt(t:norm()) end
complex_m.__index.abs=function(x) local t=complex(x) return math.sqrt(t:norm()) end
complex_m.__index.phase=function(x) local t=complex(x) 
	local a=math.atan(t[2],t[1])
	return complex{ math.cos(a), math.sin(a) }
end
complex_m.__index.arg=function(x) local t=complex(x) return math.atan(t[2],t[1]) end
complex_m.__index.exp=function(x) 
	local z=complex(x)
	local t=math.exp(z[1])
	return complex{ t*math.cos(z[2]), t*math.sin(z[2]) }
end
complex_m.__index.log=function(x) 
	local z=complex(x)
	return complex{ math.log(z:norm())/2, z:arg() }
end
complex_mt.__index=complex_m.__index
complex_mt.__add=function(va,vb)
	local a,b=complex(va),complex(vb)
	return complex{ a[1]+b[1], a[2]+b[2] }
end
complex_mt.__unm=function(va)
	local a=complex(va)
	return complex{ -a[1], -a[2] }
end
complex_mt.__sub=function(va,vb)
	local a,b=complex(va),complex(vb)
	return complex{ a[1]-b[1], a[2]-b[2] }
end
complex_mt.__mul=function(va,vb)
	-- n*c
	-- c*n
	-- c*c
	-- c*v
	-- c*m
	local mt=getmetatable(vb)
	if mt and mt.type~='complex' then
		-- c*v
		-- c*m
		return vb:unary(function(vbi) return va*vbi end)
	end
	local a,b=complex(va),complex(vb)
	return complex{ a[1]*b[1]-a[2]*b[2], a[2]*b[1]+a[1]*b[2] }
end
complex_mt.__div=function(va,vb)
	-- n/c
	-- c/n
	-- c/c
	-- c/v -- error
	-- c/m = c*inv(m)
	local mt=getmetatable(vb)
	if mt and mt.type~='complex' then
		-- c/v
		-- c/m
		return vb:scalar_ldiv(va)
	end
	local a,b=complex(va),complex(vb)
	local d=b:norm()
	return complex{ (a[1]*b[1]+a[2]*b[2])/d, (a[2]*b[1]-a[1]*b[2])/d }
end
complex_mt.__pow=function(va,vb)
	local a,b=complex(va),complex(vb)
	local lnma=math.log(a:norm())/2
	local arga=a:arg()
	local s=math.exp( lnma*b[1] - b[2]*arga )
	local f=b[1]*arga+b[2]*lnma
	return complex{ s*math.cos(f), s*math.sin(f)  }
end
complex_m.__index.format_string="%.4g"
complex_m.__index.format_prefix="complex"
complex_mt.__tostring=function(z,fmt)
	fmt=fmt or complex.format_string
	local r=complex.format_prefix..'{' for i=1,2 do if i>1 then r=r..',' end r=r..string.format(fmt,z[i]) end
	return r..'}'
end
