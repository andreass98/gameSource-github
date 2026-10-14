RollercoasterStateRiding = {}
local RollercoasterStateRiding_mt = Class(RollercoasterStateRiding, ConstructibleState)
function RollercoasterStateRiding.new(constructible, dirtyFlag, customMt)
    -- upvalues: (copy) RollercoasterStateRiding_mt
    local self = ConstructibleState.new(constructible, dirtyFlag, customMt or RollercoasterStateRiding_mt)
    self.lastSentTime = -1
    self.infoBoxRideUnderway = {
        ["title"] = g_i18n:getText("infohud_rideUnderway"),
        ["accentuate"] = true
    }
    return self
end
function RollercoasterStateRiding:init()
    self.animation = self.constructible:getAnimation()
    self.animationTimeNetworkPrecision = 0.05
    self.animationTimeNetworkPrecisionFactor = 1000 * self.animationTimeNetworkPrecision
    local maxValue = math.ceil(self.animation.clipDuration / self.animationTimeNetworkPrecisionFactor)
    self.animationTimeNetworkNumBits = MathUtil.getNumRequiredBits(maxValue)
    self.animationInterpolator = self.constructible.spec_rollercoaster.animationInterpolator
    self.animationTimeInterpolator = self.constructible.spec_rollercoaster.animationTimeInterpolator
end
function RollercoasterStateRiding:isDone()
    return self.animation.clipCharacterSet ~= nil and getAnimTrackTime(self.animation.clipCharacterSet, self.animation.clipIndex) >= self.animation.clipDuration
end
function RollercoasterStateRiding:raiseActive()
    return true
end
function RollercoasterStateRiding:activate()
    RollercoasterStateRiding:superClass().activate(self)
    if self.constructible.isClient and not self.constructible.isServer then
        g_currentMission:addUpdateable(self)
    end
    self.constructible:startRide()
end
function RollercoasterStateRiding:deactivate()
    RollercoasterStateRiding:superClass().activate(self)
    if self.constructible.isClient and not self.constructible.isServer then
        g_currentMission:removeUpdateable(self)
    end
    self.constructible:endRide()
end
function RollercoasterStateRiding:update(dt)
    if self.constructible.isClient then
        self.constructible:updateFxModifierValues(dt)
    end
    if self.constructible.isServer then
        if self.lastSentTime ~= MathUtil.round(getAnimTrackTime(self.animation.clipCharacterSet, self.animation.clipIndex) / self.animationTimeNetworkPrecisionFactor) then
            self.constructible:raiseDirtyFlags(self.dirtyFlag)
            return
        end
    else
        self.animationTimeInterpolator:update(dt)
        local interpolationAlpha = self.animationTimeInterpolator:getAlpha()
        local animationTime = self.animationInterpolator:getInterpolatedValue(interpolationAlpha)
        self.constructible:setAnimationTime(animationTime)
    end
end
function RollercoasterStateRiding:onReadStream(streamId, _)
    local animationTime = streamReadUInt16(streamId)
    self.animationInterpolator:setValue(animationTime)
    self.animationTimeInterpolator:reset()
end
function RollercoasterStateRiding:onWriteStream(streamId, _)
    streamWriteUInt16(streamId, getAnimTrackTime(self.animation.clipCharacterSet, self.animation.clipIndex))
end
function RollercoasterStateRiding:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        local animationTime = streamReadUIntN(streamId, self.animationTimeNetworkNumBits) * self.animationTimeNetworkPrecisionFactor
        self.animationTimeInterpolator:startNewPhaseNetwork()
        self.animationInterpolator:setTargetValue(animationTime)
    end
end
function RollercoasterStateRiding:onWriteUpdateStream(streamId, connection, _)
    if not connection:getIsServer() then
        local animationTimeCompacted = MathUtil.round(getAnimTrackTime(self.animation.clipCharacterSet, self.animation.clipIndex) / self.animationTimeNetworkPrecisionFactor)
        self.lastSentTime = animationTimeCompacted
        streamWriteUIntN(streamId, animationTimeCompacted, self.animationTimeNetworkNumBits)
    end
end
function RollercoasterStateRiding:updateInfo(infoTable)
    table.insert(infoTable, self.infoBoxRideUnderway)
end
function RollercoasterStateRiding:getIsConstructibleState()
    return false
end