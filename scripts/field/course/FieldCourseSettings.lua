FieldCourseSettings = {}
FieldCourseSettings.NUM_HEADLANDS_SYNC_BITS = 4
FieldCourseSettings.MAX_HEADLAND_AMOUNT = 2 ^ FieldCourseSettings.NUM_HEADLANDS_SYNC_BITS - 1
FieldCourseSettings.SETTINGS = {}
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "implementWidth",
    ["default"] = 10,
    ["title"] = "Implement width",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = true,
    ["min"] = 0.5,
    ["max"] = 60
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "numHeadlands",
    ["default"] = 2,
    ["title"] = "Number of headlands",
    ["xmlValueType"] = XMLValueType.INT,
    ["customizable"] = true,
    ["min"] = 1,
    ["max"] = 10
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "headlandsFirst",
    ["default"] = false,
    ["title"] = "Headlands first",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = true
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "skipNumLines",
    ["default"] = 0,
    ["title"] = "Skip Num Lines",
    ["xmlValueType"] = XMLValueType.INT,
    ["customizable"] = true,
    ["min"] = 0,
    ["max"] = 10
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "workHeadlands",
    ["default"] = true,
    ["title"] = "Work headlands",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = true
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "workDirection",
    ["default"] = -1,
    ["title"] = "Work direction",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = true,
    ["min"] = -1,
    ["max"] = 3.141592653589793,
    ["formatFunc"] = function(v)
        return v > 0 and math.deg(v) or "Automatic"
    end
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "workInitialSegment",
    ["default"] = false,
    ["title"] = "Work initial segment",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "minTurnRadius",
    ["default"] = 8,
    ["title"] = "Minimum turn radius",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false,
    ["min"] = 1,
    ["max"] = 20
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "initialTurnRadiusFactor",
    ["default"] = 1,
    ["title"] = "Initial turn radius factor",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false,
    ["min"] = 1,
    ["max"] = 5
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "canTurnBackward",
    ["default"] = true,
    ["title"] = "Can turn backward",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "allowStraightReversing",
    ["default"] = true,
    ["title"] = "Allow straight reversing",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "isVineyardTool",
    ["default"] = false,
    ["title"] = "Is vineyard tool",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "isVineyardRowTool",
    ["default"] = false,
    ["title"] = "Is vineyard row tool",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "headlandTailAvoidance",
    ["default"] = false,
    ["title"] = "Headland tail avoidance",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "rowSpacing",
    ["default"] = 0,
    ["title"] = "Row Spacing",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "rowSnapAngle",
    ["default"] = 0,
    ["title"] = "Row Snap Angle",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "rowOffset",
    ["default"] = 0,
    ["title"] = "Row Offset",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "cornerCutOutSupported",
    ["default"] = false,
    ["title"] = "Corner cut out supported",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "toolFrontOffset",
    ["default"] = 0,
    ["title"] = "Front offset of the tool",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false,
    ["min"] = -25,
    ["max"] = 25
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "toolBackOffset",
    ["default"] = 0,
    ["title"] = "Back offset of the tool",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false,
    ["min"] = -25,
    ["max"] = 25
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "hasStaticTools",
    ["default"] = false,
    ["title"] = "Has static tools",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "toolFullOverlap",
    ["default"] = false,
    ["title"] = "Tool full overlap",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "toolFullOverlapInside",
    ["default"] = false,
    ["title"] = "Tool full overlap inside",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "segmentExtendedToBoundary",
    ["default"] = false,
    ["title"] = "Segments Extended to Boundary",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "segmentHeadlandReverseLines",
    ["default"] = false,
    ["title"] = "Segments Headland Rev. Lines",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "segmentMinOffset",
    ["default"] = 0,
    ["title"] = "Segment Min. Offset",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "segmentMinLength",
    ["default"] = 0,
    ["title"] = "Segment Min. Length",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "sideOffset",
    ["default"] = 0,
    ["title"] = "Side offset",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false,
    ["min"] = -10,
    ["max"] = 10
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "variableSideOffset",
    ["default"] = false,
    ["title"] = "Variable side offset",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "sideOffsetHeadlandAlternate",
    ["default"] = false,
    ["title"] = "Alternate headland side offset",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "headlandForcedDirection",
    ["default"] = 0,
    ["title"] = "Forced headland direction",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false,
    ["min"] = -1,
    ["max"] = 1
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "segmentSplitAngle",
    ["default"] = 25,
    ["title"] = "Segment Split Angle",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false,
    ["min"] = 0,
    ["max"] = 90
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "segmentSplitDistance",
    ["default"] = 10,
    ["title"] = "Segment Split Distance",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false,
    ["min"] = 0,
    ["max"] = 1000
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "segmentValidityCheckOffset",
    ["default"] = 0,
    ["title"] = "Segment Validity Offset",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false,
    ["min"] = 0,
    ["max"] = 1000
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "toolAlwaysActive",
    ["default"] = false,
    ["title"] = "Tool Always Active",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "toolStraighteningSegmentLength",
    ["default"] = 2,
    ["title"] = "Straightening Seg. Length",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false,
    ["min"] = 0.1,
    ["max"] = 100
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "toolStraighteningAlwaysActive",
    ["default"] = false,
    ["title"] = "Straightening Always Active",
    ["xmlValueType"] = XMLValueType.BOOL,
    ["customizable"] = false
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "agentFrontOffset",
    ["default"] = 4,
    ["title"] = "Front offset of the agent",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false,
    ["min"] = -25,
    ["max"] = 25
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "agentBackOffset",
    ["default"] = 4,
    ["title"] = "Back offset of the agent",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false,
    ["min"] = -25,
    ["max"] = 25
})
table.insert(FieldCourseSettings.SETTINGS, {
    ["name"] = "agentHeight",
    ["default"] = 4,
    ["title"] = "Height of the agent",
    ["xmlValueType"] = XMLValueType.FLOAT,
    ["customizable"] = false,
    ["min"] = 0,
    ["max"] = 25
})
function FieldCourseSettings.new()
    local self = {}
    FieldCourseSettings.init(self)
    setmetatable(self, {
        ["__index"] = FieldCourseSettings,
        ["__newindex"] = function(_, key, _)
            if key ~= "__CLASSNAME" then
                Logging.warning("Setting \'%s\' not defined in FieldCourseSettings", key)
            end
        end
    })
    return self
end
function FieldCourseSettings:init()
    for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
        self[setting.name] = setting.default
    end
end
function FieldCourseSettings:writeStream(streamId, _)
    streamWriteFloat32(streamId, self.implementWidth)
    streamWriteUIntN(streamId, math.clamp(self.numHeadlands, 0, FieldCourseSettings.MAX_HEADLAND_AMOUNT), FieldCourseSettings.NUM_HEADLANDS_SYNC_BITS)
    streamWriteBool(streamId, self.headlandsFirst)
    streamWriteBool(streamId, self.workHeadlands)
    streamWriteFloat32(streamId, self.workDirection)
    streamWriteUIntN(streamId, math.clamp(self.skipNumLines, 0, 5), 3)
    streamWriteFloat32(streamId, self.sideOffset)
end
function FieldCourseSettings.readStream(streamId, _)
    return {
        ["implementWidth"] = streamReadFloat32(streamId),
        ["numHeadlands"] = streamReadUIntN(streamId, FieldCourseSettings.NUM_HEADLANDS_SYNC_BITS),
        ["headlandsFirst"] = streamReadBool(streamId),
        ["workHeadlands"] = streamReadBool(streamId),
        ["workDirection"] = streamReadFloat32(streamId),
        ["skipNumLines"] = streamReadUIntN(streamId, 3),
        ["sideOffset"] = streamReadFloat32(streamId)
    }
end
function FieldCourseSettings:clone()
    local clone = FieldCourseSettings.new()
    for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
        clone[setting.name] = self[setting.name]
    end
    return clone
end
function FieldCourseSettings:isIdentical(otherSettings)
    if math.abs(self.implementWidth - otherSettings.implementWidth) > 0.01 then
        return false
    end
    if self.numHeadlands ~= otherSettings.numHeadlands then
        return false
    end
    if self.headlandsFirst ~= otherSettings.headlandsFirst then
        return false
    end
    if self.workHeadlands ~= otherSettings.workHeadlands then
        return false
    end
    if math.abs(self.workDirection - otherSettings.workDirection) > 0.01 then
        return false
    end
    if self.skipNumLines ~= otherSettings.skipNumLines then
        return false
    end
    return math.abs(self.sideOffset - otherSettings.sideOffset) <= 0.01
end
function FieldCourseSettings:applyAttributes(attributes)
    for name, value in pairs(attributes) do
        self[name] = value
    end
end
function FieldCourseSettings:getProtectedBoundarySize()
    local boundarySize = (self.hasStaticTools and 0.45 or 0.25) * self.implementWidth
    if self.sideOffsetHeadlandAlternate then
        boundarySize = math.min(boundarySize, self.implementWidth * 0.5 - math.abs(self.sideOffset) - 0.25)
    end
    return boundarySize
end
function FieldCourseSettings:saveToXML(xmlFile, key)
    for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
        xmlFile:setValue(key .. "#" .. setting.name, self[setting.name])
    end
end
function FieldCourseSettings.loadFromXML(xmlFile, key)
    if not xmlFile:hasProperty(key) then
        return nil
    end
    local fieldCourseSettings = FieldCourseSettings.new()
    for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
        fieldCourseSettings[setting.name] = xmlFile:getValue(key .. "#" .. setting.name, fieldCourseSettings[setting.name])
    end
    return fieldCourseSettings
end
function FieldCourseSettings:draw()
    setTextAlignment(RenderText.ALIGN_CENTER)
    renderText(0.5, 0.98, 0.015, "FieldCourse Settings")
    local numSettings = #FieldCourseSettings.SETTINGS
    local isLeft = true
    local y = 1
    local i = 1
    for i = i, numSettings do
        local setting = FieldCourseSettings.SETTINGS[i]
        if isLeft and numSettings * 0.5 < i then
            isLeft = false
            y = 1
        end
        local v = self[setting.name]
        local v
        if setting.formatFunc == nil then
            if setting.xmlValueType == XMLValueType.FLOAT then
                v = string.format("%.3f", v)
            elseif setting.xmlValueType == XMLValueType.INT then
                v = string.format("%d", v)
            else
                v = tostring(v)
            end
        else
            v = setting.formatFunc(v)
        end
        if isLeft then
            setTextAlignment(RenderText.ALIGN_LEFT)
            renderText(0.35, 0.98 - y * 0.016, 0.015, string.format("%s: %s", setting.title, v))
        else
            setTextAlignment(RenderText.ALIGN_RIGHT)
            renderText(0.65, 0.98 - y * 0.016, 0.015, string.format("%s: %s", setting.title, v))
        end
        y = y + 1
    end
    setTextAlignment(RenderText.ALIGN_LEFT)
end
function FieldCourseSettings:print(func, target)
    local tableStr = func or Logging.info
    local tableStr = "{"
    for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
        local v = self[setting.name]
        if type(v) == "number" then
            v = string.format("%.3f", v)
        end
        tableStr = tableStr .. string.format("%s=%s,", setting.name, v)
    end
    local tableStr = tableStr .. "}"
    if target == nil then
        tableStr("FieldCourse Settings:")
        for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
            local v = self[setting.name]
            local v
            if setting.formatFunc == nil then
                if setting.xmlValueType == XMLValueType.FLOAT then
                    v = string.format("%.3f", v)
                elseif setting.xmlValueType == XMLValueType.INT then
                    v = string.format("%d", v)
                else
                    v = tostring(v)
                end
            else
                v = setting.formatFunc(v)
            end
            tableStr("  %s: %s", setting.title, v)
        end
        tableStr("  Setting: %s", tableStr)
    else
        tableStr(target, "FieldCourse Settings:")
        for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
            local v = self[setting.name]
            local v
            if setting.formatFunc == nil then
                if setting.xmlValueType == XMLValueType.FLOAT then
                    v = string.format("%.3f", v)
                elseif setting.xmlValueType == XMLValueType.INT then
                    v = string.format("%d", v)
                else
                    v = tostring(v)
                end
            else
                v = setting.formatFunc(v)
            end
            tableStr(target, "  %s: %s", setting.title, v)
        end
        tableStr(target, "  Setting: %s", tableStr)
    end
end
function FieldCourseSettings:reset(rootVehicle)
    local _, implementData = FieldCourseSettings.generate(rootVehicle, self)
    return implementData
end
function FieldCourseSettings:resetDynamicSettings(rootVehicle)
    for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
        if setting.customizable then
            ({})[setting.name] = self[setting.name]
        end
    end
    local implementData = self:reset(rootVehicle)
    if #implementData > 0 then
        for setting, setting in ipairs(FieldCourseSettings.SETTINGS) do
            if setting.customizable then
                self[setting.name] = customData[setting.name]
            end
        end
    end
    return implementData
end
function FieldCourseSettings.generate(rootVehicle, fieldCourseSettings)
    local aiSteeringNode = rootVehicle:getAISteeringNode()
    local implementData = {}
    local attachedAIImplements = rootVehicle:getAttachedAIImplements()
    if #attachedAIImplements == 0 then
        if fieldCourseSettings == nil then
            fieldCourseSettings = FieldCourseSettings.new()
        else
            FieldCourseSettings.init(fieldCourseSettings)
        end
        for _, vehicle in ipairs(rootVehicle.childVehicles) do
            SpecializationUtil.raiseEvent(vehicle, "onAIFieldCourseSettingsInitialized", fieldCourseSettings)
            SpecializationUtil.raiseEvent(vehicle, "onPostAIFieldCourseSettingsInitialized", fieldCourseSettings)
        end
        return fieldCourseSettings, implementData
    end
    local toolFrontOffset = -math.huge
    local toolBackOffset = math.huge
    local _ = false
    local vehicle = false
    local toolFullOverlapInside = false
    local implementMinX = math.huge
    local implementMaxX = -math.huge
    local variableSideOffset = false
    local _, agentLength, agentLengthOffset, _, agentHeight, _ = rootVehicle:getAIAgentSize()
    local agentLengthOffset = agentLengthOffset or 0
    local maxInitialTurnRadiusFactor = 0
    local aiImplementsIdenticalTypes = true
    local segmentValidityCheckOffset = 0
    local rowSpacing = 0
    local rowSnapAngle = 0
    local rowOffset = 0
    for i, implement in ipairs(attachedAIImplements) do
        implement.object:updateAIMarkerWidth()
        if i > 1 then
            local firstObject = attachedAIImplements[1].object
            aiImplementsIdenticalTypes = aiImplementsIdenticalTypes and implement.object:compareFieldCropsQuery(firstObject)
            if aiImplementsIdenticalTypes then
                aiImplementsIdenticalTypes = firstObject:compareFieldCropsQuery(implement.object)
            end
        end
        local firstObject, aiMarkerRight, aiMarkerBack, _, aiMarkerWidth, aiMarkerValidityOffset = implement.object:getAIMarkers()
        local data = {
            ["isLowered"] = false,
            ["wasLowered"] = nil,
            ["width"] = aiMarkerWidth,
            ["frontOffset"] = 0,
            ["backOffset"] = 0
        }
        if aiMarkerValidityOffset ~= nil then
            segmentValidityCheckOffset = math.max(segmentValidityCheckOffset, aiMarkerValidityOffset)
        end
        local baseZOffset = nil
        if implement.object.getAttacherVehicle ~= nil then
            local attacherVehicle = implement.object:getAttacherVehicle()
            if attacherVehicle ~= nil then
                local jointDesc = attacherVehicle:getAttacherJointDescFromObject(implement.object)
                local _, frontOffsetLeft
                _, frontOffsetLeft, baseZOffset = localToLocal(jointDesc.jointTransformOrig, aiSteeringNode, 0, 0, 0)
            end
        end
        local baseZOffset = baseZOffset or 0
        local attacherVehicle = implement.object:getAIMarkerAttacherJointOffset(firstObject)
        if attacherVehicle ~= nil then
            data.frontOffset = baseZOffset + attacherVehicle.frontOffset * math.sign(baseZOffset)
            data.backOffset = baseZOffset + attacherVehicle.backOffset * math.sign(baseZOffset)
        end
        if rootVehicle == implement.object then
            local jointDesc, _, frontOffsetLeft = localToLocal(firstObject, aiSteeringNode, 0, 0, 0)
            local _, _, frontOffsetRight = localToLocal(aiMarkerRight, aiSteeringNode, 0, 0, 0)
            local _, _, backOffset = localToLocal(aiMarkerBack, aiSteeringNode, 0, 0, 0)
            data.frontOffset = (frontOffsetLeft + frontOffsetRight) * 0.5
            data.backOffset = backOffset
        end
        implementData[i] = data
        local frontOffsetLeft = data.frontOffset
        toolFrontOffset = math.max(toolFrontOffset, frontOffsetLeft)
        local frontOffsetLeft = data.backOffset
        toolBackOffset = math.min(toolBackOffset, frontOffsetLeft)
        local jointDesc, _, frontOffsetLeft, _, _ = implement.object:getAITurnRadiusLimitation()
        if not _ then
            _ = frontOffsetLeft == nil or #frontOffsetLeft == 0
        end
        if _ ~= nil then
            maxInitialTurnRadiusFactor = math.max(maxInitialTurnRadiusFactor, _)
        end
        local frontOffsetRight, _ = implement.object:getAIImplementSideOffset()
        local backOffset = -data.width * 0.5 + frontOffsetRight
        implementMinX = math.min(backOffset, implementMinX)
        local backOffset = data.width * 0.5 + frontOffsetRight
        implementMaxX = math.max(backOffset, implementMaxX)
        local _, backOffset = implement.object:getAIHasNoFullCoverageArea()
        if _ then
            toolFullOverlapInside = true
            vehicle = true
        end
        local doRowAlignment, _rowSpacing, _rowSnapAngle, _rowOffset = implement.object:getAIRowAlignment()
        if doRowAlignment then
            rowOffset = _rowOffset
            rowSpacing = _rowSpacing
            rowSnapAngle = _rowSnapAngle
        end
    end
    for i, implement in ipairs(attachedAIImplements) do
        if implement.object.getAttacherVehicle ~= nil then
            local firstObject = implement.object:getAttacherVehicle()
            for aiMarkerWidth, aiMarkerValidityOffset in ipairs(attachedAIImplements) do
                if aiMarkerValidityOffset ~= implement and aiMarkerValidityOffset.object == firstObject then
                    implementData[i].parentAIImplement = implementData[aiMarkerWidth]
                end
            end
        end
    end
    local implementWidth, sideOffset
    if implementMinX == math.huge then
        implementWidth = 5
        sideOffset = 0
    else
        sideOffset = implementMinX + (implementMaxX - implementMinX) * 0.5
    end
    local implement = toolFrontOffset - toolBackOffset - 0.25
    local canTurnBackward = math.min(0.5, implement) * 0.5
    local offset = math.max(canTurnBackward, 0)
    local toolFrontOffset = toolFrontOffset - offset
    local toolBackOffset = toolBackOffset + offset
    if toolBackOffset - toolFrontOffset == 0 then
    end
    local canTurnBackward = AIVehicleUtil.getAttachedImplementsAllowTurnBackward(rootVehicle)
    local minTurnRadius = rootVehicle.maxTurningRadius * 1.1
    if g_server ~= nil then
        local i = rootVehicle:getAIMinTurningRadius()
        if i ~= nil then
            minTurnRadius = math.max(minTurnRadius, i)
        end
        local implement = 0
        for _, aiMarkerWidth in pairs(attachedAIImplements) do
            implement = math.max(implement, AIVehicleUtil.getMaxToolRadius(aiMarkerWidth))
        end
        local firstObject = math.max(minTurnRadius, implement)
        minTurnRadius = math.max(firstObject, 2.5)
    end
    local maxInitialTurnRadiusFactor = maxInitialTurnRadiusFactor == 0 and 1 or maxInitialTurnRadiusFactor
    local i = AIVehicleUtil.getAIToolReverserDirectionNode(rootVehicle) ~= nil
    local implement = math.max(agentLength or 0, 0.1)
    local firstObject = implement + agentLengthOffset
    local implement = math.max(firstObject, toolFrontOffset)
    if toolBackOffset < 0 then
    end
    local aiMarkerRight = implement / implementWidth
    local firstObject = math.ceil(aiMarkerRight)
    if not vehicle then
        vehicle = false
        if toolFrontOffset > 0 then
            vehicle = toolBackOffset < 0
        end
    end
    if fieldCourseSettings == nil then
        fieldCourseSettings = FieldCourseSettings.new()
    else
        FieldCourseSettings.init(fieldCourseSettings)
    end
    fieldCourseSettings.implementWidth = implementWidth
    fieldCourseSettings.numHeadlands = firstObject
    fieldCourseSettings.minTurnRadius = minTurnRadius
    fieldCourseSettings.initialTurnRadiusFactor = maxInitialTurnRadiusFactor
    fieldCourseSettings.canTurnBackward = canTurnBackward
    fieldCourseSettings.allowStraightReversing = i
    fieldCourseSettings.toolFrontOffset = toolFrontOffset
    fieldCourseSettings.toolBackOffset = toolBackOffset
    fieldCourseSettings.hasStaticTools = _
    fieldCourseSettings.toolFullOverlap = vehicle
    fieldCourseSettings.toolFullOverlapInside = toolFullOverlapInside
    fieldCourseSettings.sideOffset = sideOffset
    fieldCourseSettings.variableSideOffset = variableSideOffset
    fieldCourseSettings.segmentValidityCheckOffset = segmentValidityCheckOffset
    fieldCourseSettings.rowSpacing = rowSpacing
    fieldCourseSettings.rowSnapAngle = rowSnapAngle
    fieldCourseSettings.rowOffset = rowOffset
    fieldCourseSettings.agentFrontOffset = implement * 0.5 + agentLengthOffset
    fieldCourseSettings.agentBackOffset = implement * 0.5 - agentLengthOffset
    fieldCourseSettings.agentHeight = agentHeight or 0
    fieldCourseSettings.segmentSplitAngle = 25
    if not fieldCourseSettings.hasStaticTools and fieldCourseSettings.toolFrontOffset < 0 then
        fieldCourseSettings.segmentSplitAngle = 45
    end
    if not aiImplementsIdenticalTypes then
        fieldCourseSettings.toolFullOverlap = true
        fieldCourseSettings.toolFullOverlapInside = true
        fieldCourseSettings.headlandsFirst = false
    end
    fieldCourseSettings.toolStraighteningSegmentLength = math.abs(fieldCourseSettings.toolBackOffset) * 2
    for aiMarkerWidth, aiMarkerValidityOffset in ipairs(rootVehicle.childVehicles) do
        SpecializationUtil.raiseEvent(aiMarkerValidityOffset, "onAIFieldCourseSettingsInitialized", fieldCourseSettings)
        SpecializationUtil.raiseEvent(aiMarkerValidityOffset, "onPostAIFieldCourseSettingsInitialized", fieldCourseSettings)
    end
    return fieldCourseSettings, implementData
end
function FieldCourseSettings.registerXMLPaths(schema, path)
    for _, setting in pairs(FieldCourseSettings.SETTINGS) do
        schema:register(setting.xmlValueType, path .. "#" .. setting.name, setting.title)
    end
end