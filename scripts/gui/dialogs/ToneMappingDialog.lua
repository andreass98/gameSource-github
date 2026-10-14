ToneMappingDialog = {}
local ToneMappingDialog_mt = Class(ToneMappingDialog, DialogElement)
function ToneMappingDialog.register()
    local toneMappingDialog = ToneMappingDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/ToneMappingDialog.xml", "ToneMappingDialog", toneMappingDialog)
    ToneMappingDialog.INSTANCE = toneMappingDialog
end
function ToneMappingDialog.show()
    if ToneMappingDialog.INSTANCE ~= nil then
        g_gui:showDialog("ToneMappingDialog")
    end
end
function ToneMappingDialog.new(target, custom_mt)
    -- upvalues: (copy) ToneMappingDialog_mt
    local self = MessageDialog.new(target, custom_mt or ToneMappingDialog_mt)
    self.isBackAllowed = false
    self.inputDelay = 250
    self.optionTexts = {}
    local i = 0
    for i = i, 1.001, 0.01 do
        table.insert(self.optionTexts, string.format("%.2f", i))
    end
    addConsoleCommand("gsToneMapping", "Toggle Tone Mapping dialog visibility", "consoleCommandToneMapping", self)
    return self
end
function ToneMappingDialog.createFromExistingGui(gui, guiName)
    ToneMappingDialog.register()
    ToneMappingDialog.show()
end
function ToneMappingDialog:onGuiSetupFinished()
    ToneMappingDialog:superClass().onGuiSetupFinished(self)
    self.optionSlope:setTexts(self.optionTexts)
    self.optionToe:setTexts(self.optionTexts)
    self.optionShoulder:setTexts(self.optionTexts)
    self.optionBlackClip:setTexts(self.optionTexts)
    self.optionWhiteClip:setTexts(self.optionTexts)
end
function ToneMappingDialog:onOpen()
    ToneMappingDialog:superClass().onOpen(self)
    self.inputDelay = self.time + 250
    self.optionSlope:setState(math.round(getToneMappingCurveSlope() * 100) + 1)
    self.optionToe:setState(math.round(getToneMappingCurveToe() * 100) + 1)
    self.optionShoulder:setState(math.round(getToneMappingCurveShoulder() * 100) + 1)
    self.optionBlackClip:setState(math.round(getToneMappingCurveBlackClip() * 100) + 1)
    self.optionWhiteClip:setState(math.round(getToneMappingCurveWhiteClip() * 100) + 1)
end
function ToneMappingDialog.onClickSlope(_, state)
    setToneMappingCurveSlope((state - 1) / 100)
end
function ToneMappingDialog.onClickToe(_, state)
    setToneMappingCurveToe((state - 1) / 100)
end
function ToneMappingDialog.onClickShoulder(_, state)
    setToneMappingCurveShoulder((state - 1) / 100)
end
function ToneMappingDialog.onClickBlackClip(_, state)
    setToneMappingCurveBlackClip((state - 1) / 100)
end
function ToneMappingDialog.onClickWhiteClip(_, state)
    setToneMappingCurveWhiteClip((state - 1) / 100)
end
function ToneMappingDialog:consoleCommandToneMapping()
    if self.isOpen then
        g_gui:closeDialogByName("ToneMappingDialog")
        Logging.info("Closed Tone Mapping dialog")
    else
        self:show()
        Logging.info("Opened Tone Mapping dialog")
    end
end