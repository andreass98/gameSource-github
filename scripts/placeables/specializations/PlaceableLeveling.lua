PlaceableLeveling = {}
function PlaceableLeveling.prerequisitesPresent(specializations)
    return true
end
function PlaceableLeveling.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "loadLevelArea", PlaceableLeveling.loadLevelArea)
    SpecializationUtil.registerFunction(placeableType, "loadPaintArea", PlaceableLeveling.loadPaintArea)
    SpecializationUtil.registerFunction(placeableType, "addDeformationArea", PlaceableLeveling.addDeformationArea)
    SpecializationUtil.registerFunction(placeableType, "applyDeformation", PlaceableLeveling.applyDeformation)
    SpecializationUtil.registerFunction(placeableType, "getDeformationObjects", PlaceableLeveling.getDeformationObjects)
    SpecializationUtil.registerFunction(placeableType, "getRequiresLeveling", PlaceableLeveling.getRequiresLeveling)
    SpecializationUtil.registerFunction(placeableType, "getRequiresRealignAfterLeveling", PlaceableLeveling.getRequiresRealignAfterLeveling)
end
function PlaceableLeveling.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableLeveling)
end
function PlaceableLeveling.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Leveling")
    schema:register(XMLValueType.BOOL, basePath .. ".leveling#requireLeveling", "If true, the ground around the placeable is leveled and all other leveling properties are used", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".leveling#maxSmoothDistance", "Radius around leveling areas where terrain will be smoothed towards the placeable", 3)
    schema:register(XMLValueType.ANGLE, basePath .. ".leveling#maxSlope", "Maximum slope of terrain created by outside smoothing expressed as an angle in degrees", 45)
    schema:register(XMLValueType.ANGLE, basePath .. ".leveling#maxEdgeAngle", "Maximum angle between polygons in smoothed areas expressed as an angle in degrees", 45)
    schema:register(XMLValueType.STRING, basePath .. ".leveling#smoothingGroundType", "Ground type used to paint the smoothed ground from leveling areas up to the radius of \'maxSmoothDistance\'  (one of the ground types defined in groundTypes.xml)")
    schema:register(XMLValueType.BOOL, basePath .. ".leveling#realignAfterLeveling", "If false placeable will not be realigned in y after leveling was performed", true)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".leveling.levelAreas.levelArea(?)#startNode", "Start node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".leveling.levelAreas.levelArea(?)#widthNode", "Width node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".leveling.levelAreas.levelArea(?)#heightNode", "Height node")
    schema:register(XMLValueType.STRING, basePath .. ".leveling.levelAreas.levelArea(?)#groundType", "Ground type name (one of the ground types defined in groundTypes.xml)")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".leveling.paintAreas.paintArea(?)#startNode", "Start node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".leveling.paintAreas.paintArea(?)#widthNode", "Width node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".leveling.paintAreas.paintArea(?)#heightNode", "Height node")
    schema:register(XMLValueType.STRING, basePath .. ".leveling.paintAreas.paintArea(?)#groundType", "Ground type name (one of the ground types defined in groundTypes.xml)")
    schema:setXMLSpecializationType()
end
function PlaceableLeveling:onLoad(_)
    local spec = self.spec_leveling
    local xmlFile = self.xmlFile
    spec.requiresLeveling = xmlFile:getValue("placeable.leveling#requireLeveling", false)
    local smoothingDistance = xmlFile:getValue("placeable.leveling#maxSmoothDistance", 3)
    local clampedSmoothingDistance = math.clamp(smoothingDistance, 0, 10)
    if clampedSmoothingDistance ~= smoothingDistance then
        Logging.xmlWarning(xmlFile, "Reduced \'placeable.leveling#maxSmoothDistance\' to maximum allowed value of %d", clampedSmoothingDistance)
    end
    spec.maxSmoothDistance = clampedSmoothingDistance
    spec.maxSlope = xmlFile:getValue("placeable.leveling#maxSlope", 45)
    spec.maxEdgeAngle = xmlFile:getValue("placeable.leveling#maxEdgeAngle", 45)
    spec.smoothingGroundType = xmlFile:getValue("placeable.leveling#smoothingGroundType")
    spec.realignAfterLeveling = xmlFile:getValue("placeable.leveling#realignAfterLeveling", true)
    if not self.xmlFile:hasProperty("placeable.leveling") then
        Logging.xmlWarning(self.xmlFile, "Missing leveling areas")
    end
    spec.levelAreas = {}
    xmlFile:iterate("placeable.leveling.levelAreas.levelArea", function(_, key)
        -- upvalues: (copy) self, (copy) xmlFile, (copy) spec
        local levelArea = {}
        if self:loadLevelArea(xmlFile, key, levelArea) then
            table.insert(spec.levelAreas, levelArea)
        end
    end)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.leveling.rampAreas.rampArea", "placeable.leveling.levelAreas.levelArea")
    spec.paintAreas = {}
    xmlFile:iterate("placeable.leveling.paintAreas.paintArea", function(_, key)
        -- upvalues: (copy) self, (copy) xmlFile, (copy) spec
        local paintArea = {}
        if self:loadPaintArea(xmlFile, key, paintArea) then
            table.insert(spec.paintAreas, paintArea)
        end
    end)
end
function PlaceableLeveling:loadLevelArea(xmlFile, key, area)
    local start = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
    if start == nil then
        Logging.xmlWarning(xmlFile, "Leveling area start node not defined for \'%s\'", key)
        return false
    end
    local width = xmlFile:getValue(key .. "#widthNode", nil, self.components, self.i3dMappings)
    if width == nil then
        Logging.xmlWarning(xmlFile, "Leveling area width node not defined for \'%s\'", key)
        return false
    end
    local height = xmlFile:getValue(key .. "#heightNode", nil, self.components, self.i3dMappings)
    if height == nil then
        Logging.xmlWarning(xmlFile, "Leveling area height node not defined for \'%s\'", key)
        return false
    end
    area.start = start
    area.width = width
    area.height = height
    area.groundType = xmlFile:getValue(key .. "#groundType")
    return true
end
function PlaceableLeveling:loadPaintArea(xmlFile, key, area)
    local start = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
    if start == nil then
        Logging.xmlWarning(xmlFile, "Paint area start node not defined for \'%s\'", key)
        return false
    end
    local width = xmlFile:getValue(key .. "#widthNode", nil, self.components, self.i3dMappings)
    if width == nil then
        Logging.xmlWarning(xmlFile, "Paint area width node not defined for \'%s\'", key)
        return false
    end
    local height = xmlFile:getValue(key .. "#heightNode", nil, self.components, self.i3dMappings)
    if height == nil then
        Logging.xmlWarning(xmlFile, "Paint area height node not defined for \'%s\'", key)
        return false
    end
    area.start = start
    area.width = width
    area.height = height
    area.groundType = xmlFile:getValue(key .. "#groundType")
    return true
end
function PlaceableLeveling:getDeformationObjects(terrainRootNode, forBlockingOnly, _)
    local spec = self.spec_leveling
    local deformationObjects = {}
    if terrainRootNode ~= nil and (terrainRootNode ~= 0 and #spec.levelAreas > 0) then
        local deformationObject = TerrainDeformation.new(terrainRootNode)
        if g_densityMapHeightManager.placementCollisionMap ~= nil then
            deformationObject:setBlockedAreaMap(g_densityMapHeightManager.placementCollisionMap, 0)
        end
        for _, levelArea in pairs(spec.levelAreas) do
            local layer = -1
            if levelArea.groundType ~= nil then
                layer = g_groundTypeManager:getTerrainLayerByType(levelArea.groundType)
            end
            self:addDeformationArea(deformationObject, levelArea, layer, true)
        end
        if spec.smoothingGroundType ~= nil then
            deformationObject:setOutsideAreaBrush(g_groundTypeManager:getTerrainLayerByType(spec.smoothingGroundType))
        end
        deformationObject:setOutsideAreaConstraints(spec.maxSmoothDistance, spec.maxSlope, spec.maxEdgeAngle)
        deformationObject:setBlockedAreaMaxDisplacement(0.1)
        deformationObject:setDynamicObjectCollisionMask(CollisionMask.LEVELING)
        deformationObject:setDynamicObjectMaxDisplacement(0.3)
        table.insert(deformationObjects, deformationObject)
    end
    if not forBlockingOnly and #spec.paintAreas > 0 then
        local deformationObject = TerrainDeformation.new(terrainRootNode)
        for _, levelArea in pairs(spec.paintAreas) do
            local layer = -1
            if levelArea.groundType ~= nil then
                layer = g_groundTypeManager:getTerrainLayerByType(levelArea.groundType)
            end
            self:addDeformationArea(deformationObject, levelArea, layer, true)
        end
        deformationObject:enablePaintingMode()
        table.insert(deformationObjects, deformationObject)
    end
    return deformationObjects
end
function PlaceableLeveling.addDeformationArea(_, deformationObject, area, terrainBrushId, writeBlockedAreaMap)
    local worldStartX, worldStartY, worldStartZ = getWorldTranslation(area.start)
    local worldSide1X, worldSide1Y, worldSide1Z = getWorldTranslation(area.width)
    local worldSide2X, worldSide2Y, worldSide2Z = getWorldTranslation(area.height)
    deformationObject:addArea(worldStartX, worldStartY, worldStartZ, worldSide1X - worldStartX, worldSide1Y - worldStartY, worldSide1Z - worldStartZ, worldSide2X - worldStartX, worldSide2Y - worldStartY, worldSide2Z - worldStartZ, terrainBrushId, writeBlockedAreaMap)
end
function PlaceableLeveling:getRequiresLeveling()
    return self.spec_leveling.requiresLeveling
end
function PlaceableLeveling:getRequiresRealignAfterLeveling()
    return self.spec_leveling.realignAfterLeveling
end
function PlaceableLeveling:applyDeformation(isPreview, callback)
    local deformationObjects = self:getDeformationObjects(g_terrainNode)
    if #deformationObjects == 0 then
        callback(TerrainDeformation.STATE_SUCCESS, 0, nil)
    else
        g_terrainDeformationQueue:queueJob(deformationObjects[1], isPreview, "callback", {
            ["index"] = 1,
            ["volume"] = 0,
            ["deformationObjects"] = deformationObjects,
            ["finishCallback"] = callback,
            ["callback"] = function(target, errorCode, displacedVolume, blockedObjectName)
                -- upvalues: (copy) isPreview
                if errorCode == TerrainDeformation.STATE_SUCCESS then
                    target.volume = target.volume + displacedVolume
                    target.index = target.index + 1
                    local objects = target.deformationObjects[target.index]
                    if objects == nil then
                        local objects = {}
                        for object, object in ipairs(target.deformationObjects) do
                            table.insert(objects, object)
                        end
                        g_asyncTaskManager:addTask(function()
                            -- upvalues: (copy) objects
                            for _, object in ipairs(objects) do
                                object:delete()
                            end
                        end)
                        target.finishCallback(TerrainDeformation.STATE_SUCCESS, target.volume, nil)
                    else
                        g_terrainDeformationQueue:queueJob(objects, isPreview, "callback", target)
                    end
                else
                    local objects = {}
                    for _, object in ipairs(target.deformationObjects) do
                        table.insert(objects, object)
                    end
                    g_asyncTaskManager:addTask(function()
                        -- upvalues: (copy) objects
                        for _, object in ipairs(objects) do
                            object:delete()
                        end
                    end)
                    target.finishCallback(errorCode, target.volume, blockedObjectName)
                    return
                end
            end
        })
    end
end