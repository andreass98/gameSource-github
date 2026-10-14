FieldCourseField = {}
local FieldCourseField_mt = Class(FieldCourseField)
FieldCourseField.NUM_BOUNDARY_SYNC_BITS = 9
FieldCourseField.MAX_BOUNDARY_SIZE = 2 ^ FieldCourseField.NUM_BOUNDARY_SYNC_BITS - 1
FieldCourseField.NUM_ISLANDS_SYNC_BITS = 5
FieldCourseField.MAX_ISLAND_AMOUNT = 2 ^ FieldCourseField.NUM_ISLANDS_SYNC_BITS - 1
FieldCourseField.MIN_BOUNDARY_LENGTH = 20
FieldCourseField.THIGHT_CORNER_ANGLE = 2.443460952792061
function FieldCourseField.new(fieldCourseSettings)
    -- upvalues: (copy) FieldCourseField_mt
    local self = setmetatable({}, FieldCourseField_mt)
    self.fieldCourseSettings = fieldCourseSettings
    self.segmentSplitAngle = math.rad(fieldCourseSettings.segmentSplitAngle)
    self.boundaryPositions = {}
    self.headlandBoundaries = {}
    self.islandBoundaries = {}
    self.state = FieldCourseDetectionState.BOUNDARY_DETECTION
    self.boundaryCollisionCheckSegmentIndex = 0
    self.boundaryCollisionCheckPending = false
    self.boundaryCollisionCheckRequiresSegmentUpdate = false
    self.ignoreIslands = false
    self.ignoreCollisions = false
    return self
end
function FieldCourseField.generateAtPosition(x, z, fieldCourseSettings, callback, callbackTarget)
    local field
    field, z = g_fieldCourseManager:roundToTerrainDetailPixel(x, z)
    local field = FieldCourseField.new(fieldCourseSettings)
    field:detectAtPosition(field, z, callback, callbackTarget)
    return field
end
function FieldCourseField:reset()
    self.headlandBoundaries = {}
    if self.islands ~= nil then
        for _, island in ipairs(self.islands) do
            island.boundaries = {}
            island.hasCutSegments = false
        end
    end
end
function FieldCourseField:setIgnoreIslands(ignoreIslands)
    self.ignoreIslands = ignoreIslands
end
function FieldCourseField:setIgnoreCollisions(ignoreCollisions)
    self.ignoreCollisions = ignoreCollisions
end
function FieldCourseField:detectAtPosition(x, z, callback, callbackTarget)
    self.startX = x
    self.startZ = z
    self.callback = callback
    self.callbackTarget = callbackTarget
    self.terrainDetailResolution = g_currentMission.terrainSize / g_currentMission.terrainDetailMapSize
    self.islandSamplePoints = {}
    local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
    local _, _, _, riceField = PlaceableRiceField.getRiceFieldAtPosition(x, y, z)
    if riceField == nil then
        self.boundaryDetectionTask = BoundaryDetectionTask.new(x, z)
        if self.boundaryDetectionTask == nil then
            self:finishTask(false)
            return nil
        end
        return
    else
        local numVerts = riceField.polygon:getNumVertices()
        local i = 1
        local z = 1
        for i = i, numVerts, z do
            local x, z = riceField.polygon:getVertex(i)
            table.insert(self.boundaryPositions, { x, z })
        end
        local x, z = riceField.polygon:getVertex(1)
        local x = self.boundaryPositions
        table.insert(x, { x, z })
        if FieldCourseBoundary.getIsBoundaryLineInverted(self.boundaryPositions) then
            local i = {}
            local i = #self.boundaryPositions
            for i = i, 1, -1 do
                table.insert(i, self.boundaryPositions[i])
            end
            self.boundaryPositions = i
        end
        local z = 1
        local i = #self.boundaryPositions
        local x = 1
        for z = z, i, x do
            self.boundaryPositions[z][1], self.boundaryPositions[z][2] = g_fieldCourseManager:roundToTerrainDetailPixel(self.boundaryPositions[z][1], self.boundaryPositions[z][2])
        end
        self.fieldRootBoundary = FieldCourseBoundary.createByBoundaryLine(self.boundaryPositions, self.segmentSplitAngle)
        self.fieldRootBoundary = self.fieldRootBoundary:extend(0.75)
        if self.fieldRootBoundary == nil then
            Logging.warning("Failed to create field boundary from rice field")
            self:finishTask(false)
            return nil
        else
            self.boundaryPositions = table.clone(self.fieldRootBoundary.boundaryLine, math.huge)
            self:finishTask(true)
            return self
        end
    end
end
function FieldCourseField:saveToXML(xmlFile, key)
    local boundaryPositionStr = ""
    local i = 1
    for i = i, #self.boundaryPositions do
        boundaryPositionStr = boundaryPositionStr .. string.format("%.2f %.2f ", self.boundaryPositions[i][1], self.boundaryPositions[i][2])
    end
    xmlFile:setValue(key .. ".boundary#positions", string.trim(boundaryPositionStr))
    for i, island in ipairs(self.islands) do
        local islandKey = string.format("%s.island(%d)", key, i - 1)
        local islandBoundaryPositionStr = ""
        local j = 1
        for j = j, #island.rootBoundary.boundaryLine do
            islandBoundaryPositionStr = islandBoundaryPositionStr .. string.format("%.2f %.2f ", island.rootBoundary.boundaryLine[j][1], island.rootBoundary.boundaryLine[j][2])
        end
        xmlFile:setValue(islandKey .. "#positions", string.trim(islandBoundaryPositionStr))
    end
end
function FieldCourseField:loadFromXML(xmlFile, key)
    if not xmlFile:hasProperty(key) then
        return false
    end
    local boundaryStr = xmlFile:getValue(key .. ".boundary#positions")
    if boundaryStr == nil then
        return false
    end
    self.boundaryPositions = {}
    local positions = string.split(boundaryStr, " ")
    local i = 1
    for i = i, #positions, 2 do
        local z = tonumber(positions[i + 1])
        table.insert(self.boundaryPositions, { islandBoundaryStr, z })
    end
    self.fieldRootBoundary = FieldCourseBoundary.createByBoundaryLine(self.boundaryPositions, self.segmentSplitAngle)
    if self.fieldRootBoundary == nil then
        Logging.xmlWarning(xmlFile, "Failed to create fieldRootBoundary from \'%s\' in \'%s\'", boundaryStr, key)
        return false
    end
    self.islands = {}
    for x, z in xmlFile:iterator(key .. ".island") do
        local islandBoundaryStr = xmlFile:getValue(z .. "#positions")
        if islandBoundaryStr == nil then
            break
        end
        local island = {
            ["boundaries"] = {},
            ["hasCutSegments"] = false
        }
        local boundaryLine = {}
        local islandPositions = string.split(islandBoundaryStr, " ")
        local i = 1
        for i = i, #islandPositions, 2 do
            local x = tonumber(islandPositions[i])
            table.insert(boundaryLine, { x, (tonumber(islandPositions[i + 1])) })
        end
        island.rootBoundary = FieldCourseBoundary.createByBoundaryLine(boundaryLine, self.segmentSplitAngle)
        table.insert(self.islands, island)
    end
    self.state = FieldCourseDetectionState.FINISHED
    return true
end
function FieldCourseField:writeStream(streamId, _)
    streamWriteUIntN(streamId, #self.boundaryPositions, FieldCourseField.NUM_BOUNDARY_SYNC_BITS)
    local i = 1
    for i = i, #self.boundaryPositions do
        g_fieldCourseManager:writeTerrainDetailPixel(streamId, self.boundaryPositions[i][1], self.boundaryPositions[i][2])
    end
    streamWriteUIntN(streamId, #self.islands, FieldCourseField.NUM_ISLANDS_SYNC_BITS)
    for _, island in ipairs(self.islands) do
        streamWriteUIntN(streamId, #island.rootBoundary.boundaryLine, FieldCourseField.NUM_BOUNDARY_SYNC_BITS)
        local i = 1
        for i = i, #island.rootBoundary.boundaryLine do
            g_fieldCourseManager:writeTerrainDetailPixel(streamId, island.rootBoundary.boundaryLine[i][1], island.rootBoundary.boundaryLine[i][2])
        end
    end
end
function FieldCourseField:readStream(streamId, _)
    self.boundaryPositions = {}
    local numBoundaryPositions = streamReadUIntN(streamId, FieldCourseField.NUM_BOUNDARY_SYNC_BITS)
    for i = 1, numBoundaryPositions do
        local x, z = g_fieldCourseManager:readTerrainDetailPixel(streamId)
        table.insert(self.boundaryPositions, { x, z })
    end
    self.fieldRootBoundary = FieldCourseBoundary.createByBoundaryLine(self.boundaryPositions, self.segmentSplitAngle)
    self.islands = {}
    local numIslands = streamReadUIntN(streamId, FieldCourseField.NUM_ISLANDS_SYNC_BITS)
    local x = 1
    for x = x, numIslands do
        local z = {
            ["boundaries"] = {},
            ["hasCutSegments"] = false
        }
        local boundaryLine = {}
        local numBoundaryPositions = streamReadUIntN(streamId, FieldCourseField.NUM_BOUNDARY_SYNC_BITS)
        for j = 1, numBoundaryPositions do
            local x, z = g_fieldCourseManager:readTerrainDetailPixel(streamId)
            table.insert(boundaryLine, { x, z })
        end
        z.rootBoundary = FieldCourseBoundary.createByBoundaryLine(boundaryLine, self.segmentSplitAngle)
        table.insert(self.islands, z)
    end
    self.state = FieldCourseDetectionState.FINISHED
end
function FieldCourseField:update(dt, frameBudget)
    if self.state == FieldCourseDetectionState.BOUNDARY_DETECTION then
        if self.boundaryDetectionTask ~= nil and not self.boundaryDetectionTask:update(dt, frameBudget) then
            if #self.boundaryDetectionTask.boundaryPositions > 0 then
                self.state = FieldCourseDetectionState.BOUNDARY_SIMPLIFICATION1
            else
                self:finishTask(false)
            end
        end
    elseif self.state == FieldCourseDetectionState.BOUNDARY_SIMPLIFICATION1 then
        local boundaryPositions = self.boundaryDetectionTask.boundaryPositions
        FieldCourseUtil.pointAveragePositions(boundaryPositions)
        local i = #boundaryPositions
        for i = i, 1, -2 do
            table.remove(boundaryPositions, i)
        end
        local i = boundaryPositions[#boundaryPositions][1]
        local i = boundaryPositions[#boundaryPositions][2]
        boundaryPositions[1][1] = i
        boundaryPositions[1][2] = i
        FieldCourseUtil.semiConvexSimplification(boundaryPositions, 10)
        FieldCourseUtil.douglasPeucker(boundaryPositions, 0.25)
        self.state = FieldCourseDetectionState.BOUNDARY_SIMPLIFICATION2
    elseif self.state == FieldCourseDetectionState.BOUNDARY_SIMPLIFICATION2 then
        local boundaryPositions = self.boundaryDetectionTask.boundaryPositions
        if FieldCourseUtil.getIsPointInsideBoundary(self.startX, self.startZ, boundaryPositions) then
            local i = 1
            local maxZ = #boundaryPositions
            for i = i, maxZ do
                local z1, x2 = g_fieldCourseManager:roundToTerrainDetailPixel(boundaryPositions[i][1], boundaryPositions[i][2])
                i[1] = z1
                boundaryPositions[boundaryPositions[i]][2] = x2
            end
            FieldCourseUtil.visvalingamWhyattSimplification(boundaryPositions, 5)
            FieldCourseUtil.douglasPeucker(boundaryPositions, 0.5)
            local maxZ = 0
            local i = 1
            local i = 1
            for i = i, #boundaryPositions - 1, i do
                maxZ = maxZ + MathUtil.vector2Length(boundaryPositions[i][1] - boundaryPositions[i + 1][1], boundaryPositions[i][2] - boundaryPositions[i + 1][2])
                if FieldCourseField.MIN_BOUNDARY_LENGTH <= maxZ then
                    break
                end
            end
            if maxZ < FieldCourseField.MIN_BOUNDARY_LENGTH then
                self:finishTask(false)
            else
                self.boundaryPositions = boundaryPositions
                self.state = FieldCourseDetectionState.BOUNDARY_SEGMENT_CREATION
            end
            self.boundaryDetectionTask = nil
        else
            local maxZ = self.boundaryDetectionTask:getMaxZ()
            self.boundaryDetectionTask = BoundaryDetectionTask.new(self.startX, maxZ + self.terrainDetailResolution)
            if self.boundaryDetectionTask == nil then
                self:finishTask(false)
            else
                self.state = FieldCourseDetectionState.BOUNDARY_DETECTION
            end
        end
    elseif self.state == FieldCourseDetectionState.BOUNDARY_SEGMENT_CREATION then
        self.fieldRootBoundary = FieldCourseBoundary.createByBoundaryLine(self.boundaryPositions, self.segmentSplitAngle)
        if self.fieldRootBoundary == nil then
            self:finishTask(false)
        else
            self.state = FieldCourseDetectionState.BOUNDARY_SHRINK
        end
    elseif self.state == FieldCourseDetectionState.BOUNDARY_SHRINK then
        self.originalBoundary = self.fieldRootBoundary
        local boundaryPositions = self.fieldRootBoundary:extend(2.5)
        if boundaryPositions == nil then
            self.state = FieldCourseDetectionState.BOUNDARY_COLLISION_CHECK
        else
            self.fieldRootBoundary = boundaryPositions
            self.state = FieldCourseDetectionState.BOUNDARY_EXTENSION
        end
    elseif self.state == FieldCourseDetectionState.BOUNDARY_EXTENSION then
        self.fieldRootBoundary = self.fieldRootBoundary:extend(-2.5)
        if self.fieldRootBoundary == nil then
            self.fieldRootBoundary = self.originalBoundary
        end
        self.originalBoundary = nil
        if self.ignoreCollisions then
            if self.ignoreIslands then
                self:finishTask(true)
            else
                self:islandDetection(self.fieldRootBoundary.boundaryLine)
                self.state = FieldCourseDetectionState.ISLAND_DETECTION
            end
        else
            self.state = FieldCourseDetectionState.BOUNDARY_COLLISION_CHECK
        end
    elseif self.state == FieldCourseDetectionState.BOUNDARY_COLLISION_CHECK then
        if not self.boundaryCollisionCheckPending then
            self.boundaryCollisionCheckPending = true
            self.fieldRootBoundary:segmentCollisionOffset(5, 1, function(segmentsAdjusted)
                -- upvalues: (copy) self
                local boundaryLine = self.fieldRootBoundary.boundaryLine
                local i = 1
                for i = i, #boundaryLine do
                    boundaryLine[i][1], boundaryLine[i][2] = g_fieldCourseManager:roundToTerrainDetailPixel(boundaryLine[i][1], boundaryLine[i][2])
                end
                self.fieldRootBoundary:regenerateSegments()
                self.boundaryPositions = self.fieldRootBoundary.boundaryLine
                if self.ignoreIslands then
                    self:finishTask(true)
                else
                    self:islandDetection(self.fieldRootBoundary.boundaryLine)
                    self.state = FieldCourseDetectionState.ISLAND_DETECTION
                end
            end)
        end
    elseif self.state == FieldCourseDetectionState.ISLAND_DETECTION then
        if self.curIslandDetectionTask ~= nil and not self.curIslandDetectionTask:update(dt, frameBudget) then
            local boundaryPositions = self.curIslandDetectionTask.boundaryPositions
            FieldCourseUtil.pointAveragePositions(boundaryPositions)
            local maxZ = {}
            local i = #boundaryPositions
            local sx = 1
            local i = -1
            for i = i, sx, i do
                table.insert(maxZ, boundaryPositions[i])
            end
            FieldCourseUtil.semiConvexSimplification(maxZ, 15)
            local boundaryPositions = {}
            local i = #maxZ
            local sx = 1
            local i = -1
            for i = i, sx, i do
                table.insert(boundaryPositions, maxZ[i])
            end
            FieldCourseUtil.douglasPeucker(boundaryPositions, 0.25)
            FieldCourseUtil.visvalingamWhyattSimplification(boundaryPositions, 5)
            local sx = boundaryPositions[1][1]
            local i = boundaryPositions[1][2]
            local i = true
            for z2, island in ipairs(self.islandBoundaries) do
                if FieldCourseUtil.getAreBoundariesColliding(island.boundaryLine, boundaryPositions) then
                    i = false
                    break
                end
                if FieldCourseUtil.getIsPointInsideBoundary(sx, i, island.boundaryLine) then
                    i = false
                    break
                end
            end
            if i then
                local x1 = FieldCourseBoundary.createByBoundaryLine(boundaryPositions, self.segmentSplitAngle)
                if x1 ~= nil then
                    local z1 = x1:extend(-0.25)
                    if z1 == nil then
                        Logging.error("FieldCourseField: Failed to extend island boundary")
                    end
                    local x1 = z1 or x1
                    local x2 = x1.boundaryLine
                    local i = 1
                    for i = i, #x2 do
                        x2[i][1], x2[i][2] = g_fieldCourseManager:roundToTerrainDetailPixel(x2[i][1], x2[i][2])
                    end
                    x1:regenerateSegments()
                    table.insert(self.islandBoundaries, x1)
                end
            end
            self.curIslandDetectionTask = nil
            if #self.islandSamplePoints == 0 then
                self:finishTask(true)
            end
        end
        if (#self.islandSamplePoints > 0 or self.islandSamplePointsDetected == false) and not self:continueIslandDetection(frameBudget) then
            self:finishTask(true)
        end
    end
    local boundaryPositions = self.state ~= FieldCourseDetectionState.FINISHED
    return boundaryPositions
end
function FieldCourseField:setProtectedBoundary(protectedBoundarySize)
    self.protectedBoundary = self.fieldRootBoundary:extend(protectedBoundarySize) or self.fieldRootBoundary
    for _, island in ipairs(self.islands) do
        island.protectedBoundary = island.rootBoundary:extend(-protectedBoundarySize) or island.rootBoundary
    end
    return self.protectedBoundary
end
function FieldCourseField:finishTask(success)
    self.state = FieldCourseDetectionState.FINISHED
    if success then
        self.islands = {}
        for _, islandBoundary in ipairs(self.islandBoundaries) do
            table.insert(self.islands, {
                ["rootBoundary"] = islandBoundary,
                ["boundaries"] = {},
                ["hasCutSegments"] = false
            })
        end
        self.islandBoundaries = nil
    end
    if self.callbackTarget == nil then
        if self.callback ~= nil then
            self.callback(self, success)
        end
    else
        self.callback(self.callbackTarget, self, success)
    end
end
function FieldCourseField.generateBoundingBoxFromBoundary(_, boundary)
    if #boundary == 0 then
        return {
            0,
            0,
            0,
            0
        }
    end
    local boundingBox = {
        math.huge,
        -math.huge,
        math.huge,
        -math.huge
    }
    local i = 1
    for i = i, #boundary do
        boundingBox[1] = math.min(boundingBox[1], boundary[i][1])
        boundingBox[2] = math.max(boundingBox[2], boundary[i][1])
        boundingBox[3] = math.min(boundingBox[3], boundary[i][2])
        boundingBox[4] = math.max(boundingBox[4], boundary[i][2])
    end
    return boundingBox
end
function FieldCourseField:islandDetection(boundary)
    self.islandSamplePoints = {}
    self.islandSamplePointsDetected = false
    self.islandSamplePointsBoundingBox = self:generateBoundingBoxFromBoundary(boundary)
    self.islandSamplePointsLastX = self.islandSamplePointsBoundingBox[1]
    local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
    if groundTypeMapId == nil then
        self:finishTask(true)
    else
        self.islandSampleModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, g_terrainNode)
        self.islandSampleFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        self.islandSampleFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        if not self:continueIslandDetection(0) then
            self:finishTask(true)
        end
    end
end
function FieldCourseField:continueIslandDetection(frameBudget)
    if self.islandSamplePointsDetected then
        if self.curIslandDetectionTask == nil then
            while #self.islandSamplePoints > 0 do
                local startTime = self.islandSamplePoints[#self.islandSamplePoints]
                self.islandSamplePoints[#self.islandSamplePoints] = nil
                local rasterSize = true
                for x, delta in ipairs(self.islandBoundaries) do
                    if FieldCourseUtil.getIsPointInsideBoundary(startTime[1], startTime[2], delta.boundaryLine) then
                        rasterSize = false
                        break
                    end
                end
                if rasterSize then
                    self.curIslandDetectionTask = BoundaryDetectionTaskInsideOut.new(terrainDetailId, boundingBox)
                end
            end
        end
        local startTime = true
        if #self.islandSamplePoints <= 0 then
            startTime = self.curIslandDetectionTask ~= nil
        end
        return startTime
    end
    local startTime = getTimeSec()
    local terrainDetailId = g_currentMission.terrainDetailId
    local boundingBox = self.islandSamplePointsBoundingBox
    local x = self.islandSamplePointsLastX
    for x = x, boundingBox[2], 15 do
        local z = boundingBox[3]
        for z = z, boundingBox[4], 15 do
            local x2 = x + 15
            local z3 = z + 15
            self.islandSampleModifier:setParallelogramWorldCoords(x, z, x2, z, x, z3, DensityCoordType.POINT_POINT_POINT)
            local _, numPixels, totalPixels = self.islandSampleModifier:executeGet(self.islandSampleFilter)
            if numPixels < totalPixels then
                if FieldCourseUtil.getIsPointInsideBoundary(x, z, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(x2, z, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(x, z3, self.boundaryPositions) and FieldCourseUtil.getIsPointInsideBoundary(x + 15, z + 15, self.boundaryPositions))) then
                    local lastState = false
                    local foundPosition = false
                    for subX = x, x2 do
                        local z1 = z
                        z = z1
                        for z = z, z3 do
                            if getDensityAtWorldPos(terrainDetailId, subX, 0, z) ~= 0 ~= lastState then
                                lastState = not lastState
                                if not lastState and (FieldCourseUtil.getIsPointInsideBoundary(subX, z, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(subX + 2, z + 2, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(subX - 2, z - 2, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(subX - 2, z + 2, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(subX + 2, z - 2, self.boundaryPositions) and FieldCourseUtil.getDistanceToBoundary(subX, z, self.boundaryPositions) > 3))))) then
                                    foundPosition = true
                                    table.insert(self.islandSamplePoints, { subX, z })
                                end
                            end
                            if foundPosition then
                                break
                            end
                        end
                        if foundPosition then
                            break
                        end
                        z = z1
                    end
                end
            end
        end
        self.islandSamplePointsLastX = x + 15
        if frameBudget < getTimeSec() - startTime then
            break
        end
    end
    if self.islandSamplePointsLastX >= boundingBox[2] then
        self.islandSamplePointsDetected = true
        if #self.islandSamplePoints <= 0 then
            return false
        end
    end
    return true
end
function FieldCourseField:getIsPointInsideBoundary(x, z)
    return FieldCourseUtil.getIsPointInsideBoundary(x, z, self.boundaryPositions) or (FieldCourseUtil.getIsPointInsideBoundary(x + 2, z + 2, self.boundaryPositions) or FieldCourseUtil.getIsPointInsideBoundary(x - 2, z - 2, self.boundaryPositions) or (FieldCourseUtil.getIsPointInsideBoundary(x + 2, z - 2, self.boundaryPositions) or FieldCourseUtil.getIsPointInsideBoundary(x - 2, z + 2, self.boundaryPositions)))
end
function FieldCourseField:getBoundingBox()
    if #self.boundaryPositions == 0 then
        return 0, 0, 0, 0
    end
    local minX = math.huge
    local maxX = -math.huge
    local minZ = math.huge
    local maxZ = -math.huge
    for _, pos in ipairs(self.boundaryPositions) do
        minX = math.min(minX, pos[1])
        maxX = math.max(maxX, pos[1])
        minZ = math.min(minZ, pos[2])
        maxZ = math.max(maxZ, pos[2])
    end
    return minX, maxX, minZ, maxZ
end
function FieldCourseField:draw()
    if self.fieldRootBoundary ~= nil then
        self.fieldRootBoundary:draw(0, 0, 1, 0.2)
    end
    if self.protectedBoundary ~= nil then
        self.protectedBoundary:draw(1, 0, 0, 0.2)
    end
    if self.islands ~= nil then
        for _, island in ipairs(self.islands) do
            if island.rootBoundary ~= nil then
                island.rootBoundary:draw(0, 0, 1, 0.2)
            end
            if island.protectedBoundary ~= nil then
                island.protectedBoundary:draw(1, 0, 0, 0.2)
            end
        end
    end
end
function FieldCourseField.thightCornerExtension(boundaryPositions)
    local i = 1
    for i = i, #boundaryPositions - 2 do
        local x2 = boundaryPositions[i + 1][1]
        local z2 = boundaryPositions[i + 1][2]
        local dir1X, dir1Z = MathUtil.vector2Normalize(x2 - boundaryPositions[i][1], z2 - boundaryPositions[i][2])
        local dir2X, dir2Z = MathUtil.vector2Normalize(x2 - boundaryPositions[i + 2][1], z2 - boundaryPositions[i + 2][2])
        if 3.141592653589793 - math.acos((MathUtil.dotProduct(dir1X, 0, dir1Z, dir2X, 0, dir2Z))) > FieldCourseField.THIGHT_CORNER_ANGLE then
            boundaryPositions[i + 1][1] = x2 + dir1X * 0.1
            boundaryPositions[i + 1][2] = z2 + dir1Z * 0.1
            table.insert(boundaryPositions, i + 1, { x2 + dir2X * 0.1, z2 + dir2Z * 0.1 })
        end
    end
end
function FieldCourseField.registerXMLPaths(schema, path)
    schema:register(XMLValueType.STRING, path .. ".boundary#positions", "List of boundary positions (x z)")
    schema:register(XMLValueType.STRING, path .. ".island(?)#positions", "List of boundary positions (x z)")
end