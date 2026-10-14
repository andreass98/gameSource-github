HUDInfoTrigger = {}
function HUDInfoTrigger.prerequisitesPresent(specializations)
    return true
end
function HUDInfoTrigger.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("HUDInfoTrigger")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.hudInfoTrigger#triggerNode", "Player or vehicle trigger node")
    schema:setXMLSpecializationType()
end
function HUDInfoTrigger.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getIsPlayerInHudInfoTrigger", HUDInfoTrigger.getIsPlayerInHudInfoTrigger)
    SpecializationUtil.registerFunction(vehicleType, "getAllowHudInfoTrigger", HUDInfoTrigger.getAllowHudInfoTrigger)
end
function HUDInfoTrigger.registerOverwrittenFunctions(vehicleType) end
function HUDInfoTrigger.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", HUDInfoTrigger)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", HUDInfoTrigger)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", HUDInfoTrigger)
end
function HUDInfoTrigger:onLoad(_)
    local spec = self.spec_hudInfoTrigger
    spec.triggerNode = self.xmlFile:getValue("vehicle.hudInfoTrigger#triggerNode", nil, self.components, self.i3dMappings)
    if spec.triggerNode == nil then
        SpecializationUtil.removeEventListener(self, "onDelete", HUDInfoTrigger)
        SpecializationUtil.removeEventListener(self, "onUpdate", HUDInfoTrigger)
    else
        spec.callbackId = addTrigger(spec.triggerNode, "onHudInfoTriggerCallback", self, false, HUDInfoTrigger.onHudInfoTriggerCallback)
        spec.enteredObjects = {}
    end
end
function HUDInfoTrigger:onDelete()
    local spec = self.spec_hudInfoTrigger
    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode, spec.callbackId)
    end
end
function HUDInfoTrigger:onUpdate(_, _, isActiveForInputIgnoreSelection, _)
    if not isActiveForInputIgnoreSelection and self:getIsPlayerInHudInfoTrigger() then
        self.rootVehicle:draw()
        self:raiseActive()
    end
end
function HUDInfoTrigger:onHudInfoTriggerCallback(_, otherId, onEnter, onLeave, _)
    local object = g_currentMission:getNodeObject(otherId)
    if object == nil and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
        object = g_localPlayer
    end
    if object ~= nil and object ~= self then
        local objectId = NetworkUtil.getObjectId(object)
        if objectId ~= nil then
            if onEnter then
                self.spec_hudInfoTrigger.enteredObjects[objectId] = (self.spec_hudInfoTrigger.enteredObjects[objectId] or 0) + 1
                self:raiseActive()
                return
            end
            if onLeave then
                spec.enteredObjects[objectId] = (spec.enteredObjects[objectId] or 0) - 1
                if spec.enteredObjects[objectId] <= 0 then
                    spec.enteredObjects[objectId] = nil
                end
            end
        end
    end
end
function HUDInfoTrigger:getAllowHudInfoTrigger()
    return true
end
function HUDInfoTrigger:getIsPlayerInHudInfoTrigger()
    if not self:getAllowHudInfoTrigger() then
        return false
    end
    local localPlayer = g_localPlayer
    if localPlayer == nil then
        return false
    end
    if not localPlayer:getIsInVehicle() then
        local objectId = NetworkUtil.getObjectId(g_localPlayer)
        return self.spec_hudInfoTrigger.enteredObjects[objectId] ~= nil
    end
    local objectId = localPlayer:getCurrentVehicle()
    if objectId == nil then
        return false
    end
    local childVehicles = objectId.childVehicles
    for _, vehicle in ipairs(childVehicles) do
        local objectId = NetworkUtil.getObjectId(vehicle)
        if spec.enteredObjects[objectId] ~= nil then
            return true
        end
    end
    return false
end