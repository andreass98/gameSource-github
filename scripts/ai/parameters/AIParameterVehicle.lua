AIParameterVehicle = {}
local AIParameterVehicle_mt = Class(AIParameterVehicle, AIParameter)
function AIParameterVehicle.new(customMt)
    -- upvalues: (copy) AIParameterVehicle_mt
    local self = AIParameter.new(customMt or AIParameterVehicle_mt)
    self.type = AIParameterType.TEXT
    self.vehicleId = nil
    return self
end
function AIParameterVehicle:saveToXMLFile(xmlFile, key, _)
    local vehicle = self:getVehicle()
    if vehicle ~= nil then
        xmlFile:setString(key .. "#vehicleUniqueId", vehicle:getUniqueId())
    end
end
function AIParameterVehicle:readStream(streamId, _)
    if streamReadBool(streamId) then
        self.vehicleId = NetworkUtil.readNodeObjectId(streamId)
    end
end
function AIParameterVehicle:writeStream(streamId, _)
    if streamWriteBool(streamId, self.vehicleId ~= nil) then
        NetworkUtil.writeNodeObjectId(streamId, self.vehicleId)
    end
end
function AIParameterVehicle:getCanBeChanged()
    return false
end
function AIParameterVehicle:getString()
    local vehicle = NetworkUtil.getObject(self.vehicleId)
    return vehicle == nil and "" or vehicle:getName()
end
function AIParameterVehicle:setVehicle(vehicle)
    self.vehicleId = NetworkUtil.getObjectId(vehicle)
end
function AIParameterVehicle:getVehicle()
    local vehicle = NetworkUtil.getObject(self.vehicleId)
    if vehicle == nil or not vehicle:getIsSynchronized() then
        return nil
    else
        return vehicle
    end
end
function AIParameterVehicle:validate(needsAITarget)
    if self.vehicleId == nil then
        return false, g_i18n:getText("ai_validationErrorNoVehicle")
    else
        local vehicle = self:getVehicle()
        if vehicle == nil then
            return false, g_i18n:getText("ai_validationErrorVehicleDoesNotExistAnymore")
        elseif vehicle.setAITarget == nil and (needsAITarget == nil or needsAITarget == true) then
            return false, g_i18n:getText("ai_validationErrorVehicleDoesNotSupportAI")
        else
            return true, nil
        end
    end
end