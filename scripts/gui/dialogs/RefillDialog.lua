RefillDialog = {}
local RefillDialog_mt = Class(RefillDialog, YesNoDialog)
RefillDialog.FILL_AMOUNTS = {
    1,
    2,
    5,
    10,
    20,
    50,
    100,
    200,
    500,
    1000,
    2000,
    5000,
    10000,
    50000,
    100000
}
function RefillDialog.register()
    local refillDialog = RefillDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/RefillDialog.xml", "RefillDialog", refillDialog)
    RefillDialog.INSTANCE = refillDialog
end
function RefillDialog.show(callback, target, freeCapacities, priceFactor)
    if RefillDialog.INSTANCE ~= nil then
        local dialog = RefillDialog.INSTANCE
        dialog:setFreeCapacities(freeCapacities, priceFactor)
        dialog:setCallback(callback, target)
        g_gui:showDialog("RefillDialog")
    end
end
function RefillDialog.new(target, custom_mt)
    -- upvalues: (copy) RefillDialog_mt
    local self = YesNoDialog.new(target, custom_mt or RefillDialog_mt)
    self.selectedFillAmount = nil
    self.fillTypeAmountMapping = {}
    self.amountMapping = {}
    self.priceMapping = {}
    self.selectedPrice = 0
    self.priceFactor = 2
    self.fillTypeMapping = {}
    self.selectedFillType = nil
    self.lastSelectedFillType = nil
    self.areButtonsDisabled = false
    return self
end
function RefillDialog.createFromExistingGui(gui, _)
    RefillDialog.register()
    RefillDialog.show(gui.callbackFunc, gui.target, gui.freeCapacities, gui.priceFactor)
end
function RefillDialog:onOpen()
    RefillDialog:superClass().onOpen(self)
    if self.fillTypesElement.disabled then
        FocusManager:setFocus(self.fillAmountsElement)
    else
        FocusManager:unsetFocus(self.fillTypesElement)
        FocusManager:setFocus(self.fillTypesElement)
    end
end
function RefillDialog:onClickOk()
    if self.areButtonsDisabled then
        return true
    end
    local fillType = g_fillTypeManager:getFillTypeByIndex(self.selectedFillType)
    local formattedPrice = g_i18n:formatMoney(self.selectedPrice)
    local text = string.format(g_i18n:getText("ui_buyProductAmount"), self.selectedFillAmount, fillType.title, formattedPrice)
    YesNoDialog.show(self.onBuyYesNo, self, text)
    return false
end
function RefillDialog:onBuyYesNo(yes)
    if yes then
        local enoughMoney = g_currentMission:getMoney() >= self.selectedPrice
        if enoughMoney then
            self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
            self.callbackArgs = self.selectedFillAmount
            self.lastSelectedFillType = self.selectedFillType
            self:sendCallback(self.selectedFillType, self.selectedFillAmount, self.selectedPrice)
            return
        end
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
        InfoDialog.show(g_i18n:getText("shop_messageNotEnoughMoneyToBuy"))
    end
end
function RefillDialog:onClickBack(_, _)
    self:sendCallback(nil, nil, nil)
    return false
end
function RefillDialog:sendCallback(fillTypeIndex, amount, price)
    self:close()
    if self.callbackFunc ~= nil then
        if self.target ~= nil then
            self.callbackFunc(self.target, fillTypeIndex, amount, price)
            return
        end
        self.callbackFunc(fillTypeIndex, amount, price)
    end
end
function RefillDialog:onClickFillTypes(state)
    self.selectedFillType = self.fillTypeMapping[state]
    self:updateFillAmounts()
end
function RefillDialog:onClickFillAmount(state)
    self.selectedFillAmount = self.amountMapping[state]
    self.selectedPrice = self.priceMapping[state]
end
function RefillDialog:setFreeCapacities(freeCapacities, priceFactor)
    self.fillTypeMapping = {}
    self.fillTypeAmountMapping = {}
    self.priceFactor = priceFactor or self.priceFactor
    local fillTypesTable = {}
    local selectedId = 1
    local numFillLevels = 1
    for fillTypeIndex, freeCapacity in pairs(freeCapacities) do
        local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
        if fillTypeIndex == self.lastSelectedFillType then
            selectedId = numFillLevels
        end
        table.insert(fillTypesTable, fillType.title)
        table.insert(self.fillTypeMapping, fillTypeIndex)
        local fillAmounts = {}
        local i = #RefillDialog.FILL_AMOUNTS
        for i = i, 1, -1 do
            local fillAmount = RefillDialog.FILL_AMOUNTS[i]
            if fillAmount < freeCapacity then
                table.insert(fillAmounts, 1, fillAmount)
            end
        end
        if freeCapacity > 0 and (freeCapacity ~= math.huge and freeCapacity ~= fillAmounts[#fillAmounts]) then
            table.insert(fillAmounts, freeCapacity)
        end
        self.fillTypeAmountMapping[fillTypeIndex] = fillAmounts
        numFillLevels = numFillLevels + 1
    end
    self.fillTypesElement:setDisabled(#fillTypesTable <= 1)
    self.fillTypesElement:setTexts(fillTypesTable)
    self.fillTypesElement:setState(selectedId, true)
    self.freeCapacities = freeCapacities
    self.priceFactor = priceFactor
end
function RefillDialog:updateFillAmounts()
    local fillAmountTexts = {}
    local fillAmounts = self.fillTypeAmountMapping[self.selectedFillType]
    self.amountMapping = {}
    self.priceMapping = {}
    local fillType = g_fillTypeManager:getFillTypeByIndex(self.selectedFillType)
    local litersText = g_i18n:getText("unit_liter")
    for _, fillAmount in ipairs(fillAmounts) do
        local price = fillType.pricePerLiter * self.priceFactor * fillAmount
        local priceStr = g_i18n:formatMoney(price)
        local text = string.format("%d %s (%s)", fillAmount, litersText, priceStr)
        table.insert(fillAmountTexts, text)
        table.insert(self.amountMapping, fillAmount)
        table.insert(self.priceMapping, price)
    end
    self.fillAmountsElement:setTexts(fillAmountTexts)
    self.fillAmountsElement:setState(#fillAmountTexts, true)
    self:setButtonDisabled(#fillAmounts == 0)
    self.fillAmountsElement:setDisabled(#fillAmounts == 0)
    if #fillAmounts == 0 then
        self.fillAmountText:setText("-")
    end
    if self.fillTypesElement.disabled and not self.fillAmountsElement.disabled then
        FocusManager:unsetFocus(self.fillAmountsElement)
        FocusManager:setFocus(self.fillAmountsElement)
    end
end
function RefillDialog:setButtonDisabled(disabled)
    self.messageBackground:setVisible(disabled)
    self.areButtonsDisabled = disabled
    self.yesButton:setDisabled(disabled)
end