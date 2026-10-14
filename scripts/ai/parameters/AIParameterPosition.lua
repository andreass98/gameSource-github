AIParameterPosition = {}
local AIParameterPosition_mt = Class(AIParameterPosition, AIParameter)
function AIParameterPosition.new(customMt)
    -- upvalues: (copy) AIParameterPosition_mt
    local self = AIParameter.new(customMt or AIParameterPosition_mt)
    self.type = AIParameterType.POSITION
    self.x = nil
    self.z = nil
    return self
end
function AIParameterPosition:saveToXMLFile(xmlFile, key, _)
    if self.x ~= nil then
        xmlFile:setFloat(key .. "#x", self.x)
        xmlFile:setFloat(key .. "#z", self.z)
    end
end
function AIParameterPosition:loadFromXMLFile(xmlFile, key)
    self.x = xmlFile:getFloat(key .. "#x", self.x)
    self.z = xmlFile:getFloat(key .. "#z", self.z)
end
function AIParameterPosition:readStream(streamId, _)
    if streamReadBool(streamId) then
        self:setPosition(streamReadFloat32(streamId), (streamReadFloat32(streamId)))
    end
end
function AIParameterPosition:writeStream(streamId, _)
    if streamWriteBool(streamId, self.x ~= nil) then
        streamWriteFloat32(streamId, self.x)
        streamWriteFloat32(streamId, self.z)
    end
end
function AIParameterPosition:setPosition(x, z)
    self.x = x
    self.z = z
end
function AIParameterPosition:getPosition()
    return self.x, self.z
end
function AIParameterPosition:getString()
    return string.format("< %.1f , %.1f >", self.x, self.z)
end
function AIParameterPosition:validate()
    if self.x == nil or self.z == nil then
        return false, g_i18n:getText("ai_validationErrorNoPosition")
    elseif g_currentMission.aiSystem:getIsPositionReachable(self.x, 0, self.z) then
        return true, nil
    else
        return false, g_i18n:getText("ai_validationErrorBlockedPosition")
    end
end