ParticleSystemManager = {}
ParticleType = nil
local ParticleSystemManager_mt = Class(ParticleSystemManager, AbstractManager)
function ParticleSystemManager.new(customMt)
    -- upvalues: (copy) ParticleSystemManager_mt
    return AbstractManager.new(customMt or ParticleSystemManager_mt)
end
function ParticleSystemManager:initDataStructures()
    self.nameToIndex = {}
    self.particleTypes = {}
    self.particleSystems = {}
end
function ParticleSystemManager:loadMapData()
    ParticleSystemManager:superClass().loadMapData(self)
    self:addParticleType("unloading")
    self:addParticleType("smoke")
    self:addParticleType("smoke_damping")
    self:addParticleType("smoke_chimney")
    self:addParticleType("smoke_train_main")
    self:addParticleType("smoke_train_side")
    self:addParticleType("chopper")
    self:addParticleType("straw")
    self:addParticleType("cutter_chopper")
    self:addParticleType("soil")
    self:addParticleType("soil_smoke")
    self:addParticleType("soil_chunks")
    self:addParticleType("soil_big_chunks")
    self:addParticleType("soil_harvesting")
    self:addParticleType("spreader")
    self:addParticleType("spreader_smoke")
    self:addParticleType("windrower")
    self:addParticleType("tedder")
    self:addParticleType("weeder")
    self:addParticleType("crusher_wood")
    self:addParticleType("crusher_dust")
    self:addParticleType("prepare_fruit")
    self:addParticleType("cleaning_soil")
    self:addParticleType("cleaning_dust")
    self:addParticleType("washer_water")
    self:addParticleType("chainsaw_wood")
    self:addParticleType("chainsaw_dust")
    self:addParticleType("pickup")
    self:addParticleType("pickup_falling")
    self:addParticleType("sowing")
    self:addParticleType("loading")
    self:addParticleType("wheel_dust")
    self:addParticleType("wheel_dry")
    self:addParticleType("wheel_wet")
    self:addParticleType("wheel_snow")
    self:addParticleType("bees")
    self:addParticleType("horse_step_slow")
    self:addParticleType("horse_step_fast")
    self:addParticleType("spraycan_paint")
    self:addParticleType("HYDRAULIC_HAMMER")
    self:addParticleType("HYDRAULIC_HAMMER_DEBRIS")
    self:addParticleType("STONE")
    ParticleType = self.nameToIndex
    return true
end
function ParticleSystemManager:unloadMapData()
    for _, fillTypeParticleSystem in pairs(self.particleSystems) do
        ParticleUtil.deleteParticleSystem(fillTypeParticleSystem)
    end
    ParticleSystemManager:superClass().unloadMapData(self)
end
function ParticleSystemManager:addParticleType(name)
    if not ClassUtil.getIsValidIndexName(name) then
        printWarning("Warning: \'" .. tostring(name) .. "\' is not a valid name for a particleType. Ignoring it!")
        return nil
    end
    name = string.upper(name)
    if self.nameToIndex[name] == nil then
        table.insert(self.particleTypes, name)
        self.nameToIndex[name] = #self.particleTypes
    end
    return nil
end
function ParticleSystemManager:getParticleSystemTypeByName(name)
    if name ~= nil then
        name = string.upper(name)
        if self.nameToIndex[name] ~= nil then
            return name
        end
    end
    return nil
end
function ParticleSystemManager:addParticleSystem(particleType, particleSystem)
    if self.particleSystems[particleType] ~= nil then
        ParticleUtil.deleteParticleSystem(self.particleSystems[particleType])
    end
    self.particleSystems[particleType] = particleSystem
end
function ParticleSystemManager:getParticleSystem(particleTypeName)
    local particleType = self:getParticleSystemTypeByName(particleTypeName)
    if particleType == nil then
        return nil
    else
        return self.particleSystems[particleType]
    end
end
function ParticleSystemManager:consoleCommandDebug()
    if ParticleSystemManager.debugRootNode == nil then
        ParticleSystemManager.debugRootNode = createTransformGroup("ParticleSystemManager_DebugRootNode")
        link(getRootNode(), ParticleSystemManager.debugRootNode)
        local x, y, z = g_localPlayer:getPosition()
        local dirX, dirZ = g_localPlayer:getCurrentFacingDirection()
        local ry = MathUtil.getYRotationFromDirection(dirX, dirZ)
        setWorldTranslation(ParticleSystemManager.debugRootNode, x + dirX * 10, y + 2, z + dirZ * 10)
        setWorldRotation(ParticleSystemManager.debugRootNode, 0, ry, 0)
    else
        local dirX = getNumOfChildren(ParticleSystemManager.debugRootNode)
        for z = 1, dirX do
            local dirX = getChildAt(ParticleSystemManager.debugRootNode, 0)
            delete(dirX)
        end
    end
    if ParticleSystemManager.debugParticleSystems == nil then
        ParticleSystemManager.debugParticleSystems = {}
    else
        for dirX, dirZ in pairs(ParticleSystemManager.debugParticleSystems) do
            ParticleUtil.deleteParticleSystem(dirZ)
        end
    end
    local x = 0
    for dirZ, ry in pairs(g_fillTypeManager.fillTypes) do
        ry:reloadData()
        if ry.prioritizedEffectType == "ParticleEffect" then
            local sourceParticleSystem = self:getParticleSystem("unloading")
            if sourceParticleSystem ~= nil then
                local psClone = clone(sourceParticleSystem.shape, true, false, true)
                local emitterShape = clone(sourceParticleSystem.emitterShape, true, false, false)
                link(ParticleSystemManager.debugRootNode, emitterShape)
                setTranslation(emitterShape, x * 3, 0, 0)
                local particleSystem = {}
                ParticleUtil.loadParticleSystemFromNode(psClone, particleSystem, false, true, sourceParticleSystem.forceFullLifespan)
                ParticleUtil.setEmitterShape(particleSystem, emitterShape)
                ry:setParticleSystemFillType(particleSystem, "unloading", "unloadingParticle", false, 1)
                ParticleUtil.setEmittingState(particleSystem, true)
                table.insert(ParticleSystemManager.debugParticleSystems, particleSystem)
                local wx, wy, wz = getWorldTranslation(emitterShape)
                local rx, ry, rz = localRotationToWorld(emitterShape, 0, 3.141592653589793, 0)
                g_debugManager:addElement(DebugText3D.new():createWithWorldPos(wx, wy + 1.3, wz, rx, ry, rz, ry.name, 0.15), nil, nil, math.huge)
                x = x + 1
            end
        end
    end
end
g_particleSystemManager = ParticleSystemManager.new()
addConsoleCommand("gsParticleSystemDebug", "Debug particle effect", "consoleCommandDebug", g_particleSystemManager)