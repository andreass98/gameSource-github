ExtendedSprayerHUDExtension = {}
ExtendedSprayerHUDExtension.MOD_NAME = g_currentModName or ExtendedSprayerHUDExtension.MOD_NAME
ExtendedSprayerHUDExtension.MOD_DIR = g_currentModDirectory or ExtendedSprayerHUDExtension.MOD_DIR
ExtendedSprayerHUDExtension.GUI_ELEMENTS = ExtendedSprayerHUDExtension.MOD_DIR .. "gui/ui_elements.png"
local ExtendedSprayerHUDExtension_mt = Class(ExtendedSprayerHUDExtension)
function ExtendedSprayerHUDExtension.new(vehicle, customMt)
    -- upvalues: (copy) ExtendedSprayerHUDExtension_mt
    local self = setmetatable({}, customMt or ExtendedSprayerHUDExtension_mt)
    self.priority = GS_PRIO_LOW
    self.vehicle = vehicle
    self.extendedSprayer = vehicle[ExtendedSprayer.SPEC_TABLE_NAME]
    self.backgroundTop = g_overlayManager:createOverlay("precisionFarming.shortcutBox_top", 0, 0, 0, 0)
    self.backgroundMiddle = g_overlayManager:createOverlay("precisionFarming.shortcutBox_middle", 0, 0, 0, 0)
    self.backgroundBottom = g_overlayManager:createOverlay("precisionFarming.shortcutBox_bottom", 0, 0, 0, 0)
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.backgroundTop:setColor(r, g, b, a)
    self.backgroundMiddle:setColor(r, g, b, a)
    self.backgroundBottom:setColor(r, g, b, a)
    self.gradient = g_overlayManager:createOverlay(ExtendedSprayerHUDExtension.SLICES.PH_GRADIENT, 0, 0, 0, 0)
    self.gradientInactive = g_overlayManager:createOverlay(ExtendedSprayerHUDExtension.SLICES.PH_GRADIENT, 0, 0, 0, 0)
    self.gradientInactive:setColor(0.4, 0.4, 0.4, 1)
    self.actualBar = g_overlayManager:createOverlay("precisionFarming.filled", 0, 0, 0, 0)
    self.actualBar:setColor(unpack(ExtendedSprayerHUDExtension.COLOR.ACTUAL_BAR))
    self.targetBar = g_overlayManager:createOverlay("precisionFarming.target_bar", 0, 0, 0, 0)
    self.targetFlag = g_overlayManager:createOverlay("precisionFarming.target_flag", 0, 0, 0, 0)
    self.setValueBar = g_overlayManager:createOverlay("precisionFarming.filled", 0, 0, 0, 0)
    self.setValueBar:setColor(unpack(ExtendedSprayerHUDExtension.COLOR.SET_VALUE_BAR_GOOD))
    self.footerSeparationBar = g_overlayManager:createOverlay("precisionFarming.filled", 0, 0, 0, 0)
    self.footerSeparationBar:setColor(unpack(ExtendedSprayerHUDExtension.COLOR.SEPARATOR_BAR))
    self.actualPos = 0.34
    self.targetPos = 0.8
    self.actualValue = 0
    self.actualValueStr = "%.3f"
    self.setValue = 0
    self.targetValue = 0
    self.hasValidValues = false
    self.soilMap = g_precisionFarming.soilMap
    self.pHMap = g_precisionFarming.pHMap
    self.nitrogenMap = g_precisionFarming.nitrogenMap
    self.texts = {}
    self.texts.headline_ph_lime = g_i18n:getText("hudExtensionSprayer_headline_ph_lime", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.headline_n_solidFertilizer = g_i18n:getText("hudExtensionSprayer_headline_n_solidFertilizer", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.headline_n_liquidFertilizer = g_i18n:getText("hudExtensionSprayer_headline_n_liquidFertilizer", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.headline_n_slurryTanker = g_i18n:getText("hudExtensionSprayer_headline_n_slurryTanker", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.headline_n_manureSpreader = g_i18n:getText("hudExtensionSprayer_headline_n_manureSpreader", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.actualValue = g_i18n:getText("hudExtensionSprayer_actualValue", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.newValue = g_i18n:getText("hudExtensionSprayer_newValue", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.targetReached = g_i18n:getText("hudExtensionSprayer_targetReached", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.applicationRate = g_i18n:getText("hudExtensionSprayer_applicationRate", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.soilType = g_i18n:getText("hudExtensionSprayer_soilType", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.unknown = g_i18n:getText("hudExtensionSprayer_unknown", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.automaticShort = g_i18n:getText("hudExtensionSprayer_automaticShort", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.description_limeAuto = g_i18n:getText("hudExtensionSprayer_description_limeAuto", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.description_limeManual = g_i18n:getText("hudExtensionSprayer_description_limeManual", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.description_slurryAuto = g_i18n:getText("hudExtensionSprayer_description_slurryAuto", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.description_manureAuto = g_i18n:getText("hudExtensionSprayer_description_manureAuto", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.description_fertilizerAutoFruit = g_i18n:getText("hudExtensionSprayer_description_fertilizerAutoFruit", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.description_fertilizerAutoNoFruit = g_i18n:getText("hudExtensionSprayer_description_fertilizerAutoNoFruit", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.description_fertilizerAutoNoFruitDefault = g_i18n:getText("hudExtensionSprayer_description_fertilizerAutoNoFruitDefault", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.description_fertilizerManualFruit = g_i18n:getText("hudExtensionSprayer_description_fertilizerManualFruit", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.description_fertilizerManualNoFruit = g_i18n:getText("hudExtensionSprayer_description_fertilizerManualNoFruit", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.description_noFertilizerRequired = g_i18n:getText("hudExtensionSprayer_description_noFertilizerRequired", ExtendedSprayerHUDExtension.MOD_NAME)
    self.texts.invalidValues = g_i18n:getText("hudExtensionSprayer_invalidValues", ExtendedSprayerHUDExtension.MOD_NAME)
    self.actualValueStr = self.texts.unknown
    self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.setColorBlindMode, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)
    self:storeScaledValues()
    return self
end
function ExtendedSprayerHUDExtension:delete()
    self.backgroundTop:delete()
    self.backgroundMiddle:delete()
    self.backgroundBottom:delete()
    self.gradient:delete()
    self.gradientInactive:delete()
    self.actualBar:delete()
    self.targetBar:delete()
    self.targetFlag:delete()
    self.setValueBar:delete()
    self.footerSeparationBar:delete()
    g_messageCenter:unsubscribeAll(self)
    self.vehicle = nil
    self.extendedSprayer = nil
end
function ExtendedSprayerHUDExtension:storeScaledValues()
    local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
    local _, heightTopBottom = getNormalizedScreenValues(300 * uiScale, 0 * uiScale)
    self.contentMaxWidth = _
    local _, heightTopBottom = getNormalizedScreenValues(0, 8 * uiScale)
    local width, height = getNormalizedScreenValues(330 * uiScale, 129 * uiScale)
    self.backgroundTop:setDimension(width, heightTopBottom)
    self.backgroundMiddle:setDimension(width, height)
    self.backgroundBottom:setDimension(width, heightTopBottom)
    local _, displayHeight = getNormalizedScreenValues(260 * uiScale, 8 * uiScale)
    self.gradient:setDimension(_, displayHeight)
    self.gradientInactive:setDimension(_, displayHeight)
    local _, displayHeight = getNormalizedScreenValues(3 * uiScale, 20 * uiScale)
    self.actualBar:setDimension(_, displayHeight)
    local _, displayHeight = getNormalizedScreenValues(3 * uiScale, 6 * uiScale)
    self.targetBar:setDimension(_, displayHeight)
    local _, displayHeight = getNormalizedScreenValues(23 * uiScale, 29 * uiScale)
    self.targetFlag:setDimension(_, displayHeight)
    local _, displayHeight = getNormalizedScreenValues(3 * uiScale, 14 * uiScale)
    self.setValueBar:setDimension(_, displayHeight)
    local _, displayHeight = getNormalizedScreenValues(330 * uiScale, 0)
    self.footerSeparationBar:setDimension(_, g_pixelSizeY)
    local _, displayHeight = getNormalizedScreenValues(0 * uiScale, 130 * uiScale)
    self.displayHeight = displayHeight
    local _, additionalTextHeightOffset = getNormalizedScreenValues(0 * uiScale, 25 * uiScale)
    self.additionalTextHeightOffset = additionalTextHeightOffset
    local _, invalidHeightOffset = getNormalizedScreenValues(0 * uiScale, 50 * uiScale)
    self.invalidHeightOffset = invalidHeightOffset
    local _, noSetBarHeightOffset = getNormalizedScreenValues(0 * uiScale, 15 * uiScale)
    self.noSetBarHeightOffset = noSetBarHeightOffset
    self.additionalDisplayHeight = 0
    _, self.textHeightHeadline = getNormalizedScreenValues(0 * uiScale, 20 * uiScale)
    _, self.textHeight = getNormalizedScreenValues(0 * uiScale, 13 * uiScale)
    self.gradientPosX, self.gradientPosY = getNormalizedScreenValues(0 * uiScale, -75 * uiScale)
    _, self.footerOffset = getNormalizedScreenValues(0 * uiScale, 9 * uiScale)
    self.footerTextSpacing, _ = getNormalizedScreenValues(2 * uiScale, 0)
    self.pixelSizeX, self.pixelSizeY = getNormalizedScreenValues(1 * uiScale, 1 * uiScale)
end
function ExtendedSprayerHUDExtension:setColorBlindMode(isActive)
    if isActive ~= self.isColorBlindMode then
        self.isColorBlindMode = isActive
        self.pHMap:setMinimapRequiresUpdate(true)
        self.nitrogenMap:setMinimapRequiresUpdate(true)
    end
end
function ExtendedSprayerHUDExtension:getHeight()
    return (self.displayHeight or 0) + (self.additionalDisplayHeight or 0)
end
local function formatDecimalNumber(n)
    if math.floor(n) == n then
        return string.format("%.1f", n)
    else
        return string.format("%s", n)
    end
end
local function renderLimitedText(x, y, textSize, text, maxWidth)
    if maxWidth ~= nil then
        while maxWidth < getTextWidth(textSize, text) do
            textSize = textSize * 0.98
        end
    end
    setTextColor(1, 1, 1, 1)
    renderText(x, y, textSize, text)
    return getTextWidth(textSize, text)
end
function ExtendedSprayerHUDExtension:draw(_, posX, posY)
    -- upvalues: (copy) formatDecimalNumber, (copy) renderLimitedText
    local spec = self.extendedSprayer
    if spec == nil then
        return posY
    else
        local headline = self.texts.headline_ph_lime
        local applicationRateStr = "%.2f t/ha"
        local changeBarText = ""
        local minValue = 0
        local maxValue = 0
        self.hasValidValues = false
        local soilTypeName = ""
        if spec.lastTouchedSoilType ~= 0 and self.soilMap ~= nil then
            local soilType = self.soilMap:getSoilTypeByIndex(spec.lastTouchedSoilType)
            if soilType ~= nil then
                soilTypeName = soilType.name
            end
        end
        local sourceVehicle, fillUnitIndex = ExtendedSprayer.getFillTypeSourceVehicle(self.vehicle)
        local sprayFillType = sourceVehicle:getFillUnitFillType(fillUnitIndex)
        local massPerLiter = g_fillTypeManager:getFillTypeByIndex(sprayFillType).massPerLiter / FillTypeManager.MASS_SCALE
        local soilType = sprayFillType == FillType.LIME and true or false
        local descriptionText = ""
        local stepResolution = nil
        local enableZeroTargetFlag = false
        local pHChanged
        if soilType then
            self.gradient:setSliceId(self.isColorBlindMode and ExtendedSprayerHUDExtension.SLICES.COLOR_BLIND_GRADIENT or ExtendedSprayerHUDExtension.SLICES.PH_GRADIENT)
            self.gradientInactive:setSliceId(self.isColorBlindMode and ExtendedSprayerHUDExtension.SLICES.COLOR_BLIND_GRADIENT or ExtendedSprayerHUDExtension.SLICES.PH_GRADIENT)
            local pHChanged = 0
            pHChanged = spec.lastLitersPerHectar * massPerLiter
            if not spec.sprayAmountAutoMode then
                local requiredLitersPerHa = self.pHMap:getLimeUsageByStateChange(spec.sprayAmountManual)
                pHChanged = self.pHMap:getPhValueFromChangedStates(spec.sprayAmountManual)
                pHChanged = requiredLitersPerHa * massPerLiter
                if pHChanged > 0 then
                    changeBarText = string.format("pH +%s", formatDecimalNumber(pHChanged))
                end
            end
            if spec.phActualValue ~= 0 and (spec.phTargetValue ~= 0 and self.vehicle.isOnField) then
                local requiredLitersPerHa = self.pHMap:getPhValueFromInternalValue(spec.phActualValue)
                local pHTarget = self.pHMap:getPhValueFromInternalValue(spec.phTargetValue)
                self.actualValue = requiredLitersPerHa
                self.setValue = requiredLitersPerHa + pHChanged
                self.targetValue = pHTarget
                if spec.sprayAmountAutoMode then
                    local pHChanged = self.targetValue - self.actualValue
                    if pHChanged > 0 then
                        changeBarText = string.format("pH +%s", formatDecimalNumber(pHChanged))
                    end
                    self.setValue = self.targetValue
                end
                self.actualValueStr = "pH %.3f"
                if soilTypeName ~= "" then
                    if spec.sprayAmountAutoMode then
                        descriptionText = string.format(self.texts.description_limeAuto, soilTypeName, formatDecimalNumber(pHTarget))
                    else
                        descriptionText = string.format(self.texts.description_limeManual, soilTypeName, formatDecimalNumber(pHTarget))
                    end
                end
                self.hasValidValues = true
            end
            if self.pHMap ~= nil then
                minValue, maxValue = self.pHMap:getMinMaxValue()
            end
            stepResolution = spec.pHMap:getPhValueFromChangedStates(1)
        else
            self.gradient:setSliceId(self.isColorBlindMode and ExtendedSprayerHUDExtension.SLICES.COLOR_BLIND_GRADIENT or ExtendedSprayerHUDExtension.SLICES.N_GRADIENT)
            self.gradientInactive:setSliceId(self.isColorBlindMode and ExtendedSprayerHUDExtension.SLICES.COLOR_BLIND_GRADIENT or ExtendedSprayerHUDExtension.SLICES.N_GRADIENT)
            pHChanged = spec.lastLitersPerHectar
            local requiredLitersPerHa = 0
            if not spec.sprayAmountAutoMode then
                pHChanged = self.nitrogenMap:getFertilizerUsageByStateChange(spec.sprayAmountManual, sprayFillType)
                requiredLitersPerHa = self.nitrogenMap:getNitrogenFromChangedStates(spec.sprayAmountManual)
                if requiredLitersPerHa > 0 then
                    changeBarText = string.format("+%dkg N/ha", requiredLitersPerHa)
                end
            end
            if spec.isSolidFertilizerSprayer then
                headline = self.texts.headline_n_solidFertilizer
                applicationRateStr = "%d kg/ha"
            elseif spec.isLiquidFertilizerSprayer then
                headline = self.texts.headline_n_liquidFertilizer
                applicationRateStr = "%d l/ha"
            elseif spec.isSlurryTanker then
                headline = self.texts.headline_n_slurryTanker
                applicationRateStr = "%.1f m\194\179/ha"
                if spec.sprayAmountAutoMode and soilTypeName ~= "" then
                    descriptionText = string.format(self.texts.description_slurryAuto, soilTypeName)
                end
            elseif spec.isManureSpreader then
                headline = self.texts.headline_n_manureSpreader
                applicationRateStr = "%.1f t/ha"
                if spec.sprayAmountAutoMode and soilTypeName ~= "" then
                    descriptionText = string.format(self.texts.description_manureAuto, soilTypeName)
                end
            else
                pHChanged = 0
            end
            if spec.nActualValue > 0 and (spec.nTargetValue > 0 and (self.vehicle.isOnField and not spec.isDoingMissionWork)) then
                local fruitTypeIndex = spec.nActualValue
                local fillType = self.nitrogenMap.maxValue
                local pHTarget = self.nitrogenMap:getNitrogenValueFromInternalValue((math.clamp(fruitTypeIndex, 0, fillType)))
                local nTarget = self.nitrogenMap
                local fillType = spec.nTargetValue
                local nTarget = nTarget:getNitrogenValueFromInternalValue((math.clamp(fillType, 0, self.nitrogenMap.maxValue)))
                self.actualValue = pHTarget
                self.setValue = pHTarget + requiredLitersPerHa
                self.targetValue = nTarget
                if spec.sprayAmountAutoMode then
                    local requiredLitersPerHa = self.targetValue - self.actualValue
                    if requiredLitersPerHa > 0 then
                        changeBarText = string.format("+%dkg N/ha", requiredLitersPerHa)
                    end
                    self.setValue = self.targetValue
                end
                self.actualValueStr = "%dkg N/ha"
                local forcedFruitType = nil
                if vehicle.spec_sowingMachine ~= nil then
                    forcedFruitType = vehicle.spec_sowingMachine.workAreaParameters.seedsFruitType
                end
                local fruitTypeIndex = forcedFruitType or spec.nApplyAutoModeFruitType
                if fruitTypeIndex ~= nil then
                    local fillType = g_fillTypeManager:getFillTypeByIndex(g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitTypeIndex))
                    if fillType ~= nil and (fillType ~= FillType.UNKNOWN and soilTypeName ~= "") then
                        if nTarget > 0 then
                            if spec.sprayAmountAutoMode then
                                descriptionText = string.format(self.texts.description_fertilizerAutoFruit, fillType.title, soilTypeName)
                            else
                                descriptionText = string.format(self.texts.description_fertilizerManualFruit, fillType.title, soilTypeName)
                            end
                        else
                            descriptionText = self.texts.description_noFertilizerRequired
                            enableZeroTargetFlag = true
                        end
                    end
                end
                if descriptionText == "" and soilTypeName ~= "" then
                    if spec.sprayAmountAutoMode then
                        descriptionText = string.format(self.texts.description_fertilizerAutoNoFruit, soilTypeName)
                        if self.nitrogenMap ~= nil then
                            local fillType = self.nitrogenMap:getFruitTypeIndexByFruitRequirementIndex(spec.nApplyAutoModeFruitRequirementDefaultIndex)
                            if fillType ~= nil then
                                local fillType = g_fillTypeManager:getFillTypeByIndex(g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fillType))
                                if fillType ~= nil then
                                    descriptionText = string.format(self.texts.description_fertilizerAutoNoFruitDefault, fillType.title, soilTypeName)
                                end
                            end
                        end
                    else
                        descriptionText = string.format(self.texts.description_fertilizerManualNoFruit, soilTypeName)
                    end
                end
                self.hasValidValues = true
            end
            if self.nitrogenMap ~= nil then
                minValue, maxValue = self.nitrogenMap:getMinMaxValue()
                local pHTarget = spec.lastNitrogenProportion
                if pHTarget == 0 then
                    pHTarget = self.nitrogenMap:getNitrogenAmountFromFillType(sprayFillType)
                end
                if spec.isSlurryTanker then
                    local nTarget = sourceVehicle.getIsUsingExactNitrogenAmount ~= nil and sourceVehicle:getIsUsingExactNitrogenAmount() and " (%skgN/m\194\179)" or " (~%skgN/m\194\179)"
                    applicationRateStr = applicationRateStr .. string.format(nTarget, MathUtil.round(pHTarget * 1000, 1))
                else
                    applicationRateStr = applicationRateStr .. string.format(" (%s%%%%N)", MathUtil.round(pHTarget * 100, 1))
                end
                stepResolution = self.nitrogenMap:getNitrogenFromChangedStates(1)
            end
        end
        if spec.sprayAmountAutoMode then
            applicationRateStr = applicationRateStr .. string.format(" (%s)", self.texts.automaticShort)
            soilTypeName = ""
        end
        local requiredLitersPerHa = (self.actualValue - minValue) / (maxValue - minValue)
        self.actualPos = math.min(requiredLitersPerHa, 1)
        local requiredLitersPerHa = (self.setValue - minValue) / (maxValue - minValue)
        self.setValuePos = math.min(requiredLitersPerHa, 1)
        local requiredLitersPerHa = (self.targetValue - minValue) / (maxValue - minValue)
        self.targetPos = math.min(requiredLitersPerHa, 1)
        local requiredLitersPerHa = self:getHeight() - self.backgroundTop.height - self.backgroundBottom.height
        self.backgroundTop:setPosition(posX, posY - self.backgroundTop.height)
        self.backgroundMiddle:setPosition(posX, posY - self.backgroundTop.height - requiredLitersPerHa)
        self.backgroundBottom:setPosition(posX, posY - self.backgroundTop.height - requiredLitersPerHa - self.backgroundBottom.height)
        self.backgroundMiddle:setDimension(nil, requiredLitersPerHa)
        self.backgroundTop:render()
        self.backgroundMiddle:render()
        self.backgroundBottom:render()
        local pHTarget = posX + self.backgroundTop.width * 0.5
        setTextColor(1, 1, 1, 1)
        setTextBold(true)
        setTextAlignment(RenderText.ALIGN_CENTER)
        renderLimitedText(pHTarget, posY - self.textHeightHeadline * 1.1, self.textHeightHeadline, headline, self.contentMaxWidth)
        setTextBold(false)
        local nTarget = pHTarget - self.gradientInactive.width * 0.5 + self.gradientPosX
        local forcedFruitType = posY + self.gradientPosY
        if not self.hasValidValues then
        end
        self.gradientInactive:setPosition(nTarget, forcedFruitType)
        self.gradientInactive:render()
        local fruitTypeIndex = 0
        if self.hasValidValues then
            fruitTypeIndex = self.actualPos
        end
        self.gradient:setPosition(nTarget, forcedFruitType)
        self.gradient:setDimension(fruitTypeIndex * self.gradientInactive.width)
        local fillType = self.gradient.uvs
        local fillType = fillType[1] + (fillType[5] - fillType[1]) * fruitTypeIndex
        local uv7 = fillType[3] + (fillType[7] - fillType[3]) * fruitTypeIndex
        setOverlayUVs(self.gradient.overlayId, fillType[1], fillType[2], fillType[3], fillType[4], fillType, fillType[6], uv7, fillType[8])
        self.gradient:render()
        local widthDiff, widthDiff
        if soilType then
            widthDiff = string.format("pH\n%s", minValue)
            widthDiff = string.format("pH\n%s", maxValue)
        else
            widthDiff = string.format("%s\nkg/ha", minValue)
            widthDiff = string.format("%s\nkg/ha", maxValue)
        end
        local widthDiff = (self.backgroundTop.width - self.gradientInactive.width) * 0.25
        renderLimitedText(posX + widthDiff, forcedFruitType + self.gradientInactive.height * 0.85, self.gradientInactive.height * 1.3, widthDiff)
        renderLimitedText(posX + self.backgroundTop.width - widthDiff, forcedFruitType + self.gradientInactive.height * 0.85, self.gradientInactive.height * 1.3, widthDiff)
        local additionalChangeLineHeight = 0
        local changeBarRendered = false
        if self.hasValidValues then
            local targetBarX = nil
            local showFlag = self.targetPos ~= 0 and true or enableZeroTargetFlag
            if showFlag then
                targetBarX = nTarget + self.gradientInactive.width * self.targetPos - self.targetBar.width * 0.5
                self.targetBar:setPosition(targetBarX, forcedFruitType)
                self.targetBar:render()
                self.targetFlag:setPosition(targetBarX, forcedFruitType + self.targetBar.height)
                self.targetFlag:render()
            end
            local actualBarText = nil
            local actualBarTextOffset = self.actualBar.height + self.textHeight * 1.1
            local actualBarSkipFlagCollisionCheck = false
            if self.actualPos == self.targetPos then
                if (spec.sprayAmountAutoMode or self.targetPos == self.setValuePos) and self.targetPos ~= 0 then
                    actualBarText = string.format(self.texts.targetReached, string.format(self.actualValueStr, self.actualValue))
                    actualBarTextOffset = -self.textHeight * 0.7
                    actualBarSkipFlagCollisionCheck = true
                    changeBarRendered = true
                end
            else
                actualBarText = string.format(self.texts.actualValue, string.format(self.actualValueStr, self.actualValue))
            end
            if actualBarText ~= nil then
                local actualBarX = nTarget + self.gradientInactive.width * self.actualPos - self.actualBar.width * 0.5
                local actualBarY = forcedFruitType + (self.gradientInactive.height - self.actualBar.height) * 0.5
                self.actualBar:setPosition(actualBarX, actualBarY)
                self.actualBar:render()
                local actualTextWidth = getTextWidth(self.textHeight * 0.7, actualBarText)
                local leftTextBorder = math.min(actualBarX, posX + self.backgroundTop.width - actualTextWidth * 0.5)
                local rightTextBorder = math.max(leftTextBorder, posX + actualTextWidth * 0.5)
                if not actualBarSkipFlagCollisionCheck and showFlag then
                    local rightTextBorder = rightTextBorder + actualTextWidth * 0.5
                    if targetBarX < rightTextBorder and rightTextBorder < targetBarX + self.targetFlag.width * 0.5 then
                        rightTextBorder = targetBarX - actualTextWidth * 0.5 - self.pixelSizeX
                    end
                    local leftTextBorder = rightTextBorder - actualTextWidth * 0.5
                    if targetBarX < leftTextBorder and leftTextBorder < targetBarX + self.targetFlag.width * 0.5 or leftTextBorder < targetBarX and targetBarX < rightTextBorder then
                        rightTextBorder = targetBarX + self.targetFlag.width + self.pixelSizeX + actualTextWidth * 0.5
                    end
                end
                renderLimitedText(rightTextBorder, actualBarY + actualBarTextOffset, self.textHeight * 0.7, actualBarText)
            end
            if self.setValuePos > self.actualPos then
                local actualBarX = ExtendedSprayerHUDExtension.COLOR.SET_VALUE_BAR_GOOD
                local actualBarY = ExtendedSprayerHUDExtension.COLOR.SET_VALUE_BAR_BAD
                local rightTextBorder = math.abs(self.setValue - self.targetValue) / stepResolution / 3
                local actualTextWidth = math.min(rightTextBorder, 1)
                local rightTextBorder = 1 - actualTextWidth
                local setValueBarX = nTarget + self.gradientInactive.width * self.actualPos
                local setValueBarY = forcedFruitType - self.gradientInactive.height - self.setValueBar.height
                self.setValueBar:setPosition(setValueBarX, setValueBarY)
                self.setValueBar:setDimension(self.gradientInactive.width * (math.min(self.setValuePos, 1) - self.actualPos))
                self.setValueBar:setColor(actualTextWidth * actualBarY[1] + rightTextBorder * actualBarX[1], actualTextWidth * actualBarY[2] + rightTextBorder * actualBarX[2], actualTextWidth * actualBarY[3] + rightTextBorder * actualBarX[3], 1)
                self.setValueBar:render()
                local setBarTextY = setValueBarY + self.setValueBar.height * 0.2
                if getTextWidth(self.setValueBar.height * 0.9, changeBarText) > self.setValueBar.width * 0.95 then
                    setBarTextY = setValueBarY - self.setValueBar.height
                    additionalChangeLineHeight = self.setValueBar.height
                end
                renderLimitedText(setValueBarX + self.setValueBar.width * 0.5, setBarTextY, self.setValueBar.height * 0.9, changeBarText)
                changeBarRendered = true
            end
        else
            descriptionText = self.texts.invalidValues
        end
        local targetBarX = posY - self:getHeight()
        if descriptionText ~= "" and self.additionalDisplayHeight ~= 0 then
            setTextAlignment(RenderText.ALIGN_CENTER)
            renderLimitedText(pHTarget, targetBarX + self.footerOffset + self.textHeight * 1.85, self.textHeight, descriptionText, self.contentMaxWidth)
        end
        self.footerSeparationBar:setPosition(pHTarget - self.footerSeparationBar.width * 0.5, targetBarX + self.footerOffset + self.textHeight * 1.3)
        self.footerSeparationBar:render()
        setTextAlignment(RenderText.ALIGN_LEFT)
        local targetBarY = (self.backgroundTop.width - self.contentMaxWidth) * 0.5
        local showFlag = self.texts.applicationRate .. " " .. string.format(applicationRateStr, pHChanged, 0)
        local actualBarText = renderLimitedText(posX + targetBarY, targetBarX + self.footerOffset, self.textHeight, showFlag, self.contentMaxWidth)
        if soilTypeName ~= "" then
            setTextAlignment(RenderText.ALIGN_RIGHT)
            renderLimitedText(posX + self.backgroundTop.width - targetBarY, targetBarX + self.footerOffset, self.textHeight, string.format(self.texts.soilType, soilTypeName), self.contentMaxWidth - actualBarText - self.footerTextSpacing)
        end
        self.additionalDisplayHeight = additionalChangeLineHeight
        if descriptionText ~= "" then
            self.additionalDisplayHeight = self.additionalDisplayHeight + self.additionalTextHeightOffset
        end
        if self.hasValidValues then
            if not changeBarRendered then
                self.additionalDisplayHeight = self.additionalDisplayHeight - self.noSetBarHeightOffset
            end
            return targetBarX
        else
            self.additionalDisplayHeight = self.additionalDisplayHeight - self.invalidHeightOffset
            return targetBarX
        end
    end
end
ExtendedSprayerHUDExtension.COLOR = {
    ["TARGET_BAR"] = {
        1,
        1,
        1,
        1
    },
    ["ACTUAL_BAR"] = {
        0.601,
        0.01,
        0.01,
        1
    },
    ["SEPARATOR_BAR"] = {
        1,
        1,
        1,
        0.3
    },
    ["SET_VALUE_BAR_GOOD"] = {
        0.01,
        0.41,
        0.01,
        1
    },
    ["SET_VALUE_BAR_BAD"] = {
        0.61,
        0.01,
        0.01,
        1
    }
}
ExtendedSprayerHUDExtension.SLICES = {
    ["PH_GRADIENT"] = "precisionFarming.gradient_ph",
    ["N_GRADIENT"] = "precisionFarming.gradient_red_green",
    ["COLOR_BLIND_GRADIENT"] = "precisionFarming.gradient_color_blind"
}
if ExtendedSprayerHUDExtension ~= nil then
    g_currentMission.vehicleSystem:consoleCommandReloadVehicle()
end