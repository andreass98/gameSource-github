ProgressFieldGround = {}
ProgressFieldGround.NAME = "fieldGround"
local ProgressFieldGround_mt = Class(ProgressFieldGround, Progress)
function ProgressFieldGround.registerXMLPaths(schema, basePath)
    ProgressFieldGround:superClass().registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#fieldId", "Id of the field", nil, true)
    schema:register(XMLValueType.STRING, basePath .. "#groundType", "Name of the ground type", "CULTIVATED", false)
    DensityMapCircle.registerXMLPaths(schema, basePath .. ".area")
    DensityMapParallelogram.registerXMLPaths(schema, basePath .. ".area")
    DensityMapPolygon.registerXMLPaths(schema, basePath .. ".area")
end
function ProgressFieldGround.new(title, description, fieldId, area, groundTypeName, customMt)
    -- upvalues: (copy) ProgressFieldGround_mt
    local self = Progress.new(title, description, customMt or ProgressFieldGround_mt)
    self.fieldId = fieldId
    self.area = area
    self.groundTypeName = groundTypeName
    self.maxRegionPerFrame = 30
    return self
end
function ProgressFieldGround:update(dt)
    ProgressFieldGround:superClass().update(self, dt)
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
function ProgressFieldGround:activate(tour, step)
    local field = g_fieldManager:getFieldById(self.fieldId)
    if field == nil then
        Logging.warning("ProgressFieldGround.activate: No field given")
        return
    else
        local fieldGroundValue = FieldGroundType.getValueByName(self.groundTypeName)
        if fieldGroundValue == nil then
            Logging.warning("ProgressFieldGround.activate: Field ground type \'%s\' not defined!", self.groundTypeName)
            return
        else
            local densityMapId, firstChannel, numChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
            local modifier = DensityMapModifier.new(densityMapId, firstChannel, numChannels, g_terrainNode)
            local area = self.area
            if area == nil then
                area = field:getDensityMapPolygon()
            end
            if area == nil then
                Logging.warning("ProgressFieldGround.activate: No area given")
            else
                ProgressFieldGround:superClass().activate(self, tour, step)
                self.filter = DensityMapFilter.new(modifier)
                self.filter:setValueCompareParams(DensityValueCompareType.EQUAL, fieldGroundValue)
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
function ProgressFieldGround:deactivate()
    self.filter = nil
    self.densityMapModifier = nil
    ProgressFieldGround:superClass().deactivate(self)
end
function ProgressFieldGround:getProgress()
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
function ProgressFieldGround.createFromXML(xmlFile, key, _, customEnvironment)
    local fieldId = xmlFile:getValue(key .. "#fieldId")
    if fieldId == nil then
        Logging.xmlWarning(xmlFile, "Missing \'fieldId\' for \'%s\'", key)
        return nil
    end
    local title = xmlFile:getValue(key .. "#title", nil, customEnvironment, false)
    local description = xmlFile:getValue(key .. "#description", nil, customEnvironment, false)
    local groundTypeName = xmlFile:getValue(key .. "#groundType", "CULTIVATED")
    local area = DensityMapParallelogram.createFromXMLFile(xmlFile, key .. ".area")
    if area == nil then
        area = DensityMapCircle.createFromXMLFile(xmlFile, key .. ".area")
    end
    if area == nil then
        area = DensityMapPolygon.createFromXMLFile(xmlFile, key .. ".area")
    end
    return ProgressFieldGround.new(title, description, fieldId, area, groundTypeName)
end
g_guidedTourManager:registerProgressClass(ProgressFieldGround.NAME, ProgressFieldGround)