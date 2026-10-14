ResetVehicleEvent = {}
ResetVehicleEvent.STATE_SUCCESS = 0
ResetVehicleEvent.STATE_FAILED = 1
ResetVehicleEvent.STATE_NO_PERMISSION = 2
ResetVehicleEvent.STATE_IN_USE = 3
local ResetVehicleEvent_mt = Class(ResetVehicleEvent, Event)
InitStaticEventClass(ResetVehicleEvent, "ResetVehicleEvent")
function ResetVehicleEvent.emptyNew()
    -- upvalues: (copy) ResetVehicleEvent_mt
    return Event.new(ResetVehicleEvent_mt)
end
function ResetVehicleEvent.new(vehicle)
    local self = ResetVehicleEvent.emptyNew()
    self.vehicle = vehicle
    return self
end
function ResetVehicleEvent.newServerToClient(state)
    local self = ResetVehicleEvent.emptyNew()
    self.state = state
    return self
end
function ResetVehicleEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.state = streamReadUIntN(streamId, 2)
    else
        self.vehicle = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end
function ResetVehicleEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.vehicle)
    else
        streamWriteUIntN(streamId, self.state, 2)
    end
end
function ResetVehicleEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(ResetVehicleEvent, self.state)
    else
        local state = ResetVehicleEvent.STATE_FAILED
        local vehicle = self.vehicle
        if vehicle ~= nil and (vehicle.isVehicleSaved and vehicle:getCanBeReset()) then
            if g_currentMission:getHasPlayerPermission("resetVehicle", connection, vehicle:getOwnerFarmId()) then
                if vehicle:getIsInUse(connection) then
                    state = ResetVehicleEvent.STATE_IN_USE
                else
                    if not vehicle.isResetInProgress then
                        vehicle:reset(false, function(success)
                            -- upvalues: (ref) state, (copy) connection
                            if success then
                                state = ResetVehicleEvent.STATE_SUCCESS
                            end
                            connection:sendEvent(ResetVehicleEvent.newServerToClient(state))
                        end)
                        return
                    end
                    state = ResetVehicleEvent.STATE_IN_USE
                end
            else
                state = ResetVehicleEvent.STATE_NO_PERMISSION
            end
        end
        connection:sendEvent(ResetVehicleEvent.newServerToClient(state))
    end
end