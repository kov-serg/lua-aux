function qfilter(n,q)
	local f={ q=q, n=n, x={}, y={} }
	f.x[0]=1/(1-q)
	for i=1,n do
		local c,xi = 1,f.x[0]
		for j=1,i-1 do c=c*(i-j+1)/j xi=xi+c*f.x[j] end
		f.x[i]=xi*q*f.x[0]
	end
	for i=0,n do f.x[i],f.y[i] = 1/f.x[i],0 end
	function f.put(x)
		for i=n,1,-1 do
			local c,yi = 1,f.y[i]+f.y[0]
			for j=1,i-1 do c=c*(i-j+1)/j yi=yi+c*f.y[j] end
			f.y[i]=f.q*yi
		end
		f.y[0]=x+f.q*f.y[0]
	end
	function f.get(n)
		n=n or f.n
		return f.y[n]*f.x[n]
	end
	return f
end

function qfilter_est_q(n,len,th,limit)
	th=th or 1e-3
	len=len or 10
	if n==0 then return math.exp(math.log(th)/len) end
	limit=limit or 24
	local function est_r(n,q,th,limit)
		local x={}
		x[0]=1/(1-q)
		for i=1,n do
			local c,xi=1,x[0]
			for j=1,i-1 do c=c*(i-j+1)/j xi=xi+c*x[j] end
			x[i]=xi*q/(1-q)
		end
		local y,y_th,k,qk=0,(1-th)*x[n],1,q
		while true do
			y=y+(k^n)*qk 
			if y>y_th or limit<0 then break end
			k=k+1 qk=q*qk limit=limit-1
		end
		return k
	end
	local h,q,t=0,0.5,1
	while true do
		local r=est_r(n,q,th,len+1)
		if r==len then break end
		if r<len then h,q=q,(q+t)/2 else t,q=q,(q+h)/2 end
		limit=limit-1
		if limit<0 then error "limit reached" end
	end
	return q
end

--[[
require "qfilter"

n=4
q=qfilter_est_q(n,10,1e-3) -- fall down to 1e-3 after 10 steps
f=qfilter(n,q)
for i=1,15 do
  f.put(1.0)
  print(string.format("%2d %.3f",i,f.get()))
end
]]
