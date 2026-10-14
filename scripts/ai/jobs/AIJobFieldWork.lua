AIJobFieldWork = {}
AIJobFieldWork.START_ERROR_LIMIT_REACHED = 1
AIJobFieldWork.START_ERROR_VEHICLE_DELETED = 2
AIJobFieldWork.START_ERROR_NO_PERMISSION = 3
AIJobFieldWork.START_ERROR_VEHICLE_IN_USE = 4
local AIJobFieldWork_mt = Class(AIJobFieldWork, AIJob)
function AIJobFieldWork.new(isServer, customMt)
    -- upvalues: (copy) AIJobFieldWork_mt
    local self = AIJob.new(isServer, customMt or AIJobFieldWork_mt)
    self.driveToTask = AITaskDriveTo.new(isServer, self)
    self.fieldWorkTask = AITaskFieldWork.new(isServer, self)
    self:addTask(self.driveToTask)
    self:addTask(self.fieldWorkTask)
    self.isDirectStart = false
    self.vehicleParameter = AIParameterVehicle.new()
    self.positionAngleParameter = AIParameterPositionAngle.new(0)
    self:addNamedParameter("vehicle", self.vehicleParameter)
    self:addNamedParameter("positionAngle", self.positionAngleParameter)
    local vehicleGroup = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleVehicle"))
    vehicleGroup:addParameter(self.vehicleParameter)
    local positionGroup = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitlePosition"))
    positionGroup:addParameter(self.positionAngleParameter)
    table.insert(self.groupedParameters, vehicleGroup)
    table.insert(self.groupedParameters, positionGroup)
    return self
end
function AIJobFieldWork:readStream(streamId, connection)
    AIJobFieldWork:superClass().readStream(self, streamId, connection)
    if streamReadBool(streamId) then
        self.pendingData = AIModeSelection.readAIModeSettingsFromStream(streamId, connection)
        self.pendingVehicle = true
    end
end
function AIJobFieldWork:writeStream(streamId, connection)
    AIJobFieldWork:superClass().writeStream(self, streamId, connection)
    local vehicle = self.vehicleParameter:getVehicle()
    if streamWriteBool(streamId, vehicle ~= nil) then
        vehicle:writeAIModeSettingsToStream(streamId, connection)
    end
end
function AIJobFieldWork:update(dt)
    if self.pendingVehicle then
        local vehicle = self.vehicleParameter:getVehicle()
        if vehicle ~= nil then
            self.driveToTask:setVehicle(vehicle)
            self.fieldWorkTask:setVehicle(vehicle)
            vehicle:applyReadAIModeSettingsFromStream(self.pendingData)
            self.pendingData = nil
            self.pendingVehicle = nil
        end
    end
    AIJobFieldWork:superClass().update(self, dt)
end
function AIJobFieldWork:getStartTaskIndex()
    if self.isDirectStart then
        return 2
    end
    local vehicle = self.vehicleParameter:getVehicle()
    local x, _, z = getWorldTranslation(vehicle.rootNode)
    local tx, tz = self.positionAngleParameter:getPosition()
    local targetReached = MathUtil.vector2Length(x - tx, z - tz) < 3
    return targetReached and 2 or 1
end
function AIJobFieldWork:start(farmId)
    AIJobFieldWork:superClass().start(self, farmId)
    if self.isServer then
        local vehicle = self.vehicleParameter:getVehicle()
        vehicle:createAgent(self.helperIndex)
        vehicle:aiJobStarted(self, self.helperIndex, farmId)
    end
end
function AIJobFieldWork:stop(aiMessage)
    if self.isServer then
        local vehicle = self.vehicleParameter:getVehicle()
        vehicle:deleteAgent()
        vehicle:aiJobFinished()
    end
    AIJobFieldWork:superClass().stop(self, aiMessage)
end
function AIJobFieldWork:applyCurrentState(vehicle, mission, farmId, isDirectStart)
    AIJobFieldWork:superClass().applyCurrentState(self, vehicle, mission, farmId, isDirectStart)
    self.vehicleParameter:setVehicle(vehicle)
    local x = nil
    local z = nil
    local angle = nil
    if vehicle.getLastJob ~= nil then
        local lastJob = vehicle:getLastJob()
        if not isDirectStart and (lastJob ~= nil and lastJob:isa(AIJobFieldWork)) then
            x, z = lastJob.positionAngleParameter:getPosition()
            angle = lastJob.positionAngleParameter:getAngle()
        end
    end
    local lastJob = vehicle:getDirectionSnapAngle()
    local terrainAngle = 3.141592653589793 / math.max(g_currentMission.fieldGroundSystem:getGroundAngleMaxValue() + 1, 4)
    local dirX = math.max(lastJob, terrainAngle)
    self.positionAngleParameter:setSnappingAngle(dirX)
    if x == nil or z == nil then
        x, _, z = getWorldTranslation(vehicle.rootNode)
    end
    if angle == nil then
        local dirX, _, dirZ = localDirectionToWorld(vehicle.rootNode, 0, 0, 1)
        angle = MathUtil.getYRotationFromDirection(dirX, dirZ)
    end
    self.positionAngleParameter:setPosition(x, z)
    self.positionAngleParameter:setAngle(angle)
end
function AIJobFieldWork:getIsAvailableForVehicle(vehicle)
    return vehicle.getCanStartFieldWork and vehicle:getCanStartFieldWork() and vehicle:getIsAIJobSupported(ClassUtil.getClassNameByObject(self))
end
function AIJobFieldWork:getShowTarget()
    return self.currentTaskIndex == 1
end
function AIJobFieldWork:getTarget()
    local angle = 0
    if self.driveToTask.dirX ~= nil then
        angle = MathUtil.getYRotationFromDirection(self.driveToTask.dirX, self.driveToTask.dirZ)
    end
    return self.driveToTask.x, self.driveToTask.z, angle
end
function AIJobFieldWork:getTitle()
    local vehicle = self.vehicleParameter:getVehicle()
    return vehicle == nil and "" or vehicle:getName()
end
function AIJobFieldWork:setValues()
    self:resetTasks()
    local vehicle = self.vehicleParameter:getVehicle()
    self.driveToTask:setVehicle(vehicle)
    self.fieldWorkTask:setVehicle(vehicle)
    local angle = self.positionAngleParameter:getAngle()
    local x, z = self.positionAngleParameter:getPosition()
    local dirX, dirZ = MathUtil.getDirectionFromYRotation(angle)
    self.driveToTask:setTargetDirection(dirX, dirZ)
    self.driveToTask:setTargetPosition(x, z)
end
function AIJobFieldWork:validate(_)
    self:setParameterValid(true)
    local isValid, errorMessage = self.vehicleParameter:validate()
    if not isValid then
        self.vehicleParameter:setIsValid(false)
    end
    return isValid, errorMessage
end
function AIJobFieldWork:getDescription()
    local desc = AIJobFieldWork:superClass().getDescription(self)
    local nextTask = self:getTaskByIndex(self.currentTaskIndex)
    if nextTask == self.driveToTask then
        return desc .. " - " .. g_i18n:getText("ai_taskDescriptionDriveToField")
    end
    if nextTask == self.fieldWorkTask then
        desc = desc .. " - " .. g_i18n:getText("ai_taskDescriptionFieldWork")
    end
    return desc
end
function AIJobFieldWork:getIsStartable(connection)
    if g_currentMission.aiSystem:getAILimitedReached() then
        return false, AIJobFieldWork.START_ERROR_LIMIT_REACHED
    else
        local vehicle = self.vehicleParameter:getVehicle()
        if vehicle == nil then
            return false, AIJobFieldWork.START_ERROR_VEHICLE_DELETED
        elseif g_currentMission:getHasPlayerPermission("hireAssistant", connection, vehicle:getOwnerFarmId()) then
            if vehicle:getIsInUse(connection) then
                return false, AIJobFieldWork.START_ERROR_VEHICLE_IN_USE
            else
                return true, AIJob.START_SUCCESS
            end
        else
            return false, AIJobFieldWork.START_ERROR_NO_PERMISSION
        end
    end
end
function AIJobFieldWork.getIsStartErrorText(state)
    if state == AIJobFieldWork.START_ERROR_LIMIT_REACHED then
        return g_i18n:getText("ai_startStateLimitReached")
    elseif state == AIJobFieldWork.START_ERROR_VEHICLE_DELETED then
        return g_i18n:getText("ai_startStateVehicleDeleted")
    elseif state == AIJobFieldWork.START_ERROR_NO_PERMISSION then
        return g_i18n:getText("ai_startStateNoPermission")
    elseif state == AIJobFieldWork.START_ERROR_VEHICLE_IN_USE then
        return g_i18n:getText("ai_startStateVehicleInUse")
    else
        return g_i18n:getText("ai_startStateSuccess")
    end
end
function AIJobFieldWork:getPricePerMs()
    return 0.0005
end