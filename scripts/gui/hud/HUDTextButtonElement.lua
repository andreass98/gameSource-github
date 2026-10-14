HUDTextButtonElement = {}
local HUDTextButtonElement_mt = Class(HUDTextButtonElement)
function HUDTextButtonElement.new(posX, posY, width, height, textSize, text, onClickedCallback)
    -- upvalues: (copy) HUDTextButtonElement_mt
    local self = setmetatable({}, HUDTextButtonElement_mt)
    self.positionX = posX
    self.positionY = posY
    self.width = width
    self.height = height
    self.frameNormalColor = {
        ["r"] = 0.0284,
        ["g"] = 0.0284,
        ["b"] = 0.0284,
        ["a"] = 0.85
    }
    self.frameHoveredColor = {
        ["r"] = 0.0184,
        ["g"] = 0.0184,
        ["b"] = 0.0184,
        ["a"] = 0.95
    }
    self.frame = g_overlayManager:createOverlay(g_plainColorSliceId, posX, posY, width, height)
    self.frame:setColor(self.frameNormalColor.r, self.frameNormalColor.g, self.frameNormalColor.b, self.frameNormalColor.a)
    self.textDisplayOffsetX = width * 0.5
    self.textDisplayOffsetY = height * 0.5 - textSize * 0.5
    self.textDisplay = HUDTextDisplay.new(posX + self.textDisplayOffsetX, posY + self.textDisplayOffsetY, textSize * g_referenceScreenHeight, RenderText.ALIGN_CENTER)
    self.textDisplay:setText(text)
    self.onClickedCallback = onClickedCallback
    return self
end
function HUDTextButtonElement:delete()
    self.frame:delete()
    self.textDisplay:delete()
    self.onClickedCallback = nil
end
function HUDTextButtonElement:setVisible(isVisible)
    self.frame:setVisible(isVisible)
    self.textDisplay:setVisible(isVisible)
end
function HUDTextButtonElement:setText(text, textSize, textAlignment, textColor, textBold)
    self.textDisplay:setText(text, textSize, textAlignment, textColor, textBold)
end
function HUDTextButtonElement:setPosition(newX, newY)
    self.positionX = newX or self.positionX
    self.positionY = newY or self.positionY
    self.frame:setPosition(self.positionX, self.positionY)
    self.textDisplay:setPosition(self.positionX + self.textDisplayOffsetX, self.positionY + self.textDisplayOffsetY)
end
function HUDTextButtonElement:setFrameColor(r, g, b, a)
    self.frameNormalColor = {
        ["r"] = r or self.frameNormalColor.r,
        ["g"] = g or self.frameNormalColor.g,
        ["b"] = b or self.frameNormalColor.b,
        ["a"] = a or self.frameNormalColor.a
    }
    self.frame:setColor(self.frameNormalColor.r, self.frameNormalColor.g, self.frameNormalColor.b, self.frameNormalColor.a)
end
function HUDTextButtonElement:setFrameHoveredColor(r, g, b, a)
    self.frameHoveredColor = {
        ["r"] = r or self.frameHoveredColor.r,
        ["g"] = g or self.frameHoveredColor.g,
        ["b"] = b or self.frameHoveredColor.b,
        ["a"] = a or self.frameHoveredColor.a
    }
end
HUDTextButtonElement.setFrameColor = HUDTextButtonElement.setFrameColor
HUDTextButtonElement.setFrameHoveredColor = HUDTextButtonElement.setFrameHoveredColor
function HUDTextButtonElement:draw()
    self.frame:render()
    self.textDisplay:draw()
end
function HUDTextButtonElement:update(dt)
    self.textDisplay:update(dt)
end
function HUDTextButtonElement:mouseEvent(posX, posY, _, isUp, button)
    if self.positionX <= posX and (posX < self.positionX + self.width and (self.positionY <= posY and posY < self.positionY + self.height)) then
        if isUp and (button == Input.MOUSE_BUTTON_LEFT and self.onClickedCallback) then
            self.onClickedCallback()
        end
        self.frame:setColor(self.frameHoveredColor.r, self.frameHoveredColor.g, self.frameHoveredColor.b, self.frameHoveredColor.a)
    else
        self.frame:setColor(self.frameNormalColor.r, self.frameNormalColor.g, self.frameNormalColor.b, self.frameNormalColor.a)
    end
end