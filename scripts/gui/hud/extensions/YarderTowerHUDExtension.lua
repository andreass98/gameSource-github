YarderTowerHUDExtension = {}
local YarderTowerHUDExtension_mt = Class(YarderTowerHUDExtension)
function YarderTowerHUDExtension.new(vehicle, customMt)
    -- upvalues: (copy) YarderTowerHUDExtension_mt
    local self = setmetatable({}, customMt or YarderTowerHUDExtension_mt)
    self.priority = GS_PRIO_HIGH
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.backgroundTop = g_overlayManager:createOverlay("gui.hudExtension_top", 0, 0, 0, 0)
    self.backgroundTop:setColor(r, g, b, a)
    self.backgroundScale = g_overlayManager:createOverlay("gui.hudExtension_middle", 0, 0, 0, 0)
    self.backgroundScale:setColor(r, g, b, a)
    self.backgroundBottom = g_overlayManager:createOverlay("gui.hudExtension_bottom", 0, 0, 0, 0)
    self.backgroundBottom:setColor(r, g, b, a)
    self.iconCarriage = g_overlayManager:createOverlay("gui.icon_carriage", 0, 0, 0, 0)
    self.iconPlayer = g_overlayManager:createOverlay("gui.icon_position", 0, 0, 0, 0)
    self.iconPosition = g_overlayManager:createOverlay("gui.icon_position", 0, 0, 0, 0)
    self.iconTree = g_overlayManager:createOverlay("gui.icon_tree", 0, 0, 0, 0)
    self.iconYarder = g_overlayManager:createOverlay("gui.icon_yarder", 0, 0, 0, 0)
    self.text = string.format("%s - %s", g_i18n:getText("ui_yarder"), vehicle:getName())
    self.vehicle = vehicle
    self:storeScaledValues()
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)
    return self
end
function YarderTowerHUDExtension:delete()
    self.backgroundTop:delete()
    self.backgroundScale:delete()
    self.backgroundBottom:delete()
    self.iconCarriage:delete()
    self.iconPlayer:delete()
    self.iconPosition:delete()
    self.iconTree:delete()
    self.iconYarder:delete()
    g_messageCenter:unsubscribeAll(self)
end
function YarderTowerHUDExtension:storeScaledValues()
    local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
    local width, height = getNormalizedScreenValues(0, 77 * uiScale)
    self.totalHeight = height
    local width, height = getNormalizedScreenValues(330 * uiScale, 6 * uiScale)
    self.backgroundTop:setDimension(width, height)
    self.backgroundBottom:setDimension(width, height)
    self.backgroundScale:setDimension(width, self.totalHeight - 2 * height)
    local width, height = getNormalizedScreenValues(20 * uiScale, 20 * uiScale)
    self.iconCarriage:setDimension(width, height)
    local width, height = getNormalizedScreenValues(6 * uiScale, 5 * uiScale)
    self.iconPosition:setDimension(width, height)
    local width, height = getNormalizedScreenValues(10 * uiScale, 9 * uiScale)
    self.iconPlayer:setDimension(width, height)
    local width, height = getNormalizedScreenValues(20 * uiScale, 9 * uiScale)
    self.iconTree:setDimension(width, height)
    local width, height = getNormalizedScreenValues(290 * uiScale, 45 * uiScale)
    self.iconYarder:setDimension(width, height)
    self.yarderOffsetX, self.yarderOffsetY = getNormalizedScreenValues(8 * uiScale, 5 * uiScale)
    _, self.playerOffsetY = getNormalizedScreenValues(0 * uiScale, 8 * uiScale)
    self.playerMinOffsetX = getNormalizedScreenValues(33 * uiScale, 0 * uiScale)
    self.playerMaxOffsetX = getNormalizedScreenValues(258 * uiScale, 0 * uiScale)
    _, self.positionOffsetY = getNormalizedScreenValues(0 * uiScale, 48 * uiScale)
    self.positionMinOffsetX = getNormalizedScreenValues(30 * uiScale, 0 * uiScale)
    self.positionMaxOffsetX = getNormalizedScreenValues(266 * uiScale, 0 * uiScale)
    _, self.carriageOffsetY = getNormalizedScreenValues(0 * uiScale, 29 * uiScale)
    self.carriageMinOffsetX = getNormalizedScreenValues(28 * uiScale, 0 * uiScale)
    self.carriageMaxOffsetX = getNormalizedScreenValues(253 * uiScale, 0 * uiScale)
    self.textOffsetX, self.textOffsetY = getNormalizedScreenValues(14 * uiScale, 58 * uiScale)
    _, self.textSize = getNormalizedScreenValues(0, 12 * uiScale)
end
function YarderTowerHUDExtension:draw(_, posX, posY)
    self.backgroundTop:setPosition(posX, posY - self.backgroundTop.height)
    self.backgroundScale:setPosition(posX, self.backgroundTop.y - self.backgroundScale.height)
    self.backgroundBottom:setPosition(posX, self.backgroundScale.y - self.backgroundBottom.height)
    self.backgroundTop:render()
    self.backgroundScale:render()
    self.backgroundBottom:render()
    posY = self.backgroundBottom.y
    local isPlayerInRange, isLoaded, playerPosition, carriagePosition, followModeState, followModeLocalPlayer, targetPosition = self.vehicle:getYarderStatusInfo()
    self.iconYarder:setPosition(posX + self.yarderOffsetX, posY + self.yarderOffsetY)
    self.iconYarder:render()
    if targetPosition ~= nil then
        self.iconPosition:setColor(nil, nil, nil, math.sin(g_time * 0.0075) * 0.25 + 0.5)
        self.iconPosition:setPosition(posX + MathUtil.lerp(self.positionMinOffsetX, self.positionMaxOffsetX, targetPosition), posY + self.positionOffsetY)
        self.iconPosition:render()
    end
    if isPlayerInRange then
        if followModeState == YarderTower.FOLLOW_MODE_ME and followModeLocalPlayer then
            self.iconPlayer:setColor(nil, nil, nil, math.sin(g_time * 0.0075) * 0.25 + 0.5)
        else
            self.iconPlayer:setColor(nil, nil, nil, 1)
        end
        local positionOffsetX = MathUtil.lerp(self.playerMinOffsetX, self.playerMaxOffsetX, playerPosition)
        self.iconPlayer:setPosition(posX + positionOffsetX, posY + self.playerOffsetY)
        self.iconPlayer:render()
    end
    local positionOffsetX = MathUtil.lerp(self.carriageMinOffsetX, self.carriageMaxOffsetX, carriagePosition)
    self.iconCarriage:setPosition(posX + positionOffsetX, posY + self.carriageOffsetY)
    self.iconCarriage:render()
    if isLoaded then
        self.iconTree:setPosition(self.iconCarriage.x + self.iconCarriage.width * 0.5 - self.iconTree.width * 0.5, self.iconCarriage.y - self.iconTree.height)
        self.iconTree:render()
    end
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    renderText(posX + self.textOffsetX, posY + self.textOffsetY, self.textSize, self.text)
    setTextBold(false)
    return posY
end
function YarderTowerHUDExtension:getHeight()
    return self.totalHeight
end