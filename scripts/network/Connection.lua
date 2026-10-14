Connection = {}
source("dataS/scripts/network/DisconnectReason.lua")
local Connection_mt = Class(Connection)
Connection.SYNC_CREATING = 1
Connection.SYNC_CREATING_DELAYED = 2
Connection.SYNC_LOADED = 3
Connection.SYNC_SYNCING = 4
Connection.SYNC_CREATED = 5
Connection.SYNC_REMOVING = 6
Connection.SYNC_MANUALLY_REGISTERED = 7
Connection.SYNC_HIST_CREATE = 0
Connection.SYNC_HIST_SYNC = 1
Connection.SYNC_HIST_UPDATE = 2
Connection.SYNC_HIST_REMOVE = 3
Connection.SEND_INFO_NUM_BITS = 3
Connection.SEND_INFO_DELETE = 0
Connection.SEND_INFO_CREATE = 1
Connection.SEND_INFO_SYNC = 2
Connection.SEND_INFO_UPDATE = 3
Connection.SEND_INFO_REMOVE = 4
function Connection.new(id, isServer, reverseConnection)
    -- upvalues: (copy) Connection_mt
    local self = setmetatable({}, Connection_mt)
    self.streamId = id
    self.isServer = isServer
    self.isConnected = true
    self.isReadyForObjects = false
    self.isReadyForEvents = false
    self.objectsInfo = {}
    self.pendingDeleteObjects = {}
    self.pendingDeleteObjectPacketIds = {}
    self.compressionRatio = 1
    self.sendStatsTime = 0
    self.lastSeqSent = 0
    self.lastSeqReceived = 0
    self.highestAckedSeq = 0
    self.ackMask = 0
    self.hasPacketsToAck = false
    self.ackPingPacketSent = false
    if self.streamId == NetworkNode.LOCAL_STREAM_ID then
        self:setIsReadyForObjects(true)
        self:setIsReadyForEvents(true)
        if reverseConnection ~= nil then
            self.localConnection = reverseConnection
            return self
        end
        self.localConnection = Connection.new(id, not isServer, self)
        self.localConnection:setIsReadyForObjects(true)
        self.localConnection:setIsReadyForEvents(true)
    end
    return self
end
function Connection:setIsReadyForObjects(isReadyForObjects)
    self.isReadyForObjects = isReadyForObjects
end
function Connection:setIsReadyForEvents(isReadyForEvents)
    self.isReadyForEvents = isReadyForEvents
end
function Connection:updateSendStats(tickSum)
    self.sendStatsTime = self.sendStatsTime + tickSum
    if self.sendStatsTime > 100 then
        self.sendStatsTime = 0
        local sendSize, sendSizeCompressed = netGetAndResetConnectionSendStats(self.streamId)
        local compressionRatio = 1
        if sendSizeCompressed > 0 then
            compressionRatio = math.clamp(sendSize / sendSizeCompressed, 1, 5)
        end
        self.compressionRatio = 0.8 * self.compressionRatio + 0.2 * compressionRatio
    end
end
function Connection:sendEvent(event, deleteEvent, force)
    if self.isConnected then
        if self.streamId == NetworkNode.LOCAL_STREAM_ID then
            event:run(self.localConnection)
        elseif self.isReadyForEvents or force then
            if event.eventId == nil then
                printError("Error: Invalid event id for " .. (ClassUtil.getClassNameByObject(event) or "<unable to retrieve class>"))
            else
                local networkChannel = event.networkChannel
                if g_server ~= nil and networkChannel == NetworkNode.CHANNEL_MAIN then
                    g_server:setCurrentReliableWriteStreamConnection(self)
                end
                streamWriteUIntN(self.streamId, MessageIds.EVENT, MessageIds.SEND_NUM_BITS)
                streamWriteUIntN(self.streamId, event.eventId, EventIds.SEND_NUM_BITS)
                streamWriteBool(self.streamId, g_networkDebug)
                local startOffset = nil
                if g_networkDebug then
                    startOffset = streamGetWriteOffset(self.streamId)
                    streamWriteInt32(self.streamId, 0)
                end
                event:writeStream(self.streamId, self)
                if g_networkDebug then
                    local endOffset = streamGetWriteOffset(self.streamId)
                    streamSetWriteOffset(self.streamId, startOffset)
                    streamWriteInt32(self.streamId, endOffset - (startOffset + 32))
                    streamSetWriteOffset(self.streamId, endOffset)
                end
                local endOffset = streamGetWriteOffset(self.streamId)
                netSendStream(self.streamId, "high", "reliable_ordered", networkChannel, true)
                if g_server == nil then
                    g_client:addPacketSize(self, NetworkNode.PACKET_EVENT, endOffset / 8)
                else
                    g_server:setCurrentReliableWriteStreamConnection(nil)
                    g_server:addPacketSize(self, NetworkNode.PACKET_EVENT, endOffset / 8)
                end
            end
        end
        if deleteEvent then
            event:delete()
        end
    end
end
function Connection:queueSendEvent(event, force, ghostObject)
    if self.isConnected then
        if self.isReadyForEvents or force then
            local objectInfo = self.objectsInfo[ghostObject.id]
            if objectInfo ~= nil then
                local isInQueueState = true
                if objectInfo.sync ~= Connection.SYNC_CREATING then
                    isInQueueState = true
                    if objectInfo.sync ~= Connection.SYNC_CREATING_DELAYED then
                        isInQueueState = true
                        if objectInfo.sync ~= Connection.SYNC_LOADED then
                            isInQueueState = true
                            if objectInfo.sync ~= Connection.SYNC_SYNCING then
                                isInQueueState = objectInfo.sync == Connection.SYNC_MANUALLY_REGISTERED
                            end
                        end
                    end
                end
                if isInQueueState then
                    event.queueCount = event.queueCount + 1
                    if objectInfo.eventQueue == nil then
                        objectInfo.eventQueue = {}
                    end
                    table.insert(objectInfo.eventQueue, event)
                    return
                end
            end
        end
    end
end
function Connection:getIsClient()
    return not self.isServer
end
function Connection:getIsServer()
    return self.isServer
end
function Connection:getIsLocal()
    return self.streamId == NetworkNode.LOCAL_STREAM_ID
end
function Connection:writeUpdateAck(streamId)
    self.lastSeqSent = self.lastSeqSent + 1
    streamWriteUInt8(streamId, self.lastSeqSent % 256)
    streamWriteUInt8(streamId, self.lastSeqReceived % 256)
    streamWriteUInt32(streamId, self.ackMask)
    self.hasPacketsToAck = false
end
function Connection:readUpdateAck(streamId)
    local seq = streamReadUInt8(streamId)
    local highestAck = streamReadUInt8(streamId)
    local ackMask = streamReadUInt32(streamId)
    local seq = seq + bit32.band(self.lastSeqReceived, 4294967040)
    if seq < self.lastSeqReceived then
    end
    if self.lastSeqReceived + 31 < seq then
        return false
    end
    local highestAck = highestAck + bit32.band(self.highestAckedSeq, 4294967040)
    if highestAck < self.highestAckedSeq then
    end
    if self.lastSeqSent < highestAck then
        return false
    end
    local i = seq - self.lastSeqReceived
    self.ackMask = bit32.lshift(self.ackMask, i)
    self.ackMask = self.ackMask + 1
    self.hasPacketsToAck = true
    local i = self.highestAckedSeq + 1
    for i = i, highestAck do
        local isTransmitted = bit32.band(ackMask, (bit32.lshift(1, highestAck - i))) ~= 0
        if isTransmitted then
            self:onPacketSent(i)
        else
            self:onPacketLost(i)
        end
    end
    self.highestAckedSeq = highestAck
    self.lastSeqReceived = seq
    return true
end
function Connection:getIsWindowFull()
    return self.lastSeqSent - self.highestAckedSeq >= 29
end
function Connection:getObjectSyncState(objectId)
    local objectInfo = self.objectsInfo[objectId]
    if objectInfo == nil then
        return nil
    else
        return objectInfo.sync
    end
end
function Connection:onPacketSent(i)
    for objectId, objectInfo in pairs(self.objectsInfo) do
        local historyEntry = objectInfo.history[i]
        if historyEntry ~= nil then
            if g_networkDebug then
                for k, _ in pairs(objectInfo.history) do
                    assert(i <= k)
                end
            end
            objectInfo.history[i] = nil
            if historyEntry.sync == Connection.SYNC_HIST_CREATE then
                if objectInfo.sync == Connection.SYNC_CREATING then
                    objectInfo.sync = Connection.SYNC_CREATED
                    self:sendObjectEventQueue(objectInfo)
                end
            elseif historyEntry.sync == Connection.SYNC_HIST_SYNC then
                if objectInfo.sync == Connection.SYNC_SYNCING then
                    objectInfo.sync = Connection.SYNC_CREATED
                    self:sendObjectEventQueue(objectInfo)
                end
            elseif historyEntry.sync == Connection.SYNC_HIST_REMOVE and objectInfo.sync == Connection.SYNC_REMOVING then
                self.objectsInfo[objectId] = nil
            end
        end
    end
    for objectId, objectInfo in pairs(self.pendingDeleteObjectPacketIds) do
        if objectInfo == i then
            self.pendingDeleteObjectPacketIds[objectId] = nil
        end
    end
    g_currentMission:onConnectionPacketSent(self, i)
end
function Connection:onPacketLost(i)
    for objectId, objectInfo in pairs(self.objectsInfo) do
        local historyEntry = objectInfo.history[i]
        if historyEntry ~= nil then
            if g_networkDebug then
                for k, _ in pairs(objectInfo.history) do
                    assert(i <= k)
                end
            end
            objectInfo.history[i] = nil
            if historyEntry.sync == Connection.SYNC_HIST_CREATE then
                if objectInfo.sync == Connection.SYNC_CREATING or objectInfo.sync == Connection.SYNC_CREATING_DELAYED then
                    if objectInfo.manuallyReplicated then
                        objectInfo.sync = Connection.SYNC_MANUALLY_REGISTERED
                    else
                        self.objectsInfo[objectId] = nil
                    end
                end
            elseif historyEntry.sync == Connection.SYNC_HIST_SYNC then
                if objectInfo.sync == Connection.SYNC_SYNCING then
                    objectInfo.sync = Connection.SYNC_LOADED
                end
            elseif historyEntry.sync == Connection.SYNC_HIST_REMOVE then
                if objectInfo.sync == Connection.SYNC_REMOVING then
                    objectInfo.sync = Connection.SYNC_CREATED
                end
            else
                local laterUpdatedMask = 0
                for _, h in pairs(objectInfo.history) do
                    laterUpdatedMask = bit32.bor(laterUpdatedMask, h.mask)
                end
                local k = bit32.bnot(laterUpdatedMask)
                local notLaterUpdatedMask = bit32.band(historyEntry.mask, k)
                if notLaterUpdatedMask ~= 0 then
                    objectInfo.dirtyMask = bit32.bor(objectInfo.dirtyMask, notLaterUpdatedMask)
                end
            end
        end
    end
    for objectId, objectInfo in pairs(self.pendingDeleteObjectPacketIds) do
        if objectInfo == i then
            self.pendingDeleteObjectPacketIds[objectId] = nil
            self.pendingDeleteObjects[objectId] = objectId
        end
    end
    g_currentMission:onConnectionPacketLost(self, i)
end
function Connection:sendObjectEventQueue(objectInfo)
    if objectInfo.eventQueue ~= nil then
        for _, event in ipairs(objectInfo.eventQueue) do
            self:sendEvent(event, false, true)
            event.queueCount = event.queueCount - 1
            if event.queueCount == 0 then
                event:delete()
            end
        end
        objectInfo.eventQueue = nil
    end
end
function Connection.dropObjectEventQueue(_, objectInfo)
    if objectInfo.eventQueue ~= nil then
        for _, event in ipairs(objectInfo.eventQueue) do
            event.queueCount = event.queueCount - 1
            if event.queueCount == 0 then
                event:delete()
            end
        end
        objectInfo.eventQueue = nil
    end
end
function Connection:notifyObjectDeleted(objectId, alreadySent)
    assert(not self.isServer)
    local objectInfo = self.objectsInfo[objectId]
    if objectInfo ~= nil then
        self:dropObjectEventQueue(objectInfo)
        self.objectsInfo[objectId] = nil
    end
    if not alreadySent and (self.streamId ~= NetworkNode.LOCAL_STREAM_ID and self.pendingDeleteObjectPacketIds[objectId] == nil) then
        self.pendingDeleteObjects[objectId] = objectId
    end
end
function Connection:getLatency()
    return 20
end