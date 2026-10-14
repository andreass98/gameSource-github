SetSplitShapesEvent = {}
local SetSplitShapesEvent_mt = Class(SetSplitShapesEvent, Event)
InitStaticEventClass(SetSplitShapesEvent, "SetSplitShapesEvent")
SetSplitShapesEvent.PartSizeBits = 160000
function SetSplitShapesEvent.emptyNew()
    -- upvalues: (copy) SetSplitShapesEvent_mt
    local self = Event.new(SetSplitShapesEvent_mt)
    self.streamId = createStream()
    return self
end
function SetSplitShapesEvent.newAck(streamCurrentOffsetAck)
    local self = SetSplitShapesEvent.emptyNew()
    self.streamCurrentOffsetAck = streamCurrentOffsetAck
    return self
end
function SetSplitShapesEvent.newReceiving(streamTotalSize)
    local self = SetSplitShapesEvent.emptyNew()
    self.streamTotalSize = streamTotalSize
    return self
end
function SetSplitShapesEvent.new()
    local self = SetSplitShapesEvent.emptyNew()
    local streamId = self.streamId
    local mapsSplitShapeFileIds = g_currentMission.mapsSplitShapeFileIds
    local numFileIds = #mapsSplitShapeFileIds
    streamWriteInt32(streamId, numFileIds)
    local i = 1
    for i = i, numFileIds do
        streamWriteInt32(streamId, mapsSplitShapeFileIds[i])
    end
    g_treePlantManager:writeToClientStream(streamId)
    writeSplitShapesToStream(streamId)
    self.streamCurrentOffset = 0
    self.streamTotalSize = streamGetWriteOffset(streamId)
    self.percentage = 0
    return self
end
function SetSplitShapesEvent:delete()
    if self.streamId ~= 0 then
        delete(self.streamId)
        self.streamId = 0
    end
end
function SetSplitShapesEvent.readStream(_, streamId, connection)
    if connection:getIsServer() then
        local streamCurrentOffset = streamReadUInt32(streamId)
        Logging.devInfo("SetSplitShapesEvent:readStream-currentOffset: %d", streamCurrentOffset)
        if streamCurrentOffset == 0 then
            local streamTotalSizeInit = streamReadUInt32(streamId)
            g_currentMission.receivingSplitShapesEvent = SetSplitShapesEvent.newReceiving(streamTotalSizeInit)
            Logging.devInfo("SetSplitShapesEvent:readStream-totalSize: %d", streamTotalSizeInit)
        end
        local streamTotalSizeInit = currentMission.receivingSplitShapesEvent
        local streamTotalSize = streamTotalSizeInit.streamTotalSize
        local sizeToRead = math.min(streamTotalSizeInit.streamTotalSize - streamCurrentOffset, SetSplitShapesEvent.PartSizeBits)
        Logging.devInfo("SetSplitShapesEvent:readStream-readData: %d", sizeToRead)
        streamWriteStream(streamTotalSizeInit.streamId, streamId, sizeToRead, true)
        local streamCurrentOffset = streamCurrentOffset + sizeToRead
        streamTotalSizeInit.percentage = math.clamp(streamCurrentOffset / streamTotalSize, 0, 1)
        currentMission:onSplitShapesProgress(connection, streamTotalSizeInit.percentage)
        connection:sendEvent(SetSplitShapesEvent.newAck(streamCurrentOffset), true)
        if streamCurrentOffset == streamTotalSize then
            streamTotalSizeInit:processReadData()
            currentMission.receivingSplitShapesEvent:delete()
            currentMission.receivingSplitShapesEvent = nil
            return
        end
    else
        local streamCurrentOffset = streamReadUInt32(streamId)
        local streamTotalSizeInit = currentMission.playersSynchronizing[connection]
        if streamTotalSizeInit ~= nil and streamTotalSizeInit.splitShapesEvent ~= nil then
            local streamTotalSize = streamTotalSizeInit.splitShapesEvent
            streamTotalSize.percentage = math.clamp(streamCurrentOffset / streamTotalSize.streamTotalSize, 0, 1)
            if streamCurrentOffset < streamTotalSize.streamTotalSize then
                connection:sendEvent(streamTotalSize, false)
            end
            currentMission:onSplitShapesProgress(connection, streamTotalSize.percentage)
        end
    end
end
function SetSplitShapesEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        streamWriteUInt32(streamId, self.streamCurrentOffsetAck)
    else
        assert(g_currentMission.playersSynchronizing[connection].splitShapesEvent == self)
        local streamCurrentOffset = self.streamCurrentOffset
        self.streamCurrentOffset = self.streamCurrentOffset + SetSplitShapesEvent.PartSizeBits
        streamWriteUInt32(streamId, streamCurrentOffset)
        Logging.devInfo("SetSplitShapesEvent:writeStream-currentOffset: %d", streamCurrentOffset)
        if streamCurrentOffset == 0 then
            streamWriteUInt32(streamId, self.streamTotalSize)
            Logging.devInfo("SetSplitShapesEvent:writeStream-totalSize: %d", self.streamTotalSize)
        end
        local readOffset = streamGetReadOffset(self.streamId)
        streamSetReadOffset(self.streamId, streamCurrentOffset)
        local start = streamGetWriteOffset(streamId)
        streamWriteStream(streamId, self.streamId, SetSplitShapesEvent.PartSizeBits, true)
        Logging.devInfo("SetSplitShapesEvent:writeStream-writeData: %d", streamGetWriteOffset(streamId) - start)
        streamSetReadOffset(self.streamId, readOffset)
    end
end
function SetSplitShapesEvent:processReadData()
    local streamId = self.streamId
    local numFileIds = streamReadInt32(streamId)
    local i = 1
    for i = i, numFileIds do
        local fileId = streamReadInt32(streamId)
        setSplitShapesFileIdMapping(g_currentMission.mapsSplitShapeFileIds[i], fileId)
    end
    g_treePlantManager:readFromServerStream(streamId)
    readSplitShapesFromStream(streamId)
end
function SetSplitShapesEvent:run(connection) end