local socket = require "socket"
local proto = require "proto"
local timesync = require "timesync"

local IP = "127.0.0.1"

local fd = assert(socket.login {
	host = IP,
	port = 8001,
	server = "sample",
	user = "hello",
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
request(fd, "userinfo", { username = "hello" } , function(obj)
	print("obj",obj)
	print("obj",obj.user1)

	for k,v in pairs(obj) do
		print("k v",k,v)
	end

end)



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

request(fd, "checkdaily", { username = "hello" } , function(obj)
	 
     
	if obj.result then
		 print("可领取")
		 
		 request(fd, "daily", {username = "hello"},function(msg)
		      print("msg.items count =",#msg.items) 
			  for i=1,#msg.items do
			       print(string.format("day %d state %d",msg.items[i].day,msg.items[i].state))
				   if msg.items[i].state==1 then
				       request(fd, "signdaily", {day = msg.items[i].day },function(msg1)
					      if msg1.result then
						     print("领取成功")
						  else
						     print("领取失败")
						  end
					       
					   end)
				   end
				   
			  end
		 end)
    else
		 print("已领取")
	end
end)
--local udp

--request(fd, "randomjoin", { group = "one" } , function(obj)
--	obj.secret = fd.secret
--	udp = socket.udp(obj)
--	udp:sync()
--end)



for i=1,1000 do
	timesync.sleep(1)

	dispatch(fd)
end
