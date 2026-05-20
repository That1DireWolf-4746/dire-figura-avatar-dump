-- Auto generated script file --

--imports
require("direwolf_nametag")

local toolItem = false
local blinkTimer = 180
local stored = {}
local animTargets = {}
local animList = {}
local animDur = {}
local animEndTime = {}
local animInit = {}
local pitch = 0
local roll = 0
local overrides = {}
local playing = {}
local tavern = false
local cFlying, oldcFlying

local flying = false
function pings.EZAnims_cFly(x)
    flying = x
end

--hide vanilla armor model
vanilla_model.ARMOR:setVisible(false)

--hide vanilla player model
vanilla_model.PLAYER:setVisible(false)

--hide vanilla elytra model
vanilla_model.ELYTRA:setVisible(false)

--entity init event, used for when the avatar entity is loaded for the first time
function events.entity_init()
  -- nametag functions
  if client.getServerData()["motd"] == "KoBOBLS???" then tavern = true else tavern = false end
  models.wulong:setVisible(tavern)
  models.scree:setVisible(not tavern)
  if tavern then
    setHoverTag('["",{"text":"Wulong bohaiensis","bold":true,"color":"white"},{"text":"\nDancing dragon from the \nBohai (渤海) strait","color":"white"}]')
    setNameplate("Notos")
  
    -- arms
    models.wulong.ROOT2.firstperson:setParentType("RIGHT_ARM")
    models.wulong.ROOT2.firstperson.rau2:setPos(5, 20, 20):setRot(-50, -80, -50):setScale(5, 5, 5)
    models.wulong.ROOT2.firstperson.rau2.RightItemPivot2:setParentType("NONE")
  
    -- setup overrides
    overrides["bite"] = animations.wulong.bite
    overrides["sleeping"] = animations.wulong.sleeping
  
    -- fix pivot points
    models.wulong.root:setParentType('WORLD'):setPivot(0.5, 0, 0)
    models.wulong.root.hips.torso.larm.lau.LeftItemPivot:setScale(0.5, 0.5, 0.5):setPos(-0.5, -1, 0):setRot(30, 0, 0)
    models.wulong.root.hips.torso.rarm.rau.RightItemPivot:setScale(0.5, 0.5, 0.5):setPos(0.5, -1, 0):setRot(30, 0, 0)
  
    -- setup animations
    for _, a in pairs(animations:getAnimations()) do
      if overrides[a:getName()] ~= nil then
        -- special animation overrides
        overrides[a:getName()]:stop():setBlend(1)
      else
        a:play():pause():setTime(0):setBlend(0)
        animTargets[a:getName()] = 0
        animList[a:getName()] = a
        animDur[a:getName()] = 0
        animEndTime[a:getName()] = 0
        animInit[a:getName()] = 0
      end
    end
  
    -- stored variables
    stored["rot"] = vec(0, 0)
    stored["vel"] = vec(0, 0, 0)
    stored["cro"] = false
    stored["gli"] = false
  end
  if not tavern then
    setHoverTag('["",{"text":"Oriental magpie ("},{"text":"Pica serica","italic":true},{"text":")"}]')
    --,{"text":"\nPing me on "},{"text":"Discord","bold":true,"color":"#7289DA"},{"text":" if the\ninfinite source jar is empty"}
    setNameplate("Scree")
    animations.scree.peck:setLoop("ONCE")
    animations.scree.walk:setSpeed(2)
    animations.scree.run:setSpeed(2)
    animations.scree.fly:setSpeed(1.5)
    vanilla_model.LEFT_ITEM:setVisible(false)
    models.scree.root:setParentType('WORLD')
    models.scree.root.head:setParentType('HEAD')
    models.scree.root.torso.torsoshiny:setPrimaryColor(1, 0.9, 0.5)
    models.scree.root.head.RightItemPivot:setScale(0.5, 0.5, 0.5)
    models.scree.root.torso.lwing.wingshinyl:setSecondaryRenderType('GLINT'):setSecondaryColor(0.3, 0.8, 1)
    models.scree.root.torso.rwing.wingshinyr:setSecondaryRenderType('GLINT'):setSecondaryColor(0.3, 0.8, 1)
    models.scree.root.torso.tail:setSecondaryRenderType('GLINT'):setSecondaryColor(0.3, 0.8, 1)
  end
end

local attackAnimationKey = keybinds:newKeybind("Attack Animation", "key.mouse.left", false)
function pings.attackAnim()
  if tavern then
    animations.wulong.bite:setBlend(1):restart()
  else
    animations.scree.peck:restart()
  end
end
attackAnimationKey.press = pings.attackAnim

local function flycheck()
  if host:isHost() then
    local sitting = vehicle ~= nil or pose == "SITTING"
    cFlying = (host:isFlying() and not sitting) or (has_status_effect("effect.minecraft.slow_falling") and not sitting and table.contains(raycast:block(player:getPos(), player:getPos() - vec(0, 0.5, 0)):getTags(), "minecraft:replaceable"))
    if cFlying ~= oldcFlying then
      pings.EZAnims_cFly(cFlying)
    end
    oldcFlying = cFlying
    blinkTimer = blinkTimer + 1
    if blinkTimer == 180 then
      pings.EZAnims_cFly(cFlying)
      blinkTimer = 0
    end
  end
end

--tick event, called 20 times per second
function events.tick()
  if tavern then
    -- get vars
    rot = player:getRot()
    velocity = player:getVelocity()
    crouch = player:isCrouching()
    gliding = player:isGliding()
  
    -- reset hip height and pitch
    hipHeight = 0
    pitch = 0
    swim = 0
  
    -- clear queue
    for a, d in pairs(playing) do
      if d ~= nil then
        if d["weight"] == animList[a]:getBlend() then
          table.removekey(playing, a)
        end
      end
    end
  
    -- reset all animations
    for a, n in pairs(animList) do
      if n:getBlend() ~= 0 then
        regAnim(a, 5, 0, true, 1)
      end
    end
  
    toolItem = holdingTool()
    blinkTimer = blinkTimer - 1
  
    -- head
    lookDir = dirToAngle(player:getLookDir())
    if lookDir["x"] > 0 then
      regAnim("headMoveBigUp", 2, lookDir["x"] / 90, true, 1)
      regAnim("headMoveBigDown", 2, 0, true, 1)
    else
      regAnim("headMoveBigUp", 2, 0, true, 1)
      regAnim("headMoveBigDown", 2, -lookDir["x"] / 90, true, 1)
    end
    leftright = ((-player:getBodyYaw()) % 360) - lookDir["y"]
    if leftright > 300 and leftright < 350 then leftright = -50 elseif leftright < -300 and leftright > 350 then leftright = 50 elseif leftright > 350 then leftright = 0 end
    regAnim("headMoveBigLR", 2, -leftright / 80, true, 1)
  
    -- tail
    tailAngle = dirToAngle(velocity - stored["vel"]) -- x = pitch, y = yaw
    if tailAngle["x"] > 90 then tailAngle["x"] = 90 elseif tailAngle["x"] < -90 then tailAngle["x"] = -90 end
    if tailAngle["y"] > 90 then tailAngle["y"] = 90 elseif tailAngle["y"] < -90 then tailAngle["y"] = -90 end
    regAnim("taillr", 2, tailAngle["y"] / 180, true, 0.5)
    regAnim("tailud", 2, tailAngle["x"] / 180, true, 0.5)
    if math.abs(tailAngle["y"]) < 30 then 
      regAnim("taillr", 2, 0, true, 0.8)
    end
  
    -- elytra
    if flying or gliding then
      hipHeight = -8
      pitch = - player:getRot()["x"]
      regAnim("lfootopen", 10, 1, true, 1)
      regAnim("rfootoc", 10, 1, true, 1)
      regAnim("larmopen", 10, 0.7, true, 1)
      regAnim("rarmopen", 10, 0.7, true, 1)
      regAnim("ltoesud", 10, -1, true, 1)
      regAnim("rtoesud", 10, -1, true, 1)
      if velocity:length() > 0 and 10 * (velocity["y"] - stored["vel"]["y"]) > 0 then
        flap = 0.5 * math.log(velocity:length() + 0.1) + 0.5
        wave = math.sin(2 * (world:getTime())) * flap
        regAnim("larmopen", 10, wave + 1, true, 1)
        regAnim("rarmopen", 10, wave + 1, true, 1)
        regAnim("lhandup", 10, wave, true, 1)
        regAnim("rhandud", 10, wave, true, 1)
        regAnim("larmroll", 10, -wave, true, 1)
        regAnim("rarmroll", 10, -wave, true, 1)
      elseif velocity["y"] < 0 and math.abs(velocity["y"]) - math.abs(stored["vel"]["y"]) > 0 and pitch < 0 then
        regAnim("rfootback", 5, 1, true, 1)
        regAnim("lfootback", 5, 1, true, 1)
        regAnim("ltoesud", 10, -1, true, 1)
        regAnim("rtoesud", 10, -1, true, 1)
      else 
        regAnim("lhandup", 10, 0, true, 1)
        regAnim("rhandud", 10, 0, true, 1)
      end
    end
  
    -- swimming
    if player:isVisuallySwimming() then
      hipHeight = -8
      pitch = - player:getRot()["x"]
      regAnim("rfootback", 5, 1, true, 1)
      regAnim("lfootback", 5, 1, true, 1)
      regAnim("ltoesud", 10, -1, true, 1)
      regAnim("rtoesud", 10, -1, true, 1)
      flap = 0.5 * math.log(velocity:length() + 0.1) + 0.5
      swim = math.sin(2 * (world:getTime())) * flap
      regAnim("taillr", 2, swim, true, 0.8)
      regAnim("headMoveBigDown", 5, 0.9, true, 0.5) -- streamline the neck a lil
      regAnim("headMoveSmallUD", 5, -0.7, true, 1)
    end
  
    -- sleeping override
  
    -- walking
    if not table.contains(raycast:block(player:getPos(), player:getPos() - vec(0, 0.1, 0), "FALLDAMAGE_RESETTING"):getTags(), "incendium:airs") and not gliding then -- if player grounded then
        regAnim("rfootback", 5, 0, true, 1)
        regAnim("lfootback", 5, 0, true, 1)
        regAnim("ltoesud", 5, 0, true, 1)
        regAnim("rtoesud", 5, 0, true, 1)
      -- IK style target detection
    
      -- Get distance from target to root
    
      -- Set foot length bounded (use inverted footdown for upstroke)
    
      -- Endpoint detection of foot
    
      -- Rotate foot endpoint to target
    elseif not gliding then -- if player jump and not elytra gliding then
      if velocity["y"] >= 0 then
        regAnim("rfootback", 5, 0.5, true, 1)
        regAnim("lfootback", 5, 0.5, true, 1)
        regAnim("ltoesud", 10, -1, true, 1)
        regAnim("rtoesud", 10, -1, true, 1)
      else
        regAnim("rfootback", 5, -1, true, 1)
        regAnim("lfootback", 5, -1, true, 1)
        regAnim("ltoesud", 5, 1, true, 1)
        regAnim("rtoesud", 5, 1, true, 1)
      end
    end
  
    -- ladder climbing (use partial footup)
    if player:isClimbing() then
      hipHeight = -12
    end
  
    if player:isCrouching() then
      if velocity:length() > 0 then
        -- sneaking
      else
        -- sitting
      end
    end
  
    -- hip height fix
    models.wulong.root.hips:setPos(0, hipHeight, 0):setRot(0, swim, 0)
  
    -- initiate animations
    for a, d in pairs(playing) do
      if d["s"] == world:getTime() then
        dur = d["duration"]
        wei = d["weight"]
        hol = d["hold"]
        initAnim(a, dur, wei, hol)
      end
    end
  
    -- store variables
    stored["rot"] = rot
    stored["vel"] = velocity
    stored["cro"] = crouch
    stored["gli"] = gliding
    flycheck()
  else
    if flying or player:isGliding() then
      animations.scree.walk:setPlaying(false)
      animations.scree.run:setPlaying(false)
      animations.scree.fall:setPlaying(false)
      animations.scree.fly:setPlaying(true)
      animations.scree.sneaking:setPlaying(false)
      if player:isGliding() then
        pitch = - player:getRot()["x"]
      else
        pitchbase = player:getVelocity():length()
        if pitchbase < 0.1 then pitchbase = 0.1 end
        pitch = 45 * (player:getVelocity()["y"] / pitchbase)
      end
    else
      animations.scree.fly:setPlaying(false)
      pitch = 0
      if player:isCrouching() then
        animations.scree.sneaking:play():setBlend(1)
      else
        animations.scree.sneaking:stop():setBlend(0)
      end
      if player:isMoving(true) and not player:isSprinting() and not player:isVisuallySwimming() then
        animations.scree.walk:setPlaying(true)
        animations.scree.run:setPlaying(false)
      elseif player:isMoving(true) and player:isSprinting() and not player:isVisuallySwimming() then
        animations.scree.walk:setPlaying(false)
        animations.scree.run:setPlaying(true)
        block = raycast:block(player:getPos(), player:getPos() - vec(0, 0.1, 0)):getTags() 
        if table.contains(block, "minecraft:replaceable") then
          animations.scree.run:pause()
        else
          animations.scree.run:play()
        end
      else
        animations.scree.walk:setPlaying(false)
        animations.scree.run:setPlaying(false)
      end
      if player:getVelocity()["y"] < -0.5 then
        animations.scree.fall:setPlaying(true)
      else
        animations.scree.fall:setPlaying(false)
      end
      if player:getPose() == "SLEEPING" then
        animations.scree.sleeping:setPlaying(true)
      else
        animations.scree.sleeping:setPlaying(false)
      end
      if player:isVisuallySwimming() then
        animations.scree.swim:setPlaying(true)
        pitch = - player:getRot()["x"]
      else
        animations.scree.swim:setPlaying(false)
      end
    end
    flycheck()
  end
end
--render event, called every time your avatar is rendered
--it have two arguments, "delta" and "context"
--"delta" is the percentage between the last and the next tick (as a decimal value, 0.0 to 1.0)
--"context" is a string that tells from where this render event was called (the paperdoll, gui, player render, first person)
function events.render(delta, context)
  if tavern then
    if context == 'FIRST_PERSON' then
      models.wulong.root:setVisible(false)
      models.wulong.ROOT2:setVisible(true)
    else
      models.wulong.root:setVisible(true)
      models.wulong.ROOT2:setVisible(false)
    end
    models.wulong.root:setPos(player:getPos(delta) * 16):setRot(math.lerp(models.wulong.root:getRot()["x"], pitch, delta), (180 - player:getBodyYaw(delta)) % 360, math.lerp(models.wulong.root:getRot()["z"], roll, delta))
  
    -- climbing rotation fix
    if player:isClimbing() then
      models.wulong.root:setRot(90, (180 - player:getBodyYaw(delta)) % 360, 0)
    end
  
    -- bow rotation
  
    -- sleep and blink
    if player:getPose() == "SLEEPING" then
      animations.wulong.eyesclosed:setBlend(1)
      vanilla_model.PLAYER:setVisible(false)
    else
      if animList["eyesclosed"]:getBlend() == 1 then initAnim("eyesclosed", 5, 0, 0) end
      if blinkTimer == 0 then
        blinkTimer = math.random(80, 120)
        initAnim("eyesclosed", 5, 1, 0)
      end
    end
  
  -- check targets for animations
    for a, w in pairs(animTargets) do
      animBlends(a, w, delta)
    end
  else
    if context == 'FIRST_PERSON' then
      models.scree.root:setVisible(false)
      vanilla_model.RIGHT_ARM:setVisible(true)
    else
      models.scree.root:setVisible(true)
      vanilla_model.RIGHT_ARM:setVisible(false)
    end
    models.scree.root:setPos(player:getPos(delta) * 16 + vec(0, 0.02, 0)):setRot(math.lerp(models.scree.root:getRot()["x"], pitch, delta), (180 - player:getBodyYaw(delta)) % 360, math.lerp(models.scree.root:getRot()["z"], roll, delta))
  
    -- climbing rotation fix
    if player:isClimbing() then
      models.scree.root:setRot(90, (180 - player:getBodyYaw(delta)) % 360, 0)
    end
    models.scree.root.torso.lwing.wingshinyl:setSecondaryColor((world.getLightLevel(player:getPos()) / 15) * 0.3, (world.getLightLevel(player:getPos()) / 15) * 0.8, (world.getLightLevel(player:getPos()) / 15) * 1)
    models.scree.root.torso.rwing.wingshinyr:setSecondaryColor((world.getLightLevel(player:getPos()) / 15) * 0.3, (world.getLightLevel(player:getPos()) / 15) * 0.8, (world.getLightLevel(player:getPos()) / 15) * 1)
    models.scree.root.torso.tail:setSecondaryColor((world.getLightLevel(player:getPos()) / 15) * 0.3, (world.getLightLevel(player:getPos()) / 15) * 0.8, (world.getLightLevel(player:getPos()) / 15) * 1)
    models.scree.root.torso.lwing.wingshinyl:setPrimaryColor((world.getLightLevel(player:getPos()) / 15), (world.getLightLevel(player:getPos()) / 15), (world.getLightLevel(player:getPos()) / 15))
    models.scree.root.torso.rwing.wingshinyr:setPrimaryColor((world.getLightLevel(player:getPos()) / 15), (world.getLightLevel(player:getPos()) / 15), (world.getLightLevel(player:getPos()) / 15))
    models.scree.root.torso.tail:setPrimaryColor((world.getLightLevel(player:getPos()) / 15), (world.getLightLevel(player:getPos()) / 15), (world.getLightLevel(player:getPos()) / 15))
    
    -- head fix
    if player:isCrouching() then
      models.scree.root.head:setPos(0, 4, 0)
    else
      models.scree.root.head:setPos(0, 0, 0)
    end
    
    -- hide enchanter's mirror
    if player:getHeldItem():getID() == "ars_nouveau:enchanters_mirror" then
      vanilla_model.RIGHT_ITEM:setVisible(false)
    end
  end
end

function animBlends(a, w, delta)
  t = 1 - ((animEndTime[a] - world:getTime(delta)) / animDur[a])
  if t < 0 then t = 0 elseif t > 1 then t = 1 end
  if animList[a] == nil then
    localprint("animation " .. a .. " missing!")
    return nil
  end
  if math.abs(w - animList[a]:getBlend()) > 0.01 and t <= 1 then
    if t < 0.5 then
      interp = (-2 * (animInit[a] - w)* t^2 ) + animInit[a]
    else
      interp = (2 * (animInit[a] - w) * (t - 1)^2) + w
    end
    if math.abs(w - interp) < 0.01 then interp = w end
    if interp < -1 then interp = -1 end
    if interp > 1 then interp = 1 end
    animList[a]:setBlend(interp)
  end
end

function regAnim(n, d, s, h, b) -- name: string, duration: int, strength: [-1, 1], h: bool, blending [0, 1]
  if playing[n] ~= nil then
    -- modify existing animation with new parameters
    if playing[n]["s"] == world:getTime() then
      -- case 1: additive (same tick)
      newWeight = ((1 - b) * playing[n]["weight"]) + (b * s)
      if newWeight > 1 then newWeight = 1 elseif newWeight < -1 then newWeight = -1 end
      playing[n]["weight"] = newWeight
    else
      -- case 2: modifying (new parameters)
      playing[n]["weight"] = ((1 - b) * playing[n]["weight"]) + (b * s)
      playing[n]["s"] = world:getTime()
      playing[n]["e"] = world:getTime() + d
      playing[n]["duration"] = d
      playing[n]["hold"] = h
    end
  else
    -- add a new animation to the queue
    newAnim = {}
    
    -- format newAnim table
    newAnim["s"] = world:getTime()
    newAnim["e"] = world:getTime() + d
    newAnim["weight"] = s
    newAnim["duration"] = d
    newAnim["hold"] = h
    
    -- add the new animation to playing
    playing[n] = newAnim
  end
end

function initAnim(n, d, s, p)
  if animList[n] == nil then
    localprint("animation " .. n .. " missing!")
    return nil
  end
  if animEndTime[n] > world:getTime(delta) then return animList[n] end
  animDur[n] = d
  animEndTime[n] = world:getTime() + d
  animTargets[n] = s
  animInit[n] = animList[n]:getBlend()
  if p then animList[n]:pause() else animList[n]:restart() end
  return animList[n]
end

function holdingTool()
  return table.contains(player:getHeldItem(false):getTags(), "minecraft:tools")
end

function has_status_effect(n)
  for _, effect in pairs(host:getStatusEffects()) do
    if effect["name"] == n then
      return true
    end
  end
  return false
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function localprint(s)
  if host:isHost() then
    print(s)
  end
end

function dirToAngle(dir)
    return vec(math.deg(math.atan2(dir.y, math.sqrt(dir.x * dir.x + dir.z * dir.z))),
        math.deg(math.atan2(dir.x, dir.z)), 0)
end

function table.removekey(table, key)
    local element = table[key]
    table[key] = nil
    return element
end

