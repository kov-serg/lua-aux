-- loops.lua

local Loops={}
function Loops:init() if self.context.init then self.context.init(self) end return self end
function Loops:reset() self.t_suspend=self.t_suspend-self.t self.t=0 self.iteration=0 end
function Loops:suspend(dt)
	dt=dt or self.ds_nested or self.ds_min or 0
	self.t_suspend=self.t+dt
	return self
end
function Loops:first() return self.iteration==1 end
function Loops:timeout(limit) return self.t>limit end
function Loops:switch_to(name) self.active=name self:reset() end
function Loops:exit(code) self.exit_code=code or 0 self.active=nil self:reset() end
function Loops:set(prm) for k,v in pairs(prm) do self[k]=v end return self end
function Loops:attach(...)
	for k,v in pairs{...} do table.insert(self.nested,v) end
	return self
end
-- advance time step and active loops. returns ds = time to sleep
-- .ds_min - minimal value of ds
-- .ds_max - maximal value of ds
-- returns nil if no active loops
function Loops:step(dt) 
	local ds,dsg
	if self.active then
		self.dt=dt
		self.t=self.t+dt
		for k,v in pairs(self.nested) do
			local dsv=v:step(dt) -- activate nested loops before master
			if dsv then
				if not dsg then dsg=dsv end
				if dsv<dsg then dsg=dsv end
			else
				self.nested[k]=nil
			end
		end
		self.ds_nested=dsg
		ds=self.t_suspend-self.t
		if ds<=0 then
			local fn=self.context[self.active]
			if not fn then error("no function "..self.active) end
			self.iteration=self.iteration+1
			fn(self) -- activate master loop
			if self.active then
				ds=self.t_suspend-self.t
				if ds<=0 then
					if self.t_step<=0 then self.t_suspend=self.t
					else -- has time step defined
						self.t_suspend=self.t_suspend+self.t_step
						if self.t_suspend-self.t<0 then
							ds=self.t_step + ds%self.t_step
							self.t_suspend=self.t + ds
						end
					end
					ds=self.t_suspend-self.t
				end
			else
				return -- no active loops
			end
		end
		if dsg and dsg<ds then ds=dsg end
		self.ds=ds
		if self.ds_min and ds<self.ds_min then ds=self.ds_min end
		if self.ds_max and ds>self.ds_max then ds=self.ds_max end
		return ds -- recomended suspend time till next iteration
	end
end

function loops(context)
	return setmetatable({ context=context, nested={},
		t=0, dt=0, ds=0, iteration=0, t_suspend=0, t_step=0, active="main",
	},{__index=Loops} ):init()
end
