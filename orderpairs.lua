function orderpairs(t,cmp)
	local keys,idx={},0
	cmp=cmp or function(a,b) return a<b end
	for k in pairs(t) do table.insert(keys,k) end
	table.sort(keys,cmp)
	return function(ctx,prev)
		idx=idx+1 if idx>#keys then return end
		return keys[idx], t[keys[idx]]
	end
end
