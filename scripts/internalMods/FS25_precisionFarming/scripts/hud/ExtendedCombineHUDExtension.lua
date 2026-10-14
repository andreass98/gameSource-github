ExtendedCombineHUDExtension = {}
ExtendedCombineHUDExtension.MOD_NAME = g_currentModName or ExtendedCombineHUDExtension.MOD_NAME
ExtendedCombineHUDExtension.MOD_DIR = g_currentModDirectory or ExtendedCombineHUDExtension.MOD_DIR
local ExtendedCombineHUDExtension_mt = Class(ExtendedCombineHUDExtension)
function ExtendedCombineHUDExtension.new(vehicle, customMt)
    -- upvalues: (copy) ExtendedCombineHUDExtension_mt
    local self = setmetatable({}, customMt or ExtendedCombineHUDExtension_mt)
    self.priority = GS_PRIO_LOW
    self.vehicle = vehicle
    self.combine = vehicle.spec_combine
    self.extendedCombine = vehicle[ExtendedCombine.SPEC_TABLE_NAME]
    self.backgroundTop = g_overlayManager:createOverlay("precisionFarming.shortcutBox_top", 0, 0, 0, 0)
    self.backgroundMiddle = g_overlayManager:createOverlay("precisionFarming.shortcutBox_middle", 0, 0, 0, 0)
    self.backgroundBottom = g_overlayManager:createOverlay("precisionFarming.shortcutBox_bottom", 0, 0, 0, 0)
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.backgroundTop:setColor(r, g, b, a)
    self.backgroundMiddle:setColor(r, g, b, a)
    self.backgroundBottom:setColor(r, g, b, a)
    self.separatorVertical = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
    self.separatorVertical:setColor(1, 1, 1, 0.25)
    self.yieldPercentageBar = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
    self.yieldPercentageBar:setColor(1, 1, 1, 1)
    self.currentYieldOverlay = g_overlayManager:createOverlay("precisionFarming.currentYield", 0, 0, 0, 0)
    self.currentYieldOverlay:setColor(1, 1, 1, 1)
    self.workAreaOverlay = g_overlayManager:createOverlay("precisionFarming.workedArea", 0, 0, 0, 0)
    self.workAreaOverlay:setColor(1, 1, 1, 1)
    self.workAreaOverlayTotal = g_overlayManager:createOverlay("precisionFarming.workedAreaTotal", 0, 0, 0, 0)
    self.workAreaOverlayTotal:setColor(1, 1, 1, 1)
    self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.setColorBlindMode, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)
    self:storeScaledValues()
    return self
end
function ExtendedCombineHUDExtension:delete()
    self.backgroundTop:delete()
    self.backgroundMiddle:delete()
    self.backgroundBottom:delete()
    self.separatorVertical:delete()
    self.yieldPercentageBar:delete()
    self.currentYieldOverlay:delete()
    self.workAreaOverlay:delete()
    self.workAreaOverlayTotal:delete()
    g_messageCenter:unsubscribeAll(self)
    self.vehicle = nil
    self.combine = nil
    self.extendedCombine = nil
end
function ExtendedCombineHUDExtension:storeScaledValues()
    local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
    local _, heightTopBottom = getNormalizedScreenValues(330 * uiScale, 42 * uiScale)
    self.displayWidth = _
    self.displayHeight = heightTopBottom
    local _, heightTopBottom = getNormalizedScreenValues(0, 8 * uiScale)
    self.backgroundTop:setDimension(self.displayWidth, heightTopBottom)
    self.backgroundMiddle:setDimension(self.displayWidth, self.displayHeight - heightTopBottom * 2)
    self.backgroundBottom:setDimension(self.displayWidth, heightTopBottom)
    self.separatorVertical:setDimension(g_pixelSizeX, self.displayHeight * 0.8)
    local barX, barY = getNormalizedScreenValues(20 * uiScale, 3 * uiScale)
    self.yieldPercentageBar:setDimension(barX, barY)
    self.iconX, self.iconY = getNormalizedScreenValues(38 * uiScale, 38 * uiScale)
    self.currentYieldOverlay:setDimension(self.iconX, self.iconY)
    self.workAreaOverlay:setDimension(self.iconX, self.iconY)
    self.workAreaOverlayTotal:setDimension(self.iconX, self.iconY)
    self.contentWidth, _ = getNormalizedScreenValues(310 * uiScale, 0)
    self.spacingX, _ = getNormalizedScreenValues(5 * uiScale, 0)
    self.textWidth, _ = getNormalizedScreenValues(38 * uiScale, 0)
end
function ExtendedCombineHUDExtension:setColorBlindMode(isActive)
    if isActive ~= self.isColorBlindMode then
        self.isColorBlindMode = isActive
    end
end
function ExtendedCombineHUDExtension:getHeight()
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
function ExtendedCombineHUDExtension:draw(inputHelpDisplay, posX, posY)
    -- upvalues: (copy) renderLimitedText
    if self.extendedCombine == nil then
        return posY
    end
    local yieldPct = self.extendedCombine.lastYieldPercentage
    local areaUnit = g_i18n:getText("unit_haShort")
    local yieldUnit = g_i18n:getText("unit_tonsShort") .. " / " .. areaUnit
    self.backgroundTop:setPosition(posX, posY - self.backgroundTop.height)
    self.backgroundMiddle:setPosition(posX, posY - self.backgroundTop.height - self.backgroundMiddle.height)
    self.backgroundBottom:setPosition(posX, posY - self.backgroundTop.height - self.backgroundMiddle.height - self.backgroundBottom.height)
    self.backgroundTop:render()
    self.backgroundMiddle:render()
    self.backgroundBottom:render()
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
    posX = posX + (self.displayWidth - self.contentWidth) * 0.5
    self.currentYieldOverlay:setPosition(posX, posY - self.displayHeight * 0.5 - self.currentYieldOverlay.height * 0.5)
    self.currentYieldOverlay:render()
    posX = posX + self.iconX + self.spacingX
    setTextBold(true)
    renderLimitedText(posX + self.textWidth * 0.5, posY - self.displayHeight * 0.3, inputHelpDisplay.textSize * 1.25, string.format("%.1f", self.extendedCombine.lastYieldWeight), self.textWidth)
    setTextBold(false)
    renderLimitedText(posX + self.textWidth * 0.5, posY - self.displayHeight * 0.7, inputHelpDisplay.textSize, yieldUnit, self.textWidth)
    posX = posX + self.textWidth + self.spacingX
    self.separatorVertical:setPosition(posX, posY - self.displayHeight * 0.5 - self.separatorVertical.height * 0.5)
    self.separatorVertical:render()
    posX = posX + self.spacingX
    setTextBold(true)
    renderLimitedText(posX + self.textWidth * 0.5, posY - self.displayHeight * 0.3, inputHelpDisplay.textSize * 1.25, string.format("%d", yieldPct), self.textWidth)
    setTextBold(false)
    renderLimitedText(posX + self.textWidth * 0.5, posY - self.displayHeight * 0.65, inputHelpDisplay.textSize, "%", self.textWidth)
    self.yieldPercentageBar:setPosition(posX + self.textWidth * 0.5 - self.yieldPercentageBar.width * 0.5, posY - self.displayHeight * 0.92)
    local r, g, b = ExtendedCombineHUDExtension.GRADIENT[self.isColorBlindMode]:get((yieldPct - 50) / (self.extendedCombine.lastYieldPotential - 50))
    self.yieldPercentageBar:setColor(r, g, b, 1)
    self.yieldPercentageBar:render()
    posX = posX + self.textWidth + self.spacingX
    self.separatorVertical:setPosition(posX, posY - self.displayHeight * 0.5 - self.separatorVertical.height * 0.5)
    self.separatorVertical:render()
    posX = posX + self.spacingX
    self.workAreaOverlay:setPosition(posX, posY - self.displayHeight * 0.5 - self.workAreaOverlay.height * 0.5)
    self.workAreaOverlay:render()
    posX = posX + self.iconX + self.spacingX
    setTextBold(true)
    renderLimitedText(posX + self.textWidth * 0.5, posY - self.displayHeight * 0.3, inputHelpDisplay.textSize * 1.25, string.format("%.1f", self.combine.workedHectars - self.combine.workedHectarsInitial), self.textWidth)
    setTextBold(false)
    renderLimitedText(posX + self.textWidth * 0.5, posY - self.displayHeight * 0.7, inputHelpDisplay.textSize, areaUnit, self.textWidth)
    posX = posX + self.textWidth + self.spacingX
    self.separatorVertical:setPosition(posX, posY - self.displayHeight * 0.5 - self.separatorVertical.height * 0.5)
    self.separatorVertical:render()
    posX = posX + self.spacingX
    self.workAreaOverlayTotal:setPosition(posX, posY - self.displayHeight * 0.5 - self.workAreaOverlayTotal.height * 0.5)
    self.workAreaOverlayTotal:render()
    posX = posX + self.iconX + self.spacingX
    setTextBold(true)
    renderLimitedText(posX + self.textWidth * 0.5, posY - self.displayHeight * 0.3, inputHelpDisplay.textSize * 1.25, string.format("%.1f", self.combine.workedHectars), self.textWidth)
    setTextBold(false)
    renderLimitedText(posX + self.textWidth * 0.5, posY - self.displayHeight * 0.7, inputHelpDisplay.textSize, areaUnit, self.textWidth)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
    setTextAlignment(RenderText.ALIGN_LEFT)
    return posY - self.displayHeight
end
ExtendedCombineHUDExtension.GRADIENT = {}
ExtendedCombineHUDExtension.GRADIENT[false] = AnimCurve.new(linearInterpolator3, 2)
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    0.9216,
    0.0003,
    0.0012,
    ["time"] = 0
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    0.9911,
    0.0152,
    0,
    ["time"] = 0.0667
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    0.9911,
    0.0529,
    0,
    ["time"] = 0.1333
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    0.9911,
    0.0999,
    0,
    ["time"] = 0.2
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    0.9911,
    0.1714,
    0,
    ["time"] = 0.2667
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    0.9911,
    0.2664,
    0,
    ["time"] = 0.3333
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    1,
    0.4125,
    0,
    ["time"] = 0.4
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    1,
    0.5457,
    0,
    ["time"] = 0.4667
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    0.7758,
    0.5395,
    0.0021,
    ["time"] = 0.5333
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    0.5089,
    0.5089,
    0.0056,
    ["time"] = 0.6
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    0.3278,
    0.4969,
    0.011,
    ["time"] = 0.6667
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    0.1878,
    0.4793,
    0.0242,
    ["time"] = 0.7333
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    0.0931,
    0.4793,
    0.0382,
    ["time"] = 0.8
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    0.0319,
    0.4621,
    0.0529,
    ["time"] = 0.8667
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    0.0048,
    0.3419,
    0.0723,
    ["time"] = 0.9333
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
    0.0048,
    0.2619,
    0.1223,
    ["time"] = 1
})
ExtendedCombineHUDExtension.GRADIENT[true] = AnimCurve.new(linearInterpolator3, 2)
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    0.3467,
    0.1384,
    0.0296,
    ["time"] = 0
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    0.402,
    0.1912,
    0.0497,
    ["time"] = 0.0667
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    0.4793,
    0.2705,
    0.0823,
    ["time"] = 0.1333
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    0.5711,
    0.3813,
    0.1329,
    ["time"] = 0.2
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    0.6514,
    0.4852,
    0.1845,
    ["time"] = 0.2667
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    0.7835,
    0.6445,
    0.3278,
    ["time"] = 0.3333
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    1,
    0.8963,
    0.7231,
    ["time"] = 0.4
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    1,
    1,
    1,
    ["time"] = 0.4667
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    0.7605,
    0.9301,
    0.9559,
    ["time"] = 0.5333
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    0.3763,
    0.6795,
    0.6307,
    ["time"] = 0.6
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    0.227,
    0.5395,
    0.4675,
    ["time"] = 0.6667
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    0.1714,
    0.4564,
    0.3916,
    ["time"] = 0.7333
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    0.1144,
    0.3712,
    0.305,
    ["time"] = 0.8
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    0.0742,
    0.2961,
    0.2307,
    ["time"] = 0.8667
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    0.0482,
    0.2384,
    0.1812,
    ["time"] = 0.9333
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
    0.0282,
    0.1884,
    0.1312,
    ["time"] = 1
})
if ExtendedCombineHUDExtension ~= nil then
    g_currentMission.vehicleSystem:consoleCommandReloadVehicle()
end