MessageDialog = {}
local MessageDialog_mt = Class(MessageDialog, DialogElement)
function MessageDialog.register()
    local messageDialog = MessageDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/MessageDialog.xml", "MessageDialog", messageDialog)
    MessageDialog.INSTANCE = messageDialog
    return messageDialog
end
function MessageDialog.show(text, callback, target, dialogType, isCloseAllowed, callbackArgs)
    if MessageDialog.INSTANCE ~= nil then
        local dialog = MessageDialog.INSTANCE
        dialog:setDialogType(Utils.getNoNil(dialogType, DialogElement.TYPE_LOADING))
        dialog:setIsCloseAllowed(Utils.getNoNil(isCloseAllowed, true))
        dialog:setText(text)
        dialog:setUpdateCallback(callback, target, callbackArgs)
        g_gui:showDialog("MessageDialog")
    end
end
function MessageDialog.hide()
    g_gui:closeDialogByName("MessageDialog")
end
function MessageDialog.new(target, custom_mt)
    -- upvalues: (copy) MessageDialog_mt
    local self = DialogElement.new(target, custom_mt or MessageDialog_mt)
    self.defaultDialogHeight = 0
    self.isBackAllowed = false
    return self
end
function MessageDialog.createFromExistingGui(gui, guiName)
    local newGui = MessageDialog.new()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    MessageDialog.show(gui.messageText, gui.updateCallback, gui.updateCallbackTarget, gui.dialogType, gui.isCloseAllowed)
    return newGui
end
function MessageDialog:onCreate(_)
    if self.dialogElement ~= nil then
        self.defaultDialogHeight = self.dialogElement.size[2]
    end
    if self.dialogTextElement ~= nil then
        local defaultTextHeight, _ = self.dialogTextElement:getTextHeight()
        self.defaultDialogHeight = self.defaultDialogHeight - defaultTextHeight
        self.defaultText = self.dialogTextElement.text
    end
    self:setDialogType(DialogElement.TYPE_WARNING)
end
function MessageDialog:onOpen()
    MessageDialog:superClass().onOpen(self)
    self.isOpen = true
    if not self.disableOpenSound then
        if self.dialogType == DialogElement.TYPE_WARNING then
            self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
        elseif self.dialogType ~= DialogElement.TYPE_LOADING then
            self:playSample(GuiSoundPlayer.SOUND_SAMPLES.QUERY)
        end
    end
    if self.dialogBg ~= nil then
        if g_gui:getIsMenuVisible() then
            self.dialogBg:applyProfile("dialogFullscreenBgWithMenu", true)
        else
            self.dialogBg:applyProfile("dialogFullscreenBgNoMenu", true)
        end
    end
    if self.dialogElement ~= nil then
        if g_gui:getIsMenuVisible() then
            self.dialogElement:applyProfile("dialogElementWithMenu", true)
            return
        end
        self.dialogElement:applyProfile("dialogElementNoMenu", true)
    end
end
function MessageDialog:onClose()
    MessageDialog:superClass().onClose(self)
    self.isOpen = false
end
function MessageDialog:setText(text)
    if self.dialogTextElement ~= nil then
        self.dialogTextElement:setText(Utils.getNoNil(text, self.defaultText))
        local textHeight, _ = self.dialogTextElement:getTextHeight()
        self:resizeDialog(textHeight)
    end
end
function MessageDialog:setDisableOpenSound(disableOpenSound)
    if disableOpenSound == nil or not disableOpenSound then
        disableOpenSound = false
    end
    self.disableOpenSound = disableOpenSound
end
function MessageDialog.getIsOpen()
    if MessageDialog.INSTANCE == nil then
        return false
    else
        return MessageDialog.INSTANCE.isOpen
    end
end
function MessageDialog:resizeDialog(heightOffset)
    if self.dialogElement ~= nil then
        self.dialogElement:setSize(nil, self.defaultDialogHeight + heightOffset)
    end
end
function MessageDialog:setUpdateCallback(callback, callbackTarget, args)
    self.updateCallback = callback
    self.updateCallbackTarget = callbackTarget
    self.updateCallbackArgs = args
end
function MessageDialog:update(dt)
    MessageDialog:superClass().update(self, dt)
    if self.updateCallback ~= nil then
        if self.updateCallbackTarget ~= nil then
            self.updateCallback(self.updateCallbackTarget, dt, self.updateCallbackArgs)
            return
        end
        self.updateCallback(dt, self.updateCallbackArgs)
    end
end