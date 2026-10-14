RollercoasterStateRideWaiting = {}
local RollercoasterStateRideWaiting_mt = Class(RollercoasterStateRideWaiting, ConstructibleState)
function RollercoasterStateRideWaiting.new(constructible, dirtyFlag, customMt)
    -- upvalues: (copy) RollercoasterStateRideWaiting_mt
    local self = ConstructibleState.new(constructible, dirtyFlag, customMt or RollercoasterStateRideWaiting_mt)
    self.infoBoxRideWaiting = {
        ["title"] = g_i18n:getText("infohud_rideWaiting"),
        ["accentuate"] = true
    }
    self.infoBoxRideStartingIn = {
        ["title"] = ""
    }
    self.textStartingIn = g_i18n:getText("infohud_rideStartingIn")
    self.hudBoxData = {}
    self.hudBox = g_currentMission.hud.infoDisplay:createBox(InfoDisplayKeyValueBox)
    return self
end
function RollercoasterStateRideWaiting:load(xmlFile, key)
    RollercoasterStateRideWaiting:superClass().load(self, xmlFile, key)
    self.waitingDuration = 2500
    if g_currentMission.missionDynamicInfo.isMultiplayer then
        self.waitingDuration = 25000
    end
end
function RollercoasterStateRideWaiting:delete()
    if self.hudBox ~= nil then
        g_currentMission.hud.infoDisplay:destroyBox(self.hudBox)
    end
    RollercoasterStateRideWaiting:superClass().delete(self)
end
function RollercoasterStateRideWaiting:isDone()
    if self.startTime == nil then
        return false
    end
    return g_time > self.startTime and self.constructible:getCanStart()
end
function RollercoasterStateRideWaiting:raiseActive()
    return self.constructible:getCanStart()
end
function RollercoasterStateRideWaiting:activate()
    RollercoasterStateRideWaiting:superClass().activate(self)
    self.constructible:setPlayerTriggerState(true)
    self.constructible:registerRidersChangedListener(self, function(numRiders, change, player)
        -- upvalues: (copy) self
        if self.constructible:getIsSynchronized() and (numRiders == 1 and change == 1) then
            self.startTime = g_time + self.waitingDuration
        end
        if player == g_localPlayer then
            if change == 1 then
                g_currentMission:addDrawable(self)
            else
                g_currentMission:removeDrawable(self)
            end
        end
        if numRiders > 0 then
            self.constructible:raiseActive()
        end
    end)
end
function RollercoasterStateRideWaiting:deactivate()
    RollercoasterStateRideWaiting:superClass().deactivate(self)
    self.constructible:unregisterRidersChangedListener(self)
    self.startTime = nil
    g_currentMission:removeDrawable(self)
    self.constructible:setPlayerTriggerState(false)
end
function RollercoasterStateRideWaiting:onReadStream(streamId, _)
    if streamReadBool(streamId) then
        local timeLeft = streamReadUInt8(streamId)
        self.startTime = g_time + timeLeft * 1000
    end
end
function RollercoasterStateRideWaiting:onWriteStream(streamId, _)
    local timeLeft = streamWriteBool
    if timeLeft(streamId, self.startTime ~= nil) then
        local timeLeft = MathUtil.round((self.startTime - g_time) / 1000)
        streamWriteUInt8(streamId, timeLeft)
    end
end
function RollercoasterStateRideWaiting:draw()
    if self.startTime and not self.constructible.spec_infoTrigger.showInfo then
        local box = self.hudBox
        box:clear()
        box:setTitle(self.constructible:getName())
        self:updateInfo(self.hudBoxData)
        if #self.hudBoxData > 0 then
            local i = 1
            for i = i, #self.hudBoxData do
                local element = self.hudBoxData[i]
                box:addLine(element.title, element.text, element.accentuate)
                self.hudBoxData[i] = nil
            end
            box:showNextFrame()
        end
    end
end
function RollercoasterStateRideWaiting:updateInfo(infoTable)
    table.insert(infoTable, self.infoBoxRideWaiting)
    if self.startTime ~= nil and self.startTime > g_time then
        self.infoBoxRideStartingIn.title = string.format(self.textStartingIn, (self.startTime - g_time) / 1000)
        table.insert(infoTable, self.infoBoxRideStartingIn)
    end
end
function RollercoasterStateRideWaiting:getIsConstructibleState()
    return false
end