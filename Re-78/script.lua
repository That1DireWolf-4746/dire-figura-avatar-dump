-- Auto generated script file --
-- imports
require("lib/animController")
require("lib/entitygoal")

model = models.model.root
tailhead = model.Body.tail1.tail2.tail3.tail4.tailhead
currentGoals = {} -- list{Goals ...}
hpg = 0
goalLocDiff = 20
tol = vec(0.5, 0.5, 0.5) -- tolerance for STARE goal detection
entities = nil
players = {}
headPos = vec(0, 0, 0)
selfStareTimer = 0
stareEnt = nil

--hide vanilla model
vanilla_model.PLAYER:setVisible(false)

--hide vanilla armor model
vanilla_model.ARMOR:setVisible(false)
--re-enable the helmet and head item
vanilla_model.HELMET_ITEM:setVisible(true)
vanilla_model.HELMET:setVisible(true)
--re-enable shoes
vanilla_model.BOOTS:setVisible(true)

--hide vanilla cape model
vanilla_model.CAPE:setVisible(false)

--hide vanilla elytra model
vanilla_model.ELYTRA:setVisible(false)

--entity init event, used for when the avatar entity is loaded for the first time
function events.entity_init()
  --player functions goes here
  model.Head.HelmetPivot:setPos(0, -1, 0)
  model.Head.HelmetItemPivot:setPos(0, -1, 0)
  model.LeftLeg.LeftBootPivot:setScale(0.9)
  model.RightLeg.RightBootPivot:setScale(0.9)
  model.Elytra:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")
  model:setSecondaryRenderType("EYES")
  models.model.Portrait:setSecondaryRenderType("NONE")
  
  animController.addOverride("idleanim")
  animController.addOverride("yawn")
  animController.addOverride("bite")
  animController.init()
  
  currentGoals[1] = Goal:create{gt = Type.IDLE} -- initial idle goal
end

--tick event, called 20 times per second
function events.tick()
  animController.startOfTick()
  if player:isLoaded() then
  
  if player:getItem(6).id ~= "minecraft:air" then
    model.Head.helmet:setVisible(true)
    model.Head.nohelmet:setVisible(false)
  else
    model.Head.helmet:setVisible(false)
    model.Head.nohelmet:setVisible(true)
  end
  
  if animations.model.idleanim:isPlaying() == false and animations.model.yawn:isPlaying() == false then
    rand = math.random(3)
    if rand == 1 then
      animations.model.yawn:play()
    end
  end
  
  headPos = tailhead:partToWorldMatrix():apply()
  snootPos = tailhead.snootTipCheck:partToWorldMatrix():apply()
  tailcheck = model.Body.tailcheck:partToWorldMatrix():apply()
  -- if being stared at, stare back (Type.STARE)
  -- can only have one stare goal at a time, check every 2 ticks
  if hasGoalOfType(Type.STARE) == false and world.getTime() % 2 == 0 then
    local pos = player:getPos()
    local min = pos - vec(16, 4, 16)
    local max = pos + vec(16, 4, 16)
    -- update list
    entities = world.getEntities(min, max)
    -- check is player
    for n, p in pairs(entities) do
        if players[n] == nil and p:isPlayer() then
          players[n] = p
        end
      end
    end
    -- for each player, check if being stared at
    if # players > 0 then
      for _, p in pairs(players) do
        if (p:getLookDir() - (p:getPos() - headPos):normalized() < tol) and p ~= player then
          currentGoals[# currentGoals + 1] = Goal:create{gt = Type.STARE, ent = p}
        end
      end
    end
  end
  
  -- track random entity in range (Type.TRACK)
  if world.getTime() % 20 == 0 then
    -- low chance to track entity
    local pos = player:getPos()
    local min = pos - vec(16, 4, 16)
    local max = pos + vec(16, 4, 16)
    if entities then
      if math.random(10) <= 1 and # entities > 1 then
        -- only get list if list does not already exist
        entities = entities or world.getEntities(min, max)
        try = entities[math.random(1, # entities)]
        if try ~= player then -- ignore if entity is self
          currentGoals[# currentGoals + 1] = Goal:create{gt = Type.TRACK, ent = try}
        end
      end
    end
  end
  
  -- curio random location (Type.CURIO)
  -- low chance to curio random location
  if math.random(20) == 1 and world.getTime() % 10 == 1 then
    loc = player:getPos() + vec(math.random(-4, 4), math.random(-4, 4), math.random(-4, 4))
    currentGoals[# currentGoals + 1] = Goal:create{gt = Type.CURIO, gp = loc}
  end
  
  -- update goals
  for i, g in ipairs(currentGoals) do 
    g:tick()
    -- check sustained goal, end on 10% chance if older than 5 seconds
    if g:getType() > 1 and g:getAge() > 100 then
      if math.random(10) == 1 then g:setDone(true) end
    end
    -- check curio goal
    if g:getType() == Type.CURIO or g:getType() == Type.SOUND then
      if math.abs((dirToAngle(g:getPos() - headPos) - dirToAngle(headPos - snootPos)):length()) < goalLocDiff then
        g:setDone(true)
      end
    end
    if g:getDone() == true then -- remove completed goals
      currentGoals[i] = nil
    end
  end
  
  -- call animations for highest priority goal
  hpg = highestPriorityIndex()
  if player:getVelocity():lengthSquared() > 0 then
      mod = math.abs(player:getVelocity():length())
      animController:regAnim("default", 5, 0, true, 1)
      animController:regAnim("headlookdown", 5, 0, true, 1)
      if mod > 0.5 then mod = 0.5 end
        animController:regAnim("headlookdown", 5, 0, true, 0.5)
        if player:getPose() ~= "FALL_FLYING" and player:getPose() ~= "SWIMMING" and player:getPose() ~= "SPIN_ATTACK" then -- inverse of or is and not
          animController:regAnim("walk", 3, 0.5 + (mod * math.sin((world.getTime() % 10))), true, 0.5)
        else
          animController:regAnim("fly", 3, 1, true, 0.5)
        end
    end
  if currentGoals[hpg]:getType() == Type.IDLE then
    animController:regAnim("default", 5, 0, true, 1)
    block = raycast:block(headPos, headPos - vec(0, 2, 0))
    if block:hasCollision() or string.find(block.id, "stair", 1, true) and (string.find(block.id, "water", 1, true) == false) then
      if player:getVelocity():lengthSquared() == 0 then
        animController:regAnim("idle", 10, 1, true, 1)
      end
    else
      animController:regAnim("fly", 10, 1, true, 0.8)
      if player:getPose() ~= "FALL_FLYING" and player:getPose() ~= "SWIMMING" and player:getPose() ~= "SPIN_ATTACK" then
        animController:regAnim("headlookdown", 10, -1, true, 0.8)
      end
    end
    animController:regAnim("default", 10, 0, true, 1)
    if animations.model.idle:getBlend() == 1 then
      if animations.model.idleanim:isPlaying() == false then
        rand = math.random(2)
        if rand == 1 then
          animations.model.idleanim:play()
        end
      end
    end
  else
    animations.model.idleanim:stop()
    -- get direction to goal
    goalDif = currentGoals[hpg]:getPos() - player:getPos()
    goalDir = (dirToAngle(goalDif) - dirToAngle(player:getPos() - tailcheck)) % 360
    -- get required rotations to goal
    if goalDif.y < 0 then vert = -1 else vert = 1 end
    if goalDif.x < 0 then horz = -1 else horz = 1 end
    rotx = horz * (goalDir.x - 180)/360
    roty = vert * (goalDir.y/360)
    
    -- apply transforms
    animController:regAnim("side", 30 * math.sqrt(goalDif:lengthSquared()), rotx, true, 1)
    animController:regAnim("vert", 30 * math.sqrt(goalDif:lengthSquared()), roty, true, 1)
    animController:regAnim("headlookdown", 5, 0, true, 0.7)
    
    -- headtilt at stare or track goal
    if currentGoals[hpg]:getType() > 1 then -- if not stare or track then skip next conditional
      if currentGoals[hpg]:getAge() > 120 then -- minimum time needed
        rand = math.random(2)
        if (rand == 1 or animations.model.headtilt:isPlaying() == true) then -- 50% chance
          animController:regAnim("headtilt", 5, 1, true, 1)
        end
      end
    end
      
    -- if hurt goal chance to bite
    if currentGoals[hpg]:getType() == Type.HURT then
      if animations.model.bite:isPlaying() == false then
        animations.model.bite:play()
      end
    end
  end

  -- collision checking
  if (raycast:block(player:getPos() + vec(0, player:getEyeHeight() / 1.5, 0), tailcheck + vec(0, player:getEyeHeight() / 8, 0), "VISUAL"):isTranslucent() == false) and (string.find(block.id, "water", 1, true) == false) then
    -- if wall, coil
    animController:regAnim("idle", 5, 0, true, 1)
    animController:regAnim("walk", 5, 0, true, 0.5)
    animController:regAnim("side", 5, 1, true, 1)
    animController:regAnim("vert", 5, 0.3, true, 1)
    animController:regAnim("headlookdown", 5, 0, true, 1)
    else
  -- if head in ground, scrunch
    if ((raycast:block(headPos - vec(0.2, 0, 0.2), headPos + vec(0.2, 0.2, 0.2), "OUTLINE"):isTranslucent() == false) or (raycast:block(headPos - vec(-0.2, 0, -0.2), headPos + vec(-0.2, 0.2, -0.2), "OUTLINE"):isTranslucent() == false)) and (string.find(block.id, "water", 1, true) == false) then
      _, loc, _ = raycast:block(headPos + vec(0, 2, 0), headPos, "OUTLINE")
      diff = (model.Body.tail1.tail2.tail3:partToWorldMatrix():apply().y - loc.y) / 2
      if diff > 1 then diff = 1 end
      animController:regAnim("idle", 5, 0, true, 1 - diff)
      animController:regAnim("walk", 5, 0, true, 1 - diff)
      animController:regAnim("vert", 5, 1, true, diff + 0.2)
      animController:regAnim("headlookdown", 5, 1, true, diff + 0.2)
    end
  end
  
  -- self stare
  if player:getTargetedEntity(16) ~= nil then
    selfStareTimer = selfStareTimer + 1
    stareEnt = player:getTargetedEntity(16)
  else 
    selfStareTimer = 0
    stareEnt = nil
  end
  
  if selfStareTimer > 10 then
    currentGoals[# currentGoals + 1] = Goal:create{gt = Type.STARE, ent = stareEnt}
  end
  
  entities = nil -- clear entities list for this tick
  animController.endOfTick()
end

function events.on_play_sound(id, pos, vol, pitch, loop, category)
    -- make sure the player is loaded
    if not player:isLoaded() then return end
    -- make sure sound not from us
    if category == "PLAYERS" and (pos - player:getPos()):lengthSquared() < 0.5 then return end
    -- block ambient sounds
    if category == "AMBIENT" then return end 
    -- get distance to sound
    dist = math.sqrt((pos - player:getPos()):lengthSquared())
    -- has a chance to add sound as Goal
    if math.random(16) < math.abs(16 - dist + vol) then
      currentGoals[# currentGoals + 1] = Goal:create{gt = Type.SOUND, gp = pos}
    end
end

function events.render(context)
  if (context == "FIRST_PERSON") then
    model.Body.tail1.tail2:setOpacity(0.25):setVisible(true)
    model.Body.tail1.tail2.tail3:setOpacity(0.5):setVisible(true)
    model.Body.tail1.tail2.tail3.tail4:setOpacity(0.75):setVisible(true)
    model.Body.tail1.tail2.tail3.tail4.tailhead:setOpacity(1):setVisible(true)
  end
end

function events.damage(type, source, attacker, pos)
    if attacker then
      currentGoals[# currentGoals + 1] = Goal:create{gt = Type.HURT, ent = attacker}
    end
end

function hasGoalOfType(goaltype)
  if # currentGoals == 0 then return false end
  for _, goal in ipairs(currentGoals) do
    if goal:getType() == goaltype then
      return true
    end
  end
  return false
end

function highestPriorityIndex()
  prio = nil
  track = nil
  idle = 1
  for i, goal in pairs(currentGoals) do
    if goal:getType() == Type.HURT then
      return i
    end
    if goal:getType() == Type.STARE then
      return i
    end
    if goal:getType() == Type.SOUND then
      return i
    end
    if goal:getType() == Type.CURIO then
      if (prio == nil) then
        prio = i
      else
        if goal:getAge() < currentGoals[prio]:getAge() then -- newest curio goal takes precedent over older curio goals
          prio = i
        end
      end
    end
    if goal:getType() == Type.TRACK then
      track = i
    end
  end
  if prio ~= nil then return prio
  elseif track ~= nil then return track 
  else
    currentGoals[1] = Goal:create{gt = Type.IDLE}
    return idle
  end
end

function dirToAngle(dir)
    return vec(math.deg(math.atan2(dir.y, math.sqrt(dir.x * dir.x + dir.z * dir.z))),
        math.deg(math.atan2(dir.x, dir.z)))
end
