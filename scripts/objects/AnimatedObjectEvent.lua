AnimatedObjectEvent = {}
local AnimatedObjectEvent_mt = Class(AnimatedObjectEvent, Event)
InitStaticEventClass(AnimatedObjectEvent, "AnimatedObjectEvent")
function AnimatedObjectEvent.emptyNew()
    -- upvalues: (copy) AnimatedObjectEvent_mt
    return Event.new(AnimatedObjectEvent_mt)
end
function AnimatedObjectEvent.new(animatedObject, direction)
    local self = AnimatedObjectEvent.emptyNew()
    self.animatedObject = animatedObject
    self.direction = direction
    return self
end
function AnimatedObjectEvent:readStream(streamId, connection)
    assert(g_currentMission:getIsServer())
    local objectId = NetworkUtil.readNodeObjectId(streamId)
    self.animatedObject = NetworkUtil.getObject(objectId)
    if self.animatedObject == nil then
        Logging.warning("AnimatedObjectEvent: AnimatedObject with id \'%s\' does not exist on server!", objectId)
    end
    self.direction = streamReadUIntN(streamId, 2) - 1
    self:run(connection)
end
function AnimatedObjectEvent:writeStream(streamId, connection)
    assert(connection:getIsServer())
    NetworkUtil.writeNodeObject(streamId, self.animatedObject)
    streamWriteUIntN(streamId, self.direction + 1, 2)
end
function AnimatedObjectEvent:run(_)
    if self.animatedObject ~= nil then
        self.animatedObject:setDirection(self.direction)
    end
end