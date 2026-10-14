FertilizerMotionPathEffect = {}
local FertilizerMotionPathEffect_mt = Class(FertilizerMotionPathEffect, TypedMotionPathEffect)
function FertilizerMotionPathEffect.new(customMt)
    -- upvalues: (copy) FertilizerMotionPathEffect_mt
    local self = TypedMotionPathEffect.new(customMt or FertilizerMotionPathEffect_mt)
    self.isLeft = false
    return self
end
function FertilizerMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
    if not FertilizerMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
        return false
    end
    self.isLeft = xmlFile:getValue(key .. ".motionPathEffect#isLeft", self.isLeft)
    self.smoothY1 = nil
    self.smoothY2 = nil
    return true
end
function FertilizerMotionPathEffect:update(dt)
    if (self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON) and self.parent.getVariableWorkWidth ~= nil then
        local currentWidth, maxWidth, isValid = self.parent:getVariableWorkWidth(self.isLeft)
        if self.textureRealWidth ~= nil then
            maxWidth = self.textureRealWidth * math.sign(maxWidth)
        end
        self.fadeVisibilityMax = 1 - currentWidth / maxWidth
        local currentWidth = not isValid and 10 or currentWidth
        for i, effectNode in ipairs(self.currentEffectNodes) do
            if currentWidth == 0 then
                setRotation(effectNode, 0, 0, 0)
            else
                local _, y1, _ = localToWorld(effectNode, 0, 0, 0)
                if self.smoothY1 == nil then
                    self.smoothY1 = y1
                end
                self.smoothY1 = self.smoothY1 * 0.98 + y1 * 0.02
                local x2, y2, z2 = localToWorld(getParent(effectNode), currentWidth, 0, 0)
                if self.smoothY2 == nil then
                    self.smoothY2 = y2
                end
                self.smoothY2 = self.smoothY2 * 0.98 + y2 * 0.02
                local _, y, _ = worldToLocal(getParent(effectNode), x2, self.smoothY2 + (y1 - self.smoothY1), z2)
                local angle = math.atan(y / currentWidth)
                setRotation(effectNode, 0, 0, angle)
            end
        end
    end
    FertilizerMotionPathEffect:superClass().update(self, dt)
end
function FertilizerMotionPathEffect:stop()
    self.smoothY1 = nil
    self.smoothY2 = nil
    return FertilizerMotionPathEffect:superClass().stop(self)
end
function FertilizerMotionPathEffect:reset()
    return FertilizerMotionPathEffect:superClass().reset(self)
end
function FertilizerMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
    TypedMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
end
function FertilizerMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
    TypedMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
end
function FertilizerMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
    TypedMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
end
function FertilizerMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
    TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
end
function FertilizerMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
    TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
end
function FertilizerMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
    TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
end
function FertilizerMotionPathEffect.registerEffectXMLPaths(schema, basePath)
    TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. ".motionPathEffect#isLeft", "(FertilizerMotionPathEffect) Defines if the effect is left or right", false)
end