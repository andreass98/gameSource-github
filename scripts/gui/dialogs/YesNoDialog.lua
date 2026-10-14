YesNoDialog = {}
local YesNoDialog_mt = Class(YesNoDialog, MessageDialog)
function YesNoDialog.register()
    local yesNoDialog = YesNoDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/YesNoDialog.xml", "YesNoDialog", yesNoDialog)
    YesNoDialog.INSTANCE = yesNoDialog
end
function YesNoDialog.show(callback, target, text, title, yesText, noText, dialogType, yesSound, noSound, callbackArgs, disableOpenSound)
    if YesNoDialog.INSTANCE == nil then
        return nil
    end
    local dialog = YesNoDialog.INSTANCE
    dialog:setCallback(callback, target, callbackArgs)
    dialog:setDialogType(Utils.getNoNil(dialogType, DialogElement.TYPE_QUESTION))
    dialog:setButtonTexts(yesText, noText)
    dialog:setButtonSounds(yesSound, noSound)
    dialog:setTitle(title)
    dialog:setText(text)
    dialog:setDisableOpenSound(disableOpenSound)
    g_gui:showDialog("YesNoDialog")
    return dialog
end
function YesNoDialog.new(target, custom_mt)
    -- upvalues: (copy) YesNoDialog_mt
    local self = MessageDialog.new(target, custom_mt or YesNoDialog_mt)
    self.isBackAllowed = false
    self.inputDelay = 250
    return self
end
function YesNoDialog.cancel()
    local dialog = YesNoDialog.INSTANCE
    if dialog.isOpen then
        dialog:onNo()
    end
end
function YesNoDialog.createFromExistingGui(gui, _)
    YesNoDialog.register()
    local yesText = gui.yesButton.yesText
    if gui.yesButton.textSeparator ~= nil and yesText ~= nil then
        yesText = string.gsub(yesText, gui.yesButton.textSeparator, "", 1)
    end
    local noText = gui.noButton.noText
    if gui.noButton.textSeparator ~= nil and noText ~= nil then
        noText = string.gsub(noText, gui.noButton.textSeparator, "", 1)
    end
    YesNoDialog.show(gui.callbackFunc, gui.target, gui.yesNoText, gui.yesNoTitle, yesText, noText, gui.dialogType, gui.yesButton.clickSoundName, gui.noButton.clickSoundName, gui.callbackArgs)
end
function YesNoDialog:onCreate()
    YesNoDialog:superClass().onCreate(self)
    if self.dialogTextElement ~= nil then
        self.defaultTextStartPosY = self.dialogTextElement.position[2]
    end
    self:setDialogType(DialogElement.TYPE_QUESTION)
    if self.dialogTitleElement ~= nil then
        self.defaultTitle = self.dialogTitleElement.text
    end
    self.defaultYesText = self.yesButton.text
    if self.yesButton.textSeparator ~= nil then
        self.defaultYesText = string.gsub(self.defaultYesText, self.yesButton.textSeparator, "", 1)
    end
    self.defaultNoText = self.noButton.text
    if self.noButton.textSeparator ~= nil then
        self.defaultNoText = string.gsub(self.defaultNoText, self.noButton.textSeparator, "", 1)
    end
end
function YesNoDialog:onOpen()
    YesNoDialog:superClass().onOpen(self)
    self.inputDelay = self.time + 250
end
function YesNoDialog:onClose()
    self:setDialogType(DialogElement.TYPE_QUESTION)
    self:setTitle(nil)
    self:setText(nil)
    self:setButtonTexts(self.defaultYesText, self.defaultNoText)
    YesNoDialog:superClass().onClose(self)
end
function YesNoDialog:sendCallback(value)
    if self.inputDelay >= self.time then
        return true
    end
    self:close()
    if self.callbackFunc ~= nil then
        if self.target == nil then
            self.callbackFunc(value, self.callbackArgs)
        else
            self.callbackFunc(self.target, value, self.callbackArgs)
        end
    end
    return false
end
function YesNoDialog:setCallback(callbackFunc, target, callbackArgs)
    self.callbackFunc = callbackFunc
    self.target = target
    self.callbackArgs = callbackArgs
end
function YesNoDialog:setTitle(text)
    if self.dialogTitleElement ~= nil then
        self.dialogTitleElement:setText(Utils.getNoNil(text, self.defaultTitle))
    end
    if GS_IS_MOBILE_VERSION and self.dialogTextElement ~= nil then
        local textHeight, _ = self.dialogTextElement:getTextHeight()
        self:resizeDialog(textHeight)
    end
end
function YesNoDialog:resizeDialog(heightOffset)
    local titleOffset = 0
    if GS_IS_MOBILE_VERSION then
        if self.dialogTitleElement ~= nil and self.dialogTitleElement.text ~= "" then
            local element = self.dialogTitleElement
            titleOffset = element.size[2] + element.margin[2] + element.margin[4]
        end
        if self.defaultTextStartPosY ~= nil then
            self.dialogTextElement:setPosition(nil, self.defaultTextStartPosY - titleOffset)
        end
    end
    YesNoDialog:superClass().resizeDialog(self, heightOffset + titleOffset)
end
function YesNoDialog:setButtonTexts(yesText, noText)
    self.yesButton:setText(Utils.getNoNil(yesText, self.defaultYesText))
    self.noButton:setText(Utils.getNoNil(noText, self.defaultNoText))
end
function YesNoDialog:setButtonSounds(yesSound, noSound)
    self.yesButton.clickSoundName = Utils.getNoNil(yesSound, self.yesButton.clickSoundName)
    self.noButton.clickSoundName = Utils.getNoNil(noSound, self.noButton.clickSoundName)
end
function YesNoDialog:onYes(_)
    return self:sendCallback(true)
end
function YesNoDialog:onNo(_)
    return self:sendCallback(false)
end
function YesNoDialog:inputEvent(action, value, eventUsed)
    eventUsed = YesNoDialog:superClass().inputEvent(self, action, value, eventUsed)
    if Platform.isAndroid and (self.inputDisableTime <= 0 and action == InputAction.MENU_BACK) then
        self:onNo()
        eventUsed = true
    end
    return eventUsed
end