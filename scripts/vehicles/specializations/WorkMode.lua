source("dataS/scripts/vehicles/specializations/events/SetWorkModeEvent.lua")
WorkMode = {}
source("dataS/scripts/gui/hud/extensions/WorkModeHUDExtension.lua")
WorkMode.WORKMODE_SEND_NUM_BITS = 4
function WorkMode.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end
function WorkMode.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("workMode", g_i18n:getText("configuration_workMode"), "workModes", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("WorkMode")
    WorkMode.registerWorkModeXMLPaths(schema, "vehicle.workModes")
    WorkMode.registerWorkModeXMLPaths(schema, "vehicle.workModes.workModeConfigurations.workModeConfiguration(?)")
    schema:setXMLSpecializationType()
    Vehicle.xmlSchemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).workMode#state", "Current work mode", 1)
end
function WorkMode.registerWorkModeXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#foldMaxLimit", "Fold max. limit to change mode", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#foldMinLimit", "Fold min. limit to change mode", 0)
    schema:register(XMLValueType.BOOL, basePath .. "#allowChangeOnLowered", "Allow change while lowered", true)
    schema:register(XMLValueType.BOOL, basePath .. "#allowChangeWhileTurnedOn", "Allow change while turned on", true)
    schema:addDelayedRegistrationPath(basePath .. ".workMode(?)", "WorkMode:workMode")
    schema:register(XMLValueType.L10N_STRING, basePath .. ".workMode(?)#name", "Work mode name")
    schema:register(XMLValueType.STRING, basePath .. ".workMode(?)#inputBindingName", "Input action name for quick access")
    schema:register(XMLValueType.BOOL, basePath .. ".workMode(?)#isDefault", "Work mode is active by default", false)
    schema:register(XMLValueType.STRING, basePath .. ".workMode(?).turnedOnAnimations.turnedOnAnimation(?)#name", "Turned on animation name")
    schema:register(XMLValueType.FLOAT, basePath .. ".workMode(?).turnedOnAnimations.turnedOnAnimation(?)#turnOnFadeTime", "Turn on fade time (sec.)", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".workMode(?).turnedOnAnimations.turnedOnAnimation(?)#turnOffFadeTime", "Turn off fade time (sec.)", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".workMode(?).turnedOnAnimations.turnedOnAnimation(?)#speedScale", "Speed scale", 1)
    schema:register(XMLValueType.STRING, basePath .. ".workMode(?).loweringAnimations.loweringAnimation(?)#name", "Lowering animation name")
    schema:register(XMLValueType.FLOAT, basePath .. ".workMode(?).loweringAnimations.loweringAnimation(?)#speed", "Speed scale", 1)
    schema:register(XMLValueType.INT, basePath .. ".workMode(?).workAreas.workArea(?)#workAreaIndex", "Work area index")
    schema:register(XMLValueType.INT, basePath .. ".workMode(?).workAreas.workArea(?)#dropAreaIndex", "Drop area index")
    schema:register(XMLValueType.STRING, basePath .. ".workMode(?).animation(?)#name", "Mode change animation name")
    schema:register(XMLValueType.FLOAT, basePath .. ".workMode(?).animation(?)#speed", "Mode change animation speed", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".workMode(?).animation(?)#stopTime", "Mode change animation stop time")
    schema:register(XMLValueType.BOOL, basePath .. ".workMode(?).animation(?)#repeatAfterUnfolding", "Repeat animation after unfolding", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".workMode(?).animation(?)#repeatStartTime", "Repeat start time")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".workMode(?).movingToolLimit#node", "Target moving tool node")
    schema:register(XMLValueType.ANGLE, basePath .. ".workMode(?).movingToolLimit#minRot", "Min. rotation", 0)
    schema:register(XMLValueType.ANGLE, basePath .. ".workMode(?).movingToolLimit#maxRot", "Max. rotation", 0)
    schema:register(XMLValueType.INT, basePath .. ".workMode(?).variableWorkWidth#leftState", "Forced index on left side")
    schema:register(XMLValueType.INT, basePath .. ".workMode(?).variableWorkWidth#rightState", "Forced index on right side")
    EffectManager.registerEffectXMLPaths(schema, basePath .. ".workMode(?).windrowerEffect")
    AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".workMode(?).animationNodes")
    AIImplement.registerAIImplementBaseXMLPaths(schema, basePath .. ".workMode(?).ai")
    schema:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. "#workModeIndex", "Index of work mode to activate spray type")
    schema:addDelayedRegistrationFunc("Cylindered:movingTool", function(cSchema, cKey)
        cSchema:register(XMLValueType.BOOL, cKey .. "#allowWhileChangingWorkMode", "Allow movement while changing work mode", true)
    end)
end
function WorkMode.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onWorkModeChanged")
end
function WorkMode.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadWorkModeFromXML", WorkMode.loadWorkModeFromXML)
    SpecializationUtil.registerFunction(vehicleType, "setWorkMode", WorkMode.setWorkMode)
    SpecializationUtil.registerFunction(vehicleType, "getWorkMode", WorkMode.getWorkMode)
    SpecializationUtil.registerFunction(vehicleType, "getIsWorkModeChangeAllowed", WorkMode.getIsWorkModeChangeAllowed)
    SpecializationUtil.registerFunction(vehicleType, "deactivateWindrowerEffects", WorkMode.deactivateWindrowerEffects)
end
function WorkMode.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", WorkMode.getIsWorkAreaActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", WorkMode.getCanBeSelected)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowsLowering", WorkMode.getAllowsLowering)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSprayTypeFromXML", WorkMode.loadSprayTypeFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSprayTypeActive", WorkMode.getIsSprayTypeActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingToolFromXML", WorkMode.loadMovingToolFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingToolActive", WorkMode.getIsMovingToolActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreEffectsVisible", WorkMode.getAreEffectsVisible)
end
function WorkMode.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", WorkMode)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", WorkMode)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", WorkMode)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", WorkMode)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", WorkMode)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", WorkMode)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", WorkMode)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", WorkMode)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WorkMode)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", WorkMode)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", WorkMode)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", WorkMode)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", WorkMode)
    SpecializationUtil.registerEventListener(vehicleType, "onSetLowered", WorkMode)
    SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", WorkMode)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", WorkMode)
end
function WorkMode:onLoad(_)
    local spec = self.spec_workMode
    local configKey = string.format("vehicle.workModes.workModeConfigurations.workModeConfiguration(%d)", (self.configurations.workMode or 1) - 1)
    local configKey = not self.xmlFile:hasProperty(configKey) and "vehicle.workModes" or configKey
    if self.xmlFile:hasProperty(configKey) then
        spec.state = 1
        spec.stateMax = 0
        spec.foldMaxLimit = self.xmlFile:getValue(configKey .. "#foldMaxLimit", 1)
        spec.foldMinLimit = self.xmlFile:getValue(configKey .. "#foldMinLimit", 0)
        spec.allowChangeOnLowered = self.xmlFile:getValue(configKey .. "#allowChangeOnLowered", true)
        spec.allowChangeWhileTurnedOn = self.xmlFile:getValue(configKey .. "#allowChangeWhileTurnedOn", true)
        spec.workModes = {}
        spec.defaultWorkModeIndex = 1
        for _, key in self.xmlFile:iterator(configKey .. ".workMode") do
            local entry = {}
            if self:loadWorkModeFromXML(self.xmlFile, key, entry) then
                table.insert(spec.workModes, entry)
                if entry.isDefault then
                    spec.defaultWorkModeIndex = #spec.workModes
                end
            end
        end
        spec.stateMax = #spec.workModes
        if spec.stateMax > 2 ^ WorkMode.WORKMODE_SEND_NUM_BITS - 1 then
            printError("Error: WorkMode only supports " .. 2 ^ WorkMode.WORKMODE_SEND_NUM_BITS - 1 .. " modes!")
        end
        if spec.stateMax > 0 then
            self:setWorkMode(spec.defaultWorkModeIndex, true)
            spec.hudExtension = WorkModeHUDExtension.new(self)
        end
        spec.accumulatedFruitType = FruitType.UNKNOWN
        spec.dirtyFlag = self:getNextDirtyFlag()
    end
    if spec.stateMax == nil or spec.stateMax == 0 then
        SpecializationUtil.removeEventListener(self, "onPostLoad", WorkMode)
        SpecializationUtil.removeEventListener(self, "onDelete", WorkMode)
        SpecializationUtil.removeEventListener(self, "onReadStream", WorkMode)
        SpecializationUtil.removeEventListener(self, "onWriteStream", WorkMode)
        SpecializationUtil.removeEventListener(self, "onReadUpdateStream", WorkMode)
        SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", WorkMode)
        SpecializationUtil.removeEventListener(self, "onUpdate", WorkMode)
        SpecializationUtil.removeEventListener(self, "onUpdateTick", WorkMode)
        SpecializationUtil.removeEventListener(self, "onDraw", WorkMode)
        SpecializationUtil.removeEventListener(self, "onTurnedOn", WorkMode)
        SpecializationUtil.removeEventListener(self, "onTurnedOff", WorkMode)
        SpecializationUtil.removeEventListener(self, "onDeactivate", WorkMode)
        SpecializationUtil.removeEventListener(self, "onSetLowered", WorkMode)
        SpecializationUtil.removeEventListener(self, "onFoldStateChanged", WorkMode)
        SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", WorkMode)
    end
end
function WorkMode:onPostLoad(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        local spec = self.spec_workMode
        if spec.stateMax > 0 and savegame.xmlFile:hasProperty(savegame.key .. ".workMode#state") then
            local workMode = savegame.xmlFile:getValue(savegame.key .. ".workMode#state", spec.defaultWorkModeIndex)
            self:setWorkMode(math.clamp(workMode, 1, spec.stateMax), true)
            AnimatedVehicle.updateAnimations(self, 99999999, true)
            if self.spec_foldable ~= nil and (self.spec_foldable.hasFoldingParts and self.spec_foldable.foldMoveDirection == 0) then
                local foldAnimTime = self:getFoldAnimTime()
                if foldAnimTime <= 0 then
                    self.spec_foldable.foldMoveDirection = -1
                    return
                end
                if self.spec_foldable.foldMiddleAnimTime == foldAnimTime then
                    self.spec_foldable.moveToMiddle = true
                end
                self.spec_foldable.foldMoveDirection = 1
            end
        end
    end
end
function WorkMode:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_workMode
    if spec.state ~= nil then
        xmlFile:setValue(key .. "#state", spec.state)
    end
end
function WorkMode:onDelete()
    local spec = self.spec_workMode
    if spec.workModes ~= nil then
        for _, mode in ipairs(spec.workModes) do
            g_effectManager:deleteEffects(mode.windrowerEffects)
            g_animationManager:deleteAnimations(mode.animationNodes)
        end
    end
    if spec.hudExtension ~= nil then
        spec.hudExtension:delete()
    end
end
function WorkMode:onReadStream(streamId, _)
    self:setWorkMode(streamReadUIntN(streamId, WorkMode.WORKMODE_SEND_NUM_BITS), true)
end
function WorkMode:onWriteStream(streamId, _)
    streamWriteUIntN(streamId, self.spec_workMode.state, WorkMode.WORKMODE_SEND_NUM_BITS)
end
function WorkMode:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        local spec = self.spec_workMode
        for _, effect in ipairs(spec.workModes[spec.state].windrowerEffects) do
            if streamReadBool(streamId) then
                effect.lastChargeTime = g_currentMission.time
            end
        end
        spec.accumulatedFruitType = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
    end
end
function WorkMode:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_workMode
        local mode = streamWriteBool
        local effect = spec.dirtyFlag
        if mode(streamId, bit32.band(dirtyMask, effect) ~= 0) then
            for _, effect in ipairs(spec.workModes[spec.state].windrowerEffects) do
                streamWriteBool(streamId, effect.lastChargeTime + 500 > g_currentMission.time)
            end
            streamWriteUIntN(streamId, spec.accumulatedFruitType, FruitTypeManager.SEND_NUM_BITS)
        end
    end
end
function WorkMode:onUpdate(dt, _, _, _)
    if self.isClient then
        local mode = self.spec_workMode.workModes[self.spec_workMode.state]
        local i = 1
        local allowWorkModeChange = #spec.workModes
        local actionEvent = 1
        for i = i, allowWorkModeChange, actionEvent do
            for _, turnedOnAnimation in pairs(spec.workModes[i].turnedOnAnimations) do
                if turnedOnAnimation.speedDirection ~= 0 then
                    local duration = turnedOnAnimation.turnOnFadeTime
                    if turnedOnAnimation.speedDirection == -1 then
                        duration = turnedOnAnimation.turnOffFadeTime
                    end
                    local min = 0
                    local max = 1
                    if turnedOnAnimation.speedDirection == 1 then
                        min = -1
                        max = 1
                    end
                    turnedOnAnimation.currentSpeed = math.clamp(turnedOnAnimation.currentSpeed + turnedOnAnimation.speedDirection * dt / duration, min, max)
                    if self:getIsAnimationPlaying(turnedOnAnimation.name) then
                        self:setAnimationSpeed(turnedOnAnimation.name, turnedOnAnimation.currentSpeed * turnedOnAnimation.speedScale)
                    else
                        self:playAnimation(turnedOnAnimation.name, turnedOnAnimation.currentSpeed * turnedOnAnimation.speedScale, self:getAnimationTime(turnedOnAnimation.name), true)
                    end
                    if turnedOnAnimation.speedDirection == -1 and turnedOnAnimation.currentSpeed == 0 then
                        self:stopAnimation(turnedOnAnimation.name, true)
                    end
                    if turnedOnAnimation.currentSpeed == 1 or turnedOnAnimation.currentSpeed == 0 then
                        turnedOnAnimation.speedDirection = 0
                    end
                end
            end
        end
        for _, effect in pairs(mode.windrowerEffects) do
            if effect.lastChargeTime + 500 > g_currentMission.time then
                local fillType = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(spec.accumulatedFruitType)
                if fillType ~= nil then
                    effect:setFillType(fillType)
                    if not effect:isRunning() then
                        g_effectManager:startEffect(effect)
                    end
                end
            elseif effect.turnOffRequiredEffect == 0 or effect.turnOffRequiredEffect ~= 0 and not mode.windrowerEffects[effect.turnOffRequiredEffect]:isRunning() then
                g_effectManager:stopEffect(effect)
            end
        end
        local allowWorkModeChange = self:getIsWorkModeChangeAllowed()
        local actionEvent = spec.actionEvents[InputAction.TOGGLE_WORKMODE]
        if actionEvent ~= nil then
            g_inputBinding:setActionEventActive(actionEvent.actionEventId, allowWorkModeChange)
        end
        for fillType, _ in ipairs(spec.workModes) do
            if _.inputAction ~= nil then
                local actionEvent = spec.actionEvents[_.inputAction]
                if actionEvent ~= nil then
                    g_inputBinding:setActionEventActive(actionEvent.actionEventId, allowWorkModeChange)
                end
            end
        end
    end
    if self.isServer then
        local mode = spec.workModes[spec.state]
        local allowWorkModeChange = nil
        local actionEvent = nil
        for fillType, _ in ipairs(mode.workAreas) do
            local turnedOnAnimation = self.spec_workArea.workAreas[_.workAreaIndex]
            if turnedOnAnimation ~= nil then
                if turnedOnAnimation.lastValidPickupFruitType ~= FruitType.UNKNOWN then
                    allowWorkModeChange = turnedOnAnimation.lastValidPickupFruitType
                end
                if not actionEvent then
                    actionEvent = turnedOnAnimation.lastPickupLiters ~= 0
                end
            end
        end
        if allowWorkModeChange ~= nil and allowWorkModeChange ~= spec.accumulatedFruitType then
            spec.accumulatedFruitType = allowWorkModeChange
            self:raiseDirtyFlags(spec.dirtyFlag)
        end
        for fillType, _ in pairs(mode.windrowerEffects) do
            if actionEvent then
                _.lastChargeTime = g_currentMission.time
                self:raiseDirtyFlags(spec.dirtyFlag)
            end
        end
    end
end
function WorkMode:onUpdateTick(_, _, _, _)
    if self.getFoldAnimTime ~= nil then
        local foldAnimTime = self:getFoldAnimTime()
        if foldAnimTime == 0 or foldAnimTime == self.spec_foldable.foldMiddleAnimTime then
            for _, anim in pairs(self.spec_workMode.workModes[self.spec_workMode.state].animations) do
                if anim.repeatAfterUnfolding and not anim.repeated then
                    local curTime = self:getAnimationTime(anim.animName)
                    if anim.stopTime == nil then
                        self:playAnimation(anim.animName, anim.animSpeed, Utils.getNoNil(anim.repeatStartTime, curTime), true)
                    else
                        self:setAnimationStopTime(anim.animName, anim.stopTime)
                        local speed = math.abs(anim.animSpeed)
                        if anim.stopTime < curTime then
                            speed = -math.abs(anim.animSpeed)
                        end
                        self:playAnimation(anim.animName, speed, Utils.getNoNil(anim.repeatStartTime, curTime), true)
                    end
                    anim.repeated = true
                end
            end
        end
        if spec.playDelayedLoweringAnimation ~= nil and (foldAnimTime == 1 or (foldAnimTime == 0 or foldAnimTime == self.spec_foldable.foldMiddleAnimTime)) then
            WorkMode.onSetLowered(self, spec.playDelayedLoweringAnimation)
            spec.playDelayedLoweringAnimation = nil
        end
    end
end
function WorkMode:onDraw(_, _, _)
    local spec = self.spec_workMode
    if spec.hudExtension ~= nil then
        g_currentMission.hud:addHelpExtension(spec.hudExtension)
    end
end
function WorkMode:onDeactivate()
    WorkMode.deactivateWindrowerEffects(self)
end
function WorkMode:deactivateWindrowerEffects()
    if self.isClient then
        for _, mode in pairs(self.spec_workMode.workModes) do
            if mode.windrowerEffects ~= nil then
                g_effectManager:stopEffects(mode.windrowerEffects)
            end
        end
    end
end
function WorkMode:loadWorkModeFromXML(xmlFile, key, workMode)
    workMode.name = xmlFile:getValue(key .. "#name", nil, self.customEnvironment)
    local inputBindingName = xmlFile:getValue(key .. "#inputBindingName")
    if inputBindingName ~= nil and InputAction[inputBindingName] ~= nil then
        workMode.inputAction = InputAction[inputBindingName]
    end
    workMode.isDefault = xmlFile:getValue(key .. "#isDefault", false)
    workMode.turnedOnAnimations = {}
    for _, animKey in xmlFile:iterator(key .. ".turnedOnAnimations.turnedOnAnimation") do
        local turnedOnAnimation = {
            ["name"] = xmlFile:getValue(animKey .. "#name"),
            ["turnOnFadeTime"] = xmlFile:getValue(animKey .. "#turnOnFadeTime", 1) * 1000,
            ["turnOffFadeTime"] = xmlFile:getValue(animKey .. "#turnOffFadeTime", 1) * 1000,
            ["speedScale"] = xmlFile:getValue(animKey .. "#speedScale", 1),
            ["speedDirection"] = 0,
            ["currentSpeed"] = 0
        }
        if self:getAnimationExists(turnedOnAnimation.name) then
            table.insert(workMode.turnedOnAnimations, turnedOnAnimation)
        end
    end
    workMode.loweringAnimations = {}
    for _, animKey in xmlFile:iterator(key .. ".loweringAnimations.loweringAnimation") do
        local turnedOnAnimation = {
            ["name"] = xmlFile:getValue(animKey .. "#name"),
            ["speed"] = xmlFile:getValue(animKey .. "#speed", 1)
        }
        if self:getAnimationExists(turnedOnAnimation.name) then
            table.insert(workMode.loweringAnimations, turnedOnAnimation)
        end
    end
    workMode.workAreas = {}
    for _, animKey in xmlFile:iterator(key .. ".workAreas.workArea") do
        local turnedOnAnimation = {
            ["workAreaIndex"] = xmlFile:getValue(animKey .. "#workAreaIndex", _),
            ["dropAreaIndex"] = xmlFile:getValue(animKey .. "#dropAreaIndex", _)
        }
        table.insert(workMode.workAreas, turnedOnAnimation)
    end
    workMode.animations = {}
    for _, animKey in xmlFile:iterator(key .. ".animation") do
        local turnedOnAnimation = {
            ["animName"] = xmlFile:getValue(animKey .. "#name"),
            ["animSpeed"] = xmlFile:getValue(animKey .. "#speed", 1),
            ["stopTime"] = xmlFile:getValue(animKey .. "#stopTime"),
            ["repeatAfterUnfolding"] = xmlFile:getValue(animKey .. "#repeatAfterUnfolding", false),
            ["repeatStartTime"] = xmlFile:getValue(animKey .. "#repeatStartTime"),
            ["repeated"] = false
        }
        if self:getAnimationExists(turnedOnAnimation.animName) then
            table.insert(workMode.animations, turnedOnAnimation)
        end
    end
    local movingToolLimitNode = xmlFile:getValue(key .. ".movingToolLimit#node", nil, self.components, self.i3dMappings)
    if movingToolLimitNode ~= nil then
        workMode.movingTool = self:getMovingToolByNode(movingToolLimitNode)
        workMode.movingToolMinRot = xmlFile:getValue(key .. ".movingToolLimit#minRot", 0)
        workMode.movingToolMaxRot = xmlFile:getValue(key .. ".movingToolLimit#maxRot", 0)
    end
    if self.setSectionsActive ~= nil then
        workMode.variableWorkWidth = {}
        workMode.variableWorkWidth.leftState = xmlFile:getValue(key .. ".variableWorkWidth#leftState")
        workMode.variableWorkWidth.rightState = xmlFile:getValue(key .. ".variableWorkWidth#rightState")
    end
    workMode.windrowerEffects = g_effectManager:loadEffect(xmlFile, string.format("%s.windrowerEffect", key), self.components, self, self.i3dMappings)
    workMode.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", self.components, self, self.i3dMappings)
    if self.loadAIImplementBaseSetupFromXML ~= nil then
        self:loadAIImplementBaseSetupFromXML(xmlFile, key .. ".ai", function(_)
            -- upvalues: (copy) self, (copy) workMode
            local spec = self.spec_workMode
            return spec.workModes[spec.state] == workMode
        end)
    end
    return true
end
function WorkMode:setWorkMode(state, noEventSend)
    local spec = self.spec_workMode
    if noEventSend == nil or noEventSend == false then
        if g_server == nil then
            g_client:getServerConnection():sendEvent(SetWorkModeEvent.new(self, state))
        else
            g_server:broadcastEvent(SetWorkModeEvent.new(self, state), nil, nil, self)
        end
    end
    local newMode = spec.workModes[state]
    if newMode ~= nil then
        if state ~= spec.state then
            if spec.workModes[spec.state].animations ~= nil then
                for _, anim in pairs(currentMode.animations) do
                    local curTime = self:getAnimationTime(anim.animName)
                    if anim.stopTime == nil then
                        self:playAnimation(anim.animName, -anim.animSpeed, curTime, noEventSend)
                    end
                end
                g_animationManager:stopAnimations(currentMode.animationNodes)
            end
            if newMode.animations ~= nil then
                for _, anim in pairs(newMode.animations) do
                    local curTime = self:getAnimationTime(anim.animName)
                    if anim.stopTime == nil then
                        self:playAnimation(anim.animName, anim.animSpeed, curTime, noEventSend)
                    else
                        self:setAnimationStopTime(anim.animName, anim.stopTime)
                        local speed = math.abs(anim.animSpeed)
                        if anim.stopTime < curTime then
                            speed = -math.abs(anim.animSpeed)
                        end
                        self:playAnimation(anim.animName, speed, curTime, noEventSend)
                    end
                end
            end
            if self.getIsTurnedOn ~= nil then
                local isTurnedOn = self:getIsTurnedOn()
                if newMode.animations ~= nil and isTurnedOn then
                    g_animationManager:startAnimations(newMode.animationNodes)
                end
                if isTurnedOn then
                    for anim, curTime in pairs(newMode.turnedOnAnimations) do
                        if self:getIsAnimationPlaying(curTime.name) then
                            local i = 1
                            for i = i, #spec.workModes do
                                local otherMode = spec.workModes[i]
                                if otherMode ~= newMode then
                                    local j = 1
                                    for j = j, #otherMode.turnedOnAnimations do
                                        local otherAnimation = otherMode.turnedOnAnimations[j]
                                        if otherAnimation.name == curTime.name then
                                            local animationSpeed = self.spec_animatedVehicle.animations[curTime.name].currentSpeed
                                            if animationSpeed ~= 0 then
                                                curTime.currentSpeed = animationSpeed / curTime.speedScale
                                                otherAnimation.currentSpeed = 0
                                                otherAnimation.speedDirection = 0
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        curTime.speedDirection = 1
                    end
                end
            end
            if newMode.variableWorkWidth ~= nil then
                if newMode.variableWorkWidth.leftState ~= nil then
                    self:setSectionsActive(newMode.variableWorkWidth.leftState, self.spec_variableWorkWidth.rightSide, true)
                end
                if newMode.variableWorkWidth.rightState ~= nil then
                    self:setSectionsActive(self.spec_variableWorkWidth.leftSide, newMode.variableWorkWidth.rightState, true)
                end
            end
            for _, anim in pairs(currentMode.windrowerEffects) do
                g_effectManager:stopEffect(anim)
            end
            spec.state = state
        end
        local isTurnedOn = self.spec_workArea
        if isTurnedOn ~= nil then
            for curTime, speed in pairs(spec.workModes[state].workAreas) do
                local workAreaToSet = isTurnedOn.workAreas[speed.workAreaIndex]
                if workAreaToSet ~= nil then
                    workAreaToSet.dropWindrowWorkAreaIndex = speed.dropAreaIndex
                    workAreaToSet.dropAreaIndex = speed.dropAreaIndex
                end
            end
        end
        if newMode.movingTool ~= nil then
            if newMode.movingToolMinRot ~= nil then
                newMode.movingTool.rotMin = newMode.movingToolMinRot
            end
            if newMode.movingToolMaxRot ~= nil then
                workAreas.rotMax = newMode.movingToolMaxRot
            end
            if self.isClient then
                workAreas.networkInterpolators.rotation:setMinMax(workAreas.rotMin, workAreas.rotMax)
            end
        end
        SpecializationUtil.raiseEvent(self, "onWorkModeChanged", newMode, currentMode)
    end
end
function WorkMode:getWorkMode()
    local spec = self.spec_workMode
    if spec.workModes == nil then
        return nil
    else
        return spec.workModes[spec.state]
    end
end
function WorkMode:getIsWorkAreaActive(superFunc, workArea)
    local spec = self.spec_workMode
    if spec.stateMax ~= nil and spec.stateMax > 0 then
        for _, workArea2 in pairs(spec.workModes[spec.state].workAreas) do
            if workArea.index == workArea2.workAreaIndex and workArea2.dropAreaIndex == 0 then
                return false
            end
        end
    end
    return superFunc(self, workArea)
end
function WorkMode:getCanBeSelected(superFunc)
    return true
end
function WorkMode:getAllowsLowering(superFunc)
    local allowLowering, warning = superFunc(self)
    local spec = self.spec_workMode
    local hasLoweringAnimations = false
    if spec.workModes ~= nil and #spec.workModes > 0 then
        hasLoweringAnimations = #spec.workModes[spec.state].loweringAnimations > 0
    end
    return allowLowering or hasLoweringAnimations, warning
end
function WorkMode:loadSprayTypeFromXML(superFunc, xmlFile, key, sprayType)
    sprayType.workModeIndex = xmlFile:getValue(key .. "#workModeIndex")
    return superFunc(self, xmlFile, key, sprayType)
end
function WorkMode:getIsSprayTypeActive(superFunc, sprayType)
    if sprayType.workModeIndex == nil or self.spec_workMode.state == sprayType.workModeIndex then
        return superFunc(self, sprayType)
    else
        return false
    end
end
function WorkMode:loadMovingToolFromXML(superFunc, xmlFile, key, entry)
    if not superFunc(self, xmlFile, key, entry) then
        return false
    end
    entry.allowWhileChangingWorkMode = xmlFile:getValue(key .. "#allowWhileChangingWorkMode", true)
    return true
end
function WorkMode:getIsMovingToolActive(superFunc, movingTool)
    if not movingTool.allowWhileChangingWorkMode then
        local spec = self.spec_workMode
        if spec.stateMax ~= nil then
            local i = 1
            for i = i, #spec.workModes do
                local workMode = spec.workModes[i]
                local j = 1
                for j = j, #workMode.animations do
                    if self:getIsAnimationPlaying(workMode.animations[j].animName) then
                        return false
                    end
                end
            end
        end
    end
    return superFunc(self, movingTool)
end
function WorkMode:getAreEffectsVisible(superFunc)
    if not superFunc(self) then
        return false
    end
    local spec = self.spec_workMode
    if spec.stateMax ~= nil and spec.stateMax > 0 then
        local i = 1
        for i = i, #spec.workModes do
            local workMode = spec.workModes[i]
            local j = 1
            for j = j, #workMode.animations do
                if self:getIsAnimationPlaying(workMode.animations[j].animName) then
                    return false
                end
            end
        end
    end
    return true
end
function WorkMode:getIsWorkModeChangeAllowed()
    local spec = self.spec_workMode
    if self.getFoldAnimTime ~= nil and (self:getFoldAnimTime() > spec.foldMaxLimit or self:getFoldAnimTime() < spec.foldMinLimit) then
        return false
    end
    if not spec.allowChangeOnLowered then
        local attacherVehicle = self:getAttacherVehicle()
        if attacherVehicle ~= nil and attacherVehicle:getAttacherJointByJointDescIndex((attacherVehicle:getAttacherJointIndexFromObject(self))).moveDown then
            return false
        end
    end
    return true
end
function WorkMode:onTurnedOff()
    if self.isClient then
        WorkMode.deactivateWindrowerEffects(self)
        local mode = self.spec_workMode.workModes[self.spec_workMode.state]
        for _, turnedOnAnimation in pairs(mode.turnedOnAnimations) do
            turnedOnAnimation.speedDirection = -1
        end
        g_animationManager:stopAnimations(mode.animationNodes)
    end
end
function WorkMode:onTurnedOn()
    if self.isClient then
        local mode = self.spec_workMode.workModes[self.spec_workMode.state]
        for _, turnedOnAnimation in pairs(mode.turnedOnAnimations) do
            turnedOnAnimation.speedDirection = 1
        end
        g_animationManager:startAnimations(mode.animationNodes)
    end
end
function WorkMode:onSetLowered(lowered)
    local spec = self.spec_workMode
    if self.getFoldAnimTime ~= nil then
        local foldAnimTime = self:getFoldAnimTime()
        if foldAnimTime ~= 1 and (foldAnimTime ~= 0 and foldAnimTime ~= self.foldMiddleAnimTime) then
            spec.playDelayedLoweringAnimation = lowered
            return
        end
    end
    local foldAnimTime = spec.workModes[spec.state]
    for _, loweringAnimation in pairs(foldAnimTime.loweringAnimations) do
        if lowered then
            if self:getAnimationTime(loweringAnimation.name) < 1 then
                self:playAnimation(loweringAnimation.name, loweringAnimation.speed, nil, true)
            end
        elseif self:getAnimationTime(loweringAnimation.name) > 0 then
            self:playAnimation(loweringAnimation.name, -loweringAnimation.speed, nil, true)
        end
    end
end
function WorkMode:onFoldStateChanged(direction, _)
    if direction > 0 then
        for _, anim in pairs(self.spec_workMode.workModes[self.spec_workMode.state].animations) do
            if anim.repeatAfterUnfolding then
                anim.repeated = false
            end
        end
        if self:getIsLowered() and self.getAttacherVehicle ~= nil then
            local attacherVehicle = self:getAttacherVehicle()
            if attacherVehicle ~= nil then
                attacherVehicle:handleLowerImplementEvent()
            end
        end
    end
end
function WorkMode:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_workMode
        if spec.stateMax > 0 then
            self:clearActionEventsTable(spec.actionEvents)
            if isActiveForInputIgnoreSelection then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TOGGLE_WORKMODE, self, WorkMode.actionEventWorkModeChange, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
                g_inputBinding:setActionEventActive(actionEventId, false)
                for _, mode in ipairs(spec.workModes) do
                    if mode.inputAction ~= nil then
                        local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, mode.inputAction, self, WorkMode.actionEventWorkModeChangeDirect, false, true, false, true, nil)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        g_inputBinding:setActionEventActive(actionEventId, false)
                    end
                end
            end
        end
    end
end
function WorkMode:actionEventWorkModeChange(_, _, _, _)
    local spec = self.spec_workMode
    local state = spec.state + 1
    local state = spec.stateMax < state and 1 or state
    if state ~= spec.state then
        self:setWorkMode(state)
    end
end
function WorkMode:actionEventWorkModeChangeDirect(actionName, _, _, _)
    local spec = self.spec_workMode
    for state, mode in ipairs(spec.workModes) do
        if mode.inputAction == InputAction[actionName] and state ~= spec.state then
            self:setWorkMode(state)
        end
    end
end