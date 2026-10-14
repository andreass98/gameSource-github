DebugElement = {}
local DebugElement_mt = Class(DebugElement)
function DebugElement.new(customMt)
    -- upvalues: (copy) DebugElement_mt
    local self = setmetatable({}, customMt or DebugElement_mt)
    self.x = 0
    self.y = 0
    self.z = 0
    self.color = Color.new(1, 1, 1, 1)
    self.text = nil
    self.textSize = nil
    self.textColor = nil
    self.textClipDistance = nil
    self.isVisible = true
    self.clipDistance = nil
    self.hideWhenGuiIsOpen = true
    return self
end
function DebugElement:getShouldBeDrawn()
    if self.isVisible then
        if self.hideWhenGuiIsOpen and (g_gui ~= nil and (g_gui:getIsGuiVisible() and g_gui.currentGuiName ~= "ConstructionScreen")) then
            return false
        end
        if self.clipDistance ~= nil then
            local x, y, z = getWorldTranslation(g_cameraManager:getActiveCamera())
            if MathUtil.vector3Length(x - self.x, y - self.y, z - self.z) > self.clipDistance then
                return false
            end
        end
        return true
    end
end
function DebugElement:draw() end
function DebugElement:addToManager(groupId, lifetime, maxCount)
    g_debugManager:addElement(self, groupId, lifetime, maxCount)
    return self
end
function DebugElement:setColorRGBA(r, g, b, a)
    self.color = Color.new(r, g, b, a)
    return self
end
function DebugElement:setColor(color)
    if color ~= nil and (color.isa ~= nil and color:isa(Color)) then
        self.color = color
        return self
    end
    Logging.error("DebugElement:setColor called with argument not being a \'Color\' object")
    printCallstack()
    return self
end
function DebugElement:setText(text)
    self.text = text and tostring(text) or nil
    return self
end
function DebugElement:setTextSize(textSize)
    self.textSize = textSize
    return self
end
function DebugElement:setTextColor(color)
    if color ~= nil and (color.isa ~= nil and color:isa(Color)) then
        self.textColor = color
        return self
    end
    Logging.error("DebugElement:setTextColor called with argument not being a \'Color\' object")
    printCallstack()
    return self
end
function DebugElement:setTextClipDistance(textClipDistance)
    self.textClipDistance = textClipDistance
    return self
end
function DebugElement:setIsVisible(isVisible)
    self.isVisible = isVisible
    return self
end
function DebugElement:setVisbileWhenGUIOpen(isVisible)
    self.hideWhenGuiIsOpen = not isVisible
    return self
end
function DebugElement:setClipDistance(clipDistance)
    self.clipDistance = clipDistance
    return self
end
function DebugElement:setIsSolid(isSolid)
    self.solid = isSolid
    return self
end