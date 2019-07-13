function reload(name)
	package.loaded[name]=nil
	return require(name)
end
return reload
