WashingStationEvent = {}
local WashingStationEvent_mt = Class(WashingStationEvent, Event)
InitStaticEventClass(WashingStationEvent, "WashingStationEvent")
function WashingStationEvent.emptyNew()
    -- upvalues: (copy) WashingStationEvent_mt
    return Event.new(WashingStationEvent_mt)
end
function WashingStationEvent.new(washingStation)
    local self = WashingStationEvent.emptyNew()
    self.washingStation = washingStation
    return self
end
function WashingStationEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.washingStation = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end
function WashingStationEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.washingStation)
    end
end
function WashingStationEvent:run(connection)
    if not connection:getIsServer() then
        local userId = g_currentMission.userManager:getUserIdByConnection(connection)
        if userId ~= nil then
            local farm = g_farmManager:getFarmByUserId(userId)
            if farm ~= nil then
                self.washingStation:startWashing(farm.farmId)
            end
        end
    end
end