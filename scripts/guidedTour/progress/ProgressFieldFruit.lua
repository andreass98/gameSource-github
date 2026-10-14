ProgressFieldFruit = {}
ProgressFieldFruit.NAME = "fieldFruit"
local ProgressFieldFruit_mt = Class(ProgressFieldFruit, Progress)
function ProgressFieldFruit.registerXMLPaths(schema, basePath)
    ProgressFieldFruit:superClass().registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#fieldId", "Id of the field", nil, true)
    schema:register(XMLValueType.STRING, basePath .. "#fruitType", "Name of the fruit type", nil, true)
    schema:register(XMLValueType.STRING, basePath .. "#growthState", "Name of the growth state", nil, true)
    DensityMapCircle.registerXMLPaths(schema, basePath .. ".area")
    DensityMapParallelogram.registerXMLPaths(schema, basePath .. ".area")
    DensityMapPolygon.registerXMLPaths(schema, basePath .. ".area")
end
function ProgressFieldFruit.new(title, description, fieldId, area, fruitTypeName, growthStateName, customMt)
    -- upvalues: (copy) ProgressFieldFruit_mt
    local self = Progress.new(title, description, customMt or ProgressFieldFruit_mt)
    self.fieldId = fieldId
    self.area = area
    self.fruitTypeName = fruitTypeName
    self.growthStateName = growthStateName
    self.maxRegionPerFrame = 30
    return self
end
function ProgressFieldFruit:update(dt)
    ProgressFieldFruit:superClass().update(self, dt)
    local modifier = self.densityMapModifier
    if modifier ~= nil then
        modifier:setPolygonClipRegion(self.currentMinY, self.currentMaxY)
        local _, numPixels, totalNumPixels = modifier:executeGet(self.filter)
        if self.totalNumPixels == nil then
            self.tempTotalPixels = self.tempTotalPixels + totalNumPixels
        end
        self.tempProgressPixels = self.tempProgressPixels + numPixels
        self.currentMinY = self.currentMaxY
        self.currentMaxY = math.min(self.currentMinY + self.maxRegionPerFrame, self.maxY)
        if self.currentMinY == self.maxY then
            self.currentMinY = self.minY
            self.currentMaxY = math.max(self.minY + self.maxRegionPerFrame, self.maxY)
            if self.totalNumPixels == nil then
                self.totalNumPixels = self.tempTotalPixels
            end
            self.progressPixels = self.tempProgressPixels
            self.tempProgressPixels = 0
        end
    end
end
function ProgressFieldFruit:activate(tour, step)
    local field = g_fieldManager:getFieldById(self.fieldId)
    if field == nil then
        Logging.warning("GoalFieldFruitProgress.activate: No field given")
        return
    else
        local fruitType = g_fruitTypeManager:getFruitTypeByName(self.fruitTypeName)
        if fruitType == nil then
            Logging.warning("GoalFieldFruitProgress.activate: Fruit type \'%s\' not defined!", self.fruitTypeName)
            return
        else
            local growthState = fruitType:getGrowthStateByName(self.growthStateName)
            if growthState == nil then
                Logging.warning("GoalFieldFruitProgress.activate: Fruit type \'%s\' has no growth state \'%s\' defined!", self.fruitTypeName, self.growthStateName)
                return
            else
                local densityMapId, firstChannel, numChannels = fruitType:getDataPlaneInfo()
                if densityMapId == nil then
                    Logging.warning("GoalFieldFruitProgress.activate: Fruit type \'%s\' not available on current map!", self.fruitTypeName)
                    return
                else
                    local modifier = DensityMapModifier.new(densityMapId, firstChannel, numChannels, g_terrainNode)
                    local area = self.area
                    if area == nil then
                        area = field:getDensityMapPolygon()
                    end
                    if area == nil then
                        Logging.warning("GoalFieldFruitProgress.activate: No area given")
                    else
                        ProgressFieldFruit:superClass().activate(self, tour, step)
                        self.filter = DensityMapFilter.new(modifier)
                        self.filter:setValueCompareParams(DensityValueCompareType.EQUAL, growthState)
                        area:applyToModifier(modifier)
                        self.minY, self.maxY = modifier:getPolygonMinMaxZ()
                        self.currentMinY = self.minY
                        self.currentMaxY = math.max(self.minY + self.maxRegionPerFrame, self.maxY)
                        self.densityMapModifier = modifier
                        self.totalPixels = nil
                        self.tempTotalPixels = 0
                        self.progressPixels = 0
                        self.tempProgressPixels = 0
                    end
                end
            end
        end
    end
end
function ProgressFieldFruit:deactivate()
    self.filter = nil
    self.densityMapModifier = nil
    ProgressFieldFruit:superClass().deactivate(self)
end
function ProgressFieldFruit:getProgress()
    if self.densityMapModifier == nil then
        return nil
    elseif self.totalNumPixels == nil then
        return 0
    elseif self.totalNumPixels == 0 then
        return nil
    else
        return self.progressPixels / self.totalNumPixels
    end
end
function ProgressFieldFruit.createFromXML(xmlFile, key, _, customEnvironment)
    local fieldId = xmlFile:getValue(key .. "#fieldId")
    if fieldId == nil then
        Logging.xmlWarning(xmlFile, "Missing \'fieldId\' for \'%s\'", key)
        return nil
    end
    local title = xmlFile:getValue(key .. "#title", nil, customEnvironment, false)
    local description = xmlFile:getValue(key .. "#description", nil, customEnvironment, false)
    local fruitTypeName = xmlFile:getValue(key .. "#fruitType")
    local growthStateName = xmlFile:getValue(key .. "#growthState")
    local area = DensityMapParallelogram.createFromXMLFile(xmlFile, key .. ".area")
    if area == nil then
        area = DensityMapCircle.createFromXMLFile(xmlFile, key .. ".area")
    end
    if area == nil then
        area = DensityMapPolygon.createFromXMLFile(xmlFile, key .. ".area")
    end
    return ProgressFieldFruit.new(title, description, fieldId, area, fruitTypeName, growthStateName)
end
g_guidedTourManager:registerProgressClass(ProgressFieldFruit.NAME, ProgressFieldFruit)