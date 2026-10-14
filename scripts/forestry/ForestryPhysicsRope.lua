ForestryPhysicsRope = {}
ForestryPhysicsRope.COLLISION_GROUP = CollisionFlag.DYNAMIC_OBJECT
local ForestryPhysicsRope_mt = ForestryPhysicsRope
ForestryPhysicsRope_mt.COLLISION_MASK = bit32.bor(CollisionFlag.TERRAIN, CollisionFlag.STATIC_OBJECT, CollisionFlag.DYNAMIC_OBJECT, CollisionFlag.TREE, CollisionFlag.VEHICLE, CollisionFlag.ROAD, CollisionFlag.BUILDING)
ForestryPhysicsRope.NUM_NODE_BITS = 8
ForestryPhysicsRope.NUM_POSITION_BITS = 16
ForestryPhysicsRope.NUM_LENGTH_BITS = 16
ForestryPhysicsRope.MAX_LENGTH = 128
ForestryPhysicsRope.NUM_UPDATE_POSITION_BITS = 7
ForestryPhysicsRope.MAX_UPDATE_LENGTH = 0.75
local ForestryPhysicsRope_mt = Class(ForestryPhysicsRope)
function ForestryPhysicsRope.new(vehicle, linkActor, linkNode, isServer, customMt)
    -- upvalues: (copy) ForestryPhysicsRope_mt
    local self = setmetatable({}, customMt or ForestryPhysicsRope_mt)
    self.vehicle = vehicle
    self.linkActor = linkActor
    self.linkNode = linkNode
    self.isServer = isServer
    self.physicsRopeIndex = nil
    self.visibility = false
    self.useDynamicLength = false
    self.visualRopes = {}
    self.nodes = {}
    self.numActiveNodes = 0
    self.boundingRadius = 1
    self.isInitialized = false
    self.ropeLengthToSet = nil
    return self
end
function ForestryPhysicsRope.registerXMLPaths(schema, baseKey)
    schema:register(XMLValueType.FILENAME, baseKey .. "#filename", "Path to rope i3d file", "$data/shared/forestry/physicsRopes.i3d")
    schema:register(XMLValueType.STRING, baseKey .. "#ropeNode", "Path to rope i3d file", "0")
    schema:register(XMLValueType.FLOAT, baseKey .. "#diameter", "Diameter of the rope", 0.02)
    schema:register(XMLValueType.FLOAT, baseKey .. "#uvScale", "UV scale of the rope", 4)
    schema:register(XMLValueType.VECTOR_4, baseKey .. "#emissiveColor", "Emissive color", "0 0 0")
    schema:register(XMLValueType.FLOAT, baseKey .. "#minLength", "Minimum length of the rope", 1)
    schema:register(XMLValueType.FLOAT, baseKey .. "#maxLength", "Minimum length of the rope", 20)
    schema:register(XMLValueType.FLOAT, baseKey .. "#linkLength", "Length of each rope segment", 0.5)
    schema:register(XMLValueType.FLOAT, baseKey .. "#nodeDistance", "Distance between two nodes for rendering", 1)
    schema:register(XMLValueType.FLOAT, baseKey .. "#massPerLength", "Mass of each segment in kg", 20)
    schema:register(XMLValueType.UINT, baseKey .. "#collisionGroup", "collisionGroup of the rope", ForestryPhysicsRope.COLLISION_GROUP)
    schema:register(XMLValueType.UINT, baseKey .. "#collisionMask", "CollisionMask of the rope", ForestryPhysicsRope.COLLISION_MASK)
end
function ForestryPhysicsRope.registerSavegameXMLPaths(schema, baseKey)
    schema:register(XMLValueType.VECTOR_TRANS, baseKey .. ".ropeNode(?)#translation", "Translation of rope node")
end
function ForestryPhysicsRope:loadFromXML(xmlFile, key, minLength, maxLength, baseDirectory)
    self.i3dFilename = xmlFile:getValue(key .. "#filename", "$data/shared/forestry/physicsRopes.i3d", baseDirectory)
    self.i3dRopePath = xmlFile:getValue(key .. "#ropeNode", "0")
    self.diameter = xmlFile:getValue(key .. "#diameter", 0.02)
    self.uvScale = xmlFile:getValue(key .. "#uvScale", 4)
    self.emissiveColor = xmlFile:getValue(key .. "#emissiveColor", "0 1 0 0", true)
    self.minLength = xmlFile:getValue(key .. "#minLength", minLength)
    self.maxLength = xmlFile:getValue(key .. "#maxLength", maxLength)
    self.linkLength = xmlFile:getValue(key .. "#linkLength", 0.5)
    self.nodeDistance = xmlFile:getValue(key .. "#nodeDistance", 1)
    self.massPerLength = xmlFile:getValue(key .. "#massPerLength", 20) * 0.001
    self.collisionGroup = xmlFile:getValue(key .. "#collisionGroup", ForestryPhysicsRope.COLLISION_GROUP)
    self.collisionMask = xmlFile:getValue(key .. "#collisionMask", ForestryPhysicsRope.COLLISION_MASK)
    local numSegments = self.maxLength / self.linkLength
    if 2 ^ ForestryPhysicsRope.NUM_NODE_BITS - 1 < numSegments then
        Logging.xmlWarning(xmlFile, "Physics rope has too many segments! Max. %d segments are allowed, %d defined. (length / linkLength)", 2 ^ ForestryPhysicsRope.NUM_NODE_BITS - 1, numSegments)
    end
    if self.maxLength > ForestryPhysicsRope.MAX_LENGTH then
        Logging.xmlWarning(xmlFile, "Physics rope too long! Max. %dm are allowed", ForestryPhysicsRope.MAX_LENGTH)
    end
    if self.i3dFilename ~= nil then
        if self.vehicle ~= nil then
            self.sharedLoadRequestId = self.vehicle:loadSubSharedI3DFile(self.i3dFilename, false, false, self.onI3DLoaded, self, self)
            return
        end
        self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, false, false, self.onI3DLoaded, self, self)
    end
end
function ForestryPhysicsRope:clone(linkActor, linkNode, maxLength)
    local ropeClone = ForestryPhysicsRope.new(self.vehicle, linkActor or self.linkActor, linkNode or self.linkNode)
    ropeClone.i3dFilename = self.i3dFilename
    ropeClone.i3dRopePath = self.i3dRopePath
    ropeClone.diameter = self.diameter
    ropeClone.uvScale = self.uvScale
    ropeClone.emissiveColor = self.emissiveColor
    ropeClone.minLength = self.minLength
    ropeClone.maxLength = maxLength or self.maxLength
    ropeClone.linkLength = self.linkLength
    ropeClone.nodeDistance = self.nodeDistance
    ropeClone.massPerLength = self.massPerLength
    ropeClone.collisionGroup = self.collisionGroup
    ropeClone.collisionMask = self.collisionMask
    if ropeClone.i3dFilename == nil then
        return nil
    end
    local i3dNode, sharedLoadRequestId, failedReason = g_i3DManager:loadSharedI3DFile(ropeClone.i3dFilename, false, false)
    ropeClone.sharedLoadRequestId = sharedLoadRequestId
    ropeClone:onI3DLoaded(i3dNode, failedReason)
    return ropeClone
end
function ForestryPhysicsRope:saveToXMLFile(xmlFile, key)
    if self.physicsRopeIndex ~= nil then
        _, self.numActiveNodes = getPhysicsRopeLength(self.physicsRopeIndex)
        local i = 1
        for i = i, self.numActiveNodes do
            local x, y, z = getWorldTranslation(self.nodes[i])
            xmlFile:setValue(string.format("%s.ropeNode(%d)#translation", key, i - 1), x, y, z)
        end
    end
end
function ForestryPhysicsRope.loadPositionDataFromSavegame(xmlFile, key)
    local positions = {}
    xmlFile:iterate(key .. ".ropeNode", function(_, nodeKey)
        -- upvalues: (copy) xmlFile, (copy) positions
        local translation = xmlFile:getValue(nodeKey .. "#translation", nil, true)
        table.insert(positions, translation)
    end)
    return positions
end
function ForestryPhysicsRope:delete()
    g_currentMission:removeUpdateable(self)
    for _, node in pairs(self.nodes) do
        delete(node)
    end
    if self.referenceFrame ~= nil then
        if entityExists(self.referenceFrame) then
            delete(self.referenceFrame)
        end
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
    end
end
function ForestryPhysicsRope:writeStream(streamId)
    if self.physicsRopeIndex == nil then
        streamWriteUIntN(streamId, 0, ForestryPhysicsRope.NUM_NODE_BITS)
    else
        local _, numSegments = getPhysicsRopeLength(self.physicsRopeIndex)
        streamWriteUIntN(streamId, numSegments, ForestryPhysicsRope.NUM_NODE_BITS)
        local i = 1
        for i = i, numSegments do
            local x, y, z = getTranslation(self.nodes[i])
            streamWriteIntN(streamId, math.clamp(x / ForestryPhysicsRope.MAX_LENGTH, -1, 1) * (2 ^ (ForestryPhysicsRope.NUM_POSITION_BITS - 1) - 1), ForestryPhysicsRope.NUM_POSITION_BITS)
            streamWriteIntN(streamId, math.clamp(y / ForestryPhysicsRope.MAX_LENGTH, -1, 1) * maxValue, ForestryPhysicsRope.NUM_POSITION_BITS)
            streamWriteIntN(streamId, math.clamp(z / ForestryPhysicsRope.MAX_LENGTH, -1, 1) * maxValue, ForestryPhysicsRope.NUM_POSITION_BITS)
        end
    end
end
function ForestryPhysicsRope.readStream(streamId, invert)
    local positions = {}
    local numPositions = streamReadUIntN(streamId, ForestryPhysicsRope.NUM_NODE_BITS)
    for i = 1, numPositions do
        local x = streamReadIntN(streamId, ForestryPhysicsRope.NUM_POSITION_BITS) / (2 ^ (ForestryPhysicsRope.NUM_POSITION_BITS - 1) - 1) * ForestryPhysicsRope.MAX_LENGTH
        local y = streamReadIntN(streamId, ForestryPhysicsRope.NUM_POSITION_BITS) / maxValue * ForestryPhysicsRope.MAX_LENGTH
        local z = streamReadIntN(streamId, ForestryPhysicsRope.NUM_POSITION_BITS) / maxValue * ForestryPhysicsRope.MAX_LENGTH
        if invert then
            table.insert(positions, 1, { x, y, z })
        else
            table.insert(positions, { x, y, z })
        end
    end
    return positions
end
function ForestryPhysicsRope:writeUpdateStream(streamId)
    local length = streamWriteBool
    if length(streamId, self.physicsRopeIndex ~= nil) then
        local length = math.clamp(getPhysicsRopeLength(self.physicsRopeIndex), 0, ForestryPhysicsRope.MAX_LENGTH)
        streamWriteUIntN(streamId, length / ForestryPhysicsRope.MAX_LENGTH * (2 ^ ForestryPhysicsRope.NUM_LENGTH_BITS - 1), ForestryPhysicsRope.NUM_LENGTH_BITS)
    end
end
function ForestryPhysicsRope:readUpdateStream(streamId)
    if streamReadBool(streamId) then
        self.ropeLength = streamReadUIntN(streamId, ForestryPhysicsRope.NUM_LENGTH_BITS) / (2 ^ ForestryPhysicsRope.NUM_LENGTH_BITS - 1) * ForestryPhysicsRope.MAX_LENGTH
        if self.physicsRopeIndex ~= nil then
            setPhysicsRopeMaxLength(self.physicsRopeIndex, self.ropeLength)
        end
    end
end
function ForestryPhysicsRope:update(_)
    if self.physicsRopeIndex ~= nil and self.useDynamicLength then
        local _, numSegments = getPhysicsRopeLength(self.physicsRopeIndex)
        local lx, ly, lz = getWorldTranslation(self.curTargetNode)
        local distance = MathUtil.vector3Length(lx - self.dynamicLengthLastPosition[1], ly - self.dynamicLengthLastPosition[2], lz - self.dynamicLengthLastPosition[3])
        local move = distance - (self.dynamicLengthLastDistance or distance)
        local numPositions = 0
        local wx = 0
        local wy = 0
        local wz = 0
        local z = numSegments - 10
        local x = math.max(1, z)
        local z = -1
        for numSegments = numSegments, x, z do
            if self.nodes[numSegments] ~= nil then
                local x, y, z = getWorldTranslation(self.nodes[numSegments])
            end
        end
        local wx, wy, wz
        if numPositions > 0 then
        else
            wx, wy, wz = getWorldTranslation(self.curLinkNode)
        end
        self:adjustLength(move < 0 and self:getRopeDirectLengthPercentage() > 1 and 0 or move, true)
        local y = self.dynamicLengthLastPosition
        local z = self.dynamicLengthLastPosition
        y[1] = wx
        z[2] = wy
        self.dynamicLengthLastPosition[3] = wz
        self.dynamicLengthLastDistance = MathUtil.vector3Length(lx - wx, ly - wy, lz - wz)
    end
    if self.physicsRopeIndex ~= nil then
        local _, numSegments = getPhysicsRopeLength(self.physicsRopeIndex)
        if self.isInitialized then
            if self.customTargetNode ~= nil and numSegments ~= 0 then
                setWorldTranslation(self.nodes[numSegments], getWorldTranslation(self.customTargetNode))
                setWorldRotation(self.nodes[numSegments], getWorldRotation(self.customTargetNode))
            end
            if self.customLinkNode ~= nil then
                setWorldTranslation(self.nodes[1], getWorldTranslation(self.customLinkNode))
                setWorldRotation(self.nodes[1], getWorldRotation(self.customLinkNode))
            end
        end
        if _ ~= self.ropeLength or numSegments ~= self.numActiveNodes then
            self.ropeLength = _
            self.numActiveNodes = numSegments
            local lx = false
            local lwx = 1
            for lwx = lwx, #self.visualRopes do
                local lwy = self.visualRopes[lwx]
                if numSegments <= lwy.numBones and not lx then
                    local lwz = setVisibility
                    local distance = lwy.node
                    local move = numSegments <= lwy.numBones
                    lwz(distance, move)
                    setShaderParameter(lwy.node, "numNodesAndLength", numSegments, _, 0, 0, false)
                    local numSegments
                    if numSegments > 1 then
                        local lwz = 0
                        local distance = 0
                        local move = 0
                        local wy = 1
                        for wy = wy, numSegments do
                            local wz, y, z = getWorldTranslation(self.nodes[wy])
                        end
                        local wy = move / numSegments
                        local z = _ * 0.5
                        local y = math.ceil(z)
                        lwy.boundingRadius = math.max(y, 2)
                        local wz, y, z = worldToLocal(self.nodes[1], lwz / numSegments, distance / numSegments, wy)
                        setShapeBoundingSphere(lwy.node, wz, y, z, lwy.boundingRadius)
                    end
                    lx = true
                else
                    setVisibility(lwy.node, false)
                    lwy.boundingRadius = nil
                end
            end
        end
        if not self.isInitialized and (_ ~= 0 and numSegments ~= 0) then
            self.isInitialized = true
            self:setVisibility(true)
            if self.ropeLengthToSet ~= nil then
                self:setLength(self.ropeLengthToSet)
                self.ropeLengthToSet = nil
            end
            if self.callback ~= nil then
                if self.callbackTarget == nil then
                    self.callback(_, numSegments)
                else
                    self.callback(self.callbackTarget, _, numSegments)
                end
                self.callback = nil
                self.callbackTarget = nil
            end
        end
    end
end
function ForestryPhysicsRope:updateAnchorNodes()
    if self.physicsRopeIndex ~= nil then
        local sx, sy, sz = worldToLocal(self.curLinkActor, getWorldTranslation(self.curLinkNode))
        setPhysicsRopeAnchor(self.physicsRopeIndex, 0, self.curLinkActor, sx, sy, sz, false)
        local ex, ey, ez = worldToLocal(self.curTargetActor, getWorldTranslation(self.curTargetNode))
        setPhysicsRopeAnchor(self.physicsRopeIndex, 999999, self.curTargetActor, ex, ey, ez, false)
    end
end
function ForestryPhysicsRope:setUseDynamicLength(useDynamicLength)
    self.useDynamicLength = useDynamicLength
    self.dynamicLengthLastPosition = { getWorldTranslation(self.curTargetNode) }
    self.dynamicLengthLastDistance = nil
end
function ForestryPhysicsRope:applySavegamePositions(savegamePositions)
    local i = 1
    for i = i, #savegamePositions do
        if self.nodes[i] ~= nil then
            setTranslation(self.nodes[i], savegamePositions[i][1], savegamePositions[i][2], savegamePositions[i][3])
        end
    end
end
function ForestryPhysicsRope:copyNodePositions(otherRope, invert)
    local i = 1
    for i = i, #otherRope.nodes do
        local otherIndex
        if invert then
            otherIndex = #self.nodes - (i - 1)
        else
            otherIndex = i
        end
        if self.nodes[otherIndex] ~= nil then
            setWorldTranslation(self.nodes[otherIndex], getWorldTranslation(otherRope.nodes[i]))
        end
    end
end
function ForestryPhysicsRope:create(targetActor, targetNode, linkActor, linkNode, inverted, useNodePositions, callback, callbackTarget)
    local sx = Utils.getNoNil(useNodePositions, false)
    local sx = linkActor or self.linkActor
    local sx = linkNode or self.linkNode
    if not inverted then
    end
    local sx, sy, sz = worldToLocal(targetActor, getWorldTranslation(targetNode))
    local ex, ey, ez = worldToLocal(sx, getWorldTranslation(sx))
    self.physicsRopeIndex = addPhysicsRope(self.nodes, self.nodeDistance, self.linkLength, self.massPerLength, self.collisionGroup, self.collisionMask, targetActor, sx, sy, sz, sx, ex, ey, ez, sx)
    self.ropeLength = getPhysicsRopeLength(self.physicsRopeIndex)
    self.ropeLengthSumUp = self.ropeLength
    self.curLinkActor = targetActor
    self.curLinkNode = targetNode
    self.curTargetActor = sx
    self.curTargetNode = sx
    self.isInitialized = false
    g_currentMission:addUpdateable(self)
    self:setVisibility(false)
    self.callback = callback
    self.callbackTarget = callbackTarget
    return self.physicsRopeIndex ~= nil
end
function ForestryPhysicsRope:setCustomVisualNodes(targetNode, linkNode)
    self.customTargetNode = targetNode
    self.customLinkNode = linkNode
end
function ForestryPhysicsRope:destroy()
    if self.physicsRopeIndex ~= nil then
        removePhysicsRope(self.physicsRopeIndex)
        self.physicsRopeIndex = nil
    end
    self.ropeLength = 0
    self.ropeLengthSumUp = 0
    self.numActiveNodes = 0
    self.curLinkActor = nil
    self.curLinkNode = nil
    self.curTargetActor = nil
    self.curTargetNode = nil
    self.isInitialized = false
    self.ropeLengthToSet = nil
    self.callback = nil
    self.callbackTarget = nil
    g_currentMission:removeUpdateable(self)
    self:setVisibility(false)
end
function ForestryPhysicsRope:setMaxLength(maxLength)
    self.maxLength = maxLength
    local numSegments = self.maxLength / self.linkLength
    if 2 ^ ForestryPhysicsRope.NUM_NODE_BITS - 1 < numSegments then
        Logging.warning("Physics rope has too many segments! Max. %d segments are allowed, %d defined. (length / linkLength)", 2 ^ ForestryPhysicsRope.NUM_NODE_BITS - 1, numSegments)
    end
    if self.maxLength > ForestryPhysicsRope.MAX_LENGTH then
        Logging.warning("Physics rope too long! Max. %dm are allowed", ForestryPhysicsRope.MAX_LENGTH)
    end
end
function ForestryPhysicsRope:generateNodes()
    local i = #self.nodes
    for i = i, 1, -1 do
        delete(self.nodes[i])
        self.nodes[i] = nil
    end
    local i = 1
    for i = i, math.ceil(self.maxLength / self.linkLength) + 1 do
        local node = createTransformGroup("ropeNode" .. i)
        link(self.linkNode, node)
        table.insert(self.nodes, node)
    end
end
function ForestryPhysicsRope:getRopeDirectLengthPercentage(referenceMaxLength)
    return self.physicsRopeIndex == nil and 0 or (calcDistanceFrom(self.curLinkNode, self.curTargetNode) - self.minLength) / ((referenceMaxLength or self.maxLength) - self.minLength)
end
function ForestryPhysicsRope:getLength()
    return self.physicsRopeIndex == nil and 0 or getPhysicsRopeLength(self.physicsRopeIndex)
end
function ForestryPhysicsRope:setLength(length)
    if self.isInitialized then
        setPhysicsRopeMaxLength(self.physicsRopeIndex, length)
    else
        self.ropeLengthToSet = length
    end
end
function ForestryPhysicsRope:adjustLength(lengthDelta, sumUp)
    if self.physicsRopeIndex ~= nil then
        local ropeLength, ropeSegments = getPhysicsRopeLength(self.physicsRopeIndex)
        if ropeSegments > 0 then
            if sumUp and self.ropeLengthSumUp ~= 0 then
                ropeLength = self.ropeLengthSumUp
            end
            local newRopeLength = math.clamp(ropeLength + lengthDelta, self.minLength, self.maxLength)
            setPhysicsRopeMaxLength(self.physicsRopeIndex, newRopeLength)
            self.ropeLengthSumUp = newRopeLength
            return math.sign(newRopeLength - ropeLength)
        end
    end
    return 0
end
function ForestryPhysicsRope:setVisibility(visibility)
    self.visibility = visibility
    if self.referenceFrame ~= nil and entityExists(self.referenceFrame) then
        setVisibility(self.referenceFrame, self.visibility)
    end
end
function ForestryPhysicsRope:setEmissiveColor(r, g, b, a)
    if r ~= self.emissiveColor[1] or (g ~= self.emissiveColor[2] or (b ~= self.emissiveColor[3] or a ~= self.emissiveColor[4])) then
        self.emissiveColor[1] = r
        self.emissiveColor[2] = g
        self.emissiveColor[3] = b
        self.emissiveColor[4] = a
        local i = 1
        for i = i, #self.visualRopes do
            setShaderParameter(self.visualRopes[i].node, "ropeEmissiveColor", self.emissiveColor[1], self.emissiveColor[2], self.emissiveColor[3], self.emissiveColor[4], false)
        end
    end
end
function ForestryPhysicsRope:onI3DLoaded(i3dNode, _)
    if i3dNode ~= 0 then
        self.referenceFrame = createTransformGroup("ropeReferenceFrame")
        link(self.linkNode, self.referenceFrame)
        setVisibility(self.referenceFrame, self.visibility)
        local ropeRoot = getChildAt(i3dNode, 0)
        local node = getNumOfChildren(ropeRoot)
        for i = 1, node do
            local node = getChildAt(ropeRoot, 0)
            link(self.referenceFrame, node)
            local visualRope = {
                ["node"] = node,
                ["numBones"] = getNumOfShapeBones(node)
            }
            table.insert(self.visualRopes, visualRope)
            setShaderParameter(node, "numBonesAndBoneDistanceAndDiameterAndVScale", visualRope.numBones, self.nodeDistance, self.diameter, self.uvScale, false)
        end
        local jointRoot = getChildAt(i3dNode, 1)
        local node = 1
        local visualRope = getNumOfChildren(jointRoot)
        for node = node, visualRope do
            local visualRope = getChildAt(jointRoot, 0)
            unlink(visualRope)
            table.insert(self.nodes, visualRope)
        end
        delete(i3dNode)
    end
end