local skynet = require "skynet"
local socket = require "socket"
local crypt = require "crypt"
local snax = require "snax"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string
local U

local sprotoloader = require "sprotoloader"
local sproto = require "sproto"
local mode = ...


--sprotoloader.register("proto/lobby.sproto",2)

if mode == "httpagent" then


    proto = sprotoloader.load(2)
    local function decode_proto(msg, sz)
        local blob = sproto.unpack(msg,sz)
        local type, offset = string.unpack("<I4", blob)
        local ret, name = proto:request_decode(type, blob:sub(5))
        return name, ret
    end

    local function encode_proto(name, obj)
        return sproto.pack(proto:response_encode(name, obj))
    end

    --skynet.error("http agent")
    local function response(id, ...)
        local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
        if not ok then
            -- if err == sockethelper.socket_error , that means socket closed.
            skynet.error(string.format("fd = %d, %s", id, err))
        end
    end

    local client_request = {}

    function client_request.register(msg)
        skynet.error(string.format("register = %s, %s", msg.username, msg.password))
        local userdb = snax.queryservice "userdb"
        local user = userdb.req.loadUser(msg.username);
        if user then
            return {result = false,msg="user is registed!"}
        else
            userdb.req.register(msg.username, msg.password,msg.platform)
            return {result = true,msg="register success!"}
        end
        --local r = fdb.req.isfriend(user.username,msg.friendname)
        --if r then
        --  inboxdb.req.sendMsg(user.username,msg.friendname,"送礼","系统通知：你的好友 dave 邀请你参加友谊赛。","coin:200",1)
        --end
        --return {result = false}
    end

    local function dispatch_client(response,id,code,name,msg)
            local f = assert(client_request[name])
            response(id,code,encode_proto(name, f(msg)))

    end
    skynet.start(function()
        skynet.dispatch("lua", function (_,_,id)
            socket.start(id)
            -- limit request body size to 8192 (you can pass nil to unlimit)
            local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
            if code then
                if code ~= 200 then
                    response(id, code)
                else
                    local tmp = {}
                    if header.host then
                        table.insert(tmp, string.format("host: %s", header.host))
                    end
                    local path, query = urllib.parse(url)
                    table.insert(tmp, string.format("path: %s", path))
                    if query then
                        local q = urllib.parse_query(query)
                        for k, v in pairs(q) do
                            table.insert(tmp, string.format("query: %s= %s", k,v))
                        end
                    end
                    table.insert(tmp, "-----header----")
                    for k,v in pairs(header) do
                        table.insert(tmp, string.format("%s = %s",k,v))
                    end
                    table.insert(tmp, "-----body----\n" .. body)
                    skynet.error(string.format("body = %d, %s",string.len(body),body))
                    if string.sub(path,2) == 'api' then
                        dispatch_client(response,id,code,decode_proto(body,string.len(body)));
                    else
                        response(id, code, table.concat(tmp,"\n"))
                    end



                end
            else
                if url == sockethelper.socket_error then
                    skynet.error("socket closed")
                else
                    skynet.error(url)
                end
            end
            socket.close(id)
        end)
    end)
else
    function init(host,port)
        --U = socket.udp(udpdispatch, host, port)

        proto = sprotoloader.load(2)
        local agent = {}
        for i= 1, 5 do
            agent[i] = skynet.newservice(SERVICE_NAME, "httpagent")
        end
        local balance = 1
        skynet.error("http host = "..host)
        U = socket.listen(host, port)
        skynet.error(string.format("Listen web port %d",port))
        socket.start(U , function(id, addr)
            skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
            skynet.send(agent[balance], "lua", id)
            balance = balance + 1
            if balance > #agent then
                balance = 1
            end
        end)
    --    U = socket.listen(host, port)
    --    print("Listen socket :", host, port)
    --    socket.start(U , function(id, addr)
    --        print("connect from " .. addr .. " " .. id)
    --        -- you have choices :
    --        -- 1. skynet.newservice("testsocket", "agent", id)
    --        -- 2. skynet.fork(echo, id)
    --        -- 3. accept(id)
    --        socket.abandon(id)
    --        skynet.fork(tcpdispatch, id)
    --    end)
        --skynet.fork(keepalive)
    end

    function exit()
        if U then
            socket.close(U)
            U = nil
        end
    end
end