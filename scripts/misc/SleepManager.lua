SleepManager = {}
SleepManager.INPUT_CONTEXT_NAME = "SLEEPING"
SleepManager.SLEEPING_TIME_SCALE = 5000
SleepManager.TIME_TO_ANSWER_REQUEST = 20000
SleepManager.TIME_TO_NEXT_REQUEST = 20000
SleepManager.NUM_SLEEP_ANIMATION_STATES = 16
SleepManager.ANIMATION_SLICE_ID = "gui.sleep"
local SleepManager_mt = Class(SleepManager, AbstractManager)
function SleepManager.new(customMt)
    -- upvalues: (copy) SleepManager_mt
    local self = AbstractManager.new(customMt or SleepManager_mt)
    self.isSleeping = false
    self.wakeUpTime = 0
    self.previousCamera = nil
    self.previousInputContext = nil
    self.fallbackCamera = nil
    self.isRequestPending = false
    self.requestAnswer = true
    self.requestedTime = 0
    self.requestedTargetTime = 0
    self.curerntSleepAnimationState = SleepManager.NUM_SLEEP_ANIMATION_STATES
    return self
end
function SleepManager:loadMapData(_, _, _)
    local width, height = getNormalizedScreenValues(128, 128)
    self.animationNumFrames = 16
    self.animationTimer = 0
    self.animationSpeed = 50
    self.animationOffset = 0
    self.animationFrameSize = 128
    self.animationRefSize = { 2048, 128 }
    local xOffset, yOffset = getNormalizedScreenValues(-4, 0)
    self.animationOverlay = g_overlayManager:createOverlay(SleepManager.ANIMATION_SLICE_ID, 0.5 + xOffset, 0.5 + yOffset, width, height)
    self.animationOverlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
    self.animationOverlay:setColor(0.22323, 0.40724, 0.00368, 1)
    local width, height = getNormalizedScreenValues(200, 200)
    self.animationBackgroundOverlay = Overlay.new("dataS/menu/hud/ui_elements.png", 0.5, 0.5, width, height)
    self.animationBackgroundOverlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
    self.animationBackgroundOverlay:setUVs(GuiUtils.getUVs({
        294,
        390,
        100,
        100
    }, { 1024, 1024 }))
    self.animationBackgroundOverlay:setColor(0, 0, 0, 0.75)
    g_messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
end
function SleepManager:unloadMapData()
    g_messageCenter:unsubscribeAll(self)
    if self.fallbackCamera ~= nil then
        g_cameraManager:removeCamera(self.fallbackCamera)
        delete(self.fallbackCamera)
        self.fallbackCamera = nil
    end
    if self.animationOverlay ~= nil then
        self.animationOverlay:delete()
        self.animationOverlay = nil
    end
    if self.animationBackgroundOverlay ~= nil then
        self.animationBackgroundOverlay:delete()
        self.animationBackgroundOverlay = nil
    end
end
function SleepManager:update(dt)
    if g_currentMission:getIsServer() then
        if self.wakeUpTime < g_currentMission.time and self.isSleeping then
            self:stopSleep()
        end
        if self.isRequestPending then
            if #self.userRequestIds == 0 then
                if self.requestAnswer then
                    self:startSleep(self.requestedTargetTime)
                    self:resetRequest()
                else
                    g_server:broadcastEvent(SleepRequestDeniedEvent.new(self.requestDeniedUserId), g_dedicatedServer ~= nil)
                    self:resetRequest()
                end
            elseif self.requestedTime + SleepManager.TIME_TO_ANSWER_REQUEST < g_currentMission.time then
                g_server:broadcastEvent(SleepRequestTimeoutEvent.new(), false)
                self:resetRequest()
            end
        end
    end
    if self.isSleeping then
        self.animationTimer = self.animationTimer - dt
        if self.animationTimer < 0 then
            self.animationTimer = self.animationSpeed
            self.animationOffset = self.animationOffset + 1
            if self.animationOffset > self.animationNumFrames - 1 then
                self.animationOffset = 0
            end
            self.curerntSleepAnimationState = self.curerntSleepAnimationState + 1
            if self.curerntSleepAnimationState > SleepManager.NUM_SLEEP_ANIMATION_STATES then
                self.curerntSleepAnimationState = 1
            end
            local sleepAnimationSliceId = SleepManager.ANIMATION_SLICE_ID
            if self.curerntSleepAnimationState < 10 then
            elseif self.curerntSleepAnimationState < SleepManager.NUM_SLEEP_ANIMATION_STATES then
            end
            self.animationOverlay:setSliceId(sleepAnimationSliceId)
        end
    end
end
function SleepManager:draw()
    if self.isSleeping and not g_currentMission.paused then
        if self.animationBackgroundOverlay ~= nil then
            self.animationBackgroundOverlay:render()
        end
        if self.animationOverlay ~= nil then
            self.animationOverlay:render()
        end
    end
end
function SleepManager:onUserRemoved(user)
    if self.isRequestPending then
        for k, id in ipairs(self.userRequestIds) do
            if id == user:getId() then
                table.remove(self.userRequestIds, k)
                return
            end
        end
    end
end
function SleepManager:getCanSleep()
    return not self.isSleeping
end
function SleepManager:getIsSleeping()
    return self.isSleeping
end
function SleepManager:onSleepNotAllowed()
    InfoDialog.cancel()
    InfoDialog.show(g_i18n:getText("ui_inGameSleepNotAllowed"), nil, self, DialogElement.TYPE_WARNING)
end
function SleepManager:onSleepRequestDenied(userId)
    local nickname = ""
    if userId > 0 then
        local user = g_currentMission.userManager:getUserByUserId(userId)
        if user ~= nil then
            nickname = string.format(" (%s)", user:getNickname())
        end
    end
    InfoDialog.cancel()
    InfoDialog.show(g_i18n:getText("ui_inGameSleepRequestDenied") .. nickname, nil, self, DialogElement.TYPE_WARNING)
end
function SleepManager:onSleepRequestTimeout()
    if self.isSleepRequestAnswerPending then
        YesNoDialog.cancel()
    end
    InfoDialog.show(g_i18n:getText("ui_inGameSleepRequestTimeout"), nil, self, DialogElement.TYPE_WARNING)
end
function SleepManager:onSleepRequestPending()
    InfoDialog.cancel()
    InfoDialog.show(g_i18n:getText("ui_inGameSleepRequestPending"), nil, self, DialogElement.TYPE_WARNING)
end
function SleepManager:onSleepRequest(userId, _)
    local user = g_currentMission.userManager:getUserByUserId(userId)
    local name = "Unknown"
    if user ~= nil then
        name = user:getNickname()
    end
    self.isSleepRequestAnswerPending = true
    YesNoDialog.show(self.onSleepRequestYesNo, self, string.format(g_i18n:getText("ui_inGameSleepRequest"), name))
end
function SleepManager:onSleepRequestYesNo(yesNo)
    self.isSleepRequestAnswerPending = false
    g_client:getServerConnection():sendEvent(SleepResponseEvent.new(yesNo))
end
function SleepManager:onSleepResponse(connection, answer)
    assert(g_currentMission:getIsServer(), "SleepManager:onSleepResponse is a server-only function")
    if self.isRequestPending then
        self.requestAnswer = self.requestAnswer and answer
        local userId = g_currentMission.userManager:getUserIdByConnection(connection)
        if not answer and self.requestDeniedUserId == nil then
            self.requestDeniedUserId = userId
        end
        if userId ~= nil then
            for k, id in ipairs(self.userRequestIds) do
                if id == userId then
                    table.remove(self.userRequestIds, k)
                    return
                end
            end
        end
    end
end
function SleepManager:showDialog()
    if self:getCanSleep() then
        local text = g_i18n:getText("ui_inGameSleepTargetTime") .. "\n" .. g_i18n:getText("ui_currentTime") .. ": " .. g_i18n:formatCurrentTime()
        SleepDialog.show(text, self.sleepDialogYesNo, self)
    else
        InfoDialog.cancel()
        InfoDialog.show(g_i18n:getText("ui_inGameSleepWrongTime"), nil, nil, DialogElement.TYPE_WARNING)
    end
end
function SleepManager:sleepDialogYesNo(yes, targetTime)
    if yes then
        if g_currentMission:getIsServer() then
            self:startSleepRequest(g_currentMission.playerUserId, targetTime)
            return
        end
        g_client:getServerConnection():sendEvent(SleepRequestEvent.new(g_currentMission.playerUserId, targetTime))
    end
end
function SleepManager:startSleepRequest(userId, targetTime)
    local userConnection = g_currentMission:getIsServer()
    assert(userConnection, "SleepManager:startSleepRequest is a server-only function")
    local user = g_currentMission.userManager:getUserByUserId(userId)
    local userConnection = nil
    if user ~= nil then
        userConnection = user:getConnection()
    end
    if self.isRequestPending then
        if userConnection ~= nil then
            userConnection:sendEvent(SleepRequestPendingEvent.new())
        end
        return
    else
        local _ = self.requestedTime + SleepManager.TIME_TO_NEXT_REQUEST > g_currentMission.time
        if self:getCanSleep() then
            self.isRequestPending = true
            self.requestedTime = g_currentMission.time
            self.requestedTargetTime = targetTime
            self.requestAnswer = true
            self.userRequestIds = {}
            local connections = {}
            for _, otherUser in ipairs(g_currentMission.userManager:getUsers()) do
                if otherUser:getId() ~= userId and (g_dedicatedServer == nil or otherUser:getId() ~= g_currentMission:getServerUserId()) and otherUser:getState() == FSBaseMission.USER_STATE_INGAME then
                    table.insert(self.userRequestIds, otherUser:getId())
                    table.insert(connections, otherUser:getConnection())
                end
            end
            g_server:broadcastEvent(SleepRequestEvent.new(userId, targetTime), g_dedicatedServer ~= nil, userConnection, nil, nil, connections)
        elseif userConnection ~= nil then
            userConnection:sendEvent(SleepNotAllowedEvent.new())
        end
    end
end
function SleepManager:resetRequest()
    self.isRequestPending = false
    self.requestedTargetTime = 0
    self.requestAnswer = true
    self.requestDeniedUserId = nil
end
function SleepManager:startSleep(targetTime)
    g_currentMission.environment.weather.cloudUpdater:setSlowModeEnabled(true)
    if g_currentMission:getIsServer() then
        targetTime = targetTime * 1000 * 60 * 60
        self.wakeUpTime = g_currentMission.time + (targetTime - (g_currentMission.environment.dayTime + 1)) % 86400000 / SleepManager.SLEEPING_TIME_SCALE
        self.startTimeScale = g_currentMission.missionInfo.timeScale
        g_currentMission:setTimeScale(SleepManager.SLEEPING_TIME_SCALE)
        g_currentMission:setTimeScaleMultiplier(1)
        g_server:broadcastEvent(StartSleepStateEvent.new(targetTime), false)
    end
    self.isSleeping = true
    g_currentMission.hud:setIsVisible(false)
    g_currentMission.isPlayerFrozen = true
    g_inputBinding:setContext(SleepManager.INPUT_CONTEXT_NAME, true)
    self.previousCamera = g_cameraManager:getActiveCamera()
    local currentHour = self:getSleepCamera()
    if currentHour ~= nil then
        local duration, y, z = getWorldTranslation(currentHour)
        local y = math.max(getTerrainHeightAtWorldPos(g_terrainNode, duration, y, z) + 60, y)
        setWorldTranslation(currentHour, duration, y, z)
        setWorldRotation(currentHour, 1.3962634015954636, 0, 0)
        g_cameraManager:setActiveCamera(currentHour)
    end
    g_messageCenter:publish(MessageType.SLEEPING, true)
end
function SleepManager:stopSleep()
    g_currentMission.environment.weather.cloudUpdater:setSlowModeEnabled(false)
    if g_currentMission:getIsServer() then
        g_currentMission:setTimeScale(self.startTimeScale)
        g_server:broadcastEvent(StopSleepStateEvent.new(), false)
    end
    if self.previousCamera == nil or not entityExists(self.previousCamera) then
        if g_localPlayer ~= nil then
            g_cameraManager:setActiveCamera(localPlayer:getCurrentCameraNode())
        end
    else
        g_cameraManager:setActiveCamera(self.previousCamera)
    end
    self.previousCamera = nil
    if g_inputBinding:getContextName() == SleepManager.INPUT_CONTEXT_NAME then
        g_inputBinding:revertContext(true)
    end
    g_currentMission.isPlayerFrozen = false
    g_currentMission.hud:setIsVisible(true)
    self.isSleeping = false
    g_messageCenter:publish(MessageType.SLEEPING, false)
end
function SleepManager:getSleepCamera()
    return g_farmManager:getSleepCamera(g_localPlayer:getFarmId()) or self:getFallbackCamera()
end
function SleepManager:getFallbackCamera()
    if self.fallbackCamera == nil then
        self.fallbackCamera = createCamera("sleepingFallbackCamera", 1.0471975511965976, 1, 10000)
        link(getRootNode(), self.fallbackCamera)
        g_cameraManager:addCamera(self.fallbackCamera, nil, false)
    end
    return self.fallbackCamera
end
g_sleepManager = SleepManager.new()