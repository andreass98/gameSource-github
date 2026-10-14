RiceFieldUpdateTask = {}
local RiceFieldUpdateTask_mt = Class(RiceFieldUpdateTask, DensityMapUpdateTask)
function RiceFieldUpdateTask.registerXMLPaths(schema, basePath)
    DensityMapUpdateTask.registerXMLPaths(schema, basePath)
end
function RiceFieldUpdateTask.new(customMt)
    -- upvalues: (copy) RiceFieldUpdateTask_mt
    local self = RiceFieldUpdateTask:superClass().new(customMt or RiceFieldUpdateTask_mt)
    self.multiModifier = DensityMapMultiModifier.new()
    return self
end
function RiceFieldUpdateTask:saveToXMLFile(xmlFile, key)
    RiceFieldUpdateTask:superClass().saveToXMLFile(self, xmlFile, key)
end
function RiceFieldUpdateTask:loadFromXMLFile(xmlFile, key)
    RiceFieldUpdateTask:superClass().loadFromXMLFile(self, xmlFile, key)
    if self.state == DensityMapUpdateTaskState.RUNNING then
        self:start()
    end
    return true
end
function RiceFieldUpdateTask:performPerlinNoiseDestruction(fruitTypes, waterFillLevelPerSqm, perlinFilter)
    for _, desc in ipairs(fruitTypes) do
        if desc.minWaterLitersPerSqm == nil and desc.maxWaterLitersPerSqm == nil then
            return
        end
        local modifier = desc:getModifier()
        local fruitReqWaterFilter = desc:getFilter()
        local growthState = desc.numGrowthStates
        for growthState = growthState, 1, -1 do
            local hasTooLittleWater = false
            if desc.minWaterLitersPerSqm[growthState] ~= nil then
                hasTooLittleWater = waterFillLevelPerSqm < desc.minWaterLitersPerSqm[growthState]
            end
            local hasTooMuchWater = false
            if desc.maxWaterLitersPerSqm[growthState] ~= nil then
                hasTooMuchWater = desc.maxWaterLitersPerSqm[growthState] < waterFillLevelPerSqm
            end
            if hasTooLittleWater or hasTooMuchWater then
                local replacementFoliageState = desc.penaltyStateName[growthState] and desc:getGrowthStateByName(desc.penaltyStateName[growthState]) or 0
                perlinFilter:setValueCompareParams(DensityValueCompareType.GREATER, 10000 * (1 - (desc.penaltyPercentage and desc.penaltyPercentage[growthState] or 0.1)))
                fruitReqWaterFilter:setValueCompareParams(DensityValueCompareType.EQUAL, growthState + 1)
                self.multiModifier:addExecuteSet(replacementFoliageState, modifier, perlinFilter, fruitReqWaterFilter)
            end
        end
    end
end
function RiceFieldUpdateTask:enqueue()
    g_fieldManager:addFieldUpdateTask(self)
end
function RiceFieldUpdateTask:start(_, immediate)
    if self.area == nil then
        self.state = DensityMapUpdateTaskState.FINISHED
        Logging.warning("Missing area for RiceFieldUpdateTask")
    else
        self.state = DensityMapUpdateTaskState.RUNNING
        local multiModifier = self.multiModifier
        self.area:applyToModifier(multiModifier)
        self.minY, self.maxY = multiModifier:getPolygonMinMaxZ()
        if self.minY ~= nil then
            if self.currentMinY == nil then
                self.currentMinY = self.minY
                self.currentMaxY = self.minY + self.maxRegionPerFrame
            end
            if immediate then
                self.currentMinY = self.minY
                self.currentMaxY = self.maxY
            end
        end
    end
end
function RiceFieldUpdateTask:update(_)
    if self.state == DensityMapUpdateTaskState.RUNNING then
        local multiModifier = self.multiModifier
        if self.currentMinY ~= nil then
            multiModifier:setPolygonClipRegion(self.currentMinY, self.currentMaxY)
        end
        multiModifier:execute()
        if self.minY == nil then
            self.state = DensityMapUpdateTaskState.FINISHED
        else
            self.currentMinY = self.currentMaxY
            self.currentMaxY = math.min(self.currentMinY + self.maxRegionPerFrame, self.maxY)
            if self.currentMinY == self.maxY then
                self.state = DensityMapUpdateTaskState.FINISHED
                return
            end
        end
    end
end