ParticleUtil = {}
function ParticleUtil.loadParticleSystemData(xmlFile, data, baseString)
    if type(xmlFile) == "table" then
    end
    data.nodeStr = getXMLString(xmlFile, baseString .. "#node")
    data.psFile = getXMLString(xmlFile, baseString .. "#file")
    local position = string.getVector(getXMLString(xmlFile, baseString .. "#position"), 3)
    if position ~= nil then
        data.posX, data.posY, data.posZ = unpack(position)
    end
    local rotation = string.getVector(getXMLString(xmlFile, baseString .. "#rotation"), 3)
    if rotation ~= nil then
        data.rotX = MathUtil.degToRad(rotation[1])
        data.rotY = MathUtil.degToRad(rotation[2])
        data.rotZ = MathUtil.degToRad(rotation[3])
    end
    data.worldSpace = Utils.getNoNil(getXMLBool(xmlFile, baseString .. "#worldSpace"), true)
    data.psRootNodeStr = getXMLString(xmlFile, baseString .. "#particleNode")
    data.forceFullLifespan = Utils.getNoNil(getXMLBool(xmlFile, baseString .. "#forceFullLifespan"), false)
    data.useEmitterVisibility = Utils.getNoNil(getXMLBool(xmlFile, baseString .. "#useEmitterVisibility"), false)
end
function ParticleUtil.loadParticleSystem(xmlFile, particleSystem, baseString, linkNodes, defaultEmittingState, defaultPsFile, baseDir, defaultLinkNode)
    local data = {}
    ParticleUtil.loadParticleSystemData(xmlFile, data, baseString)
    return ParticleUtil.loadParticleSystemFromData(data, particleSystem, linkNodes, defaultEmittingState, defaultPsFile, baseDir, defaultLinkNode)
end
function ParticleUtil.loadParticleSystemFromData(data, particleSystem, linkNodes, defaultEmittingState, defaultPsFile, baseDir, defaultLinkNode)
    if defaultLinkNode == nil then
        if type(linkNodes) == "table" then
            defaultLinkNode = linkNodes[1].node
        else
            defaultLinkNode = linkNodes
        end
    end
    local linkNode = Utils.getNoNil(I3DUtil.indexToObject(linkNodes, data.nodeStr), defaultLinkNode)
    local psFile = data.psFile
    if psFile ~= nil then
        defaultPsFile = psFile
    end
    if defaultPsFile ~= nil then
        local arguments = Utils.getFilename(defaultPsFile, baseDir)
        particleSystem.isValid = false
        particleSystem.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(arguments, true, true, ParticleUtil.particleI3DFileLoaded, ParticleUtil, {
            ["data"] = data,
            ["particleSystem"] = particleSystem,
            ["linkNode"] = linkNode,
            ["psFile"] = arguments,
            ["defaultEmittingState"] = defaultEmittingState
        })
        return true
    end
end
function ParticleUtil.particleI3DFileLoaded(_, i3dNode, _, args)
    if i3dNode == 0 then
        printError("Error: failed to load particle system " .. args.psFile)
    else
        local newRootNode
        if args.data.psRootNodeStr == nil then
            newRootNode = getChildAt(i3dNode, 0)
        else
            newRootNode = I3DUtil.indexToObject(i3dNode, data.psRootNodeStr)
            if newRootNode == nil then
                newRootNode = i3dNode
            end
        end
        if args.linkNode ~= nil then
            link(linkNode, newRootNode)
        end
        local newRootNode = data.posX
        local posY = data.posY
        local posZ = data.posZ
        if newRootNode ~= nil and (posY ~= nil and posZ ~= nil) then
            setTranslation(newRootNode, newRootNode, posY, posZ)
        end
        local rotX = data.rotX
        local rotY = data.rotY
        local rotZ = data.rotZ
        if rotX ~= nil and (rotY ~= nil and rotZ ~= nil) then
            setRotation(newRootNode, rotX, rotY, rotZ)
        end
        ParticleUtil.loadParticleSystemFromNode(newRootNode, args.particleSystem, args.defaultEmittingState, data.worldSpace, data.forceFullLifespan, psFile)
        if newRootNode ~= i3dNode then
            delete(i3dNode)
        end
    end
end
function ParticleUtil.loadParticleSystemFromNode(rootNode, particleSystem, defaultEmittingState, worldSpace, forceFullLifespan)
    defaultEmittingState = defaultEmittingState == nil and true or defaultEmittingState
    if getHasClassId(rootNode, ClassIds.SHAPE) then
        local geometry = getGeometry(rootNode)
        if geometry ~= 0 and getHasClassId(geometry, ClassIds.PARTICLE_SYSTEM) then
            particleSystem.emitterShape = getEmitterShape(geometry)
            particleSystem.emitterShapeSize = getEmitterSurfaceSize(geometry)
            particleSystem.defaultEmitterShapeSize = getEmitterSurfaceSize(geometry)
            if worldSpace then
                local parent = getParent(rootNode)
                if particleSystem.emitterShape ~= 0 and getParent(particleSystem.emitterShape) == rootNode then
                    local x, y, z = getScale(particleSystem.emitterShape)
                    setTranslation(particleSystem.emitterShape, worldToLocal(parent, getWorldTranslation(particleSystem.emitterShape)))
                    local dx, dy, dz = worldDirectionToLocal(rootNode, localDirectionToWorld(particleSystem.emitterShape, 0, 0, 1))
                    local upx, upy, upz = worldDirectionToLocal(rootNode, localDirectionToWorld(particleSystem.emitterShape, 0, 1, 0))
                    setDirection(particleSystem.emitterShape, dx, dy, dz, upx, upy, upz)
                    link(parent, particleSystem.emitterShape)
                    setScale(particleSystem.emitterShape, x, y, z)
                end
                link(getRootNode(), rootNode)
                setTranslation(rootNode, 0, 0, 0)
                setRotation(rootNode, 0, 0, 0)
            end
            setObjectMask(rootNode, 16711807)
            particleSystem.geometry = geometry
            particleSystem.shape = rootNode
            particleSystem.worldSpace = worldSpace
            particleSystem.forceFullLifespan = forceFullLifespan
            particleSystem.originalLifespan = getParticleSystemLifespan(geometry)
            particleSystem.isValid = true
            setEmittingState(geometry, defaultEmittingState)
        end
    end
    particleSystem.isEmitting = defaultEmittingState
    return rootNode
end
function ParticleUtil.deleteParticleSystem(particleSystem)
    if particleSystem ~= nil and particleSystem.shape ~= nil then
        if entityExists(particleSystem.shape) then
            delete(particleSystem.shape)
        end
        particleSystem.shape = nil
        if particleSystem.sharedLoadRequestId ~= nil then
            g_i3DManager:releaseSharedI3DFile(particleSystem.sharedLoadRequestId)
            particleSystem.sharedLoadRequestId = nil
        end
    end
end
function ParticleUtil.deleteParticleSystems(particleSystems)
    if particleSystems ~= nil then
        for _, ps in pairs(particleSystems) do
            ParticleUtil.deleteParticleSystem(ps)
        end
    end
end
function ParticleUtil.setEmittingState(particleSystem, state, resetStartTimer, resetStopTimer)
    if particleSystem ~= nil and (particleSystem.isValid and particleSystem.isEmitting ~= state) then
        particleSystem.isEmitting = state
        resetStartTimer = resetStartTimer == nil and true or resetStartTimer
        resetStopTimer = resetStopTimer == nil and true or resetStopTimer
        if state then
            if resetStartTimer then
                resetEmitStartTimer(particleSystem.geometry)
            end
        elseif resetStopTimer then
            resetEmitStopTimer(particleSystem.geometry)
        end
        setEmittingState(particleSystem.geometry, state)
        if state and particleSystem.useEmitterVisibility then
            setVisibility(particleSystem.shape, getEffectiveVisibility(particleSystem.emitterShape))
        end
    end
end
function ParticleUtil.getParticleSystemAverageSpeed(particleSystem)
    if particleSystem == nil or not particleSystem.isValid then
        return nil
    else
        return getParticleSystemAverageSpeed(particleSystem.geometry)
    end
end
function ParticleUtil.setParticleSystemTimeScale(particleSystem, scale)
    if particleSystem ~= nil and (particleSystem.isValid and scale ~= nil) then
        setParticleSystemTimeScale(particleSystem.geometry, scale)
    end
end
function ParticleUtil.setEmitCountScale(particleSystem, scale)
    if particleSystem ~= nil and (particleSystem.isValid and scale ~= nil) then
        setEmitCountScale(particleSystem.geometry, scale)
    end
end
function ParticleUtil.setParticleLifespan(particleSystem, lifespan)
    if particleSystem ~= nil and (particleSystem.isValid and lifespan ~= nil) then
        setParticleSystemLifespan(particleSystem.geometry, lifespan, true)
    end
end
function ParticleUtil.addParticleSystemSimulationTime(particleSystem, simTime)
    if particleSystem ~= nil and (particleSystem.isValid and simTime ~= nil) then
        addParticleSystemSimulationTime(particleSystem.geometry, simTime)
    end
end
function ParticleUtil.setParticleStartStopTime(particleSystem, startTime, stopTime)
    if particleSystem ~= nil and (particleSystem.isValid and (startTime ~= nil and stopTime ~= nil)) then
        setEmitStartTime(particleSystem.geometry, startTime * 1000)
        setEmitStopTime(particleSystem.geometry, stopTime * 1000)
    end
end
function ParticleUtil.getParticleSystemSpeed(particleSystem)
    if particleSystem == nil or not particleSystem.isValid then
        return nil
    else
        return getParticleSystemSpeed(particleSystem.geometry)
    end
end
function ParticleUtil.setParticleSystemSpeed(particleSystem, speed)
    if particleSystem ~= nil and (particleSystem.isValid and speed ~= nil) then
        setParticleSystemSpeed(particleSystem.geometry, speed)
    end
end
function ParticleUtil.getParticleSystemSpeedRandom(particleSystem)
    if particleSystem == nil or not particleSystem.isValid then
        return nil
    else
        return getParticleSystemSpeedRandom(particleSystem.geometry)
    end
end
function ParticleUtil.setParticleSystemSpeedRandom(particleSystem, randomSpeed)
    if particleSystem ~= nil and (particleSystem.isValid and randomSpeed ~= nil) then
        setParticleSystemSpeedRandom(particleSystem.geometry, randomSpeed)
    end
end
function ParticleUtil.getParticleSystemNormalSpeed(particleSystem)
    if particleSystem == nil or not particleSystem.isValid then
        return nil
    else
        return getParticleSystemNormalSpeed(particleSystem.geometry)
    end
end
function ParticleUtil.setParticleSystemNormalSpeed(particleSystem, normalSpeed)
    if particleSystem ~= nil and (particleSystem.isValid and normalSpeed ~= nil) then
        setParticleSystemNormalSpeed(particleSystem.geometry, normalSpeed)
    end
end
function ParticleUtil.getParticleSystemTangentSpeed(particleSystem)
    if particleSystem == nil or not particleSystem.isValid then
        return nil
    else
        return getParticleSystemTangentSpeed(particleSystem.geometry)
    end
end
function ParticleUtil.setParticleSystemTangentSpeed(particleSystem, tangentSpeed)
    if particleSystem ~= nil and (particleSystem.isValid and tangentSpeed ~= nil) then
        setParticleSystemTangentSpeed(particleSystem.geometry, tangentSpeed)
    end
end
function ParticleUtil.getParticleSystemSpriteScaleX(particleSystem)
    if particleSystem == nil or not particleSystem.isValid then
        return nil
    else
        return getParticleSystemSpriteScaleX(particleSystem.geometry)
    end
end
function ParticleUtil.setParticleSystemSpriteScaleX(particleSystem, spriteScaleX)
    if particleSystem ~= nil and (particleSystem.isValid and spriteScaleX ~= nil) then
        setParticleSystemSpriteScaleX(particleSystem.geometry, spriteScaleX)
    end
end
function ParticleUtil.getParticleSystemSpriteScaleY(particleSystem)
    if particleSystem == nil or not particleSystem.isValid then
        return nil
    else
        return getParticleSystemSpriteScaleY(particleSystem.geometry)
    end
end
function ParticleUtil.setParticleSystemSpriteScaleY(particleSystem, spriteScaleY)
    if particleSystem ~= nil and (particleSystem.isValid and spriteScaleY ~= nil) then
        setParticleSystemSpriteScaleY(particleSystem.geometry, spriteScaleY)
    end
end
function ParticleUtil.getParticleSystemSpriteScaleXGain(particleSystem)
    if particleSystem == nil or not particleSystem.isValid then
        return nil
    else
        return getParticleSystemSpriteScaleXGain(particleSystem.geometry)
    end
end
function ParticleUtil.setParticleSystemSpriteScaleXGain(particleSystem, spriteScaleXGain)
    if particleSystem ~= nil and (particleSystem.isValid and spriteScaleXGain ~= nil) then
        setParticleSystemSpriteScaleXGain(particleSystem.geometry, spriteScaleXGain)
    end
end
function ParticleUtil.getParticleSystemSpriteScaleYGain(particleSystem)
    if particleSystem == nil or not particleSystem.isValid then
        return nil
    else
        return getParticleSystemSpriteScaleYGain(particleSystem.geometry)
    end
end
function ParticleUtil.setParticleSystemSpriteScaleYGain(particleSystem, spriteScaleYGain)
    if particleSystem ~= nil and (particleSystem.isValid and spriteScaleYGain ~= nil) then
        setParticleSystemSpriteScaleYGain(particleSystem.geometry, spriteScaleYGain)
    end
end
function ParticleUtil.getParticleSystemVelocityScale(particleSystem)
    if particleSystem == nil or not particleSystem.isValid then
        return nil
    else
        return getEmitterShapeVelocityScale(particleSystem.geometry)
    end
end
function ParticleUtil.setParticleSystemVelocityScale(particleSystem, velocityScale)
    if particleSystem ~= nil and (particleSystem.isValid and velocityScale ~= nil) then
        setEmitterShapeVelocityScale(particleSystem.geometry, velocityScale)
    end
end
function ParticleUtil.resetNumOfEmittedParticles(particleSystem)
    if particleSystem ~= nil and particleSystem.isValid then
        resetNumOfEmittedParticles(particleSystem.geometry)
    end
end
function ParticleUtil.setEmitterShape(particleSystem, emitterShape)
    if particleSystem ~= nil and (particleSystem.isValid and (emitterShape ~= nil and (particleSystem.geometry ~= nil and (particleSystem.geometry ~= 0 and getHasClassId(particleSystem.geometry, ClassIds.PARTICLE_SYSTEM))))) then
        if not getHasClassId(emitterShape, ClassIds.SHAPE) then
            Logging.warning("Trying to set an emitter shape for a particle system but given node (\'%s\') is not a shape. Ignoring it!", getName(emitterShape))
            return
        end
        setEmitterShape(particleSystem.geometry, emitterShape)
        particleSystem.emitterShape = emitterShape
        particleSystem.emitterShapeSize = getEmitterSurfaceSize(particleSystem.geometry)
    end
end
function ParticleUtil.initEmitterScale(particleSystem, scale)
    if particleSystem ~= nil and particleSystem.isValid then
        if particleSystem.baseNumOfParticlesToEmitPerMs == nil then
            particleSystem.baseNumOfParticlesToEmitPerMs = getNumOfParticlesToEmitPerMs(particleSystem.geometry)
        end
        setNumOfParticlesToEmitPerMs(particleSystem.geometry, particleSystem.baseNumOfParticlesToEmitPerMs * scale)
        if particleSystem.baseMaxNumOfParticles == nil then
            particleSystem.baseMaxNumOfParticles = getMaxNumOfParticles(particleSystem.geometry)
        end
        setMaxNumOfParticles(particleSystem.geometry, (math.ceil(particleSystem.baseMaxNumOfParticles * scale)))
    end
end
function ParticleUtil.setMaxNumOfParticlesToEmitScale(particleSystem, scale)
    if particleSystem ~= nil and particleSystem.isValid then
        if particleSystem.baseNumOfParticlesToEmitPerMs == nil then
            particleSystem.baseNumOfParticlesToEmitPerMs = getNumOfParticlesToEmitPerMs(particleSystem.geometry)
        end
        setNumOfParticlesToEmitPerMs(particleSystem.geometry, particleSystem.baseNumOfParticlesToEmitPerMs * scale)
    end
end
function ParticleUtil.setMaterial(particleSystem, material)
    if particleSystem ~= nil and particleSystem.isValid then
        setMaterial(particleSystem.shape, material, 0)
    end
end
function ParticleUtil.copyParticleSystem(xmlFile, key, particleSystem, emitterShape)
    local currentPS = {
        ["worldSpace"] = true,
        ["emitCountScale"] = 1,
        ["useEmitterVisibility"] = false
    }
    if key ~= nil then
        currentPS.worldSpace = xmlFile:getValue(key .. "#worldSpace", currentPS.worldSpace)
        currentPS.emitCountScale = xmlFile:getValue(key .. "#emitCountScale", currentPS.emitCountScale)
        currentPS.delay = xmlFile:getValue(key .. "#delay")
        currentPS.startTime = xmlFile:getValue(key .. "#startTime", currentPS.delay)
        currentPS.stopTime = xmlFile:getValue(key .. "#stopTime", currentPS.delay)
        currentPS.lifespan = xmlFile:getValue(key .. "#lifespan")
        currentPS.useEmitterVisibility = xmlFile:getValue(key .. "#useEmitterVisibility", currentPS.useEmitterVisibility)
    end
    currentPS.isValid = true
    local psClone = clone(particleSystem.shape, true, false, true)
    setObjectMask(psClone, 16711807)
    ParticleUtil.loadParticleSystemFromNode(psClone, currentPS, false, currentPS.worldSpace, particleSystem.forceFullLifespan)
    if emitterShape ~= nil then
        local scale = clone(emitterShape, true, false, false)
        ParticleUtil.setEmitterShape(currentPS, scale)
        local scale = currentPS.emitterShapeSize / currentPS.defaultEmitterShapeSize * currentPS.emitCountScale
        ParticleUtil.initEmitterScale(currentPS, scale)
        ParticleUtil.setEmitCountScale(currentPS, 1)
        if currentPS.lifespan ~= nil then
            ParticleUtil.setParticleLifespan(currentPS, currentPS.lifespan * 1000)
            currentPS.originalLifespan = currentPS.lifespan * 1000
        end
        ParticleUtil.setParticleStartStopTime(currentPS, currentPS.startTime, currentPS.stopTime)
        if not currentPS.worldSpace then
            link(getParent(scale), currentPS.shape, getChildIndex(scale))
            setTranslation(currentPS.shape, getTranslation(scale))
            setRotation(currentPS.shape, getRotation(scale))
            link(currentPS.shape, scale)
            setTranslation(scale, 0, 0, 0)
            setRotation(scale, 0, 0, 0)
        end
    end
    return currentPS
end
function ParticleUtil.registerParticleXMLPaths(schema, basePath, name)
    schema:setXMLSharedRegistration("ParticleSystem", basePath)
    basePath = basePath .. "." .. name
    schema:register(XMLValueType.STRING, basePath .. "#node", "Particle link node")
    schema:register(XMLValueType.STRING, basePath .. "#file", "Particle file name")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#position", "Particle position")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Particle rotation")
    schema:register(XMLValueType.BOOL, basePath .. "#worldSpace", "Is world space", true)
    schema:register(XMLValueType.STRING, basePath .. "#particleNode", "Particle node in loaded file")
    schema:register(XMLValueType.BOOL, basePath .. "#forceFullLifespan", "Force full lifespan", false)
    schema:register(XMLValueType.BOOL, basePath .. "#useEmitterVisibility", "Use emitter visibility to show/hide particles", false)
    schema:resetXMLSharedRegistration("ParticleSystem", basePath)
end
function ParticleUtil.registerParticleCopyXMLPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. "#worldSpace", "Is world space", true)
    schema:register(XMLValueType.FLOAT, basePath .. "#emitCountScale", "Emit count scale", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#delay", "Activation delay")
    schema:register(XMLValueType.FLOAT, basePath .. "#startTime", "Start time", "Delay value")
    schema:register(XMLValueType.FLOAT, basePath .. "#stopTime", "Stop time", "Delay value")
    schema:register(XMLValueType.FLOAT, basePath .. "#lifespan", "Lifespan")
    schema:register(XMLValueType.BOOL, basePath .. "#useEmitterVisibility", "use emitter shape visibility", true)
end