HUDDisplay = {}
local HUDDisplay_mt = Class(HUDDisplay)
function HUDDisplay.new(customMt)
    -- upvalues: (copy) HUDDisplay_mt
    local self = setmetatable({}, customMt or HUDDisplay_mt)
    self.uiScale = 1
    self.x = 0
    self.y = 0
    self.isVisible = true
    return self
end
function HUDDisplay:delete() end
function HUDDisplay:update(dt) end
function HUDDisplay:draw() end
function HUDDisplay:setVisible(isVisible)
    self.isVisible = isVisible
end
function HUDDisplay:getVisible()
    return self.isVisible
end
function HUDDisplay:setPosition(x, y)
    self.x = x or self.x
    self.y = y or self.y
end
function HUDDisplay:getPosition()
    return self.x, self.y
end
function HUDDisplay:setScale(scale)
    self.uiScale = scale
    self:storeScaledValues()
end
function HUDDisplay:storeScaledValues() end
function HUDDisplay:scalePixelToScreenVector(vector2D)
    return vector2D[1] * self.uiScale * g_aspectScaleX / g_referenceScreenWidth, vector2D[2] * self.uiScale * g_aspectScaleY / g_referenceScreenHeight
end
function HUDDisplay:scalePixelValuesToScreenVector(width, height)
    return width * self.uiScale * g_aspectScaleX / g_referenceScreenWidth, height * self.uiScale * g_aspectScaleY / g_referenceScreenHeight
end
function HUDDisplay:scalePixelToScreenHeight(height)
    return height * self.uiScale * g_aspectScaleY / g_referenceScreenHeight
end
function HUDDisplay:scalePixelToScreenWidth(width)
    return width * self.uiScale * g_aspectScaleX / g_referenceScreenWidth
end