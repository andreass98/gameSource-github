AIAutomaticSteeringCourseEvent = {}
local AIAutomaticSteeringCourseEvent_mt = Class(AIAutomaticSteeringCourseEvent, Event)
InitStaticEventClass(AIAutomaticSteeringCourseEvent, "AIAutomaticSteeringCourseEvent")
function AIAutomaticSteeringCourseEvent.emptyNew()
    -- upvalues: (copy) AIAutomaticSteeringCourseEvent_mt
    return Event.new(AIAutomaticSteeringCourseEvent_mt)
end
function AIAutomaticSteeringCourseEvent.new(vehicle, steeringFieldCourse)
    local self = AIAutomaticSteeringCourseEvent.emptyNew()
    self.vehicle = vehicle
    self.steeringFieldCourse = steeringFieldCourse
    return self
end
function AIAutomaticSteeringCourseEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setAIAutomaticSteeringCourse(nil, true)
    end
    if streamReadBool(streamId) then
        SteeringFieldCourse.readStream(streamId, connection, function(steeringFieldCourse)
            -- upvalues: (copy) self
            if steeringFieldCourse ~= nil and (self.vehicle ~= nil and self.vehicle:getIsSynchronized()) then
                self.vehicle:setAIAutomaticSteeringCourse(steeringFieldCourse, true)
            end
        end)
    end
end
function AIAutomaticSteeringCourseEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    if streamWriteBool(streamId, self.steeringFieldCourse ~= nil) then
        self.steeringFieldCourse:writeStream(streamId, connection)
    end
end
function AIAutomaticSteeringCourseEvent:run(connection) end