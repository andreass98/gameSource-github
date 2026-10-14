VoteDialog = {}
local VoteDialog_mt = Class(VoteDialog, MessageDialog)
function VoteDialog.register()
    local voteDialog = VoteDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/VoteDialog.xml", "VoteDialog", voteDialog)
    VoteDialog.INSTANCE = voteDialog
end
function VoteDialog.show(callback, target, value)
    if VoteDialog.INSTANCE ~= nil then
        local dialog = VoteDialog.INSTANCE
        dialog:setCallback(callback, target)
        dialog:setValue(value)
        g_gui:showDialog("VoteDialog")
    end
end
function VoteDialog.new(target, custom_mt)
    -- upvalues: (copy) VoteDialog_mt
    local self = MessageDialog.new(target, custom_mt or VoteDialog_mt)
    self.value = 0
    self.isBackAllowed = true
    self.inputDelay = 250
    return self
end
function VoteDialog.createFromExistingGui(gui, _)
    VoteDialog.register()
    VoteDialog.show(gui.callbackFunc, gui.target, gui.value)
end
function VoteDialog:onGuiSetupFinished()
    VoteDialog:superClass().onGuiSetupFinished(self)
    FocusManager:linkElements(self.stars[1], FocusManager.LEFT, nil)
end
function VoteDialog:onClickBack(_, _)
    self:close()
    if self.callback ~= nil then
        if self.target == nil then
            self.callback(self.args, nil)
        else
            self.callback(self.target, self.args, nil)
        end
    end
    return false
end
function VoteDialog:onClickOk()
    if self.value ~= 0 then
        if self.inputDelay >= self.time then
            return true
        end
        self:close()
        if self.callback ~= nil then
            if self.target == nil then
                self.callback(self.value)
            else
                self.callback(self.target, self.value)
            end
        end
        return false
    end
end
function VoteDialog:setCallback(callback, target)
    self.callback = callback
    self.target = target
end
function VoteDialog:setValue(value)
    self.value = value or 5
    self:setStars(self.value)
    self.okButton:setDisabled(value == 0)
    FocusManager:setFocus(self.stars[value])
end
function VoteDialog:onStarHighlight(element)
    self:setStars((self:getValueForElement(element)))
end
function VoteDialog:onStarHighlightRemove()
    self:setStars(self.value)
end
function VoteDialog:onStarFocus(element)
    self:setValue((self:getValueForElement(element)))
end
function VoteDialog:onStarClick(element)
    self:setValue(self:getValueForElement(element))
end
function VoteDialog:getValueForElement(element)
    for i, elem in ipairs(self.stars) do
        if element == elem then
            return i
        end
    end
    return nil
end
function VoteDialog:setStars(value)
    local i = 1
    for i = i, value do
        self.stars[i]:applyProfile("fs25_voteDialogStarButtonActive")
    end
    local i = value + 1
    for i = i, 5 do
        self.stars[i]:applyProfile("fs25_voteDialogStarButton")
    end
end