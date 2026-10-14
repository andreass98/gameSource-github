ProductionChainManager = {}
ProductionChainManager.NUM_MAX_PRODUCTION_POINTS = 60
local ProductionChainManager_mt = Class(ProductionChainManager, AbstractManager)
function ProductionChainManager.new(isServer, customMt)
    -- upvalues: (copy) ProductionChainManager_mt
    local self = AbstractManager.new(customMt or ProductionChainManager_mt)
    self.isServer = isServer
    addConsoleCommand("gsProductionPointsList", "List all production points on map", "commandListProductionPoints", self)
    addConsoleCommand("gsProductionPointsPrintAutoDeliverMapping", "Prints which fillTypes are required by which production points", "commandPrintAutoDeliverMapping", self)
    addConsoleCommand("gsProductionPointSetOwner", "", "commandSetOwner", self)
    addConsoleCommand("gsProductionPointSetProductionState", "", "commandSetProductionState", self)
    addConsoleCommand("gsProductionPointSetOutputMode", "", "commandSetOutputMode", self)
    addConsoleCommand("gsProductionPointSetFillLevel", "", "commandSetFillLevel", self)
    if self.isServer then
        g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
    end
    return self
end
function ProductionChainManager:initDataStructures()
    self.productionPoints = {}
    self.reverseProductionPoint = {}
    self.factories = {}
    self.reverseFactory = {}
    self.farmIds = {}
    self.currentUpdateIndex = 1
    self.hourChangedDirty = false
    self.hourChangeUpdating = false
end
function ProductionChainManager:unloadMapData()
    removeConsoleCommand("gsProductionPointsList")
    removeConsoleCommand("gsProductionPointsPrintAutoDeliverMapping")
    removeConsoleCommand("gsProductionPointSetOwner")
    removeConsoleCommand("gsProductionPointSetProductionState")
    removeConsoleCommand("gsProductionPointSetOutputMode")
    removeConsoleCommand("gsProductionPointSetFillLevel")
    if self.isServer then
        g_messageCenter:unsubscribe(MessageType.HOUR_CHANGED, self)
    end
    ProductionChainManager:superClass().unloadMapData(self)
end
function ProductionChainManager:addProductionPoint(productionPoint)
    if self.reverseProductionPoint[productionPoint] then
        Logging.warning("Production point \'%s\' already registered.", productionPoint:tableId())
        return false
    end
    if #self.productionPoints >= ProductionChainManager.NUM_MAX_PRODUCTION_POINTS then
        printf("Maximum number of %i Production Points reached.", ProductionChainManager.NUM_MAX_PRODUCTION_POINTS)
        return false
    end
    if #self.productionPoints == 0 and self.isServer then
        g_currentMission:addUpdateable(self)
    end
    self.reverseProductionPoint[productionPoint] = true
    table.insert(self.productionPoints, productionPoint)
    local farmId = productionPoint:getOwnerFarmId()
    if farmId ~= AccessHandler.EVERYONE then
        if not self.farmIds[farmId] then
            self.farmIds[farmId] = {}
        end
        self:addProductionPointToFarm(productionPoint, self.farmIds[farmId])
    end
    return true
end
function ProductionChainManager.addProductionPointToFarm(_, productionPoint, farmTable)
    if not farmTable.productionPoints then
        farmTable.productionPoints = {}
    end
    table.insert(farmTable.productionPoints, productionPoint)
    if not farmTable.inputTypeToProductionPoints then
        farmTable.inputTypeToProductionPoints = {}
    end
    for inputType in pairs(productionPoint.inputFillTypeIds) do
        if not farmTable.inputTypeToProductionPoints[inputType] then
            farmTable.inputTypeToProductionPoints[inputType] = {}
        end
        table.insert(farmTable.inputTypeToProductionPoints[inputType], productionPoint)
    end
end
function ProductionChainManager:addFactory(factory)
    if self.reverseFactory[factory] then
        Logging.warning("Factory \'%s\' already registered.", factory:tableId())
        return false
    end
    self.reverseFactory[factory] = true
    table.insert(self.factories, factory)
    local farmId = factory:getOwnerFarmId()
    if farmId ~= AccessHandler.EVERYONE then
        if not self.farmIds[farmId] then
            self.farmIds[farmId] = {}
        end
        self:addFactoryToFarm(factory, self.farmIds[farmId])
    end
    return true
end
function ProductionChainManager.addFactoryToFarm(_, factory, farmTable)
    if not farmTable.factories then
        farmTable.factories = {}
    end
    table.insert(farmTable.factories, factory)
end
function ProductionChainManager:removeProductionPoint(productionPoint)
    self.reverseProductionPoint[productionPoint] = nil
    if table.removeElement(self.productionPoints, productionPoint) then
        local farmId = productionPoint:getOwnerFarmId()
        if farmId ~= AccessHandler.EVERYONE then
            self.farmIds[farmId] = self:removeProductionPointFromFarm(productionPoint, self.farmIds[farmId])
        end
    end
    if #self.productionPoints == 0 and self.isServer then
        g_currentMission:removeUpdateable(self)
    end
end
function ProductionChainManager.removeProductionPointFromFarm(_, productionPoint, farmTable)
    if farmTable.productionPoints == nil then
        return farmTable
    end
    table.removeElement(farmTable.productionPoints, productionPoint)
    for inputType in pairs(productionPoint.inputFillTypeIds) do
        if farmTable.inputTypeToProductionPoints[inputType] then
            if not table.removeElement(inputTypeToProductionPoints[inputType], productionPoint) then
                printError("Error: ProductionChainManager:removeProductionPoint(): Unable to remove production point from input type mapping")
            end
            if #inputTypeToProductionPoints[inputType] == 0 then
                inputTypeToProductionPoints[inputType] = nil
            end
        end
    end
    if #farmTable.productionPoints == 0 and farmTable.factories == nil then
        farmTable = nil
    end
    return farmTable
end
function ProductionChainManager:removeFactory(factory, farmId)
    self.reverseFactory[factory] = nil
    if table.removeElement(self.factories, factory) and (farmId ~= AccessHandler.EVERYONE and self.farmIds[farmId] ~= nil) then
        self.farmIds[farmId] = self:removeFactoryFromFarm(factory, self.farmIds[farmId])
    end
end
function ProductionChainManager.removeFactoryFromFarm(_, factory, farmTable)
    if farmTable.factories == nil then
        return farmTable
    end
    table.removeElement(farmTable.factories, factory)
    if #farmTable.factories == 0 and farmTable.productionPoints == nil then
        farmTable = nil
    end
    return farmTable
end
function ProductionChainManager:getProductionPointsForFarmId(farmId)
    return self.farmIds[farmId] and self.farmIds[farmId].productionPoints or {}
end
function ProductionChainManager:getFactoriesForFarmId(farmId)
    return self.farmIds[farmId] and self.farmIds[farmId].factories or {}
end
function ProductionChainManager:getNumOfProductionPoints()
    return #self.productionPoints
end
function ProductionChainManager:getUnownedProductionPoints()
    local unownedPoints = {}
    for _, point in pairs(self.productionPoints) do
        if point:getOwnerFarmId() == AccessHandler.EVERYONE then
            table.insert(unownedPoints, point)
        end
    end
    return unownedPoints
end
function ProductionChainManager:getUnownedFactories()
    local unownedFactories = {}
    for _, factory in pairs(self.factories) do
        if factory:getOwnerFarmId() == AccessHandler.EVERYONE then
            table.insert(unownedFactories, factory)
        end
    end
    return unownedFactories
end
function ProductionChainManager:getHasFreeSlots()
    return #self.productionPoints < ProductionChainManager.NUM_MAX_PRODUCTION_POINTS
end
function ProductionChainManager:update()
    if #self.productionPoints ~= 0 then
        if self.currentUpdateIndex > #self.productionPoints then
            self.currentUpdateIndex = 1
            if self.hourChangedDirty then
                self.hourChangeUpdating = true
                self.hourChangedDirty = false
            elseif self.hourChangeUpdating then
                self.hourChangeUpdating = false
                self:distributeGoods()
            end
        end
        local prodPoint = self.productionPoints[self.currentUpdateIndex]
        if prodPoint then
            prodPoint:updateProduction()
            if self.hourChangeUpdating and (self.isServer and prodPoint.isOwned) then
                prodPoint:claimProductionCosts()
                prodPoint:directlySellOutputs()
                prodPoint:updateBalaceDirectlySoldOutputs()
            end
        end
        self.currentUpdateIndex = self.currentUpdateIndex + 1
    end
end
function ProductionChainManager:hourChanged()
    self.hourChangedDirty = true
end
function ProductionChainManager:distributeGoods()
    if self.isServer then
        for _, farmTable in pairs(self.farmIds) do
            if farmTable.productionPoints ~= nil then
                local i = 1
                for i = i, #farmTable.productionPoints do
                    local distributingProdPoint = farmTable.productionPoints[i]
                    for fillTypeIdToDistribute in pairs(distributingProdPoint.outputFillTypeIdsAutoDeliver) do
                        local amountToDistribute = distributingProdPoint.storage:getFillLevel(fillTypeIdToDistribute)
                        if amountToDistribute > 0 then
                            local prodPointsInDemand = farmTable.inputTypeToProductionPoints[fillTypeIdToDistribute] or {}
                            local totalFreeCapacity = 0
                            local n = 1
                            for n = n, #prodPointsInDemand do
                                totalFreeCapacity = totalFreeCapacity + prodPointsInDemand[n].storage:getFreeCapacity(fillTypeIdToDistribute, true)
                            end
                            if totalFreeCapacity > 0 then
                                local n = 1
                                for n = n, #prodPointsInDemand do
                                    local prodPointInDemand = prodPointsInDemand[n]
                                    local maxAmountToReceive = prodPointInDemand.storage:getFreeCapacity(fillTypeIdToDistribute, true)
                                    if maxAmountToReceive > 0 then
                                        local amountToTransfer = math.min(maxAmountToReceive, amountToDistribute * (maxAmountToReceive / totalFreeCapacity))
                                        g_currentMission:addMoney(-(amountToTransfer * calcDistanceFrom(distributingProdPoint.owningPlaceable.rootNode, prodPointInDemand.owningPlaceable.rootNode) * ProductionPoint.DIRECT_DELIVERY_PRICE), prodPointInDemand.ownerFarmId, MoneyType.PRODUCTION_COSTS, true)
                                        prodPointInDemand.storage:setFillLevel(prodPointInDemand.storage:getFillLevel(fillTypeIdToDistribute) + amountToTransfer, fillTypeIdToDistribute)
                                        distributingProdPoint.storage:setFillLevel(distributingProdPoint.storage:getFillLevel(fillTypeIdToDistribute) - amountToTransfer, fillTypeIdToDistribute)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
function ProductionChainManager:updateBalance() end
function ProductionChainManager:commandListProductionPoints()
    if #self.productionPoints <= 0 then
        return "no productions points available"
    end
    print("available production points:")
    local i = 1
    for i = i, #self.productionPoints do
        print(string.format("%i: %s", i, self.productionPoints[i]:toString()))
    end
    return string.format("listed %i production points", #self.productionPoints)
end
function ProductionChainManager:commandPrintAutoDeliverMapping()
    print("AutoDeliverMapping")
    for farmId, farmTable in pairs(self.farmIds) do
        printf("  Farm %i", farmId)
        for inputType, prodPoints in pairs(farmTable.inputTypeToProductionPoints) do
            print(string.format("    FillType %s distributed to", g_fillTypeManager:getFillTypeNameByIndex(inputType)))
            for _, prodPoint in pairs(prodPoints) do
                print(string.format("      %s", prodPoint:toString()))
            end
        end
    end
end
function ProductionChainManager:commandSetOwner(ppIdentifier, farmId)
    local productionPoints = self:getProductionPointsFromString(ppIdentifier)
    farmId = tonumber(farmId)
    if productionPoints == false then
        return "Error: no production point given\nUsage: gsProductionPointSetOwner ppIdentifier farmId"
    end
    if farmId == nil then
        return "Error: no farmId given\nUsage: gsProductionPointSetOwner ppIdentifier farmId"
    end
    local productionPoints = table.clone(productionPoints)
    for _, prodPoint in pairs(productionPoints) do
        prodPoint:setOwnerFarmId(farmId, true)
    end
    return string.format("Updated owner for %d production points", table.size(productionPoints))
end
function ProductionChainManager:commandSetProductionState(ppIdentifier, productionIdentifier, state)
    local productionPoints = self:getProductionPointsFromString(ppIdentifier)
    local productions = Utils.stringToBoolean(state)
    if productionPoints == false then
        return "Error: no production point given\nUsage: gsProductionPointSetProductionState ppIdentifier productionIdentifier|all state"
    end
    if productionIdentifier == nil then
        return "Error: no production identifier given\nUsage: gsProductionPointSetProductionState ppIdentifier productionIdentifier|all state"
    end
    if productions == nil then
        return "Error: no valid state given\nUsage: gsProductionPointSetProductionState ppIdentifier productionIdentifier|all state"
    end
    local productions = {}
    for _, prodPoint in pairs(productionPoints) do
        if string.lower(productionIdentifier) == "all" then
            for _, production in pairs(prodPoint.productions) do
                table.insert(productions, { prodPoint, production })
            end
        else
            local production = prodPoint.productionsIdToObj[productionIdentifier]
            if production then
                table.insert(productions, { prodPoint, production })
            end
        end
    end
    if #productions == 0 then
        return string.format("Error: no productions found for identifier \'%s\'\n%s", productionIdentifier, "Usage: gsProductionPointSetProductionState ppIdentifier productionIdentifier|all state")
    end
    for _, prodPoint in pairs(productions) do
        local production = prodPoint[1]
        local production = prodPoint[2]
        production:setProductionState(production.id, productions)
        print(string.format("%s (%s): %s = %s", production:getName(), production:tableId(), production.id, productions))
    end
    return string.format("Updated state for %d productions", table.size(productions))
end
function ProductionChainManager:commandSetOutputMode(ppIdentifier, outputFillTypeIdentifier, mode)
    local productionPoints = self:getProductionPointsFromString(ppIdentifier)
    if productionPoints == false then
        return "Error: no production point given\nUsage: gsProductionPointSetOutputMode ppIdentifier outputFillType|all outputMode"
    end
    if not outputFillTypeIdentifier then
        return "Error: Missing argument outputFillType.\nUsage: gsProductionPointSetOutputMode ppIdentifier outputFillType|all outputMode"
    end
    if not table.hasElement(ProductionPoint.OUTPUT_MODE, (tonumber(mode))) then
        return string.format("Error: Invalid output mode \'%s\'. Available modes:\n%s", mode, (function()
            local str = {}
            for key, val in pairs(ProductionPoint.OUTPUT_MODE) do
                table.insert(str, val .. "=" .. key)
            end
            return table.concat(str, "\n")
        end)())
    end
    if string.lower(outputFillTypeIdentifier) == "all" then
        for _, _ in pairs(productionPoints) do
            for outputType in pairs(_.outputFillTypeIds) do
                _:setOutputDistributionMode(outputType, mode)
            end
        end
    else
        local outputType = g_fillTypeManager:getFillTypeIndexByName(outputFillTypeIdentifier)
        for _, prodPoint in pairs(productionPoints) do
            if prodPoint.outputFillTypeIds[outputType] then
                prodPoint:setOutputDistributionMode(outputType, mode)
            end
        end
    end
    return "Updated production points"
end
function ProductionChainManager:commandSetFillLevel(ppIdentifier, fillTypeIdentifier, fillLevel)
    local productionPoints = self:getProductionPointsFromString(ppIdentifier)
    if productionPoints == false then
        return "Error: no production point given\nUsage: gsProductionPointSetFillLevel ppIdentifier fillTypeName|all fillLevel"
    end
    local fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeIdentifier)
    if not fillTypeIdentifier or string.lower(fillTypeIdentifier) ~= "all" and not fillType then
        return "Error: no valid fillType given\nUsage: gsProductionPointSetFillLevel ppIdentifier fillTypeName|all fillLevel"
    end
    local numStorageSpaces = tonumber(fillLevel)
    if not numStorageSpaces then
        return "Error: no fillLevel given\nUsage: gsProductionPointSetFillLevel ppIdentifier fillTypeName|all fillLevel"
    end
    local numStorageSpaces = 0
    for _, prodPoint in pairs(productionPoints) do
        if string.lower(fillTypeIdentifier) == "all" then
            for supportedFillType in pairs(prodPoint.storage:getSupportedFillTypes()) do
                prodPoint.storage:setFillLevel(numStorageSpaces, supportedFillType)
            end
        elseif fillType and prodPoint.storage:getIsFillTypeSupported(fillType) then
            prodPoint.storage:setFillLevel(numStorageSpaces, fillType)
        end
    end
    return string.format("Filled %i storage spaces", numStorageSpaces)
end
function ProductionChainManager:consoleCommandToggleProdPointDebug()
    self.debugEnabled = not self.debugEnabled
    if g_currentMission ~= nil then
        for _, prodPoint in pairs(self.productionPoints) do
            if self.debugEnabled then
                g_currentMission:addDrawable(prodPoint)
            else
                g_currentMission:removeDrawable(prodPoint)
            end
        end
    end
    return "ProductionChainManager.debugEnabled=" .. tostring(self.debugEnabled)
end
function ProductionChainManager:getProductionPointsFromString(identificationString)
    if not identificationString or identificationString == "" then
        return false
    end
    if string.lower(identificationString) == "all" then
        return self.productionPoints
    end
    local prodPoint = self.productionPoints[tonumber(identificationString)]
    if not prodPoint and string.len(identificationString) >= 4 then
        for _, productionPoint in pairs(self.productionPoints) do
            if string.find(productionPoint:tableId(), identificationString) then
                if prodPoint ~= nil then
                    printError(string.format("Error: Multiple production points for index/identifier \'%s\'. Please provide a longer identifier.", identificationString))
                    self:commandListProductionPoints()
                    return false
                end
            end
        end
    end
    if prodPoint then
        table.insert({}, prodPoint)
        return prodPoints
    end
    printError(string.format("Error: No Production Point for index/identifier \'%s\'", identificationString))
    self:commandListProductionPoints()
    return false
end