PlaceableDestructible = {}
source("dataS/scripts/placeables/specializations/activatables/DestructibleActivatable.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableDestructibleRepairEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableDestructibleDestructedEvent.lua")
function PlaceableDestructible.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Destructible")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".destructible.trigger#node", "Trigger", nil, false)
    schema:register(XMLValueType.STRING, basePath .. ".destructible.destruct.transition(?)#from", "State name from", nil, false)
    schema:register(XMLValueType.STRING, basePath .. ".destructible.destruct.transition(?)#to", "State name to", nil, false)
    schema:register(XMLValueType.FLOAT, basePath .. ".destructible.repair#bonus", "Bonus for repairing an unowned building", nil, false)
    schema:register(XMLValueType.STRING, basePath .. ".destructible.repair.transition(?)#from", "State name from", nil, false)
    schema:register(XMLValueType.STRING, basePath .. ".destructible.repair.transition(?)#to", "State name to", nil, false)
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".destructible.sounds", "destructed")
    schema:setXMLSpecializationType()
end
function PlaceableDestructible.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. ".repairingFarm#id", "")
end
function PlaceableDestructible.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableConstructible, specializations)
end
function PlaceableDestructible.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "destruct", PlaceableDestructible.destruct)
    SpecializationUtil.registerFunction(placeableType, "destructed", PlaceableDestructible.destructed)
    SpecializationUtil.registerFunction(placeableType, "startRepairDestructible", PlaceableDestructible.startRepairDestructible)
    SpecializationUtil.registerFunction(placeableType, "getCanRepairDestructible", PlaceableDestructible.getCanRepairDestructible)
    SpecializationUtil.registerFunction(placeableType, "onDestructibleTriggerCallback", PlaceableDestructible.onDestructibleTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "getCanBeDestructedByTwister", PlaceableDestructible.getCanBeDestructedByTwister)
    SpecializationUtil.registerFunction(placeableType, "startedRepairDestructible", PlaceableDestructible.startedRepairDestructible)
end
function PlaceableDestructible.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "finalizeConstruction", PlaceableDestructible.finalizeConstruction)
end
function PlaceableDestructible.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableDestructible)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableDestructible)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableDestructible)
end
function PlaceableDestructible:onLoad(_)
    local spec = self.spec_destructible
    spec.destructTransitions = {}
    for _, transitionKey in self.xmlFile:iterator("placeable.destructible.destruct.transition") do
        local stateFromName = self.xmlFile:getValue(transitionKey .. "#from", "")
        local stateFromIndex = self:getConstructibleStateIndexByName(stateFromName)
        if stateFromIndex == nil then
            Logging.xmlError(self.xmlFile, "Invalid state. Transition from name \'%s\' not defined for \'%s\'", stateFromName, transitionKey)
            break
        end
        local stateToName = self.xmlFile:getValue(transitionKey .. "#to", "")
        local stateToIndex = self:getConstructibleStateIndexByName(stateToName)
        if stateToIndex == nil then
            Logging.xmlError(self.xmlFile, "Invalid state. Transition to name \'%s\' not defined for \'%s\'", stateToName, transitionKey)
            break
        end
        spec.destructTransitions[stateFromIndex] = stateToIndex
    end
    spec.repairTransitions = {}
    for _, transitionKey in self.xmlFile:iterator("placeable.destructible.repair.transition") do
        local stateFromName = self.xmlFile:getValue(transitionKey .. "#from", "")
        local stateFromIndex = self:getConstructibleStateIndexByName(stateFromName)
        if stateFromIndex == nil then
            Logging.xmlError(self.xmlFile, "Invalid state. Transition from name \'%s\' not defined for \'%s\'", stateFromName, transitionKey)
            break
        end
        local stateToName = self.xmlFile:getValue(transitionKey .. "#to", "")
        local stateToIndex = self:getConstructibleStateIndexByName(stateToName)
        if stateToIndex == nil then
            Logging.xmlError(self.xmlFile, "Invalid state. Transition to name \'%s\' not defined for \'%s\'", stateToName, transitionKey)
            break
        end
        spec.repairTransitions[stateFromIndex] = stateToIndex
    end
    spec.repairBonus = self.xmlFile:getValue("placeable.destructible.repair#bonus", nil)
    spec.triggerNode = self.xmlFile:getValue("placeable.destructible.trigger#node", nil, self.components, self.i3dMappings)
    if spec.triggerNode ~= nil and not CollisionFlag.getHasMaskFlagSet(spec.triggerNode, CollisionFlag.PLAYER) then
        Logging.xmlWarning(self.xmlFile, "Trigger collision mask is missing bit \'TRIGGER_PLAYER\' (%d)", CollisionFlag.getBit(CollisionFlag.PLAYER))
    end
    if self.isClient then
        spec.samples = {}
        spec.samples.destructed = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.destructible.sounds", "destructed", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
    end
    spec.activatable = DestructibleActivatable.new(self)
end
function PlaceableDestructible:onDelete()
    local spec = self.spec_destructible
    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode)
        spec.triggerNode = nil
    end
    g_soundManager:deleteSamples(spec.samples)
end
function PlaceableDestructible:onFinalizePlacement()
    local spec = self.spec_destructible
    if spec.triggerNode ~= nil then
        addTrigger(spec.triggerNode, "onDestructibleTriggerCallback", self)
    end
end
function PlaceableDestructible:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_destructible
    if spec.repairingFarmId ~= nil then
        xmlFile:setValue(key .. ".repairingFarm#id", spec.repairingFarmId)
    end
end
function PlaceableDestructible:loadFromXMLFile(xmlFile, key)
    local farmId = xmlFile:getValue(key .. ".repairingFarm#id")
    if farmId ~= nil then
        if g_farmManager:getFarmById(farmId) ~= nil then
            self.spec_destructible.repairingFarmId = farmId
            return
        end
        Logging.warning(xmlFile, "Repairing farm (Id \'%s\') does not exist anymore. Ignoring it in \'%s\'", farmId, key)
    end
end
function PlaceableDestructible:getCanBeDestructedByTwister()
    local stateIndex = self:getConstructibleStateIndex()
    return self.spec_destructible.destructTransitions[stateIndex] ~= nil
end
function PlaceableDestructible:destructed()
    local spec = self.spec_destructible
    if spec.samples ~= nil then
        if g_soundManager:getIsSamplePlaying(spec.samples.destructed) then
            g_soundManager:stopSample(spec.samples.destructed)
        end
        g_soundManager:playSample(spec.samples.destructed, 1)
    end
end
function PlaceableDestructible:destruct()
    assert(self.isServer, "PlaceableDestructible.destruct is a server-only function")
    local newStateIndex = self.spec_destructible.destructTransitions[self:getConstructibleStateIndex()]
    if newStateIndex == nil then
        return false
    end
    self:setConstructibleState(newStateIndex)
    g_server:broadcastEvent(PlaceableDestructibleDestructedEvent.new(self), true)
    return true
end
function PlaceableDestructible.startedRepairDestructible(_, wasSuccessful)
    if wasSuccessful then
        InfoDialog.show(g_i18n:getText("action_destructibleStartRepairing_successful"))
    else
        InfoDialog.show(g_i18n:getText("action_destructibleStartRepairing_failed"))
    end
end
function PlaceableDestructible:startRepairDestructible(farmId)
    local ownerFarmId = self:getOwnerFarmId()
    local owned = false
    if ownerFarmId ~= AccessHandler.EVERYONE then
        if ownerFarmId ~= farmId then
            return false
        end
        owned = true
    end
    local spec = self.spec_destructible
    local stateIndex = self:getConstructibleStateIndex()
    local newStateIndex = spec.repairTransitions[stateIndex]
    if newStateIndex == nil then
        return false
    end
    self:resetConstructibleToState(newStateIndex)
    if self.isServer and not owned then
        spec.repairingFarmId = farmId
    end
    return true
end
function PlaceableDestructible:getCanRepairDestructible(farmId)
    local stateIndex = self:getConstructibleStateIndex()
    if self.spec_destructible.repairTransitions[stateIndex] == nil then
        return false
    end
    local ownerFarmId = self:getOwnerFarmId()
    if ownerFarmId == AccessHandler.EVERYONE then
        return true
    end
    return ownerFarmId == farmId
end
function PlaceableDestructible:finalizeConstruction(_)
    local spec = self.spec_destructible
    if self.isServer and (spec.repairingFarmId ~= nil and spec.repairBonus ~= nil) then
        g_currentMission:addMoney(spec.repairBonus, spec.repairingFarmId, MoneyType.MISSIONS, false, true)
    end
    spec.repairingFarmId = nil
end
function PlaceableDestructible:onDestructibleTriggerCallback(_, otherActorId, onEnter, onLeave, _)
    if (onEnter or onLeave) and (g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode) then
        local spec = self.spec_destructible
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
            return
        end
        g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    end
end