DenyAcceptDialog = {}
local DenyAcceptDialog_mt = Class(DenyAcceptDialog, YesNoDialog)
function DenyAcceptDialog.register()
    local denyAcceptDialog = DenyAcceptDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/DenyAcceptDialog.xml", "DenyAcceptDialog", denyAcceptDialog)
    DenyAcceptDialog.INSTANCE = denyAcceptDialog
end
function DenyAcceptDialog.show(callback, target, connection, nickname, platformId, splitShapesWithinLimits)
    if DenyAcceptDialog.INSTANCE ~= nil then
        local dialog = DenyAcceptDialog.INSTANCE
        dialog:setCallback(callback, target)
        dialog:setConnection(connection, nickname, platformId, splitShapesWithinLimits)
        g_gui:showDialog("DenyAcceptDialog")
    end
end
function DenyAcceptDialog.new(target, custom_mt)
    -- upvalues: (copy) DenyAcceptDialog_mt
    return YesNoDialog.new(target, custom_mt or DenyAcceptDialog_mt)
end
function DenyAcceptDialog.createFromExistingGui(gui, guiName)
    local newGui = DenyAcceptDialog.new(nil, nil)
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    DenyAcceptDialog.show(gui.callbackFunc, gui.target, gui.connection, gui.nickname, gui.platformId, gui.splitShapesWithinLimits)
    return newGui
end
function DenyAcceptDialog:sendCallback(isDenied, isAlwaysDenied)
    if self.inputDelay >= self.time then
        return true
    end
    self:close()
    if self.callbackFunc ~= nil then
        if self.target == nil then
            self.callbackFunc(self.connection, isDenied, isAlwaysDenied)
        else
            self.callbackFunc(self.target, self.connection, isDenied, isAlwaysDenied)
        end
    end
    return false
end
function DenyAcceptDialog:onClickAccept()
    self:sendCallback(false, false)
    return false
end
function DenyAcceptDialog:onClickBack(_)
    self:onClickRefuse()
end
function DenyAcceptDialog:onClickRefuse(_)
    self:sendCallback(true, false)
    return false
end
function DenyAcceptDialog:onClickDenyAlways()
    self:sendCallback(true, true)
    return false
end
function DenyAcceptDialog:setConnection(connection, nickname, platformId, splitShapesWithinLimits)
    if connection ~= nil then
        self.connection = connection
    end
    self:setTitle(nickname)
    self.platformIcon:setPlatformId(platformId)
    self.platformIcon.parent:invalidateLayout()
    self.dialogWarning:setVisible(not splitShapesWithinLimits)
    self.nickname = nickname
    self.platformId = platformId
    self.splitShapesWithinLimits = splitShapesWithinLimits
end