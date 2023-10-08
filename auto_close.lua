-- lua54 helper function

function auto_close()
    local list={}
    local function auto(close,msg)
        return function(t)
            if type(t)~='table' then error("need table: { expression }",2) end
            if t[1] then table.insert(list,{ arg=t[1], fn=close or io.close })
            else
                if msg=='weak' then return table.unpack(t) end
                error(msg or t[2] or "no resource",2)
            end
            return table.unpack(t)
        end
    end
    return setmetatable({ defer=function(fn) auto(fn){true} end },{
        __call=function(self,...) return auto(...) end,
        __close=function(self)
            for i=#list,1,-1 do list[i].fn(list[i].arg) end
        end
    })
end

--[[ usage:

function xopen(name) print("xopen "..name) return name end
function xclose(handle) print("xclose "..handle) end

do local auto<close> = auto_close() -- scope.begin
    print "1"
    local v1=auto(xclose) { xopen "v1" }
    print "get something" auto.defer(function() print "put it back" end)
    print "2"
    local f=auto() { io.open "readme.txt" }
    print(f:read "a")
end -- scope.end
print "3"

]]
