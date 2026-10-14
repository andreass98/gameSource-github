WorkshopScreen = {}
local WorkshopScreen_mt = Class(WorkshopScreen, ScreenElement)
function WorkshopScreen.register()
    local workshopScreen = WorkshopScreen.new()
    g_gui:loadGui("dataS/gui/WorkshopScreen.xml", "WorkshopScreen", workshopScreen)
    return workshopScreen
end
function WorkshopScreen.new(target, custom_mt)
    -- upvalues: (copy) WorkshopScreen_mt
    local self = WorkshopScreen:superClass().new(target, custom_mt or WorkshopScreen_mt)
    self.vehicles = {}
    return self
end
function WorkshopScreen.createFromExistingGui(gui, guiName)
    local newGui = WorkshopScreen.new()
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    FocusManager:deleteGuiFocusData("WorkshopScreen")
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    newGui:setVehicles(gui.vehicles)
    g_workshopScreen = newGui
    return newGui
end
function WorkshopScreen:onOpen()
    WorkshopScreen:superClass().onOpen(self)
    self:updateBalanceText()
    g_messageCenter:subscribe(SellVehicleEvent, self.onVehicleSellEvent, self)
    g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.updateBalanceText, self)
    g_messageCenter:subscribe(MessageType.VEHICLE_REPAIRED, self.onVehicleRepairEvent, self)
    g_messageCenter:subscribe(MessageType.VEHICLE_REPAINTED, self.onVehicleRepaintEvent, self)
    self.refreshTimer = 0
    if self.isMobileWorkshop then
        self.headerText:setText(g_i18n:getText("ui_mobileWorkshop"))
        return
    elseif self.isOwnWorkshop then
        self.headerText:setText(g_i18n:getText("ui_sellOrCustomizeVehicleTitle"))
    else
        self.headerText:setText(g_i18n:getText("ui_dealer"))
    end
end
function WorkshopScreen:onClose()
    WorkshopScreen:superClass().onClose(self)
    self.vehicle = nil
    self.owner = nil
    g_messageCenter:unsubscribeAll(self)
    g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_BUY)
    g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_SELL)
end
function WorkshopScreen:setSellingPoint(sellingPoint, isDealer, isOwnWorkshop, isMobileWorkshop)
    self.owner = sellingPoint
    self.isDealer = isDealer
    self.isOwnWorkshop = isOwnWorkshop
    self.isMobileWorkshop = isMobileWorkshop
end
function WorkshopScreen:setConfigurations(vehicleBuyData, vehicleId)
    g_shopConfigScreen:onClickBack()
    if vehicleBuyData:isValid() then
        local areChangesMade = false
        local vehicle = NetworkUtil.getObject(vehicleId)
        if vehicle == nil then
            return
        end
        for configName, configValue in pairs(vehicleBuyData.configurations) do
            if vehicle.configurations[configName] ~= configValue then
                areChangesMade = true
                break
            end
        end
        local areChangesMade = ConfigurationUtil.getConfigurationDataHasChanged(vehicle.configFileName, vehicleBuyData.configurationData, vehicle.configurationData) and true or areChangesMade
        if vehicle.getLicensePlatesDataIsEqual ~= nil and not vehicle:getLicensePlatesDataIsEqual(vehicleBuyData.licensePlateData) and true or areChangesMade then
            local playerVehicle = g_localPlayer:getCurrentVehicle()
            if playerVehicle ~= nil and vehicle == playerVehicle then
                g_localPlayer:leaveVehicle()
            end
            g_client:getServerConnection():sendEvent(ChangeVehicleConfigEvent.new(vehicle, vehicleBuyData))
            return
        end
    else
        self:onClickBack()
        if self.owner ~= nil then
            self.owner:openMenu()
        end
    end
end
function WorkshopScreen:update(dt)
    WorkshopScreen:superClass().update(self, dt)
    if self.vehicle ~= nil then
        if self.vehicle.isDeleted then
            table.removeElement(self.vehicles, self.vehicle)
            self.vehicle = nil
            self.list:reloadData()
            if #self.vehicles == 0 then
                self:setVehicle(nil)
            end
        elseif g_server == nil then
            self.refreshTimer = self.refreshTimer + dt
            if self.refreshTimer > 250 then
                self.refreshTimer = 0
                self:setVehicle(self.vehicle)
            end
        end
    end
    if self.needsListReload then
        self.list:reloadData()
        self.needsListReload = false
    end
end
function WorkshopScreen:setVehicles(vehicles)
    self.vehicles = vehicles
    self.list:reloadData()
    if #vehicles == 0 then
        self:setVehicle(nil)
    end
end
function WorkshopScreen:updateVehicles(sellingPoint, vehicles)
    if sellingPoint == self.owner then
        self:setVehicles(vehicles)
    end
end
function WorkshopScreen:setVehicle(vehicle)
    self.storeItem = nil
    self.canBeConfigured = false
    self.canBeSold = not self.mobileWorkshop
    if vehicle == nil then
        self.repairButton:setLocaKey("button_repair")
        self.repairButton:setDisabled(true)
        self.repaintButton:setLocaKey("button_repaint")
        self.repaintButton:setDisabled(true)
    else
        self.vehicle = vehicle
        self.storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
        if self.storeItem ~= nil then
            local repairPrice = false
            if self.storeItem.configurations ~= nil then
                repairPrice = vehicle.propertyState == VehiclePropertyState.OWNED
            end
            self.canBeConfigured = repairPrice
            local repairPrice = self.storeItem.canBeSold
            if repairPrice then
                repairPrice = not self.mobileWorkshop
            end
            self.canBeSold = repairPrice
        end
        self.sellButton:setDisabled(false)
        if vehicle.propertyState == VehiclePropertyState.OWNED then
            self:setButtonText(g_i18n:getText("button_sell"))
        elseif vehicle.propertyState == VehiclePropertyState.LEASED then
            self:setButtonText(g_i18n:getText("button_return"))
        elseif vehicle.propertyState == VehiclePropertyState.MISSION then
            self.sellButton:setDisabled(true)
        end
        local repairPrice = vehicle:getRepairPrice()
        if repairPrice >= 1 then
            self.repairButton:setText(string.format("%s (%s)", g_i18n:getText("button_repair"), g_i18n:formatMoney(repairPrice, 0, true, true)))
        else
            self.repairButton:setLocaKey("button_repair")
        end
        local repaintPrice = self.repairButton
        repaintPrice:setDisabled(repairPrice < 1)
        local repaintPrice = vehicle:getRepaintPrice()
        if repaintPrice >= 1 then
            self.repaintButton:setText(string.format("%s (%s)", g_i18n:getText("button_repaint"), g_i18n:formatMoney(repaintPrice, 0, true, true)))
        else
            self.repaintButton:setLocaKey("button_repaint")
        end
        self.repaintButton:setDisabled(repaintPrice < 1 or vehicle.propertyState == VehiclePropertyState.MISSION)
    end
    self.configButton:setDisabled(not self.canBeConfigured)
    self.configButton:setVisible(Platform.gameplay.hasVehicleConfigs)
    local repairPrice = self.sellButton
    repairPrice:setDisabled(vehicle == nil or self.isOwnWorkshop or (self.vehicle.propertyState == VehiclePropertyState.MISSION or not self.canBeSold))
    local repairPrice = self.sellButton
    repairPrice:setVisible(vehicle ~= nil and not self.isOwnWorkshop and self.vehicle.propertyState ~= VehiclePropertyState.MISSION)
    local repairPrice = self.repaintButton
    repairPrice:setVisible(not self.isOwnWorkshop and Platform.gameplay.hasVehicleDamage)
    self.repairButton:setVisible(Platform.gameplay.hasVehicleDamage)
    local repairPrice = self.dialogInfo
    repairPrice:setVisible(vehicle ~= nil)
    self.buttonsBox:invalidateLayout()
end
function WorkshopScreen:setButtonText(text)
    self.sellButton:setText(text)
end
function WorkshopScreen.setStatusBarValue(_, bar, value)
    local minSize = (bar.lastStatusBarValue or -1) - value
    if math.abs(minSize) > 0.01 then
        local minSize = 0
        if bar.startSize ~= nil then
            minSize = bar.startSize[1] + bar.endSize[1]
        end
        bar:setSize(math.max(minSize, (bar.parent.size[1] - bar.margin[1] * 2) * math.min(value, 1)), nil)
        bar.lastStatusBarValue = value
    end
end
function WorkshopScreen:updateBalanceText()
    local balance = g_currentMission ~= nil and g_currentMission:getMoney() or 0
    self.lastBalance = balance
    self.balanceElement:setValue(balance)
    if balance > 0 then
        self.balanceElement:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY)
    else
        self.balanceElement:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE)
    end
    if self.moneyBox ~= nil then
        self.moneyBox:invalidateLayout()
        self.moneyBoxBg:setSize(self.moneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
    end
end
function WorkshopScreen:onClickBack(_)
    WorkshopScreen:superClass().onClickBack(self)
    self.vehicle = nil
    self.vehicles = {}
    self:changeScreen(nil)
end
function WorkshopScreen:onClickRepair()
    if self.vehicle == nil or self.vehicle:getRepairPrice(true) < 1 then
        return false
    end
    local text = string.format(g_i18n:getText("ui_repairDialog"), g_i18n:formatMoney(self.vehicle:getRepairPrice(true)))
    YesNoDialog.show(self.onYesNoRepairDialog, self, text, nil, nil, nil, nil, GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
    return true
end
function WorkshopScreen:onClickRepaint()
    if self.vehicle == nil or self.vehicle:getRepaintPrice() < 1 then
        return false
    end
    local text = string.format(g_i18n:getText("ui_repaintDialog"), g_i18n:formatMoney(self.vehicle:getRepaintPrice()))
    YesNoDialog.show(self.onYesNoRepaintDialog, self, text, nil, nil, nil, nil, GuiSoundPlayer.SOUND_SAMPLES.CONFIG_SPRAY)
    return true
end
function WorkshopScreen:onClickConfigure()
    if not self.canBeConfigured then
        return true
    end
    self:changeScreen(ShopConfigScreen, nil, WorkshopScreen)
    g_shopConfigScreen:setReturnScreenClass(WorkshopScreen)
    g_shopConfigScreen:setStoreItem(self.storeItem, self.vehicle, nil, self.isOwnWorkshop and 0 or EconomyManager.CONFIG_CHANGE_PRICE)
    g_shopConfigScreen:setCallbacks(self.setConfigurations, self)
    return false
end
function WorkshopScreen:onClickSell()
    if self.vehicle == nil or (self.isOwnWorkshop or (self.vehicle.propertyState == VehiclePropertyState.MISSION or not self.canBeSold)) then
        return true
    end
    local storeItem = g_storeManager:getItemByXMLFilename(self.vehicle.configFileName)
    g_shopController:sell(storeItem, self.vehicle, true)
    return false
end
function WorkshopScreen:getNumberOfItemsInSection(_, _)
    return #self.vehicles
end
function WorkshopScreen:populateCellForItemInSection(_, _, index, cell)
    local vehicle = self.vehicles[index]
    cell:getAttribute("icon"):setImageFilename(vehicle:getImageFilename())
    local brandName = ""
    local brand = g_brandManager:getBrandByIndex(vehicle:getBrand())
    if brand ~= nil then
        brandName = brand.title .. " "
    end
    cell:getAttribute("name"):setText(brandName .. vehicle:getName())
    self:setVehicleDetails(self.vehicles[index], cell)
end
function WorkshopScreen:setVehicleDetails(vehicle, cell)
    local age = 0
    local operatingTime = 0
    if vehicle ~= nil then
        operatingTime = vehicle:getOperatingTime()
        age = vehicle.age
        if vehicle.propertyState == VehiclePropertyState.OWNED then
            local hours = math.floor(vehicle:getSellPrice() * EconomyManager.DIRECT_SELL_MULTIPLIER)
            local sellPrice = math.min(hours, vehicle:getPrice())
            cell:getAttribute("priceText"):setText(g_i18n:formatMoney(sellPrice))
        elseif vehicle.propertyState == VehiclePropertyState.LEASED then
            cell:getAttribute("priceText"):setText("-")
        elseif vehicle.propertyState == VehiclePropertyState.MISSION then
            cell:getAttribute("priceText"):setText("-")
        end
        if vehicle.getWearTotalAmount ~= nil then
            self:setStatusBarValue(cell:getAttribute("paintConditionBar"), 1 - vehicle:getWearTotalAmount())
        end
        local sellPrice = cell:getAttribute("paintConditionBar").parent
        sellPrice:setVisible(Platform.gameplay.hasVehicleDamage and vehicle.getWearTotalAmount ~= nil)
        if vehicle.getDamageAmount ~= nil then
            self:setStatusBarValue(cell:getAttribute("conditionBar"), 1 - vehicle:getDamageAmount())
        end
        local sellPrice = cell:getAttribute("conditionBar").parent
        sellPrice:setVisible(Platform.gameplay.hasVehicleDamage and vehicle.getDamageAmount ~= nil)
    end
    local sellPrice = operatingTime / 60000
    local hours = math.floor(sellPrice / 60)
    local sellPrice = math.floor((sellPrice - hours * 60) / 6) * 10
    cell:getAttribute("operatingHoursText"):setText(string.format(g_i18n:getText("shop_operatingTime"), hours, sellPrice))
    cell:getAttribute("ageText"):setText(string.format(g_i18n:getText("shop_age"), string.format("%d", age)))
end
function WorkshopScreen:onListSelectionChanged(_, _, index)
    self:setVehicle(self.vehicles[index])
end
function WorkshopScreen:onInfoDialogCallback() end
function WorkshopScreen:onYesNoRepaintDialog(yes)
    if yes then
        if g_currentMission:getMoney() < self.vehicle:getRepaintPrice() then
            InfoDialog.show(g_i18n:getText("shop_messageNotEnoughMoneyToBuy"))
            return
        end
        g_client:getServerConnection():sendEvent(WearableRepaintEvent.new(self.vehicle))
    end
end
function WorkshopScreen:onYesNoRepairDialog(yes)
    if yes then
        if g_currentMission:getMoney() < self.vehicle:getRepairPrice() then
            InfoDialog.show(g_i18n:getText("shop_messageNotEnoughMoneyToBuy"))
            return
        end
        g_client:getServerConnection():sendEvent(WearableRepairEvent.new(self.vehicle, true))
    end
end
function WorkshopScreen:onVehicleSold(_, isOwned, _)
    local text = g_i18n:getText("shop_messageSoldVehicle")
    if not isOwned then
        text = g_i18n:getText("shop_messageReturnedVehicle")
    end
    InfoDialog.show(text, self.onInfoDialogCallback, self, DialogElement.TYPE_INFO)
end
function WorkshopScreen.onVehicleSellFailed(_, isOwned, errorCode)
    local text
    if isOwned then
        if errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
            text = g_i18n:getText("shop_messageNoPermissionToSellVehicleText")
        elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
            text = g_i18n:getText("shop_messageSellVehicleInUse")
        else
            text = g_i18n:getText("shop_messageFailedToSellVehicle")
        end
    elseif errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
        text = g_i18n:getText("shop_messageNoPermissionToReturnVehicleText")
    elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
        text = g_i18n:getText("shop_messageReturnVehicleInUse")
    else
        text = g_i18n:getText("shop_messageFailedToReturnVehicle")
    end
    InfoDialog.show(text)
end
function WorkshopScreen:onVehicleChanged(success)
    if self.owner ~= nil then
        self.owner:openMenu()
    end
    if success then
        InfoDialog.show(g_i18n:getText("shop_messageConfigurationChanged"), self.onInfoDialogCallback, self, DialogElement.TYPE_INFO)
    else
        InfoDialog.show(g_i18n:getText("shop_messageConfigurationChangeFailed"), self.onInfoDialogCallback, self)
    end
end
function WorkshopScreen:onVehicleRepairEvent(vehicle, _)
    if vehicle == self.vehicle then
        self:setVehicle(vehicle)
    end
    self.needsListReload = true
end
function WorkshopScreen:onVehicleRepaintEvent(vehicle, _)
    if vehicle == self.vehicle then
        self:setVehicle(vehicle)
    end
    self.needsListReload = true
end
function WorkshopScreen:onVehicleSellEvent(isDirectSell, errorCode, sellPrice, isOwned, ownerFarmId)
    if isDirectSell then
        if errorCode == SellVehicleEvent.SELL_SUCCESS then
            self:onVehicleSold(sellPrice, isOwned, ownerFarmId)
        else
            self:onVehicleSellFailed(isOwned, errorCode)
        end
    else
        return
    end
end