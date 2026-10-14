GroundTypeManager = {}
local GroundTypeManager_mt = Class(GroundTypeManager, AbstractManager)
function GroundTypeManager.new(customMt)
    -- upvalues: (copy) GroundTypeManager_mt
    return AbstractManager.new(customMt or GroundTypeManager_mt)
end
function GroundTypeManager:initDataStructures()
    self.groundTypes = {}
    self.groundTypeMappings = {}
    self.terrainLayerMapping = {}
end
function GroundTypeManager:loadGroundTypes()
    self.groundTypes = {}
    local xmlFile = loadXMLFile("fuitTypes", "data/maps/groundTypes.xml")
    local i = 0
    while true do
        local key = string.format("groundTypes.groundType(%d)", i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local name = getXMLString(xmlFile, key .. "#name")
        if name == nil then
            Logging.xmlWarning(xmlFile, "Missing groundType name for \'%s\'", key)
        else
            local groundType = {}
            local fallbackLayerNames = getXMLString(xmlFile, key .. "#fallbacks")
            if not string.isNilOrWhitespace(fallbackLayerNames) then
                groundType.fallbacks = string.split(fallbackLayerNames, " ")
            end
            self.groundTypes[name] = groundType
        end
        i = i + 1
    end
    delete(xmlFile)
end
function GroundTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    GroundTypeManager:superClass().loadMapData(self)
    self:loadGroundTypes()
    return XMLUtil.loadDataFromMapXML(xmlFile, "groundTypeMappings", baseDirectory, self, self.loadGroundTypeMappings, missionInfo)
end
function GroundTypeManager:loadGroundTypeMappings(xmlFile, _)
    local i = 0
    while true do
        local key = string.format("map.groundTypeMappings.groundTypeMapping(%d)", i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local typeName = getXMLString(xmlFile, key .. "#type")
        if typeName == nil then
            Logging.xmlWarning(xmlFile, "Missing groudTypeMapping type for \'%s\'", key)
        else
            local layerName = getXMLString(xmlFile, key .. "#layer")
            if layerName == nil then
                Logging.xmlWarning(xmlFile, "Missing groudTypeMapping layerName for \'%s\'", key)
            else
                local title = getXMLString(xmlFile, key .. "#title")
                if title == nil then
                    Logging.xmlWarning(xmlFile, "Missing groudTypeMapping title for \'%s\'", key)
                else
                    local groundType = {
                        ["typeName"] = typeName,
                        ["layerName"] = layerName,
                        ["title"] = title
                    }
                    self.groundTypeMappings[groundType.typeName] = groundType
                end
            end
        end
        i = i + 1
    end
    return true
end
function GroundTypeManager:initTerrain(terrainRootNode)
    self.terrainLayerMapping = {}
    local i = 0
    for i = i, getTerrainNumOfLayers(terrainRootNode) - 1 do
        local layerName = getTerrainLayerName(terrainRootNode, i)
        self.terrainLayerMapping[layerName] = i
    end
end
function GroundTypeManager:getTerrainTitleByType(typeName)
    return self.groundTypeMappings[typeName].title
end
function GroundTypeManager:getTerrainLayerByType(typeName)
    local layerName = nil
    if typeName ~= nil and self.groundTypeMappings[typeName] ~= nil then
        layerName = self.groundTypeMappings[typeName].layerName
    end
    if layerName ~= nil then
        local layer = self.terrainLayerMapping[layerName]
        if layer ~= nil then
            return layer
        end
    end
    local layer = self.groundTypes[typeName]
    if layer ~= nil and layer.fallbacks ~= nil then
        for _, fallbackTypeName in pairs(layer.fallbacks) do
            if self.groundTypeMappings[fallbackTypeName] == nil then
                Logging.warning("Unknown fallback layer \'%s\' for ground type \'%s\'", fallbackTypeName, typeName)
            else
                local fallbackLayerName = self.groundTypeMappings[fallbackTypeName].layerName
                if fallbackLayerName ~= nil then
                    local layer = self.terrainLayerMapping[fallbackLayerName]
                    if layer ~= nil then
                        return layer
                    end
                end
            end
        end
    end
    return 0
end
g_groundTypeManager = GroundTypeManager.new()