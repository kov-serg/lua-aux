local Vector={}
local Vector_mt={ type='vector', __index=Vector }

vector=function(x)
	local r={}
	local mt=getmetatable(x)
	if type(x)=='number' or (mt and mt.scalar) then
		r[1]=x
	else
		for k,v in ipairs(x) do r[k]=v end
	end
	return setmetatable(r,Vector_mt)
end
local function tostring(v,fmt)
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
Vector.format_string="%.4g"
Vector.format_prefix=Vector_mt.type
function Vector_mt:__tostring(fmt)
	fmt=fmt or self.format_string
	local r=self.format_prefix..'{'
	for k,v in ipairs(self) do if k>1 then r=r..',' end r=r..tostring(v,fmt) end
	return r..'}'
end
local function need_vector(va)
	local mt=getmetatable(va)
	if mt and mt.type==Vector_mt.type then return end
	error("need vector",3)
end
function Vector:unary(fn)
	local r={} for k,v in ipairs(self) do r[k]=fn(v) end
	return setmetatable(r,Vector_mt)
end
function Vector.binary(a,b,fn) need_vector(b)
	local na,nb,r=#a,#b,{}
	local nab=math.min(na,nb)
	for i=1,nab do r[i]=fn(a[i],b[i]) end
 	for i=na+1,nb do r[i]=fn(0,b[i]) end
  	for i=nb+1,na do r[i]=fn(a[i],0) end
	return setmetatable(r,Vector_mt)
end
function Vector:norm()
	local s=0
	for k,v in ipairs(self) do if type(v)=='number' then s=s+v*v else s=s+v:norm() end end
	return s
end
function Vector:len() return self:norm()^0.5 end
function Vector_mt.__unm(va) return va:unary(function(x) return -x end) end
function Vector_mt.__add(va,vb) return va:binary(vb,function(ai,bi) return ai+bi end) end
function Vector_mt.__sub(va,vb) return va:binary(vb,function(ai,bi) return ai-bi end) end
function Vector_mt.__mul(va,vb)
	-- n*v =v
	-- v*n =v
	-- v*c =v
	-- v*v =n
	-- v*m =v ?
	if type(va)=='number' then return vb:unary(function(vbi) return va*vbi end) end
	local mt=getmetatable(vb)
	if type(vb)=='number' or (mt and mt.scalar) then return va:unary(function(vai) return vai*vb end) end
	if mt and mt.type==Vector_mt.type then
		local s=0
		local n=math.min(#va,#vb)
		for i=1,n do
			local vbi=vb[i]
			if type(vbi)=='number' then s=s+va[i]*vbi
			else s=s+va[i]*vbi:conj() end
		end
		return s
	end
	error("operation vector*"..mt.type.." not implemented")
end
function Vector_mt.__div(va,vb)
	-- n/v =error
	-- v/n =v
	-- v/c =v
	-- v/v =error
	-- v/m =v*inv(m) ?
	local mt=getmetatable(vb)
	if mt and mt.type==Vector_mt.type then error("operation /vector not supported",2) end
	if type(vb)=='number' or (mt and mt.scalar) then 
		return va:unary(function(vai) return vai/vb end)
	end
	error("vector/"..mt.type)
end
function Vector.vmul3(a,b)
	if #a~=3 or #b~=3 then error "need 3d vectors" end
	return vector{ a[2]*b[3]-a[3]*b[2], a[3]*b[1]-a[1]*b[3], a[1]*b[2]-a[2]*b[1] }
end
function Vector:ort2()
	if #self~=2 then error "need 2d vector" end
	return vector{ self[2],-self[1] }
end
function Vector:dir()
	return self/self:len()
end

--[[
require "complex"
i=complex{0,1}
a=vector{3,4*i}
x=vector{1,i,0}
y=vector{0,1,0}
z=vector{0,0,1}
q=vector{1+i,1-i,i}
--print(x,y,z,q)
print( x*y,y*x,z*i,i*z )
--print(vector{1,complex{1,1}}*complex{0,1})
--print(complex{0,1}*vector{1,complex{1,1}})
print( vector(complex{1,2}))
]]
