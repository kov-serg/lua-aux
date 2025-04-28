function top(t,n,get,inv)
	local keys,idx,cmp={},0
	n=n or 0 get=get or function(v,k) return v,k end
	cmp=function(a,b)
		if inv then a,b=b,a end
		local v1,v2={get(t[a],a)},{get(t[b],b)}
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
function ntop(t,n,get,inv) return top(t,n,get,not inv) end
function opairs(t) return top(t,0,function(v,k) return k end,true) end
