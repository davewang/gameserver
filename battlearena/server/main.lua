local skynet = require "skynet"
local snax = require "snax"
--http
--local socket = require "socket"
--local httpd = require "http.httpd"
--local sockethelper = require "http.sockethelper"
--local urllib = require "http.url"
--local table = table
--local string = string
--
--local mode = ...
--
--if mode == "httpagent" then
--	--skynet.error("http agent")
--	local function response(id, ...)
--		local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
--		if not ok then
--			-- if err == sockethelper.socket_error , that means socket closed.
--			skynet.error(string.format("fd = %d, %s", id, err))
--		end
--	end
--
--	skynet.start(function()
--		skynet.dispatch("lua", function (_,_,id)
--			socket.start(id)
--			-- limit request body size to 8192 (you can pass nil to unlimit)
--			local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
--			if code then
--				if code ~= 200 then
--					response(id, code)
--				else
--					local tmp = {}
--					if header.host then
--						table.insert(tmp, string.format("host: %s", header.host))
--					end
--					local path, query = urllib.parse(url)
--					table.insert(tmp, string.format("path: %s", path))
--					if query then
--						local q = urllib.parse_query(query)
--						for k, v in pairs(q) do
--							table.insert(tmp, string.format("query: %s= %s", k,v))
--						end
--					end
--					table.insert(tmp, "-----header----")
--					for k,v in pairs(header) do
--						table.insert(tmp, string.format("%s = %s",k,v))
--					end
--					table.insert(tmp, "-----body----\n" .. body)
--					response(id, code, table.concat(tmp,"\n"))
--				end
--			else
--				if url == sockethelper.socket_error then
--					skynet.error("socket closed")
--				else
--					skynet.error(url)
--				end
--			end
--			socket.close(id)
--		end)
--	end)
--else

skynet.start(function()
	skynet.newservice("console")
	skynet.newservice("debug_console",8000)
	snax.uniqueservice("usermgr")
	snax.uniqueservice("roomkeeper")
	snax.uniqueservice("frienddb")
	snax.uniqueservice("giftmark")
	snax.uniqueservice("userdb")
	snax.uniqueservice("inboxdb")
	snax.uniqueservice("league")
	snax.uniqueservice("blocks")

  --snax.queryservice("inboxdb").req.sendMsg("davewang","hello","nihao","nihaonihao helll","coin100")
	--snax.queryservice("inboxdb").req.inbox("hello")
	--snax.queryservice("inboxdb").req.delete(3)
	--snax.queryservice("frienddb").req.befriend("G:1445528490","G:1855665654")
	--snax.queryservice("frienddb").req.befriend("G:1152190469","G:1445528490")
	--snax.queryservice("frienddb").req.relationship("G:1445528490")
	--snax.queryservice("userdb").req.getfriends("G:1445528490")
	--snax.queryservice("userdb").req.update("G:1445528490",{score=12101})
	--snax.queryservice("league").req.friendranks("G:1445528490")
	--snax.queryservice("league").req.worldranks()
	--snax.queryservice("league").req.scoreranks()
	--snax.queryservice("frienddb").req.befriend("G:1152190469","G:1445528490")
	--snax.queryservice("frienddb").req.befriend("G:1152190469","G:867210176")


	local loginserver = skynet.newservice("logind")
	local gate = skynet.newservice("gated", loginserver)
	snax.newservice("httpserver", "0.0.0.0", 8002)
	skynet.call(gate, "lua", "open" , {
		address = skynet.getenv "gate_address",
		port = tonumber(skynet.getenv "gate_port"),
		maxclient = tonumber(skynet.getenv "max_client"),
		servername = skynet.getenv "gate_name",
	})

	skynet.exit()
--	local agent = {}
--	for i= 1, 5 do
--		agent[i] = skynet.newservice(SERVICE_NAME, "httpagent")
--	end
--	local balance = 1
--	skynet.error(tonumber(skynet.getenv "gate_address"))
--	local id = socket.listen("0.0.0.0", 8002)
--	skynet.error(string.format("Listen web port %d",8002))
--	socket.start(id , function(id, addr)
--		skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
--		skynet.send(agent[balance], "lua", id)
--		balance = balance + 1
--		if balance > #agent then
--			balance = 1
--		end
--	end)

	--skynet.exit()
end)


--end