HandsThrowObjectEvent = {}
local HandsThrowObjectEvent_mt = Class(HandsThrowObjectEvent, Event)
InitStaticEventClass(HandsThrowObjectEvent, "HandsThrowObjectEvent")
HandsThrowObjectEvent.THROW_FORCE_SCALAR_NUM_BITS = 8
function HandsThrowObjectEvent.emptyNew()
    -- upvalues: (copy) HandsThrowObjectEvent_mt
    return Event.new(HandsThrowObjectEvent_mt)
end
function HandsThrowObjectEvent.new(hands, dirX, dirY, dirZ, forceScalar)
    local self = HandsThrowObjectEvent.emptyNew()
    self.hands = hands
    self.dirX = dirX
    self.dirY = dirY
    self.dirZ = dirZ
    self.forceScalar = forceScalar
    return self
end
function HandsThrowObjectEvent:readStream(streamId, connection)
    self.hands = NetworkUtil.readNodeObject(streamId)
    self.dirX = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
    self.dirY = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
    self.dirZ = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
    self.forceScalar = NetworkUtil.readCompressedRange(streamId, 0, 1, HandsThrowObjectEvent.THROW_FORCE_SCALAR_NUM_BITS)
    self:run(connection)
end
function HandsThrowObjectEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.hands)
    NetworkUtil.writeCompressedRange(streamId, self.dirX, -1, 1, 12)
    NetworkUtil.writeCompressedRange(streamId, self.dirY, -1, 1, 12)
    NetworkUtil.writeCompressedRange(streamId, self.dirZ, -1, 1, 12)
    NetworkUtil.writeCompressedRange(streamId, self.forceScalar, 0, 1, HandsThrowObjectEvent.THROW_FORCE_SCALAR_NUM_BITS)
end
function HandsThrowObjectEvent:run(connection)
    if self.hands ~= nil then
        if not connection:getIsServer() then
            g_server:broadcastEvent(self, false, connection, self.player)
        end
        if self.dirX == 0 and (self.dirY == 0 and self.dirZ == 0) then
            self.hands:dropHeldItem(true)
            return
        end
        self.hands:throwHeldItemWithForceVector(self.dirX, self.dirY, self.dirZ, self.forceScalar, true)
    end
end
function HandsThrowObjectEvent.sendEvent(hands, dirX, dirY, dirZ, forceScalar, noEventSend)
    if noEventSend == true then
        return
    elseif g_server == nil then
        g_client:getServerConnection():sendEvent(HandsThrowObjectEvent.new(hands, dirX, dirY, dirZ, forceScalar))
    else
        g_server:broadcastEvent(HandsThrowObjectEvent.new(hands, dirX, dirY, dirZ, forceScalar), nil, nil, hands)
    end
end