AnimalClusterUpdateEvent = {}
local AnimalClusterUpdateEvent_mt = Class(AnimalClusterUpdateEvent, Event)
InitStaticEventClass(AnimalClusterUpdateEvent, "AnimalClusterUpdateEvent")
function AnimalClusterUpdateEvent.emptyNew()
    -- upvalues: (copy) AnimalClusterUpdateEvent_mt
    return Event.new(AnimalClusterUpdateEvent_mt)
end
function AnimalClusterUpdateEvent.new(owner, clusters)
    local self = AnimalClusterUpdateEvent.emptyNew()
    assert(#clusters < 65535, "Number of clusters is too big")
    self.owner = owner
    self.clusters = clusters
    return self
end
function AnimalClusterUpdateEvent:readStream(streamId, connection)
    self.owner = NetworkUtil.readNodeObject(streamId)
    self.owner:getClusterSystem():readStream(streamId, connection)
end
function AnimalClusterUpdateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.owner)
    self.owner:getClusterSystem():writeStream(streamId, connection)
end
function AnimalClusterUpdateEvent:run(connection) end