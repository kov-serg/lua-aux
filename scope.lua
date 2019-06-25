function scope(self)
    local result
    self=self or {}
    self.list={}
    self.error=self.error or error
    local function auto(arg,close,msg)
        if arg then
            table.insert(self.list,{ arg=arg, fn=close or io.close })
        else
            self.error(msg or "init error",2)
        end
        return arg
    end
    local ok,err=true
    if self.init then ok,err=pcall(function() self.init(auto) end) end
    if ok then ok,err=pcall(function() result=table.pack(self.body()) end) end
    if self.done then self.done(ok,err) end
    for _,close in pairs(self.list) do close.fn(close.arg) end
    if not ok then self.error(err) end
    return table.unpack(result)
end
