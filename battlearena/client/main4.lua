local socket = require "socket"
local proto = require "proto"
local timesync = require "timesync"

local IP = "127.0.0.1"

local fd = assert(socket.login {
	host = IP,
	port = 8001,
	server = "sample",
	user = "emma",
	pass = "password",
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
	print(string.format("notify ranklevel %d",obj.players[1].ranklevel))


	print(string.format("matchnotify result:%s", obj))
end)
local udp

request(fd, "randomjoin", { group = "one" } , function(obj)
	obj.secret = fd.secret
	udp = socket.udp(obj)
	udp:sync()
end)

for i=1,1000 do
	timesync.sleep(1)
	if (i == 100 or i == 200 or i ==300 or i == 600) and udp then
		local gtime = timesync.globaltime()
		if gtime then
			print("send time", gtime)
			udp:send ("emma" .. i .. ":1")
			udp:send ("emma" .. i .. ":2")
			udp:send ("emma" .. i .. ":3")
		end
	end
	if udp then
		local time, session, data = udp:recv()
		if time then
			print("UDP", "time=", time, "session =", session, "data=", data)
		end
	end
	dispatch(fd)
end
request(fd, "leave", { uid = "" } , function(obj)
	print(string.format("result:%s", obj.result))
end)
