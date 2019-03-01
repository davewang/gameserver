local skynet = require "skynet"
local snax = require "snax"

local max_number = 5

local random_pool_number = 100
--gen 随机方块
local colors = {'red', 'green', 'blue', 'yellow'}
local types = {normal=1,crash=2,super_crash=3}
local kinds = {'a','b','c','d','e'}
local function random_block()
    local randType = math.random(1, 100)
    local type
    if randType > 105 then
        if 4 == math.random(1, 4) then
            type = types['super_crash']
        else 
            type = types['crash']  
        end 
		
	  elseif randType > 75 then
        type = types['crash'] 
    else
        type = types['normal'] 
    end
    return {a=math.random(1, #colors),b=type}--{ color=colors[math.random(1, #colors)],type = type}
end 
local blocks
function response.blocks()
   return blocks[math.random(1, #kinds)]
end
local function create_kind()
    local kind = {}
    for i=1,random_pool_number do 
      table.insert(kind,random_block())
    end 
    return kind
end 
function init()
    blocks = {} 
    print("start random blocks ")
    for i=1,#kinds do 
        table.insert(blocks,create_kind())
    end 
    -- for i=1,#blocks[#blocks] do 
    --     print(string.format("{a=%d,b=%d}",blocks[#blocks][i].a,blocks[#blocks][i].b ))
    -- end 
    -- print(#blocks[#blocks]) 
    print("end random blocks ")
    print("blocks init ")
--   local skynet = require "skynet"

--   host = skynet.getenv "mongo_host"
--   port = skynet.getenv "mongo_port"
--   dbname = "iapploft"
--   db = mongo.client({host=host,port=port})
--   userdb = snax.queryservice "userdb"
  --snax.self().req.sendMsg("davewang","hello","nihao","nihaonihao helll")
end
