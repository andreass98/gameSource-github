HusbandryFenceCustomizeStartEvent = {}
local HusbandryFenceCustomizeStartEvent_mt = Class(HusbandryFenceCustomizeStartEvent, Event)
InitStaticEventClass(HusbandryFenceCustomizeStartEvent, "HusbandryFenceCustomizeStartEvent")
function HusbandryFenceCustomizeStartEvent.emptyNew()
    -- upvalues: (copy) HusbandryFenceCustomizeStartEvent_mt
    return Event.new(HusbandryFenceCustomizeStartEvent_mt)
end
function HusbandryFenceCustomizeStartEvent.new(placeable)
    local self = HusbandryFenceCustomizeStartEvent.emptyNew()
    self.placeable = placeable
    return self
end
function HusbandryFenceCustomizeStartEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function HusbandryFenceCustomizeStartEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
end
function HusbandryFenceCustomizeStartEvent:run(connection)
    if self.placeable ~= nil then
        if not connection:getIsServer() then
            g_server:broadcastEvent(self, false, connection, self.placeable)
        end
        if self.placeable:getIsSynchronized() then
            local user = nil
            if not connection:getIsServer() then
                user = g_currentMission.userManager:getUserByConnection(connection)
            end
            self.placeable:startFenceCustomization(user, true)
        end
    end
end
function HusbandryFenceCustomizeStartEvent.sendEvent(placeable, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(HusbandryFenceCustomizeStartEvent.new(placeable), nil, nil, placeable)
            return
        end
        g_client:getServerConnection():sendEvent(HusbandryFenceCustomizeStartEvent.new(placeable))
    end
end