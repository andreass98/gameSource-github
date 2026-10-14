ConnectionPendingDialog = {}
local ConnectionPendingDialog_mt = Class(ConnectionPendingDialog, MessageDialog)
function ConnectionPendingDialog.register()
    local connectionPendingDialog = ConnectionPendingDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/ConnectionPendingDialog.xml", "ConnectionPendingDialog", connectionPendingDialog)
    ConnectionPendingDialog.INSTANCE = connectionPendingDialog
    return connectionPendingDialog
end
function ConnectionPendingDialog.show(callback, target, text, dialogType, isCloseAllowed, callbackArgs)
    if ConnectionPendingDialog.INSTANCE ~= nil then
        local dialog = ConnectionPendingDialog.INSTANCE
        dialog:setDialogType(Utils.getNoNil(dialogType, DialogElement.TYPE_LOADING))
        dialog:setIsCloseAllowed(Utils.getNoNil(isCloseAllowed, true))
        dialog:setText(text)
        dialog:setUpdateCallback(callback, target, callbackArgs)
        g_gui:showDialog("ConnectionPendingDialog")
    end
end
function ConnectionPendingDialog.hide()
    g_gui:closeDialogByName("ConnectionPendingDialog")
end
function ConnectionPendingDialog.new(target, custom_mt)
    -- upvalues: (copy) ConnectionPendingDialog_mt
    return MessageDialog.new(target, custom_mt or ConnectionPendingDialog_mt)
end
function ConnectionPendingDialog:onClickCancel()
    ConnectionPendingDialog.hide()
    if g_gui.currentGuiName ~= "MainScreen" then
        g_gui:changeScreen(nil, MainScreen)
    end
end