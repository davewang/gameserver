local MatchManager = class("MatchManager")
local json = require("dkjson")
function MatchManager:ctor()
    self.listeners = {}
    --self.match = match
    self.remotePlayer = nil
    self.queue = {}
   
    self.state_names = {in_game = 'in game', idle = 'idle'}
    self.keyOrder = {'msgid','msg_type','playerId','dx','solid_count','gap_index','next','random_fig'}
    self.state = ""
    self.groups = {}
   
    local function update(dt)
       -- print(string.format("-->queue count %d listeners count %d",#self.queue,#self.listeners))
        
        if #self.queue>0 and #self.listeners>0 then
            print(string.format("==>queue count %d listeners count %d",#self.queue,#self.listeners))
            local msg = table.remove(self.queue,1)
           --  print("self.listeners count = ",#self.listeners)
           --  print("onReceived msg = ",msg.msgid)
            for i=1,#self.listeners do
                if self.listeners[i] then
                    self.listeners[i]:onReceived(msg)
                end
            end
        end
    end
    registerlistener(update)
   -- local scheduler = cc.Director:getInstance():getScheduler()
    --local schedulerEntry = scheduler:scheduleScriptFunc(update, 1/60, false)
  --  MessageDispatchCenter:registerMessage(MessageDispatchCenter.MessageType.MATCH_NOTIFY,handler(self,self.onReceivedMatched))
end

function MatchManager:getOnlineInfo()
    self.app_.client:request("onlineinfo", {uid="1"} , function(obj)
        if obj then
            self.groups = obj

            print(string.format( "self.groups count = %d ",#self.groups))
            for i=1,#self.groups do
                print(string.format( "group id %s count = %d ",self.groups[i].id,self.groups[i].count))
            end
        end
    end)
end
function MatchManager:onReceivedDataFromPlayer(session,data)
   --print("onReceivedDataFromPlayer data ",data.msgid)
   table.insert(self.queue,data) 
end

function MatchManager:sendJsonMsgToAllPlayer(data)
    --print("sendJsonMsgToAllPlayer data ",data.msgid)
    self.app_.client:send(data)
end
function MatchManager:findOpponentByGroup(group)
    local msg = {group=group}
    self.app_.state = "busy"
    -- self.app_.client:SendJsonMsg(GAME_OP_CODES.START_MATCH,msg)
    self.app_.client:request(GAME_OP_CODES.START_MATCH,msg,function(obj)
        self.app_.client:openBroadcast(obj,handler(self,self.onReceivedDataFromPlayer))
        --print("response START_MATCH")
        
    end)
end
function MatchManager:cancelMatchmakingOpponent()
    --local msg = {action="cancel"}
    --self.app_.client:SendJsonMsg(GAME_OP_CODES.CANCEL_MATCH,msg)
    self.app_.client:request(GAME_OP_CODES.CANCEL_MATCH,{uid=""},function(obj)
        print("response CANCEL_MATCH")
        self.app_.state = "idle"
        --app.matchManager:findOpponentByGroup("one")
    end)
end
function MatchManager:clearQueue()
   --print("onReceivedDataFromPlayer data ",data.msgid)
   self.queue = {}
   
end
function MatchManager:requestMatchGameByGroup(group)
    local msg = {user_id="hello",group=group,user_name = self.app_:getCurrentUser().nickname }
    self.app_.client:SendJsonMsg(GAME_OP_CODES.START_MATCH,msg)
end

function MatchManager:onPlayerDisconnected(msg)
    local disconnectMsg = {
        msgid = 1008,
        msg_type = 0,
        playerId = msg.playerId
    }
    table.insert(self.queue,disconnectMsg)
end


function MatchManager:sendSolidMsg(solid_count)
    print("MatchManager:sendSolidMsg solid_count = ",solid_count)
    local solidTetris = {
        msgid = 2001,
        msg_type = 1,
        solid_count = solid_count
    }
  
    self:sendJsonMsgToAllPlayer(solidTetris)
end
function MatchManager:sendSolidSimMsg(solid_count,gap_index)
    local solidTetris = {
        msgid = 1010,
        msg_type = 0,
        solid_count = solid_count,
        gap_index = gap_index
    }
    --self.match:sendJsonMsgToAllPlayer(solidTetris)
    self:sendJsonMsgToAllPlayer(solidTetris)
end
function MatchManager:sendGameOverMsg()
    local gameOverTetris = {
        msgid = 1009,
        msg_type = 0
    }
    --self.match:sendJsonMsgToAllPlayer(gameOverTetris)
    self:sendJsonMsgToAllPlayer(gameOverTetris)
end

 
function MatchManager:sendHoldSimMsg(index)
    local startTetris = {
        msgid = 1011,
        msg_type = 0,
        random_fig = index
    }
    --self.match:sendJsonMsgToAllPlayer(startTetris)
    self:sendJsonMsgToAllPlayer(startTetris)
end

function MatchManager:sendReadyMsg()
    local startTetris = {
        msgid = 9001,
        msg_type = 1
    }
    --self.match:sendJsonMsgToAllPlayer(startTetris)
    self:sendJsonMsgToAllPlayer(startTetris)
end

 
function MatchManager:sendDropMsg()
    local dropTetris = {
        msgid = 1001,
        msg_type = 0
    }
    --self.match:sendJsonMsgToAllPlayer(dropTetris)
    self:sendJsonMsgToAllPlayer(dropTetris)
end
function MatchManager:sendHoldMsg()
    local fallTetris = {
        msgid = 1002,
        msg_type = 0
    }
    --self.match:sendJsonMsgToAllPlayer(fallTetris)
    self:sendJsonMsgToAllPlayer(fallTetris)
end
function MatchManager:sendRotateMsg()
    local lockTetris = {
        msgid = 1003,
        msg_type = 0
    }
    --self.match:sendJsonMsgToAllPlayer(lockTetris)
    self:sendJsonMsgToAllPlayer(lockTetris)

end
function MatchManager:sendGemMsg(solid_count)
    local removeTetris = {
        msgid = 1004,
        msg_type = 0,
        solid_count = solid_count
    }
    --self.match:sendJsonMsgToAllPlayer(removeTetris)
    self:sendJsonMsgToAllPlayer(removeTetris)

end
function MatchManager:sendMoveLeftMsg()
    local moveTetris = {
        msgid = 1101,
        msg_type = 0
    }
    --self.match:sendJsonMsgToAllPlayer(removeTetris)
    self:sendJsonMsgToAllPlayer(moveTetris)

end
function MatchManager:sendMoveRightMsg()
    local moveTetris = {
        msgid = 1102,
        msg_type = 0
    }
    --self.match:sendJsonMsgToAllPlayer(removeTetris)
    self:sendJsonMsgToAllPlayer(moveTetris)

end
function MatchManager:sendMoveDirectionMsg(dx)
    local aroundTetris = {
        msgid = 1005,
        dx = dx,
        msg_type = 0
    }
    --self.match:sendJsonMsgToAllPlayer(aroundTetris)
    self:sendJsonMsgToAllPlayer(aroundTetris)

end


function MatchManager:addListener(obj)
    print("addListener")
    for i=1,#self.listeners  do
        if self.listeners[i]==obj then
            return
        end
    end
    self.listeners[#self.listeners+1] = obj
end
 
function MatchManager:matchFail()
    
    local current = self.app_:getCurrentUser()
    local group =  group_map[currentSelectedGroup]
    self.app_.client:request("edituser",{user={coin=current.coin-group.enterfee,xp=current.xp+group.lose_xp,lose=current.lose+1}} , function(obj)
       self.app_:getCurrentUser().lose = current.lose+1
       self.app_:getCurrentUser().coin = current.coin-group.enterfee 
       self.app_:getCurrentUser().xp = current.xp+group.lose_xp
    end)
end 
function MatchManager:matchWin()
    local current = self.app_:getCurrentUser()
    local group =  group_map[currentSelectedGroup]
        self.app_.client:request("edituser",{user={coin=current.coin+group.enterfee,xp=current.xp+group.win_xp,win=current.win+1}} , function(obj)
            self.app_:getCurrentUser().win = current.win+1
            self.app_:getCurrentUser().coin = current.coin+group.enterfee 
            self.app_:getCurrentUser().xp = current.xp+group.win_xp
        end)
end 
function MatchManager:removeListener(obj)
    for i=1,#self.listeners  do
        if self.listeners[i]==obj then
            table.remove(self.listeners,i)
            break
        end
    end
end

return MatchManager
