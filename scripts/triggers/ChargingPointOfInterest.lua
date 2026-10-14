ChargingPointOfInterest = {}
local ChargingPointOfInterest_mt = Class(ChargingPointOfInterest, PointOfInterest)
function ChargingPointOfInterest.new(placeable, customEnv, customMt)
    -- upvalues: (copy) ChargingPointOfInterest_mt
    return PointOfInterest.new(placeable, customEnv, customMt or ChargingPointOfInterest_mt)
end
function ChargingPointOfInterest:finalize()
    ChargingPointOfInterest:superClass().finalize(self)
    self.defaultInfoText = self.infoText
end
function ChargingPointOfInterest:draw()
    self.infoText = self.defaultInfoText
    if self.placeable ~= nil and (self.placeable.getIsCharging ~= nil and self.placeable:getIsCharging()) then
        self.infoText = self.placeable.spec_chargingStation.chargingInfoText
    end
    ChargingPointOfInterest:superClass().draw(self)
end