Ferry = {}
Ferry.ERROR_SUCCESS = 0
Ferry.ERROR_FAILED_ALREADY_MOVING = 1
Ferry.ERROR_FAILED_BLOCKED = 2
Ferry.ERROR_FAILED_BARRIERS_BLOCKED = 3
Ferry.ERROR_SEND_NUM_BITS = 2
local Ferry_mt = Class(Ferry, Object)
InitStaticObjectClass(Ferry, "Ferry")
g_xmlManager:addCreateSchemaFunction(function()
    Ferry.xmlSchema = XMLSchema.new("ferry")
end)
g_xmlManager:addInitSchemaFunction(function()
    local schema = Ferry.xmlSchema
    schema:register(XMLValueType.STRING, "ferry.annotation", "Copyright annotation")
    schema:register(XMLValueType.NODE_INDEX, "ferry.vessel#node", "The visuals of the vessel")
    schema:register(XMLValueType.FLOAT, "ferry.vessel#speedKmh", "The vessel speed in kmh")
    schema:register(XMLValueType.NODE_INDEX, "ferry.vessel.trigger#node", "The mount trigger for objects")
    schema:register(XMLValueType.VECTOR_3, "ferry.vessel.shallowWaterObstacle#size", "obstacle size (x y z) centered on vessel node")
    SoundManager.registerSampleXMLPaths(schema, "ferry.vessel.sounds", "start")
    SoundManager.registerSampleXMLPaths(schema, "ferry.vessel.sounds", "stop")
    SoundManager.registerSampleXMLPaths(schema, "ferry.vessel.sounds", "driving")
    EffectManager.registerEffectXMLPaths(schema, "ferry.vessel.exhaustEffects")
    schema:register(XMLValueType.NODE_INDEX, "ferry.spline#node", "The spline node")
    schema:register(XMLValueType.NODE_INDEX, "ferry.spline.crossing(?)#node", "A spline crossing node")
    schema:register(XMLValueType.NODE_INDEX, "ferry.activationTriggers.activationTrigger(?)#node", "An activation trigger")
    schema:register(XMLValueType.NODE_INDEX, "ferry.barrierTriggers.barrierTrigger(?)#node", "A barrier trigger")
    AnimatedObject.registerXMLPaths(schema, "ferry.animatedObjects")
    schema:register(XMLValueType.STRING, "ferry.stateMachine.states.state(?)#name", "State name")
    schema:register(XMLValueType.STRING, "ferry.stateMachine.states.state(?)#class", "State class")
    FerryState.registerXMLPaths(schema, "ferry.stateMachine.states.state(?)")
    FerryStateDriving.registerXMLPaths(schema, "ferry.stateMachine.states.state(?)")
    schema:register(XMLValueType.STRING, "ferry.stateMachine.transitions.transition(?)#from", "State name from")
    schema:register(XMLValueType.STRING, "ferry.stateMachine.transitions.transition(?)#to", "State name to")
    local savegameSchema = OnCreateObjectSystem.xmlSchemaSavegame
    savegameSchema:register(XMLValueType.BOOL, "onCreateLoadedObjects.object(?).ferry#isMounted")
    savegameSchema:register(XMLValueType.FLOAT, "onCreateLoadedObjects.object(?).ferry#time")
    savegameSchema:register(XMLValueType.STRING, "onCreateLoadedObjects.object(?).ferry#state")
    savegameSchema:register(XMLValueType.STRING, "onCreateLoadedObjects.object(?).ferry.vehicle(?)#uniqueId")
    savegameSchema:register(XMLValueType.INT, "onCreateLoadedObjects.object(?).ferry.splitShape(?)#splitShapePart1")
    savegameSchema:register(XMLValueType.INT, "onCreateLoadedObjects.object(?).ferry.splitShape(?)#splitShapePart2")
    savegameSchema:register(XMLValueType.INT, "onCreateLoadedObjects.object(?).ferry.splitShape(?)#splitShapePart3")
    savegameSchema:register(XMLValueType.INT, "onCreateLoadedObjects.object(?).ferry.animatedObject(?)#index")
    AnimatedObject.registerSavegameXMLPaths(savegameSchema, "onCreateLoadedObjects.object(?).ferry.animatedObject(?)")
end)
function Ferry.onCreate(_, node)
    local xmlFilename = getUserAttribute(node, "xmlFilename")
    if xmlFilename == nil then
        Logging.warning("Missing \'xmlFilename\' user attribute for ferry root node \'%s\'", getName(node))
        return
    else
        local ferry = Ferry.new
        local ferry = ferry(g_server ~= nil, g_client ~= nil, node)
        if ferry:load(xmlFilename, g_currentMission.baseDirectory) then
            g_currentMission.onCreateObjectSystem:add(ferry, true)
            ferry:register(true)
        else
            ferry:delete()
        end
    end
end
function Ferry.new(isServer, isClient, node, customMt)
    -- upvalues: (copy) Ferry_mt
    local self = Object.new(isServer, isClient, customMt or Ferry_mt)
    self.rootNode = node
    self.saveId = getName(node)
    self.animatedObjects = {}
    self.isMounted = false
    self.nodesInBarrierTrigger = {}
    self.stateMachineNextIndex = 0
    self.stateIndex = nil
    self.state = {}
    self.stateMachine = {}
    self.stateTransitions = {}
    self.lastSpeed = 0
    self.mountedNodes = {}
    self.nodesInTrigger = {}
    return self
end
function Ferry:load(xmlFilename, baseDirectory)
    local xmlFile = Utils.getFilename(xmlFilename, baseDirectory)
    local xmlFile = XMLFile.load("ferry", xmlFile, Ferry.xmlSchema)
    if xmlFile == nil then
        Logging.warning("Could not open ferry config file \'%s\'", xmlFile)
        return false
    end
    self.veselNode = xmlFile:getValue("ferry.vessel#node", nil, self.rootNode, nil)
    self.triggerNode = xmlFile:getValue("ferry.vessel.trigger#node", nil, self.rootNode, nil)
    if self.triggerNode == nil then
        Logging.xmlWarning(xmlFile, "Missing trigger node")
        xmlFile:delete()
        return false
    end
    if not getHasTrigger(self.triggerNode) then
        Logging.xmlWarning(xmlFile, "Trigger node \'%s\' has no trigger flag set", getName(self.triggerNode))
        xmlFile:delete()
        return false
    end
    self.triggerCallbackId = addTrigger(self.triggerNode, "onObjectCallback", self, false, self.onObjectCallback)
    self.swsObstacleSize = xmlFile:getValue("ferry.vessel.shallowWaterObstacle#size", nil, true)
    self.activationTriggers = {}
    for _, triggerKey in xmlFile:iterator("ferry.activationTriggers.activationTrigger") do
        local activationTrigger = xmlFile:getValue(triggerKey .. "#node", nil, self.rootNode, nil)
        if activationTrigger == nil then
            Logging.xmlWarning(xmlFile, "Invalid activation trigger node in \'%s\'", triggerKey)
        elseif getHasTrigger(activationTrigger) then
            local callbackId = addTrigger(activationTrigger, "onActivationTriggerCallback", self, false, self.onActivationTriggerCallback)
            table.insert(self.activationTriggers, {
                ["node"] = activationTrigger,
                ["callbackId"] = callbackId
            })
        else
            Logging.xmlWarning(xmlFile, "Activationtrigger node \'%s\' has no trigger flag set in \'%s\'", getName(activationTrigger), triggerKey)
        end
    end
    self.barrierTriggers = {}
    for _, triggerKey in xmlFile:iterator("ferry.barrierTriggers.barrierTrigger") do
        local activationTrigger = xmlFile:getValue(triggerKey .. "#node", nil, self.rootNode, nil)
        if activationTrigger == nil then
            Logging.xmlWarning(xmlFile, "Invalid barrier trigger node in \'%s\'", triggerKey)
        elseif getHasTrigger(activationTrigger) then
            local callbackId = addTrigger(activationTrigger, "onBarrierTriggerCallback", self, false, self.onBarrierTriggerCallback)
            table.insert(self.barrierTriggers, {
                ["node"] = activationTrigger,
                ["callbackId"] = callbackId
            })
        else
            Logging.xmlWarning(xmlFile, "Barrier Trigger node \'%s\' has no trigger flag set in \'%s\'", getName(activationTrigger), triggerKey)
        end
    end
    for _, triggerKey in xmlFile:iterator("ferry.animatedObjects.animatedObject") do
        local activationTrigger = AnimatedObject.new(self.isServer, self.isClient)
        activationTrigger:setOwnerFarmId(self:getOwnerFarmId(), false)
        if activationTrigger:load(self.rootNode, xmlFile, triggerKey, xmlFile, nil) then
            table.insert(self.animatedObjects, activationTrigger)
        else
            Logging.xmlError(xmlFile, "Failed to load animated object \'%s\'", triggerKey)
        end
    end
    if self.isClient then
        self.samples = {}
        self.samples.driving = g_soundManager:loadSampleFromXML(xmlFile, "ferry.vessel.sounds", "driving", baseDirectory, self.rootNode, 0, AudioGroup.VEHICLE, nil, self)
        self.samples.start = g_soundManager:loadSampleFromXML(xmlFile, "ferry.vessel.sounds", "start", baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, self)
        self.samples.stop = g_soundManager:loadSampleFromXML(xmlFile, "ferry.vessel.sounds", "stop", baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, self)
        self.exhaustEffects = g_effectManager:loadEffect(xmlFile, "ferry.vessel.exhaustEffects", self.rootNode, self, nil)
    end
    for triggerKey, activationTrigger in xmlFile:iterator("ferry.stateMachine.states.state") do
        if 255 < self.stateMachineNextIndex then
            Logging.xmlError(xmlFile, "Maximum number of states reached (%d)", 255)
            return false
        end
        local callbackId = string.upper(xmlFile:getValue(activationTrigger .. "#name", ""))
        if self.state[callbackId] ~= nil then
            Logging.xmlError(xmlFile, "State \'%s\' at \'%s\' already defined", callbackId, activationTrigger)
            return false
        end
        local stateClassName = xmlFile:getValue(activationTrigger .. "#class", "")
        local class = ClassUtil.getClassObject(stateClassName)
        if class == nil then
            Logging.xmlError(xmlFile, "State class \'%s\' not defined for \'%s\'", stateClassName, activationTrigger)
            return false
        end
        local state = class.new(self)
        state.name = callbackId
        if not state:load(xmlFile, activationTrigger) then
            Logging.xmlError(xmlFile, "State \'%s\' could not be loaded for \'%s\'", callbackId, activationTrigger)
            return false
        end
        local stateIndex = self.stateMachineNextIndex
        self.state[callbackId] = stateIndex
        self.stateMachine[stateIndex] = state
        self.stateMachineNextIndex = self.stateMachineNextIndex + 1
        if self.stateIndex == nil then
            self.stateIndex = stateIndex
        end
    end
    for triggerKey, activationTrigger in xmlFile:iterator("ferry.stateMachine.transitions.transition") do
        local callbackId = string.upper(xmlFile:getValue(activationTrigger .. "#from", ""))
        local stateClassName = self.state[callbackId]
        if stateClassName == nil then
            Logging.xmlError(xmlFile, "Invalid state. Transition from name \'%s\' not defined for \'%s\'", callbackId, activationTrigger)
            return false
        end
        local class = string.upper(xmlFile:getValue(activationTrigger .. "#to", ""))
        local state = self.state[class]
        if state == nil then
            Logging.xmlError(xmlFile, "Invalid state. Transition to name \'%s\' not defined for \'%s\'", class, activationTrigger)
            return false
        end
        self.stateTransitions[stateClassName] = state
    end
    self.splineNode = xmlFile:getValue("ferry.spline#node", nil, self.rootNode, nil)
    if self.splineNode == nil then
        Logging.xmlWarning(xmlFile, "Missing spline node for ferry")
        xmlFile:delete()
        return false
    end
    self.crossingNodes = {}
    for triggerKey, activationTrigger in xmlFile:iterator("ferry.spline.crossing") do
        local callbackId = xmlFile:getValue(activationTrigger .. "#node", nil, self.rootNode, nil)
        if callbackId ~= nil then
            table.insert(self.crossingNodes, callbackId)
            g_currentMission.shipSystem:addCrossingNode(self, callbackId)
        end
    end
    local maxSpeedMps = MathUtil.kmhToMps(xmlFile:getValue("ferry.vessel#speedKmh", 5))
    local splineLength = getSplineLength(self.splineNode)
    self.durationMs = splineLength / maxSpeedMps * 1000
    self.deltaSplineTimePerMs = 1 / self.durationMs
    self.splineLength = splineLength
    self.lastSplineTime = 0
    self.currentSplineTime = 0
    self.currentSplineTimeSent = 0
    self.updateThreshold = 0
    self.isMoving = false
    if self.isServer then
        self.dirtyFlag = self:getNextDirtyFlag()
        self.updateThreshold = 0.05 / splineLength
    else
        self.networkTimeInterpolator = InterpolationTime.new(1.2)
        self.networkSplineTimeInterpolator = InterpolatorSplineTime.new(0, false)
    end
    self.activatable = FerryActivatable.new(self)
    for callbackId, stateClassName in ipairs(self.animatedObjects) do
        stateClassName:register(true)
    end
    g_currentMission.shipSystem:addSpline(self.splineNode, self)
    xmlFile:delete()
    self.nodes = {}
    I3DUtil.iterateRecursively(self.rootNode, function(node, _)
        -- upvalues: (copy) self
        if getRigidBodyType(node) ~= RigidBodyType.NONE then
            self.nodes[node] = true
        end
    end)
    self.mapHotspot = FerryHotspot.new(self)
    g_currentMission:addMapHotspot(self.mapHotspot)
    return true
end
function Ferry:delete()
    g_currentMission.onCreateObjectSystem:remove(self)
    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    g_currentMission.shipSystem:removeSpline(self.splineNode, self)
    if self.crossingNodes ~= nil then
        for _, crossingNode in ipairs(self.crossingNodes) do
            g_currentMission.shipSystem:removeCrossingNode(self, crossingNode)
        end
    end
    if self.activationTriggers ~= nil then
        for _, crossingNode in ipairs(self.activationTriggers) do
            removeTrigger(crossingNode.node, crossingNode.callbackId)
        end
    end
    if self.barrierTriggers ~= nil then
        for _, crossingNode in ipairs(self.barrierTriggers) do
            removeTrigger(crossingNode.node, crossingNode.callbackId)
        end
    end
    if self.triggerCallbackId ~= nil then
        removeTrigger(self.triggerNode, self.triggerCallbackId)
    end
    if self.animatedObjects ~= nil then
        for _, crossingNode in ipairs(self.animatedObjects) do
            crossingNode:delete()
        end
        self.animatedObjects = nil
    end
    if self.samples ~= nil then
        g_soundManager:deleteSamples(self.samples)
    end
    if self.exhaustEffects ~= nil then
        g_effectManager:deleteEffects(self.exhaustEffects)
    end
    if self.mapHotspot ~= nil then
        g_currentMission:removeMapHotspot(self.mapHotspot)
        self.mapHotspot:delete()
    end
    Ferry:superClass().delete(self)
end
function Ferry:readStream(streamId, connection, _)
    if connection:getIsServer() then
        self:setState((streamReadUInt8(streamId)))
        self.currentSplineTime = streamReadFloat32(streamId)
        self.networkSplineTimeInterpolator:setValue(self.currentSplineTime)
        self.networkTimeInterpolator:reset()
        for _, animatedObject in ipairs(self.animatedObjects) do
            local animatedObjectId = NetworkUtil.readNodeObjectId(streamId)
            animatedObject:readStream(streamId, connection)
            g_client:finishRegisterObject(animatedObject, animatedObjectId)
        end
    end
end
function Ferry:writeStream(streamId, connection)
    if not connection:getIsServer() then
        streamWriteUInt8(streamId, self.stateIndex)
        streamWriteFloat32(streamId, self.currentSplineTimeSent)
        for _, animatedObject in ipairs(self.animatedObjects) do
            NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(animatedObject))
            animatedObject:writeStream(streamId, connection)
            g_server:registerObjectInStream(connection, animatedObject)
        end
    end
end
function Ferry:readUpdateStream(streamId, _, connection)
    Ferry:superClass().readUpdateStream(self, streamId, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        local time = streamReadFloat32(streamId)
        self.networkSplineTimeInterpolator:setTargetValue(time)
        self.networkTimeInterpolator:startNewPhaseNetwork()
    end
end
function Ferry:writeUpdateStream(streamId, connection, dirtyMask)
    Ferry:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.dirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, self.currentSplineTimeSent)
        end
    end
end
function Ferry:loadFromXMLFile(xmlFile, key)
    key = key .. ".ferry"
    self.isMounted = xmlFile:getValue(key .. "#isMounted", self.isMounted)
    local time = xmlFile:getValue(key .. "#time")
    if time ~= nil then
        self.currentSplineTime = time
        self.currentSplineTimeSent = time
        removeFromPhysics(self.veselNode)
        self:updatePosition()
        addToPhysics(self.veselNode)
    end
    local stateName = xmlFile:getValue(key .. "#state")
    if stateName ~= nil then
        local stateIndex = self.state[stateName]
        if stateIndex ~= nil then
            self:setState(stateIndex)
        end
    end
    for _, animKey in xmlFile:iterator(key .. ".animatedObject") do
        local index = xmlFile:getValue(animKey .. "#index")
        local animatedObject = self.animatedObjects[index]
        if animatedObject ~= nil then
            animatedObject:loadFromXMLFile(xmlFile, animKey)
        end
    end
    if self.isMounted then
        self.mountingPending = true
    end
    return true
end
function Ferry:saveToXMLFile(xmlFile, key, _)
    key = key .. ".ferry"
    xmlFile:setValue(key .. "#isMounted", self.isMounted)
    xmlFile:setValue(key .. "#time", self:getSplineTime())
    local state = self:getState()
    xmlFile:setValue(key .. "#state", state.name)
    for k, animObject in ipairs(self.animatedObjects) do
        local animKey = string.format("%s.animatedObject(%d)", key, k - 1)
        xmlFile:setValue(animKey .. "#index", k)
        animObject:saveToXMLFile(xmlFile, animKey)
    end
    local splitIndex = 0
    local vehicleIndex = 0
    for animKey, _ in pairs(self.mountedNodes) do
        if entityExists(animKey) then
            local object = g_currentMission:getNodeObject(animKey)
            if object == nil then
                if getHasClassId(animKey, ClassIds.MESH_SPLIT_SHAPE) then
                    local vehicleKey, splitShapePart2, splitShapePart3 = getSaveableSplitShapeId(animKey)
                    if vehicleKey ~= 0 and vehicleKey ~= nil then
                        local treeKey = string.format("%s.splitShape(%d)", key, splitIndex)
                        xmlFile:setValue(treeKey .. "#splitShapePart1", vehicleKey)
                        xmlFile:setValue(treeKey .. "#splitShapePart2", splitShapePart2)
                        xmlFile:setValue(treeKey .. "#splitShapePart3", splitShapePart3)
                        splitIndex = splitIndex + 1
                    end
                end
            elseif object:isa(Vehicle) then
                xmlFile:setValue(string.format("%s.vehicle(%d)", key, vehicleIndex) .. "#uniqueId", object:getUniqueId())
                vehicleIndex = vehicleIndex + 1
            end
        end
    end
end
function Ferry:setOwnerFarmId(ownerFarmId, noEventSend)
    Ferry:superClass().setOwnerFarmId(self, ownerFarmId, noEventSend)
    for _, animatedObject in ipairs(self.animatedObjects) do
        animatedObject:setOwnerFarmId(ownerFarmId, true)
    end
end
function Ferry:update(dt)
    Ferry:superClass().update(self, dt)
    if self.mountingPending then
        self:mountObjects()
        self.mountingPending = false
    end
    local state = self.stateMachine[self.stateIndex]
    if self.isServer then
        if state:isDone() then
            self:setState(self.stateTransitions[self.stateIndex])
            self:raiseActive()
        elseif state:raiseActive() then
            self:raiseActive()
        end
    end
    state:update(dt)
    if not self.isServer and self.isClient then
        self.networkTimeInterpolator:update(dt)
        local nextStateIndex = self.networkTimeInterpolator:getAlpha()
        self.currentSplineTime = self.networkSplineTimeInterpolator:getInterpolatedValue(nextStateIndex)
        if self.networkTimeInterpolator:isInterpolating() then
            self:raiseActive()
        end
    end
    if self.isClient then
        self:updatePosition(dt)
    end
end
function Ferry:getSplineTimeDeltaPerMs()
    return self.deltaSplineTimePerMs
end
function Ferry:getSplineTime()
    return self.currentSplineTime
end
function Ferry:addSplineTimeDelta(delta)
    if self.isServer then
        self.currentSplineTime = math.clamp(self.currentSplineTime + delta, 0, 1)
        local isDirty = true
        if self.currentSplineTime ~= 0 then
            isDirty = true
            if self.currentSplineTime ~= 1 then
                isDirty = math.abs(self.currentSplineTime - self.currentSplineTimeSent) > self.updateThreshold
            end
        end
        if isDirty then
            self.currentSplineTimeSent = self.currentSplineTime
            self:raiseDirtyFlags(self.dirtyFlag)
        end
    end
end
function Ferry:setState(newState)
    if newState ~= self.stateIndex then
        if self.isServer then
            g_server:broadcastEvent(FerryStateEvent.new(self, newState), false)
        end
        self.stateIndex = newState
        self.stateMachine[self.stateIndex]:deactivate()
        self.stateMachine[newState]:activate()
    end
end
function Ferry:getState()
    return self.stateMachine[self.stateIndex]
end
function Ferry:onActivationTriggerCallback(triggerId, otherId, onEnter, onLeave, _)
    if (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
        if onEnter then
            self.activatable:setTrigger(triggerId)
            g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
        else
            g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
        end
        self:raiseActive()
    end
end
function Ferry:onBarrierTriggerCallback(_, otherId, onEnter, onLeave, _)
    if onEnter then
        self.nodesInBarrierTrigger[otherId] = (self.nodesInBarrierTrigger[otherId] or 0) + 1
    elseif onLeave then
        self.nodesInBarrierTrigger[otherId] = self.nodesInBarrierTrigger[otherId] - 1
        if self.nodesInBarrierTrigger[otherId] == 0 then
            self.nodesInBarrierTrigger[otherId] = nil
        end
    end
end
function Ferry:onObjectCallback(_, otherId, onEnter, onLeave, _)
    if (onEnter or onLeave) and self:getIsNodeSupported(otherId) then
        if onEnter then
            self.nodesInTrigger[otherId] = true
            return
        end
        self.nodesInTrigger[otherId] = nil
    end
end
function Ferry:getWorldPosition()
    return getWorldTranslation(self.veselNode)
end
function Ferry:getWorldRotation()
    return getWorldRotation(self.veselNode)
end
function Ferry:getIsNodeSupported(node)
    return self.nodes[node] == nil
end
function Ferry:updatePosition(dt)
    local time = self.currentSplineTime
    if dt ~= nil then
        self.lastSpeed = math.abs(self.lastSplineTime - self.currentSplineTime) * self.splineLength / dt * 1000
    end
    self.lastSplineTime = time
    local delta = Tween.CURVE.EASE_IN_OUT(time)
    local delta, distance, z = getSplinePosition(self.splineNode, delta)
    local dirX, dirY, dirZ = getSplineDirection(self.splineNode, delta)
    local lx, ly, lz = getWorldTranslation(self.veselNode)
    setWorldTranslation(self.veselNode, delta, distance, z)
    setWorldDirection(self.veselNode, dirX, dirY, dirZ, 0, 1, 0)
    if self.mapHotspot ~= nil then
        local _, yRot, _ = getWorldRotation(self.veselNode)
        self.mapHotspot:setWorldPosition(delta, z)
        self.mapHotspot:setWorldRotation(yRot)
    end
    if self.isServer then
        local _ = delta - lx
        local yRot = distance - ly
        local _ = z - lz
        if MathUtil.vector3Length(_, yRot, _) > 0.0001 then
            for node, _ in pairs(self.nodesInTrigger) do
                local object = g_currentMission:getNodeObject(node)
                if object ~= nil and (object.moveCCTExternal ~= nil and object:getTouchingNode() ~= 0) then
                    yRot = math.min(yRot, -0.01)
                    object:moveCCTExternal(_, yRot, _)
                end
            end
        end
    end
end
function Ferry:getIsAllowedToDrive()
    for _, crossingNode in ipairs(self.crossingNodes) do
        if g_currentMission.shipSystem:getIsShipCrossingPoint(crossingNode, self.durationMs) then
            return false
        end
    end
    return true
end
function Ferry:getCanActivateDriving()
    return self:getState():getCanFinishState()
end
function Ferry:start(connection)
    if self.isServer then
        if self:getCanActivateDriving() then
            local found = false
            for nodeId, _ in pairs(self.nodesInBarrierTrigger) do
                if entityExists(nodeId) then
                    found = true
                else
                    self.nodesInBarrierTrigger[nodeId] = nil
                end
            end
            if found then
                if connection == nil then
                    self:onStartFailed(Ferry.ERROR_FAILED_BARRIERS_BLOCKED)
                else
                    connection:sendEvent(FerryStartEvent.newToClient(self, Ferry.ERROR_FAILED_BARRIERS_BLOCKED))
                end
            elseif self:getIsAllowedToDrive() then
                self:raiseActive()
                if connection ~= nil then
                    connection:sendEvent(FerryStartEvent.newToClient(self, Ferry.ERROR_SUCCESS))
                end
                self:getState():finish()
                self:onStarted()
                return
            elseif connection == nil then
                self:onStartFailed(Ferry.ERROR_FAILED_BLOCKED)
            else
                connection:sendEvent(FerryStartEvent.newToClient(self, Ferry.ERROR_FAILED_BLOCKED))
            end
        elseif connection == nil then
            self:onStartFailed(Ferry.ERROR_FAILED_BLOCKED)
        else
            connection:sendEvent(FerryStartEvent.newToClient(self, Ferry.ERROR_FAILED_ALREADY_MOVING))
        end
    else
        g_client:getServerConnection():sendEvent(FerryStartEvent.new(self))
        return
    end
end
function Ferry:onStarted()
    Logging.devInfo("Ferry:onStarted")
end
function Ferry:onStartFailed(errorCode)
    Logging.devInfo("Ferry:onStartFailed. Errorcode %d", errorCode)
    if errorCode == Ferry.ERROR_FAILED_BLOCKED then
        g_currentMission:showBlinkingWarning(g_i18n:getText("warning_ferryBlockedByOtherShips", self.customEnvironment), 2000)
        return
    elseif errorCode == Ferry.ERROR_FAILED_BARRIERS_BLOCKED then
        g_currentMission:showBlinkingWarning(g_i18n:getText("warning_ferryBarriersBlocked", self.customEnvironment), 2000)
    elseif errorCode == Ferry.ERROR_FAILED_ALREADY_MOVING then
        g_currentMission:showBlinkingWarning(g_i18n:getText("warning_ferryAlreadyMoving", self.customEnvironment), 2000)
    end
end
function Ferry:mountObjects()
    Logging.devInfo("Ferry:mountObjects")
    self.isMounted = true
    if not self.isServer then
        ::l2::
        return
    end
    for node, _ in pairs(self.nodesInTrigger) do
        if entityExists(node) then
            local object = g_currentMission:getNodeObject(node)
            if object == nil then
                if not getHasClassId(node, ClassIds.MESH_SPLIT_SHAPE) or getSplitType(node) == 0 then
                    goto l12
                end
                if ({})[node] == nil then
                    alreadyMountedObjects[node] = true
                    goto l12
                end
            elseif alreadyMountedObjects[object] == nil and object.moveCCTExternal == nil then
                alreadyMountedObjects[object] = true
                if object.setDynamicMountType ~= nil then
                    object:setDynamicMountType(MountableObject.MOUNT_TYPE_DYNAMIC)
                end
                ::l12::
                local constr = JointConstructor.new()
                constr:setActors(self.triggerNode, node)
                constr:setJointTransforms(node, node)
                constr:setRotationLimit(0, 0, 0)
                constr:setRotationLimit(1, 0, 0)
                constr:setRotationLimit(2, 0, 0)
                constr:setTranslationLimit(0, true, 0, 0)
                constr:setTranslationLimit(1, true, 0, 0)
                constr:setTranslationLimit(2, true, 0, 0)
                self.mountedNodes[node] = constr:finalize()
            end
        else
            self.nodesInTrigger[node] = nil
        end
    end
    goto l2
end
function Ferry:unmountObjects()
    Logging.devInfo("Ferry:unmountObjects")
    for node, jointIndex in pairs(self.mountedNodes) do
        if entityExists(node) then
            removeJoint(jointIndex)
            local object = g_currentMission:getNodeObject(node)
            if object ~= nil and object.setDynamicMountType ~= nil then
                object:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
            end
        end
    end
    self.mountedNodes = {}
    self.isMounted = false
end
function Ferry:startMotor()
    if self.isClient then
        local samples = self.samples
        if not g_soundManager:getIsSamplePlaying(samples.driving) then
            g_soundManager:stopSample(samples.stop)
            g_soundManager:playSample(samples.start)
            g_soundManager:playSample(samples.driving, 0, samples.start)
        end
        g_effectManager:startEffects(self.exhaustEffects)
    end
    if self.swsObstacle == nil and self.swsObstacleSize ~= nil then
        self.swsObstacle = g_currentMission.shallowWaterSimulation:addObstacle(self.veselNode, self.swsObstacleSize[1], self.swsObstacleSize[2], self.swsObstacleSize[3], function()
            -- upvalues: (copy) self
            local speed = self.lastSpeed
            local dx, _, dz = localDirectionToWorld(self.veselNode, 0, 0, 1)
            local yRot = MathUtil.getYRotationFromDirection(dx, dz)
            return dx * speed + speed * MathUtil.randomFloat(-0.1, 0.1), dz * speed + speed * MathUtil.randomFloat(-0.1, 0.1), yRot
        end)
    end
end
function Ferry:stopMotor()
    if self.isClient then
        local samples = self.samples
        g_soundManager:stopSample(samples.driving)
        g_soundManager:stopSample(samples.start)
        if not g_soundManager:getIsSamplePlaying(samples.stop) then
            g_soundManager:playSample(samples.stop)
        end
        g_effectManager:stopEffects(self.exhaustEffects)
    end
    if self.swsObstacle ~= nil then
        g_currentMission.shallowWaterSimulation:removeObstacle(self.swsObstacle)
        self.swsObstacle = nil
    end
end
function Ferry:addDynamicMountedObject(object) end
function Ferry:removeDynamicMountedObject(object, isDeleting) end