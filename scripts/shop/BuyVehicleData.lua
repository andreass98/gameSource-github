BuyVehicleData = {}
local BuyVehicleData_mt = Class(BuyVehicleData)
function BuyVehicleData.new(customMt)
    -- upvalues: (copy) BuyVehicleData_mt
    local self = setmetatable({}, customMt or BuyVehicleData_mt)
    self.storeItem = nil
    self.isFreeOfCharge = false
    self.configurations = {}
    self.boughtConfigurations = {}
    self.configurationData = {}
    self.leaseVehicle = false
    self.ownerFarmId = AccessHandler.EVERYONE
    self.licensePlateData = nil
    self.saleItem = nil
    self.price = 0
    return self
end
function BuyVehicleData:isValid()
    if self.storeItem == nil then
        return false
    else
        return (not GS_IS_CONSOLE_VERSION or fileExists(self.storeItem.xmlFilename)) and true or false
    end
end
function BuyVehicleData:setStoreItem(storeItem)
    self.storeItem = storeItem
end
function BuyVehicleData:setIsFreeOfCharge(isFreeOfCharge)
    self.isFreeOfCharge = isFreeOfCharge
end
function BuyVehicleData:setConfigurations(configurations, boughtConfigurations)
    self.configurations = configurations or self.configurations
    self.boughtConfigurations = boughtConfigurations or self.boughtConfigurations
    for configName, index in pairs(self.configurations) do
        if self.boughtConfigurations[configName] == nil then
            self.boughtConfigurations[configName] = {}
        end
        self.boughtConfigurations[configName][index] = true
    end
end
function BuyVehicleData:setConfigurationData(configurationData)
    self.configurationData = configurationData or self.configurationData
end
function BuyVehicleData:setLeaseVehicle(leaseVehicle)
    self.leaseVehicle = leaseVehicle
end
function BuyVehicleData:setOwnerFarmId(ownerFarmId)
    self.ownerFarmId = ownerFarmId
end
function BuyVehicleData:setLicensePlateData(licensePlateData)
    self.licensePlateData = licensePlateData
end
function BuyVehicleData:setSaleItem(saleItem)
    self.saleItem = saleItem
end
function BuyVehicleData:setPrice(price)
    self.price = price
end
function BuyVehicleData:updatePrice()
    self.price = g_currentMission.economyManager:getBuyPrice(self.storeItem, self.configurations, self.saleItem)
    if self.leaseVehicle then
        self.price = g_currentMission.economyManager:getInitialLeasingPrice(self.price)
    end
end
function BuyVehicleData:getIsLimitedObjectPurchase()
    local xmlFile = XMLFile.load("BuyVehicleDataVehicleXML", self.storeItem.xmlFilename, nil)
    local isBalePurchase = xmlFile:hasProperty("vehicle.multipleItemPurchase")
    if isBalePurchase then
        isBalePurchase = xmlFile:getBool("vehicle.multipleItemPurchase#isVehicle") == false
    end
    local isPalletPurchase = xmlFile:hasProperty("vehicle.multipleItemPurchase")
    if isPalletPurchase then
        isPalletPurchase = xmlFile:getBool("vehicle.multipleItemPurchase#isVehicle")
    end
    xmlFile:delete()
    return isBalePurchase, isPalletPurchase
end
function BuyVehicleData:readStream(streamId, connection)
    local xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
    self.storeItem = g_storeManager:getItemByXMLFilename(string.lower(xmlFilename))
    self.isFreeOfCharge = streamReadBool(streamId)
    self.configurations, self.boughtConfigurations, self.configurationData = ConfigurationUtil.readConfigurationsFromStream(g_vehicleConfigurationManager, streamId, connection, xmlFilename)
    self.leaseVehicle = streamReadBool(streamId)
    self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.licensePlateData = LicensePlateManager.readLicensePlateData(streamId, connection)
    local saleId = streamReadUInt8(streamId)
    if saleId ~= 0 then
        self.saleItem = g_currentMission.vehicleSaleSystem:getSaleById(saleId)
    end
end
function BuyVehicleData:writeStream(streamId, connection)
    streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.storeItem.xmlFilename))
    streamWriteBool(streamId, self.isFreeOfCharge)
    ConfigurationUtil.writeConfigurationsToStream(g_vehicleConfigurationManager, streamId, connection, self.storeItem.xmlFilename, self.configurations, self.boughtConfigurations, self.configurationData)
    streamWriteBool(streamId, self.leaseVehicle)
    streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    LicensePlateManager.writeLicensePlateData(streamId, connection, self.licensePlateData)
    if self.saleItem == nil then
        streamWriteUInt8(streamId, 0)
    else
        streamWriteUInt8(streamId, self.saleItem.id)
    end
end
function BuyVehicleData:buy(storePlaces, usedStorePlaces, callback, callbackTarget, callbackArguments)
    local data = VehicleLoadingData.new()
    data:setStoreItem(self.storeItem)
    data:setConfigurations(self.configurations, self.boughtConfigurations)
    data:setConfigurationData(self.configurationData)
    data:setLoadingPlace(storePlaces, usedStorePlaces)
    data:setPropertyState(self.leaseVehicle and VehiclePropertyState.LEASED or VehiclePropertyState.OWNED)
    data:setOwnerFarmId(self.ownerFarmId)
    data:setSaleItem(self.saleItem)
    data:load(self.onBought, self, {
        ["callback"] = callback,
        ["callbackTarget"] = callbackTarget,
        ["callbackArguments"] = callbackArguments
    })
end
function BuyVehicleData:onBought(vehicles, loadingState, arguments)
    if loadingState == VehicleLoadingState.OK then
        for _, vehicle in pairs(vehicles) do
            if vehicle.setLicensePlatesData ~= nil and (vehicle.getHasLicensePlates ~= nil and vehicle:getHasLicensePlates()) then
                vehicle:setLicensePlatesData(self.licensePlateData)
            end
        end
        if not self.isFreeOfCharge then
            if self.leaseVehicle then
                g_currentMission:addMoney(-self.price, self.ownerFarmId, MoneyType.LEASING_COSTS, true)
            else
                local financeCategory = MoneyType.getMoneyTypeByName(self.storeItem.financeCategory) or MoneyType.SHOP_VEHICLE_BUY
                g_currentMission:addMoney(-self.price, self.ownerFarmId, financeCategory, true)
                if self.saleItem ~= nil then
                    g_currentMission.vehicleSaleSystem:onVehicleBought(self.saleItem)
                end
            end
        end
    end
    if arguments.callback ~= nil then
        arguments.callback(arguments.callbackTarget, vehicles, loadingState, arguments.callbackArguments)
    end
end