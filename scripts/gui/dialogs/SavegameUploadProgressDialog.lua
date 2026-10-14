SavegameUploadProgressDialog = {}
local SavegameUploadProgressDialog_mt = Class(SavegameUploadProgressDialog, DialogElement)
function SavegameUploadProgressDialog.register()
    local savegameUploadProgressDialog = SavegameUploadProgressDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/SavegameUploadProgressDialog.xml", "SavegameUploadProgressDialog", savegameUploadProgressDialog)
    SavegameUploadProgressDialog.INSTANCE = savegameUploadProgressDialog
    return savegameUploadProgressDialog
end
function SavegameUploadProgressDialog.show(progress)
    if SavegameUploadProgressDialog.INSTANCE ~= nil then
        local dialog = SavegameUploadProgressDialog.INSTANCE
        dialog:setDialogType(DialogElement.TYPE_LOADING)
        dialog:setIsCloseAllowed(false)
        dialog:setProgress(progress or 0)
        g_gui:showDialog("SavegameUploadProgressDialog")
    end
end
function SavegameUploadProgressDialog.hide()
    g_gui:closeDialogByName("SavegameUploadProgressDialog")
end
function SavegameUploadProgressDialog.new(target, custom_mt)
    -- upvalues: (copy) SavegameUploadProgressDialog_mt
    return DialogElement.new(target, custom_mt or SavegameUploadProgressDialog_mt)
end
function SavegameUploadProgressDialog.createFromExistingGui(gui, guiName)
    local newGui = SavegameUploadProgressDialog.new()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    SavegameUploadProgressDialog.show(gui.messageText, gui.progress, gui.dialogType, gui.isCloseAllowed)
    return newGui
end
function SavegameUploadProgressDialog:onCreate(_)
    self:setDialogType(DialogElement.TYPE_LOADING)
end
function SavegameUploadProgressDialog:onOpen()
    SavegameUploadProgressDialog:superClass().onOpen(self)
    SavegameUploadProgressDialog.INSTANCE.isOpen = true
    if not self.disableOpenSound and self.dialogType ~= DialogElement.TYPE_LOADING then
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.QUERY)
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
function SavegameUploadProgressDialog:onClose()
    SavegameUploadProgressDialog:superClass().onClose(self)
    SavegameUploadProgressDialog.INSTANCE.isOpen = false
end
function SavegameUploadProgressDialog:setText(text)
    if self.dialogTextElement ~= nil then
        self.dialogTextElement:setText(Utils.getNoNil(text, self.defaultText))
    end
end
function SavegameUploadProgressDialog.getIsOpen()
    if SavegameUploadProgressDialog.INSTANCE == nil then
        return false
    else
        return SavegameUploadProgressDialog.INSTANCE.isOpen
    end
end
function SavegameUploadProgressDialog:setProgress(progress)
    self.progress = progress
    self.progressElement:setText(string.format("%d%%", progress))
end