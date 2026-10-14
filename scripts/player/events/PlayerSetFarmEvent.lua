source("dataS/scripts/player/events/PlayerSetFarmAnswerEvent.lua")
PlayerSetFarmEvent = {}
local PlayerSetFarmEvent_mt = Class(PlayerSetFarmEvent, Event)
InitStaticEventClass(PlayerSetFarmEvent, "PlayerSetFarmEvent")
function PlayerSetFarmEvent.emptyNew()
    -- upvalues: (copy) PlayerSetFarmEvent_mt
    return Event.new(PlayerSetFarmEvent_mt)
end
function PlayerSetFarmEvent.new(player, farmId, password)
    local self = PlayerSetFarmEvent.emptyNew()
    self.player = player
    self.farmId = farmId
    self.password = password
    return self
end
function PlayerSetFarmEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.player)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    if self.password == nil then
        streamWriteBool(streamId, false)
    else
        streamWriteBool(streamId, true)
        streamWriteString(streamId, self.password)
    end
end
function PlayerSetFarmEvent:readStream(streamId, connection)
    self.player = NetworkUtil.readNodeObject(streamId)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    if streamReadBool(streamId) then
        self.password = streamReadString(streamId)
    end
    self:run(connection)
end
function PlayerSetFarmEvent:run(connection)
    if connection:getIsServer() then
        self.player.farmId = self.farmId
        if self.player.playerHotspot ~= nil then
            self.player.playerHotspot:setOwnerFarmId(self.farmId)
        end
        g_messageCenter:publish(MessageType.PLAYER_FARM_CHANGED, self.player)
    else
        local oldFarmId = self.player.farmId
        local oldFarm = g_farmManager:getFarmById(oldFarmId)
        local farm = g_farmManager:getFarmById(self.farmId)
        if farm ~= nil then
            local user = g_currentMission.userManager:getUserByUserId(self.player.userId)
            if user:getIsMasterUser() or (farm.password == nil or farm.password == self.password) then
                oldFarm:removeUser(user:getId())
                self.player:setFarmId(self.farmId)
                farm:addUser(user:getId(), user:getUniqueUserId(), user:getIsMasterUser())
                if self.player.playerHotspot ~= nil then
                    self.player.playerHotspot:setOwnerFarmId(self.farmId)
                end
                g_messageCenter:publish(MessageType.PLAYER_FARM_CHANGED, self.player)
                user:setFinancesVersionCounter(0)
                connection:sendEvent(PlayerSetFarmAnswerEvent.new(PlayerSetFarmAnswerEvent.STATE.OK, self.farmId, self.password))
                g_server:broadcastEvent(PlayerSwitchedFarmEvent.new(oldFarmId, self.farmId, user:getId()))
            else
                connection:sendEvent(PlayerSetFarmAnswerEvent.new(PlayerSetFarmAnswerEvent.STATE.PASSWORD_REQUIRED, self.farmId))
            end
        end
    end
end
function PlayerSetFarmEvent.sendEvent(player, farmId, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PlayerSetFarmEvent.new(player, farmId), nil, nil, player)
            return
        end
        g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(player, farmId))
    end
end