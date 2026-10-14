MapObjectDestroyedEvent = {}
local MapObjectDestroyedEvent_mt = Class(MapObjectDestroyedEvent, Event)
InitStaticEventClass(MapObjectDestroyedEvent, "MapObjectDestroyedEvent")
function MapObjectDestroyedEvent.emptyNew()
    -- upvalues: (copy) MapObjectDestroyedEvent_mt
    return Event.new(MapObjectDestroyedEvent_mt)
end
function MapObjectDestroyedEvent.new(groupId, childIndex)
    local self = MapObjectDestroyedEvent.emptyNew()
    self.groupId = groupId
    self.childIndex = childIndex
    return self
end
function MapObjectDestroyedEvent:readStream(streamId, connection)
    self.groupId = streamReadUIntN(streamId, DestructibleMapObjectSystem.GROUP_ID_NUM_BITS)
    self.childIndex = streamReadUIntN(streamId, DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS)
    self:run(connection)
end
function MapObjectDestroyedEvent:writeStream(streamId, _)
    streamWriteUIntN(streamId, self.groupId, DestructibleMapObjectSystem.GROUP_ID_NUM_BITS)
    streamWriteUIntN(streamId, self.childIndex, DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS)
end
function MapObjectDestroyedEvent:run(connection)
    if connection:getIsServer() and (self.groupId and self.childIndex) then
        g_currentMission.destructibleMapObjectSystem:setGroupChildIndexDestroyed(self.groupId, self.childIndex, false, true)
    end
end