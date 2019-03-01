
local tile = {};
local function tile_setPos(self,pos)
    self.pos.x=pos.x;
    self.pos.y=pos.y;
end
local function tile_commitPendingActions(self)
    if #self.pendingActions > 0 then
        self.pendingActions = {}
        self.pendingActionIndex = 0
    end
end
local function tile_commitPendingActionsWithEndCallBack(self,callback)
    callback()
end
--------------tile--------------
function tile.new(conf)
    return {
        type = conf.type,
        color = conf.color,
        pos = conf.pos,
        setPos = tile_setPos,
        pendingActions = {},
        commitPendingActions = tile_commitPendingActions,
        commitPendingActionsWithEndCallBack = tile_commitPendingActionsWithEndCallBack,

    }
end

return tile;