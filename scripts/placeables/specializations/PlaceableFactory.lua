PlaceableFactory = {}
source("dataS/scripts/placeables/specializations/activatables/FactoryActivatable.lua")
function PlaceableFactory.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableSellingStation, specializations)
end
function PlaceableFactory.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onMeshI3DFileLoaded", PlaceableFactory.onMeshI3DFileLoaded)
    SpecializationUtil.registerFunction(placeableType, "updateRemainingAmount", PlaceableFactory.updateRemainingAmount)
    SpecializationUtil.registerFunction(placeableType, "setMeshProgress", PlaceableFactory.setMeshProgress)
    SpecializationUtil.registerFunction(placeableType, "createFactoryItem", PlaceableFactory.createFactoryItem)
    SpecializationUtil.registerFunction(placeableType, "sellFactoryItem", PlaceableFactory.sellFactoryItem)
    SpecializationUtil.registerFunction(placeableType, "getCapacity", PlaceableFactory.getCapacity)
    SpecializationUtil.registerFunction(placeableType, "getFillLevel", PlaceableFactory.getFillLevel)
    SpecializationUtil.registerFunction(placeableType, "removeFillLevel", PlaceableFactory.removeFillLevel)
    SpecializationUtil.registerFunction(placeableType, "playerTriggerCallback", PlaceableFactory.playerTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "buyRequest", PlaceableFactory.buyRequest)
    SpecializationUtil.registerFunction(placeableType, "updateInfoData", PlaceableFactory.updateInfoData)
end
function PlaceableFactory.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableFactory.updateInfo)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableFactory.setOwnerFarmId)
end
function PlaceableFactory.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableFactory)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableFactory)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableFactory)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableFactory)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableFactory)
    SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableFactory)
    SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableFactory)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableFactory)
    SpecializationUtil.registerEventListener(placeableType, "onInfoTriggerEnter", PlaceableFactory)
    SpecializationUtil.registerEventListener(placeableType, "onInfoTriggerLeave", PlaceableFactory)
end
function PlaceableFactory.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("PlaceableFactory")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".factory#playerTrigger", "")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".factory.item#linkNode", "")
    schema:register(XMLValueType.STRING, basePath .. ".factory.item#filename", "")
    schema:register(XMLValueType.INT, basePath .. ".factory.item#reward", "")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".factory.item.progressiveVisibilityMesh.mesh(?)#node", "")
    schema:register(XMLValueType.STRING, basePath .. ".factory.item.progressiveVisibilityMesh.mesh(?)#id", "")
    schema:register(XMLValueType.INT, basePath .. ".factory.item.progressiveVisibilityMesh.mesh(?)#indexMin", "")
    schema:register(XMLValueType.INT, basePath .. ".factory.item.progressiveVisibilityMesh.mesh(?)#indexMax", "")
    schema:register(XMLValueType.STRING, basePath .. ".factory.production.input(?)#fillType", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".factory.production.input(?)#amount", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".factory.production.input(?)#usagePerHour", "")
    schema:register(XMLValueType.STRING, basePath .. ".factory.production.output#fillType", "")
    schema:register(XMLValueType.STRING, basePath .. ".factory.production#meshId", "")
    SellingStation.registerXMLPaths(schema, basePath .. ".factory.sellingStation")
    Storage.registerXMLPaths(schema, basePath .. ".factory.storage")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".factory.sounds", "active")
    schema:setXMLSpecializationType()
end
function PlaceableFactory.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".input(?)#fillType", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".input(?)#remainingAmount", "")
    Storage.registerSavegameXMLPaths(schema, basePath .. ".storage")
end
function PlaceableFactory:onLoad(_)
    local spec = self.spec_factory
    spec.itemLinkNode = self.xmlFile:getValue("placeable.factory.item#linkNode", nil, self.components, self.i3dMappings)
    local itemI3DFilename = Utils.getFilename(self.xmlFile:getValue("placeable.factory.item#filename"), self.baseDirectory)
    spec.itemReward = self.xmlFile:getValue("placeable.factory.item#reward", 100000)
    spec.idToMesh = {}
    spec.meshes = {}
    local arguments = {
        ["loadingTask"] = self:createLoadingTask(spec)
    }
    spec.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(itemI3DFilename, true, false, self.onMeshI3DFileLoaded, self, arguments)
    local sellingStation = self.spec_sellingStation.sellingStation
    sellingStation.owningPlaceable = self
    function sellingStation.getStoreGoods(_, farmId, fillTypeIndex)
        return true
    end
    function sellingStation.getSkipSell(_, farmId, fillTypeIndex)
        -- upvalues: (copy) self
        return self:getOwnerFarmId() ~= AccessHandler.EVERYONE
    end
    spec.storage = Storage.new(self.isServer, self.isClient)
    spec.storage:load(self.components, self.xmlFile, "placeable.factory.storage", self.i3dMappings, self.baseDirectory)
    spec.storage:register(true)
    spec.storage:addFillLevelChangedListeners(function()
        -- upvalues: (copy) self
        self:raiseActive()
    end)
    function spec.storageFillLevelChangedCallback()
        -- upvalues: (copy) self
        self:updateInfoData()
    end
    spec.fillTypesAndLevelsAuxiliary = {}
    spec.fillTypeToFillTypeStorageTable = {}
    spec.infoTriggerFillTypesAndLevels = {}
    spec.infoTableEntryStorage = {
        ["title"] = g_i18n:getText("statistic_storage"),
        ["accentuate"] = true
    }
    sellingStation:addTargetStorage(spec.storage)
    spec.playerTrigger = self.xmlFile:getValue("placeable.factory#playerTrigger", nil, self.components, self.i3dMappings)
    if spec.playerTrigger ~= nil then
        addTrigger(spec.playerTrigger, "playerTriggerCallback", self)
        local production = self:getOwnerFarmId() == AccessHandler.EVERYONE
        setVisibility(spec.playerTrigger, production)
    end
    spec.activatable = FactoryActivatable.new(self)
    spec.totalAmount = 0
    spec.inputs = {}
    spec.hasInputMaterials = true
    spec.progress = 0
    spec.progressLastSynced = 0
    spec.progressNumBits = 7
    spec.progressDirtyFlag = self:getNextDirtyFlag()
    self.inputFillTypeIdsArray = {}
    self.outputFillTypeIdsArray = {}
    local outputTypeStr = self.xmlFile:getValue("placeable.factory.production.output#fillType")
    local outputType = g_fillTypeManager:getFillTypeByName(outputTypeStr)
    self.productions = {}
    local production = {
        ["inputs"] = {},
        ["outputs"] = {},
        ["cyclesPerMonth"] = 1,
        ["costsPerActiveMonth"] = 0
    }
    if outputType ~= nil then
        production.primaryProductFillType = outputType.index
        production.name = outputType.title
        table.insert(self.outputFillTypeIdsArray, outputType.index)
        table.insert(production.outputs, {
            ["type"] = outputType.index,
            ["amount"] = 1,
            ["isFactory"] = true
        })
    end
    for _, inputKey in self.xmlFile:iterator("placeable.factory.production.input") do
        local fillTypeStr = self.xmlFile:getValue(inputKey .. "#fillType")
        local fillType = g_fillTypeManager:getFillTypeByName(fillTypeStr)
        if fillType == nil then
            Logging.xmlWarning(self.xmlFile, "Unknown fillType \'%s\' in \'%s\'", fillTypeStr, inputKey)
            break
        end
        if not spec.storage:getIsFillTypeSupported(fillType.index) then
            Logging.xmlWarning(self.xmlFile, "Filltype \'%s\' in \'%s\' not supported by storage", fillType.name, inputKey)
            break
        end
        local amount = self.xmlFile:getValue(inputKey .. "#amount")
        local usagePerHour = self.xmlFile:getValue(inputKey .. "#usagePerHour")
        spec.totalAmount = spec.totalAmount + amount
        table.insert(spec.inputs, {
            ["fillType"] = fillType,
            ["amount"] = amount,
            ["remainingAmount"] = amount,
            ["usagePerSecond"] = usagePerHour / 60 / 60,
            ["infoTableEntry"] = {
                ["title"] = fillType.title,
                ["text"] = g_i18n:formatVolume(amount)
            }
        })
        table.insert(production.inputs, {
            ["type"] = fillType.index,
            ["amount"] = amount
        })
        production.cyclesPerMonth = math.max(production.cyclesPerMonth, amount * g_currentMission.environment.timeAdjustment / (usagePerHour * 24))
        table.insert(self.inputFillTypeIdsArray, fillType.index)
    end
    table.insert(self.productions, production)
    spec.samples = {}
    spec.samples.active = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.factory.sounds", "active", self.baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
    spec.isSoundPlaying = false
end
function PlaceableFactory:onMeshI3DFileLoaded(i3dFileRoot, _, args)
    local spec = self.spec_factory
    if i3dFileRoot ~= 0 then
        spec.itemRoot = i3dFileRoot
        local components = {}
        I3DUtil.loadI3DComponents(i3dFileRoot, components)
        for index, nodeKey in self.xmlFile:iterator("placeable.factory.item.progressiveVisibilityMesh.mesh") do
            local node = self.xmlFile:getValue(nodeKey .. "#node", nil, components)
            if not getHasClassId(node, ClassIds.SHAPE) then
                Logging.xmlError(self.xmlFile, "node \'%s\' at \'%s\' is not a shape", getName(node), nodeKey)
                break
            end
            if not getHasShaderParameter(node, "hideByIndex") then
                Logging.xmlError(self.xmlFile, "mesh \'%s\' at \'%s\' does not have required shader parameter \'hideByIndex\'", getName(node), nodeKey)
                break
            end
            local id = self.xmlFile:getValue(nodeKey .. "#id")
            local indexMin = self.xmlFile:getValue(nodeKey .. "#indexMin", 0)
            local indexMax = self.xmlFile:getValue(nodeKey .. "#indexMax")
            if indexMax == nil then
                indexMax = getUserAttribute(node, "hideByIndexMaxIndex")
                if indexMin == nil then
                    Logging.xmlError(self.xmlFile, "Cannot retrieve indexMax from shape material and value is also not set in xml at \'%s\'", getName(node), nodeKey)
                    break
                end
            end
            if spec.idToMesh[id] ~= nil then
                Logging.xmlError(self.xmlFile, "id \'%s\' at \'%s\' already in use", id, nodeKey)
                break
            end
            local mesh = {
                ["node"] = node,
                ["childIndex"] = getChildIndex(node),
                ["id"] = id,
                ["index"] = #spec.meshes + 1,
                ["indexMin"] = indexMin,
                ["indexMax"] = indexMax,
                ["lastValue"] = -1,
                ["dirtyFlag"] = self:getNextDirtyFlag(),
                ["numBits"] = MathUtil.getNumRequiredBits(indexMax)
            }
            spec.idToMesh[id] = mesh
            table.insert(spec.meshes, mesh)
        end
    end
    self:createFactoryItem()
    for _, mesh in ipairs(spec.meshes) do
        self:setMeshProgress(mesh.id, 1)
    end
    self:finishLoadingTask(args.loadingTask)
    self:raiseActive()
end
function PlaceableFactory:onDelete()
    local spec = self.spec_factory
    g_currentMission.productionChainManager:removeFactory(self)
    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    if spec.samples ~= nil then
        g_soundManager:deleteSamples(spec.samples)
        spec.samples = nil
    end
    if spec.playerTrigger ~= nil then
        removeTrigger(spec.playerTrigger)
        spec.playerTrigger = nil
    end
    if spec.itemRoot ~= nil then
        delete(spec.itemRoot)
        spec.itemRoot = nil
    end
    if spec.storage ~= nil then
        spec.storage:delete()
        spec.storage = nil
    end
    if spec.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(spec.sharedLoadRequestId)
        spec.sharedLoadRequestId = nil
    end
end
function PlaceableFactory:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_factory
    xmlFile:setSortedTable(key .. ".input", spec.inputs, function(inputKey, input)
        -- upvalues: (copy) xmlFile
        xmlFile:setValue(inputKey .. "#fillType", input.fillType.name)
        xmlFile:setValue(inputKey .. "#remainingAmount", input.remainingAmount)
    end)
    spec.storage:saveToXMLFile(xmlFile, key .. ".storage")
end
function PlaceableFactory:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_factory
    for _, inputKey in xmlFile:iterator(key .. ".input") do
        local fillType = g_fillTypeManager:getFillTypeByName(xmlFile:getValue(inputKey .. "#fillType"))
        local remainingAmount = xmlFile:getValue(inputKey .. "#remainingAmount")
        for _, input in ipairs(spec.inputs) do
            if input.fillType == fillType then
                self:updateRemainingAmount(input, remainingAmount)
            end
        end
    end
    spec.storage:loadFromXMLFile(xmlFile, key .. ".storage")
end
function PlaceableFactory:onReadStream(streamId, connection)
    local spec = self.spec_factory
    local storageId = NetworkUtil.readNodeObjectId(streamId)
    spec.storage:readStream(streamId, connection)
    g_client:finishRegisterObject(spec.storage, storageId)
    spec.hasInputMaterials = streamReadBool(streamId)
    spec.progress = NetworkUtil.readCompressedPercentages(streamId, spec.progressNumBits)
    for meshIndex, mesh in ipairs(spec.meshes) do
        local hideByIndexValue = streamReadUIntN(streamId, mesh.numBits)
        local progress = MathUtil.inverseLerp(mesh.indexMax, mesh.indexMin, hideByIndexValue)
        self:setMeshProgress(mesh.id, progress)
    end
end
function PlaceableFactory:onWriteStream(streamId, connection)
    local spec = self.spec_factory
    NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.storage))
    spec.storage:writeStream(streamId, connection)
    g_server:registerObjectInStream(connection, spec.storage)
    streamWriteBool(streamId, spec.hasInputMaterials)
    NetworkUtil.writeCompressedPercentages(streamId, spec.progress, spec.progressNumBits)
    for meshIndex, mesh in ipairs(spec.meshes) do
        streamWriteUIntN(streamId, mesh.lastValue, mesh.numBits)
    end
end
function PlaceableFactory:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        local spec = self.spec_factory
        spec.hasInputMaterials = streamReadBool(streamId)
        if streamReadBool(streamId) then
            spec.progress = NetworkUtil.readCompressedPercentages(streamId, spec.progressNumBits)
        end
        for meshIndex, mesh in ipairs(spec.meshes) do
            if streamReadBool(streamId) then
                local hideByIndexValue = streamReadUIntN(streamId, mesh.numBits)
                local progress = MathUtil.inverseLerp(mesh.indexMax, mesh.indexMin, hideByIndexValue)
                self:setMeshProgress(mesh.id, progress)
            end
        end
    end
end
function PlaceableFactory:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_factory
        streamWriteBool(streamId, spec.hasInputMaterials)
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.progressDirtyFlag) ~= 0) then
            NetworkUtil.writeCompressedPercentages(streamId, spec.progress, spec.progressNumBits)
            spec.progressLastSynced = spec.progress
        end
        for meshIndex, mesh in ipairs(spec.meshes) do
            if streamWriteBool(streamId, bit32.band(dirtyMask, mesh.dirtyFlag) ~= 0) then
                streamWriteUIntN(streamId, mesh.lastValue, mesh.numBits)
            end
        end
    end
end
function PlaceableFactory:onUpdate(dt)
    local spec = self.spec_factory
    if not self.isServer then
        ::l2::
        if self.isClient and spec.samples.active ~= nil then
            if spec.hasInputMaterials then
                if not spec.isSoundPlaying then
                    g_soundManager:playSample(spec.samples.active)
                    spec.isSoundPlaying = true
                    return
                end
            elseif spec.isSoundPlaying then
                g_soundManager:stopSample(spec.samples.active)
                spec.isSoundPlaying = false
            end
        end
        return
    end
    local usedAmount = 0
    local hasInputMaterials = false
    for i, input in ipairs(spec.inputs) do
        if input.remainingAmount > 0 then
            local delta = self:removeFillLevel(input.fillType.index, input.usagePerSecond / 1000 * (dt * g_currentMission.missionInfo.timeScale))
            if delta > 0 then
                hasInputMaterials = true
                self:updateRemainingAmount(input, input.remainingAmount - delta)
            end
        end
    end
    local progress = usedAmount / spec.totalAmount
    if progress >= 0.001 then
        if math.abs(spec.progressLastSynced - progress) < 0.01 then
            ::l10::
            spec.progress = progress
            for input, amount in ipairs(spec.meshes) do
                self:setMeshProgress(amount.id, spec.progress)
            end
            if hasInputMaterials or hasInputMaterials ~= spec.hasInputMaterials then
                self:raiseActive()
            end
            spec.hasInputMaterials = hasInputMaterials
            if spec.progress >= 1 then
                self:sellFactoryItem()
                for input, amount in ipairs(spec.meshes) do
                    self:setMeshProgress(amount.id, 0)
                end
                for input, amount in ipairs(spec.inputs) do
                    self:updateRemainingAmount(amount, amount.amount)
                end
            end
            goto l2
        end
    end
    self:raiseDirtyFlags(spec.progressDirtyFlag)
    goto l10
end
function PlaceableFactory.updateRemainingAmount(_, input, amount)
    input.remainingAmount = math.max(0, amount)
    input.infoTableEntry.text = g_i18n:formatVolume(input.remainingAmount)
end
function PlaceableFactory:setOwnerFarmId(superFunc, farmId)
    local oldFarmId = self:getOwnerFarmId()
    superFunc(self, farmId)
    local spec = self.spec_factory
    if spec.playerTrigger ~= nil then
        setVisibility(spec.playerTrigger, farmId == AccessHandler.EVERYONE)
    end
    if self.propertyState ~= PlaceablePropertyState.CONSTRUCTION_PREVIEW then
        g_currentMission.productionChainManager:removeFactory(self, oldFarmId)
        local sellingStation = self.spec_sellingStation.sellingStation
        if sellingStation ~= nil then
            if farmId == AccessHandler.EVERYONE then
                g_currentMission.storageSystem:addUnloadingStation(sellingStation, self)
                g_currentMission.economyManager:addSellingStation(sellingStation)
            else
                g_currentMission.economyManager:removeSellingStation(sellingStation)
                g_currentMission.storageSystem:removeUnloadingStation(sellingStation, self)
            end
        end
        g_currentMission.productionChainManager:addFactory(self)
    end
end
function PlaceableFactory:onFinalizePlacement()
    local spec = self.spec_factory
    if spec.item ~= nil then
        addToPhysics(spec.item)
    end
    if self.ownerFarmId ~= AccessHandler.EVERYONE then
        local sellingStation = self.spec_sellingStation.sellingStation
        g_currentMission.economyManager:removeSellingStation(sellingStation)
        g_currentMission.storageSystem:removeUnloadingStation(sellingStation, self)
    end
end
function PlaceableFactory:setMeshProgress(meshId, percentage)
    local spec = self.spec_factory
    if spec.item ~= nil then
        local mesh = spec.idToMesh[meshId]
        if mesh ~= nil then
            local hideByIndexValue = MathUtil.round(MathUtil.lerp(mesh.indexMax, mesh.indexMin, percentage))
            if hideByIndexValue ~= mesh.lastValue then
                local node = getChildAt(spec.item, mesh.childIndex)
                setVisibility(node, percentage ~= 0)
                mesh.lastValue = hideByIndexValue
                setShaderParameter(node, "hideByIndex", hideByIndexValue, 0, 0, 0, false)
                if self.isServer then
                    self:raiseDirtyFlags(mesh.dirtyFlag)
                end
            end
        end
    end
end
function PlaceableFactory:createFactoryItem()
    local spec = self.spec_factory
    if spec.itemLinkNode ~= nil and spec.item == nil then
        spec.item = clone(spec.itemRoot, false, false, false)
        link(spec.itemLinkNode, spec.item)
    end
end
function PlaceableFactory:sellFactoryItem()
    local spec = self.spec_factory
    if spec.item ~= nil then
        if self.isServer and self:getOwnerFarmId() ~= AccessHandler.EVERYONE then
            g_currentMission:addMoney(spec.itemReward * EconomyManager.getPriceMultiplier(), self:getOwnerFarmId(), MoneyType.SOLD_PRODUCTS, true, true)
        end
        self:raiseActive()
    end
end
function PlaceableFactory:getCapacity(fillType)
    return self.spec_factory.storage:getCapacity(fillType)
end
function PlaceableFactory:getFillLevel(fillType)
    return self.spec_factory.storage:getFillLevel(fillType)
end
function PlaceableFactory:removeFillLevel(fillType, amount)
    local spec = self.spec_factory
    local previousFillLevel = spec.storage:getFillLevel(fillType)
    spec.storage:setFillLevel(previousFillLevel - amount, fillType)
    return previousFillLevel - spec.storage:getFillLevel(fillType)
end
function PlaceableFactory:updateInfoData()
    local spec = self.spec_factory
    spec.fillTypesAndLevelsAuxiliary = {}
    for fillType, fillLevel in pairs(spec.storage:getFillLevels()) do
        spec.fillTypesAndLevelsAuxiliary[fillType] = (spec.fillTypesAndLevelsAuxiliary[fillType] or 0) + fillLevel
    end
    table.clear(spec.infoTriggerFillTypesAndLevels)
    for fillType, fillLevel in pairs(spec.fillTypesAndLevelsAuxiliary) do
        if fillLevel > 0.1 then
            spec.fillTypeToFillTypeStorageTable[fillType] = spec.fillTypeToFillTypeStorageTable[fillType] or {
                ["fillType"] = fillType,
                ["fillLevel"] = fillLevel
            }
            spec.fillTypeToFillTypeStorageTable[fillType].fillLevel = fillLevel
            table.insert(spec.infoTriggerFillTypesAndLevels, spec.fillTypeToFillTypeStorageTable[fillType])
        end
    end
    table.clear(spec.fillTypesAndLevelsAuxiliary)
    table.sort(spec.infoTriggerFillTypesAndLevels, function(a, b)
        return a.fillLevel > b.fillLevel
    end)
end
function PlaceableFactory:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)
    local spec = self.spec_factory
    if spec.hasInputMaterials then
        local numEntries = math.min(#spec.infoTriggerFillTypesAndLevels, 7)
        if numEntries > 0 then
            local i = spec.infoTableEntryStorage
            table.insert(infoTable, i)
            local i = 1
            for i = i, numEntries do
                local fillTypeAndLevel = spec.infoTriggerFillTypesAndLevels[i]
                table.insert(infoTable, {
                    ["title"] = g_fillTypeManager:getFillTypeTitleByIndex(fillTypeAndLevel.fillType),
                    ["text"] = g_i18n:formatVolume(fillTypeAndLevel.fillLevel, 0)
                })
            end
        end
    else
        table.insert(infoTable, {
            ["title"] = g_i18n:getText("ui_production_status_materialsMissing"),
            ["accentuate"] = true
        })
        for i, fillTypeAndLevel in ipairs(spec.inputs) do
            table.insert(infoTable, {
                ["title"] = "   " .. g_fillTypeManager:getFillTypeTitleByIndex(fillTypeAndLevel.fillType.index)
            })
        end
    end
    table.insert(infoTable, {
        ["title"] = g_i18n:getText("contract_progress"),
        ["text"] = string.format("%.1f%%", spec.progress * 100),
        ["accentuate"] = true
    })
end
function PlaceableFactory:onInfoTriggerEnter(_)
    local spec = self.spec_factory
    if not spec.hasStorageListener then
        self:updateInfoData()
        spec.storage:addFillLevelChangedListeners(spec.storageFillLevelChangedCallback)
        spec.hasStorageListener = true
    end
end
function PlaceableFactory:onInfoTriggerLeave(_)
    local spec = self.spec_factory
    if spec.hasStorageListener then
        spec.storage:removeFillLevelChangedListeners(spec.storageFillLevelChangedCallback)
        spec.hasStorageListener = false
    end
end
function PlaceableFactory:playerTriggerCallback(_, otherId, onEnter, onLeave, _, _)
    if (onEnter or onLeave) and (g_localPlayer ~= nil and g_localPlayer.rootNode == otherId) then
        if onEnter then
            if Platform.isMobile and self.spec_factory.activatable:getIsActivatable() then
                spec.activatable:run()
                return
            end
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
        end
        if onLeave then
            g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
        end
    end
end
function PlaceableFactory:buyRequest(requestCallback, target)
    local price = self:getPrice()
    local function buyingEventCallback(statusCode)
        -- upvalues: (copy) self
        if statusCode ~= nil then
            local dialogArgs = BuyExistingPlaceableEvent.DIALOG_MESSAGES[statusCode]
            if dialogArgs ~= nil then
                InfoDialog.show(g_i18n:getText(dialogArgs.text), nil, nil, dialogArgs.dialogType)
            end
        end
        g_messageCenter:unsubscribe(BuyExistingPlaceableEvent, self)
    end
    local text = string.format(g_i18n:getText("dialog_buyBuildingFor"), self:getName(), g_i18n:formatMoney(price, 0, true))
    YesNoDialog.show(function(yes, _)
        -- upvalues: (copy) buyingEventCallback, (copy) self, (copy) requestCallback, (copy) target
        if yes then
            g_messageCenter:subscribe(BuyExistingPlaceableEvent, buyingEventCallback)
            g_client:getServerConnection():sendEvent(BuyExistingPlaceableEvent.new(self, g_currentMission:getFarmId()))
        end
        if requestCallback ~= nil then
            if target ~= nil then
                requestCallback(target, yes)
                return
            end
            requestCallback(yes)
        end
    end, nil, text)
end