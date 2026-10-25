local vfft_mt={}
function vfft_mt:init(p)
	self.p=p
	self.n=2^p
	self.n2=2^(p-1)
	self:mkw()
	return self
end
function vfft_mt:mkw()
	local w,a={ 1, 0 },math.pi/self.n2
	for k=1,self.n2 do w[2*k+1],w[2*k+2]=math.cos(k*a),math.sin(k*a) end
	self.w=w
end
function vfft_mt:core(s)
	local p,n,w,a,d,i,j,mc=self.p,self.n,self.w
	a=n for c=1,p do mc=2^c d=a a=math.floor(a/2) 
		for f=0,a-1 do for g=0,n-1,d do i=g+f j=i+a
			self:twist(i,j,w[f*mc+1],s*w[f*mc+2])
		end end 
	end
end
function vfft_mt:reorder()
	local p,q,j,i,k=self.n2,self.n-1,0,0
	while i<q do
		if i<j then self:swap(i,j) end
		k=p while k<=j do j=j-k k=math.floor(k/2) end
		i=i+1 j=j+k
	end
end

local function vfft_inplace_raw_vector(vfft)
	function vfft:scale(a) 
		local v=self.v for k=1,2*self.n do v[k]=v[k]*a end
	end
	function vfft:swap(i,j) i=2*i j=2*j local v=self.v
		v[i+1],v[j+1]=v[j+1],v[i+1]
		v[i+2],v[j+2]=v[j+2],v[i+2]
	end
	function vfft:twist(i,j,wx,wy)
		i=i*2 j=j*2 local v=self.v
		local tx, ty  = v[i+1]-v[j+1], v[i+2]-v[j+2]
		v[i+1],v[i+2] = v[i+1]+v[j+1], v[i+2]+v[j+2]
		v[j+1],v[j+2] = tx*wx-ty*wy, tx*wy+ty*wx
	end
end

local fft={}

function fft.icv(p) -- inplace complex vector [2*2^p] { x1,y1,...,xn,yn }
	local fft=setmetatable({},{__index=vfft_mt})
	fft:init(p) vfft_inplace_raw_vector(fft) fft.sqn=math.sqrt(1/fft.n)
	function fft:forward(z) 
		self.v=z fft:core(-1) fft:reorder() fft:scale(fft.sqn)
	end
	function fft:backward(z) 
		self.v=z fft:core(1) fft:reorder() fft:scale(fft.sqn)
	end
	return fft
end

function fft.rv(p) -- real vector [2^p] { x1,x2,...,xn } <-> { g0,gn,gx1,gy1,gx2,gy2,... }
	local fft=setmetatable({},{__index=vfft_mt})
	fft:init(p) vfft_inplace_raw_vector(fft) fft.sqn=math.sqrt(1/fft.n)
	fft.v={} -- raw complex vector	
	local sq2,sqh=math.sqrt(2),math.sqrt(0.5)
	function fft:forward(f)
		local v,g=self.v,{}
		for k=1,self.n do v[2*k-1],v[2*k]=f[k],0 end
		fft:core(-1) fft:reorder() fft:scale(fft.sqn*sq2)
	 	g[1],g[2]=v[1]*sqh,v[self.n+1]*sqh
	 	for k=1,self.n2-1 do g[2*k+1],g[2*k+2]=v[2*k+1],v[2*k+2] end
	 	return g
	end
	function fft:backward(g)
		local v,f,n=self.v,{},self.n
		v[1],v[2]=g[1]*sq2,0
		for k=1,self.n2-1 do 
			local x,y=v[2*k+1], v[2*k+2]
			v[2*k+1    ],v[2*k+2    ]=x, y
			v[2*(n-k)+1],v[2*(n-k)+2]=x,-y
		end
		v[n+1],v[n+2]=g[2]*sq2,0
		fft:core(1) fft:reorder() fft:scale(fft.sqn*sqh)
		for k=1,n do f[k]=v[2*k-1] end
	 	return f
	end
	return fft
end

return fft
