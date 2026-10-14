ProductionPointOutputModeEvent = {}
local ProductionPointOutputModeEvent_mt = Class(ProductionPointOutputModeEvent, Event)
InitStaticEventClass(ProductionPointOutputModeEvent, "ProductionPointOutputModeEvent")
function ProductionPointOutputModeEvent.emptyNew()
    -- upvalues: (copy) ProductionPointOutputModeEvent_mt
    return Event.new(ProductionPointOutputModeEvent_mt)
end
function ProductionPointOutputModeEvent.new(productionPoint, outputFillTypeId, outputMode)
    local self = ProductionPointOutputModeEvent.emptyNew()
    self.productionPoint = productionPoint
    self.outputFillTypeId = outputFillTypeId
    self.outputMode = outputMode
    return self
end
function ProductionPointOutputModeEvent:readStream(streamId, connection)
    self.productionPoint = NetworkUtil.readNodeObject(streamId)
    self.outputFillTypeId = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
    self.outputMode = streamReadUIntN(streamId, ProductionPoint.OUTPUT_MODE_NUM_BITS)
    self:run(connection)
end
function ProductionPointOutputModeEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.productionPoint)
    streamWriteUIntN(streamId, self.outputFillTypeId, FillTypeManager.SEND_NUM_BITS)
    streamWriteUIntN(streamId, self.outputMode, ProductionPoint.OUTPUT_MODE_NUM_BITS)
end
function ProductionPointOutputModeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection)
    end
    if self.productionPoint ~= nil then
        self.productionPoint:setOutputDistributionMode(self.outputFillTypeId, self.outputMode, true)
    end
end
function ProductionPointOutputModeEvent.sendEvent(productionPoint, outputFillTypeId, outputMode, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(ProductionPointOutputModeEvent.new(productionPoint, outputFillTypeId, outputMode))
            return
        end
        g_client:getServerConnection():sendEvent(ProductionPointOutputModeEvent.new(productionPoint, outputFillTypeId, outputMode))
    end
end