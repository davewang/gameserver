local PFCommon = import(".PFCommon")
local BTCommon = import(".BTCommon")
local Grid = class("Grid")
function Grid:ctor()
    self.w = 6
    self.h = 15
    self.offset = {x = 250, y = 350}
    --self.offset = {x = 100, y = 100}
    self:init()
     
end
function Grid:setOffset(offset)
    self.offset = offset
end
function Grid:init()
        for y = 1, self.h+1 do
            self[y] = {}
            for x = 1, self.w do
                self[y][x] = 0
            end
        end
end
--坐标转换x
function Grid:xLocationOfPosition(p,isshow)
    if isshow then
        return (p.x-1) * (self.blockShowConfig.w + self.blockShowConfig.offset)-- + block.offset;
    end
    return (p.x-1) * (self.blockConfig.w + self.blockConfig.offset)-- + block.offset;
end
--坐标转换y
function Grid:yLocationOfPosition(p,isshow)
    if isshow then
       return (p.y-1) * (self.blockShowConfig.h + self.blockShowConfig.offset)-- + block.offset;
    end
    return (p.y-1) * (self.blockConfig.h + self.blockConfig.offset)-- + block.offset;
end
--坐标转换
function Grid:locationOfPosition(p,isshow)
     
    --print(p.x)
    --print(p.y)
    
    return {x = self:xLocationOfPosition(p,isshow)+self.offset.x,y = self:yLocationOfPosition(p,isshow)+self.offset.y}-- + block.offset;
end
--得到可用的空间
function Grid:getAbleSpaces()
        local spaces = {}
        for y = 1,13 do
            for x = self.w,1,-1 do
               -- block({x=x,y=y})
                if self[y][x] == 0 then
                   table.insert(spaces,{x=x,y=y})
                end 
            end
        end
        return spaces
end
--得到整个区域的所有方块
function Grid:getAllTiles()
    local blocks = {}
    for y = 1,13 do
        for x = self.w,1,-1 do
            -- block({x=x,y=y})
            if self[y][x] ~= 0 then
                table.insert(blocks,{x=x,y=y})
            end
        end
    end
    return blocks
end
--得到方块
function Grid:getAbleTiles()
        local blocks = {}
        for y = 1,13 do
            for x = self.w,1,-1 do
               -- block({x=x,y=y})
                if self[y][x] ~= 0 then
                   table.insert(blocks,{x=x,y=y})
                end 
            end
        end
        local result = {}
        if #blocks > 0 then 
            for x = self.w,1,-1 do
                 local maxY = nil 
                 for i=1,#blocks do 
                    if blocks[i].x == x then 
                        if maxY then 
                           if blocks[i].y > maxY.y then 
                              maxY = blocks[i]
                           end 
                        else
                           maxY = blocks[i]
                        end 
                    end 
                 end 
                 if maxY then table.insert(result,self[maxY.y][maxY.x])  end 
                  
            end
        end
        
        return result
end

function Grid:checkBoxTiles()
        local normaltiles = {}
        for y = 1,12 do
            for x = self.w,1,-1 do
               -- block({x=x,y=y})
                if self[y][x] ~= 0 and self[y][x].type =="normal" then
                   table.insert(normaltiles,self[y][x])
                end 
            end
        end
        local groups = {}
        local group = {}
        while #normaltiles > 0 do 
            local tiles = self:findingBox( normaltiles[1])
            for i=0,#tiles do 
                 local del_index = nil 
                 for j=0,#normaltiles do
                    if normaltiles[j] == tiles[i] then
                        del_index = j 
                    end 
                 end  
                 table.remove(normaltiles, del_index)
            end 
            if #tiles>=4 then
                table.insert(groups,tiles) 
            end 
        end 
        
        print(#groups)
        
         
        --return normaltiles
end
function Grid:updateSolidTiles()
        local changed_tiles = {}
        for y = 1,12 do
            for x = self.w,1,-1 do
               -- block({x=x,y=y})
                if self[y][x] ~= 0 and self[y][x].type =="solid" then
                   --table.insert(tiles,self[y][x])
                   self[y][x]:updateSolid()
                   if self[y][x].type == "normal" then
                      table.insert(changed_tiles,self[y][x])
                   end 
                end 
            end
        end
        return changed_tiles
end
--得到指定方块下落的目标位置
function Grid:getTileAbleFallPoint(tile)
    local f_x = tile.pos.x
    local f_y = tile.pos.y
    while true do
        if not BTCommon.collides_with_blocks({"#"}, self, f_x,f_y-1) then
            f_y = f_y - 1 
        else
            break
        end 
    end
    return {x=f_x,y=f_y}
end 
--下落“方块”添加action到pending
function Grid:fallTile(tile)
   -- local tile = self[y][x]
    if tile ~= 0 then
        local to_p = self:getTileAbleFallPoint(tile)
        --local move = cc.MoveTo:create(0.2,self:locationOfPosition(to_p))
      
        self[tile.pos.y][tile.pos.x] = 0
        tile.pos.x = to_p.x
        tile.pos.y = to_p.y
        self[to_p.y][to_p.x]=tile
        --tile:addPendingAction(cc.Sequence:create(move))
        return tile
    end
    return nil
end
--检测是否可以下落“方块”
function Grid:checkFall(removed)
    local falled = {}
    for i=1,#removed do
        local t_x = removed[i].x
        local t_y = removed[i].y
        for y=t_y,self.h  do
            if self[y][t_x] ~= 0 then
                if not PFCommon.isExist(removed,self[y][t_x]) then
                    local tt = self:fallTile(self[y][t_x])
                    if tt ~= nil then
                        table.insert(falled,tt)
                    end 
                end
            end
        end
    end
    return falled
end
 
function Grid:findingBox(tile)
    local start = tile
    local open_list = {start}
    local close_list = {}
     
    while #open_list ~= 0 do 
        --从open中取开始点
        local current = table.remove(open_list,1)
        table.insert(close_list,current)
        local left = {y=current.pos.y,x=current.pos.x-1} 
        if left.x>0 and self[left.y][left.x] ~=0 and self[left.y][left.x].color == self[current.pos.y][current.pos.x].color  then
                if PFCommon.contains(open_list,left) or PFCommon.contains(close_list,left)  then
                    --print("is have!")
                else
                    if self[left.y][left.x].type == 'normal' then 
                     table.insert(open_list, self[left.y][left.x])
                    end
                end
        end
        local right = {y=current.pos.y,x=current.pos.x+1}
        if right.x < self.w+1 and self[right.y][right.x] ~=0 and self[right.y][right.x].color == self[current.pos.y][current.pos.x].color  then
            if PFCommon.contains(open_list,right) or PFCommon.contains(close_list,right)  then
        --print("is have!")
            else
                 if self[right.y][right.x].type == 'normal' then 
                  table.insert(open_list, self[right.y][right.x])
                end
            end
        end
        local up = {y=current.pos.y-1,x=current.pos.x}
        if up.y>0 and self[up.y][up.x] ~=0 and self[up.y][up.x].color == self[current.pos.y][current.pos.x].color  then
            if PFCommon.contains(open_list,up) or PFCommon.contains(close_list,up)  then
        -- print("is have!")
            else
               if self[up.y][up.x].type == 'normal' then
                 table.insert(open_list, self[up.y][up.x])
               end
            end
        end
        local down = {y=current.pos.y+1,x=current.pos.x}
        if down.y<self.h+1 and self[down.y][down.x] ~=0 and self[down.y][down.x].color == self[current.pos.y][current.pos.x].color  then
            if PFCommon.contains(open_list,down) or PFCommon.contains(close_list,down)  then
        --print("is have!")
            else
                if self[down.y][down.x].type == 'normal' then
                 table.insert(open_list, self[down.y][down.x])
                end
            end
        end
        
        
    end 
    
    return close_list
     
end
--查找可消除的方块 A*查找
function Grid:finding(tile)
    local start = tile
    local open_list = {start}
    local close_list = {}
     
    while #open_list ~= 0 do 
        --从open中取开始点
        local current = table.remove(open_list,1)
        table.insert(close_list,current)
        local left = {y=current.pos.y,x=current.pos.x-1} 
        if left.x>0 and self[left.y][left.x] ~=0 and self[left.y][left.x].color == self[current.pos.y][current.pos.x].color  then
                if PFCommon.contains(open_list,left) or PFCommon.contains(close_list,left)  then
                    --print("is have!")
                else
                    if self[left.y][left.x].type ~= 'solid' then 
                     table.insert(open_list, self[left.y][left.x])
                    end
                end
        end
        local right = {y=current.pos.y,x=current.pos.x+1}
        if right.x < self.w+1 and self[right.y][right.x] ~=0 and self[right.y][right.x].color == self[current.pos.y][current.pos.x].color  then
            if PFCommon.contains(open_list,right) or PFCommon.contains(close_list,right)  then
        --print("is have!")
            else
                 if self[right.y][right.x].type ~= 'solid' then 
                  table.insert(open_list, self[right.y][right.x])
                end
            end
        end
        local up = {y=current.pos.y-1,x=current.pos.x}
        if up.y>0 and self[up.y][up.x] ~=0 and self[up.y][up.x].color == self[current.pos.y][current.pos.x].color  then
            if PFCommon.contains(open_list,up) or PFCommon.contains(close_list,up)  then
        -- print("is have!")
            else
               if self[up.y][up.x].type ~= 'solid' then
                 table.insert(open_list, self[up.y][up.x])
               end
            end
        end
        local down = {y=current.pos.y+1,x=current.pos.x}
        if down.y<self.h+1 and self[down.y][down.x] ~=0 and self[down.y][down.x].color == self[current.pos.y][current.pos.x].color  then
            if PFCommon.contains(open_list,down) or PFCommon.contains(close_list,down)  then
        --print("is have!")
            else
                if self[down.y][down.x].type ~= 'solid' then
                 table.insert(open_list, self[down.y][down.x])
                end
            end
        end
        
        
    end 
    
   
    if #close_list>1 then 
        for i=1,#close_list do 
             if close_list[i].type ~= 'solid' and close_list[i].type ~= 'crash' then 
                  -- close_list[i]:addPendingAction(cc.ScaleTo:create(0.2, 1))
                    
             end
              
        end 
    end 
    local ishave =  false 
    if PFCommon.isHaveCrash(close_list) then
        ishave = true     
    end
    return close_list,ishave
end

function Grid:forEachReverseOrder(block,reverse)
       if reverse then
        for y = 1,12 do
            for x = self.w,1,-1 do
                block({x=x,y=y})
            end
        end
       else
        for y = 1,12 do
            for x = 1,self.w do
                block({x=x,y=y})
            end
        end
       end
       
       
end
--根据grid的pos得到tile
function Grid:tileAtPosition(m2pos)
    if self[m2pos.y][m2pos.x] ~= 0 then
    
        return self[m2pos.y][m2pos.x]
    end
	return nil
end




function Grid:getTileAbleRightPoint(x,y)
    local f_x = x
    local f_y = y
    while true do
        if not BTCommon.collides_with_blocks({"#"}, self, f_x+1,f_y) then
            f_x = f_x + 1 
        else
            break
        end 
    end
    return {x=f_x,y=f_y}
end
function Grid:getTileAbleLeftPoint(x,y)
    local f_x = x
    local f_y = y
    while true do
        if not BTCommon.collides_with_blocks({"#"}, self, f_x-1,f_y) then
            f_x = f_x - 1 
        else
            break
        end 
    end
    return {x=f_x,y=f_y}
end
function Grid:rightTile(x,y)
    local tile = self[y][x]
    if tile ~= 0 then
        local to_p = self:getTileAbleRightPoint(x,y)
       -- local move = cc.MoveTo:create(0.2,self:locationOfPosition(to_p))
        tile.pos.x = to_p.x
        tile.pos.y = to_p.y
        self[y][x] = 0
        self[to_p.y][to_p.x]=tile
        --tile:addPendingAction(cc.Sequence:create(move)) 
        return tile
    end
    return nil
end
function Grid:leftTile(x,y)
    local tile = self[y][x]
    if tile ~= 0 then
        local to_p = self:getTileAbleLeftPoint(x,y)
       -- local move = cc.MoveTo:create(0.2,self:locationOfPosition(to_p))
        tile.pos.x = to_p.x
        tile.pos.y = to_p.y
        self[y][x] = 0
        self[to_p.y][to_p.x]=tile
       -- tile:addPendingAction(cc.Sequence:create(move)) 
        return tile
    end
    return nil
end

return Grid