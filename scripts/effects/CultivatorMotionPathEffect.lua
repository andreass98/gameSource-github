CultivatorMotionPathEffect = {}
local CultivatorMotionPathEffect_mt = Class(CultivatorMotionPathEffect, TypedMotionPathEffect)
function CultivatorMotionPathEffect.new(customMt)
    -- upvalues: (copy) CultivatorMotionPathEffect_mt
    local self = TypedMotionPathEffect.new(customMt or CultivatorMotionPathEffect_mt)
    self.shapeVariationStateDelay = ValueDelay.new(500)
    self.shapeVariationStateSmoothed = 0
    self.densityScale = math.random(75, 100) * 0.01
    self.autoTurnOffSpeed = 1
    return self
end
function CultivatorMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
    if not CultivatorMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
        return false
    end
    self.isCultivatorSweepEffect = xmlFile:getValue(key .. ".motionPathEffect#isCultivatorSweepEffect", false)
    self.minDensity = 0.4
    self.maxDensitySpeed = 4
    if self.isCultivatorSweepEffect then
        self.minDensity = 0
        self.maxDensitySpeed = 10
    end
    self.minDensity = xmlFile:getValue(key .. ".motionPathEffect#minDensity", self.minDensity)
    self.maxDensitySpeed = xmlFile:getValue(key .. ".motionPathEffect#maxDensitySpeed", self.maxDensitySpeed)
    self.densityScale = xmlFile:getValue(key .. ".motionPathEffect#densityScale", self.densityScale)
    self.maxVariationState = xmlFile:getValue(key .. ".motionPathEffect#maxVariationState", 1)
    return true
end
function CultivatorMotionPathEffect:update(dt)
    local lastSpeed = self.parent:getLastSpeed()
    if self.isCultivatorSweepEffect then
        if self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON then
            local variationState = math.clamp((lastSpeed - 5) / 10, 0, 1)
            self.effectSpeedScale = self.effectSpeedScaleOrig * (0.5 + variationState * 0.5)
        end
    else
        local variationState = math.clamp(lastSpeed / 10, 0, 1)
        self.effectSpeedScale = self.effectSpeedScaleOrig * (0.5 + variationState * 0.5)
    end
    if self.state == MotionPathEffect.STATE_ON and lastSpeed < self.autoTurnOffSpeed then
        g_effectManager:stopEffect(self)
    end
    if self.hasCurrentEffectNodes then
        if self.state == MotionPathEffect.STATE_TURNING_OFF then
            self.effectSpeedScale = self.effectSpeedScaleOrig * math.clamp(lastSpeed / 10, 0.4, 1)
        end
        local y = 0
        for i, effectNode in ipairs(self.currentEffectNodes) do
            if self.state == MotionPathEffect.STATE_TURNING_OFF then
                local effectNode, y, z = getTranslation(effectNode)
                y = y - dt * 0.001
                setTranslation(effectNode, effectNode, y, z)
                if y < -0.5 then
                    setTranslation(effectNode, 0, 0, 0)
                end
            else
                setTranslation(effectNode, 0, 0, 0)
            end
        end
        if y < -0.5 then
            self.fadeIn = self.minFade
            self.fadeOut = self.minFade
            self.state = MotionPathEffect.STATE_OFF
        end
    elseif self.state == MotionPathEffect.STATE_TURNING_OFF then
        self.fadeIn = self.minFade
        self.fadeOut = self.minFade
        self.state = MotionPathEffect.STATE_OFF
    end
    CultivatorMotionPathEffect:superClass().update(self, dt)
    if self.hasCurrentEffectNodes then
        if self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON then
            local variationAlpha = lastSpeed / self.maxDensitySpeed
            self:setDensity((math.min(variationAlpha, 1) * (1 - self.minDensity) + self.minDensity) * self.densityScale)
            local y = 0
            local z = 0
            local variationAlpha = 0
            if self.isCultivatorSweepEffect then
                local variationState = math.clamp((lastSpeed - 5) / 10, 0, self.maxVariationState)
                self.shapeVariationStateSmoothed = self.shapeVariationStateSmoothed * 0.985 + variationState * 0.015
                y = math.floor(self.shapeVariationStateSmoothed * 2)
                z = math.floor(self.shapeVariationStateSmoothed * 2 + 1)
                variationAlpha = self.shapeVariationStateSmoothed * 2 % 1
            end
            for effectNode, effectNode in ipairs(self.currentEffectNodes) do
                setShaderParameterRecursive(effectNode, "scrollPos", nil, y, z, variationAlpha, false)
            end
        end
        if self.state == MotionPathEffect.STATE_OFF then
            self.shapeVariationStateDelay:reset()
            self.shapeVariationStateSmoothed = 0
        end
    end
end
function CultivatorMotionPathEffect:stop()
    return CultivatorMotionPathEffect:superClass().stop(self)
end
function CultivatorMotionPathEffect:reset()
    return CultivatorMotionPathEffect:superClass().reset(self)
end
function CultivatorMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
    TypedMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
end
function CultivatorMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
    TypedMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
end
function CultivatorMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
    TypedMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
end
function CultivatorMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
    TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
end
function CultivatorMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
    TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
end
function CultivatorMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
    TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
end
function CultivatorMotionPathEffect.registerEffectXMLPaths(schema, basePath)
    TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. ".motionPathEffect#isCultivatorSweepEffect", "(CultivatorMotionPathEffect) Is sweep effect", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#minDensity", "(CultivatorMotionPathEffect) Min. Density", 0.5)
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#maxDensitySpeed", "(CultivatorMotionPathEffect) Speed at which the density is 1", 8)
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#densityScale", "(CultivatorMotionPathEffect) Density Scale", "Random between 0.75 and 1")
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#maxVariationState", "(CultivatorMotionPathEffect) Max. variation state", "Max state of variation depending on speed (0 -> slow, 0.5 -> normal, 1 -> fast)")
end