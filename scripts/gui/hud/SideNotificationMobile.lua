local data = nil
if SideNotificationMobile ~= nil then
    local old = g_currentMission.hud.sideNotifications
    data = {
        ["notificationQueue"] = old.notificationQueue,
        ["uiScale"] = old.uiScale
    }
    old:delete()
end
SideNotificationMobile = {}
local old = Class(SideNotificationMobile, SideNotification)
function SideNotificationMobile.new()
    -- upvalues: (copy) old
    local self = SideNotificationMobile:superClass().new(old)
    self.uiScale = 1
    self.r, self.g, self.b, self.a = unpack(SideNotificationMobile.COLOR.BACKGROUND)
    self:applyValues(self.uiScale)
    return self
end
function SideNotificationMobile:setScale(uiScale)
    SideNotificationMobile:superClass().setScale(self, uiScale)
    self.uiScale = uiScale
    local posX, posY = SideNotificationMobile.getBackgroundPosition(uiScale)
    self:setPosition(posX, posY)
    self:applyValues(uiScale)
end
function SideNotificationMobile:applyValues(uiScale)
    local _, textSize = getNormalizedScreenValues(0, SideNotificationMobile.TEXT_SIZE.DEFAULT_NOTIFICATION)
    self.textSize = textSize * uiScale
    local textOffsetX, textOffsetY = getNormalizedScreenValues(unpack(SideNotificationMobile.POSITION.TEXT_OFFSET))
    self.textOffsetX = textOffsetX * uiScale
    self.textOffsetY = textOffsetY * uiScale
    local _, bgHeight = getNormalizedScreenValues(0, SideNotificationMobile.SIZE.BG_HEIGHT)
    self.bgHeight = bgHeight * uiScale
    local _, offsetY = getNormalizedScreenValues(0, SideNotificationMobile.POSITION.OFFSET)
    self.offsetY = offsetY * uiScale
end
function SideNotificationMobile:updateSizeAndPositions() end
function SideNotificationMobile:draw()
    if self:getVisible() and #self.notificationQueue > 0 then
        local baseX, baseY = self:getPosition()
        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_LEFT)
        local i = 1
        local fadeAlpha = #self.notificationQueue
        local textWidth = SideNotification.MAX_NOTIFICATIONS
        local notification = math.min(fadeAlpha, textWidth)
        for i = i, notification do
            local notification = self.notificationQueue[i]
            local fadeAlpha = 1
            if notification.startDuration - notification.duration < SideNotification.FADE_DURATION then
                fadeAlpha = (notification.startDuration - notification.duration) / SideNotification.FADE_DURATION
            elseif notification.duration < SideNotification.FADE_DURATION then
                fadeAlpha = notification.duration / SideNotification.FADE_DURATION
            end
            local textWidth = getTextWidth(self.textSize, notification.text) + 2 * self.textOffsetX
            local posX = baseX - textWidth
            local posY = baseY - i * self.bgHeight - (i - 1) * self.offsetY
            drawFilledRectRound(posX, posY, textWidth, bgHeight, self.uiScale, self.r, self.g, self.b, self.a * fadeAlpha)
            setTextColor(notification.color[1], notification.color[2], notification.color[3], notification.color[4] * fadeAlpha)
            renderText(posX + textOffsetX, posY + self.textOffsetY, textSize, notification.text)
            setTextColor(1, 1, 1, 1)
        end
    end
end
function SideNotificationMobile.getBackgroundPosition(uiScale)
    local offX, offY = getNormalizedScreenValues(unpack(SideNotificationMobile.POSITION.SELF))
    return 1 + offX * uiScale, 1 + offY * uiScale
end
function SideNotificationMobile:createBackground()
    local posX, posY = SideNotificationMobile.getBackgroundPosition(1)
    local width, height = getNormalizedScreenValues(unpack(SideNotificationMobile.SIZE.SELF))
    return Overlay.new(nil, posX - width, posY - height, width, height)
end
SideNotificationMobile.POSITION = {
    ["SELF"] = { -45, -160 },
    ["TEXT_OFFSET"] = { 10, 11 },
    ["OFFSET"] = 6
}
SideNotificationMobile.SIZE = {
    ["SELF"] = { 1, 1 },
    ["BG_HEIGHT"] = 46
}
SideNotificationMobile.COLOR = {
    ["BACKGROUND"] = {
        0,
        0,
        0,
        0.4
    }
}
SideNotificationMobile.TEXT_SIZE = {
    ["DEFAULT_NOTIFICATION"] = 32
}
if data ~= nil then
    local sideNotifications = SideNotificationMobile.new(g_baseHUDFilename)
    sideNotifications:setScale(data.uiScale)
    sideNotifications.notificationQueue = data.notificationQueue
    for k, elem in ipairs(g_currentMission.hud.displayComponents) do
        if elem == g_currentMission.hud.sideNotifications then
            g_currentMission.hud.displayComponents[k] = sideNotifications
            break
        end
    end
    g_currentMission.hud.sideNotifications = sideNotifications
    Logging.info("Reloaded")
end