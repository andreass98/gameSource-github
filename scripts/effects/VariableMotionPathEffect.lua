VariableMotionPathEffect = {}
local VariableMotionPathEffect_mt = Class(VariableMotionPathEffect, TypedMotionPathEffect)
function VariableMotionPathEffect.new(customMt)
    -- upvalues: (copy) VariableMotionPathEffect_mt
    return TypedMotionPathEffect.new(customMt or VariableMotionPathEffect_mt)
end
function VariableMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
    if not VariableMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
        return false
    end
    self.referenceNode = xmlFile:getValue(key .. ".variableState#referenceNode", nil, Utils.getNoNil(node, self.rootNodes), i3dMapping)
    if self.referenceNode ~= nil then
        self.referenceRotAxis = xmlFile:getValue(key .. ".variableState#referenceRotAxis")
        self.referenceTransAxis = xmlFile:getValue(key .. ".variableState#referenceTransAxis")
        self.axisValues = { 0, 0, 0 }
        if self.referenceRotAxis == nil and self.referenceTransAxis == nil then
            Logging.xmlWarning(xmlFile, "VariableMotionPathEffect: No reference rotation or translation axis defined in (%s)", key)
        end
    end
    self.referenceUseVehicleSpeed = xmlFile:getValue(key .. ".variableState#referenceUseVehicleSpeed", false)
    for _, stateKey in xmlFile:iterator(key .. ".variableState.state") do
        local referenceValue = xmlFile:getValue(stateKey .. "#referenceValue")
        if self.referenceRotAxis ~= nil then
            referenceValue = math.rad(referenceValue)
        end
        local density = xmlFile:getValue(stateKey .. "#density")
        if density ~= nil then
            if self.animCurveDensity == nil then
                self.animCurveDensity = AnimCurve.new(linearInterpolatorN)
            end
            self.animCurveDensity:addKeyframe({
                density,
                ["time"] = referenceValue
            })
        end
        local speedScale = xmlFile:getValue(stateKey .. "#speedScale")
        if speedScale ~= nil then
            if self.animCurveSpeedScale == nil then
                self.animCurveSpeedScale = AnimCurve.new(linearInterpolatorN)
            end
            self.animCurveSpeedScale:addKeyframe({
                speedScale,
                ["time"] = referenceValue
            })
        end
        local visibilityXMin, visibilityXMax = xmlFile:getValue(stateKey .. "#visibilityX")
        local visibilityYMin, visibilityYMax = xmlFile:getValue(stateKey .. "#visibilityY")
        local visibilityZMin, visibilityZMax = xmlFile:getValue(stateKey .. "#visibilityZ")
        if visibilityXMin ~= nil or (visibilityXMax ~= nil or (visibilityYMin ~= nil or (visibilityYMax ~= nil or (visibilityZMin ~= nil or visibilityZMax ~= nil)))) then
            if self.animCurveVisibility == nil then
                self.animCurveVisibility = AnimCurve.new(linearInterpolatorN)
            end
            self.animCurveVisibility:addKeyframe({
                visibilityXMin,
                visibilityXMax,
                visibilityYMin,
                visibilityYMax,
                visibilityZMin,
                visibilityZMax,
                ["time"] = referenceValue
            })
        end
        local scaleX, scaleY, scaleZ = xmlFile:getValue(stateKey .. "#scale")
        if scaleX ~= nil or (scaleY ~= nil or scaleZ ~= nil) then
            if self.animCurveScale == nil then
                self.animCurveScale = AnimCurve.new(linearInterpolatorN)
            end
            self.animCurveScale:addKeyframe({
                scaleX,
                scaleY,
                scaleZ,
                ["time"] = referenceValue
            })
        end
    end
    return true
end
function VariableMotionPathEffect:update(dt)
    VariableMotionPathEffect:superClass().update(self, dt)
    local refValue = 0
    if self.referenceNode ~= nil then
        if self.referenceRotAxis == nil then
            if self.referenceTransAxis ~= nil then
                local visibilityYMax, visibilityZMin, visibilityZMax = getTranslation(self.referenceNode)
                self.axisValues[1] = visibilityYMax
                self.axisValues[2] = visibilityZMin
                self.axisValues[3] = visibilityZMax
                refValue = self.axisValues[self.referenceTransAxis]
            end
        else
            local visibilityYMax, visibilityZMin, visibilityZMax = getRotation(self.referenceNode)
            self.axisValues[1] = visibilityYMax
            self.axisValues[2] = visibilityZMin
            self.axisValues[3] = visibilityZMax
            refValue = self.axisValues[self.referenceRotAxis]
        end
    end
    if self.referenceUseVehicleSpeed and self.parent.getLastSpeed ~= nil then
        refValue = self.parent:getLastSpeed()
    end
    if self.animCurveDensity ~= nil then
        self.effectDensityScaleSetting = self.animCurveDensity:get(refValue) or self.effectDensityScaleSetting
    end
    if self.animCurveSpeedScale ~= nil then
        local density = self.animCurveSpeedScale:get(refValue)
        if density ~= nil then
            self.effectSpeedScale = density
            self.effectSpeedScaleOrig = density
        end
    end
    if self.animCurveVisibility ~= nil then
        local density, visibilityXMax, visibilityYMin, visibilityYMax, visibilityZMin, visibilityZMax = self.animCurveVisibility:get(refValue)
        local visibilityXChanged = false
        local visibilityYChanged = false
        local visibilityZChanged = false
        if density ~= nil then
            self.visibilityX[1] = density
            visibilityXChanged = true
        end
        if visibilityXMax ~= nil then
            self.visibilityX[2] = visibilityXMax
            visibilityXChanged = true
        end
        if visibilityYMin ~= nil then
            self.visibilityY[1] = visibilityYMin
            visibilityYChanged = true
        end
        if visibilityYMax ~= nil then
            self.visibilityY[2] = visibilityYMax
            visibilityYChanged = true
        end
        if visibilityZMin ~= nil then
            self.visibilityZ[1] = visibilityZMin
            visibilityZChanged = true
        end
        if visibilityZMax ~= nil then
            self.visibilityZ[2] = visibilityZMax
            visibilityZChanged = true
        end
        for _, effectNode in ipairs(self.currentEffectNodes) do
            if visibilityXChanged and (self.visibilityX ~= nil and #self.visibilityX == 2) then
                setShaderParameterRecursive(effectNode, "visibilityX", self.visibilityX[1], self.visibilityX[2], nil, nil, false)
            end
            if visibilityYChanged and (self.visibilityY ~= nil and #self.visibilityY == 2) then
                setShaderParameterRecursive(effectNode, "visibilityY", self.visibilityY[1], self.visibilityY[2], nil, nil, false)
            end
            if visibilityZChanged and (self.visibilityZ ~= nil and #self.visibilityZ == 2) then
                setShaderParameterRecursive(effectNode, "visibilityZ", self.visibilityZ[1], self.visibilityZ[2], nil, nil, false)
            end
        end
    end
    if self.animCurveScale ~= nil then
        local density, visibilityXMax, visibilityYMin = self.animCurveScale:get(refValue)
        for visibilityXChanged, visibilityYChanged in ipairs(self.currentEffectNodes) do
            setScale(visibilityYChanged, density, visibilityXMax, visibilityYMin)
        end
    end
end
function VariableMotionPathEffect.registerEffectXMLPaths(schema, basePath)
    TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".variableState#referenceNode", "(VariableMotionPathEffect) Reference Node")
    schema:register(XMLValueType.INT, basePath .. ".variableState#referenceRotAxis", "(VariableMotionPathEffect) Reference Rotation Axis")
    schema:register(XMLValueType.INT, basePath .. ".variableState#referenceTransAxis", "(VariableMotionPathEffect) Reference Translation Axis")
    schema:register(XMLValueType.BOOL, basePath .. ".variableState#referenceUseVehicleSpeed", "(VariableMotionPathEffect) Use vehicle speed as reference value", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".variableState.state(?)#referenceValue", "(VariableMotionPathEffect) Reference Value")
    schema:register(XMLValueType.FLOAT, basePath .. ".variableState.state(?)#density", "(VariableMotionPathEffect) Density in this state")
    schema:register(XMLValueType.FLOAT, basePath .. ".variableState.state(?)#speedScale", "(VariableMotionPathEffect) Speed scale in this state")
    schema:register(XMLValueType.VECTOR_2, basePath .. ".variableState.state(?)#visibilityX", "(VariableMotionPathEffect) Visibility cut on X axis in this state", "50 -50")
    schema:register(XMLValueType.VECTOR_2, basePath .. ".variableState.state(?)#visibilityY", "(VariableMotionPathEffect) Visibility cut on Y axis in this state", "50 -50")
    schema:register(XMLValueType.VECTOR_2, basePath .. ".variableState.state(?)#visibilityZ", "(VariableMotionPathEffect) Visibility cut on Z axis in this state", "50 -50")
    schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".variableState.state(?)#scale", "(VariableMotionPathEffect) Scale of the mesh in this state")
end