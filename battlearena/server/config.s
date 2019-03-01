thread = 8
logger = nil
logpath = "."
harbor = 0
start = "tcpserver"	-- main script
bootstrap = "snlua bootstrap"	-- The service for bootstrap
luaservice = "skynet/service/?.lua;server/?.lua"
lualoader = "skynet/lualib/loader.lua"
cpath = "skynet/cservice/?.so"
snax = "server/?.lua"
lua_path = "skynet/lualib/?.lua;server/data/?.lua"
lua_cpath = "skynet/luaclib/?.so"
-- daemon = "./skynet.pid"

