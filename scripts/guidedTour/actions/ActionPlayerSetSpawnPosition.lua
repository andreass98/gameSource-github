ActionPlayerSetSpawnPosition = {}
ActionPlayerSetSpawnPosition.NAME = "playerSetSpawnPosition"
local ActionPlayerSetSpawnPosition_mt = Class(ActionPlayerSetSpawnPosition)
function ActionPlayerSetSpawnPosition.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#worldPosition", "Target position of the npc", nil, false)
    schema:register(XMLValueType.ANGLE, basePath .. "#yaw", "The yaw of the player", nil, false)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "The spawn vehicle", nil, false)
    schema:register(XMLValueType.BOOL, basePath .. "#reset", "If true current settings will be reset", nil, false)
end
function ActionPlayerSetSpawnPosition.new(worldPosX, worldPosY, worldPosZ, yaw, vehicleName, customMt)
    -- upvalues: (copy) ActionPlayerSetSpawnPosition_mt
    local self = setmetatable({}, customMt or ActionPlayerSetSpawnPosition_mt)
    self.worldPosX = worldPosX
    self.worldPosY = worldPosY
    self.worldPosZ = worldPosZ
    self.yaw = yaw
    self.vehicleName = vehicleName
    return self
end
function ActionPlayerSetSpawnPosition:run(_, _)
    local player = g_localPlayer
    player:setSpawnPosition(nil, nil, nil)
    player:setSpawnYaw(nil)
    player:setSpawnVehicle(nil)
    if self.worldPosX == nil then
        if self.vehicleName ~= nil then
            local vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
            if vehicle == nil then
                Logging.warning("ActionPlayerSetSpawnPosition.run: Vehicle \'%s\' not found", self.vehicleName)
                return false
            end
            player:setSpawnVehicle(vehicle)
        end
    else
        player:setSpawnPosition(self.worldPosX, self.worldPosY, self.worldPosZ)
        player:setSpawnYaw(self.yaw)
    end
    return true
end
function ActionPlayerSetSpawnPosition.createFromXML(xmlFile, key, _, _)
    local worldPosX, worldPosY, worldPosZ = xmlFile:getValue(key .. "#worldPosition")
    local yaw = xmlFile:getValue(key .. "#yaw")
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    return ActionPlayerSetSpawnPosition.new(worldPosX, worldPosY, worldPosZ, yaw, vehicleName)
end
g_guidedTourManager:registerActionClass(ActionPlayerSetSpawnPosition.NAME, ActionPlayerSetSpawnPosition)