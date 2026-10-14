FillUnitUnloadEvent = {}
local FillUnitUnloadEvent_mt = Class(FillUnitUnloadEvent, Event)
InitStaticEventClass(FillUnitUnloadEvent, "FillUnitUnloadEvent")
function FillUnitUnloadEvent.emptyNew()
    -- upvalues: (copy) FillUnitUnloadEvent_mt
    return Event.new(FillUnitUnloadEvent_mt)
end
function FillUnitUnloadEvent.new(object)
    local self = FillUnitUnloadEvent.emptyNew()
    self.object = object
    return self
end
function FillUnitUnloadEvent.newServerToClient()
    return FillUnitUnloadEvent.emptyNew()
end
function FillUnitUnloadEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.object = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end
function FillUnitUnloadEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.object)
    end
end
function FillUnitUnloadEvent:run(connection)
    if not connection:getIsServer() and (self.object ~= nil and self.object:getIsSynchronized()) then
        self.object:unloadFillUnits(true)
    end
end