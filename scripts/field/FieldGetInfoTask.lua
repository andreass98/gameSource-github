FieldGetInfoTask = {}
local FieldGetInfoTask_mt = Class(FieldGetInfoTask, DensityMapUpdateTask)
function FieldGetInfoTask.new(customMt)
    -- upvalues: (copy) FieldGetInfoTask_mt
    local self = FieldGetInfoTask:superClass().new(customMt or FieldGetInfoTask_mt)
    self.fieldId = nil
    return self
end
function FieldGetInfoTask:setCallback(callbackFunc, callbackTarget, callbackArgs)
    self.callbackFunc = callbackFunc
    self.callbackTarget = callbackTarget
    self.callbackArgs = callbackArgs
end
function FieldGetInfoTask:setField(field)
    self.fieldId = field:getId()
end
function FieldGetInfoTask:getField()
    return g_fieldManager:getFieldById(self.fieldId)
end
function FieldGetInfoTask:setFruitTypes(fruits)
    fruits = fruits or g_fruitTypeManager:getFruitTypes()
    self.multiModifier = DensityMapMultiModifier.new()
    for _, desc in pairs(fruits) do
        if desc.terrainDataPlaneId ~= nil then
            local fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, g_terrainNode)
            local foliageState = 1
            for foliageState = foliageState, desc.numFoliageStates do
                local fruitFilter = DensityMapFilter.new(fruitModifier)
                fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, foliageState)
                self.multiModifier:addExecuteGet(desc.name .. "|" .. foliageState, fruitModifier, fruitFilter)
            end
        end
    end
end
function FieldGetInfoTask:enqueue()
    g_fieldManager:addFieldUpdateTask(self)
end
function FieldGetInfoTask:start(immediate)
    if self.area == nil and self.fieldId ~= nil then
        local field = g_fieldManager:getFieldById(self.fieldId)
        if field ~= nil then
            self.area = field:getDensityMapPolygon()
        end
    end
    if self.area == nil then
        self.state = DensityMapUpdateTaskState.FINISHED
        Logging.warning("Missing area for FieldGetInfoTask")
    else
        self.state = DensityMapUpdateTaskState.RUNNING
        self.area:applyToModifier(self.multiModifier)
        self.minY, self.maxY = self.multiModifier:getPolygonMinMaxZ()
        self.numPixelsPerGrowthStage = {}
        self.totalNumTouchedPixels = 0
        self.multiModifier:resetStats()
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
function FieldGetInfoTask:update(_)
    if self.state == DensityMapUpdateTaskState.RUNNING then
        if self.currentMinY ~= nil then
            self.multiModifier:setPolygonClipRegion(self.currentMinY, self.currentMaxY)
        end
        local _, _, _, numTouchedPixels = self.multiModifier:execute(nil, self.numPixelsPerGrowthStage)
        self.totalNumTouchedPixels = self.totalNumTouchedPixels + numTouchedPixels
        if self.minY == nil then
            self:onFinish()
        else
            self.currentMinY = self.currentMaxY
            self.currentMaxY = math.min(self.currentMinY + self.maxRegionPerFrame, self.maxY)
            if self.currentMinY == self.maxY then
                self:onFinish()
                return
            end
        end
    end
end
function FieldGetInfoTask:onFinish()
    self.state = DensityMapUpdateTaskState.FINISHED
    if self.callbackFunc ~= nil then
        if self.callbackTarget ~= nil then
            self.callbackFunc(self.callbackTarget, self.numPixelsPerGrowthStage, self.totalNumTouchedPixels, self.callbackArgs)
            return
        end
        self.callbackFunc(self.numPixelsPerGrowthStage, self.totalNumTouchedPixels, self.callbackArgs)
    end
end
function FieldGetInfoTask:getIsFinished()
    return self.state == DensityMapUpdateTaskState.FINISHED
end