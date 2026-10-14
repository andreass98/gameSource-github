ActionNPCMove = {}
ActionNPCMove.NAME = "npcMove"
local ActionNPCMove_mt = Class(ActionNPCMove)
function ActionNPCMove.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#npc", "Name of the npc", nil, true)
    schema:register(XMLValueType.BOOL, basePath .. "#reset", "If NPC should be reset", nil, false)
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#offset", "Target position of the npc (offset to rootnode or vehicle)", nil, false)
    schema:register(XMLValueType.VECTOR_ROT, basePath .. "#offsetRotation", "Target rotation of the npc (offset rotation to rootnode or vehicle)", nil, false)
    schema:register(XMLValueType.BOOL, basePath .. "#alignToTerrain", "The npc position will be aligned to the terrain", false, false)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle the npc position should be offset to", nil, false)
end
function ActionNPCMove.new(npcName, reset, vehicleName, offsetX, offsetY, offsetZ, offsetRotX, offsetRotY, offsetRotZ, _, alignToTerrain, customMt)
    -- upvalues: (copy) ActionNPCMove_mt
    local self = setmetatable({}, customMt or ActionNPCMove_mt)
    self.npcName = npcName
    self.reset = reset
    self.vehicleName = vehicleName
    self.offsetX = offsetX
    self.offsetY = offsetY
    self.offsetZ = offsetZ
    self.offsetRotX = offsetRotX
    self.offsetRotY = offsetRotY
    self.offsetRotZ = offsetRotZ
    self.alignToTerrain = alignToTerrain
    return self
end
function ActionNPCMove:run(tour, _)
    local npc = g_npcManager:getNPCByName(self.npcName)
    if npc == nil then
        return false
    end
    if self.reset then
        local spot = tour:getNPCSpot(self.npcName)
        local currentSpot = npc:getSpot()
        if currentSpot == nil or currentSpot == spot then
            spot.isAvailable = false
            npc:setSpot(nil)
        end
        return true
    end
    local spot = nil
    if self.vehicleName ~= nil then
        spot = g_guidedTourManager:getVehicleByName(self.vehicleName)
        if spot == nil then
            Logging.warning("ActionNPCMove.run: Vehicle \'%s\' not found", self.vehicleName)
            return false
        end
    end
    local currentSpot = tour:getNPCSpot(self.npcName)
    if currentSpot == nil then
        Logging.warning("ActionNPCMove.run: Cannot create spot for npc \'%s\'", self.npcName)
        return false
    end
    currentSpot.isAvailable = true
    if spot == nil then
        currentSpot.x = self.offsetX
        currentSpot.y = self.offsetY
        currentSpot.z = self.offsetZ
        currentSpot.rx = self.offsetRotX
        currentSpot.ry = self.offsetRotY
        currentSpot.rz = self.offsetRotZ
    else
        currentSpot.x, currentSpot.y, currentSpot.z = localToWorld(spot.rootNode, self.offsetX, self.offsetY, self.offsetZ)
        currentSpot.rx, currentSpot.ry, currentSpot.rz = localRotationToWorld(spot.rootNode, self.offsetRotX, self.offsetRotY, self.offsetRotZ)
    end
    if self.alignToTerrain then
        currentSpot.y = getTerrainHeightAtWorldPos(g_terrainNode, currentSpot.x, 0, currentSpot.z)
    end
    npc:setSpot(currentSpot)
    return true
end
function ActionNPCMove.createFromXML(xmlFile, key, _, _, _)
    local npcName = xmlFile:getValue(key .. "#npc")
    if npcName == nil then
        Logging.xmlWarning(xmlFile, "Missing \'npc\' for \'%s\'", key)
        return nil
    end
    local offsetX = nil
    local offsetY = nil
    local offsetZ = nil
    local offsetRotX = nil
    local offsetRotY = nil
    local offsetRotZ = nil
    local vehicleName = nil
    local alignToTerrain = nil
    local reset = xmlFile:getValue(key .. "#reset")
    if not reset then
        offsetX, offsetY, offsetZ = xmlFile:getValue(key .. "#offset")
        if offsetX == nil or (offsetY == nil or offsetZ == nil) then
            Logging.xmlWarning(xmlFile, "Missing \'offset\' for \'%s\'", key)
            return nil
        end
        offsetRotX, offsetRotY, offsetRotZ = xmlFile:getValue(key .. "#offsetRotation")
        if offsetRotX == nil or (offsetRotY == nil or offsetRotZ == nil) then
            Logging.xmlWarning(xmlFile, "Missing \'offsetRotation\' for \'%s\'", key)
            return nil
        end
        vehicleName = xmlFile:getValue(key .. "#vehicle")
        alignToTerrain = xmlFile:getValue(key .. "#alignToTerrain", false)
    end
    return ActionNPCMove.new(npcName, reset, vehicleName, offsetX, offsetY, offsetZ, offsetRotX, offsetRotY, offsetRotZ, alignToTerrain)
end
g_guidedTourManager:registerActionClass(ActionNPCMove.NAME, ActionNPCMove)