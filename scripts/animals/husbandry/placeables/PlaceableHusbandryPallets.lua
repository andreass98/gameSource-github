PlaceableHusbandryPallets = {}
function PlaceableHusbandryPallets.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, specializations)
end
function PlaceableHusbandryPallets.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onPalletTriggerCallback", PlaceableHusbandryPallets.onPalletTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "getAllPalletsCallback", PlaceableHusbandryPallets.getAllPalletsCallback)
    SpecializationUtil.registerFunction(placeableType, "updatePallets", PlaceableHusbandryPallets.updatePallets)
    SpecializationUtil.registerFunction(placeableType, "addPendingLiters", PlaceableHusbandryPallets.addPendingLiters)
    SpecializationUtil.registerFunction(placeableType, "getPalletCallback", PlaceableHusbandryPallets.getPalletCallback)
    SpecializationUtil.registerFunction(placeableType, "showSpawnerBlockedWarning", PlaceableHusbandryPallets.showSpawnerBlockedWarning)
    SpecializationUtil.registerFunction(placeableType, "showPalletBlockedWarning", PlaceableHusbandryPallets.showPalletBlockedWarning)
    SpecializationUtil.registerFunction(placeableType, "updatePalletInfo", PlaceableHusbandryPallets.updatePalletInfo)
end
function PlaceableHusbandryPallets.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryPallets.getConditionInfos)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryPallets.updateOutput)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryPallets.updateInfo)
end
function PlaceableHusbandryPallets.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryPallets)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryPallets)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryPallets)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryPallets)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryPallets)
    SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableHusbandryPallets)
    SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableHusbandryPallets)
    SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryPallets)
end
function PlaceableHusbandryPallets.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    basePath = basePath .. ".husbandry.pallets.palletSpawner(?)"
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".palletTrigger(?)#node", "A pallet trigger")
    FillTypeManager.registerConfigXMLFilltypes(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#unitText", "Pallet fill type unit")
    schema:register(XMLValueType.INT, basePath .. "#maxNumPallets", "Maximum number of pallets")
    PalletSpawner.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType()
end
function PlaceableHusbandryPallets.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    schema:register(XMLValueType.STRING, basePath .. ".pendingLiters(?)#fillType", "Name of the filltype")
    schema:register(XMLValueType.FLOAT, basePath .. ".pendingLiters(?)#liters", "Pending liters")
    schema:setXMLSpecializationType()
end
function PlaceableHusbandryPallets:onLoad(_)
    local spec = self.spec_husbandryPallets
    spec.fillTypeIndexToPalletSpawner = {}
    spec.palletSpawner = {}
    spec.fillTypes = {}
    spec.litersPerHour = {}
    spec.currentPallets = {}
    spec.maxNumPallets = {}
    spec.numPalletInfoUpdateRunning = 0
    spec.numSpawnsPending = 0
    spec.pendingLiters = {}
    spec.capacities = {}
    spec.capacitiesPending = {}
    spec.capacitiesSent = {}
    spec.maxCapacitiesPending = {}
    spec.fillLevels = {}
    spec.fillLevelsPending = {}
    spec.fillLevelsSent = {}
    spec.pallets = {}
    spec.activeFillTypes = {}
    for _, key in self.xmlFile:iterator("placeable.husbandry.pallets.palletSpawner") do
        local fillTypes = g_fillTypeManager:loadCombinedFillTypesFromConfig(self.xmlFile, key)
        if #fillTypes > 0 then
            local maxNumPallets = self.xmlFile:getValue(key .. "#maxNumPallets", 1)
            local palletSpawner = PalletSpawner.new(self.baseDirectory)
            palletSpawner:load(self.components, self.xmlFile, key, self.customEnvironment, self.i3dMappings)
            for _, fillTypeIndex in ipairs(fillTypes) do
                if spec.fillTypeIndexToPalletSpawner[fillTypeIndex] == nil then
                    spec.fillTypeIndexToPalletSpawner[fillTypeIndex] = palletSpawner
                    table.insert(spec.fillTypes, fillTypeIndex)
                    spec.litersPerHour[fillTypeIndex] = 0
                    spec.maxNumPallets[fillTypeIndex] = maxNumPallets
                    spec.capacities[fillTypeIndex] = 0
                    spec.capacitiesPending[fillTypeIndex] = 0
                    spec.capacitiesSent[fillTypeIndex] = 0
                    spec.maxCapacitiesPending[fillTypeIndex] = 0
                    spec.fillLevels[fillTypeIndex] = 0
                    spec.fillLevelsPending[fillTypeIndex] = 0
                    spec.fillLevelsSent[fillTypeIndex] = 0
                    spec.pendingLiters[fillTypeIndex] = 0
                else
                    Logging.xmlWarning(self.xmlFile, "There is already a palletSpawner defined for fillType \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex))
                end
            end
            local palletTriggers = nil
            if self.isServer then
                for fillTypeIndex, triggerKey in self.xmlFile:iterator(key .. ".palletTrigger") do
                    local node = self.xmlFile:getValue(triggerKey .. "#node", nil, self.components, self.i3dMappings)
                    if node ~= nil then
                        if CollisionFlag.getHasMaskFlagSet(node, CollisionFlag.VEHICLE) then
                            table.insert({}, {
                                ["node"] = node,
                                ["added"] = false
                            })
                        else
                            Logging.xmlWarning(self.xmlFile, "Pallet trigger %q at %q does not have \'VEHICLE\' bit set in its mask, ignoring", I3DUtil.getNodePath(node, self.rootNode), triggerKey)
                        end
                    end
                end
            end
            table.insert(spec.palletSpawner, {
                ["palletSpawner"] = palletSpawner,
                ["maxNumPallets"] = maxNumPallets,
                ["palletTriggers"] = palletTriggers
            })
        end
    end
    spec.palletLimitReached = false
    spec.infoHudTooManyPallets = {
        ["title"] = g_i18n:getText("infohud_tooManyPallets"),
        ["accentuate"] = true
    }
    spec.dirtyFlag = self:getNextDirtyFlag()
    local animalTypeIndex = self:getAnimalTypeIndex()
    local animalType = g_currentMission.animalSystem:getTypeByIndex(animalTypeIndex)
    if animalType ~= nil then
        for fillTypes, maxNumPallets in ipairs(animalType.subTypes) do
            local palletSpawner = g_currentMission.animalSystem:getSubTypeByIndex(maxNumPallets)
            if palletSpawner.output ~= nil then
                local palletTriggers = palletSpawner.output.pallets
                if palletTriggers ~= nil and spec.litersPerHour[palletTriggers.fillType] == nil then
                    Logging.xmlWarning(self.xmlFile, "Husbandry does not support pallet filltype \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(palletTriggers.fillType))
                end
            end
        end
    end
end
function PlaceableHusbandryPallets:onDelete()
    local spec = self.spec_husbandryPallets
    if spec.palletSpawner ~= nil then
        for _, info in ipairs(spec.palletSpawner) do
            info.palletSpawner:delete()
            if info.palletTriggers ~= nil then
                for _, trigger in ipairs(info.palletTriggers) do
                    if trigger.added then
                        removeTrigger(trigger.node)
                    end
                end
            end
        end
    end
end
function PlaceableHusbandryPallets:onFinalizePlacement()
    local spec = self.spec_husbandryPallets
    if spec.palletSpawner ~= nil then
        for _, info in ipairs(spec.palletSpawner) do
            if info.palletTriggers ~= nil then
                for _, trigger in ipairs(info.palletTriggers) do
                    addTrigger(trigger.node, "onPalletTriggerCallback", self)
                    trigger.added = true
                end
            end
        end
    end
end
function PlaceableHusbandryPallets:onReadStream(streamId, _)
    local spec = self.spec_husbandryPallets
    for _, fillTypeIndex in ipairs(spec.fillTypes) do
        spec.fillLevelsSent[fillTypeIndex] = streamReadFloat32(streamId)
        spec.capacitiesSent[fillTypeIndex] = streamReadFloat32(streamId)
    end
    spec.palletLimitReached = streamReadBool(streamId)
end
function PlaceableHusbandryPallets:onWriteStream(streamId, _)
    local spec = self.spec_husbandryPallets
    for _, fillTypeIndex in ipairs(spec.fillTypes) do
        streamWriteFloat32(streamId, spec.fillLevelsSent[fillTypeIndex])
        streamWriteFloat32(streamId, spec.capacitiesSent[fillTypeIndex])
    end
    streamWriteBool(streamId, spec.palletLimitReached)
end
function PlaceableHusbandryPallets:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        local spec = self.spec_husbandryPallets
        for _, fillTypeIndex in ipairs(spec.fillTypes) do
            spec.fillLevelsSent[fillTypeIndex] = streamReadFloat32(streamId)
            spec.capacitiesSent[fillTypeIndex] = streamReadFloat32(streamId)
        end
        spec.palletLimitReached = streamReadBool(streamId)
    end
end
function PlaceableHusbandryPallets:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_husbandryPallets
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
            for _, fillTypeIndex in ipairs(spec.fillTypes) do
                streamWriteFloat32(streamId, spec.fillLevelsSent[fillTypeIndex])
                streamWriteFloat32(streamId, spec.capacitiesSent[fillTypeIndex])
            end
            streamWriteBool(streamId, spec.palletLimitReached)
        end
    end
end
function PlaceableHusbandryPallets:loadFromXMLFile(xmlFile, key)
    for _, pendingKey in xmlFile:iterator(key .. ".pendingLiters") do
        local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getValue(pendingKey .. "#fillType"))
        if fillTypeIndex ~= nil then
            self.spec_husbandryPallets.pendingLiters[fillTypeIndex] = xmlFile:getValue(pendingKey .. "#liters") or 0
        end
    end
    self:updatePalletInfo()
end
function PlaceableHusbandryPallets:saveToXMLFile(xmlFile, key, _)
    local index = 0
    for fillTypeIndex, pendingLiters in pairs(self.spec_husbandryPallets.pendingLiters) do
        if pendingLiters > 0 then
            local pendingKey = string.format("%s.pendingLiters(%d)", key, index)
            xmlFile:setValue(pendingKey .. "#fillType", g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex))
            xmlFile:setValue(pendingKey .. "#liters", pendingLiters)
            index = index + 1
        end
    end
end
function PlaceableHusbandryPallets:onHusbandryAnimalsUpdate(clusters)
    local spec = self.spec_husbandryPallets
    for fillTypeIndex, _ in pairs(spec.litersPerHour) do
        spec.litersPerHour[fillTypeIndex] = 0
    end
    spec.activeFillTypes = {}
    for fillTypeIndex, _ in ipairs(clusters) do
        local subType = g_currentMission.animalSystem:getSubTypeByIndex(_.subTypeIndex)
        if subType ~= nil then
            local pallets = subType.output.pallets
            if pallets ~= nil then
                local age = _:getAge()
                local litersPerDay = pallets.curve:get(age) * _:getNumAnimals()
                spec.litersPerHour[pallets.fillType] = spec.litersPerHour[pallets.fillType] + litersPerDay / 24
                table.addElement(spec.activeFillTypes, pallets.fillType)
            end
        end
    end
end
function PlaceableHusbandryPallets:onPalletTriggerCallback(_, otherId, _, onLeave, _)
    if onLeave then
        local object = g_currentMission:getNodeObject(otherId)
        if object ~= nil then
            for fillTypeIndex, pallet in pairs(self.spec_husbandryPallets.currentPallets) do
                if object == pallet then
                    spec.currentPallets[fillTypeIndex] = nil
                end
            end
            spec.pallets[object] = nil
            self:updatePalletInfo()
        end
    end
end
function PlaceableHusbandryPallets:updatePalletInfo()
    if self.isServer then
        local spec = self.spec_husbandryPallets
        if spec.numPalletInfoUpdateRunning == 0 then
            for fillTypeIndex in pairs(spec.capacitiesPending) do
                spec.fillLevelsPending[fillTypeIndex] = 0
                spec.capacitiesPending[fillTypeIndex] = 0
                spec.maxCapacitiesPending[fillTypeIndex] = 0
            end
            for fillTypeIndex, palletSpawner in pairs(spec.fillTypeIndexToPalletSpawner) do
                spec.numPalletInfoUpdateRunning = spec.numPalletInfoUpdateRunning + 1
                palletSpawner:getAllPallets(fillTypeIndex, self.getAllPalletsCallback, self)
            end
        end
    end
end
function PlaceableHusbandryPallets:getAllPalletsCallback(pallets, fillTypeIndex)
    local spec = self.spec_husbandryPallets
    spec.numPalletInfoUpdateRunning = math.max(spec.numPalletInfoUpdateRunning - 1, 0)
    for _, pallet in pairs(pallets) do
        local fillUnitIndex = pallet.spec_pallet.fillUnitIndex
        local palletCapacity = pallet:getFillUnitCapacity(fillUnitIndex)
        spec.capacitiesPending[fillTypeIndex] = spec.capacitiesPending[fillTypeIndex] + palletCapacity
        spec.fillLevelsPending[fillTypeIndex] = spec.fillLevelsPending[fillTypeIndex] + pallet:getFillUnitFillLevel(fillUnitIndex)
        spec.maxCapacitiesPending[fillTypeIndex] = math.max(spec.maxCapacitiesPending[fillTypeIndex], palletCapacity)
    end
    if spec.numPalletInfoUpdateRunning > 0 then
        ::l5::
        return
    end
    for _, pallet in pairs(spec.fillLevels) do
        spec.fillLevels[_] = spec.fillLevelsPending[_]
        local fillUnitIndex = spec.capacitiesPending[_]
        if #pallets < spec.maxNumPallets[_] then
            fillUnitIndex = spec.maxCapacitiesPending[_] * spec.maxNumPallets[_]
        end
        spec.capacities[_] = fillUnitIndex
        if math.abs(spec.fillLevels[_] - spec.fillLevelsSent[_]) > 1 then
            ::l11::
            spec.fillLevelsSent[_] = spec.fillLevels[_]
            spec.capacitiesSent[_] = spec.capacities[_]
            self:raiseDirtyFlags(spec.dirtyFlag)
        elseif math.abs(spec.capacities[_] - spec.capacitiesSent[_]) > 1 then
            goto l11
        end
    end
    goto l5
end
function PlaceableHusbandryPallets:updatePallets()
    if self.isServer then
        local spec = self.spec_husbandryPallets
        if spec.numSpawnsPending == 0 then
            for fillTypeIndex, pendingLiters in pairs(spec.pendingLiters) do
                if pendingLiters > 5 then
                    spec.numSpawnsPending = spec.numSpawnsPending + 1
                    spec.fillTypeIndexToPalletSpawner[fillTypeIndex]:getOrSpawnPallet(self:getOwnerFarmId(), fillTypeIndex, self.getPalletCallback, self)
                end
            end
        end
    end
end
function PlaceableHusbandryPallets:addPendingLiters(fillTypeIndex, liters)
    if not self.isServer then
        return 0
    end
    if liters <= 0 then
        return 0
    end
    local spec = self.spec_husbandryPallets
    if spec.pendingLiters[fillTypeIndex] == nil then
        return 0
    end
    spec.pendingLiters[fillTypeIndex] = spec.pendingLiters[fillTypeIndex] + liters
    self:updatePallets()
    return liters
end
function PlaceableHusbandryPallets:getPalletCallback(pallet, result, fillTypeIndex)
    local spec = self.spec_husbandryPallets
    local pendingLiters = spec.numSpawnsPending - 1
    spec.numSpawnsPending = math.max(pendingLiters, 0)
    spec.currentPallets[fillTypeIndex] = pallet
    if pallet == nil then
        if result == PalletSpawner.RESULT_NO_SPACE then
            self:showSpawnerBlockedWarning(fillTypeIndex)
        elseif result == PalletSpawner.PALLET_LIMITED_REACHED and not spec.palletLimitReached then
            spec.palletLimitReached = true
            self:raiseDirtyFlags(spec.dirtyFlag)
        end
    else
        if spec.palletLimitReached then
            spec.palletLimitReached = false
            self:raiseDirtyFlags(spec.dirtyFlag)
        end
        if result == PalletSpawner.RESULT_SUCCESS then
            pallet:emptyAllFillUnits(true)
        end
        spec.pallets[pallet] = true
        local delta = pallet:addFillUnitFillLevel(self:getOwnerFarmId(), pallet.spec_pallet.fillUnitIndex, spec.pendingLiters[fillTypeIndex], fillTypeIndex, ToolType.UNDEFINED)
        if delta > 0 then
            spec.pendingLiters[fillTypeIndex] = math.max(spec.pendingLiters[fillTypeIndex] - delta, 0)
            if spec.pendingLiters[fillTypeIndex] > 5 then
                self:updatePallets()
            end
        end
    end
    self:updatePalletInfo()
end
function PlaceableHusbandryPallets:showSpawnerBlockedWarning(fillTypeIndex)
    local spec = self.spec_husbandryPallets
    if not spec.showedWarning then
        if self.isServer then
            g_currentMission:broadcastEventToFarm(AnimalHusbandryNoMorePalletSpaceEvent.new(self, fillTypeIndex), self:getOwnerFarmId(), false)
        end
        self:showPalletBlockedWarning(fillTypeIndex)
        spec.showedWarning = true
    end
end
function PlaceableHusbandryPallets:showPalletBlockedWarning(fillTypeIndex)
    if self.isClient and g_currentMission:getFarmId() == self:getOwnerFarmId() then
        local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
        if fillType ~= nil then
            local text = string.format(g_i18n:getText("ingameNotification_palletSpawnerBlocked"), fillType.title, self:getName())
            g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, text)
        end
    end
end
function PlaceableHusbandryPallets:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)
    local spec = self.spec_husbandryPallets
    if spec.palletLimitReached then
        table.insert(infoTable, spec.infoHudTooManyPallets)
    end
end
function PlaceableHusbandryPallets:getConditionInfos(superFunc)
    local infos = superFunc(self)
    local spec = self.spec_husbandryPallets
    for _, fillTypeIndex in ipairs(spec.activeFillTypes) do
        local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
        if fillType ~= nil then
            local info = {}
            local fillLevel = spec.fillLevels[fillTypeIndex]
            local capacity = spec.capacities[fillTypeIndex]
            info.title = fillType.title
            info.value = fillLevel
            local ratio = 0
            if capacity > 0 then
                ratio = fillLevel / capacity
            end
            info.ratio = math.clamp(ratio, 0, 1)
            info.invertedBar = true
            info.customUnitText = spec.fillTypeUnit
            table.insert(infos, info)
        end
    end
    return infos
end
function PlaceableHusbandryPallets:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
    superFunc(self, foodFactor, productionFactor, globalProductionFactor)
    local spec = self.spec_husbandryPallets
    spec.showedWarning = false
    if self.isServer then
        for _, fillTypeIndex in ipairs(spec.fillTypes) do
            local litersPerHour = spec.litersPerHour[fillTypeIndex]
            if litersPerHour > 0 then
                spec.pendingLiters[fillTypeIndex] = spec.pendingLiters[fillTypeIndex] + productionFactor * globalProductionFactor * litersPerHour * g_currentMission.environment.timeAdjustment
                self:updatePallets()
            end
        end
    end
end