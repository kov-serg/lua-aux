function top(t,n,get)
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
