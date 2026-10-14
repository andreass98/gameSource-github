CollectibleStateEvent = {}
local CollectibleStateEvent_mt = Class(CollectibleStateEvent, Event)
InitStaticEventClass(CollectibleStateEvent, "CollectibleStateEvent")
function CollectibleStateEvent.emptyNew()
    -- upvalues: (copy) CollectibleStateEvent_mt
    return Event.new(CollectibleStateEvent_mt)
end
function CollectibleStateEvent.new(state)
    local self = CollectibleStateEvent.emptyNew()
    self.state = state
    return self
end
function CollectibleStateEvent:writeStream(streamId, _)
    streamWriteUInt8(streamId, #self.state)
    local i = 1
    for i = i, #self.state do
        streamWriteBool(streamId, self.state[i])
    end
end
function CollectibleStateEvent:readStream(streamId, connection)
    self.state = {}
    local num = streamReadUInt8(streamId)
    local i = 1
    for i = i, num do
        self.state[i] = streamReadBool(streamId)
    end
    self:run(connection)
end
function CollectibleStateEvent:run(connection)
    if connection:getIsServer() then
        g_currentMission.collectiblesSystem:onStateEvent(self.state)
    end
end