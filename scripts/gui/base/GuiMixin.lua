GuiMixin = {}
local GuiMixin_mt = Class(GuiMixin)
function GuiMixin.new(class, mixinType)
    -- upvalues: (copy) GuiMixin_mt
    if class == nil then
        class = GuiMixin_mt
    end
    if mixinType == nil then
        mixinType = GuiMixin
    end
    local self = setmetatable({}, class)
    self.mixinType = mixinType
    return self
end
function GuiMixin:addTo(guiElement)
    if guiElement[self.mixinType] then
        return false
    end
    guiElement[self.mixinType] = self
    guiElement.hasIncluded = self.hasIncluded
    return true
end
function GuiMixin.hasIncluded(guiElement, mixinType)
    return guiElement[mixinType] ~= nil
end
function GuiMixin.cloneMixin(mixinType, srcGuiElement, dstGuiElement)
    mixinType:clone(srcGuiElement, dstGuiElement)
end
function GuiMixin:clone(srcGuiElement, dstGuiElement) end