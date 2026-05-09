local HTVideo={}

HTVideo.pixel_shader=[[
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 xy) {
	vec4 c=Texel(tex,uv), m=Texel(tex,uv+vec2(0.5,0));
	c.a=m.r; return c*color;
}
]]
function HTVideo:load(filename)
	local gr=love.graphics
	self.video=gr.newVideo(filename)
	self.w2,self.h = self.video:getDimensions()
	self.w=math.floor(self.w2/2)
	self.canvas=gr.newCanvas(self.w2,self.h)
	self.quad=gr.newQuad(0,0,self.w,self.h,self.w2,self.h)
	self.shader=gr.newShader(self.pixel_shader)
	return self
end
function HTVideo:play() self.video:play() return self end
function HTVideo:rewind() self.video:rewind() return self end
function HTVideo:isPlaying() return self.video:isPlaying() end
function HTVideo:prepare_frame(gr)
	gr.push"all"
	gr.setCanvas(self.canvas)
	gr.setColor{1,1,1}
	gr.draw(self.video)
	gr.pop()
end
function HTVideo:draw_frame(gr,...)
	-- if not self.canvas then return end
	gr.push"all"
	gr.setShader(self.shader)
	gr.draw(self.canvas,self.quad,...)
	gr.pop()
end
function HTVideo:end_frame()
end
function HTVideo:draw(gr,...)
	gr.push"all"
	local canvas=gr.newCanvas(self.w2,self.h)
	gr.setCanvas(canvas)
	gr.setColor{1,1,1}
	gr.draw(self.video)
	gr.pop()
	gr.push"all"
	gr.setShader(self.shader)
	gr.draw(canvas,self.quad,...)
	gr.pop()
end
function HTVideo.new(name)
	local self=setmetatable({},{__index=HTVideo})
	if type(name)=='string' then self:load(name) end
	return self
end

return HTVideo
