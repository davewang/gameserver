local PFCommon = import(".PFCommon")
local BTCommon = import(".BTCommon")
local Tile = import(".Tile")
local Pair = class("Pair") 

function Pair:ctor(player) 
    self.tiles = {} 
    self.shadowTiles = {}
    self.data = player.current
    --self.scene = player.scene
    self.pos = {x=player.default_position.x,y=player.default_position.y} 
    self.current = nil
    
    self.player = player
    self.grid = player.grid
    self:initTiles()
    self.holdBlocks = {} 
    self.nextBlocks = {}
    
    if self.player.showNext then
        self:drawNext()
    end
    if self.player.showHold then
        self:drawHold()
    end
    
     
end  

function Pair:initTiles()    
    local newData = {} 
    for y = 1, #self.data do
        newData[y] = {} 
        for x = 1, #self.data[1] do 
            if self.data[1][x] then
                --print(self.data[1][x].info.type)
                --print(self.data[1][x].info.color)
                self.tiles[#self.tiles+1] = self:buildingTile(self.pos.x + x - 1, self.pos.y + y - 1,{type = self.data[1][x].info.type ,color = self.data[1][x].info.color , alpha=255}) 
                newData[y][x] = self.tiles[#self.tiles] 
                self.tiles[#self.tiles].shadow = self:buildingShadowTile(self.pos.x + x - 1,  self.pos.y + y - 1,{type = self.data[1][x].info.type ,color = self.data[1][x].info.color , alpha=50})
            end 
            
        end
    end 
    self.current = newData
    --self:move()
end
function Pair:buildingShadowTile(x,y,attr)
    
    attr.w = self.grid.blockConfig.w
    attr.h = self.grid.blockConfig.h
    local tile = Tile:create(attr) 
     
    --local scale = cc.ScaleTo:create(0, 0.9)
    --tile:setPosition(self.grid:locationOfPosition({x=x,y=18}))
    tile.grid = self.grid
    tile.pos.x = x 
    tile.pos.y = y
    local shadow_y =  y
    while true do
            if not BTCommon.collides_with_blocks( {"#"}, self.grid, x, shadow_y - 1) then
                shadow_y = shadow_y - 1
            else
                break
            end 
    end
    
    --local x_s,y_s = self:getShadowPos(tile.pos.x,tile.pos.y)
    tile.pos.y = shadow_y
   
    -- local move = cc.MoveTo:create(0.3,self.grid:locationOfPosition({x=tile.pos.x,y=tile.pos.y}))    
    -- local fadein = cc.FadeIn:create(0.2)
    
    -- local group = cc.Spawn:create(move)
    
  --  tile:setVisible(false)
   -- self.scene:addChild(tile,11)
  --  tile:runAction(cc.Sequence:create(scale,move,cc.Show:create()))
    return tile
end
function Pair:buildingTile(x,y,attr)
    
    attr.w = self.grid.blockConfig.w
    attr.h = self.grid.blockConfig.h
    local tile = Tile:create(attr) 
    tile.pos={x=x,y=y}
    
    --tile:setVisible(false)
   -- self.scene:addChild(tile,11)
   -- tile:setPosition(self.grid:locationOfPosition({x=x,y=15}))
    tile.grid = self.grid
     
    print("buildingTile")
    -- local function endCb(t)
    --         print("endCb")
    --         --self.grid[t.pos.y][t.pos.x] = t
    --         local spx =  t.newBlock:getTextureRect().width
    --         local spy =  t.newBlock:getTextureRect().height
    --         t.newBlock:setScaleX(t.w/spx*0.8) --设置精灵宽度缩放比例
    --         t.newBlock:setScaleY(t.h/spy*0.8)
    -- end
  --  local move = cc.MoveTo:create(0.2,self.grid:locationOfPosition({x=x,y=y}))
  --  local fadein = cc.FadeIn:create(0.2)
  --  local scale = cc.ScaleTo:create(0.0, 0.9)
   -- tile:setOpacity(0)
      
    --local end_cb = cc.CallFunc:create(endCb)
    --local group = cc.Spawn:create(move)
    --tile:runAction(cc.Sequence:create(scale,move))
    
    return tile
end
 
function Pair:buildingShowBlock(x,y,attr)
    attr.w = self.grid.blockShowConfig.w
    attr.h = self.grid.blockShowConfig.h
    local tile = Tile:create(attr) 
   
    tile.pos={x=x,y=y}
    --self.scene:addChild(tile,11)
    --tile:setPosition(self.grid:locationOfPosition({x=x,y=y},true))
    
    
   -- tile:setPosition(BTCommon.locationOfPosition(self.grid,{x=x,y=y},self.game.block_show_config))
   -- print("shadow.x = ".. BTCommon.locationOfPosition(self.grid,{x=x,y=y}).x)
    -- print("shadow.y = ".. BTCommon.locationOfPosition(self.grid,{x=x,y=y}).y)
    return tile
end
function Pair:reset(data)
    --print("reset data = "..table.concat(data) )
    self.data = data
    self.tiles = {}
    self.shadowTiles = {} 
    self.pos = {x=self.player.default_position.x,y=self.player.default_position.y}
    self.current = nil
    self:initTiles()
    --self:move()
    
    if self.player.showNext then
        self:drawNext()
    end
    if self.player.showHold then
        self:drawHold()
    end
end
function Pair:clear()
 
	for i=1,#self.tiles do
		--self.tiles[i].shadow:removeFromParent()
        --self.tiles[i]:removeFromParent()
	end
	self.tiles = nil

end
--2016-5-20 start
function Pair:moveTo(x)
    local move = ( x - self.pos.x)
    return self:moveDirection1(move)
end
function Pair:rotate1()
    local newData = {}
    for y = 1, #self.current[1] do
        newData[y] = {}
        for x = #self.current, 1, -1 do
            if self.current[x][y] ~= ' ' then
                newData[y][#newData[y]+1] = self.current[x][y]
            else
                newData[y][#newData[y]+1] = ' '
            end
        end
    end

    self.current = newData

    local rotate_tiles = {}
    for y = 1, #self.current do
        for x = 1, #self.current[1] do
            if self.current[y][x] ~= ' ' then
                self.current[y][x].pos={x=(self.pos.x + x - 1),y=(self.pos.y + y - 1) }
                table.insert(rotate_tiles,self.current[y][x])
            end
        end
    end
    PFCommon.commitActionsWithLastCallback(rotate_tiles,function()   end )

end
function Pair:drop1()
    self.undo_pos = {x=self.pos.x,y=self.pos.y}
    while true do
        if self:fall() then break end
    end
    self:move1(function()
    end)

end
function Pair:undoDrop(changed_tiles)
    if self.undo_pos then
        self.pos = {x=self.undo_pos.x,y=self.undo_pos.y}
    end
    self:move1(function()
    end)
end
function Pair:undoMerge(changed_tiles)
    --undo grid
    for i=1,#changed_tiles do
        self.grid[changed_tiles[i].pos.y][changed_tiles[i].pos.x] = 0;
        --table.insert(mergedTiles,changed_tiles[i])
        changed_tiles[i].pos.y = changed_tiles[i].oldPos.y
        changed_tiles[i].pos.x = changed_tiles[i].oldPos.x
    end

end
function Pair:merge1(changed_tiles)

    if changed_tiles==nil then
        changed_tiles = {}
    end
    local mergedTiles = {}

    for y = 1, #self.current do
        for x = 1, #self.current[1] do
            if self.current[y][x] ~= ' ' then
                local down_y = self.current[y][x].pos.y
                local down_x = x + self.pos.x - 1
                while true do
                    if not BTCommon.collides_with_blocks({"#"}, self.grid, down_x, down_y - 1) then
                        down_y = down_y - 1
                    else
                        break
                    end
                end
                self.grid[down_y][down_x] = self.current[y][x]
                self.current[y][x].oldPos ={x=self.current[y][x].pos.x,y=self.current[y][x].pos.y}
                self.current[y][x].pos={x=down_x,y=down_y}
                table.insert(mergedTiles,self.grid[down_y][down_x])
            end
        end
    end

    for i=1,#changed_tiles do
        table.insert(mergedTiles,changed_tiles[i])
    end

    --self.player.state = 'clearing'

    PFCommon.commitActionsWithLastCallback(mergedTiles,function()

        --self.player:doMerge(mergedTiles)
    end)
    return mergedTiles;


end
function Pair:move1(cb)

    local moves = {}
    for y = 1, #self.current do
        for x = 1, #self.current[1] do
            if self.current[y][x] ~= ' ' then
                --self.current[y][x].undo_move_pos = {x=self.current[y][x].pos.x,y=self.current[y][x].pos.y}
                self.current[y][x].pos={x=(self.pos.x + x - 1),y=(self.pos.y + y - 1)}
                table.insert( moves, self.current[y][x])
            end
        end
    end
    PFCommon.commitActionsWithLastCallback(moves,function()
        cb();
    end)
    return moves;
end
function Pair:moveDirection1(dx)
    local isMove = false
    if not PFCommon.collides_with_blocks(self.current, self.grid, self.pos.x + dx, self.pos.y) then
        self.pos.x = self.pos.x + dx
        isMove = true
    end

    self:move1(function()
    end)
    return isMove

end
--2016-5-20 end
function Pair:moveDirection(dx)
    local isMove = false;
    if not PFCommon.collides_with_blocks(self.current, self.grid, self.pos.x + dx, self.pos.y) then
        self.pos.x = self.pos.x + dx
        isMove = true
    end
    self:move(function()
        self.player.action_state = "normal"
    end)
    if PFCommon.is_on_floor(self.grid,self) then
       --self.player.state = 'on_floor'
    end
    return isMove
    
    -- if rules.move_reset then
    --     game.frame = 1
    -- end
   
   
end 
function Pair:drawNext()
    
    for i=1,#self.nextBlocks do
        --self.nextBlocks[i]:removeFromParent()
    end
    self.nextBlocks = {}
    local offset = {x=self.player.drawnext_offset.x,y=self.player.drawnext_offset.y} 
    for i=1,self.player.next_visible do 
        for y = 1, #self.player.next[i] do
            for x = 1, #self.player.next[i][1] do 
             
                if self.player.next[i][y][x] then 
                    --print(self.player.next[i][y][x].info.type)
                    self.nextBlocks[#self.nextBlocks+1] = self:buildingShowBlock(offset.x + x - 1, offset.y + y - 1,{type = self.player.next[i][y][x].info.type ,color = self.player.next[i][y][x].info.color , alpha=255}) 
                    --self.nextBlocks[#self.nextBlocks+1] = self:buildingBlock(offset.x + x - 1, offset.y + y - 1,{color = BTCommon.colors[self.next[i].index], alpha=255}) 
                end
            end
        end
        offset.y = offset.y-2
    end
  
end
function Pair:drawHold()
 
    for i=1,#self.holdBlocks do
        --self.holdBlocks[i]:removeFromParent()
    end
    self.holdBlocks = {}
    local offset = {x=self.player.drawhold_offset.x,y=self.player.drawhold_offset.y}--{x=-4,y=18}
    for i=1,#self.player.holds do 
        for y = 1, #self.player.holds[i] do
            for x = 1, #self.player.holds[i][1] do 
                if self.player.holds[i][y][x] then 
                    self.holdBlocks[#self.holdBlocks+1] = self:buildingShowBlock(offset.x + x - 1, offset.y + y - 1,{type = self.player.holds[i][y][x].info.type ,color = self.player.holds[i][y][x].info.color , alpha=255}) 
                    --self.holdBlocks[#self.holdBlocks+1] = self:buildingBlock(offset.x + x - 1, offset.y + y - 1,{color = BTCommon.colors[self.game.holds[i].index], alpha=255}) 
                end
            end
        end
        offset.y = offset.y-2
    end

end
function Pair:gray_blocks()
       for y = 1,self.grid.h do
                for x = 1,self.grid.w do
                    if self.grid[y][x] ~= 0   then
                         -- self.grid[y][x].newBlock:setGLProgramState(self.state)
                    local function sp(n)
                         -- n:setGLProgramState(self.state)
                    end 
                    --local go = cc.CallFunc:create(sp)
                   -- self.grid[y][x].newBlock:runAction(cc.Sequence:create(cc.DelayTime:create(0.2 + y*0.04),go))

                    end
                end
       end
      
end 
function Pair:drop()
    
    while true do
        if self:fall() then break end
    end
    self:move(function()  --self.player.action_state = "normal"
             end)
    self.player:lock() 
end

function Pair:fall()
 
    

    -- todo check if floor is reached
    if not PFCommon.collides_with_blocks(self.current, self.grid, self.pos.x, self.pos.y - 1) then
        self.pos.y = self.pos.y - 1
        self.player.frame = 1 --reset lock delay
       
        return false
    else
        return true
    end
end

function Pair:rotate() 
       local newData = {}
        for y = 1, #self.current[1] do
            newData[y] = {}
            for x = #self.current, 1, -1 do
             if self.current[x][y] ~= ' ' then
                newData[y][#newData[y]+1] = self.current[x][y]
             else
                newData[y][#newData[y]+1] = ' '
             end
            end
        end
         
     self.current = newData
     local isRight = false 

     local shadow_y =  self.pos.y
     if PFCommon.collides_with_blocks(self.current, self.grid, self.pos.x, self.pos.y) then

          isRight = true  
     end
       
    

    local _x = 0
    local _y = 0

    local isHorizontal = true
    -- if #self.data >1 then
    if #self.current >1 then
        isHorizontal = false
        local s_p = self:getShadowPos(self.pos.x,self.pos.y)
        _x = s_p.x
        _y = s_p.y
        
     end
     local rotate_tiles = {}
     printInfo(string.format(  "isHorizontal = %s isRight = %s",tostring(isHorizontal),tostring(isRight)) )
       for y = 1, #self.current do
        for x = 1, #self.current[1] do
            if self.current[y][x] ~= ' ' then 
                if isRight then 
                    self.current[y][x].pos={x=(self.pos.x + x - 2),y=(self.pos.y + y - 1)}
                    if isHorizontal then
                        local shadow_p = self:getShadowPos(self.pos.x + x - 2,self.pos.y + y - 1)
                        self.current[y][x].shadow.pos={x=shadow_p.x,y=shadow_p.y}  
                    else
                        self.current[y][x].shadow.pos={x=(_x + x - 2),y=(_y + y - 1)} 
                    end
                else
                   
                    self.current[y][x].pos={x=(self.pos.x + x - 1),y=(self.pos.y + y - 1)}
                    if isHorizontal then
                        local shadow_p = self:getShadowPos(self.pos.x + x - 1,self.pos.y + y - 1)
                        self.current[y][x].shadow.pos={x=shadow_p.x,y=shadow_p.y}  
                    else
                        self.current[y][x].shadow.pos={x=(_x + x - 1),y=(_y + y - 1)} 
                    end
                    --self.rdata[y][x].shadow.position_={x=(self.position_.x + x - 1),y=(_y + y - 1)}  
                end 
                
               -- local move = cc.MoveTo:create(0.1,self.grid:locationOfPosition(self.current[y][x].pos))
               -- self.current[y][x]:stopAllActions()
               -- self.current[y][x]:runAction(move)
              --  self.current[y][x]:addPendingAction(move)
                -- move shadow
               -- local move1 = cc.MoveTo:create(0.1,self.grid:locationOfPosition(self.current[y][x].shadow.pos))
                --self.current[y][x].shadow:stopAllActions()
               -- self.current[y][x].shadow:runAction(move1)
                --self.current[y][x].shadow:addPendingAction(move1)
                table.insert( rotate_tiles,self.current[y][x])
                table.insert( rotate_tiles,self.current[y][x].shadow)
            end
        end
       end  
       PFCommon.commitActionsWithLastCallback(rotate_tiles,function() self.player.action_state = "normal" end )
        
       
    
end 

function Pair:getShadowPos(x,y)
    local s = {"#"}
    
    local sa = false
    if #self.current >1 then
       s = self.current
       sa = true
    end
    local shadow_y =  y
    while true do
        if sa == true then
            if not PFCommon.collides_with_blocks(s, self.grid, x, shadow_y - 1) then
                shadow_y = shadow_y - 1
            else
                break
            end
        else
            if not BTCommon.collides_with_blocks(s, self.grid, x, shadow_y - 1) then
                shadow_y = shadow_y - 1
            else
                break
            end
        end
        
    end
    return {x=x,y=shadow_y}
end

function Pair:move(cb)
    local _x = 0
    local _y = 0
    local moves = {}
    local isHorizontal = true
    --if #self.data >1 then
    if #self.current >1 then
        isHorizontal = false
        local s_p = self:getShadowPos(self.pos.x,self.pos.y)
        _x = s_p.x
        _y = s_p.y
    end
    
    for y = 1, #self.current do
        for x = 1, #self.current[1] do
            if self.current[y][x] ~= ' ' then 
                self.current[y][x].pos={x=(self.pos.x + x - 1),y=(self.pos.y + y - 1)}  
                
               -- local move = cc.MoveTo:create(0.1,self.grid:locationOfPosition(self.current[y][x].pos))
               -- self.current[y][x]:stopAllActions()
                --self.current[y][x]:runAction(move)
                -- self.current[y][x]:addPendingAction(move)
                --move shadow
                
                if isHorizontal then
                    local shadow_p = self:getShadowPos(self.pos.x + x - 1,self.pos.y + y - 1)
                    self.current[y][x].shadow.pos={x=shadow_p.x,y=shadow_p.y}  
                else
                    self.current[y][x].shadow.pos={x=(_x + x - 1),y=(_y + y - 1)} 
                end
                
               -- local move1 = cc.MoveTo:create(0.1,self.grid:locationOfPosition(self.current[y][x].shadow.pos))
              --  self.current[y][x].shadow:stopAllActions()
                --self.current[y][x].shadow:runAction(move1)
             --   self.current[y][x].shadow:addPendingAction(move1)
          
                table.insert( moves, self.current[y][x])
                table.insert( moves, self.current[y][x].shadow)
            end
        end
    end  
    
    
     PFCommon.commitActionsWithLastCallback(moves,function() 
         cb(); 
     end)
end
function Pair:hiddenShadow()

    for i=1,#self.tiles do
        --self.tiles[i].shadow:setVisible(false) 
    end

end
function Pair:showShadow()
    for i=1,#self.tiles do
        --self.tiles[i].shadow:setVisible(true) 
       
        
       -- local delay = cc.DelayTime:create(0.3)
        local function hidden(t)
         --   t:setVisible(true) 
        end
       -- local cb = cc.CallFunc:create(hidden)
        --self.tiles[i].shadow:runAction(cc.Sequence:create(delay,cb))
        
    end

end
function Pair:moveLeft()
    local movedTiles = {}
    self.grid:forEachReverseOrder(function(m2position)
        if self.grid[m2position.y][m2position.x] ~= 0 then
            local tt = self.grid:leftTile(m2position.x,m2position.y)
            if tt ~= nil then 
                table.insert(movedTiles,tt)
            end
        end
    end)
 
    if #movedTiles > 0 then 
        --self:hiddenShadow()
        self.player:doMerge(movedTiles)
    else 
        self.player.action_state = 'normal' 
    end 
end
function Pair:moveRight()
    local movedTiles = {}
    
    self.grid:forEachReverseOrder(function(m2position)
        if self.grid[m2position.y][m2position.x] ~= 0 then
            local tt = self.grid:rightTile(m2position.x,m2position.y)
            if tt ~= nil then
                table.insert(movedTiles,tt)
            end
        end
    end,true)
    if #movedTiles > 0 then 
       -- self:hiddenShadow()
        self.player:doMerge(movedTiles)
    else 
        self.player.action_state = 'normal' 
    end 
    
end

function Pair:merge(changed_tiles)
 
    local mergedTiles = {}
    local isRight = false 

    local shadow_y =  self.pos.y
    if PFCommon.collides_with_blocks(self.current, self.grid, self.pos.x, self.pos.y) then
        isRight = true 
    end
   
    for y = 1, #self.current do
        for x = 1, #self.current[1] do
            if self.current[y][x] ~= ' ' then 
                local down_y = self.current[y][x].pos.y
                local down_x --= x + self.position_.x - 1
                if isRight then 
                     down_x = x + self.pos.x - 2   
                else
                     down_x = x + self.pos.x - 1
                end
                
                while true do
                    if not BTCommon.collides_with_blocks({"#"}, self.grid, down_x, down_y - 1) then
                        down_y = down_y - 1
                    else
                        break
                    end
                end
                self.grid[down_y][down_x] = self.current[y][x]
                self.current[y][x].oldPos ={x=self.current[y][x].pos.x,y=self.current[y][x].pos.y}
                self.current[y][x].pos={x=down_x,y=down_y}
           
                --local move = cc.MoveTo:create(0.2,self.grid:locationOfPosition(self.current[y][x].pos))
               -- self.current[y][x]:stopAllActions()
                
                local function remove()
                 --   self.current[y][x].shadow:stopAllActions()
                 --   self.current[y][x].shadow:removeFromParent()
                    self.current[y][x].shadow=nil
                end 
                --local delay = cc.DelayTime:create(0.3)
                --local removeShadow = cc.CallFunc:create(remove)
                --self.current[y][x]:addPendingAction(cc.Sequence:create(removeShadow,move))
                table.insert(mergedTiles,self.grid[down_y][down_x])
            end
        end
    end
  
    for i=1,#changed_tiles do
       -- local delay = cc.DelayTime:create(0.2)
       -- changed_tiles[i]:addPendingAction(cc.Sequence:create(delay))
        table.insert(mergedTiles,changed_tiles[i])
    end
   
    self.player.state = 'clearing'
    -- self.player:doMerge(mergedTiles)
    --self.player.state = 'clearing'
    --self.player.clearTiles = mergedTiles
    --move操作
     
    PFCommon.commitActionsWithLastCallback(mergedTiles,function() 
    -- PFCommon.createAnimation(mergedTiles[1],"block_drop_ani","play")
    -- PFCommon.createAnimation(mergedTiles[2],"block_drop_ani","play")
    
    --mergedTiles[1].newBlock:setGLProgramState(self.state)
    --mergedTiles[2].newBlock:setGLProgramState(self.state)
    --self.state:applyUniforms()
       self.player:doMerge(mergedTiles) 
    end)
    
 
end
return Pair