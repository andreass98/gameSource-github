VariableWorkWidthHUDExtension = {}
local VariableWorkWidthHUDExtension_mt = Class(VariableWorkWidthHUDExtension)
function VariableWorkWidthHUDExtension.new(vehicle, customMt)
    -- upvalues: (copy) VariableWorkWidthHUDExtension_mt
    local self = setmetatable({}, customMt or VariableWorkWidthHUDExtension_mt)
    self.priority = GS_PRIO_HIGH
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.background = g_overlayManager:createOverlay("gui.shortcutBox2", 0, 0, 0, 0)
    self.background:setColor(r, g, b, a)
    self.bar = ThreePartOverlay.new()
    self.bar:setLeftPart("gui.progressbar_left", 0, 0)
    self.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
    self.bar:setRightPart("gui.progressbar_right", 0, 0)
    self.separator = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
    self.separator:setColor(1, 1, 1, 0.25)
    self.title = utf8ToUpper(g_i18n:getText("info_partialWorkingWidth"))
    self.vehicle = vehicle
    self.variableWorkWidth = vehicle.spec_variableWorkWidth
    self.numSections = #self.variableWorkWidth.sections
    self:storeScaledValues()
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)
    return self
end
function VariableWorkWidthHUDExtension:delete()
    self.background:delete()
    self.bar:delete()
    self.separator:delete()
    g_messageCenter:unsubscribeAll(self)
end
function VariableWorkWidthHUDExtension:storeScaledValues()
    local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
    local width, height = getNormalizedScreenValues(330 * uiScale, 50 * uiScale)
    self.background:setDimension(width, height)
    local barPartWidth, barPartHeight = getNormalizedScreenValues(14 * uiScale, 27 * uiScale)
    self.titleOffsetX = barPartWidth
    self.titleOffsetY = barPartHeight
    local barPartWidth, barPartHeight = getNormalizedScreenValues(316 * uiScale, 27 * uiScale)
    self.textOffsetX = barPartWidth
    self.textOffsetY = barPartHeight
    local barPartWidth, barPartHeight = getNormalizedScreenValues(0, 12 * uiScale)
    self.textSize = barPartHeight
    local barPartWidth, barPartHeight = getNormalizedScreenValues(14 * uiScale, 11 * uiScale)
    self.barOffsetX = barPartWidth
    self.barOffsetY = barPartHeight
    self.barSpacingX = getNormalizedScreenValues(5 * uiScale, 0)
    local barPartWidth, barPartHeight = getNormalizedScreenValues(3, 6)
    local barMaxWidth, _ = getNormalizedScreenValues(302 * uiScale, 0)
    self.singleBarWidth = (barMaxWidth - self.barSpacingX * (self.numSections - 1)) / self.numSections
    self.bar:setLeftPart(nil, barPartWidth, barPartHeight)
    self.bar:setMiddlePart(nil, self.singleBarWidth - 2 * barPartWidth, barPartHeight)
    self.bar:setRightPart(nil, barPartWidth, barPartHeight)
    local _, seperatorHeight = getNormalizedScreenValues(0, 15 * uiScale)
    self.separatorOffsetX, self.separatorOffsetY = getNormalizedScreenValues(2 * uiScale, 6 * uiScale)
    self.separator:setDimension(g_pixelSizeX, seperatorHeight)
end
function VariableWorkWidthHUDExtension:draw(_, posX, posY)
    posY = posY - self.background.height
    self.background:setPosition(posX, posY)
    self.background:render()
    setTextBold(true)
    setTextColor(1, 1, 1, 1)
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(posX + self.titleOffsetX, posY + self.titleOffsetY, self.textSize, self.title)
    setTextBold(false)
    local usage = self.vehicle:getVariableWorkWidthUsage()
    local barPosX
    if usage == nil then
        barPosX = string.format(g_i18n:getText("info_workWidth"), self.vehicle:getWorkAreaWidth(self.variableWorkWidth.widthReferenceWorkArea))
    else
        local barPosX = MathUtil.round(usage)
        barPosX = string.format(g_i18n:getText("info_workWidthAndUsage"), barPosX, self.vehicle:getWorkAreaWidth(self.variableWorkWidth.widthReferenceWorkArea))
    end
    setTextAlignment(RenderText.ALIGN_RIGHT)
    renderText(posX + self.textOffsetX, posY + self.textOffsetY, self.textSize, barPosX)
    setTextAlignment(RenderText.ALIGN_LEFT)
    local barPosX = posX + self.barOffsetX
    local i = 1
    for i = i, self.numSections do
        local section = self.variableWorkWidth.sections[i]
        self.bar:setColor(HUD.COLOR.ACTIVE[1], HUD.COLOR.ACTIVE[2], HUD.COLOR.ACTIVE[3], HUD.COLOR.ACTIVE[4] * (not section.isActive and 0.25 or 1))
        self.bar:setPosition(barPosX, posY + self.barOffsetY)
        self.bar:render()
        if section.isCenter then
            local separatorPosY = posY + self.separatorOffsetY
            self.separator:setPosition(barPosX - self.separatorOffsetX - self.separator.width, separatorPosY)
            self.separator:render()
            self.separator:setPosition(barPosX + self.singleBarWidth + self.separatorOffsetX, separatorPosY)
            self.separator:render()
        end
        barPosX = barPosX + self.singleBarWidth + self.barSpacingX
    end
    return posY
end
function VariableWorkWidthHUDExtension:getHeight()
    return self.background.height
end