if not love then os.execute "love ." os.exit() end

local gr=love.graphics
local app={ P=3, CL=8 }

app.pixel_shader=string.format([[
  #define CL %d
  #define W  %d
  uniform float noise[W*W];
  vec4 effect(vec4 c,Image tex,vec2 uv,vec2 xy){
    vec4 p=Texel(tex,uv);
    int idx=int(mod(floor(xy.x),W)+W*mod(floor(xy.y),W));
    float e=noise[idx]/CL;
    vec4 q=p*c+vec4(e,e,e,0);
    q=floor(q*CL)/(CL-1);
    return q;
  }
]],app.CL,2^app.P)

function love.load()
	app.shader=gr.newShader(app.pixel_shader)
	app.shader:send("noise",unpack(gen_noise_table(app.P)))
	app.image=gr.newImage "image.png"
end

function love.draw()
	local y,x1,x2 = 8, 8, app.image:getWidth()+16
	gr.draw(app.image,x1,y)
	gr.setShader(app.shader)
	gr.draw(app.image,x2,y)
	gr.setShader()
end

function love.keypressed(key)
	if key=='escape' then love.event.quit() end
end

function gen_noise_table(p)
	local function f(x,y,n) local r=0
		for i=1,n do r=r+r+x%2 x=bit.rshift(x,1) r=r+r+y%2 y=bit.rshift(y,1) end
		return r
	end
	local r,n,k = {}, 2^p, 2/(4^p-1)
	for y=0,n-1 do for x=0,n-1 do table.insert(r,f(bit.bxor(x,y),y,p)*k-1) end end
	return r
end
