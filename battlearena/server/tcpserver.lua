local skynet = require "skynet"
local socket = require "socket"
local crypt = require "crypt"
local snax = require "snax"

local U
local S = {}
local SESSION = 0
local timeout = 10 * 60 * 100	-- 10 mins

--[[
	8 bytes hmac   crypt.hmac_hash(key, session .. data)
	4 bytes localtime
	4 bytes eventtime		-- if event time is ff ff ff ff , time sync
	4 bytes session
	padding data
]]

function response.register(service, key)

    
	SESSION = (SESSION + 1) & 0xffffffff
	S[SESSION] = {
		session = SESSION,
		key = key,
		room = snax.bind(service, "room"),
		address = nil,
		time = skynet.now(),
		lastevent = nil,
	}
	--snax.printf("register Session %d ", SESSION)
	return SESSION
end

function response.unregister(session)
	S[session] = nil
end

function accept.post(session, data)
	local s = S[session]
	 
	--snax.printf("post Session %d send data %s", s, socket.udp_address(s.address))
	 
	if s and s.address then
	    socket.write(s.address, data)
		--socket.sendto(U, s.address, data)
	else
		snax.printf("Session is invalid %d", session)
	end
end
 
local function tcpdispatch(id)
	socket.start(id)
    local head_len = 2
	while true do
	        local h = socket.read(id,head_len)
	        if h == false then
		   socket.close(id)
		   break;
		end
		local sz = string.unpack("<I2", h)
		
		local data = socket.read(id,sz-head_len)
	        if data == false then socket.close(id); break; end	
		local session = string.unpack("<I", data, 9)
		local s = S[session]
		local from = id
		--print(string.unpack("<I2",sz))
		--print(string.format("session %d from =%d sz is %d",session,from,sz))
		--print(string.format("session %d from =%d data len %d ",session,from,string.len(data)) )
		if s then
			if s.address ~= from then
				if crypt.hmac_hash(s.key, data:sub(9)) ~= data:sub(1,8) then
					snax.printf("Invalid signature of session %d from %s", session, socket.udp_address(from))
					return
				end
				s.address = from
				--snax.printf("set address session %d from %s" , session,socket.udp_address(s.address) )
			end
			--snax.printf("data session %d from %s" , session,data:sub(9))
		 	--s.room.post.update(str:sub(9))
			s.room.post.update(data:sub(9))
		else
			snax.printf("Invalid session %d from %s" , session, socket.udp_address(from))
		end	 
	end
end

   

function init(host, port, address)
	--U = socket.udp(udpdispatch, host, port)
	U = socket.listen(host, port)
	print("Listen socket :", host, port)
	socket.start(U , function(id, addr)
			print("connect from " .. addr .. " " .. id)
			-- you have choices :
			-- 1. skynet.newservice("testsocket", "agent", id)
			-- 2. skynet.fork(echo, id)
			-- 3. accept(id)
			socket.abandon(id)
			skynet.fork(tcpdispatch, id) 
		end)
	--skynet.fork(keepalive)
end

function exit() 
	if U then
		socket.close(U)
		U = nil
	end
end
