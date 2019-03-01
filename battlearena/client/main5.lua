local socket = require "socket"
local proto = require "proto"
local timesync = require "timesync"

local IP = "127.0.0.1"

local fd = assert(socket.login {
	host = IP,
	port = 8001,
	server = "sample",
	user = "jack",
	pass = "password",
	platform = "ios",
})


fd:connect(IP, 8888)

local function request(fd, type, obj, cb)
	local data, tag = proto.request(type, obj)
	local function callback(ok, msg)
		if ok then
			return cb(proto.response(tag, msg))
		else
			print("error:", msg)
		end
	end
	fd:request(data, callback)
end

local function dispatch(fd)
	local cb, ok, blob = fd:dispatch(0)
	if cb then
		cb(ok, blob)
	end
end

request(fd, "matchnotify", { sid = "one" } , function(obj)

	print(string.format("matchnotify %s",#obj.players))

	print(string.format("notify count %s",#obj.players))

	print(string.format("notify uid %s",obj.players[1].uid))
	-- for k in pairs(vi) do
	--    skynet.error(string.format("notify vi key = %s value = %s",k,vi[k]))
	--  end
	print(string.format("notify username %s",obj.players[1].nickname))

	print(string.format("notify avatarid %d",obj.players[1].avatarid))
	--print(string.format("notify ranklevel %d",obj.players[1].ranklevel))


	--print(string.format("matchnotify result:%s", obj))
end)

--local udp
local tcp

request(fd, "randomjoin", { group = "one" } , function(obj)
	obj.secret = fd.secret
	--udp = socket.udp(obj)
	tcp = socket.tcp(obj)
	--tcp:sync()
end)
--timesync.sleep(1)
for i=1,1000 do
	
    timesync.sleep(1)
	--timesync.sleep(1)
	if (i == 100 or i == 200 or i ==300 or i == 600) and tcp then
		--local gtime = timesync.globaltime()
		--if gtime then
			print("send time", gtime)
			tcp:send ("jack" .. i .. ":1")
			tcp:send ("jack" .. i .. ":2")
			tcp:send ("jack" .. i .. ":3")
		--end
	end
	if tcp then
		local  session, data = tcp:recv()
		if session then
			print("TCP", "session =", session, "data=", data)
		end
	end
	dispatch(fd)
end
request(fd, "leave", { uid = "" } , function(obj)
	print(string.format("result:%s", obj.result))
end)
