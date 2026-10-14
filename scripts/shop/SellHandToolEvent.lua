SellHandToolEvent = {}
SellHandToolEvent.STATE_SUCCESS = 0
SellHandToolEvent.STATE_FAILED = 1
SellHandToolEvent.STATE_NO_PERMISSION = 2
SellHandToolEvent.STATE_IN_USE = 3
local SellHandToolEvent_mt = Class(SellHandToolEvent, Event)
InitStaticEventClass(SellHandToolEvent, "SellHandToolEvent")
function SellHandToolEvent.emptyNew()
    -- upvalues: (copy) SellHandToolEvent_mt
    return Event.new(SellHandToolEvent_mt)
end
function SellHandToolEvent.new(handTool)
    local self = SellHandToolEvent.emptyNew()
    self.handTool = handTool
    return self
end
function SellHandToolEvent.newServerToClient(errorCode)
    local self = SellHandToolEvent.emptyNew()
    self.errorCode = errorCode
    return self
end
function SellHandToolEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.errorCode = streamReadUIntN(streamId, 2)
    else
        self.handTool = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end
function SellHandToolEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.handTool)
    else
        streamWriteUIntN(streamId, self.errorCode, 2)
    end
end
function SellHandToolEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publishDelayedAfterFrames(SellHandToolEvent, 2, self.errorCode)
    else
        local errorCode = SellHandToolEvent.STATE_SUCCESS
        if g_currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE, connection, self.handTool:getOwnerFarmId()) then
            local seller = g_currentMission:getPlayerByConnection(connection)
            if self.handTool:getHolder() == nil or self.handTool:getHolder() == seller then
                local sellPrice = self.handTool:getSellPrice()
                self.handTool:delete()
                g_currentMission:addMoney(sellPrice, self.handTool:getOwnerFarmId(), MoneyType.SHOP_HANDTOOL_SELL, true)
            else
                errorCode = SellHandToolEvent.STATE_IN_USE
            end
        else
            errorCode = SellHandToolEvent.STATE_NO_PERMISSION
        end
        connection:sendEvent(SellHandToolEvent.newServerToClient(errorCode))
    end
end