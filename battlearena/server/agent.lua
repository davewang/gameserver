local snax = require "snax"
local skynet = require "skynet"
local sprotoloader = require "sprotoloader"
local sproto = require "sproto"

local league
local roomkeeper
local usermgr
local gate, room
local U = {}
local proto
local this
local userdb
local inboxdb 
local fdb
local notifyresponse
local notifys = {}
local user
local queue = require "skynet.queue"
local cs

function response.login(source, uid, sid, secret)
	-- you may use secret to make a encrypted data stream
	roomkeeper = snax.queryservice "roomkeeper"
	--usermgr = snax.queryservice "usrmgr"
	snax.printf("%s--->%s is login",os.date("%Y-%m-%d %T"),uid)
	gate = source
	U.userid = uid
	U.subid = sid
	U.key = secret
	-- you may load user data from database
    user = userdb.req.getuserinfo(uid)
end

function response.user()

	return user
end
local function logout()
	if gate then
		skynet.call(gate, "lua", "logout", U.userid, U.subid)
	end
	snax.exit()
end

function response.logout()
	-- NOTICE: The logout MAY be reentry
	snax.printf("%s is logout", U.userid)
	if room then
		room.req.leave(U.session)
	end
	logout()
end

function response.afk()
	-- the connection is broken, but the user may back
	snax.printf("AFK")
	if room then
		room.req.leave(U.session)
	end
end

function response.notify(name,msg)
    skynet.error(string.format("%s--->notify name %s",os.date("%Y-%m-%d %T"),name))
			
	-- skynet.error(string.format("dispatch_notify %s",name))
	-- skynet.error(string.format("dispatch_notify %s",msg))
 	notifyresponse(true,name,msg)

end

local function decode_proto(msg, sz)
	local blob = sproto.unpack(msg,sz)
	local type, offset = string.unpack("<I4", blob)
	local ret, name = proto:request_decode(type, blob:sub(5))
	return name, ret
end

local function encode_proto(name, obj)
	return sproto.pack(proto:response_encode(name, obj))
end


local client_request = {}


function client_request.randomjoin(msg)
	 
		local handle, host, port = roomkeeper.req.randomapply(msg.group)
		local r = snax.bind(handle , "room")
		local room_state = ""
	    if r.req.isBusy() then 
			room_state = "busy"
		else
			room_state = "idle"
		end 
		skynet.error(string.format("%s--->room(%s) %s",os.date("%Y-%m-%d %T"),handle,room_state ))
 	    local session = assert(r.req.join(skynet.self(), U.key))
		U.session = session
		room = r
	return { session = session, host = host, port = port }
end
function client_request.onlineinfo(msg)
	local groupone = roomkeeper.req.getgroupinfo("one")
	local grouptwo = roomkeeper.req.getgroupinfo("two")
	local groupthree = roomkeeper.req.getgroupinfo("three")
	local s = string.format("group %s have %d ",groupone.id,groupone.count)
	s = s .. string.format("%s have %d ",grouptwo.id,grouptwo.count)
	s = s .. string.format("%s have %d ",groupthree.id,groupthree.count)
	
	--skynet.error(string.format("%s--->%s",os.date("%Y-%m-%d %T"),s))
 	
  return { groups={groupone,grouptwo,groupthree}}
end
function client_request.leave(msg)
	if room then
		room.req.leave(U.session)
		room = nil
	end
	return {result=true}
end
-- function client_request.info(msg)
-- 	skynet.error(string.format("response.info %s",msg.uid))
-- 	skynet.error(string.format("response.info %s",msg.nickname))
-- 	skynet.error(string.format("response.info %d",msg.ranklevel))
-- 	skynet.error(string.format("response.info %d",msg.avatarid))
-- 	U.info = msg
-- 	return {result=true}
-- end
function client_request.userinfo(msg)
    user = userdb.req.getuserinfo(user.username)
	return {user = user}
end
function client_request.editnikename(msg)
    local r = userdb.req.updatenickname(user.username,msg.nickname)
	
	return {result = r}
end

function client_request.product(msg)
	return {goods = userdb.req.getproducts()}

end
--ranks
function client_request.scorerank(msg)
	return {ranks = league.req.scoreranks()}

end
function client_request.worldrank(msg)
	return {ranks = league.req.worldranks()}

end
function client_request.friendrank(msg)
  --local username =  msg.username or user.username
	return {ranks = league.req.friendranks(user.username)}
end
--inbox
function client_request.inbox(msg)
  --local username =  msg.username or user.username
	return {messages = inboxdb.req.inboxbytype(user.username,msg.type)}
end

function client_request.delmessage(msg)
  --local username =  msg.username or user.username
	 inboxdb.req.delete(msg.id)
	 return {result = true}
end
 
 
  
function client_request.haveureadmessage(msg)
  --local username =  msg.username or user.username
	 local ishave = inboxdb.req.ishaveunread(user.username)
	 return {result = ishave}
end

function client_request.readallmessagebytype(msg)
  --local username =  msg.username or user.username
 
	 local ok = inboxdb.req.readallbytype(user.username,msg.type)
	 return {result = ok}
end

function client_request.recvall(msg)
  --local username =  msg.username or user.username
	 local r = inboxdb.req.recvall(user.username,msg.type)
	 return {result = r}
end
function client_request.addCoin(obj)
     --local username =  msg.username or user.username
	 if obj.type == 1 then 
	 	 print(obj.type)
		 print(obj.p_id)
		 userdb.req.add_pay_record(user.username,obj.p_id) 
		 userdb.req.update_pay_times(user.username)
	 end 
     local r = userdb.req.addCoin(user.username,obj.count)
	 return {result = r}
end
function client_request.edituser(profile)
     --local username =  msg.username or user.username
     userdb.req.update(user.username,profile)
	 return {result = "ok"}
end
--更新分数
function client_request.updatescore(obj)
     --local username =  msg.username or user.username
     userdb.req.updatescore(user.username,obj.score)
	 return {result = true }
end
function client_request.daily(msg)
	return {items = userdb.req.loaddailysign(user.username)}
end
--检查是否可领取
function client_request.checkdaily(msg)
     local r = userdb.req.checksigndaily(user.username)
	 
	 return {result = r}
end
--领取 每日奖励
function client_request.signdaily(msg)
     local r = userdb.req.signdaily(user.username,msg.day)
	 return {result = r}
end
--好友赠送金币
function client_request.sendgift(msg)
     local r = userdb.req.sendgift(user.username,msg.friendname)
	 if r then
	   inboxdb.req.sendMsg(user.username,msg.friendname,"送礼","系统通知：你的好友 dave 邀请你参加友谊赛。","coin:200",1)
	 end
	 return {result = r}
end
--添加好友
function client_request.addfriend(msg)
     local r = fdb.req.befriend(user.username,msg.friendname)
	 --if r then
	 --  inboxdb.req.sendMsg(user.username,msg.friendname,"送礼","系统通知：你的好友 dave 邀请你参加友谊赛。","coin:200",1)
	 --end
	 return {result = r}
end
--是否为好友

function client_request.isfriend(msg)
     local r = fdb.req.isfriend(user.username,msg.friendname)
	 --if r then
	 --  inboxdb.req.sendMsg(user.username,msg.friendname,"送礼","系统通知：你的好友 dave 邀请你参加友谊赛。","coin:200",1)
	 --end
	 return {result = r}
end



local function dispatch_client(_,_,name,msg)
  --skynet.error(string.format("%s--->dispatch_client %s",os.date("%Y-%m-%d %T"),name))
  if name == 'matchnotify' then
	 skynet.error(string.format("%s--->matchnotify notifyresponse %s",os.date("%Y-%m-%d %T"),user.nickname))
	 notifyresponse = skynet.response(encode_proto)
	elseif name == 'randomjoin' then
		local f = assert(client_request[name])
		skynet.ret(encode_proto(name, f(msg)))
		room.req.checkNotify()
	 
		
	else
		local f = assert(client_request[name])
		skynet.ret(encode_proto(name, f(msg)))
	end
end


function init()
	skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = decode_proto,
	}

	this = snax.self()
	userdb = snax.queryservice "userdb"
	usermgr = snax.queryservice "usermgr"
	league = snax.queryservice "league"
	inboxdb = snax.queryservice "inboxdb"
	fdb = snax.queryservice "frienddb"
	-- todo: dispatch client message
	skynet.dispatch("client", dispatch_client)
  -- todo: dispatch internal notify
	proto = sprotoloader.load(2)
	cs = queue()
	
	--inboxdb.req.sendMsg("dave","G:1152190469","邀请","系统通知：你的好友 dave 邀请你参加友谊赛。","",0)
	--inboxdb.req.sendMsg("emma","G:1152190469","送礼","系统通知：你的好友 dave 邀请你参加友谊赛。","coin:200",1)
	--inboxdb.req.sendMsg("dave","G:1152190469","Hello","Hello body","coin:200",0)
	--inboxdb.req.sendMsg("dave","G:1152190469","Hello","Hello body","coin:100",1)
end
