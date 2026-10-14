GoalPlayerInTrigger = {}
GoalPlayerInTrigger.NAME = "playerInTrigger"
local GoalPlayerInTrigger_mt = Class(GoalPlayerInTrigger)
function GoalPlayerInTrigger.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.VECTOR_2, basePath .. "#offset", "If vehicle is given offset is local to vehicle rootnode, else world positions are assumed. X and Z values only", nil, true)
    schema:register(XMLValueType.FLOAT, basePath .. "#offsetY", "Local y offset if vehicle is given, else terrain offset", 0, false)
    schema:register(XMLValueType.FLOAT, basePath .. "#radius", "Trigger distance", 2, false)
    schema:register(XMLValueType.BOOL, basePath .. "#showMarker", "Show navigation marker", true, false)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle the position should be offset to", nil, false)
    schema:register(XMLValueType.STRING, basePath .. "#npc", "Name of the npc the position should be offset to", nil, false)
end
function GoalPlayerInTrigger.new(vehicleName, npcName, offsetX, offsetY, offsetZ, radius, showMarker, customMt)
    -- upvalues: (copy) GoalPlayerInTrigger_mt
    local self = setmetatable({}, customMt or GoalPlayerInTrigger_mt)
    self.vehicleName = vehicleName
    self.npcName = npcName
    self.offsetX = offsetX
    self.offsetY = offsetY or 0
    self.offsetZ = offsetZ
    self.radius = radius
    self.height = 5
    self.axis = Axis.Y
    self.showMarker = showMarker
    return self
end
function GoalPlayerInTrigger:update(_)
    self:updateTarget()
end
function GoalPlayerInTrigger:updateTarget()
    local needUpdate = false
    if self.vehicle == nil then
        if self.npc ~= nil then
            self.worldPosX, self.worldPosY, self.worldPosZ = self.npc:getPositionOffset(self.offsetX, self.offsetY, self.offsetZ)
            needUpdate = true
        end
    else
        self.worldPosX, self.worldPosY, self.worldPosZ = localToWorld(self.vehicle.rootNode, self.offsetX, self.offsetY, self.offsetZ)
        needUpdate = true
    end
    if self.showMarker and needUpdate then
        g_currentMission.navigationSystem:navigateTo(self.worldPosX, self.worldPosY, self.worldPosZ)
        self.mapHotspot:setWorldPosition(self.worldPosX, self.worldPosZ)
    end
end
function GoalPlayerInTrigger:activate(_, _)
    if self.vehicleName == nil then
        if self.npcName == nil then
            self.worldPosX = self.offsetX
            self.worldPosZ = self.offsetZ
            self.worldPosY = getTerrainHeightAtWorldPos(g_terrainNode, self.worldPosX, 0, self.worldPosZ) + self.offsetY
        else
            self.npc = g_npcManager:getNPCByName(self.npcName)
            if self.npc == nil then
                Logging.warning("GoalPlayerInTrigger.activate: NPC \'%s\' not found", self.npcName)
                return
            end
            self.worldPosX, self.worldPosY, self.worldPosZ = self.npc:getPositionOffset(self.offsetX, self.offsetY, self.offsetZ)
        end
    else
        self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
        if self.vehicle == nil then
            Logging.warning("GoalPlayerInTrigger.activate: Vehicle \'%s\' not found", self.vehicleName)
            return
        end
        self.worldPosX, self.worldPosY, self.worldPosZ = localToWorld(self.vehicle.rootNode, self.offsetX, self.offsetY, self.offsetZ)
    end
    if self.showMarker then
        g_currentMission.navigationSystem:navigateTo(self.worldPosX, self.worldPosY, self.worldPosZ)
        self.mapHotspot = TourHotspot.new()
        g_currentMission:addMapHotspot(self.mapHotspot)
        self.mapHotspot:setWorldPosition(self.worldPosX, self.worldPosZ)
    end
end
function GoalPlayerInTrigger:deactivate()
    if self.showMarker then
        g_currentMission.navigationSystem:stop()
        g_currentMission:removeMapHotspot(self.mapHotspot)
        self.mapHotspot:delete()
        self.mapHotspot = nil
    end
    self.vehicle = nil
    self.npc = nil
end
function GoalPlayerInTrigger:isAchieved()
    if self.vehicleName ~= nil and self.vehicle == nil then
        return true
    end
    self.isPlayerInRange = false
    overlapCylinder(self.worldPosX, self.worldPosY + self.height * 0.5, self.worldPosZ, self.radius, self.height, self.axis, "onPlayerCallback", self, CollisionFlag.PLAYER, true, true, false, false)
    return self.isPlayerInRange
end
function GoalPlayerInTrigger:onPlayerCallback(transformId)
    if transformId ~= 0 and transformId == g_localPlayer.rootNode then
        self.isPlayerInRange = true
    end
end
function GoalPlayerInTrigger.createFromXML(xmlFile, key, _, _)
    local offsetX, offsetZ = xmlFile:getValue(key .. "#offset")
    if offsetX == nil or offsetZ == nil then
        Logging.xmlWarning(xmlFile, "Missing \'offset\' for \'%s\'", key)
        return nil
    end
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    local npcName = xmlFile:getValue(key .. "#npc")
    local radius = xmlFile:getValue(key .. "#radius", 2)
    local showMarker = xmlFile:getValue(key .. "#showMarker", true)
    local offsetY = xmlFile:getValue(key .. "#offsetY", 0)
    return GoalPlayerInTrigger.new(vehicleName, npcName, offsetX, offsetY, offsetZ, radius, showMarker)
end
g_guidedTourManager:registerGoalClass(GoalPlayerInTrigger.NAME, GoalPlayerInTrigger)