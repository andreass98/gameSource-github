ProductionPointProductionStatusEvent = {}
local ProductionPointProductionStatusEvent_mt = Class(ProductionPointProductionStatusEvent, Event)
InitStaticEventClass(ProductionPointProductionStatusEvent, "ProductionPointProductionStatusEvent")
function ProductionPointProductionStatusEvent.emptyNew()
    -- upvalues: (copy) ProductionPointProductionStatusEvent_mt
    return Event.new(ProductionPointProductionStatusEvent_mt)
end
function ProductionPointProductionStatusEvent.new(productionPoint, productionIndex, status)
    local self = ProductionPointProductionStatusEvent.emptyNew()
    self.productionPoint = productionPoint
    self.productionIndex = productionIndex
    self.status = status
    return self
end
function ProductionPointProductionStatusEvent:readStream(streamId, connection)
    self.productionPoint = NetworkUtil.readNodeObject(streamId)
    self.productionIndex = streamReadUInt8(streamId)
    self.status = streamReadUIntN(streamId, ProductionPoint.PROD_STATUS_NUM_BITS)
    self:run(connection)
end
function ProductionPointProductionStatusEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.productionPoint)
    streamWriteUInt8(streamId, self.productionIndex)
    streamWriteUIntN(streamId, self.status, ProductionPoint.PROD_STATUS_NUM_BITS)
end
function ProductionPointProductionStatusEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection)
    end
    if self.productionPoint ~= nil then
        self.productionPoint:setProductionStatus(self.productionPoint.productions[self.productionIndex].id, self.status, true)
    end
end
function ProductionPointProductionStatusEvent.sendEvent(productionPoint, productionIndex, status, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(ProductionPointProductionStatusEvent.new(productionPoint, productionIndex, status))
            return
        end
        g_client:getServerConnection():sendEvent(ProductionPointProductionStatusEvent.new(productionPoint, productionIndex, status))
    end
end