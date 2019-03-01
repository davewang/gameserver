local skynet = require "skynet"
local snax = require "snax"
local json = require "dkjson"
local max_number = 2
local roomid
local gate
local blocks
--local tcpgate
local users = {}
local queue = require "skynet.queue"
local cs
local isReady = false
local ready_msgs = {}
local busy = false
 
--[[
	4 bytes localtime
	4 bytes eventtime		-- if event time is ff ff ff ff , time sync
	4 bytes session
	padding data
]]
 
function accept.update(data)
	
	--local time = skynet.now()
	--data = string.pack("<I", time) .. data
    --local sz = string.pack("<I2", h)
	
	 local function checkReady(str)
	 	if string.len(str) >= 2 then
	   	 local sz,offset = string.unpack("<I2", str)
			if string.len(str) >= sz then
		    	--self.__read = str:sub(sz+1)
				local data = str:sub(offset, offset+(sz-2))
				local session = string.unpack("<I", data)
			    return session,data:sub(5),data:sub(1,4)
		    end
 
	    end
	 end 
	 
	 data = string.pack("<I2", string.len(data)+2 ) .. data
	
	 --if isReady == false then
	 --end 
	local session,str = checkReady(data)
	
	local json_data, pos, err = json.decode (str, 1, nil)
    if err then
        print ("REQUEST Error:", err)
    end
	--print(string.format("msgid = %d",json_data.msgid))
	if json_data.msgid == 9001 then
	    table.insert(ready_msgs,data)
		--print(string.format("msgid = %d",json_data.msgid))
		if #ready_msgs == max_number then
		   --print(string.format("max 2 msgid = %d",json_data.msgid))
		   --获取随机方块
		   json_data.data = blocks.req.blocks() 
		   --构建发送给客户端
		   local r_data = json.encode(json_data, { indent = true }) 
	       for i=1,#ready_msgs do
		       local _data = ready_msgs[i]
			   local ss,sr,mid = checkReady(_data)
			   local r_r_data = string.pack("<I2", string.len(r_data)+2+4)..mid..r_data
			   for s,v in pairs(users) do
			      if s ~= ss then
					--gate.post.post(s, _data)
					gate.post.post(s, r_r_data)
				--	print(string.format("post sesson=%d",s))
	  			  end	
			   end
		   end 
		   ready_msgs = {}
		end
		return
	end
	
	
	for s,v in pairs(users) do
		--skynet.error(string.format("accept.update %s",data))
		if s ~= session then
			gate.post.post(s, data)
	    end
		--tcpgate.post.post(s, data)
		
	end
end

function response.join(agent, secret)
	--skynet.error(string.format("response.join "))
	local user
	cs(function()

				local n = 0
				for _ in pairs(users) do
					n = n + 1
				end
				if n >= max_number then
				   return false	-- max number of room
				end
				agent = snax.bind(agent, "agent")
			    user = {
					agent = agent,
					key = secret,
					session = gate.req.register(skynet.self(), secret),
					username =  agent.req.user().username
				}
				users[user.session] = user

				n = 0
				for _ in pairs(users) do
					n = n + 1
				end
				if n == max_number then
				   busy = true
				end
				skynet.error(string.format("%s--->%s join room(%s) after user count %d ",os.date("%Y-%m-%d %T"),user.username,snax.self(),n))

	end)
	return user.session
end
function response.checkNotify()
	local n = 0
	for _ in pairs(users) do
		n = n + 1
	end
	if n == max_number then
            local players_names = {}
			for si,vi in pairs(users) do
				local players = {}
				for sj,vj in pairs(users) do
					if si ~= sj then
						  local au = vj.agent.req.user()
						  
						   table.insert(players_names,au.username)
						--	skynet.error(string.format("au.username %s",au.username))
						--	skynet.error(string.format("au.nickname %s",au.nickname))
						--	skynet.error(string.format("au.ranklevel %d",au.level))
						--	skynet.error(string.format("au.avatarid %d",au.avatarid))
							table.insert(players,{ username = au.username , nickname = au.nickname, level = au.level,avatarid = au.avatarid })
					end
				end
				--skynet.send(vi.agent.handle,"notify","notify",{players=players})
				vi.agent.req.notify("notify",{players=players})

			end
			skynet.error(string.format("%s--->%s vs %s in root(%s)",os.date("%Y-%m-%d %T"),players_names[1],players_names[2],snax.self()))
			
	end
end
function response.leave(session)

	if (not users[session]) or (not session) then
		return
	end

    local leaveName = users[session].username
	users[session] = nil
	local n = 0
	for _ in pairs(users) do
		n = n + 1
	end
	ready_msgs = {}
	skynet.error(string.format("%s--->%s leave room(%s) after users count %d",os.date("%Y-%m-%d %T"),leaveName,snax.self(),n))
	if n == 0 then 
		busy = false
	end 
	 
	skynet.error(string.format("%s--->room(%s) busy = %s",os.date("%Y-%m-%d %T"),snax.self(),busy))
 	
	
	--response
	local disconnectMsg = {
        msgid = 1008,
        msg_type = 0
    }
	
	local data = json.encode(disconnectMsg, { indent = true }) 
	--skynet.error(data)
	--skynet.error(string.len(data))
	data = string.pack("<I", session) .. data
	data = string.pack("<I2",string.len(data)+2)..data
	--skynet.error(data)
	--self.post(self,data)
	 
	--skynet.error(string.len(data))
	
    for s,v in pairs(users) do
		--skynet.error(string.format("accept.update %s",data))
		if s ~= session then
			gate.post.post(s, data)
	    end
		--tcpgate.post.post(s, data)
		
	end
	
	
end

function response.query(session)
	--skynet.error(string.format("response.query "))
	local user = users[session]
	-- todo: we can do more
	if user then
		return user.agent.handle
	end
end
function response.isBusy()
    skynet.error(string.format("%s--->room(%s) busy = %s",os.date("%Y-%m-%d %T"),snax.self(),busy))
 	
	return busy
end 
function response.count()
	--skynet.error(string.format("response.isFull "))
	local n = 0
	for _ in pairs(users) do
		n = n + 1
	end
	return n
end
function response.isFull()
	--skynet.error(string.format("response.isFull "))
	local n = 0
	for _ in pairs(users) do
		n = n + 1
	end
	  
	if n >= max_number then
		return true	-- max number of room
	end
  return false
end
function response.users()
  return users
end


function init( tcpserver)--udpserver,

	--gate = snax.bind(udpserver, "udpserver")
	gate = snax.bind(tcpserver, "tcpserver")
	blocks = snax.queryservice "blocks"
	cs = queue()
end

function exit()
	for _,user in pairs(users) do
		--gate.req.unregister(user.session)
		gate.req.unregister(user.session)
	end
end
