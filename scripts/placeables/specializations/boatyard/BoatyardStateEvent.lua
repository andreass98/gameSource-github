BoatyardStateEvent = {}
local BoatyardStateEvent_mt = Class(BoatyardStateEvent, Event)
InitStaticEventClass(BoatyardStateEvent, "BoatyardStateEvent")
function BoatyardStateEvent.emptyNew()
    -- upvalues: (copy) BoatyardStateEvent_mt
    return Event.new(BoatyardStateEvent_mt)
end
function BoatyardStateEvent.new(boatyard, stateIndex)
    local self = BoatyardStateEvent.emptyNew()
    self.boatyard = boatyard
    self.stateIndex = stateIndex
    return self
end
function BoatyardStateEvent:readStream(streamId, connection)
    self.boatyard = NetworkUtil.readNodeObject(streamId)
    self.stateIndex = streamReadUInt8(streamId)
    self:run(connection)
end
function BoatyardStateEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.boatyard)
    streamWriteUInt8(streamId, self.stateIndex)
end
function BoatyardStateEvent:run(_)
    if self.boatyard ~= nil and self.boatyard:getIsSynchronized() then
        self.boatyard:setState(self.stateIndex)
    end
end