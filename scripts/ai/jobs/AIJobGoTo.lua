AIJobGoTo = {}
AIJobGoTo.START_ERROR_LIMIT_REACHED = 1
AIJobGoTo.START_ERROR_VEHICLE_DELETED = 2
AIJobGoTo.START_ERROR_NO_PERMISSION = 3
AIJobGoTo.START_ERROR_VEHICLE_IN_USE = 4
local AIJobGoTo_mt = Class(AIJobGoTo, AIJob)
function AIJobGoTo.new(isServer, customMt)
    -- upvalues: (copy) AIJobGoTo_mt
    local self = AIJob.new(isServer, customMt or AIJobGoTo_mt)
    self.driveToTask = AITaskDriveTo.new(isServer, self)
    self:addTask(self.driveToTask)
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
function AIJobGoTo:start(farmId)
    AIJobGoTo:superClass().start(self, farmId)
    local vehicle = self.vehicleParameter:getVehicle()
    if vehicle ~= nil then
        if self.isServer then
            vehicle:createAgent(self.helperIndex)
        end
        vehicle:aiJobStarted(self, self.helperIndex, farmId)
    end
end
function AIJobGoTo:stop(aiMessage)
    local vehicle = self.vehicleParameter:getVehicle()
    if vehicle ~= nil then
        if self.isServer then
            vehicle:deleteAgent()
        end
        vehicle:aiJobFinished()
    end
    AIJobGoTo:superClass().stop(self, aiMessage)
end
function AIJobGoTo:getShowTarget()
    return true
end
function AIJobGoTo:getTarget()
    local angle = nil
    if self.driveToTask.dirX ~= nil then
        angle = MathUtil.getYRotationFromDirection(self.driveToTask.dirX, self.driveToTask.dirZ)
    end
    return self.driveToTask.x, self.driveToTask.z, angle
end
function AIJobGoTo:getIsAvailableForVehicle(vehicle)
    if vehicle.createAgent == nil or (vehicle.setAITarget == nil or not vehicle:getCanStartAIVehicle()) then
        return false
    else
        return vehicle:getIsAIJobSupported(ClassUtil.getClassNameByObject(self)) and true or false
    end
end
function AIJobGoTo:getTitle()
    local vehicle = self.vehicleParameter:getVehicle()
    return vehicle == nil and "" or vehicle:getName()
end
function AIJobGoTo:applyCurrentState(vehicle, mission, farmId, isDirectStart)
    AIJobGoTo:superClass().applyCurrentState(self, vehicle, mission, farmId, isDirectStart)
    self.vehicleParameter:setVehicle(vehicle)
    local x = nil
    local z = nil
    local angle = nil
    if vehicle.getLastJob ~= nil then
        local lastJob = vehicle:getLastJob()
        if not isDirectStart and (lastJob ~= nil and lastJob:isa(AIJobGoTo)) then
            x, z = lastJob.positionAngleParameter:getPosition()
            angle = lastJob.positionAngleParameter:getAngle()
        end
    end
    self.positionAngleParameter:setSnappingAngle(0)
    if x == nil or z == nil then
        x, _, z = getWorldTranslation(vehicle.rootNode)
    end
    if angle == nil then
        local lastJob, _, dirZ = localDirectionToWorld(vehicle.rootNode, 0, 0, 1)
        angle = MathUtil.getYRotationFromDirection(lastJob, dirZ)
    end
    self.positionAngleParameter:setPosition(x, z)
    self.positionAngleParameter:setAngle(angle)
end
function AIJobGoTo:setValues()
    self:resetTasks()
    self.driveToTask:setVehicle(self.vehicleParameter:getVehicle())
    local angle = self.positionAngleParameter:getAngle()
    local x, z = self.positionAngleParameter:getPosition()
    local dirX, dirZ = MathUtil.getDirectionFromYRotation(angle)
    self.driveToTask:setTargetDirection(dirX, dirZ)
    self.driveToTask:setTargetPosition(x, z)
end
function AIJobGoTo:validate(_)
    self:setParameterValid(true)
    local isVehicleValid, errorMessageVehicle = self.vehicleParameter:validate()
    if not isVehicleValid then
        self.vehicleParameter:setIsValid(false)
    end
    local isPositionValid, errorMessagePosition = self.positionAngleParameter:validate()
    if not isPositionValid then
        self.positionAngleParameter:setIsValid(false)
    end
    return isVehicleValid and isPositionValid, errorMessageVehicle or errorMessagePosition
end
function AIJobGoTo:getDescription()
    local desc = AIJobGoTo:superClass().getDescription(self)
    if self:getTaskByIndex(self.currentTaskIndex) == self.driveToTask then
        desc = desc .. " - " .. g_i18n:getText("ai_taskDescriptionDriveToTarget")
    end
    return desc
end
function AIJobGoTo:getIsStartable(connection)
    if g_currentMission.aiSystem:getAILimitedReached() then
        return false, AIJobGoTo.START_ERROR_LIMIT_REACHED
    else
        local vehicle = self.vehicleParameter:getVehicle()
        if vehicle == nil then
            return false, AIJobGoTo.START_ERROR_VEHICLE_DELETED
        elseif g_currentMission:getHasPlayerPermission("hireAssistant", connection, vehicle:getOwnerFarmId()) then
            if vehicle:getIsInUse(connection) then
                return false, AIJobGoTo.START_ERROR_VEHICLE_IN_USE
            else
                return true, AIJob.START_SUCCESS
            end
        else
            return false, AIJobGoTo.START_ERROR_NO_PERMISSION
        end
    end
end
function AIJobGoTo.getIsStartErrorText(state)
    if state == AIJobGoTo.START_ERROR_LIMIT_REACHED then
        return g_i18n:getText("ai_startStateLimitReached")
    elseif state == AIJobGoTo.START_ERROR_VEHICLE_DELETED then
        return g_i18n:getText("ai_startStateVehicleDeleted")
    elseif state == AIJobGoTo.START_ERROR_NO_PERMISSION then
        return g_i18n:getText("ai_startStateNoPermission")
    elseif state == AIJobGoTo.START_ERROR_VEHICLE_IN_USE then
        return g_i18n:getText("ai_startStateVehicleInUse")
    else
        return g_i18n:getText("ai_startStateSuccess")
    end
end