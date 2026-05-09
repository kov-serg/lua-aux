local enet = require "enet"
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


log("server.start")
local host = enet.host_create("*:6789")
dump(getmetatable(host).__index)
while true do
  local event = host:service(1000)
  if not event then
    host:broadcast("hello",100)
  end
  while event do
    if event.type == "receive" then
      log_print("Got message: ", event.data, event.peer)
      event.peer:send( "pong" )
    elseif event.type == "connect" then
      log_print(event.peer, "connected.")
    elseif event.type == "disconnect" then
      log_print(event.peer, "disconnected.")
    end
    event = host:service()
  end
end
