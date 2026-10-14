local data = nil
if SideNotification ~= nil then
    local old = g_currentMission.hud.sideNotifications
    data = {
        ["uiScale"] = old.uiScale,
        ["isVisible"] = old:getVisible(),
        ["progressBars"] = old.progressBars
    }
    old:delete()
end
SideNotification = {}
SideNotification.MAX_NOTIFICATIONS = 5
local mission = Class(SideNotification, HUDDisplay)
function SideNotification.new(customMt)
    -- upvalues: (copy) mission
    local self = SideNotification:superClass().new(mission)
    self.notificationQueue = {}
    self.progressBars = {}
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.bgScale = g_overlayManager:createOverlay("gui.rectangle_center", 0, 0, 0, 0)
    self.bgScale:setColor(r, g, b, a)
    self.bgLeft = g_overlayManager:createOverlay("gui.rectangle_left", 0, 0, 0, 0)
    self.bgLeft:setColor(r, g, b, a)
    self.bgRight = g_overlayManager:createOverlay("gui.rectangle_right", 0, 0, 0, 0)
    self.bgRight:setColor(r, g, b, a)
    self.progressBarBgScale = g_overlayManager:createOverlay("gui.progressBackground_middle", 0, 0, 0, 0)
    self.progressBarBgScale:setColor(r, g, b, a)
    self.progressBarBgTop = g_overlayManager:createOverlay("gui.progressBackground_top", 0, 0, 0, 0)
    self.progressBarBgTop:setColor(r, g, b, a)
    self.progressBarBgBottom = g_overlayManager:createOverlay("gui.progressBackground_bottom", 0, 0, 0, 0)
    self.progressBarBgBottom:setColor(r, g, b, a)
    self.bar = ThreePartOverlay.new()
    self.bar:setLeftPart("gui.progressbar_left", 0, 0)
    self.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
    self.bar:setRightPart("gui.progressbar_right", 0, 0)
    self.savingIcon = g_overlayManager:createOverlay("gui.savingInProgress", 0, 0, 0, 0)
    self.saveText = g_i18n:getText("ui_savegameSaveInProgress")
    self.savingIcon:setColor(1, 1, 1, 0.5)
    return self
end
function SideNotification:delete()
    self.bgScale:delete()
    self.bgLeft:delete()
    self.bgRight:delete()
    self.progressBarBgScale:delete()
    self.progressBarBgTop:delete()
    self.progressBarBgBottom:delete()
    self.savingIcon:delete()
    self.bar:delete()
end
function SideNotification:storeScaledValues()
    local offsetX, offsetY = self:scalePixelValuesToScreenVector(0, -65)
    local posX = g_hudAnchorRight + offsetX
    local posY = g_hudAnchorTop + offsetY
    self:setPosition(posX, posY)
    local bgRightWidth, bgHeight = self:scalePixelValuesToScreenVector(10, 25)
    local bgLeftWidth = self:scalePixelToScreenWidth(10)
    self.bgRight:setDimension(bgRightWidth, bgHeight)
    self.bgLeft:setDimension(bgLeftWidth, bgHeight)
    self.bgScale:setDimension(0, bgHeight)
    self.textSize = self:scalePixelToScreenHeight(16)
    self.textOffsetY = self:scalePixelToScreenHeight(6)
    self.notificationOffsetY = self:scalePixelToScreenHeight(6)
    self.textMaxWidth = self:scalePixelToScreenWidth(330)
    local progressBarBgWidth, progressBarBgPartHeight = self:scalePixelValuesToScreenVector(400, 6)
    self.progressBarBgBottom:setDimension(progressBarBgWidth, progressBarBgPartHeight)
    self.progressBarBgTop:setDimension(progressBarBgWidth, progressBarBgPartHeight)
    self.progressBarBgScale:setDimension(progressBarBgWidth, 0)
    self.progressBarTextSize = self:scalePixelToScreenHeight(12)
    self.progressBarMaxTextWidth = self:scalePixelToScreenWidth(330)
    local backgroundPosX, barPartWidth = self:scalePixelValuesToScreenVector(14, -21)
    self.progressBarTitleOffsetX = backgroundPosX
    self.progressBarTitleOffsetY = barPartWidth
    local backgroundPosX, barPartWidth = self:scalePixelValuesToScreenVector(0, 21)
    self.progressBarTextOffsetX = backgroundPosX
    self.progressBarTextOffsetY = barPartWidth
    self.progressBarSectionOffsetY = self:scalePixelToScreenHeight(5)
    local backgroundPosX, barPartWidth = self:scalePixelValuesToScreenVector(-8, 8)
    self.progressBarProgressTextOffsetX = backgroundPosX
    self.progressBarProgressTextOffsetY = barPartWidth
    self.progressBarProgressTextSize = self:scalePixelToScreenHeight(15)
    local backgroundPosX = posX - self.progressBarBgBottom.width
    self.progressBarBgBottom:setPosition(backgroundPosX, nil)
    self.progressBarBgScale:setPosition(backgroundPosX, nil)
    self.progressBarBgTop:setPosition(backgroundPosX, nil)
    self.helpAnchorPosX = self.progressBarBgTop.x + self:scalePixelToScreenWidth(-15)
    self.helpAnchorPosY = posY + self:scalePixelToScreenHeight(-25)
    local barPartWidth, barPartHeight = self:scalePixelValuesToScreenVector(3, 6)
    local barTotalWidth, _ = self:scalePixelValuesToScreenVector(330, 0)
    self.barMaxScaleWidth = barTotalWidth - 2 * barPartWidth
    self.bar:setLeftPart(nil, barPartWidth, barPartHeight)
    self.bar:setMiddlePart(nil, self.barMaxScaleWidth, barPartHeight)
    self.bar:setRightPart(nil, barPartWidth, barPartHeight)
    local width, height = self:scalePixelValuesToScreenVector(14, 10)
    self.barOffsetX = width
    self.barOffsetY = height
    self.barHeight = self:scalePixelToScreenHeight(20)
    local width, height = self:scalePixelValuesToScreenVector(19, 19)
    self.savingIcon:setDimension(width, height)
    self.savingIconOffsetX, self.savingIconOffsetY = self:scalePixelValuesToScreenVector(6, 3)
end
function SideNotification:update(dt)
    local notification = #self.notificationQueue
    local i = math.min(notification, SideNotification.MAX_NOTIFICATIONS)
    for i = i, 1, -1 do
        local notification = self.notificationQueue[i]
        if notification.duration <= 0 then
            table.remove(self.notificationQueue, i)
        else
            notification.duration = math.max(0, notification.duration - dt)
        end
    end
end
function SideNotification:draw()
    SideNotification:superClass().draw(self)
    local posX, posY = self:getPosition()
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    local hasProgressBars = false
    local textMaxWidth = self.textMaxWidth
    for _, progressBar in ipairs(self.progressBars) do
        if progressBar.isVisible then
            local title = progressBar.progress
            local progress = math.clamp(title, 0, 1)
            local title = ""
            if progressBar.title ~= nil then
                title = utf8ToUpper(progressBar.title .. (progressBar.text == nil and "" or ": "))
            end
            local text = ""
            if progressBar.text ~= nil then
                text = utf8ToUpper(progressBar.text)
            end
            local textWidth = getTextWidth(self.progressBarTextSize, text)
            setTextBold(true)
            setTextAlignment(RenderText.ALIGN_LEFT)
            local titleWidth = getTextWidth(self.progressBarTextSize, title)
            if textWidth + titleWidth > self.textMaxWidth then
                if textWidth < titleWidth then
                    titleWidth = self.textMaxWidth - textWidth
                    title = Utils.limitTextToWidth(title, self.progressBarTextSize, self.textMaxWidth - textWidth, false, "...")
                else
                    text = Utils.limitTextToWidth(text, self.progressBarTextSize, self.textMaxWidth - textWidth, false, "...")
                end
            end
            setTextWrapWidth(self.textMaxWidth - titleWidth)
            local textHeight = getTextHeight(self.progressBarTextSize, text)
            setTextWrapWidth(0)
            local totalHeight = textHeight + self.textOffsetY * 2 + self.barHeight
            self.progressBarBgScale:setDimension(nil, totalHeight - self.progressBarBgTop.height - self.progressBarBgBottom.height)
            self.progressBarBgTop:setPosition(nil, posY - self.notificationOffsetY - self.progressBarBgTop.height)
            self.progressBarBgTop:render()
            self.progressBarBgScale:setPosition(nil, self.progressBarBgTop.y - self.progressBarBgScale.height)
            self.progressBarBgScale:render()
            self.progressBarBgBottom:setPosition(nil, self.progressBarBgScale.y - self.progressBarBgBottom.height)
            self.progressBarBgBottom:render()
            self.bar:setColor(HUD.COLOR.BACKGROUND_DARK[1], HUD.COLOR.BACKGROUND_DARK[2], HUD.COLOR.BACKGROUND_DARK[3], HUD.COLOR.BACKGROUND_DARK[4])
            self.bar:setMiddlePart(nil, self.barMaxScaleWidth, nil)
            self.bar:setPosition(self.progressBarBgBottom.x + self.barOffsetX, self.progressBarBgBottom.y + self.barOffsetY)
            self.bar:render()
            if progress >= 0.01 then
                self.bar:setColor(HUD.COLOR.ACTIVE[1], HUD.COLOR.ACTIVE[2], HUD.COLOR.ACTIVE[3], HUD.COLOR.ACTIVE[4])
                self.bar:setMiddlePart(nil, self.barMaxScaleWidth * progress, nil)
                self.bar:setPosition(self.progressBarBgBottom.x + self.barOffsetX, self.progressBarBgBottom.y + self.barOffsetY)
                self.bar:render()
            end
            local textPosX = self.progressBarBgTop.x + self.progressBarTitleOffsetX
            local textPosY = posY + self.progressBarTitleOffsetY
            renderText(textPosX, textPosY, self.progressBarTextSize, title)
            setTextBold(false)
            setTextWrapWidth(self.textMaxWidth - titleWidth)
            renderText(textPosX + titleWidth, textPosY, self.progressBarTextSize, text)
            setTextWrapWidth(0)
            setTextAlignment(RenderText.ALIGN_RIGHT)
            local progressText = string.format("%d%%", progress * 100)
            renderText(posX + self.progressBarProgressTextOffsetX, self.progressBarBgBottom.y + self.progressBarProgressTextOffsetY, self.progressBarProgressTextSize, progressText)
            hasProgressBars = true
        end
        progressBar.isVisible = false
    end
    if hasProgressBars then
    end
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    if self.isSaving then
        posY = posY - self.bgRight.height - self.notificationOffsetY
        local text = self.saveText
        local textWidth = getTextWidth(self.textSize, text) + self.savingIconOffsetX + self.savingIcon.width
        self.bgRight:setPosition(posX - self.bgRight.width, posY)
        self.bgRight:render()
        self.bgScale:setDimension(textWidth, nil)
        self.bgScale:setPosition(self.bgRight.x - self.bgScale.width, posY)
        self.bgScale:render()
        self.bgLeft:setPosition(self.bgScale.x - self.bgLeft.width, posY)
        self.bgLeft:render()
        self.savingIcon:setPosition(self.bgLeft.x + self.savingIconOffsetX, self.bgLeft.y + self.savingIconOffsetY)
        self.savingIcon:setRotation(self.savingIcon.rotation + 0.0041887902047863905 * g_currentDt, self.savingIcon.width * 0.5, self.savingIcon.height * 0.5)
        self.savingIcon:render()
        setTextColor(1, 1, 1, 1)
        renderText(self.bgRight.x, self.bgRight.y + self.textOffsetY, self.textSize, text)
    end
    local deltaRot = 1
    local progressBar = #self.notificationQueue
    local progress = SideNotification.MAX_NOTIFICATIONS
    local textWidth = 1
    for deltaRot = deltaRot, math.min(progressBar, progress), textWidth do
        posY = posY - self.bgRight.height - self.notificationOffsetY
        local _ = self.notificationQueue[deltaRot]
        local progressBar = getTextWidth(self.textSize, _.text)
        self.bgRight:setPosition(posX - self.bgRight.width, posY)
        self.bgRight:render()
        self.bgScale:setDimension(progressBar, nil)
        self.bgScale:setPosition(self.bgRight.x - self.bgScale.width, posY)
        self.bgScale:render()
        self.bgLeft:setPosition(self.bgScale.x - self.bgLeft.width, posY)
        self.bgLeft:render()
        setTextColor(_.color[1], _.color[2], _.color[3], _.color[4])
        renderText(self.bgRight.x, self.bgRight.y + self.textOffsetY, self.textSize, _.text)
    end
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    setTextBold(false)
end
function SideNotification:addNotification(text, color, displayDuration)
    table.insert(self.notificationQueue, {
        ["text"] = text,
        ["color"] = color,
        ["duration"] = displayDuration,
        ["startDuration"] = displayDuration
    })
end
function SideNotification:addProgressBar(title, text, progress)
    local progressBar = {
        ["title"] = title,
        ["text"] = text,
        ["progress"] = progress,
        ["isVisible"] = false
    }
    table.addElement(self.progressBars, progressBar)
    return progressBar
end
function SideNotification:removeProgressBar(progressBar)
    table.removeElement(self.progressBars, progressBar)
end
function SideNotification:setIsSaving(isSaving)
    self.isSaving = isSaving
end
function SideNotification.markProgressBarForDrawing(_, progressBar)
    progressBar.isVisible = true
end
function SideNotification:getHelpAnchorPosition()
    return self.helpAnchorPosX, self.helpAnchorPosY
end
if data ~= nil then
    local old = SideNotification.new()
    old:setScale(data.uiScale)
    old:setVisible(data.isVisible)
    for _, progressBar in ipairs(data.progressBars) do
        table.addElement(old.progressBars, progressBar)
    end
    local hud = g_currentMission.hud
    hud.sideNotifications = old
    hud.displayComponents.sideNotifications = old
    Logging.info("Reloaded SideNotification")
end