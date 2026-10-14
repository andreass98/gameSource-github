PlaceablePlacement = {}
PlaceablePlacement.OVERLAP_COLLISION_MASK = CollisionMask.ALL - CollisionFlag.TERRAIN - CollisionFlag.TERRAIN_DELTA - CollisionFlag.TERRAIN_DISPLACEMENT
function PlaceablePlacement.prerequisitesPresent(specializations)
    return true
end
function PlaceablePlacement.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "loadTestArea", PlaceablePlacement.loadTestArea)
    SpecializationUtil.registerFunction(placeableType, "getIsAreaOwnedByFarm", PlaceablePlacement.getIsAreaOwnedByFarm)
    SpecializationUtil.registerFunction(placeableType, "getIsOnOwnedFarmland", PlaceablePlacement.getIsOnOwnedFarmland)
    SpecializationUtil.registerFunction(placeableType, "startPlacementCheck", PlaceablePlacement.startPlacementCheck)
    SpecializationUtil.registerFunction(placeableType, "getPlacementRotation", PlaceablePlacement.getPlacementRotation)
    SpecializationUtil.registerFunction(placeableType, "getPlacementPosition", PlaceablePlacement.getPlacementPosition)
    SpecializationUtil.registerFunction(placeableType, "getPositionSnapSize", PlaceablePlacement.getPositionSnapSize)
    SpecializationUtil.registerFunction(placeableType, "getPositionSnapOffset", PlaceablePlacement.getPositionSnapOffset)
    SpecializationUtil.registerFunction(placeableType, "getRotationSnapAngle", PlaceablePlacement.getRotationSnapAngle)
    SpecializationUtil.registerFunction(placeableType, "getPlacementOverlapMask", PlaceablePlacement.getPlacementOverlapMask)
    SpecializationUtil.registerFunction(placeableType, "isValidOverlapNode", PlaceablePlacement.isValidOverlapNode)
    SpecializationUtil.registerFunction(placeableType, "getHasOverlap", PlaceablePlacement.getHasOverlap)
    SpecializationUtil.registerFunction(placeableType, "getHasOverlapWithPlaces", PlaceablePlacement.getHasOverlapWithPlaces)
    SpecializationUtil.registerFunction(placeableType, "getCanBePlacedInWater", PlaceablePlacement.getCanBePlacedInWater)
    SpecializationUtil.registerFunction(placeableType, "getHasOverlapWithZones", PlaceablePlacement.getHasOverlapWithZones)
    SpecializationUtil.registerFunction(placeableType, "getTestParallelogramAtWorldPosition", PlaceablePlacement.getTestParallelogramAtWorldPosition)
    SpecializationUtil.registerFunction(placeableType, "playPlaceSound", PlaceablePlacement.playPlaceSound)
    SpecializationUtil.registerFunction(placeableType, "playDestroySound", PlaceablePlacement.playDestroySound)
    SpecializationUtil.registerFunction(placeableType, "getIsAreaBlocked", PlaceablePlacement.getIsAreaBlocked)
    SpecializationUtil.registerFunction(placeableType, "getHasOverlapWithDensityHeight", PlaceablePlacement.getHasOverlapWithDensityHeight)
end
function PlaceablePlacement.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceablePlacement)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceablePlacement)
    SpecializationUtil.registerEventListener(placeableType, "onPreFinalizePlacement", PlaceablePlacement)
end
function PlaceablePlacement.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Placement")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".placement#pos1Node", "Position node 1 (Required if alignToWorldY is false to calculate the terrain alignment)")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".placement#pos2Node", "Position node 2 (Required if alignToWorldY is false to calculate the terrain alignment)")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".placement#pos3Node", "Position node 3 (Required if alignToWorldY is false to calculate the terrain alignment)")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".placement.testAreas.testArea(?)#startNode", "Start node of box for testing overlap")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".placement.testAreas.testArea(?)#endNode", "End node of box for testing overlap")
    schema:register(XMLValueType.BOOL, basePath .. ".placement#useRandomYRotation", "Use random Y rotation", false)
    schema:register(XMLValueType.BOOL, basePath .. ".placement#useManualYRotation", "Use manual Y rotation", false)
    schema:register(XMLValueType.BOOL, basePath .. ".placement#alignToWorldY", "Placeable is aligned to world Y instead of terrain", true)
    schema:register(XMLValueType.FLOAT, basePath .. ".placement#placementPositionSnapSize", "Position snap size", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".placement#placementPositionSnapOffset", "Position snap offset", 0)
    schema:register(XMLValueType.ANGLE, basePath .. ".placement#placementRotationSnapAngle", "Rotation snap angle", 0)
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".placement.sounds", "place")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".placement.sounds", "placeLayered")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".placement.sounds", "destroy")
    schema:setXMLSpecializationType()
end
function PlaceablePlacement:onLoad(_)
    local spec = self.spec_placement
    local xmlFile = self.xmlFile
    spec.testAreas = {}
    xmlFile:iterate("placeable.placement.testAreas.testArea", function(_, key)
        -- upvalues: (copy) self, (copy) xmlFile, (copy) spec
        local testArea = {}
        if self:loadTestArea(xmlFile, key, testArea) then
            table.insert(spec.testAreas, testArea)
        end
    end)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#sizeX")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#sizeZ")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#sizeOffsetX")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#sizeOffsetZ")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#testSizeX", "placeable.placement.testAreas.testArea")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#testSizeZ", "placeable.placement.testAreas.testArea")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#testSizeOffsetX", "placeable.placement.testAreas.testArea")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#testSizeOffsetZ", "placeable.placement.testAreas.testArea")
    spec.useRandomYRotation = xmlFile:getValue("placeable.placement#useRandomYRotation", spec.useRandomYRotation)
    spec.useManualYRotation = xmlFile:getValue("placeable.placement#useManualYRotation", spec.useManualYRotation)
    spec.positionSnapSize = math.abs((xmlFile:getValue("placeable.placement#placementPositionSnapSize", 0)))
    spec.positionSnapOffset = math.abs((xmlFile:getValue("placeable.placement#placementPositionSnapOffset", 0)))
    spec.rotationSnapAngle = math.abs((xmlFile:getValue("placeable.placement#placementRotationSnapAngle", 0)))
    spec.alignToWorldY = xmlFile:getValue("placeable.placement#alignToWorldY", true)
    if not spec.alignToWorldY then
        spec.pos1Node = xmlFile:getValue("placeable.placement#pos1Node", nil, self.components, self.i3dMappings)
        spec.pos2Node = xmlFile:getValue("placeable.placement#pos2Node", nil, self.components, self.i3dMappings)
        spec.pos3Node = xmlFile:getValue("placeable.placement#pos3Node", nil, self.components, self.i3dMappings)
        if spec.pos1Node == nil or (spec.pos2Node == nil or spec.pos3Node == nil) then
            spec.alignToWorldY = true
            Logging.xmlWarning(xmlFile, "pos1Node, pos2Node and pos3Node has to be set when alignToWorldY is false!")
        end
    end
    if self.isClient and Platform.hasContruction then
        spec.samples = {}
        spec.samples.place = g_soundManager:loadSample2DFromXML(xmlFile.handle, "placeable.placement.sounds", "place", self.baseDirectory, 1, AudioGroup.GUI)
        spec.samples.placeLayered = g_soundManager:loadSample2DFromXML(xmlFile.handle, "placeable.placement.sounds", "placeLayered", self.baseDirectory, 1, AudioGroup.GUI)
        spec.samples.destroy = g_soundManager:loadSample2DFromXML(xmlFile.handle, "placeable.placement.sounds", "destroy", self.baseDirectory, 1, AudioGroup.GUI)
    end
end
function PlaceablePlacement:onDelete()
    if self.isClient then
        g_soundManager:deleteSamples(self.spec_placement.samples)
    end
end
function PlaceablePlacement:loadTestArea(xmlFile, key, area)
    local startNode = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
    local endNode = xmlFile:getValue(key .. "#endNode", nil, self.components, self.i3dMappings)
    if startNode == nil then
        Logging.xmlWarning(xmlFile, "Missing test area start node for \'%s\'", key)
        return false
    end
    if endNode == nil then
        Logging.xmlWarning(xmlFile, "Missing test area end node for \'%s\'", key)
        return false
    end
    if getParent(endNode) ~= startNode then
        Logging.xmlWarning(xmlFile, "Test area end node is not a direct child of startNode for \'%s\'", key)
        return false
    end
    area.startNode = startNode
    area.endNode = endNode
    local offsetX, offsetY, offsetZ = localToLocal(endNode, startNode, 0, -0.05, 0)
    local centerX, centerY, centerZ = localToLocal(startNode, self.rootNode, offsetX * 0.5, offsetY * 0.5, offsetZ * 0.5)
    local dirX = math.abs(offsetX)
    local dirX = math.abs(offsetY + 0.05)
    local sizeZ = math.abs(offsetZ)
    if offsetY < 0.01 then
        Logging.xmlDevWarning(xmlFile, "TestArea \'%s \'has no height (endNode has same y as startNode)", key)
    end
    area.size = {}
    area.size.x = math.abs(dirX)
    area.size.y = math.abs(dirX)
    area.size.z = math.abs(sizeZ)
    area.center = {}
    area.center.x = centerX
    area.center.y = centerY
    area.center.z = centerZ
    local dirX, _, dirZ = localDirectionToLocal(startNode, self.rootNode, 0, 0, 1)
    area.rotYOffset = MathUtil.getYRotationFromDirection(dirX, dirZ)
    return true
end
function PlaceablePlacement:getPlacementRotation(x, y, z)
    local spec = self.spec_placement
    if spec.rotationSnapAngle ~= 0 then
        y = math.rad((MathUtil.snapValue(math.deg(y), (math.deg(spec.rotationSnapAngle)))))
    end
    return x, y, z
end
function PlaceablePlacement:getPlacementPosition(x, y, z)
    local spec = self.spec_placement
    local snapSize = spec.positionSnapSize
    if snapSize ~= 0 then
        local snapSize = 1 / snapSize
        x = math.floor(x * snapSize) / snapSize + spec.positionSnapOffset
        z = math.floor(z * snapSize) / snapSize + spec.positionSnapOffset
    end
    return x, y, z
end
function PlaceablePlacement:getPositionSnapSize()
    return self.spec_placement.positionSnapSize
end
function PlaceablePlacement:getPositionSnapOffset()
    return self.spec_placement.positionSnapOffset
end
function PlaceablePlacement:getRotationSnapAngle()
    return self.spec_placement.rotationSnapAngle
end
function PlaceablePlacement:onPreFinalizePlacement()
    local spec = self.spec_placement
    if not spec.alignToWorldY and self.isServer then
        local x1, y1, z1 = getWorldTranslation(self.rootNode)
        local x2 = getTerrainHeightAtWorldPos(g_terrainNode, x1, y1, z1)
        setTranslation(self.rootNode, x1, x2, z1)
        local x2, y2, z2 = getWorldTranslation(spec.pos1Node)
        local x3 = getTerrainHeightAtWorldPos(g_terrainNode, x2, y2, z2)
        local x3, y3, z3 = getWorldTranslation(spec.pos2Node)
        local x4 = getTerrainHeightAtWorldPos(g_terrainNode, x3, y3, z3)
        local x4, y4, z4 = getWorldTranslation(spec.pos3Node)
        local dirX = getTerrainHeightAtWorldPos(g_terrainNode, x4, y4, z4)
        local dirX = x2 - x1
        local dirY = x3 - x2
        local dirZ = z2 - z1
        local upX, upY, upZ = MathUtil.crossProduct(x3 - x4, x4 - dirX, z3 - z4, dirX, dirY, dirZ)
        setDirection(self.rootNode, dirX, dirY, dirZ, upX, upY, upZ)
    end
end
function PlaceablePlacement.getIsAreaOwnedByFarm(_, sx, sz, wx, wz, hx, hz, farmId)
    return g_farmlandManager:getIsOwnedByFarmAlongLine(farmId, sx, sz, wx, wz) and (g_farmlandManager:getIsOwnedByFarmAlongLine(farmId, sx, sz, hx, hz) and g_farmlandManager:getIsOwnedByFarmAlongLine(farmId, hx, hz, hx + (wx - sx), hz + (wz - sz))) and g_farmlandManager:getIsOwnedByFarmAlongLine(farmId, wx, wz, wx + (hx - sx), wz + (hz - sz))
end
function PlaceablePlacement:startPlacementCheck(x, y, z, rotY) end
function PlaceablePlacement:getIsOnOwnedFarmland(x, _, z, rotY)
    local farmId = g_localPlayer.farmId
    if not g_currentMission.accessHandler:canFarmAccessLand(farmId, x, z, true) then
        return false
    end
    for _, area in ipairs(self.spec_placement.testAreas) do
        local size = area.size
        local center = area.center
        local dirX, dirZ = MathUtil.getDirectionFromYRotation(rotY)
        local normX, _, normZ = MathUtil.crossProduct(0, 1, 0, dirX, 0, dirZ)
        local posX = x + dirX * center.z + normX * center.x
        local posZ = z + dirZ * center.z + normZ * center.x
        local sizeXHalf = size.x * 0.5
        local sizeZHalf = size.z * 0.5
        if not self:getIsAreaOwnedByFarm(posX + dirX * sizeZHalf - normX * sizeXHalf, posZ + dirZ * sizeZHalf - normZ * sizeXHalf, posX + dirX * sizeZHalf + normX * sizeXHalf, posZ + dirZ * sizeZHalf + normZ * sizeXHalf, posX - dirX * sizeZHalf - normX * sizeXHalf, posZ - dirZ * sizeZHalf - normZ * sizeXHalf, farmId) then
            return false
        end
    end
    return true
end
function PlaceablePlacement.isValidOverlapNode(_, node)
    return node ~= g_terrainNode
end
function PlaceablePlacement:getPlacementOverlapMask()
    return PlaceablePlacement.OVERLAP_COLLISION_MASK
end
function PlaceablePlacement.getIsAreaBlocked(_, frontLeftX, frontLeftZ, frontRightX, frontRightZ, backLeftX, backLeftZ)
    return g_densityMapHeightManager:getIsPlacementAreaBlocked(frontLeftX, frontLeftZ, frontRightX, frontRightZ, backLeftX, backLeftZ)
end
function PlaceablePlacement:getHasOverlapWithDensityHeight(area, x, z, rotY)
    local startX, startZ, widthX, widthZ, heightX, heightZ = self:getTestParallelogramAtWorldPosition(area, x, z, rotY)
    return DensityMapHeightUtil.getValueAtArea(startX, startZ, widthX, widthZ, heightX, heightZ, true) > 0
end
function PlaceablePlacement:getHasOverlap(x, y, z, rotY, checkFunc)
    local placementOverlapMask = self:getPlacementOverlapMask()
    local callbackTarget = {
        ["hasOverlap"] = false,
        ["overlapCallback"] = function(_, hitObjectId, _, _, _, _)
            -- upvalues: (copy) checkFunc, (copy) callbackTarget, (copy) self
            if checkFunc == nil then
                if self:isValidOverlapNode(hitObjectId) then
                    callbackTarget.hasOverlap = true
                    callbackTarget.node = hitObjectId
                    return false
                end
            elseif checkFunc(hitObjectId) then
                callbackTarget.hasOverlap = true
                callbackTarget.node = hitObjectId
                return false
            end
            return true
        end
    }
    for _, area in ipairs(self.spec_placement.testAreas) do
        local size = area.size
        local center = area.center
        local dirX, dirZ = MathUtil.getDirectionFromYRotation(rotY)
        local normX, _, normZ = MathUtil.crossProduct(0, 1, 0, dirX, 0, dirZ)
        local posX = x + dirX * center.z + normX * center.x
        local posZ = z + dirZ * center.z + normZ * center.x
        local sizeXHalf = size.x * 0.5
        local sizeZHalf = size.z * 0.5
        local frontLeftX = posX + dirX * sizeZHalf - normX * sizeXHalf
        local frontLeftZ = posZ + dirZ * sizeZHalf - normZ * sizeXHalf
        local frontRightX = posX + dirX * sizeZHalf + normX * sizeXHalf
        local frontRightZ = posZ + dirZ * sizeZHalf + normZ * sizeXHalf
        local backLeftX = posX - dirX * sizeZHalf - normX * sizeXHalf
        local backLeftZ = posZ - dirZ * sizeZHalf - normZ * sizeXHalf
        if self:getIsAreaBlocked(frontLeftX, frontLeftZ, frontRightX, frontRightZ, backLeftX, backLeftZ) then
            return true, nil
        end
        local frontLeftY = getTerrainHeightAtWorldPos(g_terrainNode, frontLeftX, 0, frontLeftZ)
        local frontRightY = getTerrainHeightAtWorldPos(g_terrainNode, frontRightX, 0, frontRightZ)
        local backLeftY = getTerrainHeightAtWorldPos(g_terrainNode, backLeftX, 0, backLeftZ)
        local backRightY = getTerrainHeightAtWorldPos(g_terrainNode, posX - dirX * sizeZHalf + normX * sizeXHalf, 0, posZ - dirZ * sizeZHalf + normZ * sizeXHalf)
        local centerY = getTerrainHeightAtWorldPos(g_terrainNode, posX, 0, posZ)
        local terrainBasedCenterY = math.min(frontLeftY, frontRightY, backLeftY, backRightY, centerY) + size.y * 0.5 - 0.5
        local extendX = math.max(terrainBasedCenterY, y + center.y)
        overlapBox(posX, size.x * 0.5, posZ, 0, rotY + area.rotYOffset, 0, extendX, size.y * 0.5, size.z * 0.5, "overlapCallback", callbackTarget, placementOverlapMask, true, true, true, true)
        if callbackTarget.hasOverlap then
            return true, callbackTarget.node
        end
        if self:getHasOverlapWithDensityHeight(area, x, z, rotY) then
            return true, nil
        end
    end
    return false, nil
end
function PlaceablePlacement:getHasOverlapWithPlaces(places, x, y, z, rotY)
    for _, area in ipairs(self.spec_placement.testAreas) do
        local x1, z1, x2, z2, x3, z3, x4, z4 = self:getTestParallelogramAtWorldPosition(area, x, z, rotY)
        if PlacementUtil.isInsidePlacementPlaces(places, x1, y, z1) then
            return true
        end
        if PlacementUtil.isInsidePlacementPlaces(places, x2, y, z2) then
            return true
        end
        if PlacementUtil.isInsidePlacementPlaces(places, x3, y, z3) then
            return true
        end
        if PlacementUtil.isInsidePlacementPlaces(places, x4, y, z4) then
            return true
        end
    end
    return false
end
function PlaceablePlacement:getCanBePlacedInWater()
    return false
end
function PlaceablePlacement:getHasOverlapWithZones(zones, x, y, z, rotY)
    local doWaterCheck = not self:getCanBePlacedInWater()
    for _, area in ipairs(self.spec_placement.testAreas) do
        local x1, z1, x2, z2, x3, z3, x4, z4 = self:getTestParallelogramAtWorldPosition(area, x, z, rotY)
        if PlacementUtil.isInsideRestrictedZone(zones, x1, y, z1, doWaterCheck) then
            return true
        end
        if PlacementUtil.isInsideRestrictedZone(zones, x2, y, z2, doWaterCheck) then
            return true
        end
        if PlacementUtil.isInsideRestrictedZone(zones, x3, y, z3, doWaterCheck) then
            return true
        end
        if PlacementUtil.isInsideRestrictedZone(zones, x4, y, z4, doWaterCheck) then
            return true
        end
        if not g_currentMission.placeableSystem:getIsInsideBoundary(x1, z1) then
            return true
        end
        if not g_currentMission.placeableSystem:getIsInsideBoundary(x2, z2) then
            return true
        end
        if not g_currentMission.placeableSystem:getIsInsideBoundary(x3, z3) then
            return true
        end
        if not g_currentMission.placeableSystem:getIsInsideBoundary(x4, z4) then
            return true
        end
    end
    return false
end
function PlaceablePlacement.getTestParallelogramAtWorldPosition(_, testArea, x, z, rotY)
    local dirX, dirZ = MathUtil.getDirectionFromYRotation(rotY)
    local normX, _, normZ = MathUtil.crossProduct(0, 1, 0, dirX, 0, dirZ)
    local centerXOffset = testArea.center.x
    local centerZOffset = testArea.center.z
    local startOffsetX, startOffsetZ = MathUtil.getDirectionFromYRotation(rotY + testArea.rotYOffset)
    local startOffsetX, startOffsetZ, startX = MathUtil.crossProduct(0, 1, 0, startOffsetX, 0, startOffsetZ)
    local startOffsetX = testArea.size.x * 0.5
    local startOffsetZ = testArea.size.z * 0.5
    local startX = x + dirX * centerZOffset + normX * centerXOffset - startOffsetX * startOffsetZ - startOffsetX * startOffsetX
    local startZ = z + dirZ * centerZOffset + normZ * centerXOffset - startOffsetZ * startOffsetZ - startX * startOffsetX
    local widthOffset = testArea.size.x
    local widthX = startX + startOffsetX * widthOffset
    local widthZ = startZ + startX * widthOffset
    local heightOffset = testArea.size.z
    return startX, startZ, widthX, widthZ, startX + startOffsetX * heightOffset, startZ + startOffsetZ * heightOffset, widthX + startOffsetX * heightOffset, widthZ + startOffsetZ * heightOffset
end
function PlaceablePlacement:playPlaceSound()
    if self.isClient then
        local spec = self.spec_placement
        g_soundManager:playSample(spec.samples.place)
        g_soundManager:playSample(spec.samples.placeLayered)
    end
end
function PlaceablePlacement:playDestroySound(onlyIfNotPlaying)
    if self.isClient then
        local spec = self.spec_placement
        if not (onlyIfNotPlaying and g_soundManager:getIsSamplePlaying(spec.samples.destroy)) then
            g_soundManager:playSample(spec.samples.destroy)
        end
    end
end