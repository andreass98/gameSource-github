SoilSampleYesNoDialog = {}
SoilSampleYesNoDialog.MOD_NAME = g_currentModName
SoilSampleYesNoDialog.MOD_DIR = g_currentModDirectory
local SoilSampleYesNoDialog_mt = Class(SoilSampleYesNoDialog, YesNoDialog)
function SoilSampleYesNoDialog.register()
    local soilSampleYesNoDialog = SoilSampleYesNoDialog.new()
    g_gui:loadGui(SoilSampleYesNoDialog.MOD_DIR .. "gui/SoilSampleYesNoDialog.xml", "SoilSampleYesNoDialog", soilSampleYesNoDialog)
    SoilSampleYesNoDialog.INSTANCE = soilSampleYesNoDialog
end
function SoilSampleYesNoDialog.new(target, custom_mt)
    -- upvalues: (copy) SoilSampleYesNoDialog_mt
    local self = SoilSampleYesNoDialog:superClass().new(target, custom_mt or SoilSampleYesNoDialog_mt)
    self.farmlandId = 0
    self.fieldSize = 0
    self.numSamples = 0
    self.sampleCosts = 0
    self.serviceCosts = 0
    return self
end
function SoilSampleYesNoDialog:setData(farmlandId, fieldSize, numSamples, sampleCost, serviceCost)
    self.farmlandId = farmlandId
    self.fieldSize = fieldSize
    self.numSamples = numSamples
    self.sampleCosts = sampleCost
    self.serviceCosts = serviceCost
    self.numSamplesText:setValue(numSamples)
    self.sampleCostsText:setValue(sampleCost)
    self.serviceCostsText:setValue(serviceCost)
    self.dialogTitleElement:setText(string.format(g_i18n:getText("ui_economicAnalysisHeaderField", SoilSampleYesNoDialog.MOD_NAME), farmlandId, fieldSize))
    self.dialogTextElement:setText(string.format(g_i18n:getText("ui_soilSampleDialogQuestion", SoilSampleYesNoDialog.MOD_NAME), g_i18n:formatMoney(sampleCost + serviceCost, 0, true, true)))
end
function SoilSampleYesNoDialog.show(callback, target, farmlandId, fieldSize, numSamples, sampleCost, serviceCost)
    if SoilSampleYesNoDialog.INSTANCE ~= nil then
        local dialog = SoilSampleYesNoDialog.INSTANCE
        dialog:setData(farmlandId, fieldSize, numSamples, sampleCost, serviceCost)
        dialog:setDialogType(DialogElement.TYPE_QUESTION)
        dialog:setCallback(callback, target, farmlandId)
        g_gui:showDialog("SoilSampleYesNoDialog")
    end
end
function SoilSampleYesNoDialog.createFromExistingGui(gui, _)
    SoilSampleYesNoDialog.register()
    SoilSampleYesNoDialog.show(gui.callbackFunc, gui.target, gui.farmlandId, gui.fieldSize, gui.numSamples, gui.sampleCost, gui.serviceCost)
end