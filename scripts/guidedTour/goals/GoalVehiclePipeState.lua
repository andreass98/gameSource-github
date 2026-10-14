GoalVehiclePipeState = {}
GoalVehiclePipeState.NAME = "vehiclePipeState"
local GoalVehiclePipeState_mt = Class(GoalVehiclePipeState)
function GoalVehiclePipeState.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
    schema:register(XMLValueType.INT, basePath .. "#pipeState", "Target pipe state value", nil, true)
end
function GoalVehiclePipeState.new(vehicleName, pipeState, customMt)
    -- upvalues: (copy) GoalVehiclePipeState_mt
    local self = setmetatable({}, customMt or GoalVehiclePipeState_mt)
    self.vehicleName = vehicleName
    self.pipeState = pipeState
    return self
end
function GoalVehiclePipeState:activate(_, _)
    self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if self.vehicle == nil then
        Logging.warning("GoalVehiclePipeState.activate: Vehicle \'%s\' not found", self.vehicleName)
        return
    elseif self.vehicle.getCurrentPipeState == nil then
        self.vehicle = nil
        Logging.warning("GoalVehiclePipeState.activate: Vehicle \'%s\' pipe cannot be unfolded", self.vehicleName)
    end
end
function GoalVehiclePipeState:deactivate()
    self.vehicle = nil
end
function GoalVehiclePipeState:isAchieved()
    if self.vehicle == nil then
        return true
    end
    return self.vehicle:getCurrentPipeState() == self.pipeState
end
function GoalVehiclePipeState.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    if vehicleName == nil then
        Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
        return nil
    end
    local pipeState = xmlFile:getValue(key .. "#pipeState")
    if pipeState ~= nil then
        return GoalVehiclePipeState.new(vehicleName, pipeState)
    end
    Logging.xmlWarning(xmlFile, "Missing \'pipeState\' for \'%s\'", key)
    return nil
end
g_guidedTourManager:registerGoalClass(GoalVehiclePipeState.NAME, GoalVehiclePipeState)