require "init"
local timesync = require "timesync"
clients = {}
local Client = import(".Client")

local function connectClients()
     for i=1,#robots do
         table.insert(clients,Client:create(robots[i].username)) 
     end 
end 
connectClients()
sep = 0
director.mainloop = function ()
   local dt =  timesync.calculateDeltaTime()
   --print( "dt = "..tostring(dt).." date = "..os.date("%T"))
   --print("listeners count = "..#listeners) 
   sep = sep + dt
   if math.floor(sep) == 5 then 
      sep = 0
     -- print( "date = "..os.date("%T"))
      for i=1,#clients do
         local client = clients[i]
         if client.state == 'idle' then 
             client:checkPlayerPool()
             break
         end 
      end 
     
   end 
  
   for i=1,#listeners do 
       if listeners[i] then
           listeners[i] (dt)
       end
   end 
end
director.run()
