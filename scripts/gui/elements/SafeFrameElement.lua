SafeFrameElement = {}
local SafeFrameElement_mt = Class(SafeFrameElement, GuiElement)
Gui.registerGuiElement("SafeFrame", SafeFrameElement)
function SafeFrameElement.new(target, custom_mt)
    -- upvalues: (copy) SafeFrameElement_mt
    local self = GuiElement.new(target, custom_mt or SafeFrameElement_mt)
    self.name = "safeFrame"
    return self
end
function SafeFrameElement:draw()
    drawFilledRect(0, 0, 1, 1, 0, 0, 0, 1)
end