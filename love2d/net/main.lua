if not love then os.execute "love ." os.exit() end
love.window.setMode(1010,525,{x=7,y=29})

local app={ t=0 }
local gr=love.graphics
local socket=require "socket"

local Notes={}
function Notes:init()
	self.lines={}
	self.line_limit=16
end
function Notes:append(line)
	table.insert(self.lines,line)
	if #self.lines>self.line_limit then table.remove(self.lines,1) end
end
function Notes:draw(x,y) x=x or 0 y=y or 0
	local fnt=gr.getFont()
	local h=fnt:getHeight()
	for k,v in pairs(self.lines) do
		gr.print(v,x,y)
		y=y+h
	end
end
function Notes.new(prm)
	local res=setmetatable(prm or {},{__index=Notes})
	res:init()
	return res
end
app.notes=Notes.new()


function love.load()
	gr.setFont(gr.newFont(16))
end
function love.keypressed(key,scan,rep)
	if key=='escape' then love.event.quit() end
end
function love.draw()
	app.notes:draw(10,10)
end
function love.update(dt)
	app.t=app.t+dt
	for limit=1,100 do
		local info=love.thread.getChannel"info":pop()
		if not info then break end
		app.notes:append(info)
		print("info:\t"..info)
	end
end

local function log(...)
	local s=string.format(...)
	app.notes:append(s)
	print(s)
end
local function log_print(...)
	local s={}
	for k,v in pairs{...} do s[#s+1]=string.format("%s",v) end
	s=table.concat(s,"\t")
	app.notes:append(s)
	print(s)
end
local function dump(x,print) print=print or log_print
	if type(x)=='table' then
		for k,v in pairs(x) do print(k,v) end
	else
		print(x)
	end
end

function test()
	--app.th_server=love.thread.newThread "th_server.lua"
	--app.th_server:start()

	--app.th_client=love.thread.newThread "th_client.lua"
	--app.th_client:start()

	app.th_s1=love.thread.newThread "th_s1.lua"
	app.th_s1:start()	
	app.th_s2=love.thread.newThread "th_s2.lua"
	app.th_s2:start()

	app.th_s16=love.thread.newThread "th_s16.lua"
	app.th_s16:start()	
	app.th_s26=love.thread.newThread "th_s26.lua"
	app.th_s26:start()
end
test()

local ident=love.filesystem.getIdentity()
log("ident=%s",ident)

local appdir = love.filesystem.getAppdataDirectory()
log("appdir=%s",appdir)
local req_dir = love.filesystem.getRequirePath()
log("req_dir=%s",req_dir)
local save_dir = love.filesystem.getSaveDirectory()
log("save_dir=%s",save_dir)
local src_dir = love.filesystem.getSource()
log("src_dir=%s",src_dir)
local src_base_dir = love.filesystem.getSourceBaseDirectory()
log("src_base_dir=%s",src_base_dir)
local user_dir = love.filesystem.getUserDirectory()
log("user_dir=%s",user_dir)
local wrk_dir = love.filesystem.getWorkingDirectory()
log("wrk_dir=%s",wrk_dir)

local a=love.filesystem.getDirectoryItems(appdir)
log_print(".",#a,a)
