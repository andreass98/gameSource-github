FlashlightToggleLightEvent = {}
local FlashlightToggleLightEvent_mt = Class(FlashlightToggleLightEvent, Event)
InitStaticEventClass(FlashlightToggleLightEvent, "FlashlightToggleLightEvent")
function FlashlightToggleLightEvent.emptyNew()
    -- upvalues: (copy) FlashlightToggleLightEvent_mt
    return Event.new(FlashlightToggleLightEvent_mt)
end
function FlashlightToggleLightEvent.new(flashlight, isActive)
    local self = FlashlightToggleLightEvent.emptyNew()
    self.flashlight = flashlight
    self.isActive = isActive
    return self
end
function FlashlightToggleLightEvent:readStream(streamId, connection)
    self.flashlight = NetworkUtil.readNodeObject(streamId)
    self.isActive = streamReadBool(streamId)
    self:run(connection)
end
function FlashlightToggleLightEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.flashlight)
    streamWriteBool(streamId, self.isActive)
end
function FlashlightToggleLightEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection)
    end
    if self.flashlight ~= nil and self.flashlight:getIsSynchronized() then
        self.flashlight:setFlashlightIsActive(self.isActive, true)
    end
end
function FlashlightToggleLightEvent.sendEvent(flashlight, isActive, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(FlashlightToggleLightEvent.new(flashlight, isActive))
            return
        end
        g_client:getServerConnection():sendEvent(FlashlightToggleLightEvent.new(flashlight, isActive))
    end
end