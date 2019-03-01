local snax = require "snax"
local skynet = require "skynet"
local userdb

local scoreranks
local worldranks
--[[
   friend ranks
          name,avator,level,win/lose
   score ranks
          name,avator,level,score,win/lose
   world ranks
          name,avator,level,win/lose
]]


function response.friendranks(username)
     local ranks = userdb.req.getfriendsandme(username) --userdb.req.getfriends(username)
     table.sort(ranks,function(a,b) return a.level>b.level end)
     skynet.error(string.format("ranks = %d",#ranks))
     return ranks
end
function response.scoreranks()
     return scoreranks
end
function response.worldranks()
     return worldranks
end
local function doscoreranks()
     local ranks = userdb.req.ranksbyscore()
     skynet.error(string.format("update ranks = %d",#ranks))
     return ranks
end
local function doworldranks()
     local ranks = userdb.req.ranksbylevel()
     skynet.error(string.format("update ranks = %d",#ranks))
     return ranks
end
function init()

  userdb = snax.queryservice "userdb"

  local function timer()
     --100*60*60*2
     skynet.timeout(100*60*30,timer)
     --skynet.timeout(100*2,timer)
     scoreranks = doscoreranks()
     worldranks = doworldranks()
     skynet.error("2 house after update ranks ",os.date("%Y-%m-%d %H:%M:%S",os.time()))
  end
  timer()

end
