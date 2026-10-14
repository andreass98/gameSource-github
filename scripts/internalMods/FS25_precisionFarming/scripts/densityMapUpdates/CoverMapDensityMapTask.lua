CoverMapDensityMapTask = {}
local CoverMapDensityMapTask_mt = Class(CoverMapDensityMapTask, DensityMapUpdateTask)
function CoverMapDensityMapTask.registerXMLPaths(schema, basePath)
    DensityMapUpdateTask.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#farmId", "Id of the farm")
    schema:register(XMLValueType.INT, basePath .. "#farmlandId", "Id of the farmland")
end
function CoverMapDensityMapTask.new(customMt)
    -- upvalues: (copy) CoverMapDensityMapTask_mt
    local self = CoverMapDensityMapTask:superClass().new(customMt or CoverMapDensityMapTask_mt)
    self.farmId = nil
    self.farmlandId = nil
    self.multiModifier = nil
    self.farmlandIds = nil
    self.frameBudget = 0.00025
    self.frames = 0
    self.totalTime = 0
    self.minX = -g_currentMission.terrainSize * 0.5
    self.maxX = g_currentMission.terrainSize * 0.5
    self.minZ = -g_currentMission.terrainSize * 0.5
    self.maxZ = g_currentMission.terrainSize * 0.5
    self.sampleStateNumMatchingPixels = {}
    return self
end
function CoverMapDensityMapTask:saveToXMLFile(xmlFile, key)
    xmlFile:setString(key .. "#status", DensityMapUpdateTaskState.getName(self.state))
    if self.state == DensityMapUpdateTaskState.RUNNING then
        xmlFile:setFloat(key .. ".area#currentMinZ", self.currentMinZ)
        xmlFile:setFloat(key .. ".area#currentMaxZ", self.currentMaxZ)
    end
    if self.farmId ~= nil then
        xmlFile:setInt(key .. "#farmId", self.farmId)
    end
    if self.farmlandId ~= nil then
        xmlFile:setInt(key .. "#farmlandId", self.farmlandId)
    end
end
function CoverMapDensityMapTask:loadFromXMLFile(xmlFile, key)
    self.farmId = xmlFile:getInt(key .. "#farmId") or self.farmId
    self.farmlandId = xmlFile:getInt(key .. "#farmlandId") or self.farmlandId
    self.state = DensityMapUpdateTaskState.getByName(xmlFile:getString(key .. "#status")) or DensityMapUpdateTaskState.CREATED
    if self.state == DensityMapUpdateTaskState.RUNNING then
        self.currentMinZ = xmlFile:getFloat(key .. ".area#currentMinZ")
        self.currentMaxZ = xmlFile:getFloat(key .. ".area#currentMaxZ")
    end
    if g_precisionFarming ~= nil and g_precisionFarming.coverMap ~= nil then
        self.multiModifier, self.farmlandIds = g_precisionFarming.coverMap:getCoverMultiModifier(farmId, farmlandId)
    end
    if self.state == DensityMapUpdateTaskState.RUNNING then
        self:start()
    end
    return true
end
function CoverMapDensityMapTask:setData(farmId, farmlandId)
    self.farmId = farmId
    self.farmlandId = farmlandId
    self.multiModifier, self.farmlandIds = g_precisionFarming.coverMap:getCoverMultiModifier(farmId, farmlandId)
end
function CoverMapDensityMapTask:prepare() end
function CoverMapDensityMapTask:enqueue(immediate)
    g_precisionFarming.densityMapUpdater:addUpdateTask(self, immediate)
end
function CoverMapDensityMapTask:start()
    if self.multiModifier == nil then
        Logging.error("CoverMapDensityMapTask:start() - MultiModifier not set!")
        return false
    end
    if self.state == DensityMapUpdateTaskState.RUNNING or self.state == DensityMapUpdateTaskState.FINISHED then
        return false
    end
    self.state = DensityMapUpdateTaskState.RUNNING
    self:prepare()
    if self.farmlandId ~= nil then
        local farmland = g_farmlandManager:getFarmlandById(self.farmlandId)
        if farmland ~= nil and farmland.getBoundingBox ~= nil then
            local minX, minZ, maxX, maxZ = farmland:getBoundingBox()
            if minX ~= nil then
                self.minX = minX
                self.maxX = maxX
                self.minZ = minZ
                self.maxZ = maxZ
            end
        end
    end
    if self.currentMinZ == nil then
        self.currentMinZ = self.minZ
        self.currentMaxZ = math.min(self.minZ + self.maxRegionPerFrame, self.maxZ)
    end
    return true
end
function CoverMapDensityMapTask:update(_)
    if self.state == DensityMapUpdateTaskState.RUNNING then
        self.frames = self.frames + 1
        local startTime = getTimeSec()
        while getTimeSec() - startTime < self.frameBudget do
            self.multiModifier:updateParallelogramWorldCoords(self.minX, self.currentMinZ, self.maxX, self.currentMinZ, self.minX, self.currentMaxZ, DensityCoordType.POINT_POINT_POINT)
            local sliceNumMatchingPixels = {}
            multiModifier:execute(nil, sliceNumMatchingPixels)
            for label, value in pairs(sliceNumMatchingPixels) do
                self.sampleStateNumMatchingPixels[label] = (self.sampleStateNumMatchingPixels[label] or 0) + value
            end
            self.currentMinZ = self.currentMaxZ
            self.currentMaxZ = math.min(self.currentMinZ + self.maxRegionPerFrame, self.maxZ)
            if self.currentMinZ >= self.maxZ then
                break
            end
        end
        self.totalTime = self.totalTime + (getTimeSec() - startTime)
        if self.currentMinZ < self.maxZ then
            return
        end
        if g_precisionFarming ~= nil and g_precisionFarming.coverMap ~= nil then
            g_precisionFarming:updatePrecisionFarmingOverlays()
            g_precisionFarming.coverMap:setMinimapRequiresUpdate(true)
        end
        self:setFinished()
    end
end
function CoverMapDensityMapTask:getSampledPercentageByFarmlandId()
    local sampledPercentageByFarmlandId = {}
    if self.farmlandIds == nil then
        return sampledPercentageByFarmlandId
    end
    for _, farmlandId in ipairs(self.farmlandIds) do
        local fieldLabel = "field_" .. tostring(farmlandId)
        local sampledLabel = "sampled_" .. tostring(farmlandId)
        local areaField = self.sampleStateNumMatchingPixels[fieldLabel] or 0
        if areaField > 0 then
            sampledPercentageByFarmlandId[farmlandId] = (self.sampleStateNumMatchingPixels[sampledLabel] or 0) / areaField
        else
            sampledPercentageByFarmlandId[farmlandId] = 0
        end
    end
    return sampledPercentageByFarmlandId
end
function CoverMapDensityMapTask:setFinished()
    Logging.devInfo("CoverMapDensityMapTask: Finished after %d frames / %.1f ms", self.frames, self.totalTime * 1000)
    self.state = DensityMapUpdateTaskState.FINISHED
    if g_precisionFarming ~= nil and g_precisionFarming.coverMap ~= nil then
        g_precisionFarming.coverMap:onCoverUpdateFinished(self.farmId, self.farmlandId, self:getSampledPercentageByFarmlandId())
    end
end