BoatyardStateRelease = {}
local BoatyardStateRelease_mt = Class(BoatyardStateRelease, BoatyardState)
function BoatyardStateRelease.new(boatyard, customMt)
    -- upvalues: (copy) BoatyardStateRelease_mt
    return BoatyardState.new(boatyard, customMt or BoatyardStateRelease_mt)
end
function BoatyardStateRelease:isDone()
    return true
end
function BoatyardStateRelease:activate()
    BoatyardStateRelease:superClass().activate(self)
    self.boatyard:releaseBoat()
    self.boatyard:setSplineTime(0, true)
    BoatyardStateRelease:superClass().activate(self)
end