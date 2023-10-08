local function bitlen(limit)
	limit=limit or 512
	local x,y,i=0,1,1
	while x<y and i<limit do x,y,i=y,y*2,i+1 end
	return i
end

local function adc(a,b,c)
	a=a|0 b=b|0 if c~=0 then c=1 else c=0 end
	local r=a+b+c
	if a<0 then if b<0 or r>=0 then c=1 else c=0 end
	elseif b<0 then if a<0 or r>=0 then c=1 else c=0 end
	else c=0 end
	return r,c
end

local function sbc(a,b,c)
	a=a|0 b=b|0 if c~=0 then c=1 else c=0 end
	local r=a-b-c
	if a>=0 then if b<0 or a-c<b then c=1 else c=0 end
	else if b<0 and a<b+c then c=1 else c=0 end end
	return r,c
end

local function adci(a,b,c)
	local sa,sb,r,rc=a<0,b<0,adc(a,b,c)
	return r,rc, sa==sb and sa~=(r<0)
end

local function sbci(a,b,c)
	local sa,sb,r,rc=a<0,b<0,sbc(a,b,c)
	return r,rc, sa~=sb and sa~=(r<0)
end

return {
	bitlen=bitlen,-- returns 64
	adc=adc,   -- returns a+b+c, unsiged_carry
	sbc=sbc,   -- returns a-b-c, unsiged_carry
	adci=adci, -- returns a+b+c, usigned_carry, integer_overflow
	sbci=sbci, -- returns a-b-c, unsiged_carry, integer_overflow
}
