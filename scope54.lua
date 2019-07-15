-- scope54.lua - scope for lua 5.4.0 only

function scope() 
  local list,first,res={},true
  local function close()
    for i=#list,1,-1 do list[i].fn(list[i].arg) end
    list={}
  end
  local function auto(close,msg)
    return function(t)
      if type(t)~='table' then close() error("need table: { expression }",2) end
      if t[1] then table.insert(list,{ arg=t[1], fn=close or io.close })
      else
        if msg=='weak' then return table.unpack(t) end
        close() error(msg or t[2] or "no resource",2) 
      end
      return table.unpack(t)
    end
  end
  local function defer(fn) auto(fn){true} end
  return function(ctx,prev)
    if first then first=false return auto,defer end
  end,nil,nil,setmetatable({},{__close=close})
end

--[[usage:
for auto,defer in scope() do
  defer(function() print"defer" end)
  local f=auto(io.close){ io.open "scope54.lua"}
  print(f:read())
end
]]

local function check(fn)
  local supported=false
  for auto,defer in scope() do
    defer(function() supported=true end)
  end
  if not supported then error "Need Lua 5.4" end
  return fn
end

return check(scope)
