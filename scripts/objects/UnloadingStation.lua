UnloadingStation = {}
UnloadingStation.FX_DURATION = 5000
local UnloadingStation_mt = Class(UnloadingStation, Object)
InitStaticObjectClass(UnloadingStation, "UnloadingStation")
function UnloadingStation.new(isServer, isClient, customMt)
    -- upvalues: (copy) UnloadingStation_mt
    return Object.new(isServer, isClient, customMt or UnloadingStation_mt)
end
function UnloadingStation:load(components, xmlFile, key, _, i3dMappings, rootNode)
    self.rootNode = rootNode or xmlFile:getValue(key .. "#node", rootNode, components, i3dMappings)
    if self.rootNode == nil then
        Logging.xmlError(xmlFile, "Missing node defined in \'%s\'", key)
        return false
    end
    self.rootNodeName = getName(self.rootNode)
    self.xmlKey = key
    local stationName = xmlFile:getValue(key .. "#stationName", nil)
    if stationName then
        stationName = g_i18n:convertText(stationName)
    end
    self.stationName = stationName
    self.storageRadius = xmlFile:getValue(key .. "#storageRadius", 50)
    self.hideFromPricesMenu = xmlFile:getValue(key .. "#hideFromPricesMenu", false)
    self.supportsExtension = xmlFile:getValue(key .. "#supportsExtension", false)
    self.isTrainStation = xmlFile:getValue(key .. "#isTrainStation", false)
    self.isPalletStation = xmlFile:getValue(key .. "#isPalletStation", false)
    self.owningPlaceable = nil
    self.hasStoragePerFarm = false
    self.targetStorages = {}
    self.supportedFillTypes = {}
    self.aiSupportedFillTypes = {}
    self.unloadTriggers = UnloadTrigger.createTriggers(self.isServer, self.isClient, xmlFile, key, components, self, nil, i3dMappings)
    for k, trigger in ipairs(self.unloadTriggers) do
        if trigger.fillTypes == nil or next(trigger.fillTypes) == nil then
            Logging.xmlWarning(xmlFile, "Unloading station trigger \'%d\' has no filltypes defined", k)
        end
        trigger:register(true)
    end
    for k, trigger in xmlFile:iterator(key .. ".simpleFillplane") do
        local node = xmlFile:getValue(trigger .. "#node", nil, components, i3dMappings)
        if node ~= nil then
            local fillTypes = g_fillTypeManager:loadCombinedFillTypesFromConfig(xmlFile, trigger)
            if fillTypes == nil then
                Logging.xmlWarning(xmlFile, "No filltypes defined for %q", trigger)
            else
                if self.simpleFillplanes == nil then
                    self.simpleFillplanes = {}
                    self.fillTypeIndexToFillplane = {}
                    g_messageCenter:subscribe(MessageType.DAY_CHANGED, UnloadingStation.dayChanged, self)
                end
                local fillplane = {
                    ["node"] = node,
                    ["hideTime"] = 0
                }
                table.insert(self.simpleFillplanes, fillplane)
                for _, fillTypeIndex in ipairs(fillTypes) do
                    if self.fillTypeIndexToFillplane[fillTypeIndex] == nil then
                        self.fillTypeIndexToFillplane[fillTypeIndex] = {}
                    end
                    table.insert(self.fillTypeIndexToFillplane[fillTypeIndex], fillplane)
                end
                setVisibility(node, false)
            end
        end
    end
    if self.isClient then
        local _, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFile:getFilename())
        self.samples = {
            ["idle"] = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "idle", baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil),
            ["active"] = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "active", baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
        }
        self.animations = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", components, self, i3dMappings)
        self.effects = g_effectManager:loadEffect(xmlFile, key .. ".effectNodes", components, self, i3dMappings)
        self.hasFx = self.samples.active ~= nil or (#self.animations > 0 or #self.effects > 0)
        self.fxTimer = nil
        self.fxActive = false
        g_soundManager:playSample(self.samples.idle)
    end
    self:updateSupportedFillTypes()
    self:validateUnloadTriggers(xmlFile, key)
    return true
end
function UnloadingStation:delete()
    if self.unloadTriggers ~= nil then
        for _, unloadTrigger in pairs(self.unloadTriggers) do
            unloadTrigger:delete()
        end
        table.clear(self.unloadTriggers)
    end
    if self.samples ~= nil then
        g_soundManager:stopSamples(self.samples)
        g_soundManager:deleteSamples(self.samples)
        table.clear(self.samples)
    end
    if self.animations ~= nil then
        g_animationManager:deleteAnimations(self.animations)
        table.clear(self.animations)
    end
    if self.effects ~= nil then
        g_effectManager:deleteEffects(self.effects)
        table.clear(self.effects)
    end
    if self.fxTimer ~= nil then
        self.fxTimer:delete()
        self.fxTimer = nil
    end
    if self.targetStorages ~= nil then
        for _, unloadTrigger in pairs(self.targetStorages) do
            _:removeUnloadingStation(self)
        end
        table.clear(self.targetStorages)
    end
    g_messageCenter:unsubscribeAll(self)
    self.owningPlaceable = nil
    UnloadingStation:superClass().delete(self)
end
function UnloadingStation:readStream(streamId, connection)
    UnloadingStation:superClass().readStream(self, streamId, connection)
    if connection:getIsServer() then
        for _, unloadTrigger in ipairs(self.unloadTriggers) do
            local unloadTriggerId = NetworkUtil.readNodeObjectId(streamId)
            unloadTrigger:readStream(streamId, connection)
            g_client:finishRegisterObject(unloadTrigger, unloadTriggerId)
        end
    end
end
function UnloadingStation:writeStream(streamId, connection)
    UnloadingStation:superClass().writeStream(self, streamId, connection)
    if not connection:getIsServer() then
        for _, unloadTrigger in ipairs(self.unloadTriggers) do
            NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(unloadTrigger))
            unloadTrigger:writeStream(streamId, connection)
            g_server:registerObjectInStream(connection, unloadTrigger)
        end
    end
end
function UnloadingStation:loadFromXMLFile(xmlFile, key)
    return true
end
function UnloadingStation:saveToXMLFile(xmlFile, key, usedModNames) end
function UnloadingStation:getName()
    return self.stationName or self.owningPlaceable and self.owningPlaceable:getName() or "Unloading Station"
end
function UnloadingStation:updateSupportedFillTypes()
    self.supportedFillTypes = {}
    self.aiSupportedFillTypes = {}
    for _, unloadTrigger in pairs(self.unloadTriggers) do
        if unloadTrigger.fillTypes ~= nil then
            local supportsAI = unloadTrigger:getSupportAIUnloading()
            for fillType, _ in pairs(unloadTrigger.fillTypes) do
                self.supportedFillTypes[fillType] = true
                if supportsAI then
                    self.aiSupportedFillTypes[fillType] = true
                end
            end
        end
    end
end
function UnloadingStation:addTargetStorage(storage)
    if storage == nil then
        return false
    end
    local hasMatchingFillType = storage.getFreeCapacity
    assert(hasMatchingFillType)
    local hasMatchingFillType = storage.getIsFillTypeSupported ~= nil
    assert(hasMatchingFillType)
    local hasMatchingFillType = storage.setFillLevel ~= nil
    assert(hasMatchingFillType)
    local hasMatchingFillType = storage.getFillLevel ~= nil
    assert(hasMatchingFillType)
    local storageFillTypes = storage.fillTypes
    if storage.supportedFillTypes ~= nil then
        storageFillTypes = storage.supportedFillTypes
    end
    local hasMatchingFillType = false
    for fillType, _ in pairs(storageFillTypes) do
        if self.supportedFillTypes[fillType] ~= nil then
            hasMatchingFillType = true
            break
        end
    end
    if not hasMatchingFillType then
        return false
    end
    self.targetStorages[storage] = storage
    storage:addUnloadingStation(self)
    return true
end
function UnloadingStation:removeTargetStorage(storage)
    if storage ~= nil then
        storage:removeUnloadingStation(self)
        self.targetStorages[storage] = nil
    end
end
function UnloadingStation:getIsFillTypeSupported(fillTypeIndex)
    return self.supportedFillTypes[fillTypeIndex] ~= nil
end
function UnloadingStation:getSupportedFillTypes()
    return self.supportedFillTypes
end
function UnloadingStation:getIsFillTypeAISupported(fillTypeIndex)
    return self.aiSupportedFillTypes[fillTypeIndex] ~= nil
end
function UnloadingStation:getAISupportedFillTypes()
    return self.aiSupportedFillTypes
end
function UnloadingStation:getIsFillTypeAllowed(fillTypeIndex, extraAttributes)
    return true
end
function UnloadingStation:getFreeCapacity(fillTypeIndex, farmId)
    local freeCapacity = 0
    for _, targetStorage in pairs(self.targetStorages) do
        if farmId == nil or self:hasFarmAccessToStorage(farmId, targetStorage) then
            freeCapacity = freeCapacity + targetStorage:getFreeCapacity(fillTypeIndex)
        end
    end
    return freeCapacity
end
function UnloadingStation:getCapacity(fillTypeIndex, farmId)
    local capacity = 0
    for _, targetStorage in pairs(self.targetStorages) do
        if self:hasFarmAccessToStorage(farmId, targetStorage) and targetStorage:getIsFillTypeSupported(fillTypeIndex) then
            local storageCapacity = targetStorage:getCapacity(fillTypeIndex)
            if storageCapacity ~= nil then
            end
        end
    end
    return capacity
end
function UnloadingStation:getFillLevel(fillTypeIndex, farmId)
    local fillLevel = 0
    for _, targetStorage in pairs(self.targetStorages) do
        if self:hasFarmAccessToStorage(farmId, targetStorage) then
            fillLevel = fillLevel + targetStorage:getFillLevel(fillTypeIndex)
        end
    end
    return fillLevel
end
function UnloadingStation:getIsToolTypeAllowed(toolType)
    return true
end
function UnloadingStation:addFillLevelFromTool(farmId, deltaFillLevel, fillType, fillInfo, toolType, _)
    assert(deltaFillLevel >= 0)
    local movedFillLevel = 0
    if self:getIsFillTypeAllowed(fillType) and self:getIsToolTypeAllowed(toolType) then
        for _, targetStorage in pairs(self.targetStorages) do
            if self:hasFarmAccessToStorage(farmId, targetStorage) then
                if targetStorage:getFreeCapacity(fillType) > 0 then
                    local oldFillLevel = targetStorage:getFillLevel(fillType)
                    targetStorage:setFillLevel(oldFillLevel + deltaFillLevel, fillType, fillInfo)
                    movedFillLevel = movedFillLevel + (targetStorage:getFillLevel(fillType) - oldFillLevel)
                end
                if deltaFillLevel - 0.001 <= movedFillLevel then
                    self:startFx(fillType)
                    movedFillLevel = deltaFillLevel
                    break
                end
            end
        end
    end
    self:activateSimpleFillplanes(fillType)
    return movedFillLevel
end
function UnloadingStation:activateSimpleFillplanes(fillTypeIndex)
    if self.fillTypeIndexToFillplane ~= nil then
        local fillplanes = self.fillTypeIndexToFillplane[fillTypeIndex]
        if fillplanes ~= nil then
            for _, fillplane in ipairs(fillplanes) do
                setVisibility(fillplane.node, true)
            end
        end
    end
end
function UnloadingStation:startFx(fillType)
    if self.isClient and self.hasFx then
        if self.fxTimer == nil then
            self.fxTimer = Timer.new(UnloadingStation.FX_DURATION):setFinishCallback(function()
                -- upvalues: (copy) self
                if self.isClient then
                    g_soundManager:stopSample(self.samples.active)
                    g_animationManager:stopAnimations(self.animations)
                    g_effectManager:stopEffects(self.effects)
                    self.fxActive = false
                end
            end)
        end
        self.fxTimer:start()
        if not self.fxActive then
            g_soundManager:playSample(self.samples.active)
            g_animationManager:startAnimations(self.animations)
            g_effectManager:setEffectTypeInfo(self.effects, fillType)
            g_effectManager:startEffects(self.effects)
            self.fxActive = true
        end
    end
end
function UnloadingStation:getIsFillAllowedFromFarm(farmId)
    for _, targetStorage in pairs(self.targetStorages) do
        if self:hasFarmAccessToStorage(farmId, targetStorage) then
            return true
        end
    end
    return false
end
function UnloadingStation:hasFarmAccessToStorage(farmId, storage)
    if not self.hasStoragePerFarm then
        return g_currentMission.accessHandler:canFarmAccess(farmId, storage, true)
    end
    local mission = farmId == storage:getOwnerFarmId()
    return mission
end
function UnloadingStation:getAITargetPositionAndDirection(fillType)
    local unloadTrigger = nil
    for _, trigger in ipairs(self.unloadTriggers) do
        if trigger:getSupportAIUnloading() and (fillType == FillType.UNKNOWN or trigger:getIsFillTypeAllowed(fillType)) then
            unloadTrigger = trigger
            break
        end
    end
    if unloadTrigger == nil then
        return nil
    end
    local x, z, xDir, _ = unloadTrigger:getAITargetPositionAndDirection()
    return x, z, xDir, _, unloadTrigger
end
function UnloadingStation:setOwnerFarmId(farmId, noEventSend)
    UnloadingStation:superClass().setOwnerFarmId(self, farmId, noEventSend)
    for _, unloadTrigger in ipairs(self.unloadTriggers) do
        unloadTrigger:setOwnerFarmId(farmId, true)
    end
end
function UnloadingStation:dayChanged()
    for _, fillplane in ipairs(self.simpleFillplanes) do
        setVisibility(fillplane.node, false)
    end
end
function UnloadingStation:validateUnloadTriggers(xmlFile, key)
    for fillTypeIndex, _ in pairs(self.supportedFillTypes) do
        local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
        if fillTypeDesc.isPalletType then
            local isValid = false
            for _, unloadTrigger in pairs(self.unloadTriggers) do
                if unloadTrigger.fillTypes[fillTypeIndex] ~= nil then
                    if ClassUtil.getClassObjectByObject(unloadTrigger) == PalletUnloadTrigger then
                        isValid = true
                    elseif unloadTrigger.exactFillRootNode == nil and ClassUtil.getClassObjectByObject(unloadTrigger) == UnloadTrigger then
                        isValid = true
                    end
                end
            end
            if not isValid then
                Logging.xmlDevWarning(xmlFile, "UnloadingStation does not have a PalletUnloadTrigger for fillType \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex))
            end
        end
        if not (self.isTrainStation or self.isPalletStation) then
            if fillTypeDesc.isBaleType then
                local isValid = false
                for _, unloadTrigger in pairs(self.unloadTriggers) do
                    if unloadTrigger.fillTypes[fillTypeIndex] ~= nil then
                        if ClassUtil.getClassObjectByObject(unloadTrigger) == BaleUnloadTrigger then
                            isValid = true
                        elseif unloadTrigger.exactFillRootNode == nil and ClassUtil.getClassObjectByObject(unloadTrigger) == UnloadTrigger then
                            isValid = true
                        end
                    end
                end
                if not (isValid or string.contains(key, "husbandry")) then
                    Logging.xmlWarning(xmlFile, "UnloadingStation does not have a BaleUnloadTrigger for fillType \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex))
                end
            end
            if fillTypeDesc.isBulkType then
                local isValid = false
                for _, unloadTrigger in pairs(self.unloadTriggers) do
                    if ClassUtil.getClassObjectByObject(unloadTrigger) == UnloadTrigger and unloadTrigger.fillTypes[fillTypeIndex] ~= nil then
                        isValid = true
                    end
                end
                if not isValid then
                    Logging.xmlWarning(xmlFile, "UnloadingStation does not have a regular UnloadTrigger for fillType \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex))
                end
            end
        end
    end
end
function UnloadingStation.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Unloading station node")
    schema:register(XMLValueType.STRING, basePath .. "#stationName", "Station name", "LoadingStation")
    schema:register(XMLValueType.FLOAT, basePath .. "#storageRadius", "Inside of this radius storages can be placed", 50)
    schema:register(XMLValueType.BOOL, basePath .. "#hideFromPricesMenu", "Hide station from prices menu", false)
    schema:register(XMLValueType.BOOL, basePath .. "#supportsExtension", "Supports extensions", false)
    schema:register(XMLValueType.BOOL, basePath .. "#isTrainStation", "Is part of the train system", false)
    schema:register(XMLValueType.BOOL, basePath .. "#isPalletStation", "At this selling station good can be unloaded only as pallets", false)
    UnloadTrigger.registerTriggerXMLPaths(schema, basePath)
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "active")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "idle")
    AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".animationNodes")
    EffectManager.registerEffectXMLPaths(schema, basePath .. ".effectNodes")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".simpleFillplane(?)#node", "A fillplane that should be visible after unloading")
    FillTypeManager.registerConfigXMLFilltypes(schema, basePath .. ".simpleFillplane(?)")
end