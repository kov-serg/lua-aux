-- sun calculations are based on http://aa.quae.nl/en/reken/zonpositie.html formulas
local sun={}
local grad,e,sin,asin,cos,acos,atan,tan,PI,days,J1970,J2000

PI=math.pi grad=PI/180
sin=math.sin   cos=math.cos   tan=math.tan
asin=math.asin acos=math.acos atan=math.atan
round=function(x) return math.floor(x+0.5) end

-- date/time constants and conversions
days=60*60*24
J1970=2440588
J2000=2451545
local function toJulian(date) return date/days-0.5+J1970 end
local function fromJulian(j)  return (j+0.5-J1970)*days end
local function toDays(date)   return toJulian(date)-J2000 end

-- general calculations for position
e=grad*23.4397 -- obliquity of the Earth
local function getRightAscension(l,b) return atan( sin(l)*cos(e)-tan(b)*sin(e), cos(l) ) end
local function getDeclination(l,b)    return asin( sin(b)*cos(e)+cos(b)*sin(e)*sin(l) ) end
local function getAzimuth(H,phi,dec)  return atan( sin(H), cos(H)*sin(phi)-tan(dec)*cos(phi) ) end
local function getAltitude(H,phi,dec) return asin( sin(phi)*sin(dec)+cos(phi)*cos(dec)*cos(H) ) end
local function getSiderealTime(d,lw)  return grad*(280.16 + 360.9856235*d) - lw end

-- general sun calculations
local function getSolarMeanAnomaly(d) return grad*(357.5291+0.98560028*d) end
local function getEquationOfCenter(M) return grad*(1.9148*sin(M) + 0.02*sin(2*M) + 0.0003*sin(3*M)) end
local function getEclipticLongitude(M,C)
	local P = grad*102.9372 -- perihelion of the Earth
    return M + C + P + PI
end
local function getSunCoords(d)
	local M,C,L
    M=getSolarMeanAnomaly(d)
    C=getEquationOfCenter(M)
    L=getEclipticLongitude(M,C)
    return { dec=getDeclination(L,0), ra=getRightAscension(L,0) }
end
-- moon calculations, based on http://aa.quae.nl/en/reken/hemelpositie.html formulas
local function getMoonCoords(d) -- geocentric ecliptic coordinates of the moon
	local L,M,F,l,b,dt
    L=grad*(218.316 + 13.176396*d) -- ecliptic longitude
    M=grad*(134.963 + 13.064993*d) -- mean anomaly
    F=grad*( 93.272 + 13.229350*d) -- mean distance
    l=L+grad*6.289*sin(M)   -- longitude
    b=grad*5.128*sin(F)     -- latitude
    dt=385001-20905*cos(M) -- distance to the moon in km
    return { ra=getRightAscension(l,b), dec=getDeclination(l,b), dist=dt }
end
local pos_mt={
	__tostring=function(pos)
		local az=pos.azimuth/grad if az>360 then az=az-360 end
		local alt=pos.altitude/grad
		local res=string.format("az=%.2f,alt=%.2f",az,alt)
		if pos.distance then res=res..string.format(",dist=%.0fkm",pos.distance) end
		return res
	end
}
sun.getMoonPosition=function(date,lat,lng)
	local lw,phi,d,c,H,h
    lw=-lng*grad
    phi=lat*grad
    d=toDays(date)
    c=getMoonCoords(d)
    H=getSiderealTime(d,lw)-c.ra
    h=getAltitude(H,phi,c.dec)
    -- altitude correction for refraction
    h=h + grad*0.017/tan(h+grad*10.26/(h+grad*5.10))
    return setmetatable({ azimuth=getAzimuth(H,phi,c.dec), altitude=h,distance=c.dist }, pos_mt)
end
-- calculations for illumination parameters of the moon,
-- based on http://idlastro.gsfc.nasa.gov/ftp/pro/astro/mphase.pro formulas and
-- Chapter 48 of "Astronomical Algorithms" 2nd edition by Jean Meeus
-- (Willmann-Bell, Richmond) 1998.
sun.getMoonIllumination=function(date)
	local d,s,m,sdist,phi,inc
    d=toDays(date)
    s=getSunCoords(d)
    m=getMoonCoords(d)
    sdist=149598000 -- distance from Earth to Sun in km
    phi =acos(sin(s.dec)*sin(m.dec) + cos(s.dec)*cos(m.dec)*cos(s.ra-m.ra))
    inc =atan(sdist*sin(phi), m.dist-sdist*cos(phi))
    return {
        fraction=(1+cos(inc))/2,
        angle=atan(
        	cos(s.dec)*sin(s.ra-m.ra), 
        	sin(s.dec)*cos(m.dec)-cos(s.dec)*sin(m.dec)*cos(s.ra-m.ra)
        )
    }
end
sun.getPosition=function(date,lat,lng)
	local lw,phi,d,c,H
    lw =-lng*grad
    phi=lat*grad
    d  =toDays(date)
    c=getSunCoords(d)
    H=getSiderealTime(d,lw)-c.ra
    return setmetatable({
        azimuth=getAzimuth(H, phi, c.dec),
        altitude=getAltitude(H, phi, c.dec)
    },pos_mt)
end

-- calculations for sun times
local sun_times={
    {-0.83, 'sunrise',       'sunset'      },
    { -0.3, 'sunriseEnd',    'sunsetStart' },
    {   -6, 'dawn',          'dusk'        },
    {  -12, 'nauticalDawn',  'nauticalDusk'},
    {  -18, 'nightEnd',      'night'       },
    {    6, 'goldenHourEnd', 'goldenHour'  },
}
local J0 = 0.0009
local function getJulianCycle(d,lw) return round(d-J0-lw/(2*PI)) end
local function getApproxTransit(Ht,lw,n) return J0+(Ht+lw)/(2*PI)+n end
local function getSolarTransitJ(ds, M, L) return J2000+ds+0.0053*sin(M)-0.0069*sin(2*L) end
local function getHourAngle(h, phi, d) return acos((sin(h)-sin(phi)*sin(d))/(cos(phi)*cos(d))) end

sun.getTimes=function(date,lat,lng)
	local lw,phi,d,n,ds,M,C,L
    lw=-lng*grad
    phi=lat*grad
    d=toDays(date)
    n  = getJulianCycle(d, lw)
    ds = getApproxTransit(0, lw, n)
    M = getSolarMeanAnomaly(ds)
    C = getEquationOfCenter(M)
    L = getEclipticLongitude(M, C)
    dec = getDeclination(L, 0)
    Jnoon = getSolarTransitJ(ds, M, L)
    -- returns set time for the given sun altitude
    local function getSetJ(h)
        local w = getHourAngle(h, phi, dec)
        local a = getApproxTransit(w, lw, n);
        return getSolarTransitJ(a, M, L)
    end
    local result = {
        solarNoon=fromJulian(Jnoon),
        nadir=fromJulian(Jnoon-0.5),
    }
    local i, len, time, angle, morningName, eveningName, Jset, Jrise
    for _,time in pairs(sun_times) do
        Jset =getSetJ(time[1]*grad)
        Jrise=Jnoon-(Jset-Jnoon)
        result[time[2]]=fromJulian(Jrise)
        result[time[3]]=fromJulian(Jset)
    end
    return result
end

-- helper function from seq.lua
local function top(t,n,get)
	local keys,idx,cmp={},0
	n=n or 0 get=get or function(v,k) return v,k end
	cmp=function(a,b)
		local v1,v2=table.pack(get(t[a],a)),table.pack(get(t[b],b))
		for k,v in ipairs(v1) do if v~=v2[k] then return v>v2[k] end end
		return false
	end
	for k in pairs(t) do table.insert(keys,k) end
	table.sort(keys,cmp)
	return function(ctx,prev)
		idx=idx+1 if (idx>n and n>0) or idx>#keys then return end
		return keys[idx], t[ keys[idx] ]
	end
end 

-- simple usage: sun.info{ name="Moscow", lat=55.753890, lng=37.620767 }
sun.info=function(place,t)
    local tt=t
	t=t or os.time()
	local pos=sun.getPosition(t,place.lat,place.lng)
	local moon=sun.getMoonPosition(t,place.lat,place.lng) moon.distance=nil
	local times=sun.getTimes(t,place.lat,place.lng)
	if tt==nil then times['<<< now']=t end
	local name=place.name or string.format("lat=%.6f lng=%.6f",place.lat,place.lng)
	print(string.format("%s sun(%s) moon=(%s)",name,pos,moon))
	for tn,tv in top(times,0,function(v) return -v end) do
		print(os.date("\t%X",math.floor(tv)),tn)
	end
end

return sun
