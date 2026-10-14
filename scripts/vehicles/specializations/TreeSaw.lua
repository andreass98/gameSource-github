TreeSaw = {}
function TreeSaw.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end
function TreeSaw.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("TreeSaw")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.treeSaw.sounds", "cut")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.treeSaw.sounds", "saw")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.treeSaw.animationNodes")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.treeSaw.effects")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.treeSaw.cutNode#node", "Cut node")
    schema:register(XMLValueType.FLOAT, "vehicle.treeSaw.cutNode#sizeY", "Size Y", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.treeSaw.cutNode#sizeZ", "Size Z", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.treeSaw.cutNode#lengthAboveThreshold", "Min. tree length above cut node", 0.3)
    schema:register(XMLValueType.FLOAT, "vehicle.treeSaw.cutNode#lengthBelowThreshold", "Min. tree length below cut node", 0.3)
    schema:register(XMLValueType.FLOAT, "vehicle.treeSaw.cutNode#timer", "Cut delay (sec.)", 1)
    schema:setXMLSpecializationType()
end
function TreeSaw.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", TreeSaw)
end
function TreeSaw:onLoad(_)
    local spec = self.spec_treeSaw
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode", "vehicle.treeSaw.animationNodes.animationNode", "stumbCutter")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.treeSaw.cutParticleSystems.emitterShape(0)", "vehicle.treeSaw.effects.effectNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.treeSaw.sawSound", "vehicle.treeSaw.sounds.saw")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.treeSaw.cutSound", "vehicle.treeSaw.sounds.cut")
    if self.isClient then
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.treeSaw.animationNodes", self.components, self, self.i3dMappings)
        spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.treeSaw.effects", self.components, self, self.i3dMappings)
        spec.samples = {}
        spec.samples.cut = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.treeSaw.sounds", "cut", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.saw = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.treeSaw.sounds", "saw", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    spec.cutNode = self.xmlFile:getValue("vehicle.treeSaw.cutNode#node", nil, self.components, self.i3dMappings)
    spec.cutSizeY = self.xmlFile:getValue("vehicle.treeSaw.cutNode#sizeY", 1)
    spec.cutSizeZ = self.xmlFile:getValue("vehicle.treeSaw.cutNode#sizeZ", 1)
    spec.lengthAboveThreshold = self.xmlFile:getValue("vehicle.treeSaw.cutNode#lengthAboveThreshold", 0.3)
    spec.lengthBelowThreshold = self.xmlFile:getValue("vehicle.treeSaw.cutNode#lengthBelowThreshold", 0.3)
    spec.cutTimerDuration = self.xmlFile:getValue("vehicle.treeSaw.cutNode#timer", 1) * 1000
    spec.curSplitShape = nil
    spec.cutTimer = -1
    spec.isCutting = false
    spec.warnTreeNotOwned = false
end
function TreeSaw:onDelete()
    local spec = self.spec_treeSaw
    g_effectManager:deleteEffects(spec.effects)
    g_soundManager:deleteSamples(spec.samples)
    g_animationManager:deleteAnimations(spec.animationNodes)
end
function TreeSaw:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        self.spec_treeSaw.isCutting = streamReadBool(streamId)
    end
end
function TreeSaw:onWriteUpdateStream(streamId, connection, _)
    if not connection:getIsServer() then
        streamWriteBool(streamId, self.spec_treeSaw.isCutting)
    end
end
function TreeSaw:onUpdate(dt, _, _, _)
    if self.isServer then
        if self.spec_treeSaw.curSplitShape ~= nil and not entityExists(self.spec_treeSaw.curSplitShape) then
            spec.curSplitShape = nil
            if g_server ~= nil then
                spec.cutTimer = -1
            end
        end
        local x = spec.curSplitShape ~= nil
        spec.isCutting = x
        if spec.curSplitShape ~= nil then
            if spec.cutTimer > 0 then
                spec.cutTimer = math.max(spec.cutTimer - dt, 0)
            end
            if spec.cutTimer == 0 then
                spec.cutTimer = -1
                local x, y, z = getWorldTranslation(spec.cutNode)
                local nx, ny, nz = localDirectionToWorld(spec.cutNode, 1, 0, 0)
                local yx, yy, yz = localDirectionToWorld(spec.cutNode, 0, 1, 0)
                ChainsawUtil.cutSplitShape(spec.curSplitShape, x, y, z, nx, ny, nz, yx, yy, yz, spec.cutSizeY, spec.cutSizeZ, self:getActiveFarm())
                spec.curSplitShape = nil
            end
        end
    end
    if self.isClient then
        if spec.cutTimer > 0 then
            g_effectManager:setEffectTypeInfo(spec.effects, FillType.WOODCHIPS)
            g_effectManager:startEffects(spec.effects)
            if not g_soundManager:getIsSamplePlaying(spec.samples.cut) then
                g_soundManager:playSample(spec.samples.cut)
                return
            end
        else
            g_effectManager:stopEffects(spec.effects)
            if g_soundManager:getIsSamplePlaying(spec.samples.cut) then
                g_soundManager:stopSample(spec.samples.cut)
            end
        end
    end
end
function TreeSaw:onUpdateTick(_, _, _, _)
    local spec = self.spec_treeSaw
    spec.warnTreeNotOwned = false
    if self:getIsTurnedOn() and spec.cutNode ~= nil then
        local x, y, z = getWorldTranslation(spec.cutNode)
        local nx, ny, nz = localDirectionToWorld(spec.cutNode, 1, 0, 0)
        local yx, yy, yz = localDirectionToWorld(spec.cutNode, 0, 1, 0)
        if spec.curSplitShape == nil then
            local shape, _, _, _, _ = findSplitShape(x, y, z, nx, ny, nz, yx, yy, yz, spec.cutSizeY, spec.cutSizeZ)
            if shape ~= 0 then
                if g_currentMission.accessHandler:canFarmAccessLand(self:getActiveFarm(), x, z) then
                    spec.curSplitShape = shape
                    spec.cutTimer = spec.cutTimerDuration
                else
                    spec.warnTreeNotOwned = true
                end
            end
        elseif not entityExists(spec.curSplitShape) then
            spec.curSplitShape = nil
        end
        if spec.curSplitShape ~= nil then
            local shape, _, _, _ = testSplitShape(spec.curSplitShape, x, y, z, nx, ny, nz, yx, yy, yz, spec.cutSizeY, spec.cutSizeZ)
            if shape == nil then
                spec.curSplitShape = nil
            else
                local _ = false
                local _, ly, _ = localToLocal(spec.cutNode, spec.curSplitShape, 0, shape, _)
                if not _ then
                    _ = ly < 0.01
                end
                local _, ly, _ = localToLocal(spec.cutNode, spec.curSplitShape, 0, shape, _)
                if not _ then
                    _ = ly < 0.01
                end
                local _, ly, _ = localToLocal(spec.cutNode, spec.curSplitShape, 0, _, _)
                if not _ then
                    _ = ly < 0.01
                end
                local _, ly, _ = localToLocal(spec.cutNode, spec.curSplitShape, 0, _, _)
                if not _ then
                    _ = ly < 0.01
                end
                if _ then
                    spec.curSplitShape = nil
                end
            end
        end
        if spec.curSplitShape ~= nil then
            local shape, _ = getSplitShapePlaneExtents(spec.curSplitShape, x, y, z, nx, ny, nz)
            if _ < spec.lengthAboveThreshold or shape < spec.lengthBelowThreshold then
                spec.curSplitShape = nil
            end
        end
        if spec.curSplitShape == nil and spec.cutTimer > -1 then
            spec.cutTimer = -1
        end
    end
end
function TreeSaw:onDraw(_, _, _)
    local spec = self.spec_treeSaw
    if spec.isCutting then
        g_currentMission:addExtraPrintText(g_i18n:getText("info_cutting"))
    end
    if spec.warnTreeNotOwned then
        g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"), 1000)
    end
end
function TreeSaw:onDeactivate()
    local spec = self.spec_treeSaw
    spec.curSplitShape = nil
    spec.cutTimer = -1
end
function TreeSaw:onTurnedOn()
    if self.isClient then
        local spec = self.spec_treeSaw
        g_animationManager:startAnimations(spec.animationNodes)
        g_soundManager:playSample(spec.samples.saw)
    end
end
function TreeSaw:onTurnedOff()
    local spec = self.spec_treeSaw
    spec.curSplitShape = nil
    spec.cutTimer = -1
    if self.isClient then
        g_animationManager:stopAnimations(spec.animationNodes)
        g_effectManager:stopEffects(spec.effects)
        g_soundManager:stopSamples(spec.samples)
    end
end