local function log(...)
  local s=string.format(...)
  love.thread.getChannel"info":push(s)
end
local function log_print(...)
  local s={}
  for k,v in pairs{...} do s[#s+1]=string.format("%s",v) end
  s=table.concat(s,"\t")
  log("%s",s)
end
local function dump(x,print) print=print or log_print
  if type(x)=='table' then
    for k,v in pairs(x) do print(k,v) end
  else
    print(x)
  end
end
local function check(intent)
  return function(res,msg)
    if res==nil then log("fail %s (%s)",intent,msg) end
    return res,msg
  end
end
return { log=log, print=log_print, dump=dump, check=check }