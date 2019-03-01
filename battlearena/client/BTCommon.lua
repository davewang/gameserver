
local BTCommon = {}
BTCommon.animationDuration = 0.1

--block look
BTCommon.block = {
    --w = 15,
   -- h = 15,
   w = 50,
   h = 50,
    offset = 1 -- space between blocks
}
 

-- tetris color scheme
BTCommon.colors = {
    -- {0, 255, 255},
    -- {32, 64, 255},
    -- {255, 128, 0},
    -- {255, 255, 16},
    -- {255, 16, 255},
    -- {0, 255, 0},
    -- {255, 0, 0},
    -- {128, 0, 128}
    "block_1.png",
    "block_2.png",
    "block_3.png",
    "block_4.png",
    "block_5.png",
    "block_6.png",
    "block_7.png",
    "block_8.png",
    "block_x.png"
    
}


-- list of possible figures
-- they are colored by their index in 'colors' list
BTCommon.figures = {
    {'    ', '####', '    '},
    {'#  ', '###', '   '},
    {'  #', '###', '   '},
    {'##', '##'},
    {' ##', '## ', '   '},
    {'## ', ' ##', '   '},
    {' # ', '###', '   '}
}




BTCommon.rules = {
    fps = 60,               -- frames per second
    shadow = true,          -- shadow piece
    gravity = 0,            -- 0-disabled, 1-sticky, 2-cascade (only 0 implemented)
    next_visible = 2,       -- number of preview pieces
    move_reset = false,     -- reset timer on horizontal moves
    spin_reset = false,     -- reset timer on rotation
    hard_drop_lock_delay = false, -- delay piece locking after hard drop
    wall_kick = false,      -- wall kicks (not implemented)

    frame_delay = 1/60,     -- defines framerate
    lock_delay = 30,        -- delay before piece locks
    spawn_delay = 1,        -- delay before piece spawns
    clear_delay = 10,       -- delay after piece locks and before next piece spawns
    autorepeat_delay = 15,  -- initilal delay
    autorepeat_interval = 4, -- delay between moves

    playfield_width = 10,   -- width of the playfield.
    playfield_height = 20,  -- height of the playfield. 2 invisible rows will be added.

    rotation_system = 'simple', -- 'srs', 'dtet', 'tgm'. simple is only implemented
    randomizer = 'rg',-- 'stupid'-just math.random, 'rg'-7-bag, 'tgm'(not implemented)

    soft_gravity = {delay = 3, distance = 1} -- G = distance / delay. Params of the soft drop.
-- delay means how frequent will piece fall. distance - number of blocks.
}

-- stores game info, such as score, game speed etc.
--BTCommon.game = {
--    state = '',--'running', 'clearing', 'game_over', 'spawning', 'paused', 'on_floor'(when lock delay>0)
--    state_names = {on_floor = 'On floor', clearing = 'Clearing full lines',
--        game_over = 'Game over', paused = 'Paused', in_air = 'Falling', spawning = 'Spawning'},
--    last_state = '', -- stores state before pausing
--
--    timer = 0, --in seconds
--
--    frame = 1, -- in frames
--    autorepeat_timer = 1, -- in frames
--    hold_timer = 1, --in frames, frames since left or right is holded
--
--    gravity = 1,
--    gravities = {{delay = 64, distance = 1}, rules.soft_gravity}, -- delay with which figure fall occurs.
--
--    hold_dir = 0, -- -1 left, 1 right, 0 none
--
--    lines_to_remove = {},
--
--    score = 0,
--    level = 1,
--
--    init = function()
--        game.score = 0
--        game.level = 1
--        game.curr_interval = 0
--        game.frame_delay = 1/rules.fps
--        game.frame_timer = 0
--        game.gravities = {{delay = 64, distance = 1}, rules.soft_gravity}
--        game.history = {}
--        game.random_gen_data = {}
--        figure.next = {}
--        for i=1, rules.next_visible do
--            table.insert(figure.next, game.random_fig())
--        end
--        --spawn_fig()
--    end,
--
--    history = {},
--    random_gen_data = {},
--
--    random_fig = function()
--        local result = randomizers[rules.randomizer](game.history, game.random_gen_data)
--
--        local figure = {}
--        for _, line in ipairs(figures[result]) do
--            table.insert(figure, line)
--        end
--        figure.index = result
--        table.remove(BTCommon.game.history)
--        table.insert(BTCommon.game.history, 1, result)
--        return figure
--    end
--}




-- field size and position
-- also stores blocks as two-dimentional array
-- '1' means no block, others are blocks and colored by the 'colors' table
--BTCommon.field = {
--    w = 0,
--    h = 0,
--    offset = {x = 250, y = 350},
--
--    init = function ()
--        BTCommon.field.w = BTCommon.rules.playfield_width
--        BTCommon.field.h = BTCommon.rules.playfield_height
--        for y = 1, field.h+2 do
--            BTCommon.field[y] = {}
--            for x = 1, BTCommon.field.w do
--                BTCommon.field[y][x] = 0
--            end
--        end
--    end
--}

--BTCommon.figure = {
--    x = 0,
--    y = 0,
--    currentDraw = nil,
--    current = {},
--    next = {}, -- array of figures
--}

 
BTCommon.xLocationOfPosition =  function(p,block_config)
    --return (p.x-1) * (BTCommon.block.w + BTCommon.block.offset)-- + block.offset;
    return (p.x-1) * (block_config.w + block_config.offset)
end

BTCommon.yLocationOfPosition = function(p,block_config)
    --return (p.y-1) * (BTCommon.block.w + BTCommon.block.offset)-- + block.offset;
    return (p.y-1) * (block_config.h + block_config.offset)
end

BTCommon.locationOfPosition = function(grid,p,block_config)
    --print("x "..tostring(GCommon.Craft.Grid.xLocationOfPosition(p)))
    --print("y "..tostring(GCommon.Craft.Grid.yLocationOfPosition(p)))
    return {x=BTCommon.xLocationOfPosition(p,block_config)+ grid.offset.x,y=BTCommon.yLocationOfPosition(p,block_config)+grid.offset.y}
end  

--function shuffle_array(array)
--    local counter = #array
--    while counter > 1 do
--        local index = math.random(counter)
--        array[counter], array[index] = array[index], array[counter]
--        counter = counter - 1
--    end
--end
BTCommon.shuffle_array = function(array)
    local counter = #array
    while counter > 1 do
        local index = math.random(counter)
        array[counter], array[index] = array[index], array[counter]
        counter = counter - 1
    end
end

BTCommon.randomizers = {
    stupid = function(history, data)
        local index = math.random(1, #BTCommon.figures)
        return index
    end,
    rg = function(history, bag)
        local result = nil
        if #bag == 0 then
            for i=1, #BTCommon.figures do
                bag[i] = i
            end
            BTCommon.shuffle_array(bag)
            --shuffle_array(bag)
        end
        result = bag[1]
        table.remove(bag, 1)

        return result
    end
}
------------------------------------------------------------
--- Checks

BTCommon.is_on_floor = function(grid,figure)
    return BTCommon.collides_with_blocks(figure.current, grid, figure.x, figure.y-1)
end

BTCommon.collides_with_spawn_zone = function(fig_to_test, field, test_x, test_y)
    return BTCommon.collision_at(fig_to_test, test_x, test_y,
        function (field_x, field_y)
            --if field_y < 1 then return true end
            if field_y > field.h then return true end
        end)
end
 
BTCommon.collides_with_blocks = function(fig_to_test, field, test_x, test_y)
    return BTCommon.collision_at(fig_to_test, test_x, test_y,
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
BTCommon.collision_at = function (fig_to_test, test_x, test_y, tester_fun)
    for y = 1, #fig_to_test do
        for x = 1, fig_to_test[1]:len() do
            if string.sub(fig_to_test[y], x, x) ~= ' ' then
                if tester_fun(x + test_x - 1, y + test_y - 1) then return true end
            end
        end
    end

    return false
end

return BTCommon
