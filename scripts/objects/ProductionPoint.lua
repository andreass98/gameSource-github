source("dataS/scripts/objects/ProductionPointActivatable.lua")
ProductionPoint = {}
ProductionPoint.NO_PALLET_SPACE_COOLDOWN = 15000
ProductionPoint.DIRECT_SELL_PRICE_FACTOR = 0.9
ProductionPoint.DIRECT_DELIVERY_PRICE = 0.000035000000000000004
ProductionPoint.OUTPUT_MODE = {}
ProductionPoint.OUTPUT_MODE.KEEP = 0
ProductionPoint.OUTPUT_MODE.DIRECT_SELL = 1
ProductionPoint.OUTPUT_MODE.AUTO_DELIVER = 2
ProductionPoint.OUTPUT_MODE_NUM_BITS = 2
ProductionPoint.PROD_STATUS = {}
ProductionPoint.PROD_STATUS.INACTIVE = 0
ProductionPoint.PROD_STATUS.RUNNING = 1
ProductionPoint.PROD_STATUS.MISSING_INPUTS = 2
ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE = 3
ProductionPoint.PROD_STATUS_NUM_BITS = 2
ProductionPoint.PROD_STATUS_TO_L10N = {
    [ProductionPoint.PROD_STATUS.INACTIVE] = "ui_production_status_inactive",
    [ProductionPoint.PROD_STATUS.RUNNING] = "ui_production_status_running",
    [ProductionPoint.PROD_STATUS.MISSING_INPUTS] = "ui_production_status_materialsMissing",
    [ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE] = "ui_production_status_outOfSpace"
}
local ProductionPoint_mt = Class(ProductionPoint, Object)
function ProductionPoint.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#name", "Name of the Production Point", "unnamed production point")
    schema:register(XMLValueType.BOOL, basePath .. ".productions#sharedThroughputCapacity", "Productions slow each other down if active at the same time", true)
    schema:register(XMLValueType.STRING, basePath .. ".productions.production(?)#id", "Unique string used for identifying the production", nil, true)
    schema:register(XMLValueType.L10N_STRING, basePath .. ".productions.production(?)#name", "Name of the production used inside the UI", "unnamed production")
    schema:register(XMLValueType.STRING, basePath .. ".productions.production(?)#params", "Optional parameters formatted into #name")
    schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#cyclesPerMonth", "Number of performed production cycles per ingame month (divided by the number of enabled productions, unless sharedThroughputCapacity is set to false)", 1440)
    schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#cyclesPerHour", "Number of production cycles per ingame hour per day (==month) (divided by the number of enabled productions, unless sharedThroughputCapacity is set to false)", 60)
    schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#cyclesPerMinute", "Number of performed production cycles per ingame minute (divided by the number of enabled productions)", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#costsPerActiveMonth", "Costs per ingame hour if this production is enabled per ingame month (regardless of whether it is producing or not)", 1440)
    schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#costsPerActiveHour", "Costs per ingame hour if this production is enabled per day (==month) (regardless of whether it is producing or not)", 60)
    schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#costsPerActiveMinute", "Costs per ingame minute if this production is enabled (regardless of whether it is producing or not)", 1)
    schema:register(XMLValueType.STRING, basePath .. ".productions.production(?).inputs.input(?)#fillType", "Input fillType", nil, true)
    schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?).inputs.input(?)#amount", "Used amount per cycle", 1)
    schema:register(XMLValueType.STRING, basePath .. ".productions.production(?).outputs.output(?)#fillType", "Output fillType", nil, true)
    schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?).outputs.output(?)#amount", "Produced amount per cycle", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".productions.production(?).outputs.output(?)#sellDirectly", "Directly sell produced amount", false)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".playerTrigger#node", "", "")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "active")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "idle")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".productions.production(?).sounds", "active")
    AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".animationNodes")
    AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".productions.production(?).animationNodes")
    EffectManager.registerEffectXMLPaths(schema, basePath .. ".effectNodes")
    EffectManager.registerEffectXMLPaths(schema, basePath .. ".productions.production(?).effectNodes")
    SellingStation.registerXMLPaths(schema, basePath .. ".sellingStation")
    LoadingStation.registerXMLPaths(schema, basePath .. ".loadingStation")
    PalletSpawner.registerXMLPaths(schema, basePath .. ".palletSpawner")
    Storage.registerXMLPaths(schema, basePath .. ".storage")
end
function ProductionPoint.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#palletSpawnCooldown", "remaining cooldown duration of pallet spawner")
    schema:register(XMLValueType.FLOAT, basePath .. "#productionCostsToClaim", "production costs yet to be claimed from the owning player")
    schema:register(XMLValueType.STRING, basePath .. ".directSellFillType(?)", "fillType currently configured to be directly sold")
    schema:register(XMLValueType.STRING, basePath .. ".autoDeliverFillType(?)", "fillType currently configured to be automatically delivered")
    schema:register(XMLValueType.STRING, basePath .. ".production(?)#id", "Unique id of the production")
    schema:register(XMLValueType.BOOL, basePath .. ".production(?)#isEnabled", "State of the production")
    Storage.registerSavegameXMLPaths(schema, basePath .. ".storage")
end
InitStaticObjectClass(ProductionPoint, "ProductionPoint")
function ProductionPoint.new(isServer, isClient, baseDirectory, customMt)
    -- upvalues: (copy) ProductionPoint_mt
    local self = Object.new(isServer, isClient, customMt or ProductionPoint_mt)
    self.baseDirectory = baseDirectory
    self.owningPlaceable = nil
    self.isOwned = false
    self.mission = g_currentMission
    self.activeProductions = {}
    self.minuteFactorTimescaled = self.mission:getEffectiveTimeScale() / 1000 / 60
    self.waitingForPalletToSpawn = false
    self.palletSpawnCooldown = 0
    self.palletLimitReached = false
    self.isFinalized = true
    self.dirtyFlag = self:getNextDirtyFlag()
    self.inputFillLevels = {}
    self.productionCostsToClaim = 0
    self.soldFillTypesToPayOut = {}
    self.activatable = ProductionPointActivatable.new(self)
    g_messageCenter:subscribe(MessageType.TIMESCALE_CHANGED, self.onTimescaleChanged, self)
    self.infoTables = {
        ["activeProds"] = {
            ["title"] = g_i18n:getText("infohud_activeProductions"),
            ["accentuate"] = true
        },
        ["noActiveProd"] = {
            ["title"] = g_i18n:getText("infohud_noActiveProduction"),
            ["accentuate"] = true
        },
        ["storage"] = {
            ["title"] = g_i18n:getText("ui_productions_buildingStorage"),
            ["accentuate"] = true
        },
        ["storageEmpty"] = {
            ["title"] = "",
            ["text"] = g_i18n:getText("infohud_storageIsEmpty")
        },
        ["palletLimitReached"] = {
            ["title"] = g_i18n:getText("infohud_tooManyPallets"),
            ["accentuate"] = true
        }
    }
    return self
end
function ProductionPoint:load(components, xmlFile, key, customEnv, i3dMappings)
    self.node = components[1].node
    local name = xmlFile:getValue(key .. "#name")
    if name then
        name = g_i18n:convertText(name, customEnv)
    end
    self.name = name
    self.productions = {}
    self.productionsIdToObj = {}
    self.inputFillTypeIds = {}
    self.inputFillTypeIdsArray = {}
    self.outputFillTypeIds = {}
    self.outputFillTypeIdsArray = {}
    self.outputFillTypeIdsDirectSell = {}
    self.outputFillTypeIdsAutoDeliver = {}
    self.outputFillTypeIdsToPallets = {}
    self.sharedThroughputCapacity = xmlFile:getValue(key .. ".productions#sharedThroughputCapacity", true)
    local usedProdIds = {}
    xmlFile:iterate(key .. ".productions.production", function(index, productionKey)
        -- upvalues: (copy) xmlFile, (copy) customEnv, (copy) usedProdIds, (copy) self, (copy) components, (copy) i3dMappings
        local production = {
            ["id"] = xmlFile:getValue(productionKey .. "#id"),
            ["name"] = xmlFile:getValue(productionKey .. "#name", nil, customEnv, false)
        }
        local params = xmlFile:getValue(productionKey .. "#params")
        if params ~= nil then
            production.name = g_i18n:insertTextParams(production.name, params, customEnv, xmlFile)
        end
        if not production.id then
            Logging.xmlError(xmlFile, "missing id for production \'%s\'", production.name or index)
            return false
        end
        local i = 1
        for i = i, #usedProdIds do
            if usedProdIds[i] == production.id then
                Logging.xmlError(xmlFile, "production id \'%s\' already in use", production.id)
                return false
            end
        end
        local i = production.id
        table.insert(usedProdIds, i)
        local i = xmlFile:getValue(productionKey .. "#cyclesPerMinute")
        production.cyclesPerMinute = xmlFile:getValue(productionKey .. "#cyclesPerMonth") and xmlFile:getValue(productionKey .. "#cyclesPerMonth") / 60 / 24 or (xmlFile:getValue(productionKey .. "#cyclesPerHour") and xmlFile:getValue(productionKey .. "#cyclesPerHour") / 60 or (i or 1))
        production.cyclesPerHour = cyclesPerHour or production.cyclesPerMinute * 60
        production.cyclesPerMonth = cyclesPerMonth or production.cyclesPerHour * 24
        local costsPerActiveMinute = xmlFile:getValue(productionKey .. "#costsPerActiveMinute")
        local costsPerActiveHour = xmlFile:getValue(productionKey .. "#costsPerActiveHour")
        local costsPerActiveMonth = xmlFile:getValue(productionKey .. "#costsPerActiveMonth")
        production.costsPerActiveMinute = costsPerActiveMonth and costsPerActiveMonth / 60 / 24 or costsPerActiveHour and costsPerActiveHour / 60 or (costsPerActiveMinute or 1)
        production.costsPerActiveHour = costsPerActiveHour or production.costsPerActiveMinute * 60
        production.costsPerActiveMonth = costsPerActiveMonth or production.costsPerActiveHour * 24
        production.status = ProductionPoint.PROD_STATUS.INACTIVE
        production.inputs = {}
        xmlFile:iterate(productionKey .. ".inputs.input", function(_, inputKey)
            -- upvalues: (ref) xmlFile, (ref) self, (copy) production
            local input = {}
            local fillTypeString = xmlFile:getValue(inputKey .. "#fillType")
            input.type = g_fillTypeManager:getFillTypeIndexByName(fillTypeString)
            if input.type == nil then
                Logging.xmlError(xmlFile, "Unable to load fillType \'%s\' for \'%s\'", fillTypeString, inputKey)
            else
                self.inputFillTypeIds[input.type] = true
                table.addElement(self.inputFillTypeIdsArray, input.type)
                input.amount = xmlFile:getValue(inputKey .. "#amount", 1)
                table.insert(production.inputs, input)
            end
        end)
        if #production.inputs ~= 0 then
            production.outputs = {}
            production.primaryProductFillType = nil
            local maxOutputAmount = 0
            xmlFile:iterate(productionKey .. ".outputs.output", function(_, outputKey)
                -- upvalues: (ref) xmlFile, (ref) self, (copy) production, (ref) maxOutputAmount
                local output = {}
                local fillTypeString = xmlFile:getValue(outputKey .. "#fillType")
                output.type = g_fillTypeManager:getFillTypeIndexByName(fillTypeString)
                if output.type == nil then
                    Logging.xmlError(xmlFile, "Unable to load fillType \'%s\' for \'%s\'", fillTypeString, outputKey)
                else
                    output.sellDirectly = xmlFile:getValue(outputKey .. "#sellDirectly", false)
                    if output.sellDirectly then
                        self.soldFillTypesToPayOut[output.type] = 0
                    else
                        self.outputFillTypeIds[output.type] = true
                        table.addElement(self.outputFillTypeIdsArray, output.type)
                    end
                    output.amount = xmlFile:getValue(outputKey .. "#amount", 1)
                    table.insert(production.outputs, output)
                    if maxOutputAmount < output.amount then
                        production.primaryProductFillType = output.type
                        maxOutputAmount = output.amount
                    end
                end
            end)
            if #production.outputs == 0 then
                Logging.xmlError(xmlFile, "No outputs for production \'%s\'", productionKey)
            end
            if self.isClient then
                production.samples = {}
                production.samples.active = g_soundManager:loadSampleFromXML(xmlFile, productionKey .. ".sounds", "active", self.baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
                production.animationNodes = g_animationManager:loadAnimations(xmlFile, productionKey .. ".animationNodes", components, self, i3dMappings)
                production.effects = g_effectManager:loadEffect(xmlFile, productionKey .. ".effectNodes", components, self, i3dMappings)
                g_effectManager:setEffectTypeInfo(production.effects, FillType.UNKNOWN)
            end
            if self.productionsIdToObj[production.id] ~= nil then
                Logging.xmlError(xmlFile, "production id \'%s\' already used", production.id)
                return false
            end
            self.productionsIdToObj[production.id] = production
            table.insert(self.productions, production)
            production.index = #self.productions
            return true
        end
        Logging.xmlError(xmlFile, "No inputs for production \'%s\'", productionKey)
    end)
    if #self.productions == 0 then
        Logging.xmlError(xmlFile, "No valid productions defined")
    end
    if self.owningPlaceable == nil then
        printError("Error: ProductionPoint.owningPlaceable was not set before load()")
        return false
    end
    self.interactionTriggerNode = xmlFile:getValue(key .. ".playerTrigger#node", nil, components, i3dMappings)
    if self.interactionTriggerNode ~= nil then
        self.useInteractionTriggerForBuying = true
        addTrigger(self.interactionTriggerNode, "interactionTriggerCallback", self)
    end
    if self.isClient then
        self.samples = {}
        self.samples.idle = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "idle", self.baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
        self.samples.active = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "active", self.baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
        self.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", components, self, i3dMappings)
        self.effects = g_effectManager:loadEffect(xmlFile, key .. ".effectNodes", components, self, i3dMappings)
        g_effectManager:setEffectTypeInfo(self.effects, FillType.UNKNOWN)
    end
    self.unloadingStation = SellingStation.new(self.isServer, self.isClient)
    self.unloadingStation:load(components, xmlFile, key .. ".sellingStation", self.customEnvironment, i3dMappings, components[1].node)
    function self.unloadingStation.getStoreGoods(_, farmId, _)
        -- upvalues: (copy) self
        local ownerFarmId = self.owningPlaceable:getOwnerFarmId()
        return ownerFarmId ~= AccessHandler.EVERYONE and (ownerFarmId == farmId or g_currentMission.accessHandler:canFarmAccess(farmId, self.owningPlaceable)) and true or false
    end
    function self.unloadingStation.getSkipSell(_, farmId, _)
        -- upvalues: (copy) self
        local ownerFarmId = self.owningPlaceable:getOwnerFarmId()
        return ownerFarmId ~= AccessHandler.EVERYONE and (ownerFarmId == farmId or g_currentMission.accessHandler:canFarmAccess(farmId, self.owningPlaceable)) and true or false
    end
    self.unloadingStation:register(true)
    local loadingStationKey = key .. ".loadingStation"
    if xmlFile:hasProperty(loadingStationKey) then
        self.loadingStation = LoadingStation.new(self.isServer, self.isClient)
        if not self.loadingStation:load(components, xmlFile, loadingStationKey, self.customEnvironment, i3dMappings, components[1].node) then
            Logging.xmlError(xmlFile, "Unable to load loading station %s", loadingStationKey)
            return false
        end
        function self.loadingStation.hasFarmAccessToStorage(_, farmId)
            -- upvalues: (copy) self
            return farmId == self.owningPlaceable:getOwnerFarmId()
        end
        self.loadingStation.owningPlaceable = self.owningPlaceable
        self.loadingStation:register(true)
    end
    local palletSpawnerKey = key .. ".palletSpawner"
    if xmlFile:hasProperty(palletSpawnerKey) then
        self.palletSpawner = PalletSpawner.new(self.baseDirectory)
        if not self.palletSpawner:load(components, xmlFile, key .. ".palletSpawner", self.customEnvironment, i3dMappings) then
            Logging.xmlError(xmlFile, "Unable to load pallet spawner %s", palletSpawnerKey)
            return false
        end
    end
    if self.loadingStation == nil and self.palletSpawner == nil then
        Logging.xmlError(xmlFile, "No loading station or pallet spawner for production point")
        return false
    end
    if self.palletSpawner ~= nil then
        for fillTypeId, pallet in pairs(self.palletSpawner:getSupportedFillTypes()) do
            if self.outputFillTypeIds[fillTypeId] then
                self.outputFillTypeIdsToPallets[fillTypeId] = pallet
            end
        end
    end
    self.storage = Storage.new(self.isServer, self.isClient)
    self.storage:load(components, xmlFile, key .. ".storage", i3dMappings, self.baseDirectory)
    self.storage:register(true)
    if self.loadingStation ~= nil then
        if not self.loadingStation:addSourceStorage(self.storage) then
            Logging.xmlWarning(xmlFile, "Unable to add source storage ")
        end
        g_currentMission.storageSystem:addLoadingStation(self.loadingStation, self.owningPlaceable)
    end
    self.unloadingStation:addTargetStorage(self.storage)
    for fillTypeId in pairs(self.inputFillTypeIds) do
        if not self.unloadingStation:getIsFillTypeSupported(fillTypeId) then
            local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeId)
            Logging.xmlWarning(xmlFile, "Input filltype \'%s\' is not supported by unloading station", fillTypeName)
        end
    end
    for fillTypeId in pairs(self.outputFillTypeIds) do
        if (self.loadingStation == nil or not self.loadingStation:getIsFillTypeSupported(fillTypeId)) and self.outputFillTypeIdsToPallets[fillTypeId] == nil then
            local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeId)
            Logging.xmlWarning(xmlFile, "Output filltype \'%s\' is not supported by loading station or pallet spawner", fillTypeName)
        end
    end
    self.unloadingStation.owningPlaceable = self.owningPlaceable
    g_currentMission.storageSystem:addUnloadingStation(self.unloadingStation, self.owningPlaceable)
    g_currentMission.economyManager:addSellingStation(self.unloadingStation)
    local i = 1
    for i = i, #self.productions do
        local fillTypeId = self.productions[i]
        local x = 1
        for x = x, #fillTypeId.inputs do
            local input = fillTypeId.inputs[x]
            if not self.storage:getIsFillTypeSupported(input.type) then
                Logging.xmlError(xmlFile, "production point storage does not support fillType \'%s\' used as in input in production \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(input.type), fillTypeId.name)
                return false
            end
        end
        local x = 1
        for x = x, #fillTypeId.outputs do
            local input = fillTypeId.outputs[x]
            if not (input.sellDirectly or self.storage:getIsFillTypeSupported(input.type)) then
                Logging.xmlError(xmlFile, "production point storage does not support fillType \'%s\' used as an output in production \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(input.type), fillTypeId.name)
                return false
            end
        end
    end
    for fillTypeId, pallet in pairs(self.storage:getSupportedFillTypes()) do
        if not (self.inputFillTypeIds[fillTypeId] or self.outputFillTypeIds[fillTypeId]) then
            Logging.xmlWarning(xmlFile, "storage fillType \'%s\' not used as a production input or ouput", g_fillTypeManager:getFillTypeNameByIndex(fillTypeId))
        end
    end
    return true
end
function ProductionPoint:findStorageExtensions()
    if self.unloadingStation ~= nil then
        local storagesInRange = g_currentMission.storageSystem:getStorageExtensionsInRange(self.unloadingStation, self:getOwnerFarmId())
        if storagesInRange ~= nil then
            for _, storage in ipairs(storagesInRange) do
                if self.unloadingStation.targetStorages[storage] == nil then
                    storageSystem:addStorageToUnloadingStation(storage, self.unloadingStation)
                end
            end
        end
    end
    if self.loadingStation ~= nil then
        local storagesInRange = storageSystem:getStorageExtensionsInRange(self.loadingStation, self:getOwnerFarmId())
        if storagesInRange ~= nil then
            for _, storage in ipairs(storagesInRange) do
                if self.loadingStation.sourceStorages[storage] == nil then
                    storageSystem:addStorageToLoadingStation(storage, self.loadingStation)
                end
            end
        end
        if self.loadingStation:getIsFillTypeSupported(FillType.LIQUIDMANURE) or self.loadingStation:getIsFillTypeSupported(FillType.DIGESTATE) then
            g_currentMission:addLiquidManureLoadingStation(self.loadingStation)
        end
    end
end
function ProductionPoint:delete()
    g_messageCenter:unsubscribeAll(self)
    self.mission.activatableObjectsSystem:removeActivatable(self.activatable)
    self.activatable = nil
    g_currentMission.productionChainManager:removeProductionPoint(self)
    if self.interactionTriggerNode ~= nil then
        removeTrigger(self.interactionTriggerNode)
        self.interactionTriggerNode = nil
    end
    if self.samples ~= nil then
        g_soundManager:deleteSamples(self.samples)
        self.samples = nil
    end
    if self.animationNodes ~= nil then
        g_animationManager:deleteAnimations(self.animationNodes)
    end
    if self.effects ~= nil then
        g_effectManager:deleteEffects(self.effects)
    end
    if self.loadingStation ~= nil then
        g_currentMission.storageSystem:removeLoadingStation(self.loadingStation, self.owningPlaceable)
        if self.loadingStation:getIsFillTypeSupported(FillType.LIQUIDMANURE) or self.loadingStation:getIsFillTypeSupported(FillType.DIGESTATE) then
            g_currentMission:removeLiquidManureLoadingStation(self.loadingStation)
        end
        self.loadingStation:delete()
    end
    if self.unloadingStation ~= nil then
        g_currentMission.storageSystem:removeUnloadingStation(self.unloadingStation, self.owningPlaceable)
        g_currentMission.economyManager:removeSellingStation(self.unloadingStation)
        self.unloadingStation:delete()
    end
    if self.palletSpawner ~= nil then
        self.palletSpawner:delete()
    end
    if self.storage ~= nil then
        self.storage:delete()
    end
    local i = 1
    for i = i, #self.productions do
        local production = self.productions[i]
        g_soundManager:deleteSamples(production.samples)
        production.samples = nil
        g_animationManager:deleteAnimations(production.animationNodes)
        g_effectManager:deleteEffects(production.effects)
    end
    ProductionPoint:superClass().delete(self)
end
function ProductionPoint:readStream(streamId, connection)
    ProductionPoint:superClass().readStream(self, streamId, connection)
    if connection:getIsServer() then
        local numSellFillTypes = streamReadUInt8(streamId)
        local i = 1
        for i = i, numSellFillTypes do
            self:setOutputDistributionMode(streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS), ProductionPoint.OUTPUT_MODE.DIRECT_SELL, true)
        end
        local numDeliverFillTypes = streamReadUInt8(streamId)
        local i = 1
        for fillType = 1, numDeliverFillTypes, i do
            self:setOutputDistributionMode(streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS), ProductionPoint.OUTPUT_MODE.AUTO_DELIVER, true)
        end
        local unloadingStationId = NetworkUtil.readNodeObjectId(streamId)
        self.unloadingStation:readStream(streamId, connection)
        g_client:finishRegisterObject(self.unloadingStation, unloadingStationId)
        if self.loadingStation ~= nil then
            local i = NetworkUtil.readNodeObjectId(streamId)
            self.loadingStation:readStream(streamId, connection)
            g_client:finishRegisterObject(self.loadingStation, i)
        end
        local i = NetworkUtil.readNodeObjectId(streamId)
        self.storage:readStream(streamId, connection)
        g_client:finishRegisterObject(self.storage, i)
        local i = 1
        for i = i, streamReadUInt8(streamId) do
            local productionIndex = streamReadUInt8(streamId)
            local production = self.productions[productionIndex]
            if production ~= nil then
                self:setProductionState(production.id, true, true)
                local productionStatus = streamReadUIntN(streamId, ProductionPoint.PROD_STATUS_NUM_BITS)
                self:setProductionStatus(production.id, productionStatus, true)
            end
        end
        self.palletLimitReached = streamReadBool(streamId)
    end
end
function ProductionPoint:writeStream(streamId, connection)
    ProductionPoint:superClass().writeStream(self, streamId, connection)
    if not connection:getIsServer() then
        streamWriteUInt8(streamId, table.size(self.outputFillTypeIdsDirectSell))
        for directSellFillTypeId in pairs(self.outputFillTypeIdsDirectSell) do
            streamWriteUIntN(streamId, directSellFillTypeId, FillTypeManager.SEND_NUM_BITS)
        end
        streamWriteUInt8(streamId, table.size(self.outputFillTypeIdsAutoDeliver))
        for directSellFillTypeId in pairs(self.outputFillTypeIdsAutoDeliver) do
            streamWriteUIntN(streamId, directSellFillTypeId, FillTypeManager.SEND_NUM_BITS)
        end
        NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.unloadingStation))
        self.unloadingStation:writeStream(streamId, connection)
        g_server:registerObjectInStream(connection, self.unloadingStation)
        if self.loadingStation ~= nil then
            NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.loadingStation))
            self.loadingStation:writeStream(streamId, connection)
            g_server:registerObjectInStream(connection, self.loadingStation)
        end
        NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.storage))
        self.storage:writeStream(streamId, connection)
        g_server:registerObjectInStream(connection, self.storage)
        streamWriteUInt8(streamId, #self.activeProductions)
        local i = 1
        for i = i, #self.activeProductions do
            local directSellFillTypeId = self.activeProductions[i]
            streamWriteUInt8(streamId, directSellFillTypeId.index)
            streamWriteUIntN(streamId, directSellFillTypeId.status, ProductionPoint.PROD_STATUS_NUM_BITS)
        end
        streamWriteBool(streamId, self.palletLimitReached)
    end
end
function ProductionPoint:readUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        self.palletLimitReached = streamReadBool(streamId)
    end
end
function ProductionPoint:writeUpdateStream(streamId, connection, _)
    if not connection:getIsServer() then
        streamWriteBool(streamId, self.palletLimitReached)
    end
end
function ProductionPoint:setOwnerFarmId(farmId, noEventSend)
    if self.isServer then
        self:claimProductionCosts()
    end
    g_currentMission.productionChainManager:removeProductionPoint(self)
    ProductionPoint:superClass().setOwnerFarmId(self, farmId, noEventSend)
    self.isOwned = farmId ~= AccessHandler.EVERYONE
    if g_server ~= nil and g_currentMission.isRunning then
        for _, production in pairs(self.productions) do
            self:setProductionState(production.id, not self.isOwned)
        end
    end
    if self.unloadingStation ~= nil then
        self.unloadingStation:setOwnerFarmId(farmId)
    end
    if self.loadingStation ~= nil then
        self.loadingStation:setOwnerFarmId(farmId)
    end
    if self.storage ~= nil then
        self.storage:setOwnerFarmId(farmId)
    end
    g_currentMission.productionChainManager:addProductionPoint(self)
end
function ProductionPoint:palletSpawnRequestCallback(pallet, status, fillType)
    self.waitingForPalletToSpawn = false
    if pallet == nil or (not pallet.addFillUnitFillLevel or fillType == nil) then
        self.palletSpawnCooldown = g_time + ProductionPoint.NO_PALLET_SPACE_COOLDOWN
        if status == PalletSpawner.PALLET_LIMITED_REACHED then
            if not self.palletLimitReached then
                self.palletLimitReached = true
                self:raiseDirtyFlags(self.dirtyFlag)
                return
            end
        else
            self.lastPalletFillTypeId = next(self.outputFillTypeIdsToPallets, self.lastPalletFillTypeId)
        end
    else
        if self.palletLimitReached then
            self.palletLimitReached = false
            self:raiseDirtyFlags(self.dirtyFlag)
        end
        local fillUnitIndex = pallet:getFirstValidFillUnitToFill(fillType)
        if not fillUnitIndex then
            printf("Error: No fillUnitIndex for fillType %s found, pallet: %s", g_fillTypeManager:getFillTypeNameByIndex(fillType), pallet.xmlFile.filename)
            return
        end
        local delta = pallet:addFillUnitFillLevel(self:getOwnerFarmId(), fillUnitIndex, self.storage:getFillLevel(fillType), fillType, ToolType.UNDEFINED)
        if delta > 0 then
            self.storage:setFillLevel(self.storage:getFillLevel(fillType) - delta, fillType)
            return
        end
    end
end
function ProductionPoint:updateFxState()
    if self.isClient then
        if #self.activeProductions > 0 and self.isFinalized then
            g_soundManager:stopSample(self.samples.idle)
            if not g_soundManager:getIsSamplePlaying(self.samples.active) then
                g_soundManager:playSample(self.samples.active)
            end
            g_animationManager:startAnimations(self.animationNodes)
            g_effectManager:startEffects(self.effects)
            return
        end
        g_soundManager:stopSample(self.samples.active)
        if not g_soundManager:getIsSamplePlaying(self.samples.idle) then
            g_soundManager:playSample(self.samples.idle)
        end
        g_animationManager:stopAnimations(self.animationNodes)
        g_effectManager:stopEffects(self.effects)
    end
end
function ProductionPoint:update(dt) end
function ProductionPoint:updateProduction()
    if self.lastUpdatedTime == nil then
        self.lastUpdatedTime = g_time
        return
    end
    local timeAdjust = g_time - self.lastUpdatedTime
    local dt = math.clamp(timeAdjust, 0, 30000)
    local timeAdjust = g_currentMission.environment.timeAdjustment
    local numActiveProductions = #self.activeProductions
    if numActiveProductions > 0 then
        local n = 1
        for n = n, numActiveProductions do
            local production = self.activeProductions[n]
            local enoughInputResources = true
            local enoughOutputSpace = true
            local x = 1
            local factor = #production.inputs
            for x = x, factor do
                local input = production.inputs[x]
                local fillLevel = self:getFillLevel(input.type)
                self.inputFillLevels[input] = fillLevel
                if self.isOwned and fillLevel < input.amount * (production.cyclesPerMinute * (dt / 60000 * timeAdjust)) then
                    enoughInputResources = false
                    if production.status ~= ProductionPoint.PROD_STATUS.MISSING_INPUTS then
                        production.status = ProductionPoint.PROD_STATUS.MISSING_INPUTS
                        self.owningPlaceable:productionStatusChanged(production, ProductionPoint.PROD_STATUS.MISSING_INPUTS)
                        self:setProductionStatus(production.id, production.status)
                    end
                    break
                end
            end
            if enoughInputResources and self.isOwned then
                local x = 1
                for x = x, #production.outputs do
                    local input = production.outputs[x]
                    if not input.sellDirectly and self.storage:getFreeCapacity(input.type) < input.amount * (production.cyclesPerMinute * (dt * self.minuteFactorTimescaled * timeAdjust)) then
                        enoughOutputSpace = false
                        if production.status ~= ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE then
                            production.status = ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE
                            self:setProductionStatus(production.id, production.status)
                        end
                        break
                    end
                end
            end
            if self.isOwned then
                self.productionCostsToClaim = self.productionCostsToClaim + production.costsPerActiveMinute * minuteFactorTimescaledDt
            end
            if not self.isOwned or enoughInputResources and enoughOutputSpace then
                local input = 1
                local x = 1
                for input = input, #production.inputs, x do
                    local fillLevel = production.inputs[input]
                    if self.loadingStation == nil then
                        local fillLevel = self.inputFillLevels[fillLevel]
                        if fillLevel and fillLevel > 0 then
                            self.storage:setFillLevel(fillLevel - fillLevel.amount * (cyclesPerMinuteMinuteFactor / (self.sharedThroughputCapacity and numActiveProductions and numActiveProductions or 1)), fillLevel.type)
                        end
                    else
                        self.loadingStation:removeFillLevel(fillLevel.type, fillLevel.amount * factor, self.ownerFarmId)
                    end
                end
                if self.isOwned then
                    local input = 1
                    for input = input, #production.outputs do
                        local fillLevel = production.outputs[input]
                        if fillLevel.sellDirectly then
                            if self.isServer then
                                self.soldFillTypesToPayOut[fillLevel.type] = self.soldFillTypesToPayOut[fillLevel.type] + fillLevel.amount * factor
                            end
                        else
                            local fillLevel = self.storage:getFillLevel(fillLevel.type)
                            self.storage:setFillLevel(fillLevel + fillLevel.amount * factor, fillLevel.type)
                        end
                    end
                end
                if production.status ~= ProductionPoint.PROD_STATUS.RUNNING then
                    production.status = ProductionPoint.PROD_STATUS.RUNNING
                    self.owningPlaceable:productionStatusChanged(production, production.status)
                    ProductionPointProductionStatusEvent.sendEvent(self, production.index, production.status)
                end
                table.clear(self.inputFillLevels)
            end
        end
    end
    if self.isServer and (self.isOwned and (g_time > self.palletSpawnCooldown and not self.waitingForPalletToSpawn)) then
        local minuteFactorTimescaledDt = nil
        while true do
            local minuteFactorDt = self.lastPalletFillTypeId
            if minuteFactorDt ~= nil and (self.outputFillTypeIdsDirectSell[minuteFactorDt] == nil and self.outputFillTypeIdsAutoDeliver[minuteFactorDt] == nil) then
                local fillLevel = self.storage:getFillLevel(minuteFactorDt)
                if fillLevel > 0 then
                    local pallet = self.outputFillTypeIdsToPallets[minuteFactorDt]
                    if pallet and pallet.capacity <= fillLevel then
                        minuteFactorTimescaledDt = minuteFactorDt
                        break
                    end
                end
            end
            self.lastPalletFillTypeId = next(self.outputFillTypeIdsToPallets, self.lastPalletFillTypeId)
            if self.lastPalletFillTypeId == nil then
                break
            end
        end
        if minuteFactorTimescaledDt ~= nil then
            self.waitingForPalletToSpawn = true
            self.palletSpawner:spawnPallet(self:getOwnerFarmId(), minuteFactorTimescaledDt, self.palletSpawnRequestCallback, self)
        end
    end
    self.lastUpdatedTime = g_time
end
function ProductionPoint:updateTick(dt) end
function ProductionPoint:draw()
    local localPlayer = g_localPlayer
    local playerNode = (localPlayer:getCurrentVehicle() or {}).rootNode or (localPlayer or {}).rootNode
    local px, py, pz = getWorldTranslation(playerNode)
    local ppx, ppy, ppz = getWorldTranslation(self.node)
    if MathUtil.vector3Length(px - ppx, py - ppy, pz - ppz) < 40 then
        local text = {}
        local i = string.format
        local n = self.ownerFarmId
        local input = self.isOwned
        table.insert(text, i("PP %s (%s); ownerFarmId: %s; isOwned: %s", self:getName(), self:tableId(), n, input))
        local i = 1
        for i = i, #self.productions do
            local production = self.productions[i]
            local n = string.format
            table.insert(text, n("  prodId \'%s\': cyclesPerMinute: %.2f; enabled: %s", production.id, production.cyclesPerMinute, (tostring(table.hasElement(self.activeProductions, production)))))
            local n = 1
            for n = n, #production.inputs do
                local input = production.inputs[n]
                table.insert(text, string.format("    i: %s: %.2f", g_fillTypeManager:getFillTypeNameByIndex(input.type), input.amount))
            end
            local n = 1
            for n = n, #production.outputs do
                local input = production.outputs[n]
                table.insert(text, string.format("    o: %s: %.2f; directSell:%s; autoDeliver:%s", g_fillTypeManager:getFillTypeNameByIndex(input.type), input.amount, tostring(self.outputFillTypeIdsDirectSell[input.type] == true), (tostring(self.outputFillTypeIdsAutoDeliver[input.type] == true))))
            end
        end
        local i = string.format
        table.insert(text, i("productionCostsToClaim : %.1f", self.productionCostsToClaim))
        local i = string.format
        table.insert(text, i("waitingForPalletToSpawn: %s", self.waitingForPalletToSpawn))
        if self.palletSpawnCooldown > g_time then
            table.insert(text, string.format("palletSpawnCooldown: %.1f s", (self.palletSpawnCooldown - g_time) / 1000))
        end
        self.debugText:setText(table.concat(text, "\n"))
        self.debugText:draw()
        self.storage:draw()
    end
end
function ProductionPoint:onTimescaleChanged()
    self.minuteFactorTimescaled = self.mission:getEffectiveTimeScale() / 1000 / 60
end
function ProductionPoint:claimProductionCosts()
    if self.isOwned and (self.isServer and self.productionCostsToClaim > 0) then
        self.mission:addMoney(-self.productionCostsToClaim, self.ownerFarmId, MoneyType.PRODUCTION_COSTS, true)
    end
    self.productionCostsToClaim = 0
end
function ProductionPoint:updateBalaceDirectlySoldOutputs()
    if self.isOwned and self.isServer then
        for fillTypeId, amount in pairs(self.soldFillTypesToPayOut) do
            local moneyType = MoneyType.HARVEST_INCOME
            if g_fillTypeManager:getIsFillTypeInCategory(fillTypeId, "PRODUCT") then
                moneyType = MoneyType.SOLD_PRODUCTS
            elseif g_fillTypeManager:getIsFillTypeInCategory(fillTypeId, "PRODUCT_BGA") then
                moneyType = MoneyType.INCOME_BGA
            end
            self.mission:addMoney(amount * g_currentMission.economyManager:getPricePerLiter(fillTypeId), self.ownerFarmId, moneyType, true)
            self.soldFillTypesToPayOut[fillTypeId] = 0
        end
    end
end
function ProductionPoint:directlySellOutputs()
    for outputFillTypeId in pairs(self.outputFillTypeIdsDirectSell) do
        local amount = self.storage:getFillLevel(outputFillTypeId)
        if amount > 0 then
            local revenue = ProductionPoint.DIRECT_SELL_PRICE_FACTOR * amount * g_currentMission.economyManager:getPricePerLiter(outputFillTypeId)
            self.mission:addMoney(revenue, self.ownerFarmId, MoneyType.SOLD_PRODUCTS, true)
            self.storage:setFillLevel(0, outputFillTypeId)
        end
    end
end
function ProductionPoint:loadFromXMLFile(xmlFile, key)
    local palletSpawnCooldown = xmlFile:getValue(key .. "#palletSpawnCooldown")
    if palletSpawnCooldown then
        self.palletSpawnCooldown = g_time + palletSpawnCooldown
    end
    self.productionCostsToClaim = xmlFile:getValue(key .. "#productionCostsToClaim") or self.productionCostsToClaim
    if self.owningPlaceable.ownerFarmId == AccessHandler.EVERYONE then
        local n = 1
        for n = n, #self.productions do
            self:setProductionState(self.productions[n].id, true)
        end
    end
    xmlFile:iterate(key .. ".production", function(_, productionKey)
        -- upvalues: (copy) xmlFile, (copy) self
        local prodId = xmlFile:getValue(productionKey .. "#id")
        local isEnabled = xmlFile:getValue(productionKey .. "#isEnabled")
        if self.productionsIdToObj[prodId] == nil then
            Logging.xmlWarning(xmlFile, "Unknown production id \'%s\'", prodId)
        else
            self:setProductionState(prodId, isEnabled)
        end
    end)
    xmlFile:iterate(key .. ".directSellFillType", function(_, directSellKey)
        -- upvalues: (copy) xmlFile, (copy) self
        local fillType = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getValue(directSellKey))
        if fillType then
            self:setOutputDistributionMode(fillType, ProductionPoint.OUTPUT_MODE.DIRECT_SELL)
        end
    end)
    xmlFile:iterate(key .. ".autoDeliverFillType", function(_, autoDeliverKey)
        -- upvalues: (copy) xmlFile, (copy) self
        local fillType = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getValue(autoDeliverKey))
        if fillType then
            self:setOutputDistributionMode(fillType, ProductionPoint.OUTPUT_MODE.AUTO_DELIVER)
        end
    end)
    return self.storage:loadFromXMLFile(xmlFile, key .. ".storage") and true or false
end
function ProductionPoint:saveToXMLFile(xmlFile, key, usedModNames)
    if g_time < self.palletSpawnCooldown then
        xmlFile:setValue(key .. "#palletSpawnCooldown", self.palletSpawnCooldown - g_time)
    end
    if self.productionCostsToClaim ~= 0 then
        xmlFile:setValue(key .. "#productionCostsToClaim", self.productionCostsToClaim)
    end
    local xmlIndex = 0
    local i = 1
    for i = i, #self.activeProductions do
        local productionKey = string.format("%s.production(%i)", key, xmlIndex)
        xmlFile:setValue(productionKey .. "#id", self.activeProductions[i].id)
        xmlFile:setValue(productionKey .. "#isEnabled", true)
        xmlIndex = xmlIndex + 1
    end
    xmlFile:setTable(key .. ".directSellFillType", self.outputFillTypeIdsDirectSell, function(fillTypeKey, _, fillTypeId)
        -- upvalues: (copy) xmlFile
        xmlFile:setValue(fillTypeKey, (g_fillTypeManager:getFillTypeNameByIndex(fillTypeId)))
    end)
    xmlFile:setTable(key .. ".autoDeliverFillType", self.outputFillTypeIdsAutoDeliver, function(fillTypeKey, _, fillTypeId)
        -- upvalues: (copy) xmlFile
        xmlFile:setValue(fillTypeKey, (g_fillTypeManager:getFillTypeNameByIndex(fillTypeId)))
    end)
    self.storage:saveToXMLFile(xmlFile, key .. ".storage", usedModNames)
end
function ProductionPoint:getName()
    return self.name or self.owningPlaceable:getName()
end
function ProductionPoint:setProductionState(productionId, state, noEventSend)
    local production = self.productionsIdToObj[productionId]
    if production == nil then
        printError(string.format("Error: setProductionState(): unknown productionId \'%s\'", productionId))
    else
        if state then
            if not table.hasElement(self.activeProductions, production) then
                production.status = ProductionPoint.PROD_STATUS.RUNNING
                table.insert(self.activeProductions, production)
            end
            if self.isClient then
                g_soundManager:playSamples(production.samples)
                g_animationManager:startAnimations(production.animationNodes)
                g_effectManager:startEffects(production.effects)
            end
        else
            table.removeElement(self.activeProductions, production)
            production.status = ProductionPoint.PROD_STATUS.INACTIVE
            if self.isClient then
                g_soundManager:stopSamples(production.samples)
                g_animationManager:stopAnimations(production.animationNodes)
                g_effectManager:stopEffects(production.effects)
            end
        end
        self.owningPlaceable:outputsChanged(production.outputs, state)
        ProductionPointProductionStateEvent.sendEvent(self, productionId, state, noEventSend)
    end
    if self.isClient then
        self:updateFxState()
    end
end
function ProductionPoint:getIsProductionEnabled(productionId)
    return table.hasElement(self.activeProductions, self.productionsIdToObj[productionId])
end
function ProductionPoint:updateInfo(infoTable)
    local owningFarm = g_farmManager:getFarmById(self:getOwnerFarmId())
    if owningFarm ~= nil and not string.isNilOrWhitespace(owningFarm.name) then
        local fillTypesDisplayed = {
            ["title"] = g_i18n:getText("fieldInfo_ownedBy"),
            ["text"] = owningFarm.name
        }
        table.insert(infoTable, fillTypesDisplayed)
    end
    if #self.activeProductions > 0 then
        table.insert(infoTable, self.infoTables.activeProds)
        local i = 1
        for i = i, #self.activeProductions do
            local activeProduction = self.activeProductions[i]
            table.insert(infoTable, {
                ["title"] = activeProduction.name or g_fillTypeManager:getFillTypeTitleByIndex(activeProduction.primaryProductFillType),
                ["text"] = g_i18n:getText(ProductionPoint.PROD_STATUS_TO_L10N[self:getProductionStatus(activeProduction.id)])
            })
        end
    else
        table.insert(infoTable, self.infoTables.noActiveProd)
    end
    local fillTypesDisplayed = false
    local i = self.infoTables.storage
    table.insert(infoTable, i)
    local i = 1
    local i = #self.inputFillTypeIdsArray
    for i = i, i do
        local activeProduction = self.inputFillTypeIdsArray[i]
        local fillLevel = self:getFillLevel(activeProduction)
        if fillLevel > 1 then
            fillTypesDisplayed = true
            table.insert(infoTable, {
                ["title"] = g_fillTypeManager:getFillTypeTitleByIndex(activeProduction),
                ["text"] = g_i18n:formatVolume(fillLevel, 0)
            })
        end
    end
    local i = 1
    local i = #self.outputFillTypeIdsArray
    for i = i, i do
        local activeProduction = self.outputFillTypeIdsArray[i]
        local fillLevel = self:getFillLevel(activeProduction)
        if fillLevel > 1 then
            fillTypesDisplayed = true
            table.insert(infoTable, {
                ["title"] = g_fillTypeManager:getFillTypeTitleByIndex(activeProduction),
                ["text"] = g_i18n:formatVolume(fillLevel, 0)
            })
        end
    end
    if not fillTypesDisplayed then
        table.insert(infoTable, self.infoTables.storageEmpty)
    end
    if self.palletLimitReached then
        table.insert(infoTable, self.infoTables.palletLimitReached)
    end
end
function ProductionPoint:getProductionStatus(productionId)
    return self.productionsIdToObj[productionId].status
end
function ProductionPoint:setOutputDistributionMode(outputFillTypeId, mode, noEventSend)
    if self.outputFillTypeIds[outputFillTypeId] == nil then
        printf("Error: setOutputDistribution(): fillType \'%s\' is not an output fillType", g_fillTypeManager:getFillTypeNameByIndex(outputFillTypeId))
    else
        mode = tonumber(mode)
        self.outputFillTypeIdsDirectSell[outputFillTypeId] = nil
        self.outputFillTypeIdsAutoDeliver[outputFillTypeId] = nil
        if mode == ProductionPoint.OUTPUT_MODE.DIRECT_SELL then
            self.outputFillTypeIdsDirectSell[outputFillTypeId] = true
        elseif mode == ProductionPoint.OUTPUT_MODE.AUTO_DELIVER then
            self.outputFillTypeIdsAutoDeliver[outputFillTypeId] = true
        elseif mode ~= ProductionPoint.OUTPUT_MODE.KEEP then
            printf("Error: setOutputDistribution(): Undefined mode \'%s\'", mode)
            return
        end
        ProductionPointOutputModeEvent.sendEvent(self, outputFillTypeId, mode, noEventSend)
    end
end
function ProductionPoint:setProductionStatus(productionId, status, noEventSend)
    local production = tonumber(status)
    local production = self.productionsIdToObj[productionId]
    production.status = production
    ProductionPointProductionStatusEvent.sendEvent(self, production.index, production, noEventSend)
end
function ProductionPoint:getOutputDistributionMode(outputFillTypeId)
    if self.outputFillTypeIdsDirectSell[outputFillTypeId] == nil then
        if self.outputFillTypeIdsAutoDeliver[outputFillTypeId] == nil then
            return ProductionPoint.OUTPUT_MODE.KEEP
        else
            return ProductionPoint.OUTPUT_MODE.AUTO_DELIVER
        end
    else
        return ProductionPoint.OUTPUT_MODE.DIRECT_SELL
    end
end
function ProductionPoint:toggleOutputDistributionMode(outputFillTypeId)
    if self.outputFillTypeIds[outputFillTypeId] ~= nil then
        local curMode = self:getOutputDistributionMode(outputFillTypeId)
        if table.hasElement(ProductionPoint.OUTPUT_MODE, curMode + 1) then
            self:setOutputDistributionMode(outputFillTypeId, curMode + 1)
            return
        end
        self:setOutputDistributionMode(outputFillTypeId, 0)
    end
end
function ProductionPoint:getFillLevel(fillTypeId)
    if self.outputFillTypeIds[fillTypeId] == nil then
        return self.inputFillTypeIds[fillTypeId] == nil and 0 or self.unloadingStation:getFillLevel(fillTypeId, self.ownerFarmId)
    elseif self.loadingStation == nil then
        return self.storage:getFillLevel(fillTypeId)
    else
        return self.loadingStation:getFillLevel(fillTypeId, self.ownerFarmId)
    end
end
function ProductionPoint:getCapacity(fillTypeId)
    if self.outputFillTypeIds[fillTypeId] == nil then
        return self.inputFillTypeIds[fillTypeId] == nil and 0 or self.unloadingStation:getCapacity(fillTypeId, self.ownerFarmId)
    else
        return self.storage:getCapacity(fillTypeId)
    end
end
function ProductionPoint:tableId()
    return tostring(self):sub(10)
end
function ProductionPoint:toString()
    local paddedName = self:getName() .. string.rep(" ", 25 - utf8Strlen(self:getName()))
    return string.format("PP %s (%s): productions:(%i/%i) - owner: %i", paddedName, self:tableId(), #self.activeProductions, #self.productions, self.ownerFarmId)
end
function ProductionPoint.loadSpecValueInputFillTypes(xmlFile, _, _)
    local fillTypeNames = nil
    xmlFile:iterate("placeable.productionPoint.productions.production", function(_, productionKey)
        -- upvalues: (copy) xmlFile, (ref) fillTypeNames
        xmlFile:iterate(productionKey .. ".inputs.input", function(_, inputKey)
            -- upvalues: (ref) xmlFile, (ref) fillTypeNames
            local fillTypeName = xmlFile:getValue(inputKey .. "#fillType")
            fillTypeNames = fillTypeNames or {}
            fillTypeNames[fillTypeName] = true
        end)
    end)
    xmlFile:iterate("placeable.productionPoint.productionPointConfigurations.productionPointConfiguration(0).productionPoint.productions.production", function(_, productionKey)
        -- upvalues: (copy) xmlFile, (ref) fillTypeNames
        xmlFile:iterate(productionKey .. ".inputs.input", function(_, inputKey)
            -- upvalues: (ref) xmlFile, (ref) fillTypeNames
            local fillTypeName = xmlFile:getValue(inputKey .. "#fillType")
            fillTypeNames = fillTypeNames or {}
            fillTypeNames[fillTypeName] = true
        end)
    end)
    return fillTypeNames
end
function ProductionPoint.getSpecValueInputFillTypes(storeItem, _)
    if storeItem.specs.prodPointInputFillTypes == nil then
        return nil
    else
        return g_fillTypeManager:getFillTypesByNames(table.concatKeys(storeItem.specs.prodPointInputFillTypes, " "))
    end
end
function ProductionPoint.loadSpecValueOutputFillTypes(xmlFile, _, _)
    local fillTypeNames = nil
    xmlFile:iterate("placeable.productionPoint.productions.production", function(_, productionKey)
        -- upvalues: (copy) xmlFile, (ref) fillTypeNames
        xmlFile:iterate(productionKey .. ".outputs.output", function(_, inputKey)
            -- upvalues: (ref) xmlFile, (ref) fillTypeNames
            local fillTypeName = xmlFile:getValue(inputKey .. "#fillType")
            fillTypeNames = fillTypeNames or {}
            fillTypeNames[fillTypeName] = true
        end)
    end)
    xmlFile:iterate("placeable.productionPoint.productionPointConfigurations.productionPointConfiguration(0).productionPoint.productions.production", function(_, productionKey)
        -- upvalues: (copy) xmlFile, (ref) fillTypeNames
        xmlFile:iterate(productionKey .. ".outputs.output", function(_, inputKey)
            -- upvalues: (ref) xmlFile, (ref) fillTypeNames
            local fillTypeName = xmlFile:getValue(inputKey .. "#fillType")
            fillTypeNames = fillTypeNames or {}
            fillTypeNames[fillTypeName] = true
        end)
    end)
    return fillTypeNames
end
function ProductionPoint.getSpecValueOutputFillTypes(storeItem, _)
    if storeItem.specs.prodPointOutputFillTypes == nil then
        return nil
    else
        return g_fillTypeManager:getFillTypesByNames(table.concatKeys(storeItem.specs.prodPointOutputFillTypes, " "))
    end
end
function ProductionPoint:interactionTriggerCallback(_, otherId, onEnter, onLeave, _, _)
    if (onEnter or onLeave) and (g_localPlayer ~= nil and g_localPlayer.rootNode == otherId) then
        if onEnter then
            if Platform.gameplay.autoActivateTrigger and self.activatable:getIsActivatable() then
                self.activatable:run()
                return
            end
            self.activatable:updateText()
            self.mission.activatableObjectsSystem:addActivatable(self.activatable)
        end
        if onLeave then
            self.mission.activatableObjectsSystem:removeActivatable(self.activatable)
        end
    end
end
function ProductionPoint:openMenu()
    g_gui:showGui("InGameMenu")
    g_messageCenter:publish(MessageType.GUI_INGAME_OPEN_PRODUCTION_SCREEN, self)
end
function ProductionPoint:buyRequest(requestCallback, target)
    if g_guidedTourManager:getIsTourRunning() then
        InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
    else
        local storeItem = g_storeManager:getItemByXMLFilename(self.owningPlaceable.configFileName)
        local price = g_currentMission.economyManager:getBuyPrice(storeItem) or self.owningPlaceable:getPrice()
        if self.owningPlaceable.buysFarmland and self.owningPlaceable.getFarmlandId ~= nil then
            local farmlandId = self.owningPlaceable:getFarmlandId()
            local farmland = g_farmlandManager:getFarmlandById(farmlandId)
            if farmland ~= nil and g_farmlandManager:getFarmlandOwner(farmlandId) ~= self.mission:getFarmId() then
            end
        end
        local farmlandId = self.activatable
        local function farmland(statusCode)
            -- upvalues: (copy) self, (copy) farmlandId, (copy) self
            if statusCode ~= nil then
                local dialogArgs = BuyExistingPlaceableEvent.DIALOG_MESSAGES[statusCode]
                if dialogArgs ~= nil then
                    InfoDialog.show(g_i18n:getText(dialogArgs.text), nil, nil, dialogArgs.dialogType)
                end
            end
            g_messageCenter:unsubscribe(BuyExistingPlaceableEvent, self)
            farmlandId:updateText()
            self.owningPlaceable:onBuy()
        end
        YesNoDialog.show(function(yes)
            -- upvalues: (copy) farmland, (copy) self, (copy) requestCallback, (copy) target
            if yes then
                g_messageCenter:subscribe(BuyExistingPlaceableEvent, farmland)
                g_client:getServerConnection():sendEvent(BuyExistingPlaceableEvent.new(self.owningPlaceable, self.mission:getFarmId()))
            end
            if requestCallback ~= nil then
                if target ~= nil then
                    requestCallback(target, yes)
                    return
                end
                requestCallback(yes)
            end
        end, nil, string.format(g_i18n:getText("dialog_buyBuildingFor"), self:getName(), g_i18n:formatMoney(price, 0, true)))
    end
end