local data = nil
if SpeakerDisplay ~= nil then
    local old = g_currentMission.hud.speakerDisplay
    data = {
        ["uiScale"] = old.uiScale,
        ["isVisible"] = old:getVisible()
    }
    old:delete()
end
SpeakerDisplay = {}
local old = Class(SpeakerDisplay, HUDDisplay)
function SpeakerDisplay.new(customMt)
    -- upvalues: (copy) old
    local self = SpeakerDisplay:superClass().new(old)
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.bgScale = g_overlayManager:createOverlay("gui.rectangle_center", 0, 0, 0, 0)
    self.bgScale:setColor(r, g, b, a)
    self.bgLeft = g_overlayManager:createOverlay("gui.rectangle_left", 0, 0, 0, 0)
    self.bgLeft:setColor(r, g, b, a)
    self.bgRight = g_overlayManager:createOverlay("gui.rectangle_right", 0, 0, 0, 0)
    self.bgRight:setColor(r, g, b, a)
    self.iconTalk = g_overlayManager:createOverlay("gui.multiplayer_chatTalk", 0, 0, 0, 0)
    self.iconTalk:setColor(1, 1, 1, 0.5)
    self.iconMuted = g_overlayManager:createOverlay("gui.multiplayer_soundMute", 0, 0, 0, 0)
    self.iconMuted:setColor(1, 1, 1, 0.5)
    self.speakingTimer = {}
    return self
end
function SpeakerDisplay:delete()
    self.bgScale:delete()
    self.bgLeft:delete()
    self.bgRight:delete()
    self.iconTalk:delete()
    self.iconMuted:delete()
end
function SpeakerDisplay:storeScaledValues()
    local offsetX, offsetY = self:scalePixelValuesToScreenVector(0, -300)
    self:setPosition(g_hudAnchorRight + offsetX, g_hudAnchorTop + offsetY)
    local bgRightWidth, bgHeight = self:scalePixelValuesToScreenVector(10, 25)
    local bgLeftWidth = self:scalePixelToScreenWidth(10)
    self.bgRight:setDimension(bgRightWidth, bgHeight)
    self.bgLeft:setDimension(bgLeftWidth, bgHeight)
    self.bgScale:setDimension(0, bgHeight)
    self.textSize = self:scalePixelToScreenHeight(16)
    self.textOffsetY = self:scalePixelToScreenHeight(6)
    self.speakerOffsetY = self:scalePixelToScreenHeight(6)
    local iconWidth, iconHeight = self:scalePixelValuesToScreenVector(24, 24)
    self.iconTalk:setDimension(iconWidth, iconHeight)
    self.iconMuted:setDimension(iconWidth, iconHeight)
    self.iconTotalOffsetX = iconWidth + self:scalePixelToScreenWidth(6)
end
function SpeakerDisplay:update(dt)
    SpeakerDisplay:superClass().update(self, dt)
    for userId, time in pairs(self.speakingTimer) do
        local newTime = time - dt
        if newTime < 0 then
            newTime = nil
        end
        self.speakingTimer[userId] = newTime
    end
end
function SpeakerDisplay:draw()
    SpeakerDisplay:superClass().draw(self)
    local users = g_currentMission.userManager:getUsers()
    if #users ~= 0 then
        new2DLayer()
        local posX, posY = self:getPosition()
        setTextBold(true)
        setTextColor(1, 1, 1, 1)
        setTextAlignment(RenderText.ALIGN_RIGHT)
        for _, user in ipairs(users) do
            local uuid = user:getUniqueUserId()
            local isSpeakingNow = VoiceChatUtil.getIsSpeakerActive(uuid)
            if isSpeakingNow then
                isSpeakingNow = not user:getIsBlocked()
            end
            if isSpeakingNow then
                self.speakingTimer[uuid] = 500
            end
            if self.speakingTimer[uuid] ~= nil then
                local text = utf8ToUpper(user:getNickname())
                posY = posY - self.bgRight.height - self.speakerOffsetY
                local scaleWidth = getTextWidth(self.textSize, text) + self.iconTotalOffsetX
                self.bgRight:setPosition(posX - self.bgRight.width, posY)
                self.bgRight:render()
                self.bgScale:setDimension(scaleWidth, nil)
                self.bgScale:setPosition(self.bgRight.x - self.bgScale.width, posY)
                self.bgScale:render()
                self.bgLeft:setPosition(self.bgScale.x - self.bgLeft.width, posY)
                self.bgLeft:render()
                if user:getVoiceMuted() then
                    self.iconMuted:renderCustom(self.bgRight.x - self.iconTalk.width, self.bgRight.y)
                else
                    self.iconTalk:renderCustom(self.bgRight.x - self.iconTalk.width, self.bgRight.y)
                end
                renderText(self.bgRight.x - self.iconTotalOffsetX, self.bgRight.y + self.textOffsetY, self.textSize, text)
            end
        end
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextBold(false)
    end
end
if data ~= nil then
    local speakerDisplay = SpeakerDisplay.new()
    speakerDisplay:setScale(data.uiScale)
    speakerDisplay:setVisible(data.isVisible)
    g_currentMission.hud.speakerDisplay = speakerDisplay
    g_currentMission.hud.displayComponents.speakerDisplay = speakerDisplay
    Logging.info("Reloaded SpeakerDisplay")
end