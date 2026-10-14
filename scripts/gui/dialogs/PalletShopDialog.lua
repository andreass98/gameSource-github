PalletShopDialog = {}
local PalletShopDialog_mt = Class(PalletShopDialog, YesNoDialog)
function PalletShopDialog.register()
    local palletShopDialog = PalletShopDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/PalletShopDialog.xml", "PalletShopDialog", palletShopDialog)
    PalletShopDialog.INSTANCE = palletShopDialog
end
function PalletShopDialog.show(callback, target, items, maxQuantity, title)
    if PalletShopDialog.INSTANCE ~= nil then
        local dialog = PalletShopDialog.INSTANCE
        dialog:setCallback(callback, target)
        dialog:setTitle(title)
        dialog:setItems(items, maxQuantity)
        g_gui:showDialog("PalletShopDialog")
    end
end
function PalletShopDialog.new(target, custom_mt)
    -- upvalues: (copy) PalletShopDialog_mt
    local self = YesNoDialog.new(target, custom_mt or PalletShopDialog_mt)
    self.selectedFillType = nil
    self.areButtonsDisabled = false
    self.lastSelectedFillType = nil
    return self
end
function PalletShopDialog.createFromExistingGui(gui, _)
    PalletShopDialog.register()
    PalletShopDialog.show(gui.callbackFunc, gui.target, gui.items, gui.maxQuantity)
end
function PalletShopDialog:onOpen()
    PalletShopDialog:superClass().onOpen(self)
    FocusManager:setFocus(self.itemsElement)
end
function PalletShopDialog:onYes()
    if self.areButtonsDisabled then
        return true
    end
    self:sendCallback(self.lastSelectedIndex, self.quantityElement:getState())
    return false
end
function PalletShopDialog:onNo(_, _)
    self:sendCallback(nil, nil)
    return false
end
function PalletShopDialog:sendCallback(index, quantity)
    if self.inputDelay >= self.time then
        return true
    end
    self:close()
    if self.callbackFunc ~= nil then
        if self.target == nil then
            self.callbackFunc(index, quantity, self.callbackArgs)
        else
            self.callbackFunc(self.target, index, quantity, self.callbackArgs)
        end
    end
    return false
end
function PalletShopDialog:onClickItems(state)
    self:setButtonDisabled(false)
    self.lastSelectedIndex = state
    self.palletIconElement:setImageFilename(self.items[state].imageFilename)
    self:updatePrices()
end
function PalletShopDialog:onClickQuantity()
    self:updatePrices()
end
function PalletShopDialog:updatePrices()
    local item = self.items[self.lastSelectedIndex]
    local quantity = self.quantityElement:getState()
    self.basePriceText:setText(g_i18n:formatMoney(item.price, 0, true, false))
    self.totalPriceText:setText(g_i18n:formatMoney(item.price * quantity, 0, true, false))
end
function PalletShopDialog:setItems(items, maxQuantity)
    self.items = items
    self.maxQuantity = maxQuantity
    self.itemsMapping = {}
    local selectedId = 1
    local itemTitles = {}
    for k, item in ipairs(items) do
        table.insert(itemTitles, item.title)
        if k == self.lastSelectedIndex then
            selectedId = k
        end
    end
    self.itemsElement:setTexts(itemTitles)
    self.itemsElement:setState(selectedId, true)
    local quantities = {}
    local k = 1
    for k = k, maxQuantity do
        table.insert(quantities, tostring(k) .. "x")
    end
    self.quantityElement:setTexts(quantities)
end
function PalletShopDialog:setButtonDisabled(disabled)
    self.areButtonsDisabled = disabled
    self.yesButton:setDisabled(disabled)
end