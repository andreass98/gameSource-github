EffectManager = {}
local EffectManager_mt = Class(EffectManager, AbstractManager)
function EffectManager.new(customMt)
    -- upvalues: (copy) EffectManager_mt
    return AbstractManager.new(customMt or EffectManager_mt)
end
function EffectManager:initDataStructures()
    self.runningEffects = {}
    self.registeredEffectClasses = {}
    self.delayedCommands = {}
    self.validCommands = 0
end
function EffectManager:loadEffect(xmlFile, baseName, rootNode, parent, i3dMapping, maxUpdateDistance)
    local effects = {}
    for i, key in xmlFile:iterator(baseName .. ".effectNode") do
        local effectClassName = xmlFile:getValue(key .. "#effectClass", "ShaderPlaneEffect")
        local effectClass = self:getEffectClass(effectClassName)
        if effectClass == nil then
            if parent.customEnvironment ~= nil and parent.customEnvironment ~= "" then
                effectClass = self:getEffectClass(parent.customEnvironment .. "." .. effectClassName)
            end
            if effectClass == nil then
                effectClass = ClassUtil.getClassObject(effectClassName)
            end
        end
        if effectClass == nil then
            Logging.xmlWarning(xmlFile, "Unknown effect class \'%s\'", effectClassName)
        else
            local effect = effectClass.new()
            if effect ~= nil then
                table.insert(effects, effect:load(xmlFile, key, rootNode, parent, i3dMapping))
            end
        end
    end
    self:setUpdateDistance(effects, maxUpdateDistance or Effect.DEFAULT_UPDATE_DISTANCE)
    return effects
end
function EffectManager:loadFromNode(node, parent, maxUpdateDistance)
    local effects = {}
    local i = 0
    for i = i, getNumOfChildren(node) - 1 do
        local child = getChildAt(node, i)
        local effectClassName = Utils.getNoNil(getUserAttribute(child, "effectClass"), "ShaderPlaneEffect")
        local effectClass = self:getEffectClass(effectClassName)
        if effectClass == nil then
            if parent.customEnvironment ~= nil and parent.customEnvironment ~= "" then
                effectClass = self:getEffectClass(parent.customEnvironment .. "." .. effectClassName)
            end
            if effectClass == nil then
                effectClass = ClassUtil.getClassObject(effectClassName)
            end
        end
        if effectClass == nil then
            printWarning("Warning: Unknown effect \'" .. effectClassName .. "\' in \'" .. getName(node) .. "\'")
        else
            local effect = effectClass.new()
            if effect ~= nil then
                table.insert(effects, effect:loadFromNode(child, parent))
            end
        end
    end
    self:setUpdateDistance(effects, maxUpdateDistance or Effect.DEFAULT_UPDATE_DISTANCE)
    return effects
end
function EffectManager:registerEffectClass(className, effectClass)
    if ClassUtil.getIsValidClassName(className) then
        self.registeredEffectClasses[className] = effectClass
    else
        printError("Error: Invalid effect class name: " .. className)
    end
end
function EffectManager:getEffectClass(className)
    return self.registeredEffectClasses[className]
end
function EffectManager:deleteEffects(effects)
    if effects ~= nil then
        for _, effect in pairs(effects) do
            self.runningEffects[effect] = nil
            effect:delete()
            local i = 1
            for i = i, #self.delayedCommands do
                local commandSlot = self.delayedCommands[i]
                if commandSlot.isValid and commandSlot.arg1 == effect then
                    commandSlot.isValid = false
                end
            end
        end
    end
end
function EffectManager:update(dt)
    for index, effect in pairs(self.runningEffects) do
        if effect.maxUpdateDistance == nil then
            effect:update(dt)
        else
            local allowUpdate = effect:getAllowUpdate()
            if allowUpdate then
                local effectDt
                if effect.allowUpdate then
                    effectDt = dt
                else
                    effectDt = g_currentMission.time - effect.lastUpdateTime
                end
                effect:update(effectDt)
                effect.lastUpdateTime = g_currentMission.time
            end
            effect.allowUpdate = allowUpdate
        end
        if not effect:isRunning() then
            self.runningEffects[index] = nil
        end
    end
    if self.validCommands > 0 then
        local i = 1
        for i = i, #self.delayedCommands do
            local index = self.delayedCommands[i]
            if index.isValid then
                index.delay = index.delay - dt
                if index.delay <= 0 then
                    index.func(self, index.arg1, index.arg2)
                    index.isValid = false
                    self.validCommands = self.validCommands - 1
                end
            end
        end
    end
end
function EffectManager:addDelayedCommand(func, arg1, arg2, delay)
    local slotToUse = nil
    local i = 1
    for i = i, #self.delayedCommands do
        local commandSlot = self.delayedCommands[i]
        if not commandSlot.isValid then
            slotToUse = commandSlot
        end
    end
    if slotToUse == nil then
        table.insert(self.delayedCommands, {
            ["func"] = func,
            ["arg1"] = arg1,
            ["arg2"] = arg2,
            ["delay"] = delay,
            ["isValid"] = true
        })
    else
        slotToUse.func = func
        slotToUse.arg1 = arg1
        slotToUse.arg2 = arg2
        slotToUse.delay = delay
        slotToUse.isValid = true
    end
    self.validCommands = self.validCommands + 1
end
function EffectManager:startEffects(effects)
    if effects == nil then
        Logging.warning("Given effects were nil!")
        printCallstack()
    else
        for _, effect in pairs(effects) do
            self:startEffect(effect)
        end
    end
end
function EffectManager:startEffect(effect, skipDelay)
    if effect == nil then
        Logging.warning("Given effect was nil!")
        printCallstack()
        return
    else
        local success, delay = effect:start(skipDelay)
        if success then
            self.runningEffects[effect] = effect
        elseif delay ~= nil then
            self:addDelayedCommand(self.startEffect, effect, true, delay)
        end
    end
end
function EffectManager:stopEffects(effects)
    if effects == nil then
        Logging.warning("Given effects were nil!")
        printCallstack()
    else
        for _, effect in pairs(effects) do
            self:stopEffect(effect)
        end
    end
end
function EffectManager:stopEffect(effect, skipDelay)
    if effect == nil then
        Logging.warning("Given effect was nil!")
        printCallstack()
        return
    else
        local success, delay = effect:stop(skipDelay)
        if success then
            self.runningEffects[effect] = effect
        elseif delay ~= nil then
            self:addDelayedCommand(self.stopEffect, effect, true, delay)
        end
    end
end
function EffectManager:resetEffects(effects)
    if effects == nil then
        Logging.warning("Given effects were nil!")
        printCallstack()
    else
        for _, effect in pairs(effects) do
            self:resetEffect(effect)
        end
    end
end
function EffectManager:resetEffect(effect)
    if effect == nil then
        Logging.warning("Given effect was nil!")
        printCallstack()
    else
        self.runningEffects[effect] = nil
        effect:reset()
    end
end
function EffectManager.setEffectTypeInfo(_, effects, fillTypeIndex, fruitTypeIndex, growthState)
    if effects == nil then
        Logging.warning("Given effects were nil!")
        printCallstack()
    else
        for _, effect in pairs(effects) do
            if effect.setEffectTypeInfo ~= nil then
                effect:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState)
            end
        end
    end
end
function EffectManager:setFillType(effects, fillType, growthState)
    Logging.error("EffectManager:setFillType is deprecated, use setEffectTypeInfo instead")
    printCallstack()
end
function EffectManager:setFruitType(effects, fruitType, growthState)
    Logging.error("EffectManager:setFruitType is deprecated, use setEffectTypeInfo instead")
    printCallstack()
end
function EffectManager.setMinMaxWidth(_, effects, minWidth, maxWidth, minWidthNorm, maxWidthNorm, reset)
    if effects == nil then
        Logging.warning("Given effects were nil!")
        printCallstack()
    else
        for _, effect in pairs(effects) do
            if effect.setMinMaxWidth ~= nil then
                effect:setMinMaxWidth(minWidth, maxWidth, minWidthNorm, maxWidthNorm, reset)
            end
        end
    end
end
function EffectManager.setDensity(_, effects, density)
    if effects == nil then
        Logging.warning("Given effects were nil!")
        printCallstack()
    else
        for _, effect in pairs(effects) do
            if effect.setDensity ~= nil then
                effect:setDensity(density)
            end
        end
    end
end
function EffectManager.setUpdateDistance(_, effects, maxUpdateDistance)
    if effects == nil then
        Logging.warning("Given effects were nil!")
        printCallstack()
    else
        for _, effect in pairs(effects) do
            effect:setUpdateDistance(maxUpdateDistance)
        end
    end
end
function EffectManager.registerEffectXMLPaths(schema, basePath)
    schema:setXMLSharedRegistration("EffectNode", basePath)
    schema:register(XMLValueType.STRING, basePath .. ".effectNode(?)#effectClass", "Effect class", "ShaderPlaneEffect")
    Effect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    ExhaustEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    LevelerEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    MorphPositionEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    ParticleEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    PipeEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    ShaderPlaneEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    SlurrySideToSideEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    WindrowerEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    TipEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    GrainTankEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    CutterMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    CultivatorMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    PlowMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    WindrowerMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    FertilizerMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    SnowPlowMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    MotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    VariableMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    CombinedEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
    schema:resetXMLSharedRegistration("EffectNode", basePath)
end
g_effectManager = EffectManager.new()