source("dataS/scripts/vehicles/specializations/events/AIVehicleIsBlockedEvent.lua")
source("dataS/scripts/vehicles/specializations/events/AIFieldWorkerStateEvent.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategy.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyBaler.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyCombine.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyConveyor.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyStonePicker.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyFieldCourse.lua")
AIFieldWorker = {}
AIFieldWorker.TRAFFIC_COLLISION_BOX_FILENAME = "data/shared/ai/trafficCollision.i3d"
AIFieldWorker.TRAFFIC_COLLISION = 0
AIFieldWorker.registeredDriveStrategies = {}
function AIFieldWorker.registerDriveStrategy(func, class, prio)
    table.insert(AIFieldWorker.registeredDriveStrategies, {
        ["func"] = func,
        ["class"] = class,
        ["prio"] = prio or #AIFieldWorker.registeredDriveStrategies + 1
    })
end
AIFieldWorker.registerDriveStrategy(function()
    return true
end, AIDriveStrategyFieldCourse, 1000)
function AIFieldWorker.deleteCollisionBox()
    if AIFieldWorker.TRAFFIC_COLLISION ~= 0 then
        delete(AIFieldWorker.TRAFFIC_COLLISION)
        AIFieldWorker.TRAFFIC_COLLISION = 0
    end
end
function AIFieldWorker.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AIJobVehicle, specializations) and SpecializationUtil.hasSpecialization(Drivable, specializations)
end
function AIFieldWorker.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AIFieldWorker")
    schema:register(XMLValueType.FLOAT, "vehicle.ai.didNotMoveTimeout#value", "Did not move time out time", 5000)
    schema:register(XMLValueType.BOOL, "vehicle.ai.didNotMoveTimeout#deactivated", "Did not move time out deactivated", false)
    schema:setXMLSpecializationType()
    g_i3DManager:loadI3DFileAsync(AIFieldWorker.TRAFFIC_COLLISION_BOX_FILENAME, true, false, AIFieldWorker.onTrafficCollisionLoaded, nil, nil)
end
function AIFieldWorker.terminateSpecialization()
    AIFieldWorker.deleteCollisionBox()
end
function AIFieldWorker.postInitSpecialization()
    table.sort(AIFieldWorker.registeredDriveStrategies, function(a, b)
        return a.prio < b.prio
    end)
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).aiFieldWorker#isActive", "AI worker is currently active")
    for _, strategyData in ipairs(AIFieldWorker.registeredDriveStrategies) do
        if strategyData.class.registerSavegameXMLPaths ~= nil then
            strategyData.class.registerSavegameXMLPaths(schemaSavegame, "vehicles.vehicle(?).aiFieldWorker")
        end
    end
end
function AIFieldWorker.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerStart")
    SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerActive")
    SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerEnd")
    SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerPrepareForWork")
    SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerStartTurn")
    SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerTurnProgress")
    SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerEndTurn")
    SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerSideOffsetChanged")
    SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerBlock")
    SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerContinue")
end
function AIFieldWorker.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getIsFieldWorkActive", AIFieldWorker.getIsFieldWorkActive)
    SpecializationUtil.registerFunction(vehicleType, "getAICollisionTriggers", AIFieldWorker.getAICollisionTriggers)
    SpecializationUtil.registerFunction(vehicleType, "startFieldWorker", AIFieldWorker.startFieldWorker)
    SpecializationUtil.registerFunction(vehicleType, "stopFieldWorker", AIFieldWorker.stopFieldWorker)
    SpecializationUtil.registerFunction(vehicleType, "getDirectionSnapAngle", AIFieldWorker.getDirectionSnapAngle)
    SpecializationUtil.registerFunction(vehicleType, "getAINeedsTrafficCollisionBox", AIFieldWorker.getAINeedsTrafficCollisionBox)
    SpecializationUtil.registerFunction(vehicleType, "clearAIDebugTexts", AIFieldWorker.clearAIDebugTexts)
    SpecializationUtil.registerFunction(vehicleType, "addAIDebugText", AIFieldWorker.addAIDebugText)
    SpecializationUtil.registerFunction(vehicleType, "clearAIDebugLines", AIFieldWorker.clearAIDebugLines)
    SpecializationUtil.registerFunction(vehicleType, "addAIDebugLine", AIFieldWorker.addAIDebugLine)
    SpecializationUtil.registerFunction(vehicleType, "updateAIFieldWorker", AIFieldWorker.updateAIFieldWorker)
    SpecializationUtil.registerFunction(vehicleType, "updateAIFieldWorkerImplementData", AIFieldWorker.updateAIFieldWorkerImplementData)
    SpecializationUtil.registerFunction(vehicleType, "updateAIFieldWorkerDriveStrategies", AIFieldWorker.updateAIFieldWorkerDriveStrategies)
    SpecializationUtil.registerFunction(vehicleType, "aiFieldWorkerStartTurn", AIFieldWorker.aiFieldWorkerStartTurn)
    SpecializationUtil.registerFunction(vehicleType, "aiFieldWorkerTurnProgress", AIFieldWorker.aiFieldWorkerTurnProgress)
    SpecializationUtil.registerFunction(vehicleType, "aiFieldWorkerEndTurn", AIFieldWorker.aiFieldWorkerEndTurn)
    SpecializationUtil.registerFunction(vehicleType, "aiFieldWorkerSideOffsetChanged", AIFieldWorker.aiFieldWorkerSideOffsetChanged)
    SpecializationUtil.registerFunction(vehicleType, "getCanAIFieldWorkerContinueWork", AIFieldWorker.getCanAIFieldWorkerContinueWork)
    SpecializationUtil.registerFunction(vehicleType, "setAIFieldWorkerIsTurning", AIFieldWorker.setAIFieldWorkerIsTurning)
    SpecializationUtil.registerFunction(vehicleType, "getAIFieldWorkerIsTurning", AIFieldWorker.getAIFieldWorkerIsTurning)
    SpecializationUtil.registerFunction(vehicleType, "setAIFieldWorkerIsCornerCutOutActive", AIFieldWorker.setAIFieldWorkerIsCornerCutOutActive)
    SpecializationUtil.registerFunction(vehicleType, "getAIFieldWorkerIsCornerCutOutActive", AIFieldWorker.getAIFieldWorkerIsCornerCutOutActive)
    SpecializationUtil.registerFunction(vehicleType, "getAIFieldWorkerLastTurnDirection", AIFieldWorker.getAIFieldWorkerLastTurnDirection)
    SpecializationUtil.registerFunction(vehicleType, "getAIFieldWorkerIsBlocked", AIFieldWorker.getAIFieldWorkerIsBlocked)
    SpecializationUtil.registerFunction(vehicleType, "getAttachedAIImplements", AIFieldWorker.getAttachedAIImplements)
    SpecializationUtil.registerFunction(vehicleType, "getCanStartFieldWork", AIFieldWorker.getCanStartFieldWork)
end
function AIFieldWorker.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "aiBlock", AIFieldWorker.aiBlock)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "aiContinue", AIFieldWorker.aiContinue)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getStartableAIJob", AIFieldWorker.getStartableAIJob)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getHasStartableAIJob", AIFieldWorker.getHasStartableAIJob)
end
function AIFieldWorker.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIFieldWorker)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIFieldWorker)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AIFieldWorker)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIFieldWorker)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AIFieldWorker)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AIFieldWorker)
end
function AIFieldWorker:onLoad(savegame)
    local spec = self.spec_aiFieldWorker
    spec.aiImplementList = {}
    spec.aiImplementDataDirtyFlag = true
    spec.aiDriveParams = {
        ["valid"] = false
    }
    spec.aiUpdateLowFrequencyDt = 0
    spec.aiUpdateDt = 0
    spec.driveStrategies = {}
    spec.reconstructionData = {}
    spec.aiTrafficCollision = nil
    spec.aiTrafficCollisionTranslation = { 0, 0, 10 }
    spec.debugTexts = {}
    spec.debugLines = {}
    spec.fieldJob = g_currentMission.aiJobTypeManager:createJob(AIJobType.FIELDWORK)
    spec.didNotMoveTimeout = self.xmlFile:getValue("vehicle.ai.didNotMoveTimeout#value", 5000)
    if self.xmlFile:getValue("vehicle.ai.didNotMoveTimeout#deactivated") then
        spec.didNotMoveTimeout = math.huge
    end
    spec.didNotMoveTimer = spec.didNotMoveTimeout
    spec.isActive = false
    spec.isBlocked = false
    spec.lastTurnDirection = false
    spec.isTurning = false
    spec.isCornerCutOutActive = false
    if savegame ~= nil and (not savegame.resetVehicles and savegame.xmlFile:getValue(savegame.key .. ".aiFieldWorker#isActive")) then
        spec.pendingAIFieldWorkerStart = true
        spec.strategyLoadingData = {}
        for strategyIndex, strategyData in ipairs(AIFieldWorker.registeredDriveStrategies) do
            if strategyData.class.loadFromXML ~= nil then
                spec.strategyLoadingData[strategyIndex] = strategyData.class.loadFromXML(spec.reconstructionData, savegame.xmlFile, savegame.key .. ".aiFieldWorker")
            end
        end
    end
end
function AIFieldWorker:onDelete()
    local spec = self.spec_aiFieldWorker
    if spec.aiTrafficCollision ~= nil and entityExists(spec.aiTrafficCollision) then
        delete(spec.aiTrafficCollision)
        spec.aiTrafficCollision = nil
    end
end
function AIFieldWorker:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_aiFieldWorker
    if spec.isActive ~= nil then
        xmlFile:setValue(key .. "#isActive", spec.isActive)
    end
    if spec.driveStrategies ~= nil and #spec.driveStrategies > 0 then
        spec.reconstructionData = {}
        for i, strategy in ipairs(spec.driveStrategies) do
            if strategy.fillReconstructionData ~= nil then
                strategy:fillReconstructionData(spec.reconstructionData)
            end
        end
    end
    for i, strategy in ipairs(AIFieldWorker.registeredDriveStrategies) do
        if strategy.class.saveToXML ~= nil then
            strategy.class.saveToXML(spec.reconstructionData, xmlFile, key)
        end
    end
end
function AIFieldWorker:onReadStream(streamId, _)
    if streamReadBool(streamId) then
        self:startFieldWorker()
    end
end
function AIFieldWorker:onWriteStream(streamId, _)
    streamWriteBool(streamId, self.spec_aiFieldWorker.isActive)
end
function AIFieldWorker:onUpdate(dt, _, _, _)
    local spec = self.spec_aiFieldWorker
    if self.isServer and spec.pendingAIFieldWorkerStart then
        local job = g_currentMission.aiJobTypeManager:createJob(AIJobType.FIELDWORK)
        job.vehicleParameter:setVehicle(self)
        local wx, _, wz = getWorldTranslation(self.rootNode)
        local dx, _, dz = localDirectionToWorld(self.rootNode, 0, 0, 1)
        job.positionAngleParameter:setPosition(wx, wz)
        job.positionAngleParameter:setAngle(MathUtil.getYRotationFromDirection(dx, dz))
        job:setValues()
        g_client:getServerConnection():sendEvent(AIJobStartRequestEvent.new(job, self:getOwnerFarmId()))
        spec.pendingAIFieldWorkerStart = false
    end
    if spec.checkImplementDirection then
        spec.checkImplementDirection = false
        for wz, dx in pairs(self:getAttachedAIImplements()) do
            if dx.object:getAINeedsRootAlignment() then
                if math.abs((Utils.getYRotationBetweenNodes(self:getAIDirectionNode(), dx.object.components[1].node, self.yRotationOffset, dx.object.yRotationOffset, false))) > 1.5707963267948966 then
                    self:stopCurrentAIJob(AIMessageErrorImplementWrongWay.new())
                    return
                end
            end
        end
    end
    if VehicleDebug.state == VehicleDebug.DEBUG_AI and self.isActiveForInputIgnoreSelectionIgnoreAI then
        if #spec.debugTexts > 0 then
            for wz, dx in pairs(spec.debugTexts) do
                renderText(0.7, 0.87 - 0.02 * wz, 0.02, dx)
            end
        end
        if #spec.debugLines > 0 then
            for wz, dx in pairs(spec.debugLines) do
                drawDebugLine(dx.s[1], dx.s[2], dx.s[3], dx.c[1], dx.c[2], dx.c[3], dx.e[1], dx.e[2], dx.e[3], dx.c[1], dx.c[2], dx.c[3])
            end
        end
    end
    if spec.aiImplementDataDirtyFlag then
        spec.aiImplementDataDirtyFlag = false
        self:updateAIFieldWorkerImplementData()
    end
    if self:getIsFieldWorkActive() and self.isServer then
        if spec.aiTrafficCollision ~= nil and not self:getAIFieldWorkerIsTurning() then
            local job, wx, _ = localToWorld(self.components[1].node, unpack(spec.aiTrafficCollisionTranslation))
            setTranslation(spec.aiTrafficCollision, job, wx, _)
            setRotation(spec.aiTrafficCollision, localRotationToWorld(self.components[1].node, 0, 0, 0))
        end
        for wz, dx in ipairs(spec.driveStrategies) do
            dx:update(dt)
        end
        self:updateAIFieldWorker(dt)
    end
end
function AIFieldWorker:updateAIFieldWorker(dt)
    self:clearAIDebugTexts()
    self:clearAIDebugLines()
    if self:getIsFieldWorkActive() then
        if #self.spec_aiFieldWorker.driveStrategies > 0 then
            local vX, vY, vZ = getWorldTranslation(self:getAISteeringNode())
            local tX = nil
            local tZ = nil
            local moveForwards = nil
            local maxSpeed = nil
            local distanceToStop = nil
            for _, driveStrategy in ipairs(spec.driveStrategies) do
                local maxSpeedStra
                tX, tZ, moveForwards, maxSpeedStra, distanceToStop = driveStrategy:getDriveData(dt, vX, vY, vZ)
                maxSpeed = math.min(maxSpeedStra or math.huge, maxSpeed or math.huge)
                if tX ~= nil or not self:getIsFieldWorkActive() then
                    break
                end
            end
            if (tX == nil or (MathUtil.isNan(tX) or MathUtil.isNan(tZ))) and self:getIsFieldWorkActive() then
                self:stopCurrentAIJob(AIMessageSuccessFinishedJob.new())
            end
            if not self:getIsFieldWorkActive() then
                return
            end
            local minimumSpeed = 5
            local lookAheadDistance = 5
            if self:getAIFieldWorkerIsTurning() then
                minimumSpeed = 1.5
                lookAheadDistance = 2
            end
            local driveStrategy = maxSpeed * math.min(1, distanceToStop / lookAheadDistance)
            local distSpeed = math.max(minimumSpeed, driveStrategy)
            local _, driveStrategy = self:getSpeedLimit(true)
            local maxSpeed = math.min(maxSpeed, distSpeed, _)
            local maxSpeed = math.min(maxSpeed, self:getCruiseControlMaxSpeed())
            if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                self:addAIDebugText(string.format("===> maxSpeed = %.2f", maxSpeed))
            end
            spec.aiDriveParams.moveForwards = moveForwards
            spec.aiDriveParams.tX = tX
            spec.aiDriveParams.tY = vY
            spec.aiDriveParams.tZ = tZ
            spec.aiDriveParams.maxSpeed = maxSpeed
            spec.aiDriveParams.valid = true
        end
        if spec.aiDriveParams.valid then
            local vX = spec.aiDriveParams.moveForwards
            local tZ = spec.aiDriveParams.maxSpeed
            local distanceToStop, lookAheadDistance
            if vX then
                local minimumSpeed
                distanceToStop, minimumSpeed, lookAheadDistance = worldToLocal(self:getAISteeringNode(), spec.aiDriveParams.tX, spec.aiDriveParams.tY, spec.aiDriveParams.tZ)
            else
                local minimumSpeed
                distanceToStop, minimumSpeed, lookAheadDistance = worldToLocal(self:getAIReverserNode(), vY, vZ, tX)
            end
            local minimumSpeed = tZ ~= 0
            AIVehicleUtil.driveToPoint(self, dt, 1, minimumSpeed, vX, distanceToStop, lookAheadDistance, tZ)
        end
        self:raiseAIEvent("onAIFieldWorkerActive", "onAIImplementActive")
    end
end
function AIFieldWorker:getIsFieldWorkActive()
    return self.spec_aiFieldWorker.isActive
end
function AIFieldWorker:getStartableAIJob(superFunc)
    local job = superFunc(self)
    local fieldJob
    if job == nil then
        self:updateAIFieldWorkerImplementData()
        if self:getCanStartFieldWork() then
            fieldJob = self.spec_aiFieldWorker.fieldJob
            fieldJob:applyCurrentState(self, g_currentMission, g_localPlayer.farmId, true)
            fieldJob:setValues()
            if not fieldJob:validate(false) then
                fieldJob = job
            end
        else
            fieldJob = job
        end
    else
        fieldJob = job
    end
    return fieldJob
end
function AIFieldWorker:getHasStartableAIJob(_)
    return self:getCanStartFieldWork()
end
function AIFieldWorker:getCanStartFieldWork()
    local spec = self.spec_aiFieldWorker
    if spec.isActive then
        return false
    else
        return #spec.aiImplementList > 0
    end
end
function AIFieldWorker:startFieldWorker()
    local spec = self.spec_aiFieldWorker
    spec.isActive = true
    if self.isServer then
        self:updateAIFieldWorkerImplementData()
        self:updateAIFieldWorkerDriveStrategies()
        spec.checkImplementDirection = true
    end
    self:raiseAIEvent("onAIFieldWorkerStart", "onAIImplementStart")
    if self:getAINeedsTrafficCollisionBox() and (AIFieldWorker.TRAFFIC_COLLISION ~= nil and (AIFieldWorker.TRAFFIC_COLLISION ~= 0 and spec.aiTrafficCollision == nil)) then
        spec.aiTrafficCollision = clone(AIFieldWorker.TRAFFIC_COLLISION, true, false, true)
    end
end
function AIFieldWorker:stopFieldWorker()
    local spec = self.spec_aiFieldWorker
    spec.aiDriveParams.valid = false
    self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF, true)
    if self.isServer then
        WheelsUtil.updateWheelsPhysics(self, 0, spec.lastSpeedReal * spec.movingDirection, 0, true, true)
        if spec.driveStrategies ~= nil and #spec.driveStrategies > 0 then
            spec.reconstructionData = {}
            local i = #spec.driveStrategies
            for i = i, 1, -1 do
                local strategy = spec.driveStrategies[i]
                if strategy.fillReconstructionData ~= nil then
                    strategy:fillReconstructionData(spec.reconstructionData)
                end
                strategy:delete()
                table.remove(spec.driveStrategies, i)
            end
            spec.driveStrategies = {}
        end
    end
    if self:getAINeedsTrafficCollisionBox() and spec.aiTrafficCollision ~= nil then
        setTranslation(spec.aiTrafficCollision, 0, -1000, 0)
    end
    if self.brake ~= nil then
        self:brake(1)
    end
    local actionController = self.rootVehicle.actionController
    if actionController ~= nil then
        actionController:resetCurrentState()
    end
    self:raiseAIEvent("onAIFieldWorkerEnd", "onAIImplementEnd")
    spec.isBlocked = false
    spec.lastTurnStrategy = nil
    spec.isActive = false
end
function AIFieldWorker:getAICollisionTriggers(collisionTriggers) end
function AIFieldWorker:getDirectionSnapAngle()
    return 0
end
function AIFieldWorker:getAINeedsTrafficCollisionBox()
    return self.isServer
end
function AIFieldWorker:clearAIDebugTexts()
    local i = #self.spec_aiFieldWorker.debugTexts
    for i = i, 1, -1 do
        self.spec_aiFieldWorker.debugTexts[i] = nil
    end
end
function AIFieldWorker:addAIDebugText(text)
    table.insert(self.spec_aiFieldWorker.debugTexts, text)
end
function AIFieldWorker:clearAIDebugLines()
    local i = #self.spec_aiFieldWorker.debugLines
    for i = i, 1, -1 do
        self.spec_aiFieldWorker.debugLines[i] = nil
    end
end
function AIFieldWorker:addAIDebugLine(s, e, c)
    table.insert(self.spec_aiFieldWorker.debugLines, {
        ["s"] = s,
        ["e"] = e,
        ["c"] = c
    })
end
function AIFieldWorker:onStateChange(state, _)
    if state == VehicleStateChange.ATTACH or state == VehicleStateChange.DETACH then
        self.spec_aiFieldWorker.aiImplementDataDirtyFlag = true
    end
end
function AIFieldWorker:updateAIFieldWorkerImplementData()
    local spec = self.spec_aiFieldWorker
    spec.aiImplementList = {}
    self:addVehicleToAIImplementList(spec.aiImplementList)
end
function AIFieldWorker:updateAIFieldWorkerDriveStrategies()
    local spec = self.spec_aiFieldWorker
    if #spec.aiImplementList > 0 then
        if spec.driveStrategies ~= nil and #spec.driveStrategies > 0 then
            local i = #spec.driveStrategies
            for i = i, 1, -1 do
                spec.driveStrategies[i]:delete()
                table.remove(spec.driveStrategies, i)
            end
            spec.driveStrategies = {}
        end
        for strategyIndex, strategyData in ipairs(AIFieldWorker.registeredDriveStrategies) do
            for _, childVehicle in pairs(self.rootVehicle.childVehicles) do
                if strategyData.func(childVehicle) then
                    table.insert(spec.driveStrategies, strategyData.class.new(spec.reconstructionData))
                    break
                end
            end
        end
        local i = 1
        for i = i, #spec.driveStrategies do
            spec.driveStrategies[i]:setAIVehicle(self)
        end
    end
end
function AIFieldWorker:aiFieldWorkerStartTurn(left, turnStrategy)
    local spec = self.spec_aiFieldWorker
    spec.lastTurnDirection = left
    spec.lastTurnStrategy = turnStrategy
    for _, driveStrategy in ipairs(spec.driveStrategies) do
        if driveStrategy.setTurnData ~= nil then
            driveStrategy:setTurnData(left, turnStrategy)
        end
    end
    self:raiseAIEvent("onAIFieldWorkerStartTurn", "onAIImplementStartTurn", left, turnStrategy)
end
function AIFieldWorker:aiFieldWorkerTurnProgress(progress, isLeft, movingDirection)
    self:raiseAIEvent("onAIFieldWorkerTurnProgress", "onAIImplementTurnProgress", progress, isLeft, movingDirection)
end
function AIFieldWorker:aiFieldWorkerEndTurn(left)
    local spec = self.spec_aiFieldWorker
    spec.lastTurnStrategy = nil
    for _, driveStrategy in ipairs(spec.driveStrategies) do
        if driveStrategy.setTurnData ~= nil then
            driveStrategy:setTurnData()
        end
    end
    self:raiseAIEvent("onAIFieldWorkerEndTurn", "onAIImplementEndTurn", left)
end
function AIFieldWorker:aiFieldWorkerSideOffsetChanged(isLeft, isInitial)
    self:raiseAIEvent("onAIFieldWorkerSideOffsetChanged", "onAIImplementSideOffsetChanged", isLeft, isInitial)
end
function AIFieldWorker:aiBlock(superFunc)
    superFunc(self)
    local spec = self.spec_aiFieldWorker
    if spec.isActive and not spec.isTurning then
        self:raiseAIEvent("onAIFieldWorkerBlock", "onAIImplementBlock")
    end
    spec.isBlocked = true
end
function AIFieldWorker:aiContinue(superFunc)
    superFunc(self)
    local spec = self.spec_aiFieldWorker
    if spec.isActive and not spec.isTurning then
        self:raiseAIEvent("onAIFieldWorkerContinue", "onAIImplementContinue")
    end
    spec.isBlocked = false
end
function AIFieldWorker:getCanAIFieldWorkerContinueWork(isTurning)
    for _, implement in ipairs(self:getAttachedAIImplements()) do
        local canContinue, stopAI, stopReason = implement.object:getCanAIImplementContinueWork(isTurning)
        if not canContinue then
            return false, stopAI, stopReason
        end
    end
    if SpecializationUtil.hasSpecialization(AIImplement, self.specializations) then
        local canContinue, stopAI, stopReason = self:getCanAIImplementContinueWork(isTurning)
        if not canContinue then
            return false, stopAI, stopReason
        end
    end
    return true, false
end
function AIFieldWorker:setAIFieldWorkerIsTurning(isTurning)
    self.spec_aiFieldWorker.isTurning = isTurning
end
function AIFieldWorker:getAIFieldWorkerIsTurning()
    return self.spec_aiFieldWorker.isTurning
end
function AIFieldWorker:setAIFieldWorkerIsCornerCutOutActive(isCornerCutOutActive)
    self.spec_aiFieldWorker.isCornerCutOutActive = isCornerCutOutActive
end
function AIFieldWorker:getAIFieldWorkerIsCornerCutOutActive()
    return self.spec_aiFieldWorker.isCornerCutOutActive
end
function AIFieldWorker:getAIFieldWorkerLastTurnDirection()
    return self.spec_aiFieldWorker.lastTurnDirection
end
function AIFieldWorker:getAIFieldWorkerIsBlocked()
    return self.spec_aiFieldWorker.isBlocked
end
function AIFieldWorker:getAttachedAIImplements()
    return self.spec_aiFieldWorker.aiImplementList
end
function AIFieldWorker.onTrafficCollisionLoaded(_, i3dNode)
    if i3dNode ~= 0 then
        local collision = getChildAt(i3dNode, 0)
        link(getRootNode(), collision)
        AIFieldWorker.TRAFFIC_COLLISION = collision
        delete(i3dNode)
    end
end