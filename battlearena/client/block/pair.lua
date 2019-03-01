
local PFCommon = import("..PFCommon")
local BTCommon = import("..BTCommon")

local tile = import(".tile")
local pair = {};
--------------pair--------------
local function pair_init(self)
    self:initTiles()
end
local function pair_undo_dorp(self,changed_tiles)
    if self.undo_pos then
        self.pos = {x=self.undo_pos.x,y=self.undo_pos.y}
    end
    self:move(function()
    end)
end
local function pair_drop(self)
    self.undo_pos = {x=self.pos.x,y=self.pos.y}
    while true do
        if self:fall() then break end
    end
    self:move(function()
    end)

end
local function pair_moveDirection(self,dx)

    local isMove = false
    -- print("1 self.pos.x =",self.pos.x )
    if not PFCommon.collides_with_blocks(self.current, self.grid, self.pos.x + dx, self.pos.y) then
        self.pos.x = self.pos.x + dx
        isMove = true
    end
    --print("2 self.pos.x =",self.pos.x )

    self:move(function()
        --self.player.action_state = "normal"
    end)
    return isMove
    --if PFCommon.is_on_floor(self.grid,self) then
    --self.player.state = 'on_floor'
    --end


    -- if rules.move_reset then
    --     game.frame = 1
    -- end


end
local function pair_fall(self)

    -- todo check if floor is reached
    if not PFCommon.collides_with_blocks(self.current, self.grid, self.pos.x, self.pos.y - 1) then
        self.pos.y = self.pos.y - 1
        --self.player.frame = 1 --reset lock delay

        return false
    else
        return true
    end
end
local function pair_rotate(self)
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
local function pair_move(self,cb)

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


local function pair_undo_merge(self,changed_tiles)
    --undo grid
    for i=1,#changed_tiles do
        self.grid[changed_tiles[i].pos.y][changed_tiles[i].pos.x] = 0;
        --table.insert(mergedTiles,changed_tiles[i])
        changed_tiles[i].pos.y = changed_tiles[i].oldPos.y
        changed_tiles[i].pos.x = changed_tiles[i].oldPos.x
    end

end

local function pair_merge(self,changed_tiles)

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
local function pair_building_tile(self,x,y,attr)
    local tileNew = tile.new({pos={x=x,y=y},type=attr.type,color = attr.color})
    tileNew.grid = self.grid
    --print("buildingTile")
    return tileNew
end
local function pair_move_to(self,x)
    local move = ( x - self.pos.x)
    return self:moveDirection(move)
end
local function pair_init_tiles(self)
    --print("pair_init_tiles")
    local newData = {}
    for y = 1, #self.data do
        newData[y] = {}
        for x = 1, #self.data[1] do
            if self.data[1][x] then
                --print(self.data[1][x].info.type)
                --print(self.data[1][x].info.color)
                self.tiles[#self.tiles+1] = self:buildingTile(self.pos.x + x - 1, self.pos.y + y - 1,{type = self.data[1][x].info.type,color =self.data[1][x].info.color })
                newData[y][x] = self.tiles[#self.tiles]
            end

        end
    end
    --print("pair_init_tiles")
    self.current = newData
    self.grid.currentPair = self

end
function pair.new(conf)
    return {
        grid = conf.grid,
        pos = conf.pos,
        tiles = {},
        data = conf.data,
        init = pair_init,
        initTiles = pair_init_tiles,
        current = {},
        fall = pair_fall,
        buildingTile = pair_building_tile,
        undoDrop = pair_undo_dorp,
        drop = pair_drop,
        move = pair_move,
        moveTo = pair_move_to,
        undoMerge = pair_undo_merge,
        merge = pair_merge,
        moveDirection = pair_moveDirection,
        rotate = pair_rotate,
    }
end

return pair;