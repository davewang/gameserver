local PFCommon = import("..PFCommon")
local BTCommon = import("..BTCommon")
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
local robot = {}
local function robot_seekSolution(self)


    local copedCurrentPair= self.grid.currentPair

    local findA,ishave = self.grid:finding(copedCurrentPair.tiles[1])
    local findB,ishave = self.grid:finding(copedCurrentPair.tiles[2])

    if #findA>#findB then
        return {max=#findA,a =findA,b=findB }
    elseif #findA<#findB then
        return {max=#findB,a =findA,b=findB }
    elseif #findA==#findB then
        return {max=#findB,a =findA,b=findB }
    end
end
local function robot_onGameOver(self)
    self.matchManager:sendGameOverMsg()
    --self.game_.state = 'paused'
    print("Robot:onGameOver")
    removelistener(self.func_)
    self.matchManager:cancelMatchmakingOpponent()
    self.matchManager:removeListener(self)

end

--启动机器人
local function robot_start(self)
    self.func_ = handler(self, self.step)
    registerlistener(self.func_)


    --self:scheduleUpdate(handler(self, self.step))
    return self
end

local function robot_onGem(self,count)
    self.matchManager:sendSolidMsg(count)
end
local function robot_onReceived(self,msg)
    print("robot_onReceived")
    if msg.msg_type == 1 then

        if msg.msgid==2001 then
            table.insert(self.commands,msg)
        end
        if msg.msgid==9001 then
            --print(#msg.data)
            for i=1,#msg.data do
                print(string.format("{a=%d,b=%d}",msg.data[i].a,msg.data[i].b))
            end
            self.blockData = msg.data

            self:start()
        end
    elseif msg.msg_type == 0 then
        if msg.msgid==1008 then
            self.state = 'paused'
            removelistener(self.func_)
            self.matchManager:cancelMatchmakingOpponent()
            self.matchManager:removeListener(self)
        end
        if msg.msgid==1009 then
            self.game_.state = 'paused'
            removelistener(self.func_)
            self.matchManager:cancelMatchmakingOpponent()
            self.matchManager:removeListener(self)

        end

    end
end

local function robot_step(self,dt)
  --  self.game_:step(dt)
    self.sep = self.sep + dt
   -- print(self.game_.state)
    if math.floor(self.sep) == 2 and self.state == 'in_air' then
        self.sep = 0
        local all = {}
        for i=1,4 do
            for j=1,self.grid.w do
                if self.grid.currentPair:moveTo(j) then
                    self.grid.currentPair:drop();
                    local mergedTiles = self.grid.currentPair:merge();
                    local data = self:seekSolutionNew();
                    table.insert(all,{count=data.max,rotate_count = i,move_x=j});
                    self.grid.currentPair:undoMerge(mergedTiles);
                    self.grid.currentPair:undoDrop();
                else
                end
            end
            self.grid.currentPair:rotate1();
        end
        table.sort(all,function(a,b)
            return a.count>b.count
        end)
        --      for i=1,#all do
        --          print(all[i].count)
        --      end
        for i=1,all[1].rotate_count do
            if i>1 then
                --newPair:rotate();
                self:doRotate();
            end
        end
        print("move to "..all[1].move_x)


        local move = ( all[1].move_x - self.game_.currentPair.pos.x)
        if move>0 then
            for i=move,1,-1 do
                self:doLeft()
            end
        elseif move<0 then
            for i=move,-1,1 do
                self:doRight()
            end
        end
        self:doDrop()
    end
    if #self.commands > 0 and self.action_state == "normal" and self.state == 'in_air' then
        local msg = table.remove(self.commands,1)
       -- local st = self.game_:addGem(msg.solid_count)
       -- self.matchManager:sendGemMsg(msg.solid_count)

    end

end
local function robot_addGem(self,gem_count)
    self.action_state = "onGem"
    self.gems = self.gems + gem_count
    return self:onGem()
end
--local function pair_building_tile(self,x,y,attr)
--    local tileNew = tile.new({pos={x=x,y=y},type=attr.type,color = attr.color})
--    tileNew.grid = self.grid
--    --print("buildingTile")
--    return tileNew
--end
local function robot_buildingSolidTile(self,x,y,attr)

    attr.w = self.grid.w
    attr.h = self.grid.h
    local tileNew = tile.new({pos={x=x,y=y},type=attr.type,color = attr.color})
    tileNew.grid = self.grid


    -- tile:setPosition(self.grid:locationOfPosition({x=x,y=13}))
    local function startCb(t)
        self.solidState = true;
    end
    local function endCb(t)
        self.grid[t.pos.y][t.pos.x] = t
        self.action_state = "normal"
        self.solidState = false;
    end

    endCb(tileNew)
    return tileNew
end
local function robot_onGem(self)
    local gems = self.gems
    local spaces = self.grid:getAbleSpaces()
    local st = ""
    if #spaces-gems <= 5 then
        st = "death"
    elseif  #spaces-gems < 12 then
        st = "warning"
    else
        st = "caution"
    end
    local function com_asc(a,b)
        return a.y<b.y
    end
    table.sort(spaces,com_asc)

    local g_map = gems_maping[1]
    local fallTiles = {}

    if gems > #spaces  then
        gems = #spaces
    end

    for i=1,gems do
        local data = g_map[spaces[i].x]
        local t = self:buildingSolidTile(spaces[i].x,spaces[i].y,data)
        table.insert(fallTiles,t)
    end


    PFCommon.commitActionsWithLastCallback(fallTiles,function()
        self:checkGameOver()
        self.grid.currentPair:move(function()  --self.player.action_state = "normal"
        end)
    end )

    self.gems = 0
    return st
end
local function robot_checkGameOver(self)
    for y = 1,self.grid.default_position.y do
        for x = 1,self.grid.w do
            if self.grid[y][x] ~= 0 and y>(self.grid.default_position.y-2) then
                if self.delegate  then
                    if self.isOpponent == false then
                        local function sp()
                            self:onGameOver()
                        end
                        sp()
                    end
                end
                return
            end
        end
    end
end
local function robot_crash(self,start)
    local tiles = start --self.grid:finding(start)
    if #tiles > 1  then
        local removed = {}
        for i=1,#tiles do
            table.insert(removed,{x=tiles[i].pos.x,y=tiles[i].pos.y})
        end
        local function doRemove(t)

            t:removeFromParent()
            print(string.format("remove x=%f,y=%f",t.pos.x,t.pos.y))
        end
        local function doRemove1(t)
            self.grid[t.pos.y][t.pos.x] = 0
        end

        for i=1,#tiles do
            self.grid[tiles[i].pos.y][tiles[i].pos.x] = 0
        end

        local function endCallBack()
            local changeTiles = self.grid:checkFall(removed)
            print( string.format("endCallBack changeTiles count %d tiles %d",#changeTiles,#tiles))

            self:doMerge(changeTiles)
            if self.delegate and self.isOpponent == false then
                table.insert(self.pendingGems,{count=#tiles})
            end
        end
        PFCommon.commitActionsWithLastCallback(tiles,endCallBack)

    end
end
local function robot_doMerge(self,tiles)

    --printInfo("doMerge..")
    local mergeds = {}
    local need_commit = {}
    for i=1,#tiles do
        local find,ishave = self.grid:finding(tiles[i])

        if #find>1 then
            if ishave then
                table.insert(mergeds,find)--tiles[i]
            else
                for j=1,#find do
                    if PFCommon.contains(need_commit,find[j].pos) then
                    else
                        table.insert(need_commit,find[j])
                    end
                end
            end
        else

            table.insert(need_commit,tiles[i])
        end
    end
    if #mergeds==0 then
        PFCommon.commitActions(need_commit)
        -- local delay = cc.DelayTime:create(0.3)

        local function sp()
--            if self.state ~= 'in_air' then
--                self.state = "spawning"
--            end
--            if self.state == 'in_air' then
--                self.currentPair:move()
--            end
--            if self.action_state ~= 'normal' then
--                self.action_state = "normal"
--            end
            self:checkGameOver()

        end
        sp()
        -- local spawning = cc.CallFunc:create(sp)
        -- self.scene:runAction(cc.Sequence:create(delay,spawning))

        return
    end

    local mer = {}
    for i=1,#mergeds do
        local find = mergeds[i]--self.grid:finding(mergeds[i])
        local isHave = false

        for j=1,#mer do
            local findNew = mer[j]--self.grid:finding(mer[j])
            if isHave == false then
                isHave = PFCommon.isJoin(find,findNew)
            end
        end
        if isHave == false then
            table.insert(mer,mergeds[i])
        end
    end
    local function cb()
        for i=1,#mer do
            self:crash(mer[i])
        end


    end
    for i=1,#mer do
        for j=1,#mer[i] do
            if PFCommon.contains(need_commit,mer[i][j].pos) then
            else
                table.insert(need_commit,mer[i][j])
            end
        end
    end
    PFCommon.commitActionsWithLastCallback(need_commit,cb)

end
local function robot_setGrid(self,grid)
    self.grid = grid
end
local function robot_init(self)

    self.matchManager:clearQueue()
    self.matchManager:addListener(self)
end
function robot.new(conf)

    print("robot.new.......")


    return {
        gems = 0;
        matchManager = conf.matchManager,
        isOpponent = false,
        grid = nil,
        commands = {},
        seekSolution= robot_seekSolution,
        doMerge = robot_doMerge,
        checkGameOver = robot_checkGameOver,
        onReceived = robot_onReceived,
        onGem=robot_onGem,
        setGrid=robot_setGrid,
        start=robot_start,
        crash=robot_crash,
        init=robot_init,

    }
end
return robot;