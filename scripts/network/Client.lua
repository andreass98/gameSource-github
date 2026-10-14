Client = {}
local Client_mt = Class(Client, NetworkNode)
local clientLocalNetConnect = ""
function InitClientOnce()
    -- upvalues: (ref) clientLocalNetConnect
    if clientLocalNetConnect == "" then
        clientLocalNetConnect = netConnect
    end
end
function Client.new()
    -- upvalues: (copy) Client_mt
    local self = NetworkNode.new(Client_mt)
    self.serverConnection = nil
    self.tempClientCreatingObjects = {}
    self.tempClientManuallyRegisteringObjects = {}
    self.tickRate = 30
    self.tickDuration = 1000 / self.tickRate
    self.tickSum = 0
    self.netIsRunning = false
    self.serverStreamId = 0
    self.currentLatency = 80
    self.lastNumUpdatesSent = 0
    self.finishedAsyncObjects = {}
    if g_server == nil then
        addConsoleCommand("gsNetworkShowTraffic", "Toggle network traffic visualization", "consoleCommandToggleShowNetworkTraffic", self)
        addConsoleCommand("gsNetworkShowObjects", "Toggle network show objects", "consoleCommandToggleNetworkShowObjects", self)
    end
    return self
end
function Client:delete()
    if g_server == nil then
        removeConsoleCommand("gsNetworkShowTraffic")
        removeConsoleCommand("gsNetworkShowObjects")
    end
    for _, object in pairs(self.tempClientCreatingObjects) do
        object:delete()
    end
    for _, object in pairs(self.tempClientManuallyRegisteringObjects) do
        object:delete()
    end
    self.finishedAsyncObjects = {}
    Client:superClass().delete(self)
    self:stop()
end
function Client:update(dt, isRunning)
    if g_server == nil then
        Client:superClass().update(self, dt)
        if self.serverStreamId == 0 then
            return
        end
        if not isRunning then
            return
        end
        if #self.finishedAsyncObjects > 0 then
            local numObjects = math.min(#self.finishedAsyncObjects, 255)
            streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_LOADED, MessageIds.SEND_NUM_BITS)
            streamWriteUInt8(self.serverStreamId, numObjects)
            for i = 1, numObjects do
                local object = table.remove(self.finishedAsyncObjects, 1)
                local serverObjectId = NetworkUtil.getObjectId(object)
                local objectInfo = self.serverConnection.objectsInfo[serverObjectId]
                if objectInfo ~= nil then
                    objectInfo.sync = Connection.SYNC_LOADED
                    NetworkUtil.writeNodeObjectId(self.serverStreamId, serverObjectId)
                end
            end
            netSendStream(self.serverStreamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
        end
        self:updateActiveObjects(dt)
        self.tickSum = self.tickSum + dt
        if self.tickSum >= self.tickDuration - 3 then
            local numObjects = self:updateActiveObjectsTick(self.tickSum)
            if self.serverConnection:getIsWindowFull() then
                if not self.serverConnection.ackPingPacketSent then
                    self.serverConnection.ackPingPacketSent = true
                    streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_PING, MessageIds.SEND_NUM_BITS)
                    self.serverConnection:writeUpdateAck(self.serverStreamId)
                    netSendStream(self.serverStreamId, "medium", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
                end
            else
                self.serverConnection.ackPingPacketSent = false
                local numDirtyObjectsSent = #numObjects
                local numDirtyObjects = math.min(numDirtyObjectsSent, 255)
                if numDirtyObjects > 0 then
                    streamWriteTimestamp(self.serverStreamId)
                end
                streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_UPDATE, MessageIds.SEND_NUM_BITS)
                self.serverConnection:writeUpdateAck(self.serverStreamId)
                local i = streamGetWriteOffset(self.serverStreamId)
                streamWriteUInt8(self.serverStreamId, 0)
                local object = 0
                local serverObjectId = 0
                local objectInfo = 0
                local isGuiActive = false
                if self.networkListener ~= nil then
                    object, serverObjectId, objectInfo = self.networkListener:getClientPosition()
                    isGuiActive = self.networkListener:getClientGuiVisibility()
                end
                streamWriteBool(self.serverStreamId, isGuiActive)
                streamWriteFloat32(self.serverStreamId, object)
                streamWriteFloat32(self.serverStreamId, serverObjectId)
                streamWriteFloat32(self.serverStreamId, objectInfo)
                local oldPacketSize = 0
                local j = 1
                local numDirtyObjectsSent = numDirtyObjects
                for j = j, numDirtyObjects do
                    local object = numObjects[j]
                    NetworkUtil.writeNodeObjectId(self.serverStreamId, numObjects[j].lastServerId)
                    object:writeUpdateStream(self.serverStreamId, self.serverConnection, object.dirtyMask)
                    object:clearDirtyMask()
                    local packetSize = streamGetWriteOffset(self.serverStreamId)
                    self:addPacketSize(self.serverConnection, self:getObjectPacketType(object), (packetSize - oldPacketSize) / 8)
                    if g_maxUploadRate * 8 * self.tickDuration < packetSize then
                        numDirtyObjectsSent = j
                        break
                    end
                end
                local endOffset = streamGetWriteOffset(self.serverStreamId)
                streamSetWriteOffset(self.serverStreamId, i)
                streamWriteUInt8(self.serverStreamId, numDirtyObjectsSent)
                streamSetWriteOffset(self.serverStreamId, endOffset)
                local endOffset = streamGetWriteOffset(self.serverStreamId)
                voiceChatWriteClientUpdateToStream(self.serverStreamId, self.serverStreamId)
                self:addPacketSize(self.serverConnection, NetworkNode.PACKET_VOICE_CHAT, (streamGetWriteOffset(self.serverStreamId) - endOffset) / 8)
                netSendStream(self.serverStreamId, "medium", "unreliable_sequenced", NetworkNode.CHANNEL_MAIN, true)
            end
            self:updatePacketStats(self.tickSum)
            self.tickSum = 0
        end
    end
end
function Client:drawDebug()
    if g_server == nil then
        Client:superClass().drawDebug(self)
        local _ = self.showNetworkTraffic
    end
end
function Client:onObjectFinishedAsyncLoading(object)
    table.insert(self.finishedAsyncObjects, object)
end
function Client:startLocal()
    self.serverConnection = g_server.clientConnections[NetworkNode.LOCAL_STREAM_ID].localConnection
    self:connectionRequestAccepted()
end
function Client:start(serverAddress, serverPort, relayHeader)
    -- upvalues: (ref) clientLocalNetConnect
    if not self.netIsRunning then
        self.netIsRunning = true
        g_connectionManager:startupWithWorkingPort(g_gameSettings:getValue(GameSettings.SETTING.DEFAULT_SERVER_PORT))
        g_connectionManager:setDefaultListener(Client.packetReceived, self)
        self.serverStreamId = clientLocalNetConnect(serverAddress, serverPort, "", relayHeader == nil and "" or relayHeader)
        self.serverConnection = Connection.new(self.serverStreamId, true)
        if self.serverStreamId == 0 then
            printError("Error: Failed to call connect")
            self.serverConnection.isConnected = false
            self.serverConnection:setIsReadyForObjects(false)
            self.serverConnection:setIsReadyForEvents(false)
            if self.networkListener ~= nil then
                self.networkListener:onConnectionClosed(self.serverConnection)
            end
        else
            self.serverConnection:setIsReadyForObjects(true)
            self.serverConnection:setIsReadyForEvents(true)
        end
        if g_isDevelopmentVersion then
            CaptionUtil.addText("- Client")
        end
    end
end
function Client:stop()
    if self.netIsRunning then
        if self.serverStreamId ~= 0 then
            netCloseConnection(self.serverStreamId, true, 1)
            self.serverStreamId = 0
        end
        self.serverConnection.isConnected = false
        self.serverConnection:setIsReadyForObjects(false)
        self.serverConnection:setIsReadyForEvents(false)
        g_connectionManager:shutdown()
        g_connectionManager:setDefaultListener(nil, nil)
        self.netIsRunning = false
    end
end
function Client:packetReceived(packetType, timestamp, streamId)
    if streamId == self.serverStreamId then
        Client:superClass().packetReceived(self, packetType, timestamp, streamId)
        if packetType == Network.TYPE_APPLICATION then
            local messageId = streamReadUIntN(streamId, MessageIds.SEND_NUM_BITS)
            if messageId == MessageIds.OBJECT_UPDATE then
                g_packetPhysicsNetworkTime = streamReadInt32(streamId)
                g_networkTime = netGetTime()
                local networkDebug = g_networkTime - timestamp
                self.currentLatency = self.currentLatency * 0.9 + math.max(networkDebug, 0.5) * 0.1
                local tickDelay = 60
                if self.lastReceivedNetworkTime ~= nil then
                    tickDelay = g_networkTime - self.lastReceivedNetworkTime
                end
                self.lastReceivedNetworkTime = g_networkTime
                local networkDebug = g_clientInterpDelayBufferMin
                local targetDelay = tickDelay + math.clamp(g_clientInterpDelayBufferOffset + tickDelay * g_clientInterpDelayBufferScale, networkDebug, g_clientInterpDelayBufferMax)
                local adjust = g_clientInterpDelayAdjustDown
                if g_clientInterpDelay < targetDelay then
                    adjust = g_clientInterpDelayAdjustUp
                end
                g_clientInterpDelay = g_clientInterpDelay * (1 - adjust) + targetDelay * adjust
                local startOffset = g_clientInterpDelayMin
                g_clientInterpDelay = math.clamp(g_clientInterpDelay, startOffset, g_clientInterpDelayMax)
                self.serverConnection:readUpdateAck(streamId)
                self.serverFPS = streamReadUIntN(streamId, 6)
                local networkDebug = streamReadBool(streamId)
                if self.networkListener ~= nil then
                    self.networkListener:onConnectionReadUpdateStream(self.serverConnection, networkDebug)
                end
                for i = 1, streamReadUInt8(streamId) do
                    local numBits = nil
                    local startOffset = 0
                    if networkDebug then
                        startOffset = streamGetReadOffset(streamId)
                        numBits = streamReadInt32(streamId)
                    end
                    local infoId = streamReadUIntN(streamId, Connection.SEND_INFO_NUM_BITS)
                    if infoId == Connection.SEND_INFO_DELETE then
                        local object = self:getObject((NetworkUtil.readNodeObjectId(streamId)))
                        if object ~= nil then
                            self:unregisterObject(object, true)
                            object:delete()
                        end
                        if networkDebug then
                            self:checkObjectUpdateDebugReadSize(streamId, numBits, startOffset, "object", object)
                        end
                    elseif infoId == Connection.SEND_INFO_CREATE then
                        if g_server ~= nil then
                            printError("Error: Unexpected packet object created")
                            return
                        end
                        local objectId = streamReadUIntN(streamId, ObjectIds.SEND_NUM_BITS)
                        local object = NetworkUtil.readNodeObjectId(streamId)
                        local object = self:getObject(object)
                        local needsCreation = object ~= nil
                        if needsCreation then
                            local objectClass = ObjectIds.getObjectClassById(objectId)
                            if objectClass ~= nil then
                                object = objectClass.new(false, true)
                                object.isManuallyReplicated = false
                                object.isRegistered = true
                            end
                        end
                        if object == nil then
                            return
                        end
                        object:readStream(streamId, self.serverConnection, object)
                        local objectClass = Connection.SYNC_CREATED
                        if needsCreation then
                            if object:getIsDelayedLoaded() then
                                objectClass = Connection.SYNC_CREATING_DELAYED
                            else
                                object.recieveUpdates = true
                            end
                            self:addObject(object, object)
                        else
                            object:onGhostAdd()
                        end
                        self.serverConnection.objectsInfo[object] = {
                            ["dirtyMask"] = 0,
                            ["sync"] = objectClass,
                            ["history"] = {}
                        }
                        if networkDebug then
                            self:checkObjectUpdateDebugReadSize(streamId, numBits, startOffset, "creation", object)
                        end
                    elseif infoId == Connection.SEND_INFO_SYNC then
                        local objectId = NetworkUtil.readNodeObjectId(streamId)
                        local object = self:getObject(objectId)
                        if object == nil then
                            return
                        end
                        object:postReadStream(streamId, self.serverConnection)
                        self.serverConnection.objectsInfo[objectId].sync = Connection.SYNC_CREATED
                        object.recieveUpdates = true
                        if networkDebug then
                            self:checkObjectUpdateDebugReadSize(streamId, numBits, startOffset, "sync", object)
                        end
                    elseif infoId == Connection.SEND_INFO_UPDATE then
                        local object = self:getObject((NetworkUtil.readNodeObjectId(streamId)))
                        if object == nil then
                            return
                        end
                        object:readUpdateStream(streamId, timestamp, self.serverConnection)
                        object:raiseActive()
                        if networkDebug then
                            self:checkObjectUpdateDebugReadSize(streamId, numBits, startOffset, "update", object)
                        end
                    else
                        local object = self:getObject((NetworkUtil.readNodeObjectId(streamId)))
                        if object ~= nil then
                            object:onGhostRemove()
                        end
                        if networkDebug then
                            self:checkObjectUpdateDebugReadSize(streamId, numBits, startOffset, "removal", object)
                        end
                    end
                end
                return
            end
            if messageId == MessageIds.OBJECT_PING then
                self.serverConnection:readUpdateAck(streamId)
                streamWriteUIntN(streamId, MessageIds.OBJECT_ACK, MessageIds.SEND_NUM_BITS)
                self.serverConnection:writeUpdateAck(streamId)
                netSendStream(streamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
                return
            end
            if messageId == MessageIds.OBJECT_ACK then
                self.serverConnection:readUpdateAck(streamId)
                return
            end
            if messageId == MessageIds.OBJECT_INITIAL_ARRAY then
                self.waitingForObjects = false
                if g_server == nil then
                    local tickDelay = streamReadBool(streamId)
                    local interpBuffer = streamReadInt32(streamId)
                    print("Joined network game (" .. interpBuffer .. ")")
                    for networkDebug = 1, interpBuffer do
                        local numInfos = 0
                        local startOffset = 0
                        if tickDelay then
                            startOffset = streamGetReadOffset(streamId)
                            numInfos = streamReadInt32(streamId)
                        end
                        local objectClassId = streamReadUIntN(streamId, ObjectIds.SEND_NUM_BITS)
                        local i = NetworkUtil.readNodeObjectId(streamId)
                        local numBits = ObjectIds.getObjectClassById(objectClassId)
                        local startOffset = nil
                        if numBits ~= nil then
                            startOffset = numBits.new(false, true)
                            startOffset.isManuallyReplicated = false
                            startOffset.isRegistered = true
                        end
                        if startOffset == nil then
                            printError("Error: Failed to create new object with class id " .. objectClassId .. " in initial object array")
                            return
                        end
                        startOffset:readStream(streamId, self.serverConnection, i)
                        self:addObject(startOffset, i)
                        local infoId = Connection.SYNC_CREATED
                        if startOffset:getIsDelayedLoaded() then
                            infoId = Connection.SYNC_CREATING_DELAYED
                        else
                            startOffset.recieveUpdates = true
                        end
                        self.serverConnection.objectsInfo[i] = {
                            ["dirtyMask"] = 0,
                            ["sync"] = infoId,
                            ["history"] = {}
                        }
                        if tickDelay then
                            local object = streamGetReadOffset(streamId) - (startOffset + 32)
                            if object ~= numInfos then
                                local object = ""
                                if startOffset.configFileName ~= nil then
                                    object = " (" .. startOffset.configFileName .. ")"
                                end
                                printError("Error: Not all bits read in object create array (" .. object .. " vs " .. numInfos .. "), Class: " .. numBits.className .. object)
                            end
                        end
                    end
                    g_messageCenter:publish(MessageType.ENQUEUED_ALL_LOADINGS)
                else
                    printError("Error: Unexpected packet object created array")
                end
            end
            if messageId == MessageIds.OBJECT_SERVER_ID then
                local tickDelay = NetworkUtil.readNodeObjectId(streamId)
                local interpBuffer = NetworkUtil.readNodeObjectId(streamId)
                local targetDelay = self.tempClientCreatingObjects[interpBuffer]
                streamWriteUIntN(streamId, MessageIds.OBJECT_SERVER_ID_ACK, MessageIds.SEND_NUM_BITS)
                NetworkUtil.writeNodeObjectId(streamId, tickDelay)
                netSendStream(streamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
                if targetDelay == nil then
                    streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_DELETED, MessageIds.SEND_NUM_BITS)
                    NetworkUtil.writeNodeObjectId(self.serverStreamId, tickDelay)
                    netSendStream(self.serverStreamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
                else
                    self:finishRegisterObject(targetDelay, tickDelay)
                    self.tempClientCreatingObjects[interpBuffer] = nil
                end
            end
            if messageId ~= MessageIds.EVENT then
                if messageId == MessageIds.EVENT_IDS then
                    local tickDelay = streamReadInt32(streamId)
                    for adjust = 1, tickDelay do
                        local networkDebug = streamReadUIntN(streamId, EventIds.SEND_NUM_BITS)
                        local numInfos = streamReadString(streamId)
                        EventIds.assignEventId(numInfos, networkDebug)
                    end
                    return
                elseif messageId == MessageIds.OBJECT_CLASS_IDS then
                    local tickDelay = streamReadInt32(streamId)
                    for adjust = 1, tickDelay do
                        local networkDebug = streamReadUIntN(streamId, ObjectIds.SEND_NUM_BITS)
                        local numInfos = streamReadString(streamId)
                        ObjectIds.assignObjectClassId(numInfos, networkDebug)
                    end
                else
                    printError("Error: Invalid message id " .. messageId)
                end
            end
            local tickDelay = streamReadUIntN(streamId, EventIds.SEND_NUM_BITS)
            local interpBuffer = EventIds.getEventClassById(tickDelay)
            if interpBuffer ~= nil then
                local targetDelay = streamReadBool(streamId)
                local adjust = nil
                local networkDebug = 0
                if targetDelay then
                    networkDebug = streamGetReadOffset(streamId)
                    adjust = streamReadInt32(streamId)
                end
                local numInfos = interpBuffer.emptyNew()
                numInfos:readStream(streamId, self.serverConnection)
                numInfos:delete()
                if targetDelay then
                    local objectClassId = streamGetReadOffset(streamId) - (networkDebug + 32)
                    if objectClassId ~= adjust then
                        local i = ClassUtil.getClassNameByObject(interpBuffer)
                        printError("Error: Not all bits read in event (" .. objectClassId .. " vs " .. adjust .. "), Class: " .. tostring(i))
                        return
                    end
                end
            end
        else
            if packetType == Network.TYPE_CONNECTION_REQUEST_ACCEPTED then
                streamWriteUIntN(self.serverStreamId, MessageIds.CLIP_COEFF, MessageIds.SEND_NUM_BITS)
                streamWriteFloat32(self.serverStreamId, getViewDistanceCoeff())
                netSendStream(self.serverStreamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
                self:connectionRequestAccepted()
                return
            end
            if packetType == Network.TYPE_DISCONNECTION_NOTIFICATION then
                if streamId == self.serverStreamId then
                    self.serverStreamId = 0
                    self.serverConnection.isConnected = false
                    self.serverConnection:setIsReadyForObjects(false)
                    self.serverConnection:setIsReadyForEvents(false)
                    if self.networkListener ~= nil then
                        self.networkListener:onConnectionClosed(self.serverConnection)
                        return
                    end
                end
            elseif (packetType == Network.TYPE_CONNECTION_ATTEMPT_FAILED or (packetType == Network.TYPE_CONNECTION_LOST or (packetType == Network.TYPE_CONNECTION_BANNED or packetType == Network.TYPE_INVALID_PASSWORD))) and streamId == self.serverStreamId then
                self.serverStreamId = 0
                self.serverConnection.isConnected = false
                self.serverConnection:setIsReadyForObjects(false)
                self.serverConnection:setIsReadyForEvents(false)
                if self.networkListener ~= nil then
                    self.networkListener:onConnectionClosed(self.serverConnection)
                end
            end
        end
    end
end
function Client:connectionRequestAccepted()
    if self.networkListener ~= nil then
        self.networkListener:onConnectionAccepted(self.serverConnection)
    end
end
function Client:registerObject(object, alreadySent)
    if not object.isRegistered then
        object.isManuallyReplicated = alreadySent
        object.isRegistered = true
        if alreadySent then
            self.tempClientManuallyRegisteringObjects[object.id] = object
            return
        end
        if g_server ~= nil then
            printError("Error: Client:registerObject not expected")
            printCallstack()
        end
        self.tempClientCreatingObjects[object.id] = object
        streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_CREATED, MessageIds.SEND_NUM_BITS)
        streamWriteUIntN(self.serverStreamId, object.classId, ObjectIds.SEND_NUM_BITS)
        NetworkUtil.writeNodeObjectId(self.serverStreamId, object.id)
        object:writeStream(self.serverStreamId, self.serverConnection)
        netSendStream(self.serverStreamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
    end
end
function Client:unregisterObject(object, alreadySent)
    if object.isRegistered then
        local serverId = self:getObjectId(object)
        if serverId == nil then
            self.tempClientManuallyRegisteringObjects[object.id] = nil
            self.tempClientCreatingObjects[object.id] = nil
        else
            if (alreadySent == nil or not alreadySent) and self.serverStreamId ~= 0 then
                streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_DELETED, MessageIds.SEND_NUM_BITS)
                NetworkUtil.writeNodeObjectId(self.serverStreamId, serverId)
                netSendStream(self.serverStreamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
            end
            self:removeObject(object, serverId)
        end
        object.isRegistered = false
    end
end
function Client:finishRegisterObject(object, serverId)
    self:addObject(object, serverId)
    self.serverConnection.objectsInfo[serverId] = {
        ["dirtyMask"] = 0,
        ["sync"] = Connection.SYNC_CREATED,
        ["history"] = {}
    }
    object.recieveUpdates = true
    self.tempClientManuallyRegisteringObjects[object.id] = nil
    self.tempClientCreatingObjects[object.id] = nil
end
function Client:getServerConnection()
    return self.serverConnection
end