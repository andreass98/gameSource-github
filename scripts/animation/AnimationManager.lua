AnimationManager = {}
local AnimationManager_mt = Class(AnimationManager, AbstractManager)
function AnimationManager.new(customMt)
    -- upvalues: (copy) AnimationManager_mt
    return AbstractManager.new(customMt or AnimationManager_mt)
end
function AnimationManager:initDataStructures()
    self.runningAnimations = {}
    self.registeredAnimations = {}
    self.registeredAnimationClasses = {}
    self.prevShaderParametersToSet = {}
end
function AnimationManager:registerAnimationClass(className, animationClass)
    if ClassUtil.getIsValidClassName(className) then
        self.registeredAnimationClasses[className] = animationClass
    else
        printError("Error: Invalid animation class name: " .. className)
    end
end
function AnimationManager:getAnimationClass(className)
    return self.registeredAnimationClasses[className]
end
function AnimationManager:loadAnimations(xmlFile, baseName, rootNode, parent, i3dMapping, maxUpdateDistance)
    local animations = {}
    local i = 0
    while true do
        local key = string.format(baseName .. ".animationNode(%d)", i)
        if not xmlFile:hasProperty(key) then
            break
        end
        local animationClassName = xmlFile:getValue(key .. "#class") or "RotationAnimation"
        local animationClass = self:getAnimationClass(animationClassName)
        if animationClass == nil then
            if parent.customEnvironment ~= nil and parent.customEnvironment ~= "" then
                animationClass = self:getAnimationClass(parent.customEnvironment .. "." .. animationClassName)
            end
            if animationClass == nil then
                animationClass = ClassUtil.getClassObject(animationClassName)
            end
        end
        if animationClass == nil then
            printWarning("Warning: Unknown animation \'" .. animationClassName .. "\' in \'" .. Utils.getNoNil(parent.configFileName, parent.xmlFilename) .. "\'")
        else
            local animation = animationClass.new()
            if animation ~= nil then
                local anim = animation:load(xmlFile, key, rootNode, parent, i3dMapping)
                if anim ~= nil then
                    local j = 1
                    for j = j, #self.registeredAnimations do
                        local otherAnim = self.registeredAnimations[j]
                        if anim:isDuplicate(otherAnim) then
                            anim:addDuplicate(otherAnim)
                            otherAnim:addDuplicate(anim)
                        end
                    end
                    anim:setUpdateDistance(maxUpdateDistance or Animation.DEFAULT_UPDATE_DISTANCE)
                    table.insert(animations, anim)
                    table.insert(self.registeredAnimations, anim)
                end
            end
        end
        i = i + 1
    end
    return animations
end
function AnimationManager:deleteAnimations(animations)
    if animations ~= nil then
        local i = #animations
        for i = i, 1, -1 do
            local animation = animations[i]
            self.runningAnimations[animation] = nil
            animation:delete()
            table.remove(animations, i)
            table.removeElement(self.registeredAnimations, animation)
        end
    end
end
function AnimationManager:update(dt)
    for index, animation in pairs(self.runningAnimations) do
        if animation.maxUpdateDistance == nil then
            animation:update(dt)
        else
            local allowUpdate = animation:getAllowUpdate()
            if allowUpdate then
                local effectDt
                if animation.allowUpdate then
                    effectDt = dt
                else
                    effectDt = g_currentMission.time - animation.lastUpdateTime
                end
                animation:update(effectDt)
                animation.lastUpdateTime = g_currentMission.time
            end
            animation.allowUpdate = allowUpdate
        end
        if not animation:isRunning() then
            self.runningAnimations[index] = nil
        end
    end
    local i = 1
    for i = i, #self.prevShaderParametersToSet do
        local index = self.prevShaderParametersToSet[i]
        if index.isValid and index.loopIndex < g_updateLoopIndex then
            if entityExists(index.node) then
                setShaderParameter(index.node, index.parameterNamePrev, index.x, index.y, index.z, index.w, index.shared)
            end
            index.isValid = false
        end
    end
end
function AnimationManager.areAnimationsRunning(_, animations)
    if animations ~= nil then
        for _, animation in ipairs(animations) do
            if animation:isRunning() then
                return true
            end
        end
    end
    return false
end
function AnimationManager:startAnimations(animations)
    if animations ~= nil then
        for _, animation in ipairs(animations) do
            self:startAnimation(animation)
        end
    end
end
function AnimationManager:startAnimation(animation)
    if animation ~= nil and animation:start() then
        self.runningAnimations[animation] = animation
    end
end
function AnimationManager:stopAnimations(animations)
    if animations ~= nil then
        for _, animation in ipairs(animations) do
            self:stopAnimation(animation)
        end
    end
end
function AnimationManager:stopAnimation(animation)
    if animation.stop == nil then
        printCallstack()
    end
    if animation ~= nil and animation:stop() then
        self.runningAnimations[animation] = animation
    end
end
function AnimationManager:resetAnimations(animations)
    if animations ~= nil then
        for _, animation in ipairs(animations) do
            self:resetAnimation(animation)
        end
    end
end
function AnimationManager:resetAnimation(animation)
    if animation ~= nil then
        self.runningAnimations[animation] = nil
        animation:reset()
    end
end
function AnimationManager.setFillType(_, animations, fillType)
    if animations ~= nil then
        for _, animation in ipairs(animations) do
            if animation.setFillType ~= nil then
                animation:setFillType(fillType)
            end
        end
    end
end
function AnimationManager:setPrevShaderParameter(node, parameterName, x, y, z, w, shared, parameterNamePrev)
    setShaderParameter(node, parameterName, x, y, z, w, shared)
    if x == nil or (y == nil or (z == nil or w == nil)) then
        x, y, z, w = getShaderParameter(node, parameterName)
    end
    local slot = nil
    local i = 1
    for i = i, #self.prevShaderParametersToSet do
        local prevShaderParameterData = self.prevShaderParametersToSet[i]
        if prevShaderParameterData.isValid then
            if prevShaderParameterData.loopIndex == g_updateLoopIndex and (prevShaderParameterData.node == node and prevShaderParameterData.parameterNamePrev == parameterNamePrev) then
                prevShaderParameterData.x = x
                prevShaderParameterData.y = y
                prevShaderParameterData.z = z
                prevShaderParameterData.w = w
                return
            end
        else
            slot = prevShaderParameterData
        end
    end
    if slot == nil then
        table.insert(self.prevShaderParametersToSet, {})
    end
    slot.node = node
    slot.parameterNamePrev = parameterNamePrev
    slot.x = x
    slot.y = y
    slot.z = z
    slot.w = w
    slot.shared = shared
    slot.isValid = true
    slot.loopIndex = g_updateLoopIndex
end
function AnimationManager.registerAnimationNodesXMLPaths(schema, basePath)
    schema:setXMLSharedRegistration("AnimationNode", basePath)
    schema:register(XMLValueType.STRING, basePath .. ".animationNode(?)#class", "Animation class (RotationAnimation | RotationAnimationSpikes | RotationAnimationSpikesGravity | ScrollingAnimation | ShakeAnimation)", "RotationAnimation")
    RotationAnimation.registerAnimationClassXMLPaths(schema, basePath .. ".animationNode(?)")
    RotationAnimationSpikes.registerAnimationClassXMLPaths(schema, basePath .. ".animationNode(?)")
    RotationAnimationSpikesGravity.registerAnimationClassXMLPaths(schema, basePath .. ".animationNode(?)")
    ScrollingAnimation.registerAnimationClassXMLPaths(schema, basePath .. ".animationNode(?)")
    ShakeAnimation.registerAnimationClassXMLPaths(schema, basePath .. ".animationNode(?)")
    schema:resetXMLSharedRegistration("AnimationNode", basePath)
end
g_animationManager = AnimationManager.new()