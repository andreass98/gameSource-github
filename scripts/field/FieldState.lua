FieldState = {}
local FieldState_mt = Class(FieldState)
function FieldState.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#fruitType", "Name of the fruit type", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#growthState", "Growthstate of the fruit", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#lastGrowthState", "Last growthstate of the fruit", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#weedState", "Weedstate on the field", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#stoneLevel", "Weedstate on the field", nil, false)
    schema:register(XMLValueType.STRING, basePath .. "#groundType", "Name of the ground type", nil, false)
    schema:register(XMLValueType.STRING, basePath .. "#sprayType", "Name of the spray type", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#sprayLevel", "Spray level of the field", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#limeLevel", "Lime level of the field", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#rollerLevel", "Roller level of the field", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#plowLevel", "Plow level of the field", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#stubbleShredLevel", "Stubble shred level of the field", nil, false)
    schema:register(XMLValueType.INT, basePath .. "#waterLevel", "Water level of the field", nil, false)
end
function FieldState.new(customMt)
    -- upvalues: (copy) FieldState_mt
    local self = setmetatable({}, customMt or FieldState_mt)
    self.isValid = false
    self.fruitTypeIndex = FruitType.UNKNOWN
    self.growthState = 0
    self.lastGrowthState = 0
    self.weedState = 0
    self.weedFactor = 0
    self.stoneLevel = 0
    self.groundType = FieldGroundType.NONE
    self.sprayLevel = 0
    self.sprayType = 0
    self.limeLevel = 0
    self.rollerLevel = 0
    self.plowLevel = 0
    self.stubbleShredLevel = 0
    self.waterLevel = 0
    self.farmlandId = 0
    self.ownerFarmId = AccessHandler.NOBODY
    return self
end
function FieldState:saveToXMLFile(xmlFile, key)
    if self.isValid then
        local fruitName = g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex)
        local groundTypeName = FieldGroundType.getName(self.groundType) or "UNKNOWN"
        local sprayTypeName = FieldSprayType.getName(self.sprayType) or "UNKNOWN"
        xmlFile:setString(key .. "#fruitType", fruitName or "UNKNOWN")
        xmlFile:setInt(key .. "#growthState", self.growthState)
        xmlFile:setInt(key .. "#lastGrowthState", self.lastGrowthState)
        xmlFile:setInt(key .. "#weedState", self.weedState)
        xmlFile:setInt(key .. "#stoneLevel", self.stoneLevel)
        xmlFile:setString(key .. "#groundType", groundTypeName)
        xmlFile:setString(key .. "#sprayType", sprayTypeName)
        xmlFile:setInt(key .. "#sprayLevel", self.sprayLevel)
        xmlFile:setInt(key .. "#limeLevel", self.limeLevel)
        xmlFile:setInt(key .. "#rollerLevel", self.rollerLevel)
        xmlFile:setInt(key .. "#plowLevel", self.plowLevel)
        xmlFile:setInt(key .. "#stubbleShredLevel", self.stubbleShredLevel)
        xmlFile:setInt(key .. "#waterLevel", self.waterLevel)
    end
end
function FieldState:loadFromXMLFile(xmlFile, key)
    local fruitTypeName = xmlFile:getString(key .. "#fruitType")
    if fruitTypeName == nil then
        return false
    end
    local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
    if fruitType ~= nil then
        self.fruitTypeIndex = fruitType.index
        self.growthState = xmlFile:getInt(key .. "#growthState") or self.growthState
        self.lastGrowthState = xmlFile:getInt(key .. "#lastGrowthState") or self.growthState
    end
    self.weedState = xmlFile:getInt(key .. "#weedState") or self.weedState
    self.stoneLevel = xmlFile:getInt(key .. "#stoneLevel") or self.stoneLevel
    local groundTypeName = xmlFile:getString(key .. "#groundType")
    self.groundType = FieldGroundType.getByName(groundTypeName) or FieldGroundType.NONE
    local sprayTypeName = xmlFile:getString(key .. "#sprayType")
    self.sprayType = FieldSprayType.getByName(sprayTypeName) or FieldSprayType.NONE
    self.sprayLevel = xmlFile:getInt(key .. "#sprayLevel") or self.sprayLevel
    self.limeLevel = xmlFile:getInt(key .. "#limeLevel") or self.limeLevel
    self.rollerLevel = xmlFile:getInt(key .. "#rollerLevel") or self.rollerLevel
    self.plowLevel = xmlFile:getInt(key .. "#plowLevel") or self.plowLevel
    self.stubbleShredLevel = xmlFile:getInt(key .. "#stubbleShredLevel") or self.stubbleShredLevel
    self.waterLevel = xmlFile:getInt(key .. "#waterLevel") or self.waterLevel
    self.isValid = true
    return true
end
function FieldState:update(x, z)
    local fieldGroundSystem = g_currentMission.fieldGroundSystem
    self.farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
    self.ownerFarmId = g_farmlandManager:getFarmlandOwner(self.farmlandId)
    self.lastFruitTypeIndex = self.fruitTypeIndex
    self.lastGrowthState = self.growthState
    self.isValid = true
    self.fruitTypeIndex = FruitType.UNKNOWN
    self.growthState = 0
    local dataPlaneId = g_fruitTypeManager:getDefaultDataPlaneId()
    if dataPlaneId ~= nil then
        local densityTypeIndex = getDensityTypeIndexAtWorldPos(dataPlaneId, x, 0, z)
        local desc = g_fruitTypeManager:getFruitTypeByDensityTypeIndex(densityTypeIndex)
        if desc ~= nil then
            self.fruitTypeIndex = desc.index
            self.growthState = desc:getGrowthStateByDensityState((getDensityStatesAtWorldPos(dataPlaneId, x, 0, z)))
        end
    end
    if self.fruitTypeIndex ~= self.lastFruitTypeIndex then
        self.lastGrowthState = 0
    end
    self.weedState = g_currentMission.weedSystem:getWeedStateAtWorldPos(x, z)
    self.weedFactor = g_currentMission.weedSystem:getWeedFactorAtWorldPos(x, z)
    self.stoneLevel = g_currentMission.stoneSystem:getStoneLevelAtWorldPos(x, z)
    local densityTypeIndex = fieldGroundSystem:getValueAtWorldPos(FieldDensityMap.GROUND_TYPE, x, 0, z)
    self.groundType = FieldGroundType.getTypeByValue(densityTypeIndex)
    local desc = fieldGroundSystem:getValueAtWorldPos(FieldDensityMap.SPRAY_TYPE, x, 0, z)
    self.sprayType = FieldSprayType.getTypeByValue(desc)
    self.sprayLevel = fieldGroundSystem:getValueAtWorldPos(FieldDensityMap.SPRAY_LEVEL, x, 0, z)
    self.limeLevel = fieldGroundSystem:getValueAtWorldPos(FieldDensityMap.LIME_LEVEL, x, 0, z)
    self.rollerLevel = fieldGroundSystem:getValueAtWorldPos(FieldDensityMap.ROLLER_LEVEL, x, 0, z)
    self.plowLevel = fieldGroundSystem:getValueAtWorldPos(FieldDensityMap.PLOW_LEVEL, x, 0, z)
    self.stubbleShredLevel = fieldGroundSystem:getValueAtWorldPos(FieldDensityMap.STUBBLE_SHRED_LEVEL, x, 0, z)
    self.waterLevel = fieldGroundSystem:getValueAtWorldPos(FieldDensityMap.WATER_LEVEL, x, 0, z)
end
function FieldState:getHarvestScaleMultiplier()
    local sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor = self:getHarvestScaleFactors()
    return g_currentMission:getHarvestScaleMultiplier(self.fruitTypeIndex, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, 0)
end
function FieldState:getHarvestScaleFactors()
    local missionInfo = g_currentMission.missionInfo
    local fieldGroundSystem = g_currentMission.fieldGroundSystem
    local sprayLevelMax = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
    local plowLevelMax = fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL)
    local limeLevelMax = fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL)
    local rollerLevelMax = fieldGroundSystem:getMaxValue(FieldDensityMap.ROLLER_LEVEL)
    local plowFactor = 1
    if missionInfo.plowingRequiredEnabled then
        plowFactor = self.plowLevel / plowLevelMax
    end
    local limeFactor = 1
    if Platform.gameplay.useLimeCounter and missionInfo.limeRequired then
        limeFactor = self.limeLevel / limeLevelMax
    end
    local rollerFactor = 1
    if Platform.gameplay.useRolling then
        rollerFactor = 1 - self.rollerLevel / rollerLevelMax
    end
    local weedFactor = 1
    if missionInfo.weedsEnabled then
        weedFactor = 1 - self.weedFactor
    end
    local stubbleFactor = 1
    if Platform.gameplay.useStubbleShred then
        stubbleFactor = self.stubbleShredLevel
    end
    return self.sprayLevel / sprayLevelMax, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor
end
function FieldState:createFieldUpdateTask()
    local fieldUpdateTask = FieldUpdateTask.new()
    fieldUpdateTask:setFruit(self.fruitTypeIndex, self.growthState)
    fieldUpdateTask:setWeedState(self.weedState)
    fieldUpdateTask:setStoneLevel(self.stoneLevel)
    fieldUpdateTask:setGroundType(self.groundType)
    fieldUpdateTask:setSprayType(self.sprayType)
    fieldUpdateTask:setSprayLevel(self.sprayLevel)
    fieldUpdateTask:setPlowLevel(self.plowLevel)
    fieldUpdateTask:setLimeLevel(self.limeLevel)
    fieldUpdateTask:setRollerLevel(self.rollerLevel)
    fieldUpdateTask:setStubbleShredLevel(self.stubbleShredLevel)
    fieldUpdateTask:setWaterLevel(self.waterLevel)
    return fieldUpdateTask
end
function FieldState:drawDebug(x, y)
    renderText(x, y, 0.012, "IsValid: " .. tostring(self.isValid))
    y = y - 0.013
    renderText(x, y, 0.012, "FruitType: " .. tostring((g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex))) .. " (" .. self.growthState .. ")")
    y = y - 0.013
    renderText(x, y, 0.012, "WeedState: " .. self.weedState)
    y = y - 0.013
    renderText(x, y, 0.012, "StoneLevel: " .. self.stoneLevel)
    y = y - 0.013
    renderText(x, y, 0.012, "GroundType: " .. FieldGroundType.getName(self.groundType))
    y = y - 0.013
    renderText(x, y, 0.012, "SprayType: " .. FieldSprayType.getName(self.sprayType))
    y = y - 0.013
    renderText(x, y, 0.012, "SprayLevel: " .. self.sprayLevel)
    y = y - 0.013
    renderText(x, y, 0.012, "LimeLevel: " .. self.limeLevel)
    y = y - 0.013
    renderText(x, y, 0.012, "RollerLevel: " .. self.rollerLevel)
    y = y - 0.013
    renderText(x, y, 0.012, "PlowLevel: " .. self.plowLevel)
    y = y - 0.013
    renderText(x, y, 0.012, "StubbleLevel: " .. self.stubbleShredLevel)
    y = y - 0.013
    renderText(x, y, 0.012, "WaterLevel: " .. self.waterLevel)
    return y - 0.013
end
function FieldState:drawDebugAtWorldPosition(x, y, z, textSize, textColor)
    local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
    local fruitTypeName = "Unknown"
    local growthStateName = "None"
    if fruitTypeDesc ~= nil then
        fruitTypeName = fruitTypeDesc.name
        growthStateName = fruitTypeDesc:getGrowthStateName(self.growthState) or growthStateName
    end
    local text = (((((((((("" .. string.format("FruitType: %s (%d - %s)\n", fruitTypeName, self.growthState, growthStateName)) .. string.format("WeedState: %s\n", self.weedState)) .. string.format("StoneLevel: %s\n", self.stoneLevel)) .. string.format("GroundType: %s\n", FieldGroundType.getName(self.groundType))) .. string.format("SprayType: %s\n", FieldSprayType.getName(self.sprayType))) .. string.format("SprayLevel: %d\n", self.sprayLevel)) .. string.format("LimeLevel: %d\n", self.limeLevel)) .. string.format("PlowLevel: %d\n", self.plowLevel)) .. string.format("RollerLevel: %d\n", self.rollerLevel)) .. string.format("StubbleLevel: %d\n", self.stubbleShredLevel)) .. string.format("WaterLevel: %d\n", self.waterLevel)
    local r, g, b, a = textColor:unpack()
    Utils.renderTextAtWorldPosition(x, y, z, text, textSize, 0, r, g, b, a)
end