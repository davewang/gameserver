--local TetrisBase = import("..models.TetrisBase")
local Player = import(".Player")
local PFCommon = import(".PFCommon")
local Robot = class("Robot")
 
local OperationType = {
    left=1,right=2,rotate=3,drop=4
}
function Robot:ctor(app)
    self.score = 0
    self.commands= {}
    
    self.game_ = Player:create() 
 
    self.matchManager = app.matchManager
    self.matchManager:clearQueue()
    self.matchManager:addListener(self)
    
    self.game_.delegate = self    
    
    self.oldTime = os.clock()
    self.sep = 0
end
function Robot:loadBoardWithGrid(gird)
    
end
function Robot:onWarning(gird)
end 
function Robot:onCaution(gird)
end 
function Robot:onDeath(gird)
 end 
function Robot:onGameOver()
    self.matchManager:sendGameOverMsg()      
    self.game_.state = 'paused'
    print("Robot:onGameOver")
    removelistener(self.func_)
    self.matchManager:cancelMatchmakingOpponent()
    self.matchManager:removeListener(self)
     
    --self:dispatchEvent({name = LocalGameView.events.PLAYER_GAME_OVER_EVENT})
end
function Robot:start()
    self.func_ = handler(self, self.step)
    registerlistener(self.func_)
    
    
    --self:scheduleUpdate(handler(self, self.step))
    return self
end
function Robot:onGem(count)
     self.matchManager:sendSolidMsg(count)
end 
function Robot:onReceived(msg)
    print("Robot:onReceived")
    if msg.msg_type == 1 then
        
        if msg.msgid==2001 then
           table.insert(self.commands,msg)
        end
        if msg.msgid==9001 then
              --print(#msg.data)
              for i=1,#msg.data do 
                 print(string.format("{a=%d,b=%d}",msg.data[i].a,msg.data[i].b))
              end 
              self.game_.blockData = msg.data
              self.game_:start()
              --self:getApp():hideLoadingView() 
              self:start()
            --self:build_next(msg.next)
            --self:spawn_build_fig(msg.random_fig)
        end
    elseif msg.msg_type == 0 then 
        if msg.msgid==1008 then
            self.game_.state = 'paused'
            removelistener(self.func_)
            self.matchManager:cancelMatchmakingOpponent()
            self.matchManager:removeListener(self)
     
           --table.insert(self.commands,msg)
        end
        if msg.msgid==1009 then
             self.game_.state = 'paused'
             removelistener(self.func_)
             self.matchManager:cancelMatchmakingOpponent()
             self.matchManager:removeListener(self)
     
           --table.insert(self.commands,msg)
        end
        
    end
end
function Robot:getScore()
    return self.score
end

function Robot:updateScore(score)
    print("score = "..score)
   -- self.score = score 
end
function Robot:stop()
    --self:unscheduleUpdate()
    removelistener(self.func_)
    return self
end
function Robot:step(dt)
    self.game_:step(dt)
    self.sep = self.sep + dt
    print(self.game_.state)
    if math.floor(self.sep) == 2 and self.game_.state == 'in_air' then
      self.sep = 0
      --self:seekSolution()

      local all = {}
      for i=1,4 do
          for j=1,self.game_.grid.w do
              if self.game_.currentPair:moveTo(j) then
                  self.game_.currentPair:drop1();
                  local mergedTiles = self.game_.currentPair:merge1();
                  local data = self:seekSolutionNew();
                  table.insert(all,{count=data.max,rotate_count = i,move_x=j});
                  self.game_.currentPair:undoMerge(mergedTiles);
                  self.game_.currentPair:undoDrop();
              else
              end
          end
          self.game_.currentPair:rotate1();
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
--      local isMove = self.game_:moveDirection(move)
--      self.game_.hold_dir = 1
--      self.matchManager:sendMoveDirectionMsg(move)
--
--      self:moveTo(all[1].move_x)
      self:doDrop()
--      newPair:drop();
--      newPair:merge();



      --print( "step date = "..os.date("%T"))
      
    end 
    --print( "step date = "..os.date("%T"))
    if #self.commands > 0 and self.game_.action_state == "normal" and self.game_.state == 'in_air' then 
        local msg = table.remove(self.commands,1)
        if msg.solid_count > 5 then
         -- playSound(GAME_SFXS.clear3)
          --PFCommon.createAnimation(self,"jiguang","play3",nil)
        elseif msg.solid_count > 2 then
          --playSound(GAME_SFXS.clear2)
          --PFCommon.createAnimation(self,"jiguang","play2",nil)
        else 
          --playSound(GAME_SFXS.clear1)
          --PFCommon.createAnimation(self,"jiguang","play1",nil)
        end 
        
        local st = self.game_:addGem(msg.solid_count)
        self.matchManager:sendGemMsg(msg.solid_count)
        -- if st== "death" then 
        --     self:onDeath(self.gird)
        -- elseif st== "warning" then 
        --     self:onWarning(self.gird)
        -- elseif st== "caution" then 
        --     self:onCaution(self.gird) 
        -- end 
    
       
    end 
     
end

function Robot:doLeft()
   print("Robot:doLeft()")
    if self.game_.state == 'in_air' then 
       
                        self.game_:moveDirection(-1)
                        self.game_.hold_dir = 1
                        self.matchManager:sendMoveDirectionMsg(-1)
                         
    end
end 
function Robot:doRight()
 print("Robot:doRight()")
    if self.game_.state == 'in_air' then 
                        self.game_:moveDirection(1)
                        self.game_.hold_dir = 1
                        self.matchManager:sendMoveDirectionMsg(1)
                        
    end
end
function Robot:doMoveTo(dx)
    print("Robot:doMoveTo()")
    if self.game_.state == 'in_air' then
        self.game_:moveDirection(dx)
        self.game_.hold_dir = 1
        self.matchManager:sendMoveDirectionMsg(dx)

    end
end
--2016-5-20
function Robot:moveTo(dx)
    print("Robot:moveTo()")
    if self.game_.state == 'in_air' then
        local move = ( dx - self.game_.currentPair.pos.x)
        local isMove = self.game_:moveDirection(move)
        self.game_.hold_dir = 1
        self.matchManager:sendMoveDirectionMsg(move)
        return isMove;
    end
    return false;
end
function Robot:doRotate()
    if self.game_.state == 'in_air' then 
             self.game_:rotate()
             self.matchManager:sendRotateMsg()
    end
end 

function Robot:doDrop()
    print("Robot:doDrop()")
    if self.game_.state == 'in_air' and self.game_.action_state == 'normal' then 
             self.game_:drop()
             self.matchManager:sendDropMsg()
    end
end 

function Robot:commitOperations(operations)
    for i=1,#operations do 
        if operations[i]== OperationType.left then
           self:doLeft()
        elseif operations[i]== OperationType.right then
           self:doRight()
        elseif operations[i]== OperationType.rotate then
           self:doRotate()
        elseif operations[i]== OperationType.drop then
           self:doDrop()
        end 
    end 
end

--function Robot:commitOperations1(operations)
--    for i=1,#operations do
--        if operations[i]== OperationType.left then
--            self:doLeft()
--        elseif operations[i]== OperationType.right then
--            self:doRight()
--        elseif operations[i]== OperationType.rotate then
--            self:doRotate()
--        elseif operations[i]== OperationType.drop then
--            self:doDrop()
--        end
--    end
--end
function Robot:seekSolutionNew()
    print("seekSolutionNew")
--    if self.game_.state ~= 'in_air'  then
--        return
--    end
    local copedCurrentPair= self.game_.currentPair

    --copedCurrentPair.grid = copedGrid
    local findA,ishave = self.game_.grid:finding(copedCurrentPair.tiles[1])
    local findB,ishave = self.game_.grid:finding(copedCurrentPair.tiles[2])

    if #findA>#findB then
        return {max=#findA,a =findA,b=findB }
    elseif #findA<#findB then
        return {max=#findB,a =findA,b=findB }
    elseif #findA==#findB then
        return {max=#findB,a =findA,b=findB }
    end

end
function Robot:seekSolution()
    print("seekSolution")
    if self.game_.state ~= 'in_air'  then
        return
    end  
     
    local operations = {}
    --获得grid的所有方块 计算出每一列最高的的方块 进行 评估
    local tiles = self.game_.grid:getAbleTiles()
    local currentTiles = self.game_.currentPair.tiles
    if #tiles > 0 then
        for i=1,#tiles do 
            for j=1,#currentTiles do 
                if tiles[i].type == currentTiles[j].type then
                   local dx = currentTiles[j].pos.x-tiles[i].pos.x
                   if dx > 0  then
                      for k=1,dx do 
                          table.insert(operations,OperationType.right)
                      end 
                   else 
                      for k=1,math.abs(dx) do 
                          table.insert(operations,OperationType.left)
                      end 
                   end 
                   break;
                end                
            end 
        end 
        table.insert(operations,OperationType.drop)
    else  
        print(OperationType.drop)
        table.insert(operations,OperationType.drop)
    end 
    
    print(string.format("operations count %d",#operations))
    self:commitOperations(operations)
     
end 
function Robot:onTouch(event)
    if self.game_.state == 'paused' then
    	return
    end 
     local label = string.format("swipe: %s", event.name)
    
    
    if self.game_.state == 'in_air' then 
                        self.game_:moveDirection(1)
                        self.game_.hold_dir = 1
                        self.matchManager:sendMoveDirectionMsg(1)
                        
    end
    if self.game_.state == 'in_air' then 
                        self.game_:moveDirection(-1)
                        self.game_.hold_dir = 1
                        self.matchManager:sendMoveDirectionMsg(-1)
                         
    end
    
    
     if self.game_.state == 'in_air' and self.game_.action_state == 'normal' then 
                         self.game_:drop()
                         self.matchManager:sendDropMsg()
     end
      if self.game_.state == 'in_air' then 
             playSound(GAME_SFXS.transform)
             self.game_:rotate()
             self.matchManager:sendRotateMsg()
        end
    -- self.stateLabel:setString(label)
     --print("label = "..label)
    if event.name == 'began' then
        self.hasPendingSwipe=true
        self.mx=event.x;
        self.my=event.y;
        self.isDirectionTouch = false
        self.startTime = os.clock()
        self.direction = nil
        return true
    elseif event.name == 'moved' then
        local tx = event.x
        local ty = event.y

        if self.hasPendingSwipe and (math.abs(self.mx-tx)>EFFECTIVE_SWIPE_DISTANCE_THRESHOLD or math.abs(self.my-ty)>EFFECTIVE_SWIPE_DISTANCE_THRESHOLD ) then
            self.isDirectionTouch = true
            self.hasPendingDir = false
           
            self.direction = nil
            if math.abs(self.mx-tx)>math.abs(self.my-ty)  then
                self.hasPendingDir = true
                if self.mx<tx then
                    self.direction = DIRECTION.right
                    label = string.format("swipe: %s", "right")
                    if self.game_.state == 'in_air' then 
                        self.game_:moveDirection(1)
                        self.game_.hold_dir = 1
                        self.matchManager:sendMoveDirectionMsg(1)
                        playSound(GAME_SFXS.move)
                     end
                      
                      --self.opponent:moveDirection(1)
                 --   self.game_:around(1)
                  --  self.game_.hold_dir = 1
                 --   playSound(GAME_SFXS.move)
                else
                    self.direction = DIRECTION.left
                    label = string.format("swipe: %s",  "left")
                     if self.game_.state == 'in_air' then 
                        self.game_:moveDirection(-1)
                        self.game_.hold_dir = 1
                        self.matchManager:sendMoveDirectionMsg(-1)
                        playSound(GAME_SFXS.move)
                     end
                    
                   -- self.opponent:moveDirection(-1)
                  --  self.game_:around(-1)
                  --  self.game_.hold_dir = 1
                  --  playSound(GAME_SFXS.move)
                end
            else
                self.hasPendingSwipe = false
                if self.my<ty then

                    self.direction = DIRECTION.up
                    label = string.format("swipe: %s",  "up")
                    self.game_:hold()
                    self.matchManager:sendHoldMsg()
                    --self.opponent:hold()
                  
                else
                
                    self.direction = DIRECTION.down
                    label = string.format("swipe: %s",  "down")
                    --self.game_.gravity = 2
                end
            end
 
            self.mx=tx
            self.my=ty
        end

    elseif event.name == 'ended' then
        self.endTime = os.clock()
        if self.isDirectionTouch then
            if self.direction == DIRECTION.down then
               if self.game_.state == 'in_air' and self.game_.action_state == 'normal' then 
                         playSound(GAME_SFXS.drop)
                         self.game_:drop()
                         self.matchManager:sendDropMsg()
                          
                        --self.opponent:drop()
               end
            end
            --self.game_.gravity = 1
            return 
        end
        if self.game_.state == 'in_air' then 
             playSound(GAME_SFXS.transform)
             self.game_:rotate()
             self.matchManager:sendRotateMsg()
        end
        --self.opponent:rotate()
        --self.game_:rotate()
 
    end

end
 
return Robot