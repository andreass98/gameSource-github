WindrowerMotionPathEffect = {}
local WindrowerMotionPathEffect_mt = Class(WindrowerMotionPathEffect, TypedMotionPathEffect)
function WindrowerMotionPathEffect.new(customMt)
    -- upvalues: (copy) WindrowerMotionPathEffect_mt
    local self = TypedMotionPathEffect.new(customMt or WindrowerMotionPathEffect_mt)
    self.workArea = nil
    self.hasTestAreas = false
    self.isLeft = false
    self.windrowerStartFade = 0.2
    self.windrowerEndFade = 0.8
    self.windrowerFadeLength = self.windrowerEndFade - self.windrowerStartFade
    return self
end
function WindrowerMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
    if not WindrowerMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
        return false
    end
    self.isPickup = xmlFile:getValue(key .. ".motionPathEffect#isPickup", false)
    self.isLeft = xmlFile:getValue(key .. ".motionPathEffect#isLeft", self.isLeft)
    self.minFadeOrig = self.minFade
    self.windrowerStartFade = xmlFile:getValue(key .. ".motionPathEffect#startFade", 0.2)
    self.windrowerEndFade = xmlFile:getValue(key .. ".motionPathEffect#endFade", 0.8)
    self.windrowerFadeLength = self.windrowerEndFade - self.windrowerStartFade
    return true
end
function WindrowerMotionPathEffect:update(dt)
    if self.workArea == nil and self.workAreaIndex ~= nil then
        self.workArea = self.parent:getWorkAreaByIndex(self.workAreaIndex)
        local currentTestAreaMinX = false
        if self.workArea ~= nil then
            currentTestAreaMinX = self.workArea.hasTestAreas
        end
        self.hasTestAreas = currentTestAreaMinX
    end
    if self.workArea ~= nil and self.hasTestAreas then
        if self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON then
            local currentTestAreaMinX, currentTestAreaMaxX, testAreaMinX, testAreaMaxX = self.parent:getTestAreaWidthByWorkAreaIndex(self.workAreaIndex)
            if self.isPickup then
                if currentTestAreaMinX ~= -math.huge and currentTestAreaMaxX ~= math.huge then
                    if self.isLeft then
                        self.fadeVisibilityMin = 0.5 + currentTestAreaMinX / testAreaMaxX * 0.5
                        self.fadeVisibilityMax = 1 - (0.5 + currentTestAreaMaxX / testAreaMinX * 0.5)
                    else
                        self.fadeVisibilityMin = 0.5 + currentTestAreaMaxX / testAreaMinX * 0.5
                        self.fadeVisibilityMax = 1 - (0.5 + currentTestAreaMinX / testAreaMaxX * 0.5)
                    end
                end
            else
                local fadePos = 1
                if currentTestAreaMinX ~= -math.huge and currentTestAreaMaxX ~= math.huge then
                    if self.isLeft then
                        fadePos = 1 - (currentTestAreaMinX - testAreaMinX) / (testAreaMaxX - testAreaMinX)
                    else
                        fadePos = (currentTestAreaMaxX - testAreaMinX) / (testAreaMaxX - testAreaMinX)
                    end
                end
                local newFade = fadePos * self.windrowerFadeLength + self.windrowerStartFade
                newFade = fadePos <= 0.01 and 0 or (fadePos >= 0.99 and 1 or newFade)
                local dir = math.sign(newFade - self.fadeOut)
                local newFade = 0
                self.fadeOut = math.clamp(self.fadeOut + dt * 0.001 * self.effectSpeedScale * dir, newFade, dir < 0 and 1 or newFade)
                self.minFade = math.min(self.minFade, self.fadeOut)
                if self.immediateUpdate then
                    self.fadeOut = newFade
                    self.minFade = newFade
                    self.immediateUpdate = false
                end
            end
        else
            self.immediateUpdate = true
            self.minFade = self.minFadeOrig
        end
    end
    WindrowerMotionPathEffect:superClass().update(self, dt)
end
function WindrowerMotionPathEffect:setWorkAreaIndex(workAreaIndex)
    self.workAreaIndex = workAreaIndex
end
function WindrowerMotionPathEffect:stop()
    return WindrowerMotionPathEffect:superClass().stop(self)
end
function WindrowerMotionPathEffect:reset()
    return WindrowerMotionPathEffect:superClass().reset(self)
end
function WindrowerMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
    TypedMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
end
function WindrowerMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
    TypedMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
end
function WindrowerMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
    TypedMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
end
function WindrowerMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
    TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
end
function WindrowerMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
    TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
end
function WindrowerMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
    TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
end
function WindrowerMotionPathEffect.registerEffectXMLPaths(schema, basePath)
    TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. ".motionPathEffect#isPickup", "(WindrowerMotionPathEffect) Defines if the effect is a pickup effect and width is adjusted by hiding rows instead of the fade value", false)
    schema:register(XMLValueType.BOOL, basePath .. ".motionPathEffect#isLeft", "(WindrowerMotionPathEffect) Defines if rake is mounted on left or right side", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#startFade", "(WindrowerMotionPathEffect) Start of fading depending on test area result", 0.2)
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#endFade", "(WindrowerMotionPathEffect) End of fading depending on test area result", 0.8)
end