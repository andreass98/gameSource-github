BoatyardStateSetup = {}
local BoatyardStateSetup_mt = Class(BoatyardStateSetup, BoatyardState)
function BoatyardStateSetup.new(boatyard, customMt)
    -- upvalues: (copy) BoatyardStateSetup_mt
    return BoatyardState.new(boatyard, customMt or BoatyardStateSetup_mt)
end
function BoatyardStateSetup:activate()
    self.boatyard:setSplineTime(0, true)
    self.boatyard:createBoat()
    BoatyardStateSetup:superClass().activate(self)
end