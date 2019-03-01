local Client = class("Client")
local crypt = require "crypt"
local Robot = import(".Robot")
local timesync = require "timesync"

--local socket = require "socket"
--local proto = require "proto"
function Client:ctor(username)
     self.client = import(".NetClient"):create()
     self.matchManager = import(".MatchManager"):create()
     self.matchManager.app_ = self
     self:login(username)

     self.state = "idle"
     timesync.sleep(10)
     self:registerNotify()
end
function Client:login(username)
    local function sha1(text)
      local c = crypt.sha1(text)
      return crypt.hexencode(c)
    end
    self.client:login(username,sha1("wangjava"),"ios")
end
function Client:registerNotify()
    self.client:request("matchnotify", {sid=""} , function(obj)
                if obj then
                    obj.state = "found"
                   -- MessageDispatchCenter:dispatchMessage(MessageDispatchCenter.MessageType.MATCH_NOTIFY,obj)
                    self.robot = Robot:create(self)
                    self.matchManager:sendReadyMsg()
                    self:registerNotify()
                end
    end)
end
function Client:findOpponentByGroup(group)

    self.matchManager:findOpponentByGroup(group)
end
function Client:checkPlayerPool()

    self.client:request("onlineinfo", {sid=""} , function(obj)
                 print("check onlineinfo")
         if obj.groups then
                for i=1,#obj.groups do
                    -- is able join
                    if obj.groups[i].count > 0 and obj.groups[i].count % 2 ~= 0 then
                       print(string.format("room %s have player count %d", obj.groups[i].id,obj.groups[i].count))
                       self:findOpponentByGroup(obj.groups[i].id)
                    end
                   -- print(string.format("room %s have player count %d", obj.groups[i].id,obj.groups[i].count))
               	end
         end
    end)
end

return Client
