FieldInfoDisplayExtension = {}
FieldInfoDisplayExtension.MOD_NAME = g_currentModName
local FieldInfoDisplayExtension_mt = Class(FieldInfoDisplayExtension)
function FieldInfoDisplayExtension.new(precisionFarming, customMt)
    -- upvalues: (copy) FieldInfoDisplayExtension_mt
    local self = setmetatable({}, customMt or FieldInfoDisplayExtension_mt)
    self.precisionFarming = precisionFarming
    self.fieldInfos = {}
    self.texts = {}
    self.texts.boxTitle = g_i18n:getText("ui_header")
    self.texts.expectedYield = g_i18n:getText("fieldInfo_expectedYield")
    self.texts.yieldPotential = g_i18n:getText("fieldInfo_yieldPotential")
    return self
end
function FieldInfoDisplayExtension:loadFromXML(_, _, _, _, _)
    self.precisionFarming:collectFieldInfos(self)
    return true
end
function FieldInfoDisplayExtension:delete() end
function FieldInfoDisplayExtension:addFieldInfo(text, object, updateFunc, _, yieldChangeFunc)
    table.insert(self.fieldInfos, {
        ["text"] = text,
        ["object"] = object,
        ["updateFunc"] = updateFunc,
        ["yieldChangeFunc"] = yieldChangeFunc,
        ["value"] = nil,
        ["color"] = nil,
        ["additionalText"] = nil,
        ["showWarning"] = nil
    })
end
function FieldInfoDisplayExtension:infoBoxAddData(func, funcTarget, _)
    local i = 1
    for i = i, #self.fieldInfos do
        local fieldInfo = self.fieldInfos[i]
        if fieldInfo.value ~= nil then
            if fieldInfo.additionalText == nil then
                func(funcTarget, fieldInfo.text, fieldInfo.value, fieldInfo.showWarning, fieldInfo.color)
            else
                func(funcTarget, string.format(fieldInfo.text .. " (%s)", fieldInfo.additionalText), fieldInfo.value, fieldInfo.showWarning, fieldInfo.color)
            end
        end
    end
end
function FieldInfoDisplayExtension:infoBoxAddYieldData(func, funcTarget, fieldInfo)
    local fruitType = g_fruitTypeManager:getFruitTypeByIndex(fieldInfo.fruitTypeIndex)
    if fruitType ~= nil then
        local maxGrowingState = fruitType.minHarvestingGrowthState - 1
        if fruitType.minPreparingGrowthState >= 0 then
            maxGrowingState = math.min(maxGrowingState, fruitType.minPreparingGrowthState - 1)
        end
        if fieldInfo.growthState > 0 and fieldInfo.growthState <= maxGrowingState and true or (fruitType.minPreparingGrowthState >= 0 and (fruitType.minPreparingGrowthState <= fieldInfo.growthState and fieldInfo.growthState <= fruitType.maxPreparingGrowthState) and true or (fruitType.minHarvestingGrowthState <= fieldInfo.growthState and fieldInfo.growthState <= fruitType.maxHarvestingGrowthState and true or false)) then
            local _, plowFactor, _, weedFactor, stubbleFactor, rollerFactor = fieldInfo:getHarvestScaleFactors()
            local harvestMultiplier = 0 + plowFactor * 0.1 + weedFactor * 0.15 + stubbleFactor * 0.025 + rollerFactor * 0.025
            local yieldPotential = nil
            local yieldPotentialToHa = nil
            local yieldPotentialFactor = nil
            local yieldPotentialFactorBest = nil
            local i = 1
            local expectedYield = #self.fieldInfos
            local expectedYieldToHa = 1
            for i = i, expectedYield, expectedYieldToHa do
                local fieldInfo = self.fieldInfos[i]
                if fieldInfo.yieldChangeFunc ~= nil then
                    local factor, proportion, _yieldPotential, _yieldPotentialToHa, _yieldPotentialFactor, _yieldPotentialFactorBest = fieldInfo.yieldChangeFunc(fieldInfo.object, fieldInfo)
                end
            end
            if yieldPotential ~= nil and yieldPotential > 0 then
                local expectedYieldToHa = 50 + harvestMultiplier * 50
                local harvestMultiplier = math.ceil(expectedYieldToHa) / 100
                local expectedYield = harvestMultiplier * yieldPotential * (yieldPotentialFactor or 1)
                local expectedYieldToHa = harvestMultiplier * yieldPotentialToHa * (yieldPotentialFactor or 1)
                local i = yieldPotential * (yieldPotentialFactorBest or 1)
                if yieldPotentialToHa ~= 0 then
                    func(funcTarget, self.texts.expectedYield, string.format("%d %% | %.1f to/ha", expectedYield * 100, expectedYieldToHa))
                    func(funcTarget, self.texts.yieldPotential, string.format("%d %% | %.1f to/ha", i * 100, yieldPotentialToHa * (yieldPotentialFactorBest or 1)))
                    return
                end
                func(funcTarget, self.texts.expectedYield, string.format("%d %%", expectedYield * 100))
                func(funcTarget, self.texts.yieldPotential, string.format("%d %%", i * 100))
            end
        end
    end
end
function FieldInfoDisplayExtension:overwriteGameFunctions(pfModule)
    pfModule:overwriteGameFunction(PlayerHUDUpdater, "new", function(superFunc, ...)
        -- upvalues: (copy) self
        local hudUpdater = superFunc(...)
        hudUpdater.precisionFarmingBox = g_currentMission.hud.infoDisplay:createBox(InfoDisplayBoxPrecisionFarming)
        hudUpdater.precisionFarmingBox:setTitle(self.texts.boxTitle)
        return hudUpdater
    end)
    pfModule:overwriteGameFunction(PlayerHUDUpdater, "delete", function(superFunc, hudUpdater, ...)
        g_currentMission.hud.infoDisplay:destroyBox(hudUpdater.precisionFarmingBox)
        return superFunc(hudUpdater, ...)
    end)
    pfModule:overwriteGameFunction(PlayerHUDUpdater, "showFieldInfo", function(superFunc, hudUpdater, posX, posY, posZ)
        -- upvalues: (copy) self
        superFunc(hudUpdater, posX, posY, posZ)
        local fieldInfo = hudUpdater.fieldInfo
        if fieldInfo.groundType ~= FieldGroundType.NONE then
            local box = hudUpdater.precisionFarmingBox
            box:clear()
            box:setTitle(self.texts.boxTitle)
            self:infoBoxAddData(box.addLine, box, fieldInfo)
            self:infoBoxAddYieldData(box.addLine, box, fieldInfo)
            box:showNextFrame()
        end
    end)
    pfModule:overwriteGameFunction(PlayerHUDUpdater, "fieldAddField", function(superFunc, hudUpdater, fieldInfo, box)
        superFunc(hudUpdater, fieldInfo, box)
        for _, line in ipairs(box.lines) do
            if line.isActive and (line.key == g_i18n:getText("fieldInfo_yieldBonus") or line.key == g_i18n:getText("ui_growthMapFertilized")) then
                line.isActive = false
            end
        end
    end)
    pfModule:overwriteGameFunction(PlayerHUDUpdater, "fieldAddFieldActions", function(superFunc, hudUpdater, fieldInfo, box)
        superFunc(hudUpdater, fieldInfo, box)
        for _, line in ipairs(box.lines) do
            if line.isActive and line.key == g_i18n:getText("ui_growthMapNeedsLime") then
                line.isActive = false
            end
        end
    end)
    pfModule:overwriteGameFunction(PlayerHUDUpdater, "update", function(superFunc, hudUpdater, dt, x, y, z, rotY)
        -- upvalues: (copy) self
        superFunc(hudUpdater, dt, x, y, z, rotY)
        local isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
        local i = 1
        for i = i, #self.fieldInfos do
            local fieldInfo = self.fieldInfos[i]
            fieldInfo.value, fieldInfo.color, fieldInfo.additionalText, fieldInfo.showWarning = fieldInfo.updateFunc(fieldInfo.object, fieldInfo, x, z, isColorBlindMode)
        end
    end)
    pfModule:overwriteGameFunction(InGameMenuMapFrame, "updateFieldInfoBox", function(_, _self, screenX, screenY)
        -- upvalues: (copy) self
        local localX, localY = _self.ingameMap:getLocalPosition(screenX, screenY)
        local worldX, worldZ = _self.ingameMap:localToWorldPos(localX, localY)
        if _self.fieldInfo == nil then
            _self.fieldInfo = FieldState.new()
        end
        local fieldInfo = _self.fieldInfo
        fieldInfo:update(worldX, worldZ)
        if fieldInfo.groundType == FieldGroundType.NONE then
            return false
        end
        local i = 1
        local ownedByYou = 1
        for i = i, #self.fieldInfos, ownedByYou do
            local pfFieldInfo = self.fieldInfos[i]
            local npc, isGrowing, fruitTypeDesc, text = pfFieldInfo.updateFunc(pfFieldInfo.object, pfFieldInfo, worldX, worldZ, false)
            pfFieldInfo.value = npc
            pfFieldInfo.color = isGrowing
            pfFieldInfo.additionalText = fruitTypeDesc
            pfFieldInfo.showWarning = text
        end
        local ownedByYou = false
        local i = fieldInfo.ownerFarmId
        local isGrowing
        if i == g_currentMission:getFarmId() and i ~= FarmManager.SPECTATOR_FARM_ID then
            isGrowing = g_i18n:getText("fieldInfo_ownerYou")
            ownedByYou = true
        elseif i == AccessHandler.EVERYONE or i == AccessHandler.NOBODY then
            local pfFieldInfo = g_farmlandManager:getFarmlandById(fieldInfo.farmlandId)
            if pfFieldInfo == nil then
                isGrowing = g_i18n:getText("fieldInfo_ownerNobody")
            else
                local npc = pfFieldInfo:getNPC()
                isGrowing = npc ~= nil and npc.title or "Unknown"
            end
        else
            local pfFieldInfo = g_farmManager:getFarmById(i)
            isGrowing = pfFieldInfo == nil and "Unknown" or pfFieldInfo.name
        end
        local isGrowing = g_i18n:getText("fieldInfo_farmland")
        local text = fieldInfo.farmlandId
        _self:addFieldInfoKeyValue(isGrowing, (tostring(text)))
        if Platform.playerInfo.showNPCNames then
            _self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), isGrowing)
        elseif ownedByYou then
            _self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), g_i18n:getText("fieldInfo_owned"))
        else
            _self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), g_i18n:getText("fieldInfo_notOwned"))
        end
        local pfFieldInfo = fieldInfo.fruitTypeIndex
        local npc = fieldInfo.growthState
        local isGrowing = false
        if pfFieldInfo ~= FruitType.UNKNOWN then
            local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(pfFieldInfo)
            _self:addFieldInfoKeyValue(g_i18n:getText("statistic_fillType"), fruitTypeDesc.fillType.title)
            local text = nil
            if fruitTypeDesc:getIsCut(npc) then
                text = g_i18n:getText("ui_growthMapCut")
            elseif fruitTypeDesc:getIsWithered(npc) then
                text = g_i18n:getText("ui_growthMapWithered")
            elseif fruitTypeDesc:getIsGrowing(npc) then
                text = g_i18n:getText("ui_growthMapGrowing")
                isGrowing = true
            elseif fruitTypeDesc:getIsPreparable(npc) then
                text = g_i18n:getText("ui_growthMapReadyToPrepareForHarvest")
                isGrowing = true
            elseif fruitTypeDesc:getIsHarvestable(npc) then
                text = g_i18n:getText("ui_growthMapReadyToHarvest")
                isGrowing = true
            end
            if text ~= nil then
                _self:addFieldInfoKeyValue(g_i18n:getText("ui_mapOverviewGrowth"), text)
            end
        end
        self:infoBoxAddData(_self.addFieldInfoKeyValue, _self, fieldInfo)
        if isGrowing then
            self:infoBoxAddYieldData(_self.addFieldInfoKeyValue, _self, fieldInfo)
        end
        if g_currentMission.missionInfo.weedsEnabled then
            local fruitTypeDesc = g_currentMission.weedSystem
            local text = fruitTypeDesc:getFieldInfoStates()
            local weedState = fieldInfo.weedState
            local toolName = nil
            if weedState > 0 then
                local fruitTypeDesc = nil
                if pfFieldInfo ~= nil then
                    fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(pfFieldInfo)
                end
                if Platform.gameplay.hasWeeder then
                    if (fruitTypeDesc == nil or fruitTypeDesc:getIsWeedable(npc)) and fruitTypeDesc:getWeederReplacements(false).weed.replacements[weedState] == 0 then
                        toolName = g_i18n:getText("weed_destruction_weeder")
                    end
                    if toolName == nil and (fruitTypeDesc == nil or fruitTypeDesc:getIsHoeable(npc)) and fruitTypeDesc:getWeederReplacements(true).weed.replacements[weedState] == 0 then
                        toolName = g_i18n:getText("weed_destruction_hoe")
                    end
                end
                if toolName == nil and (fruitTypeDesc == nil or fruitTypeDesc:getIsGrowing(npc)) then
                    toolName = g_i18n:getText("weed_destruction_herbicide")
                end
                local weederReplacements = text[weedState]
                if weederReplacements ~= nil then
                    _self:addFieldInfoKeyValue(weederReplacements, toolName or "")
                end
            end
        end
        return true
    end)
end