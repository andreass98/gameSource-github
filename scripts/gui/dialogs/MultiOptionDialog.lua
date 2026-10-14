MultiOptionDialog = {}
MultiOptionDialog.ACTION = {
    ["BACK"] = 1,
    ["ACCEPT"] = 2,
    ["CANCEL"] = 3,
    ["ACTIVATE"] = 4
}
local MultiOptionDialog_mt = Class(MultiOptionDialog, MessageDialog)
function MultiOptionDialog.register()
    local multiOptionDialog = MultiOptionDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/MultiOptionDialog.xml", "MultiOptionDialog", multiOptionDialog)
    MultiOptionDialog.INSTANCE = multiOptionDialog
end
function MultiOptionDialog.show(callback, target, text, title, acceptText, backText, activateText, cancelText, dialogType, callbackArgs, disableOpenSound)
    if MultiOptionDialog.INSTANCE == nil then
        return nil
    end
    local dialog = MultiOptionDialog.INSTANCE
    dialog:setCallback(callback, target, callbackArgs)
    dialog:setDialogType(Utils.getNoNil(dialogType, DialogElement.TYPE_QUESTION))
    dialog:setButtonTexts(backText, acceptText, cancelText, activateText)
    dialog:setTitle(title)
    dialog:setText(text)
    dialog:setDisableOpenSound(disableOpenSound)
    g_gui:showDialog("MultiOptionDialog")
    return dialog
end
function MultiOptionDialog.new(target, custom_mt)
    -- upvalues: (copy) MultiOptionDialog_mt
    local self = MessageDialog.new(target, custom_mt or MultiOptionDialog_mt)
    self.isBackAllowed = false
    self.inputDelay = 250
    return self
end
function MultiOptionDialog.createFromExistingGui(gui, _)
    MultiOptionDialog.register()
    local title = gui.dialogTitleElement:getText()
    local text = gui.dialogTextElement:getText()
    local backText = gui.buttonBack ~= nil and gui.buttonBack:getText() or nil
    local acceptText = gui.buttonAccept ~= nil and gui.buttonAccept:getText() or nil
    local cancelText = gui.buttonCancel ~= nil and gui.buttonCancel:getText() or nil
    local activateText = gui.buttonActivate ~= nil and gui.buttonActivate:getText() or nil
    MultiOptionDialog.show(gui.callbackFunc, gui.target, text, title, backText, acceptText, cancelText, activateText, gui.dialogType, gui.callbackArgs)
end
function MultiOptionDialog:onCreate()
    MultiOptionDialog:superClass().onCreate(self)
    if self.dialogTextElement ~= nil then
        self.defaultTextStartPosY = self.dialogTextElement.position[2]
    end
    self:setDialogType(DialogElement.TYPE_QUESTION)
    if self.dialogTitleElement ~= nil then
        self.defaultTitle = self.dialogTitleElement.text
    end
    function self.buttonBox.invalidateLayout(buttonBox, ignoreVisibility, blockLayoutUpdate)
        -- upvalues: (copy) self
        BoxLayoutElement.invalidateLayout(buttonBox, ignoreVisibility, blockLayoutUpdate)
        local minWidth = math.max(self.dialogElement.absSize[1], self.buttonBox.maxFlowSize + 44 * g_pixelSizeScaledX)
        self.dialogElement:setSize(minWidth, nil)
    end
end
function MultiOptionDialog:onOpen()
    MultiOptionDialog:superClass().onOpen(self)
    self.inputDelay = self.time + 250
end
function MultiOptionDialog:onClose()
    self:setDialogType(DialogElement.TYPE_QUESTION)
    self:setTitle(nil)
    self:setText(nil)
    MultiOptionDialog:superClass().onClose(self)
end
function MultiOptionDialog:sendCallback(value)
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
function MultiOptionDialog:setCallback(callbackFunc, target, callbackArgs)
    self.callbackFunc = callbackFunc
    self.target = target
    self.callbackArgs = callbackArgs
end
function MultiOptionDialog:setTitle(text)
    if self.dialogTitleElement ~= nil then
        self.dialogTitleElement:setText(Utils.getNoNil(text, self.defaultTitle))
    end
    if Platform.isMobile and self.dialogTextElement ~= nil then
        local textHeight, _ = self.dialogTextElement:getTextHeight()
        self:resizeDialog(textHeight)
    end
end
function MultiOptionDialog:resizeDialog(heightOffset)
    local titleOffset = 0
    if Platform.isMobile then
        if self.dialogTitleElement ~= nil and self.dialogTitleElement.text ~= "" then
            local element = self.dialogTitleElement
            titleOffset = element.size[2] + element.margin[2] + element.margin[4]
        end
        if self.defaultTextStartPosY ~= nil then
            self.dialogTextElement:setPosition(nil, self.defaultTextStartPosY - titleOffset)
        end
    end
    MultiOptionDialog:superClass().resizeDialog(self, heightOffset + titleOffset)
end
function MultiOptionDialog:setButtonTexts(backText, acceptText, cancelText, activateText)
    local firstVisibleButton = nil
    self.buttonCancel:setVisible(cancelText ~= nil)
    if cancelText ~= nil then
        self.buttonCancel:setText(cancelText)
        firstVisibleButton = self.buttonCancel
        self.buttonActivate:getDescendantByName("separator"):setVisible(true)
    end
    self.buttonActivate:setVisible(activateText ~= nil)
    if activateText ~= nil then
        self.buttonActivate:setText(activateText)
        firstVisibleButton = self.buttonActivate
        self.buttonActivate:getDescendantByName("separator"):setVisible(true)
    end
    self.buttonBack:setVisible(backText ~= nil)
    if backText ~= nil then
        self.buttonBack:setText(backText)
        firstVisibleButton = self.buttonBack
        self.buttonBack:getDescendantByName("separator"):setVisible(true)
    end
    self.buttonAccept:setVisible(acceptText ~= nil)
    if acceptText ~= nil then
        self.buttonAccept:setText(acceptText)
        firstVisibleButton = self.buttonAccept
    end
    if firstVisibleButton ~= nil then
        firstVisibleButton:getDescendantByName("separator"):setVisible(false)
    end
end
function MultiOptionDialog:onBack(_)
    return self:sendCallback(MultiOptionDialog.ACTION.BACK)
end
function MultiOptionDialog:onAccept(_)
    return self:sendCallback(MultiOptionDialog.ACTION.ACCEPT)
end
function MultiOptionDialog:onCancel(_)
    return self:sendCallback(MultiOptionDialog.ACTION.CANCEL)
end
function MultiOptionDialog:onActivate()
    return self:sendCallback(MultiOptionDialog.ACTION.ACTIVATE)
end
function MultiOptionDialog:inputEvent(action, value, eventUsed)
    eventUsed = MultiOptionDialog:superClass().inputEvent(self, action, value, eventUsed)
    if Platform.isAndroid and (self.inputDisableTime <= 0 and action == InputAction.MENU_BACK) then
        self:onNo()
        eventUsed = true
    end
    return eventUsed
end