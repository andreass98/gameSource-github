PlaceableConstructible = {}
source("dataS/scripts/placeables/specializations/constructible/ConstructibleStateEvent.lua")
source("dataS/scripts/placeables/specializations/constructible/ConstructibleState.lua")
source("dataS/scripts/placeables/specializations/constructible/ConstructibleStateBuilding.lua")
source("dataS/scripts/placeables/specializations/constructible/ConstructibleStateFinalize.lua")
function PlaceableConstructible.prerequisitesPresent(specializations)
    return true
end
function PlaceableConstructible.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "setConstructibleState", PlaceableConstructible.setConstructibleState)
    SpecializationUtil.registerFunction(placeableType, "finalizeConstruction", PlaceableConstructible.finalizeConstruction)
    SpecializationUtil.registerFunction(placeableType, "getConstructibleFillLevel", PlaceableConstructible.getConstructibleFillLevel)
    SpecializationUtil.registerFunction(placeableType, "getConstructibleSupportsFillType", PlaceableConstructible.getConstructibleSupportsFillType)
    SpecializationUtil.registerFunction(placeableType, "removeConstructibleFillLevel", PlaceableConstructible.removeConstructibleFillLevel)
    SpecializationUtil.registerFunction(placeableType, "getConstructibleStateIndexByName", PlaceableConstructible.getConstructibleStateIndexByName)
    SpecializationUtil.registerFunction(placeableType, "setConstructiblePreviewState", PlaceableConstructible.setConstructiblePreviewState)
    SpecializationUtil.registerFunction(placeableType, "getConstructibleStateIndex", PlaceableConstructible.getConstructibleStateIndex)
    SpecializationUtil.registerFunction(placeableType, "resetConstructibleToState", PlaceableConstructible.resetConstructibleToState)
    SpecializationUtil.registerFunction(placeableType, "consoleCommandFinishConstructionState", PlaceableConstructible.consoleCommandFinishConstructionState)
    SpecializationUtil.registerFunction(placeableType, "getNumFinishedConstructibleStates", PlaceableConstructible.getNumFinishedConstructibleStates)
end
function PlaceableConstructible.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableConstructible.collectPickObjects)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableConstructible.updateInfo)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableConstructible.setOwnerFarmId)
end
function PlaceableConstructible.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableConstructible)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableConstructible)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableConstructible)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableConstructible)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableConstructible)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableConstructible)
    SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableConstructible)
    SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableConstructible)
    SpecializationUtil.registerEventListener(placeableType, "onInfoTriggerEnter", PlaceableConstructible)
    SpecializationUtil.registerEventListener(placeableType, "onInfoTriggerLeave", PlaceableConstructible)
end
function PlaceableConstructible.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Constructible")
    schema:register(XMLValueType.STRING, basePath .. ".constructible.stateMachine.states.state(?)#name", "State name")
    schema:register(XMLValueType.STRING, basePath .. ".constructible.stateMachine.states.state(?)#class", "State class")
    schema:register(XMLValueType.BOOL, basePath .. ".constructible.stateMachine.states.state(?)#isStartState", "Marks a state as starting state")
    schema:register(XMLValueType.BOOL, basePath .. ".constructible.stateMachine.states.state(?)#isPreviewState", "State is shown while placing the placeable or used in the icon generator")
    ConstructibleState.registerXMLPaths(schema, basePath .. ".constructible.stateMachine.states.state(?)")
    ConstructibleStateBuilding.registerXMLPaths(schema, basePath .. ".constructible.stateMachine.states.state(?)")
    ConstructibleStateFinalize.registerXMLPaths(schema, basePath .. ".constructible.stateMachine.states.state(?)")
    schema:register(XMLValueType.STRING, basePath .. ".constructible.stateMachine.transitions.transition(?)#from", "State name from")
    schema:register(XMLValueType.STRING, basePath .. ".constructible.stateMachine.transitions.transition(?)#to", "State name to")
    SellingStation.registerXMLPaths(schema, basePath .. ".constructible.sellingStation")
    Storage.registerXMLPaths(schema, basePath .. ".constructible.storage")
    schema:setXMLSpecializationType()
end
function PlaceableConstructible.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. ".state#index", "")
    schema:register(XMLValueType.STRING, basePath .. ".state#name", "")
    ConstructibleStateBuilding.registerSavegameXMLPaths(schema, basePath)
    Storage.registerSavegameXMLPaths(schema, basePath .. ".storage")
end
function PlaceableConstructible:onLoad(_)
    local spec = self.spec_constructible
    spec.unloadingStation = SellingStation.new(self.isServer, self.isClient)
    spec.unloadingStation:load(self.components, self.xmlFile, "placeable.constructible.sellingStation", self.customEnvironment, self.i3dMappings, self.components[1].node)
    spec.unloadingStation.owningPlaceable = self
    function spec.unloadingStation.getStoreGoods(_, farmId, fillTypeIndex)
        return true
    end
    function spec.unloadingStation.getSkipSell(_, farmId, fillTypeIndex)
        -- upvalues: (copy) self
        return self:getOwnerFarmId() ~= AccessHandler.EVERYONE
    end
    spec.unloadingStation:register(true)
    spec.storage = Storage.new(self.isServer, self.isClient)
    spec.storage:load(self.components, self.xmlFile, "placeable.constructible.storage", self.i3dMappings, self.baseDirectory)
    spec.storage:register(true)
    spec.storage:addFillLevelChangedListeners(function()
        -- upvalues: (copy) self
        self:raiseActive()
    end)
    spec.fillTypesAndLevelsAuxiliary = {}
    spec.fillTypeToFillTypeStorageTable = {}
    spec.infoTriggerFillTypesAndLevels = {}
    spec.infoTableEntryStorage = {
        ["title"] = g_i18n:getText("statistic_storage"),
        ["accentuate"] = true
    }
    spec.unloadingStation:addTargetStorage(spec.storage)
    g_currentMission.storageSystem:addUnloadingStation(spec.unloadingStation, self)
    g_currentMission.economyManager:addSellingStation(spec.unloadingStation)
    spec.stateMachine = {}
    spec.stateNameToIndex = {}
    spec.stateTransitions = {}
    spec.stateIndex = -1
    spec.startStateIndex = 1
    spec.previewStateIndex = 1
    spec.statesDirtyMask = 0
    local stateMachineNextIndex = 1
    for _, stateKey in self.xmlFile:iterator("placeable.constructible.stateMachine.states.state") do
        if 255 < stateMachineNextIndex then
            Logging.xmlWarning(self.xmlFile, "Maximum number of states reached (%d)", 255)
            break
        end
        local stateName = string.upper(self.xmlFile:getValue(stateKey .. "#name", ""))
        if spec.stateNameToIndex[stateName] ~= nil then
            Logging.xmlError(self.xmlFile, "State \'%s\' already defined", stateName, stateKey)
            break
        end
        local stateClassName = self.xmlFile:getValue(stateKey .. "#class", "")
        local class = ClassUtil.getClassObject(stateClassName)
        if class == nil then
            Logging.xmlError(self.xmlFile, "State class \'%s\' at \'%s\' not defined", stateClassName, stateKey)
            break
        end
        if not class:isa(ConstructibleState) then
            Logging.xmlError(self.xmlFile, "State class \'%s\' is not a ConstructibleState at \'%s\'", stateClassName, stateKey)
            break
        end
        if #{} < 10 then
            table.insert(dirtyFlags, self:getNextDirtyFlag())
        end
        spec.stateNameToIndex[stateName] = stateMachineNextIndex
        local dirtyFlag = dirtyFlags[(stateMachineNextIndex - 1) % 10 + 1]
        local state = class.new(self, dirtyFlag)
        state:load(self.xmlFile, stateKey)
        spec.stateMachine[stateMachineNextIndex] = state
        spec.statesDirtyMask = bit32.bor(spec.statesDirtyMask, dirtyFlag)
        if self.xmlFile:getValue(stateKey .. "#isStartState") then
            spec.startStateIndex = stateMachineNextIndex
        end
        if self.xmlFile:getValue(stateKey .. "#isPreviewState") then
            spec.previewStateIndex = stateMachineNextIndex
        end
        stateMachineNextIndex = stateMachineNextIndex + 1
    end
    for _, stateKey in self.xmlFile:iterator("placeable.constructible.stateMachine.transitions.transition") do
        local stateName = string.upper(self.xmlFile:getValue(stateKey .. "#from", ""))
        local stateClassName = spec.stateNameToIndex[stateName]
        if stateClassName == nil then
            Logging.xmlError(self.xmlFile, "Invalid state. Transition from name \'%s\' not defined for \'%s\'", stateName, stateKey)
            break
        end
        local class = string.upper(self.xmlFile:getValue(stateKey .. "#to", ""))
        local stateIndex = spec.stateNameToIndex[class]
        if stateIndex == nil then
            Logging.xmlError(self.xmlFile, "Invalid state. Transition to name \'%s\' not defined for \'%s\'", class, stateKey)
            break
        end
        spec.stateTransitions[stateClassName] = stateIndex
    end
    if self.propertyState == PlaceablePropertyState.CONSTRUCTION_PREVIEW then
        self:setConstructiblePreviewState()
    end
end
function PlaceableConstructible:onFinalizePlacement(_)
    local spec = self.spec_constructible
    local farmId = self:getOwnerFarmId()
    if spec.unloadingStation ~= nil then
        spec.unloadingStation:setOwnerFarmId(farmId, true)
    end
    if spec.storage ~= nil then
        spec.storage:setOwnerFarmId(farmId, true)
    end
    if self.isServer then
        if spec.stateIndexPending == nil then
            self:setConstructibleState(spec.startStateIndex)
        else
            local i = 1
            for i = i, spec.stateIndexPending do
                self:setConstructibleState(i)
            end
            if spec.postFinalize ~= nil then
                spec.postFinalize()
            end
            spec.stateIndexPending = nil
            spec.postFinalize = nil
        end
        self:raiseActive()
    end
end
function PlaceableConstructible:onDelete()
    local spec = self.spec_constructible
    removeConsoleCommand("gsConstructibleFinishState")
    g_messageCenter:unsubscribeAll(self)
    if spec.unloadingStation ~= nil then
        g_currentMission.storageSystem:removeUnloadingStation(spec.unloadingStation, self)
        g_currentMission.economyManager:removeSellingStation(spec.unloadingStation)
        spec.unloadingStation:delete()
        spec.unloadingStation = nil
    end
    if spec.storage ~= nil then
        spec.storage:delete()
        spec.storage = nil
    end
    if spec.stateMachine ~= nil then
        for _, state in ipairs(spec.stateMachine) do
            state:delete()
        end
        spec.stateMachine = nil
    end
end
function PlaceableConstructible:collectPickObjects(superFunc, node)
    local spec = self.spec_constructible
    local i = 1
    for i = i, #spec.unloadingStation.unloadTriggers do
        if node == spec.unloadingStation.unloadTriggers[i].exactFillRootNode then
            return
        end
    end
    superFunc(self, node)
end
function PlaceableConstructible:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_constructible
    if spec.stateIndex ~= nil and spec.stateIndex > 0 then
        local state = spec.stateMachine[spec.stateIndex]
        xmlFile:setValue(key .. ".state#name", state.name)
        state:saveToXMLFile(xmlFile, key, usedModNames)
    end
    spec.storage:saveToXMLFile(xmlFile, key .. ".storage")
end
function PlaceableConstructible:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_constructible
    local stateName = xmlFile:getValue(key .. ".state#name")
    spec.stateIndexPending = spec.stateNameToIndex[stateName] or 1
    function spec.postFinalize()
        -- upvalues: (copy) spec, (copy) xmlFile, (copy) key
        spec.stateMachine[spec.stateIndexPending]:loadFromXMLFile(xmlFile, key)
    end
    spec.storage:loadFromXMLFile(xmlFile, key .. ".storage")
end
function PlaceableConstructible:onReadStream(streamId, connection)
    local spec = self.spec_constructible
    local unloadingStationId = NetworkUtil.readNodeObjectId(streamId)
    spec.unloadingStation:readStream(streamId, connection)
    g_client:finishRegisterObject(spec.unloadingStation, unloadingStationId)
    local storageId = NetworkUtil.readNodeObjectId(streamId)
    spec.storage:readStream(streamId, connection)
    g_client:finishRegisterObject(spec.storage, storageId)
    local i = 1
    for i = i, stateIndex do
        self:setConstructibleState(i)
    end
    spec.stateMachine[stateIndex]:onReadStream(streamId, connection)
end
function PlaceableConstructible:onWriteStream(streamId, connection)
    local spec = self.spec_constructible
    NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.unloadingStation))
    spec.unloadingStation:writeStream(streamId, connection)
    g_server:registerObjectInStream(connection, spec.unloadingStation)
    NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.storage))
    spec.storage:writeStream(streamId, connection)
    g_server:registerObjectInStream(connection, spec.storage)
    streamWriteUInt8(streamId, spec.stateIndex)
    spec.stateMachine[spec.stateIndex]:onWriteStream(streamId, connection)
end
function PlaceableConstructible:onReadUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            for _, state in ipairs(self.spec_constructible.stateMachine) do
                if streamReadBool(streamId) then
                    state:onReadUpdateStream(streamId, timestamp, connection)
                end
            end
        end
    end
end
function PlaceableConstructible:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_constructible
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.statesDirtyMask) ~= 0) then
            for _, state in ipairs(spec.stateMachine) do
                if streamWriteBool(streamId, bit32.band(dirtyMask, state.dirtyFlag) ~= 0) then
                    state:onWriteUpdateStream(streamId, connection, dirtyMask)
                end
            end
        end
    end
end
function PlaceableConstructible:onUpdate(dt)
    if self.isServer then
        local state = self.spec_constructible.stateMachine[self.spec_constructible.stateIndex]
        if state ~= nil then
            if state:isDone() then
                self:setConstructibleState(spec.stateTransitions[spec.stateIndex])
                state = spec.stateMachine[spec.stateIndex]
                self:raiseActive()
            elseif state:raiseActive() then
                self:raiseActive()
            end
            if state ~= nil then
                state:update(dt)
            end
        end
    end
end
function PlaceableConstructible:resetConstructibleToState(stateIndex)
    local spec = self.spec_constructible
    local i = spec.stateIndex
    for i = i, stateIndex, -1 do
        spec.stateMachine[i]:reset()
    end
    self:setConstructibleState(stateIndex)
    spec.storage:empty()
    g_currentMission.storageSystem:addUnloadingStation(spec.unloadingStation, self)
    g_currentMission.economyManager:addSellingStation(spec.unloadingStation)
end
function PlaceableConstructible:getConstructibleStateIndex()
    return self.spec_constructible.stateIndex
end
function PlaceableConstructible:getConstructibleStateIndexByName(name)
    return self.spec_constructible.stateNameToIndex[string.upper(name)]
end
function PlaceableConstructible:setConstructiblePreviewState()
    local i = 1
    for i = i, self.spec_constructible.previewStateIndex do
        self:setConstructibleState(i)
    end
end
function PlaceableConstructible:setConstructibleState(newStateIndex)
    local spec = self.spec_constructible
    if self.isServer and self.propertyState ~= PlaceablePropertyState.CONSTRUCTION_PREVIEW then
        g_server:broadcastEvent(ConstructibleStateEvent.new(self, newStateIndex), false)
    end
    if newStateIndex ~= spec.stateIndex then
        spec.stateIndex = newStateIndex
        local oldState = spec.stateMachine[spec.stateIndex]
        local state = spec.stateMachine[newStateIndex]
        if oldState ~= nil then
            oldState:deactivate()
        end
        if state ~= nil then
            state:activate()
            return
        end
        Logging.devWarning("PlaceableConstructible:setConstructibleState(): unable to get state for given state index %s for %q", newStateIndex, self.configFileName)
    end
end
function PlaceableConstructible:finalizeConstruction()
    local spec = self.spec_constructible
    spec.storage:empty()
    g_currentMission.storageSystem:removeUnloadingStation(spec.unloadingStation, self)
    g_currentMission.economyManager:removeSellingStation(spec.unloadingStation)
end
function PlaceableConstructible:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)
    local spec = self.spec_constructible
    local finishedStates, numConstructibleStates = self:getNumFinishedConstructibleStates()
    if finishedStates < numConstructibleStates then
        table.insert(infoTable, {
            ["title"] = g_i18n:getText("ui_construction_state"),
            ["text"] = string.format("(%d / %d)", finishedStates, numConstructibleStates)
        })
    end
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
    local state = #spec.infoTriggerFillTypesAndLevels
    local numEntries = math.min(state, 7)
    if numEntries > 0 then
        local fillType = spec.infoTableEntryStorage
        table.insert(infoTable, fillType)
        local fillType = 1
        for fillType = fillType, numEntries do
            local fillLevel = spec.infoTriggerFillTypesAndLevels[fillType]
            table.insert(infoTable, {
                ["title"] = g_fillTypeManager:getFillTypeTitleByIndex(fillLevel.fillType),
                ["text"] = g_i18n:formatVolume(fillLevel.fillLevel, 0)
            })
        end
    end
    local state = spec.stateMachine[spec.stateIndex]
    if state.updateInfo ~= nil then
        state:updateInfo(infoTable)
    end
end
function PlaceableConstructible:getConstructibleFillLevel(fillType)
    return self.spec_constructible.storage:getFillLevel(fillType)
end
function PlaceableConstructible:getConstructibleSupportsFillType(fillType)
    return self.spec_constructible.storage:getIsFillTypeSupported(fillType)
end
function PlaceableConstructible:removeConstructibleFillLevel(fillType, amount)
    local spec = self.spec_constructible
    local previousFillLevel = spec.storage:getFillLevel(fillType)
    spec.storage:setFillLevel(previousFillLevel - amount, fillType)
    return previousFillLevel - spec.storage:getFillLevel(fillType)
end
function PlaceableConstructible:setOwnerFarmId(superFunc, farmId, noEventSend)
    superFunc(self, farmId, noEventSend)
    local spec = self.spec_constructible
    if spec ~= nil then
        if spec.unloadingStation ~= nil then
            spec.unloadingStation:setOwnerFarmId(farmId, true)
        end
        if spec.storage ~= nil then
            spec.storage:setOwnerFarmId(farmId, true)
        end
    end
end
function PlaceableConstructible:onInfoTriggerEnter(_)
    if self.spec_constructible ~= nil then
        addConsoleCommand("gsConstructibleFinishState", "Finishes current construction state", "consoleCommandFinishConstructionState", self)
    end
end
function PlaceableConstructible:onInfoTriggerLeave(_)
    if self.spec_constructible ~= nil then
        removeConsoleCommand("gsConstructibleFinishState")
    end
end
function PlaceableConstructible:consoleCommandFinishConstructionState()
    local spec = self.spec_constructible
    if spec ~= nil then
        local nextStateIndex = spec.stateTransitions[spec.stateIndex]
        if nextStateIndex ~= nil then
            self:setConstructibleState(nextStateIndex)
            self:raiseActive()
            return
        end
        Logging.info("No next state found")
    end
end
function PlaceableConstructible:getNumFinishedConstructibleStates()
    local spec = self.spec_constructible
    local numConstructibleStates = -2
    local finishedStates = 0
    for i, state in ipairs(spec.stateMachine) do
        if state:getIsConstructibleState() then
            if i ~= spec.isPreviewState then
            end
            if i < spec.stateIndex then
            end
        end
    end
    return finishedStates, numConstructibleStates
end
function PlaceableConstructible.loadSpecValueFillTypes(xmlFile, _, _, resultTable)
    if not xmlFile:hasProperty("placeable.constructible") then
        return resultTable
    end
    local fillTypeNames = resultTable or {}
    for _, stateKey in xmlFile:iterator("placeable.constructible.stateMachine.states.state") do
        for _, inputKey in xmlFile:iterator(stateKey .. ".input") do
            fillTypeNames[xmlFile:getString(inputKey .. "#fillType")] = true
        end
    end
    return fillTypeNames
end