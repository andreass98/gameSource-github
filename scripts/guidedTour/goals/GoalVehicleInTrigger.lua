GoalVehicleInTrigger = {}
GoalVehicleInTrigger.NAME = "vehicleInTrigger"
local GoalVehicleInTrigger_mt = Class(GoalVehicleInTrigger)
function GoalVehicleInTrigger.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.VECTOR_2, basePath .. "#worldPosition", "World position of trigger. X and Z values only", nil, true)
    schema:register(XMLValueType.FLOAT, basePath .. "#worldPositionY", "World y position. If defined the y position will not be calculated based on the terrain", nil, false)
    schema:register(XMLValueType.ANGLE, basePath .. "#worldRotationY", "World rotation y", nil, false)
    schema:register(XMLValueType.FLOAT, basePath .. "#radius", "Trigger distance", 2, false)
    schema:register(XMLValueType.FLOAT, basePath .. "#height", "Trigger height", 10, false)
    schema:register(XMLValueType.BOOL, basePath .. "#showMarker", "Show navigation marker", true, false)
    schema:register(XMLValueType.FLOAT, basePath .. "#terrainOffsetY", "Navigation marker terrain offset", 0, false)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
end
function GoalVehicleInTrigger.new(vehicleName, worldPosX, worldPosY, worldPosZ, radius, height, worldRotY, showMarker, terrainOffsetY, customMt)
    -- upvalues: (copy) GoalVehicleInTrigger_mt
    local self = setmetatable({}, customMt or GoalVehicleInTrigger_mt)
    self.vehicleName = vehicleName
    self.worldPosX = worldPosX
    self.worldPosY = worldPosY
    self.worldPosZ = worldPosZ
    self.worldRotY = worldRotY
    self.radius = radius
    self.height = height or 10
    self.showMarker = showMarker
    self.terrainOffsetY = terrainOffsetY or 0
    return self
end
function GoalVehicleInTrigger:activate(_, _)
    self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if self.vehicle == nil then
        Logging.warning("GoalVehicleInTrigger.activate: Vehicle \'%s\' not found", self.vehicleName)
    else
        if self.worldPosY == nil then
            self.worldPosY = getTerrainHeightAtWorldPos(g_terrainNode, self.worldPosX, 0, self.worldPosZ)
        end
        if self.showMarker then
            local dirX = nil
            local dirY = nil
            local dirZ = nil
            if self.worldRotY ~= nil then
                local dirX, dirZ = MathUtil.getDirectionFromYRotation(self.worldRotY)
                dirX, dirY, dirZ = MathUtil.vector3Normalize(dirX, 0, dirZ)
            end
            g_currentMission.navigationSystem:navigateTo(self.worldPosX, self.worldPosY, self.worldPosZ, dirX, dirY, dirZ)
            self.mapHotspot = TourHotspot.new()
            g_currentMission:addMapHotspot(self.mapHotspot)
            self.mapHotspot:setWorldPosition(self.worldPosX, self.worldPosZ)
        end
    end
end
function GoalVehicleInTrigger:deactivate()
    if self.showMarker then
        g_currentMission.navigationSystem:stop()
        g_currentMission:removeMapHotspot(self.mapHotspot)
        self.mapHotspot:delete()
    end
    self.vehicle = nil
end
function GoalVehicleInTrigger:isAchieved()
    if self.vehicle == nil then
        return true
    end
    self.isVehicleInRange = false
    overlapCylinder(self.worldPosX, self.worldPosY + self.height * 0.5, self.worldPosZ, self.radius, self.height, Axis.Y, "onVehicleCallback", self, CollisionFlag.VEHICLE, true, true, false, false)
    return self.isVehicleInRange
end
function GoalVehicleInTrigger:onVehicleCallback(transformId)
    if transformId ~= 0 and g_currentMission:getNodeObject(transformId) == self.vehicle then
        self.isVehicleInRange = true
    end
end
function GoalVehicleInTrigger.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    if vehicleName == nil then
        Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
        return nil
    end
    local worldPosX, worldPosZ = xmlFile:getValue(key .. "#worldPosition")
    if worldPosX == nil or worldPosZ == nil then
        Logging.xmlWarning(xmlFile, "Missing \'worldPosition\' for \'%s\'", key)
        return nil
    end
    local worldPosY = xmlFile:getValue(key .. "#worldPositionY")
    local worldRotY = xmlFile:getValue(key .. "#worldRotationY")
    local radius = xmlFile:getValue(key .. "#radius", 2)
    local height = xmlFile:getValue(key .. "#height", 10)
    local showMarker = xmlFile:getValue(key .. "#showMarker", true)
    local terrainOffsetY = xmlFile:getValue(key .. "#terrainOffsetY", 0)
    return GoalVehicleInTrigger.new(vehicleName, worldPosX, worldPosY, worldPosZ, radius, height, worldRotY, showMarker, terrainOffsetY)
end
g_guidedTourManager:registerGoalClass(GoalVehicleInTrigger.NAME, GoalVehicleInTrigger)