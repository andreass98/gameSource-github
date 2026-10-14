BuyingStation = {}
local BuyingStation_mt = Class(BuyingStation, LoadingStation)
InitStaticObjectClass(BuyingStation, "BuyingStation")
function BuyingStation.new(isServer, isClient, customMt)
    -- upvalues: (copy) BuyingStation_mt
    local self = LoadingStation.new(isServer, isClient, customMt or BuyingStation_mt)
    self.incomeName = "other"
    self.incomeNameFuel = "purchaseFuel"
    self.incomeNameLime = "other"
    return self
end
function BuyingStation:load(components, xmlFile, key, customEnv, i3dMappings)
    if not BuyingStation:superClass().load(self, components, xmlFile, key, customEnv, i3dMappings) then
        return false
    end
    self.lastMoneyChange = 0
    self.providedFillTypes = {}
    self.fillTypePricesScale = {}
    self.fillTypeStatsName = {}
    local i = 0
    while true do
        local fillTypeKey = string.format(key .. ".fillType(%d)", i)
        if not xmlFile:hasProperty(fillTypeKey) then
            break
        end
        local fillTypeStr = xmlFile:getValue(fillTypeKey .. "#name")
        local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)
        local fillTypeStatsName = xmlFile:getValue(fillTypeKey .. "#statsName", "other")
        if FinanceStats.statNameToIndex[fillTypeStatsName] == nil then
            Logging.xmlWarning(xmlFile, "StatsName \'%s\' for fillType \'%s\' is not defined for buying station", fillTypeStatsName, fillTypeStr)
        end
        if fillTypeIndex ~= nil then
            if self.supportedFillTypes[fillTypeIndex] == nil then
                Logging.xmlWarning(xmlFile, "FillType \'%s\' is not supported by loading triggers for buying station", fillTypeStr)
            else
                local priceScale = xmlFile:getValue(fillTypeKey .. "#priceScale", 1)
                self.fillTypePricesScale[fillTypeIndex] = priceScale
                self.fillTypeStatsName[fillTypeIndex] = fillTypeStatsName
                self.providedFillTypes[fillTypeIndex] = true
            end
        end
        i = i + 1
    end
    for fillTypeStatsName in pairs(self.supportedFillTypes) do
        if self.fillTypePricesScale[fillTypeStatsName] == nil then
            self.fillTypePricesScale[fillTypeStatsName] = 1
            self.fillTypeStatsName[fillTypeStatsName] = "other"
            self.providedFillTypes[fillTypeStatsName] = true
        end
    end
    if self.isServer then
        self.moneyChangeType = MoneyType.register("other", "finance_other")
    end
    return true
end
function BuyingStation:readStream(streamId, connection)
    local moneyTypeId = streamReadUInt16(streamId)
    self.moneyChangeType = MoneyType.registerWithId(moneyTypeId, "other", "finance_other")
    BuyingStation:superClass().readStream(self, streamId, connection)
end
function BuyingStation:writeStream(streamId, connection)
    streamWriteUInt16(streamId, self.moneyChangeType.id)
    BuyingStation:superClass().writeStream(self, streamId, connection)
end
function BuyingStation:update(_)
    if self.lastMoneyChange > 0 then
        self.lastMoneyChange = self.lastMoneyChange - 1
        if self.lastMoneyChange == 0 then
            g_currentMission:showMoneyChange(self.moneyChangeType, "finance_" .. self.lastIncomeName, false, self.lastMoneyChangeFarmId)
        end
        self:raiseActive()
    end
end
function BuyingStation:addSourceStorage(_)
    printError("Error: LoadingStation \'" .. tostring(self:getName()) .. "\' is a buying point and does not accept any storages!")
    return false
end
function BuyingStation:getAllFillLevels()
    local fillLevels = {}
    for fillType, _ in pairs(self.supportedFillTypes) do
        fillLevels[fillType] = 1
    end
    return fillLevels, 1
end
function BuyingStation:getEffectiveFillTypePrice(fillTypeIndex)
    local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
    return self.fillTypePricesScale[fillTypeIndex] * fillType.pricePerLiter * ((fillTypeIndex == FillType.DIESEL or fillTypeIndex == FillType.DEF) and 1 or EconomyManager.getPriceMultiplier(fillTypeIndex))
end
function BuyingStation:addFillLevelToFillableObject(fillableObject, fillUnitIndex, fillTypeIndex, fillDelta, fillInfo, toolType)
    if fillableObject == nil or (fillTypeIndex == FillType.UNKNOWN or (fillDelta == 0 or toolType == nil)) then
        return 0
    end
    local farmId = fillableObject:getOwnerFarmId()
    local price
    if g_currentMission:getMoney(farmId) > 0 then
        price = fillableObject:addFillUnitFillLevel(farmId, fillUnitIndex, fillDelta, fillTypeIndex, toolType, fillInfo)
        if price > 0 then
            local price = self:getEffectiveFillTypePrice(fillTypeIndex) * price
            self.lastIncomeName = self:getIncomeNameForFillType(fillTypeIndex, toolType)
            self.moneyChangeType.statistic = self.lastIncomeName
            g_currentMission:addMoney(-price, farmId, self.moneyChangeType, true)
            self.lastMoneyChangeFarmId = farmId
            self.lastMoneyChange = 30
            self:raiseActive()
            return price
        end
    else
        price = 0
    end
    return price
end
function BuyingStation:getIncomeNameForFillType(fillType, _)
    if fillType == FillType.DIESEL then
        return self.incomeNameFuel
    elseif fillType == FillType.LIME then
        return self.incomeNameLime
    elseif self.fillTypeStatsName[fillType] == nil then
        return self.incomeName
    else
        return self.fillTypeStatsName[fillType]
    end
end
function BuyingStation:getIsFillAllowedToFarm(farmId)
    return true
end
function BuyingStation:getIsFillTypeSupported(fillType)
    return self.providedFillTypes[fillType] == true
end
function BuyingStation.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".fillType(?)#name", "Fill type name")
    schema:register(XMLValueType.STRING, basePath .. ".fillType(?)#statsName", "Name in stats", "other")
    schema:register(XMLValueType.FLOAT, basePath .. ".fillType(?)#priceScale", "Price scale", 1)
    LoadingStation.registerXMLPaths(schema, basePath)
end
function BuyingStation.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir)
    local fillTypeNames = nil
    local fillTypesNamesString = xmlFile:getValue("placeable.buyingStation#fillTypes")
    if fillTypesNamesString ~= nil and fillTypesNamesString:trim() ~= "" then
        for _, fillTypeName in pairs(string.split(fillTypesNamesString, " ")) do
            ({})[string.upper(fillTypeName)] = true
        end
    end
    for _, fillTypeName in xmlFile:iterator("placeable.buyingStation.loadTrigger") do
        local fillTypeNamesString = xmlFile:getValue(fillTypeName .. "#fillTypes")
        if fillTypeNamesString ~= nil and fillTypeNamesString:trim() ~= "" then
            fillTypeNames = fillTypeNames or {}
            for _, fillTypeName in pairs(string.split(fillTypeNamesString, " ")) do
                fillTypeNames[string.upper(fillTypeName)] = true
            end
        end
    end
    return PlaceableHeapSpawner.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir, fillTypeNames)
end
function BuyingStation.getSpecValueFillTypes(storeItem, _)
    if storeItem.specs.buyingStationFillTypes == nil then
        return nil
    else
        return g_fillTypeManager:getFillTypesByNames(table.concatKeys(storeItem.specs.buyingStationFillTypes, " "))
    end
end