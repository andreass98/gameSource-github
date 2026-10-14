TreeMarkerSystem = {}
TreeMarkerSystem.MOD_DIRECTORY = g_currentModDirectory
g_xmlManager:addCreateSchemaFunction(function()
    TreeMarkerSystem.xmlSchema = XMLSchema.new("treeMarkerSystem")
    TreeMarkerSystem.xmlSchemaSavegame = XMLSchema.new("treeMarkerSystem_savegame")
end)
g_xmlManager:addInitSchemaFunction(function()
    local schema = TreeMarkerSystem.xmlSchema
    schema:register(XMLValueType.STRING, "treeMarkerTypes.treeMarkerType(?)#name", "Name of the treemarker")
    schema:register(XMLValueType.STRING, "treeMarkerTypes.treeMarkerType(?)#title", "Title of the treemarker")
    schema:register(XMLValueType.FLOAT, "treeMarkerTypes.treeMarkerType(?)#scale", "Scale of the marker")
    schema:register(XMLValueType.STRING, "treeMarkerTypes.treeMarkerType(?).texture#filename", "Filename of the custom shader texture")
    schema:register(XMLValueType.STRING, "treeMarkerTypes.treeMarkerType(?).icon#filename", "Filename of the hud icon")
    local schemaSave = TreeMarkerSystem.xmlSchemaSavegame
    schemaSave:register(XMLValueType.STRING, "treeMarkerSystem.treeMarkers.treeMarker(?)#type", "Treemarker type name")
    schemaSave:register(XMLValueType.BOOL, "treeMarkerSystem.treeMarkers.treeMarker(?)#isSplitShape", "Is treemarker on a splitshape or on a preplaced tree")
    schemaSave:register(XMLValueType.VECTOR_4, "treeMarkerSystem.treeMarkers.treeMarker(?)#color", "Treemarker color")
    schemaSave:register(XMLValueType.FLOAT, "treeMarkerSystem.treeMarkers.treeMarker(?)#scale", "Treemarker scale")
    schemaSave:register(XMLValueType.FLOAT, "treeMarkerSystem.treeMarkers.treeMarker(?)#posX", "Treemarker x position")
    schemaSave:register(XMLValueType.FLOAT, "treeMarkerSystem.treeMarkers.treeMarker(?)#posY", "Treemarker y position")
    schemaSave:register(XMLValueType.FLOAT, "treeMarkerSystem.treeMarkers.treeMarker(?)#rotY", "Treemarker rotation")
    schemaSave:register(XMLValueType.INT, "treeMarkerSystem.treeMarkers.treeMarker(?)#splitShapePart1", "Treemarker splitShapePart1")
    schemaSave:register(XMLValueType.INT, "treeMarkerSystem.treeMarkers.treeMarker(?)#splitShapePart2", "Treemarker splitShapePart2")
    schemaSave:register(XMLValueType.INT, "treeMarkerSystem.treeMarkers.treeMarker(?)#splitShapePart3", "Treemarker splitShapePart3")
end)
local TreeMarkerSystem_mt = Class(TreeMarkerSystem)
function TreeMarkerSystem.new(isServer, customMt)
    -- upvalues: (copy) TreeMarkerSystem_mt
    local self = setmetatable({}, customMt or TreeMarkerSystem_mt)
    self.isServer = isServer
    self.treeMarkers = {}
    self.nameToTreeMarkerType = {}
    self.treeMarkerTypes = {}
    self.shaderParameter = "markerPosScaleRot"
    self.shaderParameterColor = "markerColorScale"
    self.shaderParameterMap = "mMarker"
    return self
end
function TreeMarkerSystem:delete()
    for _, treeMarker in ipairs(self.treeMarkerTypes) do
        delete(treeMarker.markerTexture)
    end
end
function TreeMarkerSystem:loadMapData(xmlFile, _, baseDirectory)
    self.baseDirectory = baseDirectory
    self:loadTreeMarkerTypes("data/maps/maps_treeMarkerTypes.xml")
    local filename = getXMLString(xmlFile, "map.treeMarkerTypes#filename")
    if filename ~= nil then
        self:loadTreeMarkerTypes((Utils.getFilename(filename, baseDirectory)))
    end
    return true
end
function TreeMarkerSystem:unloadMapData()
    for _, treeMarker in ipairs(self.treeMarkerTypes) do
        delete(treeMarker.markerTexture)
    end
end
function TreeMarkerSystem:initTerrain()
    self.yWorldPosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(1500, 0, 0.01)
    self.xzWorldPosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(g_currentMission.terrainSize + 500, 0.5 * (g_currentMission.terrainSize + 500), 0.01)
    self.xTreePosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(10, 0, 0.01)
    self.yTreePosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(50, 0, 0.01)
end
function TreeMarkerSystem:loadTreeMarkerTypes(filename)
    local xmlFile = XMLFile.loadIfExists("treeMarker", filename, TreeMarkerSystem.xmlSchema)
    if xmlFile ~= nil then
        local modName, baseDirectory = Utils.getModNameAndBaseDirectory(filename)
        for _, key in xmlFile:iterator("treeMarkerTypes.treeMarkerType") do
            local name = xmlFile:getValue(key .. "#name")
            local title = xmlFile:getValue(key .. "#title")
            local scale = xmlFile:getValue(key .. "#scale")
            local textureFilename = xmlFile:getValue(key .. ".texture#filename")
            local iconFilename = xmlFile:getValue(key .. ".icon#filename")
            if name ~= nil then
                local textureFilename = Utils.getFilename(textureFilename, baseDirectory)
                local iconFilename = Utils.getFilename(iconFilename, baseDirectory)
                self:registerTreeMarkerType(name, g_i18n:convertText(title, modName), scale, textureFilename, iconFilename)
            end
        end
        xmlFile:delete()
    end
end
function TreeMarkerSystem:registerTreeMarkerType(name, title, scale, markerFilename, iconFilename)
    if ClassUtil.getIsValidIndexName(name) then
        local treeMarkerType = string.upper(name)
        local treeMarkerType = self.nameToTreeMarkerType[treeMarkerType]
        if treeMarkerType == nil then
            treeMarkerType = {}
            self.nameToTreeMarkerType[treeMarkerType] = treeMarkerType
            table.insert(self.treeMarkerTypes, treeMarkerType)
            treeMarkerType.index = #self.treeMarkerTypes
        end
        treeMarkerType.name = treeMarkerType
        treeMarkerType.title = title or (treeMarkerType.title or "Unknown")
        treeMarkerType.scale = scale or (treeMarkerType.scale or 0.4)
        treeMarkerType.iconFilename = iconFilename
        if markerFilename ~= nil then
            local markerTexture = createMaterialTextureFromFile(markerFilename, true, false)
            if markerTexture ~= 0 and markerTexture ~= nil then
                if treeMarkerType.markerTexture ~= nil then
                    delete(treeMarkerType.markerTexture)
                end
                treeMarkerType.markerTexture = markerTexture
            end
        end
    else
        Logging.warning("\'%s\' is not a valid name for a tree marker type!", (tostring(name)))
    end
end
function TreeMarkerSystem:onClientJoined(connection)
    local treeMarkers = {}
    for splitShapeId, data in pairs(self.treeMarkers) do
        if entityExists(splitShapeId) then
            table.insert(treeMarkers, {
                ["splitShapeId"] = data.splitShapeId,
                ["treeMarkerTypeIndex"] = data.treeMarkerTypeIndex,
                ["r"] = data.r,
                ["g"] = data.g,
                ["b"] = data.b,
                ["a"] = data.a,
                ["posX"] = data.posX,
                ["posY"] = data.posY,
                ["scale"] = data.scale,
                ["rotY"] = data.rotY
            })
            if #treeMarkers == 255 then
                connection:sendEvent(TreeMarkerEvent.new(treeMarkers))
            end
        else
            self.treeMarkers[splitShapeId] = nil
        end
    end
    if #treeMarkers > 0 then
        connection:sendEvent(TreeMarkerEvent.new(treeMarkers))
    end
end
function TreeMarkerSystem:saveToXMLFile(xmlPath, _)
    if xmlPath ~= nil then
        local xmlFile = XMLFile.create("TreeMarkerSystemSavegameXML", xmlPath, "treeMarkerSystem", TreeMarkerSystem.xmlSchemaSavegame)
        if xmlFile ~= nil then
            local i = 0
            for shapeId, treeMarker in pairs(self.treeMarkers) do
                if entityExists(shapeId) then
                    local splitShapePart1, splitShapePart2, splitShapePart3 = getSaveableSplitShapeId(shapeId)
                    if splitShapePart1 ~= 0 and splitShapePart1 ~= nil then
                        local key = string.format("treeMarkerSystem.treeMarkers.treeMarker(%d)", i)
                        xmlFile:setValue(key .. "#splitShapePart1", splitShapePart1)
                        xmlFile:setValue(key .. "#splitShapePart2", splitShapePart2)
                        xmlFile:setValue(key .. "#splitShapePart3", splitShapePart3)
                        local treeMarkerType = self:getTreeMarkerTypeByIndex(treeMarker.treeMarkerTypeIndex)
                        xmlFile:setValue(key .. "#type", treeMarkerType.name)
                        xmlFile:setValue(key .. "#color", treeMarker.r, treeMarker.g, treeMarker.b, treeMarker.a)
                        xmlFile:setValue(key .. "#scale", treeMarker.scale)
                        xmlFile:setValue(key .. "#posX", treeMarker.posX)
                        xmlFile:setValue(key .. "#posY", treeMarker.posY)
                        xmlFile:setValue(key .. "#rotY", (math.deg(treeMarker.rotY)))
                        i = i + 1
                    end
                else
                    self.treeMarkers[shapeId] = nil
                end
            end
            xmlFile:save()
            xmlFile:delete()
        end
    end
end
function TreeMarkerSystem:loadFromSavegameXML(xmlPath)
    if xmlPath ~= nil then
        local xmlFile = XMLFile.loadIfExists("TreeMarkerSystemSavegameXML", xmlPath, TreeMarkerSystem.xmlSchemaSavegame)
        if xmlFile ~= nil then
            for _, key in xmlFile:iterator("treeMarkerSystem.treeMarkers.treeMarker") do
                local treeMarkerTypeName = xmlFile:getValue(key .. "#type")
                if treeMarkerTypeName ~= nil then
                    local treeMarkerType = self:getTreeMarkerTypeByName(treeMarkerTypeName)
                    if treeMarkerType ~= nil then
                        local splitShapePart1 = xmlFile:getValue(key .. "#splitShapePart1")
                        if splitShapePart1 ~= nil then
                            local splitShapePart2 = xmlFile:getValue(key .. "#splitShapePart2")
                            local splitShapePart3 = xmlFile:getValue(key .. "#splitShapePart3")
                            local shapeId = getShapeFromSaveableSplitShapeId(splitShapePart1, splitShapePart2, splitShapePart3)
                            if shapeId ~= nil and shapeId ~= 0 then
                                local r, g, b, a = xmlFile:getValue(key .. "#color", {
                                    1,
                                    1,
                                    1,
                                    1
                                }, false)
                                local posX = xmlFile:getValue(key .. "#posX", 0)
                                local posY = xmlFile:getValue(key .. "#posY", 0)
                                local scale = xmlFile:getValue(key .. "#scale", 0.4)
                                local rotY = math.rad((xmlFile:getValue(key .. "#rotY", 0)))
                                self:addTreeMarker(shapeId, treeMarkerType.index, r, g, b, a, posX, posY, scale, rotY)
                            end
                        end
                    end
                end
            end
            xmlFile:delete()
        end
    end
end
function TreeMarkerSystem:getTreeMarkerTypeByIndex(index)
    return self.treeMarkerTypes[index]
end
function TreeMarkerSystem:getTreeMarkerTypeByName(name)
    if ClassUtil.getIsValidIndexName(name) then
        name = string.upper(name)
        return self.nameToTreeMarkerType[name]
    else
        Logging.warning("\'%s\' is not a valid name for a tree marker type!", (tostring(name)))
        return nil
    end
end
function TreeMarkerSystem:getNumOfTreeMarkerTypes()
    return #self.treeMarkerTypes
end
function TreeMarkerSystem:addTreeMarkerCameraBased(shapeId, treeMarkerTypeIndex, r, g, b, a, camX, camY, camZ, hitX, hitY, hitZ, noEventSend)
    treeMarkerTypeIndex = treeMarkerTypeIndex or 0
    local treeMarkerType = self:getTreeMarkerTypeByIndex(treeMarkerTypeIndex)
    if treeMarkerType == nil then
        Logging.warning("No tree marker type found for tree marker type index \'%d\'", treeMarkerTypeIndex)
    else
        local _, localHitY, _ = worldToLocal(shapeId, hitX, hitY, hitZ)
        local localCamX, _, localCamZ = worldToLocal(shapeId, camX, camY, camZ)
        local localDirX, localDirZ = MathUtil.vector2Normalize(localCamX, localCamZ)
        local angle = math.atan2(localDirX, localDirZ)
        self:addTreeMarker(shapeId, treeMarkerTypeIndex, r, g, b, a, 0, localHitY, treeMarkerType.scale or 0.4, angle, noEventSend)
    end
end
function TreeMarkerSystem:addTreeMarkerByWorldDirection(shapeId, treeMarkerTypeIndex, r, g, b, a, dirX, dirZ, yOffset, scale, noEventSend)
    treeMarkerTypeIndex = treeMarkerTypeIndex or 0
    local treeMarkerType = self:getTreeMarkerTypeByIndex(treeMarkerTypeIndex)
    if treeMarkerType == nil then
        Logging.warning("No tree marker type found for tree marker type index \'%d\'", treeMarkerTypeIndex)
    else
        local localDirX, _, localDirZ = worldDirectionToLocal(shapeId, dirX, 0, dirZ)
        local angle = math.atan2(localDirX, localDirZ)
        self:addTreeMarker(shapeId, treeMarkerTypeIndex, r, g, b, a, 0, yOffset, scale or (treeMarkerType.scale or 0.4), angle, noEventSend)
    end
end
function TreeMarkerSystem:addTreeMarker(splitShapeId, treeMarkerTypeIndex, r, g, b, a, posX, posY, scale, rotY, noEventSend)
    if self.isServer and (noEventSend == nil or noEventSend == false) then
        g_server:broadcastEvent(TreeMarkerEvent.new({
            {
                ["splitShapeId"] = splitShapeId,
                ["treeMarkerTypeIndex"] = treeMarkerTypeIndex,
                ["r"] = r,
                ["g"] = g,
                ["b"] = b,
                ["a"] = a,
                ["posX"] = posX,
                ["posY"] = posY,
                ["scale"] = scale,
                ["rotY"] = rotY
            }
        }), false)
    end
    if splitShapeId ~= nil and entityExists(splitShapeId) then
        local treeMarker = self:getTreeMarkerTypeByIndex(treeMarkerTypeIndex)
        if treeMarker ~= nil and treeMarker.markerTexture ~= nil then
            local material = getMaterial(splitShapeId, 0)
            local newMaterialId = setMaterialCustomMap(material, self.shaderParameterMap, treeMarker.markerTexture, false)
            setMaterial(splitShapeId, newMaterialId, 0)
        end
        if getHasShaderParameter(splitShapeId, self.shaderParameter) then
            setShaderParameter(splitShapeId, self.shaderParameter, posX, posY, scale, rotY, false)
        end
        if getHasShaderParameter(splitShapeId, self.shaderParameterColor) then
            setShaderParameter(splitShapeId, self.shaderParameterColor, r, g, b, a, false)
        end
        self.treeMarkers[splitShapeId] = {
            ["splitShapeId"] = splitShapeId,
            ["treeMarkerTypeIndex"] = treeMarkerTypeIndex,
            ["r"] = r,
            ["g"] = g,
            ["b"] = b,
            ["a"] = a,
            ["posX"] = posX,
            ["posY"] = posY,
            ["scale"] = scale,
            ["rotY"] = rotY
        }
    end
end