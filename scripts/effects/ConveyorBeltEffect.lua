ConveyorBeltEffect = {}
local ConveyorBeltEffect_mt = Class(ConveyorBeltEffect, MorphPositionEffect)
function ConveyorBeltEffect.new(customMt)
    -- upvalues: (copy) ConveyorBeltEffect_mt
    return MorphPositionEffect.new(customMt or ConveyorBeltEffect_mt)
end
function ConveyorBeltEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
    if not ConveyorBeltEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
        return false
    end
    self.scrollUpdate = true
    return true
end
function ConveyorBeltEffect:update(dt)
    if self.scrollUpdate then
        self.scrollPosition = (self.scrollPosition + dt * self.scrollSpeed) % self.scrollLength
        setShaderParameter(self.node, "offsetUV", self.scrollPosition, nil, nil, nil, false)
    end
    setVisibility(self.node, true)
end
function ConveyorBeltEffect:setScrollUpdate(state)
    if state == nil then
        self.scrollUpdate = not self.scrollUpdate
    else
        self.scrollUpdate = state
    end
end
function ConveyorBeltEffect:setMorphPosition(fade1, fade2)
    self.fadeCur[1] = fade1
    self.fadeCur[2] = fade2
    g_animationManager:setPrevShaderParameter(self.node, "morphPos", fade1, fade2, 1, self.speed, false, "prevMorphPos")
end