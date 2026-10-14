local data = nil
if GamePausedDisplay ~= nil then
    local old = g_currentMission.hud.gamePausedDisplay
    data = {
        ["uiScale"] = old.uiScale,
        ["isVisible"] = old:getVisible()
    }
    old:delete()
end
GamePausedDisplay = {}
local old = Class(GamePausedDisplay, HUDDisplay)
function GamePausedDisplay.new()
    -- upvalues: (copy) old
    local self = SideNotification:superClass().new(old)
    self.syncBackground = Overlay.new("shared/splash.png", 0, 0, 1, g_screenAspectRatio)
    self.pauseText = utf8ToUpper("Pausiert")
    return self
end
function GamePausedDisplay:delete()
    self.syncBackground:delete()
end
function GamePausedDisplay:storeScaledValues()
    self:setPosition(0.5, 0.5)
    self.width = 1
    self.height = self:scalePixelToScreenHeight(75)
    self.textSize = self:scalePixelToScreenHeight(26)
    self.textOffsetY = self:scalePixelToScreenHeight(28)
end
function GamePausedDisplay:draw(drawBackground)
    if self:getVisible() then
        GamePausedDisplay:superClass().draw(self)
        if drawBackground then
            self.syncBackground:render()
        end
        local posX, posY = self:getPosition()
        local posY = posY - self.height * 0.5
        drawFilledRect(0, posY, 1, self.height, 0, 0, 0, 0.8)
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextBold(true)
        setTextColor(1, 1, 1, 1)
        renderText(posX, posY + self.textOffsetY, self.textSize, self.pauseText)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextBold(false)
    end
end
function GamePausedDisplay:setPauseText(text)
    self.pauseText = utf8ToUpper(text)
end
if data ~= nil then
    local gamePausedDisplay = GamePausedDisplay.new()
    gamePausedDisplay:setScale(data.uiScale)
    gamePausedDisplay:setVisible(data.isVisible)
    g_currentMission.hud.gamePausedDisplay = gamePausedDisplay
    g_currentMission.hud.displayComponents.gamePausedDisplay = gamePausedDisplay
    Logging.info("Reloaded GamePausedDisplay")
end