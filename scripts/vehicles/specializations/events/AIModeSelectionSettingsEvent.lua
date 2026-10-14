AIModeSelectionSettingsEvent = {}
local AIModeSelectionSettingsEvent_mt = Class(AIModeSelectionSettingsEvent, Event)
InitStaticEventClass(AIModeSelectionSettingsEvent, "AIModeSelectionSettingsEvent")
function AIModeSelectionSettingsEvent.emptyNew()
    -- upvalues: (copy) AIModeSelectionSettingsEvent_mt
    return Event.new(AIModeSelectionSettingsEvent_mt)
end
function AIModeSelectionSettingsEvent.new(vehicle, fieldCourseSettings)
    local self = AIModeSelectionSettingsEvent.emptyNew()
    self.vehicle = vehicle
    self.fieldCourseSettings = fieldCourseSettings
    return self
end
function AIModeSelectionSettingsEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    local attributes = FieldCourseSettings.readStream(streamId, connection)
    self.fieldCourseSettings = FieldCourseSettings.new(self.vehicle)
    self.fieldCourseSettings:applyAttributes(attributes)
    self:run(connection)
end
function AIModeSelectionSettingsEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    self.fieldCourseSettings:writeStream(streamId, connection)
end
function AIModeSelectionSettingsEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setAIModeFieldCourseSettings(self.fieldCourseSettings)
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(AIModeSelectionSettingsEvent.new(self.vehicle, self.fieldCourseSettings), nil, connection, self.vehicle)
    end
end
function AIModeSelectionSettingsEvent.sendEvent(vehicle, fieldCourseSettings, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(AIModeSelectionSettingsEvent.new(vehicle, fieldCourseSettings), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(AIModeSelectionSettingsEvent.new(vehicle, fieldCourseSettings))
    end
end