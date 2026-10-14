FenceRequestDeleteSegmentEvent = {}
local FenceRequestDeleteSegmentEvent_mt = Class(FenceRequestDeleteSegmentEvent, Event)
InitStaticEventClass(FenceRequestDeleteSegmentEvent, "FenceRequestDeleteSegmentEvent")
function FenceRequestDeleteSegmentEvent.emptyNew()
    -- upvalues: (copy) FenceRequestDeleteSegmentEvent_mt
    return Event.new(FenceRequestDeleteSegmentEvent_mt, NetworkNode.CHANNEL_MAIN)
end
function FenceRequestDeleteSegmentEvent.new(fencePlaceable, segmentId)
    local self = FenceRequestDeleteSegmentEvent.emptyNew()
    self.fencePlaceable = fencePlaceable
    self.segmentId = segmentId
    return self
end
function FenceRequestDeleteSegmentEvent.newServerToClient(success)
    local self = FenceRequestDeleteSegmentEvent.emptyNew()
    self.success = success
    return self
end
function FenceRequestDeleteSegmentEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.success = streamReadBool(streamId)
    else
        self.fencePlaceable = NetworkUtil.readNodeObject(streamId)
        self.segmentId = streamReadUInt16(streamId)
    end
    self:run(connection)
end
function FenceRequestDeleteSegmentEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)
        streamWriteUInt16(streamId, self.segmentId)
    else
        streamWriteBool(streamId, self.success)
    end
end
function FenceRequestDeleteSegmentEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(FenceRequestDeleteSegmentEvent, self.success)
    elseif self.fencePlaceable ~= nil and self.fencePlaceable:getIsSynchronized() then
        local fence = self.fencePlaceable:getFence()
        local segment = fence:getSegmentById(self.segmentId)
        if segment == nil then
            connection:sendEvent(FenceRequestDeleteSegmentEvent.newServerToClient(false))
            return
        end
        fence:removeSegment(segment)
        segment:delete()
        connection:sendEvent(FenceRequestDeleteSegmentEvent.newServerToClient(true))
        g_server:broadcastEvent(FenceDeleteSegmentEvent.new(self.fencePlaceable, self.segmentId), false, connection)
    end
end