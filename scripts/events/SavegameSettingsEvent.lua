SavegameSettingsEvent = {}
local SavegameSettingsEvent_mt = Class(SavegameSettingsEvent, Event)
InitStaticEventClass(SavegameSettingsEvent, "SavegameSettingsEvent")
function SavegameSettingsEvent.emptyNew()
    -- upvalues: (copy) SavegameSettingsEvent_mt
    return Event.new(SavegameSettingsEvent_mt)
end
function SavegameSettingsEvent.new()
    return SavegameSettingsEvent.emptyNew()
end
function SavegameSettingsEvent:readStream(streamId, connection)
    local timeScale = streamReadFloat32(streamId)
    local economicDifficulty = EconomicDifficulty.readStream(streamId)
    local isSnowEnabled = streamReadBool(streamId)
    local growthMode = GrowthMode.readStream(streamId)
    local fruitDestruction = streamReadBool(streamId)
    local plowingRequired = streamReadBool(streamId)
    local stonesEnabled = streamReadBool(streamId)
    local limeRequired = streamReadBool(streamId)
    local weedsEnabled = streamReadBool(streamId)
    local automaticMotorStartEnabled = streamReadBool(streamId)
    local trafficEnabled = streamReadBool(streamId)
    local stopAndGoBraking = streamReadBool(streamId)
    local trailerFillLimit = streamReadBool(streamId)
    local savegameName = streamReadString(streamId)
    local dirtInterval = streamReadUIntN(streamId, 3)
    local autoSaveInterval = streamReadInt32(streamId)
    local fixedSeasonalVisuals = streamReadUIntN(streamId, 4)
    if fixedSeasonalVisuals == 0 then
        fixedSeasonalVisuals = nil
    end
    local plannedDaysPerPeriod = streamReadUIntN(streamId, 5)
    local fuelUsage = streamReadUIntN(streamId, 2)
    local helperBuyFuel = streamReadBool(streamId)
    local helperBuySeeds = streamReadBool(streamId)
    local helperBuyFertilizer = streamReadBool(streamId)
    local helperSlurrySource = streamReadUIntN(streamId, 4)
    local helperManureSource = streamReadUIntN(streamId, 4)
    local disasterDestructionState = DisasterDestructionState.readStream(streamId)
    local mission = g_currentMission
    if connection:getIsServer() or mission.userManager:getIsConnectionMasterUser(connection) then
        mission:setTimeScale(timeScale, true)
        mission:setEconomicDifficulty(economicDifficulty, true)
        mission:setSnowEnabled(isSnowEnabled, true)
        mission:setGrowthMode(growthMode, true)
        mission:setFruitDestructionEnabled(fruitDestruction, true)
        mission:setPlowingRequiredEnabled(plowingRequired, true)
        mission:setStonesEnabled(stonesEnabled, true)
        mission:setLimeRequired(limeRequired, true)
        mission:setWeedsEnabled(weedsEnabled, true)
        mission:setSavegameName(savegameName, true)
        mission:setDirtInterval(dirtInterval, true)
        mission:setAutoSaveInterval(autoSaveInterval, true)
        mission:setFixedSeasonalVisuals(fixedSeasonalVisuals, true)
        mission:setPlannedDaysPerPeriod(plannedDaysPerPeriod, true)
        mission:setAutomaticMotorStartEnabled(automaticMotorStartEnabled, true)
        mission:setTrafficEnabled(trafficEnabled, true)
        mission:setHelperBuyFuel(helperBuyFuel, true)
        mission:setHelperBuySeeds(helperBuySeeds, true)
        mission:setHelperBuyFertilizer(helperBuyFertilizer, true)
        mission:setHelperSlurrySource(helperSlurrySource, true)
        mission:setHelperManureSource(helperManureSource, true)
        mission:setFuelUsage(fuelUsage, true)
        mission:setStopAndGoBraking(stopAndGoBraking, true)
        mission:setTrailerFillLimit(trailerFillLimit, true)
        mission:setDisasterDestructionState(disasterDestructionState, true)
        if not connection:getIsServer() then
            g_server:broadcastEvent(self, false, connection)
        end
    end
end
function SavegameSettingsEvent.writeStream(_, streamId, _)
    local missionInfo = g_currentMission.missionInfo
    streamWriteFloat32(streamId, missionInfo.timeScale)
    EconomicDifficulty.writeStream(streamId, missionInfo.economicDifficulty)
    streamWriteBool(streamId, missionInfo.isSnowEnabled)
    GrowthMode.writeStream(streamId, missionInfo.growthMode)
    streamWriteBool(streamId, missionInfo.fruitDestruction)
    streamWriteBool(streamId, missionInfo.plowingRequiredEnabled)
    streamWriteBool(streamId, missionInfo.stonesEnabled)
    streamWriteBool(streamId, missionInfo.limeRequired)
    streamWriteBool(streamId, missionInfo.weedsEnabled)
    streamWriteBool(streamId, missionInfo.automaticMotorStartEnabled)
    streamWriteBool(streamId, missionInfo.trafficEnabled)
    streamWriteBool(streamId, missionInfo.stopAndGoBraking)
    streamWriteBool(streamId, missionInfo.trailerFillLimit)
    streamWriteString(streamId, missionInfo.savegameName)
    streamWriteUIntN(streamId, missionInfo.dirtInterval, 3)
    streamWriteInt32(streamId, g_autoSaveManager:getInterval())
    streamWriteUIntN(streamId, missionInfo.fixedSeasonalVisuals or 0, 4)
    streamWriteUIntN(streamId, missionInfo.plannedDaysPerPeriod, 5)
    streamWriteUIntN(streamId, missionInfo.fuelUsage, 2)
    streamWriteBool(streamId, missionInfo.helperBuyFuel)
    streamWriteBool(streamId, missionInfo.helperBuySeeds)
    streamWriteBool(streamId, missionInfo.helperBuyFertilizer)
    streamWriteUIntN(streamId, missionInfo.helperSlurrySource, 4)
    streamWriteUIntN(streamId, missionInfo.helperManureSource, 4)
    DisasterDestructionState.writeStream(streamId, missionInfo.disasterDestructionState)
end
function SavegameSettingsEvent:run(connection)
    printError("Error: SavegameSettingsEvent is not allowed to be executed on a local client")
end
function SavegameSettingsEvent.sendEvent(noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_currentMission:getIsServer() then
            g_server:broadcastEvent(SavegameSettingsEvent.new(), false)
            return
        end
        g_client:getServerConnection():sendEvent(SavegameSettingsEvent.new())
    end
end