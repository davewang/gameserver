local skynet = require "skynet"
local snax = require "snax"

local mongo = require "mongo"
local bson = require "bson"
local db
--local userdb
local function maxid()
  local ret = db[dbname].relationship:find():sort({id=-1}):limit(1)
  if ret:count()>0 then
    if ret:hasNext() then
       ret = ret:next()
    end
    return ret.id
  end
  return 0

end
--os.date("%Y-%m-%d %H:%M:%S",os.time())
function response.befriend(a,b)
   local ret = db[dbname].relationship:find({['$and']={ {user_b={['$in'] = {b,a} }},{user_a={['$in'] = {b,a} }}} })
   skynet.error(string.format("found  %d ", ret:count()))
   if ret:count()>0 then
      return false
   end
   db[dbname].relationship:safe_insert({user_a=a,user_b=b})
   return true
end
function response.isfriend(a,b)
   local ret = db[dbname].relationship:find({['$and']={ {user_b={['$in'] = {b,a} }},{user_a={['$in'] = {b,a} }}} })
   skynet.error(string.format("found  %d ", ret:count()))
   if ret:count()>0 then
      return true
   end
   --db[dbname].relationship:safe_insert({user_a=a,user_b=b})
   return false
end
function response.deleteRelationship(a,b)

   db[dbname].relationship:delete({['$and']={ {user_b={['$in'] = {b,a} }},{user_a={['$in'] = {b,a} }}} })--:sort({sendtime})
end
function response.relationship(a)

  local ret = db[dbname].relationship:find({['$or']={ {user_b={['$in'] = {a} }},{user_a={['$in'] = {a} }}} })
  local friendids = {}

  while ret:hasNext() do
       --local msg = ret:next()
       --msg.sendtime =msg
       local rs = ret:next()
       if rs.user_a == a then
         table.insert(friendids,rs.user_b)
       end
       if rs.user_b == a then
         table.insert(friendids,rs.user_a)
       end

  end
  skynet.error(string.format("friendids  %d ", #friendids))
  return friendids
  --:sort({sendtime})
end

function init()
  local skynet = require "skynet"

  host = skynet.getenv "mongo_host"
  port = skynet.getenv "mongo_port"
  dbname = "iapploft"
  db = mongo.client({host=host,port=port})
  --userdb = snax.queryservice "userdb"
  --snax.self().req.sendMsg("davewang","hello","nihao","nihaonihao helll")
end
