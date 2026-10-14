AIAutomaticSteeringRequestEvent = {}
local AIAutomaticSteeringRequestEvent_mt = Class(AIAutomaticSteeringRequestEvent, Event)
InitStaticEventClass(AIAutomaticSteeringRequestEvent, "AIAutomaticSteeringRequestEvent")
function AIAutomaticSteeringRequestEvent.emptyNew()
    -- upvalues: (copy) AIAutomaticSteeringRequestEvent_mt
    return Event.new(AIAutomaticSteeringRequestEvent_mt)
end
function AIAutomaticSteeringRequestEvent.new(vehicle, x, z, fieldCourseSettings)
    local self = AIAutomaticSteeringRequestEvent.emptyNew()
    self.vehicle = vehicle
    self.x = x
    self.z = z
    self.fieldCourseSettings = fieldCourseSettings
    return self
end
function AIAutomaticSteeringRequestEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.x, self.z = g_fieldCourseManager:readTerrainDetailPixel(streamId)
    local attributes = FieldCourseSettings.readStream(streamId, connection)
    self.fieldCourseSettings = FieldCourseSettings.new(self.vehicle)
    self.fieldCourseSettings:applyAttributes(attributes)
    self:run(connection)
end
function AIAutomaticSteeringRequestEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    g_fieldCourseManager:writeTerrainDetailPixel(streamId, self.x, self.z)
    self.fieldCourseSettings:writeStream(streamId, connection)
end
function AIAutomaticSteeringRequestEvent:run(_)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:generateSteeringFieldCourse(self.x, self.z, self.fieldCourseSettings)
    end
end