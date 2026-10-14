FarmsInitialStateEvent = {}
local FarmsInitialStateEvent_mt = Class(FarmsInitialStateEvent, Event)
InitStaticEventClass(FarmsInitialStateEvent, "FarmsInitialStateEvent")
function FarmsInitialStateEvent.emptyNew()
    -- upvalues: (copy) FarmsInitialStateEvent_mt
    return Event.new(FarmsInitialStateEvent_mt)
end
function FarmsInitialStateEvent.new(playerFarmId)
    local self = FarmsInitialStateEvent.emptyNew()
    self.playerFarmId = playerFarmId
    self.farms = g_farmManager.farms
    return self
end
function FarmsInitialStateEvent:writeStream(streamId, _)
    streamWriteUInt8(streamId, #self.farms)
    for _, farm in ipairs(self.farms) do
        NetworkUtil.writeNodeObject(streamId, farm)
    end
    streamWriteUIntN(streamId, self.playerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end
function FarmsInitialStateEvent:readStream(streamId, connection)
    self.farms = {}
    local numFarms = streamReadUInt8(streamId)
    for _ = 1, numFarms do
        local farm = NetworkUtil.readNodeObject(streamId)
        table.insert(self.farms, farm)
    end
    self.playerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self:run(connection)
end
function FarmsInitialStateEvent:run(connection)
    if connection:getIsServer() then
        g_farmManager:updateFarms(self.farms, self.playerFarmId)
    end
end