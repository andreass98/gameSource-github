SavegameUploadDialog = {}
local SavegameUploadDialog_mt = Class(SavegameUploadDialog, TextInputDialog)
function SavegameUploadDialog.register()
    local savegameUploadDialog = SavegameUploadDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/SavegameUploadDialog.xml", "SavegameUploadDialog", savegameUploadDialog)
    SavegameUploadDialog.INSTANCE = savegameUploadDialog
end
function SavegameUploadDialog.show(callback, target, defaultText, dialogPrompt, imePrompt, maxCharacters, confirmText, callbackArgs, text, applyTextFilter)
    if SavegameUploadDialog.INSTANCE ~= nil then
        local dialog = SavegameUploadDialog.INSTANCE
        dialog:setButtonTexts(confirmText)
        dialog:setText(text)
        dialog:setCallback(callback, target, defaultText, dialogPrompt, imePrompt, maxCharacters, callbackArgs, applyTextFilter)
        g_gui:showDialog("SavegameUploadDialog")
    end
end
function SavegameUploadDialog.new(target, custom_mt)
    -- upvalues: (copy) SavegameUploadDialog_mt
    return TextInputDialog.new(target, custom_mt or SavegameUploadDialog_mt)
end
function SavegameUploadDialog.createFromExistingGui(gui, _)
    SavegameUploadDialog.register()
    SavegameUploadDialog.show(gui.onTextEntered, gui.target, gui.defaultText, gui.dialogPrompt, gui.imePrompt, gui.maxCharacters, gui.confirmText, gui.callbackArgs, gui.inputText, gui.applyTextFilter)
end