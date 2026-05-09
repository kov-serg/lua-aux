if not love then os.execute 'love .' os.exit() end
local gr=love.graphics
local HTVideo=require "htvideo"

local app={t=0}

local function hslcolor(h,s,l,a)
	local r,g,b,q,p
	h=h/360 s=s/100 l=l/100
	h=h-math.floor(h)
	if s==0 then r,g,b=l,l,l -- achromatic
	else
		local c3,c23,c6=1/3,2/3,1/6
		local function hue2rgb(p,q,t)
			if t<0 then t=t + 1 end
			if t>1 then t=t - 1 end
			if t<c6 then return p+(q-p)*6*t end
			if t<0.5 then return q end
			if t<c23 then return p+(q-p)*(c23-t)*6 end
			return p;
		end
		if l<0.5 then q=l*(1+s) else q=l+s-l*s end
		p=2*l-q
		r=hue2rgb(p,q,h+c3)
		g=hue2rgb(p,q,h)
		b=hue2rgb(p,q,h-c3)
	end
	return {r,g,b,a}
end

function love.load()
	gr.setFont(gr.newFont(20))
	-- app.img1=gr.newImage("back.jpg")
	app.htv1=HTVideo.new("girl.ogv"):play()
	love.mouse.setVisible(false)
	love.window.setFullscreen(true)
end

function placein(sw,sh,w,h)
	local k=math.min(sw/w, sh/h)
	return w*k, h*k
end

function love.draw()
	local color1=hslcolor(app.t*40,50,35)
	local color2=hslcolor(app.t*40,50,80)
	local w,h=gr:getDimensions()

	gr.setColor(color1)
	if app.img1 then gr.draw(app.img1) else gr.rectangle("fill",0,0,w,h) end
	gr.setColor{1,1,1}

	if app.htv1 then
		if not app.htv1:isPlaying() then app.htv1:rewind() end

		gr.setColor(color2)
		local k=math.min(1,h/app.htv1.h)
		local vx,vy=k*app.htv1.w, k*app.htv1.h
		local x1,x2,y1 = 0,w-vx,h-vy

		app.htv1:prepare_frame(gr)
		app.htv1:draw_frame(gr,x1,y1,0,k,k)
		app.htv1:draw_frame(gr,x2,y1,0,k,k)
		app.htv1:end_frame()
	end

	if not love.window.getFullscreen() then
		gr.setColor{1,1,1}
		local s=string.format("t=%.2fs",app.t)
		gr.print(s,10,10)
	end
end

function love.update(dt)
	app.t=app.t+dt
end

function love.keypressed(key,scan,rep)
	if key=='escape' then love.event.quit() end
	if key=='f11' then
		local fs=not love.window.getFullscreen()
		love.mouse.setVisible(not fs)
		love.window.setFullscreen(fs)
	end
end
