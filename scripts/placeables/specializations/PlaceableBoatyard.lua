PlaceableBoatyard = {}
source("dataS/scripts/placeables/specializations/boatyard/BoatyardActivatable.lua")
source("dataS/scripts/placeables/specializations/boatyard/BoatyardState.lua")
source("dataS/scripts/placeables/specializations/boatyard/BoatyardStateBuilding.lua")
source("dataS/scripts/placeables/specializations/boatyard/BoatyardStateEvent.lua")
source("dataS/scripts/placeables/specializations/boatyard/BoatyardStateSetup.lua")
source("dataS/scripts/placeables/specializations/boatyard/BoatyardStateLaunching.lua")
source("dataS/scripts/placeables/specializations/boatyard/BoatyardStateMoving.lua")
source("dataS/scripts/placeables/specializations/boatyard/BoatyardStateRelease.lua")
function PlaceableBoatyard.prerequisitesPresent(specializations)
    return true
end
function PlaceableBoatyard.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onBoatI3DFileLoaded", PlaceableBoatyard.onBoatI3DFileLoaded)
    SpecializationUtil.registerFunction(placeableType, "setMeshProgress", PlaceableBoatyard.setMeshProgress)
    SpecializationUtil.registerFunction(placeableType, "setState", PlaceableBoatyard.setState)
    SpecializationUtil.registerFunction(placeableType, "setSplineTime", PlaceableBoatyard.setSplineTime)
    SpecializationUtil.registerFunction(placeableType, "addSplineDistanceDelta", PlaceableBoatyard.addSplineDistanceDelta)
    SpecializationUtil.registerFunction(placeableType, "getSplineTime", PlaceableBoatyard.getSplineTime)
    SpecializationUtil.registerFunction(placeableType, "releaseBoat", PlaceableBoatyard.releaseBoat)
    SpecializationUtil.registerFunction(placeableType, "createBoat", PlaceableBoatyard.createBoat)
    SpecializationUtil.registerFunction(placeableType, "setWindValues", PlaceableBoatyard.setWindValues)
    SpecializationUtil.registerFunction(placeableType, "getFillLevel", PlaceableBoatyard.getFillLevel)
    SpecializationUtil.registerFunction(placeableType, "removeFillLevel", PlaceableBoatyard.removeFillLevel)
    SpecializationUtil.registerFunction(placeableType, "playerTriggerCallback", PlaceableBoatyard.playerTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "buyRequest", PlaceableBoatyard.buyRequest)
end
function PlaceableBoatyard.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableBoatyard.collectPickObjects)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableBoatyard.updateInfo)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableBoatyard.setOwnerFarmId)
end
function PlaceableBoatyard.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableBoatyard)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableBoatyard)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableBoatyard)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableBoatyard)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableBoatyard)
    SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableBoatyard)
    SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableBoatyard)
end
function PlaceableBoatyard.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Boatyard")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".boatyard#spline", "")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".boatyard#linkNode", "")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".boatyard#playerTrigger", "")
    schema:register(XMLValueType.STRING, basePath .. ".boatyard.boat#filename", "")
    schema:register(XMLValueType.INT, basePath .. ".boatyard.boat#reward", "")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".boatyard.boat.progressiveVisibilityMesh.mesh(?)#node", "")
    schema:register(XMLValueType.STRING, basePath .. ".boatyard.boat.progressiveVisibilityMesh.mesh(?)#id", "")
    schema:register(XMLValueType.INT, basePath .. ".boatyard.boat.progressiveVisibilityMesh.mesh(?)#indexMin", "")
    schema:register(XMLValueType.INT, basePath .. ".boatyard.boat.progressiveVisibilityMesh.mesh(?)#indexMax", "")
    schema:register(XMLValueType.STRING, basePath .. ".boatyard.stateMachine.states.state(?)#name", "State name")
    schema:register(XMLValueType.STRING, basePath .. ".boatyard.stateMachine.states.state(?)#class", "State class")
    BoatyardState.registerXMLPaths(schema, basePath .. ".boatyard.stateMachine.states.state(?)")
    BoatyardStateMoving.registerXMLPaths(schema, basePath .. ".boatyard.stateMachine.states.state(?)")
    BoatyardStateBuilding.registerXMLPaths(schema, basePath .. ".boatyard.stateMachine.states.state(?)")
    BoatyardStateLaunching.registerXMLPaths(schema, basePath .. ".boatyard.stateMachine.states.state(?)")
    schema:register(XMLValueType.STRING, basePath .. ".boatyard.stateMachine.transitions.transition(?)#from", "State name from")
    schema:register(XMLValueType.STRING, basePath .. ".boatyard.stateMachine.transitions.transition(?)#to", "State name to")
    schema:register(XMLValueType.FLOAT, basePath .. ".boatyard.sailingSplines#bobbingFreq", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".boatyard.sailingSplines#bobbingAmount", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".boatyard.sailingSplines#swayingFreq", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".boatyard.sailingSplines#swayingAmount", "")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".boatyard.sailingSplines.spline(?)#node", "")
    SellingStation.registerXMLPaths(schema, basePath .. ".boatyard.sellingStation")
    Storage.registerXMLPaths(schema, basePath .. ".boatyard.storage")
    schema:setXMLSpecializationType()
end
function PlaceableBoatyard.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. ".state#index", "")
    schema:register(XMLValueType.FLOAT, basePath .. "#splineTime", "")
    BoatyardStateBuilding.registerSavegameXMLPaths(schema, basePath)
    Storage.registerSavegameXMLPaths(schema, basePath .. ".storage")
end
function PlaceableBoatyard:onLoad(_)
    local spec = self.spec_boatyard
    spec.spline = self.xmlFile:getValue("placeable.boatyard#spline", nil, self.components, self.i3dMappings)
    spec.splineLength = getSplineLength(spec.spline)
    spec.splineTime = 0
    spec.splineTimeInterpolator = InterpolationTime.new(1.2)
    spec.splineInterpolator = InterpolatorValue.new(0)
    spec.splineTimeDirtyFlag = self:getNextDirtyFlag()
    spec.splineTimeChanged = false
    spec.boatLinkNode = self.xmlFile:getValue("placeable.boatyard#linkNode", nil, self.components, self.i3dMappings)
    link(getRootNode(), spec.boatLinkNode)
    local boatI3DFilename = self.xmlFile:getValue("placeable.boatyard.boat#filename")
    local arguments = Utils.getFilename(boatI3DFilename, self.baseDirectory)
    spec.boatLaunchReward = self.xmlFile:getValue("placeable.boatyard.boat#reward", 100000)
    spec.idToMesh = {}
    spec.meshes = {}
    local arguments = {
        ["loadingTask"] = self:createLoadingTask(spec)
    }
    spec.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(arguments, true, false, self.onBoatI3DFileLoaded, self, arguments)
    spec.unloadingStation = SellingStation.new(self.isServer, self.isClient)
    spec.unloadingStation:load(self.components, self.xmlFile, "placeable.boatyard.sellingStation", self.customEnvironment, self.i3dMappings, self.components[1].node)
    spec.unloadingStation.owningPlaceable = self
    function spec.unloadingStation.getStoreGoods(_, farmId, fillTypeIndex)
        return true
    end
    function spec.unloadingStation.getSkipSell(_, farmId, fillTypeIndex)
        -- upvalues: (copy) self
        return self:getOwnerFarmId() ~= AccessHandler.EVERYONE
    end
    function spec.unloadingStation.getIsFillAllowedFromFarm(_, farmId)
        return true
    end
    spec.unloadingStation:register(true)
    spec.storage = Storage.new(self.isServer, self.isClient)
    spec.storage:load(self.components, self.xmlFile, "placeable.boatyard.storage", self.i3dMappings, self.baseDirectory)
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
    spec.playerTrigger = self.xmlFile:getValue("placeable.boatyard#playerTrigger", nil, self.components, self.i3dMappings)
    if spec.playerTrigger ~= nil then
        addTrigger(spec.playerTrigger, "playerTriggerCallback", self)
    end
    spec.activatable = BoatyardActivatable.new(self)
    spec.stateMachine = {}
    spec.stateNameToIndex = {}
    spec.stateTransitions = {}
    spec.stateIndex = -1
    spec.stateMachineNextIndex = 0
    spec.statesDirtyMask = 0
    for _, stateKey in self.xmlFile:iterator("placeable.boatyard.stateMachine.states.state") do
        if 255 < spec.stateMachineNextIndex then
            Logging.xmlWarning(self.xmlFile, "Maximum number of states reached (%d)", 255)
            break
        end
        local stateName = self.xmlFile:getValue(stateKey .. "#name", ""):upper()
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
        local stateIndex = spec.stateMachineNextIndex
        spec.stateNameToIndex[stateName] = stateIndex
        local state = class.new(self)
        state:load(self.xmlFile, stateKey)
        spec.stateMachine[stateIndex] = state
        spec.statesDirtyMask = spec.statesDirtyMask + state.dirtyFlag
        spec.stateMachineNextIndex = spec.stateMachineNextIndex + 1
    end
    for _, stateKey in self.xmlFile:iterator("placeable.boatyard.stateMachine.transitions.transition") do
        local stateName = self.xmlFile:getValue(stateKey .. "#from", ""):upper()
        local stateClassName = spec.stateNameToIndex[stateName]
        if stateClassName == nil then
            Logging.xmlError(self.xmlFile, "Invalid state. Transition from name \'%s\' not defined for \'%s\'", stateName, stateKey)
            break
        end
        local class = self.xmlFile:getValue(stateKey .. "#to", ""):upper()
        local stateIndex = spec.stateNameToIndex[class]
        if stateIndex == nil then
            Logging.xmlError(self.xmlFile, "Invalid state. Transition to name \'%s\' not defined for \'%s\'", class, stateKey)
            break
        end
        spec.stateTransitions[stateClassName] = stateIndex
    end
    spec.sailingSplines = {}
    spec.boatBobbingFreq = self.xmlFile:getValue("placeable.boatyard.sailingSplines#bobbingFreq", 1) / 1000 / 3.141592653589793
    spec.boatBobbingAmount = self.xmlFile:getValue("placeable.boatyard.sailingSplines#bobbingAmount", 0.05)
    spec.boatSwayingFreq = self.xmlFile:getValue("placeable.boatyard.sailingSplines#swayingFreq", 0.8) / 1000 / 3.141592653589793
    spec.boatSwayingAmount = self.xmlFile:getValue("placeable.boatyard.sailingSplines#swayingAmount", 0.025)
    for _, stateKey in self.xmlFile:iterator("placeable.boatyard.sailingSplines.spline") do
        local stateName = self.xmlFile:getValue(stateKey .. "#node", nil, self.components, self.i3dMappings)
        local stateClassName = getSplineLength(stateName)
        table.insert(spec.sailingSplines, {
            ["node"] = stateName,
            ["length"] = stateClassName
        })
    end
    spec.nextSailingSplineIndex = math.random(1, #spec.sailingSplines)
    spec.boatsSailingLinkNode = createTransformGroup("sailingBoatsLinkNode")
    link(getRootNode(), spec.boatsSailingLinkNode)
    spec.boatsSailing = {}
    spec.sailingAcc = 0.2
    spec.windSpeed = 1
    g_currentMission.environment.weather.windUpdater:addWindChangedListener(self)
end
function PlaceableBoatyard:onBoatI3DFileLoaded(i3dFileRoot, _, args)
    local spec = self.spec_boatyard
    if i3dFileRoot ~= 0 then
        spec.boatRoot = i3dFileRoot
        local components = {}
        I3DUtil.loadI3DComponents(i3dFileRoot, components)
        self.xmlFile:iterate("placeable.boatyard.boat.progressiveVisibilityMesh.mesh", function(_, nodeKey)
            -- upvalues: (copy) self, (copy) components, (copy) spec
            local node = self.xmlFile:getValue(nodeKey .. "#node", nil, components)
            if getHasClassId(node, ClassIds.SHAPE) then
                if getHasShaderParameter(node, "hideByIndex") then
                    local id = self.xmlFile:getValue(nodeKey .. "#id")
                    local indexMin = self.xmlFile:getValue(nodeKey .. "#indexMin", 0)
                    local indexMax = self.xmlFile:getValue(nodeKey .. "#indexMax")
                    if spec.idToMesh[id] == nil then
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
                    else
                        Logging.xmlError(self.xmlFile, "id \'%s\' at \'%s\' already in use", id, nodeKey)
                    end
                else
                    Logging.xmlError(self.xmlFile, "mesh \'%s\' at \'%s\' does not have required shader parameter \'hideByIndex\'", getName(node), nodeKey)
                    return
                end
            else
                Logging.xmlError(self.xmlFile, "node \'%s\' at \'%s\' is not a shape", getName(node), nodeKey)
                return
            end
        end)
    end
    self:finishLoadingTask(args.loadingTask)
    self:raiseActive()
end
function PlaceableBoatyard:onDelete()
    local spec = self.spec_boatyard
    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    if spec.unloadingStation ~= nil then
        g_currentMission.storageSystem:removeUnloadingStation(spec.unloadingStation, self)
        g_currentMission.economyManager:removeSellingStation(spec.unloadingStation)
        spec.unloadingStation:delete()
    end
    if spec.playerTrigger ~= nil then
        removeTrigger(spec.playerTrigger)
        spec.playerTrigger = nil
    end
    for _, state in ipairs(spec.stateMachine) do
        state:delete()
    end
    if spec.boatRoot ~= nil then
        delete(spec.boatRoot)
        spec.boatRoot = nil
    end
    if spec.boatLinkNode ~= nil then
        delete(spec.boatLinkNode)
        spec.boatLinkNode = nil
    end
    if spec.boatsSailingLinkNode ~= nil then
        delete(spec.boatsSailingLinkNode)
        spec.boatsSailingLinkNode = nil
    end
    if spec.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(spec.sharedLoadRequestId)
        spec.sharedLoadRequestId = nil
    end
end
function PlaceableBoatyard:collectPickObjects(superFunc, node)
    local spec = self.spec_boatyard
    local i = 1
    for i = i, #spec.unloadingStation.unloadTriggers do
        if node == spec.unloadingStation.unloadTriggers[i].exactFillRootNode then
            return
        end
    end
    superFunc(self, node)
end
function PlaceableBoatyard:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_boatyard
    if spec.stateIndex > 0 then
        xmlFile:setValue(key .. ".state#index", spec.stateIndex)
        xmlFile:setValue(key .. "#splineTime", spec.splineTime)
        spec.stateMachine[spec.stateIndex]:saveToXMLFile(xmlFile, key, usedModNames)
    end
    spec.storage:saveToXMLFile(xmlFile, key .. ".storage")
end
function PlaceableBoatyard:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_boatyard
    local stateIndex = xmlFile:getValue(key .. ".state#index") or 0
    local splineTimeLoaded = xmlFile:getValue(key .. "#splineTime")
    local i = 0
    for i = i, stateIndex do
        self:setState(i)
    end
    if splineTimeLoaded ~= nil then
        self:setSplineTime(splineTimeLoaded)
    end
    spec.stateMachine[spec.stateIndex]:loadFromXMLFile(xmlFile, key)
    spec.storage:loadFromXMLFile(xmlFile, key .. ".storage")
end
function PlaceableBoatyard:onReadStream(streamId, connection)
    local spec = self.spec_boatyard
    local unloadingStationId = NetworkUtil.readNodeObjectId(streamId)
    spec.unloadingStation:readStream(streamId, connection)
    g_client:finishRegisterObject(spec.unloadingStation, unloadingStationId)
    local storageId = NetworkUtil.readNodeObjectId(streamId)
    spec.storage:readStream(streamId, connection)
    g_client:finishRegisterObject(spec.storage, storageId)
    local i = 0
    for i = i, stateIndex do
        self:setState(i)
    end
    spec.stateMachine[stateIndex]:onReadStream(streamId, connection)
    spec.splineTimeChanged = true
    spec.splineInterpolator:setValue((streamReadFloat32(streamId)))
    spec.splineTimeInterpolator:reset()
    for meshIndex, mesh in ipairs(spec.meshes) do
        local hideByIndexValue = streamReadUIntN(streamId, mesh.numBits)
        local progress = MathUtil.inverseLerp(mesh.indexMax, mesh.indexMin, hideByIndexValue)
        self:setMeshProgress(mesh.id, progress)
    end
    spec.nextSailingSplineIndex = streamReadUInt8(streamId)
end
function PlaceableBoatyard:onWriteStream(streamId, connection)
    local spec = self.spec_boatyard
    NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.unloadingStation))
    spec.unloadingStation:writeStream(streamId, connection)
    g_server:registerObjectInStream(connection, spec.unloadingStation)
    NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.storage))
    spec.storage:writeStream(streamId, connection)
    g_server:registerObjectInStream(connection, spec.storage)
    streamWriteUInt8(streamId, spec.stateIndex)
    spec.stateMachine[spec.stateIndex]:onWriteStream(streamId, connection)
    streamWriteFloat32(streamId, spec.splineTime)
    for meshIndex, mesh in ipairs(spec.meshes) do
        streamWriteUIntN(streamId, mesh.lastValue, mesh.numBits)
    end
    streamWriteUInt8(streamId, spec.nextSailingSplineIndex)
end
function PlaceableBoatyard:onReadUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        local spec = self.spec_boatyard
        for meshIndex, mesh in ipairs(spec.meshes) do
            if streamReadBool(streamId) then
                local hideByIndexValue = streamReadUIntN(streamId, mesh.numBits)
                local progress = MathUtil.inverseLerp(mesh.indexMax, mesh.indexMin, hideByIndexValue)
                self:setMeshProgress(mesh.id, progress)
            end
        end
        spec.splineTimeChanged = streamReadBool(streamId)
        if spec.splineTimeChanged then
            local splineTime = streamReadFloat32(streamId)
            spec.splineTimeInterpolator:startNewPhaseNetwork()
            spec.splineInterpolator:setTargetValue(splineTime)
        end
        if streamReadBool(streamId) then
            for meshIndex, mesh in ipairs(spec.stateMachine) do
                if streamReadBool(streamId) then
                    mesh:onReadUpdateStream(streamId, timestamp, connection)
                end
            end
        end
    end
end
function PlaceableBoatyard:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_boatyard
        for meshIndex, mesh in ipairs(spec.meshes) do
            if streamWriteBool(streamId, bitAND(dirtyMask, mesh.dirtyFlag) ~= 0) then
                streamWriteUIntN(streamId, mesh.lastValue, mesh.numBits)
            end
        end
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.splineTimeDirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, spec.splineTime)
        end
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.statesDirtyMask) ~= 0) then
            for meshIndex, mesh in ipairs(spec.stateMachine) do
                if streamWriteBool(streamId, bitAND(dirtyMask, mesh.dirtyFlag) ~= 0) then
                    mesh:onWriteUpdateStream(streamId, connection, dirtyMask)
                end
            end
        end
    end
end
function PlaceableBoatyard:onUpdate(dt)
    local spec = self.spec_boatyard
    if self.isServer then
        local state = spec.stateMachine[spec.stateIndex]
        if state:isDone() then
            self:setState(spec.stateTransitions[spec.stateIndex])
            state = spec.stateMachine[spec.stateIndex]
            self:raiseActive()
        elseif state:raiseActive() then
            self:raiseActive()
        end
        state:update(dt)
    elseif self.isClient and spec.splineTimeChanged then
        spec.splineTimeInterpolator:update(dt)
        local state = spec.splineTimeInterpolator:getAlpha()
        self:setSplineTime((spec.splineInterpolator:getInterpolatedValue(state)))
        if spec.splineTimeInterpolator:isInterpolating() then
            self:raiseActive()
        end
    end
    for boatSailingNode, boatAttrs in pairs(spec.boatsSailing) do
        local swaying = spec.boatBobbingAmount
        local x = g_time * spec.boatBobbingFreq
        local bobbing = swaying * math.sin(x)
        local alpha = spec.boatSwayingAmount
        local y = g_time * spec.boatSwayingFreq
        local swaying = alpha * math.sin(y)
        if boatAttrs.transitionTime < boatAttrs.transitionDuration then
            local alpha = boatAttrs.transitionTime / boatAttrs.transitionDuration
            local x, y, z = MathUtil.vector3Lerp(boatAttrs.startX, boatAttrs.startY, boatAttrs.startZ, boatAttrs.spline.startX, boatAttrs.spline.startY + bobbing, boatAttrs.spline.startZ, alpha)
            setWorldTranslation(boatSailingNode, x, y, z)
            local dx, dy, dz = MathUtil.vector3Lerp(boatAttrs.startDx, boatAttrs.startDy, boatAttrs.startDz, spline.startDx, spline.startDy, spline.startDz, alpha)
            local ux, uy, uz = MathUtil.vector3Lerp(boatAttrs.startUx, boatAttrs.startUy, boatAttrs.startUz, swaying, 1, 0, alpha)
            setDirection(boatSailingNode, dx, dy, dz, ux, uy, uz)
            boatAttrs.transitionTime = boatAttrs.transitionTime + dt
        else
            local alpha = math.clamp(spec.windSpeed / 15, 0.5, 2)
            boatAttrs.speed = math.clamp(boatAttrs.speed + spec.sailingAcc * dt / 1000, 0, alpha * 3)
            boatAttrs.splineTime = boatAttrs.splineTime + boatAttrs.speed / 1000 * dt / spline.length
            local x, y, z = getSplinePosition(spline.node, boatAttrs.splineTime)
            local dx, dy, dz = getSplineDirection(spline.node, boatAttrs.splineTime)
            setWorldTranslation(boatSailingNode, x, y + bobbing, z)
            setDirection(boatSailingNode, dx, dy, dz, swaying, 1, 0)
            if boatAttrs.splineTime >= 1 then
                spec.boatsSailing[boatSailingNode] = nil
                delete(boatSailingNode)
            end
        end
    end
    if next(spec.boatsSailing) then
        self:raiseActive()
    end
end
function PlaceableBoatyard:setOwnerFarmId(superFunc, farmId)
    superFunc(self, farmId)
    local spec = self.spec_boatyard
    if spec.unloadingStation ~= nil then
        if farmId == AccessHandler.EVERYONE then
            g_currentMission.storageSystem:addUnloadingStation(spec.unloadingStation, self)
            g_currentMission.economyManager:addSellingStation(spec.unloadingStation)
        else
            g_currentMission.economyManager:removeSellingStation(spec.unloadingStation)
            g_currentMission.storageSystem:removeUnloadingStation(spec.unloadingStation, self)
        end
    end
    if spec.playerTrigger ~= nil then
        setVisibility(spec.playerTrigger, farmId == AccessHandler.EVERYONE)
    end
end
function PlaceableBoatyard:setWindValues(_, _, windVelocity, _)
    self.spec_boatyard.windSpeed = windVelocity
end
function PlaceableBoatyard:setMeshProgress(meshId, percentage)
    local spec = self.spec_boatyard
    if spec.boat ~= nil then
        local mesh = spec.idToMesh[meshId]
        if mesh ~= nil then
            local hideByIndexValue = MathUtil.round(MathUtil.lerp(mesh.indexMax, mesh.indexMin, percentage))
            if hideByIndexValue ~= mesh.lastValue then
                local node = getChildAt(spec.boat, mesh.childIndex)
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
function PlaceableBoatyard:setState(newStateIndex)
    local spec = self.spec_boatyard
    if self.isServer then
        g_server:broadcastEvent(BoatyardStateEvent.new(self, newStateIndex), false)
    end
    if newStateIndex ~= spec.stateIndex then
        spec.stateIndex = newStateIndex
        local oldState = spec.stateMachine[spec.stateIndex]
        if oldState ~= nil then
            oldState:deactivate()
        end
        spec.stateMachine[newStateIndex]:activate()
    end
end
function PlaceableBoatyard:createBoat()
    local spec = self.spec_boatyard
    if spec.boat == nil then
        spec.boat = clone(spec.boatRoot, false, false, true)
        link(spec.boatLinkNode, spec.boat)
    end
end
function PlaceableBoatyard:releaseBoat()
    local spec = self.spec_boatyard
    if spec.boat ~= nil then
        local sailingSplineAttrs = spec.sailingSplines[spec.nextSailingSplineIndex]
        local x, y, z = getWorldTranslation(spec.boat)
        local rx, ry, rz = getWorldRotation(spec.boat)
        link(spec.boatsSailingLinkNode, spec.boat)
        setWorldTranslation(spec.boat, x, y, z)
        setWorldRotation(spec.boat, rx, ry, rz)
        local dx, dy, dz = localDirectionToWorld(spec.boat, 0, 0, 1)
        local ux, uy, uz = localDirectionToWorld(spec.boat, 0, 1, 0)
        local splineX, splineY, splineZ, splineTime = getClosestSplinePosition(sailingSplineAttrs.node, x, y, z, 0.2)
        local splineDx, splineDy, splineDz = getSplineDirection(sailingSplineAttrs.node, splineTime)
        sailingSplineAttrs.startX = splineX
        sailingSplineAttrs.startY = splineY
        sailingSplineAttrs.startZ = splineZ
        sailingSplineAttrs.startDx = splineDx
        sailingSplineAttrs.startDy = splineDy
        sailingSplineAttrs.startDz = splineDz
        local distanceDifference = MathUtil.vector3Length(x - splineX, y - splineY, z - splineZ)
        local angleDifference = math.deg((MathUtil.getVectorAngleDifference(dx, dy, dz, splineDx, splineDy, splineDz)))
        spec.boatsSailing[spec.boat] = {
            ["spline"] = sailingSplineAttrs,
            ["splineIndex"] = spec.nextSailingSplineIndex,
            ["splineTime"] = splineTime,
            ["speed"] = 0,
            ["transitionTime"] = 0,
            ["transitionDuration"] = math.max(distanceDifference * 4, angleDifference) * 1000,
            ["startX"] = x,
            ["startY"] = y,
            ["startZ"] = z,
            ["startDx"] = dx,
            ["startDy"] = dy,
            ["startDz"] = dz,
            ["startUx"] = ux,
            ["startUy"] = uy,
            ["startUz"] = uz
        }
        if self.isServer and self:getOwnerFarmId() ~= AccessHandler.EVERYONE then
            g_currentMission:addMoney(spec.boatLaunchReward * EconomyManager.getPriceMultiplier(), self:getOwnerFarmId(), MoneyType.SOLD_PRODUCTS, true, true)
        end
        spec.boat = nil
        spec.nextSailingSplineIndex = 1 + spec.nextSailingSplineIndex % #spec.sailingSplines
        self:raiseActive()
    end
end
function PlaceableBoatyard:setSplineTime(splineTime, resetInterpolation)
    local spec = self.spec_boatyard
    spec.splineTime = math.clamp(splineTime, 0, 1)
    if self.isServer then
        self:raiseDirtyFlags(spec.splineTimeDirtyFlag)
    elseif resetInterpolation and self.isClient then
        spec.splineInterpolator:setValue(splineTime)
    end
    local x, y, z = getSplinePosition(spec.spline, spec.splineTime)
    setWorldTranslation(spec.boatLinkNode, x, y, z)
    local dx, dy, dz = getSplineDirection(spec.spline, spec.splineTime)
    local jitter = 0.002 * math.sin(spec.splineTime * spec.splineLength * 2)
    setDirection(spec.boatLinkNode, -dx, -dy, -dz, jitter, 1, 0)
end
function PlaceableBoatyard:addSplineDistanceDelta(distance)
    local spec = self.spec_boatyard
    local increment = distance / spec.splineLength
    self:setSplineTime(spec.splineTime + increment)
    return spec.splineTime, increment
end
function PlaceableBoatyard:getSplineTime()
    return self.spec_boatyard.splineTime
end
function PlaceableBoatyard:getFillLevel(fillType)
    return self.spec_boatyard.storage:getFillLevel(fillType)
end
function PlaceableBoatyard:removeFillLevel(fillType, amount)
    local spec = self.spec_boatyard
    local previousFillLevel = spec.storage:getFillLevel(fillType)
    spec.storage:setFillLevel(previousFillLevel - amount, fillType)
    return previousFillLevel - spec.storage:getFillLevel(fillType)
end
function PlaceableBoatyard:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)
    local spec = self.spec_boatyard
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
function PlaceableBoatyard:playerTriggerCallback(_, otherId, onEnter, onLeave, _, _)
    if (onEnter or onLeave) and (g_localPlayer ~= nil and g_localPlayer.rootNode == otherId) then
        if onEnter then
            if Platform.isMobile and self.spec_boatyard.activatable:getIsActivatable() then
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
function PlaceableBoatyard:buyRequest()
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
        -- upvalues: (copy) buyingEventCallback, (copy) self
        if yes then
            g_messageCenter:subscribe(BuyExistingPlaceableEvent, buyingEventCallback)
            g_client:getServerConnection():sendEvent(BuyExistingPlaceableEvent.new(self, g_currentMission:getFarmId()))
        end
    end, nil, text)
end