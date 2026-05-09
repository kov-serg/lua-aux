local socket=require "socket"
local log=require "log"
local hostname=socket.dns.gethostname()
-- log.log("s2: hostname=%s",hostname)
local check=log.check

local ma1="224.0.0.0"
local port=6789
local udp,err=socket.udp4()
check "reuseaddr"         (udp:setoption("reuseaddr",true))
check "ip-add-membership" (udp:setoption("ip-add-membership",{interface="*",multiaddr=ma1}))

check "setsockname" (udp:setsockname("*",port))
udp:settimeout(1000)
while true do
	local data,ca,cp=udp:receivefrom()
	if data then 
		log.log("s2: %s:%s receive=%s", ca,cp,data)
	end
end
-- log.log "s2.done"
