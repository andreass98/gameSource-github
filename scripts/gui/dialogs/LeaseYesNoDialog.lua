LeaseYesNoDialog = {}
local LeaseYesNoDialog_mt = Class(LeaseYesNoDialog, YesNoDialog)
function LeaseYesNoDialog.register()
    local leaseYesNoDialog = LeaseYesNoDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/LeaseYesNoDialog.xml", "LeaseYesNoDialog", leaseYesNoDialog)
    LeaseYesNoDialog.INSTANCE = leaseYesNoDialog
end
function LeaseYesNoDialog.show(callback, target, costsBase, initialCosts, costsPerOperatingHour, costsPerDay)
    if LeaseYesNoDialog.INSTANCE ~= nil then
        local dialog = LeaseYesNoDialog.INSTANCE
        dialog:setPrices(costsBase, initialCosts, costsPerOperatingHour, costsPerDay)
        dialog:setDialogType(DialogElement.TYPE_QUESTION)
        dialog:setCallback(callback, target)
        g_gui:showDialog("LeaseYesNoDialog")
    end
end
function LeaseYesNoDialog.new(target, custom_mt)
    -- upvalues: (copy) LeaseYesNoDialog_mt
    return LeaseYesNoDialog:superClass().new(target, custom_mt or LeaseYesNoDialog_mt)
end
function LeaseYesNoDialog.createFromExistingGui(gui, _)
    LeaseYesNoDialog.register()
    LeaseYesNoDialog.show(gui.callbackFunc, gui.target, gui.costsBase, gui.initialCosts, gui.costsPerOperatingHour, gui.costsPerDay)
end
function LeaseYesNoDialog:setPrices(costsBase, initialCosts, costsPerOperatingHour, costsPerDay)
    self.costsBaseValue:setValue(costsBase)
    self.costsPerDayValue:setValue(costsPerDay)
    self.costsPerOperatingHourValue:setValue(costsPerOperatingHour)
    self.leaseText = string.format(g_i18n:getText("shop_doYouWantToLease"), g_i18n:formatMoney(initialCosts, 0, true, true))
    self.dialogTextElement:setText(self.leaseText)
    self.costsBase = costsBase
    self.initialCosts = initialCosts
    self.costsPerOperatingHour = costsPerOperatingHour
    self.costsPerDay = costsPerDay
end