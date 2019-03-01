
require "init"
local timesync = require "timesync"
local grid = require "block.grid"
local pair = require "block.pair"
local robot = require "block.robot"


local colors = {
	'red', 'green', 'blue', 'yellow'
}
local types = {'normal','crash','super_crash'}
local gems_maping = {
	{
		{
			color = 'red',
			type = 'solid'
		},
		{
			color = 'blue',
			type = 'solid'
		},
		{
			color = 'green',
			type = 'solid'
		},
		{
			color = 'yellow',
			type = 'solid'
		},
		{
			color = 'red',
			type = 'solid'
		},
		{
			color = 'green',
			type = 'solid'
		},

	},
}

local function random_tile()
	local randType = math.random(1, 100)
	local type = nil
	if randType > 105 then
		if 4 == math.random(1, 4) then
			type = 'super_crash'
		else
			type = 'crash'
		end

	elseif randType > 75 then
		type = 'crash'
	else
		type = 'normal'
	end

	return {
		color = colors[math.random(1, #colors)],
		type = type
	}
end
local function random_pair_data()
	local shape = {}
	for _, line in ipairs({'##'}) do
		local newLine = {} --= ""
		for x = 1, #line do
			if string.sub(line,x-1, 1) == '#' then
				table.insert(newLine,{str='#',info=random_tile()})
			end
		end
		table.insert(shape, newLine)
	end
	return shape
end





clients = {}
local Client = import(".block.client")

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

--
--
--local newGrid = grid.new({w=6,h=6})
--newGrid:init();
--newGrid:print_self();
--
--local newPair = pair.new({grid=newGrid,pos={x=3,y=newGrid.h+1},data=random_pair_data()});
--newPair:init();
--
--newPair:drop();
--
--newPair:merge();
--
--
--newPair = pair.new({grid=newGrid,pos={x=3,y=newGrid.h+1},data=random_pair_data()});
--newPair:init();
--newGrid:print_self();
--
--sep = 0
--local newRobot = robot.new({grid=newGrid})
--director.mainloop = function ()
--	local dt =  timesync.calculateDeltaTime()
--	--print( "dt = "..tostring(dt).." date = "..os.date("%T"))
--	--print("listeners count = "..#listeners)
--	sep = sep + dt
--	if math.floor(sep) == 5 then
--		sep = 0
--		print( "date = "..os.date("%T"))
----		for i=1,#clients do
----			local client = clients[i]
----			if client.state == 'idle' then
----				client:checkPlayerPool()
----				break
----			end
----		end
--
--		local all = {}
--		for i=1,4 do
--			for j=1,newGrid.w do
--				if newPair:moveTo(j) then
--					newPair:drop();
--					local mergedTiles = newPair:merge();
--					local data = newRobot:seekSolution();
--					table.insert(all,{count=data.max,rotate_count = i,move_x=j});
--					newPair:undoMerge(mergedTiles);
--					newPair:undoDrop();
--				else
--				end
--			end
--			newPair:rotate();
--		end
--		table.sort(all,function(a,b)
--			return a.count>b.count
--		end)
--
--		for i=1,all[1].rotate_count do
--			if i>1 then
--			   newPair:rotate();
--			end
--		end
--		newPair:moveTo(all[1].move_x)
--		newPair:drop();
--		newPair:merge();
--		newGrid:print_self();
--		newPair = pair.new({grid=newGrid,pos={x=3,y=newGrid.h+1},data=random_pair_data()});
--		newPair:init();
--
--
--	end
--
--
--end
--director.run()
