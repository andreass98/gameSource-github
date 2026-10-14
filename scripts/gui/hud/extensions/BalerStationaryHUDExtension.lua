BalerStationaryHUDExtension = {}
local BalerStationaryHUDExtension_mt = Class(BalerStationaryHUDExtension)
function BalerStationaryHUDExtension.new(vehicle, customMt)
    -- upvalues: (copy) BalerStationaryHUDExtension_mt
    local self = setmetatable({}, customMt or BalerStationaryHUDExtension_mt)
    self.priority = GS_PRIO_HIGH
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.backgroundTop = g_overlayManager:createOverlay("gui.hudExtension_top", 0, 0, 0, 0)
    self.backgroundTop:setColor(r, g, b, a)
    self.backgroundScale = g_overlayManager:createOverlay("gui.hudExtension_middle", 0, 0, 0, 0)
    self.backgroundScale:setColor(r, g, b, a)
    self.backgroundBottom = g_overlayManager:createOverlay("gui.hudExtension_bottom", 0, 0, 0, 0)
    self.backgroundBottom:setColor(r, g, b, a)
    self.vehicleIcon = g_overlayManager:createOverlay("gui.icon_goeweil", 0, 0, 0, 0)
    self.baleIcon = g_overlayManager:createOverlay("gui.icon_goeweil_bale", 0, 0, 0, 0)
    self.grassIcon = g_overlayManager:createOverlay("gui.icon_goeweil_grass", 0, 0, 0, 0)
    self.wrappedBaleIcon = g_overlayManager:createOverlay("gui.icon_goeweil_wrappedBale", 0, 0, 0, 0)
    self.vehicle = vehicle
    self.baler = vehicle.spec_baler
    self.baleWrapper = vehicle.spec_baleWrapper
    self:storeScaledValues()
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)
    return self
end
function BalerStationaryHUDExtension:delete()
    self.backgroundTop:delete()
    self.backgroundScale:delete()
    self.backgroundBottom:delete()
    self.vehicleIcon:delete()
    self.baleIcon:delete()
    self.grassIcon:delete()
    self.wrappedBaleIcon:delete()
    g_messageCenter:unsubscribeAll(self)
end
function BalerStationaryHUDExtension:storeScaledValues()
    local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
    local width, height = getNormalizedScreenValues(0, 115 * uiScale)
    self.totalHeight = height
    local width, height = getNormalizedScreenValues(330 * uiScale, 6 * uiScale)
    self.backgroundTop:setDimension(width, height)
    self.backgroundBottom:setDimension(width, height)
    self.backgroundScale:setDimension(width, self.totalHeight - 2 * height)
    local width, height = getNormalizedScreenValues(250 * uiScale, 95 * uiScale)
    self.vehicleIcon:setDimension(width, height)
    local width, height = getNormalizedScreenValues(38 * uiScale, 38 * uiScale)
    self.baleIcon.defaultWidth = width
    self.baleIcon.defaultHeight = height
    self.baleIcon:setDimension(width, height)
    local width, height = getNormalizedScreenValues(55 * uiScale, 30 * uiScale)
    self.grassIcon.defaultWidth = width
    self.grassIcon.defaultHeight = height
    self.grassIcon:setDimension(width, height)
    local width, height = getNormalizedScreenValues(38 * uiScale, 38 * uiScale)
    self.wrappedBaleIcon:setDimension(width, height)
    self.vehicleIconOffsetX, self.vehicleIconOffsetY = getNormalizedScreenValues(26 * uiScale, 10 * uiScale)
    self.wrappedBaleIconOffsetX, self.wrappedBaleIconOffsetY = getNormalizedScreenValues(44 * uiScale, 45 * uiScale)
    self.baleIconOffsetX, self.baleIconOffsetY = getNormalizedScreenValues(133 * uiScale, 69 * uiScale)
    self.grassIconOffsetX, self.grassIconOffsetY = getNormalizedScreenValues(232 * uiScale, 50 * uiScale)
    _, self.textSize = getNormalizedScreenValues(0, 12 * uiScale)
    self.baleTextOffsetX, self.baleTextOffsetY = getNormalizedScreenValues(133 * uiScale, 100 * uiScale)
    self.bunkerTextOffsetX, self.bunkerTextOffsetY = getNormalizedScreenValues(238 * uiScale, 75 * uiScale)
end
function BalerStationaryHUDExtension:draw(_, posX, posY)
    local hasBaleOnWrapper = false
    if self.baleWrapper.baleWrapperState > 0 then
        hasBaleOnWrapper = self.baleWrapper.baleWrapperState < BaleWrapper.STATE_WRAPPER_DROPPING_BALE
    end
    local balerBunkerFillLevel = self.vehicle:getFillUnitFillLevel(self.baler.buffer.fillUnitIndex)
    local balerBunkerCapacity = self.vehicle:getFillUnitCapacity(self.baler.buffer.fillUnitIndex)
    local balerMainFillLevel = self.vehicle:getFillUnitFillLevel(self.baler.fillUnitIndex)
    local balerMainCapacity = self.vehicle:getFillUnitCapacity(self.baler.fillUnitIndex)
    self.backgroundTop:setPosition(posX, posY - self.backgroundTop.height)
    self.backgroundScale:setPosition(posX, self.backgroundTop.y - self.backgroundScale.height)
    self.backgroundBottom:setPosition(posX, self.backgroundScale.y - self.backgroundBottom.height)
    self.backgroundTop:render()
    self.backgroundScale:render()
    self.backgroundBottom:render()
    posY = self.backgroundBottom.y
    self.vehicleIcon:setPosition(posX + self.vehicleIconOffsetX, posY + self.vehicleIconOffsetY)
    self.vehicleIcon:render()
    if balerBunkerFillLevel > 0 then
        local grassFillScale = balerBunkerFillLevel / balerBunkerCapacity * 0.3 + 0.7
        self.grassIcon:setScale(grassFillScale, grassFillScale)
        self.grassIcon:setPosition(posX + self.grassIconOffsetX - self.grassIcon.width * 0.5, posY + self.grassIconOffsetY - self.grassIcon.height * 0.5)
        self.grassIcon:render()
    end
    if balerMainFillLevel > 0 then
        local grassFillScale = balerMainFillLevel / balerMainCapacity * 0.5 + 0.5
        self.baleIcon:setScale(grassFillScale, grassFillScale)
        self.baleIcon:setRotation(-(balerMainFillLevel / balerMainCapacity * 5 * 3.141592653589793 * 2), self.baleIcon.width * 0.5, self.baleIcon.height * 0.5)
        self.baleIcon:setPosition(posX + self.baleIconOffsetX - self.baleIcon.width * 0.5, posY + self.baleIconOffsetY - self.baleIcon.height * 0.5)
        self.baleIcon:render()
    end
    if hasBaleOnWrapper then
        self.wrappedBaleIcon:setPosition(posX + self.wrappedBaleIconOffsetX, posY + self.wrappedBaleIconOffsetY)
        self.wrappedBaleIcon:setRotation(-(self.baleWrapper.currentWrapper.currentTime / self.baleWrapper.currentWrapper.animTime * 3.141592653589793 * 2), self.wrappedBaleIcon.width * 0.5, self.wrappedBaleIcon.height * 0.5)
        self.wrappedBaleIcon:render()
    end
    setTextAlignment(RenderText.ALIGN_CENTER)
    renderText(posX + self.bunkerTextOffsetX, posY + self.bunkerTextOffsetY, self.textSize, string.format("%dl", MathUtil.round(balerBunkerFillLevel)))
    renderText(posX + self.baleTextOffsetX, posY + self.baleTextOffsetY, self.textSize, string.format("%dl", MathUtil.round(balerMainFillLevel)))
    setTextAlignment(RenderText.ALIGN_LEFT)
    return self.backgroundBottom.y
end
function BalerStationaryHUDExtension:getHeight()
    return self.totalHeight
end