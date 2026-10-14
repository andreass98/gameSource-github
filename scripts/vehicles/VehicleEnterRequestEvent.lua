VehicleEnterRequestEvent = {}
local VehicleEnterRequestEvent_mt = Class(VehicleEnterRequestEvent, Event)
InitStaticEventClass(VehicleEnterRequestEvent, "VehicleEnterRequestEvent")
function VehicleEnterRequestEvent.emptyNew()
    -- upvalues: (copy) VehicleEnterRequestEvent_mt
    return Event.new(VehicleEnterRequestEvent_mt, NetworkNode.CHANNEL_MAIN)
end
function VehicleEnterRequestEvent.new(object, playerStyle, farmId, force)
    local self = VehicleEnterRequestEvent.emptyNew()
    self.object = object
    self.objectId = NetworkUtil.getObjectId(self.object)
    self.farmId = farmId
    self.playerStyle = playerStyle
    self.force = Utils.getNoNil(force, false)
    return self
end
function VehicleEnterRequestEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObjectId(streamId, self.objectId)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.playerStyle:writeStream(streamId, connection)
    streamWriteBool(streamId, self.force)
end
function VehicleEnterRequestEvent:readStream(streamId, connection)
    self.objectId = NetworkUtil.readNodeObjectId(streamId)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    if self.playerStyle == nil then
        self.playerStyle = PlayerStyle.new()
    end
    self.playerStyle:readStream(streamId, connection)
    self.force = streamReadBool(streamId)
    self.object = NetworkUtil.getObject(self.objectId)
    self:run(connection)
end
function VehicleEnterRequestEvent:run(connection)
    if self.object == nil or not self.object:getIsSynchronized() then
        return
    elseif self.force or g_server:hasGhostObject(connection, self.object) then
        local enterableSpec = self.object.spec_enterable
        if enterableSpec ~= nil and not enterableSpec.isControlled then
            local userId = g_currentMission.userManager:getUserIdByConnection(connection)
            self.object:setOwnerConnection(connection)
            self.object.controllerFarmId = self.farmId
            self.object.controllerUserId = userId
            g_server:broadcastEvent(VehicleEnterResponseEvent.new(self.objectId, false, self.playerStyle, self.farmId, userId), true, connection)
            connection:sendEvent(VehicleEnterResponseEvent.new(self.objectId, true, self.playerStyle, self.farmId, userId))
        end
    else
        Logging.warning("Vehicle %q is not fully synchronized to on client", self.object.configFileName)
        return
    end
end