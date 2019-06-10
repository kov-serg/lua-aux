-- Packet.lua
local packet_print_value

local Packet_mt={
	eos=function(p) return p.pos>#p.data end,
	size=function(p) return #p.data end,
	rewind=function(p) p.pos=1 return p end,
	clear=function(p) p.pos=1 p.data="" return p end,
	set_ofs=function(p,ofs) p.pos=ofs+1 return p end,
	get=function(p,f) -- <>= !4 bB hH lL i3 I3 f d c32 z s1 s2 s4 x X2 X4 X8
		if type(f)=='number' then
			local r=string.sub(p.data,p.pos,p.pos+f-1)
			p.pos=p.pos+f
			return r
		end
		local r=table.pack(string.unpack(f or 'B',p.data,p.pos))
		p.pos=r[#r] return table.unpack(r,1,#r-1)
	end,
	get_struct=function(p,s,r) r=r or {}
		local debug,trace,p0=r.debug or false,r.print or print,p.pos
		string.gsub(s,"([%w_]*):(%S+)",function(name,type)
			local p1,value,p2
			p1=p.pos value=p:get(type) p2=p.pos
			if #name>0 then r[name]=value end
			if debug then packet_print_value(name,type,value,p1-p0,p2-p1,trace) end
		end)
		return r
	end,
	put=function(p,v,f)
		if f==nil and type(v)=="string" then p.data=p.data .. v
		else p.data = p.data .. string.pack(f or "B",v) end
		return p
	end,
	put_struct=function(p,s,r0)
		local fn=function(r)
			string.gsub(s,"([%w_]*):(%S+)",function(name,type) p:put(r[name],type) end)
			return p
		end
		if r0~=nil then return fn(r0) end
		return fn
	end,
	pack=function(p,f,...)
		if nil==... then return function(t)
			p.data=p.data .. string.pack(f,table.unpack(t))
			return p
		end end
		local v=...
		if type(v)=='table' then
			p.data=p.data .. string.pack(f,table.unpack(v))
			return p
		end
		p.data=p.data .. string.pack(f,...)
		return p
	end,
	hex=function(p,s)
		if s==nil or type(s)=='number' then -- read hex
			local r=p:get(s)
			r=r:gsub('.',function(x) return string.format("%02X",string.byte(x)) end)
			return r
		else -- write hex string
			string.gsub(s,"%x%x",function(x) p:put(tonumber(x,16)) end)
			return p
		end
	end,
}

function Packet(p)
	if type(p)=='string' then p={data=p} end
	p=p or {}
	p.data=p.data or ""
	p.pos=p.pos or 1
	return setmetatable(p,{__index=Packet_mt})
end

function packet_print_value(name,vtype,value,ofs,size,print)
	local space,ln,fmt
	print=print or print
	if #name>0 then space=' ' else space='' end
	if type(value)=='number' then
		fmt='0x%016X'
		if vtype=='l' or vtype=='L' then fmt='0x%08X' end
		if vtype=='h' or vtype=='H' then fmt='    0x%04X' end
		if vtype=='b' or vtype=='B' then fmt='      0x%02X' end
		ln=name:lower()
		if ln:match "size" or ln:match "number"or ln:match "version"
			 or ln:match "count"
		then
			fmt="%10d" 
		end
		print(string.format("+%04X "..fmt.."%s%s",ofs,value,space,name))
	else
		local sv=value:gsub("[%s%z]+$",""):gsub('[\x00-\x1F\x7F-\xFF]','-')
		print(string.format('+%04X %10s%s%s="%s"',ofs,'#'..size,space,name,sv))
	end
end

function Packet_mt:hexdump(prm)
	local c,res,line,a,t,u,left
	if type(prm)=='number' then prm={len=prm} end
	prm=prm or {}
	prm.width=prm.w or 16
	prm.zero=prm.zero or 0
	prm.addr=prm.addr or self.pos-1
	if prm.addr_fmt==nil then
		if #self.data<0x10000 then prm.addr_fmt="%04X"
		else  prm.addr_fmt="%08X" end
	end
	prm.len=prm.len or #self.data-prm.addr
	res=""
	a=prm.addr
	t=a+prm.len
	if t>#self.data then t=#self.data end
	while a<t do
		line=string.format(prm.addr_fmt,a-prm.zero).." "
		for i=1,prm.width do 
			u=a+i
			if u>0 and u<=t and u<#self.data then
				line=line..string.format(" %02X",string.byte(self.data,u)) 
			else
				line=line.." --"
			end
		end
		line=line.." |"
		for i=1,prm.width do
			u=a+i
			if u>0 and u<=t and u<=#self.data then
				c=string.byte(self.data,u)
				if c<32 or c>=127 then c=string.byte('.') end
			else
				c=string.byte(' ')
			end
			line=line..string.char(c)
		end
		line=line.."|\n"
		res=res..line
		a=a+prm.width
	end
	return res
end

--[[usage example:

require "Packet"

p=Packet()
p:put(1):put(2):put_struct "x:H y:H" {x=123,y=456} :pack"BHI3L" {1,2,3,4} :hex"AA55"
v1=p:get()
v2=p:get()
s1=p:get_struct "x:H y:H"
a,b,c,d=p:get"BHI3L"
m=p:get"H"

print(p:hexdump())

]]
