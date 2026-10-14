ConstructibleStateEvent = {}
local ConstructibleStateEvent_mt = Class(ConstructibleStateEvent, Event)
InitStaticEventClass(ConstructibleStateEvent, "ConstructibleStateEvent")
function ConstructibleStateEvent.emptyNew()
    -- upvalues: (copy) ConstructibleStateEvent_mt
    return Event.new(ConstructibleStateEvent_mt)
end
function ConstructibleStateEvent.new(constructible, stateIndex)
    local self = ConstructibleStateEvent.emptyNew()
    self.constructible = constructible
    self.stateIndex = stateIndex
    return self
end
function ConstructibleStateEvent:readStream(streamId, connection)
    self.constructible = NetworkUtil.readNodeObject(streamId)
    self.stateIndex = streamReadUInt8(streamId)
    self:run(connection)
end
function ConstructibleStateEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.constructible)
    streamWriteUInt8(streamId, self.stateIndex)
end
function ConstructibleStateEvent:run(_)
    if self.constructible ~= nil and self.constructible:getIsSynchronized() then
        self.constructible:setConstructibleState(self.stateIndex)
    end
end