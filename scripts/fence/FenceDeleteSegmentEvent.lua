FenceDeleteSegmentEvent = {}
local FenceDeleteSegmentEvent_mt = Class(FenceDeleteSegmentEvent, Event)
InitStaticEventClass(FenceDeleteSegmentEvent, "FenceDeleteSegmentEvent")
function FenceDeleteSegmentEvent.emptyNew()
    -- upvalues: (copy) FenceDeleteSegmentEvent_mt
    return Event.new(FenceDeleteSegmentEvent_mt, NetworkNode.CHANNEL_MAIN)
end
function FenceDeleteSegmentEvent.new(fencePlaceable, segmentId)
    local self = FenceDeleteSegmentEvent.emptyNew()
    self.fencePlaceable = fencePlaceable
    self.segmentId = segmentId
    return self
end
function FenceDeleteSegmentEvent:readStream(streamId, connection)
    self.fencePlaceable = NetworkUtil.readNodeObject(streamId)
    self.segmentId = streamReadUInt16(streamId)
    self:run(connection)
end
function FenceDeleteSegmentEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)
    streamWriteUInt16(streamId, self.segmentId)
end
function FenceDeleteSegmentEvent:run(_)
    if self.fencePlaceable ~= nil and self.fencePlaceable:getIsSynchronized() then
        if g_server ~= nil then
            g_server:broadcastEvent(self, false, nil)
        end
        local fence = self.fencePlaceable:getFence()
        local segment = fence:getSegmentById(self.segmentId)
        if segment ~= nil then
            fence:removeSegment(segment)
            segment:delete()
            g_messageCenter:publish(FenceDeleteSegmentEvent, self.fencePlaceable, segment)
        end
    end
end