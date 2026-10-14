local data = nil
if TopNotification ~= nil then
    local old = g_currentMission.hud.topNotification
    data = {
        ["uiScale"] = old.uiScale,
        ["isVisible"] = old:getVisible()
    }
    old:delete()
end
TopNotification = {}
TopNotification.DEFAULT_DURATION = 5000
local old = Class(TopNotification, HUDDisplay)
function TopNotification.new()
    -- upvalues: (copy) old
    local self = TopNotification:superClass().new(old)
    self.currentNotification = {
        ["title"] = "",
        ["text"] = "",
        ["info"] = "",
        ["icon"] = nil,
        ["duration"] = 0,
        ["isValid"] = false
    }
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.bgScale = g_overlayManager:createOverlay("gui.gameInfo_middle", 0, 0, 0, 0)
    self.bgScale:setColor(r, g, b, a)
    self.bgLeft = g_overlayManager:createOverlay("gui.gameInfo_left", 0, 0, 0, 0)
    self.bgLeft:setColor(r, g, b, a)
    self.bgRight = g_overlayManager:createOverlay("gui.gameInfo_right", 0, 0, 0, 0)
    self.bgRight:setColor(r, g, b, a)
    self.icons = {}
    return self
end
function TopNotification:delete()
    self.bgLeft:delete()
    self.bgScale:delete()
    self.bgRight:delete()
    for _, overlay in pairs(self.icons) do
        overlay:delete()
    end
end
function TopNotification:storeScaledValues()
    self:setPosition(0.5, g_hudAnchorTop)
    local bgRightWidth, bgHeight = self:scalePixelValuesToScreenVector(10, 65)
    local bgLeftWidth = self:scalePixelToScreenWidth(10)
    local bgScaleWidth = self:scalePixelToScreenWidth(460)
    self.bgRight:setDimension(bgRightWidth, bgHeight)
    self.bgScale:setDimension(bgScaleWidth, bgHeight)
    self.bgLeft:setDimension(bgLeftWidth, bgHeight)
    self.iconWidth, self.iconHeight = self:scalePixelValuesToScreenVector(80, 40)
    self.iconOffsetX, self.iconOffsetY = self:scalePixelValuesToScreenVector(7, 13)
    self.titleTextSize = self:scalePixelToScreenHeight(17)
    self.titleTextOffsetY = self:scalePixelToScreenHeight(40)
    self.textSize = self:scalePixelToScreenHeight(12)
    self.textOffsetY = self:scalePixelToScreenHeight(24)
    self.infoTextSize = self:scalePixelToScreenHeight(12)
    self.infoTextOffsetY = self:scalePixelToScreenHeight(11)
end
function TopNotification:hide()
    if self.currentNotification.isValid then
        self.currentNotification.duration = 0
    end
end
function TopNotification:update(dt)
    if self.currentNotification.isValid then
        if self.currentNotification.duration <= 0 then
            self.currentNotification.isValid = false
            return
        end
        self.currentNotification.duration = self.currentNotification.duration - dt
    end
end
function TopNotification:draw()
    TopNotification:superClass().draw(self)
    local notification = self.currentNotification
    if notification.isValid then
        local posX, posY = self:getPosition()
        local posY = posY - self.bgScale.height
        self.bgScale:setPosition(posX - self.bgScale.width * 0.5, posY)
        self.bgScale:render()
        self.bgLeft:setPosition(self.bgScale.x - self.bgLeft.width, posY)
        self.bgLeft:render()
        self.bgRight:setPosition(self.bgScale.x + self.bgScale.width, posY)
        self.bgRight:render()
        local icon = notification.icon
        if icon ~= nil then
            icon:setPosition(self.bgLeft.x + self.iconOffsetX, self.bgLeft.y + self.iconOffsetY)
            icon:render()
        end
        local maxTextWidth
        if icon == nil then
            maxTextWidth = self.bgScale.width
        else
            maxTextWidth = self.bgScale.width - 2 * self.iconWidth
        end
        local title = Utils.limitTextToWidth(notification.title, self.titleTextSize, maxTextWidth, false, "...")
        local text = Utils.limitTextToWidth(notification.text, self.textSize, maxTextWidth, false, "...")
        local info = Utils.limitTextToWidth(notification.info, self.infoTextSize, maxTextWidth, false, "...")
        setTextBold(true)
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextColor(1, 1, 1, 1)
        renderText(posX, posY + self.titleTextOffsetY, self.titleTextSize, title)
        renderText(posX, posY + self.textOffsetY, self.textSize, text)
        setTextColor(1, 1, 1, 0.3)
        renderText(posX, posY + self.infoTextOffsetY, self.infoTextSize, info)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextBold(false)
    end
end
function TopNotification:setNotification(title, text, info, iconFilename, duration)
    local icon = self.icons[iconFilename]
    if iconFilename ~= nil and icon == nil then
        icon = Overlay.new(iconFilename, 0, 0, self.iconWidth, self.iconHeight)
        self.icons[iconFilename] = icon
    end
    self.currentNotification.title = utf8ToUpper(title)
    self.currentNotification.text = utf8ToUpper(text)
    self.currentNotification.info = info
    self.currentNotification.icon = icon
    self.currentNotification.duration = duration or TopNotification.DEFAULT_DURATION
    self.currentNotification.isValid = true
end
if data ~= nil then
    local topNotification = TopNotification.new()
    topNotification:setScale(data.uiScale)
    topNotification:setVisible(data.isVisible)
    g_currentMission.hud.topNotification = topNotification
    g_currentMission.hud.displayComponents.topNotification = topNotification
    Logging.info("Reloaded TopNotification")
end