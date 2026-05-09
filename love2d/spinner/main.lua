if not love then os.execute 'love .' os.exit() end

local gr=love.graphics
local unpack=table.unpack or unpack
package.path="../?.lua;"..package.path

local app={
	t=0,
	makeimage=require "makeimage",
	coverfn=require "coverfn",
	color=require "color",
}
local hex=app.color.hex
local hsv=app.color.hsv
local hsl=app.color.hsl
local function fn(t) if t<0.5 then return 2*t*t end t=1-t return 1-2*t*t end

local function draw_spinner_frame(g,ctx)
	local t=ctx.frame/ctx.frames
	local cx,cy=ctx.width/2,ctx.height/2
	local r=cx*0.8
	local r0=cx*0.15
	for k=0,4 do
		for i=8,0,-1 do
			local t1=t-i*0.0025
			t1=t1-math.floor(t1)
			t1=2*fn(fn(t1))
			local a=2*math.pi*(t1+k/5+0.125)
			local x,y=cx+math.cos(a)*r,cy+math.sin(a)*r
			local color=hsv(0+72*k,75,100,1-i/9)
			g.setColor(color)
			g.ellipse("fill",x,y,r0,r0)
		end
	end
end

local function make_spinner()
	local w,h=64,64
	local nx,ny=10,10
	local spinner, spinner_data=app.makeimage.makeSpriteSheet{ 
		width=w, height=h, nx=nx, ny=ny, 
		frames=nx*ny,
		draw=draw_spinner_frame
	}
	app.makeimage.saveImageData(spinner_data,"spinner.png")
	app.spinner=app.makeimage.animatedImage{ image=spinner, width=w,height=h,nx=nx,ny=ny,count=nx*ny }
end

local function make_ring()
	local c1=app.coverfn.circleCoverFn(50,50,49)
	local c2=app.coverfn.circleCoverFn(50,50,30)
	local ring,ring_data=app.makeimage.makeImage{
		w=100, h=100,
		render=function(x,y,r,g,b,a)
			local c1,r1,f1=c1(x,y)
			local c2,r2,f2=c2(x,y)
			r,g,b=unpack( hsl(f1*360,100,50) )
			return r,g,b,c1*(1-c2)
		end,
	}
	app.makeimage.saveImageData(ring_data,"ring.png")
	app.ring=ring
end

function love.load()
	make_spinner()
	make_ring()
end

function love.draw()
	local w,h=gr:getDimensions()
	gr.setColor(hex "1b0d86")
	gr.rectangle("fill",0,0,w,h)
	gr.setColor{1,1,1}

	local x,y=love.mouse.getPosition()
	local rw,rh=app.ring:getDimensions()
	local sw,sh=app.spinner.width,app.spinner.height

	gr.push()
	gr.translate(x,y)
	gr.rotate(-app.t)
	gr.draw(app.ring,-rw/2,-rh/2)
	gr.pop()

	app.spinner:draw(gr,x-sw/2,y-sh/2)
end

function love.update(dt)
	app.t=app.t+dt
	app.spinner:update(dt)
end

function love.keypressed(key,scan,rep)
	if key=='escape' then love.event.quit() end
end