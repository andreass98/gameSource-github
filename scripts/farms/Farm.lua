Farm = {}
Farm.MIN_LOAN = 500000
Farm.MAX_LOAN = 3000000
Farm.EQUITY_LOAN_RATIO = 0.8
Farm.LOAN_INTEREST_RATE = 0.04
Farm.MAX_NUM_SAVED_PLAYERS = 150
Farm.MAX_NUM_DAYS_OFFLINE = 30
Farm.PERMISSION = {
    ["BUY_VEHICLE"] = "buyVehicle",
    ["SELL_VEHICLE"] = "sellVehicle",
    ["BUY_PLACEABLE"] = "buyPlaceable",
    ["SELL_PLACEABLE"] = "sellPlaceable",
    ["MANAGE_CONTRACTS"] = "manageContracts",
    ["TRADE_ANIMALS"] = "tradeAnimals",
    ["CREATE_FIELDS"] = "createFields",
    ["LANDSCAPING"] = "landscaping",
    ["HIRE_ASSISTANT"] = "hireAssistant",
    ["RESET_VEHICLE"] = "resetVehicle",
    ["MANAGE_PRODUCTIONS"] = "manageProductions",
    ["CUT_TREES"] = "cutTrees",
    ["MANAGE_RIGHTS"] = "manageRights",
    ["TRANSFER_MONEY"] = "transferMoney",
    ["UPDATE_FARM"] = "updateFarm",
    ["MANAGE_CONTRACTING"] = "manageContracting"
}
Farm.PERMISSIONS = {
    Farm.PERMISSION.BUY_VEHICLE,
    Farm.PERMISSION.SELL_VEHICLE,
    Farm.PERMISSION.BUY_PLACEABLE,
    Farm.PERMISSION.SELL_PLACEABLE,
    Farm.PERMISSION.MANAGE_CONTRACTS,
    Farm.PERMISSION.TRADE_ANIMALS,
    Farm.PERMISSION.CREATE_FIELDS,
    Farm.PERMISSION.LANDSCAPING,
    Farm.PERMISSION.HIRE_ASSISTANT,
    Farm.PERMISSION.RESET_VEHICLE,
    Farm.PERMISSION.MANAGE_PRODUCTIONS,
    Farm.PERMISSION.CUT_TREES,
    Farm.PERMISSION.MANAGE_RIGHTS,
    Farm.PERMISSION.TRANSFER_MONEY,
    Farm.PERMISSION.UPDATE_FARM,
    Farm.PERMISSION.MANAGE_CONTRACTING
}
Farm.NO_PERMISSIONS = {}
Farm.DEFAULT_PERMISSIONS = {}
Farm.COLORS = {
    {
        1,
        0.4287,
        0,
        1
    },
    {
        1,
        0.1221,
        0.0003,
        1
    },
    {
        0.7084,
        0.0203,
        0.2086,
        1
    },
    {
        0.2541,
        0.0065,
        0.5089,
        1
    },
    {
        0.1921,
        0.0976,
        0.8632,
        1
    },
    {
        0.1248,
        0.2541,
        1,
        1
    },
    {
        0.1248,
        0.9216,
        1,
        1
    },
    {
        0.2307,
        1,
        0.2232,
        1
    }
}
Farm.COLOR_SEND_NUM_BITS = 4
Farm.ICON_UVS = {
    {
        330,
        0,
        256,
        256
    },
    {
        660,
        0,
        256,
        256
    },
    {
        330,
        310,
        256,
        256
    },
    {
        0,
        310,
        256,
        256
    },
    {
        660,
        310,
        256,
        256
    },
    {
        0,
        620,
        256,
        256
    },
    {
        330,
        620,
        256,
        256
    },
    {
        660,
        620,
        256,
        256
    }
}
Farm.ICON_SLICE_IDS = {
    "gui.multiplayer_chicken",
    "gui.multiplayer_goat",
    "gui.multiplayer_pig",
    "gui.multiplayer_horse",
    "gui.multiplayer_bull",
    "gui.multiplayer_chainsaw",
    "gui.multiplayer_barn",
    "gui.multiplayer_vehicle"
}
Farm.COLOR_SPECTATOR = {
    0,
    0,
    0,
    0
}
Farm.COLOR_NO_FARM = {
    0.89627,
    0.92158,
    0.81485,
    1
}
Farm.COLOR_SINGLEPLAYER = {
    0.22323,
    0.40724,
    0.00368,
    1
}
local Farm_mt = Class(Farm, Object)
InitStaticObjectClass(Farm, "Farm")
function Farm.new(isServer, isClient, spectator, customMt)
    -- upvalues: (copy) Farm_mt
    local self = Object.new(isServer, isClient, customMt or Farm_mt)
    self.farmId = nil
    self.name = ""
    self.color = 1
    self.showInFarmScreen = true
    self.isSpectator = spectator or false
    self:setInitialEconomy()
    self.players = {}
    self.uniqueUserIdToPlayer = {}
    self.userIdToPlayer = {}
    self.activeUsers = {}
    self.contractingFor = {}
    self.stats = FarmStats.new()
    g_messageCenter:subscribe(MessageType.FARM_PROPERTY_CHANGED, self.farmPropertyChanged, self)
    if self.isServer then
        g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.periodChanged, self)
    end
    self.farmMoneyDirtyFlag = self:getNextDirtyFlag()
    self.lastMoneySent = self.money
    self.lastMoneyPublished = self.money
    return self
end
function Farm:setInitialEconomy()
    self.loanMax = 0
    self:updateMaxLoan()
    if self.isSpectator then
        self.money = 0
        self.loan = 0
    else
        self.money = g_currentMission.missionInfo.initialMoney
        self.loan = g_currentMission.missionInfo.initialLoan
    end
end
function Farm:delete()
    g_messageCenter:unsubscribeAll(self)
    Farm:superClass().delete(self)
end
function Farm:loadFromXMLFile(xmlFile, key)
    self.farmId = xmlFile:getInt(key .. "#farmId")
    self.name = xmlFile:getString(key .. "#name")
    self.color = xmlFile:getInt(key .. "#color")
    self.password = xmlFile:getString(key .. "#password")
    self.loan = xmlFile:getFloat(key .. "#loan", 0)
    self.money = xmlFile:getFloat(key .. "#money", 9999999999)
    for _, playerKey in xmlFile:iterator(key .. ".players.player") do
        local player = {
            ["uniqueUserId"] = xmlFile:getString(playerKey .. "#uniqueUserId"),
            ["isFarmManager"] = xmlFile:getBool(playerKey .. "#farmManager", false),
            ["lastNickname"] = xmlFile:getString(playerKey .. "#lastNickname", ""),
            ["timeLastConnected"] = xmlFile:getString(playerKey .. "#timeLastConnected") or getDate("%Y/%m/%d %H:%M"),
            ["permissions"] = {}
        }
        for _, permission in ipairs(Farm.PERMISSIONS) do
            player.permissions[permission] = xmlFile:getBool(playerKey .. "#" .. permission, false) or player.isFarmManager
        end
        table.insert(self.players, player)
        self.uniqueUserIdToPlayer[player.uniqueUserId] = player
    end
    for _, playerKey in xmlFile:iterator(key .. ".contracting.farm") do
        local player = xmlFile:getInt(playerKey .. "#farmId")
        self.contractingFor[player] = true
    end
    self.stats:loadFromXMLFile(xmlFile, key)
    return true
end
function Farm:saveToXMLFile(xmlFile, key)
    xmlFile:setInt(key .. "#farmId", self.farmId)
    xmlFile:setString(key .. "#name", self.name)
    xmlFile:setInt(key .. "#color", self.color)
    if self.password ~= nil then
        xmlFile:setString(key .. "#password", self.password)
    end
    xmlFile:setFloat(key .. "#loan", self.loan)
    xmlFile:setFloat(key .. "#money", self.money)
    local playersToSave = table.clone(self.players)
    table.sort(playersToSave, function(a, b)
        return a.timeLastConnected > b.timeLastConnected
    end)
    local yearCur, monthCur, dayCur, hourCur, minuteCur = string.match(getDate("%Y/%m/%d %H:%M"), "(%d+)/(%d+)/(%d+) (%d+):(%d+)")
    local maxTimeSinceLastConnectionSec = tonumber(yearCur)
    local maxTimeSinceLastConnectionSec = tonumber(monthCur)
    local maxTimeSinceLastConnectionSec = tonumber(dayCur)
    local maxTimeSinceLastConnectionSec = tonumber(hourCur)
    local maxTimeSinceLastConnectionSec = tonumber(minuteCur)
    local xmlIndex = 0
    for i, player in ipairs(playersToSave) do
        local playerKey = string.format("%s.players.player(%d)", key, xmlIndex)
        if Farm.MAX_NUM_SAVED_PLAYERS <= xmlIndex then
            local year, month, day, hour, minute = string.match(player.timeLastConnected, "(%d+)/(%d+)/(%d+) (%d+):(%d+)")
            local value = tonumber(year)
            local value = tonumber(month)
            local value = tonumber(day)
            local value = tonumber(hour)
            local value = tonumber(minute)
            if value then
                if maxTimeSinceLastConnectionSec < math.abs((getDateDiffSeconds(value, value, value, value, value, 0, Farm.MAX_NUM_DAYS_OFFLINE * 24 * 60 * 60, maxTimeSinceLastConnectionSec, maxTimeSinceLastConnectionSec, maxTimeSinceLastConnectionSec, maxTimeSinceLastConnectionSec, 0))) then
                    Logging.info("Excluded %d players from \'%s\': Limit reached and affected players did not join the server for more than %d days", #playersToSave - xmlIndex, xmlFile:getFilename(), Farm.MAX_NUM_DAYS_OFFLINE)
                    break
                end
            end
        end
        xmlFile:setString(playerKey .. "#uniqueUserId", player.uniqueUserId)
        xmlFile:setBool(playerKey .. "#farmManager", player.isFarmManager)
        xmlFile:setString(playerKey .. "#lastNickname", player.lastNickname or "")
        xmlFile:setString(playerKey .. "#timeLastConnected", player.timeLastConnected)
        for hour, minute in ipairs(Farm.PERMISSIONS) do
            local value = Utils.getNoNil(player.permissions[minute], false)
            xmlFile:setBool(playerKey .. "#" .. minute, value)
        end
        xmlIndex = xmlIndex + 1
    end
    xmlFile:setTable(key .. ".contracting.farm", self.contractingFor, function(contractKey, _, farmId)
        -- upvalues: (copy) xmlFile
        xmlFile:setInt(contractKey .. "#farmId", farmId)
    end)
    self.stats:saveToXMLFile(xmlFile, key)
end
function Farm:writeStream(streamId, connection)
    Farm:superClass().writeStream(self, streamId, connection)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    streamWriteString(streamId, self.name)
    streamWriteUIntN(streamId, self.color, Farm.COLOR_SEND_NUM_BITS)
    streamWriteFloat32(streamId, self.money)
    streamWriteFloat32(streamId, self.loan)
    streamWriteBool(streamId, self.isSpectator)
    streamWriteBool(streamId, self.showInFarmScreen)
    streamWriteUInt8(streamId, #self.activeUsers)
    for _, player in ipairs(self.activeUsers) do
        User.streamWriteUserId(streamId, player.userId)
        streamWriteBool(streamId, player.isFarmManager)
        for _, permission in ipairs(Farm.PERMISSIONS) do
            streamWriteBool(streamId, player.permissions[permission] or player.isFarmManager)
        end
    end
    streamWriteUInt8(streamId, table.size(self.contractingFor))
    for _, player in pairs(self.contractingFor) do
        streamWriteUIntN(streamId, _, FarmManager.FARM_ID_SEND_NUM_BITS)
    end
end
function Farm:readStream(streamId, connection)
    Farm:superClass().readStream(self, streamId, connection)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.name = streamReadString(streamId)
    self.color = streamReadUIntN(streamId, Farm.COLOR_SEND_NUM_BITS)
    self.money = streamReadFloat32(streamId)
    self.loan = streamReadFloat32(streamId)
    self.isSpectator = streamReadBool(streamId)
    self.showInFarmScreen = streamReadBool(streamId)
    if self.farmId == FarmManager.SPECTATOR_FARM_ID then
        self.isSpectator = true
    end
    local numPlayers = streamReadUInt8(streamId)
    self.players = {}
    self.activeUsers = {}
    for _ = 1, numPlayers do
        local player = {
            ["userId"] = User.streamReadUserId(streamId),
            ["isFarmManager"] = streamReadBool(streamId),
            ["permissions"] = {}
        }
        for _, permission in ipairs(Farm.PERMISSIONS) do
            player.permissions[permission] = streamReadBool(streamId)
        end
        self.userIdToPlayer[player.userId] = player
        table.insert(self.players, player)
        table.insert(self.activeUsers, player)
    end
    local numContracting = streamReadUInt8(streamId)
    local player = 1
    for player = player, numContracting do
        local farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
        self.contractingFor[farmId] = true
    end
end
function Farm:writeUpdateStream(streamId, connection, dirtyMask)
    Farm:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
    if streamWriteBool(streamId, bit32.band(dirtyMask, self.farmMoneyDirtyFlag) ~= 0) then
        streamWriteFloat32(streamId, self.money)
        self.lastMoneySent = self.money
    end
end
function Farm:readUpdateStream(streamId, timestamp, connection)
    Farm:superClass().readUpdateStream(self, streamId, timestamp, connection)
    if streamReadBool(streamId) then
        self.money = streamReadFloat32(streamId)
        g_messageCenter:publish(MessageType.MONEY_CHANGED, self.farmId, self.money)
    end
end
function Farm:merge(other)
    self.money = self.money + other.money
    self.loan = self.loan + other.loan
    self.stats:merge(other.stats)
end
function Farm:resetToSingleplayer()
    local player = {
        ["uniqueUserId"] = getUniqueUserId(),
        ["isFarmManager"] = true,
        ["permissions"] = {}
    }
    for _, permission in ipairs(Farm.PERMISSIONS) do
        player.permissions[permission] = true
    end
    player.timeLastConnected = getDate("%Y/%m/%d %H:%M")
    self.players = { player }
    self.color = 1
    self.uniqueUserIdToPlayer[player.uniqueUserId] = player
end
function Farm:getId()
    return self.farmId
end
function Farm:getFarmhouse()
    return g_currentMission.placeableSystem:getFarmhouse(self.farmId)
end
function Farm:getSpawnPoint()
    if not self.isSpectator then
        local farmhouse = self:getFarmhouse()
        if farmhouse ~= nil then
            return farmhouse:getSpawnPoint()
        end
    end
    return g_mission00StartPoint
end
function Farm:getSleepCamera()
    if not self.isSpectator then
        local farmhouse = self:getFarmhouse()
        if farmhouse ~= nil then
            return farmhouse:getSleepCamera()
        end
    end
    return nil
end
function Farm:getNumActivePlayers()
    return #self.activeUsers
end
function Farm:getNumPlayers()
    return #self.players
end
function Farm:getActiveUsers()
    return self.activeUsers
end
function Farm:isUserFarmManager(userId)
    local player = self.userIdToPlayer[userId]
    return player ~= nil and player.isFarmManager
end
function Farm:getUserPermissions(userId)
    local player = self.userIdToPlayer[userId]
    return player ~= nil and player.permissions or Farm.NO_PERMISSIONS
end
function Farm:setUserPermission(userId, permission, hasPermission)
    local player = self.userIdToPlayer[userId]
    if player ~= nil then
        player.permissions[permission] = hasPermission
        g_client:getServerConnection():sendEvent(PlayerPermissionsEvent.new(userId, player.permissions, player.isFarmManager))
    end
end
function Farm:promoteUser(userId)
    if self.userIdToPlayer[userId] ~= nil then
        local fullPermissions = {}
        for _, permissionKey in ipairs(Farm.PERMISSIONS) do
            fullPermissions[permissionKey] = true
        end
        g_client:getServerConnection():sendEvent(PlayerPermissionsEvent.new(userId, fullPermissions, true))
    end
end
function Farm:demoteUser(userId)
    if self.userIdToPlayer[userId] ~= nil then
        local fullPermissions = {}
        for _, permissionKey in ipairs(Farm.PERMISSIONS) do
            fullPermissions[permissionKey] = false
        end
        g_client:getServerConnection():sendEvent(PlayerPermissionsEvent.new(userId, fullPermissions, false))
    end
end
function Farm:canBeDestroyed()
    if #self.activeUsers > 0 then
        return false, "ui_farmDeleteHasPlayers"
    else
        return true
    end
end
function Farm:getColor()
    if g_currentMission.missionDynamicInfo.isMultiplayer then
        if self.isSpectator then
            return Farm.COLOR_SPECTATOR
        else
            return Farm.COLORS[self.color]
        end
    else
        return Farm.COLOR_SINGLEPLAYER
    end
end
function Farm:getIconUVs()
    return Farm.ICON_UVS[self.color]
end
function Farm:getIconSliceId()
    return Farm.ICON_SLICE_IDS[self.color]
end
function Farm:getIsContractingFor(farmId)
    return self.contractingFor[farmId] or false
end
function Farm:setIsContractingFor(farmId, isContracting, noSendEvent)
    if self.isServer or noSendEvent then
        if isContracting then
            self.contractingFor[farmId] = true
        else
            self.contractingFor[farmId] = nil
        end
        if self.isServer and not noSendEvent then
            g_server:broadcastEvent(ContractingStateEvent.new(self.farmId, farmId, isContracting))
        end
        g_messageCenter:publish(ContractingStateEvent, self.farmId, farmId, isContracting)
    elseif not noSendEvent then
        g_client:getServerConnection():sendEvent(ContractingStateEvent.new(self.farmId, farmId, isContracting))
    end
end
function Farm:farmPropertyChanged(farmId)
    if farmId == self.farmId and not self.isSpectator then
        self:updateMaxLoan()
    end
end
function Farm:getEquity()
    local equity = 0
    local farmlands = g_farmlandManager:getOwnedFarmlandIdsByFarmId(self.farmId)
    for _, farmlandId in pairs(farmlands) do
        equity = equity + g_farmlandManager:getFarmlandById(farmlandId).price
    end
    for _, farmlandId in pairs(g_currentMission.placeableSystem.placeables) do
        if farmlandId:getOwnerFarmId() == self.farmId then
            equity = equity + farmlandId:getMonetaryValue()
        end
    end
    return equity
end
function Farm:updateMaxLoan()
    local roundedTo5000 = MathUtil.snapValue(Farm.EQUITY_LOAN_RATIO * self:getEquity(), 5000)
    self.loanMax = math.clamp(roundedTo5000, Farm.MIN_LOAN, Farm.MAX_LOAN)
end
function Farm:calculateDailyLoanInterest()
    return math.floor(Farm.LOAN_INTEREST_RATE / (g_currentMission.environment.daysPerPeriod * Environment.PERIODS_IN_YEAR) * self.loan)
end
function Farm:changeBalance(amount, moneyType)
    self.money = self.money + amount
    self.stats:changeFinanceStats(amount, moneyType ~= nil and moneyType.statistic or nil)
    if amount > 0 then
        self.stats:addHeroStat("moneyEarned", amount)
    end
    if math.abs(self.lastMoneyPublished - self.money) >= 1 then
        ::l7::
        self:raiseDirtyFlags(self.farmMoneyDirtyFlag)
        self.lastMoneyPublished = self.money
        g_messageCenter:publish(MessageType.MONEY_CHANGED, self.farmId, self.money)
        goto l9
    else
        if g_currentMission.missionDynamicInfo.isMultiplayer then
            if math.abs(self.lastMoneySent - self.money) >= 1 then
                goto l7
            end
        end
        ::l9::
        return
    end
end
function Farm:addPurchasedCoins(amount)
    self.money = self.money + amount
    g_messageCenter:publish(MessageType.MONEY_CHANGED, self.farmId, self.money)
end
function Farm:getBalance()
    return self.money
end
function Farm:getLoan()
    return self.loan
end
function Farm:periodChanged()
    self.stats:archiveFinances()
end
function Farm:addUser(userId, uniqueUserId, isFarmManager, user)
    if g_currentMission.connectedToDedicatedServer and userId == g_currentMission:getServerUserId() then
        return
    elseif self.userIdToPlayer[userId] == nil then
        local player = {}
        isFarmManager = isFarmManager or false
        player.isFarmManager = isFarmManager
        player.userId = userId
        player.permissions = {}
        for _, permission in ipairs(Farm.PERMISSIONS) do
            player.permissions[permission] = isFarmManager
        end
        if not isFarmManager then
            for _, permission in pairs(Farm.DEFAULT_PERMISSIONS) do
                player.permissions[permission] = true
            end
        end
        if self.isServer then
            player.uniqueUserId = uniqueUserId
            player.timeLastConnected = getDate("%Y/%m/%d %H:%M")
            self.uniqueUserIdToPlayer[uniqueUserId] = player
        end
        table.insert(self.players, player)
        table.insert(self.activeUsers, player)
        self.userIdToPlayer[userId] = player
        self:updateLastNickname(userId, user)
    end
end
function Farm:removeUser(userId)
    local player = self.userIdToPlayer[userId]
    if player ~= nil then
        table.removeElement(self.players, player)
        table.removeElement(self.activeUsers, player)
        self.userIdToPlayer[userId] = nil
        if self.isServer then
            self.uniqueUserIdToPlayer[player.uniqueUserId] = nil
        end
    end
end
function Farm:onUserJoinGame(uniqueUserId, userId, user)
    if not g_currentMission.connectedToDedicatedServer or userId ~= g_currentMission:getServerUserId() then
        if self.isSpectator and self.uniqueUserIdToPlayer[uniqueUserId] == nil then
            self:addUser(userId, uniqueUserId, nil, user)
            return true
        end
        if self.userIdToPlayer[userId] ~= nil then
            return false
        end
        player.userId = userId
        self.userIdToPlayer[userId] = player
        self:updateLastNickname(userId, user)
        table.insert(self.activeUsers, player)
        return true
    end
end
function Farm:onUserQuitGame(userId)
    local player = self.userIdToPlayer[userId]
    if player ~= nil then
        player.userId = nil
        self.userIdToPlayer[userId] = nil
        table.removeElement(self.activeUsers, player)
    end
end
function Farm:updateLastNickname(userId, user)
    if user == nil then
        user = g_currentMission.userManager:getUserByUserId(userId)
    end
    if user ~= nil then
        self.userIdToPlayer[userId].lastNickname = user:getNickname()
    end
end