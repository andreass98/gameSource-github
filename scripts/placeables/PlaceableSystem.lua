g_xmlManager:addInitSchemaFunction(function()
    Mission00.xmlSchema:register(XMLValueType.VECTOR_2, "map.placeableSystem.boundary.point(?)#translation", "Translation of the point")
end)
PlaceableSystem = {}
PlaceableSystem.TERRAIN_BORDER = 40
PlaceableSystem.UNIQUE_ID_PREFIX = "placeable"
local PlaceableSystem_mt = Class(PlaceableSystem)
function PlaceableSystem.new(mission, customMt)
    -- upvalues: (copy) PlaceableSystem_mt
    local self = setmetatable({}, customMt or PlaceableSystem_mt)
    self.mission = mission
    self.placeables = {}
    self.placableByUniqueId = {}
    self.pendingPlaceableLoadingData = {}
    self.preplacedPlaceableData = {}
    self.uniqueIdToReplacedPlaceableData = {}
    self.placeablesToDelete = {}
    self.weatherStations = {}
    self.farmhouses = {}
    self.bunkerSilos = {}
    self.boundary = nil
    self.version = 1
    self.isReloadRunning = false
    if self.mission:getIsServer() and g_addTestCommands then
        addConsoleCommand("gsPlaceablesDeleteAll", "Deletes all placeables", "consoleCommandDeleteAllPlaceables", self, nil, true)
        addConsoleCommand("gsPlaceablesReloadAll", "Reloads all placeables", "consoleCommandReloadAllPlaceables", self)
        addConsoleCommand("gsPlaceablesLoadAll", "Loads all placeables", "consoleCommandLoadAllPlaceables", self, nil, true)
    end
    if g_addTestCommands then
        addConsoleCommand("gsPlaceablesPendingLoadings", "Prints the pending placeable loadings", "consoleCommandPrintPendingLoadings", self)
        addConsoleCommand("gsPlaceableSystemDrawBoundary", "Draws the placeable map boundaries", "consoleCommandDrawMapBoundaries", self)
    end
    return self
end
function PlaceableSystem:loadMapData(xmlFileHandle, _, _)
    local xmlFile = XMLFile.wrap(xmlFileHandle)
    if xmlFile ~= nil then
        if xmlFile:hasProperty("map.placeableSystem.boundary") then
            local boundary = {}
            for _, pointKey in xmlFile:iterator("map.placeableSystem.boundary.point") do
                local point = xmlFile:getVector(pointKey .. "#translation", nil, 2)
                if point ~= nil then
                    table.insert(boundary, point)
                end
            end
            if #boundary >= 3 then
                self.boundary = boundary
            else
                Logging.error("PlaceableSystem: Boundary must have at least 3 points, found %d", #boundary)
            end
        end
        xmlFile:delete()
    end
end
function PlaceableSystem:delete()
    local i = #self.pendingPlaceableLoadingData
    for i = i, 1, -1 do
        self.pendingPlaceableLoadingData[i]:cancelLoading()
    end
    for k, placeable in pairs(self.placeablesToDelete) do
        placeable:delete(true)
        self.placeablesToDelete[k] = nil
    end
    local i = #self.placeables
    for i = i, 1, -1 do
        self.placeables[i]:delete(true)
    end
    if self.savegameXMLFile ~= nil then
        self.savegameXMLFile:delete()
        self.savegameXMLFile = nil
    end
    self.mission = nil
    self.boundary = nil
    self.placeables = {}
    self.savegameIdToPlaceable = {}
    self.farmhouses = {}
    self.bunkerSilos = {}
    self.preplacedPlaceableData = {}
    self.uniqueIdToReplacedPlaceableData = {}
    removeConsoleCommand("gsPlaceablesDeleteAll")
    removeConsoleCommand("gsPlaceablesReloadAll")
    removeConsoleCommand("gsPlaceablesLoadAll")
    removeConsoleCommand("gsPlaceablesPendingLoadings")
    removeConsoleCommand("gsPlaceableSystemDrawBoundary")
end
function PlaceableSystem:deleteAll()
    local i = #self.placeables
    for i = i, 1, -1 do
        self.placeables[i]:delete()
    end
    return #self.placeables
end
function PlaceableSystem:draw()
    if PlaceableSystem.DEBUG_DRAW_BOUNDARIES then
        if self.boundary ~= nil then
            local i = 1
            for i = i, #self.boundary - 1 do
                local point = self.boundary[i]
                local nextPoint = self.boundary[i + 1]
                local pH = getTerrainHeightAtWorldPos(g_terrainNode, point[1], 0, point[2])
                local npH = getTerrainHeightAtWorldPos(g_terrainNode, nextPoint[1], 0, nextPoint[2])
                drawDebugLine(point[1], pH, point[2], 1, 0, 0, nextPoint[1], npH, nextPoint[2], 1, 0, 0, false)
            end
            return
        end
        local limit = g_currentMission.terrainSize * 0.5 - PlaceableSystem.TERRAIN_BORDER
        local e1x = -limit
        local i = -limit
        local nextPoint = -limit
        local e4x = -limit
        local e1y = getTerrainHeightAtWorldPos(g_terrainNode, e1x, 0, i)
        local e2y = getTerrainHeightAtWorldPos(g_terrainNode, limit, 0, nextPoint)
        local e3y = getTerrainHeightAtWorldPos(g_terrainNode, limit, 0, limit)
        local e4y = getTerrainHeightAtWorldPos(g_terrainNode, e4x, 0, limit)
        drawDebugLine(e1x, e1y, i, 1, 0, 0, limit, e2y, nextPoint, 1, 0, 0, false)
        drawDebugLine(limit, e2y, nextPoint, 1, 0, 0, limit, e3y, limit, 1, 0, 0, false)
        drawDebugLine(limit, e3y, limit, 1, 0, 0, e4x, e4y, limit, 1, 0, 0, false)
        drawDebugLine(e4x, e4y, limit, 1, 0, 0, e1x, e1y, i, 1, 0, 0, false)
    end
end
function PlaceableSystem:limitPositionToBoundary(x, z)
    if self.boundary == nil then
        local limit = g_currentMission.terrainSize * 0.5 - PlaceableSystem.TERRAIN_BORDER
        x = math.clamp(x, -limit, limit)
        z = math.clamp(z, -limit, limit)
    elseif not FieldCourseUtil.getIsPointInsideBoundary(x, z, self.boundary) then
        x, z = FieldCourseUtil.getClosestPositionOnBoundary(x, z, self.boundary)
    end
    if PlaceableSystem.DEBUG_DRAW_BOUNDARIES then
        self:draw()
        local limit = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
        drawDebugArrow(x, limit, z, 0, 0, 1, 0, 1, 0, 0, 1, 0, false)
    end
    return x, z
end
function PlaceableSystem:getIsInsideBoundary(x, z)
    if self.boundary == nil then
        local limit = g_currentMission.terrainSize * 0.5 - PlaceableSystem.TERRAIN_BORDER
        if x < -limit or limit < x then
            return false
        else
            return z >= -limit and limit >= z
        end
    else
        return FieldCourseUtil.getIsPointInsideBoundary(x, z, self.boundary)
    end
end
function PlaceableSystem:readStreamPreplacedInfo(streamId, _)
    local numPreplacedPlaceables = streamReadUInt16(streamId)
    local i = 1
    for i = i, numPreplacedPlaceables do
        if streamReadBool(streamId) then
            self:deletePreplacedPlaceable(self.preplacedPlaceableData[i])
        end
    end
end
function PlaceableSystem:writeStreamPreplacedInfo(streamId, _)
    streamWriteUInt16(streamId, #self.preplacedPlaceableData)
    for _, data in ipairs(self.preplacedPlaceableData) do
        streamWriteBool(streamId, data.isDeleted)
    end
end
function PlaceableSystem:addMapPlaceableNode(nodeId)
    Logging.devInfo("Adding preplaced map placeable \'%s\'", getName(nodeId))
    if nodeId == nil then
        Logging.error("No node given for validation")
        return
    elseif getNumOfChildren(nodeId) == 0 then
        Logging.error("Node \'%s\' is not a valid preplaced placeable node. No children defined", I3DUtil.getNodePath(nodeId))
        return
    else
        local uniqueId = getUserAttribute(nodeId, "uniqueId")
        if string.isNilOrWhitespace(uniqueId) then
            Logging.error("Node \'%s\' is not a valid preplaced placeable node. Missing uniqueId attribute", I3DUtil.getNodePath(nodeId))
            return
        else
            local xmlFilename = getUserAttribute(nodeId, "xmlFilename")
            if string.isNilOrWhitespace(xmlFilename) then
                Logging.error("Node \'%s\' is not a valid preplaced placeable node. Missing xmlFilename attribute", I3DUtil.getNodePath(nodeId))
                return
            else
                local xmlFile = Utils.getFilename(xmlFilename, g_currentMission.loadingMapBaseDirectory)
                local xmlFile = XMLFile.load("Preplaced Placeable", xmlFile, Placeable.xmlSchema)
                if xmlFile == nil then
                    Logging.error("Node \'%s\' is not a valid preplaced placeable node. Cannot open config xml file", I3DUtil.getNodePath(nodeId))
                    return
                else
                    xmlFile:delete()
                    local boughtWithFarmlandOverwrite = getUserAttribute(nodeId, "boughtWithFarmlandOverwrite") or false
                    local customImageFilename = getUserAttribute(nodeId, "customImageFilename")
                    local node = getChildAt(nodeId, 0)
                    if getNumOfChildren(node) == 0 then
                        Logging.error("Node \'%s\' is not a valid preplaced placeable node. No child nodes for \'placeable\' transform group", I3DUtil.getNodePath(nodeId))
                    else
                        local data = {
                            ["index"] = #self.preplacedPlaceableData + 1,
                            ["rootNode"] = nodeId,
                            ["node"] = node,
                            ["xmlFilename"] = xmlFile,
                            ["uniqueId"] = uniqueId,
                            ["foundInSavegame"] = false,
                            ["isDeleted"] = false,
                            ["boughtWithFarmlandOverwrite"] = boughtWithFarmlandOverwrite,
                            ["customImageFilename"] = customImageFilename
                        }
                        table.insert(self.preplacedPlaceableData, data)
                        self.uniqueIdToReplacedPlaceableData[uniqueId] = data
                    end
                end
            end
        end
    end
end
function PlaceableSystem:addPlaceable(placeable)
    if placeable == nil or placeable:isa(Placeable) == nil then
        Logging.error("Given object is not a placeable")
        return
    else
        local uniqueId = placeable:getUniqueId()
        if uniqueId == nil or self.placableByUniqueId[uniqueId] == nil then
            if uniqueId == nil then
                uniqueId = Utils.getUniqueId(placeable, self.placableByUniqueId, PlaceableSystem.UNIQUE_ID_PREFIX)
                placeable:setUniqueId(uniqueId)
            end
            g_messageCenter:publish(MessageType.PLACEABLE_ADDED, placeable)
            table.addElement(self.placeables, placeable)
            self.placableByUniqueId[uniqueId] = placeable
        else
            Logging.warning("Tried to add existing placeable with unique id of %s! Existing: %s, new: %s", uniqueId, tostring(self.placableByUniqueId[uniqueId]), (tostring(placeable)))
        end
    end
end
function PlaceableSystem:removePlaceable(placeable)
    table.removeElement(self.placeables, placeable)
    local uniqueId = placeable:getUniqueId()
    if uniqueId ~= nil then
        self.placableByUniqueId[uniqueId] = nil
    end
    g_messageCenter:publish(MessageType.PLACEABLE_REMOVED, placeable)
end
function PlaceableSystem:addPreplacedPlaceable(placeable)
    local uniqueId = placeable:getUniqueId()
    local preplacedData = self.uniqueIdToReplacedPlaceableData[uniqueId]
    if preplacedData ~= nil then
        preplacedData.placeable = placeable
        local rootNode = preplacedData.rootNode
        local aiSplineNodePath = getUserAttribute(rootNode, "aiSplines")
        if not string.isNilOrWhitespace(aiSplineNodePath) then
            local aiSplineNode = I3DUtil.indexToObject(rootNode, aiSplineNodePath)
            if aiSplineNode ~= nil then
                local i = 0
                for i = i, getNumOfChildren(aiSplineNode) - 1 do
                    local splineNode = getChildAt(aiSplineNode, i)
                    local maxWidth, maxWidthType = getUserAttributeValueAndType(splineNode, "maxWidth")
                    if maxWidth ~= nil and maxWidthType ~= UserAttributeType.FLOAT then
                        maxWidth = nil
                        Logging.warning("Preplaced placeable aiSpline node \'%s\' maxWidth attribute has wrong type. Has to be float type", getName(splineNode))
                    end
                    local maxTurningRadius, maxTurningRadiusType = getUserAttributeValueAndType(splineNode, "maxTurningRadius")
                    if maxTurningRadius ~= nil and maxTurningRadiusType ~= UserAttributeType.FLOAT then
                        maxTurningRadius = nil
                        Logging.warning("Preplaced placeable aiSpline node \'%s\' maxTurningRadius attribute has wrong type. Has to be float type", getName(splineNode))
                    end
                    local maxHeight, maxHeightType = getUserAttributeValueAndType(splineNode, "maxHeight")
                    if maxHeight ~= nil and maxHeightType ~= UserAttributeType.FLOAT then
                        maxHeight = nil
                        Logging.warning("Preplaced placeable aiSpline node \'%s\' maxHeight attribute has wrong type. Has to be float type", getName(splineNode))
                    end
                    g_currentMission.aiSystem:addRoadSpline(splineNode, maxWidth, maxTurningRadius, maxHeight)
                    if preplacedData.aiSplineNodes == nil then
                        preplacedData.aiSplineNodes = {}
                    end
                    table.insert(preplacedData.aiSplineNodes, splineNode)
                end
            end
        end
    end
end
function PlaceableSystem:removePreplacedPlaceable(placeable)
    local uniqueId = placeable:getUniqueId()
    local preplacedData = self.uniqueIdToReplacedPlaceableData[uniqueId]
    if preplacedData ~= nil then
        preplacedData.placeable = nil
        if preplacedData.aiSplineNodes ~= nil then
            for _, splineNode in ipairs(preplacedData.aiSplineNodes) do
                g_currentMission.aiSystem:removeRoadSpline(splineNode)
            end
        end
        if not placeable.isReloading then
            self:deletePreplacedPlaceable(preplacedData)
        end
    end
end
function PlaceableSystem.deletePreplacedPlaceable(_, data)
    if entityExists(data.rootNode) then
        Logging.devInfo("PlaceableSystem:deletePreplacedPlaceable - Deleted node \'%s\'", getName(data.rootNode))
        delete(data.rootNode)
    else
        Logging.devWarning("PlaceableSystem:deletePreplacedPlaceable - entity %d does not exist", data.rootNode)
    end
    data.isDeleted = true
end
function PlaceableSystem:getPreplacedNodeByIndex(index)
    local data = self.preplacedPlaceableData[index]
    if data == nil then
        return nil
    else
        return data.node
    end
end
function PlaceableSystem:getPreplacedFilenameByIndex(index)
    local data = self.preplacedPlaceableData[index]
    if data == nil then
        return nil
    else
        return data.xmlFilename
    end
end
function PlaceableSystem:getPreplacedUniqueIdByIndex(index)
    local data = self.preplacedPlaceableData[index]
    if data == nil then
        return nil
    else
        return data.uniqueId
    end
end
function PlaceableSystem:getPlaceableByUniqueId(uniqueId)
    return self.placableByUniqueId[uniqueId]
end
function PlaceableSystem:getArePlaceablesOnFarmland(farmId, farmlandId, includeBoughtWithFarmland)
    for _, placeable in ipairs(self.placeables) do
        if placeable.ownerFarmId == farmId and (includeBoughtWithFarmland or not placeable.boughtWithFarmland) and placeable:getIsOnFarmland(farmlandId) then
            return true
        end
    end
    return false
end
function PlaceableSystem:addPendingPlaceableLoad(placeableLoadingData)
    table.addElement(self.pendingPlaceableLoadingData, placeableLoadingData)
end
function PlaceableSystem:removePendingPlaceableLoad(placeableLoadingData)
    table.removeElement(self.pendingPlaceableLoadingData, placeableLoadingData)
end
function PlaceableSystem:getNumPendingPlaceables()
    return #self.pendingPlaceableLoadingData
end
function PlaceableSystem:canStartMission()
    local i = 1
    for i = i, #self.placeables do
        if not self.placeables[i]:getIsSynchronized() then
            return false
        end
    end
    return #self.pendingPlaceableLoadingData <= 0
end
function PlaceableSystem:addWeatherStation(weatherStation)
    table.addElement(self.weatherStations, weatherStation)
end
function PlaceableSystem:removeWeatherStation(weatherStation)
    table.removeElement(self.weatherStations, weatherStation)
end
function PlaceableSystem:addBunkerSilo(bunkerSilo)
    table.addElement(self.bunkerSilos, bunkerSilo)
end
function PlaceableSystem:removeBunkerSilo(bunkerSilo)
    table.removeElement(self.bunkerSilos, bunkerSilo)
end
function PlaceableSystem:getBunkerSilos()
    return self.bunkerSilos
end
function PlaceableSystem:getExistingPlaceableByXMLFilename(xmlFilename, ownerFarmId, excludeBoughtWithFarmland)
    for _, placeable in ipairs(self.placeables) do
        if placeable.configFileName == xmlFilename and (not placeable.markedForDeletion and (ownerFarmId == nil or placeable.ownerFarmId == ownerFarmId)) and not (excludeBoughtWithFarmland and placeable.boughtWithFarmlandSavegameOverwrite) then
            return placeable
        end
    end
    return nil
end
function PlaceableSystem:getHasWeatherStation(farmId)
    for _, weatherStation in ipairs(self.weatherStations) do
        if farmId == nil or weatherStation:getOwnerFarmId() == farmId then
            return true
        end
    end
    return false
end
function PlaceableSystem:addFarmhouse(farmhouse)
    table.addElement(self.farmhouses, farmhouse)
end
function PlaceableSystem:removeFarmhouse(farmhouse)
    table.removeElement(self.farmhouses, farmhouse)
end
function PlaceableSystem:getFarmhouse(farmId)
    for _, farmhouse in ipairs(self.farmhouses) do
        if farmId == nil or farmhouse:getOwnerFarmId() == farmId then
            return farmhouse
        end
    end
    return nil
end
function PlaceableSystem:deleteMarkedPlaceables()
    for k, placeable in pairs(self.placeablesToDelete) do
        placeable:delete(true)
        self.placeablesToDelete[k] = nil
    end
end
function PlaceableSystem:markPlaceableForDeletion(placeable)
    self.placeablesToDelete[placeable] = placeable
end
function PlaceableSystem:save(xmlFilename, usedModNames)
    local xmlFile = XMLFile.create("placeablesXML", xmlFilename, "placeables", Placeable.xmlSchemaSavegame)
    if xmlFile ~= nil then
        self:saveToXML(xmlFile, usedModNames)
        xmlFile:save()
        xmlFile:delete()
    end
end
function PlaceableSystem:saveToXML(xmlFile, usedModNames, savePreplaced)
    if xmlFile ~= nil then
        xmlFile:setValue("placeables#version", self.version)
        local xmlIndex = 0
        if Utils.getNoNil(savePreplaced, true) then
            for _, data in ipairs(self.preplacedPlaceableData) do
                local placeableKey = string.format("placeables.placeable(%d)", xmlIndex)
                xmlFile:setValue(placeableKey .. "#isPreplaced", true)
                xmlFile:setValue(placeableKey .. "#uniqueId", data.uniqueId)
                if data.isDeleted then
                    xmlFile:setValue(placeableKey .. "#isDeleted", true)
                end
                if data.boughtWithFarmlandOverwrite then
                    xmlFile:setBool(placeableKey .. "#boughtWithFarmlandOverwrite", true)
                end
                if not string.isNilOrWhitespace(data.customImageFilename) then
                    xmlFile:setString(placeableKey .. ".customImage#filename", data.customImageFilename)
                end
                if data.placeable ~= nil then
                    data.placeable:saveToXMLFile(xmlFile, placeableKey, usedModNames)
                end
                xmlIndex = xmlIndex + 1
            end
        end
        for _, data in ipairs(self.placeables) do
            if data:getNeedsSaving() and not data.isPreplaced then
                self:savePlaceableToXML(data, xmlFile, xmlIndex, _, usedModNames)
                xmlIndex = xmlIndex + 1
            end
        end
    end
end
function PlaceableSystem.savePlaceableToXML(_, placeable, xmlFile, index, _, usedModNames)
    local placeableKey = string.format("placeables.placeable(%d)", index)
    local modName = placeable.customEnvironment
    if modName ~= nil then
        if usedModNames ~= nil then
            usedModNames[modName] = modName
        end
        xmlFile:setValue(placeableKey .. "#modName", modName)
    end
    xmlFile:setValue(placeableKey .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(placeable.configFileName)))
    placeable:saveToXMLFile(xmlFile, placeableKey, usedModNames)
end
function PlaceableSystem:load(xmlFilename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
    self.savegameXMLFile = XMLFile.load("placeablesXML", xmlFilename, Placeable.xmlSchemaSavegame)
    self:loadFromXMLFile(self.savegameXMLFile, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
end
function PlaceableSystem:loadFromXMLFile(xmlFile, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
    local defaultItemsToSPFarm = xmlFile:getValue("placeables#loadAnyFarmInSingleplayer", false)
    self.loadedPlaceables = {}
    self.placeablesToLoad = 0
    self.placeableLoadingState = nil
    self.asyncCallbackFunction = asyncCallbackFunction
    self.asyncCallbackObject = asyncCallbackObject
    self.asyncCallbackArguments = asyncCallbackArguments
    for _, key in xmlFile:iterator("placeables.placeable") do
        local isPreplaced = xmlFile:getValue(key .. "#isPreplaced")
        local isDeleted = xmlFile:getValue(key .. "#isDeleted")
        local uniqueId = xmlFile:getValue(key .. "#uniqueId")
        if uniqueId == nil then
            ::l4::
            if isPreplaced then
                isPreplaced = self.uniqueIdToReplacedPlaceableData[uniqueId]
            end
            if isPreplaced ~= nil then
                isPreplaced.foundInSavegame = true
            end
            if isDeleted then
                if isPreplaced == nil then
                    Logging.xmlWarning(xmlFile, "Only preplaced placeables can be marked as deleted. \'%s\'", key)
                else
                    self:deletePreplacedPlaceable(isPreplaced)
                end
            elseif not self:loadPlaceableFromXML(xmlFile, key, defaultItemsToSPFarm, isPreplaced, self.loadPlaceableFinished, self, nil) and isPreplaced ~= nil then
                self:deletePreplacedPlaceable(isPreplaced)
            end
        else
            if ({})[uniqueId] == nil then
                usedUniqueIds[uniqueId] = true
                goto l4
            end
            Logging.xmlError(xmlFile, "Skipping placeable \'%s\' because another placeable has the same uniqueId", key)
        end
    end
    for _, key in ipairs(self.preplacedPlaceableData) do
        if not key.foundInSavegame then
            Logging.xmlWarning(xmlFile, "No entry defined for map preplaced placeable \'%s\'. Deleting preplaced placeable!", key.uniqueId)
            self:deletePreplacedPlaceable(key)
        end
    end
    if self.asyncCallbackFunction ~= nil and self.placeablesToLoad <= 0 then
        g_asyncTaskManager:addSubtask(function()
            -- upvalues: (copy) self
            self.asyncCallbackFunction(self.asyncCallbackObject, self.loadedPlaceables, PlaceableLoadingState.OK, self.asyncCallbackArguments)
            self.asyncCallbackFunction = nil
            self.asyncCallbackObject = nil
            self.asyncCallbackArguments = nil
        end)
    end
end
function PlaceableSystem:loadPlaceableFromXML(xmlFile, key, defaultItemsToSPFarm, preplacedData, callback, callbackTarget, callbackArguments)
    local missionInfo = g_currentMission.missionInfo
    local defaultProperty = xmlFile:getValue(key .. "#defaultFarmProperty", false)
    local farmId = xmlFile:getValue(key .. "#farmId")
    local loadForCompetitive = defaultProperty and missionInfo.isCompetitiveMultiplayer
    if loadForCompetitive then
        loadForCompetitive = g_farmManager:getFarmById(farmId) ~= nil
    end
    local loadDefaultProperty = defaultProperty and (missionInfo.loadDefaultFarm and not g_currentMission.missionDynamicInfo.isMultiplayer)
    if loadDefaultProperty then
        loadDefaultProperty = true
        if farmId ~= FarmManager.SINGLEPLAYER_FARM_ID then
            loadDefaultProperty = defaultItemsToSPFarm
        end
    end
    local filename
    if preplacedData == nil then
        filename = xmlFile:getValue(key .. "#filename")
    else
        filename = preplacedData.xmlFilename
    end
    if filename == nil then
        if xmlFile:getValue(key .. "#isPreplaced") then
            Logging.xmlInfo(xmlFile, "Preplaced placeable node is not defined anmore in the map. \'%s\'", key)
        else
            Logging.xmlInfo(xmlFile, "Missing filename for placeable \'%s\'", key)
        end
        return false
    else
        if missionInfo.isValid or (not defaultProperty or (loadDefaultProperty or loadForCompetitive)) then
            if string.startsWith(filename, "$data") then
                filename = Utils.getFilename(filename)
            end
            local storeItem = NetworkUtil.convertFromNetworkFilename(filename)
            local storeItem = g_storeManager:getItemByXMLFilename(storeItem)
            if storeItem ~= nil then
                local savegame = {
                    ["xmlFile"] = xmlFile,
                    ["key"] = key,
                    ["ignoreFarmId"] = false
                }
                if loadDefaultProperty and (defaultItemsToSPFarm and farmId ~= FarmManager.SINGLEPLAYER_FARM_ID) then
                    local farmId = FarmManager.SINGLEPLAYER_FARM_ID
                    savegame.ignoreFarmId = true
                end
                self.placeablesToLoad = self.placeablesToLoad + 1
                local data = PlaceableLoadingData.new()
                data:setStoreItem(storeItem)
                data:setSavegameData(savegame)
                if preplacedData ~= nil then
                    data:setPreplacedIndex(preplacedData.index)
                end
                g_asyncTaskManager:addSubtask(function()
                    -- upvalues: (copy) data, (copy) callback, (copy) callbackTarget, (copy) callbackArguments
                    data:load(callback, callbackTarget, callbackArguments)
                end)
                return true
            end
            Logging.xmlWarning(xmlFile, "Placeable \'%s\' not defined in store items", storeItem)
        end
        return false
    end
end
function PlaceableSystem:loadPlaceableFinished(placeable, loadingState, _)
    if loadingState == PlaceableLoadingState.OK then
        table.insert(self.loadedPlaceables, placeable)
    else
        self.placeableLoadingState = self.placeableLoadingState or loadingState
    end
    self.placeablesToLoad = self.placeablesToLoad - 1
    if self.asyncCallbackFunction ~= nil and self.placeablesToLoad <= 0 then
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            self.asyncCallbackFunction(self.asyncCallbackObject, self.loadedPlaceables, self.placeableLoadingState or PlaceableLoadingState.OK, self.asyncCallbackArguments)
            self.asyncCallbackFunction = nil
            self.asyncCallbackObject = nil
            self.asyncCallbackArguments = nil
            self.loadedPlaceables = nil
            self.placeableLoadingState = nil
        end, "PlaceableSystem:loadPlaceableFinished asyncCallbackFunction")
    end
end
function PlaceableSystem:consoleCommandPrintPendingLoadings()
    Logging.info("Pending Placeable Loadings:")
    for _, pendingData in ipairs(self.pendingPlaceableLoadingData) do
        Logging.info("    - %s", pendingData.storeItem ~= nil and pendingData.storeItem.xmlFilename or "Unknown")
    end
    Logging.info("Pending Placeable:")
    for _, pendingData in ipairs(self.placeables) do
        if not pendingData:getIsSynchronized() then
            Logging.info("    - LoadingState: %s | LoadingStep: %s | %s", PlaceableLoadingState.getName(pendingData.loadingState), SpecializationUtil.getLoadingStepName(pendingData.loadingStep), pendingData.configFileName)
        end
    end
end
function PlaceableSystem:consoleCommandDeleteAllPlaceables(includePreplaced)
    local numDeleted = 0
    local i = #self.placeables
    for i = i, 1, -1 do
        local placeable = self.placeables[i]
        if not placeable:getIsPreplaced() or includePreplaced then
            placeable:delete()
        end
    end
    if includePreplaced then
        return string.format("Deleted all %i placeables! Included preplaced ones!", numDeleted)
    else
        return string.format("Deleted %i placeables! Excluded preplaced ones.\n%s", numDeleted, "Usage: gsPlaceablesDeleteAll [includePreplaced]")
    end
end
function PlaceableSystem:consoleCommandReloadAllPlaceables()
    if self.isReloadRunning then
        return "Cannot start reloading. Another reloading is currently running"
    end
    if not g_currentMission:getIsServer() or g_currentMission.missionDynamicInfo.isMultiplayer then
        return "Placeable reloading only allowed in SP"
    end
    local numPlaceables = 0
    if self.reloadPlaceableSavegame == nil then
        g_i3DManager:clearEntireSharedI3DFileCache(false)
        Logging.info("Start reloading placeables (non preplaced placables)...")
        xmlFile = XMLFile.create("placeableXMLFile", "", "placeables", Placeable.xmlSchemaSavegame)
        self:saveToXML(xmlFile, {}, false)
        local i = #self.placeables
        for i = i, 1, -1 do
            local placeable = self.placeables[i]
            if not placeable.isPreplaced then
                placeable.isReloading = true
                placeable:delete()
            end
        end
    else
        Logging.info("Restart reloading placeables with remaining placeables...")
        numPlaceables = self.reloadPlaceableSavegame:getNumOfElements("placeables.placeable")
    end
    local xmlFile
    function callback(_, loadedPlaceables, _, _)
        -- upvalues: (ref) xmlFile, (copy) self
        for _, placeable in ipairs(loadedPlaceables) do
            local uniqueId = placeable:getUniqueId()
            for _, key in xmlFile:iterator("placeables.placeable") do
                if xmlFile:getValue(key .. "#uniqueId") == uniqueId then
                    xmlFile:removeProperty(key)
                    Logging.info("Reloaded placeable \'%s\'.", placeable.configFileName)
                    break
                end
            end
        end
        local numElements = xmlFile:getNumOfElements("placeables.placeable")
        if numElements == 0 then
            Logging.info("Finished reloading.")
            xmlFile:delete()
            self.reloadPlaceableSavegame = nil
        else
            self.reloadPlaceableSavegame = xmlFile
            Logging.info("Finished reloading. %d placeables could not be reloaded. Please fix the config/i3d and run the command again!", numElements)
        end
        self.isReloadRunning = false
    end
    self.isReloadRunning = numPlaceables > 0
    if numPlaceables <= 0 then
        return "No placeables found to reload"
    end
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (ref) xmlFile
        self:loadFromXMLFile(xmlFile, callback, nil, nil)
    end)
end
function PlaceableSystem:consoleCommandLoadAllPlaceables()
    if self.isLoadAllRunning then
        return "Cannot start loading all placeables. Another loading is currently running"
    end
    if not g_currentMission:getIsServer() or g_currentMission.missionDynamicInfo.isMultiplayer then
        return "Placeable loading only allowed in SP"
    end
    local placeablesToLoad = {}
    for _, storeItem in ipairs(g_storeManager:getItems()) do
        if storeItem.brush ~= nil and storeItem.brush.type ~= "" then
            if storeItem.brush.type == "fence" then
                local singletonFilename = storeItem.brush.parameters[1]
                if singletonFilename == nil then
                    Logging.error("No fence singleton filename found for \'%s\'", storeItem.xmlFilename)
                else
                    table.insert(placeablesToLoad, singletonFilename)
                end
            else
                table.insert(placeablesToLoad, storeItem)
            end
        end
    end
    if #placeablesToLoad == 0 then
        return "No placeables found"
    end
    g_i3DManager:clearEntireSharedI3DFileCache(false)
    self.isLoadAllRunning = true
    Logging.info("Start loading all placeables...")
    local x = 0
    local z = 0
    local y = getTerrainHeightAtWorldPos(g_terrainNode, 0, 0, 0)
    local _ = nil
    local function storeItem(_, loadedPlaceable, placeableLoadingState, args)
        -- upvalues: (copy) placeablesToLoad, (copy) self, (ref) _
        if placeableLoadingState == PlaceableLoadingState.OK then
            Logging.info("Loaded placeable \'%s\'", loadedPlaceable.configFileName)
            loadedPlaceable:finalizePlacement()
        else
            Logging.error("Could not load placeable \'%s\', PlaceableLoadingState: %s", args.filename, EnumUtil.getName(PlaceableLoadingState, placeableLoadingState))
        end
        if loadedPlaceable ~= nil then
            loadedPlaceable:delete()
        end
        table.remove(placeablesToLoad, 1)
        if #placeablesToLoad == 0 then
            self.isLoadAllRunning = false
            print("Finished loading placeables")
        else
            _(placeablesToLoad[1])
        end
    end
    _ = function(storeItem)
        -- upvalues: (copy) y, (copy) storeItem, (copy) x, (copy) z
        local data = PlaceableLoadingData.new()
        data:setStoreItem(storeItem)
        data:setSavegameData(nil)
        data:setPosition(0, y, 0)
        data:setRotation(0, 0, 0)
        data:load(storeItem, nil, {
            ["filename"] = storeItem.xmlFilename
        })
    end
    _(placeablesToLoad[1])
end
function PlaceableSystem:consoleCommandDrawMapBoundaries()
    PlaceableSystem.DEBUG_DRAW_BOUNDARIES = not PlaceableSystem.DEBUG_DRAW_BOUNDARIES
    if PlaceableSystem.DEBUG_DRAW_BOUNDARIES then
        g_currentMission:addDrawable(self)
    else
        g_currentMission:removeDrawable(self)
    end
end