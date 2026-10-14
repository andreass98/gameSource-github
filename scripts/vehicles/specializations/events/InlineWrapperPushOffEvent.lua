InlineWrapperPushOffEvent = {}
local InlineWrapperPushOffEvent_mt = Class(InlineWrapperPushOffEvent, Event)
InitStaticEventClass(InlineWrapperPushOffEvent, "InlineWrapperPushOffEvent")
function InlineWrapperPushOffEvent.emptyNew()
    -- upvalues: (copy) InlineWrapperPushOffEvent_mt
    return Event.new(InlineWrapperPushOffEvent_mt)
end
function InlineWrapperPushOffEvent.new(inlineWrapper)
    local self = InlineWrapperPushOffEvent.emptyNew()
    self.inlineWrapper = inlineWrapper
    return self
end
function InlineWrapperPushOffEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.inlineWrapper = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end
function InlineWrapperPushOffEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.inlineWrapper)
    end
end
function InlineWrapperPushOffEvent:run(connection)
    if not connection:getIsServer() and (self.inlineWrapper ~= nil and self.inlineWrapper:getIsSynchronized()) then
        self.inlineWrapper:pushOffInlineBale()
    end
end