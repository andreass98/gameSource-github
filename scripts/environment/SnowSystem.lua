SnowSystem = {}
SnowSystem.MAX_HEIGHT = 0.5
SnowSystem.MIN_LAYER_HEIGHT = 0.06
SnowSystem.MAX_MS_PER_FRAME = 1
SnowSystem.MAX_MS_PER_FRAME_SLEEPING = 3
SnowSystem.DELTA_REMOVE_ALL = -100
local SnowSystem_mt = Class(SnowSystem)
function SnowSystem.new(mission, isServer, customMt)
    -- upvalues: (copy) SnowSystem_mt
    local self = setmetatable({}, customMt or SnowSystem_mt)
    self.mission = mission
    self.isServer = isServer
    self.updater = nil
    self.updateQueue = {}
    self.height = 0
    self.exactHeight = 0
    self.snowShaderValue = 0
    self.vehicleWakeUpIndex = 0
    self.vehicleWakeUpDelay = 500
    self.vehicleWakeUpTimer = 0
    self.itemWakeUpIndex = 0
    self.itemWakeUpDelay = 100
    self.itemWakeUpTimer = 0
    setSharedShaderParameter(Shader.PARAM_SHARED_SNOW, 0)
    if self.isServer then
        g_messageCenter:subscribe(MessageType.SLEEPING, self.onSleepChanged, self)
    end
    return self
end
function SnowSystem:delete()
    g_messageCenter:unsubscribeAll(self)
    if g_addCheatCommands then
        removeConsoleCommand("gsSnowAdd")
        removeConsoleCommand("gsSnowSet")
        removeConsoleCommand("gsSnowReset")
        removeConsoleCommand("gsSnowShaderSet")
        removeConsoleCommand("gsSnowAddSalt")
    end
end
function SnowSystem:loadMapData(_, missionInfo, _)
    self.missionInfo = missionInfo
    self.environment = self.mission.environment
    self.indoorMask = self.mission.indoorMask
    if g_addCheatCommands and g_currentMission:getIsServer() then
        addConsoleCommand("gsSnowAdd", "Add snow", "consoleCommandAddSnow", self)
        addConsoleCommand("gsSnowSet", "Set snow", "consoleCommandSetSnow", self)
        addConsoleCommand("gsSnowReset", "Reset snow", "consoleCommandResetSnow", self)
        addConsoleCommand("gsSnowShaderSet", "Force snow shader value for map objects", "consoleCommandSetSnowShader", self)
        addConsoleCommand("gsSnowAddSalt", "Salt around player", "consoleCommandSalt", self)
    end
end
function SnowSystem:loadFromXMLFile(filename)
    local xmlFile = XMLFile.load("environment", filename)
    if xmlFile ~= nil then
        self.height = xmlFile:getFloat("environment.snow#physicalHeight", self.height)
        self.exactHeight = xmlFile:getFloat("environment.snow#height", self.exactHeight)
        for _, key in xmlFile:iterator("environment.snow.queue.delta") do
            local delta = xmlFile:getFloat(key)
            table.insert(self.updateQueue, delta)
        end
        if self.currentApplyingDelta == nil and #self.updateQueue > 0 then
            self.startPendingQueueTask = true
        end
        self.currentApplyingDelta = xmlFile:getFloat("environment.snow.queue#current")
        xmlFile:delete()
    end
    if g_currentMission.environment.weather.snowHeight == 0 and self.exactHeight ~= 0 then
        Logging.info("Weather indicates there must be no snow, snow system disagrees. Resetting snow.")
        self:setSnowHeight(0)
    end
    self:updateSnowShader()
end
function SnowSystem:saveToXMLFile(file, key)
    local xmlFile = XMLFile.wrap(file)
    xmlFile:setFloat(key .. "#physicalHeight", self.height)
    xmlFile:setFloat(key .. "#height", self.exactHeight)
    if self.currentApplyingDelta ~= nil then
        xmlFile:setFloat(key .. ".queue#current", self.currentApplyingDelta)
    end
    xmlFile:setSortedTable("environment.snow.queue.delta", self.updateQueue, function(keyQueueDelta, value)
        -- upvalues: (copy) xmlFile
        xmlFile:setFloat(keyQueueDelta, value)
    end)
    xmlFile:delete()
end
function SnowSystem:saveState(directory)
    saveDensityMapHeightUpdaterStateToFile(self.updater, directory .. "/snow_state.xml")
end
function SnowSystem:onTerrainLoad(_)
    local terrainDetailHeightId = self.mission.terrainDetailHeightId
    self.snowHeightTypeIndex = g_densityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeIndex(FillType.SNOW)
    local modifiers = {
        ["height"] = {}
    }
    modifiers.height.modifierHeight = DensityMapModifier.new(terrainDetailHeightId, getDensityMapHeightFirstChannel(terrainDetailHeightId), getDensityMapHeightNumChannels(terrainDetailHeightId))
    modifiers.height.filterHeight = DensityMapFilter.new(modifiers.height.modifierHeight)
    modifiers.height.filterType = DensityMapFilter.new(terrainDetailHeightId, g_densityMapHeightManager.heightTypeFirstChannel, g_densityMapHeightManager.heightTypeNumChannels)
    modifiers.height.filterSnowType = DensityMapFilter.new(terrainDetailHeightId, g_densityMapHeightManager.heightTypeFirstChannel, g_densityMapHeightManager.heightTypeNumChannels)
    modifiers.height.filterSnowType:setValueCompareParams(DensityValueCompareType.EQUAL, self.snowHeightTypeIndex)
    modifiers.fillType = {}
    modifiers.fillType.modifierType = DensityMapModifier.new(terrainDetailHeightId, g_densityMapHeightManager.heightTypeFirstChannel, g_densityMapHeightManager.heightTypeNumChannels)
    modifiers.fillType.filterHeight = DensityMapFilter.new(terrainDetailHeightId, getDensityMapHeightFirstChannel(terrainDetailHeightId), getDensityMapHeightNumChannels(terrainDetailHeightId))
    modifiers.fillType.filterType = DensityMapFilter.new(modifiers.fillType.modifierType)
    local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = self.mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
    modifiers.sprayLevel = {}
    modifiers.sprayLevel.modifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, g_terrainNode)
    self.modifiers = modifiers
    self.layerHeight = 1 / g_densityMapHeightManager.heightToDensityValue
    if self.isServer then
        self.updater = g_densityMapHeightManager.terrainDetailHeightUpdater
        setDensityMapHeightUpdateType(self.updater, self.snowHeightTypeIndex)
        setDensityMapHeightUpdateApplyMaxTimePerFrame(self.updater, SnowSystem.MAX_MS_PER_FRAME)
        if self.indoorMask:hasMask() then
            local blockMaskId, blockMaskFirstChannel, blockMaskNumChannels = self.indoorMask:getDensityMapData()
            setDensityMapHeightUpdateApplyBlockMask(self.updater, blockMaskId, blockMaskFirstChannel, blockMaskNumChannels)
        end
        if self.missionInfo.isValid and self.missionInfo.densityMapRevision == g_densityMapRevision then
            local blockMaskFirstChannel, blockMaskNumChannels = loadDensityMapHeightUpdaterStateFromFile(self.updater, self.missionInfo.savegameDirectory .. "/snow_state.xml")
            if blockMaskFirstChannel and blockMaskNumChannels > -1 then
                self.currentApplyingDelta = blockMaskNumChannels
            end
        end
        setDensityMapHeightUpdateApplyFinishedCallback(self.updater, "onApplicationFinished", self)
    end
end
function SnowSystem:update(dt)
    if self.isServer and self.startPendingQueueTask then
        local delta = table.remove(self.updateQueue, 1)
        if delta ~= nil then
            self:startApplication(delta)
        end
        self.startPendingQueueTask = nil
    end
    if self.vehicleWakeUpIndex > 0 then
        self.vehicleWakeUpTimer = self.vehicleWakeUpTimer + dt
        if self.vehicleWakeUpTimer > self.vehicleWakeUpDelay then
            local delta = self.mission.vehicleSystem.vehicles[self.vehicleWakeUpIndex]
            if delta == nil then
                self.vehicleWakeUpIndex = 0
            else
                delta:wakeUp()
                self.vehicleWakeUpIndex = self.vehicleWakeUpIndex + 1
            end
            self.vehicleWakeUpTimer = 0
        end
    end
    if self.itemWakeUpIndex > 0 then
        self.itemWakeUpTimer = self.itemWakeUpTimer + dt
        if self.itemWakeUpTimer > self.itemWakeUpDelay then
            local delta = self.mission.itemSystem.sortedItemsToSave[self.itemWakeUpIndex]
            if delta == nil then
                self.itemWakeUpIndex = 0
            else
                if delta.item.wakeUp ~= nil then
                    delta.item:wakeUp()
                end
                self.itemWakeUpIndex = self.itemWakeUpIndex + 1
            end
            self.itemWakeUpTimer = 0
        end
    end
end
function SnowSystem:applySnow(delta)
    if self.isServer then
        if self.currentApplyingDelta == nil then
            self:startApplication(delta)
        else
            local folded = false
            if #self.updateQueue > 0 then
                local lastItemDelta = self.updateQueue[#self.updateQueue]
                if lastItemDelta <= SnowSystem.DELTA_REMOVE_ALL then
                else
                    self.updateQueue[#self.updateQueue] = lastItemDelta + delta
                    folded = true
                end
            end
            if not folded then
                self.updateQueue[#self.updateQueue + 1] = delta
                return
            end
        end
    end
end
function SnowSystem:startApplication(delta)
    local blockMaskId, blockMaskFirstChannel, blockMaskNumChannels = self.indoorMask:getDensityMapData()
    self.currentApplyingDelta = delta
    applyDensityMapHeightUpdate(self.updater, self.snowHeightTypeIndex, delta, delta < 0 and 0 or SnowSystem.MAX_HEIGHT, false, false, delta < 0 and 0 or blockMaskId, blockMaskFirstChannel, blockMaskNumChannels, "onApplicationFinished", self, self:getMaxUpdateTime(), g_currentMission.tireTrackSystem.tireTrackSystemId)
end
function SnowSystem:onApplicationFinished()
    local currentDelta = self.currentApplyingDelta
    self.currentApplyingDelta = nil
    if currentDelta > 0 then
        self:removeSnowUnderObjects(currentDelta)
    else
        self:onHeightChanged(currentDelta)
    end
    if #self.updateQueue > 0 then
        table.remove(self.updateQueue, 1)
        self:startApplication(self.updateQueue[1])
    end
end
function SnowSystem:onHeightChanged(_)
    self.vehicleWakeUpIndex = 1
    self.itemWakeUpIndex = 1
    g_messageCenter:publish(MessageType.SNOW_HEIGHT_CHANGED, math.max(self.height / SnowSystem.MAX_HEIGHT, 0), (math.max(self.height, 0)))
end
function SnowSystem:removeSnowUnderObjects(delta)
    for _, object in pairs(self.mission.itemSystem.itemsToSave) do
        if object.item.doDensityMapItemAreaUpdate ~= nil then
            object.item:doDensityMapItemAreaUpdate(self.removeSnow, self, delta / self.layerHeight)
        end
    end
    for _, object in pairs(self.mission.vehicleSystem.vehicles) do
        if object.spec_wheels ~= nil then
            for _, wheel in pairs(object.spec_wheels.wheels) do
                local width = 0.5 * wheel.physics.width
                local length = math.min(0.5, 0.5 * wheel.physics.width)
                local x, _, z = localToLocal(wheel.driveNode, wheel.repr, 0, 0, 0)
                local x0, _, z0 = localToWorld(wheel.repr, x + width, 0, z - length)
                local x1, _, z1 = localToWorld(wheel.repr, x - width, 0, z - length)
                local x2, _, z2 = localToWorld(wheel.repr, x + width, 0, z + length)
                self:removeSnow(x0, z0, x1, z1, x2, z2, delta / self.layerHeight)
            end
        end
    end
    self:onHeightChanged(delta)
end
function SnowSystem:saltArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local modifiers = self.modifiers.height
    local modifier = modifiers.modifierHeight
    local filter1 = modifiers.filterType
    local filter2 = modifiers.filterHeight
    modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    filter1:setValueCompareParams(DensityValueCompareType.EQUAL, self.snowHeightTypeIndex)
    filter2:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
    FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    FSDensityMapUtil.eraseTireTrack(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local density, area, totalArea = modifier:executeSetWithStats(0, filter1, filter2)
    local modifier = self.modifiers.sprayLevel.modifier
    modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    modifier:executeSet(0)
    if density ~= 0 then
        local modifier = self.modifiers.fillType.modifierType
        modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        filter2:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        modifier:executeSet(0, filter2)
    end
    return area, totalArea
end
function SnowSystem:getSnowHeightAtArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local modifiers = self.modifiers.height
    local modifier = modifiers.modifierHeight
    local filter = modifiers.filterType
    modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    filter:setValueCompareParams(DensityValueCompareType.EQUAL, self.snowHeightTypeIndex)
    local density, area, _ = modifier:executeGet(filter)
    return area == 0 and 0 or density / area * self.layerHeight
end
function SnowSystem:setSnowHeightAtArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, height)
    local modifiers = height / self.layerHeight
    local layers = math.floor(modifiers)
    if layers > 0 then
        local modifiers = self.modifiers.fillType
        local modifier = modifiers.modifierType
        local filter = modifiers.filterHeight
        modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        filter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        modifier:executeSet(self.snowHeightTypeIndex, filter)
    end
    local modifiers = self.modifiers.height
    local modifier = modifiers.modifierHeight
    local filter = modifiers.filterType
    modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    filter:setValueCompareParams(DensityValueCompareType.EQUAL, self.snowHeightTypeIndex)
    modifier:executeSet(layers, filter)
    if layers == 0 then
        local modifiers = self.modifiers.fillType
        local modifier = modifiers.modifierType
        local filter = modifiers.filterHeight
        modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        filter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        modifier:executeSet(0, filter)
    end
end
function SnowSystem:removeSnow(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    local modifiers = self.modifiers.height
    local modifier = modifiers.modifierHeight
    local filter = modifiers.filterType
    modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    filter:setValueCompareParams(DensityValueCompareType.EQUAL, self.snowHeightTypeIndex)
    if modifier:executeAddWithStats(-layers, filter) ~= 0 then
        local modifiers = self.modifiers.fillType
        local modifier = modifiers.modifierType
        local filter = modifiers.filterHeight
        modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        filter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        modifier:executeSet(0, filter)
    end
end
function SnowSystem:setSnowHeight(height)
    local deltaHeight = math.clamp(height, -4.02, SnowSystem.MAX_HEIGHT)
    self.exactHeight = math.max(deltaHeight, 0)
    self:updateSnowShader()
    if self.height ~= deltaHeight then
        if self.height > 0 and deltaHeight <= 0 then
            self:removeAll()
        end
        if self.height < 0 and deltaHeight > 0 then
            self.height = 0
        elseif self.height < 0 and self.height < deltaHeight then
            self.height = deltaHeight
        end
        if self.isServer then
            if self.layerHeight == nil then
                return
            end
            if math.abs(deltaHeight - self.height) >= self.layerHeight then
                local deltaHeight = deltaHeight - self.height
                self:applySnow(deltaHeight)
                self.height = self.height + deltaHeight
            end
        end
    end
end
function SnowSystem:updateSnowShader()
    self.snowShaderValue = 0
    if self.layerHeight ~= nil then
        self.snowShaderValue = self.exactHeight / self.layerHeight
    end
    setSharedShaderParameter(Shader.PARAM_SHARED_SNOW, self.debug_forcedSnowShaderValue or self.snowShaderValue)
end
function SnowSystem:getSnowShaderValue()
    return self.debug_forcedSnowShaderValue or self.snowShaderValue
end
function SnowSystem:removeAll(force)
    if self.height > 0 or (self.exactHeight > 0 or force) then
        self:applySnow(SnowSystem.DELTA_REMOVE_ALL)
        self.height = 0
        self.exactHeight = 0
        self:updateSnowShader()
    end
end
function SnowSystem:getHeight()
    return self.height
end
function SnowSystem:getMaxUpdateTime()
    if g_sleepManager.isSleeping then
        return SnowSystem.MAX_MS_PER_FRAME_SLEEPING
    else
        return SnowSystem.MAX_MS_PER_FRAME
    end
end
function SnowSystem:onSleepChanged(_)
    setDensityMapHeightUpdateApplyMaxTimePerFrame(self.updater, self:getMaxUpdateTime())
end
function SnowSystem:consoleCommandAddSnow(layers)
    if layers == nil or tonumber(layers) == nil then
        return "Usage: gsSnowAdd layers"
    end
    local height = tonumber(layers)
    local height = self.height + height * self.layerHeight
    self:setSnowHeight(height)
    return string.format("New height is %.3f", height)
end
function SnowSystem:consoleCommandSetSnow(height)
    if height == nil or tonumber(height) == nil then
        return "Usage: gsSnowSet height"
    end
    height = tonumber(height)
    self:setSnowHeight(height)
    return string.format("New height is %.3f", height)
end
function SnowSystem:consoleCommandResetSnow()
    self:removeAll()
end
function SnowSystem:consoleCommandSetSnowShader(snowShaderValue)
    self.debug_forcedSnowShaderValue = tonumber(snowShaderValue)
    self:updateSnowShader()
    local returnStr = "forcedSnowShaderValue=" .. tostring(self.debug_forcedSnowShaderValue)
    if self.debug_forcedSnowShaderValue == nil then
        return returnStr .. "\nUsing value from weather simulation"
    else
        return returnStr .. "\nUse gsSnowShaderSet without parameter to use weather again"
    end
end
function SnowSystem:consoleCommandSalt(radius)
    radius = tonumber(radius) or 5
    local x, _, z = getWorldTranslation(g_cameraManager:getActiveCamera())
    self:saltArea(x - radius, z - radius, x + radius, z - radius, x - radius, z + radius)
end