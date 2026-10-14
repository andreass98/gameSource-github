SavegameConflictDialog = {}
local SavegameConflictDialog_mt = Class(SavegameConflictDialog, MessageDialog)
function SavegameConflictDialog.register()
    local savegameConflictDialog = SavegameConflictDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/SavegameConflictDialog.xml", "SavegameConflictDialog", savegameConflictDialog)
    SavegameConflictDialog.INSTANCE = savegameConflictDialog
end
function SavegameConflictDialog.show(startCallback, savegameScreenCallback, savegame, savegameId, showKeepBoth)
    if SavegameConflictDialog.INSTANCE ~= nil then
        local dialog = SavegameConflictDialog.INSTANCE
        dialog:setFinishedCallback(startCallback, savegameScreenCallback)
        dialog:setSavegame(true, savegame)
        dialog:setCloudSavegame(savegame.conflictedMetadata)
        dialog:setSavegameId(savegameId)
        dialog:setShowKeepBoth(showKeepBoth == nil and true or showKeepBoth)
        g_gui:showDialog("SavegameConflictDialog")
    end
end
function SavegameConflictDialog.new(target, custom_mt)
    -- upvalues: (copy) SavegameConflictDialog_mt
    if custom_mt == nil then
        custom_mt = SavegameConflictDialog_mt
    end
    local self = ColorPickerDialog.new(target, custom_mt)
    self.savegameId = 1
    return self
end
function SavegameConflictDialog.createFromExistingGui(gui, _)
    SavegameConflictDialog.register()
    SavegameConflictDialog.show(gui.startCallback, gui.savegameScreenCallback, gui.savegame, gui.savegameId, gui.showKeepBoth)
end
function SavegameConflictDialog:setFinishedCallback(startCallback, savegameScreenCallback)
    self.startCallback = startCallback
    self.savegameScreenCallback = savegameScreenCallback
end
function SavegameConflictDialog:setLocalSavegame(metadata)
    self:setSavegame(true, (self:getSavegameFromMetadata(metadata)))
end
function SavegameConflictDialog:setCloudSavegame(metadata)
    self:setSavegame(false, (self:getSavegameFromMetadata(metadata)))
end
function SavegameConflictDialog.getSavegameFromMetadata(_, metadata)
    local savegame = FSCareerMissionInfo.new("", nil, 1)
    savegame:loadDefaults()
    if metadata ~= "" then
        local xmlFile = loadXMLFileFromMemory("careerSavegameXML", metadata)
        if xmlFile ~= nil then
            if not savegame:loadFromXML(xmlFile) then
                savegame:loadDefaults()
            end
            delete(xmlFile)
        end
    end
    return savegame
end
function SavegameConflictDialog:setSavegame(isLocal, savegame)
    if savegame ~= nil then
        local playTimeHoursF = savegame.playTime / 60 + 0.0001
        local playTimeHours = math.floor(playTimeHoursF)
        local timePlayed = (playTimeHoursF - playTimeHours) * 60
        local playTimeMinutes = math.floor(timePlayed)
        local timePlayed = string.format("%02d:%02d", playTimeHours, playTimeMinutes)
        if isLocal then
            self.local_gameName:setText(savegame.savegameName)
            self.local_money:setText(savegame.money)
            self.local_timePlayed:setText(timePlayed)
            self.local_createDate:setText(savegame.saveDateFormatted)
        else
            self.cloud_gameName:setText(savegame.savegameName)
            self.cloud_money:setText(savegame.money)
            self.cloud_timePlayed:setText(timePlayed)
            self.cloud_createDate:setText(savegame.saveDateFormatted)
        end
    end
    self.savegame = savegame
end
function SavegameConflictDialog:setSavegameId(savegameId)
    self.savegameId = savegameId
end
function SavegameConflictDialog:setShowKeepBoth(showKeepBoth)
    self.keepBoth:setDisabled(showKeepBoth ~= nil and not showKeepBoth and true or false)
    self.showKeepBoth = showKeepBoth
end
function SavegameConflictDialog:onClickKeepLocal()
    g_savegameController:resolveConflict(self.savegameId, SaveGameResolvePolicy.KEEP_LOCAL)
    self:close()
    if self.startCallback ~= nil then
        self.startCallback.callback(self.startCallback.target, unpack(self.startCallback.extraAttributes))
    end
end
function SavegameConflictDialog:onClickKeepRemote()
    g_savegameController:resolveConflict(self.savegameId, SaveGameResolvePolicy.KEEP_REMOTE)
    self:close()
    if self.startCallback ~= nil then
        self.startCallback.callback(self.startCallback.target, unpack(self.startCallback.extraAttributes))
    end
end
function SavegameConflictDialog:onClickKeepBoth()
    self:close()
    if g_savegameController:resolveConflict(self.savegameId, SaveGameResolvePolicy.KEEP_BOTH) and self.savegameScreenCallback ~= nil then
        self.savegameScreenCallback.callback(self.savegameScreenCallback.target, unpack(self.savegameScreenCallback.extraAttributes))
    end
end
SavegameConflictDialog.L10N_SYMBOL = {
    ["TITLE_CREATE_FARM"] = "ui_createNewFarm",
    ["TITLE_EDIT_FARM_TEMPLATE"] = "ui_editFarm",
    ["DEFAULT_FARM_NAME"] = "ui_defaultFarmName",
    ["BUTTON_CREATE"] = "button_mp_createFarm",
    ["BUTTON_CONFIRM"] = "button_confirm"
}