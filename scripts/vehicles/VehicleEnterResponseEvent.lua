VehicleEnterResponseEvent = {}
local VehicleEnterResponseEvent_mt = Class(VehicleEnterResponseEvent, Event)
InitStaticEventClass(VehicleEnterResponseEvent, "VehicleEnterResponseEvent")
function VehicleEnterResponseEvent.emptyNew()
    -- upvalues: (copy) VehicleEnterResponseEvent_mt
    return Event.new(VehicleEnterResponseEvent_mt, NetworkNode.CHANNEL_MAIN)
end
function VehicleEnterResponseEvent.new(id, isOwner, playerStyle, farmId, userId)
    local self = VehicleEnterResponseEvent.emptyNew()
    self.id = id
    self.isOwner = isOwner
    self.playerStyle = playerStyle
    self.farmId = farmId
    self.userId = userId
    return self
end
function VehicleEnterResponseEvent:readStream(streamId, connection)
    self.id = NetworkUtil.readNodeObjectId(streamId)
    self.isOwner = streamReadBool(streamId)
    if self.playerStyle == nil then
        self.playerStyle = PlayerStyle.new()
    end
    self.playerStyle:readStream(streamId, connection)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.userId = User.streamReadUserId(streamId)
    self:run(connection)
end
function VehicleEnterResponseEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObjectId(streamId, self.id)
    streamWriteBool(streamId, self.isOwner)
    self.playerStyle:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    User.streamWriteUserId(streamId, self.userId)
end
function VehicleEnterResponseEvent:run(_)
    local vehicle = NetworkUtil.getObject(self.id)
    if vehicle == nil then
        Logging.devWarning("VehicleEnterResponseEvent: Vehicle \'%s\' not found. Skip entering", self.id)
        return
    elseif vehicle:getIsSynchronized() then
        local player = g_currentMission.playerSystem:getPlayerByUserId(self.userId)
        if player == nil then
            Logging.devWarning("VehicleEnterResponseEvent: Player \'%s\' not found. Skip entering", self.userId)
        else
            player:onEnterVehicle(vehicle)
        end
    else
        Logging.devWarning("VehicleEnterResponseEvent: Vehicle \'%s\' not synchronized. Skip entering", vehicle.configFileName)
        return
    end
end