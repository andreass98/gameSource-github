PlaceableManureHeap = {}
function PlaceableManureHeap.prerequisitesPresent(specializations)
    return true
end
function PlaceableManureHeap.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableManureHeap.setOwnerFarmId)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableManureHeap.collectPickObjects)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getCanBePlacedAt", PlaceableManureHeap.getCanBePlacedAt)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableManureHeap.updateInfo)
end
function PlaceableManureHeap.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableManureHeap)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableManureHeap)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableManureHeap)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableManureHeap)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableManureHeap)
end
function PlaceableManureHeap.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("ManureHeap")
    ManureHeap.registerXMLPaths(schema, basePath .. ".manureHeap")
    schema:register(XMLValueType.BOOL, basePath .. ".manureHeap#needsBarn", "Can only be placed next to a barn", true)
    LoadingStation.registerXMLPaths(schema, basePath .. ".manureHeap.loadingStation")
    schema:setXMLSpecializationType()
end
function PlaceableManureHeap.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("ManureHeap")
    ManureHeap.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType()
end
function PlaceableManureHeap.initSpecialization()
    g_storeManager:addSpecType("manureHeapCapacity", "shopListAttributeIconCapacity", PlaceableManureHeap.loadSpecValueCapacity, PlaceableManureHeap.getSpecValueCapacity, StoreSpecies.PLACEABLE)
end
function PlaceableManureHeap:onLoad(_)
    local spec = self.spec_manureHeap
    local xmlFile = self.xmlFile
    spec.loadingStation = LoadingStation.new(self.isServer, self.isClient)
    if not spec.loadingStation:load(spec.components, xmlFile, "placeable.manureHeap.loadingStation", self.customEnvironment, self.i3dMappings, self.components[1].node) then
        spec.loadingStation:delete()
        spec.loadingStation = nil
        return false
    end
    spec.loadingStation.owningPlaceable = self
    spec.loadingStation.hasStoragePerFarm = false
    spec.manureHeap = ManureHeap.new(spec.isServer, self.isClient)
    if not spec.manureHeap:load(spec.components, xmlFile, "placeable.manureHeap", self.customEnvironment, self.i3dMappings, self.components[1].node) then
        spec.manureHeap:delete()
        spec.manureHeap = nil
    end
    spec.needsBarn = xmlFile:getValue("placeable.manureHeap#needsBarn", false)
    spec.infoFillLevel = {
        ["title"] = g_i18n:getText("fillType_manure"),
        ["text"] = ""
    }
    return true
end
function PlaceableManureHeap:onDelete()
    local spec = self.spec_manureHeap
    if spec.manureHeap ~= nil then
        if g_currentMission.storageSystem:hasStorage(spec.manureHeap) then
            storageSystem:removeStorageFromUnloadingStations(spec.manureHeap, spec.manureHeap.unloadingStations)
            storageSystem:removeStorageFromLoadingStations(spec.manureHeap, spec.manureHeap.loadingStations)
            storageSystem:removeStorage(spec.manureHeap)
        end
        spec.manureHeap:delete()
        spec.manureHeap = nil
    end
    if spec.loadingStation ~= nil then
        if spec.loadingStation:getIsFillTypeSupported(FillType.MANURE) then
            g_currentMission:removeManureLoadingStation(spec.loadingStation)
        end
        storageSystem:removeLoadingStation(spec.loadingStation, self)
        spec.loadingStation:delete()
        spec.loadingStation = nil
    end
end
function PlaceableManureHeap:onFinalizePlacement()
    local spec = self.spec_manureHeap
    local ownerFarmId = self:getOwnerFarmId()
    if spec.loadingStation ~= nil and spec.manureHeap ~= nil then
        spec.loadingStation:register(true)
        g_currentMission.storageSystem:addLoadingStation(spec.loadingStation, self)
        spec.manureHeap:finalize()
        spec.manureHeap:register(true)
        spec.manureHeap:setOwnerFarmId(ownerFarmId, true)
        storageSystem:addStorage(spec.manureHeap)
        storageSystem:addStorageToLoadingStation(spec.manureHeap, spec.loadingStation)
        if spec.loadingStation:getIsFillTypeSupported(FillType.MANURE) then
            g_currentMission:addManureLoadingStation(spec.loadingStation)
        end
        local storagesInRange = storageSystem:getStorageExtensionsInRange(spec.loadingStation, ownerFarmId)
        for _, storage in ipairs(storagesInRange) do
            if spec.loadingStation.sourceStorages[storage] == nil then
                storageSystem:addStorageToLoadingStation(storage, spec.loadingStation)
            end
        end
        local lastFoundUnloadingStations = storageSystem:getExtendableUnloadingStationsInRange(spec.manureHeap, ownerFarmId)
        local lastFoundLoadingStations = storageSystem:getExtendableLoadingStationsInRange(spec.manureHeap, ownerFarmId)
        storageSystem:addStorageToUnloadingStations(spec.manureHeap, lastFoundUnloadingStations)
        storageSystem:addStorageToLoadingStations(spec.manureHeap, lastFoundLoadingStations)
    end
end
function PlaceableManureHeap:onReadStream(streamId, connection)
    local spec = self.spec_manureHeap
    if spec.loadingStation ~= nil and spec.manureHeap ~= nil then
        local loadingStationId = NetworkUtil.readNodeObjectId(streamId)
        spec.loadingStation:readStream(streamId, connection)
        g_client:finishRegisterObject(spec.loadingStation, loadingStationId)
        local manureHeapId = NetworkUtil.readNodeObjectId(streamId)
        spec.manureHeap:readStream(streamId, connection)
        g_client:finishRegisterObject(spec.manureHeap, manureHeapId)
    end
end
function PlaceableManureHeap:onWriteStream(streamId, connection)
    local spec = self.spec_manureHeap
    if spec.loadingStation ~= nil and spec.manureHeap ~= nil then
        NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.loadingStation))
        spec.loadingStation:writeStream(streamId, connection)
        g_server:registerObjectInStream(connection, spec.loadingStation)
        NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.manureHeap))
        spec.manureHeap:writeStream(streamId, connection)
        g_server:registerObjectInStream(connection, spec.manureHeap)
    end
end
function PlaceableManureHeap:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_manureHeap
    if spec.manureHeap ~= nil then
        spec.manureHeap:loadFromXMLFile(xmlFile, key)
    end
end
function PlaceableManureHeap:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_manureHeap
    if spec.manureHeap ~= nil then
        spec.manureHeap:saveToXMLFile(xmlFile, key, usedModNames)
    end
end
function PlaceableManureHeap:setOwnerFarmId(superFunc, farmId, noEventSend)
    superFunc(self, farmId, noEventSend)
    local spec = self.spec_manureHeap
    if self.isServer and spec.manureHeap ~= nil then
        spec.manureHeap:setOwnerFarmId(farmId, true)
    end
    if spec.loadingStation ~= nil then
        local storagesInRange = g_currentMission.storageSystem:getStorageExtensionsInRange(spec.loadingStation, farmId)
        for _, storage in ipairs(storagesInRange) do
            if spec.loadingStation.sourceStorages[storage] == nil then
                storageSystem:addStorageToLoadingStation(storage, spec.loadingStation)
            end
        end
    end
    if spec.manureHeap ~= nil then
        local storagesInRange = storageSystem:getExtendableUnloadingStationsInRange(spec.manureHeap, farmId)
        local lastFoundLoadingStations = storageSystem:getExtendableLoadingStationsInRange(spec.manureHeap, farmId)
        storageSystem:addStorageToUnloadingStations(spec.manureHeap, storagesInRange)
        storageSystem:addStorageToLoadingStations(spec.manureHeap, lastFoundLoadingStations)
    end
end
function PlaceableManureHeap:collectPickObjects(superFunc, node)
    local spec = self.spec_manureHeap
    if spec.loadingStation ~= nil then
        for _, loadTrigger in ipairs(spec.loadingStation.loadTriggers) do
            if node == loadTrigger.triggerNode then
                return
            end
        end
    end
    if spec.manureHeap == nil or node ~= spec.manureHeap.activationTriggerNode then
        superFunc(self, node)
    end
end
function PlaceableManureHeap:getCanBePlacedAt(superFunc, x, y, z, farmId)
    local spec = self.spec_manureHeap
    if spec.manureHeap == nil then
        return false
    elseif spec.needsBarn and #g_currentMission.storageSystem:getExtendableUnloadingStationsInRange(spec.manureHeap, farmId, x, y, z) == 0 then
        return false, g_i18n:getText("warning_manureHeapNotNearBarn")
    else
        return superFunc(self, x, y, z, farmId)
    end
end
function PlaceableManureHeap:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)
    local spec = self.spec_manureHeap
    if spec.manureHeap ~= nil then
        local fillLevel = spec.manureHeap:getFillLevel(spec.manureHeap.fillTypeIndex)
        spec.infoFillLevel.text = string.format("%d l", fillLevel)
        table.insert(infoTable, spec.infoFillLevel)
    end
end
function PlaceableManureHeap.loadSpecValueCapacity(xmlFile, _, _)
    return xmlFile:getValue("placeable.manureHeap#capacity")
end
function PlaceableManureHeap.getSpecValueCapacity(storeItem, _)
    if storeItem.specs.manureHeapCapacity == nil then
        return nil
    else
        return g_i18n:formatVolume(storeItem.specs.manureHeapCapacity)
    end
end