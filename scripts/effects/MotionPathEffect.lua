MotionPathEffect = {}
local MotionPathEffect_mt = Class(MotionPathEffect, Effect)
MotionPathEffect.STATE_OFF = 0
MotionPathEffect.STATE_TURNING_ON = 1
MotionPathEffect.STATE_ON = 2
MotionPathEffect.STATE_TURNING_OFF = 3
MotionPathEffect.DEFAULT_CLIP_DISTANCE = 150
function MotionPathEffect.new(customMt)
    -- upvalues: (copy) MotionPathEffect_mt
    local self = Effect.new(customMt or MotionPathEffect_mt)
    self.state = MotionPathEffect.STATE_OFF
    self.fadeIn = 0
    self.fadeOut = 0
    self.numRows = 0
    self.rowLength = 0
    self.lastSharedEffect = nil
    self.lastSharedEffectMesh = nil
    self.lastSharedEffectMaterial = nil
    self.currentEffectNodes = {}
    self.hasCurrentEffectNodes = false
    self.lastDensity = 0
    self.lastDensityReal = 1
    self.lastDensityDelay = ValueDelay.new(750, -1)
    self.effectDensityScale = 1
    self.pathPosition = 0
    self.lastPathPosition = 0
    self.useVehicleSpeed = false
    self.motionPathEffectManager = g_motionPathEffectManager
    return self
end
function MotionPathEffect:delete()
    if self.hasCurrentEffectNodes then
        local i = #self.currentEffectNodes
        for i = i, 1, -1 do
            delete(self.currentEffectNodes[i])
            self.currentEffectNodes[i] = nil
        end
        self.hasCurrentEffectNodes = false
    end
    if self.texture ~= nil then
        delete(self.texture)
        self.texture = nil
    end
    if self.densityMask ~= nil then
        delete(self.densityMask)
        self.densityMask = nil
    end
    MotionPathEffect:superClass().delete(self)
end
function MotionPathEffect:loadEffectAttributes(xmlFile, key, node, _, i3dMapping)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#lengthAndRadius")
    self.linkNodes = {}
    for _, linkNodeKey in xmlFile:iterator(key .. ".linkNode") do
        local linkNode = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), xmlFile:getValue(linkNodeKey .. "#node"), i3dMapping)
        if linkNode ~= nil then
            table.insert(self.linkNodes, linkNode)
        end
    end
    local linkNode = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), xmlFile:getValue(key .. "#linkNode"), i3dMapping)
    if linkNode ~= nil then
        table.insert(self.linkNodes, linkNode)
    end
    if #self.linkNodes == 0 then
        Logging.xmlError(xmlFile, "Missing linkNode in \'%s\'", key)
        return false
    end
    self.effectNode = self.linkNodes[1]
    self.effectType = xmlFile:getValue(key .. "#effectType", "DEFAULT"):upper()
    self.textureFilename = xmlFile:getValue(key .. ".motionPathEffect#textureFilename")
    if self.textureFilename == nil then
        Logging.xmlError(xmlFile, "No texture defined for motion path effect \'%s\'. Please update effects to new motion path effect system.", key)
        return false
    end
    self.textureFilename = Utils.getFilename(self.textureFilename, self.baseDirectory)
    self.texture = createMaterialTextureFromFile(self.textureFilename, true, false)
    if self.texture == 0 then
        self.texture = nil
        return false
    end
    if g_currentMission.vehicleSystem.isReloadRunning then
        reloadResource(self.textureFilename)
    end
    self.textureRealWidth = xmlFile:getValue(key .. ".motionPathEffect#textureRealWidth")
    self.numRows = xmlFile:getValue(key .. ".motionPathEffect#numRows", 12)
    self.rowLength = xmlFile:getValue(key .. ".motionPathEffect#rowLength", 30)
    self.useVehicleSpeed = xmlFile:getValue(key .. ".motionPathEffect#useVehicleSpeed", self.useVehicleSpeed)
    self.maxReferenceVehicleSpeed = xmlFile:getValue(key .. ".motionPathEffect#maxReferenceVehicleSpeed", 10)
    self.speedScale = xmlFile:getValue(key .. ".motionPathEffect#speedScale")
    self.effectSpeedScale = self.speedScale or 1
    self.effectSpeedScaleOrig = self.speedScale or 1
    self.verticalOffset = xmlFile:getValue(key .. ".motionPathEffect#verticalOffset")
    self.shapeScale = xmlFile:getValue(key .. ".motionPathEffect#shapeScale")
    self.maxShapeScale = xmlFile:getValue(key .. ".motionPathEffect#maxShapeScale")
    self.fadeOutScale = xmlFile:getValue(key .. ".motionPathEffect#fadeOutScale", 1)
    self.minFade = xmlFile:getValue(key .. ".motionPathEffect#minFade", 0)
    self.inversedFadeOut = xmlFile:getValue(key .. ".motionPathEffect#inversedFadeOut", false)
    self.scrollLength = xmlFile:getValue(key .. ".motionPathEffect#scrollLength", 1)
    self.delay = xmlFile:getValue(key .. ".motionPathEffect#delay", 0)
    self.startDelay = xmlFile:getValue(key .. ".motionPathEffect#startDelay", self.delay) * 1000
    self.stopDelay = xmlFile:getValue(key .. ".motionPathEffect#stopDelay", self.delay) * 1000
    self.effectDensityScaleSetting = xmlFile:getValue(key .. ".motionPathEffect#density", 1)
    self.densityMaskFilename = xmlFile:getValue(key .. ".motionPathEffect#densityMaskFilename")
    if self.densityMaskFilename ~= nil then
        self.densityMaskFilename = Utils.getFilename(self.densityMaskFilename, self.baseDirectory)
        self.densityMask = createMaterialTextureFromFile(self.densityMaskFilename, true, false)
        if self.densityMask == 0 then
            self.densityMask = nil
        end
    end
    self.speedReferenceAnimation = xmlFile:getValue(key .. ".motionPathEffect#speedReferenceAnimation")
    self.speedReferenceAnimationOffset = xmlFile:getValue(key .. ".motionPathEffect#speedReferenceAnimationOffset", 0)
    self.visibilityX = xmlFile:getValue(key .. ".motionPathEffect#visibilityX", "50 -50", true)
    self.visibilityY = xmlFile:getValue(key .. ".motionPathEffect#visibilityY", "50 -50", true)
    self.visibilityZ = xmlFile:getValue(key .. ".motionPathEffect#visibilityZ", "50 -50", true)
    self.currentStartDelay = 0
    self.currentStopDelay = 0
    self.fadeIn = self.minFade
    self.fadeOut = self.minFade
    self.fadeVisibilityMin = xmlFile:getValue(key .. ".motionPathEffect#fadeVisibilityMin", 1)
    self.fadeVisibilityMax = xmlFile:getValue(key .. ".motionPathEffect#fadeVisibilityMax", 0)
    local speedFuncStr = xmlFile:getValue(key .. ".motionPathEffect#speedFunc")
    if speedFuncStr ~= nil then
        if self.parent[speedFuncStr] == nil then
            Logging.xmlWarning(xmlFile, "Could not find speed function \'%s\' for rotation animation \'%s\'!", speedFuncStr, key)
        else
            self.speedFunc = self.parent[speedFuncStr]
            self.speedFuncParam = xmlFile:getValue(key .. ".motionPathEffect#speedFuncParam")
        end
    end
    return true
end
function MotionPathEffect:transformEffectNode(xmlFile, key, node)
    if self.node ~= nil then
        MotionPathEffect:superClass().transformEffectNode(self, xmlFile, key, node)
        setVisibility(self.node, true)
    end
end
function MotionPathEffect:update(dt)
    if self.useVehicleSpeed then
        if self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON then
            self.effectSpeedScale = self.effectSpeedScaleOrig * math.clamp(self.parent:getLastSpeed() / self.maxReferenceVehicleSpeed, 0, 1)
        else
            self.effectSpeedScale = self.effectSpeedScaleOrig
            if self.inversedFadeOut then
                self.effectSpeedScale = -self.effectSpeedScale
            end
        end
    elseif self.speedFunc ~= nil then
        local speedScale = self.speedFunc(self.parent, self.speedFuncParam)
        if speedScale == nil then
            self.effectSpeedScale = self.effectSpeedScaleOrig
        else
            self.effectSpeedScale = self.effectSpeedScaleOrig * speedScale
        end
    end
    local speedScale = self.effectSpeedScale
    if self.state == MotionPathEffect.STATE_TURNING_OFF then
    end
    self.pathPosition = (self.pathPosition + dt * 0.001 * speedScale) % self.scrollLength
    if self.speedReferenceAnimation ~= nil then
        self.pathPosition = self.parent:getAnimationTime(self.speedReferenceAnimation) + self.speedReferenceAnimationOffset
    end
    if self.state == MotionPathEffect.STATE_TURNING_ON then
        self.currentStartDelay = math.max(self.currentStartDelay - dt, 0)
        if self.currentStartDelay == 0 then
            self.fadeIn = math.clamp(self.fadeIn + dt * 0.001 * speedScale, self.minFade, 1)
            self.fadeOut = self.minFade
            if self.fadeIn == 1 then
                self.state = MotionPathEffect.STATE_ON
                if self.currentStopDelay > 0 then
                    self.state = MotionPathEffect.STATE_TURNING_OFF
                end
            end
        end
    end
    if self.state == MotionPathEffect.STATE_TURNING_OFF then
        self.currentStopDelay = math.max(self.currentStopDelay - dt, 0)
        if self.currentStopDelay == 0 then
            local finished = false
            local finished
            if self.inversedFadeOut then
                self.fadeIn = math.clamp(self.fadeIn - dt * 0.001 * math.abs(speedScale), self.minFade, 1)
                self.fadeOut = self.minFade
            else
                self.fadeIn = math.clamp(self.fadeIn + dt * 0.001 * speedScale, self.minFade, 1)
                self.fadeOut = math.clamp(self.fadeOut + dt * 0.001 * speedScale, self.minFade, 1)
            end
            if finished then
                self.fadeIn = self.minFade
                self.fadeOut = self.minFade
                self.state = MotionPathEffect.STATE_OFF
            end
        end
    end
    if self.hasCurrentEffectNodes then
        if self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON then
            self.lastDensity = self.lastDensityDelay:add(self.lastDensityReal)
        else
            self.lastDensityDelay:reset()
        end
        for _, effectNode in ipairs(self.currentEffectNodes) do
            setShaderParameterRecursive(effectNode, "fadeProgress", self.fadeIn, self.fadeOut, self.fadeVisibilityMin, self.fadeVisibilityMax, false)
            setShaderParameterRecursive(effectNode, "density", self.lastDensity * self.effectDensityScale * self.effectDensityScaleSetting, nil, nil, nil, false)
            setShaderParameterRecursive(effectNode, "scrollPos", self.pathPosition, nil, nil, nil, false)
            setShaderParameterRecursive(effectNode, "prevScrollPos", self.lastPathPosition, nil, nil, nil, false)
            setVisibility(effectNode, self.fadeIn ~= self.minFade or self.fadeOut ~= self.minFade)
        end
        self.lastPathPosition = self.pathPosition
    end
end
function MotionPathEffect:isRunning()
    return self.state ~= MotionPathEffect.STATE_OFF
end
function MotionPathEffect:start()
    if self.state == MotionPathEffect.STATE_OFF or self.state == MotionPathEffect.STATE_TURNING_OFF then
        self.state = MotionPathEffect.STATE_TURNING_ON
        if not self.hasCurrentEffectNodes then
            self:loadSharedMotionPathEffect()
        end
        if self.fadeOut > 0.5 then
            self.fadeIn = self.minFade
        end
        self.currentStartDelay = self.startDelay
    end
    self.currentStopDelay = 0
    return true
end
function MotionPathEffect:stop()
    if self.state == MotionPathEffect.STATE_ON or self.state == MotionPathEffect.STATE_TURNING_ON then
        if self.currentStartDelay <= 0 then
            self.state = MotionPathEffect.STATE_TURNING_OFF
            self.currentStopDelay = self.stopDelay
        else
            self.currentStopDelay = math.max(self.stopDelay - self.currentStartDelay, 0.001)
        end
    end
    return true
end
function MotionPathEffect:reset()
    self.fadeIn = self.minFade
    self.fadeOut = self.minFade
    for _, effectNode in ipairs(self.currentEffectNodes) do
        setVisibility(effectNode, false)
    end
end
function MotionPathEffect:getIsVisible()
    return self.fadeIn > self.minFade
end
function MotionPathEffect:getIsFullyVisible()
    return self.fadeIn == 1
end
function MotionPathEffect:setDensity(density)
    self.lastDensityReal = density
end
function MotionPathEffect:getIsSharedEffectMatching(sharedEffect, _)
    local i = 1
    for i = i, #sharedEffect.effectTypes do
        if sharedEffect.effectTypes[i] == self.effectType then
            return true
        end
    end
    return false
end
function MotionPathEffect:getIsEffectMeshMatching(effectMesh, _)
    return effectMesh.rowLength == self.rowLength and effectMesh.numRows == self.numRows
end
function MotionPathEffect:getIsEffectMaterialMatching(effectMaterial, alternativeCheck)
    return true
end
function MotionPathEffect:getEffectMatchingString()
    return string.format("Class: \'%s\', numRows: %d, rowLength: %d", ClassUtil.getClassName(self:class()), self.numRows, self.rowLength)
end
function MotionPathEffect:loadSharedMotionPathEffect()
    local sharedEffect = self.motionPathEffectManager:getSharedMotionPathEffect(self)
    if sharedEffect == nil then
        Logging.error("Could not find motion path effect for settings (%s)", self:getEffectMatchingString())
        if self.hasCurrentEffectNodes then
            local allUsed = #self.currentEffectNodes
            for allUsed = allUsed, 1, -1 do
                delete(self.currentEffectNodes[allUsed])
                self.currentEffectNodes[allUsed] = nil
            end
            self.hasCurrentEffectNodes = false
        end
    else
        if sharedEffect ~= self.lastSharedEffect then
            self.lastSharedEffect = sharedEffect
        end
        self.effectDensityScale = sharedEffect.densityScale or 1
        local effectMesh = self.motionPathEffectManager:getMotionPathEffectMesh(sharedEffect, self)
        if effectMesh == nil then
            Logging.error("Could not find motion path effect mesh for settings (%s)", self:getEffectMatchingString())
            if self.hasCurrentEffectNodes then
                local i = #self.currentEffectNodes
                for i = i, 1, -1 do
                    delete(self.currentEffectNodes[i])
                    self.currentEffectNodes[i] = nil
                end
                self.hasCurrentEffectNodes = false
            end
        else
            if effectMesh ~= self.lastSharedEffectMesh or not self.hasCurrentEffectNodes then
                local i = #self.currentEffectNodes
                local sourceNode = 1
                local allUsed = -1
                for i = i, sourceNode, allUsed do
                    delete(self.currentEffectNodes[i])
                    self.currentEffectNodes[i] = nil
                end
                local sourceNode = effectMesh.node
                if effectMesh.numVariations > 1 then
                    local allUsed = true
                    local i = 1
                    local indexToUse = nil
                    local i = 1
                    local numChildren = effectMesh.numVariations
                    local linkNode = 1
                    for i = i, numChildren, linkNode do
                        if not effectMesh.usedVariations[i] then
                            if math.random(0, 100) > 75 then
                                effectMesh.usedVariations[i] = true
                                indexToUse = i
                            else
                                allUsed = false
                            end
                        end
                    end
                    if indexToUse == nil then
                        effectMesh.usedVariations[i] = true
                        if not allUsed then
                            allUsed = true
                            local i = 1
                            for i = i, effectMesh.numVariations do
                                if not effectMesh.usedVariations[i] then
                                    allUsed = false
                                end
                            end
                        end
                    end
                    if allUsed then
                        local i = 1
                        for i = i, effectMesh.numVariations do
                            effectMesh.usedVariations[i] = false
                        end
                    end
                    if getNumOfChildren(sourceNode) > 0 then
                        sourceNode = getChildAt(sourceNode, (indexToUse or (i or 1)) - 1)
                    end
                end
                for numChildren, linkNode in ipairs(self.linkNodes) do
                    local i = clone(sourceNode, false, false, true)
                    link(linkNode, i)
                    setVisibility(i, self.fadeIn ~= self.minFade or self.fadeOut ~= self.minFade)
                    setClipDistance(i, MotionPathEffect.DEFAULT_CLIP_DISTANCE)
                    table.insert(self.currentEffectNodes, i)
                end
                self.hasCurrentEffectNodes = true
                self.currentEffectNode = self.currentEffectNodes[1]
                self.lastSharedEffectMesh = effectMesh
            end
            self.effectDensityScale = effectMesh.densityScale or self.effectDensityScale
            local sourceNode = self.motionPathEffectManager:getMotionPathEffectMaterial(sharedEffect, self)
            if sourceNode ~= nil then
                for numChildren, linkNode in ipairs(self.currentEffectNodes) do
                    self.motionPathEffectManager:setEffectMaterial(linkNode, sourceNode)
                end
                self.effectDensityScale = sourceNode.densityScale or self.effectDensityScale
                self.lastSharedEffectMaterial = sourceNode
            end
        end
        self.effectSpeedScale = self.motionPathEffectManager:applyEffectConfiguration(sharedEffect, effectMesh, self.lastSharedEffectMaterial, self.currentEffectNodes, self.texture, self.speedScale)
        self.effectSpeedScaleOrig = self.effectSpeedScale
        for indexToUse, numChildren in ipairs(self.currentEffectNodes) do
            if self.verticalOffset ~= nil then
                setShaderParameterRecursive(numChildren, "verticalOffset", self.verticalOffset, 0, 0, 0, false)
            end
            if self.shapeScale ~= nil then
                setShaderParameterRecursive(numChildren, "sizeScale", self.shapeScale, nil, nil, nil, false)
            end
            if self.maxShapeScale ~= nil then
                setShaderParameterRecursive(numChildren, "sizeScale", nil, self.maxShapeScale, nil, nil, false)
            end
            if self.visibilityX ~= nil and #self.visibilityX == 2 then
                setShaderParameterRecursive(numChildren, "visibilityX", self.visibilityX[1], self.visibilityX[2], nil, nil, false)
            end
            if self.visibilityY ~= nil and #self.visibilityY == 2 then
                setShaderParameterRecursive(numChildren, "visibilityY", self.visibilityY[1], self.visibilityY[2], nil, nil, false)
            end
            if self.visibilityZ ~= nil and #self.visibilityZ == 2 then
                setShaderParameterRecursive(numChildren, "visibilityZ", self.visibilityZ[1], self.visibilityZ[2], nil, nil, false)
            end
            if self.densityMask ~= nil then
                self.motionPathEffectManager:setEffectCustomMap(numChildren, "densityMask", self.densityMask)
            end
            setShaderParameterRecursive(numChildren, "speed", 0, 0, nil, nil, false)
            setShaderParameterRecursive(numChildren, "randomSeed", math.random() * 10000, nil, nil, nil, false)
        end
    end
end
function MotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
    motionPathEffect.speedScale = xmlFile:getValue(key .. "#speedScale")
    motionPathEffect.densityScale = xmlFile:getValue(key .. "#densityScale")
end
function MotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
    effectMesh.speedScale = xmlFile:getValue(key .. "#speedScale")
    effectMesh.densityScale = xmlFile:getValue(key .. "#densityScale")
end
function MotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
    effectMaterial.speedScale = xmlFile:getValue(key .. "#speedScale")
    effectMaterial.densityScale = xmlFile:getValue(key .. "#densityScale")
end
function MotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#speedScale", "Speed of effect", 0.5)
    schema:register(XMLValueType.FLOAT, basePath .. "#densityScale", "Density of effect", 1)
end
function MotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#speedScale", "Speed of effect", 0.5)
    schema:register(XMLValueType.FLOAT, basePath .. "#densityScale", "Density of effect", 1)
end
function MotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#speedScale", "Speed of effect", 0.5)
    schema:register(XMLValueType.FLOAT, basePath .. "#densityScale", "Density of effect", 1)
end
function MotionPathEffect.registerEffectXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#linkNode", "Link node")
    schema:register(XMLValueType.STRING, basePath .. ".linkNode(?)#node", "Link node")
    schema:register(XMLValueType.STRING, basePath .. "#effectType", "(MotionPathEffect) Effect type string")
    schema:register(XMLValueType.STRING, basePath .. ".motionPathEffect#textureFilename", "(MotionPathEffect) Animation texture", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#textureRealWidth", "(MotionPathEffect) Real width of effect in meter with this texture")
    schema:register(XMLValueType.INT, basePath .. ".motionPathEffect#numRows", "(MotionPathEffect) Number of rows", 0)
    schema:register(XMLValueType.INT, basePath .. ".motionPathEffect#rowLength", "(MotionPathEffect) Number of plants for each row", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#speedScale", "(MotionPathEffect) Speed scale that is applied to effect speed defined in effect.xml or i3d file")
    schema:register(XMLValueType.BOOL, basePath .. ".motionPathEffect#useVehicleSpeed", "(MotionPathEffect) Use speed of vehicle as effect speed")
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#maxReferenceVehicleSpeed", "(MotionPathEffect) This speed represents speed \'1\' for effect", 10)
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#verticalOffset", "(MotionPathEffect) Vertical offset of plants")
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#shapeScale", "(MotionPathEffect) Scale of single shapes")
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#maxShapeScale", "(MotionPathEffect) Scale of single shapes at the end of the effect")
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#minFade", "(MotionPathEffect) Defines start fade value", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#fadeOutScale", "(MotionPathEffect) Fade out speed multiplicator", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".motionPathEffect#inversedFadeOut", "(MotionPathEffect) Using inversed fade in as fade out", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#scrollLength", "(MotionPathEffect) Scroll length to wrap around", 1)
    schema:register(XMLValueType.STRING, basePath .. ".motionPathEffect#speedReferenceAnimation", "(MotionPathEffect) This animation will be used for the effect speed")
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#speedReferenceAnimationOffset", "(MotionPathEffect) Time offset to apply", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#delay", "(MotionPathEffect) Start and stop delay", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#startDelay", "(MotionPathEffect) Start delay", "value of #delay")
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#stopDelay", "(MotionPathEffect) Stop delay", "value of #delay")
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#density", "(MotionPathEffect) Density Scale", 1)
    schema:register(XMLValueType.STRING, basePath .. ".motionPathEffect#densityMaskFilename", "(MotionPathEffect) Custom Density Mask Texture")
    schema:register(XMLValueType.VECTOR_2, basePath .. ".motionPathEffect#visibilityX", "(MotionPathEffect) Visibility cut size X axis", "50 -50")
    schema:register(XMLValueType.VECTOR_2, basePath .. ".motionPathEffect#visibilityY", "(MotionPathEffect) Visibility cut size Y axis", "50 -50")
    schema:register(XMLValueType.VECTOR_2, basePath .. ".motionPathEffect#visibilityZ", "(MotionPathEffect) Visibility cut size Z axis", "50 -50")
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#fadeVisibilityMin", "(MotionPathEffect) Default fade visibility min. value", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#fadeVisibilityMax", "(MotionPathEffect) Default fade visibility max. value", 0)
    schema:register(XMLValueType.STRING, basePath .. ".motionPathEffect#speedFunc", "Lua speed function")
    schema:register(XMLValueType.STRING, basePath .. ".motionPathEffect#speedFuncParam", "Additional string parameter that is passed to the speedFunc")
end