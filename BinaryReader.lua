local function unloader(self)
	self=self or {}
	self.size=self.size or 12
	self.pos=1
	self.list={}
	self.index={}
	self.load=self.load or function(item) end
	self.unload=self.unload or function(item) end
	self.clear=self.clear or function()
		for k,v in pairs(self.list) do self.unload(v) end
		self.list={}
		self.index={}
		self.pos=1
	end
	self.touch=self.touch or function(item) local pos,p1,v1
		pos=self.index[item]
		if pos then
			p1=self.pos-1 if p1<1 then p1=self.size end
			if pos~=p1 then
				v1=self.list[p1]
				self.list[pos],self.list[p1]=self.list[p1],self.list[pos]
				self.index[item]=p1
				self.index[v1]=pos
			end
		else
			v1=self.list[self.pos]
			if v1 then
				self.unload(v1)
				self.index[v1]=nil
			end
			self.load(item)
			self.list[self.pos]=item
			self.index[item]=self.pos
			self.pos=self.pos+1 if self.pos>self.size then self.pos=1 end
		end
	end
	return self
end

local function seq_unpack(f,data,ofs,read,limit)
	local res,rc,re,more
	limit=limit or 8
	for i=1,limit do
		rc,re=pcall(function() res=table.pack(string.unpack(f,data,ofs)) end)
		if rc then
			if res[2]~=#data+2 then return res end
			re="more"
		end
		local re1=re:match':%s*([^:]+)$' -- check for invalid format
		if re1 and re1:find('invalid') then error(re1,2) end
		more=read() if not more then error(re) end
		data=data..more
	end
	error(re)
end

local FileStreamReader={}
function newFileStreamReader(name)
	local self,err={}
	self.file,err=io.open(name,'rb')
	if not self.file then error(err,2) end
	return setmetatable(self,{__index=FileStreamReader})
end
function FileStreamReader:read(size) 
	return self.file:read(size)
end
function FileStreamReader:seek(ofs) 
	return self.file:seek('set',ofs) 
end
function FileStreamReader:size()
	local pos,res
	pos=self.file:seek()
	res=self.file:seek('end')
	self.file:seek('set',pos)
	return res
end
function FileStreamReader:close() self.file:close() end

local StringStreamReader={}
function newStringStreamReader(data)
	local res={data=data,pos=0}
	return setmetatable(res,{__index=StringStreamReader})
end
function StringStreamReader:read(size)
	local h,t=self.pos, self.pos+size
	if t>#self.data then t=#self.data end
	self.pos=t
	if h<#self.data then return self.data:sub(h+1,t+1) end
end
function StringStreamReader:seek(ofs,mode)
	self.pos=ofs
	if self.pos<0 then self.pos=0 end
	if self.pos>#self.data then self.pos=#self.data end
	return self.pos
end
function StringStreamReader:size() return #self.data end
function StringStreamReader:close() self.data="" end

local BinaryReader={}
function newBinaryReader(self)
	if type(self)=='string' then self={ filename=self } end
	self=self or {}
	self.pagesize=self.pagesize or 4096
	self.unpack_page_limit=self.unpack_page_limit or 4
	self.cache_size=self.cache_size or 32
	self.ofs=self.ofs or 0
	self.pages={}
	self.cur_page=0
	--self.datasize=nil
	self.unloader=unloader{
		size=self.cache_size,
		unload=function(page) self.pages[page]=nil end,
	}
	if self.data then self.stream=newStringStreamReader(self.data) end
	if self.filename then self.stream=newFileStreamReader(self.filename) end
	return setmetatable(self,{__index=BinaryReader})
end

function BinaryReader:eos() return self.ofs>=self:size() end
function BinaryReader:seek(pos) self.ofs=pos return self end
function BinaryReader:size()
	if not self.datasize then self.datasize=self.stream:size() end
	return self.datasize or 0
end
function BinaryReader:rewind()
	self.ofs=0
	self.datasize=nil
	return self
end
function BinaryReader:getpage(ofs,count)
	local res,wrk,page
	count=count or 1
	page=ofs//self.pagesize
	while count>0 do
		wrk=self.pages[page]
		if not wrk then
			if self.cur_page~=page then self.stream:seek(page*self.pagesize) end
			wrk=self.stream:read(self.pagesize)
			if not wrk then break end
			self.pages[page]=wrk
			if #wrk~=self.pagesize then self.cur_page=-1 
			else self.cur_page=page+1 end
		end
		if #wrk>0 then self.unloader.touch(page) end
		if not res then res=wrk else res=res..wrk end
		if #wrk<self.pagesize then break end
		count=count-1 page=page+1
	end
	return res
end
function BinaryReader:at(ofs,fn,...)
	local old,res,ok,err,args
	old=self.ofs
	args=table.pack(...)
	self:seek(ofs)
	ok,err=pcall(function()
		res=table.pack(fn(table.unpack(args)))
	end)
	self.ofs=old
	if not ok then error(err,2) end
	return table.unpack(res)
end
function BinaryReader:get_at(ofs,...)
	return self:at(ofs,self.get,self,...)
end
function BinaryReader:get_struct_at(ofs,...)
	return self:at(ofs,self.get_struct,self,...)
end
 -- <>= !4 bB i2 I2 i3 I3 i4 I4  hH lL f d c32 z s1 s2 s4 x X2 X4 X8
function BinaryReader:get(f,clip)
	local h,po,ph,pt,pc,wrk,size,res
	f=f or 1
	wrk=self:getpage(self.ofs)
	ph=self.ofs%self.pagesize
	po=self.ofs-ph
	if type(f)=='number' then
		size=f
		pt=ph+size
		self.ofs=self.ofs+size
		if pt>self.pagesize then 
			pc=pt//self.pagesize
			wrk=wrk..self:getpage(po+self.pagesize,pc)
		end
		if not clip and pt>#wrk then 
			error(string.format(
				"no data in stream. need %d bytes more",
				pt-#wrk
			),2) 
		end
		return wrk:sub(1+ph,pt)
	else
		res=seq_unpack(f,wrk,ph+1,function() 
			po=po+self.pagesize
			return self:getpage(po) 
		end,self.unpack_page_limit)
		self.ofs=self.ofs-ph+res[#res]-1
		return table.unpack(res,1,#res-1)
	end
end
function BinaryReader:peek(...)
	return self:get_at(self.ofs,...)
end
local function trace_value(name,vtype,value,ofs,size,trace)
	local space,ln,fmt,fw
	if #name>0 then space=' ' else space='' end
	if type(value)=='number' then
		fw=string.packsize(vtype)
		fmt=string.rep(' ',8-2*fw)..string.format('0x%%0%dX',2*fw)
		if vtype:match'[fd]' then fmt="%10.4g" end
		ln=name:lower()
		if ln:match "size" or ln:match "number" or ln:match "version"
			or ln:match "count"
		then
			fmt="%10d" 
		end
		trace(string.format("+%04X "..fmt.."%s%s",ofs,value,space,name))
	else
		local sv=value:gsub("[%s%z]+$",""):gsub('[\x00-\x1F\x7F-\xFF]','-')
		trace(string.format('+%04X %10s%s%s="%s"',ofs,'#'..size,space,name,sv))
	end
end
function BinaryReader:get_struct(s,r)
	r=r or {}
	local debug=self.debug or false
	local trace=self.print or print
	local p0=self.ofs
	string.gsub(s,"([%w_]*):(%S+)",function(name,type)
		local p1,value,p2
		p1=self.ofs value=self:get(type) p2=self.ofs
		if #name>0 then r[name]=value end
		if debug then trace_value(name,type,value,p1-p0,p2-p1,trace) end
	end)
	return r
end
function BinaryReader:hexdump(prm)
	local a,c,line,buf,saved_ofs,w
	if type(prm)=='number' then 
		if prm<0 then prm=self:size()-self.ofs+prm end
		prm={ size=prm }
	end
	prm=prm or {}
	if prm.at then
		saved_ofs=self.ofs
		self.ofs=prm.at
	end
	prm.size=prm.size or self:size()-self.ofs
	if prm.size<=0 then return self end
	prm.width=prm.width or 16
	prm.addr_fmt="%08X"
	prm.print=prm.print or print
	a=0
	while a<prm.size do
		line=string.format(prm.addr_fmt,self.ofs).." "
		w=prm.size-a if w>prm.width then w=prm.width end
		buf=self:get(w,true)
		for i=1,prm.width do
			if i>#buf then line=line..' --'
			else line=line..string.format(" %02X",buf:byte(i)) end
		end
		line=line..'  |'
		for i=1,prm.width do
			if i>#buf then line=line..' '
			else
				c=buf:byte(i)
				if c<32 or c>=127 then c=string.byte('.') end
				line=line..string.char(c)
			end
		end
		line=line..'|'
		prm.print(line)
		if #buf<prm.width then break end
		a=a+prm.width
	end
	if saved_ofs then self.ofs=saved_ofs end
	return self
end

-- experimental
local function seq_find(pat,data,ofs,read,limit)
	local res,rc,re,more
	limit=limit or 2
	for i=1,limit do
		res=table.pack(string.find(data,pat,ofs))
		if #res>1 and res[2]<#data then break end
		more=read() if not more then break end
		data=data..more
	end
	return res
end
-- experimental
function BinaryReader:find(f)
	local wrk,ph,po,res

	wrk=self:getpage(self.ofs)
	ph=self.ofs%self.pagesize
	po=self.ofs-ph
	res=seq_find(f,wrk,ph+1,function() 
		po=po+self.pagesize
		return self:getpage(po) 
	end)
	if #res>0 then
		res[1]=res[1]+po
		res[2]=res[2]+po
		self.ofs=res[2]
		return table.unpack(res)
	end
end
