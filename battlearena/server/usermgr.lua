local snax = require "snax"
local skynet = require "skynet"
local players = {}

function accept.set(uid,user)
  --skynet.error(string.format("response.set uid = %s ",uid))
  players[uid] = user
end
function response.get(uid)
  --skynet.error(string.format("response.get uid = %s ",uid))
  return players[uid]
end
function accept.setInfo(uid,info)
  --skynet.error(string.format("response.setInfo uid = %s ",uid))
  players[uid].info = info

end
function accept.del(uid)
  --skynet.error(string.format("response.del uid = %s ",uid))

  players[uid] = nil

end


function init()

end
