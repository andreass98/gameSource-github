RotationAnimation = {}
RotationAnimation.STATE_OFF = 0
RotationAnimation.STATE_ON = 1
RotationAnimation.STATE_TURNING_OFF = 2
local RotationAnimation_mt = Class(RotationAnimation, Animation)
function RotationAnimation.new(customMt)
    -- upvalues: (copy) RotationAnimation_mt
    local self = Animation.new(customMt or RotationAnimation_mt)
    self.state = RotationAnimation.STATE_OFF
    self.nodes = {}
    self.shaderParameterName = nil
    self.shaderComponentScale = {
        1,
        0,
        0,
        0
    }
    self.rotSpeed = 0
    self.currentAlpha = 0
    self.initialTurnOnFadeTime = 1000
    self.turnOnOffVariance = nil
    self.turnOnFadeTime = 0
    self.turnOffFadeTime = 0
    self.rotAxis = 1
    self.currentRot = 0
    self.owner = nil
    return self
end
function RotationAnimation:load(xmlFile, key, rootNodes, owner, i3dMapping)
    if not xmlFile:hasProperty(key) then
        return nil
    end
    self.owner = owner
    self.rotSpeed = xmlFile:getValue(key .. "#rotSpeed", 1) * 0.001
    local node = xmlFile:getValue(key .. "#node", nil, rootNodes, i3dMapping)
    if node ~= nil then
        self.nodes[node] = 1
    end
    for _, nodeKey in xmlFile:iterator(key .. ".node") do
        local speedScale = xmlFile:getValue(nodeKey .. "#node", nil, rootNodes, i3dMapping)
        if speedScale ~= nil then
            local speedScale = xmlFile:getValue(nodeKey .. "#speedScale", 1)
            local rotSpeed = xmlFile:getValue(nodeKey .. "#rotSpeed")
            if rotSpeed ~= nil then
            end
            self.nodes[speedScale] = speedScale
        end
    end
    if table.size(self.nodes) == 0 then
        Logging.xmlWarning(xmlFile, "Missing node(s) for rotation animation \'%s\'!", key)
        return nil
    end
    self.rootNode = next(self.nodes)
    self.shaderParameterName = xmlFile:getValue(key .. "#shaderParameterName")
    if self.shaderParameterName ~= nil then
        for _, nodeKey in pairs(self.nodes) do
            if not getHasShaderParameter(_, self.shaderParameterName) then
                Logging.xmlWarning(xmlFile, "Node \'%s\' has no shader parameter \'%s\' for animationNode \'%s\'!", getName(_), self.shaderParameterName, key)
                return nil
            end
        end
        self.shaderParameterPrevName = xmlFile:getValue(key .. "#shaderParameterPrevName")
        if self.shaderParameterPrevName == nil then
            local nodeKey = string.upper((string.sub(self.shaderParameterName, 1, 1)))
            local prevName = "prev" .. self.shaderParameterName .. string.sub(nodeKey, 2)
            if getHasShaderParameter(self.rootNode, prevName) then
                self.shaderParameterPrevName = prevName
            end
        else
            for _, nodeKey in pairs(self.nodes) do
                if not getHasShaderParameter(_, self.shaderParameterPrevName) then
                    Logging.xmlWarning(xmlFile, "Node \'%s\' has no shader parameter \'%s\' (prev) for animationNode \'%s\'!", getName(_), self.shaderParameterPrevName, key)
                    return nil
                end
            end
        end
    end
    self.shaderComponentScale = xmlFile:getValue(key .. "#shaderComponentScale", "1 0 0 0", true)
    self.rotSpeed = xmlFile:getValue(key .. "#rotSpeed", 1) * 0.001
    self.rotAxis = xmlFile:getValue(key .. "#rotAxis", 2)
    local _ = xmlFile:getValue(key .. "#turnOnFadeTime", 2) * 1000
    self.turnOnFadeTime = math.max(_, 1)
    local _ = xmlFile:getValue(key .. "#turnOffFadeTime", 2) * 1000
    self.turnOffFadeTime = math.max(_, 1)
    self.turnOnOffVariance = xmlFile:getValue(key .. "#turnOnOffVariance")
    if self.turnOnOffVariance ~= nil then
        self.initialTurnOnFadeTime = self.turnOnFadeTime
        self.initialTurnOffFadeTime = self.turnOffFadeTime
        self.turnOnOffVariance = self.turnOnOffVariance * 1000
    end
    local prevName = xmlFile:getValue(key .. "#speedFunc")
    if prevName ~= nil then
        if owner[prevName] == nil then
            Logging.xmlWarning(xmlFile, "Could not find speed function \'%s\' for rotation animation \'%s\'!", prevName, key)
        else
            self.speedFunc = owner[prevName]
            self.speedFuncTarget = self.owner
            self.speedFuncParam = xmlFile:getValue(key .. "#speedFuncParam")
        end
    end
    self.minAlphaForTurnOff = xmlFile:getValue(key .. "#minAlphaForTurnOff", 0)
    self.delayedTurnOff = false
    self.turnedOffRotation = xmlFile:getValue(key .. "#turnedOffRotation")
    if self.turnedOffRotation ~= nil then
        self.turnOffFadeTimeOrigin = self.turnOffFadeTime
        self.turnedOffSubDivisions = xmlFile:getValue(key .. "#turnedOffSubDivisions", 1)
        if self.shaderParameterName == nil then
            for nodeKey, speedScale in pairs(self.nodes) do
                if self.rotAxis == 2 then
                    setRotation(nodeKey, 0, self.turnedOffRotation * speedScale, 0)
                elseif self.rotAxis == 1 then
                    setRotation(nodeKey, self.turnedOffRotation * speedScale, 0, 0)
                else
                    setRotation(nodeKey, 0, 0, self.turnedOffRotation * speedScale)
                end
            end
            self.currentRot = self.turnedOffRotation
        end
    end
    if self.rotAxis == 1 then
        self.currentRot, _, nodeKey = getRotation(self.rootNode)
    elseif self.rotAxis == 2 then
        local _, _, nodeKey = getRotation(self.rootNode)
        self.currentRot = _
    else
        local _, _, nodeKey = getRotation(self.rootNode)
        self.currentRot = nodeKey
    end
    for speedScale, rotSpeed in pairs(self.nodes) do
        local rx, ry, rz = getRotation(speedScale)
        if self.rotAxis == 2 then
            setRotation(speedScale, rx, self.currentRot * rotSpeed, rz)
        elseif self.rotAxis == 1 then
            setRotation(speedScale, self.currentRot * rotSpeed, ry, rz)
        else
            setRotation(speedScale, rx, ry, self.currentRot * rotSpeed)
        end
    end
    return self
end
function RotationAnimation:update(dt)
    RotationAnimation:superClass().update(self, dt)
    local prevRot = self.currentRot
    local frame = self.speedFunc == nil and 1 or self.speedFunc(self.speedFuncTarget, self.speedFuncParam)
    if self.state == RotationAnimation.STATE_ON then
        if self.currentAlpha < 1 then
            while dt > 0 do
                local scaleZ = self.currentAlpha + math.min(16.66667, dt) / self.turnOnFadeTime
                self.currentAlpha = math.min(1, scaleZ)
                local rot = self.currentAlpha * math.min(frame, dt) * self.rotSpeed * frame
                self.currentRot = (self.currentRot + rot) % 6.283185307179586
                dt = dt - 16.66667
                if self.currentAlpha == 1 then
                    break
                end
            end
        else
            self.currentRot = (self.currentRot + self.currentAlpha * dt * self.rotSpeed * frame) % 6.283185307179586
        end
    elseif self.state == RotationAnimation.STATE_TURNING_OFF then
        while dt > 0 do
            local scaleZ = self.currentAlpha - math.min(frame, dt) / self.turnOffFadeTime
            self.currentAlpha = math.max(0, scaleZ)
            local rot = self.currentAlpha * math.min(frame, dt) * self.rotSpeed * frame
            self.currentRot = (self.currentRot + rot) % 6.283185307179586
            dt = dt - 16.66667
            if self.currentAlpha == 0 then
                break
            end
        end
    end
    if self.currentRot ~= prevRot then
        if self.shaderParameterName == nil then
            for node, speedScale in pairs(self.nodes) do
                local rx, ry, rz = getRotation(node)
                if self.rotAxis == 2 then
                    setRotation(node, rx, self.currentRot * speedScale, rz)
                elseif self.rotAxis == 1 then
                    setRotation(node, self.currentRot * speedScale, ry, rz)
                else
                    setRotation(node, rx, ry, self.currentRot * speedScale)
                end
            end
        else
            local rot = self.shaderComponentScale[1]
            local scaleY = self.shaderComponentScale[2]
            local scaleZ = self.shaderComponentScale[3]
            local node = self.shaderComponentScale[4]
            for node, speedScale in pairs(self.nodes) do
                if self.shaderParameterPrevName == nil then
                    setShaderParameter(node, self.shaderParameterName, self.currentRot * rot * (prevRot * rot), self.currentRot * scaleY * (prevRot * rot), self.currentRot * scaleZ * (prevRot * rot), self.currentRot * node * (prevRot * rot), false)
                else
                    setShaderParameter(node, self.shaderParameterPrevName, speedScale * speedScale, prevRot * scaleY * speedScale, prevRot * scaleZ * speedScale, prevRot * node * speedScale, false)
                    setShaderParameter(node, self.shaderParameterName, x * speedScale, y * speedScale, z * speedScale, w * speedScale, false)
                end
            end
        end
        if self.owner ~= nil and self.owner.setMovingToolDirty ~= nil then
            for node, speedScale in pairs(self.nodes) do
                self.owner:setMovingToolDirty(node, true)
            end
        end
    end
    if self.currentAlpha == 0 then
        self.state = RotationAnimation.STATE_OFF
    end
    if self.delayedTurnOff and self.currentAlpha >= self.minAlphaForTurnOff then
        self.delayedTurnOff = false
        self:stop()
    end
    self:updateDuplicates()
end
function RotationAnimation:isRunning()
    return self.state ~= RotationAnimation.STATE_OFF
end
function RotationAnimation:start()
    if self.state == RotationAnimation.STATE_ON then
        return false
    end
    if self.state == RotationAnimation.STATE_OFF and (self.turnOnOffVariance ~= nil and self.currentAlpha == 0) then
        self.turnOnFadeTime = self.initialTurnOnFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
        self.turnOffFadeTime = self.initialTurnOffFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
    end
    self.state = RotationAnimation.STATE_ON
    self:updateDuplicates()
    return true
end
function RotationAnimation:stop()
    if self.state == RotationAnimation.STATE_OFF then
        return false
    end
    if self.minAlphaForTurnOff > 0 and self.currentAlpha < self.minAlphaForTurnOff then
        self.delayedTurnOff = true
        self.state = RotationAnimation.STATE_ON
        return true
    end
    self.state = RotationAnimation.STATE_TURNING_OFF
    self:updateDuplicates()
    if self.turnedOffRotation ~= nil then
        local ry, ry, rz = getRotation(self.rootNode)
        if self.rotAxis ~= 1 then
            local _ = self.rotAxis == 2
        end
        local speedFactor = self.speedFunc == nil and 1 or self.speedFunc(self.speedFuncTarget, self.speedFuncParam)
        self.turnOffFadeTime = Animation.calculateTurnOffFadeTime(self.currentAlpha, self.rotSpeed * speedFactor, math.sign(self.rotSpeed), ry, self.turnedOffRotation, self.turnOffFadeTimeOrigin, 6.283185307179586, self.turnedOffSubDivisions)
    end
    return true
end
function RotationAnimation:reset()
    self.currentAlpha = 0
    self.state = RotationAnimation.STATE_OFF
    self:updateDuplicates()
end
function RotationAnimation:isDuplicate(otherAnimation)
    if not otherAnimation:isa(RotationAnimation) or (self.parent ~= otherAnimation.parent or table.size(self.nodes) ~= table.size(otherAnimation.nodes)) then
        return false
    end
    for node, _ in pairs(self.nodes) do
        if otherAnimation.nodes[node] == nil then
            return false
        end
    end
    return true
end
function RotationAnimation:updateDuplicate(otherAnimation)
    otherAnimation.currentAlpha = self.currentAlpha
    otherAnimation.currentRot = self.currentRot
    otherAnimation.state = self.state
end
function RotationAnimation.registerAnimationClassXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".node(?)#node", "Node")
    schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#speedScale", "Speed scale", 1)
    schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#rotSpeed", "Rotation speed", "Default rotation speed")
    schema:register(XMLValueType.STRING, basePath .. "#shaderParameterName", "Shader parameter name")
    schema:register(XMLValueType.VECTOR_4, basePath .. "#shaderComponentScale", "Shader parameter name", "1 0 0 0")
    schema:register(XMLValueType.ANGLE, basePath .. "#rotSpeed", "Rotation speed", 1)
    schema:register(XMLValueType.ANGLE, basePath .. "#turnedOffRotation", "(RotationAnimation) Target rotation while turned off")
    schema:register(XMLValueType.FLOAT, basePath .. "#minAlphaForTurnOff", "Min. alpha for turn off (speed [0-1])", 0)
    schema:register(XMLValueType.FLOAT, basePath .. "#turnedOffSubDivisions", "Amount of sub divisions which have the same state", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#rotAxis", "Rotation axis", 2)
    schema:register(XMLValueType.FLOAT, basePath .. "#turnOnFadeTime", "Turn on fade time", 2)
    schema:register(XMLValueType.FLOAT, basePath .. "#turnOffFadeTime", "Turn off fade time", 2)
    schema:register(XMLValueType.FLOAT, basePath .. "#turnOnOffVariance", "Turn off time variance")
    schema:register(XMLValueType.STRING, basePath .. "#speedFunc", "Lua speed function")
    schema:register(XMLValueType.STRING, basePath .. "#speedFuncParam", "Additional string parameter that is passed to the speedFunc")
end