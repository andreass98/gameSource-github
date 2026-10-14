YieldMap = {}
YieldMap.MOD_NAME = g_currentModName
local YieldMap_mt = Class(YieldMap, ValueMap)
source(g_currentModDirectory .. "scripts/densityMapUpdates/YieldMapResetDensityMapTask.lua")
function YieldMap.new(pfModule, customMt)
    -- upvalues: (copy) YieldMap_mt
    local self = ValueMap.new(pfModule, customMt or YieldMap_mt)
    self.filename = "precisionFarming_yieldMap.grle"
    self.name = "yieldMap"
    self.id = "YIELD_MAP"
    self.label = "ui_mapOverviewYield"
    self.densityMapModifiersYield = {}
    self.densityMapModifiersReset = nil
    self.densityMapModifiersClear = nil
    self.minimapGradientSliceId = "precisionFarming.gradient_red_green"
    self.minimapGradientColorBlindSliceId = "precisionFarming.gradient_color_blind"
    self.minimapLabelName = g_i18n:getText("ui_mapOverviewYield", YieldMap.MOD_NAME)
    self.yieldMapSelected = false
    self.selectedFarmland = nil
    self.selectedField = nil
    self.selectedFieldArea = nil
    return self
end
function YieldMap:initialize()
    YieldMap:superClass().initialize(self)
    self.densityMapModifiersYield = {}
    self.densityMapModifiersReset = nil
    self.densityMapModifiersClear = nil
    self.yieldMapSelected = false
    self.selectedFarmland = nil
    self.selectedField = nil
    self.selectedFieldArea = nil
end
function YieldMap:delete()
    g_messageCenter:unsubscribeAll(self)
    YieldMap:superClass().delete(self)
end
function YieldMap:loadFromXML(xmlFile, key, _, _, _)
    key = key .. ".yieldMap"
    self.numChannels = getXMLInt(xmlFile, key .. ".bitVectorMap#numChannels") or 4
    self.maxValue = 2 ^ self.numChannels - 1
    self.sizeX = getXMLInt(xmlFile, key .. ".bitVectorMap#sizeX") or 1024
    self.sizeY = getXMLInt(xmlFile, key .. ".bitVectorMap#sizeY") or 1024
    self.bitVectorMap = self:loadSavedBitVectorMap("YieldMap", self.filename, self.numChannels, self.sizeX)
    self:addBitVectorMapToSync(self.bitVectorMap)
    self:addBitVectorMapToSave(self.bitVectorMap, self.filename)
    self:addBitVectorMapToDelete(self.bitVectorMap)
    self.yieldValues = {}
    local i = 0
    while true do
        local baseKey = string.format("%s.yieldValues.yieldValue(%d)", key, i)
        if not hasXMLProperty(xmlFile, baseKey) then
            break
        end
        local yieldValue = {
            ["value"] = getXMLInt(xmlFile, baseKey .. "#value") or 0,
            ["displayValue"] = getXMLFloat(xmlFile, baseKey .. "#displayValue") or 100,
            ["color"] = string.getVector(getXMLString(xmlFile, baseKey .. "#color"), 3),
            ["colorBlind"] = string.getVector(getXMLString(xmlFile, baseKey .. "#colorBlind"), 3)
        }
        local j = false
        if yieldValue.color ~= nil then
            j = yieldValue.colorBlind ~= nil
        end
        yieldValue.showInMenu = j
        table.insert(self.yieldValues, yieldValue)
        i = i + 1
    end
    local j = 1
    local baseKey = #self.yieldValues - 1
    local yieldValue = 1
    for j = j, baseKey, yieldValue do
        if self.yieldValues[j].color == nil and j > 1 then
            local color1 = self.yieldValues[j - 1].color
            local color2 = self.yieldValues[j + 1].color
            if color1 ~= nil and color2 ~= nil then
                self.yieldValues[j].color = {}
                self.yieldValues[j].color[1] = (color1[1] + color2[1]) * 0.5
                self.yieldValues[j].color[2] = (color1[2] + color2[2]) * 0.5
                self.yieldValues[j].color[3] = (color1[3] + color2[3]) * 0.5
            end
            local colorBlind1 = self.yieldValues[j - 1].colorBlind
            local colorBlind2 = self.yieldValues[j + 1].colorBlind
            if colorBlind1 ~= nil and colorBlind2 ~= nil then
                self.yieldValues[j].colorBlind = {}
                self.yieldValues[j].colorBlind[1] = (colorBlind1[1] + colorBlind2[1]) * 0.5
                self.yieldValues[j].colorBlind[2] = (colorBlind1[2] + colorBlind2[2]) * 0.5
                self.yieldValues[j].colorBlind[3] = (colorBlind1[3] + colorBlind2[3]) * 0.5
            end
        end
    end
    self.minimapGradientLabelName = string.format("%d%% - %d%%", self:getMinMaxValue())
    g_messageCenter:subscribe(MessageType.FARMLAND_OWNER_CHANGED, self.onFarmlandStateChanged, self)
    return true
end
function YieldMap:update(dt) end
local function worldCoordsToLocalCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, size, terrainSize)
    return (startWorldX + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (startWorldZ + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (widthWorldX + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (widthWorldZ + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (heightWorldX + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (heightWorldZ + terrainSize * 0.5) / terrainSize * size + 0.5 - 1
end
function YieldMap:setAreaYield(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, yieldPercentage)
    -- upvalues: (copy) worldCoordsToLocalCoords
    local modifier = self.densityMapModifiersYield.modifier
    local maskFilter = self.densityMapModifiersYield.maskFilter
    if modifier == nil or maskFilter == nil then
        self.densityMapModifiersYield.modifier = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels)
        modifier = self.densityMapModifiersYield.modifier
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        self.densityMapModifiersYield.maskFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        self.densityMapModifiersYield.maskFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
    end
    local fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels
    fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, heightWorldX, heightWorldZ = worldCoordsToLocalCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, self.sizeX, g_currentMission.terrainSize)
    modifier:setParallelogramDensityMapCoords(fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    modifier:executeSet(self:getNearestInternalYieldValueFromValue(yieldPercentage / 2 * 100), maskFilter)
    self:setMinimapRequiresUpdate(true)
end
function YieldMap:getNearestInternalYieldValueFromValue(value)
    local minDifference = 10000
    local minValue = 0
    if value > 0 then
        local i = 1
        for i = i, #self.yieldValues do
            local difference = math.abs(value - self.yieldValues[i].displayValue)
            if difference < minDifference then
                minValue = self.yieldValues[i].value
                minDifference = difference
            end
        end
    end
    return minValue
end
function YieldMap.resetFarmlandYieldArea(_, farmlandId)
    local updateTask = YieldMapResetDensityMapTask.new()
    updateTask:setData(farmlandId)
    updateTask:enqueue()
    if g_server == nil and g_client ~= nil then
        g_client:getServerConnection():sendEvent(ResetYieldMapEvent.new(farmlandId))
    end
end
function YieldMap:getResetMultiModifier(farmlandId)
    local functionData = self.densityMapModifiersReset
    if functionData == nil then
        functionData = {
            ["modifier"] = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels, g_terrainNode),
            ["farmlandMask"] = DensityMapFilter.new(g_farmlandManager.localMap, 0, g_farmlandManager.numberOfBits),
            ["farmlandModifiers"] = {}
        }
        self.densityMapModifiersUncover = functionData
    end
    local farmlandModifier = functionData.farmlandModifiers[farmlandId]
    if farmlandModifier == nil then
        farmlandModifier = DensityMapMultiModifier.new()
        functionData.farmlandMask:setValueCompareParams(DensityValueCompareType.EQUAL, farmlandId)
        farmlandModifier:addExecuteSet(0, functionData.modifier, functionData.farmlandMask)
        functionData.farmlandModifiers[farmlandId] = farmlandModifier
    end
    return farmlandModifier
end
function YieldMap:addClearToMultiModifier(multiModifier, filter1, filter2)
    local functionData = self.densityMapModifiersClear
    if functionData == nil then
        functionData = {
            ["modifier"] = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels, g_terrainNode)
        }
        self.densityMapModifiersClear = functionData
    end
    multiModifier:addExecuteSet(0, functionData.modifier, filter1, filter2)
end
function YieldMap:buildOverlay(overlay, yieldFilter, isColorBlindMode)
    resetDensityMapVisualizationOverlay(overlay)
    setOverlayColor(overlay, 1, 1, 1, 1)
    local filterIndex = 1
    local i = 1
    for i = i, #self.yieldValues do
        local yieldValue = self.yieldValues[i]
        if yieldFilter[filterIndex] then
            local r, g, b
            if isColorBlindMode then
                r = yieldValue.colorBlind[1]
                g = yieldValue.colorBlind[2]
                b = yieldValue.colorBlind[3]
            else
                r = yieldValue.color[1]
                g = yieldValue.color[2]
                b = yieldValue.color[3]
            end
            setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, 0, 0, 0, self.numChannels, yieldValue.value, r, g, b)
        end
        if yieldValue.showInMenu then
        end
    end
end
function YieldMap:getMinimapZoomFactor()
    return 3
end
function YieldMap:getMinMaxValue()
    if #self.yieldValues > 0 then
        return self.yieldValues[1].displayValue, self.yieldValues[#self.yieldValues].displayValue, #self.yieldValues
    else
        return 0, 1, 0
    end
end
function YieldMap:getDisplayValues()
    if self.valuesToDisplay == nil then
        self.valuesToDisplay = {}
        local i = 1
        for i = i, #self.yieldValues do
            local yieldValue = self.yieldValues[i]
            if yieldValue.showInMenu then
                local yieldValueToDisplay = {
                    ["colors"] = {}
                }
                yieldValueToDisplay.colors[true] = { yieldValue.colorBlind or { (i - 1) / (#self.yieldValues - 1) * 0.9 + 0.1, (i - 1) / (#self.yieldValues - 1) * 0.9 + 0.1, 0.1 } }
                yieldValueToDisplay.colors[false] = { yieldValue.color }
                yieldValueToDisplay.description = string.format("%d%%", yieldValue.displayValue)
                table.insert(self.valuesToDisplay, yieldValueToDisplay)
            end
        end
    end
    return self.valuesToDisplay
end
function YieldMap:getValueFilter()
    if self.valueFilter == nil then
        self.valueFilter = {}
        local i = 1
        for i = i, #self.yieldValues do
            if self.yieldValues[i].showInMenu then
                table.insert(self.valueFilter, true)
            end
        end
    end
    return self.valueFilter
end
function YieldMap:onValueMapSelectionChanged(valueMap)
    self.yieldMapSelected = valueMap == self
end
function YieldMap:onFarmlandSelectionChanged(farmlandId, fieldNumber, fieldArea)
    self.selectedFarmland = farmlandId
    self.selectedField = fieldNumber
    self.selectedFieldArea = fieldArea
end
function YieldMap:onFarmlandStateChanged(farmlandId, _, loadFromSavegame)
    if not loadFromSavegame then
        self:resetFarmlandYieldArea(farmlandId)
    end
end
function YieldMap:setMapFrame(mapFrame)
    self.mapFrame = mapFrame
end
function YieldMap:getHelpLinePage()
    return 6
end
function YieldMap:collectFarmlandHotspotActions(actions)
    table.insert(actions, {
        ["title"] = g_i18n:getText("ui_resetYield"),
        ["callback"] = self.onResetYieldMapCallback,
        ["callbackTarget"] = self
    })
end
function YieldMap:onResetYieldMapCallback(farmlandId)
    self.mapFrame:setMapSelectionItem(nil)
    self:resetFarmlandYieldArea(farmlandId)
    g_precisionFarming:updatePrecisionFarmingOverlays()
end