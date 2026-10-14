CraneShovel = {}
source("dataS/scripts/vehicles/specializations/events/CraneShovelEvent.lua")
function CraneShovel.prerequisitesPresent(specializations)
    return true
end
function CraneShovel.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("CraneShovel")
    schema:addDelayedRegistrationPath("vehicle.craneShovel", "CraneShovel")
    schema:register(XMLValueType.STRING, "vehicle.craneShovel#inputAction", "Input action name to open and close the shovel")
    schema:register(XMLValueType.STRING, "vehicle.craneShovel#animationName", "Name of the animation")
    schema:register(XMLValueType.FLOAT, "vehicle.craneShovel#animationSpeed", "Speed of animation", 1)
    schema:register(XMLValueType.BOOL, "vehicle.craneShovel#isDefaultOpen", "Shovel is open by default", false)
    schema:register(XMLValueType.BOOL, "vehicle.craneShovel#closeWhileFolding", "Close shovel while folding", false)
    schema:register(XMLValueType.INT, "vehicle.craneShovel#fillUnitIndex", "Index of fill unit", 1)
    schema:register(XMLValueType.INT, "vehicle.craneShovel#dischargeNodeIndex", "Index of discharge node", 1)
    schema:register(XMLValueType.L10N_STRING, "vehicle.craneShovel.texts#open", "Text for opening", "$l10n_action_craneShovelOpen")
    schema:register(XMLValueType.L10N_STRING, "vehicle.craneShovel.texts#close", "Text for closing", "$l10n_action_craneShovelClose")
    schema:setXMLSpecializationType()
    Vehicle.xmlSchemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).craneShovel#state", "Shovel open/close state", false)
end
function CraneShovel.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadCraneShovelFromXML", CraneShovel.loadCraneShovelFromXML)
    SpecializationUtil.registerFunction(vehicleType, "setCraneShovelState", CraneShovel.setCraneShovelState)
    SpecializationUtil.registerFunction(vehicleType, "getCraneShovelStateChangedAllowed", CraneShovel.getCraneShovelStateChangedAllowed)
end
function CraneShovel.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDischargeNodeActive", CraneShovel.getIsDischargeNodeActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShovelNodeIsActive", CraneShovel.getShovelNodeIsActive)
end
function CraneShovel.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", CraneShovel)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", CraneShovel)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", CraneShovel)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", CraneShovel)
    SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", CraneShovel)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", CraneShovel)
end
function CraneShovel:onLoad(_)
    local spec = self.spec_craneShovel
    if self:loadCraneShovelFromXML(spec, self.xmlFile, "vehicle.craneShovel") then
        spec.state = spec.isDefaultOpen
        if not (self.isServer and spec.closeWhileFolding) then
            SpecializationUtil.removeEventListener(self, "onFoldStateChanged", CraneShovel)
            return
        end
    else
        SpecializationUtil.removeEventListener(self, "onPostLoad", CraneShovel)
        SpecializationUtil.removeEventListener(self, "onReadStream", CraneShovel)
        SpecializationUtil.removeEventListener(self, "onWriteStream", CraneShovel)
        SpecializationUtil.removeEventListener(self, "onFoldStateChanged", CraneShovel)
        SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", CraneShovel)
    end
end
function CraneShovel:onPostLoad(savegame)
    local spec = self.spec_craneShovel
    local state = spec.state
    if savegame ~= nil and not savegame.resetVehicles then
        state = savegame.xmlFile:getValue(savegame.key .. ".craneShovel#state", state)
    end
    spec.state = nil
    self:setCraneShovelState(state, true, true)
end
function CraneShovel:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_craneShovel
    if spec.animationName ~= nil then
        xmlFile:setValue(key .. "#state", spec.state)
    end
end
function CraneShovel:onReadStream(streamId, _)
    self:setCraneShovelState(streamReadBool(streamId), true, true)
end
function CraneShovel:onWriteStream(streamId, _)
    streamWriteBool(streamId, self.spec_craneShovel.state)
end
function CraneShovel:onFoldStateChanged(direction, _)
    if direction ~= self.spec_foldable.turnOnFoldDirection then
        local spec = self.spec_craneShovel
        if spec.animationName ~= nil and spec.state then
            self:setCraneShovelState(false)
        end
    end
end
function CraneShovel:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    local spec = self.spec_craneShovel
    self:clearActionEventsTable(spec.actionEvents)
    if isActiveForInputIgnoreSelection then
        local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, spec.inputAction, self, CraneShovel.actionEvent, true, false, false, true, nil)
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
        CraneShovel.updateActionEvents(self)
    end
end
function CraneShovel:actionEvent(_, _, _, _)
    local isAllowed, warning = self:getCraneShovelStateChangedAllowed(self.spec_craneShovel)
    if isAllowed then
        self:setCraneShovelState(not self.spec_craneShovel.state)
    elseif warning ~= nil then
        g_currentMission:showBlinkingWarning(warning, 5000)
    end
end
function CraneShovel:updateActionEvents()
    local spec = self.spec_craneShovel
    local actionEvent = spec.actionEvents[spec.inputAction]
    if actionEvent ~= nil then
        g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.state and spec.texts.close or spec.texts.open)
    end
end
function CraneShovel:loadCraneShovelFromXML(spec, xmlFile, key)
    spec.animationName = xmlFile:getValue(key .. "#animationName")
    if spec.animationName == nil then
        return false
    end
    local inputActionName = xmlFile:getValue(key .. "#inputAction")
    spec.inputAction = InputAction[inputActionName]
    spec.animationSpeed = xmlFile:getValue(key .. "#animationSpeed", 1)
    spec.isDefaultOpen = xmlFile:getValue(key .. "#isDefaultOpen", false)
    spec.closeWhileFolding = xmlFile:getValue(key .. "#closeWhileFolding", false)
    spec.fillUnitIndex = xmlFile:getValue(key .. "#fillUnitIndex", 1)
    spec.dischargeNodeIndex = xmlFile:getValue(key .. "#dischargeNodeIndex", 1)
    spec.texts = {}
    spec.texts.open = xmlFile:getValue(key .. ".texts#open", "action_craneShovelOpen", self.customEnvironment)
    spec.texts.close = xmlFile:getValue(key .. ".texts#close", "action_craneShovelClose", self.customEnvironment)
    return true
end
function CraneShovel:setCraneShovelState(state, skipAnimation, noEventSend)
    local spec = self.spec_craneShovel
    if spec.state ~= state then
        spec.state = state
        local currentTime = self:getAnimationTime(spec.animationName)
        self:stopAnimation(spec.animationName, true)
        self:playAnimation(spec.animationName, (state and 1 or -1) * spec.animationSpeed, currentTime, true)
        if skipAnimation then
            AnimatedVehicle.updateAnimationByName(self, spec.animationName, 9999999, true)
        end
        if self.isClient and spec.inputAction ~= nil then
            CraneShovel.updateActionEvents(self)
        end
    end
    CraneShovelEvent.sendEvent(self, spec.state, noEventSend)
end
function CraneShovel:getCraneShovelStateChangedAllowed(spec)
    return true, nil
end
function CraneShovel:getIsDischargeNodeActive(superFunc, dischargeNode)
    local spec = self.spec_craneShovel
    if spec.animationName == nil or (spec.dischargeNodeIndex == nil or (dischargeNode.index ~= spec.dischargeNodeIndex or spec.state)) then
        return superFunc(self, dischargeNode)
    else
        return false
    end
end
function CraneShovel:getShovelNodeIsActive(superFunc, shovelNode)
    local spec = self.spec_craneShovel
    if spec.animationName == nil then
        ::l2::
        return superFunc(self, shovelNode)
    else
        if self:getIsAnimationPlaying(spec.animationName) then
            if math.sign((self:getAnimationSpeed(spec.animationName))) ~= 1 then
                goto l2
            end
        end
        return false
    end
end