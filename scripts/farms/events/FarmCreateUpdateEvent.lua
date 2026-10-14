FarmCreateUpdateEvent = {}
local FarmCreateUpdateEvent_mt = Class(FarmCreateUpdateEvent, Event)
InitStaticEventClass(FarmCreateUpdateEvent, "FarmCreateUpdateEvent")
function FarmCreateUpdateEvent.emptyNew()
    -- upvalues: (copy) FarmCreateUpdateEvent_mt
    return Event.new(FarmCreateUpdateEvent_mt)
end
function FarmCreateUpdateEvent.new(name, color, password, isUpdate, farmId)
    local self = FarmCreateUpdateEvent.emptyNew()
    self.name = name
    self.color = color
    self.password = password
    self.isUpdate = isUpdate
    self.farmId = farmId
    return self
end
function FarmCreateUpdateEvent:writeStream(streamId, _)
    local filteredName = filterText(self.name, false, false)
    streamWriteString(streamId, filteredName)
    streamWriteUIntN(streamId, self.color, Farm.COLOR_SEND_NUM_BITS)
    streamWriteBool(streamId, self.isUpdate)
    if streamWriteBool(streamId, self.password ~= nil) then
        streamWriteString(streamId, self.password)
    end
    if streamWriteBool(streamId, self.isUpdate or self.farmId ~= nil) then
        streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    end
end
function FarmCreateUpdateEvent:readStream(streamId, connection)
    self.name = streamReadString(streamId)
    self.color = streamReadUIntN(streamId, Farm.COLOR_SEND_NUM_BITS)
    self.isUpdate = streamReadBool(streamId)
    if streamReadBool(streamId) then
        self.password = streamReadString(streamId)
    else
        self.password = nil
    end
    if streamReadBool(streamId) then
        self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    end
    self:run(connection)
end
function FarmCreateUpdateEvent:run(connection)
    if connection:getIsServer() then
        if self.isUpdate then
            local farm = g_farmManager:getFarmById(self.farmId)
            farm.name = self.name
            farm.color = self.color
            g_messageCenter:publish(MessageType.FARM_SETTINGS_CHANGED, farm.farmId)
        end
    elseif self.isUpdate then
        if g_currentMission:getHasPlayerPermission("updateFarm", connection, self.farmId) then
            local farm = g_farmManager:getFarmById(self.farmId)
            farm.name = self.name
            farm.color = self.color
            farm.password = self.password
            g_server:broadcastEvent(FarmCreateUpdateEvent.new(self.name, self.color, nil, true, self.farmId))
            g_messageCenter:publish(MessageType.FARM_SETTINGS_CHANGED, self.farmId)
            return
        end
    elseif connection:getIsLocal() or g_currentMission.userManager:getIsConnectionMasterUser(connection) then
        g_farmManager:createFarm(self.name, self.color, self.password)
        return
    end
end