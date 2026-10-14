ParticleEffect = {}
local ParticleEffect_mt = Class(ParticleEffect, Effect)
function ParticleEffect.new(customMt)
    -- upvalues: (copy) ParticleEffect_mt
    local self = Effect.new(customMt or ParticleEffect_mt)
    self.isActive = false
    self.currentFillTypeIndex = FillType.UNKNOWN
    return self
end
function ParticleEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
    if not ParticleEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
        return false
    end
    self.emitterShape = self.node
    self.emitCountScale = Effect.getValue(xmlFile, key, node, "emitCountScale", 1)
    self.particleType = Effect.getValue(xmlFile, key, node, "particleType", "unloading")
    self.materialType = Effect.getValue(xmlFile, key, node, "materialType")
    self.useFruitColor = Effect.getValue(xmlFile, key, node, "useFruitColor", false)
    self.worldSpace = Effect.getValue(xmlFile, key, node, "worldSpace", true)
    self.delay = Effect.getValue(xmlFile, key, node, "delay", 0)
    self.startTime = Effect.getValue(xmlFile, key, node, "startTime", self.delay)
    self.startTimeMs = self.startTime * 1000
    self.stopTime = Effect.getValue(xmlFile, key, node, "stopTime", self.delay)
    self.stopTimeMs = self.stopTime * 1000
    self.lifespan = Effect.getValue(xmlFile, key, node, "lifespan")
    self.extraDistance = Effect.getValue(xmlFile, key, node, "extraDistance", 0.5)
    self.ignoreDistanceLifeSpan = Effect.getValue(xmlFile, key, node, "ignoreDistanceLifeSpan", false)
    self.alphaScale = Effect.getValue(xmlFile, key, node, "alphaScale", 1)
    self.velocityScale = Effect.getValue(xmlFile, key, node, "velocityScale")
    if string.lower(self.particleType) == "unloading" and self.materialType == nil then
        Logging.xmlWarning(xmlFile, "ParticleEffect \'%s\' is missing the \'materialType\' attribute.", key)
        return false
    end
    self.spriteScale = Effect.getValue(xmlFile, key, node, "spriteScale", 1)
    self.spriteGainScale = Effect.getValue(xmlFile, key, node, "spriteGainScale", self.spriteScale)
    self.speedScale = Effect.getValue(xmlFile, key, node, "speedScale", 1)
    self.realStartTime = math.huge
    self.realStopTime = math.huge
    self.useCuttingWidth = Effect.getValue(xmlFile, key, node, "useCuttingWidth", true)
    self.lastEmitterScale = 1
    self.currentEmitCountScale = 1
    self.particleSystem = nil
    return true
end
function ParticleEffect:delete()
    ParticleEffect:superClass().delete(self)
    ParticleUtil.deleteParticleSystem(self.particleSystem)
end
function ParticleEffect:isRunning()
    return self.isActive
end
function ParticleEffect:start()
    if not self:canStart() or self.particleSystem == nil then
        return false
    end
    ParticleUtil.setEmittingState(self.particleSystem, self.totalWidth == nil or self.totalWidth > 0)
    self.isActive = true
    self.realStartTime = g_time
    self.realStopTime = math.huge
    setVisibility(self.emitterShape, true)
    return true
end
function ParticleEffect:update(dt)
    ParticleEffect:superClass().update(self, dt)
    if self.isActive then
        local x, y, z = getScale(self.emitterShape)
        local scale = math.min(x * y * z, 1)
        if math.abs(scale - self.lastEmitterScale) > 0.05 then
            self.lastEmitterScale = scale
            ParticleUtil.setMaxNumOfParticlesToEmitScale(self.particleSystem, self.currentEmitCountScale * scale)
        end
    end
end
function ParticleEffect:stop()
    ParticleUtil.setEmittingState(self.particleSystem, false)
    if self.particleSystem ~= nil then
        self.realStopTime = g_time
    end
    self.isActive = false
    setVisibility(self.emitterShape, false)
end
function ParticleEffect:reset()
    ParticleUtil.resetNumOfEmittedParticles(self.particleSystem)
end
function ParticleEffect:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, _)
    if fruitTypeIndex ~= nil then
        fillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitTypeIndex)
    end
    if fillTypeIndex == nil then
        return false
    end
    self.useFruitColor = true
    return self:setFillType(fillTypeIndex)
end
function ParticleEffect:setFillType(fillTypeIndex)
    local success = true
    if self.currentFillTypeIndex ~= fillTypeIndex or self.particleSystem == nil then
        if self.particleSystem ~= nil then
            ParticleUtil.deleteParticleSystem(self.particleSystem)
            self.particleSystem = nil
        end
        local sourceParticleSystem = g_particleSystemManager:getParticleSystem(self.particleType)
        if sourceParticleSystem == nil then
            Logging.error("Failed to find particle system for type \'%s\'.", self.particleType)
            success = false
        else
            local psClone = clone(sourceParticleSystem.shape, true, false, true)
            local particleSystem = {}
            ParticleUtil.loadParticleSystemFromNode(psClone, particleSystem, false, self.worldSpace, sourceParticleSystem.forceFullLifespan)
            ParticleUtil.setEmitterShape(particleSystem, self.emitterShape)
            self.currentEmitCountScale = particleSystem.emitterShapeSize / particleSystem.defaultEmitterShapeSize * self.emitCountScale
            ParticleUtil.initEmitterScale(particleSystem, self.currentEmitCountScale)
            ParticleUtil.setParticleSystemSpeed(particleSystem, ParticleUtil.getParticleSystemSpeed(particleSystem) * self.speedScale)
            ParticleUtil.setEmitCountScale(particleSystem, 1)
            if self.lifespan ~= nil then
                ParticleUtil.setParticleLifespan(particleSystem, self.lifespan * 1000)
                particleSystem.originalLifespan = self.lifespan * 1000
            end
            ParticleUtil.setParticleStartStopTime(particleSystem, self.startTime, self.stopTime)
            if self.spriteScale ~= 1 then
                local originalSpriteScaleX = ParticleUtil.getParticleSystemSpriteScaleX(particleSystem)
                ParticleUtil.setParticleSystemSpriteScaleX(particleSystem, originalSpriteScaleX * self.spriteScale)
                local originalSpriteScaleY = ParticleUtil.getParticleSystemSpriteScaleY(particleSystem)
                ParticleUtil.setParticleSystemSpriteScaleY(particleSystem, originalSpriteScaleY * self.spriteScale)
            end
            if self.spriteGainScale ~= 1 then
                local originalSpriteScaleX = ParticleUtil.getParticleSystemSpriteScaleXGain(particleSystem)
                ParticleUtil.setParticleSystemSpriteScaleXGain(particleSystem, originalSpriteScaleX * self.spriteGainScale)
                local originalSpriteScaleY = ParticleUtil.getParticleSystemSpriteScaleYGain(particleSystem)
                ParticleUtil.setParticleSystemSpriteScaleYGain(particleSystem, originalSpriteScaleY * self.spriteGainScale)
            end
            if particleSystem.worldSpace then
                if self.velocityScale ~= nil then
                    ParticleUtil.setParticleSystemVelocityScale(particleSystem, self.velocityScale)
                end
            else
                link(getParent(self.emitterShape), particleSystem.shape)
                setWorldTranslation(particleSystem.shape, getWorldTranslation(self.emitterShape))
                setWorldRotation(particleSystem.shape, getWorldRotation(self.emitterShape))
                ParticleUtil.setParticleSystemVelocityScale(particleSystem, 0)
            end
            self.particleSystem = particleSystem
            self.distanceToLifespans = {}
            local j = 0
            local originalSpriteScaleX = 1
            local originalSpriteScaleY = 0.1
            for j = j, originalSpriteScaleX, originalSpriteScaleY do
                local lifespans = AnimCurve.new(linearInterpolator1)
                local i = 1
                for i = i, 20 do
                    local lifespan = i * 100
                    local normalSpeed, _ = getParticleSystemAverageSpeed(self.particleSystem.geometry)
                    lifespans:addKeyframe({
                        lifespan,
                        ["time"] = normalSpeed * lifespan * (1 - j) + 7.17e-6 * lifespan * lifespan
                    })
                end
                table.insert(self.distanceToLifespans, lifespans)
            end
        end
        if self.particleSystem ~= nil and self.particleSystem.shape ~= nil then
            local psClone = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
            if psClone == nil then
                if getHasShaderParameter(self.particleSystem.shape, "colorAlpha") then
                    local particleSystem, originalSpriteScaleX, originalSpriteScaleY, j = getShaderParameter(self.particleSystem.shape, "colorAlpha")
                    setShaderParameter(self.particleSystem.shape, "colorAlpha", nil, nil, nil, j * self.alphaScale, false)
                end
            else
                self.currentEmitCountScale = psClone:setParticleSystemFillType(self.particleSystem, self.particleType, self.materialType, self.useFruitColor, self.emitCountScale, self.alphaScale) or self.currentEmitCountScale
            end
            if getHasShaderParameter(self.particleSystem.shape, "playScale") then
                local particleSystem, originalSpriteScaleX, originalSpriteScaleY, j = getShaderParameter(self.particleSystem.shape, "playScale")
                setShaderParameter(self.particleSystem.shape, "playScale", particleSystem * self.speedScale, originalSpriteScaleX * self.speedScale, nil, nil, false)
            end
        end
        self.currentFillTypeIndex = fillTypeIndex
    end
    return success
end
function ParticleEffect:setColor(r, g, b, a)
    if self.particleSystem ~= nil and getHasShaderParameter(self.particleSystem.shape, "colorAlpha") then
        setShaderParameter(self.particleSystem.shape, "colorAlpha", r, g, b, a * self.alphaScale, false)
    end
end
function ParticleEffect:setMinMaxWidth(minValue, maxValue, _, _, _)
    if self.useCuttingWidth then
        local widthX = math.abs(minValue - maxValue)
        local _, sy, sz = getScale(self.emitterShape)
        setScale(emitterShape, widthX, sy, sz)
        local _, y, z = getTranslation(emitterShape)
        setTranslation(emitterShape, -(maxValue - widthX * 0.5), y, z)
        ParticleUtil.setEmitCountScale(self.particleSystem, widthX)
        self.totalWidth = widthX
        if self.isActive then
            ParticleUtil.setEmittingState(self.particleSystem, widthX > 0)
        end
    end
end
function ParticleEffect:setDistance(distance, _)
    if self.particleSystem ~= nil and not (self.ignoreDistanceLifeSpan or self.particleSystem.forceFullLifespan) then
        local _, dirY, _ = localDirectionToWorld(self.particleSystem.emitterShape, 0, 1, 0)
        local index = math.floor(dirY / 1 * #self.distanceToLifespans)
        ParticleUtil.setParticleLifespan(self.particleSystem, (self.distanceToLifespans[math.clamp(index, 1, #self.distanceToLifespans)]:get(distance + self.extraDistance)))
    end
end
function ParticleEffect:setDensity(density)
    if self.particleSystem ~= nil then
        ParticleUtil.setEmitCountScale(self.particleSystem, self.emitCountScale * density)
    end
end
function ParticleEffect:getIsVisible()
    return self:getIsFullyVisible()
end
function ParticleEffect:getIsFullyVisible()
    return self.realStartTime + self.startTimeMs < g_time and self.realStopTime + self.stopTimeMs > g_time
end
function ParticleEffect.registerEffectXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#emitCountScale", "(ParticleEffect) Emit count scale", 1)
    schema:register(XMLValueType.STRING, basePath .. "#particleType", "(ParticleEffect) Particle type", "unloading")
    schema:register(XMLValueType.STRING, basePath .. "#materialType", "(ParticleEffect) Material type")
    schema:register(XMLValueType.BOOL, basePath .. "#useFruitColor", "(ParticleEffect) Apply the fruit color to the smoke effect instead of the fill color", false)
    schema:register(XMLValueType.BOOL, basePath .. "#worldSpace", "(ParticleEffect) World space", true)
    schema:register(XMLValueType.FLOAT, basePath .. "#delay", "(ParticleEffect) Delay", 0)
    schema:register(XMLValueType.FLOAT, basePath .. "#startTime", "(ParticleEffect) Start time", "delay")
    schema:register(XMLValueType.FLOAT, basePath .. "#stopTime", "(ParticleEffect) Stop time", "delay")
    schema:register(XMLValueType.FLOAT, basePath .. "#lifespan", "(ParticleEffect) Lifespan")
    schema:register(XMLValueType.FLOAT, basePath .. "#extraDistance", "(ParticleEffect) Extra distance", 0.5)
    schema:register(XMLValueType.BOOL, basePath .. "#ignoreDistanceLifeSpan", "(ParticleEffect) Ignore distance based lifespan and apply fixed lifespan", false)
    schema:register(XMLValueType.FLOAT, basePath .. "#alphaScale", "(ParticleEffect) Scale for the color alpha value", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#velocityScale", "(ParticleEffect) Overwrite velocity scale of particles (only if world space)")
    schema:register(XMLValueType.FLOAT, basePath .. "#spriteScale", "(ParticleEffect) Scale factor that is applied on sprite scale loaded from particle system", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#spriteGainScale", "(ParticleEffect) Scale factor that is applied on sprite gain scale loaded from particle system", "#spriteScale value")
    schema:register(XMLValueType.FLOAT, basePath .. "#speedScale", "(ParticleEffect) Scale factor for particle speed")
    schema:register(XMLValueType.BOOL, basePath .. "#useCuttingWidth", "(ParticleEffect) Use cutting width", true)
end