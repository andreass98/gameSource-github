ActionVehicleReset = {}
ActionVehicleReset.NAME = "vehicleReset"
local ActionVehicleReset_mt = Class(ActionVehicleReset)
function ActionVehicleReset.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
    schema:register(XMLValueType.STRING, basePath .. "#targetVehicle", "Name of the target vehicle", nil, false)
    schema:register(XMLValueType.VECTOR_2, basePath .. "#offset", "Offset of the vehicle to the target vehicle", nil, false)
    schema:register(XMLValueType.VECTOR_2, basePath .. "#worldPosition", "Reset position of the vehicle", nil, false)
    schema:register(XMLValueType.ANGLE, basePath .. "#rotationY", "Y-rotation of the vehicle", 0, false)
end
function ActionVehicleReset.new(vehicleName, worldX, worldZ, rotationY, targetVehicleName, offsetX, offsetZ, customMt)
    -- upvalues: (copy) ActionVehicleReset_mt
    local self = setmetatable({}, customMt or ActionVehicleReset_mt)
    self.vehicleName = vehicleName
    self.worldX = worldX
    self.worldZ = worldZ
    self.rotationY = rotationY
    self.targetVehicleName = targetVehicleName
    self.offsetX = offsetX
    self.offsetZ = offsetZ
    return self
end
function ActionVehicleReset:run(_, _)
    local vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if vehicle == nil then
        Logging.warning("ActionVehicleReset.run: Vehicle \'%s\' not found", self.vehicleName)
    end
    local posX = self.worldX
    local posZ = self.worldZ
    local rotY = self.rotationY
    if self.targetVehicleName ~= nil then
        local targetVehicle = g_guidedTourManager:getVehicleByName(self.targetVehicleName)
        if targetVehicle == nil then
            Logging.warning("ActionVehicleReset.run: Target vehicle \'%s\' not found", self.targetVehicleName)
            return true
        end
        posX, _, posZ = localToWorld(targetVehicle.rootNode, self.offsetX or 0, 0, self.offsetZ or 0)
        _, rotY, _ = localRotationToWorld(targetVehicle.rootNode, 0, self.rotationY, 0)
    end
    if posX == nil then
        Logging.warning("ActionVehicleReset.run: No position to reset defined for target vehicle \'%s\'", self.vehicleName)
        return true
    else
        g_currentMission:teleportVehicle(vehicle, posX, posZ, rotY)
        return true
    end
end
function ActionVehicleReset.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    local worldPosX, worldPosZ = xmlFile:getValue(key .. "#worldPosition")
    local rotationY = xmlFile:getValue(key .. "#rotationY", 0)
    local targetVehicleName = xmlFile:getValue(key .. "#targetVehicle")
    local offsetX, offsetZ = xmlFile:getValue(key .. "#offset")
    if vehicleName == nil then
        Logging.warning("ActionVehicleReset.createFromXML: No vehicle defined", vehicleName)
        return nil
    else
        if targetVehicleName == nil then
            if worldPosX == nil or worldPosZ == nil then
                Logging.warning("ActionVehicleReset.createFromXML: No world postion given to reset vehicle \'%s\'", vehicleName)
                return nil
            end
        elseif offsetX == nil or offsetZ == nil then
            Logging.warning("ActionVehicleReset.createFromXML: No offset given for targetVehicle \'%s\'", targetVehicleName)
            return nil
        end
        return ActionVehicleReset.new(vehicleName, worldPosX, worldPosZ, rotationY, targetVehicleName, offsetX, offsetZ)
    end
end
g_guidedTourManager:registerActionClass(ActionVehicleReset.NAME, ActionVehicleReset)