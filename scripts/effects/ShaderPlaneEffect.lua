ShaderPlaneEffect = {}
local ShaderPlaneEffect_mt = Class(ShaderPlaneEffect, Effect)
ShaderPlaneEffect.STATE_OFF = 0
ShaderPlaneEffect.STATE_TURNING_ON = 1
ShaderPlaneEffect.STATE_ON = 2
ShaderPlaneEffect.STATE_TURNING_OFF = 3
function ShaderPlaneEffect.new(customMt)
    -- upvalues: (copy) ShaderPlaneEffect_mt
    local self = Effect.new(customMt or ShaderPlaneEffect_mt)
    self.state = ShaderPlaneEffect.STATE_OFF
    self.planeFadeTime = 0
    return self
end
function ShaderPlaneEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
    if not ShaderPlaneEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
        return false
    end
    self.fadeInTime = Effect.getValue(xmlFile, key, node, "fadeInTime", Effect.getValue(xmlFile, key, node, "fadeTime", 1)) * 1000
    self.fadeOutTime = Effect.getValue(xmlFile, key, node, "fadeOutTime", Effect.getValue(xmlFile, key, node, "fadeTime", 1)) * 1000
    local effectMaterial = self.fadeInTime
    local defaultFillType = math.max(effectMaterial, 0.01)
    local shaderFilename = self.fadeOutTime
    local effectMaterial = math.max(shaderFilename, 0.01)
    self.fadeInTime = defaultFillType
    self.fadeOutTime = effectMaterial
    local effectMaterial = self.planeFadeTime
    local shaderFilename = self.fadeInTime
    local defaultUseTextureArrays = self.fadeOutTime
    self.planeFadeTime = math.max(effectMaterial, shaderFilename, defaultUseTextureArrays)
    self.startDelay = Effect.getValue(xmlFile, key, node, "startDelay", Effect.getValue(xmlFile, key, node, "delay", 0)) * 1000
    self.stopDelay = Effect.getValue(xmlFile, key, node, "stopDelay", Effect.getValue(xmlFile, key, node, "delay", 0)) * 1000
    self.currentDelay = self.startDelay
    self.alwaysVisibile = Effect.getValue(xmlFile, key, node, "alwaysVisibile", false)
    self.showOnFirstUse = Effect.getValue(xmlFile, key, node, "showOnFirstUse", false)
    local defaultFillType = Effect.getValue(xmlFile, key, node, "defaultFillType")
    if defaultFillType ~= nil then
        self.defaultFillType = g_fillTypeManager:getFillTypeIndexByName(defaultFillType)
    end
    self.dynamicFillType = Effect.getValue(xmlFile, key, node, "dynamicFillType", true)
    self.materialType = Effect.getValue(xmlFile, key, node, "materialType", "unloading")
    self.materialTypeId = Effect.getValue(xmlFile, key, node, "materialTypeId", 1)
    self.alignToWorldY = Effect.getValue(xmlFile, key, node, "alignToWorldY", false)
    self.alignXAxisToWorldY = Effect.getValue(xmlFile, key, node, "alignXAxisToWorldY", false)
    self.alignXAxisToWorldNode = Effect.getValue(xmlFile, key, node, "alignXAxisToWorldNode", self.node, i3dNode, i3dMapping)
    self.hasValidMaterial = false
    self.useBaseMaterial = false
    if getNumOfMaterials(self.node) > 1 then
        Logging.xmlWarning(xmlFile, "Failed to assign material to shader plane effect. Node \'%s\' has multiple materials assigned. Please assign only one default material.", getName(self.node))
        return false
    end
    local effectMaterial = g_materialManager:getBaseMaterialByName(self.materialType)
    if effectMaterial == nil then
        if g_materialManager:getMaterialTypeByName(self.materialType) == nil then
            Logging.error("Failed to assign material to shader plane effect. Material \'%s\' not found!", self.materialType)
        end
    else
        setMaterial(self.node, effectMaterial, 0)
        local shaderFilename = getMaterialCustomShaderFilename(effectMaterial)
        local defaultUseTextureArrays = false
        if shaderFilename ~= nil then
            defaultUseTextureArrays = shaderFilename:contains("grainUnloadingSmokeShader") or shaderFilename:contains("grainUnloadingBeltShader") or (shaderFilename:contains("grainUnloadingShader") or shaderFilename:contains("levelerShader"))
        end
        self.useFillTypeTextureArrays = Effect.getValue(xmlFile, key, node, "useFillTypeTextureArrays", defaultUseTextureArrays)
        if self.useFillTypeTextureArrays then
            if shaderFilename == nil or shaderFilename:find("grainUnloadingSmokeShader") == nil then
                g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(self.node, g_terrainNode, true, true, true)
            else
                g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(self.node, g_terrainNode, true, false, false)
            end
        end
        self.useBaseMaterial = true
        self.hasValidMaterial = true
    end
    if not self.dynamicFillType then
        self:setEffectTypeInfo(self.defaultFillType, nil, nil, true)
    end
    self.fadeXDistance = { Effect.getValue(xmlFile, key, node, "fadeXMinDistance", -1.58), Effect.getValue(xmlFile, key, node, "fadeXMaxDistance", 4.18) }
    self.useDistance = Effect.getValue(xmlFile, key, node, "useDistance", true)
    self.extraDistance = Effect.getValue(xmlFile, key, node, "extraDistance", -0.25)
    self.extraDistanceNode = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), Effect.getValue(xmlFile, key, node, "extraDistanceNode"), i3dMapping)
    self.fadeScale = Effect.getValue(xmlFile, key, node, "fadeScale")
    self.uvSpeed = Effect.getValue(xmlFile, key, node, "uvSpeed")
    self.uvScale = Effect.getValue(xmlFile, key, node, "uvScale")
    self.fadeX = { -1, 1 }
    self.fadeY = { -1, 1 }
    self.fadeCur = { -1, 1 }
    self.fadeDir = { 1, 1 }
    self.offset = 0
    setShaderParameter(self.node, "fadeProgress", -1, 1, 0, 0, false)
    if self.alignXAxisToWorldY then
        self.worldYReferenceFrame = createTransformGroup("worldYReferenceFrame")
        link(getParent(self.alignXAxisToWorldNode), self.worldYReferenceFrame)
        setTranslation(self.worldYReferenceFrame, getTranslation(self.alignXAxisToWorldNode))
        setRotation(self.worldYReferenceFrame, getRotation(self.alignXAxisToWorldNode))
    end
    return true
end
function ShaderPlaneEffect:update(dt)
    ShaderPlaneEffect:superClass().update(self, dt)
    local isRunning = false
    self.currentDelay = self.currentDelay - dt
    local isRunning
    if self.currentDelay <= 0 then
        local fadeTime = self.fadeInTime
        if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
            fadeTime = self.fadeOutTime
        end
        local valueX = self.fadeCur[1] + math.abs(self.fadeX[1] - self.fadeX[2]) * (dt / fadeTime) * self.fadeDir[1]
        local isVisible = self.fadeCur[2]
        local valueY = isVisible + math.abs(self.fadeY[1] - self.fadeY[2]) * (dt / fadeTime) * self.fadeDir[2]
        local isVisible = self.fadeCur
        isVisible[1] = math.clamp(valueX, self.fadeX[1], self.fadeX[2])
        local isVisible = self.fadeCur
        isVisible[2] = math.clamp(valueY, self.fadeY[1], self.fadeY[2])
        setShaderParameter(self.node, "fadeProgress", self.fadeCur[1], self.fadeCur[2], 0, 0, false)
        if self.showOnFirstUse then
            if self.hasValidMaterial then
                setVisibility(self.node, true)
            end
        else
            local isVisible = true
            if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
                isVisible = not (self.fadeCur[1] == self.fadeX[2] and self.fadeCur[2] == self.fadeY[1])
            end
            local _ = setVisibility
            if isVisible then
                isVisible = self.hasValidMaterial
            end
            _(self.node, isVisible)
        end
    else
        isRunning = true
    end
    if self.alignXAxisToWorldY then
        local fadeTime, valueX, valueY = worldDirectionToLocal(self.worldYReferenceFrame, 0, 1, 0)
        local isVisible = math.atan2(valueY, valueX)
        local _, ry, rz = getRotation(self.alignXAxisToWorldNode)
        setRotation(self.alignXAxisToWorldNode, isVisible, ry, rz)
    end
    if self.alignToWorldY then
        I3DUtil.setWorldDirection(self.node, 0, 0, 1, 0, 1, 0)
    end
    if not isRunning then
        if self.state == ShaderPlaneEffect.STATE_TURNING_ON then
            self.state = ShaderPlaneEffect.STATE_ON
            return
        end
        if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
            self.state = ShaderPlaneEffect.STATE_OFF
        end
    end
end
function ShaderPlaneEffect:isRunning()
    return self.state == ShaderPlaneEffect.STATE_TURNING_OFF or (self.state == ShaderPlaneEffect.STATE_TURNING_ON or self.state == ShaderPlaneEffect.STATE_ON)
end
function ShaderPlaneEffect:start()
    if not self:canStart() or (self.state == ShaderPlaneEffect.STATE_TURNING_ON or self.state == ShaderPlaneEffect.STATE_ON) then
        return false
    end
    self.state = ShaderPlaneEffect.STATE_TURNING_ON
    self.fadeCur[1] = -1
    self.fadeCur[2] = 1
    self.fadeDir[1] = 1
    self.fadeDir[2] = 1
    self.currentDelay = self.startDelay
    return true
end
function ShaderPlaneEffect:stop()
    if self.state == ShaderPlaneEffect.STATE_TURNING_OFF or self.state == ShaderPlaneEffect.STATE_OFF then
        return false
    end
    self.state = ShaderPlaneEffect.STATE_TURNING_OFF
    self.fadeDir[1] = 1
    self.fadeDir[2] = -1
    self.currentDelay = self.stopDelay
    return true
end
function ShaderPlaneEffect:reset()
    self.fadeCur[1] = -1
    self.fadeCur[2] = 1
    self.fadeDir[1] = 1
    self.fadeDir[2] = -1
    setShaderParameter(self.node, "fadeProgress", self.fadeCur[1], self.fadeCur[2], 0, 0, false)
    setVisibility(self.node, false)
    self.state = ShaderPlaneEffect.STATE_OFF
end
function ShaderPlaneEffect:setEffectTypeInfo(fillTypeIndex, _, _, force)
    local success = true
    if self.dynamicFillType and self.lastFillTypeIndex ~= fillTypeIndex or force then
        if self.useFillTypeTextureArrays then
            local textureArrayIndex = g_fillTypeManager:getTextureArrayIndexByFillTypeIndex(self.defaultFillType or fillTypeIndex)
            if textureArrayIndex ~= nil then
                setShaderParameter(self.node, "fillTypeId", textureArrayIndex - 1, 0, 0, 0, false)
            end
            local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
            if fillTypeDesc ~= nil then
                setShaderParameter(self.node, "alphaClipScale", fillTypeDesc:getBeltEffectAlphaClipScale(), nil, nil, nil, false)
            end
        end
        if not self.useBaseMaterial and (self.materialType ~= nil and self.materialTypeId ~= nil) then
            local textureArrayIndex = g_materialManager:getMaterial(fillTypeIndex, self.materialType, self.materialTypeId)
            if textureArrayIndex == nil and self.defaultFillType ~= nil then
                textureArrayIndex = g_materialManager:getMaterial(self.defaultFillType, self.materialType, self.materialTypeId)
            end
            self.hasValidMaterial = textureArrayIndex ~= nil
            if textureArrayIndex == nil then
                success = false
            else
                setMaterial(self.node, textureArrayIndex, 0)
            end
        end
        local textureArrayIndex = getMaterial(self.node, 0)
        local fillTypeDesc = getMaterialIsAlphaBlended(textureArrayIndex)
        if string.contains(string.lower(self.materialType), "smoke") or fillTypeDesc then
            setObjectMask(self.node, 16711807)
        end
        if self.fadeScale ~= nil then
            setShaderParameter(self.node, "fadeScale", self.fadeScale, 0, 0, 0, false)
        end
        if self.uvSpeed ~= nil then
            setShaderParameter(self.node, "uvSpeedMult", self.uvSpeed, 0, 0, 0, false)
        end
        setShaderParameter(self.node, "uvScaleSpeed", self.uvScale, self.uvSpeed, nil, nil, false)
        self.lastFillTypeIndex = fillTypeIndex
    end
    return success
end
function ShaderPlaneEffect:getIsVisible()
    return self.fadeCur[1] > self.fadeX[1] and self.fadeCur[2] == self.fadeY[2]
end
function ShaderPlaneEffect:getIsFullyVisible()
    return math.abs(self.fadeCur[1] - self.fadeX[2]) < 0.05 and math.abs(self.fadeCur[2] - self.fadeY[2]) < 0.05
end
function ShaderPlaneEffect:setDelays(startDelay, stopDelay)
    if self.state == ShaderPlaneEffect.STATE_TURNING_ON then
        self.currentDelay = math.max(0, self.currentDelay + (startDelay - self.startDelay))
    elseif self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
        self.currentDelay = math.max(0, self.currentDelay + (stopDelay - self.stopDelay))
    end
    self.startDelay = startDelay
    self.stopDelay = stopDelay
end
function ShaderPlaneEffect:setOffset(offset)
    self.offset = offset
end
function ShaderPlaneEffect:setDistance(distance)
    if self.useDistance then
        distance = distance + self.extraDistance
        if self.extraDistanceNode ~= nil then
            local _, y, _ = localToLocal(self.node, self.extraDistanceNode, 0, 0, 0)
        end
        self.fadeX[2] = 2 * ((distance - self.fadeXDistance[1]) / (self.fadeXDistance[2] - self.fadeXDistance[1])) - 1
    end
end
function ShaderPlaneEffect:setColor(r, g, b, a)
    if self.node ~= nil then
        setShaderParameter(self.node, "colorScale", r, g, b, a, false)
    end
end
function ShaderPlaneEffect.registerEffectXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#fadeTime", "(ShaderPlaneEffect) Fade time for fade in and fade out", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#fadeInTime", "(ShaderPlaneEffect) Fade in time", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#fadeOutTime", "(ShaderPlaneEffect) Fade out time", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#delay", "(ShaderPlaneEffect) Start/Stop delay", 0)
    schema:register(XMLValueType.FLOAT, basePath .. "#startDelay", "(ShaderPlaneEffect) Start delay", 0)
    schema:register(XMLValueType.FLOAT, basePath .. "#stopDelay", "(ShaderPlaneEffect) Stop delay", 0)
    schema:register(XMLValueType.BOOL, basePath .. "#alwaysVisibile", "(ShaderPlaneEffect) Always visible", false)
    schema:register(XMLValueType.BOOL, basePath .. "#showOnFirstUse", "(ShaderPlaneEffect) Show on first use", false)
    schema:register(XMLValueType.STRING, basePath .. "#defaultFillType", "(ShaderPlaneEffect) Default fill type name")
    schema:register(XMLValueType.BOOL, basePath .. "#dynamicFillType", "(ShaderPlaneEffect) Dynamic fill type", false)
    schema:register(XMLValueType.STRING, basePath .. "#materialType", "(ShaderPlaneEffect) Material type name", "unloading")
    schema:register(XMLValueType.STRING, basePath .. "#materialTypeId", "(ShaderPlaneEffect) Material type id", 1)
    schema:register(XMLValueType.BOOL, basePath .. "#useFillTypeTextureArrays", "(ShaderPlaneEffect) Apply shared fill type texture array to effect")
    schema:register(XMLValueType.BOOL, basePath .. "#alignToWorldY", "(ShaderPlaneEffect) Align Y axis to world Y", false)
    schema:register(XMLValueType.BOOL, basePath .. "#alignXAxisToWorldY", "(ShaderPlaneEffect) Align X axis to world Y", false)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#alignXAxisToWorldNode", "(ShaderPlaneEffect) Custom node that is used for the alignment instead of the effect node")
    schema:register(XMLValueType.FLOAT, basePath .. "#fadeXMinDistance", "(ShaderPlaneEffect) Fade X min. distance", -1.58)
    schema:register(XMLValueType.FLOAT, basePath .. "#fadeXMaxDistance", "(ShaderPlaneEffect) Fade X max. distance", 4.18)
    schema:register(XMLValueType.BOOL, basePath .. "#useDistance", "(ShaderPlaneEffect) Use distance", true)
    schema:register(XMLValueType.FLOAT, basePath .. "#extraDistance", "(ShaderPlaneEffect) Extra distance", -0.25)
    schema:register(XMLValueType.STRING, basePath .. "#extraDistanceNode", "(ShaderPlaneEffect) Distance between effect and this node will be added to distance")
    schema:register(XMLValueType.FLOAT, basePath .. "#fadeScale", "(ShaderPlaneEffect) Fade scale")
    schema:register(XMLValueType.FLOAT, basePath .. "#uvSpeed", "(ShaderPlaneEffect) UV speed")
    schema:register(XMLValueType.FLOAT, basePath .. "#uvScale", "(ShaderPlaneEffect) UV Scale")
end