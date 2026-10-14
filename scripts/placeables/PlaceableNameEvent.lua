PlaceableNameEvent = {}
local PlaceableNameEvent_mt = Class(PlaceableNameEvent, Event)
InitStaticEventClass(PlaceableNameEvent, "PlaceableNameEvent")
function PlaceableNameEvent.emptyNew()
    -- upvalues: (copy) PlaceableNameEvent_mt
    return Event.new(PlaceableNameEvent_mt)
end
function PlaceableNameEvent.new(placeable, name)
    local self = PlaceableNameEvent.emptyNew()
    self.placeable = placeable
    self.resetName = name ~= nil
    self.name = name or ""
    return self
end
function PlaceableNameEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.resetName = streamReadBool(streamId)
    if not self.resetName then
        self.name = streamReadString(streamId)
    end
    self:run(connection)
end
function PlaceableNameEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    if not streamWriteBool(streamId, self.resetName) then
        streamWriteString(streamId, self.name)
    end
end
function PlaceableNameEvent:run(connection)
    if self.placeable ~= nil then
        log("PlaceableNameEvent:run", self.name)
        self.placeable:setName(self.name, true)
        if not connection:getIsServer() then
            g_server:broadcastEvent(self, false)
        end
    end
end
function PlaceableNameEvent.sendEvent(placeable, name, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_currentMission:getIsServer() then
            g_server:broadcastEvent(PlaceableNameEvent.new(placeable, name), false)
            return
        end
        g_client:getServerConnection():sendEvent(PlaceableNameEvent.new(placeable, name))
    end
end