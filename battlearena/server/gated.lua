local msgserver = require "snax.msgserver"
local crypt = require "crypt"
local skynet = require "skynet"
local snax = require "snax"
local sprotoloader = require "sprotoloader"
local sproto = require "sproto"

local loginservice = tonumber(...)

local server = {}
local users = {}
local username_map = {}
local internal_id = 0
local usermgr
local db
-- login server disallow multi login, so login_handler never be reentry
-- call by login server
function server.login_handler(uid, secret)
	--skynet.error(string.format("login_handler %s ", uid))
	if users[uid] then
		error(string.format("%s is already login", uid))
	end

	internal_id = internal_id + 1
	local username = msgserver.username(uid, internal_id, servername)

	-- you can use a pool to alloc new agent
	local agent = snax.newservice "agent"
	local u = {
		username = username,
		agent = agent,
		uid = uid,
		subid = internal_id,
	}

	-- trash subid (no used)
	agent.req.login(skynet.self(), uid, internal_id, secret)
	usermgr.post.set(uid,{uid=uid})
	users[uid] = u
	username_map[username] = u

	msgserver.login(username, secret)

	-- you should return unique subid
	return internal_id
end

-- call by agent
function server.logout_handler(uid, subid)
	skynet.error(string.format("logout_handler %s ", uid))
	local u = users[uid]
	usermgr.post.del(uid)
	if u then
		local username = msgserver.username(uid, subid, servername)
		assert(u.username == username)
		msgserver.logout(u.username)
		users[uid] = nil
		username_map[u.username] = nil
		skynet.call(loginservice, "lua", "logout",uid, subid)
	end
end

-- call by login server
function server.kick_handler(uid, subid)
	skynet.error(string.format("kick_handler %s ", uid))
	local u = users[uid]
	if u then
		local username = msgserver.username(uid, subid, servername)
		assert(u.username == username)
		-- NOTICE: logout may call skynet.exit, so you should use pcall.
		pcall(u.agent.req.logout)
	end
end

-- call by self (when socket disconnect)
function server.disconnect_handler(username)
	local u = username_map[username]
	if u then
		u.agent.req.afk()
	end
end

-- call by self (when recv a request from client)
function server.request_handler(username, msg, sz)
--	skynet.error(string.format("request_handler %s ", username))
	local u = username_map[username]
	return skynet.tostring(skynet.rawcall(u.agent.handle, "client", msg, sz))
end

-- call by self (when gate open)
function server.register_handler(name)
	usermgr = snax.queryservice "usermgr"
	skynet.error(string.format("register_handler %s ", name))
	servername = name
	-- todo: move the gate into a cluster, split from loginservice
	skynet.call(loginservice, "lua", "register_gate", servername, skynet.self())
end

--sprotoloader.register("proto/lobby.sproto",1)
sprotoloader.register("proto/lobby.sproto",2)
--sprotoloader.register("proto/lobby.sproto",2)

proto = sprotoloader.load(2)


local CMD = {}


function CMD.rawagent(uid)
	skynet.error(string.format("rawagent %s is agent", uid))

	local u = users[uid]
	if u then
		skynet.error(string.format("rawagent %s have", uid))
	end
end

function server.command_handler(command, ...)
	local f = assert(CMD[command])
	return f(...)
end
msgserver.start(server)
