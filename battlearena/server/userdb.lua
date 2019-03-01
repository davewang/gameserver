local snax = require "snax"
local skynet = require "skynet"
local mongo = require "mongo"
local bson = require "bson"
local products = require "product"

local daily = require "daily"
local level = require "level"
local host
local port
local dbname
local db
local frienddb
local giftmarkdb
--[[
  inbox {title:'name',content:'hello',
	       receiverid:11,extatt:'',sendid:21,
				 sendername='dave',createdate:'2014-11-11'}
   user {username:'dave',pass:'d',nickname:'hello',
	       avatarid:1,avatarurl:"",coin:21,level:3,xp:10}
]]
function response.loadUser(username)
    local ret = db[dbname].user:findOne({username = username})
	if ret then
		 --print("found!")
		 -- skynet.error(string.format("found  %s ", username))
		return ret;
	else
		skynet.error(string.format("not found  %s ", username))
		return nil;
	end
end
function response.register(username,password,platform)
	--skynet.error(string.format("anonymous %s ", username))
	--local db = mongo.client({host=host,port=port})
	local ret = db[dbname].user:findOne({username = username})
	if ret then
		--print("found!")
		-- skynet.error(string.format("found  %s ", username))
	else
		skynet.error(string.format("no found  %s auto create user", username))
		db[dbname].user:ensureIndex({username = username}, {unique = true, name = "username_key_index"})
		local rt = db[dbname].user:safe_insert({username=username,password=password,nickname="noname",
			coin=7000,avatarid=1,avatarurl="",
			platform=platform,level=1,xp=0,score=0,win=0,lose=0,pay_times=1,lastreceiveday=0,lastreceivedate=0,fixnickname=0 })
		assert(rt and rt.n == 1)
	end
	return true

end
function response.anonymous(username,platform)
	--skynet.error(string.format("anonymous %s ", username))
	--local db = mongo.client({host=host,port=port})
	local ret = db[dbname].user:findOne({username = username})
	if ret then
		 --print("found!")
		 -- skynet.error(string.format("found  %s ", username))
	else
		 skynet.error(string.format("no found  %s auto create user", username))
	     db[dbname].user:ensureIndex({username = username}, {unique = true, name = "username_key_index"})
		 local rt = db[dbname].user:safe_insert({username=username,nickname="noname",
		                                         coin=7000,avatarid=1,avatarurl="",
		                                         platform=platform,level=1,xp=0,score=0,win=0,lose=0,pay_times=0,lastreceiveday=0,lastreceivedate=0,fixnickname=0 })
		 assert(rt and rt.n == 1)
	end
  return true

end

--user crud
function response.getuserinfo(username)
	--skynet.error(string.format("anonymous %s ", username))

  return  db[dbname].user:findOne({username = username})
end
function response.updatescore(username,score_)
	db[dbname].user:update({ username= username }, {['$set']={score=score_}})
end

function response.updatenickname(username,inputnickname)
 skynet.error(string.format("--->username = %s nickname = %s",username,inputnickname))
    local ret = db[dbname].user:findOne({nickname=inputnickname})
	if ret then
		 --print("found!")
		 skynet.error("nickname already haved! ")
		 return false
	else
         db[dbname].user:update({ username=username }, {['$set']={nickname=inputnickname,fixnickname=1}})
	end
	return true
end

function response.update_pay_times(username)
    local user = db[dbname].user:findOne({username = username})
	local r = true
	db[dbname].user:update({ username= username },{ ['$set']= { pay_times = user.pay_times+1 } })
	return r
	 
end
function response.addCoin(username,num)
    local user = db[dbname].user:findOne({username = username})
	local r = false
	if num > 0 then
		db[dbname].user:update({ username= username },{ ['$set']= { coin=user.coin+num } })
		r = true
	end
    return r
	 
end
function response.update(username,profile)
    local user = db[dbname].user:findOne({username = username})
	if  user.level < 30 and profile.user.xp >= level[user.level]  then


			local retaim = profile.user.xp -level[user.level]

		skynet.error(string.format("up level %d retaim %d", user.level,retaim))
		--db[dbname].user:findAndModify({query = {username = username}, update = {["$inc"] = {level = 1} }})
		db[dbname].user:update({ username= username }, {['$set']={level=user.level+1,xp=retaim}})
	else
		skynet.error(string.format("level %d retaim %d", user.level,profile.user.xp))
		db[dbname].user:update({ username= username },{ ['$set']= { xp=profile.user.xp } })
	end
    profile.user.xp = nil
	local updatefields = {}
	for k,v in pairs(profile.user) do
		updatefields[k]=v
	end
	db[dbname].user:update({ username= username }, {['$set']=updatefields})
end
function response.addXp(username,xp)
	--skynet.error(string.format("anonymous %s ", username))
	local user = db[dbname].user:findOne({username = username})
	if (xp+user.xp) >= level[user.level] then

		local retaim = (xp+user.xp)-level[user.level]

		skynet.error(string.format("up level %d retaim %d", user.level,retaim))
		--db[dbname].user:findAndModify({query = {username = username}, update = {["$inc"] = {level = 1} }})
		db[dbname].user:update({ username= username }, {['$set']={level=user.level+1,xp=retaim}})
	else
		skynet.error(string.format("level %d retaim %d", user.level,(xp+user.xp)))
		db[dbname].user:update({ username= username },{ ['$set']= { xp=(xp+user.xp) } })
	end
  return  db[dbname].user:findOne({username = username})
end

function response.ranksbyscore()
	
	local ret = db[dbname].user:find():sort({coin=-1}):limit(30)--:sort({sendtime}) {score=-1}
	local ranks = {}

	while ret:hasNext() do
			--local msg = ret:next()
			--msg.sendtime =msg
			table.insert(ranks,ret:next())
	end
	return ranks
end
function response.ranksbylevel()
	local ret = db[dbname].user:find():sort({level=-1}):limit(30)--:sort({sendtime})
	local ranks = {}

	while ret:hasNext() do
			--local msg = ret:next()
			--msg.sendtime =msg
			table.insert(ranks,ret:next())
	end
	return ranks
end

function response.getfriendsandme(username)
  local friendids = frienddb.req.relationship(username)
	skynet.error(string.format("friendids count %d ", #friendids))
	table.insert(friendids,1,username)
  if #friendids == 0  then
	   return {}
	end

	local ret = db[dbname].user:find({username={['$in'] = friendids }} )--:sort({sendtime})
	local friends = {}
    local me = nil
	while ret:hasNext() do
		  local friend = ret:next()
		  if friend.username == username then
			me = friend
		  else
		    --检查是否可以送金币
		    local isSend = giftmarkdb.req.checkGift(username,friend.username)
			friend.isablesendgift = isSend
			print(isSend)
			skynet.error(friend.isablesendgift )
		    table.insert(friends,friend)
			
		  end
			skynet.error(string.format("friend username %s ", friend.username))
	end
	table.insert(friends,1,me)
	skynet.error(string.format("friend count %d ", #friends))
  return  friends
end
function response.getfriends(username)
  local friendids = frienddb.req.relationship(username)
	skynet.error(string.format("friendids count %d ", #friendids))

  if #friendids == 0  then
	   return {}
	end
	local ret = db[dbname].user:find({username={['$in'] = friendids }} )--:sort({sendtime})
	local friends = {}

	while ret:hasNext() do
		  local friend = ret:next()
			table.insert(friends,friend)
			skynet.error(string.format("friend username %s ", friend.username))
	end
	skynet.error(string.format("friend count %d ", #friends))
  return  friends
end
function response.checksigndaily(username)
   local ret = db[dbname].user:findOne({username = username})
   if ret.lastreceivedate > 0 then
       local last = ret.lastreceivedate
	   local curr = os.time()
	  -- print("curr= ",curr)
	  -- print("last= ",last)
	   local reallast = os.time({year=os.date("%Y",last),month=os.date("%m",last),day=os.date("%d",last)})
	   local realcurr = os.time({year=os.date("%Y",curr),month=os.date("%m",curr),day=os.date("%d",curr)})
	   --print("realcurr= ",realcurr)
	  -- print("reallast= ",reallast)
	   if (realcurr-reallast) == 86400 then
	   	   --print("day= ",ret.lastreceiveday)
	       return true
	   elseif (realcurr - reallast) == 0 then 
	       return false
	   elseif (realcurr - reallast) > 86400 then 
	       db[dbname].user:update({ username= username }, {['$set']={lastreceiveday=0,lastreceivedate=0}})
	       return true
	   end
   end
   return true
    
end
function response.signdaily(username,day)
    local user = db[dbname].user:findOne({username = username})
	local r = false
	if daily[day].coin_count > 0 then
		db[dbname].user:update({ username= username },{ ['$set']= { coin=user.coin+daily[day].coin_count,lastreceiveday=day,lastreceivedate=os.time() } })
		--db[dbname].user:update({ username= username }, {['$set']={lastreceiveday=day,lastreceivedate=os.time()}})
		r = true
	end
    return r


    
	
  
end
function response.add_pay_record(username,p_id)
	lastreceivedate=os.time() 
	local rt = db[dbname].pay_records:safe_insert({username=username,product_id=p_id,create_date=os.time()})
    assert(rt and rt.n == 1)
end 
--向好友送金币
function response.sendgift(username,friendname)



    local r = giftmarkdb.req.sendGift(username,friendname)
--	local r = true
--	if daily[day].coin_count > 0 then
--		db[dbname].user:update({ username= username },{ ['$set']= { coin=user.coin+daily[day].coin_count,lastreceiveday=day,lastreceivedate=os.time() } })
--		--db[dbname].user:update({ username= username }, {['$set']={lastreceiveday=day,lastreceivedate=os.time()}})
--		r = true
--	end
    return r


    
	
  
end
function response.loaddailysign(username)
         local ret = db[dbname].user:findOne({username = username})
		 if ret.lastreceiveday>0 and ret.lastreceiveday+1<8 then
		 		local day = ret.lastreceiveday+1
		        for i=1,#daily do
				   if day < daily[i].day then
				       daily[i].state = 3
				   elseif day > daily[i].day then
				  	   daily[i].state = 2
				   elseif day == daily[i].day  then
				        daily[i].state = 1
				   end
					 
				end
		 else
		  	   for i=1,#daily do
				   if daily[i].day == 1 then
				    		daily[i].state = 1
				   else
				            daily[i].state = 3
				   end
					 
			   end
		 end
	    
		return daily
   
end


--product
local function loadProduct()

	if db[dbname].product:find():count()==0 then
		  skynet.error( "do load product ")
	  	db[dbname].product:ensureIndex({id = id}, {unique = true, name = "uid_key_index"})
      for i=1,#products do
				db[dbname].product:safe_insert({id=products[i].id,coin_count=products[i].coin_count,product_uid=products[i].product_uid,price=products[i].price})
			end
	end
end
--daily
local function loadDaily()

	if db[dbname].daily:find():count()==0 then
     	skynet.error( "do load daily ")
	  	db[dbname].daily:ensureIndex({id = id}, {unique = true, name = "uid_key_index"})
      for i=1,#daily do
				db[dbname].daily:safe_insert({id=daily[i].id,coin_count=daily[i].coin_count,day=daily[i].day})
			end
	end
end

function response.getproducts()
	return products
end
--
-- from = os.time() --当前时间，单位秒
-- to = os.time({year=2012,month=1,day=1,hour=1,min=30}) --指定时间，单位秒
--
-- sub = to-from --差
function response.getdaily()
	skynet.error( string.format("daily count %d",#daily))
	return daily
end










---send gift mark
--function response.sendGift(username,friendname)
--  skynet.error("sendGift")   
--  local ret = db[dbname].gift_mark:findOne({username=username,friendname=friendname})
--	if ret then
--		 --print("found!")
--		  skynet.error("mark found! ")
--      db[dbname].gift_mark:update({username=username,friendname=friendname}, {['$set']={lastsendtime=os.time()}})
--	else
--      db[dbname].gift_mark:safe_insert({username=username,friendname=friendname,lastsendtime=os.time()})
--	end
--  inboxdb.req.sendMsg(username,friendname,"送你些金币","送你些金币","coin100")
--end
--function response.checkGift(username,friendName)
--	local ret = db[dbname].gift_mark:findOne({username=username,friendname=friendname})
--  if ret then
--		 --print("found!")
--     local last = ret.lastsendtime
--	   local curr = os.time()
--	   print("curr= ",curr)
--	   print("last= ",last)
--	   local reallast = os.time({year=os.date("%Y",last),month=os.date("%m",last),day=os.date("%d",last)})
--	   local realcurr = os.time({year=os.date("%Y",curr),month=os.date("%m",curr),day=os.date("%d",curr)})
--	   print("realcurr= ",realcurr)
--	   print("reallast= ",reallast)
--	   if (realcurr-reallast) >= 86400 then
--	   	  
--	       return true
--	   else
--         return false
--     end
-- 
--	else
--      return true
--  end
--end

function init()
	local skynet = require "skynet"
-- todo: we can use a gate pool
	host = skynet.getenv "mongo_host"
  port = skynet.getenv "mongo_port"
	dbname = "iapploft"
	db = mongo.client({host=host,port=port})
	loadProduct()
	loadDaily()
	frienddb = snax.queryservice "frienddb"
	giftmarkdb = snax.queryservice "giftmark"
end
