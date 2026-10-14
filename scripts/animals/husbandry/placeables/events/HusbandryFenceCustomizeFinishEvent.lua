HusbandryFenceCustomizeFinishEvent = {}
local HusbandryFenceCustomizeFinishEvent_mt = Class(HusbandryFenceCustomizeFinishEvent, Event)
InitStaticEventClass(HusbandryFenceCustomizeFinishEvent, "HusbandryFenceCustomizeFinishEvent")
function HusbandryFenceCustomizeFinishEvent.emptyNew()
    -- upvalues: (copy) HusbandryFenceCustomizeFinishEvent_mt
    return Event.new(HusbandryFenceCustomizeFinishEvent_mt)
end
function HusbandryFenceCustomizeFinishEvent.new(placeable, success)
    local self = HusbandryFenceCustomizeFinishEvent.emptyNew()
    self.placeable = placeable
    self.success = success
    return self
end
function HusbandryFenceCustomizeFinishEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.success = streamReadBool(streamId)
    self:run(connection)
end
function HusbandryFenceCustomizeFinishEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteBool(streamId, self.success)
end
function HusbandryFenceCustomizeFinishEvent:run(connection)
    if self.placeable ~= nil then
        if not connection:getIsServer() then
            g_server:broadcastEvent(self, false, connection, self.placeable)
        end
        if self.placeable:getIsSynchronized() then
            local user = nil
            if not connection:getIsServer() then
                user = g_currentMission.userManager:getUserByConnection(connection)
            end
            self.placeable:finishFenceCustomization(user, self.success, true)
        end
    end
end
function HusbandryFenceCustomizeFinishEvent.sendEvent(placeable, success, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(HusbandryFenceCustomizeFinishEvent.new(placeable, success), nil, nil, placeable)
            return
        end
        g_client:getServerConnection():sendEvent(HusbandryFenceCustomizeFinishEvent.new(placeable, success))
    end
end