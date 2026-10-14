PalletUnloadTriggerEvent = {}
local PalletUnloadTriggerEvent_mt = Class(PalletUnloadTriggerEvent, Event)
InitStaticEventClass(PalletUnloadTriggerEvent, "PalletUnloadTriggerEvent")
function PalletUnloadTriggerEvent.emptyNew()
    -- upvalues: (copy) PalletUnloadTriggerEvent_mt
    return Event.new(PalletUnloadTriggerEvent_mt)
end
function PalletUnloadTriggerEvent.new(object)
    local self = PalletUnloadTriggerEvent.emptyNew()
    self.object = object
    return self
end
function PalletUnloadTriggerEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function PalletUnloadTriggerEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
end
function PalletUnloadTriggerEvent:run(connection)
    if self.object ~= nil then
        local userId = g_currentMission.userManager:getUserIdByConnection(connection)
        if userId ~= nil then
            local farm = g_farmManager:getFarmByUserId(userId)
            if farm ~= nil then
                self.object:unloadPallets(farm.farmId)
            end
        end
    end
end