FarmlandInitialStateEvent = {}
local FarmlandInitialStateEvent_mt = Class(FarmlandInitialStateEvent, Event)
InitStaticEventClass(FarmlandInitialStateEvent, "FarmlandStateEvent")
function FarmlandInitialStateEvent.emptyNew()
    -- upvalues: (copy) FarmlandInitialStateEvent_mt
    return Event.new(FarmlandInitialStateEvent_mt)
end
function FarmlandInitialStateEvent.new()
    return FarmlandInitialStateEvent.emptyNew()
end
function FarmlandInitialStateEvent.readStream(_, streamId, _)
    for _, farmlandId in ipairs(g_farmlandManager.sortedFarmlandIds) do
        if streamReadBool(streamId) then
            local farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
            g_farmlandManager:setLandOwnership(farmlandId, farmId, true)
        end
    end
end
function FarmlandInitialStateEvent.writeStream(_, streamId, _)
    for _, farmlandId in ipairs(g_farmlandManager.sortedFarmlandIds) do
        local owner = g_farmlandManager:getFarmlandOwner(farmlandId)
        if streamWriteBool(streamId, owner ~= FarmlandManager.NO_OWNER_FARM_ID) then
            streamWriteUIntN(streamId, owner, FarmManager.FARM_ID_SEND_NUM_BITS)
        end
    end
end