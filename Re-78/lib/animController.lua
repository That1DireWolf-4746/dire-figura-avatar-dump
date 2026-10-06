if animController then return end
animController = {}

animController = {}
local animTargets = {}
local animList = {}
local animDur = {}
local animEndTime = {}
local animInit = {}
local overrides = {}
local playing = {}

function animController.addOverride(anim)
  if anim == nil then 
    missingAnimErrorMsg(anim)
  else
    table.insert(overrides, anim)
  end
end

function animController.init()
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
end

function animController:regAnim(n, d, s, h, b) -- name: string, duration: int, strength: [-1, 1], h: bool, blending [0, 1]
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

function animController.startOfTick()
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
      animController:regAnim(a, 5, 0, true, 1)
    end
    if a == "default" and # playing == 0 then
      animController:regAnim(a, 5, 1, true, 1)
    end
  end
end

function animController.endOfTick()
-- initiate animations
  for a, d in pairs(playing) do
    if d["s"] == world:getTime() then
      dur = d["duration"]
      wei = d["weight"]
      hol = d["hold"]
      initAnim(a, dur, wei, hol)
    end
  end
end

function events.render(delta, context)
  -- check targets for animations
  for a, w in pairs(animTargets) do
    animBlends(a, w, delta)
  end
end

function animBlends(a, w, delta)
  t = 1 - ((animEndTime[a] - world:getTime(delta)) / animDur[a])
  if t < 0 then t = 0 elseif t > 1 then t = 1 end
  if animList[a] == nil then
    missingAnimErrorMsg(a)
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

function initAnim(n, d, s, p)
  if animList[n] == nil then
    localprint("[ERROR] invalid animation!")
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

local function missingAnimErrorMsg(anim)
    localprint("[ERROR] animation " .. anim .. " missing!")
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

function table.removekey(table, key)
    local element = table[key]
    table[key] = nil
    return element
end
