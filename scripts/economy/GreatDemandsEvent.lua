GreatDemandsEvent = {}
local GreatDemandsEvent_mt = Class(GreatDemandsEvent, Event)
InitStaticEventClass(GreatDemandsEvent, "GreatDemandsEvent")
function GreatDemandsEvent.emptyNew()
    -- upvalues: (copy) GreatDemandsEvent_mt
    return Event.new(GreatDemandsEvent_mt)
end
function GreatDemandsEvent.new(greatDemands)
    local self = GreatDemandsEvent.emptyNew()
    self.greatDemands = greatDemands
    return self
end
function GreatDemandsEvent:readStream(streamId, connection)
    local numberOfDemands = streamReadUInt8(streamId)
    local i = 1
    for i = i, numberOfDemands do
        local greatDemand = g_currentMission.economyManager:getGreatDemandById(i)
        greatDemand.isValid = streamReadBool(streamId)
        if greatDemand.isValid then
            greatDemand.sellStation = NetworkUtil.readNodeObject(streamId)
            greatDemand.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
            greatDemand.demandMultiplier = streamReadFloat32(streamId)
            greatDemand.demandStart.day = streamReadInt32(streamId)
            greatDemand.demandStart.hour = streamReadInt32(streamId)
            greatDemand.demandDuration = streamReadInt32(streamId)
            local isRunning = streamReadBool(streamId)
            greatDemand.needsStarting = isRunning and not greatDemand.isRunning
            greatDemand.needsStopping = not isRunning and greatDemand.isRunning
        elseif greatDemand.isRunning then
            greatDemand.needsStopping = true
        end
    end
    self:run(connection)
end
function GreatDemandsEvent:writeStream(streamId, _)
    streamWriteUInt8(streamId, #self.greatDemands)
    for _, greatDemand in ipairs(self.greatDemands) do
        if streamWriteBool(streamId, greatDemand.isValid) then
            NetworkUtil.writeNodeObject(streamId, greatDemand.sellStation)
            streamWriteUIntN(streamId, greatDemand.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
            streamWriteFloat32(streamId, greatDemand.demandMultiplier)
            streamWriteInt32(streamId, greatDemand.demandStart.day)
            streamWriteInt32(streamId, greatDemand.demandStart.hour)
            streamWriteInt32(streamId, greatDemand.demandDuration)
            streamWriteBool(streamId, greatDemand.isRunning)
        end
    end
end
function GreatDemandsEvent.run(_, connection)
    if connection:getIsServer() then
        for _, demand in pairs(g_currentMission.economyManager.greatDemands) do
            if demand.needsStarting then
                g_currentMission.economyManager:startGreatDemand(demand)
                demand.needsStarting = false
            end
            if demand.needsStopping then
                g_currentMission.economyManager:stopGreatDemand(demand)
                demand.needsStopping = false
            end
        end
    end
end