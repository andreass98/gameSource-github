AdditionalFieldBuyInfo = {}
AdditionalFieldBuyInfo.MOD_NAME = g_currentModName
local AdditionalFieldBuyInfo_mt = Class(AdditionalFieldBuyInfo)
function AdditionalFieldBuyInfo.new(pfModule, customMt)
    -- upvalues: (copy) AdditionalFieldBuyInfo_mt
    local self = setmetatable({}, customMt or AdditionalFieldBuyInfo_mt)
    self.statistics = {}
    self.statisticsByFarmland = {}
    self.mapFrame = nil
    self.selectedFarmlandId = nil
    self.showTotal = false
    self.selectedField = 0
    self.selectedFieldSize = 0
    self.soilDistribution = {
        0,
        0,
        0,
        0
    }
    self.soilDistributionTarget = {
        0,
        0,
        0,
        0
    }
    self.yieldPotential = 0
    self.yieldPotentialTarget = 0
    self.doInterpolation = false
    self.allPlaceablesLoaded = false
    self.pfModule = pfModule
    return self
end
function AdditionalFieldBuyInfo:loadFromXML(_, _, _, _, _)
    self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.setColorBlindMode, self)
    g_messageCenter:subscribe(MessageType.LOADED_ALL_SAVEGAME_PLACEABLES, self.onAllPlaceablesLoaded, self)
    return true
end
function AdditionalFieldBuyInfo:loadFromItemsXML(xmlFile, key) end
function AdditionalFieldBuyInfo:saveToXMLFile(xmlFile, key, usedModNames) end
function AdditionalFieldBuyInfo:delete()
    g_messageCenter:unsubscribeAll(self)
end
function AdditionalFieldBuyInfo:readInfoFromStream(farmlandId, streamId, _)
    if streamReadBool(streamId) then
        self.selectedField = streamReadUIntN(streamId, 9)
        self.selectedFieldSize = streamReadFloat32(streamId)
        g_farmlandManager.farmlands[farmlandId].totalFieldArea = self.selectedFieldSize
        self.mapFrame.fieldBuyInfoWindow:setVisible(true)
        local i = 1
        for i = i, #self.soilDistributionTarget do
            self.soilDistribution[i] = 0
            self.soilDistributionTarget[i] = streamReadUIntN(streamId, 8) / 255
        end
        self.yieldPotentialTarget = streamReadUIntN(streamId, 8) / 255 * 1.25
        self.yieldPotential = 1
        self.doInterpolation = true
        self:updateUIValues()
    else
        self.mapFrame.fieldBuyInfoWindow:setVisible(false)
    end
end
function AdditionalFieldBuyInfo:writeInfoToStream(farmlandId, streamId, _)
    local fieldNumber, fieldArea = self:getFarmlandFieldInfo(farmlandId)
    local isValid = false
    if fieldArea > 0 then
        isValid = g_farmlandManager.farmlands[farmlandId].soilDistribution ~= nil
    end
    if streamWriteBool(streamId, isValid) then
        streamWriteUIntN(streamId, fieldNumber, 9)
        streamWriteFloat32(streamId, fieldArea)
        local i = 1
        for i = i, #self.soilDistributionTarget do
            streamWriteUIntN(streamId, farmland.soilDistribution[i] * 255, 8)
        end
        streamWriteUIntN(streamId, farmland.yieldPotential / 1.25 * 255, 8)
    end
end
function AdditionalFieldBuyInfo:setColorBlindMode(isActive)
    if isActive ~= self.isColorBlindMode then
        self.isColorBlindMode = isActive
        self:updateSoilBars()
    end
end
function AdditionalFieldBuyInfo:update(dt)
    if self.doInterpolation then
        local limit = self.yieldPotentialTarget - self.yieldPotential
        local dir = math.sign(limit)
        self.yieldPotential = (dir == 1 and math.min or math.max)(self.yieldPotential + dt * 0.00025 * dir, self.yieldPotentialTarget)
        local finishedSoilBars = true
        local i = 1
        for i = i, #self.soilDistributionTarget do
            local dir = math.sign(self.soilDistributionTarget[i] - self.soilDistribution[i])
            self.soilDistribution[i] = (dir == 1 and math.min or math.max)(self.soilDistribution[i] + dt * 0.001 * dir, self.soilDistributionTarget[i])
            if self.soilDistribution[i] ~= self.soilDistributionTarget[i] then
                finishedSoilBars = false
            end
        end
        self:updateUIValues()
        if self.yieldPotential == self.yieldPotentialTarget and finishedSoilBars then
            self.doInterpolation = false
        end
    end
end
function AdditionalFieldBuyInfo:setMapFrame(mapFrame)
    self.mapFrame = mapFrame
    self.maxBarSize = self.maxBarSize or mapFrame.soilPercentageBar[1].size[1]
    mapFrame.fieldBuyInfoWindow:setVisible(false)
end
function AdditionalFieldBuyInfo:updateSoilBars()
    if self.pfModule.soilMap ~= nil then
        local soilTypes = self.pfModule.soilMap.soilTypes
        local i = 1
        for i = i, #soilTypes do
            local soilType = soilTypes[i]
            self.mapFrame.soilNameText[i]:setText(soilType.name)
            self.mapFrame.soilPercentageBar[i]:setImageColor(nil, unpack(self.isColorBlindMode and soilType.colorBlind or soilType.color))
        end
    end
end
function AdditionalFieldBuyInfo:updateUIValues()
    local contentBox = self.mapFrame.contextBoxFarmland
    if self.farmlandBoxHeight == nil then
        self.farmlandBoxHeight = contentBox.size[2]
        self.farmlandBoxBgHeight = contentBox.elements[1].size[2]
    end
    if self.selectedFieldSize >= 0.01 then
        self.mapFrame.fieldBuyInfoWindow:setVisible(true)
        contentBox:setSize(nil, self.farmlandBoxHeight + self.mapFrame.fieldBuyInfoWindow.size[2])
        background:setSize(nil, self.farmlandBoxBgHeight + self.mapFrame.fieldBuyInfoWindow.size[2])
        self:updateSoilBars()
        local i = 1
        local barWidth = 4
        for i = i, barWidth do
            local offset = self.mapFrame.soilPercentageText[i].size[1] * 0.1
            local str = "~%d%%"
            if self.soilDistribution[i] == 0 then
                str = "%d%%"
                offset = 0
            end
            mapFrame.soilPercentageText[i]:setText(string.format(str, self.soilDistribution[i] * 100))
            mapFrame.soilPercentageBar[i]:setSize(self.maxBarSize * self.soilDistribution[i])
            mapFrame.soilPercentageText[i]:setPosition(mapFrame.soilPercentageBar[i].position[1] + mapFrame.soilPercentageBar[i].size[1] + offset)
        end
        if self.yieldPotential > 1 then
            mapFrame.yieldPercentageBarPos:setPosition(mapFrame.yieldPercentageBarBase.position[1] + mapFrame.yieldPercentageBarBase.size[1])
            mapFrame.yieldPercentageBarPos:setSize(mapFrame.yieldPercentageBarBase.size[1] * (self.yieldPotential - 1))
            mapFrame.yieldPercentageBarNeg:setSize(0)
        elseif self.yieldPotential < 1 then
            local barWidth = mapFrame.yieldPercentageBarBase.size[1] * math.abs(self.yieldPotential - 1)
            mapFrame.yieldPercentageBarNeg:setPosition(mapFrame.yieldPercentageBarBase.position[1] + mapFrame.yieldPercentageBarBase.size[1] - barWidth)
            mapFrame.yieldPercentageBarNeg:setSize(barWidth)
            mapFrame.yieldPercentageBarPos:setSize(0)
        else
            mapFrame.yieldPercentageBarNeg:setSize(0)
            mapFrame.yieldPercentageBarPos:setSize(0)
        end
        mapFrame.yieldPercentageText:setText(string.format("~%d%%", self.yieldPotential * 100))
        local barWidth = mapFrame.yieldPercentageBarBase.position[1] + mapFrame.yieldPercentageBarBase.size[1] * 1.25 - mapFrame.yieldPercentageText.size[1]
        local str = mapFrame.yieldPercentageBarBase.position[1] + mapFrame.yieldPercentageBarBase.size[1] * self.yieldPotential - mapFrame.yieldPercentageText.size[1] * 0.5
        mapFrame.yieldPercentageText:setPosition((math.min(str, barWidth)))
        self:updateContextBox()
    else
        self.mapFrame.fieldBuyInfoWindow:setVisible(false)
        contentBox:setSize(nil, self.farmlandBoxHeight)
        background:setSize(nil, self.farmlandBoxBgHeight)
    end
end
function AdditionalFieldBuyInfo:onFarmlandSelectionChanged(selectedFarmland)
    if self.mapFrame ~= nil then
        if selectedFarmland == nil then
            self.selectedField = 0
            self.selectedFieldSize = 0
            self.selectedFarmlandId = 0
            self:updateUIValues()
        else
            self.selectedFarmlandId = selectedFarmland.id
            if g_server ~= nil then
                local fieldNumber, fieldArea = self:getFarmlandFieldInfo(selectedFarmland.id)
                if fieldArea >= 0.01 then
                    self.selectedField = fieldNumber
                    self.selectedFieldSize = fieldArea
                    if selectedFarmland.soilDistribution ~= nil then
                        local i = 1
                        for i = i, #self.soilDistributionTarget do
                            self.soilDistribution[i] = 0
                            self.soilDistributionTarget[i] = selectedFarmland.soilDistribution[i]
                        end
                        self.yieldPotentialTarget = selectedFarmland.yieldPotential
                        self.yieldPotential = 1
                        self.doInterpolation = true
                    end
                else
                    self.selectedField = 0
                    self.selectedFieldSize = 0
                end
                self:updateUIValues()
                return
            end
            if g_server == nil and g_client ~= nil then
                g_client:getServerConnection():sendEvent(RequestFieldBuyInfoEvent.new(selectedFarmland.id))
                return
            end
        end
    end
end
function AdditionalFieldBuyInfo:onShowContextBox(_, contextBox)
    self.lastContextBox = contextBox
end
function AdditionalFieldBuyInfo:updateContextBox()
    if self.lastContextBox ~= nil then
        local farmland = g_farmlandManager.farmlands[self.selectedFarmlandId]
        if farmland == nil then
            return
        end
        local text
        if farmland.totalFieldArea == nil then
            text = g_i18n:formatMoney(farmland.price, 0, true, false)
        else
            text = string.format("%s (%s / ha)", g_i18n:formatMoney(farmland.price, 0, true, false), g_i18n:formatMoney(farmland.price / farmland.totalFieldArea, 0, true, false))
        end
        self.lastContextBox:getDescendantByName("farmlandValue"):setText(text)
        if farmland.totalFieldArea ~= nil then
            local text = string.format("%s (%s: %s)", g_i18n:formatArea(farmland.areaInHa, 2), g_i18n:getText("contract_details_field"), g_i18n:formatArea(farmland.totalFieldArea, 2))
            self.lastContextBox:getDescendantByName("farmlandSize"):setText(text)
        end
        if self.mapFrame.updatePrecisionFarmingContextActions ~= nil then
            self.mapFrame.updatePrecisionFarmingContextActions()
        end
    end
end
function AdditionalFieldBuyInfo.getFarmlandFieldInfo(_, farmlandId)
    local farmland = g_farmlandManager.farmlands[farmlandId]
    local fieldArea = farmland ~= nil and (farmland.totalFieldArea or 0) or 0
    local fields = g_fieldManager:getFields()
    if fields ~= nil then
        for _, field in pairs(fields) do
            if field.farmland ~= nil and field.farmland.id == farmlandId then
                return field:getId(), fieldArea
            end
        end
    end
    return 0, fieldArea
end
function AdditionalFieldBuyInfo:updateFieldSoilDistributionData()
    local pfModule = self.pfModule
    if pfModule.soilMap ~= nil then
        local soilBitVectorMap = pfModule.soilMap.bitVectorMap
        if soilBitVectorMap ~= nil then
            local startTime = getTimeSec()
            local farmlandX, _ = getBitVectorMapSize(g_farmlandManager.localMap)
            local soilX, soilY = getBitVectorMapSize(soilBitVectorMap)
            local x = 0
            local totalYieldPotentialPixels = soilX - 1
            local totalFarmlandPixels = 1
            for x = x, totalYieldPotentialPixels, totalFarmlandPixels do
                local y = 0
                for y = y, soilY - 1 do
                    local isOnField = getDensityAtWorldPos(g_currentMission.terrainDetailId, x / (soilX - 1) * g_currentMission.terrainSize - g_currentMission.terrainSize * 0.5, 0, y / (soilY - 1) * g_currentMission.terrainSize - g_currentMission.terrainSize * 0.5) ~= 0
                    if isOnField then
                        local valueFarmland = getBitVectorMapPoint(farmlandManager.localMap, x * (farmlandX / soilX), y * (farmlandX / soilX), 0, farmlandManager.numberOfBits)
                        local farmland = getBitVectorMapPoint(soilBitVectorMap, x, y, 0, pfModule.soilMap.numChannels)
                        local valueSoil = bit32.band(farmland, 3)
                        if valueFarmland > 0 then
                            local farmland = farmlandManager.farmlands[valueFarmland]
                            if farmland ~= nil then
                                if farmland.totalFieldArea == nil then
                                    farmland.totalFieldArea = 0
                                end
                                farmland.totalFieldArea = farmland.totalFieldArea + 1
                                if farmland.soilDistribution == nil then
                                    farmland.soilDistribution = {}
                                    local i = 1
                                    for i = i, #pfModule.soilMap.soilTypes do
                                        farmland.soilDistribution[i] = 0
                                    end
                                end
                                farmland.soilDistribution[valueSoil + 1] = farmland.soilDistribution[valueSoil + 1] + 1
                            end
                        end
                    end
                end
            end
            local totalYieldPotentialPixels = 0
            local totalFarmlandPixels = 0
            for y, worldX in pairs(farmlandManager.farmlands) do
                worldX:updatePrice()
                if worldX.soilDistribution ~= nil then
                    local worldZ = 0
                    local valueSoil = 1
                    local isOnField = #worldX.soilDistribution
                    local valueFarmland = 1
                    for valueSoil = valueSoil, isOnField, valueFarmland do

                    end
                    if worldZ > 0 then
                        local isOnField = 0
                        local farmland = 1
                        for farmland = farmland, #worldX.soilDistribution do
                            worldX.soilDistribution[farmland] = math.floor(worldX.soilDistribution[farmland] / worldZ * 100) / 100
                            isOnField = isOnField + self.pfModule.soilMap:getYieldPotentialBySoilTypeIndex(farmland) * worldX.soilDistribution[farmland]
                            self.soilDistribution[farmland] = 0
                        end
                        worldX.yieldPotential = math.clamp(isOnField, 0, 1.25)
                    end
                    local isOnField = g_currentMission.terrainSize / soilX
                    worldX.totalFieldArea = worldX.totalFieldArea * isOnField * isOnField / 10000
                end
            end
            Logging.devInfo("Map Overall Yield Potential: %.3f (%.2fms)", totalYieldPotentialPixels / totalFarmlandPixels, (getTimeSec() - startTime) * 1000)
        end
    end
end
function AdditionalFieldBuyInfo:onAllPlaceablesLoaded()
    self.allPlaceablesLoaded = true
    if self.delayedFieldSoilDistributionUpdate and #g_fieldManager.updateTasks == 0 then
        local readyForUpdate = true
        for _, _field in pairs(g_fieldManager.fields) do
            if not _field:getHasOwner() and (_field.isMissionAllowed and not _field.pf_fieldInitialized) then
                readyForUpdate = false
                break
            end
        end
        if readyForUpdate then
            self.delayedFieldSoilDistributionUpdate = false
            self:updateFieldSoilDistributionData()
        end
    end
end
function AdditionalFieldBuyInfo:overwriteGameFunctions(pfModule)
    if g_server == nil then
        pfModule:overwriteGameFunction(Placeable, "setLoadingStep", function(superFunc, placeable, loadingStep, ...)
            -- upvalues: (copy) self
            superFunc(placeable, loadingStep, ...)
            if g_currentMission.placeableSystem:canStartMission() then
                self:onAllPlaceablesLoaded()
            end
        end)
    end
    pfModule:overwriteGameFunction(FarmlandManager, "loadFarmlandData", function(superFunc, farmlandManager, xmlFile)
        -- upvalues: (copy) self
        if not superFunc(farmlandManager, xmlFile) then
            return false
        end
        if g_currentMission.missionInfo.isValid then
            self:updateFieldSoilDistributionData()
        else
            self.delayedFieldSoilDistributionUpdate = true
        end
        return true
    end)
    pfModule:overwriteGameFunction(FieldManager, "onFinishFieldUpdateTask", function(superFunc, _fieldManager, task, ...)
        -- upvalues: (copy) self
        superFunc(_fieldManager, task, ...)
        if task.fieldId ~= nil then
            local field = _fieldManager:getFieldById(task.fieldId)
            if field ~= nil then
                field.pf_fieldInitialized = true
            end
        end
        if self.delayedFieldSoilDistributionUpdate and (self.allPlaceablesLoaded and #_fieldManager.updateTasks == 0) then
            local field = true
            for _, _field in pairs(_fieldManager.fields) do
                if not _field:getHasOwner() and (_field.isMissionAllowed and not _field.pf_fieldInitialized) then
                    field = false
                    break
                end
            end
            if field then
                self.delayedFieldSoilDistributionUpdate = false
                self:updateFieldSoilDistributionData()
            end
        end
    end)
    pfModule:overwriteGameFunction(Farmland, "updatePrice", function(superFunc, farmland)
        superFunc(farmland)
        if farmland.yieldPotential ~= nil then
            farmland.price = farmland.price * farmland.yieldPotential
        end
    end)
end