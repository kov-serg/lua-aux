-- (To-be-closed Variables)[https://www.lua.org/manual/5.4/manual.html#3.3.8] is very dubious feature
-- here is one possible replacement
--
-- example of resource management for sequential functions

-- helper functions ----------------------------------------------------------
function dump(x) for k,v in pairs(x) do print(k,v) end end
function randomize() math.randomseed(os.clock()*1e6) end
function macros(names)
    return function(text) local stack={}
        return (text:gsub("@(%w+)",function(name)
            if name=='end' then name=table.remove(stack) return names[name][2] end
            if names[name] then table.insert(stack,name) return names[name][1] end
        end))
    end
end
function for_scope(body)
    local list,res={}
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
    local function defer(fn) auto(fn){true} end
    local ok,err=pcall(function() res={body(auto,defer)} end)
    for i=#list,1,-1 do list[i].fn(list[i].arg) end
    if not ok then
        if type(err)~='string' then error(err,2)
        else error("scope error\nlua: "..err,2) end
    end
    if #res>0 then return res end
end
-- usage:
--
-- function test()
--   for scope in for_scope,function(auto,defer) -- scope.begin
--     local f,err=auto(io.close,"weak") { io.open "test2.txt" }
--     print(f,err)
--     defer(function() print "defer" end)
--     return auto(){ io.open "readme.txt" }:read()
--   end do return table.unpack(scope) end -- scope.end
-- end
-- print(test())
--

local Seq={}
function Seq:next(...) return coroutine.resume(self.coro,...) end
function Seq:done()
    self.terminate=true
    if coroutine.status(self.coro)~='dead' then return self:next() end
end
function sequence(fn)
    local seq=setmetatable({},{__index=Seq})
    local yield=function(...)
        local resp=table.pack(coroutine.yield(...))
        if seq.terminate then error "terminate" end
        return table.unpack(resp)
    end
    seq.coro=coroutine.create(function() fn(yield) end)
    return seq
end

-- end of helper functions ---------------------------------------------------

function xopen(name) print("\txopen "..name) return name end
function xclose(handle) print("\txclose "..handle) end

-- sequence function in pure lua
s1=sequence(function(yield) 
    print "step1"
    yield()
    for scope in for_scope,function(auto,defer) -- scope.begin
        local value=auto(xclose) { xopen "data" }
        print("\tvalue="..value)
        defer(function() print "\tsome defer function" end)
        for i=1,3 do
            local name=("data_%d"):format(i)
            print"step2"
            local value_i=auto(xclose) { xopen(name) }
            yield(i)
        end
    end do return table.unpack(scope) end -- scope.end
    print "step3"
    yield "leave"
    print "last step"
end)

function seq_fn(text)
    local filter=macros{
        scope={ "for scope in for_scope,function(auto,defer)", 
                "end do return table.unpack(scope) end" },
        defer={ "defer(function()", "end)" },
        fn   ={ "function()", "end" },
    }
    local code="return sequence(function(yield)\n"..filter(text).."\nend)"
    return load(code)()
end

-- same thins but using syntax sugar
s2=seq_fn[[
    print "step1"
    yield()
    @scope
        local value=auto(xclose) { xopen "data" }
        print("\tvalue="..value)
        @defer print "\tsome defer function" @end
        for i=1,3 do
            local name=("data_%d"):format(i)
            print"step2"
            local value_i=auto(xclose) { xopen(name) }
            yield(i)
        end
    @end
    local fn=@fn print "step fn" @end
    fn()
    print "step3"
    yield "leave"
    print "last step"
]]

function run(s,n)
    print(("---run %d times---"):format(n))
    for k=1,n do s:next() end
    print "---done---"
    print( s:done() )
end

randomize()
run(s2, math.random(10))
print "done"
