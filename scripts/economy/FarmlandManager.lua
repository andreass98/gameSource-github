FarmlandManager = {}
FarmlandManager.NO_OWNER_FARM_ID = 0
local FarmlandManager_mt = FarmlandManager
FarmlandManager_mt.NOT_BUYABLE_FARM_ID = GS_IS_MOBILE_VERSION and 15 or 255
local FarmlandManager_mt = Class(FarmlandManager, AbstractManager)
g_xmlManager:addCreateSchemaFunction(function()
    FarmlandManager.xmlSchema = XMLSchema.new("farmlands")
end)
g_xmlManager:addInitSchemaFunction(function()
    Mission00.xmlSchema:register(XMLValueType.STRING, "map.farmlands#filename", "Filename of the farmland definition config")
    local schema = FarmlandManager.xmlSchema
    schema:register(XMLValueType.STRING, "map.farmlands#infoLayer", "Name of the info layer", nil, false)
    schema:register(XMLValueType.STRING, "map.farmlands#densityMapFilename", "Filename of the info layer", nil, false)
    schema:register(XMLValueType.INT, "map.farmlands#numChannels", "Number of channels of the info layer", 8, false)
    schema:register(XMLValueType.FLOAT, "map.farmlands#pricePerHa", "Price per Ha", 60000, false)
    Farmland.registerXMLPaths(schema, "map.farmlands.farmland(?)")
end)
function FarmlandManager.new(customMt)
    -- upvalues: (copy) FarmlandManager_mt
    return AbstractManager.new(customMt or FarmlandManager_mt)
end
function FarmlandManager:initDataStructures()
    self.farmlands = {}
    self.sortedFarmlands = {}
    self.sortedFarmlandIds = {}
    self.farmlandMapping = {}
    self.localMap = nil
    self.localMapWidth = 0
    self.localMapHeight = 0
    self.numberOfBits = 8
end
function FarmlandManager:loadMapData(xmlFile)
    FarmlandManager:superClass().loadMapData(self)
    return XMLUtil.loadDataFromMapXML(xmlFile, "farmlands", g_currentMission.baseDirectory, self, self.loadFarmlandData)
end
function FarmlandManager:loadFarmlandData(xmlFileHandle)
    local xmlFile = XMLFile.wrap(xmlFileHandle, FarmlandManager.xmlSchema)
    self.isLoadedFromTerrain = true
    local infoLayer = nil
    local infoLayerName = xmlFile:getValue("map.farmlands#infoLayer")
    if infoLayerName ~= nil then
        infoLayer = getInfoLayerFromTerrain(g_terrainNode, infoLayerName)
        if infoLayer == nil or infoLayer == 0 then
            Logging.xmlWarning(xmlFile, "No info layer \'%s\' defined on terrain!", infoLayerName)
        end
    end
    if infoLayer == nil then
        local numberOfBits = xmlFile:getValue("map.farmlands#densityMapFilename")
        if numberOfBits == nil then
            Logging.xmlWarning(xmlFile, "Loading farmland file \'%s\' failed! Missing densityMapFilename", numberOfBits)
            return false
        end
        local numberOfBits = Utils.getFilename(numberOfBits, g_currentMission.baseDirectory)
        local numberOfBits = xmlFile:getValue("map.farmlands#numChannels") or 8
        infoLayer = createBitVectorMap("FarmlandMap")
        if not loadBitVectorMapFromFile(infoLayer, numberOfBits, numberOfBits) then
            Logging.xmlWarning(xmlFile, "Loading farmland file \'%s\' failed!", numberOfBits)
            xmlFile:delete()
            return false
        end
        self.isLoadedFromTerrain = false
    end
    self.pricePerHa = xmlFile:getValue("map.farmlands#pricePerHa") or 60000
    FarmlandManager.NOT_BUYABLE_FARM_ID = 2 ^ self.numberOfBits - 1
    self.localMap = infoLayer
    self.numberOfBits = getBitVectorMapNumChannels(self.localMap)
    local numberOfBits, success = getBitVectorMapSize(self.localMap)
    self.localMapWidth = numberOfBits
    self.localMapHeight = success
    local numberOfBits = {}
    local success = {}
    local numOfFarmlands = 0
    local maxFarmlandId = 0
    local missingFarmlandDefinitions = false
    local x = 0
    local isNewSavegame = self.localMapWidth - 1
    local transformFactor = 1
    for x = x, isNewSavegame, transformFactor do
        local y = 0
        for y = y, self.localMapHeight - 1 do
            local value = getBitVectorMapPoint(self.localMap, x, y, 0, self.numberOfBits)
            if value > 0 then
                if self.farmlandMapping[value] == nil then
                    numberOfBits[value] = 0
                    success[value] = {
                        ["sumPosX"] = 0,
                        ["sumPosZ"] = 0
                    }
                    ({})[value] = {
                        ["minX"] = math.huge,
                        ["minZ"] = math.huge,
                        ["maxX"] = -math.huge,
                        ["maxZ"] = -math.huge
                    }
                    self.farmlandMapping[value] = FarmlandManager.NO_OWNER_FARM_ID
                    maxFarmlandId = math.max(value, maxFarmlandId)
                end
                numberOfBits[value] = numberOfBits[value] + 1
                success[value].sumPosX = success[value].sumPosX + (x - 0.5)
                success[value].sumPosZ = success[value].sumPosZ + (y - 0.5)
                local boundingBox = farmlandBoundingBox[value]
                boundingBox.minX = math.min(boundingBox.minX, x - 0.5)
                boundingBox.minZ = math.min(boundingBox.minZ, y - 0.5)
                boundingBox.maxX = math.max(boundingBox.maxX, x + 0.5)
                boundingBox.maxZ = math.max(boundingBox.maxZ, y + 0.5)
            else
                missingFarmlandDefinitions = true
            end
        end
    end
    if missingFarmlandDefinitions then
        Logging.xmlWarning(xmlFile, "Farmland-Id was not set for all pixels in farmland-infoLayer!")
    end
    local isNewSavegame = not g_currentMission.missionInfo.isValid
    for _, y in xmlFile:iterator("map.farmlands.farmland") do
        local value = Farmland.new()
        if value:load(xmlFile, y) and (self.farmlands[value.id] == nil and self.farmlandMapping[value.id] ~= nil) then
            self.farmlands[value.id] = value
            table.insert(self.sortedFarmlands, value)
            table.insert(self.sortedFarmlandIds, value.id)
            local boundingBox = isNewSavegame and g_currentMission.missionInfo.hasInitiallyOwnedFarmlands
            if boundingBox then
                boundingBox = not g_currentMission.missionDynamicInfo.isMultiplayer
            end
            if boundingBox and (g_currentMission:getIsServer() and value.defaultFarmProperty) then
                self:setLandOwnership(value.id, FarmManager.SINGLEPLAYER_FARM_ID, true)
            end
        else
            if self.farmlandMapping[value.id] == nil then
                Logging.xmlError(xmlFile, "Farmland-Id \'%s\' not defined in farmland info layer. Skipping farmland definition!", value.id)
            end
            if self.farmlands[value.id] ~= nil then
                Logging.xmlError(xmlFile, "Farmland-id \'%s\' already exists! Ignore it!", value.id)
            end
            value:delete()
        end
    end
    for _, y in pairs(self.farmlandMapping) do
        if _ ~= FarmlandManager.NOT_BUYABLE_FARM_ID and self.farmlands[_] == nil then
            Logging.xmlError(xmlFile, "Farmland-Id \'%d\' not defined in farmland xml file!", _)
        end
    end
    local transformFactor = g_currentMission.terrainSize / self.localMapWidth
    local x = transformFactor * transformFactor
    for value, boundingBox in pairs(self.farmlands) do
        boundingBox:setArea((MathUtil.areaToHa(numberOfBits[value], x)))
        boundingBox:addMapHotspot()
        if boundingBox.xWorldPos == nil then
            boundingBox:setIndicatorPosition((success[value].sumPosX / numberOfBits[value] - self.localMapWidth * 0.5) * transformFactor, (success[value].sumPosZ / numberOfBits[value] - self.localMapHeight * 0.5) * transformFactor)
        end
        local posX = farmlandBoundingBox[value]
        posX.minX = (posX.minX - self.localMapWidth * 0.5) * transformFactor
        posX.minZ = (posX.minZ - self.localMapHeight * 0.5) * transformFactor
        posX.maxX = (posX.maxX - self.localMapWidth * 0.5) * transformFactor
        posX.maxZ = (posX.maxZ - self.localMapHeight * 0.5) * transformFactor
        boundingBox:setBoundingBox(posX)
    end
    g_messageCenter:subscribe(MessageType.FARM_DELETED, self.farmDestroyed, self)
    g_messageCenter:subscribe(MessageType.FARM_SETTINGS_CHANGED, self.onFarmSettingsChanged, self)
    if g_addCheatCommands then
        if g_currentMission:getIsServer() then
            addConsoleCommand("gsFarmlandBuy", "Buys farmland with given id", "consoleCommandBuyFarmland", self)
            addConsoleCommand("gsFarmlandBuyAll", "Buys all farmlands", "consoleCommandBuyAllFarmlands", self)
            addConsoleCommand("gsFarmlandSell", "Sells farmland with given id", "consoleCommandSellFarmland", self)
            addConsoleCommand("gsFarmlandSellAll", "Sells all farmlands", "consoleCommandSellAllFarmlands", self)
        end
        addConsoleCommand("gsFarmlandShow", "Show farmlands", "consoleCommandShowFarmlands", self)
    end
    xmlFile:delete()
    return true
end
function FarmlandManager:unloadMapData()
    removeConsoleCommand("gsFarmlandBuy")
    removeConsoleCommand("gsFarmlandBuyAll")
    removeConsoleCommand("gsFarmlandSell")
    removeConsoleCommand("gsFarmlandSellAll")
    removeConsoleCommand("gsFarmlandShow")
    g_messageCenter:unsubscribeAll(self)
    if self.localMap ~= nil then
        if not self.isLoadedFromTerrain then
            delete(self.localMap)
        end
        self.localMap = nil
    end
    if self.farmlands ~= nil then
        for _, farmland in pairs(self.farmlands) do
            farmland:delete()
        end
    end
    FarmlandManager:superClass().unloadMapData(self)
end
function FarmlandManager:saveToXMLFile(xmlFilename)
    local xmlFile = createXMLFile("farmlandsXML", xmlFilename, "farmlands")
    if xmlFile == 0 then
        Logging.error("Failed to create farmlands xml file")
        return false
    end
    local index = 0
    for farmlandId, farmId in pairs(self.farmlandMapping) do
        local farmlandKey = string.format("farmlands.farmland(%d)", index)
        setXMLInt(xmlFile, farmlandKey .. "#id", farmlandId)
        setXMLInt(xmlFile, farmlandKey .. "#farmId", Utils.getNoNil(farmId, FarmlandManager.NO_OWNER_FARM_ID))
        index = index + 1
    end
    saveXMLFile(xmlFile)
    delete(xmlFile)
    return true
end
function FarmlandManager:loadFromXMLFile(xmlFilename)
    if xmlFilename == nil then
        return false
    end
    local xmlFile = loadXMLFile("farmlandXML", xmlFilename)
    if xmlFile == 0 then
        return false
    end
    local farmlandCounter = 0
    while true do
        local key = string.format("farmlands.farmland(%d)", farmlandCounter)
        local farmlandId = getXMLInt(xmlFile, key .. "#id")
        if farmlandId == nil then
            break
        end
        local farmId = getXMLInt(xmlFile, key .. "#farmId")
        if FarmlandManager.NO_OWNER_FARM_ID < farmId then
            self:setLandOwnership(farmlandId, farmId, true)
        end
        farmlandCounter = farmlandCounter + 1
    end
    delete(xmlFile)
    g_farmManager:mergeFarmlandsForSingleplayer()
    return true
end
function FarmlandManager:delete() end
function FarmlandManager:getLocalMap()
    return self.localMap
end
function FarmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, worldPosX, worldPosZ)
    if farmId == FarmlandManager.NO_OWNER_FARM_ID or farmId == nil then
        return false
    end
    local farmlandId = self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
    return self.farmlandMapping[farmlandId] == farmId
end
function FarmlandManager:getIsOwnedByFarmAlongLine(farmId, worldPosX1, worldPosZ1, worldPosX2, worldPosZ2)
    if farmId == FarmlandManager.NO_OWNER_FARM_ID or farmId == nil then
        return false
    end
    if self.localMap == nil then
        return false
    end
    local length = MathUtil.vector2Length(worldPosX1 - worldPosX2, worldPosZ1 - worldPosZ2)
    if length == 0 then
        return self:getIsOwnedByFarmAtWorldPosition(farmId, worldPosX1, worldPosZ1)
    end
    local alpha = 0
    for alpha = alpha, 1, g_currentMission.terrainSize / self.localMapWidth / length * 2 do
        local x, z = MathUtil.vector2Lerp(worldPosX1, worldPosZ1, worldPosX2, worldPosZ2, alpha)
        local localPosX, localPosZ = self:convertWorldToLocalPosition(x, z)
        local farmlandId = getBitVectorMapPoint(self.localMap, localPosX, localPosZ, 0, self.numberOfBits)
        if self.farmlandMapping[farmlandId] ~= farmId then
            return false
        end
    end
    return true
end
function FarmlandManager:getCanAccessLandAtWorldPosition(farmId, worldPosX, worldPosZ)
    if farmId == FarmlandManager.NO_OWNER_FARM_ID or farmId == nil then
        return false
    end
    local farmlandId = self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
    local ownerFarmId = self.farmlandMapping[farmlandId]
    return ownerFarmId == farmId and true or g_currentMission.accessHandler:canFarmAccessOtherId(farmId, ownerFarmId)
end
function FarmlandManager:getFarmlandOwner(farmlandId)
    if farmlandId == nil or self.farmlandMapping[farmlandId] == nil then
        return FarmlandManager.NO_OWNER_FARM_ID
    else
        return self.farmlandMapping[farmlandId]
    end
end
function FarmlandManager:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
    if self.localMap == nil then
        return FarmlandManager.NO_OWNER_FARM_ID
    end
    local localPosX, localPosZ = self:convertWorldToLocalPosition(worldPosX, worldPosZ)
    return getBitVectorMapPoint(self.localMap, localPosX, localPosZ, 0, self.numberOfBits)
end
function FarmlandManager:getFarmlandAtWorldPosition(worldPosX, worldPosZ)
    local farmlandId = self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
    return self.farmlands[farmlandId]
end
function FarmlandManager:getOwnerIdAtWorldPosition(worldPosX, worldPosZ)
    return self:getFarmlandOwner((self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)))
end
function FarmlandManager:getIsValidFarmlandId(farmlandId)
    if farmlandId == nil or (farmlandId == 0 or farmlandId < 0) then
        return false
    else
        return self:getFarmlandById(farmlandId) ~= nil
    end
end
function FarmlandManager:setLandOwnership(farmlandId, farmId, loadFromSavegame)
    if not self:getIsValidFarmlandId(farmlandId) then
        return false
    end
    if farmId == nil or (farmId < FarmlandManager.NO_OWNER_FARM_ID or farmId == FarmlandManager.NOT_BUYABLE_FARM_ID) then
        return false
    end
    local farmland = self:getFarmlandById(farmlandId)
    if farmland == nil then
        Logging.warning("Farmland id %d not defined in map!", farmlandId)
        return false
    end
    if loadFromSavegame == nil then
        loadFromSavegame = false
    end
    self.farmlandMapping[farmlandId] = farmId
    farmland:setOwnerFarmId(farmId)
    g_messageCenter:publish(MessageType.FARMLAND_OWNER_CHANGED, farmlandId, farmId, loadFromSavegame)
    return true
end
function FarmlandManager:getFarmlandById(farmlandId)
    return self.farmlands[farmlandId]
end
function FarmlandManager:getFarmlands()
    return self.farmlands
end
function FarmlandManager:getPricePerHa()
    return self.pricePerHa
end
function FarmlandManager:getOwnedFarmlandIdsByFarmId(id)
    local farmlandIds = {}
    for farmlandId, farmId in pairs(self.farmlandMapping) do
        if farmId == id then
            table.insert(farmlandIds, farmlandId)
        end
    end
    return farmlandIds
end
function FarmlandManager:getNumOwnedFarmlandIdsByFarmId(id)
    local num = 0
    for farmlandId, farmId in pairs(self.farmlandMapping) do
        if farmId == id then
        end
    end
    return num
end
function FarmlandManager:convertWorldToLocalPosition(worldPosX, worldPosZ)
    local terrainSize = g_currentMission.terrainSize
    return math.floor(self.localMapWidth * (worldPosX + terrainSize * 0.5) / terrainSize), math.floor(self.localMapHeight * (worldPosZ + terrainSize * 0.5) / terrainSize)
end
function FarmlandManager:farmDestroyed(farmId)
    for _, farmland in pairs(self:getFarmlands()) do
        if self:getFarmlandOwner(farmland.id) == farmId then
            self:setLandOwnership(farmland.id, FarmlandManager.NO_OWNER_FARM_ID)
        end
    end
end
function FarmlandManager:onFarmSettingsChanged(farmId)
    for index, farmlandId in pairs(self:getOwnedFarmlandIdsByFarmId(farmId)) do
        local farmland = self:getFarmlandById(farmlandId)
        local hotspot = farmland ~= nil and farmland:getMapHotspot() or nil
        if hotspot ~= nil then
            hotspot:updateColors()
        end
    end
end
function FarmlandManager:consoleCommandBuyFarmland(farmlandIdStr)
    if not ((g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient()) then
        return "Command not allowed"
    end
    local farmlandId
    if farmlandIdStr == nil then
        local x, _, z = g_localPlayer:getPosition()
        farmlandId = self:getFarmlandIdAtWorldPosition(x, z)
        if farmlandId == nil then
            printError("Error: Unable to retrieve farmland id at player position, provide farmland as argument instead")
            return
        end
    else
        farmlandId = tonumber(farmlandIdStr)
        if farmlandId == nil or self:getFarmlandById(farmlandId) == nil then
            printError(string.format("Error: Invalid farmland id %q.", farmlandIdStr))
            return "Use gsFarmlandBuy <farmlandId>"
        end
    end
    local x = g_localPlayer.farmId
    if self:getFarmlandOwner(farmlandId) ~= x then
        g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(farmlandId, x, 0))
        return "Bought farmland " .. farmlandId
    end
    printError(string.format("Error: Farmland %d already owned by farm %d", farmlandId, x))
end
function FarmlandManager:consoleCommandBuyAllFarmlands()
    if not ((g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient()) then
        return "Command not allowed"
    end
    for k, _ in pairs(g_farmlandManager:getFarmlands()) do
        g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(k, g_localPlayer.farmId, 0))
    end
    return "Bought all farmlands"
end
function FarmlandManager:consoleCommandSellFarmland(farmlandIdStr)
    if not ((g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient()) then
        return "Command not allowed"
    end
    local farmlandId
    if farmlandIdStr == nil then
        local x, _, z = g_localPlayer:getPosition()
        farmlandId = self:getFarmlandIdAtWorldPosition(x, z)
        if farmlandId == nil then
            printError("Error: Unable to retrieve farmland id at player position, provide farmland as argument instead")
            return
        end
    else
        farmlandId = tonumber(farmlandIdStr)
        if farmlandId == nil or self:getFarmlandById(farmlandId) == nil then
            printError(string.format("Error: Invalid farmland id %q", farmlandIdStr))
            return "Use gsFarmlandSell <farmlandId>"
        end
    end
    if self:getFarmlandOwner(farmlandId) ~= FarmlandManager.NO_OWNER_FARM_ID then
        g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(farmlandId, FarmlandManager.NO_OWNER_FARM_ID, 0))
        return "Sold farmland " .. farmlandId
    end
    printError(string.format("Error: Farmland %d not owned by anyone", farmlandId))
end
function FarmlandManager:consoleCommandSellAllFarmlands()
    if not ((g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient()) then
        return "Command not allowed"
    end
    for k, _ in pairs(g_farmlandManager:getFarmlands()) do
        g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(k, FarmlandManager.NO_OWNER_FARM_ID, 0))
    end
    return "Sold all farmlands"
end
function FarmlandManager:consoleCommandShowFarmlands()
    if not g_debugManager:hasDrawable(self) then
        g_debugManager:addDrawable(self)
        return "showFarmlands = true\nUse F5 to enter debug mode for enabling overlay"
    end
    g_debugManager:removeDrawable(self)
    self.debugFarmlandColors = nil
    return "showFarmlands = false"
end
function FarmlandManager:drawDebug()
    local x, _, z = getWorldTranslation(g_cameraManager:getActiveCamera())
    if self.debugFarmlandColors == nil then
        self.debugFarmlandColors = {}
        for farmlandId, _ in pairs(self.farmlands) do
            local color = DebugUtil.getDebugColor(farmlandId)
            color.a = 0.15
            self.debugFarmlandColors[farmlandId] = color
        end
    end
    if g_localPlayer:getCurrentVehicle() ~= nil then
        local object = g_localPlayer:getCurrentVehicle()
        if g_localPlayer:getCurrentVehicle().selectedImplement ~= nil then
            object = g_localPlayer:getCurrentVehicle().selectedImplement.object
        end
        local worldToBitmap
        x, worldToBitmap, z = getWorldTranslation(object.components[1].node)
    end
    local object = g_currentMission.terrainSize / 2
    local bitmapToWorld = g_currentMission.terrainSize / self.localMapWidth
    local worldToBitmap = self.localMapWidth / g_currentMission.terrainSize
    local _ = (x + object) * worldToBitmap
    local farmlandId = math.floor(color)
    local color = (z + object) * worldToBitmap
    color = math.floor(color)
    local bitmapMinZ = farmlandId - 25
    local bitmapMinX = math.max(bitmapMinZ, 0)
    local bitmapMaxX = color - 25
    local bitmapMinZ = math.max(bitmapMaxX, 0)
    local farmlandsLegend = self.localMapWidth - 1
    local bitmapMaxX = math.min(farmlandId + 25, farmlandsLegend)
    local farmlandsLegend = color + 25
    local bitmapMaxZ = math.min(farmlandsLegend, self.localMapWidth - 1)
    local farmlandsLegend = {}
    local i = 1
    for bitmapMinZ = bitmapMinZ, bitmapMaxZ, i do
        local v37_ = bitmapMinX
        for bitmapMinX = bitmapMinX, bitmapMaxX do
            local farmland = self.farmlands[getBitVectorMapPoint(self.localMap, bitmapMinX, bitmapMinZ, 0, self.numberOfBits)]
            if farmland then
                local color = self.debugFarmlandColors[farmland.id]
                farmlandsLegend[farmland] = color
                local worldX = bitmapMinX * bitmapToWorld - object
                local worldZ = bitmapMinZ * bitmapToWorld - object
                DebugPlane.renderWithPositions(worldX, 0, worldZ, worldX, 0, worldZ + bitmapToWorld, worldX + bitmapToWorld, 0, worldZ, color, true, true)
                v37_ = bitmapMinX
            else
                v37_ = bitmapMinX
            end
            bitmapMinX = v37_
        end
    end
    local i = 0
    if next(farmlandsLegend) == nil then
        renderText(0.3, 0.97 - i * 0.015, 0.015, "No farmlands defined in vicinity")
    else
        for bitmapStepX, farmland in pairs(farmlandsLegend) do
            local worldX = string.format("Farmland %d | Owner: %s | Area: %.3fha | Price: %d%s", bitmapStepX.id, self:getFarmlandOwner(bitmapStepX.id), bitmapStepX.areaInHa, bitmapStepX.price, bitmapStepX.defaultFarmProperty and " | defaultFarmProperty" or "")
            setTextColor(farmland[1], farmland[2], farmland[3], 1)
            renderText(0.3, 0.97 - i * 0.015, 0.015, worldX)
            setTextColor(1, 1, 1, 1)
            i = i + 1
        end
    end
end
g_farmlandManager = FarmlandManager.new()