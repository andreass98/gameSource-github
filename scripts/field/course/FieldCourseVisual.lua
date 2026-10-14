FieldCourseVisual = {}
FieldCourseVisual.ACTIVE_LINE_UPDATE_THRESHOLD = 2.5
FieldCourseVisual.NUM_VISIBLE_TILES = 3
FieldCourseVisual.TERRAIN_OFFSET = 0.05
FieldCourseVisual.VISUALS = {}
FieldCourseVisual.VISUALS[false] = {}
FieldCourseVisual.VISUALS[false].ACTIVE = {
    {
        0,
        1,
        0,
        1
    },
    0.25,
    2.25,
    true
}
FieldCourseVisual.VISUALS[false].AVAILABLE = {
    {
        1,
        0.3,
        0,
        1
    },
    0.25,
    5,
    true
}
FieldCourseVisual.VISUALS[false].INACTIVE = {
    {
        0.8,
        0.8,
        0.8,
        1
    },
    1,
    1.25,
    true
}
FieldCourseVisual.VISUALS[false].WORKED = {
    {
        0.2,
        0.2,
        0.2,
        1
    },
    0.5,
    0.75,
    true
}
FieldCourseVisual.VISUALS[false].TOOL_SIDE = {
    {
        0,
        0,
        1,
        1
    },
    1,
    1,
    true
}
FieldCourseVisual.VISUALS[false].HIDDEN = {
    {
        0,
        0,
        0,
        1
    },
    0,
    0,
    false
}
FieldCourseVisual.VISUALS[true] = {}
FieldCourseVisual.VISUALS[true].ACTIVE = {
    {
        0.0423,
        0.2502,
        0.8069,
        1
    },
    0.25,
    9,
    true,
    {
        0.9473,
        0.5271,
        0,
        0.015,
        1
    }
}
FieldCourseVisual.VISUALS[true].AVAILABLE = {
    {
        0.9473,
        0.5271,
        0,
        1
    },
    0.25,
    9,
    true,
    {
        0.0423,
        0.2502,
        0.8069,
        0.015,
        1
    }
}
FieldCourseVisual.VISUALS[true].INACTIVE = {
    {
        0.8,
        0.8,
        0.8,
        1
    },
    1,
    2.5,
    true
}
FieldCourseVisual.VISUALS[true].WORKED = {
    {
        0.2,
        0.2,
        0.2,
        1
    },
    0.5,
    1.5,
    true
}
FieldCourseVisual.VISUALS[true].TOOL_SIDE = {
    {
        0,
        0.0742,
        0.0513,
        1
    },
    2,
    3,
    true,
    nil,
    { 1, 0.75 }
}
FieldCourseVisual.VISUALS[true].HIDDEN = {
    {
        0,
        0,
        0,
        1
    },
    0,
    0,
    false
}
FieldCourseVisual.VISUALS_FILENAME = "data/shared/ai/fieldCourseVisuals.i3d"
source("dataS/scripts/field/course/FieldCourseVisualTile.lua")
local FieldCourseVisual_mt = Class(FieldCourseVisual)
function FieldCourseVisual.new()
    -- upvalues: (copy) FieldCourseVisual_mt
    local self = setmetatable({}, FieldCourseVisual_mt)
    self.fieldCourse = nil
    self.vehicle = nil
    self.rootSegmentsByLength = {}
    self.lineSegmentPoolByLength = {}
    self.segmentIndexToData = {}
    self.lastActiveSegmentIndex = -1
    self.lastSteeringIsEnabled = false
    self.lastActiveSegmentIsLeft = false
    self.lastCameraPosition = { 0, 0 }
    self.lastSideOffsetReversed = false
    self.updateDirty = false
    self.isColorBlindMode = Utils.getNoNil(g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE), false)
    self.tiles = {}
    self.linkNode = createTransformGroup("FieldCourseVisual_linkNode")
    link(getRootNode(), self.linkNode)
    setVisibility(self.linkNode, false)
    self.loadRequestId = g_i3DManager:loadI3DFileAsync(FieldCourseVisual.VISUALS_FILENAME, true, false, FieldCourseVisual.onVisualsLoaded, self, nil)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.onColorBlindModeChanged, self)
    return self
end
function FieldCourseVisual:delete()
    if self.loadRequestId ~= nil then
        g_i3DManager:cancelStreamI3DFile(self.loadRequestId)
        self.loadRequestId = nil
    end
    self:setActiveSteeringFieldCourse(nil)
    for _, tile in ipairs(self.tiles) do
        tile:reset()
    end
    if self.rootSegmentsByLength ~= nil then
        local i = #self.rootSegmentsByLength
        for i = i, 1, -1 do
            delete(self.rootSegmentsByLength[i])
        end
        self.rootSegmentsByLength = nil
    end
    if self.lineSegmentPoolByLength ~= nil then
        local i = #self.lineSegmentPoolByLength
        for i = i, 1, -1 do
            local j = #self.lineSegmentPoolByLength[i]
            for j = j, 1, -1 do
                delete(self.lineSegmentPoolByLength[i][j])
            end
        end
        self.lineSegmentPoolByLength = nil
    end
    if self.linkNode ~= nil then
        delete(self.linkNode)
        self.linkNode = nil
    end
    g_messageCenter:unsubscribeAll(self)
end
function FieldCourseVisual:setActiveSteeringFieldCourse(fieldCourse, vehicle)
    self.fieldCourse = fieldCourse
    self.vehicle = vehicle
    for _, tile in ipairs(self.tiles) do
        tile:reset()
    end
    if fieldCourse == nil then
        g_fieldCourseManager:removeUpdateable(self)
        self.fieldCourseSettings = nil
    else
        g_fieldCourseManager:addUpdateable(self)
        self.fieldCourseSettings = fieldCourse.fieldCourseSettings
    end
    setVisibility(self.linkNode, fieldCourse ~= nil)
    self.updateDirty = true
end
function FieldCourseVisual:update(_)
    if self.vehicle == nil or (not self.vehicle:getIsActiveForInput(true) or (g_noHudModeEnabled or not g_gameSettings:getValue(GameSettings.SETTING.STEERING_ASSIST_LINES))) then
        setVisibility(self.linkNode, false)
        return
    end
    setVisibility(self.linkNode, true)
    local cx, _, cz = getWorldTranslation(g_cameraManager:getActiveCamera())
    local vy = self.lastCameraPosition[1] - cx
    if math.abs(vy) <= FieldCourseVisual.ACTIVE_LINE_UPDATE_THRESHOLD then
        local vy = self.lastCameraPosition[2] - cz
        if math.abs(vy) <= FieldCourseVisual.ACTIVE_LINE_UPDATE_THRESHOLD and not self.updateDirty then
            ::l9::
            if self.lastActiveSegmentIndex ~= self.fieldCourse.currentSegmentIndex or (self.lastActiveSegmentIsLeft ~= self.fieldCourse.currentSegmentIsLeft or (self.lastSteeringIsEnabled ~= self.fieldCourse.vehicleSteeringEnabled or self.updateDirty)) then
                if self.lastActiveSegmentIndex ~= self.fieldCourse.currentSegmentIndex or self.updateDirty then
                    local segment = self.fieldCourse.segments[self.fieldCourse.currentSegmentIndex]
                    if segment == nil then
                        self.toolSideSegmentLeft = nil
                        self.toolSideSegmentRight = nil
                        self.toolSideOffsetSegmentLeft = nil
                        self.toolSideOffsetSegmentRight = nil
                    else
                        self.toolSideSegmentLeft = table.clone(segment, 3)
                        FieldCourseUtil.segmentApplySideOffset(self.toolSideSegmentLeft, -(self.fieldCourseSettings.implementWidth * 0.5))
                        self.toolSideSegmentRight = table.clone(segment, 3)
                        FieldCourseUtil.segmentApplySideOffset(self.toolSideSegmentRight, self.fieldCourseSettings.implementWidth * 0.5)
                        if not (segment.isHeadlandSegment or segment.isIslandSegment) then
                            FieldCourseUtil.extendSegmentToBoundary(self.toolSideSegmentLeft.positions, self.fieldCourse.rootBoundaryLine)
                            FieldCourseUtil.extendSegmentToBoundary(self.toolSideSegmentRight.positions, self.fieldCourse.rootBoundaryLine)
                        end
                        if self.fieldCourseSettings.sideOffset ~= 0 then
                            self.toolSideOffsetSegmentLeft = table.clone(segment, 3)
                            FieldCourseUtil.segmentApplySideOffset(self.toolSideOffsetSegmentLeft, self.fieldCourseSettings.sideOffset)
                            self.toolSideOffsetSegmentRight = table.clone(segment, 3)
                            FieldCourseUtil.segmentApplySideOffset(self.toolSideOffsetSegmentRight, -self.fieldCourseSettings.sideOffset)
                        end
                    end
                    for _, tile in ipairs(self.tiles) do
                        if tile.isValid then
                            tile:resetAdditionalSegments()
                            tile:fillAdditionalTileSegment(self.toolSideSegmentLeft, self.fieldCourse.currentSegmentIndex, true, false, false)
                            tile:fillAdditionalTileSegment(self.toolSideSegmentRight, self.fieldCourse.currentSegmentIndex, true, false, false)
                            tile:fillAdditionalTileSegment(self.toolSideOffsetSegmentLeft, self.fieldCourse.currentSegmentIndex, false, true, false)
                            tile:fillAdditionalTileSegment(self.toolSideOffsetSegmentRight, self.fieldCourse.currentSegmentIndex, false, false, true)
                        end
                    end
                end
                local segment = self.fieldCourse.segments
                for _, tile in ipairs(segment) do
                    local visualData
                    if self.fieldCourse.vehicleSteeringEnabled then
                        if _ == self.fieldCourse.currentSegmentIndex then
                            visualData = FieldCourseVisual.VISUALS[self.isColorBlindMode].ACTIVE
                        else
                            visualData = FieldCourseVisual.VISUALS[self.isColorBlindMode].HIDDEN
                        end
                    elseif _ == self.fieldCourse.currentSegmentIndex then
                        visualData = FieldCourseVisual.VISUALS[self.isColorBlindMode].AVAILABLE
                    elseif self.fieldCourse.segmentStates[_] then
                        visualData = FieldCourseVisual.VISUALS[self.isColorBlindMode].WORKED
                    else
                        visualData = FieldCourseVisual.VISUALS[self.isColorBlindMode].INACTIVE
                    end
                    self.segmentIndexToData[_] = visualData
                end
                for _, tile in ipairs(self.tiles) do
                    if tile.isValid then
                        tile:setSegmentData(self.segmentIndexToData, self.fieldCourse.vehicleSteeringEnabled, self.fieldCourse.currentSegmentIsLeft, self.fieldCourse.currentSegmentIndex)
                    end
                end
                self.lastActiveSegmentIndex = self.fieldCourse.currentSegmentIndex
                self.lastActiveSegmentIsLeft = self.fieldCourse.currentSegmentIsLeft
                self.lastSteeringIsEnabled = self.fieldCourse.vehicleSteeringEnabled
            end
            local segment, vy, vz, qx, _, tile, visualData, extendX, extendY, extendZ = self.vehicle:getAIRootNodeBoundingBox()
            setMaterialCustomParameter(self.lineMaterial, "boxPosition", segment, vy, vz, 0, true)
            setMaterialCustomParameter(self.lineMaterial, "boxQuaternion", qx, _, tile, visualData, true)
            setMaterialCustomParameter(self.lineMaterial, "boxHalfExtent", extendX + 1, extendY + 1, extendZ + 1, 0, true)
            self.updateDirty = false
            return
        end
    end
    self:updateTiles(cx, cz)
    self.lastCameraPosition[1] = cx
    self.lastCameraPosition[2] = cz
    goto l9
end
function FieldCourseVisual:updateTiles(cx, cz)
    local halfTerrainSize = g_currentMission.terrainSize * 0.5
    local centerX = (cx + halfTerrainSize) / FieldCourseVisualTile.TILE_SIZE
    local centerZ = (cz + halfTerrainSize) / FieldCourseVisualTile.TILE_SIZE
    local numVisibleTiles = MathUtil.round(centerX)
    local centerTiltZ = MathUtil.round(centerZ)
    local numVisibleTiles = FieldCourseVisual.NUM_VISIBLE_TILES
    for _, tile in ipairs(self.tiles) do
        tile.isValid = false
    end
    local x = -numVisibleTiles
    for x = x, numVisibleTiles do
        local z = -numVisibleTiles
        local tile = 1
        for z = z, numVisibleTiles, tile do
            local tx = numVisibleTiles + x
            local tz = centerTiltZ + z
            if MathUtil.vector2Length(tx - centerX, tz - centerZ) < FieldCourseVisual.NUM_VISIBLE_TILES + 0.71 then
                for _, tile in ipairs(self.tiles) do
                    if tile.index == tx + tz * (g_currentMission.terrainSize / FieldCourseVisualTile.TILE_SIZE) then
                        tile.isValid = true
                        break
                    end
                end
            end
        end
    end
    local x = -numVisibleTiles
    for x = x, numVisibleTiles do
        local z = -numVisibleTiles
        local tile = 1
        for z = z, numVisibleTiles, tile do
            local tx = numVisibleTiles + x
            local tz = centerTiltZ + z
            if MathUtil.vector2Length(tx - centerX, tz - centerZ) < tileClipDistance then
                local hasTile = false
                for tile, tile in ipairs(self.tiles) do
                    if tile.index == tx + tz * numRows then
                        hasTile = true
                    end
                end
                if not hasTile then
                    local tileToUse = nil
                    for tile, tile in ipairs(self.tiles) do
                        if not tile.isValid then
                            tileToUse = tile
                            break
                        end
                    end
                    if tileToUse == nil then
                        tileToUse = FieldCourseVisualTile.new(self)
                        table.insert(self.tiles, tileToUse)
                    end
                    tileToUse:init(tileIndex)
                    self.updateDirty = true
                end
            end
        end
    end
    for _, tile in ipairs(self.tiles) do
        if not tile.isValid and tile.index >= 0 then
            tile:reset()
        end
    end
end
function FieldCourseVisual:getMaxVisualLineLength()
    return #self.rootSegmentsByLength
end
function FieldCourseVisual:getVisualSegment(length)
    local lineSegmentPool = MathUtil.round(length)
    local absLength = math.clamp(lineSegmentPool, 1, #self.rootSegmentsByLength)
    local lineSegmentPool = self.lineSegmentPoolByLength[absLength]
    if #lineSegmentPool > 0 then
        local lineSegment = lineSegmentPool[1]
        table.remove(lineSegmentPool, 1)
        setVisibility(lineSegment, true)
        return lineSegment
    end
    local lineSegment = clone(self.rootSegmentsByLength[absLength], false, false, false)
    link(self.linkNode, lineSegment)
    setVisibility(lineSegment, true)
    setMaterial(lineSegment, self.lineMaterial, 0)
    return lineSegment
end
function FieldCourseVisual:releaseVisualSegment(lineSegment)
    local absLength = getUserAttribute(lineSegment, "segmentLength")
    local lineSegmentPool = self.lineSegmentPoolByLength[absLength]
    if lineSegmentPool ~= nil then
        table.insert(lineSegmentPool, lineSegment)
        setVisibility(lineSegment, false)
    end
end
function FieldCourseVisual:onVisualsLoaded(i3dNode)
    if i3dNode ~= 0 then
        local i = 1
        local lineSegment = getNumOfChildren(i3dNode)
        for i = i, lineSegment do
            local lineSegment = getChildAt(i3dNode, i - 1)
            setVisibility(lineSegment, false)
            setObjectMask(lineSegment, 127)
            setUserAttribute(lineSegment, "segmentLength", UserAttributeType.INTEGER, i)
            self.rootSegmentsByLength[i] = lineSegment
            self.lineSegmentPoolByLength[i] = {}
            if self.lineMaterial == nil then
                setShaderParameter(lineSegment, "terrainOffset", math.random(), 0, 0, 0, false)
                self.lineMaterial = getMaterial(lineSegment, 0)
                setMaterialCustomParameter(self.lineMaterial, "terrainOffset", FieldCourseVisual.TERRAIN_OFFSET, 0, 0, 0, true)
            end
        end
        if self.linkNode ~= nil then
            local i = 1
            for i = i, #self.rootSegmentsByLength do
                link(self.linkNode, self.rootSegmentsByLength[i])
            end
        end
        delete(i3dNode)
    end
    self.loadRequestId = nil
end
function FieldCourseVisual:onColorBlindModeChanged()
    self.isColorBlindMode = Utils.getNoNil(g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE), false)
    self.updateDirty = true
end