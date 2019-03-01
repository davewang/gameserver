local Player = class("Player")
local Grid = import(".Grid")
local Pair = import(".Pair")
local Tile = import(".Tile")
local PFCommon = import(".PFCommon")
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
function Player:ctor(isOpponent)
    self.isOpponent = isOpponent or false   
    self.name = nil
    self.avatar = nil
	self.next = {}
    self.gravity = 1 
    self.gravities = {{delay = 20, distance = 1}, {delay = 3, distance = 1} }  -- delay with which figure fall occurs.
    self.autorepeat_timer = 1  -- in frames
    self.hold_timer = 1  --in frames, frames since left or right is holded
    self.hold_dir = 0  -- -1 left, 1 right, 0 none
    self.autorepeat_delay = 15
    self.autorepeat_interval = 4
    self.timer = 0  
    self.frame = 1 
    self.lock_delay = 30
    self.clear_delay = 10
    self.frame_delay = 1/60
    self.state = ''--'running', 'clearing', 'game_over', 'spawning', 'paused', 'on_floor'(when lock delay>0)
    self.state_names = {on_floor = 'On floor', clearing = 'Clearing tiles',game_over = 'Game over', paused = 'Paused', in_air = 'wait falling',  spawning = 'Spawning'}
    self.current = nil
	self.next_visible = 3
    self.default_position = {x=3,y=14}
    self.tile_default_config = {w=56*2.2,h=56*2.22,offset=1}
    self.tile_show_default_config = {w=56,h=56,offset=1}
    self.opponent_tile_default_config = {w=56/1.2,h=56/1.5,offset=1}
     self.solidState = false;
     
   
	--初始化next
	-- for i=1,self.next_visible do
    --     table.insert( self.next, self:newPair())
    -- end
      
    self.showNext = not self.isOpponent
    self.showHold = not self.isOpponent
    self.drawnext_offset = {x = -3, y = 14}
    self.drawhold_offset = {x = -3, y = 3}
    self.holds = {}
    
    self.grid = Grid:create()
   
    if self.isOpponent then 
       self.grid:setOffset({x = 20, y = 962})
       self.grid.blockConfig = self.opponent_tile_default_config
    else 
       self.grid:setOffset({x = 324, y = 22})
       self.grid.blockConfig = self.tile_default_config
    end 
    self.grid.blockShowConfig = self.tile_show_default_config
    --self.scene = scene
    
    --self.scene:loadBoardWithGrid(self.grid)
    self.state = 'in_air'
    self.gems = 0
    self.hold_times = 0
    self.blockData = {}
    
    self.mergeState = 'merge' --normal merge done 
    self.action_state = 'normal' -- drop rotate move merge 
    --self:init()
    
    self.pendingGems= {}
end
function Player:start()
    self:init()
end 
function Player:init()
        self.next = self:newPairsWithData(self.blockData)
        self:spawn() 
        self.currentPair = Pair:create(self)
        --self.currentPair.grid = self.grid
        --self.grid.scene = self.scene
        self.grid.pair = self.currentPair  
        self.state = 'in_air'
end
function Player:spawnPair()
   -- print("spawnPair")
    self:spawn()
    self.currentPair:reset(self.current)
    --CraftManager.currentShape.grid = CraftManager.grid
end

function Player:moveLeft()
    self.action_state = 'left'
    self.currentPair:moveLeft()
end 

function Player:moveRight()
    self.action_state = 'right' -- drop
    self.currentPair:moveRight()
end 
function Player:step(dt)
    --print("step ",dt)
    local game = self
    if game.state ~= 'game_over' and game.state ~= 'paused' then
        game.timer = game.timer + dt
        if game.timer >= game.frame_delay then
            --print("do_frame")
            self:doFrame()
            game.timer = game.timer - game.frame_delay
        end
    end
end
function Player:doFrame()
    local game = self
    
    local gravity = game.gravities[game.gravity]
 
    if game.hold_dir ~= 0 then
        game.hold_timer = game.hold_timer + 1
        if game.hold_timer >= self.autorepeat_delay then
            game.autorepeat_timer = game.autorepeat_timer + 1

            if game.autorepeat_timer >= self.autorepeat_interval then
           
                game.autorepeat_timer = 1
            end
        end
    end

    if game.state == 'in_air' and game.frame >= gravity.delay then
        -- for i=1,gravity.distance do 
        --     print("distance")
        -- end 
        -- for i=1, gravity.distance do
         
        --     self.currentPair:fall()
           
        --     -- if self.matchAble then
        --     --     self.matchManager:sendFallMsg()
        --     -- end

        -- end
        -- if PFCommon.is_on_floor(self.grid,self.currentPair) then
        --     game.state = 'on_floor'
        -- end
    elseif game.state == 'on_floor' and
        (game.frame >= self.lock_delay) then
        --print("on_floor")
        self:lock() -- can cause game over
        -- if self.matchAble then
 
        --    self.matchManager:sendLockMsg()
        -- end
        game.state = 'paused'
    elseif game.state == 'clearing' and game.frame >= self.clear_delay then
    --    print( 'clearing')
    --    game.state = 'paused'
    --    self:doMerge(self.clearTiles)
       -- self:remove_lines()
       -- game.state = 'paused'
       -- print("self.clearTiles",self.clearTiles)
        --self:doMerge(self.clearTiles)
        -- if self.matchAble then
 
        --     self.matchManager:sendRemoveMsg()
        -- end
    elseif game.state == 'spawning' then
        game.state = 'in_air'
        game:spawnPair()
        self.hold_times = 0
        self:materializePendingGems()
        --print("spawning")
    end

    game.frame = game.frame + 1
end
function Player:drop()
    self.action_state = 'drop' -- drop 
    self.currentPair:drop()
   
end
 
function Player:spawn()
    local current = table.remove(self.next, 1)
    --print("spawn ",#current)
    if current then
        self.current = current
        --table.insert(self.next, self:newPair())
        if #self.next < 10 then 
           local tmp = self:newPairsWithData(self.blockData)
           for i=1,#tmp do 
            table.insert(self.next,tmp[i])
           end 
        end 
        
    else
        print("local newPair ")
        self.current = self:newPair()
    end
end
function Player:hold()
   if self.hold_times == 0 then
        local hold = table.remove(self.holds,1)
        self:holdSpawn(hold)
   end

end
function Player:holdSpawn(hold)
    self.hold_times = self.hold_times+1
    print("...holdSpawn ") 
    -- if self.matchAble then
    --     self.matchManager:sendHoldSimMsg(random_fig.index)
    -- end
    local current = hold
    if current then
        table.insert(self.holds, self.current)
        self.current = current 
    else
        table.insert(self.holds, self.current)
       -- self.current = table.remove(self.next, 1)
       -- table.insert(self.next, random_fig)
        self:spawn()
       
    end
    self.currentPair:clear()
    self.currentPair:reset(self.current)
end



function Player:rotate() 
     
    self.action_state = "rotate"
    self.currentPair:rotate()
end
function Player:moveDirection(dx)
    self.action_state = "direction"
    return self.currentPair:moveDirection(dx)
end
function Player:lock()
    local changed_tiles = self.grid:updateSolidTiles()
    self.currentPair:merge(changed_tiles)
end

function Player:newPairsWithData(data)
  local tmp_next = {}
  for i=1,#data,2 do 
    local shape = {}
    for _, line in ipairs({'##'}) do
        local newLine = {} --= ""   
        for x = 1, #line do
            if string.sub(line,x-1, 1) == '#' then
                local index = i+(x-1)
                table.insert(newLine,{str='#',info={color=colors[data[index].a],type=types[data[index].b]} })
            end
        end
        table.insert(shape, newLine)
    end 
    table.insert(tmp_next,shape)
  end 
  return tmp_next
 
end 
function Player:newPair()
  local shape = {}
    for _, line in ipairs({'##'}) do
        local newLine = {} --= ""   
        for x = 1, #line do
            if string.sub(line,x-1, 1) == '#' then
                table.insert(newLine,{str='#',info=self:randomTile()})
            end
        end
        table.insert(shape, newLine)
    end 
 
  return shape
	
end
function Player:randomTile()
    local randType = math.random(1, 100)
    local type
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
function Player:buildingSolidTile(x,y,attr)
    
    attr.w = self.grid.blockConfig.w
    attr.h = self.grid.blockConfig.h
    local tile = Tile:create(attr) 
    tile.pos={x=x,y=y}
    --tile:setOpacity(0)
    --self.scene:addChild(tile,11)
    tile.grid = self.grid
   -- tile:setPosition(self.grid:locationOfPosition({x=x,y=13}))
    local function startCb(t)
           self.solidState = true;
    end
    local function endCb(t)
            self.grid[t.pos.y][t.pos.x] = t
            self.action_state = "normal"
            self.solidState = false;
    end
--     local move = cc.MoveTo:create(0.3,self.grid:locationOfPosition({x=x,y=y}))
--     local fadein = cc.FadeIn:create(0.3)
--     local end_cb = cc.CallFunc:create(endCb)
--     local begin_cb = cc.CallFunc:create(startCb)
--     local scale = cc.ScaleTo:create(0.3, 0.9) 
--     local group = cc.Spawn:create(move,fadein,scale)
--    -- tile:runAction(cc.Sequence:create(group,end_cb))
--     tile:addPendingAction(cc.Sequence:create(group,end_cb))
    
    endCb(tile)
    return tile
end
function Player:onGem()
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
             self.currentPair:move(function()  --self.player.action_state = "normal"
                       end) 
             end )
    
    self.gems = 0
    return st
end 
function Player:addGem(gem_count)
   self.action_state = "onGem"
   self.gems = self.gems + gem_count
   return self:onGem()
end 
-- function Player:clear_blocks(blocks)
--       local _blocks = blocks
--       local removed = {}
      
--       local delay = cc.DelayTime:create(0.2)
--       local scale = cc.ScaleTo:create(0.2,0) 
--       local delay2 = cc.DelayTime:create(0.2 * 3)
--       local function doRemove(t)
--             t:removeFromParent()
--             print(string.format("remove x=%f,y=%f",t.pos.x,t.pos.y))
--       end
--       local function doRemove1(t)
--             self.grid[t.pos.y][t.pos.x] = 0
--       end
--       --删除
--       local remove = cc.CallFunc:create(doRemove)
--       local remove1 = cc.CallFunc:create(doRemove1)
--       local group = cc.Spawn:create(scale,remove1)
      
--       for i=1,#blocks do
--           table.insert(removed,{x=blocks[i].pos.x,y=blocks[i].pos.y})
--           blocks[i]:addPendingAction(cc.Sequence:create(delay,group,remove))
--       end
--       local function end_callback()
--           local change_tiles = self.grid:checkFall(removed)
--           if change_tiles > 0 then
--           end 
--       end 
--       return removed
      
--       --PFCommon.commitActionsWithLastCallback(tiles,endCallBack)      
-- end  
--消除方块
function Player:crash(start)
    local tiles = start --self.grid:finding(start)
    if #tiles > 1  then
        local removed = {}
        for i=1,#tiles do
            table.insert(removed,{x=tiles[i].pos.x,y=tiles[i].pos.y})
        end
        
        -- local delay = cc.DelayTime:create(0.2*2)
        -- local scale = cc.ScaleTo:create(0.2,0) 
        -- local delay2 = cc.DelayTime:create(0.2 * 3)
        --local delay3 = cc.DelayTime:create(0.1)
        local function doRemove(t)
            
            t:removeFromParent()
            print(string.format("remove x=%f,y=%f",t.pos.x,t.pos.y))
        end
        local function doRemove1(t)
            self.grid[t.pos.y][t.pos.x] = 0
             
        end
        
        --特效
        
    
        -- local function broken(n)
        --     if n.type == 'normal' then 
                
        --         local emitter = cc.ParticleSystemQuad:create(GAME_PARTICLES.broken)
        --         emitter:setAutoRemoveOnFinish(true)
        --         emitter:setStartSize(40)
        --         emitter:setEndSize(40)
        --         emitter:setPosition(cc.p(n:getContentSize().width/2,n:getContentSize().height/2))
        --         if n.color == 'red' then 
        --              emitter:setStartColor(cc.c4f(1,0,0,1))
        --              emitter:setStartColorVar(cc.c4f(1,0,0,1))
        --              emitter:setEndColor(cc.c4f(1,0,0,1))
        --              emitter:setEndColorVar(cc.c4f(1,0,0,1))
        --         elseif n.color == 'green' then 
        --              emitter:setStartColor(cc.c4f(0,1,0,1))
        --              emitter:setStartColorVar(cc.c4f(0,1,0,1))
        --              emitter:setEndColor(cc.c4f(0,1,0,1))
        --              emitter:setEndColorVar(cc.c4f(0,1,0,1))
                     
        --         elseif n.color == 'blue' then 
        --              emitter:setStartColor(cc.c4f(0,0,1,1))
        --              emitter:setStartColorVar(cc.c4f(0,0,1,1))
        --              emitter:setEndColor(cc.c4f(0,0,1,1))
        --              emitter:setEndColorVar(cc.c4f(0,0,1,1))
        --         elseif n.color == 'yellow' then 
        --              print("yellow")
        --               emitter:setBlendAdditive(true)
        --              --emitter:setStartColor(cc.c4f(0.5,0.5,0,1))
        --             -- emitter:setStartColorVar(cc.c4f(0.5,0.5,0,1))
        --            --  emitter:setEndColor(cc.c4f(0.5,0.5,0,1))
        --             -- emitter:setEndColorVar(cc.c4f(0.5,0.5,0,1))
        --         end 
        --         emitter:setBlendAdditive(true)
        --         n:addChild(emitter,2001)  
        --         playSound(GAME_SFXS.broken)
        --     end 
        -- end 
    
    
  
        --合并
        -- local remove = cc.CallFunc:create(doRemove)
        -- local remove1 = cc.CallFunc:create(doRemove1)
        -- local broken_ =  cc.CallFunc:create(broken)
        -- local group = cc.Spawn:create(broken_,scale,remove1)
        for i=1,#tiles do
           --tiles[i]:addPendingAction(cc.Sequence:create(delay,group,remove))
           --doRemove1()
           self.grid[tiles[i].pos.y][tiles[i].pos.x] = 0
        end
             
 
        local function endCallBack()
            local changeTiles = self.grid:checkFall(removed)
            print( string.format("endCallBack changeTiles count %d tiles %d",#changeTiles,#tiles))
           
            --if #changeTiles > 0 then 
                self:doMerge(changeTiles) 
            --end 
            --self:addGem(#tiles)
            if self.delegate and self.isOpponent == false then 
                 --self.delegate:onGem(#tiles)
                 
                 table.insert(self.pendingGems,{count=#tiles})
            end 
        end
        --local endCallBack = cc.CallFunc:create(endCallBack);
        --self.scene:runAction(cc.Sequence:create(delay2,endCallBack))
         PFCommon.commitActionsWithLastCallback(tiles,endCallBack)

    end
end
function Player:materializePendingGems()
   -- self.score = self.score + pendingScore
   -- self.scene:updateScore(self.score) 
   local pend_count = 0
   local first = table.remove(self.pendingGems,1)
   while first ~= nil do 
      pend_count =  pend_count + first.count
      first =  table.remove(self.pendingGems,1)
   end 
   if self.delegate and self.isOpponent == false  and pend_count > 0 then 
      self.delegate:onGem(pend_count)
      --table.insert(self.pendingGems,{count=#tiles})
   end 
  -- return pend_count
end
function Player:materializePendingScore(pendingScore)
    self.score = self.score + pendingScore
   -- self.scene:updateScore(self.score) 
end

function Player:checkGameOver()
       for y = 1,self.default_position.y do
                for x = 1,self.grid.w do
                    if self.grid[y][x] ~= 0 and y>(self.default_position.y-2) then
                        --self.state = "game over"
                        if self.delegate    then 
                           -- self.delegate:onGem(pend_count)
                               self.currentPair:gray_blocks()
                               if self.isOpponent == false then 
                                  
                                  local function sp()
                                    self.delegate:onGameOver()
                                  end 
                                   sp()
                                  --local go = cc.CallFunc:create(sp)
                                  --self.scene:runAction(cc.Sequence:create(cc.DelayTime:create(0.8),go))

                               end 
                        end 
                        
                        return
                    end
                end
       end
end 

-- function Player:do_clear(tiles)
--     local mergeds = {}
--     local need_commit = {}
--     for i=1,#tiles do
--         local find,ishave = self.grid:finding(tiles[i])
--         if #find>1 then
--           if ishave then
--               table.insert(mergeds,find)--tiles[i]
--           else   
--               for j=1,#find do 
--                   if PFCommon.contains(need_commit,find[j].pos) then 
--                   else 
--                      table.insert(need_commit,find[j])
--                   end 
--               end
--           end 
--         else 
--           table.insert(need_commit,tiles[i])
--         end
--     end
--     if mergeds>0 then 
    
--     local mer = {}
--     for i=1,#mergeds do 
--         local find = mergeds[i] 
--         local isHave = false

--         for j=1,#mer do
--             local findNew = mer[j] 
--             if isHave == false then
--                 isHave = PFCommon.isJoin(find,findNew) 
--             end    
--         end
--         if isHave == false then
--             table.insert(mer,mergeds[i])
--         end
--     end
--     local function cb()
--         for i=1,#mer do 
--             local rd = self:clear_blocks(mer[i])
            
--             --self:crash(mer[i])
--         end 
--     end 
--     for i=1,#mer do 
--         for j=1,#mer[i] do 
--             if PFCommon.contains(need_commit,mer[i][j].pos) then 
--             else 
--                 table.insert(need_commit,mer[i][j])
--             end 
--             --table.insert(need_commit,mer[i][j])
--         end 
--         --self:crash(mer[i])
--     end
--     PFCommon.commitActionsWithLastCallback(need_commit,cb)
       
    
--     end 
    
-- end 
--merge

function Player:doMerge(tiles)
    
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
          --tiles[i]:commitPendingActions()
          table.insert(need_commit,tiles[i])
        end
    end
    if #mergeds==0 then
         PFCommon.commitActions(need_commit)
       -- local delay = cc.DelayTime:create(0.3)

        local function sp()
            if self.state ~= 'in_air' then
               -- self.grid:checkBoxTiles()
                self.state = "spawning"
                
                
            end    
            if self.state == 'in_air' then
                self.currentPair:move()
                self.currentPair:showShadow()
            end 
            if self.action_state ~= 'normal' then 
               self.action_state = "normal"
            end 
            self:checkGameOver()
            -- for y = 1,self.default_position.y do
            --     for x = 1,self.grid.w do
            --         if self.grid[y][x] ~= 0 and y>(self.default_position.y-2) then
            --             --self.state = "game over"
            --              self.scene:onGameOver()
            --             return
            --         end
            --     end
            -- end
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
            --table.insert(need_commit,mer[i][j])
        end 
        --self:crash(mer[i])
    end
    PFCommon.commitActionsWithLastCallback(need_commit,cb)
    
end
return Player