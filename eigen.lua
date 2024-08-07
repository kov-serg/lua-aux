require "complex"
require "vector"
require "matrix"
require "qsort"

local EigenReal={ eps=2^-52 }

local function sqr(x) return x*x end

local function hypot(x,y)
  x,y=math.abs(x),math.abs(y)
  if x>=y then y=y/x return x*math.sqrt(1+y*y) end
  if y~=0 then x=x/y return y*math.sqrt(1+x*x) end
  return 0
end

local function cdiv(xr,xi,yr,yi)
  local zr,zi,r,d
  if math.abs(yr) > math.abs(yi) then
    r=yi/yr d=yr+r*yi
    zr=(xr+r*xi)/d
    zi=(xi-r*xr)/d
  else
    r=yr/yi d=yi+r*yr
    zr=(r*xr+xi)/d
    zi=(r*xi-xr)/d
  end
  return zr,zi
end

local function eq(x,y,eps)
  eps=eps or 1e-16
  local d,s=math.abs(x-y),math.abs(x)+math.abs(y)
  if d+eps==eps then return true end
  return d<eps*s
end

function EigenReal:checkSymmetric(A)
  local n,eps=A.dim,self.eps
  for i=1,n-1 do
    for j=i+1,n do
      if not eq(A:get(i,j),A:get(j,i),eps) then return false end
    end
  end
  return true
end

function EigenReal:hqr2() -- Nonsymmetric reduction from Hessenberg to real Schur form
  --  This is derived from the Algol procedure hqr2,
  --  by Martin and Wilkinson, Handbook for Auto. Comp.,
  --  Vol.ii-Linear Algebra, and the corresponding
  --  Fortran subroutine in EISPACK.

  -- Initialize
  local eps=self.eps
  local low,high,exshift=1,self.n
  local n,p,q,r,s,z,t,w,x,y,norm,iter,l,m,notlast,ra,sa,vr,vi,zi,zr
  local nn,H,V,d,e=self.n,self.H,self.V,self.d,self.e

  p=0 q=0 r=0 s=0 z=0 exshift=0.0
  -- Store roots isolated by balanc and compute matrix norm
  norm=0.0
  for i=1,nn do
    if i<low or i>high then d[i]=H:get(i,i) e[i]=0.0 end
    for j=math.max(i-1,1),nn do norm=norm+math.abs(H:get(i,j)) end
  end
  -- Outer loop over eigenvalue index
  iter=0
  n=self.n while n>=low do
    -- Look for single small sub-diagonal element
    l=n while l>low do
      s=math.abs(H:get(l-1,l-1)) + math.abs(H:get(l,l))
      if s==0.0 then s=norm end
      if math.abs(H:get(l,l-1))<eps*s then break end
      l=l-1
    end
    -- Check for convergence
    -- One root found
    if l==n then
      H:add(n,n, exshift )
      d[n]=H:get(n,n) e[n]=0.0
      n=n-1 iter=0
      -- Two roots found
    elseif l==n-1 then
      w=H:get(n,n-1)*H:get(n-1,n)
      p=(H:get(n-1,n-1)-H:get(n,n))*0.5
      q=p*p+w
      z=math.sqrt(math.abs(q))
      H:add(n  ,n  , exshift )
      H:add(n-1,n-1, exshift )
      x=H:get(n,n)
      -- Real pair
      if q>=0 then
        if p>=0 then z=p+z else z=p-z end
        d[n-1]=x+z d[n]=d[n-1]
        if z~=0 then d[n]=x-w/z end
        e[n-1]=0.0 e[n]=0.0
        x=H:get(n,n-1)
        s=math.abs(x)+math.abs(z)
        p=x/s q=z/s
        r=math.sqrt(p*p+q*q)
        p=p/r q=q/r
        -- Row modification
        for j=n-1,self.n do
          z=H:get(n-1,j)
          H:set(n-1,j, q*z + p*H:get(n,j) )
          H:set(n  ,j, q*H:get(n,j) - p*z )
        end
        -- Column modification
        for i=1,n do
          z=H:get(i,n-1)
          H:set(i,n-1, q*z + p*H:get(i,n) )
          H:set(i,n  , q*H:get(i,n) - p*z )
        end
        -- Accumulate transformations
        for i=low,high do
          z=V:get(i,n-1)
          V:set(i,n-1, q*z + p*V:get(i,n) )
          V:set(i,n  , q*V:get(i,n) - p*z )
        end
        -- Complex pair
      else
        d[n-1]=x+p d[n]=x+p
        e[n-1]=z   e[n]=-z
      end
      n=n-2 iter=0
      -- No convergence yet
    else
      -- Form shift
      x=H:get(n,n) y=0.0 w=0.0
      if l<n then
        y=H:get(n-1,n-1)
        w=H:get(n,n-1)*H:get(n-1,n)
      end
      -- Wilkinson's original ad hoc shift
      if iter==10 then
        exshift=exshift+x
        for i=low,n do H:sub(i,i, x ) end
        s=math.abs(H:get(n,n-1)) + math.abs(H:get(n-1,n-2))
        x=0.75*s y=x w=-0.4375*s*s
      end
      -- MATLAB's new ad hoc shift
      if iter==30 then
        s=(y-x)/2 s=s*s+w
        if s>0 then
          s=math.sqrt(s) if y<x then s=-s end
          s=x-w/((y-x)/2+s)
          for i=low,n do H:sub(i,i, s ) end
          exshift=exshift+s
          x=0.964 y=x w=x
        end
      end
      iter=iter+1 -- (Could check iteration count here)
      -- Look for two consecutive small sub-diagonal elements
      m=n-2
      while m>=l do
        z=H:get(m,m) r=x-z s=y-z
        p=(r*s-w)/H:get(m+1,m) + H:get(m,m+1)
        q=H:get(m+1,m+1)-z-r-s
        r=H:get(m+2,m+1)
        s=math.abs(p)+math.abs(q)+math.abs(r)
        p=p/s q=q/s r=r/s
        if m==l then break end
        if (math.abs(H:get(m,m-1)) * (math.abs(q) + math.abs(r)) <
              eps * (math.abs(p) * (math.abs(H:get(m-1,m-1)) + math.abs(z) +
              math.abs(H:get(m+1,m+1))))) then break end
        m=m-1
      end
      for i=m+2,n do H:set(i,i-2, 0.0 ) if i>m+2 then H:set(i,i-3, 0.0) end end
      -- Double QR step involving rows l:n and columns m:n
      for k=m,n-1 do
        notlast=(k~=n-1)
        if k~=m then
          p=H:get(k,k-1)
          q=H:get(k+1,k-1)
          if notlast then r=H:get(k+2,k-1) else r=0 end
          x=math.abs(p)+math.abs(q)+math.abs(r)
          if x~=0.0 then p=p/x q=q/x r=r/x end
        end
        if x==0.0 then break end
        s=math.sqrt(p*p + q*q + r*r)
        if p<0 then s=-s end
        if s~=0 then
          if k~=m then H:set(k,k-1, -s*x )
          elseif l~=m then H:set(k,k-1, -H:get(k,k-1) ) end
          p=p+s x=p/s y=q/s z=r/s q=q/p r=r/p
          -- Row modification
          for j=k,nn do
            p=H:get(k,j) + q*H:get(k+1,j)
            if notlast then p=p+r*H:get(k+2,j) H:sub(k+2,j, p*z ) end
            H:sub(k  ,j, p*x )
            H:sub(k+1,j, p*y )
          end
          -- Column modification
          for i=1,math.min(n,k+3) do
            p=x*H:get(i,k) + y*H:get(i,k+1)
            if notlast then p=p+z*H:get(i,k+2) H:sub(i,k+2, p*r ) end
            H:sub(i,k  , p   )
            H:sub(i,k+1, p*q )
          end
          -- Accumulate transformations
          for i=low,high do
            p=x*V:get(i,k) + y*V:get(i,k+1)
            if notlast then p=p+z*V:get(i,k+2) V:sub(i,k+2, p*r ) end
            V:sub(i,k  , p   )
            V:sub(i,k+1, p*q )
          end
        end -- s~=0
      end -- k loop
    end -- check convergence
  end -- while (n >= low)

  -- Backsubstitute to find vectors of upper triangular form
  if norm==0 then return end
  for n=nn,1,-1 do
    p=d[n] q=e[n]
    -- Real vector
    if q==0 then
      l=n
      H:set(n,n, 1.0)
      for i=n,1,-1 do
        w=H:get(i,i)-p
        r=0.0
        for j=l,n do r=r+H:get(i,j) * H:get(j,n) end
        if e[i]<0 then z=w s=r else
          l=i
          if e[i]==0.0 then
            if w~=0.0 then H:set(i,n, -r/w ) else H:set(i,n, -r/(eps*norm) ) end
            -- Solve real equations
          else
            x=H:get(i,i+1)
            y=H:get(i+1,i)
            q=(d[i]-p)^2 + e[i]^2
            t=(x*s-z*r)/q
            H:set(i,n, t )
            if math.abs(x) > math.abs(z) then
              H:set(i+1,n, (-r-w*t)/x )
            else
              H:set(i+1,n, (-s-y*t)/z )
            end
          end
          -- Overflow control
          t=math.abs(H:get(i,n))
          if (eps*t)*t > 1 then for j=i,n do H:div(j,n, t ) end end
        end
      end
      -- Complex vector
    elseif q<0 then
      l=n-1
      -- Last vector component imaginary so matrix is triangular
      if (math.abs(H:get(n,n-1)) > math.abs(H:get(n-1,n))) then
        H:set(n-1,n-1, q/H:get(n,n-1) )
        H:set(n-1,n  , -(H:get(n,n)-p)/H:get(n,n-1) )
      else
        zr,zi=cdiv(0.0,-H:get(n-1,n), H:get(n-1,n-1)-p,q)
        H:set(n-1,n-1, zr )
        H:set(n-1,n  , zi )
      end
      H:set(n,n-1, 0.0 )
      H:set(n,n  , 1.0 )
      for i=n-2,1,-1 do
        ra=0.0 sa=0.0
        for j=l,n do
          ra=ra+H:get(i,j)*H:get(j,n-1)
          sa=sa+H:get(i,j)*H:get(j,n)
        end
        w=H:get(i,i)-p
        if e[i]<0.0 then z=w r=ra s=sa
        else
          l=i
          if e[i]==0 then
            zr,zi=cdiv(-ra,-sa,w,q)
            H:set(i,n-1, zr )
            H:set(i,n  , zi )
          else
            -- Solve complex equations
            x=H:get(i,i+1)
            y=H:get(i+1,i)
            vr=(d[i]-p)^2 + e[i]^2 - q*q
            vi=(d[i]-p)*2.0*q
            if vr==0.0 and vi==0.0 then
              vr=eps*norm*(math.abs(w)+math.abs(q)+
                      math.abs(x)+math.abs(y)+math.abs(z))
            end
            zr,zi=cdiv(x*r-z*ra+q*sa,x*s-z*sa-q*ra,vr,vi)
            H:set(i,n-1, zr )
            H:set(i,n  , zi )
            if math.abs(x) > (math.abs(z)+math.abs(q)) then
              H:set(i+1,n-1, (-ra - w*H:get(i,n-1) + q*H:get(i,n))/x )
              H:set(i+1,n  , (-sa - w*H:get(i,n) - q*H:get(i,n-1))/x )
            else
              zr,zi=cdiv(-r-y*H:get(i,n-1),-s-y*H:get(i,n),z,q)
              H:set(i+1,n-1, zr )
              H:set(i+1,n  , zi )
            end
          end
          -- Overflow control
          t = math.max(math.abs(H:get(i,n-1)),math.abs(H:get(i,n)))
          if (eps*t)*t > 1 then
            for j=i,n do
              H:div(j,n-1, t )
              H:div(j,n  , t )
            end
          end
        end
      end
    end
  end
  -- Vectors of isolated roots
  for i=1,nn do
    if i<low or i>high then
      for j=i,nn do V:set(i,j, H:get(i,j) ) end
    end
  end
  -- Back transformation to get eigenvectors of original matrix
  for j=nn,low,-1 do
    for i=low,high do
      z=0.0 for k=low,math.min(j,high) do z=z+V:get(i,k)*H:get(k,j) end
      V:set(i,j, z )
    end
  end
  return self
end

function EigenReal:orthes()
  --  This is derived from the Algol procedures orthes and ortran,
  --  by Martin and Wilkinson, Handbook for Auto. Comp.,
  --  Vol.ii-Linear Algebra, and the corresponding
  --  Fortran subroutines in EISPACK.
  local low,high,ort,scale,h,g,f=1,self.n,vector(0,self.n)
  local H,V=self.H,self.V
  for m=low+1,high-1 do
    -- Scale column
    scale=0.0 for i=m,high do scale=scale + math.abs(H:get(i,m-1)) end
    if scale~=0.0 then
      -- Compute Householder transformation
      h=0.0 for i=high,m,-1 do ort[i]=H:get(i,m-1)/scale h=h+ort[i]^2 end
      g=math.sqrt(h) if ort[m]>0 then g=-g end
      h=h-ort[m]*g
      ort[m]=ort[m]-g
      -- Apply Householder similarity transformation
      -- H = (I-u*u'/h)*H*(I-u*u')/h)
      for j=m,self.n do
        f=0.0 for i=high,m,-1 do f=f+ort[i]*H:get(i,j) end
        f=f/h for i=m,high do H:set(i,j, H:get(i,j)-f*ort[i] ) end
      end
      for i=1,high do
        f=0.0 for j=high,m,-1 do f=f+ort[j]*H:get(i,j) end
        f=f/h for j=m,high do H:set(i,j, H:get(i,j)-f*ort[j]) end
      end
      ort[m]=scale*ort[m]
      H:set(m,m-1, scale*g )
    end
  end
  -- Accumulate transformations (Algol's ortran).
  for i=1,self.n do
    for j=1,self.n do
      if i==j then V:set(i,j,1.0) else V:set(i,j,0.0) end
    end
  end
  for m=high-1,low+1,-1 do
    if H:get(m,m-1)~=0.0 then
      for i=m+1,high do ort[i]=H:get(i,m-1) end
      for j=m,high do
        g=0.0 for i=m,high do g=g+ort[i]*V:get(i,j) end
        -- Double division avoids possible underflow
        g=(g/ort[m])/H:get(m,m-1)
        for i=m,high do V:set(i,j, V:get(i,j)+g*ort[i] ) end
      end
    end
  end
  return self
end

function EigenReal:tred2() -- symmetric Householder reduction to tridiagonal form
  -- Symmetric Householder reduction to tridiagonal form.
  --  This is derived from the Algol procedures tred2 by
  --  Bowdler, Martin, Reinsch, and Wilkinson, Handbook for
  --  Auto. Comp., Vol.ii-Linear Algebra, and the corresponding
  --  Fortran subroutine in EISPACK.
  local i,j,k, scale, kh, f,g,hh
  local d=self.d
  local n=self.n
  local V=self.V
  local e=self.e
  for j=1,n do d[j]=V:get(n,j) end
  -- Householder reduction to tridiagonal form.
  for i=n,2,-1 do
    -- Scale to avoid under/overflow.
    scale=0 kh=0
    for k=1,i-1 do scale=scale+math.abs(d[k]) end
    if scale==0 then
      e[i]=d[i-1]
      for j=1,i-1 do
        d[j]=V:get(i-1,j)
        V:set(i,j, 0 )
        V:set(j,i, 0 )
      end
    else
      -- Generate Householder vector.
      for k=1,i-1 do
        d[k]=d[k]/scale
        kh=kh+sqr(d[k])
      end
      f=d[i-1]
      g=math.sqrt(kh)
      if f>0 then g=-g end
      e[i]=scale*g
      kh=kh-f*g
      d[i-1]=f-g
      for j=1,i-1 do e[j]=0 end
      -- Apply similarity transformation to remaining columns.
      for j=1,i-1 do
        f=d[j]
        V:set(j,i, f )
        g=e[j]+V:get(j,j)*f
        for k=j+1,i-1 do
          g=g+V:get(k,j)*d[k]
          e[k]=e[k]+V:get(k,j)*f
        end
        e[j]=g
      end
      f=0
      for j=1,i-1 do
        e[j]=e[j]/kh
        f=f+e[j]*d[j]
      end
      hh=0.5*f/kh
      for j=1,i-1 do e[j]=e[j]-hh*d[j] end
      for j=1,i-1 do
        f=d[j]
        g=e[j]
        for k=j,i-1 do V:sub(k,j, f*e[k]+g*d[k] ) end
        d[j]=V:get(i-1,j)
        V:set(i,j, 0 )
      end
    end
    d[i]=kh
  end;
  -- Accumulate transformations.
  for i=1,n-1 do
    V:set(n,i, V:get(i,i) )
    V:set(i,i, 1.0 );
    kh=d[i+1];
    if kh~=0 then
      for k=1,i do d[k]=V:get(k,i+1)/kh end
      for j=1,i do
        g=0
        for k=1,i do g=g+V:get(k,i+1)*V:get(k,j) end
        for k=1,i do V:sub(k,j, g*d[k] ) end
      end
    end
    for k=1,i do V:set(k,i+1, 0 ) end
  end
  for j=1,n do
    d[j]=V:get(n,j)
    V:set(n,j, 0 )
  end
  V:set(n,n, 1.0 )
  e[0]=0.0
  return self
end

function EigenReal:tql2() -- QL: diagonalize symmetric tridiagonal form
  -- Symmetric tridiagonal QL algorithm.
  --  This is derived from the Algol procedures tql2, by
  --  Bowdler, Martin, Reinsch, and Wilkinson, Handbook for
  --  Auto. Comp., Vol.ii-Linear Algebra, and the corresponding
  --  Fortran subroutine in EISPACK.
  local i,j,l,m,k,iter
  local f,tst1,g,p,r,dl1,kh,c,c2,c3,el1,s,s2
  local eps=self.eps
  local d=self.d
  local n=self.n
  local V=self.V
  local e=self.e
  for i=2,n do e[i-1]=e[i] end e[n]=0 -- e[]<<=1;
  f=0 tst1=0
  for l=1,n do
    -- Find small subdiagonal element
    tst1=math.max(tst1,math.abs(d[l])+math.abs(e[l])) --maxf
    m=l while m<n do
      if math.abs(e[m])<=eps*tst1 then break end
      m=m+1
    end
    -- If m=l, d[l] is an eigenvalue, otherwise, iterate.
    if m>l then
      iter=0
      repeat
        iter=iter+1 -- (Could check iteration count here.)
        --ex: if iter>50 then error('no coverage, sorry. you should do something') end
        -- Compute implicit shift
        g=d[l]
        p=(d[l+1]-g)/(2*e[l])
        r=hypot(p,1.0)
        if p<0 then r=-r end
        d[l]=e[l]/(p+r)
        d[l+1]=e[l]*(p+r)
        dl1=d[l+1]
        kh=g-d[l]
        for i=l+2,n do d[i]=d[i]-kh end
        f=f+kh
        -- Implicit QL transformation.
        p=d[m]
        c=1.0 c2=c c3=c
        el1=e[l+1]
        s=0 s2=0
        for i=m-1,l,-1 do
          c3=c2 c2=c s2=s
          g=c*e[i]
          kh=c*p
          r=hypot(p,e[i])
          e[i+1]=s*r
          s=e[i]/r
          c=p/r
          p=c*d[i]-s*g
          d[i+1]=kh+s*(c*g+s*d[i])
          -- Accumulate transformation.
          for k=1,n do
            kh=V:get(k,i+1)
            V:set(k,i+1, s*V:get(k,i) + c*kh )
            V:set(k,i  , c*V:get(k,i) - s*kh )
          end
        end
        p=-s*s2*c3*el1*e[l]/dl1
        e[l]=s*p
        d[l]=c*p
        -- Check for convergence.
      until math.abs(e[l]) <= eps*tst1
    end
    d[l]=d[l]+f
    e[l]=0
  end
  -- Sort eigenvalues and corresponding vectors.
  qsort{ n=n,
    cmp=function(i,j) return d[i]-d[j] end,
    swp=function(i,j) d[i],d[j]=d[j],d[i] V:swap(i,j) end,
  }
  return self
end

function EigenReal:normalize()
  local e,V,i,k,norm,sr=self.e,self.V
  k=1 while k<=self.n do
    norm=0 sr=0
    if e[k]==0 then -- real vector
      for i=1,self.n do norm=norm+V:get(i,k)^2 sr=sr+V:get(i,k) end
      if norm~=0 then
        norm=math.sqrt(norm) if sr<0 then norm=-norm end
        for i=1,self.n do V:div(i,k,norm) end
      end
      k=k+1
    else -- complex vector
      for i=1,self.n do
        norm=norm+V:get(i,k)^2+V:get(i,k+1)^2
        sr=sr+V:get(i,k)
      end
      if norm~=0 then
        norm=math.sqrt(norm) if sr<0 then norm=-norm end
        for i=1,self.n do V:div(i,k,norm) V:div(i,k+1,norm) end
      end
      k=k+2
    end
  end
  return self
end

local function newEigen(A,symmetric)
  local self=setmetatable({},{__index=EigenReal})
  if symmetric==nil then symmetric=self:checkSymmetric(A) end
  self.n=A.dim
  self.d=vector(0,self.n)
  self.e=vector(0,self.n)
  if symmetric then
    self.V=matrix(A)
    self:tred2():tql2()
  else 
    self.H=matrix(A)
    self.V=matrix(self.n)
    self:orthes():hqr2()
  end
  self:normalize()
  return self
end

local Eigen={ EigenReal=EigenReal }

function Eigen.eigen(A,symmetric)
  local e=newEigen(A,symmetric)
  local z,k=vector(0,e.n)
  k=1 while k<=e.n do
    if e.e[k]==0 then z[k]=e.d[k] k=k+1
    else
      z[k  ]=complex{ e.d[k], e.e[k] }
      z[k+1]=complex{ e.d[k],-e.e[k] }
      k=k+2
    end
  end
  local E,V=matrix(e.n),e.V
  k=1 while k<=e.n do
    if e.e[k]==0 then
      for i=1,e.n do E:set(i,k, V:get(i,k) ) end
      k=k+1
    else
      for i=1,e.n do
        E:set(i,k  , complex{ V:get(i,k),  V:get(i,k+1) } )
        E:set(i,k+1, complex{ V:get(i,k), -V:get(i,k+1) } )
      end
      k=k+2
    end
  end
  return z,E
end

function Eigen.eigenvals(A,symmetric)
  local e=newEigen(A,symmetric)
  local z,k=vector(0,e.n)
  k=1 while k<=e.n do
    if e.e[k]==0 then z[k]=e.d[k] k=k+1
    else
      z[k  ]=complex{ e.d[k], e.e[k] }
      z[k+1]=complex{ e.d[k],-e.e[k] }
      k=k+2
    end
  end
  return z
end

return Eigen
