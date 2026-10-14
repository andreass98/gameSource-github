AIJobDeliver = {}
AIJobDeliver.START_ERROR_LIMIT_REACHED = 1
AIJobDeliver.START_ERROR_VEHICLE_DELETED = 2
AIJobDeliver.START_ERROR_NO_PERMISSION = 3
AIJobDeliver.START_ERROR_VEHICLE_IN_USE = 4
local AIJobDeliver_mt = Class(AIJobDeliver, AIJob)
function AIJobDeliver.new(isServer, customMt)
    -- upvalues: (copy) AIJobDeliver_mt
    local self = AIJob.new(isServer, customMt or AIJobDeliver_mt)
    self.dischargeNodeInfos = {}
    self.driveToLoadingTask = AITaskDriveTo.new(isServer, self)
    self.waitForFillingTask = AITaskWaitForFilling.new(isServer, self)
    self.driveToUnloadingTask = AITaskDriveTo.new(isServer, self)
    self.dischargeTask = AITaskDischarge.new(isServer, self)
    self:addTask(self.driveToLoadingTask)
    self:addTask(self.waitForFillingTask)
    self:addTask(self.driveToUnloadingTask)
    self:addTask(self.dischargeTask)
    self.vehicleParameter = AIParameterVehicle.new()
    self.unloadingStationParameter = AIParameterUnloadingStation.new()
    self.loopingParameter = AIParameterLooping.new()
    self.positionAngleParameter = AIParameterPositionAngle.new(0.08726646259971647)
    self:addNamedParameter("vehicle", self.vehicleParameter)
    self:addNamedParameter("unloadingStation", self.unloadingStationParameter)
    self:addNamedParameter("looping", self.loopingParameter)
    self:addNamedParameter("positionAngle", self.positionAngleParameter)
    local vehicleGroup = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleVehicle"))
    vehicleGroup:addParameter(self.vehicleParameter)
    local unloadTargetGroup = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleUnloadingStation"))
    unloadTargetGroup:addParameter(self.unloadingStationParameter)
    local positionGroup = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleLoadingPosition"))
    positionGroup:addParameter(self.positionAngleParameter)
    local loopingGroup = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleLooping"))
    loopingGroup:addParameter(self.loopingParameter)
    table.insert(self.groupedParameters, vehicleGroup)
    table.insert(self.groupedParameters, unloadTargetGroup)
    table.insert(self.groupedParameters, positionGroup)
    table.insert(self.groupedParameters, loopingGroup)
    return self
end
function AIJobDeliver:setValues()
    self:resetTasks()
    local vehicle = self.vehicleParameter:getVehicle()
    if vehicle == nil then
        return
    else
        local unloadingStation = self.unloadingStationParameter:getUnloadingStation()
        if unloadingStation == nil then
            return
        else
            self.driveToUnloadingTask:setVehicle(vehicle)
            self.driveToLoadingTask:setVehicle(vehicle)
            self.dischargeTask:setVehicle(vehicle)
            self.waitForFillingTask:setVehicle(vehicle)
            self.dischargeNodeInfos = {}
            for fillType, _ in pairs(unloadingStation:getAISupportedFillTypes()) do
                self.waitForFillingTask:addAllowedFillType(fillType)
            end
            if vehicle.getAIDischargeNodes ~= nil then
                for fillType, _ in ipairs(vehicle:getAIDischargeNodes()) do
                    local _, _, z = vehicle:getAIDischargeNodeZAlignedOffset(_, vehicle)
                    table.insert(self.dischargeNodeInfos, {
                        ["vehicle"] = vehicle,
                        ["dischargeNode"] = _,
                        ["offsetZ"] = z,
                        ["dirty"] = true
                    })
                end
            end
            local childVehicles = vehicle:getChildVehicles()
            for _, _ in ipairs(childVehicles) do
                if _.getAIDischargeNodes ~= nil then
                    for _, dischargeNode in ipairs(_:getAIDischargeNodes()) do
                        local _, _, z = _:getAIDischargeNodeZAlignedOffset(dischargeNode, vehicle)
                        table.insert(self.dischargeNodeInfos, {
                            ["vehicle"] = _,
                            ["dischargeNode"] = dischargeNode,
                            ["offsetZ"] = z,
                            ["dirty"] = true
                        })
                    end
                end
            end
            if #self.dischargeNodeInfos ~= 0 then
                table.sort(self.dischargeNodeInfos, function(a, b)
                    return a.offsetZ > b.offsetZ
                end)
                for _, _ in ipairs(self.dischargeNodeInfos) do
                    self.waitForFillingTask:addFillUnits(_.vehicle, _.dischargeNode.fillUnitIndex)
                end
                local maxOffset = self.dischargeNodeInfos[#self.dischargeNodeInfos].offsetZ
                self.driveToLoadingTask:setTargetOffset(-maxOffset)
                self.driveToUnloadingTask:setTargetOffset(-maxOffset)
                local x, fillType = self.positionAngleParameter:getPosition()
                if x ~= nil then
                    self.driveToLoadingTask:setTargetPosition(x, fillType)
                end
                local _, _ = self.positionAngleParameter:getDirection()
                if _ ~= nil then
                    self.driveToLoadingTask:setTargetDirection(_, _)
                end
            end
        end
    end
end
function AIJobDeliver:validate(_)
    self:setParameterValid(true)
    local isVehicleValid, vehicleErrorMessage = self.vehicleParameter:validate()
    if isVehicleValid and #self.dischargeNodeInfos == 0 then
        isVehicleValid = false
        vehicleErrorMessage = g_i18n:getText("ai_validationErrorNoAIDischargeNodesFound")
    end
    if not isVehicleValid then
        self.vehicleParameter:setIsValid(false)
    end
    local isUnloadingStationValid, unloadingStationErrorMessage = self.unloadingStationParameter:validate()
    if not isUnloadingStationValid then
        self.unloadingStationParameter:setIsValid(false)
    end
    local isPositionValid, positionErrorMessage = self.positionAngleParameter:validate()
    if not isPositionValid then
        positionErrorMessage = g_i18n:getText("ai_validationErrorNoLoadingPoint")
        self.positionAngleParameter:setIsValid(false)
    end
    if isVehicleValid then
        if not isUnloadingStationValid then
            isPositionValid = isUnloadingStationValid
        end
    else
        isPositionValid = isVehicleValid
    end
    return isPositionValid, vehicleErrorMessage or (unloadingStationErrorMessage or positionErrorMessage)
end
function AIJobDeliver:applyCurrentState(vehicle, mission, farmId, isDirectStart)
    AIJobDeliver:superClass().applyCurrentState(self, vehicle, mission, farmId, isDirectStart)
    self.vehicleParameter:setVehicle(vehicle)
    self.loopingParameter:setIsLooping(true)
    local x = nil
    local z = nil
    local angle = nil
    if vehicle.getLastJob ~= nil then
        local lastJob = vehicle:getLastJob()
        if lastJob ~= nil and lastJob:isa(AIJobDeliver) then
            self.unloadingStationParameter:setUnloadingStation(lastJob.unloadingStationParameter:getUnloadingStation())
            self.loopingParameter:setIsLooping(lastJob.loopingParameter:getIsLooping())
            x, z = lastJob.positionAngleParameter:getPosition()
            angle = lastJob.positionAngleParameter:getAngle()
        end
    end
    if x == nil or z == nil then
        x, _, z = getWorldTranslation(vehicle.rootNode)
    end
    if angle == nil then
        local lastJob, _, dirZ = localDirectionToWorld(vehicle.rootNode, 0, 0, 1)
        angle = MathUtil.getYRotationFromDirection(lastJob, dirZ)
    end
    self.positionAngleParameter:setPosition(x, z)
    self.positionAngleParameter:setAngle(angle)
    local lastJob = {}
    for _, unloadingStation in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
        if g_currentMission.accessHandler:canPlayerAccess(unloadingStation) and unloadingStation:isa(UnloadingStation) then
            local fillTypes = unloadingStation:getAISupportedFillTypes()
            if next(fillTypes) ~= nil then
                table.insert(lastJob, unloadingStation)
            end
        end
    end
    table.sort(lastJob, function(a, b)
        return a:getName() < b:getName()
    end)
    self.unloadingStationParameter:setValidUnloadingStations(lastJob)
end
function AIJobDeliver:start(farmId)
    AIJobDeliver:superClass().start(self, farmId)
    if self.isServer then
        local vehicle = self.vehicleParameter:getVehicle()
        vehicle:createAgent(self.helperIndex)
        vehicle:aiJobStarted(self, self.helperIndex, farmId)
    end
end
function AIJobDeliver:stop(aiMessage)
    if self.isServer then
        local vehicle = self.vehicleParameter:getVehicle()
        vehicle:deleteAgent()
        vehicle:aiJobFinished()
    end
    AIJobDeliver:superClass().stop(self, aiMessage)
    self.dischargeNodeInfos = {}
end
function AIJobDeliver:startTask(task)
    if task == self.waitForFillingTask then
        for _, dischargeNodeInfo in ipairs(self.dischargeNodeInfos) do
            dischargeNodeInfo.dirty = true
        end
    end
    AIJobDeliver:superClass().startTask(self, task)
end
function AIJobDeliver:getStartTaskIndex()
    local hasOneEmptyFillUnit = false
    for _, dischargeNodeInfo in ipairs(self.dischargeNodeInfos) do
        if dischargeNodeInfo.vehicle:getFillUnitFillLevel(dischargeNodeInfo.dischargeNode.fillUnitIndex) == 0 then
            hasOneEmptyFillUnit = true
            break
        end
    end
    local vehicle = self.vehicleParameter:getVehicle()
    local x, _, _ = getWorldTranslation(vehicle.rootNode)
    local dischargeNodeInfo, vehicle = self.positionAngleParameter:getPosition()
    local fillUnitIndex = false
    if math.abs(x - dischargeNodeInfo) < 1 then
        fillUnitIndex = math.abs(_ - vehicle) < 1
    end
    if fillUnitIndex then
        if not hasOneEmptyFillUnit then
            self.waitForFillingTask:skip()
        end
        return self.waitForFillingTask.taskIndex
    else
        if not hasOneEmptyFillUnit then
            self.driveToLoadingTask:skip()
            self.waitForFillingTask:skip()
        end
        return self.driveToLoadingTask.taskIndex
    end
end
function AIJobDeliver:getNextTaskIndex(isSkipTask)
    if self.currentTaskIndex == self.waitForFillingTask.taskIndex or self.currentTaskIndex == self.dischargeTask.taskIndex then
        local lastUnloadTrigger = nil
        if self.currentTaskIndex == self.dischargeTask.taskIndex then
            lastUnloadTrigger = self.dischargeTask.unloadTrigger
        end
        local nextFillType = nil
        local nextDischargeNodeInfo = nil
        local unloadingStation = self.unloadingStationParameter:getUnloadingStation()
        for _, dischargeNodeInfo in ipairs(self.dischargeNodeInfos) do
            if dischargeNodeInfo.dirty then
                local vehicle = dischargeNodeInfo.vehicle
                local fillUnitIndex = dischargeNodeInfo.dischargeNode.fillUnitIndex
                if vehicle:getFillUnitFillLevel(fillUnitIndex) > 1 then
                    local currentFillType = vehicle:getFillUnitFillType(fillUnitIndex)
                    if lastUnloadTrigger ~= nil and lastUnloadTrigger:getIsFillTypeSupported(currentFillType) then
                        self.dischargeTask:setDischargeNode(vehicle, dischargeNodeInfo.dischargeNode, dischargeNodeInfo.offsetZ)
                        dischargeNodeInfo.dirty = false
                        return self.currentTaskIndex
                    end
                    if nextFillType == nil then
                        local _, _, _, _, trigger = unloadingStation:getAITargetPositionAndDirection(currentFillType)
                        if trigger == nil then
                            dischargeNodeInfo.dirty = false
                        else
                            nextDischargeNodeInfo = dischargeNodeInfo
                            nextFillType = currentFillType
                        end
                    end
                end
            end
        end
        if nextFillType ~= nil then
            local x, z, dirX, _, dischargeNodeInfo = unloadingStation:getAITargetPositionAndDirection(nextFillType)
            self.driveToUnloadingTask:setTargetPosition(x, z)
            self.driveToUnloadingTask:setTargetDirection(dirX, _)
            self.dischargeTask:setUnloadTrigger(dischargeNodeInfo)
            self.dischargeTask:setDischargeNode(nextDischargeNodeInfo.vehicle, nextDischargeNodeInfo.dischargeNode, nextDischargeNodeInfo.offsetZ)
            nextDischargeNodeInfo.dirty = false
            return self.driveToUnloadingTask.taskIndex
        end
    end
    return AIJobDeliver:superClass().getNextTaskIndex(self, isSkipTask)
end
function AIJobDeliver:canContinueWork()
    if self.vehicleParameter:getVehicle() == nil then
        return false, AIMessageErrorVehicleDeleted.new()
    end
    local unloadingStation = self.unloadingStationParameter:getUnloadingStation()
    if unloadingStation == nil then
        return false, AIMessageErrorUnloadingStationDeleted.new()
    end
    if self.currentTaskIndex == self.waitForFillingTask.taskIndex then
        local hasSpace = false
        for _, dischargeNodeInfo in ipairs(self.dischargeNodeInfos) do
            local dischargeVehicle = dischargeNodeInfo.vehicle
            local fillUnitIndex = dischargeNodeInfo.dischargeNode.fillUnitIndex
            if dischargeVehicle:getFillUnitFillLevel(fillUnitIndex) > 1 and unloadingStation:getFreeCapacity(dischargeVehicle:getFillUnitFillType(fillUnitIndex), self.startedFarmId) > 0 then
                hasSpace = true
                break
            end
        end
        if not hasSpace then
            return false, AIMessageErrorUnloadingStationFull.new()
        end
    end
    return true, nil
end
function AIJobDeliver:getHasLoadedValidFillType()
    local unloadingStation = self.unloadingStationParameter:getUnloadingStation()
    for _, dischargeNodeInfo in ipairs(self.dischargeNodeInfos) do
        local vehicle = dischargeNodeInfo.vehicle
        local fillUnitIndex = dischargeNodeInfo.dischargeNode.fillUnitIndex
        if vehicle:getFillUnitFillLevel(fillUnitIndex) > 1 and unloadingStation:getIsFillTypeAISupported((vehicle:getFillUnitFillType(fillUnitIndex))) then
            return true
        end
    end
    return false
end
function AIJobDeliver:getCanSkipTask()
    return self.currentTaskIndex == self.waitForFillingTask.taskIndex and (not self.waitForFillingTask.isFinished and self:getHasLoadedValidFillType()) and true or false
end
function AIJobDeliver:skipCurrentTask()
    if self.currentTaskIndex == self.waitForFillingTask.taskIndex then
        self.waitForFillingTask:skip()
    end
end
function AIJobDeliver:getIsAvailableForVehicle(vehicle)
    if vehicle.createAgent == nil or (vehicle.setAITarget == nil or not vehicle:getCanStartAIVehicle()) then
        return false
    end
    if not vehicle:getIsAIJobSupported(ClassUtil.getClassNameByObject(self)) then
        return false
    end
    if vehicle.getAIDischargeNodes ~= nil then
        local nodes = vehicle:getAIDischargeNodes()
        if next(nodes) ~= nil then
            return true
        end
    end
    local nodes = vehicle:getChildVehicles()
    for _, childVehicle in ipairs(nodes) do
        if childVehicle.getAIDischargeNodes ~= nil then
            local nodes = childVehicle:getAIDischargeNodes()
            if next(nodes) ~= nil then
                return true
            end
        end
    end
    return false
end
function AIJobDeliver:getTitle()
    local vehicle = self.vehicleParameter:getVehicle()
    return vehicle == nil and "" or vehicle:getName()
end
function AIJobDeliver:getIsLooping()
    return self.loopingParameter:getIsLooping()
end
function AIJobDeliver:getIsStartable(connection)
    if g_currentMission.aiSystem:getAILimitedReached() then
        return false, AIJobDeliver.START_ERROR_LIMIT_REACHED
    else
        local vehicle = self.vehicleParameter:getVehicle()
        if vehicle == nil then
            return false, AIJobDeliver.START_ERROR_VEHICLE_DELETED
        elseif g_currentMission:getHasPlayerPermission("hireAssistant", connection, vehicle:getOwnerFarmId()) then
            if vehicle:getIsInUse(connection) then
                return false, AIJobDeliver.START_ERROR_VEHICLE_IN_USE
            else
                return true, AIJob.START_SUCCESS
            end
        else
            return false, AIJobDeliver.START_ERROR_NO_PERMISSION
        end
    end
end
function AIJobDeliver:getDescription()
    local desc = AIJobDeliver:superClass().getDescription(self)
    local nextTask = self:getTaskByIndex(self.currentTaskIndex)
    if nextTask == self.driveToLoadingTask then
        return desc .. " - " .. g_i18n:getText("ai_taskDescriptionDriveToLoadingStation")
    end
    if nextTask == self.waitForFillingTask then
        return desc .. " - " .. g_i18n:getText("ai_taskDescriptionWaitForFilling")
    end
    if nextTask == self.driveToUnloadingTask then
        return desc .. " - " .. g_i18n:getText("ai_taskDescriptionDriveToUnloadingStation")
    end
    if nextTask == self.dischargeTask then
        desc = desc .. " - " .. g_i18n:getText("ai_taskDescriptionUnloading")
    end
    return desc
end
function AIJobDeliver.getIsStartErrorText(state)
    if state == AIJobDeliver.START_ERROR_LIMIT_REACHED then
        return g_i18n:getText("ai_startStateLimitReached")
    elseif state == AIJobDeliver.START_ERROR_VEHICLE_DELETED then
        return g_i18n:getText("ai_startStateVehicleDeleted")
    elseif state == AIJobDeliver.START_ERROR_NO_PERMISSION then
        return g_i18n:getText("ai_startStateNoPermission")
    elseif state == AIJobDeliver.START_ERROR_VEHICLE_IN_USE then
        return g_i18n:getText("ai_startStateVehicleInUse")
    else
        return g_i18n:getText("ai_startStateSuccess")
    end
end