WeatherAddObjectEvent = {}
local WeatherInitEvent_mt = Class(WeatherAddObjectEvent, Event)
InitStaticEventClass(WeatherAddObjectEvent, "WeatherAddObjectEvent")
function WeatherAddObjectEvent.emptyNew(networkChannel)
    -- upvalues: (copy) WeatherInitEvent_mt
    return Event.new(WeatherInitEvent_mt, networkChannel)
end
function WeatherAddObjectEvent.new(instances, isInitialSync, finishTwister)
    local networkChannel = nil
    if isInitialSync then
        networkChannel = NetworkNode.CHANNEL_MAIN
    end
    local self = WeatherAddObjectEvent.emptyNew(networkChannel)
    self.instances = instances
    self.isInitialSync = isInitialSync
    self.finishTwister = Utils.getNoNil(finishTwister, false)
    return self
end
function WeatherAddObjectEvent:readStream(streamId, connection)
    self.instances = {}
    self.isInitialSync = streamReadBool(streamId)
    self.finishTwister = streamReadBool(streamId)
    local numStates = streamReadUIntN(streamId, Weather.SEND_BITS_NUM_OBJECTS)
    local twisterId = 1
    for _ = 1, numStates, twisterId do
        local instance = WeatherInstance.new()
        instance:readStream(streamId)
        table.insert(self.instances, instance)
    end
    if self.finishTwister then
        local twister = g_currentMission.environment.weather.twister
        if twister ~= nil then
            local twisterId = NetworkUtil.readNodeObjectId(streamId)
            twister:readStream(streamId, connection)
            g_client:finishRegisterObject(twister, twisterId)
        end
    end
    self:run(connection)
end
function WeatherAddObjectEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.isInitialSync)
    streamWriteBool(streamId, self.finishTwister)
    streamWriteUIntN(streamId, #self.instances, Weather.SEND_BITS_NUM_OBJECTS)
    for _, instance in ipairs(self.instances) do
        instance:writeStream(streamId, connection)
    end
    if self.finishTwister then
        local twister = g_currentMission.environment.weather.twister
        if twister ~= nil then
            NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(twister))
            twister:writeStream(streamId, connection)
            g_server:registerObjectInStream(connection, twister)
        end
    end
end
function WeatherAddObjectEvent:run(_)
    if self.isInitialSync then
        g_currentMission.environment.weather.forecastItems = {}
    end
    for _, instance in ipairs(self.instances) do
        weather:addWeatherForecast(instance)
    end
    if self.isInitialSync then
        weather:init()
    end
end