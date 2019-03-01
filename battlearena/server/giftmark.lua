local skynet = require "skynet"
local snax = require "snax"

local mongo = require "mongo"
local bson = require "bson"
local db
--local userdb
--local inboxdb

 

 
function response.delete(id)
   db[dbname].gift_mark:delete({id = id})--:sort({sendtime})
end

function response.sendGift(username,friendname)
  skynet.error("sendGift")   
  if snax.self().req.checkGift(username,friendname) then
  
  local ret = db[dbname].gift_mark:findOne({username=username,friendname=friendname})
   if ret then
		 --print("found!")
		  skynet.error("mark found! ")
      db[dbname].gift_mark:update({username=username,friendname=friendname}, {['$set']={lastsendtime=os.time()}})
	else
      db[dbname].gift_mark:safe_insert({username=username,friendname=friendname,lastsendtime=os.time()})
	end
   return true
  else
   return false
  end
 -- inboxdb.req.sendMsg(username,friendname,"送你些金币","送你些金币","coin100")
end
function response.checkGift(username,friendName)
	local ret = db[dbname].gift_mark:findOne({username=username,friendname=friendName})
  if ret then
		 --print("found!")
     local last = ret.lastsendtime
	   local curr = os.time()
	   --print("curr= ",curr)
	   --print("last= ",last)
	   local reallast = os.time({year=os.date("%Y",last),month=os.date("%m",last),day=os.date("%d",last)})
	   local realcurr = os.time({year=os.date("%Y",curr),month=os.date("%m",curr),day=os.date("%d",curr)})
	   --print("realcurr= ",realcurr)
	   --print("reallast= ",reallast)
	   if (realcurr-reallast) >= 86400 then
	   	  
	       return true
	   else
         return false
     end
 
	else
      return true
  end
end
function init()
  local skynet = require "skynet"

  host = skynet.getenv "mongo_host"
  port = skynet.getenv "mongo_port"
  dbname = "iapploft"
  db = mongo.client({host=host,port=port})--// ,username = "dave",password = "wangjava"

 -- userdb = snax.queryservice "userdb"
  --inboxdb = snax.queryservice "inboxdb"
  --snax.self().req.sendMsg("davewang","hello","nihao","nihaonihao helll")
end
