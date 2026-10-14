local data = nil
if GameInfoDisplayMobile ~= nil then
    local old = g_currentMission.hud.gameInfoDisplay
    data = {
        ["vehicle"] = old.vehicle,
        ["hud"] = old.hud,
        ["uiScale"] = old.uiScale,
        ["hudAtlasPath"] = old.hudAtlasPath,
        ["controlHudAtlasPath"] = old.controlHudAtlasPath,
        ["moneyUnit"] = old.moneyUnit,
        ["missionInfo"] = old.missionInfo,
        ["environment"] = old.environment
    }
    old:delete()
end
GameInfoDisplayMobile = {}
local old = Class(GameInfoDisplayMobile, HUDDisplayElement)
GameInfoDisplayMobile.HIDE_TIME = 500
function GameInfoDisplayMobile.new(hud, hudAtlasPath, moneyUnit, controlHudAtlasPath)
    -- upvalues: (copy) old
    local backgroundOverlay = GameInfoDisplayMobile.createBackground()
    local self = GameInfoDisplayMobile:superClass().new(backgroundOverlay, nil, old)
    self.hud = hud
    self.uiScale = 1
    self.hudAtlasPath = hudAtlasPath
    self.controlHudAtlasPath = controlHudAtlasPath
    self.moneyUnit = moneyUnit
    self.vehicle = nil
    self.isRideable = false
    self.buttons = {}
    self.textElements = {}
    self:createMenuButton()
    self:createShopButton()
    self:createMapButton()
    self:createHelpButton()
    self:createWeatherElement()
    self:createMoneyElement()
    self:createFuelFitnessElement()
    g_messageCenter:subscribe(MessageType.INSETS_CHANGED, self.updateInsets, self)
    return self
end
function GameInfoDisplayMobile:setVehicle(vehicle)
    self.vehicle = vehicle
    if vehicle == nil then
        self.isRideable = false
    else
        self.isRideable = SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations)
    end
    self.fuelFitnessElement:setVisible(vehicle ~= nil)
end
function GameInfoDisplayMobile:createButton(callbackFunc, iconSize, iconUVs, inputAction, refButton)
    local buttonOffsetX = getNormalizedScreenValues
    local buttonOffsetX, buttonOffsetY = buttonOffsetX(unpack(GameInfoDisplayMobile.POSITION.BUTTON_OFFSET))
    local iconSizeX, iconSizeY = getNormalizedScreenValues(unpack(iconSize))
    local button = HUDButtonElement.new(self.hud, 0, 0)
    local buttonWidth = button:getWidth()
    local basePosX, basePosY = self:getPosition()
    local baseWidth = self:getWidth()
    local baseHeight = self:getHeight()
    local anchorRight = basePosX + baseWidth
    local anchorTop = basePosY + baseHeight
    local posX
    if refButton == nil then
        posX = anchorRight
    else
        posX = refButton:getPosition() + buttonOffsetX
    end
    local posX = posX - buttonWidth
    local buttonPosX = anchorTop + buttonOffsetY - button:getHeight()
    button:setPosition(posX, buttonPosX)
    button:setIcon(self.controlHudAtlasPath, iconSizeX, iconSizeY, GuiUtils.getUVs(iconUVs))
    button:setAction(inputAction)
    button:addTouchHandler(callbackFunc, self)
    button.offsetX = posX - anchorRight
    button.offsetY = buttonPosX - anchorTop
    table.insert(self.buttons, button)
    self:addChild(button)
    return button
end
function GameInfoDisplayMobile:updateButtonPosition(button, refPosX, _)
    button:setPosition(refPosX + button.offsetX * self.uiScale, nil)
end
function GameInfoDisplayMobile:createMenuButton()
    self.menuButton = self:createButton(self.onOpenMenu, GameInfoDisplayMobile.SIZE.ICON, GameInfoDisplayMobile.UV.MENU, InputAction.MENU)
end
function GameInfoDisplayMobile:createShopButton()
    self.shopButton = self:createButton(self.onOpenShop, GameInfoDisplayMobile.SIZE.ICON, GameInfoDisplayMobile.UV.SHOP, InputAction.TOGGLE_STORE, self.menuButton)
end
function GameInfoDisplayMobile:createMapButton()
    self.mapButton = self:createButton(self.onOpenMap, GameInfoDisplayMobile.SIZE.ICON, GameInfoDisplayMobile.UV.MAP, InputAction.TOGGLE_MAP, self.shopButton)
end
function GameInfoDisplayMobile:createHelpButton()
    local width, height = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.BUTTON_HIGHLIGHT))
    Overlay.new(self.hudAtlasPath, 0, 0, width, height):setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.BUTTON_HIGHLIGHT))
    self.helpHighlightElement = HUDElement.new(highlight)
    self:addChild(self.helpHighlightElement)
    self.helpHighlightElement:setVisible(false)
    self.helpButton = self:createButton(self.onOpenHelp, GameInfoDisplayMobile.SIZE.ICON, GameInfoDisplayMobile.UV.HELP, InputAction.TOGGLE_HELP, self.mapButton)
    local basePosX, basePosY = self:getPosition()
    local anchorTop = basePosY + self:getHeight()
    local anchorRight = basePosX + self:getWidth()
    local offsetX, offsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.BUTTON_HIGHLIGHT))
    local posX, posY = self.helpButton:getPosition()
    local posY = posY + offsetY
    self.helpHighlightElement:setPosition(posX + offsetX, posY)
    self.helpHighlightElement.offsetX = posX - anchorRight
    self.helpHighlightElement.offsetY = posY - anchorTop
end
function GameInfoDisplayMobile:createBackgroundElements(posX, posY, sizeX)
    local sizeXLeft, sizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.BG_LEFT))
    local sizeXRight, _ = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.BG_RIGHT))
    Overlay.new(self.hudAtlasPath, posX, posY, sizeXLeft, sizeY):setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.BG_LEFT))
    local baseElement = HUDElement.new(overlayLeft)
    self:addChild(baseElement)
    local posXMiddle = posX + sizeXLeft
    local sizeXMiddle = sizeX - sizeXLeft - sizeXRight
    local overlayMiddle = Overlay.new(self.hudAtlasPath, posXMiddle, posY, sizeXMiddle, sizeY)
    overlayMiddle:setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.BG_MIDDLE))
    baseElement:addChild(HUDElement.new(overlayMiddle))
    local overlayRight = Overlay.new(self.hudAtlasPath, posXMiddle + sizeXMiddle, posY, sizeXRight, sizeY)
    overlayRight:setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.BG_RIGHT))
    baseElement:addChild(HUDElement.new(overlayRight))
    baseElement.totalSize = sizeX
    return baseElement
end
function GameInfoDisplayMobile:createWeatherElement()
    local sizeX, sizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.WEATHER))
    self.weatherOffsetX = sizeX
    self.weatherOffsetY = sizeY
    local sizeX, sizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.WEATHER))
    local posX = math.max(self:getPosition(), self.weatherOffsetX)
    local posY = 1 + self.weatherOffsetY - sizeY
    self.weatherElement = self:createBackgroundElements(posX, posY, sizeX)
    local separatorSizeX, separatorSizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.WEATHER_SEPARATOR))
    local separatorOffsetX, separatorOffsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.WEATHER_SEPARATOR))
    Overlay.new(self.hudAtlasPath, posX + separatorOffsetX, posY + separatorOffsetY, separatorSizeX, separatorSizeY):setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
    self.weatherElement:addChild(HUDElement.new(separatorOverlay))
    local seasonOverlayUVs = {}
    for i, uvs in pairs(GameInfoDisplayMobile.UV.SEASON_ICON) do
        seasonOverlayUVs[i] = GuiUtils.getUVs(uvs)
    end
    local seasonIconSizeX, seasonIconSizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.SEASON_ICON))
    local uvs = GameInfoDisplayMobile.POSITION.SEASON_ICON
    local seasonOffsetX, i = getNormalizedScreenValues(unpack(uvs))
    local uvs = Overlay.new(self.controlHudAtlasPath, posX + seasonOffsetX, posY + i, seasonIconSizeX, seasonIconSizeY)
    uvs:setUVs(seasonOverlayUVs[1])
    local seasonElement = HUDElement.new(uvs)
    self.weatherElement:addChild(seasonElement)
    local _, textSize = getNormalizedScreenValues(0, GameInfoDisplayMobile.SIZE.MONTH_TEXT)
    local monthOffsetX = getNormalizedScreenValues
    local colorWhite = GameInfoDisplayMobile.POSITION.MONTH_TEXT
    local monthOffsetX, monthOffsetY = monthOffsetX(unpack(colorWhite))
    local colorWhite = {
        1,
        1,
        1,
        1
    }
    table.insert(self.textElements, function()
        -- upvalues: (copy) seasonElement, (copy) seasonOverlayUVs, (copy) self, (copy) monthOffsetX, (copy) monthOffsetY, (copy) textSize, (copy) colorWhite
        seasonElement:setUVs(seasonOverlayUVs[self.environment.currentSeason])
        local text = g_i18n:formatDayInPeriod(nil, nil, true)
        local x, y = self.weatherElement:getPosition()
        GameInfoDisplayMobile.drawText(x + monthOffsetX * self.uiScale, y + monthOffsetY * self.uiScale, textSize * self.uiScale, true, RenderText.ALIGN_LEFT, colorWhite, text)
    end)
    local timeIconSizeX, timeIconSizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.TIME_ICON))
    local timeOffsetX, timeOffsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.TIME_ICON))
    Overlay.new(self.controlHudAtlasPath, posX + timeOffsetX, posY + timeOffsetY, timeIconSizeX, timeIconSizeY):setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.TIME))
    local timeElement = HUDElement.new(timeOverlay)
    self.weatherElement:addChild(timeElement)
    local _, timeTextSize = getNormalizedScreenValues(0, GameInfoDisplayMobile.SIZE.TIME_TEXT)
    local timeTextOffsetX = getNormalizedScreenValues
    local timeTextSpacingOffsetX = GameInfoDisplayMobile.POSITION.TIME_TEXT
    local timeTextOffsetX, timeTextOffsetY = timeTextOffsetX(unpack(timeTextSpacingOffsetX))
    local timeTextSpacingOffsetX = getNormalizedScreenValues
    local timeTextSpacingOffsetX, _ = timeTextSpacingOffsetX(unpack(GameInfoDisplayMobile.POSITION.TIME_TEXT_OFFSET))
    table.insert(self.textElements, function()
        -- upvalues: (copy) self, (copy) timeTextOffsetX, (copy) timeTextOffsetY, (copy) timeTextSpacingOffsetX, (copy) timeTextSize, (copy) colorWhite
        local currentTime = self.environment.dayTime / 3600000
        local timeHours = math.floor(currentTime)
        local timeMinutes = math.floor((currentTime - timeHours) * 60)
        local minutes = string.format("%02d", timeMinutes)
        local x, y = self.weatherElement:getPosition()
        local textX = x + timeTextOffsetX * self.uiScale
        local textY = y + timeTextOffsetY * self.uiScale
        GameInfoDisplayMobile.drawText(textX - timeTextSpacingOffsetX * self.uiScale, textY, timeTextSize * self.uiScale, true, RenderText.ALIGN_RIGHT, colorWhite, (string.format("%02d", timeHours)))
        GameInfoDisplayMobile.drawText(textX, textY, timeTextSize * self.uiScale, true, RenderText.ALIGN_CENTER, colorWhite, ":")
        GameInfoDisplayMobile.drawText(textX + timeTextSpacingOffsetX * self.uiScale, textY, timeTextSize * self.uiScale, true, RenderText.ALIGN_LEFT, colorWhite, minutes)
    end)
end
function GameInfoDisplayMobile:createMoneyElement()
    local sizeX, sizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.MONEY))
    local weatherPos, weatherWidth = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.MONEY))
    self.moneyOffsetX = weatherPos
    self.moneyOffsetY = weatherWidth
    local posY = 1 + self.moneyOffsetY - sizeY
    self.moneyElement = self:createBackgroundElements(self.weatherElement:getPosition() + self.weatherElement.totalSize + self.moneyOffsetX, posY, sizeX)
    local moneyOverlayUVs = {}
    for i, uvs in pairs(GameInfoDisplayMobile.UV.MONEY_ICON) do
        moneyOverlayUVs[i] = GuiUtils.getUVs(uvs)
    end
    local iconSizeX, iconSizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.MONEY_ICON))
    local uvs = GameInfoDisplayMobile.POSITION.MONEY_ICON
    local iconOffsetX, i = getNormalizedScreenValues(unpack(uvs))
    local uvs = Overlay.new(self.controlHudAtlasPath, posX + iconOffsetX, posY + i, iconSizeX, iconSizeY)
    uvs:setUVs(moneyOverlayUVs[1])
    local moneyElement = HUDElement.new(uvs)
    self.moneyElement:addChild(moneyElement)
    local _, textSize = getNormalizedScreenValues(0, GameInfoDisplayMobile.SIZE.MONEY_TEXT)
    local moneyOffsetX = getNormalizedScreenValues
    local colorWhite = GameInfoDisplayMobile.POSITION.MONEY_TEXT
    local moneyOffsetX, moneyOffsetY = moneyOffsetX(unpack(colorWhite))
    local colorWhite = {
        1,
        1,
        1,
        1
    }
    table.insert(self.textElements, function()
        -- upvalues: (copy) moneyElement, (copy) moneyOverlayUVs, (copy) self, (copy) moneyOffsetX, (copy) moneyOffsetY, (copy) textSize, (copy) colorWhite
        moneyElement:setUVs(moneyOverlayUVs[self.moneyUnit])
        local money = "0"
        if g_localPlayer ~= nil then
            local farm = g_farmManager:getFarmById(g_localPlayer.farmId)
            local value = farm.money
            if value >= 100000000 then
                local textX = math.min(value / 1000000, 999999)
                money = g_i18n:formatNumber(textX, 2, true) .. " M"
            else
                money = g_i18n:formatMoney(farm.money, 0, false, true)
            end
        end
        local farm, value = moneyElement:getPosition()
        local textX = farm + moneyOffsetX * self.uiScale
        local textY = value + moneyOffsetY * self.uiScale
        GameInfoDisplayMobile.drawText(textX, textY, textSize * self.uiScale, true, RenderText.ALIGN_RIGHT, colorWhite, money)
    end)
end
function GameInfoDisplayMobile:createFuelFitnessElement()
    local sizeX, sizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.FUEL))
    self.fuelOffsetX = sizeX
    self.fuelOffsetY = sizeY
    local sizeX, sizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.FUEL))
    local posX = self.moneyElement:getPosition() + self.moneyElement.totalSize + self.fuelOffsetX
    local posY = 1 + self.fuelOffsetY - sizeY
    self.fuelFitnessElement = self:createBackgroundElements(posX, posY, sizeX)
    local fuelOverlayUVs = {}
    for i, uvs in pairs(GameInfoDisplayMobile.UV.FUEL_ICON) do
        fuelOverlayUVs[i] = GuiUtils.getUVs(uvs)
    end
    local iconSizeX, iconSizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.FUEL_ICON))
    local uvs = GameInfoDisplayMobile.POSITION.FUEL_ICON
    local iconOffsetX, i = getNormalizedScreenValues(unpack(uvs))
    local uvs = Overlay.new(self.controlHudAtlasPath, posX + iconOffsetX, posY + i, iconSizeX, iconSizeY)
    local _, uvs = next(fuelOverlayUVs)
    uvs:setUVs(uvs)
    local fuelElement = HUDElement.new(uvs)
    self.fuelFitnessElement:addChild(fuelElement)
    local fitnessUVs = GuiUtils.getUVs(GameInfoDisplayMobile.UV.HORSE)
    local _, textSize = getNormalizedScreenValues(0, GameInfoDisplayMobile.SIZE.FUEL_TEXT)
    local fuelOffsetX = getNormalizedScreenValues
    local colorWhite = GameInfoDisplayMobile.POSITION.FUEL_TEXT
    local fuelOffsetX, fuelOffsetY = fuelOffsetX(unpack(colorWhite))
    local colorWhite = {
        1,
        1,
        1,
        1
    }
    table.insert(self.textElements, function()
        -- upvalues: (copy) self, (copy) fuelOffsetX, (copy) fuelOffsetY, (copy) colorWhite, (copy) textSize, (copy) fuelElement, (copy) fitnessUVs, (copy) fuelOverlayUVs
        local x, y = self.fuelFitnessElement:getPosition()
        if self.vehicle ~= nil then
            if self.isRideable then
                local color = self.vehicle:getCluster():getRidingFactor() * 100
                local dailyRiding = math.floor(color)
                local color = colorWhite
                if dailyRiding <= 5 then
                    color = GameInfoDisplayMobile.COLOR.FUEL_EMPTY
                end
                GameInfoDisplayMobile.drawText(x + fuelOffsetX * self.uiScale, y + fuelOffsetY * self.uiScale, textSize * self.uiScale, true, RenderText.ALIGN_RIGHT, color, string.format("%d%%", dailyRiding))
                fuelElement:setUVs(fitnessUVs)
                return
            end
            if self.vehicle.getConsumerFillUnitIndex ~= nil then
                local horse = self.vehicle:getConsumerFillUnitIndex(FillType.DIESEL) or (self.vehicle:getConsumerFillUnitIndex(FillType.ELECTRICCHARGE) or self.vehicle:getConsumerFillUnitIndex(FillType.METHANE))
                if horse ~= nil then
                    local dailyRiding = g_fillTypeManager:getFillTypeNameByIndex(self.vehicle:getFillUnitFillType(horse))
                    local color = MathUtil.round(self.vehicle:getFillUnitFillLevelPercentage(horse) * 100)
                    local color = colorWhite
                    if color <= 5 then
                        color = GameInfoDisplayMobile.COLOR.FUEL_EMPTY
                    end
                    GameInfoDisplayMobile.drawText(textX, textY, textSize * self.uiScale, true, RenderText.ALIGN_RIGHT, color, string.format("%d%%", color))
                    fuelElement:setUVs(fuelOverlayUVs[dailyRiding])
                end
            end
        end
    end)
end
function GameInfoDisplayMobile.drawText(posX, posY, textSize, textBold, textAlign, color, text)
    setTextColor(color[1], color[2], color[3], color[4])
    setTextBold(textBold)
    setTextAlignment(textAlign)
    renderText(posX, posY, textSize, text)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    setTextColor(1, 1, 1, 1)
end
function GameInfoDisplayMobile.drawTextElement(_, textElement)
    textElement.updateFunc()
    local color = textElement.color
    setTextColor(color[1], color[2], color[3], color[4])
    setTextBold(textElement.textBold)
    setTextAlignment(textElement.textAlign)
    renderText(textElement.posX, textElement.posY, textElement.textSize, textElement.text)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    setTextColor(1, 1, 1, 1)
end
function GameInfoDisplayMobile:onOpenShop()
    if not g_sleepManager:getIsSleeping() then
        g_currentMission:onToggleStore()
    end
end
function GameInfoDisplayMobile:onOpenMap()
    if not g_sleepManager:getIsSleeping() then
        g_currentMission:onToggleMap()
    end
end
function GameInfoDisplayMobile:onOpenMenu()
    if not g_sleepManager:getIsSleeping() then
        g_currentMission:onToggleMenu()
    end
end
function GameInfoDisplayMobile:onOpenHelp()
    if not g_sleepManager:getIsSleeping() then
        g_currentMission:onToggleHelp()
    end
end
function GameInfoDisplayMobile:setMoneyUnit(moneyUnit)
    if moneyUnit ~= GS_MONEY_EURO and (moneyUnit ~= GS_MONEY_POUND and moneyUnit ~= GS_MONEY_DOLLAR) then
        moneyUnit = GS_MONEY_DOLLAR
    end
    self.moneyUnit = moneyUnit
end
function GameInfoDisplayMobile:setMissionInfo(missionInfo)
    self.missionInfo = missionInfo
end
function GameInfoDisplayMobile:setEnvironment(environment)
    self.environment = environment
end
function GameInfoDisplayMobile:setMoneyVisible(isVisible) end
function GameInfoDisplayMobile:setTimeVisible(isVisible) end
function GameInfoDisplayMobile:setTemperatureVisible(isVisible) end
function GameInfoDisplayMobile:setWeatherVisible(isVisible) end
function GameInfoDisplayMobile:setDateVisible(isVisible) end
function GameInfoDisplayMobile:setTutorialVisible(isVisible) end
function GameInfoDisplayMobile:setTutorialProgress(progress) end
function GameInfoDisplayMobile:setHelpHighlighted(isHighlighted)
    self.isHelpHighlighted = isHighlighted
end
function GameInfoDisplayMobile:delete()
    g_messageCenter:unsubscribe(MessageType.INSETS_CHANGED, self)
    GameInfoDisplayMobile:superClass().delete(self)
end
function GameInfoDisplayMobile:update(_)
    self:updateButtons()
    local x, y, z = getWorldTranslation(g_cameraManager:getActiveCamera())
    local isHelpAvailable = g_helpLineManager:getIsContextBasedHelpAvailable(x, y, z)
    self.helpHighlightElement:setVisible(self.helpButtonActive and isHelpAvailable)
end
function GameInfoDisplayMobile:draw()
    for _, drawFuncs in ipairs(self.textElements) do
        drawFuncs()
    end
    GameInfoDisplayMobile:superClass().draw(self)
end
function GameInfoDisplayMobile:updateButtons()
    local shopButtonWasActive = self.shopButtonActive
    local helpButtonWasActive = self.helpButtonActive
    local mapButtonWasActive = self.mapButtonActive
    local menuButtonWasActive = self.menuButtonActive
    g_gui:getIsGuiVisible()
end
function GameInfoDisplayMobile:setScale(uiScale)
    GameInfoDisplayMobile:superClass().setScale(self, uiScale, uiScale)
    local currentVisibility = self:getVisible()
    self:setVisible(true, false)
    self.uiScale = uiScale
    local posX, posY, width, height = GameInfoDisplayMobile.getBackgroundPositionAndSize(uiScale)
    self:setPosition(posX, posY)
    self:setDimension(width, height)
    self:storeOriginalPosition()
    self:setVisible(currentVisibility, false)
    local refPosX = posX + width
    local refPosY = posY + height
    self:updateButtonPosition(self.shopButton, refPosX, refPosY)
    self:updateButtonPosition(self.menuButton, refPosX, refPosY)
    self:updateButtonPosition(self.mapButton, refPosX, refPosY)
    self:updateButtonPosition(self.helpButton, refPosX, refPosY)
    local buttonHighlight = self.helpHighlightElement
    buttonHighlight:setPosition(refPosX + buttonHighlight.offsetX * self.uiScale, nil)
end
function GameInfoDisplayMobile:updateInsets()
    self:setScale(self.uiScale)
end
function GameInfoDisplayMobile.getBackgroundPositionAndSize(scale)
    local offX, offY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.BACKGROUND))
    local _, sizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.BACKGROUND))
    local leftInset, rightInset, _, _ = getSafeFrameInsets()
    local sizeX = math.max(leftInset, offX * scale)
    local sizeX = math.max(rightInset, offX)
    return 1 - sizeX - sizeX, 1 + offY * scale - sizeY * scale, sizeX, sizeY
end
function GameInfoDisplayMobile.createBackground()
    local posX, posY, width, height = GameInfoDisplayMobile.getBackgroundPositionAndSize(1)
    return Overlay.new(nil, posX, posY, width, height)
end
GameInfoDisplayMobile.SIZE = {
    ["BACKGROUND"] = { 1251, 106 },
    ["BUTTON"] = { 106, 106 },
    ["BUTTON_HIGHLIGHT"] = { 114, 114 },
    ["ICON"] = { 84, 84 },
    ["BG_LEFT"] = { 38, 75 },
    ["BG_RIGHT"] = { 38, 75 },
    ["BG_MIDDLE"] = { 34, 75 },
    ["WEATHER"] = { 493, 75 },
    ["WEATHER_SEPARATOR"] = { 2, 65 },
    ["MONTH_TEXT"] = 54,
    ["SEASON_ICON"] = { 65, 65 },
    ["TIME_ICON"] = { 75, 75 },
    ["TIME_TEXT"] = 54,
    ["MONEY"] = { 390, 75 },
    ["MONEY_ICON"] = { 75, 75 },
    ["MONEY_TEXT"] = 54,
    ["FUEL"] = { 262, 75 },
    ["FUEL_ICON"] = { 75, 75 },
    ["FUEL_TEXT"] = 54
}
GameInfoDisplayMobile.POSITION = {
    ["BG_LEFT"] = { 38, 75 },
    ["BG_RIGHT"] = { 38, 75 },
    ["BG_MIDDLE"] = { 34, 75 },
    ["BUTTON_OFFSET"] = { -25, -35 },
    ["MENU"] = { -25, -35 },
    ["SHOP"] = { -25, -35 },
    ["MAP"] = { -25, -35 },
    ["HELP"] = { -25, -35 },
    ["BUTTON_HIGHLIGHT"] = { -4, -4 },
    ["WEATHER"] = { 0, -35 },
    ["WEATHER_SEPARATOR"] = { 232, 5 },
    ["SEASON_ICON"] = { 10, 5 },
    ["MONTH_TEXT"] = { 93, 18 },
    ["TIME_ICON"] = { 246, 0 },
    ["TIME_TEXT"] = { 400, 18 },
    ["TIME_TEXT_OFFSET"] = { 5, 0 },
    ["MONEY"] = { 15, -35 },
    ["MONEY_ICON"] = { 5, 0 },
    ["MONEY_TEXT"] = { 370, 18 },
    ["FUEL"] = { 15, -35 },
    ["FUEL_ICON"] = { 15, 0 },
    ["FUEL_TEXT"] = { 242, 18 },
    ["BACKGROUND"] = { 55, -1 }
}
local gameInfoDisplay = GameInfoDisplayMobile
gameInfoDisplay.UV = {
    ["BUTTON_NORMAL"] = {
        132,
        908,
        106,
        106
    },
    ["BUTTON_PRESSED"] = {
        238,
        908,
        106,
        106
    },
    ["BUTTON_DISABLED"] = {
        344,
        908,
        106,
        106
    },
    ["BUTTON_HIGHLIGHT"] = {
        801,
        904,
        114,
        114
    },
    ["SHOP"] = {
        576,
        96,
        96,
        96
    },
    ["MENU"] = {
        864,
        0,
        96,
        96
    },
    ["MAP"] = {
        480,
        96,
        96,
        96
    },
    ["HELP"] = {
        0,
        288,
        96,
        96
    },
    ["BG_LEFT"] = {
        454,
        928,
        38,
        75
    },
    ["BG_RIGHT"] = {
        526,
        928,
        38,
        75
    },
    ["BG_MIDDLE"] = {
        498,
        928,
        34,
        75
    },
    ["SEASON_ICON"] = {
        [Season.SPRING] = {
            960,
            48,
            48,
            48
        },
        [Season.SUMMER] = {
            960,
            96,
            48,
            48
        },
        [Season.AUTUMN] = {
            960,
            144,
            48,
            48
        },
        [Season.WINTER] = {
            960,
            0,
            48,
            48
        }
    },
    ["TIME"] = {
        384,
        192,
        96,
        96
    },
    ["MONEY_ICON"] = {
        [GS_MONEY_DOLLAR] = {
            480,
            192,
            96,
            96
        },
        [GS_MONEY_POUND] = {
            576,
            192,
            96,
            96
        },
        [GS_MONEY_EURO] = {
            672,
            192,
            96,
            96
        }
    },
    ["FUEL_ICON"] = {
        ["DIESEL"] = {
            288,
            192,
            96,
            96
        },
        ["ELECTRICCHARGE"] = {
            768,
            192,
            96,
            96
        },
        ["METHANE"] = {
            864,
            192,
            96,
            96
        }
    },
    ["HORSE"] = {
        192,
        192,
        96,
        96
    }
}
GameInfoDisplayMobile.COLOR = {
    ["BACKGROUND"] = {
        1,
        1,
        1,
        0.5
    },
    ["SEPARATOR"] = {
        1,
        1,
        1,
        0.5
    },
    ["FUEL_EMPTY"] = {
        0.5029,
        0.0152,
        0.0152,
        1
    }
}
if data ~= nil then
    local gameInfoDisplay = GameInfoDisplayMobile.new(data.hud, data.hudAtlasPath, data.moneyUnit, data.controlHudAtlasPath)
    gameInfoDisplay:setVehicle(data.vehicle)
    gameInfoDisplay:setScale(data.uiScale)
    gameInfoDisplay:setMoneyUnit(data.moneyUnit)
    gameInfoDisplay:setMissionInfo(data.missionInfo)
    gameInfoDisplay:setEnvironment(data.environment)
    for k, elem in ipairs(g_currentMission.hud.displayComponents) do
        if elem == g_currentMission.hud.gameInfoDisplay then
            g_currentMission.hud.displayComponents[k] = gameInfoDisplay
            break
        end
    end
    g_currentMission.hud.gameInfoDisplay = gameInfoDisplay
    Logging.info("Reloaded")
end