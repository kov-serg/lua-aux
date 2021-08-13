function base64(s)
	local n,a,res,b64
	b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
	n=0 a=0 s=s:gsub('[^A-Za-z0-9+/=]','');
	local function ch(a,r,n) local x={}
		a=a>>r for i=1,n do x[i]=(a>>8*(n-i))&255 end
		return string.char(table.unpack(x))
	end
	local function tl() local r=''
		if n==3 then r=ch(a,2,2)
		elseif n==2 then r=ch(a,4,1) end
		return r
	end
	res=s:gsub('[A-Za-z0-9+/=]',function(x) local r=''
		if x=='=' then r=tl() n=4 else
			a=a*64+b64:find(x)-1 n=n+1
			if n==4 then r=ch(a,0,3) n=0 a=0 end
		end
		return r
	end)
	return res..tl()
end

function create(name,decoder) decoder=decoder or base64 
	local f=io.open(name,"wb")
	return function(data) f:write(decoder(data)) f:close() end
end

function xml_encode(x) 
	local tab={ ['<']='&lt;',['>']='&gt;',
		['&']='&amp;',['"']='&quot;',["'"]='&apos;' }
	return x:gsub("[<>&'\"]",function(v) return tab[v] end)
end

function template(G) G=G or _G local fs,fn={}
	fn=function(t)
		if type(t)=='table' then G=setmetatable(t,{__index=G}) return fn end
		if type(t)=='function' then table.insert(fs,t) return fn end
		local r=t:gsub('{{([^}]+)}}',function(v)
			local g=G for i in v:gmatch("[^%.]+") do
				local p,fn=i:find('|')
				if p then fn=i:sub(p+1) i=i:sub(1,p-1) end
				if type(g[i])=='function' then g=g[i]() else g=g[i]
					if g==nil then error("no variable "..i.." in {{"..v.."}}") end
				end
				if p then fn:gsub('[^|]+',function(f)
						if G[f]==nil then error("no function "..fn.."in {{"..v.."}}") end
						g=G[f](g)
					end)
				end
			end
			return g
		end)
		for i=#fs,1,-1 do r=fs[i](r) end
		return r
	end
	return fn
end

function create_text(name,G) return create(name,template(G)) end

function ansi_encode(x)
	local tab={ ['\0']='\\0',['\n']='\\n',['\r']='\\r',
		['\t']='\\t',['\a']='\\a',['\\']='\\\\',['"']='\\"' };
	return x:gsub('[\x00-\x1f\\\"\x80-\xFF]',function(v)
		if tab[v]~=null then return tab[v] end
		return string.format("\\x%02X",string.byte(v))
	end)
end

function hex_encode(x)
	return x:gsub('.',function(v)
		return string.format("%02X",string.byte(v))
	end)
end

function string.split(s,delim,limit,plain)
	local res,pos,t,h={},1
	delim=delim or ',' limit=limit or 0 plain=plain or false
	while pos do
		h,t=s:find(delim,pos,plain)
		if h then h=h-1 t=t+1 end
		limit=limit-1 if limit==0 then h=null t=null end
		table.insert(res,s:sub(pos,h))
		pos=t
	end
	return res
end
