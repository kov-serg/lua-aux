local Parser={}
function parser(prm)
	prm=prm or {}
	if type(prm)=='string' then prm={text=prm} end
	prm.text=prm.text or error "no text"
	prm.h=prm.h or 1
	prm.t=prm.t or #prm.text
	if prm.t>#prm.text then prm.t=#prm.text end
	prm.pos=prm.pos or prm.h
	return setmetatable(prm,{__index=Parser})
end
function Parser:eos() return self.pos>self.t end
function Parser:rewind() self.pos=self.h end
function Parser:size() return self.t-self.h+1 end
function Parser:left() return self.t-self.pos+1 end
function Parser:seek(p)
	if p==nil then return self.pos-self.h end
	if p<0 then self.pos=self.t+p+1 else self.pos=self.h+p end
	return self
end
function Parser:skipspace(f) f=f or "%s+"
	local h,t=self.text:find("^"..f,self.pos)
	if t then self.pos=t+1 end
	return self
end
function Parser:peek(f)
	f=f or 1
	local h,t
	if type(f)=='number' then
		h,t=self.pos,self.pos+f-1
		if h>self.t then return nil end
		if t>self.t then t=self.t end
	else 
		h,t=self.text:find("^"..f,self.pos)
	end
	if t then
		if t>self.t then t=self.t if h>t then return nil end end
		return self.text:sub(h,t),t+1
	end
end
function Parser:get(f,...)
	f=f or 1
	if type(f)=='number' then
		local h,t=self.pos,self.pos+f-1
		if h>self.t then return nil end
		if t>self.t then t=self.t end
		self.pos=t+1 return self.text:sub(h,t)
	end
	if type(f)=='function' then return f(self,...) end
	if type(f)=='table' then
		for grp_idx,grp in ipairs(f) do
			if type(grp)=='string' then
				local r={ self:get(grp) }
				if #r>0 then return table.unpack(r) end
			else
				local r={ self:get(grp[1]) }
				if #r>0 then 
					if type(grp[2])=='function' then 
						return grp[2](table.unpack(r))
					elseif grp[2]==nil then 
						return grp_idx,table.unpack(r)
					else 
						return grp[2],table.unpack(r)
					end
				end
			end
		end
		return nil
	end
	local res,t=self:peek(f)
	if t then
		self.pos=t 
		return res:match(f)
	end
end
function Parser:chk(f)
	if type(f)~='string' then error "invalid argument" end
	local h,t=self.text:find("^"..f,self.pos)
	if t then
		if t>self.t then t=self.t end
		self.pos=t+1
		return h<=t
	end
	return false
end
function Parser:try(fn,...)
	local p=self.pos
	local r={ fn(self,...) }
	if not r[1] then self.pos=p end
	return table.unpack(r)
end

return parser
