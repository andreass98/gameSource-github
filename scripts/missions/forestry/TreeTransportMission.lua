TreeTransportMission = {}
source("dataS/scripts/missions/forestry/TreeTransportMissionHotspot.lua")
source("dataS/scripts/missions/forestry/TreeTransportMissionTreeCutEvent.lua")
source("dataS/scripts/missions/forestry/TreeTransportMissionWrongSellingStationEvent.lua")
TreeTransportMission.NAME = "treeTransportMission"
local TreeTransportMission_mt = Class(TreeTransportMission, AbstractMission)
InitStaticObjectClass(TreeTransportMission, "TreeTransportMission")
function TreeTransportMission.registerXMLPaths(schema, key)
    TreeTransportMission:superClass().registerXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#maxNumInstances", "Max number of instances")
    schema:register(XMLValueType.INT, key .. "#rewardPerTree", "Reward per tree")
    schema:register(XMLValueType.INT, key .. "#penaltyPerTree", "Penalty per tree")
    schema:register(XMLValueType.STRING, key .. "#treeType", "Tree type")
    schema:register(XMLValueType.STRING, key .. ".spots#filename", "Filename to tree spots")
end
function TreeTransportMission.registerSavegameXMLPaths(schema, key)
    TreeTransportMission:superClass().registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#spotIndex", "Spot index")
    schema:register(XMLValueType.INT, key .. "#numTrees", "Number of trees")
    schema:register(XMLValueType.INT, key .. "#numDeliveredTrees", "Number of delivered trees")
    schema:register(XMLValueType.INT, key .. "#numDeletedTrees", "Number of deleted trees")
    schema:register(XMLValueType.INT, key .. ".tree(?)#splitShapePart1", "Part1 of the tree")
    schema:register(XMLValueType.INT, key .. ".tree(?)#splitShapePart2", "Part2 of the tree")
    schema:register(XMLValueType.INT, key .. ".tree(?)#splitShapePart3", "Part3 of the tree")
    schema:register(XMLValueType.VECTOR_TRANS, key .. ".tree(?)#position", "Position of the tree")
    schema:register(XMLValueType.VECTOR_ROT, key .. ".tree(?)#rotation", "Rotation of the tree")
    schema:register(XMLValueType.INT, key .. ".cutSplitShape(?)#splitShapePart1", "Part1 of the cut split shape")
    schema:register(XMLValueType.INT, key .. ".cutSplitShape(?)#splitShapePart2", "Part2 of the cut split shape")
    schema:register(XMLValueType.INT, key .. ".cutSplitShape(?)#splitShapePart3", "Part3 of the cut split shape")
    schema:register(XMLValueType.STRING, key .. ".sellingStation#uniqueId", "UniqueId of the selling station")
    schema:register(XMLValueType.INT, key .. ".sellingStation#unloadingStationIndex", "Index of the unloading station")
end
function TreeTransportMission.registerMetaXMLPaths(schema, key)
    TreeTransportMission:superClass().registerMetaXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#nextDay", "Earliest day a new mission can spawn")
end
function TreeTransportMission.new(isServer, isClient, customMt)
    -- upvalues: (copy) TreeTransportMission_mt
    local title = g_i18n:getText("contract_forestry_treeTransport_title")
    local description = g_i18n:getText("contract_forestry_treeTransport_description")
    local self = AbstractMission.new(isServer, isClient, title, description, customMt or TreeTransportMission_mt)
    self.spot = nil
    self.trees = {}
    self.pendingTrees = {}
    self.treeShapeToTree = {}
    self.cutSplitShapes = {}
    self.resolveServerIds = false
    self.hasCollision = false
    self.numDeliveredTrees = 0
    self.numDeletedTrees = 0
    self.numTrees = 0
    self.mapHotspot = nil
    self.isHotspotAdded = false
    self.pendingSellingStationId = nil
    self.sellingStation = nil
    g_messageCenter:subscribe(MessageType.SPLIT_SHAPE, self.onTreeShapeCut, self)
    local data = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
    table.addElement(data.activeMissions, self)
    return self
end
function TreeTransportMission:init(spot, sellingStation)
    if spot == nil then
        return false
    end
    self:setSpot(spot)
    if not self:canSpawnTrees() then
        return false
    end
    self.numTrees = getNumOfChildren(spot.node)
    local rewardPerTree = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME).rewardPerTree
    self.reward = self.numTrees * rewardPerTree
    self:setSellingStation(sellingStation)
    return TreeTransportMission:superClass().init(self)
end
function TreeTransportMission:onSavegameLoaded()
    if not self:getIsFinished() then
        local placeable = g_currentMission.placeableSystem:getPlaceableByUniqueId(self.sellingStationPlaceableUniqueId)
        if placeable == nil then
            Logging.error("Selling station placeable with uniqueId \'%s\' not available for tree transport mission", self.sellingStationPlaceableUniqueId)
            g_missionManager:markMissionForDeletion(self)
            return
        end
        local unloadingStation = g_currentMission.storageSystem:getPlaceableUnloadingStation(placeable, self.unloadingStationIndex)
        if unloadingStation == nil then
            Logging.error("Unable to retrieve unloadingStation %d for placeable %s for tree transport mission", self.unloadingStationIndex, placeable.configFileName)
            g_missionManager:markMissionForDeletion(self)
            return
        end
        self:setSellingStation(unloadingStation)
        if self:getWasStarted() then
            unloadingStation.missions[self] = self
        end
    end
    TreeTransportMission:superClass().onSavegameLoaded(self)
end
function TreeTransportMission:setSpot(spot)
    self.spot = spot
    spot.isInUse = true
    self.farmlandId = spot.farmlandId
    if self.mapHotspot == nil then
        self.mapHotspot = TreeTransportMissionHotspot.new()
    end
    self.mapHotspot:setWorldPosition(self.spot.x, self.spot.z)
    self.mapHotspots = { self.mapHotspot }
end
function TreeTransportMission:delete()
    self:removeHotspot()
    self:deleteTrees()
    g_messageCenter:unsubscribeAll(self)
    if self.spot ~= nil then
        self.spot.isInUse = false
        self.spot = nil
    end
    if self.mapHotspot ~= nil then
        self.mapHotspot:delete()
        self.mapHotspot = nil
    end
    if self.sellingStationMapHotspot ~= nil then
        self.sellingStationMapHotspot:delete()
        self.sellingStationMapHotspot = nil
    end
    if self.sellingStation ~= nil then
        self.sellingStation.missions[self] = nil
        self.sellingStation = nil
    end
    local data = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
    if data ~= nil then
        table.removeElement(data.activeMissions, self)
    end
    TreeTransportMission:superClass().delete(self)
end
function TreeTransportMission:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. "#numTrees", self.numTrees)
    TreeTransportMission:superClass().saveToXMLFile(self, xmlFile, key)
    xmlFile:setValue(key .. "#spotIndex", self.spot.index)
    xmlFile:setValue(key .. "#numDeliveredTrees", self.numDeliveredTrees)
    xmlFile:setValue(key .. "#numDeletedTrees", self.numDeletedTrees)
    if self:getWasRunning() then
        local i = 0
        for _, shape in ipairs(self.trees) do
            local treeKey = string.format("%s.tree(%d)", key, i)
            if entityExists(shape) then
                local splitShapePart1, splitShapePart2, splitShapePart3 = getSaveableSplitShapeId(shape)
                if splitShapePart1 ~= 0 then
                    xmlFile:setValue(treeKey .. "#splitShapePart1", splitShapePart1)
                    xmlFile:setValue(treeKey .. "#splitShapePart2", splitShapePart2)
                    xmlFile:setValue(treeKey .. "#splitShapePart3", splitShapePart3)
                    local x, y, z = getWorldTranslation(shape)
                    local rx, ry, rz = getWorldRotation(shape)
                    xmlFile:setValue(treeKey .. "#position", x, y, z)
                    xmlFile:setValue(treeKey .. "#rotation", rx, ry, rz)
                end
            end
        end
        local i = 0
        for _, shape in pairs(self.cutSplitShapes) do
            local treeKey = string.format("%s.cutSplitShape(%d)", key, i)
            if entityExists(_) then
                local splitShapePart1, splitShapePart2, splitShapePart3 = getSaveableSplitShapeId(_)
                if splitShapePart1 ~= 0 then
                    xmlFile:setValue(treeKey .. "#splitShapePart1", splitShapePart1)
                    xmlFile:setValue(treeKey .. "#splitShapePart2", splitShapePart2)
                    xmlFile:setValue(treeKey .. "#splitShapePart3", splitShapePart3)
                end
            end
        end
    end
    if self.sellingStation ~= nil then
        local i = self.sellingStation.owningPlaceable
        if i == nil then
            local sellPointName = self.sellingStation.getName and self.sellingStation:getName() or "unknown"
            Logging.xmlWarning(xmlFile, "Unable to retrieve placeable of sellPoint \'%s\' for saving tree transport mission \'%s\' ", sellPointName, key)
            return
        end
        local sellPointName = g_currentMission.storageSystem:getPlaceableUnloadingStationIndex(i, self.sellingStation)
        if sellPointName == nil then
            local sellPointName = self.sellingStation.getName and self.sellingStation:getName() or (i.getName and i:getName() or "unknown")
            Logging.xmlWarning(xmlFile, "Unable to retrieve unloading station index of sellPoint \'%s\' for saving tree transport mission \'%s\' ", sellPointName, key)
            return
        end
        xmlFile:setValue(key .. ".sellingStation#uniqueId", i:getUniqueId())
        xmlFile:setValue(key .. ".sellingStation#unloadingStationIndex", sellPointName)
    end
end
function TreeTransportMission:loadFromXMLFile(xmlFile, key)
    self.numTrees = xmlFile:getValue(key .. "#numTrees") or self.numTrees
    TreeTransportMission:superClass().loadFromXMLFile(self, xmlFile, key)
    local spotIndex = xmlFile:getValue(key .. "#spotIndex") or 0
    local spot = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME).spots[spotIndex]
    if spot == nil then
        return false
    end
    self:setSpot(spot)
    self.numDeliveredTrees = xmlFile:getValue(key .. "#numDeliveredTrees") or 0
    self.numDeletedTrees = xmlFile:getValue(key .. "#numDeletedTrees") or 0
    if self:getWasRunning() then
        self.pendingSavegameData = {
            ["trees"] = {},
            ["cutSplitShapes"] = {}
        }
        for _, treeKey in xmlFile:iterator(key .. ".tree") do
            local splitShapePart1 = xmlFile:getValue(treeKey .. "#splitShapePart1")
            local splitShapePart2 = xmlFile:getValue(treeKey .. "#splitShapePart2")
            local splitShapePart3 = xmlFile:getValue(treeKey .. "#splitShapePart3")
            local x, y, z = xmlFile:getValue(treeKey .. "#position")
            local rx, ry, rz = xmlFile:getValue(treeKey .. "#rotation")
            table.insert(self.pendingSavegameData.trees, {
                ["splitShapeId1"] = splitShapePart1,
                ["splitShapeId2"] = splitShapePart2,
                ["splitShapeId3"] = splitShapePart3,
                ["x"] = x or 0,
                ["y"] = y or 0,
                ["z"] = z or 0,
                ["rx"] = rx or 0,
                ["ry"] = ry or 0,
                ["rz"] = rz or 0
            })
        end
        for _, treeKey in xmlFile:iterator(key .. ".cutSplitShape") do
            local splitShapePart1 = xmlFile:getValue(treeKey .. "#splitShapePart1")
            local splitShapePart2 = xmlFile:getValue(treeKey .. "#splitShapePart2")
            local splitShapePart3 = xmlFile:getValue(treeKey .. "#splitShapePart3")
            table.insert(self.pendingSavegameData.cutSplitShapes, {
                ["splitShapePart1"] = splitShapePart1,
                ["splitShapePart2"] = splitShapePart2,
                ["splitShapePart3"] = splitShapePart3
            })
        end
    end
    if not self:getIsFinished() then
        local sellingStationPlaceableUniqueId = xmlFile:getValue(key .. ".sellingStation#uniqueId")
        if sellingStationPlaceableUniqueId == nil then
            Logging.xmlError(xmlFile, "No sellPointPlaceable uniqueId given for tree transport mission at \'%s\'", key)
            return false
        end
        local unloadingStationIndex = xmlFile:getValue(key .. ".sellingStation#unloadingStationIndex")
        if unloadingStationIndex == nil then
            Logging.xmlError(xmlFile, "No unloadting station index given for tree transport mission at \'%s\'", key)
            return false
        end
        self.sellingStationPlaceableUniqueId = sellingStationPlaceableUniqueId
        self.unloadingStationIndex = unloadingStationIndex
    end
    return true
end
function TreeTransportMission:writeStream(streamId, connection)
    streamWriteUInt8(streamId, self.numTrees)
    TreeTransportMission:superClass().writeStream(self, streamId, connection)
    streamWriteUInt8(streamId, self.spot.index)
    streamWriteUInt8(streamId, self.numDeletedTrees)
    streamWriteUInt8(streamId, self.numDeliveredTrees)
    streamWriteUInt8(streamId, #self.trees)
    for _, treeNode in ipairs(self.trees) do
        local treeExists = entityExists(treeNode)
        if streamWriteBool(streamId, treeExists) then
            writeSplitShapeIdToStream(streamId, treeNode)
        end
    end
    NetworkUtil.writeNodeObject(streamId, self.sellingStation)
end
function TreeTransportMission:readStream(streamId, connection)
    self.numTrees = streamReadUInt8(streamId)
    TreeTransportMission:superClass().readStream(self, streamId, connection)
    local spotIndex = streamReadUInt8(streamId)
    self:setSpot(g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME).spots[spotIndex])
    self.numDeletedTrees = streamReadUInt8(streamId)
    self.numDeliveredTrees = streamReadUInt8(streamId)
    local numTrees = streamReadUInt8(streamId)
    for i = 1, numTrees do
        if streamReadBool(streamId) then
            local entityId, splitShapeId1, splitShapeId2 = readSplitShapeIdFromStream(streamId)
            if entityId == 0 then
                if splitShapeId1 ~= 0 then
                    table.insert(self.pendingTrees, { splitShapeId1, splitShapeId2 })
                end
            else
                table.insert(self.trees, entityId)
            end
        end
    end
    self.pendingSellingStationId = NetworkUtil.readNodeObjectId(streamId)
    self.resolveServerIds = true
end
function TreeTransportMission:writeUpdateStream(streamId, connection, dirtyMask)
    TreeTransportMission:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
    streamWriteUInt8(streamId, self.numDeletedTrees)
    streamWriteUInt8(streamId, self.numDeliveredTrees)
end
function TreeTransportMission:readUpdateStream(streamId, timestamp, connection)
    TreeTransportMission:superClass().readUpdateStream(self, streamId, timestamp, connection)
    self.numDeletedTrees = streamReadUInt8(streamId)
    self.numDeliveredTrees = streamReadUInt8(streamId)
end
function TreeTransportMission:update(dt)
    if self.isServer then
        if self.pendingSellingStationId ~= nil then
            self:tryToResolveSellingStation()
        end
        if self.pendingSavegameData ~= nil then
            local found = false
            local numLoadedTrees = 0
            local numSavegameTrees = 0
            for _, data in ipairs(self.pendingSavegameData.trees) do
                if data.splitShapeId1 ~= nil then
                    local treeNode = getShapeFromSaveableSplitShapeId(data.splitShapeId1, data.splitShapeId2, data.splitShapeId3)
                    if treeNode ~= 0 then
                        found = true
                        setWorldTranslation(treeNode, data.x, data.y, data.z)
                        setWorldRotation(treeNode, data.rx, data.ry, data.rz)
                        local treeObj = TreeTransportMissionTree.new(self.isServer, self.isClient)
                        treeObj:setNodeId(treeNode)
                        treeObj:register()
                        self.treeShapeToTree[treeNode] = treeObj
                        table.insert(self.trees, treeNode)
                    end
                end
            end
            if found then
                self.numDeletedTrees = self.numDeletedTrees + (numSavegameTrees - numLoadedTrees)
            end
            for _, data in ipairs(self.pendingSavegameData.cutSplitShapes) do
                if data.splitShapeId1 ~= nil then
                    local treeNode = getShapeFromSaveableSplitShapeId(data.splitShapeId1, data.splitShapeId2, data.splitShapeId3)
                    if treeNode ~= 0 then
                        self.cutSplitShapes[treeNode] = true
                    end
                end
            end
            self.pendingSavegameData = nil
        end
        for numDeletedTrees, tree in pairs(self.treeShapeToTree) do
            if not entityExists(numDeletedTrees) then
                self:onMissionTreeCut(numDeletedTrees)
            end
        end
    end
    TreeTransportMission:superClass().update(self, dt)
    if not self.isServer and self.pendingTrees ~= nil then
        local numSavegameTrees = #self.pendingTrees
        for numSavegameTrees = numSavegameTrees, 1, -1 do
            local numDeletedTrees = self.pendingTrees[numSavegameTrees]
            local tree = resolveStreamSplitShapeId(numDeletedTrees[1], numDeletedTrees[2])
            if tree ~= 0 then
                table.remove(self.pendingTrees, numSavegameTrees)
                table.insert(self.trees, tree)
            end
        end
        if #self.pendingTrees == 0 then
            self.pendingTrees = nil
        end
    end
    if self.status == MissionStatus.RUNNING and (g_localPlayer ~= nil and (g_localPlayer.farmId == self.farmId and not self.isHotspotAdded)) then
        self:addHotspots()
    end
end
function TreeTransportMission:tryToResolveSellingStation()
    if self.pendingSellingStationId ~= nil and self.sellingStation == nil then
        local sellingStation = NetworkUtil.getObject(self.pendingSellingStationId)
        if sellingStation ~= nil then
            self:setSellingStation(sellingStation)
        end
    end
end
function TreeTransportMission:setSellingStation(sellingStation)
    if sellingStation ~= nil then
        self.pendingSellingStationId = nil
        self.sellingStation = sellingStation
        local placeable = sellingStation.owningPlaceable
        if placeable ~= nil and placeable.getHotspot ~= nil then
            local mapHotspot = placeable:getHotspot()
            if mapHotspot ~= nil then
                self.sellingStationMapHotspot = HarvestMissionHotspot.new()
                self.sellingStationMapHotspot:setWorldPosition(mapHotspot:getWorldPosition())
                table.addElement(self.mapHotspots, self.sellingStationMapHotspot)
                if self.addSellingStationHotSpot then
                    g_currentMission:addMapHotspot(self.sellingStationMapHotspot)
                end
            end
        end
    end
end
function TreeTransportMission:createTree(x, y, z, rx, ry, rz)
    local data = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
    local treeNode = g_treePlantManager:plantTree(data.treeIndex, x, y, z, rx, ry, rz, 1, 1, false, nil)
    if treeNode == nil then
        return nil
    end
    local splitShapeId = SplitShapeUtil.getSplitShapeId(treeNode)
    local treeObj = TreeTransportMissionTree.new(self.isServer, self.isClient)
    treeObj:setNodeId(splitShapeId)
    treeObj:register()
    self.treeShapeToTree[splitShapeId] = treeObj
    table.insert(self.trees, splitShapeId)
    return treeNode
end
function TreeTransportMission:deleteTrees()
    for _, tree in ipairs(self.trees) do
        if entityExists(tree) then
            local parent = getParent(tree)
            if entityExists(parent) then
                delete(parent)
            end
        end
    end
    for _, tree in pairs(self.cutSplitShapes) do
        if entityExists(_) then
            delete(_)
            self.cutSplitShapes[_] = nil
        end
    end
end
function TreeTransportMission:start(spawnVehicles)
    if self.pendingSellingStationId ~= nil then
        self:tryToResolveSellingStation()
    end
    if self.sellingStation == nil then
        return false
    else
        self.sellingStation.missions[self] = self
        if TreeTransportMission:superClass().start(self, spawnVehicles) then
            return self:canSpawnTrees() and true or false
        else
            return false
        end
    end
end
function TreeTransportMission:prepare(spawnVehicles)
    TreeTransportMission:superClass().prepare(self, spawnVehicles)
    if self.isServer then
        local i = 0
        for i = i, self.numTrees - 1 do
            local spawnNode = getChildAt(self.spot.node, i)
            local x, y, z = getWorldTranslation(spawnNode)
            local rx, ry, rz = getWorldRotation(spawnNode)
            self:createTree(x, y, z, rx, ry, rz)
        end
    end
end
function TreeTransportMission:finish(finishState)
    if self.sellingStation ~= nil then
        self.sellingStation.missions[self] = nil
        self.sellingStation = nil
    end
    self:removeHotspot()
    local mission = g_currentMission
    if mission:getFarmId() == self.farmId then
        if finishState == MissionFinishState.SUCCESS then
            mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("contract_forestry_treeTransport_finished"), self.farmlandId))
        elseif finishState == MissionFinishState.FAILED then
            mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_forestry_treeTransport_failed"), self.farmlandId))
        elseif finishState == MissionFinishState.TIMED_OUT then
            mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_forestry_treeTransport_timedOut"), self.farmlandId))
        end
    end
    TreeTransportMission:superClass().finish(self, finishState)
end
function TreeTransportMission:addHotspots()
    if self.mapHotspot ~= nil then
        self.isHotspotAdded = true
        g_currentMission:addMapHotspot(self.mapHotspot)
    end
    if self.sellingStationMapHotspot ~= nil then
        g_currentMission:addMapHotspot(self.sellingStationMapHotspot)
    end
    self.addSellingStationHotSpot = true
end
function TreeTransportMission:removeHotspot()
    if self.mapHotspot ~= nil then
        g_currentMission:removeMapHotspot(self.mapHotspot)
        self.isHotspotAdded = false
    end
    if self.sellingStationMapHotspot ~= nil then
        g_currentMission:removeMapHotspot(self.sellingStationMapHotspot)
    end
    self.addSellingStationHotSpot = false
end
function TreeTransportMission:onMissionTreeCut(splitShapeId)
    local tree = self.treeShapeToTree[splitShapeId]
    if tree ~= nil then
        tree:delete()
        self.treeShapeToTree[splitShapeId] = nil
        self.numDeletedTrees = self.numDeletedTrees + 1
        g_currentMission:broadcastEventToFarm(TreeTransportMissionTreeCutEvent.new(), self.farmId, true)
    end
end
function TreeTransportMission:onTreeShapeCut(shapeData, splitShapeData)
    if self.status == MissionStatus.RUNNING then
        if self.isServer then
            if self.treeShapeToTree[shapeData.shape] then
                self:onMissionTreeCut(shapeData.shape)
                for _, data in ipairs(splitShapeData) do
                    self.cutSplitShapes[data.shape] = true
                end
                return
            end
            if self.cutSplitShapes[shapeData.shape] ~= nil then
                for _, data in ipairs(splitShapeData) do
                    self.cutSplitShapes[data.shape] = true
                end
                return
            end
        end
    end
end
function TreeTransportMission:validate()
    local res = TreeTransportMission:superClass().validate(self)
    if res then
        local farmland = g_farmlandManager:getFarmlandById(self.farmlandId)
        if farmland == nil or farmland.isOwned then
            return false
        elseif self.sellingStation == nil or self.sellingStation.isRegistered then
            return res
        else
            return false
        end
    else
        return false
    end
end
function TreeTransportMission:getLocation()
    return string.format(g_i18n:getText("contract_farmland"), self.farmlandId)
end
function TreeTransportMission:getMapHotspots()
    return self.mapHotspots
end
function TreeTransportMission:getWorldPosition()
    local spot = self.spot
    if spot == nil then
        return g_farmlandManager:getFarmlandById(self.farmlandId):getIndicatorPosition()
    else
        return spot.x, spot.z
    end
end
function TreeTransportMission:getVehicleSize()
    local numTrees = self.numTrees
    return numTrees > 20 and "large" or (numTrees >= 10 and "medium" or "small")
end
function TreeTransportMission:getDetails()
    local details = TreeTransportMission:superClass().getDetails(self)
    local data = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
    table.insert(details, {
        ["title"] = g_i18n:getText("contract_details_farmland"),
        ["value"] = self.farmlandId
    })
    local title = nil
    if self.pendingSellingStationId ~= nil then
        self:tryToResolveSellingStation()
    end
    if self.sellingStation ~= nil then
        title = self.sellingStation:getName()
    end
    if title ~= nil then
        table.insert(details, {
            ["title"] = g_i18n:getText("contract_forestry_details_sellingStation"),
            ["value"] = title
        })
    end
    table.insert(details, {
        ["title"] = g_i18n:getText("contract_forestry_details_rewardPerTree"),
        ["value"] = g_i18n:formatMoney(data.rewardPerTree, 0, true)
    })
    table.insert(details, {
        ["title"] = g_i18n:getText("contract_forestry_details_penaltyPerTree"),
        ["value"] = g_i18n:formatMoney(data.penaltyPerTree, 0, true)
    })
    table.insert(details, {
        ["title"] = g_i18n:getText("contract_forestry_details_totalNumTrees"),
        ["value"] = self.numTrees - self.numDeletedTrees
    })
    if self.status ~= MissionStatus.CREATED then
        table.insert(details, {
            ["title"] = g_i18n:getText("contract_forestry_treeTransport_details_deliveredNumTrees"),
            ["value"] = self.numDeliveredTrees
        })
    end
    return details
end
function TreeTransportMission:getNPC()
    local farmland = g_farmlandManager:getFarmlandById(self.farmlandId)
    return g_npcManager:getNPCByIndex(farmland.npcIndex)
end
function TreeTransportMission:getExtraProgressText()
    local remaining = math.max(0, self.numTrees - (self.numDeliveredTrees + self.numDeletedTrees))
    return string.format(g_i18n:getText("contract_forestry_treeTransport_remainingTrees"), remaining)
end
function TreeTransportMission:getCompletion()
    return self.numTrees <= 0 and 1 or (self.numDeliveredTrees + self.numDeletedTrees) / self.numTrees
end
function TreeTransportMission:getReward()
    return self.reward
end
function TreeTransportMission:getFarmlandId()
    return self.farmlandId
end
function TreeTransportMission:calculateStealingCost()
    local data = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
    return data == nil and 0 or self.numDeletedTrees * data.penaltyPerTree
end
function TreeTransportMission:dismiss()
    if self.isServer then
        local change = 0
        if self.finishState == MissionFinishState.SUCCESS then
            change = self:getReward()
        end
        local change = change - self:calculateStealingCost()
        if change ~= 0 then
            g_currentMission:addMoney(change, self.farmId, MoneyType.MISSIONS, true, true)
        end
    end
end
function TreeTransportMission:getIsShapeCutAllowed(shape, _, _, _)
    if self.status == MissionStatus.CREATED or self.treeShapeToTree[shape] == nil then
        return nil
    else
        return false
    end
end
function TreeTransportMission:onTriggerProcessedWood(trigger, splitShapeId, _, _)
    if not self.isServer then
        return
    end
    if self.treeShapeToTree[splitShapeId] == nil then
        return
    end
    if self.pendingSellingStationId ~= nil then
        self:tryToResolveSellingStation()
    end
    local found = false
    if self.sellingStation ~= nil then
        local target = trigger:getTarget()
        while target ~= nil do
            if target == self.sellingStation then
                found = true
                break
            end
            if target.getTarget == nil then
                break
            end
            target = target:getTarget()
        end
    end
    if found then
        self.numDeliveredTrees = self.numDeliveredTrees + 1
    else
        g_currentMission:broadcastEventToFarm(TreeTransportMissionWrongSellingStationEvent.new(), self.farmId, true)
        self.numDeletedTrees = self.numDeletedTrees + 1
    end
    self.treeShapeToTree[splitShapeId]:delete()
    self.treeShapeToTree[splitShapeId] = nil
end
function TreeTransportMission:getIsMissionSplitShape(shape)
    if shape == nil or shape == 0 then
        return false
    elseif self.status == MissionStatus.RUNNING then
        return self.treeShapeToTree[shape] ~= nil
    else
        return false
    end
end
function TreeTransportMission:canSpawnTrees()
    local spot = self.spot
    local sizeX = spot.sizeX * 0.5
    local sizeY = spot.sizeY * 0.5
    local sizeZ = spot.sizeZ * 0.5
    local x, y, z = localToWorld(spot.node, sizeX - 0.15, sizeY - 0.15, sizeZ - 0.15)
    local rx, ry, rz = getWorldRotation(spot.node)
    self.hasCollision = false
    overlapBox(x, y, z, rx, ry, rz, sizeX + 0.15, sizeY + 0.15, sizeZ + 0.15, "onSpotCollision", self, CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.DYNAMIC_OBJECT, true, true, true, true)
    return not self.hasCollision
end
function TreeTransportMission:onSpotCollision(node)
    if node ~= g_terrainNode and not getHasTrigger(node) then
        self.hasCollision = true
    end
end
function TreeTransportMission:getMissionTypeName()
    return TreeTransportMission.NAME
end
function TreeTransportMission:onDeleteSellingStation(sellingStation)
    if sellingStation == self.sellingStation and (self.isServer and (self.status == MissionStatus.RUNNING and not g_currentMission.isExitingGame)) then
        Logging.warning("Finish tree transport mission because selling station was removed")
        self:finish(MissionFinishState.FAILED)
    end
end
function TreeTransportMission.loadMapData(xmlFile, key, baseDirectory)
    if xmlFile:hasProperty(key) then
        local treeTypeName = xmlFile:getString(key .. "#treeType")
        local treeDesc = g_treePlantManager:getTreeTypeDescFromName(treeTypeName)
        if treeDesc == nil then
            Logging.xmlWarning(xmlFile, "Missing or undefined treeType \'%s\' for treeTransport mission (%s)!", treeTypeName, key)
            return false
        end
        local spotFilename = xmlFile:getString(key .. ".spots#filename")
        if spotFilename == nil then
            Logging.xmlWarning(xmlFile, "Missing spot definition file for treeTransport mission (%s)", key)
            return false
        end
        local i3dNode = Utils.getFilename(spotFilename, baseDirectory)
        local i3dNode = g_i3DManager:loadI3DFile(i3dNode, false, false)
        if i3dNode == 0 then
            return false
        end
        local data = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
        data.spots = {}
        data.activeMissions = {}
        data.treeIndex = treeDesc.index
        data.maxNumInstances = xmlFile:getInt(key .. "#maxNumInstances") or 1
        data.rewardPerTree = xmlFile:getFloat(key .. "#rewardPerTree") or 255
        data.penaltyPerTree = xmlFile:getFloat(key .. "#penaltyPerTree") or 2000
        local root = getChildAt(i3dNode, 0)
        link(getRootNode(), root)
        local i = 0
        for i = i, getNumOfChildren(root) - 1 do
            local spotNode = getChildAt(root, i)
            local x, y, z = getTranslation(spotNode)
            local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
            local isValidFarmland = false
            if farmlandId ~= nil then
                isValidFarmland = farmlandId ~= FarmlandManager.NOT_BUYABLE_FARM_ID
            end
            if isValidFarmland then
                local sizeX = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z)
                local sizeX = tonumber(getUserAttribute(spotNode, "sizeX")) or 1
                local sizeY = tonumber(getUserAttribute(spotNode, "sizeY")) or 1
                table.insert(data.spots, {
                    ["node"] = spotNode,
                    ["index"] = #data.spots + 1,
                    ["x"] = x,
                    ["y"] = sizeX,
                    ["z"] = z,
                    ["isInUse"] = false,
                    ["farmlandId"] = farmlandId,
                    ["sizeX"] = sizeX,
                    ["sizeY"] = sizeY,
                    ["sizeZ"] = tonumber(getUserAttribute(spotNode, "sizeZ")) or 1
                })
            else
                local sizeX = "Not defined"
                if farmlandId == FarmlandManager.NOT_BUYABLE_FARM_ID then
                    sizeX = string.format("Not buyable (%d)", farmlandId)
                end
                Logging.xmlWarning(xmlFile, "Invalid farmland \'%s\' found for tree transport mission spot \'%s\' at %d %d!", sizeX, getName(spotNode), x, z)
            end
        end
        data.spotRoot = root
        delete(i3dNode)
        return true
    end
end
function TreeTransportMission.unloadMapData()
    local data = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
    if data ~= nil and data.spotRoot ~= nil then
        delete(data.spotRoot)
    end
end
function TreeTransportMission.loadMetaDataFromXMLFile(xmlFile, key)
    g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME).nextMissionDay = xmlFile:getValue(key .. "#nextDay")
end
function TreeTransportMission.saveMetaDataToXMLFile(xmlFile, key)
    local data = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
    if data.nextMissionDay ~= nil then
        xmlFile:setValue(key .. "#nextDay", data.nextMissionDay)
    end
end
function TreeTransportMission.getSellPointWithHighestPrice()
    local highestPrice = 0
    local sellPoint = nil
    for _, unloadingStation in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
        if unloadingStation.owningPlaceable ~= nil and (unloadingStation.isSellingPoint and (unloadingStation.allowMissions and unloadingStation.acceptedFillTypes[FillType.WOOD])) then
            local hasWoodUnloadTrigger = false
            for _, unloadTrigger in ipairs(unloadingStation.unloadTriggers) do
                if unloadTrigger:isa(WoodUnloadTrigger) then
                    hasWoodUnloadTrigger = true
                    break
                end
            end
            if hasWoodUnloadTrigger then
                local price = unloadingStation:getEffectiveFillTypePrice(FillType.WOOD)
                if highestPrice < price then
                    sellPoint = unloadingStation
                    highestPrice = price
                end
            end
        end
    end
    return sellPoint, highestPrice
end
function TreeTransportMission.tryGenerateMission()
    if TreeTransportMission.canRun() then
        local data = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
        local spots = data.spots
        Utils.shuffle(spots)
        for _, activeMission in ipairs(data.activeMissions) do
            ({})[activeMission.spot.farmlandId] = true
        end
        local foundSpot = nil
        for activeMission, spot in ipairs(spots) do
            if not spot.isInUse and (blockedFarmlands[spot.farmlandId] == nil and g_farmlandManager:getFarmlandOwner(spot.farmlandId) == FarmlandManager.NO_OWNER_FARM_ID) then
                foundSpot = spot
                break
            end
        end
        if not foundSpot then
            return
        end
        local sellPoint, _ = TreeTransportMission.getSellPointWithHighestPrice()
        if sellPoint == nil then
            return
        end
        local _ = TreeTransportMission.new
        local activeMission = true
        local spot = g_client ~= nil
        activeMission = activeMission(activeMission, spot)
        if activeMission:init(foundSpot, sellPoint) then
            activeMission:setEndDate(g_currentMission.environment.currentMonotonicDay + 2, MathUtil.hoursToMs(math.random(10, 18)))
            return activeMission
        end
        activeMission:delete()
    end
    return nil
end
function TreeTransportMission.canRun()
    local data = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
    if data.spots == nil then
        return false
    elseif #data.spots == 0 then
        return false
    elseif data.treeIndex == nil then
        return false
    elseif data.numInstances >= data.maxNumInstances then
        return false
    else
        return data.nextMissionDay == nil or g_currentMission.environment.currentMonotonicDay >= data.nextMissionDay
    end
end
g_missionManager:registerMissionType(TreeTransportMission, TreeTransportMission.NAME, 1)