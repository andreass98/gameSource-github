BaleCounterHUDExtension = {}
local BaleCounterHUDExtension_mt = Class(BaleCounterHUDExtension)
function BaleCounterHUDExtension.new(vehicle, customMt)
    -- upvalues: (copy) BaleCounterHUDExtension_mt
    local self = setmetatable({}, customMt or BaleCounterHUDExtension_mt)
    self.priority = GS_PRIO_NORMAL
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.background = g_overlayManager:createOverlay("gui.shortcutBox1", 0, 0, 0, 0)
    self.background:setColor(r, g, b, a)
    self.sessionOverlay = g_overlayManager:createOverlay("gui.baleCount_session", 0, 0, 0, 0)
    self.sessionOverlay:setColor(1, 1, 1, 1)
    self.lifetimeOverlay = g_overlayManager:createOverlay("gui.baleCount_lifetime", 0, 0, 0, 0)
    self.lifetimeOverlay:setColor(1, 1, 1, 1)
    self.title = utf8ToUpper(g_i18n:getText("info_baleCounter"))
    self.vehicle = vehicle
    self:storeScaledValues()
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)
    return self
end
function BaleCounterHUDExtension:delete()
    self.background:delete()
    self.sessionOverlay:delete()
    self.lifetimeOverlay:delete()
    g_messageCenter:unsubscribeAll(self)
end
function BaleCounterHUDExtension:storeScaledValues()
    local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
    local width, height = getNormalizedScreenValues(330 * uiScale, 25 * uiScale)
    self.background:setDimension(width, height)
    local iconWidth, iconHeight = getNormalizedScreenValues(20 * uiScale, 20 * uiScale)
    self.sessionOverlay:setDimension(iconWidth, iconHeight)
    self.lifetimeOverlay:setDimension(iconWidth, iconHeight)
    self.textOffsetX, self.textOffsetY = getNormalizedScreenValues(14 * uiScale, 8 * uiScale)
    _, self.textSize = getNormalizedScreenValues(0, 12 * uiScale)
    self.sessionIconOffsetX, self.sessionIconOffsetY = getNormalizedScreenValues(210 * uiScale, 3 * uiScale)
    self.lifetimeIconOffsetX, self.lifetimeIconOffsetY = getNormalizedScreenValues(270 * uiScale, 4 * uiScale)
    self.sessionTextOffsetX, self.sessionTextOffsetY = getNormalizedScreenValues(235 * uiScale, 8 * uiScale)
    self.lifetimeTextOffsetX, self.lifetimeTextOffsetY = getNormalizedScreenValues(295 * uiScale, 8 * uiScale)
end
function BaleCounterHUDExtension:draw(_, posX, posY)
    posY = posY - self.background.height
    self.background:setPosition(posX, posY)
    self.background:render()
    setTextBold(true)
    setTextColor(1, 1, 1, 1)
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(posX + self.textOffsetX, posY + self.textOffsetY, self.textSize, self.title)
    setTextBold(false)
    local spec = self.vehicle.spec_baleCounter
    local sessionOverlay = self.sessionOverlay
    sessionOverlay:setPosition(posX + self.sessionIconOffsetX, posY + self.sessionIconOffsetY)
    sessionOverlay:render()
    renderText(posX + self.sessionTextOffsetX, posY + self.sessionTextOffsetY, self.textSize, string.format("%d", spec.sessionCounter))
    local lifetimeOverlay = self.lifetimeOverlay
    lifetimeOverlay:setPosition(posX + self.lifetimeIconOffsetX, posY + self.lifetimeIconOffsetY)
    lifetimeOverlay:render()
    renderText(posX + self.lifetimeTextOffsetX, posY + self.lifetimeTextOffsetY, self.textSize, string.format("%d", spec.lifetimeCounter))
    return posY
end
function BaleCounterHUDExtension:getHeight()
    return self.background.height
end