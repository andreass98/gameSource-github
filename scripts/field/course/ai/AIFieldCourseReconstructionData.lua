AIFieldCourseReconstructionData = {}
local AIFieldCourseReconstructionData_mt = Class(AIFieldCourseReconstructionData)
function AIFieldCourseReconstructionData.new()
    -- upvalues: (copy) AIFieldCourseReconstructionData_mt
    local self = setmetatable({}, AIFieldCourseReconstructionData_mt)
    self.lastVehicleX = 0
    self.lastVehicleZ = 0
    self.fieldCourseField = nil
    self.fieldCourseSettings = nil
    self.activeSegmentId = nil
    self.fieldCourseSegments = {}
    return self
end
function AIFieldCourseReconstructionData:setDataByAIFieldCourse(aiFieldCourse)
    local activeSegment = aiFieldCourse.lastVehicleX
    local usedSegments = aiFieldCourse.lastVehicleZ
    self.lastVehicleX = activeSegment
    self.lastVehicleZ = usedSegments
    self.fieldCourseField = aiFieldCourse.fieldCourse.courseField
    self.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
    local activeSegment = aiFieldCourse:getActiveSegment()
    if activeSegment ~= nil then
        self.activeSegmentId = activeSegment.segmentId
    end
    local usedSegments = aiFieldCourse.usedSegments
    local excludedSegments = aiFieldCourse.segmentOrderTask.excludedSegments
    local segmentsToSkip = aiFieldCourse.segmentOrderTask.segmentsToSkip
    for _, segment in pairs(aiFieldCourse.fieldCourse.segments) do
        local segmentData = {
            ["segmentId"] = segment.segmentId,
            ["lineGroupIndex"] = segment.lineGroupIndex,
            ["isHeadlandSegment"] = segment.isHeadlandSegment,
            ["headlandIndex"] = segment.headlandIndex,
            ["isIslandSegment"] = segment.isIslandSegment,
            ["islandIndex"] = segment.islandIndex
        }
        local allSegmentsWorked = true
        for _, otherSegment in pairs(aiFieldCourse.fieldCourse.segments) do
            if otherSegment.segmentId == segment.segmentId and not (function(segment)
                -- upvalues: (copy) self, (copy) excludedSegments, (copy) segmentsToSkip, (copy) usedSegments
                if segment.segmentId == self.activeSegmentId then
                    return false
                end
                for excludedSegment, _ in pairs(excludedSegments) do
                    if excludedSegment.segmentId == segment.segmentId then
                        return true
                    end
                end
                if segmentsToSkip[segment.segmentId] ~= nil then
                    return true
                end
                return usedSegments[segment.segmentId] ~= nil
            end)(otherSegment) then
                allSegmentsWorked = false
                break
            end
        end
        segmentData.used = allSegmentsWorked
        table.insert(self.fieldCourseSegments, segmentData)
    end
end
function AIFieldCourseReconstructionData:saveToXML(xmlFile, key)
    xmlFile:setValue(key .. "#lastPosition", self.lastVehicleX, self.lastVehicleZ)
    if self.fieldCourseField ~= nil then
        self.fieldCourseField:saveToXML(xmlFile, key .. ".field")
    end
    if self.fieldCourseSettings ~= nil then
        self.fieldCourseSettings:saveToXML(xmlFile, key .. ".fieldCourseSettings")
    end
    if self.activeSegmentId ~= nil then
        xmlFile:setValue(key .. "#activeSegmentId", self.activeSegmentId)
    end
    local xmlIndex = 0
    for _, segmentData in pairs(self.fieldCourseSegments) do
        local segmentKey = string.format("%s.segments.segment(%d)", key, xmlIndex)
        xmlFile:setValue(segmentKey .. "#segmentId", segmentData.segmentId)
        xmlFile:setValue(segmentKey .. "#used", segmentData.used)
        if segmentData.lineGroupIndex ~= nil then
            xmlFile:setValue(segmentKey .. "#lineGroupIndex", segmentData.lineGroupIndex)
        end
        if segmentData.isHeadlandSegment then
            xmlFile:setValue(segmentKey .. "#isHeadlandSegment", segmentData.isHeadlandSegment)
            xmlFile:setValue(segmentKey .. "#headlandIndex", segmentData.headlandIndex)
        end
        if segmentData.isIslandSegment then
            xmlFile:setValue(segmentKey .. "#isIslandSegment", segmentData.isIslandSegment)
            xmlFile:setValue(segmentKey .. "#islandIndex", segmentData.islandIndex)
        end
        xmlIndex = xmlIndex + 1
    end
end
function AIFieldCourseReconstructionData:loadFromXML(xmlFile, key)
    self.lastVehicleX, self.lastVehicleZ = xmlFile:getValue(key .. "#lastPosition", "0 0")
    self.fieldCourseSettings = FieldCourseSettings.loadFromXML(xmlFile, key .. ".fieldCourseSettings")
    if self.fieldCourseSettings == nil then
        Logging.warning("Failed to load FieldCourseSettings from xml")
        return false
    end
    self.fieldCourseField = FieldCourseField.new(self.fieldCourseSettings)
    if not self.fieldCourseField:loadFromXML(xmlFile, key .. ".field") then
        Logging.warning("Failed to load FieldCourseField from xml")
        return false
    end
    self.activeSegmentId = xmlFile:getValue(key .. "#activeSegmentId")
    self.fieldCourseSegments = {}
    for _, segmentKey in xmlFile:iterator(key .. ".segments.segment") do
        local segmentData = {
            ["segmentId"] = xmlFile:getValue(segmentKey .. "#segmentId")
        }
        if segmentData.segmentId ~= nil then
            segmentData.used = xmlFile:getValue(segmentKey .. "#used", false)
            segmentData.lineGroupIndex = xmlFile:getValue(segmentKey .. "#lineGroupIndex")
            segmentData.isHeadlandSegment = xmlFile:getValue(segmentKey .. "#isHeadlandSegment", false)
            segmentData.headlandIndex = xmlFile:getValue(segmentKey .. "#headlandIndex")
            segmentData.isIslandSegment = xmlFile:getValue(segmentKey .. "#isIslandSegment", false)
            segmentData.islandIndex = xmlFile:getValue(segmentKey .. "#islandIndex")
            table.insert(self.fieldCourseSegments, segmentData)
        end
    end
    self:generateFieldCourse()
    return true
end
function AIFieldCourseReconstructionData:generateFieldCourse()
    if self.fieldCourse == nil and not self.fieldCourseInProgress then
        local generator = FieldCourseSegmentGenerator.new(self.fieldCourseSettings, function(segments, _, isVineyardCourse)
            -- upvalues: (copy) self
            if #segments > 0 then
                self.fieldCourse = FieldCourse.new(self.fieldCourseSettings, self.fieldCourseField, isVineyardCourse)
                self.fieldCourse:addSegments(segments)
                self.fieldCourseInProgress = false
            else
                Logging.devWarning("Unable to generate field course based on savegame data")
            end
            if self.callback ~= nil then
                self:doCallback()
            end
        end)
        self.fieldCourseField.headlandBoundaries = {}
        generator:setFieldData(self.fieldCourseField)
        self.fieldCourseInProgress = true
        generator:generate()
    end
end
function AIFieldCourseReconstructionData:apply(callbackTarget, callback, vx, vz)
    if self.lastVehicleX == nil or self.lastVehicleZ == nil then
        Logging.devInfo("AIFieldCourseReconstructionData: No last vehicle position available. Completely regenerate field course.")
        return false
    end
    if MathUtil.vector2Length(vx - self.lastVehicleX, vz - self.lastVehicleZ) > 25 then
        Logging.devInfo("AIFieldCourseReconstructionData: Vehicle has moved too far. Completely regenerate field course.")
        return false
    end
    if not FieldCourseUtil.getIsPointInsideBoundary(vx, vz, self.fieldCourseField.boundaryPositions) then
        Logging.devInfo("AIFieldCourseReconstructionData: Vehicle is not inside the field anymore. Completely regenerate field course.")
        return false
    end
    self.callbackTarget = callbackTarget
    self.callback = callback
    self:generateFieldCourse()
    if self.fieldCourse ~= nil then
        self:doCallback()
    end
    return true
end
function AIFieldCourseReconstructionData:doCallback()
    if self.callback ~= nil then
        local aiFieldCourse = AIFieldCourse.new(self.fieldCourse)
        local numSkippedSegments = 0
        local segmentsToSkip = {}
        local isValid = true
        for _, segment in pairs(self.fieldCourse.segments) do
            for _, segmentData in pairs(self.fieldCourseSegments) do
                if segment.segmentId == segmentData.segmentId then
                    if segmentData.lineGroupIndex ~= segment.lineGroupIndex then
                        isValid = false
                    end
                    if segmentData.isHeadlandSegment ~= segment.isHeadlandSegment then
                        isValid = false
                    end
                    if segmentData.headlandIndex ~= segment.headlandIndex then
                        isValid = false
                    end
                    if segmentData.isIslandSegment ~= segment.isIslandSegment then
                        isValid = false
                    end
                    if segmentData.islandIndex ~= segment.islandIndex then
                        isValid = false
                    end
                    if segmentData.used then
                        segmentsToSkip[segment.segmentId] = true
                    end
                    break
                end
            end
        end
        if isValid then
            Logging.devInfo("AIFieldCourseReconstructionData: Reconstructed field course from savegame. Skipping %d already worked segments.", numSkippedSegments)
        else
            Logging.devInfo("AIFieldCourseReconstructionData: Loaded field course from savegame does not match the generated one. Dismiss worked data.")
            segmentsToSkip = nil
        end
        if segmentsToSkip ~= nil then
            aiFieldCourse:setSegmentsToSkip(segmentsToSkip)
        end
        if self.activeSegmentId ~= nil then
            aiFieldCourse:setLastActiveSegmentId(self.activeSegmentId)
        end
        self.callback(self.callbackTarget, aiFieldCourse)
        self.callbackTarget = nil
        self.callback = nil
    end
end
function AIFieldCourseReconstructionData.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.VECTOR_2, basePath .. "#lastPosition", "Last vehicle position in world space")
    FieldCourseSettings.registerXMLPaths(schema, basePath .. ".fieldCourseSettings")
    FieldCourseField.registerXMLPaths(schema, basePath .. ".field")
    schema:register(XMLValueType.INT, basePath .. "#activeSegmentId", "Identifier of the currently active segment")
    schema:register(XMLValueType.INT, basePath .. ".segments.segment(?)#segmentId", "Identifier of the segment")
    schema:register(XMLValueType.BOOL, basePath .. ".segments.segment(?)#used", "Segment has been worked already")
    schema:register(XMLValueType.INT, basePath .. ".segments.segment(?)#lineGroupIndex", "Line group index")
    schema:register(XMLValueType.BOOL, basePath .. ".segments.segment(?)#isHeadlandSegment", "Is headland segment")
    schema:register(XMLValueType.INT, basePath .. ".segments.segment(?)#headlandIndex", "Headland index")
    schema:register(XMLValueType.BOOL, basePath .. ".segments.segment(?)#isIslandSegment", "Is island segment")
    schema:register(XMLValueType.INT, basePath .. ".segments.segment(?)#islandIndex", "Island index")
end