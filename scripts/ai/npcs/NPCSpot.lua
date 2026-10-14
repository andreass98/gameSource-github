NPCSpot = {}
function NPCSpot.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. "#node", "NPC spot node")
    schema:register(XMLValueType.STRING, key .. "#npcName", "NPC name")
    schema:register(XMLValueType.BOOL, key .. "#isStartSpot", "If spot is a spot at game start")
end
function NPCSpot.registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. "#uniqueId")
    schema:register(XMLValueType.STRING, key .. "#npcName")
    schema:register(XMLValueType.VECTOR_TRANS, key .. "#position")
    schema:register(XMLValueType.VECTOR_ROT, key .. "#rotation")
end
function NPCSpot.onCreate(_, nodeId)
    local spot = NPCSpot.createFromNode(nodeId)
    if spot ~= nil then
        g_npcManager:addSpot(spot)
    end
end
local NPCSpot_mt = Class(NPCSpot)
function NPCSpot.new(customMt)
    -- upvalues: (copy) NPCSpot_mt
    return setmetatable({}, customMt or NPCSpot_mt)
end
function NPCSpot:loadFromXMLFile(xmlFile, key, components, i3dMappings, uniqueId)
    local node = xmlFile:getValue(key .. "#node", nil, components, i3dMappings)
    if node == nil then
        Logging.xmlWarning(xmlFile, "No spot node defined for npc spot \'%s\'", key)
        return false
    end
    local npcName = xmlFile:getValue(key .. "#npcName")
    if npcName == nil then
        Logging.xmlWarning(xmlFile, "Missing \'npcName\' for npc spot \'%s\'", key)
        return false
    end
    local npc = g_npcManager:getNPCByName(npcName)
    if npc == nil then
        Logging.xmlWarning(xmlFile, "Used npcName \'%s\' not defined for npc spot \'%s\'", npcName, key)
        return false
    end
    self.node = node
    self.npc = npc
    self.isStartSpot = xmlFile:getValue(key .. "#isStartSpot")
    self.needsSaving = false
    self.uniqueId = uniqueId
    return true
end
function NPCSpot:delete()
    g_npcManager:removeSpot(self)
end
function NPCSpot:saveToSavegameXMLFile(xmlFile, key)
    xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
    xmlFile:setValue(key .. "#npcName", self.npc.name)
    xmlFile:setValue(key .. "#position", self.x, self.y, self.z)
    xmlFile:setValue(key .. "#rotation", self.rx, self.ry, self.rz)
end
function NPCSpot:loadFromSavegameXMLFile(xmlFile, key)
    self.uniqueId = xmlFile:getValue(key .. "#uniqueId")
    local npcName = xmlFile:getValue(key .. "#npcName")
    local npc = g_npcManager:getNPCByName(npcName)
    if npc == nil then
        Logging.xmlWarning(xmlFile, "NPC \'%s\' for spot \'%s\' not defined", npcName, key)
        return false
    end
    self.npc = npc
    self.x, self.y, self.z = xmlFile:getValue(key .. "#position")
    self.rx, self.ry, self.rz = xmlFile:getValue(key .. "#rotation")
    self.needsSaving = true
    self.isAvailable = true
    return true
end
function NPCSpot:activate()
    local placementCol = createPlaneShapeFrom2DContour("npcSpotPlacementCollision", {
        -1,
        -1,
        1,
        -1,
        1,
        1,
        -1,
        1
    }, true)
    if placementCol ~= 0 then
        setIsNonRenderable(placementCol, true)
        removeFromPhysics(placementCol)
        link(getRootNode(), placementCol)
        setWorldTranslation(placementCol, self:getPosition())
        setWorldRotation(placementCol, self:getRotation())
        setRigidBodyType(placementCol, RigidBodyType.STATIC)
        setCollisionFilterGroup(placementCol, CollisionFlag.PLACEMENT_BLOCKING)
        addToPhysics(placementCol)
        local minX, _, minZ = localToWorld(placementCol, -1, 0, -1)
        local maxX, _, maxZ = localToWorld(placementCol, 1, 0, 1)
        self.placementCollisionNode = placementCol
        self.placementCollisionArea = {
            minX,
            minZ,
            maxX,
            maxZ
        }
        g_densityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ, true)
        g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
    end
end
function NPCSpot:deactivate()
    if self.placementCollisionNode ~= nil then
        delete(self.placementCollisionNode)
        self.placementCollisionNode = nil
        local minX, minZ, maxX, maxZ = unpack(self.placementCollisionArea)
        g_densityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ, true)
        g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
    end
end
function NPCSpot:getIsAvailable()
    if self.node == nil then
        return self.isAvailable
    else
        return getVisibilityConditionEntityState(self.node)
    end
end
function NPCSpot:getPosition()
    if self.node == nil then
        return self.x, self.y, self.z
    else
        return getWorldTranslation(self.node)
    end
end
function NPCSpot:getRotation()
    if self.node == nil then
        return self.rx, self.ry, self.rz
    else
        return getWorldRotation(self.node)
    end
end
function NPCSpot:getUniqueId()
    return self.uniqueId
end
function NPCSpot.createFromNode(node)
    local npcName = getUserAttribute(node, "npcName")
    if npcName == nil then
        Logging.warning("Missing user attribute \'npcName\' for npc spot node \'%s\'", getName(node))
        return nil
    end
    local npc = g_npcManager:getNPCByName(npcName)
    if npc == nil then
        Logging.warning("Used npcName \'%s\' not defined for spot node \'%s\'", npcName, getName(node))
        return nil
    end
    local uniqueId = getUserAttribute(node, "uniqueId")
    if uniqueId == nil then
        Logging.warning("Missing user attribute \'uniqueId\' for npc spot node \'%s\'", getName(node))
        return nil
    end
    if g_npcManager:getSpotByUniqueId(uniqueId) ~= nil then
        Logging.warning("UniqueId \'%s\' already in use for npc spot node \'%s\'", uniqueId, getName(node))
        return nil
    end
    local spot = NPCSpot.new()
    spot.node = node
    spot.uniqueId = uniqueId
    spot.npc = npc
    spot.isStartSpot = getUserAttribute(node, "isStartSpot")
    spot.needsSaving = false
    return spot
end
function NPCSpot.create(uniqueId, npc, x, y, z, rx, ry, rz, needsSaving)
    local spot = NPCSpot.new()
    spot.uniqueId = uniqueId
    spot.npc = npc
    spot.x = x
    spot.y = y
    spot.z = z
    spot.rx = rx
    spot.ry = ry
    spot.rz = rz
    spot.needsSaving = needsSaving
    return spot
end