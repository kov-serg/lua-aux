local matrix_m={ __index={} }
local matrix_mt={type='matrix',__index={}}
matrix=setmetatable({},matrix_m)

matrix_m.__call=function(m,v,n)
	local r
	if type(v)=='number' or n then 
		if n==nil then n,v=v,1 end
		r={ dim=n, data={} }
		for y=1,n do
			for x=1,n do table.insert(r.data,x==y and v or 0) end
		end
	else
		local mt=getmetatable(v)
		if mt and mt.type=='matrix' then
			r={ dim=v.dim, data={} }
			for di,dv in ipairs(v.data) do r.data[di]=dv end
			return setmetatable(r,matrix_mt)		
		end
		-- from array
		n=n or math.max(#v,#v[1])
		r={ dim=n, data={} } 
		for y=1,n do
			local row=v[y] or {}
			for x=1,n do
				r.data[x+(y-1)*n]=row[x] or 0
			end
		end
	end
	return setmetatable(r,matrix_mt)
end

local tostring=function(v,fmt)
	if type(v)=='number' then
		return string.format(fmt,v)
	elseif type(v)=='table' then
		local mt=getmetatable(v)
		if mt then 
			local ts=mt.__tostring
			if ts then return ts(v,fmt) end
		end
	end
	return type(v)
end
matrix_mt.__tostring=function(m,fmt)
	local r='matrix{\n'
	fmt=fmt or '%8.4f'
	for y=1,m.dim do
		r=r..'\t{'
		for x=1,m.dim do
			if x>1 then r=r..',' end
			r=r..tostring(m.data[x+(y-1)*m.dim],fmt)
		end

		r=r..'},\n'
	end
	return r..'}'
end
local need_matrix=function(va)
	local mt=getmetatable(va)
	if mt and mt.type=='matrix' then return end
	error("need matrix",3)
end
matrix_mt.__index.tr=function(a)
	local n=a.dim
	local r={dim=n,data={}}
	for y=1,r.dim do
		for x=1,r.dim do
			local v=a.data[y+(x-1)*n]
			if type(v)~='number' then v=v:conj() end
			r.data[x+(y-1)*n]=v
		end
	end
	return setmetatable(r,matrix_mt)
end
matrix_mt.__index.unary=function(a,fn)
	local r={ dim=a.dim, data={} }
	for k,v in ipairs(a.data) do r.data[k]=fn(v) end
	return setmetatable(r,matrix_mt)
end
matrix_mt.__index.binary=function(a,b,fn)
	need_matrix(b)
	local da,db=a.dim,b.dim
	local r={dim=math.max(da,db),data={}}
	local va,vb
	for y=1,r.dim do
		for x=1,r.dim do
			if x<=da and y<=da then va=a.data[x+da*(y-1)] else va=0 end
			if x<=db and y<=db then vb=b.data[x+db*(y-1)] else vb=0 end
			r.data[x+r.dim*(y-1)]=fn(va,vb)
		end
	end
	return setmetatable(r,matrix_mt)
end
matrix_mt.__index.get=function(m,y,x) return m.data[x+(y-1)*m.dim] end
matrix_mt.__index.set=function(m,y,x,v) m.data[x+(y-1)*m.dim]=v end
matrix_mt.__unm=function(va) return va:unary(function(x) return -x end) end
matrix_mt.__add=function(va,vb) return va:binary(vb,function(ai,bi) return ai+bi end) end
matrix_mt.__sub=function(va,vb) return va:binary(vb,function(ai,bi) return ai-bi end) end
matrix_mt.__mul=function(va,vb)
	-- n*m =m
	-- m*n =m
	-- m*c =mc
	-- m*v =v
	-- m*m =m
	if type(va)=='number' then return vb:unary(function(vbi) return va*vbi end) end
	local mt=getmetatable(vb)
	if type(vb)=='number' or (mt and mt.scalar) then return va:unary(function(vai) return vai*vb end) end
	if mt and mt.type=='matrix' then
		if va.dim~=vb.dim then error "need matrix same dimensions" end
		local n=va.dim
		local r={ dim=n, data={} }
		for y=1,n do
			for x=1,n do
				local s=0
				for k=1,n do
					s=s+va.data[k+(y-1)*va.dim]*vb.data[x+(k-1)*vb.dim]
				end
				r.data[x+(y-1)*n]=s
			end
		end
		return setmetatable(r,matrix_mt)
	end
	if mt and mt.type=='vector' then
		if va.dim~=#vb then error "need vector same dimensions" end
		local n=va.dim
		local r={}
		for y=1,n do
			local s=0
			for x=1,n do
				s=s+va.data[x+(y-1)*va.dim]*vb[x]
			end
			r[y]=s
		end
		return setmetatable(r,mt)
	end
	error("operation matrix*"..mt.type.." not implemented")
end
matrix_mt.__div=function(va,vb)
	-- n/m =n*inv(m)
	-- m/n =m
	-- m*c =mc
	-- m/v =error
	-- m/m =m*inv(m)
	if type(va)=='number' then return n*vb:inverse() end
	local mt=getmetatable(vb)
	if type(vb)=='number' or (mt and mt.scalar) then return va:unary(function(vai) return vai/vb end) end
	if mt and mt.type=='matrix' then
		if va.dim~=vb.dim then error "need matrix same dimensions" end
		return va*vb:inverse()
	end
	error("operation matrix*"..mt.type.." not implemented")
end
local norm=function(x) if type(x)=='number' then return math.abs(x) end return x:norm() end
matrix_mt.__index.det=function(m)
	local n,w,r
	n=m.dim w=matrix(m) r=1
	for x=1,n do
		mi=x mv=norm(w.data[x+(x-1)*n])
		for y=x+1,n do tv=norm(w.data[x+(y-1)*n]) if mv<tv then mv=tv mi=y end end
		if mi~=x then
			for k=x,n do w.data[k+(x-1)*n],w.data[k+(mi-1)*n]=w.data[k+(mi-1)*n],w.data[k+(x-1)*n] end
		end
		for y=x+1,n do
			mf=w.data[x+(y-1)*n]/w.data[x+(x-1)*n]
			for k=x+1,n do w.data[k+(y-1)*n]=w.data[k+(y-1)*n]-mf*w.data[k+(x-1)*n] end
		end
		r=r*w.data[x+(x-1)*n]
	end
	return r
end
matrix_mt.__index.inv=function(m)
	local n,r,w,mi,mv,tv,mf
	n=m.dim w=matrix(m) r=matrix(n)
	for x=1,n do
		mi=x mv=norm(w.data[x+(x-1)*n])
		for y=x+1,n do tv=norm(w.data[x+(y-1)*n]) if mv<tv then mv=tv mi=y end end
		if mi~=x then
			for k=x,n do w.data[k+(x-1)*n],w.data[k+(mi-1)*n]=w.data[k+(mi-1)*n],w.data[k+(x-1)*n] end
			for k=1,n do r.data[k+(x-1)*n],r.data[k+(mi-1)*n]=r.data[k+(mi-1)*n],r.data[k+(x-1)*n] end
		end
		for y=1,n do
			if y~=x then
				mf=w.data[x+(y-1)*n]/w.data[x+(x-1)*n]
				for k=x+1,n do w.data[k+(y-1)*n]=w.data[k+(y-1)*n]-mf*w.data[k+(x-1)*n] end
				for k=1,n do r.data[k+(y-1)*n]=r.data[k+(y-1)*n]-mf*r.data[k+(x-1)*n] end
			end
		end
	end
	for x=1,n do
		mf=1.0/w.data[x+(x-1)*n]
		for k=1,n do r.data[k+(x-1)*n]=r.data[k+(x-1)*n]*mf end
	end
	return r
end

--[[
require "complex"
require "vector"

i=complex{0,1}
r=vector{1,-1,i,0}
f=30*math.pi/180
c=math.cos(f)
s=math.sin(f)

m1=matrix{
	{c ,s,0,0},
	{-s,c,0,0},
	{0 ,0,1,0},
	{0 ,0,0,1},
}
m2=matrix{
	{ 1, 0, 0, 7},
	{ 1, 0, 0, 0},
	{ 0, 1, 0, 0},
	{ 0, 0, 1, 1},
}
m3=m2:inv()
print(m2*m3)
print(m3:tr()*r)
]]
