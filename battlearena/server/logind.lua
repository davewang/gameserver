local login = require "snax.loginserver"
local crypt = require "crypt"
local skynet = require "skynet"
local snax = require "snax"


local server = {
	host = skynet.getenv "login_address",
	port = tonumber(skynet.getenv "login_port"),
	multilogin = false,	-- disallow multilogin
	name = "login_master",
}

local server_list = {}
local user_online = {}
local user_login = {}

function server.auth_handler(token)
	-- the token is base64(user)@base64(server):base64(password)
	local user, server, password,platform = token:match("([^@]+)@([^:]+):(.+)*(.+)")
	user = crypt.base64decode(user)
	server = crypt.base64decode(server)
	password = crypt.base64decode(password)
	platform = crypt.base64decode(platform)
	-- todo : auth user's real password
	--assert(password == "password")

	local userdb = snax.queryservice "userdb"
	--userdb.req.anonymous(user,platform)
	local realUser = userdb.req.loadUser(user);
	assert(password == realUser.password)

	--assert(password == "pass")
	--skynet.error(string.format("auth_handler %s platform %s ", token,platform))
	return server, user
end

function server.login_handler(server, uid, secret)
	--skynet.error(string.format("%s@%s is login, secret is %s", uid, server, crypt.hexencode(secret)))
	local gameserver = assert(server_list[server], "Unknown server")
	-- only one can login, because disallow multilogin
	local last = user_online[uid]
	if last then
		skynet.call(last.address, "lua", "kick", uid, last.subid)
	end
	if user_online[uid] then
		error(string.format("user %s is already online", uid))
	end

	local subid = tostring(skynet.call(gameserver, "lua", "login", uid, secret))
	user_online[uid] = { address = gameserver, subid = subid , server = server}
	return subid
end

local CMD = {}

function CMD.register_gate(server, address)
	-- todo: support cluster
	server_list[server] = address
end

function CMD.logout(uid, subid)
	local u = user_online[uid]
	if u then
		--skynet.error(string.format("%s@%s is logout", uid, u.server))
		user_online[uid] = nil
	end
end

function server.command_handler(command, ...)
	local f = assert(CMD[command])
	return f(...)
end

login(server)
