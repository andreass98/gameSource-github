NetworkNode = {}
local NetworkNode_mt = Class(NetworkNode)
NetworkNode.LOCAL_STREAM_ID = 0
NetworkNode.PACKET_EVENT = 1
NetworkNode.PACKET_VEHICLE = 2
NetworkNode.PACKET_PLAYER = 3
NetworkNode.PACKET_SPLITSHAPES = 4
NetworkNode.PACKET_DENSITY_MAPS = 5
NetworkNode.PACKET_TERRAIN_DEFORM = 6
NetworkNode.PACKET_VOICE_CHAT = 7
NetworkNode.PACKET_PLACEABLE = 8
NetworkNode.PACKET_HANDTOOL = 9
NetworkNode.PACKET_TRAFFICSYSTEM = 10
NetworkNode.PACKET_OTHERS = 11
NetworkNode.NUM_PACKETS = 11
NetworkNode.CHANNEL_MAIN = 1
NetworkNode.CHANNEL_SECONDARY = 2
NetworkNode.CHANNEL_CHAT = 3
NetworkNode.CHANNEL_TERRAIN_DEFORMATION = 4
NetworkNode.OBJECT_SEND_NUM_BITS = 24
function NetworkNode.new(customMt)
    -- upvalues: (copy) NetworkNode_mt
    local self = setmetatable({}, customMt or NetworkNode_mt)
    self.objects = {}
    self.objectIds = {}
    self.activeObjects = {}
    self.activeObjectsNextFrame = {}
    self.removedObjects = {}
    self.dirtyObjects = {}
    self.lastUploadedKBs = 0
    self.lastUploadedKBsSmooth = 0
    self.maxUploadedKBs = 0
    self.serverFPS = 60
    self.graphData = {}
    self.graphData[NetworkNode.PACKET_EVENT] = {
        ["color"] = {
            1,
            0,
            0,
            1
        },
        ["title"] = "event"
    }
    self.graphData[NetworkNode.PACKET_VEHICLE] = {
        ["color"] = {
            0,
            1,
            0,
            1
        },
        ["title"] = "vehicle"
    }
    self.graphData[NetworkNode.PACKET_PLAYER] = {
        ["color"] = {
            0,
            0,
            1,
            1
        },
        ["title"] = "player"
    }
    self.graphData[NetworkNode.PACKET_SPLITSHAPES] = {
        ["color"] = {
            1,
            1,
            0,
            1
        },
        ["title"] = "split shapes"
    }
    self.graphData[NetworkNode.PACKET_DENSITY_MAPS] = {
        ["color"] = {
            0.5,
            0.5,
            0,
            1
        },
        ["title"] = "density maps"
    }
    self.graphData[NetworkNode.PACKET_TERRAIN_DEFORM] = {
        ["color"] = {
            0.5,
            0.5,
            0.5,
            1
        },
        ["title"] = "terrain deform"
    }
    self.graphData[NetworkNode.PACKET_VOICE_CHAT] = {
        ["color"] = {
            1,
            0.5,
            0.5,
            1
        },
        ["title"] = "voice chat"
    }
    self.graphData[NetworkNode.PACKET_PLACEABLE] = {
        ["color"] = {
            1,
            0.2,
            0.2,
            1
        },
        ["title"] = "placeable"
    }
    self.graphData[NetworkNode.PACKET_HANDTOOL] = {
        ["color"] = {
            1,
            1,
            0.2,
            1
        },
        ["title"] = "handTool"
    }
    self.graphData[NetworkNode.PACKET_TRAFFICSYSTEM] = {
        ["color"] = {
            1,
            0.2,
            1,
            1
        },
        ["title"] = "traffic system"
    }
    self.graphData[NetworkNode.PACKET_OTHERS] = {
        ["color"] = {
            0,
            1,
            1,
            1
        },
        ["title"] = "others"
    }
    self.packetGraphs = {}
    self.connectionPacketGraphs = {}
    self.packetBytes = {}
    local i = 1
    for i = i, NetworkNode.NUM_PACKETS do
        local showGraphLabels = i == 1
        self.packetGraphs[i] = Graph.new(80, 0.4, 0.05, 0.55, 0.8, 0, 1000, showGraphLabels, "bytes (max)")
        local color = self.graphData[i].color
        self.packetGraphs[i]:setColor(color[1], color[2], color[3], color[4])
        if showGraphLabels then
            self.packetGraphs[i]:setHorizontalLine(1000, false, 1, 1, 1, 0.2)
            self.packetGraphs[i]:setBackgroundColor(0.2, 0.2, 0.2, 0.3)
        end
        self.packetBytes[i] = {}
        self.connectionPacketGraphs[i] = {}
    end
    self.showNetworkTraffic = false
    self.showNetworkTrafficClients = false
    self.showObjects = false
    self.updateDurationTimer = 0
    self.updateDurationFrames = 0
    self.updateDurationTotalTime = 0
    return self
end
function NetworkNode:delete()
    g_debugManager:removeDrawable(self)
    for _, object in pairs(self.objects) do
        self:unregisterObject(object, true)
        object:delete()
    end
    self.objects = {}
    self.objectIds = {}
    self.activeObjects = {}
    self.activeObjectsNextFrame = {}
    self.removedObjects = {}
    self.dirtyObjects = {}
    for _, object in pairs(self.connectionPacketGraphs) do
        for connection, graph in pairs(object) do
            graph:delete()
            object[connection] = nil
        end
    end
    local i = 1
    for i = i, NetworkNode.NUM_PACKETS do
        self.packetGraphs[i]:delete()
    end
end
function NetworkNode:setNetworkListener(listener)
    self.networkListener = listener
end
function NetworkNode:update(dt) end
function NetworkNode:updateActiveObjects(dt)
    for id, object in pairs(self.removedObjects) do
        self.activeObjects[id] = nil
        self.activeObjectsNextFrame[id] = nil
        self.removedObjects[id] = nil
    end
    if self.showObjects then
        for object, object in pairs(self.activeObjects) do
            local startTime = getTimeSec()
            if object.recieveUpdates then
                object:update(dt)
            end
            object.profilerUpdateCounter = (object.profilerUpdateCounter or 0) + (getTimeSec() - startTime)
        end
        self.updateDurationTimer = self.updateDurationTimer + dt
        self.updateDurationFrames = self.updateDurationFrames + 1
        if self.updateDurationTimer >= 1000 then
            self.updateDurationTotalTime = 0
            for object, object in pairs(activeObjects) do
                object.profilerUpdateTime = object.profilerUpdateCounter * 1000 / self.updateDurationFrames
                object.profilerUpdateCounter = 0
                self.updateDurationTotalTime = self.updateDurationTotalTime + object.profilerUpdateTime
            end
            self.updateDurationTimer = 0
            self.updateDurationFrames = 0
            return
        end
    else
        for object, object in pairs(activeObjects) do
            if object.recieveUpdates then
                object:update(dt)
            end
        end
    end
end
function NetworkNode:updateActiveObjectsTick(dt)
    local i = #self.dirtyObjects
    for i = i, 1, -1 do
        self.dirtyObjects[i] = nil
    end
    for serverId, object in pairs(self.activeObjects) do
        if object.recieveUpdates then
            object:updateTick(dt)
        end
        if object.dirtyMask ~= 0 then
            object.lastServerId = object._serverId or serverId
            table.insert(self.dirtyObjects, object)
        end
        local id = self.objectIds[object]
        self.activeObjects[id] = nil
        if object.recieveUpdates and self.activeObjectsNextFrame[id] == nil then
            object:updateEnd(dt)
        end
    end
    self.activeObjects = self.activeObjectsNextFrame
    self.activeObjectsNextFrame = self.activeObjects
    return self.dirtyObjects
end
function NetworkNode.drawConnectionNetworkStats(_, connection, posX, posY, textSize)
    if connection.streamId == NetworkNode.LOCAL_STREAM_ID then
        return false
    end
    local refTextSize = getCorrectTextSize(0.01)
    if not connection.isConnected then
        renderText(posX, posY, textSize, "Not connected")
        return false
    end
    local ping, download, upload, packetLoss = netGetConnectionStats(connection.streamId)
    if ping == nil then
        ping = 0
        download = 0
        upload = 0
        packetLoss = 0
    end
    if connection.pingSmooth == nil then
        connection.pingSmooth = ping
        connection.downloadSmooth = download
        connection.uploadSmooth = upload
        connection.packetLossSmooth = packetLoss
    end
    connection.pingSmooth = connection.pingSmooth + (ping - connection.pingSmooth) * 0.2
    connection.downloadSmooth = connection.downloadSmooth + (download - connection.downloadSmooth) * 0.2
    connection.uploadSmooth = connection.uploadSmooth + (upload - connection.uploadSmooth) * 0.2
    connection.packetLossSmooth = connection.packetLossSmooth + (packetLoss - connection.packetLossSmooth) * 0.2
    local ping = connection.pingSmooth
    local download = connection.downloadSmooth
    local upload = connection.uploadSmooth
    local packetLoss = connection.packetLossSmooth
    renderText(posX, posY, textSize, string.format("%dms", ping))
    renderText(posX + 0.016 * (textSize / refTextSize), posY, textSize, string.format("w:%2d", connection.lastSeqSent - connection.highestAckedSeq))
    renderText(posX + 0.029 * (textSize / refTextSize), posY, textSize, string.format("d:%4.2fkb/s", download / 1024))
    renderText(posX + 0.061 * (textSize / refTextSize), posY, textSize, string.format("u:%4.2fkb/s", upload / 1024))
    renderText(posX + 0.093 * (textSize / refTextSize), posY, textSize, string.format("loss:%4.2f%%", packetLoss * 100))
    renderText(posX + 0.126 * (textSize / refTextSize), posY, textSize, string.format("comp:%.2f%%", 1 / connection.compressionRatio * 100))
    return true
end
function NetworkNode.getObjectPacketType(_, object)
    if object == nil then
        return NetworkNode.PACKET_OTHERS
    elseif object:isa(Vehicle) then
        return NetworkNode.PACKET_VEHICLE
    elseif object:isa(Player) then
        return NetworkNode.PACKET_PLAYER
    elseif object:isa(Placeable) then
        return NetworkNode.PACKET_PLACEABLE
    elseif object:isa(HandTool) then
        return NetworkNode.PACKET_HANDTOOL
    elseif object:isa(TrafficSystem) then
        return NetworkNode.PACKET_TRAFFICSYSTEM
    else
        return NetworkNode.PACKET_OTHERS
    end
end
function NetworkNode.getPacketTypeName(_, packetType)
    for key, value in pairs(Network) do
        if value == packetType then
            return key
        end
    end
    return "TYPE_UNKNOWN"
end
function NetworkNode.checkObjectUpdateDebugReadSize(_, streamId, numBits, startOffset, name, object)
    local readNumBits = streamGetReadOffset(streamId) - (startOffset + 32)
    if readNumBits ~= numBits then
        local objectInfo = ""
        if object ~= nil then
            objectInfo = ": " .. object.className
            if object.configFileName ~= nil then
            end
        end
        printError("Error: Not all bits read in object " .. name .. " (" .. readNumBits .. " vs " .. numBits .. ")" .. objectInfo)
    end
end
function NetworkNode:addPacketSize(connection, packetType, packetSizeInBytes)
    if self.showNetworkTraffic or self.showNetworkTrafficClients then
        self.packetBytes[packetType][connection] = (self.packetBytes[packetType][connection] or 0) + packetSizeInBytes
    end
end
function NetworkNode:updatePacketStats(dt)
    if self.showNetworkTraffic or self.showNetworkTrafficClients then
        local packetBytesSum = 0
        local i = 1
        for i = i, NetworkNode.NUM_PACKETS do
            local connections = self.packetBytes[i]
            local totalPacketBytes = 0
            for connection, bytes in pairs(connections) do
                if self.clientConnections ~= nil and self.clientConnections[connection.streamId] == nil then
                    connections[connection] = nil
                    if self.connectionPacketGraphs[i][connection] ~= nil then
                        self.connectionPacketGraphs[i][connection]:delete()
                        self.connectionPacketGraphs[i][connection] = nil
                    end
                end
                if connections[connection] ~= nil then
                    if self.connectionPacketGraphs[i][connection] == nil then
                        local showGraphLabels = i == 1
                        self.connectionPacketGraphs[i][connection] = Graph.new(80, 0, 0, 0.15, 0.25, 0, 7500, showGraphLabels, "bytes", nil, nil, nil, getCorrectTextSize(0.008))
                        local color = self.graphData[i].color
                        self.connectionPacketGraphs[i][connection]:setColor(color[1], color[2], color[3], color[4])
                        if showGraphLabels then
                            self.connectionPacketGraphs[i][connection]:setHorizontalLine(1000, false, 1, 1, 1, 0.3)
                            self.connectionPacketGraphs[i][connection]:setBackgroundColor(0.2, 0.2, 0.2, 0.3)
                        end
                    end
                    if ({})[connection] == nil then
                        connectionSum[connection] = 0
                    end
                    self.connectionPacketGraphs[i][connection]:addValue(connectionSum[connection] + bytes, connectionSum[connection])
                    connectionSum[connection] = connectionSum[connection] + bytes
                    connections[connection] = 0
                end
            end
            self.packetGraphs[i]:addValue(packetBytesSum + totalPacketBytes, packetBytesSum)
            packetBytesSum = packetBytesSum + totalPacketBytes
        end
        local i = 1
        for i = i, NetworkNode.NUM_PACKETS do
            self.packetGraphs[i].maxValue = math.max(self.packetGraphs[i].maxValue, packetBytesSum)
        end
        self.lastUploadedKBs = packetBytesSum / 1024 * 1000 / dt
    end
end
function NetworkNode:drawGraphLabels(x, y, textSize)
    local i = 1
    for i = i, NetworkNode.NUM_PACKETS do
        local data = self.graphData[i]
        setTextColor(unpack(data.color))
        renderText(x, y + (i - 1) * textSize, textSize, data.title)
    end
    setTextColor(1, 1, 1, 1)
end
function NetworkNode:drawDebug()
    if self.showNetworkTraffic then
        self.lastUploadedKBsSmooth = self.lastUploadedKBsSmooth * 0.8 + self.lastUploadedKBs * 0.19999999999999996
        setTextColor(1, 1, 1, 1)
        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(0.01, 0.8, getCorrectTextSize(0.015), string.format("Game Data Upload %.2fkb/s ", self.lastUploadedKBsSmooth))
        local alpha = math.clamp(self.serverFPS / 60, 0, 1)
        setTextColor(1 - alpha, alpha, 0, 1)
        renderText(0.01, 0.82, getCorrectTextSize(0.015), string.format("Server: %d FPS", self.serverFPS))
        setTextColor(1, 1, 1, 1)
        self:drawGraphLabels(self.packetGraphs[1].left - 0.15, self.packetGraphs[1].bottom, getCorrectTextSize(0.02))
        local i = 1
        local textSize = NetworkNode.NUM_PACKETS
        local i = 1
        for i = i, textSize, i do
            self.packetGraphs[i]:draw()
        end
        local textSize = getCorrectTextSize(0.014)
        if self.clientConnections == nil then
            if self.serverConnection ~= nil then
                self:drawConnectionNetworkStats(self.serverConnection, 0.01, 0.8 - textSize * 1.1, textSize)
            end
        else
            local i = 1
            for _, connection in pairs(self.clientConnections) do
                local posY = 0.78 - i * textSize * 1.1
                if self:drawConnectionNetworkStats(connection, 0.01, posY, textSize) then
                    local user = g_currentMission.userManager:getUserByConnection(connection)
                    if user ~= nil then
                        renderText(0.255, posY, textSize, user:getNickname())
                    end
                end
            end
        end
    end
    if self.showNetworkTrafficClients and self.clientConnections ~= nil then
        local r = 0.04
        local g = 0.7
        local x = getCorrectTextSize(0.01)
        for i, connection in pairs(self.clientConnections) do
            local hasGraph = false
            local posY = 1
            local connection = 1
            for posY = posY, NetworkNode.NUM_PACKETS, connection do
                local user = self.connectionPacketGraphs[posY][connection]
                if user ~= nil then
                    user.left = r
                    user.bottom = g + 0.015
                    local activeG = false
                    if posY == 1 then
                        activeG = r == 0.04
                    end
                    user.showLabels = activeG
                    self.connectionPacketGraphs[posY][connection]:draw()
                    hasGraph = true
                end
            end
            if hasGraph then
                self:drawConnectionNetworkStats(connection, r, g, x)
                local _ = userManager:getUserByConnection(connection)
                if _ ~= nil then
                    renderText(r, g - 0.011, x, _:getNickname())
                end
                r = r + 0.16
                if r + 0.16 > 1 then
                    r = 0.04
                end
            end
        end
        self:drawGraphLabels(0.8, 0.1, getCorrectTextSize(0.02))
    end
    if self.showObjects then
        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_LEFT)
        local smoothAlpha = 0
        for x, y in pairs(self.activeObjects) do
            y.debugServerId = self.objectIds[y] or -1
        end
        local alpha = {}
        for y, textSize in pairs(self.objects) do
            textSize.debugServerId = self.objectIds[textSize] or -1
            local i = textSize.debugClassName
            if not i then
                i = tostring(ClassUtil.getClassNameByObject(textSize))
            end
            textSize.debugClassName = i
            table.insert(alpha, textSize)
        end
        local r = self.debugSortByClassName
        table.sort(alpha, function(a, b)
            -- upvalues: (copy) r
            if r and a.debugClassName ~= b.debugClassName then
                return a.debugClassName < b.debugClassName
            else
                return a.debugServerId < b.debugServerId
            end
        end)
        local g = 0.015
        local x = 0.96
        local y = string.format("Registered Objects: %d | Objects in update-loop: %d | Update time: %.3f ms", #alpha, smoothAlpha, self.updateDurationTotalTime)
        setTextColor(0, 0, 0, 1)
        renderText(g + g_pixelSizeX, 0.98 + g_pixelSizeY, 0.013, y)
        setTextColor(1, 1, 1, 1)
        renderText(g, 0.98, 0.013, y)
        for connection, hasGraph in ipairs(alpha) do
            if hasGraph.networkDebugFilename == nil then
                local _ = hasGraph.configFileName or hasGraph.xmlFilename
                if _ == nil then
                    hasGraph.networkDebugFilename = "<unknown file>"
                else
                    hasGraph.networkDebugFilename = Utils.getFilenameFromPath(_)
                end
            end
            local connection = hasGraph.debugServerId
            local _ = tostring(connection)
            local connection = string.format
            local user = hasGraph.debugClassName
            local connection = connection(" - %s - %s", user, (tostring(hasGraph.networkDebugFilename)))
            local posY = self.activeObjects[hasGraph.debugServerId] ~= nil
            local user = 0.1254
            local activeG = 0.7647
            if hasGraph.profilerUpdateTime ~= nil then
                connection = string.format("%s (%.3f ms)", connection, hasGraph.profilerUpdateTime)
                user = math.clamp(hasGraph.profilerUpdateTime / 1, 0, 1)
                activeG = 1 - user
            end
            setTextBold(posY)
            setTextColor(0, 0, 0, 1)
            renderText(g + g_pixelSizeX, x + g_pixelSizeY, 0.01, connection)
            setTextAlignment(RenderText.ALIGN_RIGHT)
            renderText(g + g_pixelSizeX, x + g_pixelSizeY, 0.01, _)
            if posY then
                setTextColor(user, activeG, 0, 1)
            else
                setTextColor(1, 1, 1, 1)
            end
            renderText(g, x, 0.01, _)
            setTextAlignment(RenderText.ALIGN_LEFT)
            renderText(g, x, 0.01, connection)
            x = x - 0.011
            if x < 0 then
                x = 0.96
            end
        end
        setTextBold(false)
        setTextColor(1, 1, 1, 1)
    end
end
function NetworkNode:packetReceived(packetType, timestamp, streamId) end
function NetworkNode:getObject(id)
    return self.objects[id]
end
function NetworkNode:getObjectId(object)
    return self.objectIds[object]
end
function NetworkNode:addObject(object, id)
    self.objects[id] = object
    self.objectIds[object] = id
    self:addObjectToUpdateLoop(object)
    if self.networkListener ~= nil then
        self.networkListener:onObjectCreated(object)
    end
end
function NetworkNode:removeObject(object, id)
    self:removeObjectFromUpdateLoop(object)
    if self.networkListener ~= nil then
        self.networkListener:onObjectDeleted(object)
    end
    self.objects[id] = nil
    self.objectIds[object] = nil
end
function NetworkNode:addObjectToUpdateLoop(object)
    if object.isRegistered then
        local id = self.objectIds[object]
        if id ~= nil then
            self.activeObjects[id] = object
            self.activeObjectsNextFrame[id] = object
        end
    end
end
function NetworkNode:removeObjectFromUpdateLoop(object)
    local id = self.objectIds[object]
    if id ~= nil then
        self.removedObjects[id] = object
        self.activeObjects[id] = nil
        self.activeObjectsNextFrame[id] = nil
    end
end
function NetworkNode:registerObject(object, alreadySent) end
function NetworkNode:unregisterObject(object, alreadySent) end
function NetworkNode:consoleCommandToggleNetworkShowObjects(sortByClassName)
    self.showObjects = not self.showObjects
    self.debugSortByClassName = string.lower(sortByClassName or "true") == "true"
    if self.showObjects then
        g_debugManager:addDrawable(self)
    end
    return "NetworkShowObjects = " .. tostring(self.showObjects)
end
function NetworkNode:consoleCommandToggleShowNetworkTraffic()
    self.showNetworkTraffic = not self.showNetworkTraffic
    if self.showNetworkTraffic then
        g_debugManager:addDrawable(self)
    end
    return "ShowNetworkTraffic = " .. tostring(self.showNetworkTraffic)
end
function NetworkNode:consoleCommandToggleShowNetworkTrafficClients()
    self.showNetworkTrafficClients = not self.showNetworkTrafficClients
    if self.showNetworkTrafficClients then
        g_debugManager:addDrawable(self)
    end
    return "ShowNetworkTrafficClients = " .. tostring(self.showNetworkTrafficClients)
end