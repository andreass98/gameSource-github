PalletSpawner = {}
PalletSpawner.RESULT_NO_SPACE = 0
PalletSpawner.RESULT_SUCCESS = 1
PalletSpawner.RESULT_ERROR_LOADING_PALLET = 2
PalletSpawner.PALLET_ALREADY_PRESENT = 3
PalletSpawner.NO_PALLET_FOR_FILLTYPE = 4
PalletSpawner.PALLET_LIMITED_REACHED = 5
local PalletSpawner_mt = Class(PalletSpawner)
function PalletSpawner.new(baseDirectory, customMt)
    -- upvalues: (copy) PalletSpawner_mt
    local self = setmetatable({}, customMt or PalletSpawner_mt)
    self.baseDirectory = baseDirectory
    self.spawnQueue = {}
    self.currentObjectToSpawn = nil
    self.spawnOffsetY = Platform.gameplay.hasDynamicPallets and 0.2 or 0
    return self
end
function PalletSpawner:load(components, xmlFile, key, _, i3dMappings)
    self.spawnPlaces = {}
    self.fillTypeToSpawnPlaces = {}
    local hasFillTypeSpawnPlaces = false
    for _, spawnPlaceKey in xmlFile:iterator(key .. ".spawnPlaces.spawnPlace") do
        local spawnPlace = PlacementUtil.loadPlaceFromXML(xmlFile, spawnPlaceKey, components, i3dMappings)
        local fillTypes = nil
        local fillTypeCategories = xmlFile:getValue(spawnPlaceKey .. "#fillTypeCategories")
        local fillTypeNames = xmlFile:getValue(spawnPlaceKey .. "#fillTypes")
        if fillTypeCategories == nil or fillTypeNames ~= nil then
            if fillTypeCategories == nil and fillTypeNames ~= nil then
                fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: Palletspawner \'" .. xmlFile:getFilename() .. "\' has invalid fillType \'%s\'.")
            end
        else
            fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: Palletspawner \'" .. xmlFile:getFilename() .. "\' has invalid fillTypeCategory \'%s\'.")
        end
        if fillTypes == nil then
            table.insert(self.spawnPlaces, spawnPlace)
        else
            hasFillTypeSpawnPlaces = true
            for _, fillType in ipairs(fillTypes) do
                if self.fillTypeToSpawnPlaces[fillType] == nil then
                    self.fillTypeToSpawnPlaces[fillType] = {}
                end
                table.insert(self.fillTypeToSpawnPlaces[fillType], spawnPlace)
            end
        end
    end
    if #self.spawnPlaces == 0 and not hasFillTypeSpawnPlaces then
        Logging.xmlError(xmlFile, "No spawn place(s) defined for pallet spawner %s%s", key, ".spawnPlaces")
        return false
    end
    self.pallets = {}
    self.fillTypeIdToPallet = {}
    for _, spawnPlaceKey in pairs(g_fillTypeManager.indexToFillType) do
        if spawnPlaceKey.palletFilename then
            self:loadPalletFromFilename(spawnPlaceKey.palletFilename, _)
        end
    end
    for _, spawnPlaceKey in xmlFile:iterator(key .. ".pallets.pallet") do
        self:loadPalletFromFilename((Utils.getFilename(xmlFile:getValue(spawnPlaceKey .. "#filename"), self.baseDirectory)))
    end
    return true
end
function PalletSpawner:delete() end
function PalletSpawner:loadPalletFromFilename(palletFilename, limitFillTypeId)
    if palletFilename ~= nil then
        local pallet = {
            ["filename"] = palletFilename,
            ["size"] = StoreItemUtil.getSizeValues(palletFilename, "vehicle", 0, {})
        }
        local palletXmlFile = XMLFile.load("palletXmlFilename", palletFilename, Vehicle.xmlSchema)
        if palletXmlFile == nil then
            return nil
        end
        local fillTypeNamesAndCategories = FillUnit.getFillTypeNamesFromXML(palletXmlFile)
        pallet.capacity = FillUnit.getCapacityFromXml(palletXmlFile)
        palletXmlFile:delete()
        local hadMatchingFillType = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeNamesAndCategories.fillTypeCategoryNames, nil, {})
        local hadMatchingFillType = g_fillTypeManager:getFillTypesByNames(fillTypeNamesAndCategories.fillTypeNames, nil, hadMatchingFillType)
        local hadMatchingFillType = false
        for _, fillTypeId in ipairs(hadMatchingFillType) do
            if limitFillTypeId == nil or limitFillTypeId == fillTypeId then
                self.fillTypeIdToPallet[fillTypeId] = pallet
                hadMatchingFillType = true
            end
        end
        if hadMatchingFillType then
            table.insert(self.pallets, pallet)
            return pallet
        end
    end
    return nil
end
function PalletSpawner:getSupportedFillTypes()
    return self.fillTypeIdToPallet
end
function PalletSpawner:spawnPallet(farmId, fillTypeId, callback, callbackTarget)
    if g_currentMission.slotSystem:getCanAddLimitedObjects(SlotSystem.LIMITED_OBJECT_PALLET, 1) then
        local pallet = self.fillTypeIdToPallet[fillTypeId]
        if pallet == nil then
            Logging.devError("PalletSpawner: no pallet for fillTypeId \'%s\'", fillTypeId)
            callback(callbackTarget, nil, PalletSpawner.NO_PALLET_FOR_FILLTYPE, fillTypeId)
        else
            table.insert(self.spawnQueue, {
                ["pallet"] = pallet,
                ["fillType"] = fillTypeId,
                ["farmId"] = farmId,
                ["callback"] = callback,
                ["callbackTarget"] = callbackTarget
            })
            g_currentMission:addUpdateable(self)
        end
    else
        callback(callbackTarget, nil, PalletSpawner.PALLET_LIMITED_REACHED, fillTypeId)
        return
    end
end
function PalletSpawner:getOrSpawnPallet(farmId, fillTypeId, callback, callbackTarget)
    self.foundExistingPallet = nil
    self.getOrSpawnPalletFilltype = fillTypeId
    local spawnPlaces = self.fillTypeToSpawnPlaces[fillTypeId] or self.spawnPlaces
    local i = 1
    for i = i, #spawnPlaces do
        local place = spawnPlaces[i]
        overlapBox(place.startX + place.width / 2 * place.dirX, place.startY + place.width / 2 * place.dirY, place.startZ + place.width / 2 * place.dirZ, place.rotX, place.rotY, place.rotZ, place.width / 2, 1, 1, "onFindExistingPallet", self, CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT, true, true, false, true)
    end
    if self.foundExistingPallet == nil then
        self:spawnPallet(farmId, fillTypeId, callback, callbackTarget)
    else
        callback(callbackTarget, self.foundExistingPallet, PalletSpawner.PALLET_ALREADY_PRESENT, fillTypeId)
    end
end
function PalletSpawner:getAllPallets(fillTypeId, callbackFunc, callbackTarget)
    self.getAllPalletsFoundPallets = {}
    self.getAllPalletsFilltype = fillTypeId
    local spawnPlaces = self.fillTypeToSpawnPlaces[fillTypeId] or self.spawnPlaces
    local i = 1
    for i = i, #spawnPlaces do
        local place = spawnPlaces[i]
        overlapBox(place.startX + place.width / 2 * place.dirX, place.startY + place.width / 2 * place.dirY, place.startZ + place.width / 2 * place.dirZ, place.rotX, place.rotY, place.rotZ, place.width / 2, 1, 1, "onFindPallet", self, CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT, true, true, false, true)
    end
    callbackFunc(callbackTarget, table.toList(self.getAllPalletsFoundPallets), fillTypeId)
end
function PalletSpawner:update(_)
    if #self.spawnQueue > 0 then
        if self.currentObjectToSpawn == nil then
            self.currentObjectToSpawn = self.spawnQueue[1]
            g_currentMission.placementManager:getPlaceAsync(self.fillTypeToSpawnPlaces[self.currentObjectToSpawn.fillType] or self.spawnPlaces, self.currentObjectToSpawn.pallet.size, self.onSpawnSearchFinished, self, nil, self.spawnOffsetY, nil, nil)
            return
        end
    else
        g_currentMission:removeUpdateable(self)
    end
end
function PalletSpawner:onSpawnSearchFinished(location)
    if location == nil then
        self.currentObjectToSpawn.callback(self.currentObjectToSpawn.callbackTarget, nil, PalletSpawner.RESULT_NO_SPACE, self.currentObjectToSpawn.fillType)
        self.currentObjectToSpawn = nil
        table.remove(self.spawnQueue, 1)
    else
        location.y = math.max(getTerrainHeightAtWorldPos(g_terrainNode, location.x, 0, location.z) + self.spawnOffsetY, location.y)
        local data = VehicleLoadingData.new()
        data:setFilename(objectToSpawn.pallet.filename)
        data:setPosition(location.x, location.y, location.z)
        data:setRotation(location.xRot, location.yRot, location.zRot)
        data:setPropertyState(VehiclePropertyState.OWNED)
        data:setOwnerFarmId(objectToSpawn.farmId)
        data:setCustomParameter("spawnEmpty", true)
        data:load(self.onFinishLoadingPallet, self)
    end
end
function PalletSpawner:onFinishLoadingPallet(vehicles, vehicleLoadState)
    local objectToSpawn = self.currentObjectToSpawn
    objectToSpawn.callback(objectToSpawn.callbackTarget, vehicles[1], vehicleLoadState == VehicleLoadingState.OK and PalletSpawner.RESULT_SUCCESS or PalletSpawner.RESULT_ERROR_LOADING_PALLET, objectToSpawn.fillType)
    self.currentObjectToSpawn = nil
    table.remove(self.spawnQueue, 1)
end
function PalletSpawner:onFindExistingPallet(node)
    local object = g_currentMission.nodeToObject[node]
    if object ~= nil and (object.isa ~= nil and (object:isa(Vehicle) and (object.isPallet and (object:getFillUnitSupportsFillType(1, self.getOrSpawnPalletFilltype) and object:getFillUnitFreeCapacity(1, self.getOrSpawnPalletFilltype) > 0)))) then
        self.foundExistingPallet = object
        return false
    end
end
function PalletSpawner:onFindPallet(node)
    local object = g_currentMission.nodeToObject[node]
    if object ~= nil and (object.isa ~= nil and (object:isa(Vehicle) and (object.isPallet and object:getFillUnitFillType(object.spec_pallet.fillUnitIndex) == self.getAllPalletsFilltype))) then
        self.getAllPalletsFoundPallets[object] = true
    end
end
function PalletSpawner.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".spawnPlaces.spawnPlace(?)#fillTypes", "Supported filltypes for this spawnPlace")
    schema:register(XMLValueType.STRING, basePath .. ".spawnPlaces.spawnPlace(?)#fillTypeCategories", "Supported filltype categories for this spawnPlace")
    PlacementUtil.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".pallets.pallet(?)#filename", "Path to pallet xml file")
end