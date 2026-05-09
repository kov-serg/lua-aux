local socket=require "socket"
local log=require "log"
local hostname=socket.dns.gethostname()
-- log.log("s1: hostname=%s",hostname)
local check=log.check

local ma1="224.0.0.0"
local port=6789
local udp,err=socket.udp4()

check "reuseaddr"         (udp:setoption("reuseaddr",true))
-- udp:setoption("ip-drop-membership",{interface="*",multiaddr=ma1})
-- check "ip-add-membership" (udp:setoption("ip-add-membership",{interface="*",multiaddr=ma1}))

socket.sleep(1)
-- log.log"s1.send"
check "sendto" (udp:sendto("s1: hello from "..hostname,ma1,port))
socket.sleep(1)
check "sendto" (udp:sendto("s1: leaving",ma1,port))
-- log.log"s1.done"

-- check "ip-drop-membership" (udp:setoption("ip-drop-membership",{interface="*",multiaddr=ma1}))
