local data = nil
if ChatDisplay ~= nil then
    local old = g_currentMission.hud.chatDisplay
    data = {
        ["uiScale"] = old.uiScale,
        ["isVisible"] = old:getVisible()
    }
    old:delete()
end
ChatDisplay = {}
ChatDisplay.DISPLAY_DURATION = 15000
local old = Class(ChatDisplay, HUDDisplay)
function ChatDisplay.new()
    -- upvalues: (copy) old
    local self = ChatDisplay:superClass().new(old)
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.bgScale = g_overlayManager:createOverlay("gui.chat_middle", 0, 0, 0, 0)
    self.bgScale:setColor(r, g, b, a)
    self.bgTop = g_overlayManager:createOverlay("gui.chat_top", 0, 0, 0, 0)
    self.bgTop:setColor(r, g, b, a)
    self.bgBottom = g_overlayManager:createOverlay("gui.chat_bottom", 0, 0, 0, 0)
    self.bgBottom:setColor(r, g, b, a)
    self.messages = {}
    self.maxNumMessages = 50
    self.scrollOffset = 0
    self.closeTime = 0
    self.duration = 10000
    return self
end
function ChatDisplay:delete()
    self.bgScale:delete()
    self.bgTop:delete()
    self.bgBottom:delete()
end
function ChatDisplay:storeScaledValues()
    local offsetX, offsetY = self:scalePixelValuesToScreenVector(0, 300)
    self:setPosition(g_hudAnchorLeft + offsetX, g_hudAnchorBottom + math.max(offsetY, offsetY / self.uiScale))
    local bgWidth, bgBottomHeight = self:scalePixelValuesToScreenVector(300, 6)
    local bgTopHeight = self:scalePixelToScreenHeight(6)
    self.bgBottom:setDimension(bgWidth, bgBottomHeight)
    self.bgTop:setDimension(bgWidth, bgTopHeight)
    self.bgScale:setDimension(bgWidth, 0)
    self.messageOffsetY = self:scalePixelToScreenHeight(5)
    self.textOffsetX, self.textOffsetY = self:scalePixelValuesToScreenVector(6, -28)
    self.textSize = self:scalePixelToScreenHeight(12)
    self.maxTextWidth = bgWidth - 2 * self.textOffsetX
    self.maxHeight = self:scalePixelToScreenHeight(300)
    self.titleOffsetX, self.titleOffsetY = self:scalePixelValuesToScreenVector(6, -13)
    self.titleHeight = self:scalePixelToScreenHeight(20)
    self.titleTextSize = self:scalePixelToScreenHeight(13)
end
function ChatDisplay:update(_)
    if self:getVisible() and g_time > self.closeTime then
        self:setVisible(false)
    end
end
function ChatDisplay:draw()
    if not self:getVisible() then
        return
    end
    if #self.messages == 0 then
        return
    end
    if g_gui:getIsMenuVisible() and g_gui.currentGuiName ~= "ChatDialog" then
        return
    end
    ChatDisplay:superClass().draw(self)
    local posX, posY = self:getPosition()
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    setTextWrapWidth(self.maxTextWidth, true)
    local i = #self.messages - self.scrollOffset
    for i = i, 1, -1 do
        local message = self.messages[i]
        local text = message.text
        local farmId = message.farmId
        setTextBold(false)
        local scaleHeight = getTextHeight(self.textSize, text) + self.titleHeight
        if posY + self.maxHeight < posY + scaleHeight + self.bgTop.height + self.bgBottom.height then
            break
        end
        self.bgBottom:setPosition(posX, posY)
        self.bgBottom:render()
        self.bgScale:setPosition(posX, self.bgBottom.y + self.bgBottom.height)
        self.bgScale:setDimension(nil, scaleHeight)
        self.bgScale:render()
        self.bgTop:setPosition(posX, self.bgScale.y + self.bgScale.height)
        self.bgTop:render()
        setTextColor(1, 1, 1, 1)
        renderText(posX + self.textOffsetX, self.bgTop.y + self.textOffsetY, self.textSize, text)
        setTextBold(true)
        local r = 1
        local g = 1
        local b = 1
        local a = 1
        if farmId ~= 0 then
            local farm = g_farmManager:getFarmById(farmId)
            if farm ~= nil then
                local color = farm:getColor()
                r = color[1]
                g = color[2]
                b = color[3]
                a = 1
            end
        end
        setTextColor(r, g, b, a)
        local farm = string.format("(%d) %s", i, message.title)
        renderText(posX + self.titleOffsetX, self.bgTop.y + self.titleOffsetY, self.titleTextSize, farm)
        posY = self.bgTop.y + self.bgTop.height + self.messageOffsetY
    end
    setTextBold(false)
    setTextWrapWidth(0)
end
function ChatDisplay:addMessage(text, sender, farmId)
    while #self.messages >= self.maxNumMessages do
        table.remove(self.messages, 1)
    end
    table.insert(self.messages, {
        ["text"] = text,
        ["title"] = string.format("%s %s", getDate("%H:%M:%S"), sender),
        ["farmId"] = farmId
    })
    self:scrollChatMessages(0)
end
function ChatDisplay:setVisible(isVisible)
    ChatDisplay:superClass().setVisible(self, isVisible)
    if isVisible then
        self.closeTime = g_time + self.duration
    end
end
function ChatDisplay:scrollChatMessages(delta)
    self.scrollOffset = math.clamp(self.scrollOffset + delta, 0, (math.max(0, #self.messages - 1)))
end
function ChatDisplay:getHasNewMessages()
    return false
end
if data ~= nil then
    local chatDisplay = ChatDisplay.new()
    chatDisplay:setScale(data.uiScale)
    chatDisplay:setVisible(data.isVisible)
    g_currentMission.hud.chatDisplay = chatDisplay
    g_currentMission.hud.displayComponents.chatDisplay = chatDisplay
    Logging.info("Reloaded ChatDisplay")
end