AbstractMission = {}
local AbstractMission_mt = Class(AbstractMission, Object)
InitStaticObjectClass(AbstractMission, "AbstractMission")
AbstractMission.SUCCESS_FACTOR = 0.98
AbstractMission.VEHICLE_USE_COST = 200
AbstractMission.REIMBURSEMENT_FACTOR = 0.95
function AbstractMission.registerXMLPaths(schema, key) end
function AbstractMission.registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. "#uniqueId", "Mission unique id")
    MissionStatus.registerXMLPath(schema, key .. "#status", "Status of the mission", nil, false)
    MissionFinishState.registerXMLPath(schema, key .. "#finishState", "Finish state of the mission", nil, false)
    schema:register(XMLValueType.INT, key .. "#farmId", "FarmId of the mission")
    schema:register(XMLValueType.INT, key .. "#activeId", "Name active id")
    schema:register(XMLValueType.INT, key .. ".info#reward", "Reward of the mission")
    schema:register(XMLValueType.FLOAT, key .. ".info#reimbursement", "Reimbursement of the mission")
    schema:register(XMLValueType.FLOAT, key .. ".info#stealingCost", "Stealing costs")
    schema:register(XMLValueType.FLOAT, key .. ".info#completion", "Completion factor of the mission")
    schema:register(XMLValueType.INT, key .. ".vehicles#group", "Vehicle group id")
    schema:register(XMLValueType.BOOL, key .. ".vehicles#spawned", "If vehicles were spawned")
    schema:register(XMLValueType.STRING, key .. ".vehicles.vehicle(?)#uniqueId", "Vehicle unique id")
    schema:register(XMLValueType.INT, key .. ".endDate#endDay", "End day of the mission")
    schema:register(XMLValueType.INT, key .. ".endDate#endDayTime", "End daytime of the mission")
end
function AbstractMission.registerMetaXMLPaths(schema, key) end
function AbstractMission.new(isServer, isClient, title, description, customMt)
    -- upvalues: (copy) AbstractMission_mt
    local self = Object.new(isServer, isClient, customMt or AbstractMission_mt)
    self.title = title
    self.progressTitle = title
    self.description = description
    self.status = MissionStatus.CREATED
    self.finishState = MissionFinishState.NONE
    self.reward = 0
    self.reimbursement = 0
    self.completion = 0
    self.vehicles = {}
    self.info = {}
    self.pendingVehicleLoadingData = {}
    self.spawnedVehicles = false
    self.uniqueId = nil
    self.missionDirtyFlag = self:getNextDirtyFlag()
    g_messageCenter:subscribe(MessageType.FARM_DELETED, self.farmDestroyed, self)
    g_messageCenter:subscribe(MessageType.SAVEGAME_LOADED, self.onSavegameLoaded, self, nil, false)
    local data = g_missionManager:getMissionTypeDataByName(self:getMissionTypeName())
    data.numInstances = data.numInstances + 1
    return self
end
function AbstractMission:init()
    self.vehiclesToLoad, self.vehicleGroupIdentifier = self:getVehicleGroup()
    return true
end
function AbstractMission:failedToLoadFromXMLFile()
    g_messageCenter:unsubscribe(MessageType.SAVEGAME_LOADED, self)
end
function AbstractMission:onSavegameLoaded()
    if self:getWasStarted() then
        self:reactivate()
    end
end
function AbstractMission:reactivate()
    if self.spawnedVehicles then
        g_messageCenter:subscribe(MessageType.VEHICLE_RESET, self.onVehicleReset, self)
    end
end
function AbstractMission:getMapHotspots()
    return nil
end
function AbstractMission:delete()
    AbstractMission:superClass().delete(self)
    self:removeAccess()
    g_messageCenter:unsubscribeAll(self)
    g_missionManager:removeMission(self)
    g_messageCenter:publish(MessageType.MISSION_DELETED, self)
    local data = g_missionManager:getMissionTypeDataByName(self:getMissionTypeName())
    if data ~= nil then
        data.numInstances = math.max(data.numInstances - 1, 0)
    end
end
function AbstractMission:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
    MissionStatus.saveToXMLFile(xmlFile, key .. "#status", self.status)
    MissionFinishState.saveToXMLFile(xmlFile, key .. "#finishState", self.finishState)
    if self.farmId ~= nil then
        xmlFile:setValue(key .. "#farmId", self.farmId)
    end
    if self.activeMissionId ~= nil then
        xmlFile:setValue(key .. "#activeId", self.activeMissionId)
    end
    xmlFile:setValue(key .. ".info#reward", self.reward)
    xmlFile:setValue(key .. ".info#reimbursement", self.reimbursement)
    xmlFile:setValue(key .. ".info#completion", self.completion)
    if self.stealingCost ~= nil then
        xmlFile:setValue(key .. ".info#stealingCost", self.stealingCost)
    end
    xmlFile:setValue(key .. ".vehicles#spawned", self.spawnedVehicles)
    xmlFile:setValue(key .. ".vehicles#group", self.vehicleGroupIdentifier)
    for k, vehicle in ipairs(self.vehicles) do
        xmlFile:setValue(string.format(key .. ".vehicles.vehicle(%d)#uniqueId", k - 1), vehicle.uniqueId)
    end
    if self.endDate ~= nil then
        xmlFile:setValue(key .. ".endDate#endDay", self.endDate.endDay)
        xmlFile:setValue(key .. ".endDate#endDayTime", self.endDate.endDayTime)
    end
end
function AbstractMission:loadFromXMLFile(xmlFile, key)
    self.activeMissionId = xmlFile:getValue(key .. "#activeId")
    self.status = MissionStatus.loadFromXMLFile(xmlFile, key .. "#status")
    if self.status == nil then
        Logging.xmlError(xmlFile, "Invalid mission status for \'%s\'", key)
        return false
    end
    self.finishState = MissionFinishState.loadFromXMLFile(xmlFile, key .. "#finishState") or MissionFinishState.NONE
    local uniqueId = xmlFile:getValue(key .. "#uniqueId", nil)
    if uniqueId ~= nil then
        self:setUniqueId(uniqueId)
    end
    self.farmId = xmlFile:getValue(key .. "#farmId")
    self.reward = xmlFile:getValue(key .. ".info#reward") or self.reward
    self.reimbursement = xmlFile:getValue(key .. ".info#reimbursement") or self.reimbursement
    self.completion = xmlFile:getValue(key .. ".info#completion") or self.completion
    self.stealingCost = xmlFile:getValue(key .. ".info#stealingCost")
    local endDay = xmlFile:getValue(key .. ".endDate#endDay")
    local endDayTime = xmlFile:getValue(key .. ".endDate#endDayTime")
    if endDay ~= nil and endDayTime ~= nil then
        self:setEndDate(endDay, endDayTime)
    end
    self.spawnedVehicles = xmlFile:getValue(key .. ".vehicles#spawned", self.spawnedVehicles)
    self.vehicleGroupIdentifier = xmlFile:getValue(key .. ".vehicles#group")
    local vehicleVariant, _, _, vehicleGroup = self:getVehicleGroupFromIdentifier(self.vehicleGroupIdentifier)
    self.vehiclesToLoad = vehicleVariant
    local vehicleVariant = self:getVehicleVariant()
    if vehicleVariant ~= nil and (vehicleGroup ~= nil and vehicleGroup.variant ~= vehicleVariant) then
        Logging.xmlWarning(xmlFile, "Loading vehicle group identifier does not match mission variant anymore. Skipping mission \'%s\'", key)
        return false
    end
    if self.vehiclesToLoad == nil then
        self.vehiclesToLoad, self.vehicleGroupIdentifier = self:getVehicleGroup()
        if self.vehiclesToLoad == nil then
            Logging.xmlWarning(xmlFile, "Loading vehicle group failed. Skipping mission \'%s\'", key)
            return false
        end
    end
    if self.spawnedVehicles and (self.status ~= MissionStatus.FINISHED and self.status ~= MissionStatus.DISMISSED) then
        self.tryToAddMissingVehicles = true
    end
    for _, vehicleKey in xmlFile:iterator(key .. ".vehicles.vehicle") do
        local vehicleUniqueId = xmlFile:getValue(vehicleKey .. "#uniqueId")
        if self.pendingVehicleUniqueIds == nil then
            self.pendingVehicleUniqueIds = {}
        end
        table.insert(self.pendingVehicleUniqueIds, vehicleUniqueId)
    end
    return true
end
function AbstractMission:writeStream(streamId, connection)
    AbstractMission:superClass().writeStream(self, streamId, connection)
    streamWriteUInt8(streamId, self.type.typeId)
    streamWriteFloat32(streamId, self.reward)
    streamWriteFloat32(streamId, self.reimbursement)
    MissionStatus.writeStream(streamId, self.status)
    streamWriteBool(streamId, self.spawnedVehicles)
    streamWriteInt32(streamId, self.vehicleGroupIdentifier)
    if self:getWasStarted() then
        streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    end
    if self.status == MissionStatus.RUNNING or self.status == MissionStatus.PREPARING then
        streamWriteInt32(streamId, self.activeMissionId)
    elseif self.status == MissionStatus.FINISHED then
        streamWriteFloat32(streamId, self.stealingCost or 0)
        MissionFinishState.writeStream(streamId, self.finishState)
    end
    if streamWriteBool(streamId, self.endDate ~= nil) then
        streamWriteInt32(streamId, self.endDate.endDay)
        streamWriteFloat32(streamId, self.endDate.endDayTime)
    end
end
function AbstractMission:readStream(streamId, connection)
    AbstractMission:superClass().readStream(self, streamId, connection)
    self.type = g_missionManager:getMissionTypeById(streamReadUInt8(streamId))
    self.reward = streamReadFloat32(streamId)
    self.reimbursement = streamReadFloat32(streamId)
    self.status = MissionStatus.readStream(streamId)
    self.spawnedVehicles = streamReadBool(streamId)
    self.vehicleGroupIdentifier = streamReadInt32(streamId)
    self.vehiclesToLoad = self:getVehicleGroupFromIdentifier(self.vehicleGroupIdentifier)
    if self:getWasStarted() then
        self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    end
    if self.status == MissionStatus.RUNNING or self.status == MissionStatus.PREPARING then
        self.activeMissionId = streamReadInt32(streamId)
    elseif self.status == MissionStatus.FINISHED then
        self.stealingCost = streamReadFloat32(streamId)
        self.finishState = MissionFinishState.readStream(streamId)
    end
    if streamReadBool(streamId) then
        self:setEndDate(streamReadInt32(streamId), (streamReadFloat32(streamId)))
    end
    g_missionManager:assignGenerationTime(self)
    table.insert(g_missionManager.missions, self)
    g_messageCenter:publishDelayed(MessageType.MISSION_GENERATED, self)
end
function AbstractMission:writeUpdateStream(streamId, _, _)
    MissionStatus.writeStream(streamId, self.status)
    streamWriteFloat32(streamId, self.completion)
end
function AbstractMission:readUpdateStream(streamId, _, _)
    self:setStatus((MissionStatus.readStream(streamId)))
    self.completion = streamReadFloat32(streamId)
end
function AbstractMission:writeStreamMissionStartedInfo(streamId, _)
    MissionStatus.writeStream(streamId, self.status)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    streamWriteInt32(streamId, self.activeMissionId)
    streamWriteBool(streamId, self.spawnedVehicles)
end
function AbstractMission:readStreamMissionStartedInfo(streamId, _)
    self.status = MissionStatus.readStream(streamId)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.activeMissionId = streamReadInt32(streamId)
    self.spawnedVehicles = streamReadBool(streamId)
end
function AbstractMission:update(_)
    if self.pendingVehicleUniqueIds ~= nil then
        local i = #self.pendingVehicleUniqueIds
        for i = i, 1, -1 do
            local vehicle = g_currentMission.vehicleSystem:getVehicleByUniqueId(self.pendingVehicleUniqueIds[i])
            if vehicle ~= nil then
                table.remove(self.pendingVehicleUniqueIds, i)
                table.insert(self.vehicles, vehicle)
            end
        end
        if #self.pendingVehicleUniqueIds == 0 then
            self.pendingVehicleUniqueIds = nil
        end
    end
    if self.tryToAddMissingVehicles and self.pendingVehicleUniqueIds == nil then
        if #self.vehicles ~= #self.vehiclesToLoad then
            for uniqueId, vehicle in ipairs(self.vehiclesToLoad) do
                local found = false
                for _, vehicle in ipairs(self.vehicles) do
                    if vehicle.filename == vehicle.configFileName then
                        found = true
                        break
                    end
                end
                if not found then
                    self:spawnVehicle(vehicle)
                end
            end
        end
        self.tryToAddMissingVehicles = false
    end
    if self.isServer and self.status == MissionStatus.PREPARING then
        if self:getIsPrepared() then
            self:finishedPreparing()
        end
        if self.failedToLoadVehicles and #self.pendingVehicleLoadingData == 0 then
            self:finish(MissionFinishState.FAILED)
        end
    end
    if self.status == MissionStatus.RUNNING and self.isServer then
        if self:isTimedOut() then
            self:finish(MissionFinishState.TIMED_OUT)
        elseif not self:validate() then
            self:finish(MissionFinishState.FAILED)
        end
    end
    if (self.status == MissionStatus.RUNNING or self.status == MissionStatus.FINISHED) and (g_localPlayer ~= nil and g_localPlayer.farmId == self.farmId) then
        if self.progressBar == nil then
            self.progressBar = mission.hud:addSideNotificationProgressBar(g_i18n:getText("contract_title"), self.progressTitle, self.completion)
        end
        self.progressBar.progress = self.completion
        mission.hud:markSideNotificationProgressBarForDrawing(self.progressBar)
    end
    if self.status == MissionStatus.RUNNING or self.status == MissionStatus.PREPARING then
        self:raiseActive()
    end
end
function AbstractMission:updateTick(_)
    if self.isServer and self.status == MissionStatus.RUNNING then
        if self.lastCompletion == nil then
            self.lastCompletion = g_currentMission.time
        elseif self.lastCompletion < mission.time - 2500 then
            self.completion = self:getCompletion()
            if self.completion >= 0.995 then
                self:finish(MissionFinishState.SUCCESS)
            end
        end
        if self.lastCompletion ~= self.completion then
            self:raiseDirtyFlags(self.missionDirtyFlag)
        end
    end
end
function AbstractMission:start(spawnVehicles)
    self:prepare(spawnVehicles)
    self:raiseActive()
    g_server:broadcastEvent(MissionStartedEvent.new(self))
    return true
end
function AbstractMission:prepare(spawnVehicles)
    self:setStatus(MissionStatus.PREPARING)
    if self.isServer and (spawnVehicles and self.vehiclesToLoad ~= nil) then
        self:spawnVehicles()
        g_messageCenter:subscribe(MessageType.VEHICLE_RESET, self.onVehicleReset, self)
    end
end
function AbstractMission:getIsPrepared()
    if not self.spawnedVehicles then
        return true
    end
    return #self.vehiclesToLoad == #self.vehicles
end
function AbstractMission:finishedPreparing()
    self:setStatus(MissionStatus.RUNNING)
end
function AbstractMission:started() end
function AbstractMission:finish(finishState)
    self:setStatus(MissionStatus.FINISHED)
    self.finishState = finishState
    if finishState ~= MissionFinishState.SUCCESS then
        self:removeAccess()
    end
    local mission = g_currentMission
    if mission:getIsServer() then
        if finishState == MissionFinishState.SUCCESS then
            g_farmManager:getFarmById(self.farmId).stats:updateMissionDone()
        end
        self.stealingCost = self:calculateStealingCost()
        g_server:broadcastEvent(MissionFinishedEvent.new(self, finishState, self.stealingCost))
    end
    mission.hud:removeSideNotificationProgressBar(self.progressBar)
    g_messageCenter:publish(MissionFinishedEvent, self, finishState)
end
function AbstractMission:dismiss()
    if self.status ~= MissionStatus.DISMISSED then
        self:setStatus(MissionStatus.DISMISSED)
        if self.finishState == MissionFinishState.SUCCESS then
            self:removeAccess()
        end
        if self.isServer then
            local change = self:getTotalReward()
            if change ~= 0 then
                g_currentMission:addMoney(change, self.farmId, MoneyType.MISSIONS, true, true)
            end
        end
    end
end
function AbstractMission:setStatus(status)
    if self.status ~= status then
        self.status = status
        g_messageCenter:publishDelayed(MessageType.MISSION_STATUS_CHANGED, self, status)
    end
end
function AbstractMission:calculateStealingCost()
    return 0
end
function AbstractMission:getUniqueId()
    return self.uniqueId
end
function AbstractMission:setUniqueId(uniqueId)
    self.uniqueId = uniqueId
end
function AbstractMission:spawnVehicles()
    for _, info in ipairs(self.vehiclesToLoad) do
        self:spawnVehicle(info)
    end
    self.spawnedVehicles = #self.vehiclesToLoad > 0
end
function AbstractMission:spawnVehicle(info)
    local data = VehicleLoadingData.new()
    data:setFilename(info.filename)
    if data.isValid then
        if info.configurations ~= nil then
            data:setConfigurations(info.configurations)
        end
        local mission = g_currentMission
        data:setLoadingPlace(mission.storeSpawnPlaces, mission.usedStorePlaces)
        data:setPropertyState(VehiclePropertyState.MISSION)
        data:setOwnerFarmId(self.farmId)
        table.insert(self.pendingVehicleLoadingData, data)
        data:load(self.onSpawnedVehicle, self, {
            ["loadingData"] = data,
            ["vehicleInfo"] = info
        })
    end
end
function AbstractMission:onSpawnedVehicle(vehicles, vehicleLoadState, loadingInfo)
    table.removeElement(self.pendingVehicleLoadingData, loadingInfo.loadingData)
    if self.failedToLoadVehicles then
        for _, vehicle in ipairs(vehicles) do
            vehicle:delete()
        end
        return
    elseif vehicleLoadState == VehicleLoadingState.OK then
        for _, vehicle in ipairs(vehicles) do
            vehicle:addWearAmount(math.random() * 0.3 + 0.1)
            vehicle:setOperatingTime(3600000 * (math.random() * 40 + 30))
            table.insert(self.vehicles, vehicle)
        end
    else
        self.failedToLoadVehicles = true
        for _, vehicle in ipairs(vehicles) do
            vehicle:delete()
        end
        for _, vehicle in ipairs(self.pendingVehicleLoadingData) do
            vehicle:cancelLoading()
        end
        table.clear(self.pendingVehicleLoadingData)
        table.clear(self.vehiclesToLoad)
        self.spawnedVehicles = false
        for _, vehicle in ipairs(self.vehicles) do
            vehicle:delete()
        end
        table.clear(self.vehicles)
    end
end
function AbstractMission:getStealingCosts()
    return 0
end
function AbstractMission:getVehicleCosts()
    if self.vehiclesToLoad == nil then
        return 0
    end
    return #self.vehiclesToLoad * AbstractMission.VEHICLE_USE_COST * (0.7 + 0.3 * g_currentMission.missionInfo.economicDifficulty)
end
function AbstractMission:getReward()
    return 0
end
function AbstractMission:getReimbursement()
    return self.reimbursement
end
function AbstractMission:calculateReimbursement() end
function AbstractMission:getActualVehicleCosts()
    return not self.spawnedVehicles and 0 or self:getVehicleCosts()
end
function AbstractMission:getActualReward()
    return self.finishState ~= MissionFinishState.SUCCESS and 0 or self:getReward()
end
function AbstractMission:getActualStealingCosts()
    return self:getStealingCosts()
end
function AbstractMission:getTotalReward()
    local reward = self:getActualReward()
    local vehicleCosts = self:getActualVehicleCosts()
    local stealingCosts = self:getActualStealingCosts()
    local reimbursement = self:getReimbursement()
    return reward - vehicleCosts - stealingCosts + reimbursement
end
function AbstractMission:validate(_)
    return not self:isTimedOut()
end
function AbstractMission:isTimedOut()
    local minutesLeft = self:getMinutesLeft()
    if minutesLeft == nil then
        return false
    end
    return minutesLeft <= 0
end
function AbstractMission:getMinutesLeft()
    local endDate = self.endDate
    if endDate == nil then
        return nil
    end
    local environment = g_currentMission.environment
    local currentMonotonicDay = environment.currentMonotonicDay
    local dayTime = environment.dayTime
    local endDay = endDate.endDay
    local endDayTime = endDate.endDayTime
    local dayTimeDelta = 0
    if dayTime < endDayTime then
        dayTimeDelta = endDayTime - dayTime
    elseif currentMonotonicDay < endDay then
        dayTimeDelta = dayTime + (86400000 - endDayTime)
    end
    return (dayTimeDelta + (endDay - currentMonotonicDay) * 86400000) / 60000
end
function AbstractMission:setDefaultEndDate()
    local environment = g_currentMission.environment
    local currentMonotonicDay = environment.currentMonotonicDay
    self:setEndDate(currentMonotonicDay + (environment.daysPerPeriod - environment:getDayInPeriodFromDay(currentMonotonicDay)), 86399999)
end
function AbstractMission:setEndDateByOffset(dayTimeOffset)
    local environment = g_currentMission.environment
    local endDay, endDayTime = environment:getDayAndDayTime(dayTimeOffset, environment.currentMonotonicDay)
    self:setEndDate(endDay, endDayTime)
end
function AbstractMission:setEndDate(endDay, endDayTime)
    self.endDate = {
        ["endDay"] = endDay,
        ["endDayTime"] = endDayTime
    }
end
function AbstractMission:getIsInProgress()
    return self.status == MissionStatus.PREPARING or self.status == MissionStatus.RUNNING
end
function AbstractMission:getIsRunning()
    return self.status == MissionStatus.RUNNING
end
function AbstractMission:getWasRunning()
    return self.status == MissionStatus.RUNNING or (self.status == MissionStatus.FINISHED or self.status == MissionStatus.DISMISSED)
end
function AbstractMission:getIsReadyToStart()
    return self.status == MissionStatus.CREATED
end
function AbstractMission:getWasStarted()
    return self.status ~= MissionStatus.CREATED
end
function AbstractMission:getIsFinished()
    return self.status == MissionStatus.FINISHED
end
function AbstractMission:getInfo()
    return self.info
end
function AbstractMission:getLocation()
    return ""
end
function AbstractMission:getDescription()
    return self.description
end
function AbstractMission:getDetails()
    local details = {}
    if not self:getWasStarted() or self.spawnedVehicles then
        table.insert(details, {
            ["title"] = g_i18n:getText("contract_vehicleCosts"),
            ["value"] = g_i18n:formatMoney(self:getVehicleCosts(), 0, true, true)
        })
    end
    return details
end
function AbstractMission:getFinishedDetails()
    local details = {}
    table.insert(details, {
        ["title"] = g_i18n:getText("contract_reward"),
        ["value"] = g_i18n:formatMoney(self:getActualReward(), 0, true, true)
    })
    table.insert(details, {
        ["title"] = g_i18n:getText("contract_reimbursement"),
        ["value"] = g_i18n:formatMoney(self:getReimbursement(), 0, true, true)
    })
    table.insert(details, {
        ["title"] = g_i18n:getText("contract_vehicleCosts"),
        ["value"] = g_i18n:formatMoney(-self:getActualVehicleCosts(), 0, true, true)
    })
    table.insert(details, {
        ["title"] = g_i18n:getText("contract_stealing"),
        ["value"] = g_i18n:formatMoney(-self:getActualStealingCosts(), 0, true, true)
    })
    return details
end
function AbstractMission:getTitle()
    return self.title
end
function AbstractMission:getNPC()
    return nil
end
function AbstractMission:getExtraProgressText()
    return ""
end
function AbstractMission:getCompletion()
    return 0
end
function AbstractMission:farmDestroyed(farmId)
    if farmId == self.farmId then
        g_missionManager:markMissionForDeletion(self)
    end
end
function AbstractMission:getMissionTypeName()
    return nil
end
function AbstractMission:onVehicleReset(oldVehicle, newVehicle)
    if self.isServer and table.removeElement(self.vehicles, oldVehicle) then
        table.addElement(self.vehicles, newVehicle)
    end
end
function AbstractMission:getVehicleSize()
    return "small"
end
function AbstractMission:getVehicleGroupFromIdentifier(identifier)
    return g_missionManager:getVehicleGroupFromIdentifier(self.type.name, self:getVehicleSize(), identifier)
end
function AbstractMission:getVehicleGroup()
    return g_missionManager:getRandomVehicleGroup(self:getMissionTypeName(), self:getVehicleSize(), self:getVehicleVariant())
end
function AbstractMission:getVehicleVariant()
    return nil
end
function AbstractMission:getVariant()
    return nil
end
function AbstractMission:removeAccess()
    if self.isServer then
        self:calculateReimbursement()
        for _, vehicle in ipairs(self.vehicles) do
            if not vehicle:getIsBeingDeleted() then
                vehicle:delete()
            end
        end
        self.vehicles = {}
    end
end
function AbstractMission:hasLeasableVehicles()
    return self.vehiclesToLoad ~= nil
end
function AbstractMission:isSpawnSpaceAvailable()
    local result = true
    local mission = g_currentMission
    local placesFilled = {}
    for _, v in ipairs(self.vehiclesToLoad) do
        local storeItem = g_storeManager:getItemByXMLFilename(v.filename)
        local size = StoreItemUtil.getSizeValues(v.filename, "vehicle", storeItem.rotation, v.configurations)
        size.width = math.max(size.width, VehicleLoadingData.MIN_SPAWN_PLACE_WIDTH)
        size.length = math.max(size.length, VehicleLoadingData.MIN_SPAWN_PLACE_LENGTH)
        size.height = math.max(size.height, VehicleLoadingData.MIN_SPAWN_PLACE_HEIGHT)
        size.width = size.width + VehicleLoadingData.SPAWN_WIDTH_OFFSET
        local x, _, _, place, width, _ = PlacementUtil.getPlace(mission.storeSpawnPlaces, size, mission.usedStorePlaces)
        if x == nil then
            result = false
            break
        end
        PlacementUtil.markPlaceUsed(usedPlaces, place, width)
        table.insert(placesFilled, place)
    end
    for _, v in ipairs(placesFilled) do
        PlacementUtil.unmarkPlaceUsed(usedPlaces, v)
    end
    return result
end
function AbstractMission:getIsWorkAllowed(farmId, x, z, workAreaType, vehicle)
    return true
end
function AbstractMission:getWorldPosition()
    return 0, 0
end
function AbstractMission.loadMapData(xmlFile, baseDirectory) end
function AbstractMission.unloadMapData() end
function AbstractMission.tryGenerateMission() end
function AbstractMission.canRun() end