local PFCommon = import("..PFCommon")
local BTCommon = import("..BTCommon")

local grid = {};
---------------grid--------------------
local function grid_init(self)
    for y = 1, self.h+2 do
        self[y] = {}
        for x = 1, self.w do
            self[y][x] = 0
        end
    end
end
local function getTiles(self)
    local tiles = {}
    for y = 1, self.h+1 do

        for x = 1, self.w do
            if self[y][x] ~= nil and  self[y][x] ~=0 then
                table.insert(tiles, self[y][x])
            end
        end
    end
    return tiles
end
local function print_self(self)

    if self.currentPair then
        --print("---------------")
        local tiles = {}
        for y = 1, #self.currentPair.current do
            --	local row = "|"
            for x = 1, #self.currentPair.current[1] do
                if self.currentPair.current[y][x] ~= ' ' then
                    local down_y = self.currentPair.current[y][x].pos.y
                    local down_x = x + self.currentPair.pos.x - 1

                    if not tiles[down_y] then
                        tiles[down_y] = {}
                    end
                    tiles[down_y][down_x]=self.currentPair.current[y][x]
                    --table.insert(tiles,{x=down_x,y=down_y,tile=self.currentPair.current[y][x]})
                end

            end
            --print(row.." |")
        end
        for y = self.h+2,self.h,-1 do
            print("---------------")
            local row = "|"
            for x = 1, self.w do
                if tiles[y] and tiles[y][x] then
                    row = row.." "..tiles[y][x].color:sub(1,1)
                else
                    row = row.." ".."0"
                end
            end

            print(row.." |")
        end
    end
    for y = self.h,1,-1 do
        print("---------------")
        local row = "|"
        for x = 1, self.w do
            if "table"==type(self[y][x]) then
                row = row.." "..self[y][x].color:sub(1,1)
            else
                row = row.." "..self[y][x]
            end
        end
        print(row.." |")
    end
    print("---------------")
end
local  function grid_forEachReverseOrder(self,block,reverse)
    if reverse then
        for y = 1,self.h do
            for x = self.w,1,-1 do
                block({x=x,y=y})
            end
        end
    else
        for y = 1,self.h do
            for x = 1,self.w do
                block({x=x,y=y})
            end
        end
    end


end

local function grid_finding(self,tile)
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


function grid.new(conf)
    return {
        w = conf.w,
        h = conf.h,
        init = grid_init,
        print_self = print_self,
        forEachReverseOrder = grid_forEachReverseOrder,
        finding = grid_finding,
        currentPair = nil,
    }
end

return grid;