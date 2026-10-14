source("dataS/scripts/vehicles/specializations/events/SetTurnedOnEvent.lua")
TurnOnVehicle = {}
TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH = "vehicle.turnOnVehicle.turnedOnAnimation(?)"
function TurnOnVehicle.prerequisitesPresent(specializations)
    return true
end
function TurnOnVehicle.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("TurnOnVehicle")
    schema:register(XMLValueType.STRING, "vehicle.turnOnVehicle#toggleButton", "Input action name", "IMPLEMENT_EXTRA")
    schema:register(XMLValueType.L10N_STRING, "vehicle.turnOnVehicle#turnOffText", "Turn off text", "action_turnOffOBJECT")
    schema:register(XMLValueType.L10N_STRING, "vehicle.turnOnVehicle#turnOnText", "Turn on text", "action_turnOnOBJECT")
    schema:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#isAlwaysTurnedOn", "Always turned on", false)
    schema:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#turnedOnByAttacherVehicle", "Turned on by attacher vehicle", false)
    schema:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#turnOffIfNotAllowed", "Turn off if not allowed", true)
    schema:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#turnOffOnDeactivate", "Turn off if the vehicle is deactivated", true)
    schema:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#aiRequiresTurnOn", "AI requires turned on vehicle", true)
    schema:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#requiresTurnOn", "(Mobile only) Vehicle requires turn on", true)
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.turnOnVehicle.animationNodes")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.turnOnVehicle.effects")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.turnOnVehicle.sounds", "start(?)")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.turnOnVehicle.sounds", "stop(?)")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.turnOnVehicle.sounds", "work(?)")
    schema:register(XMLValueType.STRING, "vehicle.turnOnVehicle.turnedAnimation#name", "Turned animation name (Animation played while activating and deactivating)")
    schema:register(XMLValueType.FLOAT, "vehicle.turnOnVehicle.turnedAnimation#turnOnSpeedScale", "Turn on speed scale", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.turnOnVehicle.turnedAnimation#turnOffSpeedScale", "Turn off speed scale", "Inversed turnOnSpeedScale")
    schema:register(XMLValueType.STRING, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#name", "Turned on animation name (Animation played while turn on)")
    schema:register(XMLValueType.FLOAT, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#turnOnFadeTime", "Turn on fade time", 1)
    schema:register(XMLValueType.FLOAT, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#turnOffFadeTime", "Turn off fade time", 1)
    schema:register(XMLValueType.FLOAT, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#speedScale", "Speed scale", 1)
    schema:register(XMLValueType.INT, "vehicle.turnOnVehicle.activatableFillUnits.activatableFillUnit(?)#index", "Activateable fill unit index")
    schema:register(XMLValueType.BOOL, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. "#canBeTurnedOn", "Attacher joint can turn on implement", true)
    schema:register(XMLValueType.BOOL, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. "#canBeTurnedOn", "Attacher joint can turn on implement", true)
    schema:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_KEY .. "#needsSetIsTurnedOn", "Work area needs turned on vehicle to work", true)
    schema:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_CONFIG_KEY .. "#needsSetIsTurnedOn", "Work area needs turned on vehicle to work", true)
    schema:register(XMLValueType.BOOL, FillUnit.ALARM_TRIGGER_XML_KEY .. "#needsTurnOn", "Needs turned on vehicle", false)
    schema:register(XMLValueType.BOOL, FillUnit.ALARM_TRIGGER_XML_KEY .. "#turnOffInTrigger", "Turn vehicle off when triggered", false)
    schema:register(XMLValueType.BOOL, Shovel.SHOVEL_NODE_XML_KEY .. "#needsActivation", "Needs activation", false)
    schema:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_XML_PATH .. "#needsSetIsTurnedOn", "Vehicle needs to be turned on to activate discharge node", false)
    schema:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_XML_PATH .. "#turnOnActivateNode", "Discharge node is set active when vehicle is turned on", false)
    schema:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. "#needsSetIsTurnedOn", "Vehicle needs to be turned on to activate discharge node", false)
    schema:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. "#turnOnActivateNode", "Discharge node is set active when vehicle is turned on", false)
    schema:register(XMLValueType.FLOAT, BunkerSiloCompacter.XML_PATH .. "#turnedOnCompactingScale", "Compacting scale which is used while vehicle is turned on", "normal scale")
    schema:register(XMLValueType.TIME, "vehicle.turnOnVehicle.turnedOnSpeed#fadeInTime", "(Turned on speed simulation - used as sound modifier and for rpm dashboards) Time to reach max. turned on speed", 1)
    schema:register(XMLValueType.TIME, "vehicle.turnOnVehicle.turnedOnSpeed#fadeOutTime", "(Turned on speed simulation - used as sound modifier and for rpm dashboards) Time to reach the turned off speed again", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.turnOnVehicle.turnedOnSpeed#variance", "Variation value at max. speed", 0.02)
    schema:register(XMLValueType.FLOAT, "vehicle.turnOnVehicle.turnedOnSpeed#varianceSpeed", "Speed factor of variance change", 1)
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.turnOnVehicle.dashboards", { "turnedOn", "rpm" })
    schema:register(XMLValueType.FLOAT, "vehicle.turnOnVehicle.dashboards.dashboard(?)#minRpm", "Rpm value if vehicle is turned off", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.turnOnVehicle.dashboards.dashboard(?)#maxRpm", "Rpm value if vehicle is turned on", 1000)
    schema:setXMLSpecializationType()
end
function TurnOnVehicle.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onTurnedOn")
    SpecializationUtil.registerEvent(vehicleType, "onTurnedOff")
end
function TurnOnVehicle.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setIsTurnedOn", TurnOnVehicle.setIsTurnedOn)
    SpecializationUtil.registerFunction(vehicleType, "getIsTurnedOn", TurnOnVehicle.getIsTurnedOn)
    SpecializationUtil.registerFunction(vehicleType, "getCanBeTurnedOn", TurnOnVehicle.getCanBeTurnedOn)
    SpecializationUtil.registerFunction(vehicleType, "getCanBeTurnedOnAll", TurnOnVehicle.getCanBeTurnedOnAll)
    SpecializationUtil.registerFunction(vehicleType, "getCanToggleTurnedOn", TurnOnVehicle.getCanToggleTurnedOn)
    SpecializationUtil.registerFunction(vehicleType, "getTurnedOnNotAllowedWarning", TurnOnVehicle.getTurnedOnNotAllowedWarning)
    SpecializationUtil.registerFunction(vehicleType, "getAIRequiresTurnOn", TurnOnVehicle.getAIRequiresTurnOn)
    SpecializationUtil.registerFunction(vehicleType, "getRequiresTurnOn", TurnOnVehicle.getRequiresTurnOn)
    SpecializationUtil.registerFunction(vehicleType, "getAIRequiresTurnOffOnHeadland", TurnOnVehicle.getAIRequiresTurnOffOnHeadland)
    SpecializationUtil.registerFunction(vehicleType, "loadTurnedOnAnimationFromXML", TurnOnVehicle.loadTurnedOnAnimationFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getIsTurnedOnAnimationActive", TurnOnVehicle.getIsTurnedOnAnimationActive)
    SpecializationUtil.registerFunction(vehicleType, "getTurnedOnSpeedFactor", TurnOnVehicle.getTurnedOnSpeedFactor)
end
function TurnOnVehicle.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUseTurnedOnSchema", TurnOnVehicle.getUseTurnedOnSchema)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadInputAttacherJoint", TurnOnVehicle.loadInputAttacherJoint)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", TurnOnVehicle.loadWorkAreaFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", TurnOnVehicle.getIsWorkAreaActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", TurnOnVehicle.getCanAIImplementContinueWork)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsOperating", TurnOnVehicle.getIsOperating)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAlarmTriggerIsActive", TurnOnVehicle.getAlarmTriggerIsActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAlarmTrigger", TurnOnVehicle.loadAlarmTrigger)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFillUnitActive", TurnOnVehicle.getIsFillUnitActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadShovelNode", TurnOnVehicle.loadShovelNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShovelNodeIsActive", TurnOnVehicle.getShovelNodeIsActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSeedChangeAllowed", TurnOnVehicle.getIsSeedChangeAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", TurnOnVehicle.getCanBeSelected)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", TurnOnVehicle.getIsPowerTakeOffActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDischargeNode", TurnOnVehicle.loadDischargeNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDischargeNodeActive", TurnOnVehicle.getIsDischargeNodeActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadBunkerSiloCompactorFromXML", TurnOnVehicle.loadBunkerSiloCompactorFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBunkerSiloCompacterScale", TurnOnVehicle.getBunkerSiloCompacterScale)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkModeChangeAllowed", TurnOnVehicle.getIsWorkModeChangeAllowed)
end
function TurnOnVehicle.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onAlarmTriggerChanged", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", TurnOnVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", TurnOnVehicle)
end
function TurnOnVehicle:onLoad(_)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#turnOffText", "vehicle.turnOnVehicle#turnOffText")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#turnOnText", "vehicle.turnOnVehicle#turnOnText")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#needsSelection")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#isAlwaysTurnedOn", "vehicle.turnOnVehicle#isAlwaysTurnedOn")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#toggleButton", "vehicle.turnOnVehicle#toggleButton")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#animationName", "vehicle.turnOnVehicle.turnedAnimation#name")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#turnOnSpeedScale", "vehicle.turnOnVehicle.turnedAnimation#turnOnSpeedScale")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#turnOffSpeedScale", "vehicle.turnOnVehicle.turnedAnimation#turnOffSpeedScale")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.turnOnVehicle.animationNodes.animationNode", "turnOn")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.foldable.foldingParts#turnOffOnFold", "vehicle.turnOnVehicle#turnOffIfNotAllowed")
    local spec = self.spec_turnOnVehicle
    local turnOnButtonStr = self.xmlFile:getValue("vehicle.turnOnVehicle#toggleButton")
    if turnOnButtonStr ~= nil then
        spec.toggleTurnOnInputBinding = InputAction[turnOnButtonStr]
    end
    spec.toggleTurnOnInputBinding = Utils.getNoNil(spec.toggleTurnOnInputBinding, InputAction.IMPLEMENT_EXTRA)
    spec.turnOffText = string.format(self.xmlFile:getValue("vehicle.turnOnVehicle#turnOffText", "action_turnOffOBJECT", self.customEnvironment), self.typeDesc)
    spec.turnOnText = string.format(self.xmlFile:getValue("vehicle.turnOnVehicle#turnOnText", "action_turnOnOBJECT", self.customEnvironment), self.typeDesc)
    spec.isTurnedOn = false
    spec.isAlwaysTurnedOn = self.xmlFile:getValue("vehicle.turnOnVehicle#isAlwaysTurnedOn", false)
    spec.turnedOnByAttacherVehicle = self.xmlFile:getValue("vehicle.turnOnVehicle#turnedOnByAttacherVehicle", false)
    spec.turnOffIfNotAllowed = self.xmlFile:getValue("vehicle.turnOnVehicle#turnOffIfNotAllowed", true)
    spec.turnOffOnDeactivate = self.xmlFile:getValue("vehicle.turnOnVehicle#turnOffOnDeactivate", not GS_IS_MOBILE_VERSION)
    spec.aiRequiresTurnOn = self.xmlFile:getValue("vehicle.turnOnVehicle#aiRequiresTurnOn", true)
    spec.requiresTurnOn = self.xmlFile:getValue("vehicle.turnOnVehicle#requiresTurnOn", true)
    if self.isClient then
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.turnOnVehicle.animationNodes", self.components, self, self.i3dMappings)
        local allowsAnimations = SpecializationUtil.hasSpecialization(AnimatedVehicle, self.specializations)
        if allowsAnimations then
            local turnOnAnimation = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedAnimation#name")
            if turnOnAnimation ~= nil then
                spec.turnOnAnimation = {}
                spec.turnOnAnimation.name = turnOnAnimation
                spec.turnOnAnimation.turnOnSpeedScale = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedAnimation#turnOnSpeedScale", 1)
                spec.turnOnAnimation.turnOffSpeedScale = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedAnimation#turnOffSpeedScale", -spec.turnOnAnimation.turnOnSpeedScale)
            end
        end
        spec.turnedOnAnimations = {}
        if allowsAnimations then
            self.xmlFile:iterate("vehicle.turnOnVehicle.turnedOnAnimation", function(_, key)
                -- upvalues: (copy) self, (copy) spec
                local entry = {}
                if self:loadTurnedOnAnimationFromXML(self.xmlFile, key, entry) then
                    table.insert(spec.turnedOnAnimations, entry)
                end
            end)
        end
        spec.activatableFillUnits = {}
        local turnOnAnimation = 0
        while true do
            local key = string.format("vehicle.turnOnVehicle.activatableFillUnits.activatableFillUnit(%d)", turnOnAnimation)
            if not self.xmlFile:hasProperty(key) then
                break
            end
            local fillUnitIndex = self.xmlFile:getValue(key .. "#index")
            if fillUnitIndex ~= nil then
                spec.activatableFillUnits[fillUnitIndex] = true
            end
            turnOnAnimation = turnOnAnimation + 1
        end
        spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.turnOnVehicle.effects", self.components, self, self.i3dMappings)
        spec.samples = {}
        spec.samples.start = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.turnOnVehicle.sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.stop = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.turnOnVehicle.sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.work = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.turnOnVehicle.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.turnedOnSpeed = {}
        spec.turnedOnSpeed.isActive = self.xmlFile:hasProperty("vehicle.turnOnVehicle.turnedOnSpeed")
        spec.turnedOnSpeed.alpha = 0
        spec.turnedOnSpeed.fadeInTime = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedOnSpeed#fadeInTime", 1)
        spec.turnedOnSpeed.fadeOutTime = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedOnSpeed#fadeOutTime", 1)
        spec.turnedOnSpeed.variance = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedOnSpeed#variance", 0.02)
        spec.turnedOnSpeed.varianceSpeed = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedOnSpeed#varianceSpeed", 0.01)
    end
    if not self.isClient then
        SpecializationUtil.removeEventListener(self, "onDelete", TurnOnVehicle)
        SpecializationUtil.removeEventListener(self, "onUpdate", TurnOnVehicle)
    end
end
function TurnOnVehicle:onRegisterDashboardValueTypes()
    local turnedOn = DashboardValueType.new("turnOnVehicle", "turnedOn")
    turnedOn:setValue(self.spec_turnOnVehicle, "isTurnedOn")
    turnedOn:setPollUpdate(false)
    self:registerDashboardValueType(turnedOn)
    local rpm = DashboardValueType.new("turnOnVehicle", "rpm")
    rpm:setValue(self, TurnOnVehicle.dashboardRpmValue)
    rpm:setAdditionalFunctions(TurnOnVehicle.dashboardRpmAttributes, nil)
    self:registerDashboardValueType(rpm)
end
function TurnOnVehicle:onDelete()
    if self.isClient then
        if self.spec_turnOnVehicle.samples ~= nil then
            g_soundManager:deleteSamples(spec.samples.start)
            g_soundManager:deleteSamples(spec.samples.stop)
            g_soundManager:deleteSamples(spec.samples.work)
        end
        g_animationManager:deleteAnimations(spec.animationNodes)
        g_effectManager:deleteEffects(spec.effects)
    end
end
function TurnOnVehicle:onReadStream(streamId, _)
    self:setIsTurnedOn(streamReadBool(streamId), true)
end
function TurnOnVehicle:onWriteStream(streamId, _)
    streamWriteBool(streamId, self.spec_turnOnVehicle.isTurnedOn)
end
function TurnOnVehicle:onUpdate(dt, _, _, _)
    local spec = self.spec_turnOnVehicle
    local i = 1
    local targetAlpha = #spec.turnedOnAnimations
    local time = 1
    for i = i, targetAlpha, time do
        local turnedOnAnimation = spec.turnedOnAnimations[i]
        local isTurnedOn = self:getIsTurnedOnAnimationActive(turnedOnAnimation)
        if turnedOnAnimation.isTurnedOn ~= isTurnedOn then
            if isTurnedOn then
                turnedOnAnimation.speedDirection = 1
                self:playAnimation(turnedOnAnimation.name, math.max(turnedOnAnimation.currentSpeed * turnedOnAnimation.speedScale, 0.001), self:getAnimationTime(turnedOnAnimation.name), true)
            else
                turnedOnAnimation.speedDirection = -1
            end
            turnedOnAnimation.isTurnedOn = isTurnedOn
        end
        if turnedOnAnimation.speedDirection ~= 0 then
            local duration = turnedOnAnimation.turnOnFadeTime
            if turnedOnAnimation.speedDirection == -1 then
                duration = turnedOnAnimation.turnOffFadeTime
            end
            turnedOnAnimation.currentSpeed = math.clamp(turnedOnAnimation.currentSpeed + turnedOnAnimation.speedDirection * dt / duration, 0, 1)
            self:setAnimationSpeed(turnedOnAnimation.name, turnedOnAnimation.currentSpeed * turnedOnAnimation.speedScale)
            if turnedOnAnimation.speedDirection == -1 and turnedOnAnimation.currentSpeed == 0 then
                self:stopAnimation(turnedOnAnimation.name, true)
            end
            if turnedOnAnimation.currentSpeed == 1 or turnedOnAnimation.currentSpeed == 0 then
                turnedOnAnimation.speedDirection = 0
            end
        end
    end
    if self.isClient and spec.turnedOnSpeed.isActive then
        local targetAlpha = 0
        if self:getIsTurnedOn() then
            local time = g_time * spec.turnedOnSpeed.varianceSpeed * 0.05
            local duration = math.sin(time)
            local turnedOnAnimation = duration * math.sin((time + 2) * 0.3) * 0.8
            targetAlpha = 1 + (turnedOnAnimation + math.cos(time * 5) * 0.2) * spec.turnedOnSpeed.variance
        end
        if targetAlpha ~= spec.turnedOnSpeed.alpha then
            local time = math.sign(targetAlpha - spec.turnedOnSpeed.alpha)
            spec.turnedOnSpeed.alpha = (time < 0 and math.max or math.min)(spec.turnedOnSpeed.alpha + 1 / (time < 0 and spec.turnedOnSpeed.fadeOutTime or spec.turnedOnSpeed.fadeInTime) * time * dt, targetAlpha)
        end
    end
end
function TurnOnVehicle:onUpdateTick(_, _, _, _)
    local spec = self.spec_turnOnVehicle
    if self.isClient and not (spec.isAlwaysTurnedOn or spec.turnedOnByAttacherVehicle) then
        TurnOnVehicle.updateActionEvents(self)
    end
    if self.isServer and (spec.turnOffIfNotAllowed and not self:getCanBeTurnedOn()) then
        if self:getIsTurnedOn() then
            self:setIsTurnedOn(false)
            return
        end
        if self.getAttacherVehicle ~= nil then
            local attacherVehicle = self:getAttacherVehicle()
            if attacherVehicle ~= nil and (attacherVehicle.setIsTurnedOn ~= nil and attacherVehicle:getIsTurnedOn()) then
                attacherVehicle:setIsTurnedOn(false)
            end
        end
    end
end
function TurnOnVehicle:setIsTurnedOn(isTurnedOn, noEventSend)
    local spec = self.spec_turnOnVehicle
    if isTurnedOn ~= spec.isTurnedOn then
        SetTurnedOnEvent.sendEvent(self, isTurnedOn, noEventSend)
        spec.isTurnedOn = isTurnedOn
        if spec.isTurnedOn then
            SpecializationUtil.raiseEvent(self, "onTurnedOn")
            self.rootVehicle:raiseStateChange(VehicleStateChange.TURN_ON, self)
        else
            SpecializationUtil.raiseEvent(self, "onTurnedOff")
            self.rootVehicle:raiseStateChange(VehicleStateChange.TURN_OFF, self)
        end
        if self.isClient and self.updateDashboardValueType ~= nil then
            self:updateDashboardValueType("turnOnVehicle.turnedOn")
        end
    end
end
function TurnOnVehicle:onTurnedOn()
    local spec = self.spec_turnOnVehicle
    if self.isClient then
        if spec.turnOnAnimation ~= nil then
            self:playAnimation(spec.turnOnAnimation.name, spec.turnOnAnimation.turnOnSpeedScale, self:getAnimationTime(spec.turnOnAnimation.name), true)
        end
        g_soundManager:stopSamples(spec.samples.start)
        g_soundManager:stopSamples(spec.samples.work)
        g_soundManager:stopSamples(spec.samples.stop)
        g_soundManager:playSamples(spec.samples.start)
        local i = 1
        for i = i, #spec.samples.work do
            g_soundManager:playSample(spec.samples.work[i], 0, spec.samples.start[i] or spec.samples.start[1])
        end
        g_animationManager:startAnimations(spec.animationNodes)
        g_effectManager:startEffects(spec.effects)
    end
    if spec.activateableDischargeNode ~= nil and spec.activateableDischargeNode.index ~= nil then
        spec.activateableDischargeNodePrev = self:getCurrentDischargeNode()
        self:setCurrentDischargeNodeIndex(spec.activateableDischargeNode.index)
    end
end
function TurnOnVehicle:onTurnedOff()
    local spec = self.spec_turnOnVehicle
    if self.isClient then
        if spec.turnOnAnimation ~= nil then
            self:playAnimation(spec.turnOnAnimation.name, spec.turnOnAnimation.turnOffSpeedScale, self:getAnimationTime(spec.turnOnAnimation.name), true)
        end
        g_soundManager:stopSamples(spec.samples.start)
        g_soundManager:stopSamples(spec.samples.work)
        g_soundManager:stopSamples(spec.samples.stop)
        g_soundManager:playSamples(spec.samples.stop)
        g_animationManager:stopAnimations(spec.animationNodes)
        g_effectManager:stopEffects(spec.effects)
    end
    if spec.activateableDischargeNodePrev ~= nil and spec.activateableDischargeNodePrev.index ~= nil then
        self:setCurrentDischargeNodeIndex(spec.activateableDischargeNodePrev.index)
        spec.activateableDischargeNodePrev = nil
    end
end
function TurnOnVehicle:getIsTurnedOn()
    local spec = self.spec_turnOnVehicle
    return spec.isAlwaysTurnedOn or spec.isTurnedOn
end
function TurnOnVehicle:getCanBeTurnedOn()
    if self.spec_turnOnVehicle.isAlwaysTurnedOn then
        return false
    end
    if self.getInputAttacherJoint ~= nil then
        local inputAttacherJoint = self:getInputAttacherJoint()
        if inputAttacherJoint ~= nil and (inputAttacherJoint.canBeTurnedOn ~= nil and not inputAttacherJoint.canBeTurnedOn) then
            return false
        end
    end
    return self:getIsPowered() and true or false
end
function TurnOnVehicle:getCanBeTurnedOnAll()
    local vehicles = self.rootVehicle:getChildVehicles()
    local i = 1
    for i = i, #vehicles do
        local vehicle = vehicles[i]
        if vehicle.getCanBeTurnedOn ~= nil and not vehicle:getCanBeTurnedOn() then
            return false
        end
    end
    return true
end
function TurnOnVehicle:getCanToggleTurnedOn()
    local spec = self.spec_turnOnVehicle
    if spec.isAlwaysTurnedOn then
        return false
    else
        return not spec.turnedOnByAttacherVehicle
    end
end
function TurnOnVehicle:getTurnedOnNotAllowedWarning()
    if self:getIsPowered() then
        return nil
    else
        return g_i18n:getText("warning_attachToPower")
    end
end
function TurnOnVehicle:getAIRequiresTurnOn()
    return self.spec_turnOnVehicle.aiRequiresTurnOn
end
function TurnOnVehicle:getRequiresTurnOn()
    return self.spec_turnOnVehicle.requiresTurnOn
end
function TurnOnVehicle:getAIRequiresTurnOffOnHeadland()
    return false
end
function TurnOnVehicle:loadTurnedOnAnimationFromXML(xmlFile, key, turnedOnAnimation)
    local name = self.xmlFile:getValue(key .. "#name")
    if name == nil then
        Logging.xmlWarning(xmlFile, "Missing animation name in \'%s\'", key)
        return false
    end
    turnedOnAnimation.name = name
    turnedOnAnimation.turnOnFadeTime = self.xmlFile:getValue(key .. "#turnOnFadeTime", 1) * 1000
    turnedOnAnimation.turnOffFadeTime = self.xmlFile:getValue(key .. "#turnOffFadeTime", 1) * 1000
    turnedOnAnimation.speedScale = self.xmlFile:getValue(key .. "#speedScale", 1)
    turnedOnAnimation.speedDirection = 0
    turnedOnAnimation.currentSpeed = 0
    turnedOnAnimation.isTurnedOn = false
    return true
end
function TurnOnVehicle:getIsTurnedOnAnimationActive(_)
    return self:getIsTurnedOn() and true or false
end
function TurnOnVehicle:getUseTurnedOnSchema(superFunc)
    return superFunc(self) or self:getIsTurnedOn()
end
function TurnOnVehicle:loadInputAttacherJoint(superFunc, xmlFile, key, inputAttacherJoint, i)
    if not superFunc(self, xmlFile, key, inputAttacherJoint, i) then
        return false
    end
    inputAttacherJoint.canBeTurnedOn = xmlFile:getValue(key .. "#canBeTurnedOn", true)
    return true
end
function TurnOnVehicle:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
    local retValue = superFunc(self, workArea, xmlFile, key)
    workArea.needsSetIsTurnedOn = xmlFile:getValue(key .. "#needsSetIsTurnedOn", true)
    return retValue
end
function TurnOnVehicle:getIsWorkAreaActive(superFunc, workArea)
    if self:getIsTurnedOn() or not workArea.needsSetIsTurnedOn then
        return superFunc(self, workArea)
    else
        return false
    end
end
function TurnOnVehicle:getCanAIImplementContinueWork(superFunc, isTurning)
    local canContinue, stopAI, stopReason = superFunc(self, isTurning)
    if canContinue then
        return not self:getAIRequiresTurnOn() and true or (not self:getIsAIImplementInLine() and true or ((not self:getCanBeTurnedOn() or self:getIsTurnedOn()) and true or false))
    else
        return false, stopAI, stopReason
    end
end
function TurnOnVehicle:getIsOperating(superFunc)
    return self:getIsTurnedOn() and true or superFunc(self)
end
function TurnOnVehicle:getAlarmTriggerIsActive(superFunc, alarmTrigger)
    local ret = superFunc(self, alarmTrigger)
    if alarmTrigger.needsTurnOn and not self:getIsTurnedOn() then
        ret = false
    end
    return ret
end
function TurnOnVehicle:loadAlarmTrigger(superFunc, xmlFile, key, alarmTrigger, fillUnit)
    local ret = superFunc(self, xmlFile, key, alarmTrigger, fillUnit)
    alarmTrigger.needsTurnOn = xmlFile:getValue(key .. "#needsTurnOn", false)
    alarmTrigger.turnOffInTrigger = xmlFile:getValue(key .. "#turnOffInTrigger", false)
    return ret
end
function TurnOnVehicle:getIsFillUnitActive(superFunc, fillUnitIndex)
    if self.spec_turnOnVehicle.activatableFillUnits[fillUnitIndex] == true and not self:getIsTurnedOn() then
        return false
    else
        return superFunc(self, fillUnitIndex)
    end
end
function TurnOnVehicle:loadShovelNode(superFunc, xmlFile, key, shovelNode)
    superFunc(self, xmlFile, key, shovelNode)
    shovelNode.needsActiveVehicle = xmlFile:getValue(key .. "#needsActivation", false)
    return true
end
function TurnOnVehicle:getShovelNodeIsActive(superFunc, shovelNode)
    if shovelNode.needsActiveVehicle and not self:getIsTurnedOn() then
        return false
    else
        return superFunc(self, shovelNode)
    end
end
function TurnOnVehicle:getIsSeedChangeAllowed(superFunc)
    return superFunc(self) and not self:getIsTurnedOn()
end
function TurnOnVehicle:getCanBeSelected(superFunc)
    return true
end
function TurnOnVehicle:getIsPowerTakeOffActive(superFunc)
    return self:getIsTurnedOn() or superFunc(self)
end
function TurnOnVehicle:loadDischargeNode(superFunc, xmlFile, key, entry)
    if not superFunc(self, xmlFile, key, entry) then
        return false
    end
    entry.needsSetIsTurnedOn = xmlFile:getValue(key .. "#needsSetIsTurnedOn", false)
    entry.turnOnActivateNode = xmlFile:getValue(key .. "#turnOnActivateNode", false)
    if entry.turnOnActivateNode then
        self.spec_turnOnVehicle.activateableDischargeNode = entry
    end
    return true
end
function TurnOnVehicle:getIsDischargeNodeActive(superFunc, dischargeNode)
    if dischargeNode.needsSetIsTurnedOn and not self:getIsTurnedOn() then
        return false
    else
        return superFunc(self, dischargeNode)
    end
end
function TurnOnVehicle:loadBunkerSiloCompactorFromXML(superFunc, xmlFile, key)
    superFunc(self, xmlFile, key)
    self.spec_bunkerSiloCompacter.turnedOnCompactingScale = xmlFile:getValue(key .. "#turnedOnCompactingScale")
end
function TurnOnVehicle:getBunkerSiloCompacterScale(superFunc)
    local spec = self.spec_bunkerSiloCompacter
    if spec.turnedOnCompactingScale == nil or not self:getIsTurnedOn() then
        return superFunc(self)
    else
        return spec.turnedOnCompactingScale
    end
end
function TurnOnVehicle:getIsWorkModeChangeAllowed(superFunc)
    if self.spec_workMode.allowChangeWhileTurnedOn == false and self:getIsTurnedOn() then
        return false
    else
        return superFunc(self)
    end
end
function TurnOnVehicle:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_turnOnVehicle
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection and self:getCanToggleTurnedOn() then
            local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, spec.toggleTurnOnInputBinding, self, TurnOnVehicle.actionEventTurnOn, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            TurnOnVehicle.updateActionEvents(self)
            local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TURN_ON_ALL_IMPLEMENTS, self, TurnOnVehicle.actionEventTurnOnAll, false, true, false, true, nil)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
        end
    end
end
function TurnOnVehicle:onRegisterExternalActionEvents(trigger, name, _, _)
    if name == "turnOn" then
        self:registerExternalActionEvent(trigger, name, TurnOnVehicle.externalActionEventRegister, TurnOnVehicle.externalActionEventUpdate)
    end
end
function TurnOnVehicle:onAlarmTriggerChanged(alarmTrigger, state)
    if state and alarmTrigger.turnOffInTrigger then
        self:setIsTurnedOn(false, true)
    end
end
function TurnOnVehicle:onSetBroken()
    self:setIsTurnedOn(false, true)
end
function TurnOnVehicle:onStateChange(state, _)
    if state == VehicleStateChange.MOTOR_TURN_OFF and not self:getCanBeTurnedOn() then
        self:setIsTurnedOn(false, true)
    end
end
function TurnOnVehicle:onDeactivate()
    if self.spec_turnOnVehicle.turnOffOnDeactivate then
        self:setIsTurnedOn(false, true)
    end
end
function TurnOnVehicle:onPostAttach(attacherVehicle, _, _)
    if self.spec_turnOnVehicle.turnedOnByAttacherVehicle and attacherVehicle.getIsTurnedOn ~= nil then
        self:setIsTurnedOn(attacherVehicle:getIsTurnedOn(), true)
    end
end
function TurnOnVehicle:onPreDetach(_, _)
    self:setIsTurnedOn(false, true)
end
function TurnOnVehicle:onRootVehicleChanged(rootVehicle)
    local actionController = rootVehicle.actionController
    if actionController == nil or not self:getCanToggleTurnedOn() then
        if self.spec_turnOnVehicle.controlledAction ~= nil then
            spec.controlledAction:remove()
        end
    else
        if spec.controlledAction ~= nil then
            spec.controlledAction:updateParent(actionController)
            return
        end
        spec.controlledAction = actionController:registerAction("turnOn", spec.toggleTurnOnInputBinding, 1)
        spec.controlledAction:setCallback(self, TurnOnVehicle.actionControllerTurnOnEvent)
        spec.controlledAction:setFinishedFunctions(self, self.getIsTurnedOn, true, false)
        spec.controlledAction:setIsSaved(true)
        spec.controlledAction:setIsAccessibleFunction(function()
            return true
        end)
        if self:getAIRequiresTurnOn() then
            if not self:getAIRequiresTurnOffOnHeadland() then
                spec.controlledAction:addAIEventListener(self, "onAIFieldWorkerPrepareForWork", 1, true)
                spec.controlledAction:addAIEventListener(self, "onAIImplementPrepareForWork", 1, true)
            end
            spec.controlledAction:addAIEventListener(self, "onAIImplementStartLine", 1, true)
            spec.controlledAction:addAIEventListener(self, "onAIImplementContinue", 1)
            spec.controlledAction:addAIEventListener(self, "onAIImplementEnd", -1)
            spec.controlledAction:addAIEventListener(self, "onAIImplementStart", -1)
            spec.controlledAction:addAIEventListener(self, "onAIFieldWorkerEnd", -1)
            if self:getAIRequiresTurnOffOnHeadland() then
                spec.controlledAction:addAIEventListener(self, "onAIImplementEndLine", -1)
            end
            spec.controlledAction:addAIEventListener(self, "onAIImplementBlock", -1)
            spec.controlledAction:addAIEventListener(self, "onAIImplementPrepareForTransport", -1)
            return
        end
    end
end
function TurnOnVehicle:actionControllerTurnOnEvent(direction)
    if direction <= 0 then
        self:setIsTurnedOn(false)
        return not self:getIsTurnedOn()
    end
    if not self:getCanBeTurnedOn() then
        return false
    end
    self:setIsTurnedOn(true)
    return true
end
function TurnOnVehicle:actionEventTurnOn(_, _, _, _)
    if self:getCanToggleTurnedOn() and self:getCanBeTurnedOn() then
        self:setIsTurnedOn(not self:getIsTurnedOn())
    elseif not self:getIsTurnedOn() then
        local warning = self:getTurnedOnNotAllowedWarning()
        if warning ~= nil then
            g_currentMission:showBlinkingWarning(warning, 2000)
        end
    end
end
function TurnOnVehicle:actionEventTurnOnAll(_, _, _, _)
    if self:getCanToggleTurnedOn() then
        local canBeTurnedOn, warning = self:getCanBeTurnedOnAll()
        if canBeTurnedOn then
            local vehicles = self.rootVehicle:getChildVehicles()
            local i = 1
            for i = i, #vehicles do
                local vehicle = vehicles[i]
                if vehicle.setIsTurnedOn ~= nil then
                    vehicle:setIsTurnedOn(not vehicle:getIsTurnedOn())
                end
            end
            return
        end
        if not self:getIsTurnedOn() and warning ~= nil then
            g_currentMission:showBlinkingWarning(warning, 2000)
        end
    end
end
function TurnOnVehicle:updateActionEvents()
    local spec = self.spec_turnOnVehicle
    local actionEvent = spec.actionEvents[spec.toggleTurnOnInputBinding]
    if actionEvent ~= nil then
        local state = self:getCanToggleTurnedOn()
        if state then
            local text
            if self:getIsTurnedOn() then
                text = spec.turnOffText
            else
                text = spec.turnOnText
            end
            g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
        end
        g_inputBinding:setActionEventActive(actionEvent.actionEventId, state)
    end
end
function TurnOnVehicle.externalActionEventRegister(data, vehicle)
    _, data.actionEventId = g_inputBinding:registerActionEvent(vehicle.spec_turnOnVehicle.toggleTurnOnInputBinding, data, function(_, actionName, inputValue, callbackState, isAnalog)
        -- upvalues: (copy) vehicle
        Motorized.tryStartMotor(vehicle)
        TurnOnVehicle.actionEventTurnOn(vehicle, actionName, inputValue, callbackState, isAnalog)
    end, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end
function TurnOnVehicle.externalActionEventUpdate(data, vehicle)
    if data.actionEventId ~= nil then
        local state = vehicle:getCanToggleTurnedOn()
        if state then
            local text
            if vehicle:getIsTurnedOn() then
                text = vehicle.spec_turnOnVehicle.turnOffText
            else
                text = vehicle.spec_turnOnVehicle.turnOnText
            end
            g_inputBinding:setActionEventText(data.actionEventId, text)
        end
        g_inputBinding:setActionEventActive(data.actionEventId, state)
    end
end
function TurnOnVehicle:getTurnedOnSpeedFactor()
    return self.spec_turnOnVehicle.turnedOnSpeed.alpha
end
g_soundManager:registerModifierType("TURNED_ON_SPEED", TurnOnVehicle.getTurnedOnSpeedFactor)
function TurnOnVehicle.dashboardRpmAttributes(_, xmlFile, key, dashboard, _)
    dashboard.minRpm = xmlFile:getValue(key .. "#minRpm", 0)
    dashboard.maxRpm = xmlFile:getValue(key .. "#maxRpm", 1000)
    return true
end
function TurnOnVehicle:dashboardRpmValue(dashboard)
    return dashboard.minRpm + (dashboard.maxRpm - dashboard.minRpm) * self.spec_turnOnVehicle.turnedOnSpeed.alpha
end