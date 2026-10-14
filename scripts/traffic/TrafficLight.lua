TrafficLight = {}
TrafficLight.AMBER_DURATION_PER_KPH = 62.5
TrafficLight.BLOCKER_TYPES = {
    ["TRAFFIC"] = 1,
    ["PEDESTRIAN"] = 2,
    ["AI"] = 3
}
local TrafficLight_mt = Class(TrafficLight, Object)
InitStaticObjectClass(TrafficLight, "TrafficLight")
function TrafficLight.onCreate(_, node)
    local xmlFilename = getUserAttribute(node, "xmlFilename")
    if xmlFilename == nil then
        Logging.error("Missing \'xmlFilename\' string userattribute for traffic light \'%s\'", I3DUtil.getNodePath(node))
        return
    else
        local trafficLight = Utils.getFilename(xmlFilename, g_currentMission.loadingMapBaseDirectory)
        if fileExists(trafficLight) then
            local trafficLight = TrafficLight.new()
            if trafficLight:loadFromXML(node, trafficLight) then
                g_currentMission.onCreateObjectSystem:add(trafficLight, false)
                trafficLight:register(true)
            else
                trafficLight:delete()
            end
        else
            Logging.error("Defined xmlFilename \'%s\' for traffic light \'%s\' does not exist", trafficLight, I3DUtil.getNodePath(node))
            return
        end
    end
end
function TrafficLight.new(customMt)
    -- upvalues: (copy) TrafficLight_mt
    Object.new(g_server ~= nil, g_client ~= nil, customMt or TrafficLight_mt).xmlFilename = nil
    self.pendingBlockingPositions = {}
    return self
end
function TrafficLight:delete()
    g_messageCenter:unsubscribeAll(self)
    TrafficLight:superClass().delete(self)
end
function TrafficLight:loadFromXML(node, xmlFilename)
    self.xmlFilename = xmlFilename
    local components = {}
    I3DUtil.loadI3DComponents(node, components)
    local xmlFile = XMLFile.load("trafficLight", xmlFilename)
    if xmlFile == nil then
        return false
    end
    local i3dMapping = {}
    I3DUtil.loadI3DMapping(xmlFile, nil, components, i3dMapping)
    self.movements = {}
    for movementIndex, movementKey in xmlFile:iterator("trafficLight.movements.movement") do
        local movementId = xmlFile:getString(movementKey .. "#id")
        if self.movements[movementId] == nil then
            local signals = nil
            for signalIndex, signalKey in xmlFile:iterator(movementKey .. ".signal") do
                local red = xmlFile:getNode(signalKey .. "#red", nil, components, i3dMapping)
                local amber = xmlFile:getNode(signalKey .. "#amber", nil, components, i3dMapping)
                local green = xmlFile:getNode(signalKey .. "#green", nil, components, i3dMapping)
                if red ~= nil or (amber ~= nil or green ~= nil) then
                    signals = signals or {}
                    table.insert(signals, {
                        ["red"] = red,
                        ["amber"] = amber,
                        ["green"] = green
                    })
                end
            end
            self.movements[movementId] = {
                ["signals"] = signals,
                ["blockers"] = nil
            }
            for signalIndex, signalKey in xmlFile:iterator(movementKey .. ".blocker") do
                local red = xmlFile:getNode(signalKey .. "#node", nil, components, i3dMapping)
                if red ~= nil then
                    if getHasClassId(red, ClassIds.SHAPE) then
                        Logging.xmlWarning(xmlFile, "Blocker node \'%s\' is of type shape", signalKey)
                    end
                    local amber = xmlFile:getString(signalKey .. "#type")
                    if amber == nil then
                        Logging.xmlError(xmlFile, "No blocker type given for \'%s\'\nAvailable blocker types: %s", signalKey, table.concatKeys(TrafficLight.BLOCKER_TYPES, ", "))
                    else
                        local green = string.upper(amber)
                        local green = TrafficLight.BLOCKER_TYPES[green]
                        if green == nil then
                            Logging.xmlError(xmlFile, "Invalid blocker type \'%s\' for \'%s\'\nAvailable blocker types: %s", green, signalKey, table.concatKeys(TrafficLight.BLOCKER_TYPES, ", "))
                        else
                            self:addBlockingPosition(green, red, movementId)
                        end
                    end
                end
            end
        else
            Logging.xmlWarning(xmlFile, "Movement id \'%s\' at \'%s\' already in use", movementId, movementKey)
        end
    end
    local phaseIds = {}
    local phases = {}
    local unusedMovements = table.clone(self.movements)
    for signals, phaseKey in xmlFile:iterator("trafficLight.phases.phase") do
        local id = xmlFile:getString(phaseKey .. "#id")
        if phaseIds[id] == nil then
            local phaseMovements = {}
            for amber, green in xmlFile:iterator(phaseKey .. ".movement") do
                local movementId = xmlFile:getString(green .. "#id")
                if self.movements[movementId] == nil then
                    Logging.xmlWarning(xmlFile, "Unknown movement id \'%s\' at \'%s\'", movementId, green)
                elseif phaseMovements[movementId] == nil then
                    local setTo = xmlFile:getString(green .. "#set")
                    local doBlockDefault = true
                    if setTo ~= "RED" then
                        doBlockDefault = true
                        if setTo ~= "RED_AMBER" then
                            doBlockDefault = setTo == "AMBER"
                        end
                    end
                    phaseMovements[movementId] = {
                        ["setTo"] = setTo,
                        ["doBlock"] = xmlFile:getBool(green .. "#block", doBlockDefault)
                    }
                    unusedMovements[movementId] = nil
                else
                    Logging.xmlWarning(xmlFile, "Movement \'%s\' at \'%s\' already defined for phase \'%s\'", movementId, green, id)
                end
            end
            local signalIndex = {
                ["movements"] = phaseMovements,
                ["id"] = id,
                ["index"] = #phases + 1
            }
            phaseIds[id] = signalIndex
            table.insert(phases, signalIndex)
        else
            Logging.xmlWarning(xmlFile, "Phase id \'%s\' at \'%s\' already in use", id, phaseKey)
        end
    end
    if table.size(unusedMovements) > 0 then
        Logging.xmlWarning(xmlFile, "traffic light has unused movements: %s", table.concatKeys(unusedMovements, ", "))
    end
    local movementIndex = {}
    local movementKey = table.clone(phaseIds)
    for id, phaseMovements in xmlFile:iterator("trafficLight.phaseArrangement.phase") do
        local signalIndex = xmlFile:getString(phaseMovements .. "#id")
        local signalKey = phaseIds[signalIndex]
        if signalKey == nil then
            Logging.xmlWarning(xmlFile, "Unknown phase id \'%s\' at \'%s\'", signalIndex, phaseMovements)
        else
            movementKey[signalIndex] = nil
            local green = {
                ["phase"] = signalKey,
                ["duration"] = (xmlFile:getFloat(phaseMovements .. "#duration") or 5) * 1000
            }
            table.insert(movementIndex, green)
        end
    end
    if table.size(movementKey) > 0 then
        Logging.xmlWarning(xmlFile, "traffic light has unused phases: %s", table.concatKeys(movementKey, ", "))
    end
    for id, phaseMovements in pairs(self.movements) do
        self:setMovementState(phaseMovements, "RED")
    end
    for id, phaseMovements in pairs(self.pendingBlockingPositions) do
        if #phaseMovements > 0 then
            if id == TrafficLight.BLOCKER_TYPES.TRAFFIC then
                g_messageCenter:subscribeOneshot(MessageType.TRAFFIC_SYSTEM_LOADED, self.onTrafficSystemLoaded, self)
            elseif id == TrafficLight.BLOCKER_TYPES.PEDESTRIAN then
                g_messageCenter:subscribeOneshot(MessageType.PEDESTRIAN_SYSTEM_LOADED, self.onPedestrianSystemLoaded, self)
            elseif id == TrafficLight.BLOCKER_TYPES.AI then
                g_messageCenter:subscribeOneshot(MessageType.AI_SYSTEM_LOADED, self.onAISystemLoaded, self)
            end
        end
    end
    xmlFile:delete()
    self.node = node
    self.phases = phases
    self.phasesNumBits = MathUtil.getNumRequiredBits(#self.phases)
    self.phaseArrangement = movementIndex
    if self.isServer then
        self.nextPhaseTime = g_time
        self.currentPhaseIndex = 1
        self.currentPhaseArrangementIndex = 1
        self.raiseActiveTimer = Timer.new()
        self.raiseActiveTimer:setFinishCallback(function()
            -- upvalues: (copy) self
            self:raiseActive()
        end)
        self.phaseDirtyFlag = self:getNextDirtyFlag()
    end
    self:setPhase(1)
    if self.isServer then
        self:raiseActive()
    end
    return true
end
function TrafficLight:addBlockingPosition(blockerType, blockerNode, movementId)
    local spline = nil
    local splineTime = nil
    local direction = nil
    local wx, wy, wz = getWorldTranslation(blockerNode)
    local dx, dy, dz = localDirectionToWorld(blockerNode, 0, 0, 1)
    if blockerType == TrafficLight.BLOCKER_TYPES.TRAFFIC then
        if g_currentMission.trafficSystem == nil or g_currentMission.trafficSystem.trafficSystemId == nil then
            self.pendingBlockingPositions[blockerType] = self.pendingBlockingPositions[blockerType] or {}
            table.insert(self.pendingBlockingPositions[blockerType], {
                ["movementId"] = movementId,
                ["blockerNode"] = blockerNode
            })
            return nil
        end
        spline, splineTime = findTrafficSystemBlockingPositionInformation(g_currentMission.trafficSystem.trafficSystemId, wx, wy, wz, dx, dy, dz, 1)
        if spline == 0 then
            Logging.xmlWarning(self.xmlFilename, "Unable to find spline in traffic blocker \'%s\' z-direction  at %.1f %.1f %.1f", I3DUtil.getNodePath(blockerNode), getWorldTranslation(blockerNode))
            return nil
        end
    elseif blockerType == TrafficLight.BLOCKER_TYPES.PEDESTRIAN then
        if g_currentMission.pedestrianSystem == nil or g_currentMission.pedestrianSystem.pedestrianSystemId == nil then
            self.pendingBlockingPositions[blockerType] = self.pendingBlockingPositions[blockerType] or {}
            table.insert(self.pendingBlockingPositions[blockerType], {
                ["movementId"] = movementId,
                ["blockerNode"] = blockerNode
            })
            return nil
        end
        spline, splineTime, direction = findPedestrianSystemBlockingPositionInformation(g_currentMission.pedestrianSystem.pedestrianSystemId, wx, wy, wz, dx, dy, dz, 1)
        if spline == 0 then
            Logging.xmlWarning(self.xmlFilename, "Unable to find spline in pedestrian blocker \'%s\' z-direction at %.1f %.1f %.1f", I3DUtil.getNodePath(blockerNode), getWorldTranslation(blockerNode))
            return nil
        end
    elseif blockerType == TrafficLight.BLOCKER_TYPES.AI then
        if g_currentMission.aiSystem == nil or g_currentMission.aiSystem.navigationMap == nil then
            self.pendingBlockingPositions[blockerType] = self.pendingBlockingPositions[blockerType] or {}
            table.insert(self.pendingBlockingPositions[blockerType], {
                ["movementId"] = movementId,
                ["blockerNode"] = blockerNode
            })
            return nil
        end
        spline, splineTime = findVehicleNavigationMapBlockingPositionInformation(g_currentMission.aiSystem.navigationMap, wx, wy, wz, dx, dy, dz, 1)
        if not entityExists(spline) then
            Logging.xmlWarning(self.xmlFilename, "Unable to find spline in vehicle navigation blocker \'%s\' z-direction  at %.1f %.1f %.1f", I3DUtil.getNodePath(blockerNode), getWorldTranslation(blockerNode))
            return nil
        end
    end
    local blockers = self.movements[movementId].blockers or {}
    table.insert(blockers, {
        ["blockerType"] = blockerType,
        ["spline"] = spline,
        ["splineTime"] = splineTime,
        ["direction"] = direction
    })
    self.movements[movementId].blockers = blockers
    self:setMovementBlocker(self.movements[movementId], true)
end
function TrafficLight:onTrafficSystemLoaded()
    if self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.TRAFFIC] ~= nil then
        for _, blockerData in ipairs(self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.TRAFFIC]) do
            self:addBlockingPosition(TrafficLight.BLOCKER_TYPES.TRAFFIC, blockerData.blockerNode, blockerData.movementId)
        end
        self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.TRAFFIC] = nil
        if next(self.pendingBlockingPositions) == nil then
            self.pendingBlockingPositions = nil
        end
    end
end
function TrafficLight:onPedestrianSystemLoaded()
    if self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.PEDESTRIAN] ~= nil then
        for _, blockerData in ipairs(self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.PEDESTRIAN]) do
            self:addBlockingPosition(TrafficLight.BLOCKER_TYPES.PEDESTRIAN, blockerData.blockerNode, blockerData.movementId)
        end
        self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.PEDESTRIAN] = nil
        if next(self.pendingBlockingPositions) == nil then
            self.pendingBlockingPositions = nil
        end
    end
end
function TrafficLight:onAISystemLoaded()
    if self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.AI] ~= nil then
        for _, blockerData in ipairs(self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.AI]) do
            self:addBlockingPosition(TrafficLight.BLOCKER_TYPES.AI, blockerData.blockerNode, blockerData.movementId)
        end
        self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.AI] = nil
        if next(self.pendingBlockingPositions) == nil then
            self.pendingBlockingPositions = nil
        end
    end
end
function TrafficLight:writeStream(streamId, connection)
    TrafficLight:superClass().writeStream(self, streamId, connection)
    if not connection:getIsServer() then
        streamWriteUIntN(streamId, self.currentPhaseIndex, self.phasesNumBits)
    end
end
function TrafficLight:readStream(streamId, connection, _)
    TrafficLight:superClass().readStream(self, streamId, connection)
    if connection:getIsServer() then
        self:setPhase(streamReadUIntN(streamId, self.phasesNumBits))
    end
end
function TrafficLight:writeUpdateStream(streamId, connection, dirtyMask)
    TrafficLight:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
    if streamWriteBool(streamId, bit32.band(dirtyMask, self.phaseDirtyFlag) ~= 0) then
        streamWriteUIntN(streamId, self.currentPhaseIndex, self.phasesNumBits)
    end
end
function TrafficLight:readUpdateStream(streamId, timestamp, connection)
    TrafficLight:superClass().readUpdateStream(self, streamId, timestamp, connection)
    if streamReadBool(streamId) then
        self:setPhase(streamReadUIntN(streamId, self.phasesNumBits))
    end
end
function TrafficLight:update(_)
    if self.isServer then
        if g_time >= self.nextPhaseTime then
            self.currentPhaseArrangementIndex = self.currentPhaseArrangementIndex + 1
            if self.currentPhaseArrangementIndex > #self.phaseArrangement then
                self.currentPhaseArrangementIndex = 1
            end
            self:setPhase(self.phaseArrangement[self.currentPhaseArrangementIndex].phase.index)
        elseif not self.raiseActiveTimer:getIsRunning() then
            self.raiseActiveTimer:setDuration(5000)
            self.raiseActiveTimer:start()
        end
    else
        return
    end
end
function TrafficLight:setPhase(index)
    local phase = self.phases[index]
    if phase ~= nil then
        self.currentPhaseIndex = index
        if table.size(phase.movements) == 0 then
            for _, movement in pairs(self.movements) do
                self:setMovementState(movement, "RED")
            end
        else
            for _, movement in pairs(phase.movements) do
                local movement = self.movements[_]
                if movement.signals ~= nil then
                    self:setMovementState(movement, movement.setTo)
                end
                if movement.blockers ~= nil then
                    self:setMovementBlocker(movement, movement.doBlock)
                end
            end
        end
        if self.isServer then
            local duration = self.phaseArrangement[self.currentPhaseArrangementIndex].duration
            self.nextPhaseTime = g_time + duration
            self.raiseActiveTimer:setDuration(duration)
            self.raiseActiveTimer:start()
            self:raiseDirtyFlags(self.phaseDirtyFlag)
        end
    end
end
function TrafficLight.setMovementState(_, movement, state)
    if movement.signals ~= nil then
        for _, signal in ipairs(movement.signals) do
            if signal.red ~= nil then
                setVisibility(signal.red, state == "RED" or state == "RED_AMBER")
            end
            if signal.amber ~= nil then
                setVisibility(signal.amber, state == "AMBER" or state == "RED_AMBER")
            end
            if signal.green ~= nil then
                setVisibility(signal.green, state == "GREEN")
            end
        end
    end
end
function TrafficLight.setMovementBlocker(_, movement, doBlock)
    if movement.blockers ~= nil then
        for _, blocker in ipairs(movement.blockers) do
            if blocker.blockerType == TrafficLight.BLOCKER_TYPES.TRAFFIC then
                setTrafficSystemBlockingPositionState(g_currentMission.trafficSystem.trafficSystemId, blocker.spline, blocker.splineTime, doBlock)
            elseif blocker.blockerType == TrafficLight.BLOCKER_TYPES.PEDESTRIAN then
                setPedestrianSystemBlockingPositionState(g_currentMission.pedestrianSystem.pedestrianSystemId, blocker.spline, blocker.splineTime, blocker.direction, doBlock)
            elseif blocker.blockerType == TrafficLight.BLOCKER_TYPES.AI then
                setVehicleNavigationMapBlockingPositionState(g_currentMission.aiSystem.navigationMap, blocker.spline, blocker.splineTime, doBlock)
            end
        end
    end
end
function TrafficLight:drawDebug()
    if not g_gui:getIsGuiVisible() and DebugUtil.isPositionInCameraRange(self.cx, self.cy, self.cz, 150) then
        local text = string.format("        currentPhase = %s (index: %d) (dur: %.2fs)\n        nextPhaseTime = %d\n        g_time = %d\n        currentArrangement = %d", self.phases[self.currentPhaseIndex].id, self.currentPhaseIndex, self.raiseActiveTimer:getDuration() / 1000, self.nextPhaseTime, g_time, self.currentPhaseArrangementIndex)
        DebugText.renderAtPosition(self.cx, self.cy, self.cz, text, nil, 0.012)
    end
end