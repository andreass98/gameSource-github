OptionDialog = {}
local OptionDialog_mt = Class(OptionDialog, YesNoDialog)
function OptionDialog.register()
    local optionDialog = OptionDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/OptionDialog.xml", "OptionDialog", optionDialog)
    OptionDialog.INSTANCE = optionDialog
end
function OptionDialog.show(callback, text, title, options, defaultOptionIndex)
    if OptionDialog.INSTANCE ~= nil then
        local dialog = OptionDialog.INSTANCE
        dialog:setCallback(callback)
        dialog:setText(text)
        dialog:setTitle(title)
        dialog:setOptions(options, defaultOptionIndex)
        g_gui:showDialog("OptionDialog")
    end
end
function OptionDialog.new(target, custom_mt)
    -- upvalues: (copy) OptionDialog_mt
    return YesNoDialog.new(target, custom_mt or OptionDialog_mt)
end
function OptionDialog.createFromExistingGui(gui, _)
    OptionDialog.register()
    OptionDialog.show(gui.callbackFunc, gui.optionText, gui.optionTitle, gui.options)
end
function OptionDialog:onClickOk()
    if self.areButtonsDisabled then
        return true
    end
    self:sendCallback(self.optionElement:getState())
    return false
end
function OptionDialog:onClickBack(_, _)
    self:sendCallback(0)
    return false
end
function OptionDialog:setOptions(options, defaultOptionIndex)
    self.options = options
    self.optionElement:setTexts(options)
    self.optionElement:setState(defaultOptionIndex or 1)
end
function OptionDialog:setText(text)
    OptionDialog:superClass().setText(self, text)
    self.optionText = text
end
function OptionDialog:setTitle(title)
    OptionDialog:superClass().setTitle(self, title)
    self.optionTitle = title
end