PlaceableProductionPoint = {}
function PlaceableProductionPoint.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableInfoTrigger, specializations)
end
function PlaceableProductionPoint.registerEvents(placeableType)
    SpecializationUtil.registerEvent(placeableType, "onOutputFillTypesChanged")
    SpecializationUtil.registerEvent(placeableType, "onProductionStatusChanged")
end
function PlaceableProductionPoint.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "outputsChanged", PlaceableProductionPoint.outputsChanged)
    SpecializationUtil.registerFunction(placeableType, "productionStatusChanged", PlaceableProductionPoint.productionStatusChanged)
end
function PlaceableProductionPoint.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableProductionPoint.setOwnerFarmId)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableProductionPoint.collectPickObjects)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "canBuy", PlaceableProductionPoint.canBuy)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableProductionPoint.updateInfo)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "finalizeConstruction", PlaceableProductionPoint.finalizeConstruction)
end
function PlaceableProductionPoint.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableProductionPoint)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableProductionPoint)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableProductionPoint)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableProductionPoint)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableProductionPoint)
    SpecializationUtil.registerEventListener(placeableType, "onBuy", PlaceableProductionPoint)
end
function PlaceableProductionPoint.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("ProductionPoint")
    ProductionPoint.registerXMLPaths(schema, basePath .. ".productionPoint")
    schema:register(XMLValueType.BOOL, (basePath .. ".productionPoint") .. "#isFinalized", "If the production point is finalized and ready on start. E.g. constructible")
    ProductionPoint.registerXMLPaths(schema, basePath .. ".productionPoint.productionPointConfigurations.productionPointConfiguration(?).productionPoint")
    schema:register(XMLValueType.BOOL, (basePath .. ".productionPoint.productionPointConfigurations.productionPointConfiguration(?).productionPoint") .. "#isFinalized", "If the production point is finalized and ready on start. E.g. constructible")
    schema:setXMLSpecializationType()
end
function PlaceableProductionPoint.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("ProductionPoint")
    ProductionPoint.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType()
end
function PlaceableProductionPoint.initSpecialization()
    g_storeManager:addSpecType("prodPointInputFillTypes", "shopListAttributeIconInput", ProductionPoint.loadSpecValueInputFillTypes, ProductionPoint.getSpecValueInputFillTypes, StoreSpecies.PLACEABLE)
    g_storeManager:addSpecType("prodPointOutputFillTypes", "shopListAttributeIconOutput", ProductionPoint.loadSpecValueOutputFillTypes, ProductionPoint.getSpecValueOutputFillTypes, StoreSpecies.PLACEABLE)
    g_placeableConfigurationManager:addConfigurationType("productionPoint", g_i18n:getText("configuration_productionPoint"), "productionPoint", PlaceableConfigurationItem)
end
function PlaceableProductionPoint:onLoad(_)
    local productionPointConfigurationId = Utils.getNoNil(self.configurations.productionPoint, 1)
    local configKey = string.format("placeable.productionPoint.productionPointConfigurations.productionPointConfiguration(%d).productionPoint", productionPointConfigurationId - 1)
    local configKey = not self.xmlFile:hasProperty(configKey) and "placeable.productionPoint" or configKey
    local productionPoint = ProductionPoint.new(self.isServer, self.isClient, self.baseDirectory)
    productionPoint.owningPlaceable = self
    if productionPoint:load(self.components, self.xmlFile, configKey, self.customEnvironment, self.i3dMappings) then
        self.spec_productionPoint.productionPoint = productionPoint
        spec.isFinalized = self.xmlFile:getBool(configKey .. "#isFinalized", true)
        if not spec.isFinalized then
            productionPoint.isFinalized = false
            productionPoint.unloadingStation.hideFromPricesMenu = true
            spec.unloadingStationDefaultAllowMissions = productionPoint.unloadingStation.allowMissions
            productionPoint.unloadingStation.allowMissions = false
            return
        end
    else
        productionPoint:delete()
        self:setLoadingState(PlaceableLoadingState.ERROR)
    end
end
function PlaceableProductionPoint:onDelete()
    local spec = self.spec_productionPoint
    if spec.productionPoint ~= nil then
        spec.productionPoint:delete()
        spec.productionPoint = nil
    end
end
function PlaceableProductionPoint:onFinalizePlacement()
    local spec = self.spec_productionPoint
    if spec.productionPoint ~= nil then
        if self.getHasBuyingTrigger ~= nil and self:getHasBuyingTrigger() then
            spec.productionPoint.useInteractionTriggerForBuying = false
        end
        spec.productionPoint:register(true)
        local owner = self:getOwnerFarmId()
        if not spec.isFinalized then
            owner = AccessHandler.EVERYONE
        end
        spec.productionPoint:setOwnerFarmId(owner)
        spec.productionPoint:findStorageExtensions()
        spec.productionPoint:updateFxState()
    end
end
function PlaceableProductionPoint:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)
    self.spec_productionPoint.productionPoint:updateInfo(infoTable)
end
function PlaceableProductionPoint:outputsChanged(outputs, state)
    SpecializationUtil.raiseEvent(self, "onOutputFillTypesChanged", outputs, state)
end
function PlaceableProductionPoint:productionStatusChanged(production, status)
    SpecializationUtil.raiseEvent(self, "onProductionStatusChanged", production, status)
end
function PlaceableProductionPoint:onReadStream(streamId, connection)
    local spec = self.spec_productionPoint
    if spec.productionPoint ~= nil then
        local productionPointId = NetworkUtil.readNodeObjectId(streamId)
        spec.productionPoint:readStream(streamId, connection)
        g_client:finishRegisterObject(spec.productionPoint, productionPointId)
    end
end
function PlaceableProductionPoint:onWriteStream(streamId, connection)
    local spec = self.spec_productionPoint
    if spec.productionPoint ~= nil then
        NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.productionPoint))
        spec.productionPoint:writeStream(streamId, connection)
        g_server:registerObjectInStream(connection, spec.productionPoint)
    end
end
function PlaceableProductionPoint:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_productionPoint
    if spec.productionPoint ~= nil then
        spec.productionPoint:loadFromXMLFile(xmlFile, key)
    end
end
function PlaceableProductionPoint:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_productionPoint
    if spec.productionPoint ~= nil then
        spec.productionPoint:saveToXMLFile(xmlFile, key, usedModNames)
    end
end
function PlaceableProductionPoint:setOwnerFarmId(superFunc, farmId, noEventSend)
    superFunc(self, farmId, noEventSend)
    local spec = self.spec_productionPoint
    if spec.productionPoint ~= nil then
        local owner = self:getOwnerFarmId()
        if not spec.isFinalized then
            owner = AccessHandler.EVERYONE
        end
        spec.productionPoint:setOwnerFarmId(owner)
        if not spec.isFinalized then
            g_currentMission.productionChainManager:removeProductionPoint(spec.productionPoint)
        end
    end
end
function PlaceableProductionPoint:collectPickObjects(superFunc, node)
    local spec = self.spec_productionPoint
    if spec.productionPoint.loadingStation ~= nil then
        local i = 1
        for i = i, #spec.productionPoint.loadingStation.loadTriggers do
            if node == spec.productionPoint.loadingStation.loadTriggers[i].triggerNode then
                return
            end
        end
    end
    local i = 1
    for i = i, #spec.productionPoint.unloadingStation.unloadTriggers do
        if node == spec.productionPoint.unloadingStation.unloadTriggers[i].exactFillRootNode then
            return
        end
    end
    superFunc(self, node)
end
function PlaceableProductionPoint:canBuy(superFunc)
    if g_currentMission.productionChainManager:getHasFreeSlots() then
        return superFunc(self)
    else
        return false, g_i18n:getText("warning_maxNumOfProdPointsReached")
    end
end
function PlaceableProductionPoint:onBuy()
    local serverFarmId = g_currentMission:getFarmId()
    local numProductionPoints = 0
    for _, existingPlaceable in ipairs(g_currentMission.placeableSystem.placeables) do
        if existingPlaceable:getOwnerFarmId() == serverFarmId and existingPlaceable.spec_productionPoint ~= nil then
        end
    end
    g_achievementManager:tryUnlock("NumProductionPoints", numProductionPoints)
end
function PlaceableProductionPoint:finalizeConstruction(superFunc)
    superFunc(self)
    local spec = self.spec_productionPoint
    if spec.productionPoint ~= nil then
        spec.isFinalized = true
        spec.productionPoint.isFinalized = true
        spec.productionPoint:setOwnerFarmId(self:getOwnerFarmId(), true)
        spec.productionPoint.unloadingStation.hideFromPricesMenu = false
        spec.productionPoint.unloadingStation.allowMissions = spec.unloadingStationDefaultAllowMissions
    end
end