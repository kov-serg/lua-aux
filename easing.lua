local Easing={}

local function out(t,f) return 1-f(1-t) end
local function inout(t,f)
	local k=0.5/f(0.5)
	if t<0.5 then return k*f(t) else return 1-k*f(1-t) end
end

function Easing.none(t) return 0 end
function Easing.linear(t) return t end
function Easing.inquad(t) return t*t end
function Easing.outquad(t) return out(t,Easing.inquad) end
function Easing.inoutquad(t) return inout(t,Easing.inquad) end
function Easing.incubic(t) return t*t*t end
function Easing.outcubic(t) return out(t,Easing.incubic) end
function Easing.inoutcubic(t) return inout(t,Easing.incubic) end
function Easing.inquart(t) t=t*t return t*t end
function Easing.outquart(t) return out(t,Easing.inquart) end
function Easing.inoutquart(t) return inout(t,Easing.inquart) end
function Easing.inquint(t) local tt=t*t return tt*tt*t end
function Easing.outquint(t) return out(t,Easing.inquint) end
function Easing.inoutquint(t) return inout(t,Easing.inquint) end
function Easing.insine(t) return math.sin(0.5*math.pi*t) end
function Easing.outsine(t) return out(t,Easing.insine) end
function Easing.inoutsine(t) return inout(t,Easing.insine) end
function Easing.inexpo(t) 
	local a,b=2^-10,1-2^-10
	t=10*(t-1)
	return (2^t-a)/b
end
function Easing.outexpo(t) return out(t,Easing.inexpo) end
function Easing.inoutexpo(t) return inout(t,Easing.inexpo) end
function Easing.incirc(t)
	local r=1-t*t
	if r<0 then r=0 end
	return 1-math.sqrt(r)
end
function Easing.outcirc(t) return out(t,Easing.incirc) end
function Easing.inoutcirc(t) return inout(t,Easing.incirc) end
function Easing.outbounce(t)
	local k1=7.5625;
	if t<1/2.75 then return k1*t*t end
	if t<2/2.75 then t=t-1.5/2.75 return k1*t*t+0.75 end
	if t<2.5/2.75 then t=t-2.25/2.75 return k1*t*t+0.9375 end
	t=t-2.625/2.75 return k1*t*t+0.984375 
end
function Easing.inbounce(t) return out(t,Easing.outbounce) end
function Easing.inoutbounce(t) return inout(t,Easing.outbounce) end
function Easing.outelastic(t)
	if t <= 0 then return 0 end
	if t >= 1 then return 1 end
	local p=2*math.pi/3
	return 1+2^(-10*t)*math.sin((t*10-0.75)*p)
end
function Easing.inelastic(t) return out(t,Easing.outelastic) end
function Easing.inoutelastic(t) return inout(t,Easing.outelastic) end
function Easing.make_c3(a,b,c,d)
	d=d or 1 b=3*b c=3*c
	return function(t)
		local q=1-t
		local tt,qq=t*t,q*q
		return a*qq*q+b*qq*t+c*q*tt+d*tt*t
	end
end
function Easing.make_step(n,jump_start,jump_end)
	local f,m=0,n
	if jump_start then f=1 m=m+1 end
	if not jump_end then m=m-1 end
	return function(t)
		if t<=0 then return 0 end
		if t>=1 then return 1 end
		local k=math.floor(f+t*n)/m
		return k
	end
end

return Easing
