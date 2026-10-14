TransferMoneyDialog = {}
local TransferMoneyDialog_mt = Class(TransferMoneyDialog, DialogElement)
function TransferMoneyDialog.register()
    local transferMoneyDialog = TransferMoneyDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/TransferMoneyDialog.xml", "TransferMoneyDialog", transferMoneyDialog)
    TransferMoneyDialog.INSTANCE = transferMoneyDialog
end
function TransferMoneyDialog.show(callback, target, farm)
    if TransferMoneyDialog.INSTANCE ~= nil then
        local dialog = TransferMoneyDialog.INSTANCE
        dialog:setCallback(callback, target)
        dialog:setTargetFarm(farm)
        g_gui:showDialog("TransferMoneyDialog")
    end
end
function TransferMoneyDialog.new(target, custom_mt)
    -- upvalues: (copy) TransferMoneyDialog_mt
    local self = DialogElement.new(target, custom_mt or TransferMoneyDialog_mt)
    self.isBackAllowed = false
    self.inputDelay = 250
    self.amount = 0
    self.optionElements = {}
    return self
end
function TransferMoneyDialog.createFromExistingGui(gui, _)
    local newGui = TransferMoneyDialog.register()
    TransferMoneyDialog.show(gui.callbackFunc, gui.target, gui.farm)
    return newGui
end
function TransferMoneyDialog:onOpen()
    TransferMoneyDialog:superClass().onOpen(self)
    self.inputDelay = self.time + 250
    for element, amount in pairs(self.optionElements) do
        element.elements[3]:setText(g_i18n:formatMoney(amount))
    end
    self.farm = g_farmManager:getFarmById(g_currentMission:getFarmId())
    self:updateAmount(0)
end
function TransferMoneyDialog:onClickActivate()
    if self.inputDelay >= self.time then
        return true
    end
    self:sendCallback(self.amount)
    return false
end
function TransferMoneyDialog:setCallback(callbackFunc, target)
    self.callbackFunc = callbackFunc
    self.target = target
end
function TransferMoneyDialog:setTargetFarm(farm)
    self.headerText:setText(string.format(g_i18n:getText("button_mp_transferMoney_dialogTitle"), farm.name))
    self.farm = farm
end
function TransferMoneyDialog:onClickBack(_)
    if self.inputDelay >= self.time then
        return true
    end
    self:sendCallback(0)
    return false
end
function TransferMoneyDialog:sendCallback(value)
    if self.inputDelay >= self.time then
        return true
    end
    self:close()
    if self.callbackFunc ~= nil then
        if self.target == nil then
            self.callbackFunc(value)
        else
            self.callbackFunc(self.target, value)
        end
    end
    return false
end
function TransferMoneyDialog:onClickLeft(element)
    self:updateAmount(-1 * self.optionElements[element.parent])
end
function TransferMoneyDialog:onClickRight(element)
    self:updateAmount(self.optionElements[element.parent])
end
function TransferMoneyDialog:updateAmount(diff)
    self.amount = math.min(math.max(self.amount + diff, 0), self.farm:getBalance())
    self.amountText:setText(g_i18n:formatMoney(self.amount))
end
function TransferMoneyDialog:onCreateScroller(element, amount)
    amount = tonumber(amount)
    self.optionElements[element] = amount
end