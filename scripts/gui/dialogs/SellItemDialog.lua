SellItemDialog = {}
local SellItemDialog_mt = Class(SellItemDialog, YesNoDialog)
function SellItemDialog.register()
    local sellItemDialog = SellItemDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/SellItemDialog.xml", "SellItemDialog", sellItemDialog)
    SellItemDialog.INSTANCE = sellItemDialog
end
function SellItemDialog.show(callback, target, item, price, storeItem, isDirectSell)
    if SellItemDialog.INSTANCE ~= nil then
        local dialog = SellItemDialog.INSTANCE
        dialog:setItem(item, price, storeItem)
        dialog:setCallback(callback, target, isDirectSell)
        g_gui:showDialog("SellItemDialog")
    end
end
function SellItemDialog.new(target, custom_mt)
    -- upvalues: (copy) SellItemDialog_mt
    local self = YesNoDialog.new(target, custom_mt or SellItemDialog_mt)
    self.selectedFillType = nil
    self.areButtonsDisabled = false
    return self
end
function SellItemDialog.createFromExistingGui(gui, _)
    SellItemDialog.register()
    local item = gui.item
    SellItemDialog.show(gui.callbackFunc, gui.target, item, item.price, gui.storeItem)
end
function SellItemDialog:onClose()
    self.item = nil
    self.storeItem = nil
    SellItemDialog:superClass().onClose(self)
end
function SellItemDialog:setItem(item, price, storeItem)
    local imageFilename = "dataS/menu/black.png"
    local name = "unknown"
    local sellPrice = g_i18n:formatMoney(Utils.getNoNil(price, 0), 0, true, true)
    if item == nil then
        if storeItem ~= nil then
            imageFilename = storeItem.imageFilename
            name = storeItem.name
        end
    else
        storeItem = storeItem or g_storeManager:getItemByXMLFilename(item.configFileName)
        if storeItem ~= nil then
            imageFilename = storeItem.imageFilename
            name = storeItem.name
        end
        if item.getFullName == nil then
            if item.getName ~= nil then
                name = item:getName()
            end
        else
            name = item:getFullName()
        end
        if item.getImageFilename ~= nil then
            imageFilename = item:getImageFilename()
        end
    end
    self.dialogImageElement:setImageFilename(imageFilename)
    self.dialogItemNameElement:setText(name)
    local title = g_i18n:getText("ui_sellItem")
    if item == nil or item.propertyState ~= VehiclePropertyState.LEASED then
        self.dialogItemPriceElement:setVisible(true)
    else
        title = g_i18n:getText("button_return")
        sellPrice = "-"
        self.dialogItemPriceElement:setVisible(false)
    end
    self.headerText:setText(title)
    self.dialogItemPriceElement:setText(sellPrice)
    self.item = item
    self.storeItem = storeItem
end