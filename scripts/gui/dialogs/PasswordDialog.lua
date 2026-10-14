PasswordDialog = {}
local PasswordDialog_mt = Class(PasswordDialog, TextInputDialog)
function PasswordDialog.register()
    local passwordDialog = PasswordDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/PasswordDialog.xml", "PasswordDialog", passwordDialog)
    PasswordDialog.INSTANCE = passwordDialog
end
function PasswordDialog.show(callback, target, callbackArgs, defaultPassword, confirmButtonText)
    if PasswordDialog.INSTANCE ~= nil then
        local dialog = PasswordDialog.INSTANCE
        dialog:setButtonTexts(confirmButtonText)
        dialog:setCallback(callback, target, defaultPassword, nil, nil, nil, callbackArgs, true)
        dialog:setText(nil)
        g_gui:showDialog("PasswordDialog")
    end
end
function PasswordDialog.new(target, custom_mt)
    -- upvalues: (copy) PasswordDialog_mt
    return TextInputDialog.new(target, custom_mt or PasswordDialog_mt)
end
function PasswordDialog.createFromExistingGui(gui, _)
    PasswordDialog.register()
    PasswordDialog.show(gui.onTextEntered, gui.target, gui.callbackArgs, gui.defaultText, gui.confirmText)
end