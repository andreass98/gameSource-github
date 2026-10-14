AnimalRidingEvent = {}
local AnimalRidingEvent_mt = Class(AnimalRidingEvent, Event)
InitStaticEventClass(AnimalRidingEvent, "AnimalRidingEvent")
function AnimalRidingEvent.emptyNew()
    -- upvalues: (copy) AnimalRidingEvent_mt
    return Event.new(AnimalRidingEvent_mt)
end
function AnimalRidingEvent.new(husbandry, clusterId, player)
    local self = AnimalRidingEvent.emptyNew()
    self.husbandry = husbandry
    self.clusterId = clusterId
    self.player = player
    return self
end
function AnimalRidingEvent:readStream(streamId, connection)
    self.husbandry = NetworkUtil.readNodeObject(streamId)
    self.clusterId = streamReadInt32(streamId)
    self.player = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function AnimalRidingEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.husbandry)
    streamWriteInt32(streamId, self.clusterId)
    NetworkUtil.writeNodeObject(streamId, self.player)
end
function AnimalRidingEvent:run(_)
    self.husbandry:startRiding(self.clusterId, self.player)
end