G_LOGIN_SERVER = "127.0.0.1"
G_LOGIN_SERVER_PORT = 8001
G_LOGIC_SERVER = "127.0.0.1"
G_LOGIC_SERVER_PORT = 8888
listeners = {}
robots = {{username = "robot1"}   }--,{username = "robot2"},{username = "robot3"},{username = "robot4"},{username = "robot5"}}

GAME_OP_CODES = {
    --http--
    PRODUCT = 1002,
    LOGIN = 1003,
    USER_INFO = 1004,
    UPDATE_SCORE = 1006,
    UPDATE_STAR = 1007,
    LEAGUE_FRIEND = 1008,
    LEAGUE_RANK = 1009,
    LEAGUE_SCORE = 1010,
    GET_INBOX = 1011,
    READ_ACTION_INBOX = 1012,
    APPECT_ACTION_INBOX = 1013,
    GET_UNREAD_COUNT_INBOX = 1014,
    GET_DAILY = 1015,
    --socket--
    AUTH_BATTLE = "2001",
    START_MATCH = "randomjoin",--"2002",
    SEND_MATCH_DATA = "2003",
    RECV_MATCH_DATA = "2004",
    CANCEL_MATCH = "leave"

}
function registerlistener(cb)
	table.insert(listeners,cb)
end
function removelistener(cb)
    for i=1,#listeners do
	    if listeners[i] == cb then
			table.remove(listeners,i)
		end 
	end 
end

local timesync = require "timesync"
animationInterval = 1 / 10.0 * 1000.0
-- run loop
director = {}
director.run = function ()
    local lastTime = 0
    local curTime = 0
    while true do
            lastTime = timesync.currentMillSecond()
            director.mainloop(); 
            curTime = timesync.currentMillSecond()
            if (curTime - lastTime) < animationInterval then
                local t = animationInterval - curTime + lastTime
                timesync.sleep(t) 
            end
     end
end


--coroutine
local function coroutine_recv ()
    local co = coroutine.create(function(fd)
          while true do 
            coroutine.yield()--挂起
          end 
    end )
    return co 
end
