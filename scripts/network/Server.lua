Server = {}
local Server_mt = Class(Server, NetworkNode)
function Server.new()
    -- upvalues: (copy) Server_mt
    local self = NetworkNode.new(Server_mt)
    self.clients = {}
    self.clientConnections = {}
    self.clientPositions = {}
    self.clientGuiVisibility = {}
    self.clientClipDistCoeffs = {}
    self.objects = {}
    self.tickRate = 30
    self.tickDuration = 1000 / self.tickRate
    self.tickSum = 0
    self.netIsRunning = false
    addConsoleCommand("gsNetworkShowTraffic", "Toggle network traffic visualization", "consoleCommandToggleShowNetworkTraffic", self)
    addConsoleCommand("gsNetworkShowTrafficClients", "Toggle client network traffic visualization", "consoleCommandToggleShowNetworkTrafficClients", self)
    addConsoleCommand("gsNetworkDebug", "Toggle network debugging", "consoleCommandToggleNetworkDebug", self)
    addConsoleCommand("gsNetworkShowObjects", "Toggle network show objects", "consoleCommandToggleNetworkShowObjects", self)
    return self
end
function Server:delete()
    removeConsoleCommand("gsNetworkShowTraffic")
    removeConsoleCommand("gsNetworkShowTrafficClients")
    removeConsoleCommand("gsNetworkDebug")
    removeConsoleCommand("gsNetworkShowObjects")
    Server:superClass().delete(self)
    self:stop()
end
function Server:update(dt, isRunning)
    Server:superClass().update(self, dt)
    if not isRunning then
        return
    end
    self:updateActiveObjects(dt)
    self.tickSum = self.tickSum + dt
    local currentFPS = MathUtil.round(1000 / dt, 0)
    local maxUploadSize = self.serverFPS
    self.serverFPS = math.min(maxUploadSize, currentFPS)
    if self.tickSum >= self.tickDuration - 3 then
        local numClients = #self.clients
        local i = g_maxUploadRatePerClient
        local streamId = numClients ~= 0 and g_maxUploadRate / numClients or g_maxUploadRate
        local maxUploadSize = math.min(i, streamId) * 8 * self.tickSum
        if self.networkListener ~= nil then
            self.networkListener:onConnectionsUpdateTick(self.tickSum)
        end
        self:updateActiveObjectsTick(self.tickSum)
        local i = 1
        for i = i, #self.clients do
            local streamId = self.clients[i]
            local connection = self.clientConnections[streamId]
            if connection.isReadyForObjects then
                if connection:getIsWindowFull() then
                    if not connection.ackPingPacketSent then
                        connection.ackPingPacketSent = true
                        streamWriteUIntN(streamId, MessageIds.OBJECT_PING, MessageIds.SEND_NUM_BITS)
                        connection:writeUpdateAck(streamId)
                        netSendStream(streamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
                    end
                else
                    connection:updateSendStats(self.tickSum)
                    connection.ackPingPacketSent = false
                    self.currentWriteStreamConnection = connection
                    local pendingDeleteObjects = connection.pendingDeleteObjects
                    local sendInfos = table.create(30)
                    local x, y, z = self:getClientPosition(streamId)
                    local coeff = self:getClientClipDistCoeff(streamId)
                    local isGuiVisible = self:getClientGuiVisibility(streamId)
                    local numObjects = 0
                    for _, object in pairs(self.objects) do
                        local objectInfo = connection.objectsInfo[object.id]
                        if objectInfo ~= nil then
                            objectInfo.dirtyMask = bit32.bor(objectInfo.dirtyMask, object.dirtyMask)
                        end
                        if objectInfo == nil then
                            local testScope = object.testScope
                            if testScope == nil or testScope(object, x, y, z, coeff, isGuiVisible) then
                                local updatePriority = object:getUpdatePriority(2, x, y, z, coeff, connection, isGuiVisible)
                                table.insert(sendInfos, {
                                    ["id"] = Connection.SEND_INFO_CREATE,
                                    ["object"] = object,
                                    ["prio"] = updatePriority
                                })
                            end
                        elseif objectInfo.sync == Connection.SYNC_LOADED then
                            local testScope = object.testScope
                            if testScope == nil or testScope(object, x, y, z, coeff, isGuiVisible) then
                                local updatePriority = object:getUpdatePriority(2, x, y, z, coeff, connection)
                                table.insert(sendInfos, {
                                    ["id"] = Connection.SEND_INFO_SYNC,
                                    ["object"] = object,
                                    ["prio"] = updatePriority
                                })
                            end
                        elseif objectInfo.sync == Connection.SYNC_CREATED then
                            local testScope = object.testScope
                            if testScope == nil or testScope(object, x, y, z, coeff, isGuiVisible) then
                                if objectInfo.dirtyMask == 0 then
                                    objectInfo.skipCount = 0
                                else
                                    objectInfo.skipCount = objectInfo.skipCount + 1
                                    local updatePriority = object:getUpdatePriority(objectInfo.skipCount, x, y, z, coeff, connection, isGuiVisible)
                                    table.insert(sendInfos, {
                                        ["id"] = Connection.SEND_INFO_UPDATE,
                                        ["object"] = object,
                                        ["prio"] = updatePriority
                                    })
                                end
                            else
                                objectInfo.skipCount = objectInfo.skipCount + 1
                                local updatePriority = object:getUpdatePriority(objectInfo.skipCount, x, y, z, coeff, connection, isGuiVisible)
                                table.insert(sendInfos, {
                                    ["id"] = Connection.SEND_INFO_REMOVE,
                                    ["object"] = object,
                                    ["prio"] = updatePriority
                                })
                            end
                        end
                    end
                    for _ in pairs(pendingDeleteObjects) do
                        table.insert(sendInfos, {
                            ["id"] = Connection.SEND_INFO_DELETE,
                            ["objectId"] = _,
                            ["prio"] = 100
                        })
                    end
                    table.sort(sendInfos, Server.prioCmp)
                    streamWriteTimestamp(streamId)
                    streamWriteUIntN(streamId, MessageIds.OBJECT_UPDATE, MessageIds.SEND_NUM_BITS)
                    streamWriteInt32(streamId, g_physicsNetworkTime)
                    connection:writeUpdateAck(streamId)
                    local clampedFPS = math.clamp(self.serverFPS, 1, 60)
                    streamWriteUIntN(streamId, clampedFPS, 6)
                    streamWriteBool(streamId, g_networkDebug)
                    if self.networkListener ~= nil then
                        self.networkListener:onConnectionWriteUpdateStream(connection, maxUploadSize * connection.compressionRatio, g_networkDebug)
                    end
                    local numInfosOffset = streamGetWriteOffset(streamId)
                    streamWriteUInt8(streamId, 0)
                    local _ = #sendInfos
                    local numInfosSent = math.min(_, 255)
                    local objectInfo = 1
                    local object = 1
                    for objectInfo = objectInfo, numInfosSent, object do
                        local testScope = streamGetWriteOffset(streamId)
                        local updatePriority = sendInfos[objectInfo]
                        local startOffset = nil
                        if g_networkDebug then
                            startOffset = streamGetWriteOffset(streamId)
                            streamWriteInt32(streamId, 0)
                        end
                        local object = updatePriority.object
                        local infoId = updatePriority.id
                        streamWriteUIntN(streamId, infoId, Connection.SEND_INFO_NUM_BITS)
                        if infoId == Connection.SEND_INFO_DELETE then
                            NetworkUtil.writeNodeObjectId(streamId, updatePriority.objectId)
                            pendingDeleteObjects[updatePriority.objectId] = nil
                            connection.pendingDeleteObjectPacketIds[updatePriority.objectId] = connection.lastSeqSent
                        elseif infoId == Connection.SEND_INFO_CREATE then
                            streamWriteUIntN(streamId, object.classId, ObjectIds.SEND_NUM_BITS)
                            NetworkUtil.writeNodeObjectId(streamId, object.id)
                            object:writeStream(streamId, connection)
                            local syncState = Connection.SYNC_CREATING
                            if object:getIsDelayedLoaded() then
                                syncState = Connection.SYNC_CREATING_DELAYED
                            end
                            objectsInfo[object.id] = {
                                ["skipCount"] = 0,
                                ["dirtyMask"] = 0,
                                ["sync"] = syncState,
                                ["history"] = {}
                            }
                            objectsInfo[object.id].history[connection.lastSeqSent] = {
                                ["mask"] = 0,
                                ["sync"] = Connection.SYNC_HIST_CREATE
                            }
                        elseif infoId == Connection.SEND_INFO_SYNC then
                            NetworkUtil.writeNodeObjectId(streamId, object.id)
                            object:postWriteStream(streamId, connection)
                            objectsInfo[object.id].sync = Connection.SYNC_SYNCING
                            objectsInfo[object.id].history[connection.lastSeqSent] = {
                                ["mask"] = 0,
                                ["sync"] = Connection.SYNC_HIST_SYNC
                            }
                        elseif infoId == Connection.SEND_INFO_UPDATE then
                            local syncState = objectsInfo[object.id]
                            local dirtyMask = syncState.dirtyMask
                            NetworkUtil.writeNodeObjectId(streamId, object.id)
                            object:writeUpdateStream(streamId, connection, dirtyMask)
                            syncState.history[connection.lastSeqSent] = {
                                ["mask"] = dirtyMask,
                                ["sync"] = Connection.SYNC_HIST_UPDATE
                            }
                            syncState.skipCount = 0
                            syncState.dirtyMask = 0
                        else
                            local syncState = objectsInfo[object.id]
                            NetworkUtil.writeNodeObjectId(streamId, object.id)
                            syncState.sync = Connection.SYNC_REMOVING
                            syncState.history[connection.lastSeqSent] = {
                                ["mask"] = 0,
                                ["sync"] = Connection.SYNC_HIST_REMOVE
                            }
                        end
                        if g_networkDebug then
                            local syncState = streamGetWriteOffset(streamId)
                            streamSetWriteOffset(streamId, startOffset)
                            streamWriteInt32(streamId, syncState - (startOffset + 32))
                            streamSetWriteOffset(streamId, syncState)
                        end
                        local syncState = streamGetWriteOffset(streamId)
                        self:addPacketSize(connection, self:getObjectPacketType(object), (syncState - testScope) / 8)
                        if g_networkDebugPrints and infoId == Connection.SEND_INFO_UPDATE then
                            local dirtyMask = ""
                            if object.configFileName ~= nil then
                                dirtyMask = "(" .. object.configFileName .. ")"
                            end
                            print("  send object " .. dirtyMask .. ", size " .. (syncState - testScope) / 8 .. " bytes")
                        end
                        if maxPacketSize < syncState then
                            numInfosSent = objectInfo
                            break
                        end
                    end
                    local _ = streamGetWriteOffset(streamId)
                    streamSetWriteOffset(streamId, numInfosOffset)
                    streamWriteUInt8(streamId, numInfosSent)
                    streamSetWriteOffset(streamId, _)
                    netSendStream(streamId, "medium", "unreliable_sequenced", NetworkNode.CHANNEL_MAIN, true)
                    self.currentWriteStreamConnection = nil
                end
            end
        end
        if self.networkListener ~= nil then
            self.networkListener:onFinishedClientsWriteUpdateStream()
        end
        for streamId, connection in pairs(self.objects) do
            if connection.dirtyMask ~= 0 then
                connection:clearDirtyMask()
            end
        end
        self:updatePacketStats(self.tickSum)
        self.tickSum = 0
        self.serverFPS = currentFPS
    end
end
function Server:startLocal()
    if g_client ~= nil then
        self.clientConnections[NetworkNode.LOCAL_STREAM_ID] = Connection.new(NetworkNode.LOCAL_STREAM_ID, false)
        self.clientConnections[NetworkNode.LOCAL_STREAM_ID]:setIsReadyForObjects(true)
        self.clientConnections[NetworkNode.LOCAL_STREAM_ID]:setIsReadyForEvents(true)
    end
end
function Server:start(serverPort, serverAddress, maxConnections)
    if not self.netIsRunning then
        self.netIsRunning = true
        print("Started network game (" .. serverPort .. ")")
        if not g_connectionManager:startup(serverPort, serverAddress, maxConnections) then
            printError("Error: Failed to startup network. Probably the select port is already in use")
        end
        g_connectionManager:setDefaultListener(Server.packetReceived, self)
        if g_client ~= nil then
            self.clientConnections[NetworkNode.LOCAL_STREAM_ID] = Connection.new(NetworkNode.LOCAL_STREAM_ID, false)
        end
        if g_isDevelopmentVersion then
            CaptionUtil.addText("- Server")
        end
    end
end
function Server:init()
    EventIds.assignEventIds()
    ObjectIds.assignObjectClassIds()
end
function Server:stop()
    if self.netIsRunning then
        for streamId in ipairs(self.clients) do
            if entityExists(streamId) then
                netCloseConnection(streamId, true, 1)
            end
        end
        self.clients = {}
        for streamId, connection in pairs(self.clientConnections) do
            connection.isConnected = false
            connection:setIsReadyForObjects(false)
            connection:setIsReadyForEvents(false)
        end
        self.clientConnections = {}
        g_connectionManager:shutdown()
        g_connectionManager:setDefaultListener(nil, nil)
        self.netIsRunning = false
    end
end
function Server:closeConnection(connection, disconnectReason)
    if connection.isConnected then
        self:removeStreamFromClients(connection.streamId)
        if self.networkListener ~= nil then
            self.networkListener:onConnectionClosed(connection, disconnectReason)
        end
        if connection.streamId ~= 0 and entityExists(connection.streamId) then
            netCloseConnection(connection.streamId, true, 1)
        end
        connection.streamId = 0
    end
end
function Server:packetReceived(packetType, timestamp, streamId)
    Server:superClass().packetReceived(self, packetType, timestamp, streamId)
    if packetType == Network.TYPE_APPLICATION then
        local messageId = streamReadUIntN(streamId, MessageIds.SEND_NUM_BITS)
        if messageId == MessageIds.OBJECT_CREATED then
            local connection = self.clientConnections[streamId]
            if connection ~= nil then
                local objectClassId = streamReadUIntN(streamId, ObjectIds.SEND_NUM_BITS)
                local clientObjectId = NetworkUtil.readNodeObjectId(streamId)
                local objectClass = ObjectIds.getObjectClassById(objectClassId)
                if objectClass ~= nil then
                    objectClass.new(true, g_client ~= nil):readStream(streamId, connection)
                    tempObject.isManuallyReplicated = false
                    tempObject.isRegistered = true
                    self:addObject(tempObject, tempObject.id)
                    connection.objectsInfo[tempObject.id] = {
                        ["skipCount"] = 0,
                        ["dirtyMask"] = 0,
                        ["sync"] = Connection.SYNC_CREATING,
                        ["history"] = {}
                    }
                    streamWriteUIntN(streamId, MessageIds.OBJECT_SERVER_ID, MessageIds.SEND_NUM_BITS)
                    NetworkUtil.writeNodeObjectId(streamId, tempObject.id)
                    NetworkUtil.writeNodeObjectId(streamId, clientObjectId)
                    netSendStream(streamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
                    return
                end
            end
        elseif messageId == MessageIds.OBJECT_SERVER_ID_ACK then
            local connection = self.clientConnections[streamId]
            if connection ~= nil then
                local objectsInfo = NetworkUtil.readNodeObjectId(streamId)
                local objectClassId = connection.objectsInfo[objectsInfo]
                if objectClassId ~= nil and objectClassId.sync == Connection.SYNC_CREATING then
                    objectClassId.sync = Connection.SYNC_CREATED
                    connection:sendObjectEventQueue(objectClassId)
                    return
                end
            end
        elseif messageId == MessageIds.OBJECT_LOADED then
            local connection = self.clientConnections[streamId]
            if connection ~= nil then
                local objectsInfo = streamReadUInt8(streamId)
                for objectClass = 1, objectsInfo do
                    local tempObject = NetworkUtil.readNodeObjectId(streamId)
                    local objectInfo = connection.objectsInfo[tempObject]
                    if objectInfo ~= nil and objectInfo.sync == Connection.SYNC_CREATING_DELAYED then
                        objectInfo.sync = Connection.SYNC_LOADED
                    end
                end
                return
            end
        elseif messageId == MessageIds.OBJECT_DELETED then
            local connection = self.clientConnections[streamId]
            if connection ~= nil then
                local objectsInfo = NetworkUtil.readNodeObjectId(streamId)
                local objectClassId = self:getObject(objectsInfo)
                if objectClassId ~= nil then
                    for objectInfo, connectionI in pairs(self.clientConnections) do
                        connectionI:notifyObjectDeleted(objectsInfo, connectionI == connection)
                    end
                    self:unregisterObject(objectClassId, true)
                    objectClassId:delete()
                    return
                end
            end
        elseif messageId == MessageIds.OBJECT_UPDATE then
            local connection = self.clientConnections[streamId]
            if connection ~= nil then
                connection:readUpdateAck(streamId)
                local objectsInfo = streamReadUInt8(streamId)
                local objectClassId = streamReadBool(streamId)
                self:setClientPosition(streamId, streamReadFloat32(streamId), streamReadFloat32(streamId), (streamReadFloat32(streamId)))
                self:setClientGuiVisibility(streamId, objectClassId)
                local i = 1
                for i = i, objectsInfo do
                    local objectId = NetworkUtil.readNodeObjectId(streamId)
                    if objectId == nil then
                        Logging.devError("Server: Unable to retrieve object id for object index %d of %d", i, objectsInfo)
                        return
                    end
                    local object = self:getObject(objectId)
                    if object == nil then
                        Logging.devError("Server: Trying to readUpdateStream from not registered object with id \'%d\'", objectId)
                        return
                    end
                    object:readUpdateStream(streamId, timestamp, connection)
                    object:raiseActive()
                end
                voiceChatReadClientUpdateFromStream(connection.streamId, g_clientInterpDelay, connection.streamId, connection.lastSeqSent)
                return
            end
        elseif messageId == MessageIds.OBJECT_PING then
            local connection = self.clientConnections[streamId]
            if connection ~= nil then
                connection:readUpdateAck(streamId)
                streamWriteUIntN(streamId, MessageIds.OBJECT_ACK, MessageIds.SEND_NUM_BITS)
                connection:writeUpdateAck(streamId)
                netSendStream(streamId, "medium", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
                return
            end
        elseif messageId == MessageIds.OBJECT_ACK then
            local connection = self.clientConnections[streamId]
            if connection ~= nil then
                connection:readUpdateAck(streamId)
                return
            end
        else
            if messageId ~= MessageIds.EVENT then
                if messageId == MessageIds.CLIP_COEFF then
                    local connection = streamReadFloat32(streamId)
                    self:setClientClipDistCoeff(self.clientConnections[streamId], connection)
                else
                    printError(string.format("Error: Invalid message id \'%s", messageId))
                end
            end
            local connection = streamReadUIntN(streamId, EventIds.SEND_NUM_BITS)
            local objectsInfo = EventIds.getEventClassById(connection)
            if objectsInfo == nil then
                Logging.devError("Could not resolve id \'%s\' to an event class", connection)
                return
            end
            local objectClassId = streamReadBool(streamId)
            local clientObjectId = nil
            local objectClass = 0
            if objectClassId then
                objectClass = streamGetReadOffset(streamId)
                clientObjectId = streamReadInt32(streamId)
            end
            local tempObject = objectsInfo.emptyNew()
            tempObject:readStream(streamId, self.clientConnections[streamId])
            tempObject:delete()
            if objectClassId then
                if not entityExists(streamId) then
                    Logging.devError("Could not validate read bits because stream was already closed by event \'%s\'", ClassUtil.getClassName(objectsInfo))
                    return
                end
                local connectionI = streamGetReadOffset(streamId) - (objectClass + 32)
                if connectionI ~= clientObjectId then
                    local i = ClassUtil.getClassNameByObject(objectsInfo)
                    printError("Error: Not all bits read in event (" .. connectionI .. " vs " .. clientObjectId .. "), Class: " .. tostring(i))
                    return
                end
            end
        end
    elseif packetType == Network.TYPE_NEW_INCOMING_CONNECTION then
        if self.clientConnections[streamId] == nil then
            table.insert(self.clients, streamId)
            self.clientConnections[streamId] = Connection.new(streamId, false)
            for objectClassId, clientObjectId in pairs(self.objects) do
                if clientObjectId.isManuallyReplicated then
                    self.clientConnections[streamId].objectsInfo[clientObjectId.id] = {
                        ["skipCount"] = 0,
                        ["dirtyMask"] = 0,
                        ["sync"] = Connection.SYNC_MANUALLY_REGISTERED,
                        ["manuallyReplicated"] = true,
                        ["history"] = {}
                    }
                end
            end
            if self.networkListener ~= nil then
                self.networkListener:onConnectionOpened(self.clientConnections[streamId])
                return
            end
        end
    elseif packetType == Network.TYPE_DISCONNECTION_NOTIFICATION then
        local messageId = self.clientConnections[streamId]
        self:removeStreamFromClients(streamId)
        if messageId ~= nil and self.networkListener ~= nil then
            self.networkListener:onConnectionClosed(messageId, DisconnectReason.PLAYER_LEFT)
            return
        end
    elseif packetType == Network.TYPE_CONNECTION_ATTEMPT_FAILED or (packetType == Network.TYPE_CONNECTION_LOST or (packetType == Network.TYPE_CONNECTION_BANNED or packetType == Network.TYPE_INVALID_PASSWORD)) then
        local messageId = self.clientConnections[streamId]
        self:removeStreamFromClients(streamId)
        if messageId ~= nil and self.networkListener ~= nil then
            local connection = nil
            if packetType == Network.TYPE_CONNECTION_LOST then
                connection = DisconnectReason.PLAYER_LOST_CONNECTION
            elseif packetType == Network.TYPE_CONNECTION_BANNED then
                connection = DisconnectReason.BANNED
            end
            self.networkListener:onConnectionClosed(messageId, connection)
        end
    end
end
function Server:removeStreamFromClients(streamId)
    local i = 1
    for i = i, #self.clients do
        if self.clients[i] == streamId then
            table.remove(self.clients, i)
            break
        end
    end
    if self.clientConnections[streamId] ~= nil then
        self.clientConnections[streamId].isConnected = false
        self.clientConnections[streamId]:setIsReadyForEvents(false)
        self.clientConnections[streamId]:setIsReadyForObjects(false)
        self.clientConnections[streamId] = nil
    end
end
function Server:registerObject(object, alreadySent)
    if object.isRegistered then
        Logging.warning("Server:registerObject() object %s %d %s already registered", object, object.id, ClassUtil.getClassNameByObject(object))
    else
        object.isRegistered = true
        self:addObject(object, object.id)
        object.isManuallyReplicated = alreadySent
        if alreadySent then
            for streamId, connection in pairs(self.clientConnections) do
                if streamId ~= NetworkNode.LOCAL_STREAM_ID then
                    connection.objectsInfo[object.id] = {
                        ["skipCount"] = 0,
                        ["dirtyMask"] = 0,
                        ["sync"] = Connection.SYNC_MANUALLY_REGISTERED,
                        ["manuallyReplicated"] = true,
                        ["history"] = {}
                    }
                end
            end
            return
        end
    end
end
function Server:unregisterObject(object, alreadySent)
    if object.isRegistered then
        local objectId = object.id
        if self.objects[objectId] ~= nil then
            self:removeObject(object, object.id)
            for _, connection in pairs(self.clientConnections) do
                connection:notifyObjectDeleted(objectId, alreadySent)
            end
        end
        object.isRegistered = false
    end
end
function Server:broadcastEvent(event, sendLocal, ignoreConnection, ghostObject, force, connectionList, allowQueuing)
    for streamId, connection in pairs(connectionList or self.clientConnections) do
        if (streamId ~= NetworkNode.LOCAL_STREAM_ID or sendLocal) and (ignoreConnection == nil or connection ~= ignoreConnection) then
            if ghostObject == nil or self:hasGhostObject(connection, ghostObject) then
                self.currentSendEventConnection = connection
                connection:sendEvent(event, false, force)
                self.currentSendEventConnection = nil
            elseif ghostObject ~= nil and allowQueuing then
                connection:queueSendEvent(event, force, ghostObject)
            end
        end
    end
    if event.queueCount == 0 then
        event:delete()
    end
end
function Server.sendEventIds(_, connection)
    local streamId = connection.streamId
    streamWriteUIntN(streamId, MessageIds.EVENT_IDS, MessageIds.SEND_NUM_BITS)
    local numIds = 0
    for _, _ in pairs(EventIds.eventClasses) do

    end
    streamWriteInt32(streamId, numIds)
    for _, _ in pairs(EventIds.eventClasses) do
        streamWriteUIntN(streamId, _.eventId, EventIds.SEND_NUM_BITS)
        streamWriteString(streamId, _)
    end
    netSendStream(streamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
end
function Server.sendObjectClassIds(_, connection)
    local streamId = connection.streamId
    streamWriteUIntN(streamId, MessageIds.OBJECT_CLASS_IDS, MessageIds.SEND_NUM_BITS)
    local numIds = 0
    for _, _ in pairs(ObjectIds.objectClasses) do

    end
    streamWriteInt32(streamId, numIds)
    for _, _ in pairs(ObjectIds.objectClasses) do
        streamWriteUIntN(streamId, _.classId, ObjectIds.SEND_NUM_BITS)
        streamWriteString(streamId, _)
    end
    netSendStream(streamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
end
function Server:sendObjects(connection, x, y, z, viewDistanceCoeff)
    connection:setIsReadyForObjects(false)
    self:setCurrentReliableWriteStreamConnection(connection)
    local streamId = connection.streamId
    streamWriteUIntN(streamId, MessageIds.OBJECT_INITIAL_ARRAY, MessageIds.SEND_NUM_BITS)
    streamWriteBool(streamId, g_networkDebug)
    local numToSendOffset = streamGetWriteOffset(streamId)
    streamWriteInt32(streamId, 0)
    local numToSend = 0
    for _, object in pairs(self.objects) do
        if connection.objectsInfo[object.id] == nil and not object.isManuallyReplicated then
            local testScope = object.testScope
            if testScope == nil or testScope(object, x, y, z, viewDistanceCoeff, true) then
                local startOffset = 0
                if g_networkDebug then
                    startOffset = streamGetWriteOffset(streamId)
                    streamWriteInt32(streamId, 0)
                end
                streamWriteUIntN(streamId, object.classId, ObjectIds.SEND_NUM_BITS)
                NetworkUtil.writeNodeObjectId(streamId, object.id)
                object:writeStream(streamId, connection)
                local syncState = Connection.SYNC_CREATED
                if object:getIsDelayedLoaded() then
                    syncState = Connection.SYNC_CREATING_DELAYED
                end
                objectsInfo[object.id] = {
                    ["skipCount"] = 0,
                    ["dirtyMask"] = 0,
                    ["sync"] = syncState,
                    ["history"] = {}
                }
                if g_networkDebug then
                    local endOffset = streamGetWriteOffset(streamId)
                    streamSetWriteOffset(streamId, startOffset)
                    streamWriteInt32(streamId, endOffset - (startOffset + 32))
                    streamSetWriteOffset(streamId, endOffset)
                end
            end
        end
    end
    local endOffset = streamGetWriteOffset(streamId)
    streamSetWriteOffset(streamId, numToSendOffset)
    streamWriteInt32(streamId, numToSend)
    streamSetWriteOffset(streamId, endOffset)
    netSendStream(streamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
    self:setCurrentReliableWriteStreamConnection(nil)
end
function Server:setClientPosition(client, x, y, z)
    if self.clientPositions[client] == nil then
        self.clientPositions[client] = { x, y, z }
    end
    self.clientPositions[client][1] = x
    self.clientPositions[client][2] = y
    self.clientPositions[client][3] = z
end
function Server:getClientPosition(client)
    local pos = self.clientPositions[client]
    if pos == nil then
        return 0, 0, 0
    else
        return unpack(pos)
    end
end
function Server:setClientGuiVisibility(client, isGuiVisible)
    if client ~= nil then
        self.clientGuiVisibility[client] = isGuiVisible
    end
end
function Server:getClientGuiVisibility(client)
    if self.clientGuiVisibility[client] == nil then
        return false
    else
        return self.clientGuiVisibility[client]
    end
end
function Server:setClientClipDistCoeff(client, coeff)
    if client ~= nil then
        self.clientClipDistCoeffs[client] = coeff
    end
end
function Server:getClientClipDistCoeff(client)
    local ret = self.clientClipDistCoeffs[client]
    return ret == nil and 1 or ret
end
function Server.hasGhostObject(_, connection, ghostObject)
    if connection:getIsLocal() then
        return true
    end
    local objectInfo = connection.objectsInfo[ghostObject.id]
    return objectInfo ~= nil and objectInfo.sync == Connection.SYNC_CREATED
end
function Server.finishRegisterObject(_, connection, object)
    local objectInfo = connection.objectsInfo[object.id]
    if objectInfo ~= nil and objectInfo.sync == Connection.SYNC_MANUALLY_REGISTERED then
        objectInfo.sync = Connection.SYNC_CREATED
        connection:sendObjectEventQueue(objectInfo)
    end
end
function Server:setCurrentReliableWriteStreamConnection(connection)
    self.currentReliableWriteStreamConnection = connection
end
function Server:registerObjectInStream(connection, object)
    if self.currentReliableWriteStreamConnection == connection or self.currentWriteStreamConnection == connection then
        if object:getIsDelayedLoaded() and not object.finishedLoading then
            printError("Error: Server:registerObjectInStream is only allowed for finished delayed loaded objects")
            printCallstack()
        else
            local objectInfo = connection.objectsInfo[object.id]
            if objectInfo ~= nil and objectInfo.sync == Connection.SYNC_MANUALLY_REGISTERED then
                if self.currentReliableWriteStreamConnection == connection then
                    objectInfo.sync = Connection.SYNC_CREATED
                else
                    objectInfo.sync = Connection.SYNC_CREATING
                    objectInfo.history[connection.lastSeqSent] = {
                        ["mask"] = 0,
                        ["sync"] = Connection.SYNC_HIST_CREATE
                    }
                end
                objectInfo.dirtyMask = 0
                objectInfo.skipCount = 0
            end
        end
    else
        printError("Error: Server:registerObjectInStream is only allowed in writeStream calls or reliable events on the main channel")
        printCallstack()
        return
    end
end
function Server.prioCmp(w1, w2)
    return w1.prio > w2.prio
end
function Server:consoleCommandToggleNetworkDebug()
    g_networkDebug = not g_networkDebug
    return "NetworkDebug = " .. tostring(g_networkDebug)
end