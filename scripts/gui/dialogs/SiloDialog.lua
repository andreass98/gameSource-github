SiloDialog = {}
local SiloDialog_mt = Class(SiloDialog, YesNoDialog)
function SiloDialog.register()
    local siloDialog = SiloDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/SiloDialog.xml", "SiloDialog", siloDialog)
    SiloDialog.INSTANCE = siloDialog
end
function SiloDialog.show(callback, target, title, fillLevels, hasInfiniteCapacity)
    if SiloDialog.INSTANCE ~= nil then
        local dialog = SiloDialog.INSTANCE
        dialog:setCallback(callback, target)
        dialog:setTitle(title)
        dialog:setText(nil)
        dialog:setFillLevels(fillLevels, hasInfiniteCapacity)
        g_gui:showDialog("SiloDialog")
    end
end
function SiloDialog.new(target, custom_mt)
    -- upvalues: (copy) SiloDialog_mt
    local self = YesNoDialog.new(target, custom_mt or SiloDialog_mt)
    self.selectedFillType = nil
    self.areButtonsDisabled = false
    self.lastSelectedFillType = nil
    return self
end
function SiloDialog.createFromExistingGui(gui, _)
    SiloDialog.register()
    SiloDialog.show(gui.callbackFunc, gui.target, gui.siloTitle, gui.fillLevels, gui.hasInfiniteCapacity)
end
function SiloDialog:onClickOk()
    if self.areButtonsDisabled then
        return true
    end
    self.lastSelectedFillType = self.selectedFillType
    self:sendCallback(self.selectedFillType)
    return false
end
function SiloDialog:onClickBack(_, _)
    self:sendCallback(FillType.UNKNOWN)
    return false
end
function SiloDialog:onClickFillTypes(state)
    self:setButtonDisabled(false)
    self.selectedFillType = self.fillTypeMapping[state]
    if self.fillLevels ~= nil and self.fillLevels[self.selectedFillType] <= 0 then
        self:setButtonDisabled(true)
    end
    local fillType = self.siloText:getTextWidth()
    local siloAmount = math.min(fillType, self.siloText.absSize[1])
    self.siloIcon:setPosition(self.siloText.position[1] - siloAmount * 0.5 - self.siloIcon.margin[3], nil)
    local fillType = g_fillTypeManager:getFillTypeByIndex(self.selectedFillType)
    self.siloIcon:setImageFilename(fillType.hudOverlayFilename)
end
function SiloDialog:setTitle(title)
    SiloDialog:superClass().setTitle(self, title)
    self.siloTitle = title
end
function SiloDialog:setFillLevels(fillLevels, hasInfiniteCapacity)
    self.fillLevels = fillLevels
    self.fillTypeMapping = {}
    local fillTypesTable = {}
    local selectedId = 1
    local numFillLevels = 1
    for fillTypeIndex, _ in pairs(fillLevels) do
        local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
        local level = Utils.getNoNil(fillLevels[fillTypeIndex], 0)
        local name
        if hasInfiniteCapacity then
            name = string.format("%s", fillType.title)
        else
            name = string.format("%s %s", fillType.title, g_i18n:formatFluid(level))
        end
        table.insert(fillTypesTable, name)
        table.insert(self.fillTypeMapping, fillTypeIndex)
        if fillTypeIndex == self.lastSelectedFillType then
            selectedId = numFillLevels
        end
        numFillLevels = numFillLevels + 1
    end
    self.fillTypesElement:setTexts(fillTypesTable)
    self.fillTypesElement:setState(selectedId, true)
end
function SiloDialog:setButtonDisabled(disabled)
    self.messageBackground:setVisible(disabled)
    self.areButtonsDisabled = disabled
    self.yesButton:setDisabled(disabled)
end