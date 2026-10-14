FarmManager = {}
FarmManager.FARM_ID_SEND_NUM_BITS = 4
FarmManager.MAX_NUM_FARMS = 8
FarmManager.MAX_FARM_ID = FarmManager.MAX_NUM_FARMS
FarmManager.SPECTATOR_FARM_ID = 0
FarmManager.SINGLEPLAYER_FARM_ID = 1
FarmManager.GUIDED_TOUR_FARM_ID = FarmManager.FARM_ID_SEND_NUM_BITS ^ 2 - 2
FarmManager.INVALID_FARM_ID = FarmManager.FARM_ID_SEND_NUM_BITS ^ 2 - 1
local FarmManager_mt = Class(FarmManager, AbstractManager)
function FarmManager.new(customMt)
    -- upvalues: (copy) FarmManager_mt
    return AbstractManager.new(customMt or FarmManager_mt)
end
function FarmManager:initDataStructures()
    self.farms = {}
    self.farmIdToFarm = {}
    self.defaultHandtools = {}
    self.mergedFarms = nil
end
function FarmManager:loadMapData(xmlFile)
    FarmManager:superClass().loadMapData(self)
    if g_currentMission:getIsServer() then
        g_currentMission:addUpdateable(self)
        Farm.new(true, g_client ~= nil, true).farmId = FarmManager.SPECTATOR_FARM_ID
        spectatorFarm.isSpectator = true
        spectatorFarm.showInFarmScreen = false
        spectatorFarm.stats.updatePlayTime = false
        spectatorFarm:register()
        table.insert(self.farms, spectatorFarm)
        self.farmIdToFarm[spectatorFarm.farmId] = spectatorFarm
        Farm.new(true, g_client ~= nil, true).farmId = FarmManager.GUIDED_TOUR_FARM_ID
        guidedTourFarm.isSpectator = false
        guidedTourFarm.showInFarmScreen = false
        guidedTourFarm.stats.updatePlayTime = false
        guidedTourFarm:register()
        table.insert(self.farms, guidedTourFarm)
        self.farmIdToFarm[guidedTourFarm.farmId] = guidedTourFarm
    end
    local spectatorFarm = XMLFile.wrap(xmlFile)
    spectatorFarm:iterate("map.farms.defaultHandTools.handTool", function(_, key)
        -- upvalues: (copy) self, (copy) spectatorFarm
        table.insert(self.defaultHandtools, spectatorFarm:getString(key .. "#filename"))
    end)
    spectatorFarm:delete()
    addConsoleCommand("gsFarmSet", "Set farm for current player or vehicle", "consoleCommandSetFarm", self)
end
function FarmManager:unloadMapData()
    g_currentMission:removeUpdateable(self)
    removeConsoleCommand("gsFarmSet")
    if g_addTestCommands then
        removeConsoleCommand("debugCreateFarm")
    end
    FarmManager:superClass().unloadMapData(self)
end
function FarmManager:saveToXMLFile(xmlFilename)
    local xmlFile = XMLFile.create("farmsXML", xmlFilename, "farms")
    xmlFile:setTable("farms.farm", self.farms, function(path, farm)
        -- upvalues: (copy) xmlFile
        if farm.farmId == FarmManager.SPECTATOR_FARM_ID or farm.farmId == FarmManager.GUIDED_TOUR_FARM_ID then
            return 0
        end
        farm:saveToXMLFile(xmlFile, path)
    end)
    xmlFile:save()
    xmlFile:delete()
end
function FarmManager:loadFromXMLFile(xmlFilename)
    if xmlFilename == nil then
        self:loadDefaults()
        return false
    end
    local xmlFile = XMLFile.load("TempXML", xmlFilename)
    if xmlFile == nil then
        return false
    end
    for _, key in xmlFile:iterator("farms.farm") do
        local farm = Farm.new
        local farm = farm(true, g_client ~= nil)
        if farm:loadFromXMLFile(xmlFile, key) then
            farm:register()
            table.insert(self.farms, farm)
            self.farmIdToFarm[farm.farmId] = farm
        else
            farm:delete()
        end
    end
    self:mergeFarmsForSingleplayer()
    if g_currentMission:getIsClient() then
        self:playerJoinedGame(getUniqueUserId(), g_currentMission:getServerUserId())
    end
    xmlFile:delete()
    return true
end
function FarmManager:loadDefaults()
    if not g_currentMission.missionDynamicInfo.isMultiplayer then
        self:createFarm(g_i18n:getText("ui_defaultFarmName"), 1, nil, FarmManager.SINGLEPLAYER_FARM_ID):addUser(g_currentMission:getServerUserId(), getUniqueUserId(), true)
    end
    self:playerJoinedGame(getUniqueUserId(), g_currentMission:getServerUserId())
end
function FarmManager:mergeFarmsForSingleplayer()
    if not g_currentMission.missionDynamicInfo.isMultiplayer then
        local specFarm = self.farmIdToFarm[FarmManager.SPECTATOR_FARM_ID]
        local tourFarm = self.farmIdToFarm[FarmManager.GUIDED_TOUR_FARM_ID]
        local spFarm = self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID]
        if spFarm == nil then
            spFarm = self:createFarm(g_i18n:getText("ui_defaultFarmName"), 1, nil, FarmManager.SINGLEPLAYER_FARM_ID)
            spFarm:addUser(g_currentMission:getServerUserId(), getUniqueUserId(), true)
        end
        for _, farm in ipairs(self.farms) do
            local farmId = farm.farmId
            if farmId ~= FarmManager.SPECTATOR_FARM_ID and (farmId ~= FarmManager.GUIDED_TOUR_FARM_ID and farmId ~= FarmManager.SINGLEPLAYER_FARM_ID) then
                if self.mergedFarms == nil then
                    self.mergedFarms = {}
                end
                self.mergedFarms[farmId] = FarmManager.SINGLEPLAYER_FARM_ID
                spFarm:merge(farm)
            end
        end
        spFarm.farmId = FarmManager.SINGLEPLAYER_FARM_ID
        self.farmIdToFarm = {}
        self.farmIdToFarm[FarmManager.SPECTATOR_FARM_ID] = specFarm
        self.farmIdToFarm[FarmManager.GUIDED_TOUR_FARM_ID] = tourFarm
        self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID] = spFarm
        self.farms = { specFarm, spFarm, tourFarm }
        self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID]:resetToSingleplayer()
    end
end
function FarmManager:mergeFarmlandsForSingleplayer()
    if not g_currentMission.missionDynamicInfo.isMultiplayer and self.mergedFarms ~= nil then
        for _, farmland in pairs(g_farmlandManager:getFarmlands()) do
            local ownerFarmId = g_farmlandManager:getFarmlandOwner(farmland.id)
            local newFarmId = self.mergedFarms[ownerFarmId]
            if newFarmId ~= nil then
                g_farmlandManager:setLandOwnership(farmland.id, newFarmId, true)
            end
        end
    end
end
function FarmManager:mergeObjectsForSingleplayer()
    if not g_currentMission.missionDynamicInfo.isMultiplayer and self.mergedFarms ~= nil then
        for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
            local ownerFarmId = vehicle:getOwnerFarmId()
            local newFarmId = self.mergedFarms[ownerFarmId]
            if newFarmId ~= nil then
                vehicle:setOwnerFarmId(newFarmId)
            end
        end
        for _, vehicle in pairs(g_currentMission.placeableSystem.placeables) do
            local ownerFarmId = vehicle:getOwnerFarmId()
            local newFarmId = self.mergedFarms[ownerFarmId]
            if newFarmId ~= nil then
                vehicle:setOwnerFarmId(newFarmId)
            end
        end
        for _, vehicle in pairs(g_currentMission.handToolSystem.handTools) do
            local ownerFarmId = vehicle:getOwnerFarmId()
            local newFarmId = self.mergedFarms[ownerFarmId]
            if newFarmId ~= nil then
                vehicle:setOwnerFarmId(newFarmId)
            end
        end
        for _, vehicle in pairs(g_currentMission.itemSystem.itemsToSave) do
            local ownerFarmId = vehicle.item
            if ownerFarmId ~= nil and ownerFarmId.getOwnerFarmId ~= nil then
                local newFarmId = ownerFarmId:getOwnerFarmId()
                local newFarmId = self.mergedFarms[newFarmId]
                if newFarmId ~= nil then
                    ownerFarmId:setOwnerFarmId(newFarmId)
                end
            end
        end
    end
end
function FarmManager:delete() end
function FarmManager:update(_)
    if g_currentMission:getIsClient() and (self.mergedFarms ~= nil and not self.mergedMessageShown) then
        InfoDialog.show(g_i18n:getText("ui_farmedMergedSP"), nil, nil, DialogElement.TYPE_INFO)
        self.mergedMessageShown = true
    end
end
function FarmManager:getFarmForUniqueUserId(uniqueUserId)
    if not g_currentMission.missionDynamicInfo.isMultiplayer then
        return self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID]
    end
    for _, farm in ipairs(self.farms) do
        if not farm.isSpectator and farm.uniqueUserIdToPlayer[uniqueUserId] ~= nil then
            return farm
        end
    end
    return self.farmIdToFarm[FarmManager.SPECTATOR_FARM_ID]
end
function FarmManager:getFarmByUserId(userId)
    if not g_currentMission.missionDynamicInfo.isMultiplayer then
        return self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID]
    end
    for _, farm in ipairs(self.farms) do
        if farm.userIdToPlayer[userId] ~= nil then
            return farm
        end
    end
    return self.farmIdToFarm[0]
end
function FarmManager:getFarmById(farmId)
    return self.farmIdToFarm[farmId]
end
function FarmManager:getSpawnPoint(farmId)
    local farm = self:getFarmById(farmId)
    if farm == nil then
        return nil
    else
        return farm:getSpawnPoint()
    end
end
function FarmManager:getSleepCamera(farmId)
    local farm = self:getFarmById(farmId)
    if farm == nil then
        return nil
    else
        return farm:getSleepCamera()
    end
end
function FarmManager:updateFarms(farms, _)
    self.farms = farms
    self.farmIdToFarm = {}
    for _, farm in ipairs(self.farms) do
        self.farmIdToFarm[farm.farmId] = farm
    end
end
function FarmManager:appendFarm(farm)
    if self.farmIdToFarm[farm.farmId] == nil then
        self.farmIdToFarm[farm.farmId] = farm
        table.insert(self.farms, farm)
    end
end
function FarmManager:getFarms()
    return self.farms
end
function FarmManager:onFarmObjectCreated(object)
    if not g_currentMission:getIsServer() then
        self:appendFarm(object)
        g_messageCenter:publish(MessageType.FARM_CREATED, object.farmId)
    end
end
function FarmManager:onFarmObjectDeleted(object)
    self:removeFarm(object.farmId)
    g_messageCenter:publishDelayed(MessageType.FARM_DELETED, object.farmId)
end
function FarmManager:updateFarmStats(farmId, stat, delta)
    local farm = self.farmIdToFarm[farmId]
    if farm == nil then
        return nil, nil
    else
        return farm.stats:updateStats(stat, delta)
    end
end
function FarmManager:getFarmStatValue(farmId, stat)
    local farm = self.farmIdToFarm[farmId]
    if farm == nil then
        return 0, 0
    else
        return farm.stats:getSessionValue(stat), farm.stats:getTotalValue(stat)
    end
end
function FarmManager:playerJoinedGame(uniqueUserId, userId, user, connection)
    if g_currentMission:getIsServer() then
        local farm = self:getFarmForUniqueUserId(uniqueUserId)
        local didJoinFarm = farm:onUserJoinGame(uniqueUserId, userId, user)
        g_server:broadcastEvent(PlayerSwitchedFarmEvent.new(FarmManager.INVALID_FARM_ID, farm.farmId, userId), nil, connection)
        if didJoinFarm then
            local player = farm.userIdToPlayer[userId]
            if player ~= nil then
                g_server:broadcastEvent(PlayerPermissionsEvent.new(userId, player.permissions, player.isFarmManager), nil, connection)
                return
            end
        end
    else
        printError("Error: FarmManager:playerJoinedGame() only allowed on server")
    end
end
function FarmManager:playerQuitGame(userId)
    if g_currentMission:getIsServer() then
        local farm = self:getFarmByUserId(userId)
        farm:onUserQuitGame(userId)
        g_server:broadcastEvent(PlayerSwitchedFarmEvent.new(farm.farmId, FarmManager.INVALID_FARM_ID, userId))
    else
        printError("Error: FarmManager:playerQuitGame() only allowed on server")
    end
end
function FarmManager.transferMoney(_, destinationFarm, amount)
    g_client:getServerConnection():sendEvent(TransferMoneyEvent.new(amount, destinationFarm.farmId))
end
function FarmManager.removeUserFromFarm(_, userId)
    g_client:getServerConnection():sendEvent(RemovePlayerFromFarmEvent.new(userId))
end
function FarmManager:createFarm(name, color, password, farmId)
    if not g_currentMission:getIsServer() then
        printError("Error: FarmManager:createFarm() only allowed on server")
        return nil
    end
    if farmId ~= FarmManager.SINGLEPLAYER_FARM_ID and (not g_currentMission.missionDynamicInfo.isMultiplayer and #self.farms > 2) then
        return nil
    end
    local farm = Farm.new
    local farm = farm(true, g_client ~= nil)
    if farmId ~= FarmManager.SINGLEPLAYER_FARM_ID and #self.farms == FarmManager.MAX_NUM_FARMS + 2 then
        return nil, "Farm limit reached"
    end
    if self.farmIdToFarm[farmId] ~= nil then
        farmId = nil
    end
    if farmId == nil then
        farmId = self:findNextFarmId()
    end
    farm.farmId = farmId
    farm.name = name
    farm.color = color
    if password ~= "" then
        farm.password = password
    end
    farm:register()
    table.insert(self.farms, farm)
    self.farmIdToFarm[farm.farmId] = farm
    g_messageCenter:publish(MessageType.FARM_CREATED, farm.farmId)
    return farm
end
function FarmManager:destroyFarm(farmId)
    if g_currentMission.missionDynamicInfo.isMultiplayer then
        local farm = self.farmIdToFarm[farmId]
        if farm ~= nil then
            farm:delete()
            self:removeFarm(farmId)
            local i = #g_currentMission.vehicleSystem.vehicles
            for i = i, 1, -1 do
                local vehicle = g_currentMission.vehicleSystem.vehicles[i]
                if vehicle:getOwnerFarmId() == farmId then
                    vehicle:delete()
                end
            end
            local i = #g_currentMission.placeableSystem.placeables
            for i = i, 1, -1 do
                local vehicle = g_currentMission.placeableSystem.placeables[i]
                if vehicle:getOwnerFarmId() == farmId then
                    if vehicle:getSellAction() == Placeable.SELL_AND_SPECTATOR_FARM then
                        vehicle:setOwnerFarmId(FarmManager.SPECTATOR_FARM_ID)
                    else
                        vehicle:delete()
                    end
                end
            end
            for vehicle, item in pairs(g_currentMission.itemSystem.itemsToSave) do
                if item.getOwnerFarmId ~= nil and item:getOwnerFarmId() == farmId then
                    item:delete()
                end
            end
            g_messageCenter:publish(MessageType.FARM_DELETED, farmId)
        end
    end
end
function FarmManager:removeFarm(farmId)
    self.farmIdToFarm[farmId] = nil
    for i, farm in ipairs(self.farms) do
        if farm.farmId == farmId then
            table.remove(self.farms, i)
            return
        end
    end
end
function FarmManager:findNextFarmId()
    local i = 1
    for i = i, FarmManager.MAX_FARM_ID do
        local inUse = false
        for _, farm in ipairs(self.farms) do
            if i == farm.farmId then
                inUse = true
                break
            end
        end
        if not inUse then
            return i
        end
    end
    return nil
end
function FarmManager:consoleCommandSetFarm(farmId)
    local playerVehicle = g_localPlayer:getCurrentVehicle()
    if farmId == nil then
        if playerVehicle == nil then
            return string.format("No farmId specified. Current player farmId is %d", g_localPlayer:getFarmId())
        else
            return string.format("No farmId specified. Current vehicle farmId is %s", playerVehicle:getOwnerFarmId())
        end
    else
        local farm = tonumber(farmId)
        if playerVehicle == nil then
            g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(g_localPlayer, farm))
            return string.format("Updated farm id for player to \'%d\'", farm)
        end
        if not g_currentMission:getIsServer() then
            return "This command currently only works on server"
        end
        if self:getFarmById(farm) == nil then
            return string.format("Farm with id %d does not exist.", farm)
        end
        playerVehicle:setOwnerFarmId(farm)
        return string.format("Updated farm id for vehicle \'%s\' to \'%d\'", playerVehicle.configFileName, farm)
    end
end
g_farmManager = FarmManager.new()