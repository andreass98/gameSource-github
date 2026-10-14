MixerWagonHUDExtension = {}
local MixerWagonHUDExtension_mt = Class(MixerWagonHUDExtension)
function MixerWagonHUDExtension.new(vehicle, customMt)
    -- upvalues: (copy) MixerWagonHUDExtension_mt
    local self = setmetatable({}, customMt or MixerWagonHUDExtension_mt)
    self.priority = GS_PRIO_HIGH
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.backgroundTop = g_overlayManager:createOverlay("gui.hudExtension_top", 0, 0, 0, 0)
    self.backgroundTop:setColor(r, g, b, a)
    self.backgroundScale = g_overlayManager:createOverlay("gui.hudExtension_middle", 0, 0, 0, 0)
    self.backgroundScale:setColor(r, g, b, a)
    self.backgroundBottom = g_overlayManager:createOverlay("gui.hudExtension_bottom", 0, 0, 0, 0)
    self.backgroundBottom:setColor(r, g, b, a)
    self.bar = ThreePartOverlay.new()
    self.bar:setLeftPart("gui.progressbar_left", 0, 0)
    self.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
    self.bar:setRightPart("gui.progressbar_right", 0, 0)
    self.marker = g_overlayManager:createOverlay("gui.tmr_marker", 0, 0, 0, 0)
    self.vehicle = vehicle
    self.mixerWagon = vehicle.spec_mixerWagon
    self.numFillTypes = #self.mixerWagon.mixerWagonFillTypes
    self.fillTypeStatus = {}
    for _, mixerWagonFillType in ipairs(self.mixerWagon.mixerWagonFillTypes) do
        local firstFilltype = next(mixerWagonFillType.fillTypes)
        local fillType = g_fillTypeManager:getFillTypeByIndex(firstFilltype)
        if fillType ~= nil then
            local status = {
                ["icon"] = Overlay.new(fillType.hudOverlayFilename, 0, 0, 0, 0),
                ["fillLevel"] = 0,
                ["minPercentage"] = mixerWagonFillType.minPercentage,
                ["maxPercentage"] = mixerWagonFillType.maxPercentage
            }
            table.insert(self.fillTypeStatus, status)
        end
    end
    self.badMixColor = {
        0.8069,
        0.0097,
        0.0097,
        1
    }
    self.title = utf8ToUpper(string.format("%s - %s", g_i18n:getText("info_mixingRatio"), vehicle:getFullName()))
    self:storeScaledValues()
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)
    return self
end
function MixerWagonHUDExtension:delete()
    self.backgroundTop:delete()
    self.backgroundScale:delete()
    self.backgroundBottom:delete()
    self.marker:delete()
    self.bar:delete()
    for _, status in ipairs(self.fillTypeStatus) do
        status.icon:delete()
    end
    g_messageCenter:unsubscribeAll(self)
end
function MixerWagonHUDExtension:storeScaledValues()
    local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
    local width, height = getNormalizedScreenValues(0, 26 * uiScale)
    self.offsetTop = height
    local width, height = getNormalizedScreenValues(0, 8 * uiScale)
    self.offsetBottom = height
    local width, height = getNormalizedScreenValues(0, 24 * uiScale)
    self.heightPerFillType = height
    self.totalHeight = self.heightPerFillType * self.numFillTypes + self.offsetTop + self.offsetBottom
    local width, height = getNormalizedScreenValues(330 * uiScale, 6 * uiScale)
    self.backgroundTop:setDimension(width, height)
    self.backgroundBottom:setDimension(width, height)
    self.backgroundScale:setDimension(width, self.totalHeight - 2 * height)
    local barPartWidth, barPartHeight = getNormalizedScreenValues(14 * uiScale, -19 * uiScale)
    self.titleOffsetX = barPartWidth
    self.titleOffsetY = barPartHeight
    local barPartWidth, barPartHeight = getNormalizedScreenValues(0, 12 * uiScale)
    self.titleSize = barPartHeight
    local barPartWidth, barPartHeight = getNormalizedScreenValues(45 * uiScale, 10 * uiScale)
    self.barOffsetX = barPartWidth
    self.barOffsetY = barPartHeight
    local barPartWidth, barPartHeight = getNormalizedScreenValues(3, 6)
    local iconWidth, iconHeight = getNormalizedScreenValues(235 * uiScale, 0)
    self.barMaxWidth = iconWidth
    self.barPartsWidth = 2 * barPartWidth
    self.barPartHeight = barPartHeight
    self.middlePartMaxWidth = self.barMaxWidth - self.barPartsWidth
    self.bar:setLeftPart(nil, barPartWidth, barPartHeight)
    self.bar:setMiddlePart(nil, self.middlePartMaxWidth, barPartHeight)
    self.bar:setRightPart(nil, barPartWidth, barPartHeight)
    local iconWidth, iconHeight = getNormalizedScreenValues(25 * uiScale, 25 * uiScale)
    for _, status in ipairs(self.fillTypeStatus) do
        status.icon:setDimension(iconWidth, iconHeight)
    end
    local markerWidth, markerHeight = getNormalizedScreenValues(11 * uiScale, 2 * uiScale)
    self.iconOffsetX = markerWidth
    self.iconOffsetY = markerHeight
    local markerWidth, markerHeight = getNormalizedScreenValues(-5 * uiScale, 8 * uiScale)
    self.textOffsetX = markerWidth
    self.textOffsetY = markerHeight
    local markerWidth, markerHeight = getNormalizedScreenValues(0, 12 * uiScale)
    self.textSize = markerHeight
    local markerWidth, markerHeight = getNormalizedScreenValues(11 * uiScale, 11 * uiScale)
    self.marker:setDimension(markerWidth, markerHeight)
end
function MixerWagonHUDExtension:draw(_, posX, posY)
    self.backgroundTop:setPosition(posX, posY - self.backgroundTop.height)
    self.backgroundScale:setPosition(posX, self.backgroundTop.y - self.backgroundScale.height)
    self.backgroundBottom:setPosition(posX, self.backgroundScale.y - self.backgroundBottom.height)
    self.backgroundTop:render()
    self.backgroundScale:render()
    self.backgroundBottom:render()
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    local title = Utils.limitTextToWidth(self.title, self.titleSize, self.backgroundTop.width - 2 * self.titleOffsetX, false, "...")
    renderText(posX + self.titleOffsetX, posY + self.titleOffsetY, self.titleSize, title)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    local totalFillLevel = 0
    if self.vehicle:getFillUnitFillLevel(self.mixerWagon.fillUnitIndex) > 0 then
        for i, mixerWagonFillType in ipairs(self.mixerWagon.mixerWagonFillTypes) do
            self.fillTypeStatus[i].fillLevel = mixerWagonFillType.fillLevel
        end
    end
    local fillTypePosY = posY - self.offsetTop
    local fillTypeTextPosX = posX + self.backgroundTop.width + self.textOffsetX
    for _, status in ipairs(self.fillTypeStatus) do
        fillTypePosY = fillTypePosY - self.heightPerFillType
        local icon = status.icon
        icon:setPosition(posX + self.iconOffsetX, fillTypePosY + self.iconOffsetY)
        icon:render()
        self.bar:setMiddlePart(nil, self.middlePartMaxWidth, nil)
        self.bar:setColor(HUD.COLOR.BACKGROUND_DARK[1], HUD.COLOR.BACKGROUND_DARK[2], HUD.COLOR.BACKGROUND_DARK[3], HUD.COLOR.BACKGROUND_DARK[4])
        self.bar:setPosition(posX + self.barOffsetX, fillTypePosY + self.barOffsetY)
        self.bar:render()
        local percentage = 0
        if self.vehicle:getFillUnitFillLevel(self.mixerWagon.fillUnitIndex) > 0 then
            percentage = status.fillLevel / totalFillLevel
        end
        local color
        if status.fillLevel > 0 and (self.vehicle:getFillUnitFillType(self.mixerWagon.fillUnitIndex) ~= FillType.FORAGE_MIXING or status.minPercentage <= percentage and percentage <= status.maxPercentage) then
            color = HUD.COLOR.ACTIVE
        else
            color = self.badMixColor
        end
        self.bar:setColor(color[1], color[2], color[3], color[4])
        self.bar:setMiddlePart(nil, self.barMaxWidth * (status.maxPercentage - status.minPercentage) - self.barPartsWidth, nil)
        self.bar:setPosition(posX + self.barOffsetX + self.barMaxWidth * status.minPercentage, nil)
        self.bar:render()
        self.marker:setPosition(posX + self.barOffsetX + self.barMaxWidth * percentage - self.marker.width * 0.5, self.bar.y - (self.marker.height - self.barPartHeight) * 0.5)
        self.marker:render()
        local text = string.format("%d%%", percentage * 100)
        renderText(fillTypeTextPosX, fillTypePosY + self.textOffsetY, self.textSize, text)
    end
    setTextBold(false)
    return self.backgroundBottom.y
end
function MixerWagonHUDExtension:getHeight()
    return self.totalHeight
end