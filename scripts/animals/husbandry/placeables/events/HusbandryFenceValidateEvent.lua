HusbandryFenceValidateEvent = {}
local HusbandryFenceValidateEvent_mt = Class(HusbandryFenceValidateEvent, Event)
InitStaticEventClass(HusbandryFenceValidateEvent, "HusbandryFenceValidateEvent")
function HusbandryFenceValidateEvent.emptyNew()
    -- upvalues: (copy) HusbandryFenceValidateEvent_mt
    return Event.new(HusbandryFenceValidateEvent_mt)
end
function HusbandryFenceValidateEvent.new(placeable)
    local self = HusbandryFenceValidateEvent.emptyNew()
    self.placeable = placeable
    return self
end
function HusbandryFenceValidateEvent.newServerToClient(success)
    local self = HusbandryFenceValidateEvent.emptyNew()
    self.success = success
    return self
end
function HusbandryFenceValidateEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.success = streamReadBool(streamId)
    else
        self.placeable = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end
function HusbandryFenceValidateEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.placeable)
    else
        streamWriteBool(streamId, self.success)
    end
end
function HusbandryFenceValidateEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(HusbandryFenceValidateEvent, self.success)
    elseif self.placeable ~= nil then
        local success = self.placeable:tryFinalizeFence()
        connection:sendEvent(HusbandryFenceValidateEvent.newServerToClient(success))
    end
end