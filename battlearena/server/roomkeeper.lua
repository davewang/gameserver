local snax = require "snax"
local skynet = require "skynet"
local queue = require "skynet.queue"
local host
local port = 9999
--local udpgate
local tcpgate
local queue = require "skynet.queue"
local cs
--local rooms = {}
local groups = {one={},two={},three={}}
function response.randomapply(groupid)
	local rooms = groups[groupid]
	local room = nil


	cs(function()

		for i=1,#rooms do
			rooms[i].count = rooms[i].r.req.count()
			skynet.error(string.format("%s--->room(%s) user count %d ",os.date("%Y-%m-%d %T"),rooms[i].r,rooms[i].count))
		end


		table.sort(rooms,function(a,b) return a.count > b.count end)

		for i=1,#rooms do
			skynet.error(string.format("%s--->sort after room(%s) user count %d ",os.date("%Y-%m-%d %T"),rooms[i].r,rooms[i].count))
		end



		for i=1,#rooms do
			if rooms[i].r.req.isFull() == false and rooms[i].r.req.isBusy() == false then
				room = rooms[i].r
				break
			end
		end
		if room == nil then
			room = snax.newservice("room",tcpgate.handle)-- udpgate.handle,
			table.insert(rooms,{count=0,r=room})
		end

	end)
	return room.handle , host, port--, full
end

function response.getgroupinfo(groupid)

	local rooms = groups[groupid]
	local sum = 0
	for i=1,#rooms do
		sum = sum + rooms[i].r.req.count()
	end
	--skynet.error(string.format("response.getgropinfo groupid = %s count = %d",groupid,sum))
	return {id=groupid,count=sum}
end
-- function response.apply(roomid)
-- 	skynet.error(string.format("response.apply roomid = %s ",roomid))
-- 	local room = rooms[roomid]
-- 	if room == nil then
-- 		room = snax.newservice("room", roomid, udpgate.handle)
-- 		rooms[roomid] = room
-- 	end
-- 	return room.handle , host, port
-- end

-- todo : close room ?

function init()
	local skynet = require "skynet"
	-- todo: we can use a gate pool
	host = skynet.getenv "udp_host"
	skynet.error(string.format("port = %d",port))
	--udpgate = snax.newservice("udpserver", "0.0.0.0", port)
	tcpgate = snax.newservice("tcpserver", "0.0.0.0", port)
	cs = queue()
end
