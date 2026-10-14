PrecisionFarmingSettingsEvent = {}
local PrecisionFarmingSettingsEvent_mt = Class(PrecisionFarmingSettingsEvent, Event)
InitEventClass(PrecisionFarmingSettingsEvent, "PrecisionFarmingSettingsEvent")
function PrecisionFarmingSettingsEvent.emptyNew()
    -- upvalues: (copy) PrecisionFarmingSettingsEvent_mt
    return Event.new(PrecisionFarmingSettingsEvent_mt)
end
function PrecisionFarmingSettingsEvent.new(setting)
    local self = PrecisionFarmingSettingsEvent.emptyNew()
    self.setting = setting
    return self
end
function PrecisionFarmingSettingsEvent:readStream(streamId, connection)
    local precisionFarmingSettings = g_precisionFarming.precisionFarmingSettings
    local index = streamReadUIntN(streamId, precisionFarmingSettings.settingIndexNumBits)
    local state = streamReadBool(streamId)
    self.setting = precisionFarmingSettings.settings[index]
    self.setting.state = state
    self:run(connection)
end
function PrecisionFarmingSettingsEvent:writeStream(streamId, _)
    streamWriteUIntN(streamId, self.setting.index, g_precisionFarming.precisionFarmingSettings.settingIndexNumBits)
    streamWriteBool(streamId, self.setting.state == true)
end
function PrecisionFarmingSettingsEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, nil)
    end
    g_precisionFarming.precisionFarmingSettings:onSettingChanged(self.setting, true)
end
function PrecisionFarmingSettingsEvent.sendEvent(setting, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PrecisionFarmingSettingsEvent.new(setting), nil, nil, nil)
            return
        end
        g_client:getServerConnection():sendEvent(PrecisionFarmingSettingsEvent.new(setting))
    end
end