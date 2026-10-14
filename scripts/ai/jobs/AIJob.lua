AIJob = {}
AIJob.START_SUCCESS = 0
local AIJob_mt = Class(AIJob)
function AIJob.new(isServer, customMt)
    -- upvalues: (copy) AIJob_mt
    local self = setmetatable({}, customMt or AIJob_mt)
    self.isServer = isServer
    self.tasks = {}
    self.namedParameters = {}
    self.groupedParameters = {}
    self.currentTaskIndex = 0
    self.jobId = nil
    self.startedFarmId = nil
    self.isDirectStart = false
    self.pendingCost = 0
    return self
end
function AIJob:delete()
    for _, namedParameter in ipairs(self.namedParameters) do
        namedParameter.parameter:delete()
    end
    for _, namedParameter in ipairs(self.tasks) do
        namedParameter:delete()
    end
end
function AIJob:saveToXMLFile(xmlFile, key, usedModNames)
    local index = 0
    for _, namedParameter in ipairs(self.namedParameters) do
        if namedParameter.parameter.saveToXMLFile ~= nil then
            local paramKey = string.format("%s.parameter(%d)", key, index)
            xmlFile:setString(paramKey .. "#name", namedParameter.name)
            namedParameter.parameter:saveToXMLFile(xmlFile, paramKey, usedModNames)
            index = index + 1
        end
    end
    return true
end
function AIJob:loadFromXMLFile(xmlFile, key)
    xmlFile:iterate(key .. ".parameter", function(_, paramKey)
        -- upvalues: (copy) xmlFile, (copy) self
        local name = xmlFile:getString(paramKey .. "#name")
        if name ~= nil then
            local parameter = self:getNamedParameter(name)
            if parameter ~= nil and parameter.loadFromXMLFile ~= nil then
                parameter:loadFromXMLFile(xmlFile, paramKey)
            end
        end
    end)
end
function AIJob:readStream(streamId, connection)
    self.isDirectStart = streamReadBool(streamId)
    if streamReadBool(streamId) then
        self.jobId = streamReadInt32(streamId)
    end
    for _, namedParameter in ipairs(self.namedParameters) do
        namedParameter.parameter:readStream(streamId, connection)
    end
    self:setValues()
    self.currentTaskIndex = streamReadUInt8(streamId)
end
function AIJob:writeStream(streamId, connection)
    streamWriteBool(streamId, self.isDirectStart)
    if streamWriteBool(streamId, self.jobId ~= nil) then
        streamWriteInt32(streamId, self.jobId)
    end
    for _, namedParameter in ipairs(self.namedParameters) do
        namedParameter.parameter:writeStream(streamId, connection)
    end
    streamWriteUInt8(streamId, self.currentTaskIndex)
end
function AIJob:update(dt)
    if self.isServer then
        local currentTask = nil
        if self.currentTaskIndex == 0 then
            local canStart, aiMessage = self:canStartWork()
            if not canStart then
                g_currentMission.aiSystem:stopJob(self, aiMessage)
                return
            end
            self:startTask((self:getTaskByIndex((self:getStartTaskIndex()))))
        else
            currentTask = self:getTaskByIndex(self.currentTaskIndex)
        end
        if currentTask ~= nil then
            currentTask:update(dt)
            if currentTask:getIsFinished() then
                local canStart, aiMessage = self:canContinueWork()
                if not canStart then
                    g_currentMission.aiSystem:stopJob(self, aiMessage)
                    return
                end
                local taskIndex = self:getNextTaskIndex()
                if #self.tasks < taskIndex then
                    if not self:getIsLooping() then
                        g_currentMission.aiSystem:stopJob(self, AIMessageSuccessFinishedJob.new())
                        return
                    end
                    taskIndex = 1
                end
                self:stopTask(currentTask, false)
                self:startTask((self:getTaskByIndex(taskIndex)))
            end
        end
    end
end
function AIJob:updateCost(dt)
    local price = self:getPricePerMs()
    if price > 0 then
        local price = price * dt * EconomyManager.getCostMultiplier()
        self.pendingCost = self.pendingCost + price
        local farm = g_farmManager:getFarmById(self.startedFarmId)
        if farm ~= nil and farm:getBalance() - self.pendingCost < 0 then
            g_currentMission.aiSystem:stopJob(self, AIMessageErrorOutOfMoney.new())
        end
        if self.pendingCost > 25 then
            g_currentMission:addMoney(-self.pendingCost, self.startedFarmId, MoneyType.AI, true)
            self.pendingCost = 0
        end
    end
end
function AIJob:canContinueWork()
    return true, nil
end
function AIJob:canStartWork()
    return true, nil
end
function AIJob:getPricePerMs()
    return 0.0004
end
function AIJob:getNextTaskIndex()
    return self.currentTaskIndex + 1
end
function AIJob:validate(farmId)
    return true, nil
end
function AIJob:getIsLooping()
    return false
end
function AIJob:setValues() end
function AIJob:startTask(task)
    self.currentTaskIndex = task.taskIndex
    task:start()
    if self.isServer then
        g_server:broadcastEvent(AITaskStartEvent.new(self, task))
    end
end
function AIJob:stopTask(task, wasJobStopped)
    task:stop(wasJobStopped)
    if self.isServer then
        g_server:broadcastEvent(AITaskStopEvent.new(self, task, wasJobStopped))
    end
end
function AIJob:start(farmId)
    self.helperIndex = g_helperManager:getRandomHelper().index
    self.startedFarmId = farmId
    self.isRunning = true
    if self.isServer then
        self.currentTaskIndex = 0
    end
end
function AIJob:getCanSkipTask()
    return false
end
function AIJob:skipCurrentTask() end
function AIJob:stop(aiMessage)
    self.isRunning = false
    if self.isServer and self.currentTaskIndex ~= 0 then
        self:stopTask(self:getTaskByIndex(self.currentTaskIndex), true)
    end
    if self.pendingCost > 0 then
        g_currentMission:addMoney(-self.pendingCost, self.startedFarmId, MoneyType.AI, true)
        self.pendingCost = 0
    end
    self:showNotification(aiMessage)
    self:resetTasks()
end
function AIJob:addTask(task)
    assert(task.taskIndex ~= nil, "Task already added")
    table.insert(self.tasks, task)
    task.taskIndex = #self.tasks
end
function AIJob:resetTasks()
    for _, task in ipairs(self.tasks) do
        task:reset()
    end
end
function AIJob:getTaskByIndex(taskIndex)
    return self.tasks[taskIndex]
end
function AIJob:getTitle()
    return g_helperManager:getHelperByIndex(self.helperIndex).title
end
function AIJob:getDescription()
    return g_currentMission.aiJobTypeManager:getJobTypeByIndex(self.jobTypeIndex).title
end
function AIJob:getHelperName()
    return g_helperManager:getHelperByIndex(self.helperIndex).title
end
function AIJob:showNotification(aiMessage)
    if g_helperManager:getHelperByIndex(self.helperIndex) ~= nil then
        local playerFarmId = nil
        if g_currentMission ~= nil and g_localPlayer ~= nil then
            playerFarmId = g_localPlayer.farmId
        end
        if aiMessage ~= nil and self.startedFarmId == playerFarmId then
            local text = aiMessage:getMessage(self)
            local errorType = aiMessage:getType()
            local notificationType = FSBaseMission.INGAME_NOTIFICATION_CRITICAL
            if errorType == AIMessageType.OK then
                notificationType = FSBaseMission.INGAME_NOTIFICATION_OK
            elseif errorType == AIMessageType.INFO then
                notificationType = FSBaseMission.INGAME_NOTIFICATION_INFO
            end
            g_currentMission:addIngameNotification(notificationType, text)
        end
    end
end
function AIJob:getStartTaskIndex()
    return 1
end
function AIJob:addNamedParameter(name, parameter)
    table.insert(self.namedParameters, {
        ["name"] = name,
        ["parameter"] = parameter
    })
end
function AIJob:setParameterValid(isValid)
    for _, namedParameter in ipairs(self.namedParameters) do
        namedParameter.parameter:setIsValid(isValid)
    end
end
function AIJob:getNamedParameters()
    return self.namedParameters
end
function AIJob:getNamedParameter(name)
    if name == nil then
        return nil
    end
    name = string.upper(name)
    for _, data in ipairs(self.namedParameters) do
        if string.upper(data.name) == name then
            return data.parameter
        end
    end
    return nil
end
function AIJob:getGroupedParameters()
    return self.groupedParameters
end
function AIJob:applyCurrentState(_, _, _, isDirectStart)
    self.isDirectStart = isDirectStart
end
function AIJob:getIsAvailableForVehicle(vehicle)
    return true
end
function AIJob:setId(id)
    self.jobId = id
end
function AIJob:onParameterValueChanged(parameter) end
function AIJob:getIsStartable(connection)
    return true, AIJob.START_SUCCESS
end