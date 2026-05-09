local unit={}

local default=require "default"
local gr=love.graphics

local function fix_alpha(x,y,r,g,b,a)
	if a>0 then r=r/a g=g/a b=b/a end
	return r,g,b,a
end

local function getImageData(canvas)
	if love.graphics.readbackTexture then return love.graphics.readbackTexture(canvas) end
	return canvas:newImageData() -- l12.deprecated -> love.graphics.readbackTexture
end

function unit.makeImageData(image) -- retrive imagedata
	local w,h=image:getDimensions()
	local canvas=gr.newCanvas(w,h)
	gr.push "all"
	gr.setCanvas(canvas)
	gr.setColor{0,0,0}
	gr.rectangle("fill",0,0,w,h)
	gr.setColor{1,1,1}
	gr.draw(image)
	gr.pop()
	local data=getImageData(canvas)
	data:mapPixel(fix_alpha)
	return data
end

function unit.makeImage(prm)
	prm=default(prm) { w=64, h=64, msaa=16, draw=function(g,prm) end, render=fix_alpha }
	local data
	if prm.draw then -- draw=function(g) end
		local canvas=gr.newCanvas(prm.w,prm.h,{ msaa=prm.msaa })
		gr.push "all"
		gr.setCanvas(canvas)
		prm.draw(gr)
		gr.pop()
		data=getImageData(canvas)
	else
		data=love.image.newImageData(prm.w,prm.h,"rgba8")
	end
	if prm.render then -- render=function(x,y,r,g,b,a) return r,g,b,a end
		data:mapPixel(prm.render)
	end
	return gr.newImage(data), data
end

function unit.saveImageData(data,filename)
	local f,err=io.open(filename,"wb+") if err then error(err) end
	f:write( data:encode("png"):getString() )
	f:close()
end

function unit.saveImage(image,filename,format)
	saveImageData(makeImageData(image),filename,format)
end

function unit.scaleImageDataDown2x(src)
	local w,h=math.floor(src:getWidth()/2),math.floor(src:getHeight()/2)
	local dst=love.image.newImageData(w,h)
	dst:mapPixel(function(x,y,r,g,b,a)
		local r1,g1,b1,a1=src:getPixel(2*x,2*y)
		local r2,g2,b2,a2=src:getPixel(2*x+1,2*y)
		local r3,g3,b3,a3=src:getPixel(2*x,2*y+1)
		local r4,g4,b4,a4=src:getPixel(2*x+1,2*y+1)
		a=a1+a2+a3+a4
		if a>0 then
		r,g,b=
			(r1*a1+r2*a2+r3*a3+r4*a4)/a,
			(g1*a1+g2*a2+g3*a3+g4*a4)/a,
			(b1*a1+b2*a2+b3*a3+b4*a4)/a
		end
		a=a*0.25
		return r,g,b,a
	end)
	return gr.newImage(dst),dst
end

function unit.scaleImageDataDownNx(src,n)
	if n==1 then return gr.newImage(src),src end
	if n==2 then return scaleImageDataDown2x(src) end
	local w,h=math.floor(src:getWidth()/n),math.floor(src:getHeight()/n)
	local dst=love.image.newImageData(w,h)
	local nn=n*n
	local w={}
	dst:mapPixel(function(x,y,r,g,b,a)
		local k=1 a=0 for iy=0,n-1 do for ix=0,n-1 do w[k]={ src:getPixel(n*x+ix,n*y+iy) } a=a+w[k][4] k=k+1 end end
		if a>0 then
			r,g,b=0,0,0 for k=1,nn do local t=w[k][4] r=r+w[k][1]*t g=g+w[k][2]*t b=b+w[k][3]*t end
			r=r/a g=g/a b=b/a a=a/nn
		end
		return r,g,b,a
	end)
	return gr.newImage(dst),dst
end

function unit.makeSpriteSheet(prm)
	prm=default(prm) {
		width=64, height=64,
		nx=4, ny=2, frames=8,
		filename=false,       -- "spritesheet.png",
		frame_filename=false, -- "frame-%04d.png",
		draw=function(g,frame,t) end,
		msaa=16, upscale=1,
	}
	local ctx={ width=prm.width*prm.upscale, height=prm.height*prm.upscale, frames=prm.frames }
	local ssw,ssh=prm.width*prm.nx,prm.height*prm.ny
	local ix,iy=0,0
	local spritesheet=gr.newCanvas(ssw,ssh)
	gr.push"all"
	local render if prm.render then render=function(x,y,r,g,b,a) return prm.render(x,y,r,g,b,a,ctx) end end
	for frame=1,prm.frames do
		ctx.frame=frame-1
		local img,data=unit.makeImage{ w=prm.width*prm.upscale, h=prm.height*prm.upscale, msaa=prm.msaa, draw=function(g) prm.draw(g,ctx) end, render=render }
		if prm.upscale>1 then img,data=unit.scaleImageDataDownNx(data,prm.upscale) end
		if prm.frame_filename then
			local filename=string.format(prm.frame_filename,frame)
			unit.saveImageData(data,filename)
		end
		if iy<prm.ny then
			local old=gr.getCanvas()
			gr.setCanvas(spritesheet) gr.draw(img,ix*prm.width,iy*prm.height)
			ix=ix+1 if ix>=prm.nx then ix=0 iy=iy+1 end
		end
	end
	gr.pop()
	local data=getImageData(spritesheet)
	data:mapPixel(fix_alpha)
	if prm.filename then unit.saveImageData(data,prm.filename) end
	return gr.newImage(data),data
end

function unit.animatedImage(prm)
	local self=default(prm) {
		width=64, height=64,
		nx=8, ny=8, count=64, index0=0,
		step=1/60, t=0, index=0,
	}
	function self:update(dt)
		self.t=self.t+dt
		local tp=self.step*self.count
		if self.t>=tp then self.t=self.t-tp
			if self.t>=tp then self.t=self.t-math.floor(self.t/tp)*tp end
		end
		self.index=self.index0+math.floor(self.t/self.step)
	end
	function self:draw(g,x,y)
		self:drawFrame(g,self.index,x,y)
	end
	function self:drawFrame(g,i,x,y)
		if i<0 or i>=self.count then return end
		local ix,iy=i%self.nx, math.floor(i/self.nx)
		local q=g.newQuad(self.width*ix,self.height*iy,self.width,self.height,self.image)
		g.draw(self.image,q,x,y)
	end
	return self
end

return unit
