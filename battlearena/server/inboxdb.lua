local skynet = require "skynet"
local snax = require "snax"

local mongo = require "mongo"
local bson = require "bson"
local db
local userdb
local function maxid()
  local ret = db[dbname].inbox:find():sort({id=-1}):limit(1)
  if ret:count()>0 then
    if ret:hasNext() then
       ret = ret:next()
    end
    return ret.id
  end
  return 0

end
--os.date("%Y-%m-%d %H:%M:%S",os.time())
function response.inbox(username)
  
   local ret = db[dbname].inbox:find({receiverid = { ['$eq'] = username}}):sort({sendtime=-1}):limit(10)--:sort({sendtime})
   local msgs = {}
   --inbox
   while ret:hasNext() do
        --local msg = ret:next()
        --msg.sendtime =msg
        table.insert(msgs,ret:next())
   end
    skynet.error( string.format( "inbox %d",#msgs))
  --  skynet.error( string.format( "ret count %d",#msgs))
  --  for i=1,#msgs do
  --    skynet.error( string.format( "ret title %s date %s",msgs[i].title,os.date("%Y-%m-%d %H:%M:%S",msgs[i].sendtime)))
   --
  --  end
   return msgs
end


function response.inboxbytype(username,type_)
    skynet.error( string.format( "inbox username: %s",username))
    
    skynet.error( string.format( "inbox type: %d",type_))
   
 
  --local ret = db[dbname].inbox:find( {receiverid=username,extatt=["/coin/"]} ):sort({sendtime=-1}):limit(10) 
   local ret = db[dbname].inbox:find( {receiverid=username,type=type_} ):sort({sendtime=-1}):limit(10) 
   local msgs = {}
   --inbox
   while ret:hasNext() do
        --local msg = ret:next()
        --msg.sendtime =msg
        table.insert(msgs,ret:next())
   end
    skynet.error( string.format( "inbox count %d",#msgs))
  --  skynet.error( string.format( "ret count %d",#msgs))
  --  for i=1,#msgs do
  --    skynet.error( string.format( "ret title %s date %s",msgs[i].title,os.date("%Y-%m-%d %H:%M:%S",msgs[i].sendtime)))
   --
  --  end
   return msgs
end
function response.ishaveunread(username)
   local ret = db[dbname].inbox:find( {receiverid=username,state=0} ):sort({sendtime=-1}):limit(1)
   if  ret:hasNext() then
        return true
   end
   return false
end
function response.readallbytype(username,type)
      skynet.error( string.format( "readallbytype username %s type %d",username,type ))
      local ret = db[dbname].inbox:find( {receiverid=username,type=type,state=0} ):sort({sendtime=-1}):limit(10) 
      if ret:hasNext() then
          db[dbname].inbox:update({receiverid=username,type=type,state=0 }, {['$set']={state=1}},false,true)
          return true
      end
    
    return false
   --db[dbname].inbox:delete({id = id})--:sort({sendtime})
end
function response.recvall(username,type)
   local ret = db[dbname].inbox:find( {receiverid=username,type=type} ):sort({sendtime=-1}):limit(10) 
   if ret:hasNext() then
          db[dbname].inbox:delete({ receiverid=username,type=type})
          return true
   end
   
    return false
   --db[dbname].inbox:delete({id = id})--:sort({sendtime})
end
function response.delete(id)
   db[dbname].inbox:delete({id = id})--:sort({sendtime})
end

function response.sendMsg(srcid,destid,title,content,extatt,msg_type)
     
     local insertid = maxid()+1
     local sender = userdb.req.getuserinfo(srcid)
     db[dbname].inbox:safe_insert({id=insertid,title=title,sendid=srcid,sendname=sender.nickname,
                                  content=content,receiverid=destid,extatt=extatt,state=0,type=msg_type,sendtime=os.time()})
     skynet.error("sendMsg")
     
     
     
end
function init()
  local skynet = require "skynet"

  host = skynet.getenv "mongo_host"
  port = skynet.getenv "mongo_port"
  dbname = "iapploft"
  db = mongo.client({host=host,port=port})
  userdb = snax.queryservice "userdb"
  --snax.self().req.sendMsg("davewang","hello","nihao","nihaonihao helll")
end
