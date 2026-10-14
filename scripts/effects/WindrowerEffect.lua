WindrowerEffect = {}
local WindrowerEffect_mt = Class(WindrowerEffect, MorphPositionEffect)
function WindrowerEffect.new(customMt)
    -- upvalues: (copy) WindrowerEffect_mt
    return MorphPositionEffect.new(customMt or WindrowerEffect_mt)
end
function WindrowerEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
    if not WindrowerEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
        return false
    end
    self.unloadDirection = Effect.getValue(xmlFile, key, node, "unloadDirection", 0)
    self.width = Effect.getValue(xmlFile, key, node, "width", 0)
    self.dropOffset = Effect.getValue(xmlFile, key, node, "dropOffset", 0)
    self.turnOffRequiredEffect = Effect.getValue(xmlFile, key, node, "turnOffRequiredEffect", 0)
    self.testAreas = {}
    local i = 0
    while true do
        local areaKey = key .. string.format(".testArea(%d)", i)
        if not xmlFile:hasProperty(areaKey) then
            break
        end
        local start = xmlFile:getValue(areaKey .. "#startNode", nil, self.rootNodes, i3dMapping)
        local width = xmlFile:getValue(areaKey .. "#widthNode", nil, self.rootNodes, i3dMapping)
        local height = xmlFile:getValue(areaKey .. "#heightNode", nil, self.rootNodes, i3dMapping)
        table.insert(self.testAreas, {
            ["start"] = start,
            ["width"] = width,
            ["height"] = height
        })
        i = i + 1
    end
    self.particleSystems = {}
    local i = 0
    while true do
        local areaKey = key .. string.format(".particleSystem(%d)", i)
        if not xmlFile:hasProperty(areaKey) then
            break
        end
        local start = xmlFile:getValue(areaKey .. "#emitterShape", nil, self.rootNodes, i3dMapping)
        local width = xmlFile:getValue(areaKey .. "#particleType")
        local height = xmlFile:getValue(areaKey .. "#materialType", width)
        local materialIndex = xmlFile:getValue(areaKey .. "#materialIndex", 1)
        local fadeInRange = xmlFile:getValue(areaKey .. "#fadeInRange", nil, true)
        local fadeOutRange = xmlFile:getValue(areaKey .. "#fadeOutRange", nil, true)
        if start ~= nil then
            local x, y, z = getWorldTranslation(start)
            local xOffset, _, _ = worldToLocal(self.node, x, y, z)
            local sourceParticleSystem = g_particleSystemManager:getParticleSystem(width)
            if sourceParticleSystem ~= nil then
                local psData = {
                    ["xOffset"] = xOffset,
                    ["fadeInRange"] = fadeInRange,
                    ["fadeOutRange"] = fadeOutRange,
                    ["particleSystem"] = ParticleUtil.copyParticleSystem(xmlFile, areaKey, sourceParticleSystem, start),
                    ["materialType"] = height,
                    ["materialIndex"] = materialIndex,
                    ["fillType"] = FillType.UNKNOWN
                }
                table.insert(self.particleSystems, psData)
            end
        end
        i = i + 1
    end
    self.lastChargeTime = 0
    self.updateTick = 0
    self.scrollUpdate = false
    self.particleSystemsTurnedOff = false
    return true
end
function WindrowerEffect:delete()
    WindrowerEffect:superClass().delete(self)
    for _, particleSystemData in ipairs(self.particleSystems) do
        ParticleUtil.deleteParticleSystem(particleSystemData.particleSystem)
    end
end
function WindrowerEffect:update(dt)
    WindrowerEffect:superClass().update(self, dt)
    if self.updateTick > 5 and self.state ~= ShaderPlaneEffect.STATE_OFF then
        local minX, maxX, foundFillType = WindrowerEffect.getCurrentTestAreaWidth(self)
        setShaderParameter(self.node, "offsetUV", self.scrollPosition, 0, minX, maxX, false)
        for _, particleSystemData in ipairs(self.particleSystems) do
            local inFadeInRange = false
            if self.fadeCur[1] >= particleSystemData.fadeInRange[1] then
                inFadeInRange = self.fadeCur[1] <= particleSystemData.fadeInRange[2]
            end
            local inFadeOutRange = false
            if self.fadeCur[2] >= particleSystemData.fadeOutRange[1] then
                inFadeOutRange = self.fadeCur[2] <= particleSystemData.fadeOutRange[2]
            end
            local inXRange = false
            if minX <= particleSystemData.xOffset then
                inXRange = particleSystemData.xOffset <= maxX
            end
            if inXRange and (inFadeInRange and (inFadeOutRange and self.state ~= ShaderPlaneEffect.STATE_OFF)) then
                if particleSystemData.fillType ~= foundFillType then
                    local material = g_materialManager:getParticleMaterial(foundFillType, particleSystemData.materialType, particleSystemData.materialIndex)
                    if material ~= nil then
                        ParticleUtil.setMaterial(particleSystemData.particleSystem, material)
                    end
                    particleSystemData.fillType = foundFillType
                end
                ParticleUtil.setEmittingState(particleSystemData.particleSystem, true)
            else
                ParticleUtil.setEmittingState(particleSystemData.particleSystem, false)
            end
        end
        self.updateTick = 0
        self.particleSystemsTurnedOff = false
    elseif not self.particleSystemsTurnedOff then
        for _, particleSystemData in ipairs(self.particleSystems) do
            ParticleUtil.setEmittingState(particleSystemData.particleSystem, false)
        end
        self.particleSystemsTurnedOff = true
    end
    local minX, maxX, foundFillType, _ = getShaderParameter(self.node, "offsetUV")
    self.scrollPosition = (self.scrollPosition + dt * self.scrollSpeed) % self.scrollLength
    setShaderParameter(self.node, "offsetUV", self.scrollPosition, maxX, foundFillType, _, false)
    self.updateTick = self.updateTick + 1
end
function WindrowerEffect:start()
    local success = WindrowerEffect:superClass().start(self)
    if success and self.unloadDirection ~= 0 then
        local minX, minX = WindrowerEffect.getCurrentTestAreaWidth(self, true)
        local _ = self.unloadDirection < 0
        self.fadeCur[2] = math.clamp((minX / (self.width / 2) + 1) / 2, 0, 1)
        if self.unloadDirection < 0 then
            self.fadeCur[2] = math.abs(1 - self.fadeCur[2])
        end
    end
    return success
end
function WindrowerEffect:stop()
    local success = WindrowerEffect:superClass().stop(self)
    if success and (self.unloadDirection ~= 0 and self.fadeCur[1] == 0) then
        local _, _, maxX, maxX = getShaderParameter(self.node, "offsetUV")
        local _ = self.unloadDirection < 0
        self.fadeCur[1] = math.clamp((maxX / (self.width / 2) + 1) / 2, 0, 1)
        if self.unloadDirection < 0 then
            self.fadeCur[1] = math.abs(1 - self.fadeCur[1])
        end
    end
    return success
end
function WindrowerEffect:getCurrentTestAreaWidth(real)
    local minX = self.width / 2 + self.dropOffset
    local maxX = -self.width / 2 - self.dropOffset
    local foundFillType = FillType.UNKNOWN
    for _, testArea in ipairs(self.testAreas) do
        local x0, y0, z0 = getWorldTranslation(testArea.start)
        local x1, y1, z1 = getWorldTranslation(testArea.width)
        local x2, _, z2 = getWorldTranslation(testArea.height)
        local fillType = DensityMapHeightUtil.getFillTypeAtArea(x0, z0, x1, z1, x2, z2)
        if fillType ~= FillType.UNKNOWN then
            local xStart, _, _ = worldToLocal(self.node, x0, y0, z0)
            local xWidth, _, _ = worldToLocal(self.node, x1, y1, z1)
            if xStart >= minX then
                xStart = minX
            end
            if maxX >= xWidth then
                xWidth = maxX
            end
            foundFillType = fillType
            maxX = xWidth
            minX = xStart
        end
    end
    if (not real or real == nil) and self.unloadDirection ~= 0 then
        if self.unloadDirection < 0 then
            minX = -self.width / 2 - self.dropOffset
        end
        if self.unloadDirection > 0 then
            maxX = self.width / 2 + self.dropOffset
        end
    end
    return minX, maxX, foundFillType
end
function WindrowerEffect.registerEffectXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#unloadDirection", "(WindrowerEffect) Unload direction")
    schema:register(XMLValueType.FLOAT, basePath .. "#width", "(WindrowerEffect) Width", 0)
    schema:register(XMLValueType.FLOAT, basePath .. "#dropOffset", "(WindrowerEffect) Drop offset", 0)
    schema:register(XMLValueType.INT, basePath .. "#turnOffRequiredEffect", "(WindrowerEffect) Index of turn off required effect", 0)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".testArea(?)#startNode", "(WindrowerEffect) Test area start node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".testArea(?)#widthNode", "(WindrowerEffect) Test area width node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".testArea(?)#heightNode", "(WindrowerEffect) Test area height node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".particleSystem(?)#emitterShape", "(WindrowerEffect) Emitter shape node")
    schema:register(XMLValueType.STRING, basePath .. ".particleSystem(?)#particleType", "(WindrowerEffect) Particle type")
    schema:register(XMLValueType.STRING, basePath .. ".particleSystem(?)#materialType", "(WindrowerEffect) Material type", "same as particleType")
    schema:register(XMLValueType.INT, basePath .. ".particleSystem(?)#materialIndex", "(WindrowerEffect) Particle type", 1)
    schema:register(XMLValueType.VECTOR_2, basePath .. ".particleSystem(?)#fadeInRange", "(WindrowerEffect) Fade in range")
    schema:register(XMLValueType.VECTOR_2, basePath .. ".particleSystem(?)#fadeOutRange", "(WindrowerEffect) Fade out range")
    ParticleUtil.registerParticleCopyXMLPaths(schema, basePath .. ".particleSystem(?)")
end