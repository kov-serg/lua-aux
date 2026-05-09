local unit={}

local function clip(x,x1,x2)
	if x<x1 then return x1 end
	if x>x2 then return x2 end
	return x
end
local sqrt2=math.sqrt(2)
local circle_cell
local function circle_cell(x,y,r)
	local x1,x2,x3,y1,y2,y3,s,q,rr,xn,x0,y0,xa,ya
	q=r*sqrt2 rr=r*r s=x*x+y*y-rr-0.5
	if s-q>0 then return 0 end
	if s+q<0 then
		if r<1e-3 then return 0 end
		if r<2 then x=2*x-0.5 y=2*y-0.5
			return 0.25*(circle_cell(x,y,2*r)+circle_cell(x+1,y,2*r)
					+circle_cell(x,y+1,2*r)+circle_cell(x+1,y+1,2*r))
		end
		return 1
	end
	x=x-0.5 y=y-0.5
	if y+1+r<0 or y>=r then return 0 end
	if x+1+r<0 or x>=r then return 0 end
	y1=y   if y1<-r then y1=-r end x1=math.sqrt(rr-y1*y1)
	y2=y+1 if y2> r then y2= r end x2=math.sqrt(rr-y2*y2)
	y3=0.5*(y2+y1) x3=math.sqrt(rr-y3*y3)
	xa={   -x3,   -x2,    x2,    x3, x1}
	ya={ y3-y1, y2-y1, y2-y1, y3-y1, 0 }
	xn=x+1 x0=clip(xa[1],x,xn)
	for i=1,#xa do xa[i]=clip(xa[i],x,xn)-x0 end
	s=0 for i=2,#xa do s=s+xa[i]*ya[i-1]-xa[i-1]*ya[i] end
	return 0.5*math.abs(s)
end

function unit.circleCoverFn(x0,y0,r0) -- fn = returns cover,ro,fi
	local atan,k=math.atan2 or math.atan, -0.5/math.pi
	return function(x,y)
		x=x-x0 y=y-y0
		local rc,fi=math.sqrt(x*x+y*y), atan(y,x)*k 
		if fi<0 then fi=fi+1 end -- 0..1
		return circle_cell(x,y,r0),rc,fi
	end
end

return unit
