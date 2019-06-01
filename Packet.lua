-- Packet.lua

local Packet_mt={
	eos=function(p) return p.pos>#p.data end,
	size=function(p) return #p.data end,
	rewind=function(p) p.pos=1 return p end,
	clear=function(p) p.pos=1 p.data="" return p end,
	get=function(p,f) -- <>= !4 bB hH lL i3 I3 f d c32 z s1 s2 s4 x X2 X4 X8
		local r=table.pack(string.unpack(f or 'B',p.data,p.pos))
		p.pos=r[#r] return table.unpack(r,1,#r-1)
	end,
	get_struct=function(p,s,r) r=r or {}
		string.gsub(s,"(%a[%w_]*):(%S+)",function(name,type) r[name]=p:get(type) end)
		return r
	end,
	put=function(p,v,f)
		if f==nil and type(v)=="string" then p.data=p.data .. v
		else p.data = p.data .. string.pack(f or "B",v) end
		return p
	end,
	put_struct=function(p,s,r0)
		local fn=function(r)
			string.gsub(s,"(%a[%w_]*):(%S+)",function(name,type) p:put(r[name],type) end)
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
		string.gsub(s,"%x%x",function(x) p:put(tonumber(x,16)) end)
		return p
	end,
	hexdump=function(p,w,a,af)
		local c,res,line
		w=w or 16 a=a or 0 af=af or "%04X"		
		res=""
		while a<#p.data do
			line=string.format("%04X ",a)

			for i=1,w do 
				if i+a<=#p.data then line=line..string.format(" %02X",string.byte(p.data,i+a)) 
				else line=line.." --" end
			end
			line=line.." |"
			for i=1,w do 
				c=a+i<=#p.data and string.byte(p.data,a+i) or string.byte(' ')
				if c<32 or c>=127 then c=string.byte('.') end				
				line=line..string.char(c)
			end
			line=line.."|\n"
			res=res..line
			a=a+w
		end
		return res
	end,
}

function Packet(p)
	p=p or {}
	p.data=p.data or ""
	p.pos=p.pos or 1
	return setmetatable(p,{__index=Packet_mt})
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
