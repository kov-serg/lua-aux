local int=require "lua_int"

-- check does it work (!! C signed overflow is UB and may cause problems with to smart optimizer !!)

local function test()
	local sb=int.bitlen()-1
	local min=1<<sb
	local max=min-1
	if min>=max then error("module math fails") end
	local function check(name,fn,a,b,c,r0,c0) 
		local r1,c1=fn(a,b,c)
		if r1~=r0 or c1~=c0 then 
			error(string.format("%s a=0x%016X b=0x%016X c=%d r=0x%016X(0x%016X) rc=%d(%d)",name,a,b,c,r1,r0,c1,c0)) 
		end
	end
	local function chk_adc(a,b,c,r0,c0) 
		check("adc",int.adc,a,b,c,r0,c0) 
		if a~=b then check("adc",int.adc,b,a,c,r0,c0) end
	end
	local function chk_sbc(a,b,c,r0,c0)
		check("sbc",int.sbc,a,b,c,r0,c0)
	end

	chk_adc(0,0,0,0,0)
	chk_adc(0,1,0,1,0)
	chk_adc(1,1,0,2,0)
	chk_adc(min,min,0,0,1)
	chk_adc(max,max,0,-2,0)
	chk_adc(max,max,1,-1,0)
	chk_adc(min,max,0,-1,0)
	chk_adc(min,max,1,0,1)
	chk_adc(-1,0,0,-1,0)
	chk_adc(-1,0,1, 0,1)
	chk_adc(-1,1,0,0,1)
	chk_adc(-1,1,1,1,1)
	chk_adc(-1,-1,0,-2,1)
	chk_adc(-1,-1,1,-1,1)
	chk_adc(-1,-2,1,-2,1)
	chk_adc(min,1,0,min+1,0)
	chk_adc(max,1,0,min,0)
	chk_adc(max,0,1,min,0)

	chk_sbc(0,0,0,0,0)
	chk_sbc(0,0,1,-1,1)
	chk_sbc(0,1,0,-1,1)
	chk_sbc(0,1,1,-2,1)
	chk_sbc(1,1,1,-1,1)
	chk_sbc(-1,1,0,-2,0)
	chk_sbc(-1,0,1,-2,0)
	chk_sbc(-1,1,1,-3,0)
	chk_sbc(0,max,0,min+1,1)
	chk_sbc(0,max,0,min+1,1)
	chk_sbc(0,max,1,min,1)
	chk_sbc(1,max,1,-max,1)
	chk_sbc(1,max,0,1-max,1)
	chk_sbc(min,max,0,1,0)
	chk_sbc(min,max,1,0,0)
	chk_sbc(max,max,0,0,0)
	chk_sbc(max,max,1,-1,1)
	chk_sbc(max,-1,0,min,1)
	chk_sbc(max,-1,1,max,1)
	chk_sbc(max,1,0,max-1,0)
	chk_sbc(max,0,1,max-1,0)
	
	local function checks(name,fn,a,b,c,r0,c0,o0) 
		local r1,c1,o1=fn(a,b,c)
		if r1~=r0 or c1~=c0 or o1~=o0 then
			error(string.format("FAIL: %s a=%d b=%d c=%d r=%d(%d) rc=%d(%d) ovf=%s(%s)",name,a,b,c,r1,r0,c1,c0,o1,o0))
		end
	end
	local function chk_adcs(a,b,c,r0,c0,o0) 
		checks("adcs",int.adci,a,b,c,r0,c0,o0) 
		if a~=b then checks("adcs",int.adci,b,a,c,r0,c0,o0) end
	end
	local function chk_sbcs(a,b,c,r0,c0,o0)
		checks("sbcs",int.sbci,a,b,c,r0,c0,o0)
	end

	chk_adcs(0,0,0, 0,0,false)
	chk_adcs(0,1,0, 1,0,false)
	chk_adcs(1,0,1, 2,0,false)
	chk_adcs(max,0,0, max,0,false)
	chk_adcs(max,0,1, max+1,0,true)
	chk_adcs(min,-1,0,max,1,true)
	chk_adcs(0,-1,0, -1,0,false)
	chk_adcs(0,-1,1,  0,1,false)
	chk_adcs(max,-1,1,max,1,false)

	chk_sbcs(0,0,0,  0,0,false)
	chk_sbcs(0,1,0, -1,1,false)
	chk_sbcs(0,1,1, -2,1,false)
	chk_sbcs(3,1,1,  1,0,false)
	chk_sbcs(min,1,0, max,0,true)
	chk_sbcs(min,1,1, max-1,0,true)
	chk_sbcs(0,max,1, min,1,false)
	chk_sbcs(-1,max,1,max,0,true)
end

test()
