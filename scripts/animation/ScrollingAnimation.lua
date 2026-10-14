ScrollingAnimation = {}
ScrollingAnimation.STATE_OFF = 0
ScrollingAnimation.STATE_ON = 1
ScrollingAnimation.STATE_TURNING_OFF = 2
local ScrollingAnimation_mt = Class(ScrollingAnimation, Animation)
function ScrollingAnimation.new(customMt)
    -- upvalues: (copy) ScrollingAnimation_mt
    local self = Animation.new(customMt or ScrollingAnimation_mt)
    self.state = ScrollingAnimation.STATE_OFF
    self.nodes = {}
    self.shaderParameterName = nil
    self.scrollPosition = 0
    self.scrollSpeed = 0
    self.scrollLength = 1
    self.shaderParameterComponent = 1
    self.currentAlpha = 0
    self.currentScroll = 0
    self.initialTurnOnFadeTime = 1000
    self.turnOnOffVariance = nil
    self.turnOnFadeTime = 0
    self.turnOffFadeTime = 0
    self.owner = nil
    return self
end
function ScrollingAnimation:load(xmlFile, key, rootNodes, owner, i3dMapping)
    if not xmlFile:hasProperty(key) then
        return nil
    end
    self.owner = owner
    self.scrollSpeed = xmlFile:getValue(key .. "#scrollSpeed", 1) * 0.001
    local node = xmlFile:getValue(key .. "#node", nil, rootNodes, i3dMapping)
    if node ~= nil then
        self.nodes[node] = 1
    end
    for _, nodeKey in xmlFile:iterator(key .. ".node") do
        local speedScale = xmlFile:getValue(nodeKey .. "#node", nil, rootNodes, i3dMapping)
        if speedScale ~= nil then
            local speedScale = xmlFile:getValue(nodeKey .. "#speedScale", 1)
            local scrollSpeed = xmlFile:getValue(nodeKey .. "#scrollSpeed")
            if scrollSpeed ~= nil then
            end
            self.nodes[speedScale] = speedScale
        end
    end
    if table.size(self.nodes) == 0 then
        Logging.xmlWarning(xmlFile, "Missing node(s) for rotation animation \'%s\'!", key)
        return nil
    end
    self.rootNode = next(self.nodes)
    self.shaderParameterName = xmlFile:getValue(key .. "#shaderParameterName", "offsetUV")
    self.shaderParameterPrevName = xmlFile:getValue(key .. "#shaderParameterPrevName")
    for _, nodeKey in pairs(self.nodes) do
        if not getHasShaderParameter(_, self.shaderParameterName) then
            Logging.xmlWarning(xmlFile, "Node \'%s\' has no shader parameter \'%s\' for animationNode \'%s\'!", getName(_), self.shaderParameterName, key)
            return nil
        end
    end
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
    local prevName = xmlFile:getValue(key .. "#type")
    if prevName ~= nil then
        self.fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(prevName)
    end
    self.scrollLength = xmlFile:getValue(key .. "#scrollLength", 1)
    self.shaderParameterComponent = xmlFile:getValue(key .. "#shaderParameterComponent", 1)
    self.turnOnFadeTime = math.max(xmlFile:getValue(key .. "#turnOnFadeTime", 2) * 1000, 1)
    self.turnOffFadeTime = math.max(xmlFile:getValue(key .. "#turnOffFadeTime", 2) * 1000, 1)
    self.turnOnOffVariance = xmlFile:getValue(key .. "#turnOnOffVariance")
    if self.turnOnOffVariance ~= nil then
        self.initialTurnOnFadeTime = self.turnOnFadeTime
        self.initialTurnOffFadeTime = self.turnOffFadeTime
        self.turnOnOffVariance = self.turnOnOffVariance * 1000
    end
    local speedFuncStr = xmlFile:getValue(key .. "#speedFunc")
    if speedFuncStr ~= nil then
        if owner[speedFuncStr] == nil then
            Logging.xmlWarning(xmlFile, "Could not find speed function \'%s\' for scrolling animation \'%s\'!", speedFuncStr, key)
        else
            self.speedFunc = owner[speedFuncStr]
            self.speedFuncTarget = self.owner
            self.speedFuncParam = xmlFile:getValue(key .. "#speedFuncParam")
        end
    end
    self.minAlphaForTurnOff = xmlFile:getValue(key .. "#minAlphaForTurnOff", 0)
    self.delayedTurnOff = false
    self.turnedOffPosition = xmlFile:getValue(key .. "#turnedOffPosition")
    if self.turnedOffPosition ~= nil then
        self.turnOffFadeTimeOrigin = self.turnOffFadeTime
        self.turnedOffSubDivisions = xmlFile:getValue(key .. "#turnedOffSubDivisions", 1)
    end
    return self
end
function ScrollingAnimation:update(dt)
    ScrollingAnimation:superClass().update(self, dt)
    local prevScroll = self.currentScroll
    local frame = self.speedFunc == nil and 1 or self.speedFunc(self.speedFuncTarget, self.speedFuncParam)
    if self.state == ScrollingAnimation.STATE_ON then
        if self.currentAlpha < 1 then
            while dt > 0 do
                local z = self.currentAlpha + math.min(16.66667, dt) / self.turnOnFadeTime
                self.currentAlpha = math.min(1, z)
                local scroll = self.currentAlpha * math.min(frame, dt) * self.scrollSpeed * frame
                self.currentScroll = (self.currentScroll + scroll) % self.scrollLength
                dt = dt - 16.66667
                if self.currentAlpha == 1 then
                    break
                end
            end
        else
            self.currentScroll = (self.currentScroll + self.currentAlpha * dt * self.scrollSpeed * frame) % self.scrollLength
        end
    elseif self.state == ScrollingAnimation.STATE_TURNING_OFF then
        while dt > 0 do
            local z = self.currentAlpha - math.min(frame, dt) / self.turnOffFadeTime
            self.currentAlpha = math.max(0, z)
            local scroll = self.currentAlpha * math.min(frame, dt) * self.scrollSpeed * frame
            self.currentScroll = (self.currentScroll + scroll) % self.scrollLength
            dt = dt - 16.66667
            if self.currentAlpha == 0 then
                break
            end
        end
    end
    if self.currentScroll ~= prevScroll then
        local scroll = nil
        local y = nil
        local z = nil
        local w = nil
        local prev_x = nil
        local prev_y = nil
        local prev_z = nil
        if self.shaderParameterComponent == 1 then
            scroll = self.currentScroll
            prev_x = prevScroll
        elseif self.shaderParameterComponent == 2 then
            y = self.currentScroll
            prev_y = prevScroll
        elseif self.shaderParameterComponent == 3 then
            z = self.currentScroll
            prev_z = prevScroll
        else
            w = self.currentScroll
        end
        for node, _ in pairs(self.nodes) do
            if self.shaderParameterPrevName == nil then
                setShaderParameter(node, self.shaderParameterName, scroll, y, z, w, false)
            else
                setShaderParameter(node, self.shaderParameterPrevName, prev_x, prev_y, prev_z, prevScroll, false)
                setShaderParameter(node, self.shaderParameterName, scroll, y, z, w, false)
            end
            if self.owner ~= nil and self.owner.setMovingToolDirty ~= nil then
                self.owner:setMovingToolDirty(node)
            end
        end
    end
    if self.currentAlpha == 0 then
        self.state = ScrollingAnimation.STATE_OFF
    end
    if self.delayedTurnOff and self.currentAlpha >= self.minAlphaForTurnOff then
        self.delayedTurnOff = false
        self:stop()
    end
    self:updateDuplicates()
end
function ScrollingAnimation:isRunning()
    return self.state ~= ScrollingAnimation.STATE_OFF
end
function ScrollingAnimation:start()
    if self.state == ScrollingAnimation.STATE_ON then
        return false
    end
    if self.state == ScrollingAnimation.STATE_OFF and (self.turnOnOffVariance ~= nil and self.currentAlpha == 0) then
        self.turnOnFadeTime = self.initialTurnOnFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
        self.turnOffFadeTime = self.initialTurnOffFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
    end
    self.state = ScrollingAnimation.STATE_ON
    self:updateDuplicates()
    return true
end
function ScrollingAnimation:stop()
    if self.state == ScrollingAnimation.STATE_OFF then
        return false
    end
    if self.minAlphaForTurnOff > 0 and self.currentAlpha < self.minAlphaForTurnOff then
        self.delayedTurnOff = true
        self.state = ScrollingAnimation.STATE_ON
        return true
    end
    self.state = ScrollingAnimation.STATE_TURNING_OFF
    self:updateDuplicates()
    if self.turnedOffPosition ~= nil then
        local speedFactor = self.speedFunc == nil and 1 or self.speedFunc(self.speedFuncTarget, self.speedFuncParam)
        self.turnOffFadeTime = Animation.calculateTurnOffFadeTime(self.currentAlpha, self.scrollSpeed * speedFactor, math.sign(self.scrollSpeed), self.currentScroll, self.turnedOffPosition, self.turnOffFadeTimeOrigin, self.scrollLength, self.turnedOffSubDivisions)
    end
    return true
end
function ScrollingAnimation:reset()
    self.currentAlpha = 0
    self.state = ScrollingAnimation.STATE_OFF
    self:updateDuplicates()
end
function ScrollingAnimation:setFillType(fillTypeIndex)
    if self.fillTypeIndex ~= nil then
        for node, _ in pairs(self.nodes) do
            setVisibility(node, self.fillTypeIndex == fillTypeIndex)
        end
    end
end
function ScrollingAnimation:isDuplicate(otherAnimation)
    if not otherAnimation:isa(ScrollingAnimation) or (self.parent ~= otherAnimation.parent or table.size(self.nodes) ~= table.size(otherAnimation.nodes)) then
        return false
    end
    for node, _ in pairs(self.nodes) do
        if otherAnimation.nodes[node] == nil then
            return false
        end
    end
    return true
end
function ScrollingAnimation:updateDuplicate(otherAnimation)
    otherAnimation.currentAlpha = self.currentAlpha
    otherAnimation.currentScroll = self.currentScroll
    otherAnimation.state = self.state
end
function ScrollingAnimation.registerAnimationClassXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".node(?)#node", "Node")
    schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#speedScale", "Speed scale", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#scrollSpeed", "(ScrollingAnimation) Scroll speed", "Default scroll speed")
    schema:register(XMLValueType.STRING, basePath .. "#shaderParameterName", "Shader parameter name")
    schema:register(XMLValueType.STRING, basePath .. "#shaderParameterPrevName", "Prev Shader parameter name", "automatically calculated from #shaderParameterName")
    schema:register(XMLValueType.STRING, basePath .. "#type", "(ScrollingAnimation) Fill type name")
    schema:register(XMLValueType.FLOAT, basePath .. "#scrollSpeed", "(ScrollingAnimation) Scroll speed", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#scrollLength", "(ScrollingAnimation) Scroll length", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#shaderParameterComponent", "(ScrollingAnimation) Shader parameter component", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#turnOnFadeTime", "Turn on fade time", 2)
    schema:register(XMLValueType.FLOAT, basePath .. "#turnOffFadeTime", "Turn off fade time", 2)
    schema:register(XMLValueType.FLOAT, basePath .. "#turnOnOffVariance", "Turn off time variance")
    schema:register(XMLValueType.FLOAT, basePath .. "#turnedOffPosition", "(ScrollingAnimation) Target position while turned off")
    schema:register(XMLValueType.FLOAT, basePath .. "#turnedOffSubDivisions", "Amount of sub divisions which have the same state", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#minAlphaForTurnOff", "Min. alpha for turn off (speed [0-1])", 0)
    schema:register(XMLValueType.STRING, basePath .. "#speedFunc", "Lua speed function")
    schema:register(XMLValueType.STRING, basePath .. "#speedFuncParam", "Additional string parameter that is passed to the speedFunc")
end