MountableSetMountTypeEvent = {}
local MountableSetMountTypeEvent_mt = Class(MountableSetMountTypeEvent, Event)
InitStaticEventClass(MountableSetMountTypeEvent, "MountableSetMountTypeEvent")
function MountableSetMountTypeEvent.emptyNew()
    -- upvalues: (copy) MountableSetMountTypeEvent_mt
    return Event.new(MountableSetMountTypeEvent_mt)
end
function MountableSetMountTypeEvent.new(object, mountType, mountObject)
    local self = MountableSetMountTypeEvent.emptyNew()
    self.object = object
    self.mountType = mountType
    self.mountObject = mountObject
    return self
end
function MountableSetMountTypeEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.mountType = streamReadUIntN(streamId, MountableObject.MOUNT_TYPE_SEND_NUM_BITS)
    if streamReadBool(streamId) then
        self.mountObject = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end
function MountableSetMountTypeEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.mountType, MountableObject.MOUNT_TYPE_SEND_NUM_BITS)
    if streamWriteBool(streamId, self.mountObject ~= nil) then
        NetworkUtil.writeNodeObject(streamId, self.mountObject)
    end
end
function MountableSetMountTypeEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        if not connection:getIsServer() then
            g_server:broadcastEvent(self, false, connection, self.object)
        end
        self.object:setDynamicMountType(self.mountType, self.mountObject, true)
    end
end
function MountableSetMountTypeEvent.sendEvent(vehicle, mountType, mountObject, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(MountableSetMountTypeEvent.new(vehicle, mountType, mountObject), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(MountableSetMountTypeEvent.new(vehicle, mountType, mountObject))
    end
end