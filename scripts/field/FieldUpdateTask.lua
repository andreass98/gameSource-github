FieldUpdateTask = {}
local FieldUpdateTask_mt = Class(FieldUpdateTask, DensityMapUpdateTask)
function FieldUpdateTask.registerXMLPaths(schema, basePath)
    DensityMapUpdateTask.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#fieldId", "Id of the field", nil, false)
    schema:register(XMLValueType.STRING, basePath .. ".fruit#type", "Name of the fruit type", nil, false)
    schema:register(XMLValueType.STRING, basePath .. ".fruit#growthState", "Growthstate of the fruit type", nil, false)
    FieldGroundType.registerXMLPath(schema, basePath .. ".ground#type", "Name of the ground type", nil, false)
    schema:register(XMLValueType.INT, basePath .. ".ground#angle", "Angle of the ground", nil, false)
    FieldSprayType.registerXMLPath(schema, basePath .. ".spray#type", "Name of the spray type", nil, false)
    schema:register(XMLValueType.INT, basePath .. ".spray#level", "Level of the spray", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#weedState", "Weed state", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#stoneLevel", "Stone level", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#plowLevel", "Plow level", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#limeLevel", "Lime level", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#rollerLevel", "Roller level", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#stubbleShredLevel", "Stubbleshred level", nil, false)
    FieldType.registerXMLPath(schema, basePath .. "#fieldType", "Name of the field type", nil, false)
    schema:register(XMLValueType.BOOL, basePath .. "#clearHeight", "Clear tip anything", nil, false)
end
function FieldUpdateTask.new(customMt)
    -- upvalues: (copy) FieldUpdateTask_mt
    local self = FieldUpdateTask:superClass().new(customMt or FieldUpdateTask_mt)
    self.fieldId = nil
    self.multiModifier = DensityMapMultiModifier.new()
    self.filter1 = nil
    self.filter2 = nil
    self.filter3 = nil
    return self
end
function FieldUpdateTask:saveToXMLFile(xmlFile, key)
    FieldUpdateTask:superClass().saveToXMLFile(self, xmlFile, key)
    if self.fieldId ~= nil then
        xmlFile:setValue(key .. "#fieldId", self.fieldId)
    end
    if self.fruitTypeIndex ~= nil then
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
        xmlFile:setValue(key .. ".fruit#type", fruitTypeDesc ~= nil and fruitTypeDesc.name or "UNKNOWN")
        if fruitTypeDesc ~= nil then
            local growthStateName = fruitTypeDesc:getGrowthStateName(self.growthState) or self.growthState
            xmlFile:setValue(key .. ".fruit#growthState", (tostring(growthStateName)))
        end
    end
    if self.groundType ~= nil then
        FieldGroundType.saveToXMLFile(xmlFile, key .. ".ground#type", self.groundType)
    end
    if self.groundAngle ~= nil then
        xmlFile:setValue(key .. ".ground#angle", self.groundAngle)
    end
    if self.fieldSprayType ~= nil then
        FieldSprayType.saveToXMLFile(xmlFile, key .. ".spray#type", self.fieldSprayType)
    end
    if self.sprayLevel ~= nil then
        xmlFile:setValue(key .. ".spray#level", self.sprayLevel)
    end
    if self.weedState ~= nil then
        xmlFile:setValue(key .. "#weedState", self.weedState)
    end
    if self.stoneLevel ~= nil then
        xmlFile:setValue(key .. "#stoneLevel", self.stoneLevel)
    end
    if self.plowLevel ~= nil then
        xmlFile:setValue(key .. "#plowLevel", self.plowLevel)
    end
    if self.limeLevel ~= nil then
        xmlFile:setValue(key .. "#limeLevel", self.limeLevel)
    end
    if self.rollerLevel ~= nil then
        xmlFile:setValue(key .. "#rollerLevel", self.rollerLevel)
    end
    if self.stubbleShredLevel ~= nil then
        xmlFile:setValue(key .. "#stubbleShredLevel", self.stubbleShredLevel)
    end
    if self.fieldType ~= nil then
        FieldType.saveToXMLFile(xmlFile, key .. "#fieldType", self.fieldType)
    end
    if self.doClearHeight ~= nil then
        xmlFile:setValue(key .. "#clearHeight", self.doClearHeight)
    end
end
function FieldUpdateTask:loadFromXMLFile(xmlFile, key)
    self.fieldId = xmlFile:getValue(key .. "#fieldId") or self.fieldId
    FieldUpdateTask:superClass().loadFromXMLFile(self, xmlFile, key)
    local fruitTypeName = xmlFile:getValue(key .. ".fruit#type")
    if fruitTypeName ~= nil then
        local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
        if fruitType == nil then
            if string.upper(fruitTypeName) == "UNKNOWN" then
                self:setFruit(FruitType.UNKNOWN, 0)
            end
        else
            local growthState = xmlFile:getValue(key .. ".fruit#growthState") or 0
            local growthStateNumber = tonumber(growthState)
            if growthStateNumber == nil then
                if not string.isNilOrWhitespace(growthState) then
                    growthStateNumber = fruitType:getGrowthStateByName(growthState)
                end
                if growthStateNumber == nil then
                    Logging.xmlWarning(xmlFile, "FieldUpdateTask: Invalid fruitTypeName \'%s\' growthstate \'%s\' for \'%s\'", fruitTypeName, growthState, key)
                    return false
                end
            end
            self:setFruit(fruitType.index, growthStateNumber)
        end
    end
    local fruitType = xmlFile:getValue(key .. "#weedState")
    if fruitType ~= nil then
        self:setWeedState(fruitType)
    end
    local growthState = xmlFile:getValue(key .. "#stoneLevel")
    if growthState ~= nil then
        self:setStoneLevel(growthState)
    end
    local growthStateNumber = FieldGroundType.loadFromXMLFile(xmlFile, key .. ".ground#type")
    if growthStateNumber ~= nil then
        self:setGroundType(growthStateNumber)
    end
    local groundAngle = xmlFile:getValue(key .. ".ground#angle")
    if groundAngle ~= nil then
        self:setGroundAngle(groundAngle)
    end
    local fieldSprayType = FieldSprayType.loadFromXMLFile(xmlFile, key .. ".spray#type")
    if fieldSprayType ~= nil then
        self:setSprayType(fieldSprayType)
    end
    local sprayLevel = xmlFile:getValue(key .. ".spray#level")
    if sprayLevel ~= nil then
        self:setSprayLevel(sprayLevel)
    end
    local limeLevel = xmlFile:getValue(key .. "#limeLevel")
    if limeLevel ~= nil then
        self:setLimeLevel(limeLevel)
    end
    local rollerLevel = xmlFile:getValue(key .. "#rollerLevel")
    if rollerLevel ~= nil then
        self:setRollerLevel(rollerLevel)
    end
    local plowLevel = xmlFile:getValue(key .. "#plowLevel")
    if plowLevel ~= nil then
        self:setPlowLevel(plowLevel)
    end
    local fieldType = FieldType.loadFromXMLFile(xmlFile, key .. "#fieldType")
    if fieldType ~= nil then
        self:setFieldType(fieldType)
    end
    local stubbleShredLevel = xmlFile:getValue(key .. "#stubbleShredLevel")
    if stubbleShredLevel ~= nil then
        self:setStubbleShredLevel(stubbleShredLevel)
    end
    if xmlFile:getValue(key .. "#clearHeight") then
        self:clearHeight()
    end
    if self.state == DensityMapUpdateTaskState.RUNNING then
        self:start()
    end
    return true
end
function FieldUpdateTask:setField(field)
    self.fieldId = field:getId()
end
function FieldUpdateTask:getField()
    return g_fieldManager:getFieldById(self.fieldId)
end
function FieldUpdateTask:addFilter(filter)
    if self.filter1 == nil then
        self.filter1 = filter
        return true
    elseif self.filter2 == nil then
        self.filter2 = filter
        return true
    elseif self.filter3 == nil then
        self.filter3 = filter
        return true
    else
        Logging.devWarning("Maximum number of filters is 3 for FieldUpdateTask")
        return false
    end
end
function FieldUpdateTask:setFruit(fruitTypeIndex, growthState)
    if fruitTypeIndex ~= nil then
        if fruitTypeIndex ~= FruitType.UNKNOWN then
            local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
            if fruitTypeDesc == nil then
                Logging.error("No fruit type for index %q", fruitTypeIndex)
                return
            end
            if fruitTypeDesc.terrainDataPlaneId == nil then
                Logging.error("No terrain data layer for fruitType %q", fruitTypeDesc.name)
                return
            end
        end
        self.fruitTypeIndex = fruitTypeIndex
        self.growthState = growthState
    end
end
function FieldUpdateTask:setWeedState(weedState)
    local weedSystem = g_currentMission.weedSystem
    if weedSystem ~= nil and weedSystem:getMapHasWeed() then
        self.weedState = weedState
    end
end
function FieldUpdateTask:setStoneLevel(stoneLevel)
    local stoneSystem = g_currentMission.stoneSystem
    if stoneSystem ~= nil and stoneSystem:getMapHasStones() then
        self.stoneLevel = stoneLevel
    end
end
function FieldUpdateTask:setGroundType(groundType)
    self.groundType = groundType
end
function FieldUpdateTask:setGroundAngle(groundAngle)
    self.groundAngle = groundAngle
end
function FieldUpdateTask:setSprayType(fieldSprayType)
    self.fieldSprayType = fieldSprayType
end
function FieldUpdateTask:setSprayLevel(sprayLevel)
    self.sprayLevel = sprayLevel
end
function FieldUpdateTask:setPlowLevel(plowLevel)
    if Platform.gameplay.usePlowCounter then
        self.plowLevel = plowLevel
    end
end
function FieldUpdateTask:setFieldType(fieldType)
    local densityMapId, _, _ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.FIELD_TYPE)
    if densityMapId == nil then
        Logging.warning("Current map does not support field types")
    else
        self.fieldType = fieldType
    end
end
function FieldUpdateTask:setLimeLevel(limeLevel)
    if Platform.gameplay.useLimeCounter then
        self.limeLevel = limeLevel
    end
end
function FieldUpdateTask:setRollerLevel(rollerLevel)
    if Platform.gameplay.useRolling then
        self.rollerLevel = rollerLevel
    end
end
function FieldUpdateTask:setStubbleShredLevel(stubbleShredLevel)
    if Platform.gameplay.useStubbleShred then
        self.stubbleShredLevel = stubbleShredLevel
    end
end
function FieldUpdateTask:setWaterLevel(waterLevel)
    self.waterLevel = waterLevel
end
function FieldUpdateTask:resetDisplacement()
    self.doResetDisplacement = true
end
function FieldUpdateTask:clearTireTracks()
    if g_currentMission.tireTrackSystem ~= nil then
        self.doClearTireTracks = true
    end
end
function FieldUpdateTask:setPerlinFilter(fruitTypeIndex, percentage, minOctave, numOctave, persistence)
    local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
    local perlinFilter = PerlinNoiseFilter.new(fruitTypeDesc.terrainDataPlaneId, minOctave or 13, numOctave or 1, persistence or 0.5)
    perlinFilter:setValueCompareParams(DensityValueCompareType.GREATER, (percentage or 0.5) * 10000)
    self.filter = perlinFilter
end
function FieldUpdateTask:clearHeight()
    self.doClearHeight = true
end
function FieldUpdateTask:setValue(densityMapId, firstChannel, numChannels, value, filter1, filter2, filter3)
    local modifier = DensityMapModifier.new(densityMapId, firstChannel, numChannels, g_terrainNode)
    self.multiModifier:addExecuteSet(value, modifier, filter1, filter2, filter3)
end
function FieldUpdateTask:setFieldGroundValue(map, value, filter1, filter2, filter3)
    local densityMapId, firstChannel, numChannels = g_currentMission.fieldGroundSystem:getDensityMapData(map)
    local modifier = DensityMapModifier.new(densityMapId, firstChannel, numChannels, g_terrainNode)
    self.multiModifier:addExecuteSet(value, modifier, filter1, filter2, filter3)
end
function FieldUpdateTask:prepare()
    if self.fruitTypeIndex ~= nil then
        local haulmFruitTypeDesc = g_fruitTypeManager:getFirstHaulmFruitType()
        if haulmFruitTypeDesc ~= nil then
            self:setValue(haulmFruitTypeDesc.terrainDataPlaneIdHaulm, haulmFruitTypeDesc.startStateChannelHaulm, haulmFruitTypeDesc.numStateChannelsHaulm, 0, self.filter1, self.filter2, self.filter3)
        end
        if self.fruitTypeIndex == FruitType.UNKNOWN then
            local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.WHEAT)
            local modifier = DensityMapModifier.new(fruitTypeDesc.terrainDataPlaneId, fruitTypeDesc.startStateChannel, fruitTypeDesc.numStateChannels, g_terrainNode)
            modifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
            self.multiModifier:addExecuteSet(0, modifier, filter1, filter2, filter3)
        else
            local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
            self:setValue(fruitTypeDesc.terrainDataPlaneId, fruitTypeDesc.startStateChannel, fruitTypeDesc.numStateChannels, self.growthState, filter1, filter2, filter3)
        end
    end
    if self.weedState ~= nil then
        local fruitTypeDesc, modifier, numChannels = g_currentMission.weedSystem:getDensityMapData()
        self:setValue(fruitTypeDesc, modifier, numChannels, self.weedState, filter1, filter2, filter3)
    end
    if self.stoneLevel ~= nil then
        local haulmFruitTypeDesc = g_currentMission.stoneSystem
        local fruitTypeDesc, modifier, numChannels = haulmFruitTypeDesc:getDensityMapData()
        local stoneFilter = DensityMapFilter.new(fruitTypeDesc, modifier, numChannels)
        local min, _ = haulmFruitTypeDesc:getMinMaxValues()
        stoneFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        local value = self.stoneLevel
        local value
        if self.stoneLevel == 0 then
            value = haulmFruitTypeDesc:getMaskValue()
        else
            value = self.stoneLevel - 1 + min
        end
        self:setValue(fruitTypeDesc, modifier, numChannels, value, stoneFilter, filter1, filter2)
    end
    if self.groundType ~= nil then
        local haulmFruitTypeDesc = FieldGroundType.getValueByType(self.groundType)
        self:setFieldGroundValue(FieldDensityMap.GROUND_TYPE, haulmFruitTypeDesc, filter1, filter2, filter3)
    end
    if self.groundAngle ~= nil then
        local haulmFruitTypeDesc = FSDensityMapUtil.convertToDensityMapAngle(self.groundAngle, g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
        self:setFieldGroundValue(FieldDensityMap.GROUND_ANGLE, haulmFruitTypeDesc, filter1, filter2, filter3)
    end
    if self.fieldSprayType ~= nil then
        local haulmFruitTypeDesc = FieldSprayType.getValueByType(self.fieldSprayType)
        self:setFieldGroundValue(FieldDensityMap.SPRAY_TYPE, haulmFruitTypeDesc, filter1, filter2, filter3)
    end
    if self.fieldType ~= nil then
        local haulmFruitTypeDesc = FieldType.getValueByType(self.fieldType)
        self:setFieldGroundValue(FieldDensityMap.FIELD_TYPE, haulmFruitTypeDesc, filter1, filter2, filter3)
    end
    if self.sprayLevel ~= nil then
        self:setFieldGroundValue(FieldDensityMap.SPRAY_LEVEL, self.sprayLevel, filter1, filter2, filter3)
    end
    if self.plowLevel ~= nil then
        self:setFieldGroundValue(FieldDensityMap.PLOW_LEVEL, self.plowLevel, filter1, filter2, filter3)
    end
    if self.limeLevel ~= nil then
        self:setFieldGroundValue(FieldDensityMap.LIME_LEVEL, self.limeLevel, filter1, filter2, filter3)
    end
    if self.rollerLevel ~= nil then
        self:setFieldGroundValue(FieldDensityMap.ROLLER_LEVEL, self.rollerLevel, filter1, filter2, filter3)
    end
    if self.stubbleShredLevel ~= nil then
        self:setFieldGroundValue(FieldDensityMap.STUBBLE_SHRED_LEVEL, self.stubbleShredLevel, filter1, filter2, filter3)
    end
    if self.waterLevel ~= nil then
        self:setFieldGroundValue(FieldDensityMap.WATER_LEVEL, self.waterLevel, filter1, filter2, filter3)
    end
    if self.doClearHeight then
        local haulmFruitTypeDesc = g_currentMission.terrainDetailHeightId
        self:setValue(haulmFruitTypeDesc, getDensityMapHeightFirstChannel(haulmFruitTypeDesc), getDensityMapHeightNumChannels(haulmFruitTypeDesc), 0, filter1, filter2, filter3)
        self:setValue(haulmFruitTypeDesc, g_densityMapHeightManager.heightTypeFirstChannel, g_densityMapHeightManager.heightTypeNumChannels, 0, filter1, filter2, filter3)
    end
    if self.doResetDisplacement then
        local haulmFruitTypeDesc, fruitTypeDesc, modifier = fieldGroundSystem:getDisplacementData()
        self:setValue(haulmFruitTypeDesc, fruitTypeDesc, modifier, fieldGroundSystem:getDisplacementResetValue(), filter1, filter2, filter3)
    end
end
function FieldUpdateTask:enqueue(immediate)
    g_fieldManager:addFieldUpdateTask(self, immediate)
end
function FieldUpdateTask:start(immediate)
    if self.state == DensityMapUpdateTaskState.RUNNING or self.state == DensityMapUpdateTaskState.FINISHED then
        return false
    end
    if self.area == nil and self.fieldId ~= nil then
        local field = g_fieldManager:getFieldById(self.fieldId)
        if field ~= nil then
            self.area = field:getDensityMapPolygon()
        end
    end
    if self.area == nil then
        self.state = DensityMapUpdateTaskState.FINISHED
        Logging.warning("Missing area for FieldUpdateTask")
        return false
    end
    self.state = DensityMapUpdateTaskState.RUNNING
    local field = self.multiModifier
    self:prepare()
    self.area:applyToModifier(field)
    self.minY, self.maxY = field:getPolygonMinMaxZ()
    if self.minY ~= nil then
        if self.currentMinY == nil then
            self.currentMinY = self.minY
            self.currentMaxY = self.minY + self.maxRegionPerFrame
        end
        if immediate then
            self.currentMinY = self.minY
            self.currentMaxY = self.maxY
        end
    end
    return true
end
function FieldUpdateTask:update(_)
    if self.state == DensityMapUpdateTaskState.RUNNING then
        local multiModifier = self.multiModifier
        if self.currentMinY ~= nil then
            multiModifier:setPolygonClipRegion(self.currentMinY, self.currentMaxY)
        end
        multiModifier:execute()
        if self.minY ~= nil then
            self.currentMinY = self.currentMaxY
            self.currentMaxY = math.min(self.currentMinY + self.maxRegionPerFrame, self.maxY)
            if self.currentMinY ~= self.maxY then
                return
            end
        end
        if self.doClearTireTracks then
            g_currentMission.tireTrackSystem:erasePolygon(self.area:getVerticesList())
            self.doClearTireTracks = nil
        end
        self:setFinished()
    end
end
function FieldUpdateTask:getName()
    if self.customName == nil then
        if self.fieldId == nil then
            return FieldUpdateTask:superClass().getName(self)
        else
            return string.format("field \'%s\'", self.fieldId)
        end
    else
        return self.customName
    end
end