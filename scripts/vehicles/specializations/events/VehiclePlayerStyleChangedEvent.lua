VehiclePlayerStyleChangedEvent = {}
local VehiclePlayerStyleChangedEvent_mt = Class(VehiclePlayerStyleChangedEvent, Event)
InitStaticEventClass(VehiclePlayerStyleChangedEvent, "VehiclePlayerStyleChangedEvent")
function VehiclePlayerStyleChangedEvent.emptyNew()
    -- upvalues: (copy) VehiclePlayerStyleChangedEvent_mt
    return Event.new(VehiclePlayerStyleChangedEvent_mt)
end
function VehiclePlayerStyleChangedEvent.new(vehicle, playerStyle)
    local self = VehiclePlayerStyleChangedEvent.emptyNew()
    self.vehicle = vehicle
    self.playerStyle = playerStyle
    return self
end
function VehiclePlayerStyleChangedEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.playerStyle = PlayerStyle.new()
    self.playerStyle:readStream(streamId, connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setVehicleCharacter(self.playerStyle)
    end
end
function VehiclePlayerStyleChangedEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    self.playerStyle:writeStream(streamId, connection)
end
function VehiclePlayerStyleChangedEvent:run(connection) end