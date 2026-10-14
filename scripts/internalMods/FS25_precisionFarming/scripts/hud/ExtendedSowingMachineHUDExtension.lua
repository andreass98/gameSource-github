ExtendedSowingMachineHUDExtension = {}
ExtendedSowingMachineHUDExtension.MOD_NAME = g_currentModName or ExtendedSowingMachineHUDExtension.MOD_NAME
ExtendedSowingMachineHUDExtension.MOD_DIR = g_currentModDirectory or ExtendedSowingMachineHUDExtension.MOD_DIR
ExtendedSowingMachineHUDExtension.GUI_ELEMENTS = ExtendedSowingMachineHUDExtension.MOD_DIR .. "gui/ui_elements.png"
local ExtendedSowingMachineHUDExtension_mt = Class(ExtendedSowingMachineHUDExtension)
function ExtendedSowingMachineHUDExtension.new(vehicle, customMt)
    -- upvalues: (copy) ExtendedSowingMachineHUDExtension_mt
    local self = setmetatable({}, customMt or ExtendedSowingMachineHUDExtension_mt)
    self.priority = GS_PRIO_NORMAL
    self.vehicle = vehicle
    self.extendedSowingMachine = vehicle[ExtendedSowingMachine.SPEC_TABLE_NAME]
    self.backgroundTop = g_overlayManager:createOverlay("precisionFarming.shortcutBox_top", 0, 0, 0, 0)
    self.backgroundMiddle = g_overlayManager:createOverlay("precisionFarming.shortcutBox_middle", 0, 0, 0, 0)
    self.backgroundBottom = g_overlayManager:createOverlay("precisionFarming.shortcutBox_bottom", 0, 0, 0, 0)
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.backgroundTop:setColor(r, g, b, a)
    self.backgroundMiddle:setColor(r, g, b, a)
    self.backgroundBottom:setColor(r, g, b, a)
    self.separatorHorizontal = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
    self.separatorHorizontal:setColor(1, 1, 1, 0.25)
    self.dots = {}
    for i = 1, 3 do
        local dotData = {
            ["dotEmpty"] = g_overlayManager:createOverlay("precisionFarming.seeds_dot_empty", 0, 0, 0, 0),
            ["dotFilled"] = g_overlayManager:createOverlay("precisionFarming.seeds_dot_filled", 0, 0, 0, 0),
            ["dotFill"] = g_overlayManager:createOverlay("precisionFarming.seeds_dot_fill", 0, 0, 0, 0)
        }
        table.insert(self.dots, dotData)
    end
    self.seedsOverlay = g_overlayManager:createOverlay(ExtendedSowingMachineHUDExtension.SEED_RATE_SLICES[1], 0, 0, 0, 0)
    self.recommendOverlay = g_overlayManager:createOverlay("precisionFarming.seeds_recommendationBar", 0, 0, 0, 0)
    self.recommendOverlay:setColor(0.5, 0.5, 0.5, 1)
    self.texts = {}
    self.texts.headline = g_i18n:getText("hudExtensionSowingMachine_headline", ExtendedSowingMachineHUDExtension.MOD_NAME)
    self.texts.seedRate = g_i18n:getText("hudExtensionSowingMachine_seedRate", ExtendedSowingMachineHUDExtension.MOD_NAME)
    self.texts.auto = g_i18n:getText("hudExtensionSowingMachine_auto", ExtendedSowingMachineHUDExtension.MOD_NAME)
    self.texts.notAvailable = g_i18n:getText("hudExtensionSowingMachine_notAvailable", ExtendedSowingMachineHUDExtension.MOD_NAME)
    self.texts.tramlineWidth = g_i18n:getText("hudExtensionSowingMachine_tramlineWidth", ExtendedSowingMachineHUDExtension.MOD_NAME)
    self.texts.tramlineNotAvailable = g_i18n:getText("hudExtensionSowingMachine_tramlineNotAvailable", ExtendedSowingMachineHUDExtension.MOD_NAME)
    self.seedRateMap = g_precisionFarming.seedRateMap
    self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.setColorBlindMode, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)
    self:storeScaledValues()
    return self
end
function ExtendedSowingMachineHUDExtension:delete()
    for _, dotData in ipairs(self.dots) do
        dotData.dotEmpty:delete()
        dotData.dotFilled:delete()
        dotData.dotFill:delete()
    end
    self.backgroundTop:delete()
    self.backgroundMiddle:delete()
    self.backgroundBottom:delete()
    self.separatorHorizontal:delete()
    self.seedsOverlay:delete()
    self.recommendOverlay:delete()
    g_messageCenter:unsubscribeAll(self)
    self.vehicle = nil
    self.extendedSowingMachine = nil
end
function ExtendedSowingMachineHUDExtension:storeScaledValues()
    local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
    local _, heightTopBottom = getNormalizedScreenValues(330 * uiScale, 61 * uiScale)
    self.displayWidth = _
    self.displayHeight = heightTopBottom
    local _, heightTopBottom = getNormalizedScreenValues(0, 8 * uiScale)
    self.backgroundTop:setDimension(self.displayWidth, heightTopBottom)
    self.backgroundMiddle:setDimension(self.displayWidth, self.displayHeight - heightTopBottom * 2)
    self.backgroundBottom:setDimension(self.displayWidth, heightTopBottom)
    local width, height = getNormalizedScreenValues(0, 41 * uiScale)
    self.seedRateHeight = height
    local width, height = getNormalizedScreenValues(0, 20 * uiScale)
    self.tramlineHeight = height
    self.separatorHorizontal:setDimension(self.displayWidth, g_pixelSizeY)
    local width, height = getNormalizedScreenValues(300 * uiScale, 0)
    self.contentWidth = width
    local width, height = getNormalizedScreenValues(0, 16 * uiScale)
    self.textHeightHeadline = height
    local width, height = getNormalizedScreenValues(0, -1 * uiScale)
    self.textOffsetHeadline = height
    local width, height = getNormalizedScreenValues(145 * uiScale, 0)
    self.textMaxWidthHeadline = width
    local width, height = getNormalizedScreenValues(249 * uiScale, 13 * uiScale)
    self.rateTextOffsetX = width
    self.rateTextHeight = height
    local width, height = getNormalizedScreenValues(0 * uiScale, 10 * uiScale)
    self.rateTextOffsetY = height
    local width, height = getNormalizedScreenValues(185 * uiScale, 13 * uiScale)
    self.modeTextOffsetX = width
    self.modeTextHeight = height
    local width, height = getNormalizedScreenValues(0, 2 * uiScale)
    self.modeTextOffset = height
    local width, height = getNormalizedScreenValues(205 * uiScale, 12 * uiScale)
    self.naTextOffsetX = width
    self.naTextHeight = height
    local width, height = getNormalizedScreenValues(120 * uiScale, 0)
    self.naTextMaxX = width
    local width, height = getNormalizedScreenValues(0, 1 * uiScale)
    self.naTextOffset = height
    local width, height = getNormalizedScreenValues(35 * uiScale, 0 * uiScale)
    self.dotsFullWidth = width
    local width, height = getNormalizedScreenValues(0 * uiScale, 0)
    self.seedOverlayOffsetX = width
    local width, height = getNormalizedScreenValues(0, 0 * uiScale)
    self.recommendOverlayOffsetY = height
    local width, height = getNormalizedScreenValues(12 * uiScale, 12 * uiScale)
    for _, dotData in ipairs(self.dots) do
        dotData.dotEmpty:setDimension(width, height)
        dotData.dotFilled:setDimension(width, height)
        dotData.dotFill:setDimension(width, height)
    end
    local width, height = getNormalizedScreenValues(30 * uiScale, 30 * uiScale)
    self.seedsOverlay:setDimension(width, height)
    local width, height = getNormalizedScreenValues(9 * uiScale, 4 * uiScale)
    self.recommendOverlay:setDimension(width, height)
end
function ExtendedSowingMachineHUDExtension:setColorBlindMode(isActive)
    if isActive ~= self.isColorBlindMode then
        self.isColorBlindMode = isActive
    end
end
function ExtendedSowingMachineHUDExtension:getHeight()
    return self.displayHeight or 0
end
local function renderLimitedText(x, y, textSize, text, maxWidth)
    if maxWidth ~= nil then
        while maxWidth < getTextWidth(textSize, text) do
            textSize = textSize * 0.98
        end
    end
    setTextColor(1, 1, 1, 1)
    renderText(x, y, textSize, text)
end
function ExtendedSowingMachineHUDExtension:draw(inputHelpDisplay, posX, posY)
    -- upvalues: (copy) renderLimitedText
    if self.extendedSowingMachine == nil then
        return posY
    end
    self.backgroundTop:setPosition(posX, posY - self.backgroundTop.height)
    self.backgroundMiddle:setPosition(posX, posY - self.backgroundTop.height - self.backgroundMiddle.height)
    self.backgroundBottom:setPosition(posX, posY - self.backgroundTop.height - self.backgroundMiddle.height - self.backgroundBottom.height)
    self.backgroundTop:render()
    self.backgroundMiddle:render()
    self.backgroundBottom:render()
    posY = posY - self.seedRateHeight
    local contentOffset = (self.displayWidth - self.contentWidth) * 0.5
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
    renderLimitedText(posX + contentOffset, posY + self.seedRateHeight * 0.55 + self.textOffsetHeadline, self.textHeightHeadline, self.texts.headline, self.textMaxWidthHeadline)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
    setTextBold(false)
    local spec = self.extendedSowingMachine
    local seedsFruitType = self.vehicle.spec_sowingMachine.workAreaParameters.seedsFruitType
    local lastSeedRate = spec.lastSeedRate
    local lastSeedRateIndex = spec.lastSeedRateIndex
    if not spec.seedRateAutoMode then
        lastSeedRate = self.seedRateMap:getSeedRateByFruitTypeAndIndex(seedsFruitType, spec.manualSeedRate)
    end
    local isSupported = self.seedRateMap:getIsFruitTypeSupported(seedsFruitType)
    if isSupported then
        setTextAlignment(RenderText.ALIGN_CENTER)
        local currentRatePosX = posX + self.rateTextOffsetX
        local currentRatePosY = posY + self.seedRateHeight * 0.5 - self.rateTextHeight * 0.5 + self.rateTextOffsetY
        renderLimitedText(currentRatePosX, currentRatePosY, self.rateTextHeight, string.format(self.texts.seedRate, lastSeedRate))
        local i = 1
        for i = i, #self.dots do
            local dotData = self.dots[i]
            if lastSeedRateIndex < i then
                dotData.dotEmpty:setPosition(currentRatePosX + (i / 2 - 1) * self.dotsFullWidth - dotData.dotEmpty.width * 0.5, currentRatePosY - dotData.dotEmpty.height * 1.5)
                dotData.dotEmpty:render()
            else
                dotData.dotFilled:setPosition(dotPosX, dotPosY)
                dotData.dotFill:setPosition(dotPosX, dotPosY)
                dotData.dotFilled:render()
                local color = self.seedRateMap:getDisplayValues()[lastSeedRateIndex].colors[self.isColorBlindMode][1]
                dotData.dotFill:setColor(color[1], color[2], color[3], 1)
                dotData.dotFill:render()
            end
            if not spec.seedRateAutoMode and (spec.seedRateRecommendation ~= nil and i <= spec.seedRateRecommendation) then
                self.recommendOverlay:setPosition(dotPosX + dotData.dotEmpty.width * 0.5 - self.recommendOverlay.width * 0.5, dotPosY - self.recommendOverlay.height + self.recommendOverlayOffsetY)
                self.recommendOverlay:render()
            end
        end
        if spec.seedRateAutoMode then
            setTextAlignment(RenderText.ALIGN_CENTER)
            setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
            renderLimitedText(posX + self.modeTextOffsetX, posY + self.seedRateHeight * 0.52, self.modeTextHeight, self.texts.auto)
        end
    else
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
        renderLimitedText(posX + contentOffset + self.naTextOffsetX, posY + self.seedRateHeight * 0.52, self.naTextHeight, self.texts.notAvailable, self.naTextMaxX)
    end
    local currentRatePosX = (lastSeedRateIndex == 0 or not isSupported) and 2 or lastSeedRateIndex
    local currentRatePosY = self.seedsOverlay
    local i = ExtendedSowingMachineHUDExtension.SEED_RATE_SLICES
    local dotPosX = math.min(currentRatePosX, 3)
    currentRatePosY:setSliceId(i[math.max(dotPosX, 1)])
    self.seedsOverlay:setPosition(posX + self.backgroundTop.width - self.seedsOverlay.width - contentOffset * 0.5, posY + self.seedRateHeight * 0.5 - self.seedsOverlay.height * 0.5)
    self.seedsOverlay:render()
    posY = posY - self.tramlineHeight
    self.separatorHorizontal:renderCustom(posX, posY + self.tramlineHeight)
    local currentRatePosY = inputHelpDisplay.textSize
    local tramlineText
    if spec.tramlineWidth == nil then
        tramlineText = self.texts.tramlineNotAvailable
    else
        tramlineText = string.format(self.texts.tramlineWidth, spec.tramlineWidth)
    end
    local tramlineText = utf8ToUpper(tramlineText)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(true)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
    renderLimitedText(posX + contentOffset, posY + self.tramlineHeight * 0.6, currentRatePosY, tramlineText)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
    setTextBold(false)
    return posY
end
ExtendedSowingMachineHUDExtension.SEED_RATE_SLICES = { "precisionFarming.seeds_rate_low", "precisionFarming.seeds_rate_mid", "precisionFarming.seeds_rate_high" }
if ExtendedSowingMachineHUDExtension ~= nil then
    g_currentMission.vehicleSystem:consoleCommandReloadVehicle()
end