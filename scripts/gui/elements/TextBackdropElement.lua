TextBackdropElement = {}
local TextBackdropElement_mt = Class(TextBackdropElement, BitmapElement)
Gui.registerGuiElement("TextBackdrop", TextBackdropElement)
function TextBackdropElement.new(target, custom_mt)
    -- upvalues: (copy) TextBackdropElement_mt
    local self = BitmapElement.new(target, custom_mt or TextBackdropElement_mt)
    self.padding = {
        0,
        0,
        0,
        0
    }
    return self
end
function TextBackdropElement:loadFromXML(xmlFile, key)
    TextBackdropElement:superClass().loadFromXML(self, xmlFile, key)
    self.padding = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#padding"), self.padding)
end
function TextBackdropElement:loadProfile(profile, applyProfile)
    TextBackdropElement:superClass().loadProfile(self, profile, applyProfile)
    self.padding = GuiUtils.getNormalizedScreenValues(profile:getValue("padding"), self.padding)
end
function TextBackdropElement:copyAttributes(src)
    TextBackdropElement:superClass().copyAttributes(self, src)
    self.padding = table.clone(src.padding)
end
function TextBackdropElement:clone(parent, includeId, suppressOnCreate, blockFocusHandlingReload)
    local clonedElement = TextBackdropElement:superClass().clone(self, parent, includeId, suppressOnCreate, blockFocusHandlingReload)
    clonedElement:installTextElement()
    return clonedElement
end
function TextBackdropElement:onGuiSetupFinished()
    TextBackdropElement:superClass().onGuiSetupFinished(self)
    self:installTextElement()
end
function TextBackdropElement:installTextElement()
    assertWithCallstack(#self.elements > 0)
    self.textElement = self.elements[1]
    assertWithCallstack(self.textElement:isa(TextElement))
    self.textElement.setSize = Utils.overwrittenFunction(self.textElement.setSize, function(textElement, superFunc, width, height)
        -- upvalues: (copy) self
        superFunc(textElement, width, height)
        self:updateSizeAndContents(width * g_aspectScaleX)
    end)
    self:updateSizeAndContents(self.textElement.absSize[1])
end
function TextBackdropElement:updateSizeAndContents(textElementWidth)
    self:setSize(textElementWidth + self.padding[1] + self.padding[3], nil)
    self.elements[1]:setPosition(self.padding[1])
end