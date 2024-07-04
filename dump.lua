function dump(x) 
  if type(x)=='table' then
    for k,v in pairs(x) do print(k,v) end 
  else
    print(x)
  end
end

return dump
