DestructibleMapObjectSystem = {}
DestructibleMapObjectSystem.GROUP_ID_NUM_BITS = 8
DestructibleMapObjectSystem.MAX_GORUP_ID = 2 ^ DestructibleMapObjectSystem.GROUP_ID_NUM_BITS - 1
DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS = 9
DestructibleMapObjectSystem.MAX_CHILD_INDEX = 2 ^ DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS - 1
DestructibleMapObjectSystem.ERROR_WRONG_DESTRUCTIBLE_TYPE = 0
local DestructibleMapObjectSystem_mt = Class(DestructibleMapObjectSystem)
g_xmlManager:addCreateSchemaFunction(function()
    DestructibleMapObjectSystem.xmlSchemaSavegame = XMLSchema.new("destructibleMapObjects_savegame")
end)
g_xmlManager:addInitSchemaFunction(function()
    local schema = DestructibleMapObjectSystem.xmlSchemaSavegame
    schema:register(XMLValueType.INT, "destructibleMapObjects.group(?)#id", "Group id defined as user attribute in map")
    schema:register(XMLValueType.INT, "destructibleMapObjects.group(?).item(?)#index", "I3d child index of destroyed object in group")
end)
function DestructibleMapObjectSystem.onCreateGroup(_, node)
    g_currentMission.destructibleMapObjectSystem:addGroup(node)
end
function DestructibleMapObjectSystem.new(mission, isServer, customMt)
    -- upvalues: (copy) DestructibleMapObjectSystem_mt
    local self = setmetatable({}, customMt or DestructibleMapObjectSystem_mt)
    self.mission = mission
    self.isServer = isServer
    self.groups = {}
    self.groupIdToGroupRoot = {}
    self.destructibleTypes = {}
    self.nodeToDestructible = {}
    self.destructibleToGroup = {}
    self.destructibleDamage = {}
    self.destructibleToRigidBodies = {}
    self.destructibleDestroyedListeners = {}
    self.activeDestructionAnimations = {}
    self.activeDestructionAnimationsToDelete = {}
    addConsoleCommand("gsDestructibleObjectsDebug", "Toggle DestructibleMapObjectSystem debug", "consoleCommandToggleDebug", self)
    if self.isServer then
        addConsoleCommand("gsDestructibleObjectsDamageAdd", "Add damage to destructible object camera is pointed at", "consoleCommandNodeAddDamage", self)
    end
    return self
end
function DestructibleMapObjectSystem:delete()
    g_currentMission:removeUpdateable(self)
    removeConsoleCommand("gsDestructibleObjectsDebug")
    removeConsoleCommand("gsDestructibleObjectsDestroy")
end
function DestructibleMapObjectSystem:onClientJoined(connection)
    for groupRoot, group in pairs(self.groups) do
        local childIndices = {}
        local childIndex = 0
        for childIndex = childIndex, getNumOfChildren(groupRoot) - 1 do
            childIndices[childIndex + 1] = not getVisibility(getChildAt(groupRoot, childIndex))
        end
        connection:sendEvent(DestroyedMapObjectsEvent.new(group.groupId, childIndices))
    end
end
function DestructibleMapObjectSystem:addGroup(groupRootNode)
    local destructibleType = getUserAttribute(groupRootNode, "destructibleType")
    if destructibleType == nil then
        Logging.error("Missing userAttribute \'destructibleType\' for \'%s\'", I3DUtil.getNodePath(groupRootNode));
        (function()
            print("Supported userAttributes next to DestructibleMapObjectSystem.onCreate")
            printf("    \'destructibleType\'           (string)  (required) - string used to differentiate between different types of objects, e.g. used for which tools can work on them")
            printf("    \'groupId\'                    (integer) (required if more than one group exists) default: 0; allowed values: 0 - %d)", DestructibleMapObjectSystem.MAX_GORUP_ID)
            printf("    \'dropFillTypeName\'           (string)  (optional) default: nil - fillTypeName of tipAny dropped upon destruction")
            printf("    \'dropAmount\'                 (float)   (optional) default: 500 - amount of tipAny dropped upon destruction")
            printf("    \'destructionVolume\'          (float)   (optional) default: 50 - destruction amount trequired to destroy the object")
            printf("    \'animDurationScrollPosition\' (float)   (optional) default: 2 - duration for destruction animation shader parameter scrollPosition in seconds")
            printf("    \'animDurationHideByIndex\'    (float)   (optional) default: 1 - duration for destruction animation shader parameter hideByIndex in seconds")
            printf("    \'animDelayHideByIndex\'       (float)   (optional) default: 0.75 * animDurationScrollPosition - delay for start of hideByIndex animation in seconds")
        end)()
        return false
    end
    local dropFillTypeName = tonumber(getUserAttribute(groupRootNode, "groupId")) or 0
    local groupId = math.floor(dropFillTypeName)
    if groupId < 0 or DestructibleMapObjectSystem.MAX_GORUP_ID < groupId then
        Logging.error("GroupId \'%d\' for %s out of allowed rage [0 %d]", groupId, I3DUtil.getNodePath(groupRootNode), DestructibleMapObjectSystem.MAX_GORUP_ID)
        return false
    end
    if self.groupIdToGroupRoot[groupId] ~= nil then
        Logging.error("GroupId \'%d\' of \'%s\' already in use in \'%s\'. Please use a different groupId", groupId, I3DUtil.getNodePath(groupRootNode), I3DUtil.getNodePath(self.groupIdToGroupRoot[groupId]))
        printUserAttributeInterface()
        return false
    end
    local dropFillTypeName = getUserAttribute(groupRootNode, "dropFillTypeName") or destructibleType
    local dropFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(dropFillTypeName)
    local destructionVolume = getUserAttribute(groupRootNode, "destructionVolume") or 50
    local animDurationScrollPositionSec = getUserAttribute(groupRootNode, "animDurationScrollPosition") or 2
    local animDurationHideByIndexSec = getUserAttribute(groupRootNode, "animDurationHideByIndex") or 2
    local animDelayHideByIndexSec = getUserAttribute(groupRootNode, "animDelayHideByIndex") or 0.75 * animDurationScrollPositionSec
    local group = {
        ["destructibleType"] = string.upper(destructibleType),
        ["groupId"] = groupId,
        ["dropFillTypeIndex"] = dropFillTypeIndex,
        ["dropAmount"] = getUserAttribute(groupRootNode, "dropAmount") or 500,
        ["destructionVolume"] = destructionVolume,
        ["animDurationScrollPosition"] = animDurationScrollPositionSec * 1000,
        ["animDurationHideByIndex"] = animDurationHideByIndexSec * 1000,
        ["animDelayHideByIndex"] = animDelayHideByIndexSec * 1000
    }
    self.groupIdToGroupRoot[groupId] = groupRootNode
    self.groups[groupRootNode] = group
    if self.destructibleTypes[destructibleType] == nil then
        self.destructibleTypes[destructibleType] = {}
    end
    self.destructibleTypes[destructibleType][group] = true
    local numChildren = getNumOfChildren(groupRootNode)
    if DestructibleMapObjectSystem.MAX_CHILD_INDEX < numChildren then
        Logging.warning("Only %d child nodes supported per group, group has %d. Ignoring additional children for \'%s\'", DestructibleMapObjectSystem.MAX_CHILD_INDEX + 1, numChildren, I3DUtil.getNodePath(groupRootNode))
    end
    local childIndex = 0
    for childIndex = childIndex, numChildren - 1 do
        local childNode = getChildAt(groupRootNode, childIndex)
        local hasCol = false
        I3DUtil.iterateRecursively(childNode, function(node)
            -- upvalues: (copy) childNode, (copy) self, (copy) group, (ref) hasCol
            if getRigidBodyType(node) ~= RigidBodyType.NONE then
                self.nodeToDestructible[node] = childNode
                self.destructibleToGroup[childNode] = group
                self.destructibleToRigidBodies[childNode] = self.destructibleToRigidBodies[childNode] or {}
                table.insert(self.destructibleToRigidBodies[childNode], node)
                hasCol = true
            end
            return true
        end, true)
        if not hasCol then
            Logging.warning("Child %d (%s) of group \'%s\' has no collision mesh in any of its children and will not be destroyable ingame", childIndex, getName(childNode), I3DUtil.getNodePath(groupRootNode))
        end
    end
    return true
end
function DestructibleMapObjectSystem:registerDestructibleDestroyedListener(target, func)
    self.destructibleDestroyedListeners[target] = func
end
function DestructibleMapObjectSystem:unregisterDestructibleDestroyedListener(target)
    self.destructibleDestroyedListeners[target] = nil
end
function DestructibleMapObjectSystem:getDestructibleFromNode(nodeId, destructibleTypes)
    local destructible = self.nodeToDestructible[nodeId]
    if destructible and destructibleTypes ~= nil then
        local group = self.destructibleToGroup[destructible]
        if group == nil or not destructibleTypes[group.destructibleType] then
            return nil, DestructibleMapObjectSystem.ERROR_WRONG_DESTRUCTIBLE_TYPE
        else
            return destructible
        end
    else
        return destructible
    end
end
function DestructibleMapObjectSystem:getGroupAndIndexForDestructible(destructible)
    return self.destructibleToGroup[destructible], getChildIndex(destructible)
end
function DestructibleMapObjectSystem:getGroupRootById(groupId)
    return self.groupIdToGroupRoot[groupId]
end
function DestructibleMapObjectSystem:getDestructibleRigidBodies(destructible)
    return self.destructibleToRigidBodies[destructible]
end
function DestructibleMapObjectSystem:addDestructibleDamage(destructible, damage)
    local group = self.destructibleToGroup[destructible]
    if group == nil then
        return nil
    end
    local totalDamage = math.max(0, (self.destructibleDamage[destructible] or 0) + damage)
    if group.destructionVolume <= totalDamage then
        if self.isServer then
            self:destroyDestructible(destructible, true)
            return 1, group.destructionVolume
        end
    else
        self.destructibleDamage[destructible] = totalDamage
    end
    return totalDamage / group.destructionVolume, totalDamage
end
function DestructibleMapObjectSystem:setDestructiblePhysicsActive(destructible, isActive)
    local bvRadius = nil
    local rigidBodies = self.destructibleToRigidBodies[destructible]
    if rigidBodies ~= nil then
        for _, rigidBody in ipairs(rigidBodies) do
            if isActive then
                addToPhysics(rigidBody)
            else
                removeFromPhysics(rigidBody)
            end
            local lx, ly, lz
            lx, ly, lz, bvRadius = getShapeBoundingSphere(rigidBody)
            local wx, _, wz = localToWorld(rigidBody, lx, ly, lz)
            local minX = wx - bvRadius
            local maxX = wx + bvRadius
            local minZ = wz - bvRadius
            local maxZ = wz + bvRadius
            g_densityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ, true)
            self.mission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
        end
    end
    return bvRadius
end
function DestructibleMapObjectSystem:restoreDestructible(destructible)
    local rigidBodies = self.destructibleToRigidBodies[destructible]
    if rigidBodies ~= nil then
        for _, rigidBody in ipairs(rigidBodies) do
            local _, _, _, bvRadius = getShapeBoundingSphere(rigidBody)
            local wx, _, wz = getWorldTranslation(rigidBody)
            local circle = DensityMapCircle.createCircle(wx, wz, bvRadius, 8)
            DensityMapHeightUtil.clear(circle)
        end
    end
    I3DUtil.setShaderParameterRec(destructible, "scrollPos", 0, nil, nil, nil)
    I3DUtil.setShaderParameterRec(destructible, "prevScrollPos", 0, nil, nil, nil)
    I3DUtil.setShaderParameterRec(destructible, "hidePieces", 0, nil, nil, nil)
    self:setDestructiblePhysicsActive(destructible, true)
    setVisibility(destructible, true)
    self.destructibleDamage[destructible] = nil
end
function DestructibleMapObjectSystem:destroyDestructible(destructible, dropTipAny)
    local bvRadius = self:setDestructiblePhysicsActive(destructible, false)
    if dropTipAny then
        local group = self.destructibleToGroup[destructible]
        if group.dropFillTypeIndex ~= nil and group.dropAmount > 0 then
            local wx, wy, wz = getWorldTranslation(destructible)
            local halfWidth = bvRadius / 2
            local lsx, lsy, lsz, lex, ley, lez, radius = DensityMapHeightUtil.getLineByAreaDimensions(wx - halfWidth, wy, wz - halfWidth, wx - halfWidth, wy, wz + halfWidth, wx + halfWidth, wy, wz - halfWidth, false)
            DensityMapHeightUtil.tipToGroundAroundLine(nil, group.dropAmount, group.dropFillTypeIndex, lsx, lsy, lsz, lex, ley, lez, radius, nil, nil, nil, nil)
        end
    end
    if g_server ~= nil then
        local group = self.destructibleToGroup[destructible]
        if group ~= nil then
            local wx = getChildIndex(destructible)
            g_server:broadcastEvent(MapObjectDestroyedEvent.new(group.groupId, wx))
        end
    end
    for wz, halfWidth in pairs(self.destructibleDestroyedListeners) do
        halfWidth(wz, destructible)
    end
    if I3DUtil.getHasShaderParameterRec(destructible, "hidePieces") or I3DUtil.getHasShaderParameterRec(destructible, "scrollPos") then
        if self.activeDestructionAnimations[destructible] == nil then
            self.activeDestructionAnimations[destructible] = 0
            g_currentMission:addUpdateable(self)
            return
        end
    else
        self:setDestructibleDestroyed(destructible, false)
    end
end
function DestructibleMapObjectSystem:setDestructibleDestroyed(destructible, updatePhysics)
    if updatePhysics then
        self:setDestructiblePhysicsActive(destructible, false)
    end
    setVisibility(destructible, false)
    self.destructibleDamage[destructible] = nil
end
function DestructibleMapObjectSystem:setGroupChildIndexDestroyed(groupId, childIndex, dropTipAny, playAnimation)
    local groupRoot = self.groupIdToGroupRoot[groupId]
    if groupRoot == nil then
        Logging.error("DestructibleMapObjectSystem: Unable to get groupRoot for group id \'%s\'", groupId)
    end
    self:setChildIndexDestroyed(groupRoot, childIndex, dropTipAny, playAnimation)
end
function DestructibleMapObjectSystem:setChildIndexDestroyed(groupRoot, childIndex, dropTipAny, playAnimation)
    if getNumOfChildren(groupRoot) < childIndex then
        Logging.warning("DestructibleMapObjectSystem: Unable to set state on child index %d, group %d at \'%s\' only has %d children", childIndex, self.groups[groupRoot].groupId, I3DUtil.getNodePath(groupRoot), getNumOfChildren(groupRoot))
        return
    else
        local group = getChildAt(groupRoot, childIndex)
        if playAnimation then
            self:destroyDestructible(group, dropTipAny)
        else
            self:setDestructibleDestroyed(group, true)
        end
    end
end
function DestructibleMapObjectSystem.getDestructedChildIndices(_, groupRoot)
    local destructedChildIndices = {}
    local childIndex = 0
    for childIndex = childIndex, getNumOfChildren(groupRoot) - 1 do
        if not getVisibility(getChildAt(groupRoot, childIndex)) then
            table.insert(destructedChildIndices, childIndex)
        end
    end
    return destructedChildIndices
end
function DestructibleMapObjectSystem:saveToXMLFile(xmlPath, _)
    if xmlPath ~= nil and next(self.groups) ~= nil then
        local xmlFile = XMLFile.create("DestructibleMapObjectSystemXML", xmlPath, "destructibleMapObjects", DestructibleMapObjectSystem.xmlSchemaSavegame)
        local numItems = 0
        xmlFile:setTable("destructibleMapObjects.group", self.groups, function(groupKey, group, groupRoot)
            -- upvalues: (copy) self, (ref) numItems, (copy) xmlFile
            local destructedChildIndices = self:getDestructedChildIndices(groupRoot)
            if #destructedChildIndices == 0 then
                return 0
            end
            xmlFile:setValue(groupKey .. "#id", group.groupId)
            xmlFile:setTable(groupKey .. ".item", destructedChildIndices, function(path, childIndex, _)
                -- upvalues: (ref) xmlFile
                xmlFile:setValue(path .. "#index", childIndex)
            end)
        end)
        xmlFile:save()
        xmlFile:delete()
    end
end
function DestructibleMapObjectSystem:loadFromSavegameXML(xmlPath)
    if xmlPath ~= nil and next(self.groups) ~= nil then
        local xmlFile = XMLFile.loadIfExists("DestructibleMapObjectSystemXML", xmlPath, DestructibleMapObjectSystem.xmlSchemaSavegame)
        if xmlFile ~= nil then
            local loadedGroups = 0
            local loadedChildren = 0
            xmlFile:iterate("destructibleMapObjects.group", function(_, groupKey)
                -- upvalues: (copy) xmlFile, (copy) self, (ref) loadedGroups, (ref) loadedChildren
                local groupId = xmlFile:getValue(groupKey .. "#id")
                if groupId == nil then
                    Logging.xmlWarning(xmlFile, "Group %s is missing an \'id\' attribute", groupKey)
                    return true
                end
                local groupRoot = self.groupIdToGroupRoot[groupId]
                if groupRoot == nil then
                    Logging.xmlWarning(xmlFile, "Group with id \'%s\' (%s) does not exist in map", groupId, groupKey)
                    return true
                end
                xmlFile:iterate(groupKey .. ".item", function(_, itemKey)
                    -- upvalues: (ref) xmlFile, (ref) loadedChildren, (ref) self, (copy) groupRoot
                    local childIndex = xmlFile:getValue(itemKey .. "#index")
                    self:setChildIndexDestroyed(groupRoot, childIndex, false)
                end)
                return true
            end)
            xmlFile:delete()
            return
        end
        Logging.devInfo("DestructibleMapObjectSystem: no xml to load from savegame")
    end
end
function DestructibleMapObjectSystem:update(dt)
    for destructible, animationTime in pairs(self.activeDestructionAnimations) do
        local animationTime = animationTime + dt
        self.activeDestructionAnimations[destructible] = animationTime
        local group = self.destructibleToGroup[destructible]
        if animationTime < group.animDurationScrollPosition then
            I3DUtil.setShaderParameterRec(destructible, "scrollPos", animationTime / group.animDurationScrollPosition, nil, nil, nil)
            I3DUtil.setShaderParameterRec(destructible, "prevScrollPos", (animationTime - dt) / group.animDurationScrollPosition, nil, nil, nil)
        end
        if group.animDelayHideByIndex < animationTime and animationTime < group.animDelayHideByIndex + group.animDurationHideByIndex then
            I3DUtil.setShaderParameterRec(destructible, "hidePieces", (animationTime - group.animDelayHideByIndex) / group.animDurationHideByIndex, nil, nil, nil)
        end
        if group.animDelayHideByIndex + group.animDurationHideByIndex < animationTime then
            self:setDestructibleDestroyed(destructible, false)
            table.insert(self.activeDestructionAnimationsToDelete, destructible)
        end
    end
    local i = #self.activeDestructionAnimationsToDelete
    for i = i, 1, -1 do
        self.activeDestructionAnimations[self.activeDestructionAnimationsToDelete[i]] = nil
        table.remove(self.activeDestructionAnimationsToDelete, i)
    end
    if next(self.activeDestructionAnimations) == nil then
        g_currentMission:removeUpdateable(self)
    end
end
function DestructibleMapObjectSystem:consoleCommandNodeAddDamage(damageAmount, destructibleType)
    damageAmount = tonumber(damageAmount) or 5
    if destructibleType then
        destructibleType = string.upper(destructibleType)
    end
    local cam = getCamera()
    local wx, wy, wz = getWorldTranslation(cam)
    local dx, dy, dz = localDirectionToWorld(cam, 0, 0, -1)
    raycastClosest(wx + dx, wy + dy, wz + dz, dx, dy, dz, 30, "consoleCommandNodeAddDamageRaycastCallback", self, CollisionMask.ALL - CollisionFlag.PLAYER)
    self.callbackNode = nil
    local destructible = self.nodeToDestructible[self.callbackNode]
    if destructible then
        if destructibleType ~= nil then
            local destructibleTypeGroups = self.destructibleTypes[destructibleType]
            if not (destructibleTypeGroups and destructibleTypeGroups[self.destructibleToGroup[destructible]]) then
                return string.format("No destructible found for given destructible type \'%s\'", destructibleType)
            end
        end
        local destructibleTypeGroups, totalDamange = self:addDestructibleDamage(destructible, damageAmount, true)
        if destructibleTypeGroups >= 1 then
            return string.format("Destroyed destructible %d (Type:%s) of group %d", getChildIndex(destructible), self.destructibleToGroup[destructible].destructibleType, self.destructibleToGroup[destructible].groupId)
        else
            return string.format("Added %d damage (%d%%, %d total) to destructible %d (Type:%s) of group %d", damageAmount, destructibleTypeGroups * 100, totalDamange, getChildIndex(destructible), group.destructibleType, group.groupId)
        end
    else
        return "No destructible found"
    end
end
function DestructibleMapObjectSystem:consoleCommandNodeAddDamageRaycastCallback(transformId, _, _, _, _, _, _, _)
    if getName(transformId) == "playerCCT" then
        return true
    end
    self.callbackNode = transformId
    return false
end
function DestructibleMapObjectSystem:consoleCommandToggleDebug()
    if self.mission:getHasDrawable(self) then
        self.mission:removeDrawable(self)
        for groupRootNode, group in pairs(self.groups) do
            local childIndex = 0
            local numChildren = getNumOfChildren(groupRootNode) - 1
            for childIndex = childIndex, numChildren do
                local childIndex = getChildAt(groupRootNode, childIndex)
                local destructibleNode = getChild(childIndex, "destructibleDebugNote")
                if destructibleNode ~= 0 then
                    delete(destructibleNode)
                end
            end
        end
        return "DestructibleMapObjectSystem: Disabled debug"
    end
    self.mission:addDrawable(self)
    for groupRootNode, group in pairs(self.groups) do
        local color = DebugUtil.tableToColor(group)
        local childIndex = 0
        local childIndex = 1
        for childIndex = childIndex, getNumOfChildren(groupRootNode) - 1, childIndex do
            local destructibleNode = getChildAt(groupRootNode, childIndex)
            if getVisibility(destructibleNode) then
                local text = string.format("%s #%d\ndestuction volume %d\ndrop amount %d", getName(groupRootNode), childIndex, group.destructionVolume, group.dropAmount)
                local note = createNoteNode(destructibleNode, text, color[1], color[2], color[3])
                setName(note, "destructibleDebugNote")
                setTranslation(note, 0, 2.5, 0)
            end
        end
    end
    if g_isDevelopmentVersion then
        executeConsoleCommand("enableNoteRendering true")
    end
    return "DestructibleMapObjectSystem: Enabled debug"
end
function DestructibleMapObjectSystem:draw()
    setTextBold(false)
    local i = 1
    if next(self.groups) then
        renderText(0.28, 0.97, 0.015, string.format("%d Groups - Total num destructibles: %d", table.size(self.groups), table.size(self.nodeToDestructible)))
        for groupRootNode, group in pairs(self.groups) do
            local destructedChildIndices = self:getDestructedChildIndices(groupRootNode)
            renderText(0.3, 0.97 - i * 0.015, 0.015, string.format("%s (%s) (%s) - %d destructibles - %d destroyed", getName(groupRootNode), groupRootNode, group.destructibleType, getNumOfChildren(groupRootNode), #destructedChildIndices))
            for childNumber, childIndex in ipairs(destructedChildIndices) do
                i = i + 1
                renderText(0.32, 0.97 - i * 0.015, 0.015, string.format("#%d - node child index: %d", childNumber, childIndex))
            end
            i = i + 1
        end
        local i = i + 1
        if next(self.destructibleTypes) then
            renderText(0.28, 0.97 - i * 0.015, 0.015, "Destructible Types")
            i = i + 1
            for groupRootNode, group in pairs(self.destructibleTypes) do
                renderText(0.3, 0.97 - i * 0.015, 0.015, string.format("%s - num groups: %d", groupRootNode, table.size(group)))
                i = i + 1
            end
        end
        local i = i + 1
        if next(self.destructibleDamage) then
            renderText(0.28, 0.97 - i * 0.015, 0.015, "Destructible Damage")
            local i = i + 1
            for groupRootNode, group in pairs(self.destructibleDamage) do
                renderText(0.3, 0.97 - i * 0.015, 0.015, string.format("%s: %d", getName(groupRootNode), group))
                i = i + 1
            end
        end
        if g_currentMission:getHasUpdateable(self) then
            setTextColor(1, 0, 0, 1)
            renderText(0.5, 0.2, 0.02, "update/animation active")
            setTextColor(1, 1, 1, 1)
        end
    else
        renderText(0.32, 0.97 - i * 0.015, 0.015, string.format("no destructibles defined in map"))
    end
end