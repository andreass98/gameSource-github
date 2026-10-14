MorphPositionEffect = {}
local MorphPositionEffect_mt = Class(MorphPositionEffect, ShaderPlaneEffect)
function MorphPositionEffect.new(customMt)
    -- upvalues: (copy) MorphPositionEffect_mt
    return ShaderPlaneEffect.new(customMt or MorphPositionEffect_mt)
end
function MorphPositionEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
    if not MorphPositionEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
        return false
    end
    self.speed = Effect.getValue(xmlFile, key, node, "speed", 1)
    self.fadeCur = { 0, 0 }
    self.fadeDir = { 0, 0 }
    self.scrollLength = Effect.getValue(xmlFile, key, node, "scrollLength", 1)
    self.scrollLengthOrig = self.scrollLength
    self.scrollSpeed = Effect.getValue(xmlFile, key, node, "scrollSpeed", 1) * 0.001
    self.scrollPosition = 0
    self.scrollUpdate = true
    setShaderParameter(self.node, "morphPos", 0, 1, 1, 0, false)
    setShaderParameter(self.node, "prevMorphPos", 0, 1, 1, 0, false)
    setVisibility(self.node, false)
    return true
end
function MorphPositionEffect:update(dt)
    local running = false
    local running
    if self.state == ShaderPlaneEffect.STATE_OFF then
        running = true
    else
        local fadeTime = self.fadeInTime
        if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
            fadeTime = self.fadeOutTime
        end
        local isVisible = self.fadeCur
        isVisible[1] = math.max(0, (math.min(1, self.fadeCur[1] + self.fadeDir[1] * (dt / fadeTime))))
        local isVisible = self.fadeCur
        isVisible[2] = math.max(0, math.min(1, self.fadeCur[2] + self.fadeDir[2] * (dt / fadeTime)), self.offset)
        if self.state ~= ShaderPlaneEffect.STATE_OFF and self.state ~= ShaderPlaneEffect.STATE_TURNING_OFF then
            self.fadeCur[1] = self.offset
        end
        g_animationManager:setPrevShaderParameter(self.node, "morphPos", self.fadeCur[1], self.fadeCur[2], 1, self.speed, false, "prevMorphPos")
        local isVisible = true
        if self.state == ShaderPlaneEffect.STATE_TURNING_OFF and self.fadeCur[1] == 1 then
            isVisible = false
            self.fadeCur[1] = 0
            self.fadeCur[2] = 0
            self.state = ShaderPlaneEffect.STATE_OFF
        end
        setVisibility(self.node, isVisible)
    end
    if self.scrollUpdate then
        self.scrollPosition = (self.scrollPosition + dt * self.scrollSpeed) % self.scrollLength
        setShaderParameter(self.node, "offsetUV", self.scrollPosition, nil, nil, nil, false)
    end
    if not running then
        if self.state == ShaderPlaneEffect.STATE_TURNING_ON then
            self.state = ShaderPlaneEffect.STATE_ON
            return
        end
        if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
            self.state = ShaderPlaneEffect.STATE_OFF
        end
    end
end
function MorphPositionEffect:start(skipDelay)
    if self.startDelay ~= 0 and not skipDelay then
        return false, self.startDelay
    end
    if not self:canStart() or (self.state == ShaderPlaneEffect.STATE_TURNING_ON or self.state == ShaderPlaneEffect.STATE_ON) then
        return false
    end
    self.state = ShaderPlaneEffect.STATE_TURNING_ON
    self.fadeCur[1] = math.min(self.offset, 0)
    self.fadeCur[2] = math.min(self.offset, self.fadeCur[2])
    self.fadeDir[1] = 0
    self.fadeDir[2] = 1
    return true
end
function MorphPositionEffect:stop(skipDelay)
    if self.stopDelay ~= 0 and not skipDelay then
        return false, self.stopDelay
    end
    if self.state == ShaderPlaneEffect.STATE_TURNING_OFF or self.state == ShaderPlaneEffect.STATE_OFF then
        return false
    end
    self.state = ShaderPlaneEffect.STATE_TURNING_OFF
    self.fadeDir[1] = 1
    self.fadeDir[2] = 1
    return true
end
function MorphPositionEffect:reset()
    self.fadeCur[1] = math.min(self.offset, 0)
    self.fadeCur[2] = math.min(self.offset, 0)
    self.fadeDir[1] = 0
    self.fadeDir[2] = 1
    g_animationManager:setPrevShaderParameter(self.node, "morphPos", self.fadeCur[1], self.fadeCur[2], 0, self.scrollSpeed, false, "prevMorphPos")
    setVisibility(self.node, false)
    self.state = ShaderPlaneEffect.STATE_OFF
end
function MorphPositionEffect:setScrollUpdate(state)
    if state == nil then
        self.scrollUpdate = not self.scrollUpdate
    else
        self.scrollUpdate = state
    end
end
function MorphPositionEffect:getIsVisible()
    return self.fadeCur[1] > 0
end
function MorphPositionEffect:getIsFullyVisible()
    return self.fadeCur[2] == 1 and self.fadeCur[1] == 0
end
function MorphPositionEffect:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState, force)
    self.scrollLength = self.scrollLengthOrig
    if fillTypeIndex ~= nil and (fillTypeIndex ~= FillType.UNKNOWN and self.useFillTypeTextureArrays) then
        local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
        if fillTypeDesc ~= nil then
            self.scrollLength = self.scrollLengthOrig * fillTypeDesc:getTextureUnitSize()
        end
    end
    return MorphPositionEffect:superClass().setEffectTypeInfo(self, fillTypeIndex, fruitTypeIndex, growthState, force)
end
function MorphPositionEffect.registerEffectXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#speed", "speed", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#scrollLength", "(MorphPositionEffect) scroll length", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#scrollSpeed", "(MorphPositionEffect) scroll speed", 1)
end