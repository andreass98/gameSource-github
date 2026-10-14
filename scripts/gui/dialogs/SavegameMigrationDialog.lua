SavegameMigrationDialog = {}
local SavegameMigrationDialog_mt = Class(SavegameMigrationDialog, YesNoDialog)
function SavegameMigrationDialog.register()
    local savegameMigrationDialog = SavegameMigrationDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/SavegameMigrationDialog.xml", "SavegameMigrationDialog", savegameMigrationDialog)
    SavegameMigrationDialog.INSTANCE = savegameMigrationDialog
end
function SavegameMigrationDialog.show(callback, target)
    if SavegameMigrationDialog.INSTANCE ~= nil then
        SavegameMigrationDialog.INSTANCE:setCallback(callback, target)
        g_gui:showDialog("SavegameMigrationDialog")
    end
end
function SavegameMigrationDialog.new(target, custom_mt)
    -- upvalues: (copy) SavegameMigrationDialog_mt
    return TextInputDialog.new(target, custom_mt or SavegameMigrationDialog_mt)
end
function SavegameMigrationDialog.createFromExistingGui(gui, _)
    SavegameMigrationDialog.register()
    SavegameMigrationDialog.show(gui.callback, gui.target)
end