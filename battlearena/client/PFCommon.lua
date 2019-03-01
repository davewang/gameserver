local PFCommon = {}
PFCommon.commitActions = function(objs)
        for i=1,#objs do 
           -- print(string.format("tile pos[%d,%d], actions %d",objs[i].pos.x,objs[i].pos.y,#objs[i].pendingActions))
            objs[i]:commitPendingActions()
        end  
end 
PFCommon.commitActionsWithLastCallback = function(objs,cb)
        for i=1,#objs do 
          --  print(string.format("tile pos[%d,%d], actions %d",objs[i].pos.x,objs[i].pos.y,#objs[i].pendingActions))
           
            if i == #objs then 
                objs[i]:commitPendingActionsWithEndCallBack(cb)
            else 
                objs[i]:commitPendingActions()
            end 
        end  
          
end
PFCommon.contains = function(tiles,e)
	for i=1,#tiles do
		if tiles[i].pos.x == e.x and tiles[i].pos.y == e.y then
			return true
		end
	end
	return false
end
PFCommon.isJoin = function(tab1,tab2)
    --local joinTab = {}
    for i=1,#tab1 do
        for j=1,#tab2 do
            if tab1[i].pos.x == tab2[j].pos.x and tab1[i].pos.y == tab2[j].pos.y  then
               -- table.insert(joinTab,tab1[i]) 
                return true
            end
        end
        
    end
    return false
end
--t is grid e 
PFCommon.isExist = function(t,e)
    for i=1,#t do
        if t[i].x == e.x and t[i].y == e.y then
            return true
        end
    end
    return false
end

PFCommon.isHaveCrash = function(tiles)
    for i=1,#tiles do
        if tiles[i].type == "crash" then
            return true
        end 
    end
    return false 
end
------------------------------------------------------------
--- Checks

PFCommon.is_on_floor = function(grid,pair)
    --坚持是否接触到地面 
    return PFCommon.collides_with_blocks(pair.current,grid,pair.pos.x,pair.pos.y-1 ) 
end

-- PFCommon.collides_with_spawn_zone = function(fig_to_test, field, test_x, test_y)
--     return PFCommon.collision_at(fig_to_test, test_x, test_y,
--         function (field_x, field_y)
--             --if field_y < 1 then return true end
--             if field_y > field.h then return true end
--         end)
-- end
 
PFCommon.collides_with_blocks = function(fig_to_test, field, test_x, test_y)
    return PFCommon.collision_at(fig_to_test, test_x, test_y,
        function (field_x, field_y)
            --print("field y ="..tostring(field_y))
            --print("field x ="..tostring(field_x))
            if field[field_y] == nil or
                field[field_y][field_x] == nil or
                field[field_y][field_x] ~= 0 then
                return true
            end
        end)
end

-- returns true if figure collides. tester_fun(field_x, field_y)
PFCommon.collision_at = function (fig_to_test, test_x, test_y, tester_fun)
    for y = 1, #fig_to_test do
        for x = 1, #fig_to_test[1] do
            if fig_to_test[1][x] ~= nil then
                if tester_fun(x + test_x - 1, y + test_y - 1) then return true end
            end
        end
    end
    return false
end
PFCommon.deepcopy = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
    copy = orig
    end
    return copy
end




--
-- PFCommon.createAnimation = function(node,name,animationName,cb)
--      local armature = ccs.Armature:create(name)--block_drop_ani
--      armature:setPosition(cc.p(display.cx ,display.cy))
--      node:addChild(armature)
--     --  armature:getAnimation():setMovementEventCallFunc(cb)
--     -- armature:getAnimation():setSpeedScale()
--      armature:getAnimation():play(animationName)
--      return armature
-- end 


 
return PFCommon