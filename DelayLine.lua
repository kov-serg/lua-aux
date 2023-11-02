local DelayLine={}

function DelayLine:update(dt)
	self.t=self.t+dt
	local k=#self.queue
	while k>0 do
		if self.sorted then
			local item=self.queue[k]
			if item.t>self.t then break end
			table.remove(self.queue,k)
			item.fn()
		else
			table.sort(self.queue,function(a,b) return a.t>b.t end)
			self.sorted=true
		end
		k=#self.queue
	end
	if k==0 then self.t=0 end
end

function DelayLine:call(dt,fn)
	local item={ t=self.t+dt, fn=fn }
	if self.sorted then
		local n=#self.queue
		if n<1 then self.sorted=true
		elseif item.t>=self.queue[n].t then self.sorted=false end
	end
	table.insert(self.queue,item)
	return self
end

function DelayLine:play(fn)
	local cor,delay
	delay=function(dt)
		self:call(dt,function()
			local ok,msg=coroutine.resume(cor)
			if msg then error(("error in play\nlua: %s"):format(msg),3) end
		end)
		return coroutine.yield()
	end
	cor=coroutine.create(function() 
		local ok,err=pcall(function() fn(delay) end)
		if not ok then coroutine.yield(err) end
	end)
	coroutine.resume(cor)
	return self	
end

function newDelayLine()
	return setmetatable({t=0,queue={}},{__index=DelayLine})
end
