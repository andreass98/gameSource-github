local data = nil
if FillLevelsDisplay ~= nil then
    local old = g_currentMission.hud.fillLevelsDisplay
    data = {
        ["vehicle"] = old.vehicle,
        ["uiScale"] = old.uiScale,
        ["isVisible"] = old:getVisible()
    }
    old:delete()
end
FillLevelsDisplay = {}
FillLevelsDisplay.TYPE_BAR = 1
FillLevelsDisplay.TYPE_STEP = 2
FillLevelsDisplay.MAX_BOXES = 5
FillLevelsDisplay.MAX_NUM_STEPS = 25
local old = Class(FillLevelsDisplay, HUDDisplay)
function FillLevelsDisplay.new()
    -- upvalues: (copy) old
    local self = FillLevelsDisplay:superClass().new(old)
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.bgScale = g_overlayManager:createOverlay("gui.filltypes_middle", 0, 0, 0, 0)
    self.bgScale:setColor(r, g, b, a)
    self.bgLeft = g_overlayManager:createOverlay("gui.filltypes_left", 0, 0, 0, 0)
    self.bgLeft:setColor(r, g, b, a)
    self.bgRight = g_overlayManager:createOverlay("gui.filltypes_right", 0, 0, 0, 0)
    self.bgRight:setColor(r, g, b, a)
    self.maxWeightIcon = g_overlayManager:createOverlay("gui.vehicleOverview_maxWeight", 0, 0, 0, 0)
    self.bar = ThreePartOverlay.new()
    self.bar:setLeftPart("gui.progressbar_left", 0, 0)
    self.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
    self.bar:setRightPart("gui.progressbar_right", 0, 0)
    self.vehicle = nil
    self.fillTypeIcons = {}
    self.fillLevelData = {}
    return self
end
function FillLevelsDisplay:delete()
    self.bgLeft:delete()
    self.bgRight:delete()
    self.bgScale:delete()
    self.maxWeightIcon:delete()
    self.bar:delete()
    for _, icon in pairs(self.fillTypeIcons) do
        icon:delete()
    end
end
function FillLevelsDisplay:storeScaledValues()
    local posX, posY = self:scalePixelValuesToScreenVector(0, 236)
    self.offsetX = posX
    self.offsetY = posY
    local posX = g_hudAnchorRight
    local posY = g_hudAnchorBottom
    self:setPosition(posX, posY)
    local bgLeftWidth, bgHeight = self:scalePixelValuesToScreenVector(12, 45)
    local bgRightWidth = self:scalePixelToScreenWidth(12)
    local bgScaleWidth = self:scalePixelToScreenWidth(290) - bgLeftWidth - bgRightWidth
    self.bgTotalWidth = bgScaleWidth + bgLeftWidth + bgRightWidth
    self.bgLeft:setDimension(bgLeftWidth, bgHeight)
    self.bgRight:setDimension(bgRightWidth, bgHeight)
    self.bgScale:setDimension(bgScaleWidth, bgHeight)
    self.bgRight:setPosition(posX - self.bgRight.width, nil)
    self.bgScale:setPosition(self.bgRight.x - self.bgScale.width, nil)
    self.bgLeft:setPosition(self.bgScale.x - self.bgLeft.width, nil)
    self.boxOffsetY = self:scalePixelToScreenHeight(5)
    self.fillTypeTextSize = self:scalePixelToScreenHeight(14)
    self.fillLevelTextSize = self:scalePixelToScreenHeight(14)
    local barPartWidth, barPartHeight = self:scalePixelValuesToScreenVector(40, 22)
    self.fillTypeTextOffsetX = barPartWidth
    self.fillTypeTextOffsetY = barPartHeight
    local barPartWidth, barPartHeight = self:scalePixelValuesToScreenVector(-12, 22)
    self.fillLevelTextOffsetX = barPartWidth
    self.fillLevelTextOffsetY = barPartHeight
    self.typeLevelOffsetX = self:scalePixelToScreenWidth(5)
    local barPartWidth, barPartHeight = self:scalePixelValuesToScreenVector(3, 6)
    local barTotalWidth, _ = self:scalePixelValuesToScreenVector(237, 0)
    self.barTotalWidth = barTotalWidth
    self.barHeight = barPartHeight
    self.barMinWidth = 2 * barPartWidth
    self.barMaxScaleWidth = barTotalWidth - 2 * barPartWidth
    self.bar:setLeftPart(nil, barPartWidth, barPartHeight)
    self.bar:setMiddlePart(nil, self.barMaxScaleWidth, barPartHeight)
    self.bar:setRightPart(nil, barPartWidth, barPartHeight)
    local weightIconWidth, weightIconHeight = self:scalePixelValuesToScreenVector(40, 9)
    self.barOffsetX = weightIconWidth
    self.barOffsetY = weightIconHeight
    self.barStepOffsetX = self:scalePixelToScreenWidth(3)
    local weightIconWidth, weightIconHeight = self:scalePixelValuesToScreenVector(7, 9)
    self.iconOffsetX = weightIconWidth
    self.iconOffsetY = weightIconHeight
    local weightIconWidth, weightIconHeight = self:scalePixelValuesToScreenVector(27, 27)
    self.iconWidth = weightIconWidth
    self.iconHeight = weightIconHeight
    local weightIconWidth, weightIconHeight = self:scalePixelValuesToScreenVector(50, 17)
    self.maxWeightIcon:setDimension(weightIconWidth, weightIconHeight)
    for _, icon in pairs(self.fillTypeIcons) do
        icon:setDimension(self.iconWidth, self.iconHeight)
    end
    self.helpAnchorPosX = self.bgLeft.x + self:scalePixelToScreenWidth(-15)
    self.helpAnchorPosY = posY + self.bgScale.height * 0.5
end
function FillLevelsDisplay:update(dt)
    FillLevelsDisplay:superClass().update(self, dt)
    if self.vehicle ~= nil then
        self:updateFillLevelData()
    end
end
function FillLevelsDisplay:draw()
    FillLevelsDisplay:superClass().draw(self)
    local posX, posY = self:getPosition()
    if g_currentMission.hud.speedMeter:getVisible() then
    end
    for _, data in ipairs(self.fillLevelData) do
        if data.isValid then
            posY = posY + self:drawFillLevel(posX, posY, data) + self.boxOffsetY
            data.isValid = false
        end
    end
end
function FillLevelsDisplay:drawFillLevel(posX, posY, data)
    self.bgRight:setPosition(nil, posY)
    self.bgLeft:setPosition(nil, posY)
    self.bgScale:setPosition(nil, posY)
    self.bgRight:render()
    self.bgLeft:render()
    self.bgScale:render()
    local icon = self.fillTypeIcons[data.fillType]
    if icon ~= nil then
        icon:setPosition(self.bgLeft.x + self.iconOffsetX, self.bgLeft.y + self.iconOffsetY)
        icon:render()
    end
    if data.typeId == FillLevelsDisplay.TYPE_BAR then
        self.bar:setColor(HUD.COLOR.BACKGROUND_DARK[1], HUD.COLOR.BACKGROUND_DARK[2], HUD.COLOR.BACKGROUND_DARK[3], HUD.COLOR.BACKGROUND_DARK[4])
        self.bar:setMiddlePart(nil, self.barMaxScaleWidth, nil)
        self.bar:setPosition(self.bgLeft.x + self.barOffsetX, self.bgLeft.y + self.barOffsetY)
        self.bar:render()
        local scale = 0
        if data.capacity > 0 then
            scale = data.fillLevel / data.capacity
        end
        if scale > 0 then
            self.bar:setColor(HUD.COLOR.ACTIVE[1], HUD.COLOR.ACTIVE[2], HUD.COLOR.ACTIVE[3], HUD.COLOR.ACTIVE[4])
            self.bar:setMiddlePart(nil, self.barMaxScaleWidth * scale, nil)
            self.bar:setPosition(self.bar.x, self.bar.y)
            self.bar:render()
        end
        setTextColor(1, 1, 1, 1)
        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(posX + self.fillLevelTextOffsetX, self.bgLeft.y + self.fillLevelTextOffsetY, self.fillLevelTextSize, data.fillLevelText)
        local fillTypeText = data.customFillTypeText
        if fillTypeText == nil and data.fillType ~= FillType.UNKNOWN then
            fillTypeText = g_fillTypeManager:getFillTypeTitleByIndex(data.fillType)
        end
        if fillTypeText ~= nil then
            if data.infoText ~= nil then
            end
            local textLength = getTextWidth(self.fillLevelTextSize, data.fillLevelText)
            local maxWidth = self.bgTotalWidth - textLength - self.fillTypeTextOffsetX - math.abs(self.fillLevelTextOffsetX) - self.typeLevelOffsetX
            local text = Utils.limitTextToWidth(fillTypeText, self.fillTypeTextSize, maxWidth, false, "...")
            setTextBold(true)
            setTextAlignment(RenderText.ALIGN_LEFT)
            renderText(self.bgLeft.x + self.fillTypeTextOffsetX, self.bgLeft.y + self.fillTypeTextOffsetY, self.fillTypeTextSize, text)
            setTextBold(false)
        end
    elseif data.typeId == FillLevelsDisplay.TYPE_STEP then
        local fillTypeText = data.capacity
        local scale, fillTypeText = math.modf(fillTypeText)
        local maxWidth = data.fillLevel
        local textLength, maxWidth = math.modf(maxWidth)
        local textLength = textLength + 1
        local barPosX = FillLevelsDisplay.MAX_NUM_STEPS
        local text = math.clamp(scale, 1, barPosX) - 1
        local barScaleWidth = (self.barTotalWidth - self.barStepOffsetX * text - self.barMinWidth * text) / text
        self.bar:setMiddlePart(nil, barScaleWidth, nil)
        local barPosX = self.bgLeft.x + self.barOffsetX
        local i = 1
        local textLength = 1
        for i = i, text, textLength do
            self.bar:setColor(barBgColor[1], barBgColor[2], barBgColor[3], barBgColor[4])
            self.bar:setPosition(barPosX, self.bgLeft.y + self.barOffsetY)
            self.bar:setMiddlePart(nil, barScaleWidth, nil)
            self.bar:render()
            local scale = 0
            local scale
            if i == textLength then
                scale = maxWidth
            end
            if scale > 0 then
                self.bar:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
                self.bar:setMiddlePart(nil, barScaleWidth * scale, nil)
                self.bar:render()
            end
            barPosX = barPosX + self.barMinWidth + barScaleWidth + self.barStepOffsetX
        end
        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(posX + self.fillLevelTextOffsetX, self.bgLeft.y + self.fillLevelTextOffsetY, self.fillLevelTextSize, data.fillLevelText)
        local fillTypeText = data.customFillTypeText
        if fillTypeText == nil and data.fillType ~= FillType.UNKNOWN then
            fillTypeText = g_fillTypeManager:getFillTypeTitleByIndex(data.fillType)
        end
        if fillTypeText ~= nil then
            local textLength = getTextWidth(self.fillLevelTextSize, data.fillLevelText)
            local i = self.bgTotalWidth - textLength - self.fillTypeTextOffsetX - math.abs(self.fillLevelTextOffsetX) - self.typeLevelOffsetX
            local scale = Utils.limitTextToWidth(fillTypeText, self.fillTypeTextSize, i, false, "...")
            setTextBold(true)
            setTextAlignment(RenderText.ALIGN_LEFT)
            renderText(self.bgLeft.x + self.fillTypeTextOffsetX, self.bgLeft.y + self.fillTypeTextOffsetY, self.fillTypeTextSize, scale)
            setTextBold(false)
        end
    end
    if data.maxReached then
        self.maxWeightIcon:setPosition(self.bgLeft.x + self.barOffsetX + self.barTotalWidth * 0.5 - self.maxWeightIcon.width * 0.5, self.bgLeft.y + self.barOffsetY + self.barHeight * 0.5 - self.maxWeightIcon.height * 0.5)
        self.maxWeightIcon:render()
    end
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)
    return self.bgScale.height
end
function FillLevelsDisplay:setVehicle(vehicle)
    self.vehicle = vehicle
end
function FillLevelsDisplay:resetFillTypes()
    for _, v in pairs(self.fillTypeIcons) do
        v:delete()
    end
    table.clear(self.fillTypeIcons)
end
function FillLevelsDisplay:updateFillLevelData()
    self.vehicle:getFillLevelInformation(self)
    for k, data in ipairs(self.fillLevelData) do
        if not data.isValid then
            break
        end
        if data.capacity > 0 or data.fillLevel > 0 then
            if data.typeId == FillLevelsDisplay.TYPE_BAR then
                local value = 0
                if data.capacity > 0 then
                    value = data.fillLevel / data.capacity
                end
                local precision = data.precision or 0
                local formattedNumber
                if precision > 0 then
                    local rounded = MathUtil.round(data.fillLevel, precision)
                    formattedNumber = string.format("%d%s%0" .. precision .. "d", math.floor(rounded), g_i18n.decimalSeparator, (rounded - math.floor(rounded)) * 10 ^ precision)
                else
                    formattedNumber = string.format("%d", MathUtil.round(data.fillLevel))
                end
                local rounded = g_fillTypeManager:getFillTypeByIndex(data.fillType)
                data.fillLevelText = string.format("%s%s (%d%%)", formattedNumber, rounded.unitShort or "", (math.floor(100 * value)))
            elseif data.typeId == FillLevelsDisplay.TYPE_STEP then
                data.fillLevelText = string.format("%d / %d", math.ceil(data.fillLevel), data.capacity)
            end
        end
    end
end
function FillLevelsDisplay:addFillLevel(fillType, fillLevel, capacity, precision, maxReached, typeId, customFillTypeText, infoText)
    local dataItem = typeId or FillLevelsDisplay.TYPE_BAR
    local dataItem = nil
    for k, data in ipairs(self.fillLevelData) do
        if not data.isValid then
            data.capacity = 0
            data.fillLevel = 0
            dataItem = data
            break
        end
        if data.fillType == fillType and (data.typeId == dataItem and data.infoText == infoText) then
            dataItem = data
            break
        end
    end
    if dataItem == nil and #self.fillLevelData < FillLevelsDisplay.MAX_BOXES then
        table.insert(self.fillLevelData, {
            ["fillLevel"] = 0,
            ["capacity"] = 0
        })
    end
    if dataItem ~= nil then
        dataItem.isValid = true
        dataItem.customFillTypeText = customFillTypeText
        dataItem.infoText = infoText
        dataItem.typeId = dataItem
        dataItem.fillType = fillType
        dataItem.fillLevel = dataItem.fillLevel + fillLevel
        dataItem.capacity = dataItem.capacity + capacity
        dataItem.precision = precision
        dataItem.maxReached = maxReached
        if self.fillTypeIcons[fillType] == nil then
            local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillType)
            local iconOverlay = Overlay.new(fillTypeDesc.hudOverlayFilename, 0, 0, self.iconWidth, self.iconHeight)
            self.fillTypeIcons[fillType] = iconOverlay
        end
    end
end
function FillLevelsDisplay:getHelpAnchorPosition()
    local posX = self.helpAnchorPosX
    local posY = self.helpAnchorPosY
    if g_currentMission.hud.speedMeter:getVisible() then
    end
    return posX, posY
end
if data ~= nil then
    local fillLevelsDisplay = FillLevelsDisplay.new()
    fillLevelsDisplay:setScale(data.uiScale)
    fillLevelsDisplay:setVisible(data.isVisible)
    fillLevelsDisplay:setVehicle(data.vehicle)
    g_currentMission.hud.fillLevelsDisplay = fillLevelsDisplay
    g_currentMission.hud.displayComponents.fillLevelsDisplay = fillLevelsDisplay
    Logging.info("Reloaded FillLevelsDisplay")
end