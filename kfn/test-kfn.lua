#!/bin/env lua

if package.config:match"/" then os.execute "./build-linux.sh"
else os.execute "build-win.cmd" end

require "mykfn"

do
	local c1=mykfn(5)
	local c2=mykfn(9)
	for i=1,7 do
		io.write(i.."\t")
		coroutine.resume(c1)
		coroutine.resume(c2)
		print(coroutine.status(c1),coroutine.status(c2))
	end
	print "--gc1--"
	collectgarbage "collect"
end
print "--gc2--"
collectgarbage "collect"
print()
print "--done--"

--[[

kfn_init n=5
kfn_init n=9
1	first step first step suspended	suspended
2	step i=0 step i=0 suspended	suspended
3	step i=1 step i=1 suspended	suspended
4	step i=2 step i=2 suspended	suspended
5	step i=3 step i=3 suspended	suspended
6	step i=4 step i=4 suspended	suspended
7	last step kfn_done n=5 finished step i=5 dead	suspended
--gc1--
kfn_done n=5 dead
--gc2--
kfn_done n=9 not finished 
--done--

]]