TramlineMapDensityMapTask = {}
local TramlineMapDensityMapTask_mt = Class(TramlineMapDensityMapTask, DensityMapUpdateTask)
function TramlineMapDensityMapTask.registerXMLPaths(schema, basePath)
    DensityMapUpdateTask.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#farmlandId", "Id of the farmland")
end
function TramlineMapDensityMapTask.new(customMt)
    -- upvalues: (copy) TramlineMapDensityMapTask_mt
    local self = TramlineMapDensityMapTask:superClass().new(customMt or TramlineMapDensityMapTask_mt)
    self.farmlandId = nil
    self.multiModifier = nil
    self.frameBudget = 0.00025
    self.frames = 0
    self.totalTime = 0
    self.minX = -g_currentMission.terrainSize * 0.5
    self.maxX = g_currentMission.terrainSize * 0.5
    self.minY = -g_currentMission.terrainSize * 0.5
    self.maxY = g_currentMission.terrainSize * 0.5
    return self
end
function TramlineMapDensityMapTask:saveToXMLFile(xmlFile, key)
    xmlFile:setString(key .. "#status", DensityMapUpdateTaskState.getName(self.state))
    if self.state == DensityMapUpdateTaskState.RUNNING then
        xmlFile:setFloat(key .. ".area#currentMinY", self.currentMinY)
        xmlFile:setFloat(key .. ".area#currentMaxY", self.currentMaxY)
    end
    if self.farmlandId ~= nil then
        xmlFile:setInt(key .. "#farmlandId", self.farmlandId)
    end
end
function TramlineMapDensityMapTask:loadFromXMLFile(xmlFile, key)
    self.farmlandId = xmlFile:getInt(key .. "#farmlandId") or self.farmlandId
    self.state = DensityMapUpdateTaskState.getByName(xmlFile:getString(key .. "#status")) or DensityMapUpdateTaskState.CREATED
    if self.state == DensityMapUpdateTaskState.RUNNING then
        self.currentMinY = xmlFile:getFloat(key .. ".area#currentMinY")
        self.currentMaxY = xmlFile:getFloat(key .. ".area#currentMaxY")
    end
    if g_precisionFarming ~= nil and g_precisionFarming.tramlineMap ~= nil then
        self.multiModifier = g_precisionFarming.tramlineMap:getResetTramlinesMultiMudifier(farmlandId)
    end
    if self.state == DensityMapUpdateTaskState.RUNNING then
        self:start()
    end
    return true
end
function TramlineMapDensityMapTask:setData(farmlandId)
    self.farmlandId = farmlandId
    self.multiModifier = g_precisionFarming.tramlineMap:getResetTramlinesMultiMudifier(farmlandId)
end
function TramlineMapDensityMapTask:prepare()
    local farmland = g_farmlandManager:getFarmlandById(self.farmlandId)
    if farmland == nil then
        Logging.warning("TramlineMapDensityMapTask:prepare() - Farmland with id %d not found!", self.farmlandId)
        self:setFinished()
    else
        local settings = FieldCourseSettings.new()
        settings.implementWidth = 15
        settings.numHeadlands = 1
        local x, z = farmland:getIndicatorPosition()
        self.courseField = FieldCourseField.generateAtPosition(x, z, settings, function(courseField, success)
            -- upvalues: (copy) self
            self.courseField = nil
            if success then
                local minX = math.huge
                local minZ = math.huge
                local maxX = -math.huge
                local maxZ = -math.huge
                self.polygon = DensityMapPolygon.new()
                local boundaryLine = courseField.fieldRootBoundary.boundaryLine
                local i = 1
                for i = i, #boundaryLine - 1 do
                    local px = boundaryLine[i][1]
                    local pz = boundaryLine[i][2]
                    self.polygon:addPolygonPoint(px, pz)
                    minX = math.min(minX, px)
                    minZ = math.min(minZ, pz)
                    maxX = math.max(maxX, px)
                    maxZ = math.max(maxZ, pz)
                end
                self.minX = minX
                self.maxX = maxX
                self.minY = minZ
                self.maxY = maxZ
                self.currentMinY = self.minY
                local i = self.minY + self.maxRegionPerFrame
                self.currentMaxY = math.min(i, maxZ)
                self.polygon:applyToModifier(self.multiModifier)
            else
                self:setFinished()
                Logging.devWarning("TramlineMapDensityMapTask: Failed to generate FieldCourseField for farmland %d", self.farmlandId)
            end
        end)
        if self.courseField.setIgnoreCollisions ~= nil then
            self.courseField:setIgnoreCollisions(true)
        end
        if self.courseField.setIgnoreIslands ~= nil then
            self.courseField:setIgnoreIslands(true)
        end
    end
end
function TramlineMapDensityMapTask:enqueue(immediate)
    g_precisionFarming.densityMapUpdater:addUpdateTask(self, immediate)
end
function TramlineMapDensityMapTask:start()
    if self.multiModifier == nil then
        Logging.error("TramlineMapDensityMapTask:start() - MultiModifier not set!")
        return false
    end
    if self.state == DensityMapUpdateTaskState.RUNNING or self.state == DensityMapUpdateTaskState.FINISHED then
        return false
    end
    self.state = DensityMapUpdateTaskState.RUNNING
    self:prepare()
    if self.currentMinY == nil then
        self.currentMinY = self.minY
        self.currentMaxY = self.minY + self.maxRegionPerFrame
    end
    return true
end
function TramlineMapDensityMapTask:update(dt)
    if self.state == DensityMapUpdateTaskState.RUNNING then
        self.frames = self.frames + 1
        if self.courseField ~= nil then
            self.courseField:update(dt, self.frameBudget)
            return
        end
        local startTime = getTimeSec()
        while getTimeSec() - startTime < self.frameBudget do
            self.multiModifier:setPolygonClipRegion(self.currentMinY, self.currentMaxY)
            multiModifier:execute()
            self.currentMinY = self.currentMaxY
            self.currentMaxY = math.min(self.currentMinY + self.maxRegionPerFrame, self.maxY)
            if self.currentMinY >= self.maxY then
                break
            end
        end
        self.totalTime = self.totalTime + (getTimeSec() - startTime)
        if self.currentMinY < self.maxY then
            return
        end
        if g_precisionFarming ~= nil and g_precisionFarming.tramlineMap ~= nil then
            g_precisionFarming:updatePrecisionFarmingOverlays()
            g_precisionFarming.tramlineMap:setMinimapRequiresUpdate(true)
            g_precisionFarming.tramlineMap:onDensityMapUpdateFinished(self.farmlandId)
        end
        self:setFinished()
    end
end
function TramlineMapDensityMapTask:setFinished()
    Logging.devInfo("TramlineMapDensityMapTask: Finished after %d frames / %.1f ms (Farmland %d)", self.frames, self.totalTime * 1000, self.farmlandId)
    self.state = DensityMapUpdateTaskState.FINISHED
end