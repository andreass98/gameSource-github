VehicleSettingsChangeEvent = {}
local VehicleSettingsChangeEvent_mt = Class(VehicleSettingsChangeEvent, Event)
InitStaticEventClass(VehicleSettingsChangeEvent, "VehicleSettingsChangeEvent")
function VehicleSettingsChangeEvent.emptyNew()
    -- upvalues: (copy) VehicleSettingsChangeEvent_mt
    return Event.new(VehicleSettingsChangeEvent_mt)
end
function VehicleSettingsChangeEvent.new(vehicle, settings, _)
    local self = VehicleSettingsChangeEvent.emptyNew()
    self.vehicle = vehicle
    self.settings = settings
    return self
end
function VehicleSettingsChangeEvent.readStream(_, streamId, _)
    local vehicle = NetworkUtil.readNodeObject(streamId)
    local numSettings = streamReadUInt8(streamId)
    local isValid = false
    if vehicle ~= nil then
        isValid = vehicle:getIsSynchronized()
    end
    for i = 1, numSettings do
        local index = streamReadUInt8(streamId)
        local state
        if streamReadBool(streamId) then
            state = streamReadBool(streamId)
        else
            state = streamReadUInt8(streamId)
        end
        if isValid then
            vehicle:setVehicleSettingState(index, state, true)
        end
    end
end
function VehicleSettingsChangeEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    local numSettingsToSend = 0
    local i = 1
    for i = i, #self.settings do
        if self.settings[i].isDirty then
        end
    end
    streamWriteUInt8(streamId, numSettingsToSend)
    local i = 1
    for i = i, #self.settings do
        local setting = self.settings[i]
        if setting.isDirty then
            streamWriteUInt8(streamId, setting.index)
            if streamWriteBool(streamId, setting.isBool) then
                streamWriteBool(streamId, setting.state)
            else
                streamWriteUInt8(streamId, setting.state)
            end
            setting.isDirty = false
        end
    end
end
function VehicleSettingsChangeEvent:run(connection) end