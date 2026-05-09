local svgpath={}

-- string -> iter
-- iter -> to_poligons, to_poligon, to_string
-- simplify, simplify_a4_mm, simpify_fhd_pix
-- transform, make_relative, make_absolute

local svgpath_commands={
	M={'L','move',2},    m={'l','move_rel',2},
	L={'L','line',2},    l={'l','line_rel',2},
	H={'L','hline',1},   h={'l','hline_rel',1},
	V={'L','vline',1},   v={'l','vline_rel',1},
	C={'C','curve3',6},  c={'c','curve3_rel',6},
	S={'S','curve3s',4}, s={'s','curve3s_rel',4},
	Q={'Q','curve2',4},  q={'q','curve2_rel',4},
	T={'T','curve2s',2}, t={'t','curve2s_rel',2},
	A={'A','arc',7},     a={'a','arc_rel',7},
	Z={'M','close',0},   z={'m','close',0},
}
local command_codes={}
for code,data in pairs(svgpath_commands) do command_codes[data[2]]=code end
command_codes.close='z'
svgpath.commands=svgpath_commands
svgpath.command_codes=command_codes
function svgpath.parse(d) -- svg path parser
	local p,n=1,#d
	local lci,h,t,v	-- = svg_commands.M
	local function get(pat) h,t,v=d:find("^"..pat,p) if t then p=t+1 return true end end
	local function get_arg()
		local s,m local p0=p
		local function invalid_number() error("invalid number pos="..p.." "..d:sub(p0,p),2) end
		get "%s*" if p>n then return end
		get "([%-%+]?)" s=1 if v=='-' then s=-1 end
		if not get "(%d*%.%d*)" then get "(%d+)" end
		if not t or v=="." then invalid_number() end
		m=tonumber(v)
		if get "([eE])" then if not get "([%+%-]?%d+)" then invalid_number() end
			m=m*10.0^tonumber(v)
		end
		return s*m
	end
	local function get_args(ci)
		local res={}
		for i=1,ci[3] do
			local arg=get_arg()
			if arg then table.insert(res,arg) else break end
			get "%s*[,]?" -- ship separator if any
		end
		get "%s*"
		return res
	end
	return function()
		if p>n then return end
		local ci=lci
		if get "%s*(%a)" then -- try to get next command
			ci=svgpath_commands[v]
			if not ci then error("unknown svg command "..v.." at position "..p) end
		end
		if not ci then error("no command ".." p="..p) end
		local args=get_args(ci)
		if #args<ci[3] then error("not enought arguments for command "..ci[1].." p="..p) end
		lci=svgpath_commands[ci[1]]
		return ci[2],args
	end
end

function svgpath.makeabs( iter ) -- convert to: move,line,curve2,curve3,arc,close
	local st={ x=0, y=0, px=0, py=0, ppx=0, ppy=0 }
	local function move_to(p)
		st.ppx,st.ppy=st.px,st.py
		st.px,st.py=st.x,st.y
		st.x,st.y=p[1],p[2]
		return p
	end
	local function move_tr(p) return move_to { p[1]+st.x, p[2]+st.y } end
	function st.move(args)      return "move",move_to(args) end
	function st.move_rel(args)  return "move",move_tr(args) end
	function st.line(args)      return "line",move_to(args) end
	function st.line_rel(args)  return "line",move_tr(args) end
	function st.hline(args)     return "line",move_to{ args[1],st.y } end
	function st.hline_rel(args) return "line",move_tr{ args[1],   0 } end
	function st.vline(args)     return "line",move_to{ st.x,args[1] } end
	function st.vline_rel(args) return "line",move_tr{    0,args[1] } end
	function st.curve2(args) move_to{ args[1],args[2] } move_to{ args[3],args[4] } return "curve2",args end
	function st.curve2s(args) return st.curve2{ 2*st.x-st.px, 2*st.x-st.px, args[1], args[2] } end
	function st.curve2_rel(args) local x0,y0=st.x,st.y return st.curve2{ args[1]+x0,args[2]+y0, args[3]+x0,args[4]+y0 } end
	function st.curve2s_rel(args) return st.curve2s{ args[1]+st.x,args[2]+st.y } end
	function st.curve3(args) move_to{ args[1],args[2] } move_to{ args[3],args[4] } move_to{ args[5],args[6] } return "curve3",args end
	function st.curve3s(args) return st.curve3{ 2*st.x-st.px,2*st.x-st.px, args[1],args[2],args[3],args[4] } end
	function st.curve3_rel(args) local x0,y0=st.x,st.y return st.curve3{ args[1]+x0,args[2]+y0, args[3]+x0,args[4]+y0, args[5]+x0, args[6]+y0 } end
	function st.curve3s_rel(args) local x0,y0=st.x,st.y return st.curve2s{ args[1]+x0,args[2]+st.y0, args[3]+x0,args[4]+y0 } end
	function st.arc(args) move_to{ args[6],args[7] } return "arc",args end
	function st.arc_rel(args) return st.arc{ args[1],args[2], args[3], args[4],args[5], args[6]+st.x,args[7]+st.y } end
	function st.close(args) return "close",args end
	return function()
		local op,args=iter()
		if op then return st[op](args) end
	end
end

local function arc_prm(rx,ry,xrot,lf,sf,dx,dy)
	local L2,L,C0,K0,K1,K2,K3,kx2,ky2,d2,d,p1,p2,a,c,s,lx,ly
	local Ax,Ay,Bx,By,Cx,Cy,a1,a2
	local eps=1e-12
	local atan=math.atan2 or math.atan -- lua5.1 atan2, lua 5.3 atan
	local pi,sin,cos,sqrt=math.pi,math.sin,math.cos,math.sqrt
	L2=dx*dx+dy*dy
	if L2==0 then return { rx=0,ry=0,a=0,cx=0,cy=0,a1=0,a2=0 } end
	L=sqrt(L2)
	if rx<=0 or ry<=0 then return {
			rx=0.5*L, ry=0, a=atan(dy,dx), a1=pi, a2=0,
			cx=0.5*dx, cy=0.5*dy
		}
	end
	a=xrot*pi/180.0
	c,s=cos(a),sin(a)
	dx,dy=c*dx+s*dy,c*dy-s*dx
	lx=dx/L ly=dy/L
	kx2=1.0/(rx*rx)
	ky2=1.0/(ry*ry)
	K0=lx*ly*(kx2-ky2)
	K1=lx*lx*kx2+ly*ly*ky2
	K2=ly*ly*kx2+lx*lx*ky2
	K3=0.25*L2*K1
	d2=(K3-1)/(K0*K0/K1-K2)
	if d2<=0 then
		d=sqrt(K3)
		rx,ry,d=rx*d,ry*d,eps
	else
		d=sqrt(d2)
	end
	if sf~=lf then d=-d end
	C0=d*K0/K1
	p1=C0-0.5*L
	p2=C0+0.5*L
	Ax,Ay = -d*ly+p1*lx, d*lx+p1*ly
	Bx,By = -d*ly+p2*lx, d*lx+p2*ly
	Cx,Cy = -Ax*c+s*Ay, -Ax*s-Ay*c	
	a1=atan(Ay*rx,Ax*ry)
	a2=atan(By*rx,Bx*ry)
	if a1>a2 then a2=a2+2*pi end
	if lf~=(a2-a1>pi) then a2=a2-2*pi end
	return { rx=rx, ry=ry, a=a, cx=Cx, cy=Cy, a1=a1, a2=a2 }
end

function svgpath.makelines(d,prm) -- move line close
	prm=prm or {}
	prm.subdiv=prm.subdiv or 32
	if prm.no_close_line==nil then prm.no_close_line=false end
	local first,x,y,fx,fy=true,0,0,0,0
	local iter=svgpath.makeabs(svgpath.parse(d))
	local st={}
	function st.close()
		local it=0
		if prm.no_close_line or first or (fx==x and fy==y) then it=1 end
		return function() it=it+1
			if it==1 then return "line",{ fx,fy }
			elseif it==2 then first=true return "close",{} end
		end
	end
	function st.curve2(args)
		local it,n=0,prm.subdiv
		local function c(t) local q=1-t return q*q,2*q*t,t*t end
		local function xy(t)
			local w1,w2,w3=c(t)
			return { x*w1+args[1]*w2+args[3]*w3, y*w1+args[2]*w2+args[4]*w3 }
		end
		return function() it=it+1 if it<=n then return "line",xy(it/n) end end
	end
	function st.curve3(args)
		local it,n=0,prm.subdiv
		local function c(t)
			local tt,q=t*t,1-t
			local qq=q*q
			return qq*q,3*qq*t,3*q*tt,tt*t
		end
		local function xy(t)
			local w1,w2,w3,w4=c(t)
			return { x*w1+args[1]*w2+args[3]*w3+args[5]*w4, y*w1+args[2]*w2+args[4]*w3+args[6]*w4 }
		end
		return function() it=it+1 if it<=n then return "line",xy(it/n) end end
	end
	function st.arc(args)
		local it,n=0,prm.subdiv
		local x0,y0=x,y --     rx,     ry,    xrot,         lf,        sf,         dx,        dy
		local prm=arc_prm(args[1],args[2], args[3], args[4]==0,args[5]==0, args[6]-x0,args[7]-y0) 
		local da=(prm.a2-prm.a1)/n
		local sin,cos=math.sin, math.cos
		local c,s=cos(prm.a),sin(prm.a)
		local function xy()
			local a=prm.a1+it*da
			local x,y=prm.rx*cos(a), prm.ry*sin(a)
			return { x0+prm.cx+x*c-y*s, y0+prm.cy+x*s+y*c }
		end
		return function() it=it+1 if it<=n then return "line",xy() end end
	end
	local nop=function() end
	local fn=nop
	return function(...)
		local op,args=fn()
		if not op then
			op,args=iter()
			if op then
				if st[op] then
					fn=st[op](args)
					op,args=fn()
				else fn=nop end
			end
		end
		if op=="move" then first=true  x,y=args[1],args[2] fx,fy=x,y
		elseif op=="line" then first=false x,y=args[1],args[2] end
		if args and #args==2 then
			local q=65536
			args[1]=args[1]+q-q
			args[2]=args[2]+q-q
		end
		return op,args
	end
end

function svgpath.apply_transform(d_or_iter,m)
	m=m or {1,0,0, 0,1,0}
	local x,y=0,0
	local ma=function(p) x,y=p[1],p[2] return p end
	local mr=function(p) x,y=x+p[1],y+p[2] return p end
	local ta=function(p) return { p[1]*m[1]+p[2]*m[2]+m[3], p[1]*m[4]+p[2]*m[5]+m[6] } end
	local tr=function(p) return { p[1]*m[1]+p[2]*m[2],      p[1]*m[4]+p[2]*m[5]      } end
	local function arc_transform(arc,M) -- arc{rx,ry,xrot,ls,sf,dx,dy}, M[6]
		local a00,a01,a10,a11,t00,t01,t10,t11,a,c,s,w,rx,ry,d
		local atan=math.atan2 or math.atan
		local sin,cos,pi,sqrt=math.sin, math.cos, math.pi, math.sqrt
		a=arc.xrot/180*pi c,s=cos(a),sin(a)
		d=M[1]*M[5]-M[2]*M[4] rx,ry=arc.rx*d,arc.ry*d
		a00,a01=( c*M[5]-s*M[4])/rx,(s*M[1]-c*M[2])/rx
		a10,a11=(-s*M[5]-c*M[4])/ry,(c*M[1]+s*M[2])/ry
		t00,t01,t10,t11=a00*a00,a01*a01,a10*a10,a11*a11
		w=2*(a00*a01+a11*a10) a=0.5*atan(w,(t00-t11)+(t10-t01))
		c,s=cos(a),sin(a) c,s,w=c*c,s*s,w*c*s
		rx=1/sqrt(c*(t00+t10)+s*(t11+t01)+w)
		ry=1/sqrt(c*(t11+t01)+s*(t00+t10)-w)
		return {
			rx=rx,ry=ry,xrot=a*180/pi,lf=arc.lf,sf=arc.sf~=(d<0),
			dx=M[1]*arc.dx+M[2]*arc.dy, dy=M[4]*arc.dx+M[5]*arc.dy
		}
	end
	local opt_line_rel=function(prm)
		if prm[1]+1==1 then return 'vline_rel',{prm[2]} end
		if prm[2]+1==1 then return 'hline_rel',{prm[1]} end
		return 'line_rel',prm
	end
	local conv={
		move=function(prm) return 'move',ta(ma(prm)) end, move_rel=function(prm) return 'move_rel',tr(mr(prm)) end,
		line=function(prm) return 'line',ta(ma(prm)) end, line_rel=function(prm) return opt_line_rel( tr(mr(prm)) ) end,
		hline=function(prm) return 'line',ta(ma{prm[1],y}) end, hline_rel=function(prm) return opt_line_rel( tr(mr{prm[1],0} )) end,
		vline=function(prm) return 'line',ta(ma{x,prm[1]}) end, vline_rel=function(prm) return opt_line_rel( tr(mr{0,prm[1]} )) end,
		curve3=function(prm) 
			local p={}
			p[1],p[2]=table.unpack( ta{prm[1],prm[2]} )
			p[3],p[4]=table.unpack( ta{prm[3],prm[4]} )
			p[5],p[6]=table.unpack( ta(ma{prm[5],prm[6]}) )
			return 'curve3',p
		end,
		curve3_rel=function(prm) 
			local p={}
			p[1],p[2]=table.unpack( tr{prm[1],prm[2]} )
			p[3],p[4]=table.unpack( tr{prm[3],prm[4]} )
			p[5],p[6]=table.unpack( tr(mr{prm[5],prm[6]}) )
			return 'curve3_rel',p
		end,
		curve3s=function(prm) 
			local p={}
			p[1],p[2]=table.unpack( ta{prm[1],prm[2]} )
			p[3],p[4]=table.unpack( ta(ma{prm[3],prm[4]}) )
			return 'curve3s',p
		end,
		curve3_rel=function(prm) 
			local p={}
			p[1],p[2]=table.unpack( tr{prm[1],prm[2]} )
			p[3],p[4]=table.unpack( tr(mr{prm[3],prm[4]}) )
			return 'curve3s_rel',p
		end,
		curve2=function(prm) 
			local p={}
			p[1],p[2]=table.unpack( ta{prm[1],prm[2]} )
			p[3],p[4]=table.unpack( ta(ma{prm[3],prm[4]}) )
			return 'curve2',p
		end,
		curve2_rel=function(prm) 
			local p={}
			p[1],p[2]=table.unpack( tr{prm[1],prm[2]} )
			p[3],p[4]=table.unpack( tr(mr{prm[3],prm[4]}) )
			return 'curve2_rel',p
		end,
		curve2s=function(prm) return 'curve2s',ta(ma(prm)) end,
		curve2s_rel=function(prm) return 'curve2_rel',tr(mr(prm)) end,
		arc=function(prm)
			local p=arc_transform({ rx=prm[1],ry=prm[2], xrot=prm[3], ls=prm[4]~=0, sf=prm[5]~=0, dx=prm[6]-x, dy=prm[7]-y }, m)
			local xy=ta{prm[6],prm[7]}
			return "arc",{ p.rx, p.ry, p.xrot, p.ls and 1 or 0, p.sf and 1 or 0, xy[1], xy[2] }
		end,
		arc_rel=function(prm)
			local p=arc_transform({ rx=prm[1],ry=prm[2], xrot=prm[3], ls=prm[4]~=0, sf=prm[5]~=0, dx=prm[6], dy=prm[7] }, m)
			local xy=tr{x,y}
			return "arc_rel",{ p.rx, p.ry, p.xrot, p.ls and 1 or 0, p.sf and 1 or 0, xy[1], xy[2] }
		end,
		close=function(prm) return 'close',prm end,
	}
	local iter=d_or_iter
	if type(d_or_iter)=='string' then iter=svgpath.parse(d_or_iter) end
	return function() local op,args=iter() 
		if op then return conv[op](args) end 
	end
end
 
function svgpath.get_polygons(d,prm)
	local res={}
	local poly={}
	local closed_arr={}
	local closed=false
	local x,y=0,0
	local x0,y0=0,0
	local flush=function(close)
		if #poly>2 then
			table.insert(res,poly)
			table.insert(closed_arr,closed)
		end
		poly={} closed=false
	end
	for op,args in svgpath.makelines(d,prm) do
		if op=='move' then flush() x,y=args[1],args[2]
		elseif op=='line' then
			if #poly==0 then table.insert(poly,{x,y}) end
			table.insert(poly,{args[1],args[2]})
		elseif op=='close' then table.remove(poly) closed=true flush() end
	end
	flush()
	return res,closed_arr
end

function svgpath.polygon(d,prm)
	local p,c=svgpath.get_polygons(d,prm)
	if #p==0 then error "no polygon" end
	if #p>1 then error "more than one polygon" end
	return p[1],c[1]
end

return svgpath
