FoliageSystem = {}
local FoliageSystem_mt = Class(FoliageSystem)
g_xmlManager:addInitSchemaFunction(function()
    local xmlSchemaFruitType = FruitTypeDesc.xmlSchema
    DensityMapHeightManager.registerXMLPaths(xmlSchemaFruitType, "foliageType")
    FruitTypeManager.registerXMLPaths(xmlSchemaFruitType, "foliageType")
    FillTypeManager.registerXMLPaths(xmlSchemaFruitType, "foliageType")
    MotionPathEffectManager.registerMotionPathXMLFiles(xmlSchemaFruitType, "foliageType")
    FillTypeManager.registerXMLPaths(FillTypeManager.xmlSchema, "foliageType")
end)
function FoliageSystem.new(customMt)
    -- upvalues: (copy) FoliageSystem_mt
    local self = setmetatable({}, customMt or FoliageSystem_mt)
    self.terrainRootNode = 0
    self.paintableFoliages = {}
    self.decoFoliages = {}
    self.decoFoliageMappings = {}
    self.modFoliageTypesToLoad = {}
    return self
end
function FoliageSystem:delete()
    self.paintableFoliages = {}
    self.decoFoliages = {}
    self.modFoliageTypesToLoad = {}
end
function FoliageSystem:loadMapData(mapXmlFile, missionInfo, _)
    local xmlFile = XMLFile.wrap(mapXmlFile)
    xmlFile:iterate("map.paintableFoliages.paintableFoliage", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) self
        local layerName = xmlFile:getString(key .. "#layerName")
        if layerName == nil then
            Logging.xmlWarning(xmlFile, "Missing layerName for paintableFoliage \'%s\'", key)
        else
            local paintableFoliage = {
                ["layerName"] = layerName,
                ["startStateChannel"] = xmlFile:getInt(key .. "#startChannel", 0),
                ["numStateChannels"] = xmlFile:getInt(key .. "#numChannels", 4),
                ["state"] = xmlFile:getInt(key .. "#state", 0),
                ["id"] = #self.paintableFoliages + 1
            }
            table.insert(self.paintableFoliages, paintableFoliage)
        end
    end)
    local decoFoliageLayerNames = {}
    xmlFile:iterate("map.decoFoliages.decoFoliage", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) decoFoliageLayerNames, (copy) self
        local decoFoliage = {
            ["layerName"] = xmlFile:getString(key .. "#layerName")
        }
        if decoFoliage.layerName == nil then
            Logging.xmlWarning(xmlFile, "Missing layerName for decoFoliage \'%s\'", key)
        else
            decoFoliage.startStateChannel = xmlFile:getInt(key .. "#startChannel", 0)
            decoFoliage.numStateChannels = xmlFile:getInt(key .. "#numChannels", 4)
            decoFoliage.mowable = xmlFile:getBool(key .. "#mowable")
            decoFoliageLayerNames[string.upper(decoFoliage.layerName)] = decoFoliage
            table.insert(self.decoFoliages, decoFoliage)
        end
    end)
    self.decoFoliageMappings = {}
    xmlFile:iterate("map.decoFoliages.mapping", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) self, (copy) decoFoliageLayerNames
        local name = xmlFile:getString(key .. "#name")
        if name == nil then
            Logging.xmlWarning(xmlFile, "Missing name for decoFoliage mapping \'%s\'", key)
            return
        else
            local nameUpper = string.upper(name)
            if self.decoFoliageMappings[nameUpper] == nil then
                local layerName = xmlFile:getString(key .. "#layerName")
                if layerName == nil then
                    Logging.xmlWarning(xmlFile, "Missing layerName for decoFoliage mapping \'%s\'", key)
                    return
                else
                    local decoFoliage = decoFoliageLayerNames[string.upper(layerName)]
                    if decoFoliage == nil then
                        Logging.xmlWarning(xmlFile, "Mapping layerName \'%s\' not defined deco foliages for \'%s\'", layerName, key)
                    else
                        self.decoFoliageMappings[nameUpper] = {
                            ["decoFoliage"] = decoFoliage,
                            ["state"] = xmlFile:getInt(key .. "#state")
                        }
                    end
                end
            else
                Logging.xmlWarning(xmlFile, "Name \'%s\' already defined for decoFoliage mapping \'%s\'", name, key)
                return
            end
        end
    end)
    xmlFile:delete()
    self.modFoliageTypesToLoad = missionInfo.foliageTypes or self.modFoliageTypesToLoad
    local newFoliageTypes = g_fruitTypeManager.modFoliageTypesToLoad
    local i = 1
    for i = i, #newFoliageTypes do
        local newFoliageType = newFoliageTypes[i]
        self:addModFoliageType(newFoliageType.name, newFoliageType.filename)
    end
    local i = 1
    for i = i, #self.modFoliageTypesToLoad do
        local newFoliageType = self.modFoliageTypesToLoad[i]
        self:loadModFoliageType(newFoliageType.name, newFoliageType.filename)
    end
    if #self.modFoliageTypesToLoad > 0 then
        g_fruitTypeManager:initializeFruitTypeConverters()
    end
    return true
end
function FoliageSystem:unloadMapData()
    self.paintableFoliages = {}
end
function FoliageSystem:streamWriteModFoliageTypes(streamId, _)
    streamWriteUInt8(streamId, #self.modFoliageTypesToLoad)
    for _, foliageType in ipairs(self.modFoliageTypesToLoad) do
        streamWriteString(streamId, foliageType.name)
        streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(foliageType.filename))
    end
end
function FoliageSystem:streamReadModFoliageTypes(streamId, _)
    local numLoadedFoliageTypes = 0
    local numTypes = streamReadUInt8(streamId)
    for i = 1, numTypes do
        local name = streamReadString(streamId)
        local filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
        if self:addModFoliageType(name, filename) and self:loadModFoliageType(name, filename) then
            numLoadedFoliageTypes = numLoadedFoliageTypes + numLoadedFoliageTypes
        end
    end
    if numLoadedFoliageTypes > 0 then
        g_fruitTypeManager:initializeFruitTypeConverters()
    end
end
function FoliageSystem:saveToXMLFile(xmlFile)
    local i = 1
    for i = i, #self.modFoliageTypesToLoad do
        local foliageType = self.modFoliageTypesToLoad[i]
        local key = string.format("careerSavegame.foliageTypes.foliageType(%d)", i - 1)
        setXMLString(xmlFile, key .. "#name", foliageType.name)
        setXMLString(xmlFile, key .. "#filename", NetworkUtil.convertToNetworkFilename(foliageType.filename))
    end
end
function FoliageSystem:initTerrain(_, terrainRootNode, _)
    self.terrainRootNode = terrainRootNode
    for key, paintableFoliage in pairs(self.paintableFoliages) do
        local id, _ = getTerrainDataPlaneByName(self.terrainRootNode, paintableFoliage.layerName)
        if id == nil or id == 0 then
            paintableFoliage.disabled = true
        else
            paintableFoliage.terrainDataPlaneId = id
            paintableFoliage.paintModifier = DensityMapModifier.new(id, paintableFoliage.startStateChannel, paintableFoliage.numStateChannels, terrainRootNode)
            paintableFoliage.paintFilter = DensityMapFilter.new(paintableFoliage.paintModifier)
        end
    end
    for key, paintableFoliage in pairs(self.decoFoliages) do
        local id, _ = getTerrainDataPlaneByName(self.terrainRootNode, paintableFoliage.layerName)
        if id ~= nil and id ~= 0 then
            paintableFoliage.terrainDataPlaneId = id
            paintableFoliage.modifier = DensityMapModifier.new(id, paintableFoliage.startStateChannel, paintableFoliage.numStateChannels, terrainRootNode)
        end
    end
    self:loadModFoliageTypes()
end
function FoliageSystem:addDensityMapSyncer(densityMapSyncer)
    for key, decoFoliage in pairs(self.decoFoliages) do
        if decoFoliage.terrainDataPlaneId ~= nil then
            densityMapSyncer:addDensityMap(decoFoliage.terrainDataPlaneId)
        end
    end
end
function FoliageSystem:applyAreas(modifiedAreas, paintTerrainFoliageId)
    for _, paintableFoliage in pairs(self.paintableFoliages) do
        if paintableFoliage.id == paintTerrainFoliageId and not paintableFoliage.disabled then
            for _, area in pairs(modifiedAreas) do
                local x, z, x1, z1, x2, z2 = unpack(area)
                self:apply(paintableFoliage, x, z, x1 - x, z1 - z, x2 - x, z2 - z)
            end
            return true
        end
    end
    return false
end
function FoliageSystem:getFoliagePaint(id)
    for _, paintableFoliage in pairs(self.paintableFoliages) do
        if paintableFoliage.id == id and not paintableFoliage.disabled then
            return paintableFoliage
        end
    end
    return nil
end
function FoliageSystem:getFoliagePaintByName(name)
    for _, paintableFoliage in pairs(self.paintableFoliages) do
        if paintableFoliage.layerName == name and not paintableFoliage.disabled then
            return paintableFoliage
        end
    end
    return nil
end
function FoliageSystem.apply(_, foliage, x, z, x1, z1, x2, z2, value)
    local modifier = foliage.paintModifier
    local filter = foliage.paintFilter
    if value == nil then
        value = foliage.value
    end
    modifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
    filter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, value)
    local _, numPixels, _ = modifier:executeSetWithStats(value, filter)
    return numPixels / 4
end
function FoliageSystem:getDecoFoliages()
    return self.decoFoliages
end
function FoliageSystem:getIsDecoLayerDefined(decoName)
    local nameUpper = string.upper(decoName)
    return self.decoFoliageMappings[nameUpper] ~= nil
end
function FoliageSystem:getDensityMapData(decoFoliageName)
    local data = self.decoFoliageMappings[string.upper(decoFoliageName)]
    if data == nil then
        return nil
    end
    local decoFoliage = data.decoFoliage
    return decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels, data.state
end
function FoliageSystem:applyDecoFoliage(decoName, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local nameUpper = string.upper(decoName)
    local data = self.decoFoliageMappings[nameUpper]
    if data ~= nil then
        local modifier = data.decoFoliage.modifier
        if modifier ~= nil then
            modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
            modifier:executeSet(data.state)
        end
    end
end
function FoliageSystem.loadModFoliageType(_, name, filename, missionInfo, baseDirectory)
    if g_fruitTypeManager.filenameToFruitType[filename] ~= nil then
        Logging.devInfo("FoliageSystem - FoliageType \'%s\' already loaded from \'%s\'", name, filename)
        return false
    end
    local foliageXMLFile = XMLFile.load("fillTypeXMLFile", filename, FruitTypeDesc.xmlSchema)
    if foliageXMLFile == nil then
        return false
    end
    local foliageXMLFileHandle = foliageXMLFile:getHandle()
    g_fillTypeManager:loadFillTypes(foliageXMLFile, "", false, nil, true)
    g_fruitTypeManager:loadFruitTypeFromXML(filename)
    g_fruitTypeManager:loadMapCategoriesAndConverters(foliageXMLFileHandle, missionInfo, baseDirectory)
    g_densityMapHeightManager:loadDensityMapHeightTypes(foliageXMLFile, missionInfo, nil, false)
    g_motionPathEffectManager:loadMotionPathEffects(foliageXMLFileHandle, "foliageType.motionPathEffects.motionPathEffect", baseDirectory, nil)
    foliageXMLFile:delete()
    Logging.devInfo("FoliageSystem - Loaded mod foliageType \'%s\'", name)
    return true
end
function FoliageSystem:addModFoliageType(name, configFilename)
    local j = 1
    for j = j, #self.modFoliageTypesToLoad do
        if name == self.modFoliageTypesToLoad[j].name then
            Logging.devWarning("FoliageSystem - Mod foliageType \'%s\' is already added. Skipping...", name)
            return false
        end
    end
    Logging.devWarning("FoliageSystem - Added Mod foliageType \'%s\'", name)
    table.insert(self.modFoliageTypesToLoad, {
        ["name"] = name,
        ["filename"] = configFilename
    })
    return true
end
local _sub = string.sub
local _len = string.len
local _oldaddFoliageTypeFromXML = addFoliageTypeFromXML
function FoliageSystem:loadModFoliageTypes()
    -- upvalues: (copy) _sub, (copy) _oldaddFoliageTypeFromXML
    local i = 1
    for i = i, #self.modFoliageTypesToLoad do
        local id = nil
        for _, fruitType in ipairs(g_fruitTypeManager:getFruitTypes()) do
            id, _ = getTerrainDataPlaneByName(self.terrainRootNode, fruitType.layerName)
            if id ~= nil then
                break
            end
        end
        if id == nil then
            Logging.warning("Failed to load foliage xml \'%s\'", self.modFoliageTypesToLoad[i].filename)
        else
            local xmlFilename = foliageType.filename
            if _sub(xmlFilename, 1, 12) == "data/foliage" then
                _oldaddFoliageTypeFromXML(g_terrainNode, id, foliageType.name, xmlFilename)
            else
                Logging.error("Failed to load foliage xml \'%s\'", xmlFilename)
            end
        end
    end
end