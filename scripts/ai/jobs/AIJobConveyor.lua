AIJobConveyor = {}
AIJobConveyor.START_ERROR_LIMIT_REACHED = 1
AIJobConveyor.START_ERROR_VEHICLE_DELETED = 2
AIJobConveyor.START_ERROR_NO_PERMISSION = 3
AIJobConveyor.START_ERROR_VEHICLE_IN_USE = 4
local AIJobConveyor_mt = Class(AIJobConveyor, AIJob)
function AIJobConveyor.new(isServer, customMt)
    -- upvalues: (copy) AIJobConveyor_mt
    local self = AIJob.new(isServer, customMt or AIJobConveyor_mt)
    self.conveyorTask = AITaskConveyor.new(isServer, self)
    self:addTask(self.conveyorTask)
    self.vehicleParameter = AIParameterVehicle.new()
    self:addNamedParameter("vehicle", self.vehicleParameter)
    local vehicleGroup = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleVehicle"))
    vehicleGroup:addParameter(self.vehicleParameter)
    table.insert(self.groupedParameters, vehicleGroup)
    return self
end
function AIJobConveyor:getPricePerMs()
    return 0.00005
end
function AIJobConveyor:start(farmId)
    AIJobConveyor:superClass().start(self, farmId)
    if self.isServer then
        self.vehicleParameter:getVehicle():aiJobStarted(self, self.helperIndex, farmId)
    end
end
function AIJobConveyor:stop(aiMessage)
    if self.isServer then
        self.vehicleParameter:getVehicle():aiJobFinished()
    end
    AIJobConveyor:superClass().stop(self, aiMessage)
end
function AIJobConveyor:applyCurrentState(vehicle, mission, farmId, isDirectStart)
    AIJobConveyor:superClass().applyCurrentState(self, vehicle, mission, farmId, isDirectStart)
    self.vehicleParameter:setVehicle(vehicle)
end
function AIJobConveyor:getIsAvailableForVehicle(vehicle)
    return vehicle.spec_aiConveyorBelt ~= nil and vehicle:getCanStartAIVehicle() and vehicle:getIsAIJobSupported(ClassUtil.getClassNameByObject(self))
end
function AIJobConveyor:getTitle()
    local vehicle = self.vehicleParameter:getVehicle()
    return vehicle == nil and "" or vehicle:getName()
end
function AIJobConveyor:setValues()
    self:resetTasks()
    self.conveyorTask:setVehicle(self.vehicleParameter:getVehicle())
end
function AIJobConveyor:validate(_)
    self:setParameterValid(true)
    local isValid, errorMessage = self.vehicleParameter:validate(false)
    if not isValid then
        self.vehicleParameter:setIsValid(false)
    end
    return isValid, errorMessage
end
function AIJobConveyor:getIsStartable(connection)
    if g_currentMission.aiSystem:getAILimitedReached() then
        return false, AIJobConveyor.START_ERROR_LIMIT_REACHED
    else
        local vehicle = self.vehicleParameter:getVehicle()
        if vehicle == nil then
            return false, AIJobConveyor.START_ERROR_VEHICLE_DELETED
        elseif g_currentMission:getHasPlayerPermission("hireAssistant", connection, vehicle:getOwnerFarmId()) then
            if vehicle:getIsInUse(connection) then
                return false, AIJobConveyor.START_ERROR_VEHICLE_IN_USE
            else
                return true, AIJob.START_SUCCESS
            end
        else
            return false, AIJobConveyor.START_ERROR_NO_PERMISSION
        end
    end
end
function AIJobConveyor.getIsStartErrorText(state)
    if state == AIJobConveyor.START_ERROR_LIMIT_REACHED then
        return g_i18n:getText("ai_startStateLimitReached")
    elseif state == AIJobConveyor.START_ERROR_VEHICLE_DELETED then
        return g_i18n:getText("ai_startStateVehicleDeleted")
    elseif state == AIJobConveyor.START_ERROR_NO_PERMISSION then
        return g_i18n:getText("ai_startStateNoPermission")
    elseif state == AIJobConveyor.START_ERROR_VEHICLE_IN_USE then
        return g_i18n:getText("ai_startStateVehicleInUse")
    else
        return g_i18n:getText("ai_startStateSuccess")
    end
end