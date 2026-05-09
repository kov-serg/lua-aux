local socket=require "socket"
local log=require "log"
local hostname=socket.dns.gethostname()
-- log.log("s2: hostname=%s",hostname)
local check=log.check

local ma1="ff12::1"
local port=6789

local udp,err=socket.udp6()
check "s2: reuseaddr" (udp:setoption("reuseaddr",true))
check "s2: setsockname" (udp:setsockname("*",port))
check "s2: ipv6-add-membership" (udp:setoption("ipv6-add-membership",{multiaddr=ma1}))
udp:settimeout(1000)
while true do
	local data,ca,cp=udp:receivefrom()
	if data then 
		log.log("s2: %s:%s receive=%s", ca,cp,data)
	end
end
-- log.log "s2.done"
