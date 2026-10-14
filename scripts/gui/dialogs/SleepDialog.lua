SleepDialog = {}
SleepDialog.MIN_TARGET_TIME = 0
SleepDialog.MAX_TARGET_TIME = 23.5
SleepDialog.DEFAULT_TARGET_TIME = 16
local SleepDialog_mt = Class(SleepDialog, YesNoDialog)
function SleepDialog.register()
    local sleepDialog = SleepDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/SleepDialog.xml", "SleepDialog", sleepDialog)
    SleepDialog.INSTANCE = sleepDialog
end
function SleepDialog.show(text, callback, target)
    if SleepDialog.INSTANCE ~= nil then
        local dialog = SleepDialog.INSTANCE
        dialog:setCallback(callback, target)
        dialog:setTitle(g_i18n:getText("ui_inGameSleep"))
        dialog:setText(text)
        g_gui:showDialog("SleepDialog")
    end
end
function SleepDialog.new(target, custom_mt)
    -- upvalues: (copy) SleepDialog_mt
    local self = YesNoDialog.new(target, custom_mt or SleepDialog_mt)
    self.selectedTargetTime = SleepDialog.DEFAULT_TARGET_TIME
    self.maxDuration = SleepDialog.DEFAULT_MAX_DURATION
    return self
end
function SleepDialog.createFromExistingGui(gui, _)
    SleepDialog.register()
    SleepDialog.show(gui.sleepText, gui.callbackFunc, gui.target)
end
function SleepDialog:onOpen()
    SleepDialog:superClass().onOpen(self)
    self:updateOptions()
end
function SleepDialog:onClose()
    SleepDialog:superClass().onClose(self)
    self:setDialogType(DialogElement.TYPE_QUESTION)
    self:setTitle(nil)
    self:setText(nil)
    self:setButtonTexts(self.defaultYesText, self.defaultNoText)
end
function SleepDialog:sendCallback(value)
    if self.inputDelay >= self.time then
        return true
    end
    self:close()
    if self.callbackFunc ~= nil then
        if self.target == nil then
            self.callbackFunc(value, self.selectedTargetTime)
        else
            self.callbackFunc(self.target, value, self.selectedTargetTime * 0.5)
        end
    end
    return false
end
function SleepDialog:updateOptions()
    self.targetTimes = {}
    local i = SleepDialog.MIN_TARGET_TIME
    for i = i, SleepDialog.MAX_TARGET_TIME, 0.5 do
        table.insert(self.targetTimes, Utils.formatTime(i * 60))
    end
    self.targetTimeElement:setTexts(self.targetTimes)
    self.targetTimeElement:setState(self.selectedTargetTime - SleepDialog.MIN_TARGET_TIME + 1)
end
function SleepDialog:onClickTargetTime(state)
    self.selectedTargetTime = state - 1 + SleepDialog.MIN_TARGET_TIME
end