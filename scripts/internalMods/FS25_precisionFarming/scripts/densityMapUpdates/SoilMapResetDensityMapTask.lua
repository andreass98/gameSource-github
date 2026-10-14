SoilMapResetDensityMapTask = {}
local SoilMapResetDensityMapTask_mt = Class(SoilMapResetDensityMapTask, DensityMapUpdateTask)
function SoilMapResetDensityMapTask.registerXMLPaths(schema, basePath)
    DensityMapUpdateTask.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#farmlandId", "Id of the farmland")
end
function SoilMapResetDensityMapTask.new(customMt)
    -- upvalues: (copy) SoilMapResetDensityMapTask_mt
    local self = SoilMapResetDensityMapTask:superClass().new(customMt or SoilMapResetDensityMapTask_mt)
    self.farmlandId = nil
    self.multiModifier = nil
    self.frameBudget = 0.00025
    self.frames = 0
    self.totalTime = 0
    self.minX = -g_currentMission.terrainSize * 0.5
    self.maxX = g_currentMission.terrainSize * 0.5
    self.minZ = -g_currentMission.terrainSize * 0.5
    self.maxZ = g_currentMission.terrainSize * 0.5
    return self
end
function SoilMapResetDensityMapTask:saveToXMLFile(xmlFile, key)
    xmlFile:setString(key .. "#status", DensityMapUpdateTaskState.getName(self.state))
    if self.state == DensityMapUpdateTaskState.RUNNING then
        xmlFile:setFloat(key .. ".area#currentMinZ", self.currentMinZ)
        xmlFile:setFloat(key .. ".area#currentMaxZ", self.currentMaxZ)
    end
    if self.farmlandId ~= nil then
        xmlFile:setInt(key .. "#farmlandId", self.farmlandId)
    end
end
function SoilMapResetDensityMapTask:loadFromXMLFile(xmlFile, key)
    self.farmlandId = xmlFile:getInt(key .. "#farmlandId") or self.farmlandId
    self.state = DensityMapUpdateTaskState.getByName(xmlFile:getString(key .. "#status")) or DensityMapUpdateTaskState.CREATED
    if self.state == DensityMapUpdateTaskState.RUNNING then
        self.currentMinZ = xmlFile:getFloat(key .. ".area#currentMinZ")
        self.currentMaxZ = xmlFile:getFloat(key .. ".area#currentMaxZ")
    end
    if g_precisionFarming == nil or g_precisionFarming.soilMap == nil then
        Logging.error("SoilMapResetDensityMapTask:loadFromXMLFile() - SoilMap not initialized!")
        return false
    end
    self.multiModifier = g_precisionFarming.soilMap:getFarmlandResetMultiModifier(farmlandId)
    if self.state == DensityMapUpdateTaskState.RUNNING then
        self:start()
    end
    return true
end
function SoilMapResetDensityMapTask:setData(farmlandId)
    self.farmlandId = farmlandId
    self.multiModifier = g_precisionFarming.soilMap:getFarmlandResetMultiModifier(farmlandId)
end
function SoilMapResetDensityMapTask:prepare() end
function SoilMapResetDensityMapTask:enqueue(immediate)
    g_precisionFarming.densityMapUpdater:addUpdateTask(self, immediate)
end
function SoilMapResetDensityMapTask:start()
    if self.multiModifier == nil then
        Logging.error("SoilMapResetDensityMapTask:start() - MultiModifier not set!")
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
function SoilMapResetDensityMapTask:update(_)
    if self.state == DensityMapUpdateTaskState.RUNNING then
        self.frames = self.frames + 1
        local startTime = getTimeSec()
        while getTimeSec() - startTime < self.frameBudget do
            self.multiModifier:updateParallelogramWorldCoords(self.minX, self.currentMinZ, self.maxX, self.currentMinZ, self.minX, self.currentMaxZ, DensityCoordType.POINT_POINT_POINT)
            multiModifier:execute()
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
        if g_precisionFarming ~= nil and g_precisionFarming.soilMap ~= nil then
            g_precisionFarming:updatePrecisionFarmingOverlays()
            g_precisionFarming.soilMap:setMinimapRequiresUpdate(true)
        end
        self:setFinished()
    end
end
function SoilMapResetDensityMapTask:setFinished()
    Logging.devInfo("SoilMapResetDensityMapTask: Finished after %d frames / %.1f ms", self.frames, self.totalTime * 1000)
    self.state = DensityMapUpdateTaskState.FINISHED
end