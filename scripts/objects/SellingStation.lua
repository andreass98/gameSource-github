SellingStation = {}
SellingStation.PRICE_FALLING = 1
SellingStation.PRICE_CLIMBING = 2
SellingStation.PRICE_GREAT_DEMAND = 5
SellingStation.RANDOM_DELTA_IMPACT = 0.3
SellingStation.PRICE_DROP_DELAY = 3600000
SellingStation.NUM_PRICE_UPDATES_PER_FRAME = 5
local SellingStation_mt = Class(SellingStation, UnloadingStation)
InitStaticObjectClass(SellingStation, "SellingStation")
function SellingStation.new(isServer, isClient, customMt)
    -- upvalues: (copy) SellingStation_mt
    local self = UnloadingStation.new(isServer, isClient, customMt or SellingStation_mt)
    self.lastMoneyChange = -1
    self.incomeName = "harvestIncome"
    self.incomeNameWool = "soldWool"
    self.incomeNameMilk = "soldMilk"
    self.incomeNameBale = "soldBales"
    self.incomeNameProduct = "soldProducts"
    self.isSellingPoint = true
    self.allowMissions = true
    return self
end
function SellingStation:load(components, xmlFile, key, customEnv, i3dMappings, rootNode)
    if not SellingStation:superClass().load(self, components, xmlFile, key, customEnv, i3dMappings, rootNode) then
        return false
    end
    if #self.unloadTriggers == 0 then
        local fillTypeCategories = xmlFile:getValue(key .. "#fillTypeCategories")
        local fillTypeNames = xmlFile:getValue(key .. "#fillTypes")
        if fillTypeCategories ~= nil then
            for _, fillType in pairs(g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: SellingStation has invalid fillTypeCategory \'%s\'.")) do
                self.supportedFillTypes[fillType] = true
            end
        end
        if fillTypeNames ~= nil then
            for _, fillType in pairs(g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: SellingStation has invalid fillType \'%s\'.")) do
                self.supportedFillTypes[fillType] = true
            end
        end
    end
    self.fixedIncomeName = xmlFile:getValue(key .. "#incomeName", nil)
    self.appearsOnStats = xmlFile:getValue(key .. "#appearsOnStats", false)
    self.suppressWarnings = xmlFile:getValue(key .. "#suppressWarnings", false)
    self.allowMissions = xmlFile:getValue(key .. "#allowMissions", true)
    self.hasDynamic = xmlFile:getValue(key .. "#hasDynamic", true)
    local fillTypeCategories = xmlFile:getValue(key .. "#litersForFullPriceDrop")
    if fillTypeCategories ~= nil then
        self.priceDropPerLiter = (1 - EconomyManager.PRICE_DROP_MIN_PERCENT) / fillTypeCategories
    end
    local fillTypeNames = xmlFile:getValue(key .. "#fullPriceRecoverHours")
    if fillTypeNames == nil then
        self.priceRecoverPerSecond = 1
    else
        self.priceRecoverPerSecond = (1 - EconomyManager.PRICE_DROP_MIN_PERCENT) / (fillTypeNames * 60 * 60)
    end
    self.acceptedFillTypes = {}
    self.numFillTypesForSelling = 0
    self.fillTypeSupportsGreatDemand = {}
    self.priceDropDisabled = {}
    self.originalFillTypePricesUnscaled = {}
    self.originalFillTypePrices = {}
    self.fillTypePrices = {}
    self.fillTypePriceInfo = {}
    self.fillTypePriceRandomDelta = {}
    self.priceMultipliers = {}
    self.totalReceived = {}
    self.totalPaid = {}
    self.pendingPriceDrop = {}
    self.prevFillLevel = {}
    self.prevTotalReceived = {}
    self.prevTotalPaid = {}
    self.lastUpdateTime = {}
    self.missions = {}
    for _, fillType in xmlFile:iterator(key .. ".fillType") do
        local fillTypeStr = xmlFile:getValue(fillType .. "#name")
        local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)
        if fillTypeIndex == nil then
            Logging.xmlWarning(xmlFile, "Invalid fillType \'%s\' in \'%s\'", fillTypeStr, fillType)
        elseif self.supportedFillTypes[fillTypeIndex] == nil then
            Logging.xmlWarning(xmlFile, "FillType \'%s\' is not supported by unload triggers for selling station", fillTypeStr)
        else
            local priceScale = xmlFile:getValue(fillType .. "#priceScale", 1)
            self:addAcceptedFillType(fillTypeIndex, g_fillTypeManager:getFillTypeByIndex(fillTypeIndex).pricePerLiter * priceScale, xmlFile:getValue(fillType .. "#supportsGreatDemand", true), (xmlFile:getValue(fillType .. "#disablePriceDrop", false)))
        end
    end
    for _, fillType in pairs(self.supportedFillTypes) do
        if self.acceptedFillTypes[_] == nil then
            self:addAcceptedFillType(_, g_fillTypeManager:getFillTypeByIndex(_).pricePerLiter, false, false)
        end
    end
    if self.isServer then
        self.moneyChangeType = MoneyType.register("soldMaterials", "finance_other")
    end
    self.priceDropTimer = 0
    self.pricingDynamics = {}
    self:initPricingDynamics()
    self.priceSyncTimerDuration = 30000
    self.priceSyncTimer = self.priceSyncTimerDuration
    self.unloadingStationDirtyFlag = self:getNextDirtyFlag()
    g_currentMission.economyManager:addSellingStation(self)
    return true
end
function SellingStation:delete()
    if self.missions ~= nil then
        for mission, _ in pairs(self.missions) do
            if mission.onDeleteSellingStation ~= nil then
                mission:onDeleteSellingStation(self)
            end
        end
    end
    SellingStation:superClass().delete(self)
end
function SellingStation:addAcceptedFillType(fillType, priceUnscaled, supportsGreatDemand, disablePriceDrop)
    if fillType == nil or self.acceptedFillTypes[fillType] ~= nil then
        return
    elseif priceUnscaled <= 0 then
        Logging.error("Cannot add fillType %q to selling station %q as it has no price defined", g_fillTypeManager:getFillTypeNameByIndex(fillType), self:getName() or self.rootNodeName)
    else
        self.acceptedFillTypes[fillType] = true
        self.fillTypeSupportsGreatDemand[fillType] = supportsGreatDemand
        if supportsGreatDemand then
            self.supportsGreatDemand = true
        end
        self.priceDropDisabled[fillType] = disablePriceDrop
        self.originalFillTypePricesUnscaled[fillType] = priceUnscaled
        self.originalFillTypePrices[fillType] = priceUnscaled
        self.fillTypePrices[fillType] = priceUnscaled
        self.fillTypePriceInfo[fillType] = 0
        self.fillTypePriceRandomDelta[fillType] = 0
        self.priceMultipliers[fillType] = 1
        self.totalReceived[fillType] = 0
        self.totalPaid[fillType] = 0
        self.pendingPriceDrop[fillType] = 0
        self.prevFillLevel[fillType] = 0
        self.prevTotalReceived[fillType] = 0
        self.prevTotalPaid[fillType] = 0
        self.lastUpdateTime[fillType] = 0
        self.numFillTypesForSelling = 0
        for acceptedFillType, _ in pairs(self.acceptedFillTypes) do
            if self.originalFillTypePrices[acceptedFillType] > 0 then
                self.numFillTypesForSelling = self.numFillTypesForSelling + 1
            end
        end
    end
end
function SellingStation:readStream(streamId, connection)
    local moneyTypeId = streamReadUInt16(streamId)
    self.moneyChangeType = MoneyType.registerWithId(moneyTypeId, "soldMaterials", "finance_other")
    SellingStation:superClass().readStream(self, streamId, connection)
    if connection:getIsServer() then
        local numFillTypes = streamReadUInt8(streamId)
        for i = 1, numFillTypes do
            local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
            self.fillTypePrices[fillType] = streamReadUInt16(streamId) / 1000
            self.fillTypePriceInfo[fillType] = streamReadUIntN(streamId, 6)
        end
    end
end
function SellingStation:writeStream(streamId, connection)
    streamWriteUInt16(streamId, self.moneyChangeType.id)
    SellingStation:superClass().writeStream(self, streamId, connection)
    if not connection:getIsServer() then
        streamWriteUInt8(streamId, self.numFillTypesForSelling)
        if self.numFillTypesForSelling > 0 then
            for fillType, _ in pairs(self.acceptedFillTypes) do
                if self.originalFillTypePrices[fillType] > 0 then
                    streamWriteUIntN(streamId, fillType, FillTypeManager.SEND_NUM_BITS)
                    local price = math.floor(self:getEffectiveFillTypePrice(fillType) * 1000 + 0.5)
                    streamWriteUInt16(streamId, (math.min(price, 65535)))
                    streamWriteUIntN(streamId, self:getCurrentPricingTrend(fillType), 6)
                end
            end
        end
    end
end
function SellingStation:readUpdateStream(streamId, timestamp, connection)
    SellingStation:superClass().readUpdateStream(self, streamId, timestamp, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        local numFillTypes = streamReadUInt8(streamId)
        for i = 1, numFillTypes do
            local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
            self.fillTypePrices[fillType] = streamReadUInt16(streamId) / 1000
            self.fillTypePriceInfo[fillType] = streamReadUIntN(streamId, 6)
        end
    end
end
function SellingStation:writeUpdateStream(streamId, connection, dirtyMask)
    SellingStation:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local price = self.unloadingStationDirtyFlag
        if streamWriteBool(streamId, bit32.band(dirtyMask, price) ~= 0) then
            streamWriteUInt8(streamId, self.numFillTypesForSelling)
            if self.numFillTypesForSelling > 0 then
                for fillType, _ in pairs(self.acceptedFillTypes) do
                    if self.originalFillTypePrices[fillType] > 0 then
                        streamWriteUIntN(streamId, fillType, FillTypeManager.SEND_NUM_BITS)
                        local price = math.floor(self:getEffectiveFillTypePrice(fillType) * 1000 + 0.5)
                        streamWriteUInt16(streamId, (math.min(price, 65535)))
                        streamWriteUIntN(streamId, self:getCurrentPricingTrend(fillType), 6)
                    end
                end
            end
        end
    end
end
function SellingStation:update(_)
    if self.lastMoneyChange > 0 then
        self.lastMoneyChange = self.lastMoneyChange - 1
        if self.lastMoneyChange == 0 then
            g_currentMission:showMoneyChange(self.moneyChangeType, "finance_" .. self.lastIncomeName, false, self.lastMoneyChangeFarmId)
        end
        self:raiseActive()
    end
end
function SellingStation:updateSellingStation(dt, scaledDt) end
function SellingStation:updatePrices(dt) end
function SellingStation:updateSellingStationPrices()
    if not self.hasDynamic then
        return true
    end
    if not self.isServer then
        return true
    end
    local currentTime = g_currentMission.time
    if self.priceSyncTimer < currentTime then
        self:raiseDirtyFlags(self.unloadingStationDirtyFlag)
        self.priceSyncTimer = currentTime + self.priceSyncTimerDuration
    end
    local fillType = self.currentUpdateFillType
    local i = 0
    while SellingStation.NUM_PRICE_UPDATES_PER_FRAME > i do
        fillType = next(self.acceptedFillTypes, fillType)
        self.currentUpdateFillType = fillType
        if self.currentUpdateFillType == nil then
            return true
        end
        local deltaTime = currentTime - self.lastUpdateTime[fillType]
        local isGreatDemandFillType = self.isGreatDemandActive
        if isGreatDemandFillType then
            isGreatDemandFillType = self.greatDemandFillType == fillType
        end
        if deltaTime > 0 and not isGreatDemandFillType then
            self:updateFillTypePrice(fillType, deltaTime)
        end
        self.lastUpdateTime[fillType] = currentTime
        i = i + 1
        if next(self.acceptedFillTypes, fillType) == nil then
            self.currentUpdateFillType = nil
            return true
        end
    end
    return false
end
function SellingStation:updateFillTypePrice(fillType, dt)
    self.pricingDynamics[fillType]:update(dt)
    self.fillTypePriceRandomDelta[fillType] = self.pricingDynamics[fillType]:evaluate()
    self.fillTypePriceInfo[fillType] = Utils.clearBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_CLIMBING)
    self.fillTypePriceInfo[fillType] = Utils.clearBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_FALLING)
    local trend = self:getTrend(fillType)
    if trend == PricingDynamics.TREND_FALLING then
        self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_FALLING)
    elseif trend == PricingDynamics.TREND_CLIMBING then
        self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_CLIMBING)
    end
    self.fillTypePrices[fillType] = math.min(self.fillTypePrices[fillType] + self.priceRecoverPerSecond * dt * 0.001 * self.originalFillTypePrices[fillType], self.originalFillTypePrices[fillType])
end
function SellingStation:loadFromXMLFile(xmlFile, key)
    local i = 0
    while true do
        local statsKey = string.format(key .. ".stats(%d)", i)
        if not xmlFile:hasProperty(statsKey) then
            break
        end
        local fillTypeStr = xmlFile:getValue(statsKey .. "#fillType")
        local fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)
        if fillType ~= nil and self.acceptedFillTypes[fillType] then
            self.totalReceived[fillType] = xmlFile:getValue(statsKey .. "#received", 0)
            self.totalPaid[fillType] = xmlFile:getValue(statsKey .. "#paid", 0)
            self.pricingDynamics[fillType]:loadFromXMLFile(xmlFile, statsKey)
        end
        i = i + 1
    end
    return true
end
function SellingStation:saveToXMLFile(xmlFile, key, usedModNames)
    local index = 0
    for fillTypeIndex, _ in pairs(self.acceptedFillTypes) do
        if self.originalFillTypePrices[fillTypeIndex] > 0 then
            local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
            local statsKey = string.format("%s.stats(%d)", key, index)
            xmlFile:setValue(statsKey .. "#fillType", fillTypeName)
            xmlFile:setValue(statsKey .. "#received", self.totalReceived[fillTypeIndex])
            xmlFile:setValue(statsKey .. "#paid", self.totalPaid[fillTypeIndex])
            self.pricingDynamics[fillTypeIndex]:saveToXMLFile(xmlFile, statsKey, usedModNames)
            index = index + 1
        end
    end
end
function SellingStation:getName()
    return self.stationName or self.owningPlaceable and self.owningPlaceable:getName() or "Selling Station"
end
function SellingStation:getIsFillTypeAllowed(fillTypeIndex, _)
    return self.acceptedFillTypes[fillTypeIndex] and true or false
end
function SellingStation:addFillLevelFromTool(farmId, deltaFillLevel, fillTypeIndex, fillInfo, toolType, extraAttributes)
    if deltaFillLevel > 0 then
        local storeGoods = self:getStoreGoods(farmId, fillTypeIndex)
        local storageAccess = not storeGoods or self:getIsFillAllowedFromFarm(farmId)
        if self:getIsFillTypeAllowed(fillTypeIndex, extraAttributes) and storageAccess then
            local usedMission = nil
            local highestProgress = 0
            local usedByMission = false
            for _, mission in pairs(self.missions) do
                if mission.fillSold ~= nil and (mission.fillTypeIndex == fillTypeIndex and mission.farmId == farmId) then
                    local progress = mission:getCompletion()
                    if highestProgress < progress then
                        usedMission = mission
                        highestProgress = progress
                    end
                end
            end
            if usedMission ~= nil then
                usedMission:fillSold(deltaFillLevel)
                usedByMission = true
            end
            if storeGoods and not usedByMission then
                deltaFillLevel = SellingStation:superClass().addFillLevelFromTool(self, farmId, deltaFillLevel, fillTypeIndex, fillInfo, toolType, extraAttributes)
            else
                self:startFx(fillTypeIndex)
            end
            if not usedByMission and (not self:getSkipSell(farmId, fillTypeIndex) and deltaFillLevel > 0.001) then
                self:sellFillType(farmId, deltaFillLevel, fillTypeIndex, toolType, extraAttributes)
            end
        else
            deltaFillLevel = 0
        end
        self:activateSimpleFillplanes(fillTypeIndex)
    else
        deltaFillLevel = movedFillLevel
    end
    return deltaFillLevel
end
function SellingStation:getStoreGoods(farmId, fillTypeIndex)
    return false
end
function SellingStation:getSkipSell(farmId, fillTypeIndex)
    return false
end
function SellingStation:sellFillType(farmId, fillDelta, fillTypeIndex, toolType, extraAttributes)
    if not self.priceDropDisabled[fillTypeIndex] then
        self:doPriceDrop(fillDelta, fillTypeIndex)
    end
    local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
    fillType.totalAmount = fillType.totalAmount + fillDelta
    self.totalReceived[fillTypeIndex] = self.totalReceived[fillTypeIndex] + fillDelta
    local pricePerLiter = self:getEffectiveFillTypePrice(fillTypeIndex, toolType)
    local priceScale = 1
    if extraAttributes ~= nil then
    end
    local price = fillDelta * pricePerLiter * priceScale
    self.totalPaid[fillTypeIndex] = self.totalPaid[fillTypeIndex] + price
    self.lastIncomeName = self:getIncomeNameForFillType(fillTypeIndex, toolType)
    self.moneyChangeType.statistic = self.lastIncomeName
    g_currentMission:addMoney(price, farmId, self.moneyChangeType, true)
    self.lastMoneyChange = 30
    self.lastMoneyChangeFarmId = farmId
    self:raiseActive()
    return price
end
function SellingStation:getEffectiveFillTypePrice(fillType, _)
    if self.fillTypePrices[fillType] == nil then
        log("Missing filltype", g_fillTypeManager:getFillTypeNameByIndex(fillType), (tostring(self:getName())))
        printCallstack()
    end
    if not self.isServer then
        return self.fillTypePrices[fillType]
    end
    local period, alpha = g_currentMission.environment:getPeriodAndAlphaIntoPeriod()
    local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillType)
    local seasonalFactor = g_currentMission.economyManager:getFillTypeSeasonalFactor(fillTypeDesc, period, alpha)
    return seasonalFactor == 0 and 0 or (self.fillTypePrices[fillType] * seasonalFactor + self.fillTypePriceRandomDelta[fillType] * SellingStation.RANDOM_DELTA_IMPACT) * self.priceMultipliers[fillType] * EconomyManager.getPriceMultiplier()
end
function SellingStation:getIncomeNameForFillType(fillType, toolType)
    if self.fixedIncomeName == nil then
        if toolType == ToolType.BALE then
            return self.incomeNameBale
        elseif fillType == FillType.WOOL then
            return self.incomeNameWool
        elseif fillType == FillType.MILK then
            return self.incomeNameMilk
        elseif fillType == FillType.WOOD then
            return "soldWood"
        elseif g_fillTypeManager:getIsFillTypeInCategory(fillType, "PRODUCT") then
            return self.incomeNameProduct
        else
            return self.incomeName
        end
    else
        return self.fixedIncomeName
    end
end
function SellingStation:initPricingDynamics()
    local per = 172800000
    local perVar = 0.375 * per
    local per2 = 604800000
    local perVar2 = 0.2 * per2
    self.levelThreshold = 0.032
    local per = per / 1
    local perVar = perVar / 1
    local per2 = per2 / 1
    local perVar2 = perVar2 / 1
    for fillType, _ in pairs(self.acceptedFillTypes) do
        self.pricingDynamics[fillType] = PricingDynamics.new(0, 0.04 * self.originalFillTypePrices[fillType], 0.15 * self.originalFillTypePrices[fillType], PricingDynamics.AMP_DIST_LINEAR_DOWN, per, perVar, PricingDynamics.AMP_DIST_CONSTANT, 0.3, 0.75)
        self.pricingDynamics[fillType]:addCurve(0.02 * self.originalFillTypePrices[fillType], 0.02 * self.originalFillTypePrices[fillType], PricingDynamics.AMP_DIST_CONSTANT, per2, perVar2, PricingDynamics.AMP_DIST_CONSTANT)
    end
end
function SellingStation:executePriceDrop(priceDrop, fillType) end
function SellingStation:doPriceDrop(fillLevel, fillType) end
function SellingStation:getTrend(fillType)
    local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillType)
    local randomDelta2 = self.pricingDynamics[fillType]:evaluateForTrend(14400000) / self.fillTypePrices[fillType]
    local period, alpha = g_currentMission.environment:getPeriodAndAlphaIntoPeriod()
    local alpha2 = alpha + 0.16666666666666666 / g_currentMission.environment.daysPerPeriod
    local period2
    if alpha2 > 1 then
        period2 = period + 1
    else
        period2 = period
    end
    local seasonalFactor1 = g_currentMission.economyManager:getFillTypeSeasonalFactor(fillTypeDesc, period, alpha)
    local seasonalFactor2 = g_currentMission.economyManager:getFillTypeSeasonalFactor(fillTypeDesc, period2, alpha2)
    local delta = seasonalFactor2 + randomDelta2 * SellingStation.RANDOM_DELTA_IMPACT - (seasonalFactor1 + self.fillTypePriceRandomDelta[fillType] / self.fillTypePrices[fillType] * SellingStation.RANDOM_DELTA_IMPACT)
    if math.abs(delta) < 0.002 then
        return PricingDynamics.TREND_PLATEAU
    elseif delta > 0 then
        return PricingDynamics.TREND_CLIMBING
    else
        return PricingDynamics.TREND_FALLING
    end
end
function SellingStation:setPriceMultiplier(fillType, priceMultiplier)
    self.priceMultipliers[fillType] = priceMultiplier
end
function SellingStation:getSupportsGreatDemand(fillType)
    if fillType == nil or self.fillTypeSupportsGreatDemand[fillType] == nil then
        return false
    else
        return self.fillTypeSupportsGreatDemand[fillType]
    end
end
function SellingStation:setIsInGreatDemand(fillType, isInGreatDemand)
    if isInGreatDemand then
        self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_GREAT_DEMAND)
        self.isGreatDemandActive = true
        self.greatDemandFillType = fillType
    else
        if self.greatDemandFillType ~= nil and self.fillTypePriceInfo[self.greatDemandFillType] ~= nil then
            self.fillTypePriceInfo[self.greatDemandFillType] = Utils.clearBit(self.fillTypePriceInfo[self.greatDemandFillType], SellingStation.PRICE_GREAT_DEMAND)
        end
        self.isGreatDemandActive = false
        self.greatDemandFillType = FillType.UNKNOWN
    end
    self:raiseDirtyFlags(self.unloadingStationDirtyFlag)
    self.priceSyncTimer = self.priceSyncTimerDuration
end
function SellingStation:getPriceMultiplier(fillType)
    return self.priceMultipliers[fillType]
end
function SellingStation:getTotalReceived(fillType)
    return self.totalReceived[fillType]
end
function SellingStation:getTotalPaid(fillType)
    return self.totalPaid[fillType]
end
function SellingStation:getCurrentPricingTrend(fillType)
    return self.fillTypePriceInfo[fillType]
end
function SellingStation:getFreeCapacity(fillTypeIndex, farmId)
    return not self:getStoreGoods(farmId, fillTypeIndex) and math.huge or SellingStation:superClass().getFreeCapacity(self, fillTypeIndex, farmId)
end
function SellingStation:getIsFillAllowedFromFarm(farmId)
    return not self:getStoreGoods(farmId, nil) and true or SellingStation:superClass().getIsFillAllowedFromFarm(self, farmId)
end
function SellingStation:getAppearsOnStats()
    return self.appearsOnStats
end
function SellingStation.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. "#appearsOnStats", "Appears on Stats", false)
    schema:register(XMLValueType.BOOL, basePath .. "#suppressWarnings", "Suppress warnings", false)
    schema:register(XMLValueType.BOOL, basePath .. "#allowMissions", "Allow missions", true)
    schema:register(XMLValueType.BOOL, basePath .. "#hasDynamic", "Has dynamic prices", true)
    schema:register(XMLValueType.INT, basePath .. "#litersForFullPriceDrop", "Liters for full price drop")
    schema:register(XMLValueType.FLOAT, basePath .. "#fullPriceRecoverHours", "Full price recover ingame hours")
    schema:register(XMLValueType.STRING, basePath .. "#fillTypeCategories", "Supported filltypes if no unloadtriggers defined")
    schema:register(XMLValueType.STRING, basePath .. "#fillTypes", "Supported filltypes if no unloadtriggers defined")
    schema:register(XMLValueType.STRING, basePath .. "#incomeName", "Income name for stats")
    schema:register(XMLValueType.STRING, basePath .. ".fillType(?)#name", "Fill type name")
    schema:register(XMLValueType.FLOAT, basePath .. ".fillType(?)#priceScale", "Price scale", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".fillType(?)#supportsGreatDemand", "Supports great demand", true)
    schema:register(XMLValueType.BOOL, basePath .. ".fillType(?)#disablePriceDrop", "Disable price drop", false)
    UnloadingStation.registerXMLPaths(schema, basePath)
end
function SellingStation.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".stats(?)#fillType", "Fill type")
    schema:register(XMLValueType.FLOAT, basePath .. ".stats(?)#received", "Recieved fill level", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".stats(?)#paid", "Payed fill level", 0)
    PricingDynamics.registerSavegameXMLPaths(schema, basePath .. ".stats(?)")
end
function SellingStation.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir)
    local fillTypeNames = nil
    local fillTypesNamesString = xmlFile:getValue("placeable.sellingStation#fillTypes")
    if not string.isNilOrWhitespace(fillTypesNamesString) then
        for _, fillTypeName in pairs(string.split(fillTypesNamesString, " ")) do
            ({})[fillTypeName] = true
        end
    end
    if xmlFile:hasProperty("placeable.sellingStation") then
        local unloadTriggerFillTypeNames = UnloadTrigger.loadSpecValueFillTypes(xmlFile, "placeable.sellingStation", customEnvironment, baseDir)
        if unloadTriggerFillTypeNames ~= nil then
            fillTypeNames = fillTypeNames or {}
            for fillTypeName in pairs(unloadTriggerFillTypeNames) do
                fillTypeNames[fillTypeName] = true
            end
        end
    end
    if PlaceableConstructible ~= nil and xmlFile:hasProperty("placeable.constructible") then
        fillTypeNames = PlaceableConstructible.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir, fillTypeNames)
    end
    return fillTypeNames
end
function SellingStation.getSpecValueFillTypes(storeItem, _)
    if storeItem.specs.sellingStationFillTypes == nil then
        return nil
    else
        return g_fillTypeManager:getFillTypesByNames(table.concatKeys(storeItem.specs.sellingStationFillTypes, " "))
    end
end