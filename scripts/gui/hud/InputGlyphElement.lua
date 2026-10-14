InputGlyphElement = {}
local InputGlyphElement_mt = Class(InputGlyphElement, HUDElement)
InputGlyphElement.GLYPH_OFFSET_X = 2
InputGlyphElement.TEXT_OFFSET_X = 4
InputGlyphElement.DEFAULT_TEXT_SIZE = 12
function InputGlyphElement.new(inputDisplayManager, baseWidth, baseHeight, customMt)
    -- upvalues: (copy) InputGlyphElement_mt
    local backgroundOverlay = Overlay.new(nil, 0, 0, baseWidth, baseHeight)
    local self = InputGlyphElement:superClass().new(backgroundOverlay, nil, customMt or InputGlyphElement_mt)
    self.inputDisplayManager = inputDisplayManager
    self.plusOverlay = inputDisplayManager:getPlusOverlay()
    self.orOverlay = inputDisplayManager:getOrOverlay()
    self.keyboardOverlay = ButtonOverlay.new()
    self.keyboardOverlay:setColor(1, 1, 1, 1, 0, 0, 0, 0.8)
    self.actionNames = {}
    self.actionText = nil
    self.displayText = nil
    self.actionTextSize = InputGlyphElement.DEFAULT_TEXT_SIZE
    self.inputHelpElement = nil
    self.buttonOverlays = {}
    self.hasButtonOverlays = false
    self.separators = {}
    self.keyNames = {}
    self.hasKeyNames = false
    self.isLeftAligned = false
    self.color = {
        1,
        1,
        1,
        1
    }
    self.buttonColor = {
        1,
        1,
        1,
        1
    }
    self.overlayCopies = {}
    self.baseWidth = baseWidth
    self.baseHeight = baseHeight
    self.glyphOffsetX = 0
    self.textOffsetX = 0
    self.iconSizeX = baseWidth
    self.iconSizeY = baseHeight
    self.plusIconSizeX = baseWidth * 0.5
    self.plusIconSizeY = baseHeight * 0.5
    self.orIconSizeX = baseWidth * 0.5
    self.orIconSizeY = baseHeight * 0.5
    self.alignX = 1
    self.alignY = 1
    self.alignmentOffsetX = 0
    self.alignmentOffsetY = 0
    self.lowerCase = false
    self.upperCase = false
    self.bold = false
    self:setScale(1, 1)
    g_messageCenter:subscribe(MessageType.INPUT_DEVICES_CHANGED, self.onInputDevicesChanged, self)
    return self
end
function InputGlyphElement:delete()
    self.keyboardOverlay:delete()
    g_messageCenter:unsubscribeAll(self)
    InputGlyphElement:superClass().delete(self)
end
function InputGlyphElement:setIsLeftAligned(isLeftAligned)
    self.isLeftAligned = isLeftAligned
end
function InputGlyphElement:setScale(widthScale, heightScale)
    InputGlyphElement:superClass().setScale(self, widthScale, heightScale)
    self.glyphOffsetX = self:scalePixelToScreenWidth(InputGlyphElement.GLYPH_OFFSET_X)
    self.textOffsetX = self:scalePixelToScreenWidth(InputGlyphElement.TEXT_OFFSET_X)
    self.iconSizeX = self.baseWidth * widthScale
    self.iconSizeY = self.baseHeight * heightScale
    self.plusIconSizeX = self.iconSizeX * 0.5
    self.plusIconSizeY = self.iconSizeY * 0.5
    self.orIconSizeX = self.iconSizeX * 0.5
    self.orIconSizeY = self.iconSizeY * 0.5
end
function InputGlyphElement:setUpperCase(enableUpperCase)
    self.upperCase = enableUpperCase
    self.lowerCase = self.lowerCase and not enableUpperCase
    self:updateDisplayText()
end
function InputGlyphElement:setLowerCase(enableLowerCase)
    self.lowerCase = enableLowerCase
    self.upperCase = self.upperCase and not enableLowerCase
    self:updateDisplayText()
end
function InputGlyphElement:setBold(isBold)
    self.bold = isBold
end
function InputGlyphElement:setKeyboardGlyphColor(color, bgColor)
    local r = nil
    local g = nil
    local b = nil
    local a = nil
    local bgR = nil
    local bgG = nil
    local bgB = nil
    local bgA = nil
    self.color = color
    if color ~= nil then
        r = color[1]
        g = color[2]
        b = color[3]
        a = color[4]
    end
    if bgColor ~= nil then
        bgR = bgColor[1]
        bgG = bgColor[2]
        bgB = bgColor[3]
        bgA = bgColor[4]
    end
    self.keyboardOverlay:setColor(r, g, b, a, bgR, bgG, bgB, bgA)
end
function InputGlyphElement:setButtonGlyphColor(color)
    self.buttonColor = color
    for _, actionName in ipairs(self.actionNames) do
        local buttonOverlays = self.buttonOverlays[actionName]
        if buttonOverlays ~= nil then
            for _, overlay in pairs(buttonOverlays) do
                overlay:setColor(unpack(color))
            end
        end
    end
end
function InputGlyphElement:onInputDevicesChanged()
    self:setActions(self.actionNames, self.actionText, self.actionTextSize, self.noModifiers)
end
function InputGlyphElement:setAction(actionName, actionText, actionTextSize, noModifiers)
    table.clear(self.actionNames)
    table.insert(self.actionNames, actionName)
    self:setActions(self.actionNames, actionText, actionTextSize, noModifiers)
end
function InputGlyphElement:setActions(actionNames, actionText, actionTextSize, noModifiers, customBinding)
    self.actionNames = actionNames
    self.actionText = actionText
    self.actionTextSize = actionTextSize or InputGlyphElement.DEFAULT_TEXT_SIZE
    self.noModifiers = noModifiers
    self:updateDisplayText()
    local height = self:getHeight()
    local width = 0
    for i, actionName in ipairs(actionNames) do
        local actionName2 = nil
        if #actionNames == 2 then
            actionName2 = actionNames[i + 1]
        end
        local helpElement = self.inputDisplayManager:getControllerSymbolOverlays(actionName, actionName2, "", noModifiers, customBinding)
        local buttonOverlays = helpElement.buttons
        self.separators = helpElement.separators
        if self.buttonOverlays[actionName] == nil then
            self.buttonOverlays[actionName] = {}
        else
            local j = 1
            for j = j, #self.buttonOverlays[actionName] do
                self.buttonOverlays[actionName][j] = nil
            end
        end
        self.hasButtonOverlays = false
        if #buttonOverlays > 0 then
            for _, overlay in ipairs(buttonOverlays) do
                table.insert(self.buttonOverlays[actionName], overlay)
                self.hasButtonOverlays = true
            end
        end
        if self.keyNames[actionName] == nil then
            self.keyNames[actionName] = {}
        else
            local j = 1
            for j = j, #self.keyNames[actionName] do
                self.keyNames[actionName][j] = nil
            end
        end
        self.hasKeyNames = false
        if #helpElement.keys > 0 then
            for _, overlay in ipairs(helpElement.keys) do
                table.insert(self.keyNames[actionName], overlay)
                self.hasKeyNames = true
            end
        end
        if isDoubleAction then
            break
        end
    end
    if self.hasButtonOverlays then
        for i, actionName in pairs(self.buttonOverlays) do
            for i, _ in ipairs(actionName) do
                if i > 1 then
                end
                width = width + self.iconSizeX + (i < #actionName and self.glyphOffsetX or 0)
            end
        end
    elseif self.hasKeyNames then
        for i, actionName in pairs(self.keyNames) do
            for i, _ in ipairs(actionName) do
                width = width + self.keyboardOverlay:getButtonWidth(_, height)
            end
        end
    end
    self:setDimension(width, height)
end
function InputGlyphElement:updateDisplayText()
    if self.actionText ~= nil then
        self.displayText = self.actionText
        if self.upperCase then
            self.displayText = utf8ToUpper(self.actionText)
            return
        end
        if self.lowerCase then
            self.displayText = utf8ToLower(self.actionText)
        end
    end
end
function InputGlyphElement:getGlyphWidth()
    local width = 0
    if not self.hasButtonOverlays then
        if self.hasKeyNames then
            for _, actionName in ipairs(self.actionNames) do
                local keyNames = self.keyNames[actionName]
                if keyNames ~= nil then
                    for _, separatorType in ipairs(keyNames) do
                        width = width + self.keyboardOverlay:getButtonWidth(separatorType, self.iconSizeY) + (_ < #self.keyNames[actionName] and self.glyphOffsetX or 0)
                    end
                end
            end
        end
        return width
    end
    for _, actionName in ipairs(self.actionNames) do
        if self.buttonOverlays[actionName] ~= nil then
            for i, _ in ipairs(self.buttonOverlays[actionName]) do
                if i > 1 and self:getDrawSeparator() then
                    local separatorType = self.separators[i - 1]
                    local separatorWidth = 0
                    if separatorType == InputHelpElement.SEPARATOR.COMBO_INPUT then
                        separatorWidth = self.plusIconSizeX
                    elseif separatorType == InputHelpElement.SEPARATOR.ANY_INPUT then
                        separatorWidth = self.orIconSizeX
                    end
                end
                local separatorType = i < #self.buttonOverlays[actionName] and self.glyphOffsetX or 0
                width = width + self.iconSizeX + separatorType
            end
        end
    end
    return width
end
function InputGlyphElement:getPositionOffset()
    return 0, 0
end
function InputGlyphElement:getDrawSeparator()
    return true
end
function InputGlyphElement:draw(clipX1, clipY1, clipX2, clipY2)
    if #self.actionNames ~= 0 and self.overlay:getIsVisible() then
        InputGlyphElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
        local posX, posY = self:getPosition()
        local offsetX, offsetY = self:getPositionOffset()
        local totalGlyphWidth = self:getGlyphWidth()
        local posX = posX + offsetX
        local posY = posY + offsetY
        if not self.isLeftAligned then
        end
        if self.hasButtonOverlays then
            for _, actionName in ipairs(self.actionNames) do
                if self.buttonOverlays[actionName] ~= nil then
                    posX = self:drawControllerButtons(self.buttonOverlays[actionName], posX, posY, clipX1, clipY1, clipX2, clipY2)
                end
            end
        elseif self.hasKeyNames then
            for _, actionName in ipairs(self.actionNames) do
                local keyNames = self.keyNames[actionName]
                if keyNames ~= nil then
                    for i, key in ipairs(keyNames) do
                        posX = posX + self.keyboardOverlay:renderButton(key, posX, posY, self.iconSizeY, true, clipX1, clipY1, clipX2, clipY2) + (i < #keyNames and self.glyphOffsetX or 0)
                    end
                end
            end
        end
        if self.actionText ~= nil then
            self:drawActionText(posX, posY, clipX1, clipY1, clipX2, clipY2)
        end
    end
end
function InputGlyphElement:drawControllerButtons(buttonOverlays, posX, posY, clipX1, clipY1, clipX2, clipY2)
    for i, overlay in ipairs(buttonOverlays) do
        if i > 1 and self:getDrawSeparator() then
            local separatorType = self.separators[i - 1]
            local separatorOverlay = self.orOverlay
            local separatorWidth = 0
            local separatorHeight = 0
            if separatorType == InputHelpElement.SEPARATOR.COMBO_INPUT then
                separatorOverlay = self.plusOverlay
                separatorWidth = self.plusIconSizeX
                separatorHeight = self.plusIconSizeY
            elseif separatorType == InputHelpElement.SEPARATOR.ANY_INPUT then
                separatorWidth = self.orIconSizeX
                separatorHeight = self.orIconSizeY
            end
            separatorOverlay:renderCustom(posX, posY + (self.iconSizeY - separatorHeight) * 0.5, separatorWidth, separatorHeight, self.buttonColor[1], self.buttonColor[2], self.buttonColor[3], self.buttonColor[4], clipX1, clipY1, clipX2, clipY2)
            posX = posX + separatorWidth + self.glyphOffsetX
        end
        overlay:renderCustom(posX, posY, self.iconSizeX, self.iconSizeY, color[1], color[2], color[3], color[4], clipX1, clipY1, clipX2, clipY2)
        local separatorOverlay = i < #buttonOverlays and self.glyphOffsetX or 0
        posX = posX + self.iconSizeX + separatorOverlay
    end
    return posX
end
function InputGlyphElement:drawActionText(posX, posY, clipX1, clipY1, clipX2, clipY2)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(self.bold)
    setTextColor(unpack(self.color))
    if clipX1 ~= nil then
        setTextClipArea(clipX1, clipY1, clipX2, clipY2)
    end
    renderText(posX + self.textOffsetX, posY + self.actionTextSize * 0.5, self.actionTextSize, self.displayText)
    if clipX1 ~= nil then
        setTextClipArea(0, 0, 1, 1)
    end
end
function InputGlyphElement:setBaseSize(baseWidth, baseHeight)
    self.baseWidth = baseWidth
    self.baseHeight = baseHeight
    self.iconSizeX = baseWidth
    self.iconSizeY = baseHeight
    self.plusIconSizeX = baseWidth * 0.5
    self.plusIconSizeY = baseHeight * 0.5
    self.orIconSizeX = baseWidth * 0.5
    self.orIconSizeY = baseHeight * 0.5
    self:setDimension(baseWidth, baseHeight)
end