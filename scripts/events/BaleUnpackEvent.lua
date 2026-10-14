BaleUnpackEvent = {}
local BaleUnpackEvent_mt = Class(BaleUnpackEvent, Event)
InitStaticEventClass(BaleUnpackEvent, "BaleUnpackEvent")
function BaleUnpackEvent.emptyNew()
    -- upvalues: (copy) BaleUnpackEvent_mt
    return Event.new(BaleUnpackEvent_mt)
end
function BaleUnpackEvent.new(bale)
    local self = BaleUnpackEvent.emptyNew()
    self.bale = bale
    return self
end
function BaleUnpackEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.bale = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end
function BaleUnpackEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.bale)
    end
end
function BaleUnpackEvent:run(_)
    self.bale:unpack()
end