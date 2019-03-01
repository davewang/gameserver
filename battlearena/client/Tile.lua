local Tile = class("Tile")
function Tile:ctor(config)
    config.alpha = config.alpha or 255
    self.pos = {x=0,y=0} 
    self.pendingActions = {}
    self.pendingActionIndex = 0
    self.grid = nil 
    self.h = config.h
    self.w = config.w
    self.color = config.color
    self.type = config.type
    self.times = 5
     
    
end 
function Tile:updateSolid()
    self.times =  self.times - 1
    if self.times == 0 then
       self.type = "normal"   
    end 
end

function Tile:commitPendingActions()
    if #self.pendingActions > 0 then 
         self.pendingActions = {}
        self.pendingActionIndex = 0
    end
end
function Tile:commitPendingActionsWithEndCallBack(callback)
     callback()
    -- local callbackAction = cc.CallFunc:create(callback);
    -- self.pendingActions[self:IncrementIndex()] = callbackAction
    -- if #(self.pendingActions) > 0 then 

    --     self:runAction(cc.Sequence:create(self.pendingActions))
    --     self.pendingActions = {}
    --     self.pendingActionIndex = 0
    -- end

end
 
  
function Tile:removeFromParentCell()
    -- A move is only one action, so if there are more than one actions, there must be
    -- a merge that needs to be committed. If things become more complicated, change
    -- this to an explicit ivar or property.
    self.grid[self.pos.y][self.pos.x] = 0

end  

function Tile:removeWithDelay()
    self:removeFromParentCell()
end
function Tile:IncrementIndex()
    self.pendingActionIndex = self.pendingActionIndex+1
    return self.pendingActionIndex
end
 
 
  
 
function Tile:addPendingAction(action) 
    self.pendingActions[self:IncrementIndex()] = action

end
function Tile:removeAnimated(animated)
    self:removeFromParentCell()
   
end

function Tile:onEnter()
    print("Tile:onEnter") 
end 

function Tile:onExit()
end

return Tile