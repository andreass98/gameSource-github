local data = nil
if AchievementMessage ~= nil then
    local old = g_currentMission.hud.achievementMessage
    data = {
        ["uiScale"] = old.uiScale,
        ["isVisible"] = old:getVisible()
    }
    old:delete()
end
AchievementMessage = {}
local old = Class(AchievementMessage, HUDDisplay)
function AchievementMessage.new(customMt)
    -- upvalues: (copy) old
    local self = AchievementMessage:superClass().new(old)
    self.pendingMessages = {}
    self.currentMessage = nil
    self.showNextFrame = false
    self.headerText = utf8ToUpper(g_i18n:getText("message_achievementUnlocked"))
    self.iconOverlay = Overlay.new(nil, 0, 0, 0, 0)
    self.nextMessageTimer = -1
    return self
end
function AchievementMessage:delete()
    self.iconOverlay:delete()
end
function AchievementMessage:storeScaledValues()
    local offsetX, offsetY = self:scalePixelValuesToScreenVector(0, 0)
    local posX = 0.5 + offsetX
    self:setPosition(posX, g_hudAnchorBottom + offsetY)
    local iconWidth, iconHeight = self:scalePixelValuesToScreenVector(600, 100)
    self.width = iconWidth
    self.height = iconHeight
    local posX = posX - self.width * 0.5
    local iconWidth, iconHeight = self:scalePixelValuesToScreenVector(90, 90)
    self.iconOffsetX, self.iconOffsetY = self:scalePixelValuesToScreenVector(5, -5)
    self.iconOverlay:setDimension(iconWidth, iconHeight)
    self.titleTextSize = self:scalePixelToScreenHeight(19)
    self.titleTextOffsetX, self.titleTextOffsetY = self:scalePixelValuesToScreenVector(105, -30)
    self.descriptionTextSize = self:scalePixelToScreenHeight(17)
    self.descriptionTextOffsetX, self.descriptionTextOffsetY = self:scalePixelValuesToScreenVector(105, -50)
    self.descriptionTextMaxWidth = self:scalePixelToScreenWidth(490)
    self.textOffsetY = self:scalePixelToScreenHeight(20)
end
function AchievementMessage:update(dt)
    if self:getAllowDisplay() then
        if self.currentMessage == nil then
            if self.nextMessageTimer > 0 then
                self.nextMessageTimer = self.nextMessageTimer - dt
                return
            end
            if #self.pendingMessages > 0 then
                self:startMessage()
            end
        else
            self.currentMessage.timeLeft = self.currentMessage.timeLeft - dt
            if self.currentMessage.timeLeft <= 0 then
                self:stopMessage()
                return
            end
        end
    end
end
function AchievementMessage:draw()
    if self:getAllowDisplay() and self:getVisible() then
        AchievementMessage:superClass().draw(self)
        local message = self.currentMessage
        if message == nil then
            return
        end
        setTextAlignment(RenderText.ALIGN_LEFT)
        local posX, posY = self:getPosition()
        local posX = posX - self.width * 0.5
        local title = message.title
        local description = message.description
        setTextBold(true)
        local height = 2 * self.textOffsetY + getTextHeight(self.titleTextSize, title)
        setTextBold(false)
        setTextWrapWidth(self.descriptionTextMaxWidth)
        local textHeight = getTextHeight(self.descriptionTextSize, description)
        setTextWrapWidth(0)
        local color = math.max(self.height, height + textHeight)
        local color = HUD.COLOR.BACKGROUND
        drawFilledRectRound(posX, posY, self.width, color, 0.5, color[1], color[2], color[3], color[4])
        self.iconOverlay:setPosition(posX + self.iconOffsetX, posY + (color - self.iconOverlay.height) * 0.5)
        self.iconOverlay:render()
        local posY = posY + color
        setTextBold(true)
        setTextColor(1, 1, 1, 1)
        renderText(posX + self.titleTextOffsetX, posY + self.titleTextOffsetY, self.titleTextSize, title)
        setTextBold(false)
        setTextColor(1, 1, 1, 0.6)
        setTextWrapWidth(self.descriptionTextMaxWidth)
        renderText(posX + self.descriptionTextOffsetX, posY + self.descriptionTextOffsetY, self.descriptionTextSize, description)
        setTextWrapWidth(0)
    end
end
function AchievementMessage:getAllowDisplay()
    if g_gui:getIsGuiVisible() then
        return false
    end
    if self.isGamePaused then
        return false
    end
    if g_sleepManager:getIsSleeping() then
        return false
    end
    local hud = g_currentMission.hud
    local contextActionDisplay = hud.contextActionDisplay
    if contextActionDisplay ~= nil and contextActionDisplay:getVisible() then
        return false
    end
    local ingameMessage = hud.ingameMessage
    return (ingameMessage == nil or not ingameMessage:getVisible()) and true or false
end
function AchievementMessage:showMessage(title, description, iconFilename, iconUVs, duration)
    if g_dedicatedServer == nil then
        table.insert(self.pendingMessages, {
            ["title"] = title,
            ["description"] = description,
            ["iconFilename"] = iconFilename,
            ["iconUVs"] = iconUVs,
            ["timeLeft"] = duration
        })
    end
end
function AchievementMessage:startMessage()
    local ingameMap = g_currentMission.hud.ingameMap
    ingameMap:setAllowToggle(false)
    ingameMap:turnSmall()
    local pendingMessage = table.remove(self.pendingMessages, 1)
    if pendingMessage ~= nil then
        self.currentMessage = pendingMessage
        self.iconOverlay:setImage(pendingMessage.iconFilename)
        self.iconOverlay:setUVs(pendingMessage.iconUVs)
        self:setVisible(true)
        g_gui.guiSoundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.ACHIEVEMENT)
    end
end
function AchievementMessage:stopMessage()
    if self.currentMessage ~= nil then
        g_currentMission.hud.ingameMap:setAllowToggle(true)
        self:setVisible(false)
        self.currentMessage = nil
        self.nextMessageTimer = 500
    end
end
if data ~= nil then
    local achievementMessage = AchievementMessage.new()
    achievementMessage:setScale(data.uiScale)
    achievementMessage:setVisible(data.isVisible)
    g_currentMission.hud.achievementMessage = achievementMessage
    g_currentMission.hud.displayComponents.achievementMessage = achievementMessage
    Logging.info("Reloaded AchievementMessage")
end