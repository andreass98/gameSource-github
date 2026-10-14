ExternalVehicleControl = {}
ExternalVehicleControl.FUNCTION_XML_PATH = "vehicle.externalVehicleControl.trigger(?).function(?)"
function ExternalVehicleControl.prerequisitesPresent(specializations)
    return true
end
function ExternalVehicleControl.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ExternalVehicleControl")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.externalVehicleControl.trigger(?)#node", "Player trigger node")
    schema:addDelayedRegistrationPath(ExternalVehicleControl.FUNCTION_XML_PATH, "ExternalVehicleControl:function")
    schema:register(XMLValueType.STRING, ExternalVehicleControl.FUNCTION_XML_PATH .. "#name", "Name of the function to be available")
    schema:setXMLSpecializationType()
end
function ExternalVehicleControl.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onRegisterExternalActionEvents")
end
function ExternalVehicleControl.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "registerExternalActionEvent", ExternalVehicleControl.registerExternalActionEvent)
end
function ExternalVehicleControl.registerOverwrittenFunctions(vehicleType) end
function ExternalVehicleControl.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", ExternalVehicleControl)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", ExternalVehicleControl)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ExternalVehicleControl)
end
function ExternalVehicleControl:onLoadFinished(_)
    local spec = self.spec_externalVehicleControl
    spec.triggers = {}
    for _, key in self.xmlFile:iterator("vehicle.externalVehicleControl.trigger") do
        local trigger = {
            ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        }
        if trigger.node ~= nil then
            if not CollisionFlag.getHasMaskFlagSet(trigger.node, CollisionFlag.PLAYER) then
                Logging.xmlWarning(self.xmlFile, "Invalid collision mask flags set in \'%s\'. Player bit missing!", key)
            end
            trigger.vehicle = self
            trigger.isPlayerInRange = false
            trigger.controlFunctions = {}
            trigger.callbackId = addTrigger(trigger.node, "onExternalVehicleControlTriggerCallback", trigger, false, ExternalVehicleControl.onExternalVehicleControlTriggerCallback)
            for _, funcKey in self.xmlFile:iterator(key .. ".function") do
                local name = self.xmlFile:getValue(funcKey .. "#name")
                if name ~= nil then
                    SpecializationUtil.raiseEvent(self, "onRegisterExternalActionEvents", trigger, name, self.xmlFile, funcKey)
                end
            end
            trigger.activatable = ExternalVehicleControlActivatable.new(self, trigger)
            table.insert(spec.triggers, trigger)
        end
    end
    if #spec.triggers == 0 then
        SpecializationUtil.removeEventListener(self, "onDelete", ExternalVehicleControl)
        SpecializationUtil.removeEventListener(self, "onUpdateTick", ExternalVehicleControl)
    end
end
function ExternalVehicleControl:onDelete()
    local spec = self.spec_externalVehicleControl
    if spec.triggers ~= nil then
        for _, trigger in ipairs(spec.triggers) do
            if trigger.node ~= nil then
                removeTrigger(trigger.node, trigger.callbackId)
            end
            g_currentMission.activatableObjectsSystem:removeActivatable(trigger.activatable)
        end
    end
end
function ExternalVehicleControl:onUpdateTick(_, _, _, _)
    for _, trigger in ipairs(self.spec_externalVehicleControl.triggers) do
        if trigger.isPlayerInRange then
            trigger.activatable:updateText()
            self:raiseActive()
        end
    end
end
function ExternalVehicleControl.registerExternalActionEvent(_, trigger, _, registerFunc, updateFunc)
    local controlFunction = {
        ["registerFunc"] = registerFunc,
        ["updateFunc"] = updateFunc
    }
    table.insert(trigger.controlFunctions, controlFunction)
    return controlFunction
end
function ExternalVehicleControl.onExternalVehicleControlTriggerCallback(trigger, _, otherId, onEnter, _, _)
    if g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
        if onEnter then
            trigger.isPlayerInRange = true
            trigger.vehicle:raiseActive()
            trigger.activatable:updateText()
            g_currentMission.activatableObjectsSystem:addActivatable(trigger.activatable)
            return
        end
        trigger.isPlayerInRange = false
        g_currentMission.activatableObjectsSystem:removeActivatable(trigger.activatable)
    end
end
ExternalVehicleControlActivatable = {}
local ExternalVehicleControlActivatable_mt = Class(ExternalVehicleControlActivatable)
function ExternalVehicleControlActivatable.new(vehicle, trigger)
    -- upvalues: (copy) ExternalVehicleControlActivatable_mt
    local self = setmetatable({}, ExternalVehicleControlActivatable_mt)
    self.vehicle = vehicle
    self.trigger = trigger
    self.activateText = ""
    self:updateText()
    return self
end
function ExternalVehicleControlActivatable:registerCustomInput(inputContext)
    if inputContext == PlayerInputComponent.INPUT_CONTEXT_NAME then
        for i, controlFunction in ipairs(self.trigger.controlFunctions) do
            if controlFunction.registerFunc ~= nil then
                controlFunction:registerFunc(self.vehicle)
            end
        end
    end
end
function ExternalVehicleControlActivatable:removeCustomInput(_)
    for i, controlFunction in ipairs(self.trigger.controlFunctions) do
        g_inputBinding:removeActionEventsByTarget(controlFunction)
    end
end
function ExternalVehicleControlActivatable:getIsActivatable()
    if g_currentMission.accessHandler:canPlayerAccess(self.vehicle) then
        return self.trigger.isPlayerInRange
    else
        return false
    end
end
function ExternalVehicleControlActivatable:run() end
function ExternalVehicleControlActivatable:getDistance(x, y, z)
    local tx, ty, tz = getWorldTranslation(self.trigger.node)
    return MathUtil.vector3Length(x - tx, y - ty, z - tz)
end
function ExternalVehicleControlActivatable:updateText()
    for i, controlFunction in ipairs(self.trigger.controlFunctions) do
        if controlFunction.updateFunc ~= nil then
            controlFunction:updateFunc(self.vehicle)
        end
    end
end