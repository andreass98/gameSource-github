AIMessageErrorCouldNotPrepare = {}
local AIMessageErrorCouldNotPrepare_mt = Class(AIMessageErrorCouldNotPrepare, AIMessage)
function AIMessageErrorCouldNotPrepare.new(vehicle, customMt)
    -- upvalues: (copy) AIMessageErrorCouldNotPrepare_mt
    local self = AIMessage.new(customMt or AIMessageErrorCouldNotPrepare_mt)
    self.vehicle = vehicle
    return self
end
function AIMessageErrorCouldNotPrepare:getMessage(job)
    local i18nText = self:getI18NText()
    local vehicleName = ""
    if self.vehicle ~= nil then
        vehicleName = self.vehicle:getName()
    end
    local helperName = "Unknown"
    if job ~= nil then
        helperName = job:getHelperName() or helperName
    end
    return string.format(i18nText, helperName, vehicleName)
end
function AIMessageErrorCouldNotPrepare:getI18NText()
    return g_i18n:getText("ai_messageErrorCouldNotPrepare")
end
function AIMessageErrorCouldNotPrepare:readStream(streamId, _)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
end
function AIMessageErrorCouldNotPrepare:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
end