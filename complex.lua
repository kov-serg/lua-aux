local Complex={}
local Complex_mt={ type='complex',scalar=true,__index=Complex }

complex=setmetatable({},{
	__call=function(t,x)
		if type(x)=='number' then return setmetatable({x,0},Complex_mt) end
		local mt=getmetatable(x)
		if mt and mt.type~=Complex_mt.type then error("unable to create complex number from "..mt.type) end
		local r={ x[1] or 0,x[2] or 0 }
		if type(r[1])~='number' or type(r[2])~='number' then error("need numbers") end
		return setmetatable(r,Complex_mt)
	end,
})

function complex.re(x) local t=complex(x) return x[1] end
function complex.im(x) local t=complex(x) return x[2] end
function complex.abs(x) local t=complex(x) return math.sqrt(t:norm()) end       
function complex.conj(x) local t=complex(x) return complex{t[1],-t[2]} end
function complex.norm(x) local t=complex(x) return t[1]*t[1]+t[2]*t[2] end
function complex.phase(x) local t=complex(x) 
	local a=math.atan(t[2],t[1])
	return complex{ math.cos(a), math.sin(a) }
end
function complex.arg(x) local t=complex(x) return math.atan(t[2],t[1]) end
function complex.exp(x)
	local z=complex(x)
	local t=math.exp(z[1])
	return complex{ t*math.cos(z[2]), t*math.sin(z[2]) }
end
function complex.log(x)
	local z=complex(x)
	return complex{ math.log(z:norm())/2, z:arg() }
end
Complex.re=complex.re
Complex.im=complex.im
Complex.len=complex.abs
Complex.conj=complex.conj
Complex.norm=complex.norm
Complex.phase=complex.phase
Complex.arg=complex.arg
function Complex_mt.__add(va,vb)
	local a,b=complex(va),complex(vb)
	return complex{ a[1]+b[1], a[2]+b[2] }
end
function Complex_mt.__unm(va)
	local a=complex(va)
	return complex{ -a[1], -a[2] }
end
function Complex_mt.__sub(va,vb)
	local a,b=complex(va),complex(vb)
	return complex{ a[1]-b[1], a[2]-b[2] }
end
function Complex_mt.__mul(va,vb)
	-- n*c
	-- c*n
	-- c*c
	-- c*v
	-- c*m
	local mt=getmetatable(vb)
	if mt and mt.type~=Complex_mt.type then
		-- c*v
		-- c*m
		return vb:unary(function(vbi) return va*vbi end)
	end
	local a,b=complex(va),complex(vb)
	return complex{ a[1]*b[1]-a[2]*b[2], a[2]*b[1]+a[1]*b[2] }
end
function Complex_mt.__div(va,vb)
	-- n/c
	-- c/n
	-- c/c
	-- c/v -- error
	-- c/m = c*inv(m)
	local mt=getmetatable(vb)
	if mt and mt.type~=Complex_mt.type then
		-- c/v
		-- c/m
		return vb:scalar_ldiv(va)
	end
	local a,b=complex(va),complex(vb)
	local d=b:norm()
	return complex{ (a[1]*b[1]+a[2]*b[2])/d, (a[2]*b[1]-a[1]*b[2])/d }
end
function Complex_mt.__pow(va,vb)
	local a,b=complex(va),complex(vb)
	local an=a:norm() 
	if an==0 then 
		if b:norm()==0 then error("0^0 is undefined")
		else return a end
	end
	local lnma=math.log(an)/2
	local arga=a:arg()
	local s=math.exp( lnma*b[1] - b[2]*arga )
	local f=b[1]*arga+b[2]*lnma
	return complex{ s*math.cos(f), s*math.sin(f)  }
end
Complex.format_string="%.4g"
Complex.format_prefix=Complex_mt.type
function Complex_mt:__tostring(fmt)
	fmt=fmt or self.format_string
	local r=self.format_prefix..'{' for i=1,2 do if i>1 then r=r..',' end r=r..string.format(fmt,self[i]) end
	return r..'}'
end

return complex
