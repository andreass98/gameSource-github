BalerCreateBaleEvent = {}
local BalerCreateBaleEvent_mt = Class(BalerCreateBaleEvent, Event)
InitStaticEventClass(BalerCreateBaleEvent, "BalerCreateBaleEvent")
function BalerCreateBaleEvent.emptyNew()
    -- upvalues: (copy) BalerCreateBaleEvent_mt
    return Event.new(BalerCreateBaleEvent_mt)
end
function BalerCreateBaleEvent.new(object, baleFillType, baleTime, baleServerId)
    local self = BalerCreateBaleEvent.emptyNew()
    self.object = object
    self.baleFillType = baleFillType
    self.baleTime = baleTime
    self.baleServerId = baleServerId
    return self
end
function BalerCreateBaleEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.baleTime = streamReadFloat32(streamId)
    self.baleFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
    if streamReadBool(streamId) then
        self.baleServerId = NetworkUtil.readNodeObjectId(streamId)
    end
    self:run(connection)
end
function BalerCreateBaleEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteFloat32(streamId, self.baleTime)
    streamWriteUIntN(streamId, self.baleFillType, FillTypeManager.SEND_NUM_BITS)
    if streamWriteBool(streamId, self.baleServerId ~= nil) then
        NetworkUtil.writeNodeObjectId(streamId, self.baleServerId)
    end
end
function BalerCreateBaleEvent:run(_)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:createBale(self.baleFillType, nil, self.baleServerId)
        self.object:setBaleTime(#self.object.spec_baler.bales, self.baleTime)
    end
end