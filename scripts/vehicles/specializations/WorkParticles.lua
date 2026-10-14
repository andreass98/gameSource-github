WorkParticles = {}
WorkParticles.PARTICLE_MAPPING_XML_PATH = "vehicle.workParticles.particle(?).node(?)"
function WorkParticles.prerequisitesPresent(specializations)
    return true
end
function WorkParticles.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("WorkParticles")
    schema:register(XMLValueType.STRING, "vehicle.workParticles.particleAnimation(?)#file", "External effect i3d file")
    schema:register(XMLValueType.FLOAT, "vehicle.workParticles.particleAnimation(?)#speedThreshold", "Speed threshold", 0)
    WorkParticles.registerGroundAnimationMappingXMLPaths(schema, "vehicle.workParticles.particleAnimation(?).node(?)")
    schema:register(XMLValueType.STRING, "vehicle.workParticles.particle(?)#file", "External effect i3d file")
    WorkParticles.registerGroundParticleMappingXMLPaths(schema, "vehicle.workParticles.particle(?).node(?)")
    schema:register(XMLValueType.BOOL, "vehicle.workParticles#requireField", "The effects require the vehicle to be on a field to work", true)
    EffectManager.registerEffectXMLPaths(schema, "vehicle.workParticles.effect(?)")
    schema:register(XMLValueType.FLOAT, "vehicle.workParticles.effect(?)#speedThreshold", "Speed threshold", 0.5)
    schema:register(XMLValueType.INT, "vehicle.workParticles.effect(?)#activeDirection", "Active Direction (effect will be turned off wen in opposite direction)", 1)
    schema:register(XMLValueType.INT, "vehicle.workParticles.effect(?)#workAreaIndex", "Work area index")
    schema:register(XMLValueType.INT, "vehicle.workParticles.effect(?)#groundReferenceNodeIndex", "Index of ground reference node")
    schema:register(XMLValueType.BOOL, "vehicle.workParticles.effect(?)#needsSetIsTurnedOn", "Needs set is turned on", false)
    schema:register(XMLValueType.NODE_INDEX, GroundReference.GROUND_REFERENCE_XML_KEY .. "#depthNode", "Depth node")
    schema:setXMLSpecializationType()
end
function WorkParticles.registerGroundAnimationMappingXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. "#node", "Link node in vehicle")
    schema:register(XMLValueType.INT, key .. "#refNodeIndex", "Ground reference node index")
    schema:register(XMLValueType.STRING, key .. "#animMeshNode", "Animation mesh node in external file")
    schema:register(XMLValueType.STRING, key .. "#materialType", "Material type name (If external file is not given)")
    schema:register(XMLValueType.INT, key .. "#materialId", "Material index (If external file is not given)", 1)
    schema:register(XMLValueType.FLOAT, key .. "#maxDepth", "Max. depth", -0.1)
end
function WorkParticles.registerGroundParticleMappingXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. "#node", "Link node in vehicle")
    schema:register(XMLValueType.INT, key .. "#refNodeIndex", "Ground reference node index")
    schema:register(XMLValueType.STRING, key .. "#particleNode", "Particle node in external file")
    schema:register(XMLValueType.STRING, key .. "#particleType", "Particle type name (If external file is not given)")
    schema:register(XMLValueType.STRING, key .. "#fillType", "Fill type for particles (If external file is not given)", "UNKNOWN")
    schema:register(XMLValueType.FLOAT, key .. "#speedThreshold", "Speed threshold", 0.5)
    schema:register(XMLValueType.INT, key .. "#movingDirection", "Moving direction")
    ParticleUtil.registerParticleCopyXMLPaths(schema, key)
end
function WorkParticles.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getDoGroundManipulation", WorkParticles.getDoGroundManipulation)
    SpecializationUtil.registerFunction(vehicleType, "loadGroundAnimations", WorkParticles.loadGroundAnimations)
    SpecializationUtil.registerFunction(vehicleType, "onGroundAnimationI3DLoaded", WorkParticles.onGroundAnimationI3DLoaded)
    SpecializationUtil.registerFunction(vehicleType, "loadGroundAnimationMapping", WorkParticles.loadGroundAnimationMapping)
    SpecializationUtil.registerFunction(vehicleType, "loadGroundParticles", WorkParticles.loadGroundParticles)
    SpecializationUtil.registerFunction(vehicleType, "groundParticleI3DLoaded", WorkParticles.groundParticleI3DLoaded)
    SpecializationUtil.registerFunction(vehicleType, "loadGroundParticleMapping", WorkParticles.loadGroundParticleMapping)
    SpecializationUtil.registerFunction(vehicleType, "loadGroundEffects", WorkParticles.loadGroundEffects)
    SpecializationUtil.registerFunction(vehicleType, "getFillTypeFromWorkAreaIndex", WorkParticles.getFillTypeFromWorkAreaIndex)
end
function WorkParticles.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadGroundReferenceNode", WorkParticles.loadGroundReferenceNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateGroundReferenceNode", WorkParticles.updateGroundReferenceNode)
end
function WorkParticles.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", WorkParticles)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", WorkParticles)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WorkParticles)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", WorkParticles)
end
function WorkParticles:onLoad(_)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.groundParticleAnimations.groundParticleAnimation", "vehicle.workParticles.particleAnimation")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.groundParticleAnimations.groundParticle", "vehicle.workParticles.particle")
    if self.isClient then
        self.spec_workParticles.requireField = self.xmlFile:getValue("vehicle.workParticles#requireField", true)
        spec.particleAnimations = {}
        local i = 0
        while true do
            local key = string.format("vehicle.workParticles.particleAnimation(%d)", i)
            if not self.xmlFile:hasProperty(key) then
                break
            end
            local animation = {}
            if self:loadGroundAnimations(self.xmlFile, key, animation, i) then
                table.insert(spec.particleAnimations, animation)
            end
            i = i + 1
        end
        spec.particles = {}
        local i = 0
        while true do
            local key = string.format("vehicle.workParticles.particle(%d)", i)
            if not self.xmlFile:hasProperty(key) then
                break
            end
            local animation = {}
            if self:loadGroundParticles(self.xmlFile, key, animation, i) then
                table.insert(spec.particles, animation)
            end
            i = i + 1
        end
        spec.effects = {}
        local i = 0
        while true do
            local key = string.format("vehicle.workParticles.effect(%d)", i)
            if not self.xmlFile:hasProperty(key) then
                break
            end
            local animation = {}
            if self:loadGroundEffects(self.xmlFile, key, animation, i) then
                table.insert(spec.effects, animation)
            end
            i = i + 1
        end
    end
    if not self.isClient then
        SpecializationUtil.removeEventListener(self, "onDelete", WorkParticles)
        SpecializationUtil.removeEventListener(self, "onUpdateTick", WorkParticles)
        SpecializationUtil.removeEventListener(self, "onDeactivate", WorkParticles)
    end
end
function WorkParticles:onDelete()
    local spec = self.spec_workParticles
    if spec.particleAnimations ~= nil then
        for _, animation in ipairs(spec.particleAnimations) do
            if animation.sharedLoadRequestId ~= nil then
                g_i3DManager:releaseSharedI3DFile(animation.sharedLoadRequestId)
                animation.sharedLoadRequestId = nil
            end
        end
    end
    if spec.particles ~= nil then
        for _, animation in pairs(spec.particles) do
            for _, mapping in ipairs(animation.mappings) do
                ParticleUtil.deleteParticleSystem(mapping.particleSystem)
            end
            if animation.sharedLoadRequestId ~= nil then
                g_i3DManager:releaseSharedI3DFile(animation.sharedLoadRequestId)
                animation.sharedLoadRequestId = nil
            end
        end
    end
    if spec.effects ~= nil then
        for _, animation in pairs(spec.effects) do
            g_effectManager:deleteEffects(animation.effect)
        end
    end
end
function WorkParticles:onUpdateTick(_, _, _, _)
    local spec = self.spec_workParticles
    local isOnField = self.isOnField or not spec.requireField
    for _, animation in ipairs(spec.particleAnimations) do
        for _, mapping in ipairs(animation.mappings) do
            local refNode = mapping.groundRefNode
            if refNode ~= nil and refNode.depthNode ~= nil then
                local depth = not isOnField and 0 or math.clamp(refNode.depth / mapping.maxWorkDepth, 0, 1)
                mapping.lastDepth = math.clamp(math.min(depth, mapping.lastDepth + refNode.movingDirection * (refNode.movedDistance / 0.5)), 0, 1)
                mapping.speed = mapping.speed - refNode.movedDistance * refNode.movingDirection
                nodeEnabled(mapping.animNode, setVisibility > 0)
                setShaderParameter(mapping.animNode, "VertxoffsetVertexdeformMotionUVscale", -6, nodeEnabled, mapping.speed, 1.5, false)
            end
        end
    end
    local lastSpeed = self:getLastSpeed(true)
    local enabled = self:getDoGroundManipulation() and isOnField
    for _, ps in pairs(spec.particles) do
        for refNode, depth in ipairs(ps.mappings) do
            local nodeEnabled
            if enabled then
                nodeEnabled = depth.groundRefNode.isActive
                if nodeEnabled then
                    nodeEnabled = depth.speedThreshold < lastSpeed
                end
            else
                nodeEnabled = enabled
            end
            if depth.movingDirection ~= nil then
                if nodeEnabled then
                    nodeEnabled = depth.movingDirection == self.movingDirection
                end
            end
            ParticleUtil.setEmittingState(depth.particleSystem, nodeEnabled)
        end
    end
    for _, ps in pairs(spec.effects) do
        local state = enabled and ps.speedThreshold < lastSpeed
        if ps.needsSetIsTurnedOn and self.getIsTurnedOn ~= nil then
            local _ = self:getIsTurnedOn()
            if self.getAttacherVehicle ~= nil then
                local mapping = self:getAttacherVehicle()
                if mapping ~= nil and mapping.getIsTurnedOn ~= nil then
                    _ = _ or mapping:getIsTurnedOn()
                end
            end
        end
        local _ = self:getWorkAreaByIndex(ps.workAreaIndex)
        if _ ~= nil and _.requiresGroundContact then
            if state then
                state = false
                if _.groundReferenceNode ~= nil then
                    state = _.groundReferenceNode.isActive
                end
            end
        end
        if ps.groundReferenceNodeIndex ~= nil and ps.groundReferenceNode == nil then
            ps.groundReferenceNode = self:getGroundReferenceNodeFromIndex(ps.groundReferenceNodeIndex)
            if ps.groundReferenceNode == nil then
                Logging.warning("Unknown ground reference node \'%s\' for WorkParticle effect!", ps.groundReferenceNodeIndex)
                ps.groundReferenceNodeIndex = nil
            end
        end
        if ps.groundReferenceNode ~= nil then
            if state then
                state = ps.groundReferenceNode.isActive
            end
        end
        if state then
            state = true
            if self.movingDirection == -ps.activeDirection then
                state = self:getLastSpeed() < 0.5
            end
        end
        if state then
            local mapping = self:getFillTypeFromWorkAreaIndex(ps.workAreaIndex)
            g_effectManager:setEffectTypeInfo(ps.effect, mapping)
            g_effectManager:startEffects(ps.effect)
        else
            g_effectManager:stopEffects(ps.effect)
        end
    end
end
function WorkParticles:getDoGroundManipulation()
    return true
end
function WorkParticles:loadGroundAnimations(xmlFile, key, animation, _)
    animation.speedThreshold = xmlFile:getValue(key .. "#speedThreshold", 0)
    animation.mappings = {}
    local j = 0
    while true do
        local nodeBaseName = string.format(key .. ".node(%d)", j)
        if not self.xmlFile:hasProperty(nodeBaseName) then
            break
        end
        local mapping = {}
        if self:loadGroundAnimationMapping(xmlFile, nodeBaseName, mapping, j) then
            table.insert(animation.mappings, mapping)
        end
        j = j + 1
    end
    local nodeBaseName = self.xmlFile:getValue(key .. "#file")
    if nodeBaseName ~= nil then
        local mapping = Utils.getFilename(nodeBaseName, self.baseDirectory)
        animation.sharedLoadRequestId = self:loadSubSharedI3DFile(mapping, false, false, self.onGroundAnimationI3DLoaded, self, {
            ["filename"] = mapping,
            ["animation"] = animation
        })
    end
    return true
end
function WorkParticles.onGroundAnimationI3DLoaded(_, i3dNode, args)
    if i3dNode ~= 0 then
        local animation = args.animation
        for _, mapping in ipairs(animation.mappings) do
            link(mapping.node, mapping.animNode)
            setVisibility(mapping.animNode, false)
        end
        animation.filename = args.filename
        delete(i3dNode)
    end
end
function WorkParticles:loadGroundAnimationMapping(xmlFile, key, mapping, _)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#index", key .. "#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#animMeshIndex", key .. "#animMeshNode")
    local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
    if node == nil then
        Logging.xmlWarning(self.xmlFile, "Invalid node \'%s\' for \'%s\'", getXMLString(xmlFile.handle, key .. "#node"), key)
        return false
    end
    local groundRefIndex = xmlFile:getValue(key .. "#refNodeIndex")
    if groundRefIndex == nil or self:getGroundReferenceNodeFromIndex(groundRefIndex) == nil then
        Logging.xmlWarning(self.xmlFile, "Invalid refNodeIndex \'%s\' for \'%s\'", xmlFile:getValue(key .. "#refNodeIndex"), key)
        return false
    end
    local animMeshNode = xmlFile:getValue(key .. "#animMeshNode")
    local animNode
    if animMeshNode == nil then
        local materialType = xmlFile:getValue(key .. "#materialType")
        local materialId = xmlFile:getValue(key .. "#materialId", 1)
        if materialType == nil then
            Logging.xmlWarning(self.xmlFile, "Missing materialType in \'%s\'", key)
            return false
        end
        local material = g_materialManager:getBaseMaterialByName(materialType)
        if material == nil then
            Logging.xmlWarning(self.xmlFile, "Invalid materialType \'%s\' or materialId \'%s\' in \'%s\'", materialType, materialId, key)
        else
            setMaterial(node, material, 0)
        end
        setVisibility(node, false)
        animNode = node
    else
        animNode = I3DUtil.indexToObject(node, animMeshNode, self.i3dMappings)
        if animNode == nil then
            Logging.xmlWarning(self.xmlFile, "Invalid animMesh node \'%s\' \'%s\'", xmlFile:getValue(key .. "#animMeshNode"), key)
            return false
        end
    end
    mapping.node = node
    mapping.animNode = animNode
    mapping.groundRefNode = self:getGroundReferenceNodeFromIndex(groundRefIndex)
    mapping.lastDepth = 0
    mapping.speed = 0
    mapping.maxWorkDepth = xmlFile:getValue(key .. "#maxDepth", -0.1)
    return true
end
function WorkParticles:loadGroundParticles(xmlFile, key, particle, _)
    particle.mappings = {}
    local filename = xmlFile:getValue(key .. "#file")
    if filename == nil then
        local arguments = 0
        while true do
            local nodeBaseName = string.format(key .. ".node(%d)", arguments)
            if not xmlFile:hasProperty(nodeBaseName) then
                break
            end
            local mapping = {}
            if self:loadGroundParticleMapping(xmlFile, nodeBaseName, mapping, arguments) then
                table.insert(particle.mappings, mapping)
            end
            arguments = arguments + 1
        end
    else
        local arguments = Utils.getFilename(filename, self.baseDirectory)
        particle.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(arguments, false, false, self.groundParticleI3DLoaded, self, {
            ["xmlFile"] = xmlFile,
            ["key"] = key,
            ["particle"] = particle,
            ["filename"] = arguments
        })
    end
    return true
end
function WorkParticles:groundParticleI3DLoaded(i3dNode, _, args)
    local j = 0
    while true do
        local nodeBaseName = string.format(args.key .. ".node(%d)", j)
        if not args.xmlFile:hasProperty(nodeBaseName) then
            break
        end
        local mapping = {}
        if self:loadGroundParticleMapping(xmlFile, nodeBaseName, mapping, j, i3dNode) then
            table.insert(args.particle.mappings, mapping)
        end
        j = j + 1
    end
    if i3dNode ~= 0 then
        for _, mapping in ipairs(particle.mappings) do
            link(mapping.node, mapping.particleNode)
            ParticleUtil.loadParticleSystemFromNode(mapping.particleNode, mapping.particleSystem, false, true)
        end
        particle.filename = args.filename
        delete(i3dNode)
    end
end
function WorkParticles:loadGroundParticleMapping(xmlFile, key, mapping, _, i3dNode)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#index", key .. "#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#particleIndex", key .. "#particleNode")
    mapping.particleSystem = {}
    local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
    if node == nil then
        Logging.xmlWarning(self.xmlFile, "Invalid node \'%s\' for \'%s\'", xmlFile:getValue(key .. "#node"), key)
        return false
    end
    local groundRefIndex = xmlFile:getValue(key .. "#refNodeIndex")
    if groundRefIndex == nil or self:getGroundReferenceNodeFromIndex(groundRefIndex) == nil then
        Logging.xmlWarning(self.xmlFile, "Invalid refNodeIndex \'%s\' for \'%s\'", xmlFile:getValue(key .. "#refNodeIndex"), key)
        return false
    end
    local particleNodeIndex = xmlFile:getValue(key .. "#particleNode")
    local particleNode
    if particleNodeIndex == nil then
        local particleType = xmlFile:getValue(key .. "#particleType")
        if particleType == nil then
            Logging.xmlWarning(self.xmlFile, "Missing particleType in \'%s\'", key)
            return false
        end
        local fillTypeStr = xmlFile:getValue(key .. "#fillType")
        local fillType = Utils.getNoNil(g_fillTypeManager:getFillTypeIndexByName(fillTypeStr), FillType.UNKNOWN)
        local particleSystem = g_particleSystemManager:getParticleSystem(particleType)
        if particleSystem == nil then
            return false
        end
        if fillType ~= FillType.UNKNOWN then
            local material = g_materialManager:getParticleMaterial(fillType, particleType, 1)
            if material ~= nil then
                ParticleUtil.setMaterial(particleSystem, material)
            end
        end
        mapping.particleSystem = ParticleUtil.copyParticleSystem(xmlFile, key, particleSystem, node)
        particleNode = node
    else
        particleNode = I3DUtil.indexToObject(i3dNode, particleNodeIndex, self.i3dMappings)
        if particleNode == nil then
            Logging.xmlWarning(self.xmlFile, "Invalid particle node \'%s\' \'%s\'", xmlFile:getValue(key .. "#particleNode"), key)
            return false
        end
    end
    mapping.node = node
    mapping.particleNode = particleNode
    mapping.groundRefNode = self:getGroundReferenceNodeFromIndex(groundRefIndex)
    mapping.speedThreshold = xmlFile:getValue(key .. "#speedThreshold", 0.5)
    mapping.movingDirection = xmlFile:getValue(key .. "#movingDirection")
    return true
end
function WorkParticles:loadGroundEffects(xmlFile, key, effect, _)
    effect.speedThreshold = xmlFile:getValue(key .. "#speedThreshold", 0.5)
    effect.activeDirection = xmlFile:getValue(key .. "#activeDirection", 1)
    effect.workAreaIndex = xmlFile:getValue(key .. "#workAreaIndex")
    effect.groundReferenceNodeIndex = xmlFile:getValue(key .. "#groundReferenceNodeIndex")
    effect.needsSetIsTurnedOn = xmlFile:getValue(key .. "#needsSetIsTurnedOn", false)
    effect.effect = g_effectManager:loadEffect(xmlFile, key, self.components, self, self.i3dMappings)
    return true
end
function WorkParticles:getFillTypeFromWorkAreaIndex(workAreaIndex)
    local fillType = FillType.UNKNOWN
    local workArea = self:getWorkAreaByIndex(workAreaIndex)
    if workArea ~= nil then
        if workArea.fillType ~= nil then
            return workArea.fillType
        end
        if workArea.fruitType ~= nil then
            fillType = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(workArea.fruitType)
        end
    end
    return fillType
end
function WorkParticles:loadGroundReferenceNode(superFunc, xmlFile, key, groundReferenceNode)
    local returnValue = superFunc(self, xmlFile, key, groundReferenceNode)
    if returnValue then
        groundReferenceNode.depthNode = xmlFile:getValue(key .. "#depthNode", nil, self.components, self.i3dMappings)
        groundReferenceNode.movedDistance = 0
        groundReferenceNode.depth = 0
        groundReferenceNode.movingDirection = 0
    end
    return returnValue
end
function WorkParticles:updateGroundReferenceNode(superFunc, groundReferenceNode, x, y, z, terrainHeight, densityHeight)
    superFunc(self, groundReferenceNode, x, y, z, terrainHeight, densityHeight)
    if self.isClient and groundReferenceNode.depthNode ~= nil then
        local newX, newY, newZ = getWorldTranslation(groundReferenceNode.depthNode)
        if groundReferenceNode.lastPosition == nil then
            groundReferenceNode.lastPosition = { newX, newY, newZ }
        end
        local dx, dy, dz = worldDirectionToLocal(groundReferenceNode.depthNode, newX - groundReferenceNode.lastPosition[1], newY - groundReferenceNode.lastPosition[2], newZ - groundReferenceNode.lastPosition[3])
        groundReferenceNode.movingDirection = 0
        if dz > 0.0001 then
            groundReferenceNode.movingDirection = 1
        elseif dz < -0.0001 then
            groundReferenceNode.movingDirection = -1
        end
        groundReferenceNode.movedDistance = MathUtil.vector3Length(dx, dy, dz)
        groundReferenceNode.lastPosition[1] = newX
        groundReferenceNode.lastPosition[2] = newY
        groundReferenceNode.lastPosition[3] = newZ
        groundReferenceNode.depth = newY - getTerrainHeightAtWorldPos(g_terrainNode, newX, newY, newZ)
    end
end
function WorkParticles:onDeactivate()
    local spec = self.spec_workParticles
    for _, ps in pairs(spec.particles) do
        for _, mapping in ipairs(ps.mappings) do
            ParticleUtil.setEmittingState(mapping.particleSystem, false)
        end
    end
    for _, ps in ipairs(spec.particleAnimations) do
        for _, mapping in ipairs(ps.mappings) do
            setVisibility(mapping.animNode, false)
        end
    end
end