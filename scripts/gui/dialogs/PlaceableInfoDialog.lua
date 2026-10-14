PlaceableInfoDialog = {}
local PlaceableInfoDialog_mt = Class(PlaceableInfoDialog, DialogElement)
function PlaceableInfoDialog.register()
    local placeableInfoDialog = PlaceableInfoDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/PlaceableInfoDialog.xml", "PlaceableInfoDialog", placeableInfoDialog)
    PlaceableInfoDialog.INSTANCE = placeableInfoDialog
end
function PlaceableInfoDialog.show(callback, placeable)
    if PlaceableInfoDialog.INSTANCE ~= nil then
        local dialog = PlaceableInfoDialog.INSTANCE
        dialog:setCallback(callback)
        dialog:setPlaceable(placeable)
        g_gui:showDialog("PlaceableInfoDialog")
    end
end
function PlaceableInfoDialog.new(target, custom_mt)
    -- upvalues: (copy) PlaceableInfoDialog_mt
    local self = DialogElement.new(target, custom_mt or PlaceableInfoDialog_mt)
    self.inputDelay = 0
    return self
end
function PlaceableInfoDialog.createFromExistingGui(gui, _)
    PlaceableInfoDialog.register()
    PlaceableInfoDialog.show(gui.callbackFunc, gui.placeable)
end
function PlaceableInfoDialog:onOpen()
    PlaceableInfoDialog:superClass().onOpen(self)
    self.inputDelay = self.time + 250
end
function PlaceableInfoDialog:onClose()
    g_messageCenter:unsubscribe(SellPlaceableEvent, self)
    self.callbackFunc = nil
    self.target = nil
    self.callbackArgs = nil
    self.placeable = nil
    PlaceableInfoDialog:superClass().onClose(self)
end
function PlaceableInfoDialog:setPlaceable(placeable)
    local name = placeable:getName()
    local price, _forFullPrice = placeable:getSellPrice()
    local sellPrice = g_i18n:formatMoney(price)
    local canRename = placeable:getCanBeRenamedByFarm(g_currentMission:getFarmId())
    local allowedToRename = g_currentMission:getHasPlayerPermission("buyPlaceable")
    local imageFilename = placeable:getImageFilename()
    local canSell = placeable:canBeSold() and placeable.storeItem.canBeSold
    if canSell then
        canSell = g_currentMission:getFarmId() == placeable:getOwnerFarmId()
    end
    local allowedToSell = g_currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_PLACEABLE)
    self.placeable = placeable
    if imageFilename == nil then
        self.icon:setVisible(false)
    else
        self.icon:setImageFilename(imageFilename)
        self.icon:setVisible(true)
    end
    self.titleText:setText(name)
    self.priceText:setText(sellPrice)
    self.ageText:setText(string.format(g_i18n:getText("shop_age"), string.format("%d", placeable.age)))
    self.sellButton:setVisible(canSell)
    self.sellButton:setDisabled(not allowedToSell)
    self.renameButton:setVisible(canRename)
    self.renameButton:setDisabled(not allowedToRename)
    self.renameSeparator:setVisible(canRename)
    self.sellButton.parent:invalidateLayout()
    g_messageCenter:subscribe(SellPlaceableEvent, self.onPlaceableDestroyed, self)
    self.placeable = placeable
end
function PlaceableInfoDialog:setCallback(callbackFunc, target, args)
    self.callbackFunc = callbackFunc
    self.target = target
    self.callbackArgs = args
end
function PlaceableInfoDialog:onClickBack()
    if self.inputDelay >= self.time then
        return true
    end
    self:sendCallback(false)
    self:close()
    return false
end
function PlaceableInfoDialog:sendCallback(didSell)
    g_messageCenter:unsubscribe(SellPlaceableEvent, self)
    if self.callbackFunc ~= nil then
        if self.target ~= nil then
            self.callbackFunc(self.target, didSell, self.callbackArgs)
            return
        end
        self.callbackFunc(didSell, self.callbackArgs)
    end
end
function PlaceableInfoDialog:onClickSell()
    local price, forFullPrice = self.placeable:getSellPrice()
    local text = string.format(g_i18n:getText("ui_constructionSellConfirmation"), self.placeable:getName(), g_i18n:formatMoney(price, 0, true, true))
    YesNoDialog.show(function(yes)
        -- upvalues: (copy) self, (copy) forFullPrice
        if yes then
            g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(self.placeable, nil, forFullPrice))
        end
    end, nil, text)
end
function PlaceableInfoDialog:onClickRename()
    local text = g_i18n:getText("button_changeName")
    local defaultText = self.placeable:getName()
    local dialogPrompt = g_i18n:getText("ui_enterName")
    local imePrompt = g_i18n:getText("ui_enterName")
    local confirmText = g_i18n:getText("button_change")
    TextInputDialog.show(function(newName, yes)
        -- upvalues: (copy) self
        if yes then
            if not g_currentMission:getHasPlayerPermission("buyPlaceable") then
                InfoDialog.show(g_i18n:getText("shop_messageNoPermissionGeneral"), nil, nil, DialogElement.TYPE_WARNING)
                return
            end
            if string.isNilOrWhitespace(newName) then
                self.placeable:setName(nil)
            else
                self.placeable:setName(string.trim(newName))
            end
            g_messageCenter:unsubscribe(SellPlaceableEvent, self)
            self:setPlaceable(self.placeable)
        end
    end, nil, defaultText, dialogPrompt, imePrompt, nil, confirmText, nil, text)
end
function PlaceableInfoDialog:onPlaceableDestroyed()
    self:sendCallback(true)
    self:close()
end