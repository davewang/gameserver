local NetClient = class("NetClient")
local json = require("dkjson")
local socket = require "socket"
local proto = require "proto"
local timesync = require "timesync"
--local scheduler = cc.Director:getInstance():getScheduler()
local LOGIN_SERVER_HOST = G_LOGIN_SERVER--"192.168.1.103"--"iapploft.eicp.net"--"192.168.1.7"--"112.74.92.14"
local LOGIN_SERVER_PORT = G_LOGIN_SERVER_PORT
local SERVER_HOST = G_LOGIC_SERVER---"192.168.1.103"--"iapploft.eicp.net"--"192.168.1.7"--"112.74.92.14"
local SERVER_PORT = G_LOGIC_SERVER_PORT
--require "app.MessageDispatchCenter"
local function request(fd, type, obj, cb)
    local data, tag = proto.request(type, obj)
    local function callback(ok, msg)
        if ok then
            return cb(proto.response(tag, msg))
        else
            print("error:", msg)
        end
    end

    if pcall(function() fd:request(data, callback) end) then

    else
       print("error: connect is disconnect!")
       -- MessageDispatchCenter:dispatchMessage(MessageDispatchCenter.MessageType.DISCONNECTION,"disconnect")
    end
end
local function dispatch(fd)
    local cb, ok, blob = fd:dispatch(0)
    if cb then
        cb(ok, blob)
    end
end
local function recv(tcp,cur,cb)
    if tcp then
        local session, data = tcp:recv()
           if session then
            if session ~= cur then
                local json_data, pos, err = json.decode (data, 1, nil)
                --print ("recv REQUEST Error:", data)
                if err then
                    print ("REQUEST Error:", err)
                end
                cb(session,json_data)
            end
           end

    end
end

function NetClient:ctor()
    local __fdTimeTick = function ()
        if self.fd then
            dispatch(self.fd)
        end
    end
    registerlistener(__fdTimeTick)
    --self.fdTimeTickScheduler = scheduler:scheduleScriptFunc(__fdTimeTick, 0.01,false)

    local __udpTimeTick = function ()
        --if self.udp then
        if self.tcp then
            --socket.__session --self.fd.__session
            --recv(self.udp,self.udp.__session,self.udp_cb)
            recv(self.tcp,self.tcp.__session,self.tcp_cb)
        end
    end
    registerlistener(__udpTimeTick)
    --self.udpTimeTickScheduler = scheduler:scheduleScriptFunc(__udpTimeTick, 0.01,false)

end


function NetClient:anonymous()
    return self:login("anonymous",nil)
end
function NetClient:login(username,password,platform)
    self.fd =  socket.login {
        host = LOGIN_SERVER_HOST,
        port = LOGIN_SERVER_PORT,
        server = "sample",
        user = username,
        pass = password,
        platform = platform,
    }
    if self.fd then
        self.fd:connect(SERVER_HOST, SERVER_PORT)
        return true
    else
        return false
    end
end

function NetClient:request(type, obj, cb)
    request(self.fd,type,obj,cb)
end
function NetClient:openBroadcast(obj,cb)
    obj.secret = self.fd.secret
    --self.udp = socket.udp(obj)
    --self.udp:sync()
    --self.udp_cb = cb
    print("obj.host = ",obj.host," obj.port = ",obj.port)
    self.tcp = socket.tcp(obj)
    self.tcp_cb = cb
end
function NetClient:send(msg)
    msg = json.encode(msg, { indent = true })
   -- print(string.format("msg = %s",msg))

   -- timesync.sleep(1)
    --self.udp:send(msg)
    self.tcp:send(msg)
end

return NetClient
