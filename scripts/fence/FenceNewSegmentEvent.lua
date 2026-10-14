FenceNewSegmentEvent = {}
FenceNewSegmentEvent.STATUS_CODE = {
    ["SUCCESS"] = 0,
    ["ERROR"] = 1
}
local FenceNewSegmentEvent_mt = Class(FenceNewSegmentEvent, Event)
InitStaticEventClass(FenceNewSegmentEvent, "FenceNewSegmentEvent")
function FenceNewSegmentEvent.emptyNew()
    -- upvalues: (copy) FenceNewSegmentEvent_mt
    return Event.new(FenceNewSegmentEvent_mt, NetworkNode.CHANNEL_MAIN)
end
function FenceNewSegmentEvent.newClientToServer(fencePlaceable, segment)
    local self = FenceNewSegmentEvent.emptyNew()
    self.fencePlaceable = fencePlaceable
    self.segment = segment
    return self
end
function FenceNewSegmentEvent.newServerToClient(statusCode, segmentId, ex, ey, ez)
    local self = FenceNewSegmentEvent.emptyNew()
    self.statusCode = statusCode
    self.segmentId = segmentId
    self.ex = ex
    self.ey = ey
    self.ez = ez
    return self
end
function FenceNewSegmentEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        local fence = streamReadUInt8(streamId)
        local templateIndex = streamReadUInt16(streamId)
        local templateId = streamReadFloat32(streamId)
        local ey = streamReadFloat32(streamId)
        local ez = streamReadFloat32(streamId)
        g_messageCenter:publish(FenceNewSegmentEvent, fence, templateIndex, templateId, ey, ez)
    else
        self.fencePlaceable = NetworkUtil.readNodeObject(streamId)
        local fence = self.fencePlaceable:getFence()
        self.segment = fence:createNewSegment((fence:getSegmentTemplateIdByIndex((streamReadUInt8(streamId)))))
        self.segment:readStream(streamId, connection)
        self:run(connection)
    end
end
function FenceNewSegmentEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)
        local segmentId = self.segment:getId()
        local fenceTemplateIndex = self.fencePlaceable:getFence():getSegmentTemplateIndexById(segmentId)
        streamWriteUInt8(streamId, fenceTemplateIndex)
        self.segment:writeStream(streamId, connection)
    else
        streamWriteUInt8(streamId, self.statusCode)
        streamWriteUInt16(streamId, self.segmentId)
        streamWriteFloat32(streamId, self.ex)
        streamWriteFloat32(streamId, self.ey)
        streamWriteFloat32(streamId, self.ez)
    end
end
function FenceNewSegmentEvent:run(connection)
    if self.fencePlaceable ~= nil and self.fencePlaceable:getIsSynchronized() then
        local statusCode = FenceNewSegmentEvent.STATUS_CODE.SUCCESS
        if self.segment:updateMeshes(true) then
            local player = g_currentMission:getPlayerByConnection(connection)
            if player ~= nil then
                local farmId = player.farmId
                if farmId ~= nil then
                    local price = self.segment:getPrice()
                    g_currentMission:addMoney(-price, farmId, MoneyType.SHOP_PROPERTY_BUY, true)
                end
            end
            self.segment:finalize()
        else
            statusCode = FenceNewSegmentEvent.STATUS_CODE.ERROR
        end
        if statusCode == FenceNewSegmentEvent.STATUS_CODE.SUCCESS then
            g_server:broadcastEvent(FenceSegmentEvent.new(self.fencePlaceable, self.segment), false, nil, self.fencePlaceable)
        end
        local player, farmId, price = self.segment:getEndPos()
        if not connection:getIsLocal() then
            connection:sendEvent(FenceNewSegmentEvent.newServerToClient(statusCode, self.segment.id, player, farmId, price))
            return
        end
        g_messageCenter:publish(FenceNewSegmentEvent, statusCode, self.segment.id, player, farmId, price)
    end
end