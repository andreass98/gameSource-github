CheckedOptionElement = {}
CheckedOptionElement.STATE_UNCHECKED = 1
CheckedOptionElement.STATE_CHECKED = 2
local CheckedOptionElement_mt = Class(CheckedOptionElement, MultiTextOptionElement)
Gui.registerGuiElement("CheckedOption", CheckedOptionElement)
Gui.registerGuiElementProcFunction("CheckedOption", Gui.assignPlaySampleCallback)
function CheckedOptionElement.new(target, custom_mt)
    -- upvalues: (copy) CheckedOptionElement_mt
    return MultiTextOptionElement.new(target, custom_mt or CheckedOptionElement_mt)
end
function CheckedOptionElement:addElement(element)
    CheckedOptionElement:superClass().addElement(self, element)
    if #self.elements == 3 then
        self:setTexts({ g_i18n:getText("ui_off"), g_i18n:getText("ui_on") })
        self:setIsChecked(self.isChecked)
    end
end
function CheckedOptionElement:getIsChecked()
    return self.state == CheckedOptionElement.STATE_CHECKED
end
function CheckedOptionElement:setIsChecked(isChecked)
    if isChecked then
        self:setState(CheckedOptionElement.STATE_CHECKED)
    else
        self:setState(CheckedOptionElement.STATE_UNCHECKED)
    end
end