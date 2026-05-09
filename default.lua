local function default(src)
	local res={}
	for k,v in pairs(src) do res[k]=v end
	return function(def)
		for k,v in pairs(def) do
			if res[k]==nil then res[k]=v end
		end
		return res
	end
end

return default