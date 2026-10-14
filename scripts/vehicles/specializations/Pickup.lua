source("dataS/scripts/vehicles/specializations/events/PickupSetStateEvent.lua")
Pickup = {}
Pickup.PICKUP_XML_KEY = "vehicle.pickup"
function Pickup.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end
function Pickup.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Pickup")
    schema:register(XMLValueType.STRING, Pickup.PICKUP_XML_KEY .. ".animation#name", "Pickup animation name")
    schema:register(XMLValueType.FLOAT, Pickup.PICKUP_XML_KEY .. ".animation#lowerSpeed", "Pickup animation lower speed")
    schema:register(XMLValueType.FLOAT, Pickup.PICKUP_XML_KEY .. ".animation#liftSpeed", "Pickup animation lift speed")
    schema:register(XMLValueType.BOOL, Pickup.PICKUP_XML_KEY .. ".animation#isDefaultLowered", "Pickup animation is default lowered")
    schema:setXMLSpecializationType()
end
function Pickup.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "allowPickingUp", Pickup.allowPickingUp)
    SpecializationUtil.registerFunction(vehicleType, "setPickupState", Pickup.setPickupState)
    SpecializationUtil.registerFunction(vehicleType, "loadPickupFromXML", Pickup.loadPickupFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getCanChangePickupState", Pickup.getCanChangePickupState)
end
function Pickup.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLowered", Pickup.getIsLowered)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Pickup.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Pickup.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerLoweringActionEvent", Pickup.registerLoweringActionEvent)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerSelfLoweringActionEvent", Pickup.registerSelfLoweringActionEvent)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToGround", Pickup.getCanDischargeToGround)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToObject", Pickup.getCanDischargeToObject)
end
function Pickup.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Pickup)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Pickup)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Pickup)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Pickup)
    SpecializationUtil.registerEventListener(vehicleType, "onSetLoweredAll", Pickup)
    SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", Pickup)
    SpecializationUtil.registerEventListener(vehicleType, "onFoldTimeChanged", Pickup)
end
function Pickup:onLoad(_)
    self:loadPickupFromXML(self.xmlFile, "vehicle.pickup", self.spec_pickup)
end
function Pickup:onPostLoad(_)
    local spec = self.spec_pickup
    if spec.animationName ~= "" then
        local dir = -20
        if spec.animationIsDefaultLowered then
            dir = 20
            spec.isLowered = true
        end
        self:playAnimation(spec.animationName, dir, nil, true)
        AnimatedVehicle.updateAnimations(self, 99999999, true)
    end
end
function Pickup:onReadStream(streamId, _)
    self:setPickupState(streamReadBool(streamId), true)
end
function Pickup:onWriteStream(streamId, _)
    streamWriteBool(streamId, self.spec_pickup.isLowered)
end
function Pickup:onSetLoweredAll(doLowering, _)
    self:setPickupState(doLowering)
end
function Pickup:onRootVehicleChanged(rootVehicle)
    local spec = self.spec_pickup
    if spec.animationName ~= "" then
        local actionController = rootVehicle.actionController
        if actionController == nil then
            if spec.controlledAction ~= nil then
                spec.controlledAction:remove()
            end
        else
            if spec.controlledAction ~= nil then
                spec.controlledAction:updateParent(actionController)
                return
            end
            spec.controlledAction = actionController:registerAction("lowerPickup", InputAction.LOWER_IMPLEMENT, 2)
            spec.controlledAction:setCallback(self, Pickup.actionControllerLowerPickupEvent)
            spec.controlledAction:setFinishedFunctions(self, self.getIsLowered, true, false)
            spec.controlledAction:setIsSaved(true)
            if self:getAINeedsLowering() then
                spec.controlledAction:addAIEventListener(self, "onAIImplementStartLine", 1)
                spec.controlledAction:addAIEventListener(self, "onAIImplementEndLine", -1)
                spec.controlledAction:addAIEventListener(self, "onAIImplementStart", -1)
                return
            end
        end
    end
end
function Pickup:onFoldTimeChanged(_)
    Pickup.updateActionEvents(self)
end
function Pickup:actionControllerLowerPickupEvent(direction)
    self:setPickupState(direction > 0)
    return true
end
function Pickup:setPickupState(isPickupLowered, noEventSend)
    local spec = self.spec_pickup
    if isPickupLowered ~= spec.isLowered then
        PickupSetStateEvent.sendEvent(self, isPickupLowered, noEventSend)
        spec.isLowered = isPickupLowered
        if spec.animationName ~= "" then
            local animTime = nil
            if self:getIsAnimationPlaying(spec.animationName) then
                animTime = self:getAnimationTime(spec.animationName)
            end
            if isPickupLowered then
                self:playAnimation(spec.animationName, spec.animationLowerSpeed, animTime, true)
            else
                self:playAnimation(spec.animationName, spec.animationLiftSpeed, animTime, true)
            end
        end
        Pickup.updateActionEvents(self)
    end
end
function Pickup:allowPickingUp()
    return self.spec_pickup.isLowered
end
function Pickup:getIsLowered(_, _)
    return self.spec_pickup.isLowered
end
function Pickup:loadPickupFromXML(xmlFile, key, spec)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, "vehicle.pickupAnimation", key .. ".animation")
    spec.isLowered = false
    spec.animationName = xmlFile:getValue(key .. ".animation#name", "")
    if not self:getAnimationExists(spec.animationName) then
        spec.animationName = ""
        spec.isLowered = true
    end
    spec.animationLowerSpeed = xmlFile:getValue(key .. ".animation#lowerSpeed", 1)
    spec.animationLiftSpeed = xmlFile:getValue(key .. ".animation#liftSpeed", -spec.animationLowerSpeed)
    spec.animationIsDefaultLowered = xmlFile:getValue(key .. ".animation#isDefaultLowered", false)
    return true
end
function Pickup:getCanChangePickupState(spec, newState)
    return true
end
function Pickup:getDirtMultiplier(superFunc)
    if self.spec_pickup.isLowered and (self.getIsTurnedOn == nil or self:getIsTurnedOn()) then
        return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
    else
        return superFunc(self)
    end
end
function Pickup:getWearMultiplier(superFunc)
    if self.spec_pickup.isLowered and (self.getIsTurnedOn == nil or self:getIsTurnedOn()) then
        return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
    else
        return superFunc(self)
    end
end
function Pickup:registerLoweringActionEvent(superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
    local spec = self.spec_pickup
    if spec.animationName ~= "" then
        local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.LOWER_IMPLEMENT, self, Pickup.actionEventTogglePickup, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
        Pickup.updateActionEvents(self)
        if inputAction == InputAction.LOWER_IMPLEMENT then
            return
        end
    end
    superFunc(self, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
end
function Pickup:registerSelfLoweringActionEvent(superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
    return Pickup.registerLoweringActionEvent(self, superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
end
function Pickup:getCanDischargeToGround(superFunc, dischargeNode)
    if self.spec_pickup.allowWhileTipping or not self.spec_pickup.isLowered then
        return superFunc(self, dischargeNode)
    else
        return false
    end
end
function Pickup:getCanDischargeToObject(superFunc, dischargeNode)
    if self.spec_pickup.allowWhileTipping or not self.spec_pickup.isLowered then
        return superFunc(self, dischargeNode)
    else
        return false
    end
end
function Pickup:updateActionEvents()
    local spec = self.spec_pickup
    if spec.animationName ~= "" then
        local actionEvent = spec.actionEvents[InputAction.LOWER_IMPLEMENT]
        if actionEvent ~= nil then
            if spec.isLowered then
                g_inputBinding:setActionEventText(actionEvent.actionEventId, string.format(g_i18n:getText("action_liftOBJECT"), g_i18n:getText("typeDesc_pickup")))
            else
                g_inputBinding:setActionEventText(actionEvent.actionEventId, string.format(g_i18n:getText("action_lowerOBJECT"), g_i18n:getText("typeDesc_pickup")))
            end
            g_inputBinding:setActionEventActive(actionEvent.actionEventId, self:getCanChangePickupState(spec, not spec.isLowered))
        end
    end
end
function Pickup:actionEventTogglePickup(_, _, _, _)
    local spec = self.spec_pickup
    if self:getCanChangePickupState(spec, not spec.isLowered) then
        self:setPickupState(not spec.isLowered)
    end
end