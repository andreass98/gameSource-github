TextInputDialog = {}
local TextInputDialog_mt = Class(TextInputDialog, YesNoDialog)
local function NO_CALLBACK() end
function TextInputDialog.register()
    local textInputDialog = TextInputDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/TextInputDialog.xml", "TextInputDialog", textInputDialog)
    TextInputDialog.INSTANCE = textInputDialog
end
function TextInputDialog.show(callback, target, defaultText, dialogPrompt, imePrompt, maxCharacters, confirmText, callbackArgs, text, applyTextFilter)
    if TextInputDialog.INSTANCE ~= nil then
        local dialog = TextInputDialog.INSTANCE
        dialog:setText(text)
        dialog:setCallback(callback, target, defaultText, dialogPrompt, imePrompt, maxCharacters, callbackArgs, applyTextFilter)
        dialog:setButtonTexts(confirmText)
        g_gui:showDialog("TextInputDialog")
    end
end
function TextInputDialog.new(target, custom_mt)
    -- upvalues: (copy) TextInputDialog_mt, (copy) NO_CALLBACK
    local self = YesNoDialog.new(target, custom_mt or TextInputDialog_mt)
    self.onTextEntered = NO_CALLBACK
    self.callbackArgs = nil
    self.extraInputDisableTime = 0
    self.doHide = GS_IS_CONSOLE_VERSION and imeIsSupported()
    self.disableOpenSound = true
    return self
end
function TextInputDialog.createFromExistingGui(gui, _)
    TextInputDialog.register()
    TextInputDialog.show(gui.onTextEntered, gui.target, gui.defaultText, gui.dialogPrompt, gui.imePrompt, gui.maxCharacters, gui.confirmText, gui.callbackArgs, gui.inputText, gui.applyTextFilter)
end
function TextInputDialog:onOpen()
    TextInputDialog:superClass().onOpen(self)
    self.extraInputDisableTime = getPlatformId() == PlatformId.SWITCH and 0 or 100
    FocusManager:setFocus(self.textElement)
    self.textElement.blockTime = 0
    self.textElement:onFocusActivate()
    self:updateButtonVisibility()
end
function TextInputDialog:onClose()
    TextInputDialog:superClass().onClose(self)
    if not GS_IS_CONSOLE_VERSION then
        self.textElement:setForcePressed(false)
    end
    self:updateButtonVisibility()
end
function TextInputDialog:setText(text)
    TextInputDialog:superClass().setText(self, text)
    self.inputText = text
end
function TextInputDialog:setButtonTexts(yesText, noText)
    TextInputDialog:superClass().setButtonTexts(self, yesText, noText)
    self.confirmText = yesText
end
function TextInputDialog:setCallback(onTextEntered, target, defaultInputText, dialogPrompt, imePrompt, maxCharacters, callbackArgs, applyTextFilter)
    -- upvalues: (copy) NO_CALLBACK
    self.onTextEntered = onTextEntered or NO_CALLBACK
    self.target = target
    self.callbackArgs = callbackArgs
    self.textElement:setText(defaultInputText or "")
    self.textElement.maxCharacters = maxCharacters or self.textElement.maxCharacters
    self.applyTextFilter = Utils.getNoNil(applyTextFilter, true)
    if dialogPrompt ~= nil then
        self.dialogTextElement:setText(dialogPrompt)
    end
    if imePrompt ~= nil then
        self.textElement.applyProfanityFilter = self.applyTextFilter
        self.textElement.imeTitle = imePrompt
        self.textElement.imeDescription = ""
        self.textElement.imePlaceholder = ""
    end
    self.dialogPrompt = dialogPrompt
    self.imePrompt = imePrompt
    self.maxCharacters = maxCharacters
end
function TextInputDialog:sendCallback(clickOk)
    self:close()
    if self.target == nil then
        self.onTextEntered(self.textElement.text, clickOk, self.callbackArgs)
    else
        self.onTextEntered(self.target, text, clickOk, self.callbackArgs)
    end
end
function TextInputDialog:onEnterPressed(_, dismissal)
    return dismissal and true or self:onClickOk()
end
function TextInputDialog:onEscPressed(_)
    return self:onClickBack()
end
function TextInputDialog:onClickBack(_, _)
    if self:isInputDisabled() then
        return true
    end
    self:sendCallback(false)
    return false
end
function TextInputDialog:onClickOk()
    if self:isInputDisabled() then
        return true
    end
    if self.applyTextFilter and not self.textElement.isPassword then
        local baseText = self.textElement.text
        local filteredText = filterText(baseText, true, true)
        if baseText ~= "" and baseText ~= filteredText then
            self.textElement:setText(filteredText)
            Logging.info("Entered text contains profanity and has been adjusted.")
            self.reactivateNextFrame = true
            self:updateButtonVisibility()
            return false
        end
    end
    self:sendCallback(true)
    self:updateButtonVisibility()
    return false
end
function TextInputDialog:updateButtonVisibility()
    if self.yesButton ~= nil then
        self.yesButton:setVisible(not self.textElement.imeActive)
    end
    if self.noButton ~= nil then
        self.noButton:setVisible(not self.textElement.imeActive)
    end
end
function TextInputDialog:update(dt)
    TextInputDialog:superClass().update(self, dt)
    if self.reactivateNextFrame then
        self.textElement.blockTime = 0
        self.textElement:onFocusActivate()
        self.reactivateNextFrame = false
        self:updateButtonVisibility()
    end
    if self.extraInputDisableTime > 0 then
        self.extraInputDisableTime = self.extraInputDisableTime - dt
    end
end
function TextInputDialog:isInputDisabled()
    return self.extraInputDisableTime > 0 and not self.doHide
end
function TextInputDialog:disableInputForDuration(duration) end
function TextInputDialog:getIsVisible()
    if self.doHide then
        return false
    else
        return TextInputDialog:superClass().getIsVisible(self)
    end
end