source("dataS/scripts/vehicles/specializations/events/AIJobVehicleStateEvent.lua")
AIJobVehicle = {}
function AIJobVehicle.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AIVehicle, specializations) and SpecializationUtil.hasSpecialization(Drivable, specializations)
end
function AIJobVehicle.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AIJobVehicle")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.ai.steeringNode#node", "Steering node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.ai.reverserNode#node", "Reverser node")
    schema:register(XMLValueType.FLOAT, "vehicle.ai.steeringSpeed", "Speed of steering", 1)
    schema:register(XMLValueType.BOOL, "vehicle.ai#supportsAIJobs", "If true vehicle supports ai jobs", true)
    schema:register(XMLValueType.STRING_LIST, "vehicle.ai#supportedJobTypes", "List of job names that are supported (AIJobConveyor, AIJobDeliver, AIJobGoTo, AIJobLoadAndDeliver, AIJobFieldWork)", "all jobs if no names are given")
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).aiJobVehicle#isAIStartAllowed", "If ai start is allowed", true)
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).aiJobVehicle#isAIStopAllowed", "If ai stop is allowed", true)
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).aiJobVehicle.lastJob#type", "Last job name", nil)
end
function AIJobVehicle.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onAIJobStarted")
    SpecializationUtil.registerEvent(vehicleType, "onAIJobFinished")
    SpecializationUtil.registerEvent(vehicleType, "onAIJobVehicleBlock")
    SpecializationUtil.registerEvent(vehicleType, "onAIJobVehicleContinue")
end
function AIJobVehicle.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getShowAIToggleActionEvent", AIJobVehicle.getShowAIToggleActionEvent)
    SpecializationUtil.registerFunction(vehicleType, "stopCurrentAIJob", AIJobVehicle.stopCurrentAIJob)
    SpecializationUtil.registerFunction(vehicleType, "skipCurrentTask", AIJobVehicle.skipCurrentTask)
    SpecializationUtil.registerFunction(vehicleType, "aiJobStarted", AIJobVehicle.aiJobStarted)
    SpecializationUtil.registerFunction(vehicleType, "aiJobFinished", AIJobVehicle.aiJobFinished)
    SpecializationUtil.registerFunction(vehicleType, "toggleAIVehicle", AIJobVehicle.toggleAIVehicle)
    SpecializationUtil.registerFunction(vehicleType, "getCanToggleAIVehicle", AIJobVehicle.getCanToggleAIVehicle)
    SpecializationUtil.registerFunction(vehicleType, "getCanStartAIVehicle", AIJobVehicle.getCanStartAIVehicle)
    SpecializationUtil.registerFunction(vehicleType, "getCanStopAIVehicle", AIJobVehicle.getCanStopAIVehicle)
    SpecializationUtil.registerFunction(vehicleType, "getIsAIJobSupported", AIJobVehicle.getIsAIJobSupported)
    SpecializationUtil.registerFunction(vehicleType, "setAIMapHotspotBlinking", AIJobVehicle.setAIMapHotspotBlinking)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentHelper", AIJobVehicle.getCurrentHelper)
    SpecializationUtil.registerFunction(vehicleType, "aiBlock", AIJobVehicle.aiBlock)
    SpecializationUtil.registerFunction(vehicleType, "aiContinue", AIJobVehicle.aiContinue)
    SpecializationUtil.registerFunction(vehicleType, "getAIDirectionNode", AIJobVehicle.getAIDirectionNode)
    SpecializationUtil.registerFunction(vehicleType, "getAISteeringNode", AIJobVehicle.getAISteeringNode)
    SpecializationUtil.registerFunction(vehicleType, "getAIReverserNode", AIJobVehicle.getAIReverserNode)
    SpecializationUtil.registerFunction(vehicleType, "getAISteeringSpeed", AIJobVehicle.getAISteeringSpeed)
    SpecializationUtil.registerFunction(vehicleType, "getAIJobFarmId", AIJobVehicle.getAIJobFarmId)
    SpecializationUtil.registerFunction(vehicleType, "getStartableAIJob", AIJobVehicle.getStartableAIJob)
    SpecializationUtil.registerFunction(vehicleType, "getHasStartableAIJob", AIJobVehicle.getHasStartableAIJob)
    SpecializationUtil.registerFunction(vehicleType, "getStartAIJobText", AIJobVehicle.getStartAIJobText)
    SpecializationUtil.registerFunction(vehicleType, "getJob", AIJobVehicle.getJob)
    SpecializationUtil.registerFunction(vehicleType, "getLastJob", AIJobVehicle.getLastJob)
    SpecializationUtil.registerFunction(vehicleType, "setIsAIStartAllowed", AIJobVehicle.setIsAIStartAllowed)
    SpecializationUtil.registerFunction(vehicleType, "setIsAIStopAllowed", AIJobVehicle.setIsAIStopAllowed)
end
function AIJobVehicle.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsVehicleControlledByPlayer", AIJobVehicle.getIsVehicleControlledByPlayer)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", AIJobVehicle.getIsActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIActive", AIJobVehicle.getIsAIActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowTireTracks", AIJobVehicle.getAllowTireTracks)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateOnLeave", AIJobVehicle.getDeactivateOnLeave)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getStopMotorOnLeave", AIJobVehicle.getStopMotorOnLeave)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDisableVehicleCharacterOnLeave", AIJobVehicle.getDisableVehicleCharacterOnLeave)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFullName", AIJobVehicle.getFullName)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getActiveFarm", AIJobVehicle.getActiveFarm)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMapHotspotVisible", AIJobVehicle.getIsMapHotspotVisible)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMapHotspot", AIJobVehicle.getMapHotspot)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateLightsOnLeave", AIJobVehicle.getDeactivateLightsOnLeave)
end
function AIJobVehicle.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIJobVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIJobVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIJobVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", AIJobVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AIJobVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AIJobVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onAIModeChanged", AIJobVehicle)
end
function AIJobVehicle:onLoad(savegame)
    local spec = self.spec_aiJobVehicle
    spec.actionEvents = {}
    spec.job = nil
    spec.lastJob = nil
    spec.startedFarmId = nil
    spec.aiSteeringSpeed = self.xmlFile:getValue("vehicle.ai.steeringSpeed", 1) * 0.001
    spec.steeringNode = self.xmlFile:getValue("vehicle.ai.steeringNode#node", nil, self.components, self.i3dMappings)
    spec.reverserNode = self.xmlFile:getValue("vehicle.ai.reverserNode#node", nil, self.components, self.i3dMappings)
    spec.supportsAIJobs = self.xmlFile:getValue("vehicle.ai#supportsAIJobs", true)
    spec.supportedJobTypes = self.xmlFile:getValue("vehicle.ai#supportedJobTypes", nil)
    spec.isAIStartAllowed = true
    spec.isAIStopAllowed = true
    spec.texts = {}
    spec.texts.dismissEmployee = g_i18n:getText("action_dismissEmployee")
    spec.texts.openHelperMenu = g_i18n:getText("action_openHelperMenu")
    spec.texts.hireEmployee = g_i18n:getText("action_hireEmployee")
    if savegame ~= nil then
        local aiJobTypeManager = g_currentMission.aiJobTypeManager
        local savegameKey = savegame.key .. ".aiJobVehicle"
        local jobKey = savegameKey .. ".lastJob"
        local jobTypeIndex = aiJobTypeManager:getJobTypeIndexByName((savegame.xmlFile:getString(jobKey .. "#type")))
        if jobTypeIndex ~= nil then
            local job = aiJobTypeManager:createJob(jobTypeIndex)
            if job ~= nil and job.loadFromXMLFile ~= nil then
                job:loadFromXMLFile(savegame.xmlFile, jobKey)
                spec.lastJob = job
            end
        end
        spec.isAIStartAllowed = savegame.xmlFile:getValue(savegameKey .. "#isAIStartAllowed", spec.isAIStartAllowed)
        spec.isAIStopAllowed = savegame.xmlFile:getValue(savegameKey .. "#isAIStopAllowed", spec.isAIStopAllowed)
    end
end
function AIJobVehicle:onDelete()
    local spec = self.spec_aiJobVehicle
    if self.isServer and spec.job ~= nil then
        self:stopCurrentAIJob()
    end
    if spec.mapAIHotspot ~= nil then
        spec.mapAIHotspot:delete()
        spec.mapAIHotspot = nil
    end
end
function AIJobVehicle:onReadStream(streamId, connection)
    if streamReadBool(streamId) then
        local jobId = streamReadInt32(streamId)
        local startedFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
        local helperIndex = streamReadUInt8(streamId)
        self:aiJobStarted(g_currentMission.aiSystem:getJobById(jobId), helperIndex, startedFarmId)
    end
    if streamReadBool(streamId) then
        local startedFarmId = streamReadInt32(streamId)
        local helperIndex = self.spec_aiJobVehicle
        helperIndex.lastJob = g_currentMission.aiJobTypeManager:createJob(startedFarmId)
        helperIndex.lastJob:readStream(streamId, connection)
    end
end
function AIJobVehicle:onWriteStream(streamId, connection)
    local spec = self.spec_aiJobVehicle
    local jobTypeIndex = streamWriteBool
    if jobTypeIndex(streamId, spec.job ~= nil) then
        streamWriteInt32(streamId, spec.job.jobId)
        streamWriteUIntN(streamId, spec.startedFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
        streamWriteUInt8(streamId, spec.currentHelper.index)
    end
    local jobTypeIndex = streamWriteBool
    if jobTypeIndex(streamId, spec.lastJob ~= nil) then
        local jobTypeIndex = g_currentMission.aiJobTypeManager:getJobTypeIndex(spec.lastJob)
        streamWriteInt32(streamId, jobTypeIndex)
        spec.lastJob:writeStream(streamId, connection)
    end
end
function AIJobVehicle:onAIModeChanged(aiMode)
    if aiMode ~= AIModeSelection.MODE.WORKER and self.spec_aiJobVehicle.job ~= nil then
        self:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
    end
end
function AIJobVehicle:onUpdate(_, _, _, _)
    if self:getIsAIActive() then
        self:raiseActive()
    end
end
function AIJobVehicle:getShowAIToggleActionEvent()
    if self:getAIDirectionNode() == nil then
        return false
    elseif g_currentMission.disableAIVehicle then
        return false
    elseif g_currentMission:getHasPlayerPermission("hireAssistant") then
        return (self:getIsAIActive() or not g_currentMission.aiSystem:getAILimitedReached()) and true or false
    else
        return false
    end
end
function AIJobVehicle:stopCurrentAIJob(aiMessage)
    local spec = self.spec_aiJobVehicle
    if spec.job ~= nil then
        g_currentMission.aiSystem:stopJob(spec.job, aiMessage)
    end
end
function AIJobVehicle:skipCurrentTask()
    local spec = self.spec_aiJobVehicle
    if spec.job ~= nil then
        g_currentMission.aiSystem:skipCurrentTask(spec.job)
    end
end
function AIJobVehicle:aiJobStarted(job, helperIndex, startedFarmId)
    if not self:getIsAIActive() then
        if self.isServer then
            g_server:broadcastEvent(AIJobVehicleStateEvent.new(self, job, helperIndex, startedFarmId))
            g_currentMission.aiSystem:addJobVehicle(self)
        end
        self.spec_aiJobVehicle.job = job
        spec.lastJob = job
        spec.startedFarmId = startedFarmId
        spec.currentHelperIndex = helperIndex
        spec.currentHelper = g_helperManager:getHelperByIndex(helperIndex)
        g_helperManager:useHelper(spec.currentHelper)
        if self.isServer then
            g_farmManager:updateFarmStats(startedFarmId, "workersHired", 1)
        end
        if self.setRandomVehicleCharacter ~= nil then
            self:setRandomVehicleCharacter(spec.currentHelper)
        end
        if spec.mapAIHotspot == nil then
            spec.mapAIHotspot = AIHotspot.new()
            spec.mapAIHotspot:setVehicle(self)
        end
        spec.mapAIHotspot:setAIHelperName(spec.currentHelper.name)
        g_currentMission:addMapHotspot(spec.mapAIHotspot)
        if Platform.isMobile then
            self:updateMapHotspot()
        end
        SpecializationUtil.raiseEvent(self, "onAIJobStarted", job)
        self:requestActionEventUpdate()
        self:raiseActive()
    end
    g_messageCenter:publish(MessageType.AI_VEHICLE_STATE_CHANGE, true, self)
end
function AIJobVehicle:aiJobFinished()
    if self:getIsAIActive() then
        if self.isServer then
            g_server:broadcastEvent(AIJobVehicleStateEvent.new(self, nil, nil, nil))
            g_currentMission.aiSystem:removeJobVehicle(self)
        end
        g_helperManager:releaseHelper(self.spec_aiJobVehicle.currentHelper)
        spec.currentHelperIndex = nil
        spec.currentHelper = nil
        if self.isServer then
            g_farmManager:updateFarmStats(spec.startedFarmId, "workersHired", -1)
        end
        if self.restoreVehicleCharacter ~= nil then
            self:restoreVehicleCharacter()
        end
        if spec.mapAIHotspot ~= nil then
            g_currentMission:removeMapHotspot(spec.mapAIHotspot)
        end
        SpecializationUtil.raiseEvent(self, "onAIJobFinished", spec.job)
        spec.job = nil
        if Platform.isMobile then
            self:updateMapHotspot()
        end
        self:requestActionEventUpdate()
    end
    g_messageCenter:publish(MessageType.AI_VEHICLE_STATE_CHANGE, false, self)
end
function AIJobVehicle:getIsVehicleControlledByPlayer(superFunc)
    if not superFunc(self) then
        return false
    end
    return self.spec_aiJobVehicle.job ~= nil
end
function AIJobVehicle:getIsInUse(superFunc, connection)
    return self:getIsAIActive() and true or superFunc(self, connection)
end
function AIJobVehicle:getIsActive(superFunc)
    return self:getIsAIActive() and true or superFunc(self)
end
function AIJobVehicle:getAIJobFarmId()
    return self.spec_aiJobVehicle.startedFarmId
end
function AIJobVehicle:getIsAIActive(superFunc)
    return superFunc(self) or self.spec_aiJobVehicle.job ~= nil
end
function AIJobVehicle:getStartableAIJob()
    return nil
end
function AIJobVehicle:getHasStartableAIJob()
    return false
end
function AIJobVehicle:getStartAIJobText()
    if self:getHasStartableAIJob() then
        return self.spec_aiJobVehicle.texts.hireEmployee
    else
        return spec.texts.openHelperMenu
    end
end
function AIJobVehicle:getJob()
    return self.spec_aiJobVehicle.job
end
function AIJobVehicle:getLastJob()
    return self.spec_aiJobVehicle.lastJob
end
function AIJobVehicle:toggleAIVehicle()
    if self:getIsAIActive() then
        self:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
        return
    else
        local startableJob = self:getStartableAIJob()
        if startableJob == nil then
            if g_guidedTourManager:getIsTourRunning() then
                return
            elseif Platform.isMobile then
                g_gui:changeScreen(nil, InGameMenu)
                g_messageCenter:publish(MessageType.GUI_INGAME_OPEN_AI_SCREEN, self)
                local inGameMap = g_currentMission.hud:getIngameMap()
                inGameMap:updateHotspotSorting()
                local playerHotspot = g_inGameMenu.pageMapMobile.inGameMap:getPlayerHotspot(inGameMap.hotspotsSorted[true])
                g_inGameMenu.pageMapMobile:onClickHotspot(nil, playerHotspot)
                g_inGameMenu.pageMapMobile:onClickPagingAI()
            else
                g_gui:showGui("InGameMenu")
                g_messageCenter:publish(MessageType.GUI_INGAME_OPEN_AI_SCREEN, self)
            end
        else
            g_client:getServerConnection():sendEvent(AIJobStartRequestEvent.new(startableJob, self:getOwnerFarmId()))
            return
        end
    end
end
function AIJobVehicle:getCanToggleAIVehicle()
    if self:getIsAIActive() then
        return self:getCanStopAIVehicle()
    else
        return self:getCanStartAIVehicle()
    end
end
function AIJobVehicle:getCanStopAIVehicle()
    return self.spec_aiJobVehicle.isAIStopAllowed and true or false
end
function AIJobVehicle:getCanStartAIVehicle()
    if g_currentMission.disableAIVehicle then
        return false
    elseif self:getOwnerFarmId() == AccessHandler.EVERYONE then
        return false
    else
        local spec = self.spec_aiJobVehicle
        if spec.supportsAIJobs then
            if spec.isAIStartAllowed then
                if self:getAIDirectionNode() == nil then
                    return false
                elseif g_currentMission.aiSystem:getAILimitedReached() then
                    return false
                elseif self:getIsAIActive() then
                    return false
                else
                    return not self.isBroken
                end
            else
                return false
            end
        else
            return false
        end
    end
end
function AIJobVehicle:getIsAIJobSupported(aiJobName)
    local spec = self.spec_aiJobVehicle
    if spec.supportedJobTypes == nil then
        return true
    end
    for _, supportedJobName in ipairs(spec.supportedJobTypes) do
        if string.lower(supportedJobName) == string.lower(aiJobName) then
            return true
        end
    end
    return false
end
function AIJobVehicle:setIsAIStartAllowed(isAllowed)
    self.spec_aiJobVehicle.isAIStartAllowed = isAllowed
end
function AIJobVehicle:setIsAIStopAllowed(isAllowed)
    self.spec_aiJobVehicle.isAIStopAllowed = isAllowed
end
function AIJobVehicle:setAIMapHotspotBlinking(isBlinking)
    local spec = self.spec_aiJobVehicle
    if spec.mapAIHotspot ~= nil then
        spec.mapAIHotspot:setBlinking(isBlinking)
    end
end
function AIJobVehicle:getMapHotspot(superFunc)
    local spec = self.spec_aiJobVehicle
    if self:getIsAIActive() and spec.mapAIHotspot ~= nil then
        return spec.mapAIHotspot
    else
        return superFunc(self)
    end
end
function AIJobVehicle:getDeactivateLightsOnLeave(superFunc)
    return superFunc(self) and not self:getIsAIActive()
end
function AIJobVehicle:onSetBroken()
    if self:getIsAIActive() then
        self:stopCurrentAIJob(AIMessageErrorVehicleBroken.new())
    end
end
function AIJobVehicle:getDeactivateOnLeave(superFunc)
    return superFunc(self) and not self:getIsAIActive()
end
function AIJobVehicle:getStopMotorOnLeave(superFunc)
    return superFunc(self) and not self:getIsAIActive()
end
function AIJobVehicle:getDisableVehicleCharacterOnLeave(superFunc)
    return superFunc(self) and not self:getIsAIActive()
end
function AIJobVehicle:getAllowTireTracks(superFunc)
    return superFunc(self) and not self:getIsAIActive()
end
function AIJobVehicle:getCurrentHelper()
    return self.spec_aiJobVehicle.currentHelper
end
function AIJobVehicle:getFullName(superFunc)
    local name = superFunc(self)
    if self:getIsAIActive() then
        local helperName = g_i18n:getText("ui_helper")
        local currentHelper = self:getCurrentHelper()
        if currentHelper ~= nil then
        end
    end
    return name
end
function AIJobVehicle:aiBlock()
    if self.isClient and g_localPlayer.farmId == self:getAIJobFarmId() then
        local currentHelper = self:getCurrentHelper()
        local name = ""
        if currentHelper ~= nil then
            name = currentHelper.name
        end
        local text = string.format(g_i18n:getText("ai_messageErrorBlockedByObject"), name)
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, text)
    end
    self:raiseAIEvent("onAIJobVehicleBlock", "onAIImplementJobVehicleBlock")
end
function AIJobVehicle:aiContinue()
    self:raiseAIEvent("onAIJobVehicleContinue", "onAIImplementJobVehicleContinue")
end
function AIJobVehicle:getAIDirectionNode()
    return self.components[1].node
end
function AIJobVehicle:getAISteeringNode()
    return self.spec_aiJobVehicle.steeringNode or self:getAIDirectionNode()
end
function AIJobVehicle:getAIReverserNode()
    return self.spec_aiJobVehicle.reverserNode or self:getAISteeringNode()
end
function AIJobVehicle:getAISteeringSpeed()
    return self.spec_aiJobVehicle.aiSteeringSpeed
end
function AIJobVehicle:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_aiJobVehicle
    if spec.lastJob ~= nil then
        local jobType = g_currentMission.aiJobTypeManager:getJobTypeByIndex(spec.lastJob.jobTypeIndex)
        xmlFile:setString(key .. ".lastJob#type", jobType.name)
        spec.lastJob:saveToXMLFile(xmlFile, key .. ".lastJob", usedModNames)
    end
    xmlFile:setValue(key .. "#isAIStartAllowed", spec.isAIStartAllowed)
end
function AIJobVehicle:saveStatsToXMLFile(xmlFile, key)
    setXMLBool(xmlFile, key .. "#isAIActive", self:getIsAIActive())
end
function AIJobVehicle:getActiveFarm(superFunc)
    local starter = self:getAIJobFarmId()
    if starter == nil then
        return superFunc(self)
    else
        return starter
    end
end
function AIJobVehicle:getIsMapHotspotVisible(superFunc)
    if superFunc(self) then
        return not self:getIsAIActive()
    else
        return false
    end
end