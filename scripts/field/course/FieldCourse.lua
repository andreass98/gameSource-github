FieldCourse = {}
local FieldCourse_mt = Class(FieldCourse)
FieldCourse.MIN_SEGMENT_LENGTH = 1
function FieldCourse.new(fieldCourseSettings, courseField, isVineyardCourse)
    -- upvalues: (copy) FieldCourse_mt
    local self = setmetatable({}, FieldCourse_mt)
    self.fieldCourseSettings = fieldCourseSettings
    self.courseField = courseField
    self.isVineyardCourse = isVineyardCourse
    self.isUICourse = false
    self.segments = {}
    self.totalLength = 0
    self.numHeadlands = 0
    return self
end
function FieldCourse.generateByFieldPosition(x, z, fieldCourseSettings, callback)
    local generator = FieldCourseSegmentGenerator.new(fieldCourseSettings, function(segments, courseField, isVineyardCourse)
        -- upvalues: (copy) fieldCourseSettings, (copy) callback
        if #segments > 0 then
            local fieldCourse = FieldCourse.new(fieldCourseSettings, courseField, isVineyardCourse)
            fieldCourse:addSegments(segments)
            callback(fieldCourse)
        else
            callback()
        end
    end)
    generator:setStartPosition(x, z)
    generator:generate()
end
function FieldCourse.generateUICourseByFieldPosition(x, z, fieldCourseSettings, callback)
    local generator = FieldCourseSegmentGenerator.new(fieldCourseSettings, function(segments, courseField, isVineyardCourse)
        -- upvalues: (copy) fieldCourseSettings, (copy) callback
        if #segments > 0 then
            local fieldCourse = FieldCourse.new(fieldCourseSettings, courseField, isVineyardCourse)
            fieldCourse:addSegments(segments)
            fieldCourse.isUICourse = true
            callback(fieldCourse)
        else
            callback()
        end
    end)
    generator:setStartPosition(x, z)
    generator:setIsUICourse()
    generator:generate()
end
function FieldCourse:updateFieldCourseSettings(fieldCourseSettings, callback)
    local generator = FieldCourseSegmentGenerator.new(fieldCourseSettings, function(segments, _, isVineyardCourse)
        -- upvalues: (copy) self, (copy) callback
        if #segments > 0 then
            self.segments = {}
            self:addSegments(segments)
            self.isVineyardCourse = isVineyardCourse
            callback(true)
        else
            callback(false)
        end
    end)
    self.courseField:reset()
    if self.isUICourse then
        generator:setIsUICourse()
    end
    generator:setFieldData(self.courseField)
    generator:generate()
end
function FieldCourse:addSegments(segments)
    for i, segment in ipairs(segments) do
        table.insert(self.segments, segment)
    end
    self.totalLength = 0
    self.numHeadlands = 0
    for i, segment in ipairs(self.segments) do
        segment.index = i
        segment.segmentId = i
        self.totalLength = self.totalLength + segment.length
        self.numHeadlands = math.max(segment.headlandIndex or 0, self.numHeadlands)
    end
end
function FieldCourse:writeStream(streamId, connection)
    self.fieldCourseSettings:writeStream(streamId, connection)
    if streamWriteBool(streamId, self.courseField ~= nil) then
        self.courseField:writeStream(streamId, connection)
    end
end
function FieldCourse.readStream(streamId, connection, callback)
    local fieldCourseSettings = FieldCourseSettings.new()
    fieldCourseSettings:applyAttributes((FieldCourseSettings.readStream(streamId, connection)))
    local courseField = nil
    if streamReadBool(streamId) then
        courseField = FieldCourseField.new(fieldCourseSettings)
        courseField:readStream(streamId, connection)
    end
    local generator = FieldCourseSegmentGenerator.new(fieldCourseSettings, function(segments, _, isVineyardCourse)
        -- upvalues: (copy) fieldCourseSettings, (ref) courseField, (copy) callback
        if #segments > 0 then
            local fieldCourse = FieldCourse.new(fieldCourseSettings, courseField, isVineyardCourse)
            fieldCourse:addSegments(segments)
            callback(fieldCourse)
        else
            callback()
        end
    end)
    generator:setFieldData(courseField)
    generator:generate()
end
function FieldCourse:saveToXML(xmlFile, key)
    if self.courseField ~= nil then
        self.courseField:saveToXML(xmlFile, key .. ".field")
    end
    if self.fieldCourseSettings ~= nil then
        self.fieldCourseSettings:saveToXML(xmlFile, key .. ".fieldCourseSettings")
    end
end
function FieldCourse.loadFromXML(xmlFile, key, callback)
    local fieldCourseSettings = FieldCourseSettings.loadFromXML(xmlFile, key .. ".fieldCourseSettings")
    if fieldCourseSettings == nil then
        callback(nil)
        return false
    end
    local courseField = FieldCourseField.new(fieldCourseSettings)
    if not courseField:loadFromXML(xmlFile, key .. ".field") then
        callback(nil)
        return false
    end
    local generator = FieldCourseSegmentGenerator.new(fieldCourseSettings, function(segments, _, isVineyardCourse)
        -- upvalues: (copy) fieldCourseSettings, (copy) courseField, (copy) callback
        if #segments > 0 then
            local fieldCourse = FieldCourse.new(fieldCourseSettings, courseField, isVineyardCourse)
            fieldCourse:addSegments(segments)
            callback(fieldCourse)
        else
            callback()
        end
    end)
    generator:setFieldData(courseField)
    generator:generate()
    return true
end
function FieldCourse:draw()
    if self.courseField ~= nil then
        self.courseField:draw()
    end
    for _, segment in pairs(self.segments) do
        local r = 0
        local g = 1
        local b = 1
        if segment.isIslandSegment then
            r = 0
            g = 0.5
            b = 0.5
        elseif segment.isHeadlandSegment then
            r = 0
            g = 0.2
            b = 0.2
        end
        local numPositions = #segment.positions
        local i = 1
        for i = i, numPositions - 1 do
            local x1 = segment.positions[i][1]
            local z1 = segment.positions[i][2]
            local x2 = segment.positions[i + 1][1]
            local z2 = segment.positions[i + 1][2]
            local y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + (segment.yOffset or 0.5)
            local y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + (segment.yOffset or 0.5)
            drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b, true)
            drawDebugPoint(x1, y1, z1, r, g, b, 1, true)
            if i + 1 == numPositions then
                drawDebugPoint(x2, y2, z2, r, g, b, 1, true)
            end
        end
    end
end
function FieldCourse.registerXMLPaths(schema, path)
    FieldCourseSettings.registerXMLPaths(schema, path .. ".fieldCourseSettings")
    FieldCourseField.registerXMLPaths(schema, path .. ".field")
end
function FieldCourse.findClosestField(x, z, dirX, dirZ, farmId, vehicle, intoFieldOffset, fieldCourseSettings)
    if x == nil or (z == nil or (dirX == nil or dirZ == nil)) then
        local rootNode = vehicle:getAISteeringNode()
        local i
        x, i, z = getWorldTranslation(rootNode)
        local i
        dirX, i, dirZ = localDirectionToWorld(rootNode, 0, 0, vehicle:getReverserDirection())
    end
    if fieldCourseSettings ~= nil then
    end
    intoFieldOffset = intoFieldOffset or 2
    local i = 1
    for i = i, 6 do
        local isOnField, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(x, 0, z)
        if isOnField then
            x = x + dirX * intoFieldOffset
            z = z + dirZ * intoFieldOffset
            local offsetIsOnField, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(x, 0, z)
            if offsetIsOnField then
                if g_currentMission.accessHandler:canFarmAccessLand(farmId, x, z) or g_missionManager:getIsMissionWorkAllowed(farmId, x, z, nil, vehicle) then
                    return x, z, false
                else
                    return nil, nil, true
                end
            end
            break
        end
        x = x + dirX * 5
        z = z + dirZ * 5
    end
    return nil, nil, false
end