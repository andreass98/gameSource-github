PrecisionFarmingSettingsInitialEvent = {}
local PrecisionFarmingSettingsInitialEvent_mt = Class(PrecisionFarmingSettingsInitialEvent, Event)
InitEventClass(PrecisionFarmingSettingsInitialEvent, "PrecisionFarmingSettingsInitialEvent")
function PrecisionFarmingSettingsInitialEvent.emptyNew()
    -- upvalues: (copy) PrecisionFarmingSettingsInitialEvent_mt
    return Event.new(PrecisionFarmingSettingsInitialEvent_mt)
end
function PrecisionFarmingSettingsInitialEvent.new(settings)
    local self = PrecisionFarmingSettingsInitialEvent.emptyNew()
    self.settings = settings
    return self
end
function PrecisionFarmingSettingsInitialEvent:readStream(streamId, connection)
    for _, setting in ipairs(g_precisionFarming.precisionFarmingSettings.settings) do
        if setting.isServerSetting then
            setting.state = streamReadBool(streamId)
        end
    end
    self:run(connection)
end
function PrecisionFarmingSettingsInitialEvent.writeStream(_, streamId, _)
    for _, setting in ipairs(g_precisionFarming.precisionFarmingSettings.settings) do
        if setting.isServerSetting then
            streamWriteBool(streamId, setting.state == true)
        end
    end
end
function PrecisionFarmingSettingsInitialEvent:run(connection)
    local precisionFarmingSettings = g_precisionFarming.precisionFarmingSettings
    for _, setting in ipairs(precisionFarmingSettings.settings) do
        if setting.isServerSetting then
            precisionFarmingSettings:onSettingChanged(setting, true)
        end
    end
end