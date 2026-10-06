Type = { -- enum Type and also priority. IDLE lowest, TRACK middle, CURIO highest
  IDLE = -1,
  CURIO = 0,
  SOUND = 1,
  TRACK = 2,
  STARE = 3,
  HURT = 4
}

Goal = {
  gt = Type.IDLE,
  gp = vec(0, 0, 0),
  ent = nil,
  comp = false,
  age = 0
}

function Goal:create (o)
  o = o or Goal   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  return o
end

function Goal.setType(self, gt)
  self.gt = gt
end

function Goal.getType(self)
  return self.gt
end

function Goal.setPos(self, pos)
  self.gp = pos
end

function Goal.getPos(self)
  return self.gp
end

function Goal.setTarget (self, ent)
  self.ent = ent
end

function Goal.getTarget(self)
  return self.ent
end

function Goal.setDone(self, done)
  self.comp = done
end

function Goal.getDone(self)
  return self.comp
end

function Goal.getAge(self)
  return self.age
end

function Goal.setAge(self, age)
  self.age = age
end

function Goal.tick(self)
  Goal.setAge(self, Goal.getAge(self) + 1)
  if Goal.getAge(self) >= 20 + (20 * Goal.getType(self)) then -- failsafe if goal runs too long
    Goal.setDone(self, true)
  end
  if Goal.getPos(self) == nil then
    Goal.setPos(self, Goal:getTarget(self):getPos())
  end
end
