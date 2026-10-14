VehicleLowerImplementEvent = {}
local VehicleLowerImplementEvent_mt = Class(VehicleLowerImplementEvent, Event)
InitStaticEventClass(VehicleLowerImplementEvent, "VehicleLowerImplementEvent")
function VehicleLowerImplementEvent.emptyNew()
    -- upvalues: (copy) VehicleLowerImplementEvent_mt
    return Event.new(VehicleLowerImplementEvent_mt)
end
function VehicleLowerImplementEvent.new(vehicle, jointIndex, moveDown)
    local self = VehicleLowerImplementEvent.emptyNew()
    self.jointIndex = jointIndex
    self.vehicle = vehicle
    self.moveDown = moveDown
    return self
end
function VehicleLowerImplementEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.jointIndex = streamReadInt8(streamId)
    self.moveDown = streamReadBool(streamId)
    self:run(connection)
end
function VehicleLowerImplementEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteInt8(streamId, self.jointIndex)
    streamWriteBool(streamId, self.moveDown)
end
function VehicleLowerImplementEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setJointMoveDown(self.jointIndex, self.moveDown, true)
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(VehicleLowerImplementEvent.new(self.vehicle, self.jointIndex, self.moveDown), nil, connection, self.vehicle)
    end
end
function VehicleLowerImplementEvent.sendEvent(vehicle, jointIndex, moveDown, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(VehicleLowerImplementEvent.new(vehicle, jointIndex, moveDown), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(VehicleLowerImplementEvent.new(vehicle, jointIndex, moveDown))
    end
end