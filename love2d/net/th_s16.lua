local socket=require "socket"
local log=require "log"
local hostname=socket.dns.gethostname() -- android returns localhost
-- log.log("s1: hostname=%s",hostname)
local check=log.check

local ma1="ff12::1"
local port=6789

local udp,err=socket.udp6()
check "s1: reuseaddr" (udp:setoption("reuseaddr",true))
socket.sleep(1)
-- log.log"s1.send"
check "s1: sendto" (udp:sendto("s1: hello from "..hostname,ma1,port))
socket.sleep(1)
check "s1: sendto" (udp:sendto("s1: leaving",ma1,port))
-- log.log"s1.done"
