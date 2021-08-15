function mod(a,m)
	if a>=m then a=a-m if a>=m then a=a%m end
	elseif a<0 then a=a+m if a<0 then a=m+a%m end	end
	return a
end
function mod_add(a,b,m) return mod(a+b,m) end
function mod_mul(a,b,m) local r,c=0 while b>0 do c=b//2
  if 2*c~=b then r=mod_add(r,a,m) end a=mod_add(a,a,m) b=c end return r 
end
function mod_pow(a,b,m) local r,c=1 while b>0 do c=b//2
  if 2*c~=b then r=mod_mul(r,a,m) end a=mod_mul(a,a,m) b=c end return r 
end
function mod_sqrt(a,m,b)
  local ai,c,d,e,r,t,s
  if not is_prime(m) then error "need prime m" end
  t=m-1 c=t/2 if mod_pow(a,c,m)==t then return 0 end
  if not b or mod_pow(b,c,m)~=t then
  	repeat b=math.random(m-1) until mod_pow(b,c,m)==t
  end
  s=0 while t%2==0 do s=s+1 t=t//2 end
  ai=mod_pow(a,m-2,m) c=mod_pow(b,t,m) r=mod_pow(a,(t+1)//2,m);
  for i=1,s-1 do e=mod_pow(2,s-i-1,m)
    d=mod_pow(mod_mul(mod_mul(r,r,m),ai,m),e,m)
    if d==m-1 then r=mod_mul(r,c,m) end c=mod_mul(c,c,m)
  end
  --if (r+a)%2==1 then r=m-r end
  if r>m//2 then r=m-r end
  return r,m-r
end
function is_prime(x)
  local n,r,a
  if x==2 or x==3 then return true end
  if x<2 or x%2==0 then return false end
  n=math.ceil(math.log(x,2))+4
  for i=1,n do
    a=1+math.random(x-3)
    r=mod_pow(a,x-1,x)
    if r~=1 then return false end
  end
  return true
end
function next_prime(x)
  if x<2 then return 2 end
  x=x-(x+1)%2
  repeat x=x+2 until is_prime(x) return x
end
function prev_prime(x)
	if x<=3 then return 2 end
	x=x-x%2+1
	repeat x=x-2 until is_prime(x) return x
end
function primes(n)
	local r,t,i,j,k={2},{}
	i=1 repeat k=2*i+1 if k>n then break end t[i]=k i=i+1 until false
	i=3 while i<=n do
		if t[i//2] then table.insert(r,i)
			k=i*i while k<=n do t[k//2]=nil k=k+2*i end
		end
		i=i+2
	end
	return r
end
function factor(x)
	local r,p,n="",2
	while x>1 and not is_prime(x) do
		n=0 while x%p==0 do n=n+1 x=x//p end
		if n>0 then
			if #r>0 then r=r.."*" end
			if n>1 then r=r..string.format("%d^%d",p,n)
			else r=r..p end
		end
		p=next_prime(p)
	end
	if x>1 then
		if #r>0 then r=r.."*" end
		r=r..x
	end
	return r
end
function factors(x)
	local p=1
	return function(ctx,prev)
		if x>1 then
			if is_prime(x) then p=x x=1 return p,1 end
			local n=0 repeat 
				p=next_prime(p)
				while x%p==0 do n=n+1 x=x//p end
			until n>0
			return p,n
		end
	end
end
function mod_muls(m,a,...)
	for _,v in ipairs(table.pack(...)) do
		a=mod_mul(a,v,m)
	end
	return a
end
function gcd(a,b)
	while b~=0 do a,b=b,a%b end
	return a
end
function is_gen(g,p)
	for m,n in factors(p-1) do
		if mod_pow(g,(p-1)//m,p)==1 then return false end
	end
	return true
end
