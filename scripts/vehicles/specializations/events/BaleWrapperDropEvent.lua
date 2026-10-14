BaleWrapperDropEvent = {}
local BaleWrapperDropEvent_mt = Class(BaleWrapperDropEvent, Event)
InitStaticEventClass(BaleWrapperDropEvent, "BaleWrapperDropEvent")
function BaleWrapperDropEvent.emptyNew()
    -- upvalues: (copy) BaleWrapperDropEvent_mt
    return Event.new(BaleWrapperDropEvent_mt)
end
function BaleWrapperDropEvent.new(object, dropAnimationIndex)
    local self = BaleWrapperDropEvent.emptyNew()
    self.object = object
    self.dropAnimationIndex = dropAnimationIndex
    return self
end
function BaleWrapperDropEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.dropAnimationIndex = streamReadUIntN(streamId, 4)
    self:run(connection)
end
function BaleWrapperDropEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.dropAnimationIndex, 4)
end
function BaleWrapperDropEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, nil, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setBaleWrapperDropAnimation(self.dropAnimationIndex)
        self.object:doStateChange(BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE, nil)
    end
end