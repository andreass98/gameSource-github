PurchaseSoilMapsEvent = {}
local PurchaseSoilMapsEvent_mt = Class(PurchaseSoilMapsEvent, Event)
InitEventClass(PurchaseSoilMapsEvent, "PurchaseSoilMapsEvent")
function PurchaseSoilMapsEvent.emptyNew()
    -- upvalues: (copy) PurchaseSoilMapsEvent_mt
    return Event.new(PurchaseSoilMapsEvent_mt)
end
function PurchaseSoilMapsEvent.new(farmlandId)
    local self = PurchaseSoilMapsEvent.emptyNew()
    self.farmlandId = farmlandId
    return self
end
function PurchaseSoilMapsEvent:readStream(streamId, connection)
    self.farmlandId = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
    self:run(connection)
end
function PurchaseSoilMapsEvent:writeStream(streamId, _)
    streamWriteUIntN(streamId, self.farmlandId, g_farmlandManager.numberOfBits)
end
function PurchaseSoilMapsEvent:run(connection)
    if not connection:getIsServer() and (g_precisionFarming ~= nil and g_precisionFarming.soilMap ~= nil) then
        g_precisionFarming.soilMap:purchaseSoilMaps(self.farmlandId)
        g_precisionFarming:updatePrecisionFarmingOverlays()
    end
end