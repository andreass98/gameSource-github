RiceFieldDialog = {}
local RiceFieldDialog_mt = Class(RiceFieldDialog, InfoDialog)
function RiceFieldDialog.register()
    local riceFieldDialog = RiceFieldDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/RiceFieldDialog.xml", "RiceFieldDialog", riceFieldDialog)
    RiceFieldDialog.INSTANCE = riceFieldDialog
end
function RiceFieldDialog.show(callback, riceFieldPlaceable, title, riceFieldIndex)
    if RiceFieldDialog.INSTANCE ~= nil then
        local dialog = RiceFieldDialog.INSTANCE
        dialog.headerTitle:setText(title)
        dialog:setCallback(callback, riceFieldPlaceable)
        dialog:setButtonAction(InputAction.MENU_BACK)
        dialog.args = {}
        dialog.args.isAccepted = false
        dialog.riceFieldPlaceable = riceFieldPlaceable
        dialog.riceFieldIndex = riceFieldIndex
        local areaSqm = riceFieldPlaceable:getArea(riceFieldIndex)
        local fillLevelCbm = riceFieldPlaceable:getWaterFillLevel(riceFieldIndex) / 1000
        local maxWaterHeight = riceFieldPlaceable:getMaxWaterHeight()
        dialog.buttonEmpty:setDisabled(true)
        dialog.buttonFill:setDisabled(true)
        if g_server == nil then
            g_messageCenter:subscribe(PlaceableRiceFieldStateEvent, dialog.onRiceFieldStatusResult, dialog)
            g_client:getServerConnection():sendEvent(PlaceableRiceFieldStateEvent.new(riceFieldPlaceable, riceFieldIndex))
        else
            riceFieldPlaceable:getRiceFieldState(riceFieldIndex, dialog.onRiceFieldStatusResult, dialog)
        end
        dialog.textFieldNr:setText(riceFieldIndex)
        dialog.textFieldSize:setText(g_i18n:formatArea(areaSqm / 10000, 2))
        dialog.textCropType:setText("")
        dialog.textWaterLevel:setText(g_i18n:formatNumber(fillLevelCbm / areaSqm / maxWaterHeight * 100, 0) .. " %")
        dialog.warning:setText("")
        dialog.warning:setVisible(false)
        g_gui:showDialog("RiceFieldDialog")
    end
end
function RiceFieldDialog.new(target, custom_mt)
    -- upvalues: (copy) RiceFieldDialog_mt
    local self = InfoDialog.new(target, custom_mt or RiceFieldDialog_mt)
    self.areButtonsDisabled = false
    return self
end
function RiceFieldDialog.createFromExistingGui(gui, _)
    RiceFieldDialog.register()
    RiceFieldDialog.show(gui.callbackFunc, gui.target, gui.headerTitle.text, gui.riceFieldIndex)
end
function RiceFieldDialog:onOpen()
    RiceFieldDialog:superClass().onOpen(self)
    if self.buttonEmpty:getIsDisabled() then
        FocusManager:setFocus(self.buttonFill)
    end
end
function RiceFieldDialog:onClose()
    g_messageCenter:unsubscribe(PlaceableRiceFieldStateEvent, self)
    self.riceFieldPlaceable = nil
    RiceFieldDialog:superClass().onClose(self)
end
function RiceFieldDialog:onRiceFieldStatusResult(maxFruitIndex, maxStage)
    g_messageCenter:unsubscribe(PlaceableRiceFieldStateEvent, self)
    local currentWaterLevelLiters = self.riceFieldPlaceable:getWaterFillLevelPerSqm(self.riceFieldIndex)
    if maxFruitIndex == FruitType.UNKNOWN then
        self.textCropType:setText("-")
        if currentWaterLevelLiters == 0 then
            self.buttonFill:setDisabled(false)
            self.targetWaterPercentage = 0.65
        else
            self.buttonEmpty:setDisabled(false)
            self.targetWaterPercentage = 0
        end
    else
        local fruitType = g_fruitTypeManager:getFruitTypeByIndex(maxFruitIndex)
        local fieldMaxWaterLiters = self.riceFieldPlaceable:getMaxWaterHeight() * 1000
        local minWaterLiters = fruitType.minWaterLitersPerSqm and fruitType.minWaterLitersPerSqm[maxStage] or 0
        local maxWaterLiters
        if fruitType.maxWaterLitersPerSqm then
            maxWaterLiters = fruitType.maxWaterLitersPerSqm[maxStage] or fieldMaxWaterLiters
        else
            maxWaterLiters = fieldMaxWaterLiters
        end
        self.targetWaterPercentage = (minWaterLiters + maxWaterLiters) / 2 / fieldMaxWaterLiters
        self.textCropType:setText(fruitType.fillType.title)
        local warningText = self.buttonEmpty
        warningText:setDisabled(currentWaterLevelLiters <= maxWaterLiters)
        local warningText = self.buttonFill
        warningText:setDisabled(minWaterLiters <= currentWaterLevelLiters)
        local warningText = nil
        if maxWaterLiters < currentWaterLevelLiters then
            warningText = g_i18n:getText("ui_riceFieldWarningWaterLevelTooHigh")
        elseif currentWaterLevelLiters < minWaterLiters then
            warningText = g_i18n:getText("ui_riceFieldWarningWaterLevelTooLow")
        end
        if warningText == nil then
            self.warning:setVisible(false)
        else
            self.warning:setText(warningText)
            self.warning:setVisible(true)
        end
    end
end
function RiceFieldDialog:setButtonDisabled(disabled)
    self.messageBackground:setVisible(disabled)
    self.areButtonsDisabled = disabled
end
function RiceFieldDialog:onClickEmpty()
    self.args.fillLevelPercentage = self.targetWaterPercentage
    self.args.isAccepted = true
    self:onClickOk()
end
function RiceFieldDialog:onClickFill()
    self.args.fillLevelPercentage = self.targetWaterPercentage
    self.args.isAccepted = true
    self:onClickOk()
end