local color={}

function color.hsv(h,s,v,a)
    local r,g,b,i,f,p,q,t
    h=h/360 s=s/100 v=v/100
    h=h-math.floor(h)
    i=math.floor(h*6) f=h*6-i p=v*(1-s) q=v*(1-f*s) t=v*(1-(1-f)*s) i=i%6
    if     i==0 then r,g,b=v,t,p
    elseif i==1 then r,g,b=q,v,p
    elseif i==2 then r,g,b=p,v,t
    elseif i==3 then r,g,b=p,q,v
    elseif i==4 then r,g,b=t,p,v
    elseif i==5 then r,g,b=v,p,q end
    return {r,g,b,a}
end

function color.hsl(h,s,l,a)
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

function color.hex(rgba) -- #rgb #rrggbb #rrggbbaa
    local t={}
    if #rgba<6 then rgba:gsub("%x",function(x) table.insert(t,tonumber(x,16)/15) end)
    else rgba:gsub("%x%x",function(x) table.insert(t,tonumber(x,16)/255) end) end
    return t
end

function color.tohex(rgb)
    local hex=function(c)
        if c<0 then c=0 end
        if c>1 then c=1 end
        return string.format("%02X",math.floor(255*c+0.5))
    end
    local res=hex(rgb[1])..hex(rgb[2])..hex(rgb[3])
    if #rgb>3 then res=res..hex(rgb[4]) end 
    return res
end

function color.srgb_to_lin(u)
    local a,b,c,d,g
    if u<0 then return 0 end
    if u>1 then return 1 end
    a=1/1.055 b=0.055/1.055 c=1/12.92 d=0.04045 g=2.4
    if u<d then return c*u end
    return (a*u+b)^g
end

function color.lin_to_srgb(u)
    local a,b,c,d,g
    if u<0 then return 0 end
    if u>1 then return 1 end
    a=1.055 b=-0.055 c=12.92 d=0.0031308 g=1/2.4
    if u<d then return c*u end
    return a*u^g+b
end

function color.gray(rgb)
    local c=0.299*rgb[1]+0.587*rgb[2]+0.114*rgb[3]
    if c<0 then c=0 end
    if c>1 then c=1 end
    return c
end

function color.rgba2(c1,c2) -- !! f(a,b)!=f(b,a)
    local a1,a2=c1[4] or 1,c2[4] or 1
    local a=a1+a2-a1*a2 if a==0 then return {0,0,0,0} end
    local k1,k2=(1-a2)*a1/a,a2/a
    return { c1[1]*k1+c2[1]*k2, c1[2]*k1+c2[2]*k2, c1[3]*k1+c2[3]*k2, a }
end

return color
