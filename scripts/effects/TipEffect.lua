TipEffect = {}
local TipEffect_mt = Class(TipEffect, Effect)
function TipEffect.new(customMt)
    -- upvalues: (copy) TipEffect_mt
    local self = Effect.new(customMt or TipEffect_mt)
    self.activeEffect = nil
    return self
end
function TipEffect:load(xmlFile, baseName, rootNodes, parent, i3dMapping)
    self.effects = g_effectManager:loadEffect(xmlFile, baseName, rootNodes, parent, i3dMapping)
    return self
end
function TipEffect:delete()
    for _, effect in ipairs(self.effects) do
        effect:delete()
    end
end
function TipEffect:update(dt)
    if self.activeEffect ~= nil then
        self.activeEffect:update(dt)
    end
end
function TipEffect:isRunning()
    return self.activeEffect ~= nil and self.activeEffect:isRunning()
end
function TipEffect:start()
    if self:canStart() and self.activeEffect ~= nil then
        return self.activeEffect:start()
    else
        return false
    end
end
function TipEffect:stop()
    if self.activeEffect == nil then
        return false
    else
        return self.activeEffect:stop()
    end
end
function TipEffect:reset()
    for _, effect in ipairs(self.effects) do
        effect:reset()
    end
end
function TipEffect:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState)
    local prioritizedEffectType = g_fillTypeManager:getPrioritizedEffectTypeByFillTypeIndex(fillTypeIndex)
    if prioritizedEffectType ~= nil then
        for _, effect in ipairs(self.effects) do
            if effect.setEffectTypeInfo ~= nil then
                local className = ClassUtil.getClassNameByObject(effect)
                if className ~= nil and (string.lower(className) == string.lower(prioritizedEffectType) and effect:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState)) then
                    self.activeEffect = effect
                    return true
                end
            end
        end
    end
    local foundEffect = false
    for effect, className in ipairs(self.effects) do
        if className.setEffectTypeInfo ~= nil and className:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState) then
            self.activeEffect = className
            return true
        end
    end
    return foundEffect
end
function TipEffect:setDistance(distance)
    if self.activeEffect ~= nil and self.activeEffect.setDistance ~= nil then
        self.activeEffect:setDistance(distance)
    end
end
function TipEffect:getIsVisible()
    if self.activeEffect == nil or self.activeEffect.getIsVisible == nil then
        return false
    else
        return self.activeEffect:getIsVisible()
    end
end
function TipEffect:getIsFullyVisible()
    if self.activeEffect == nil or self.activeEffect.getIsFullyVisible == nil then
        return false
    else
        return self.activeEffect:getIsFullyVisible()
    end
end
function TipEffect.registerEffectXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".effectNode(?)#effectClass", "Effect class", "ShaderPlaneEffect")
    Effect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    ExhaustEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    LevelerEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    MorphPositionEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    ParticleEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    PipeEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    ShaderPlaneEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    SlurrySideToSideEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    WindrowerEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    GrainTankEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    CutterMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    CultivatorMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    PlowMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    WindrowerMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    MotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    VariableMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
end