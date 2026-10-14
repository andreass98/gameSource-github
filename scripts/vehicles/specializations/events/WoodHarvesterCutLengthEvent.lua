WoodHarvesterCutLengthEvent = {}
local WoodHarvesterCutLengthEvent_mt = Class(WoodHarvesterCutLengthEvent, Event)
InitStaticEventClass(WoodHarvesterCutLengthEvent, "WoodHarvesterCutLengthEvent")
function WoodHarvesterCutLengthEvent.emptyNew()
    -- upvalues: (copy) WoodHarvesterCutLengthEvent_mt
    return Event.new(WoodHarvesterCutLengthEvent_mt)
end
function WoodHarvesterCutLengthEvent.new(object, index)
    local self = WoodHarvesterCutLengthEvent.emptyNew()
    self.object = object
    self.index = index
    return self
end
function WoodHarvesterCutLengthEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.index = streamReadUIntN(streamId, WoodHarvester.NUM_BITS_CUT_LENGTH)
    self:run(connection)
end
function WoodHarvesterCutLengthEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.index, WoodHarvester.NUM_BITS_CUT_LENGTH)
end
function WoodHarvesterCutLengthEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setWoodHarvesterCutLengthIndex(self.index, true)
    end
end
function WoodHarvesterCutLengthEvent.sendEvent(object, index, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(WoodHarvesterCutLengthEvent.new(object, index), nil, nil, object)
            return
        end
        g_client:getServerConnection():sendEvent(WoodHarvesterCutLengthEvent.new(object, index))
    end
end