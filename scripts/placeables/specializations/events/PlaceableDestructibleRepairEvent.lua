PlaceableDestructibleRepairEvent = {}
local PlaceableDestructibleRepairEvent_mt = Class(PlaceableDestructibleRepairEvent, Event)
InitStaticEventClass(PlaceableDestructibleRepairEvent, "PlaceableDestructibleRepairEvent")
function PlaceableDestructibleRepairEvent.emptyNew()
    -- upvalues: (copy) PlaceableDestructibleRepairEvent_mt
    return Event.new(PlaceableDestructibleRepairEvent_mt)
end
function PlaceableDestructibleRepairEvent.new(placeable)
    local self = PlaceableDestructibleRepairEvent.emptyNew()
    self.placeable = placeable
    return self
end
function PlaceableDestructibleRepairEvent.newServerToClient(placeable, wasSuccessful)
    local self = PlaceableDestructibleRepairEvent.emptyNew()
    self.placeable = placeable
    self.wasSuccessful = wasSuccessful
    return self
end
function PlaceableDestructibleRepairEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    if connection:getIsServer() then
        self.wasSuccessful = streamReadBool(streamId)
    end
    self:run(connection)
end
function PlaceableDestructibleRepairEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    if not connection:getIsServer() then
        streamWriteBool(streamId, self.wasSuccessful)
    end
end
function PlaceableDestructibleRepairEvent:run(connection)
    local placeable = self.placeable
    if placeable ~= nil and placeable:getIsSynchronized() then
        if not connection:getIsServer() then
            local user = g_currentMission.userManager:getUserByConnection(connection)
            if user == nil then
                connection:sendEvent(PlaceableDestructibleRepairEvent.newServerToClient(placeable, false))
                return
            else
                local farm = g_farmManager:getFarmByUserId(user:getId())
                if farm == nil then
                    connection:sendEvent(PlaceableDestructibleRepairEvent.newServerToClient(placeable, false))
                else
                    local wasSuccessful = placeable:startRepairDestructible(farm:getId())
                    connection:sendEvent(PlaceableDestructibleRepairEvent.newServerToClient(placeable, wasSuccessful))
                end
            end
        end
        placeable:startedRepairDestructible(self.wasSuccessful)
    end
end