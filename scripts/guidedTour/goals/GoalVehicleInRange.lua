GoalVehicleInRange = {}
GoalVehicleInRange.NAME = "vehicleInRange"
local GoalVehicleInRange_mt = Class(GoalVehicleInRange)
function GoalVehicleInRange.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
    schema:register(XMLValueType.STRING, basePath .. "#targetVehicle", "Name of the target vehicle", nil, true)
    schema:register(XMLValueType.VECTOR_2, basePath .. "#offset", "Offset from target vehicle", nil, true)
    schema:register(XMLValueType.FLOAT, basePath .. "#radius", "Trigger distance", 2, false)
    schema:register(XMLValueType.FLOAT, basePath .. "#height", "Trigger height", 10, false)
    schema:register(XMLValueType.BOOL, basePath .. "#showMarker", "Show navigation marker", true, false)
    schema:register(XMLValueType.INT, basePath .. "#exactFillRootNodeIndex", "Index of the fill rootnode", nil, false)
end
function GoalVehicleInRange.new(vehicleName, targetVehicleName, offsetX, offsetZ, radius, height, showMarker, exactFillRootNodeIndex, customMt)
    -- upvalues: (copy) GoalVehicleInRange_mt
    local self = setmetatable({}, customMt or GoalVehicleInRange_mt)
    self.vehicleName = vehicleName
    self.targetVehicleName = targetVehicleName
    self.offsetX = offsetX
    self.offsetZ = offsetZ
    self.radius = radius
    self.height = height or 10
    self.showMarker = showMarker
    self.exactFillRootNodeIndex = exactFillRootNodeIndex
    return self
end
function GoalVehicleInRange:activate(_, _)
    self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if self.vehicle == nil then
        Logging.warning("GoalVehicleInRange.activate: Vehicle \'%s\' not found", self.vehicleName)
        return
    else
        self.targetVehicle = g_guidedTourManager:getVehicleByName(self.targetVehicleName)
        if self.targetVehicle == nil then
            Logging.warning("GoalVehicleInRange.activate: Target vehicle \'%s\' not found", self.targetVehicleName)
        end
    end
end
function GoalVehicleInRange:deactivate()
    if self.showMarker then
        g_currentMission.navigationSystem:stop()
    end
    self.vehicle = nil
    self.targetVehicle = nil
end
function GoalVehicleInRange:isAchieved()
    if self.vehicle == nil or self.targetVehicle == nil then
        return true
    end
    local x, y, z = localToWorld(self.targetVehicle.rootNode, self.offsetX, 0, self.offsetZ)
    local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
    local dirX, _, dirZ = localDirectionToWorld(self.targetVehicle.rootNode, 0, 0, 1)
    if self.showMarker then
        local dirX, dirY, dirZ = MathUtil.vector3Normalize(dirX, 0, dirZ)
        g_currentMission.navigationSystem:navigateTo(x, y, z, dirX, dirY, dirZ)
    end
    local y = y + self.height * 0.5
    local dirY = CollisionFlag.VEHICLE
    if self.exactFillRootNodeIndex ~= nil then
        dirY = CollisionFlag.FILLABLE
    end
    self.isVehicleInRange = false
    overlapCylinder(x, y, z, self.radius, self.height, Axis.Y, "onVehicleCallback", self, dirY, true, true, false, false)
    return self.isVehicleInRange
end
function GoalVehicleInRange:onVehicleCallback(hitActorId, _)
    if hitActorId ~= 0 and g_currentMission:getNodeObject(hitActorId) == self.vehicle then
        self.isVehicleInRange = true
    end
end
function GoalVehicleInRange.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    if vehicleName == nil then
        Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
        return nil
    end
    local targetVehicleName = xmlFile:getValue(key .. "#targetVehicle")
    if targetVehicleName == nil then
        Logging.xmlWarning(xmlFile, "Missing target vehicle for \'%s\'", key)
        return nil
    end
    local offsetX, offsetZ = xmlFile:getValue(key .. "#offset")
    if offsetX == nil or offsetZ == nil then
        Logging.xmlWarning(xmlFile, "Missing \'offset\' for \'%s\'", key)
        return nil
    end
    local radius = xmlFile:getValue(key .. "#radius", 2)
    local height = xmlFile:getValue(key .. "#height", 10)
    local showMarker = xmlFile:getValue(key .. "#showMarker", true)
    local exactFillRootNodeIndex = xmlFile:getValue(key .. "#exactFillRootNodeIndex")
    return GoalVehicleInRange.new(vehicleName, targetVehicleName, offsetX, offsetZ, radius, height, showMarker, exactFillRootNodeIndex)
end
g_guidedTourManager:registerGoalClass(GoalVehicleInRange.NAME, GoalVehicleInRange)