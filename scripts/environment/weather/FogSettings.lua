FogSettings = {}
local FogSettings_mt = Class(FogSettings)
function FogSettings.new(customMt)
    -- upvalues: (copy) FogSettings_mt
    local self = setmetatable({}, customMt or FogSettings_mt)
    self.groundFogCoverageEdge0 = 0.15
    self.groundFogCoverageEdge1 = 1
    self.groundFogExtraHeight = 7
    self.groundFogGroundLevelDensity = 0.05
    self.groundFogMinValleyDepth = 1.5
    self.groundFogStartDayTimeMinutes = 240
    self.groundFogEndDayTimeMinutes = 600
    self.groundFogWeatherTypes = {}
    self.heightFogMaxHeight = 550
    self.heightFogGroundLevelDensity = 0.6
    self.template = nil
    return self
end
function FogSettings:clone()
    local ret = self.new()
    ret.groundFogCoverageEdge0 = self.groundFogCoverageEdge0
    ret.groundFogCoverageEdge1 = self.groundFogCoverageEdge1
    ret.groundFogExtraHeight = self.groundFogExtraHeight
    ret.groundFogGroundLevelDensity = self.groundFogGroundLevelDensity
    ret.groundFogMinValleyDepth = self.groundFogMinValleyDepth
    ret.groundFogStartDayTimeMinutes = self.groundFogStartDayTimeMinutes
    ret.groundFogEndDayTimeMinutes = self.groundFogEndDayTimeMinutes
    ret.groundFogWeatherTypes = table.clone(self.groundFogWeatherTypes)
    ret.heightFogMaxHeight = self.heightFogMaxHeight
    ret.heightFogGroundLevelDensity = self.heightFogGroundLevelDensity
    return ret
end
function FogSettings:loadTemplate(xmlFile, key)
    local template = {
        ["groundFogCoverageEdge0"] = {}
    }
    template.groundFogCoverageEdge0.min = xmlFile:getFloat(key .. ".groundFog.coverageEdge0#min", 0.15)
    template.groundFogCoverageEdge0.max = xmlFile:getFloat(key .. ".groundFog.coverageEdge0#max", 0.15)
    template.groundFogCoverageEdge1 = {}
    template.groundFogCoverageEdge1.min = xmlFile:getFloat(key .. ".groundFog.coverageEdge1#min", 1)
    template.groundFogCoverageEdge1.max = xmlFile:getFloat(key .. ".groundFog.coverageEdge1#max", 1)
    template.groundFogExtraHeight = {}
    template.groundFogExtraHeight.min = xmlFile:getFloat(key .. ".groundFog.extraHeight#min", 20)
    template.groundFogExtraHeight.max = xmlFile:getFloat(key .. ".groundFog.extraHeight#max", 20)
    template.groundFogGroundLevelDensity = {}
    template.groundFogGroundLevelDensity.min = xmlFile:getFloat(key .. ".groundFog.groundLevelDensity#min", 0.1)
    template.groundFogGroundLevelDensity.max = xmlFile:getFloat(key .. ".groundFog.groundLevelDensity#max", 0.1)
    template.groundFogMinValleyDepth = {}
    template.groundFogMinValleyDepth.min = xmlFile:getFloat(key .. ".groundFog.minValleyDepth#min", 1.5)
    template.groundFogMinValleyDepth.max = xmlFile:getFloat(key .. ".groundFog.minValleyDepth#max", 1.5)
    template.groundFogStartDayTimeMinutes = {}
    template.groundFogStartDayTimeMinutes.min = xmlFile:getInt(key .. ".groundFog.startDayTimeMinutes#min", 300)
    template.groundFogStartDayTimeMinutes.max = xmlFile:getInt(key .. ".groundFog.startDayTimeMinutes#max", 300)
    template.groundFogEndDayTimeMinutes = {}
    template.groundFogEndDayTimeMinutes.min = xmlFile:getInt(key .. ".groundFog.endDayTimeMinutes#min", 600)
    template.groundFogEndDayTimeMinutes.max = xmlFile:getInt(key .. ".groundFog.endDayTimeMinutes#max", 600)
    template.groundFogWeatherTypes = {}
    for _, weatherTypeKey in xmlFile:iterator(key .. ".groundFog.weatherTypes.weatherType") do
        local weatherTypeName = xmlFile:getString(weatherTypeKey .. "#name")
        local weatherType = WeatherType.getByName(weatherTypeName)
        if weatherType ~= nil then
            template.groundFogWeatherTypes[weatherType] = true
        end
    end
    template.heightFogMaxHeight = {}
    template.heightFogMaxHeight.min = xmlFile:getInt(key .. ".heightFog.maxHeight#min", 550)
    template.heightFogMaxHeight.max = xmlFile:getInt(key .. ".heightFog.maxHeight#max", 550)
    template.heightFogGroundLevelDensity = {}
    template.heightFogGroundLevelDensity.min = xmlFile:getFloat(key .. ".heightFog.groundLevelDensity#min", 0.6)
    template.heightFogGroundLevelDensity.max = xmlFile:getFloat(key .. ".heightFog.groundLevelDensity#max", 0.6)
    self.template = template
    return true
end
function FogSettings:createFromTemplate()
    local template = self.template
    if template == nil then
        return nil
    end
    local settings = FogSettings.new()
    settings.groundFogCoverageEdge0 = MathUtil.lerp(template.groundFogCoverageEdge0.min, template.groundFogCoverageEdge0.max, math.random())
    settings.groundFogCoverageEdge1 = MathUtil.lerp(template.groundFogCoverageEdge1.min, template.groundFogCoverageEdge1.max, math.random())
    settings.groundFogExtraHeight = MathUtil.lerp(template.groundFogExtraHeight.min, template.groundFogExtraHeight.max, math.random())
    settings.groundFogGroundLevelDensity = MathUtil.lerp(template.groundFogGroundLevelDensity.min, template.groundFogGroundLevelDensity.max, math.random())
    settings.groundFogMinValleyDepth = MathUtil.lerp(template.groundFogMinValleyDepth.min, template.groundFogMinValleyDepth.max, math.random())
    settings.groundFogStartDayTimeMinutes = math.floor((MathUtil.lerp(template.groundFogStartDayTimeMinutes.min, template.groundFogStartDayTimeMinutes.max, math.random())))
    settings.groundFogEndDayTimeMinutes = math.floor((MathUtil.lerp(template.groundFogEndDayTimeMinutes.min, template.groundFogEndDayTimeMinutes.max, math.random())))
    settings.groundFogWeatherTypes = table.clone(template.groundFogWeatherTypes)
    settings.heightFogMaxHeight = MathUtil.lerp(template.heightFogMaxHeight.min, template.heightFogMaxHeight.max, math.random())
    settings.heightFogGroundLevelDensity = MathUtil.lerp(template.heightFogGroundLevelDensity.min, template.heightFogGroundLevelDensity.max, math.random())
    return settings
end
function FogSettings:loadFromXMLFile(xmlFile, key)
    self.groundFogCoverageEdge0 = xmlFile:getFloat(key .. ".groundFog#coverageEdge0", self.groundFogCoverageEdge0)
    self.groundFogCoverageEdge1 = xmlFile:getFloat(key .. ".groundFog#coverageEdge1", self.groundFogCoverageEdge1)
    self.groundFogExtraHeight = xmlFile:getFloat(key .. ".groundFog#extraHeight", self.groundFogExtraHeight)
    self.groundFogGroundLevelDensity = xmlFile:getFloat(key .. ".groundFog#groundLevelDensity", self.groundFogGroundLevelDensity)
    self.groundFogMinValleyDepth = xmlFile:getFloat(key .. ".groundFog#minValleyDepth", self.groundFogMinValleyDepth)
    self.groundFogStartDayTimeMinutes = xmlFile:getInt(key .. ".groundFog#startDayTimeMinutes", self.groundFogStartDayTimeMinutes)
    self.groundFogEndDayTimeMinutes = xmlFile:getInt(key .. ".groundFog#endDayTimeMinutes", self.groundFogEndDayTimeMinutes)
    local weatherTypeNames = xmlFile:getString(key .. ".groundFog#weatherTypes")
    if weatherTypeNames ~= nil then
        local weatherTypes = string.split(weatherTypeNames, " ")
        for _, weatherTypeName in ipairs(weatherTypes) do
            local weatherType = WeatherType.getByName(weatherTypeName)
            if weatherType ~= nil then
                self.groundFogWeatherTypes[weatherType] = true
            end
        end
    end
    self.heightFogMaxHeight = xmlFile:getFloat(key .. ".heightFog#maxHeight", self.heightFogMaxHeight)
    self.heightFogGroundLevelDensity = xmlFile:getFloat(key .. ".heightFog#groundLevelDensity", self.heightFogGroundLevelDensity)
    self:validate(xmlFile, key)
end
function FogSettings:saveToXMLFile(xmlFile, key)
    xmlFile:setFloat(key .. ".groundFog#coverageEdge0", self.groundFogCoverageEdge0)
    xmlFile:setFloat(key .. ".groundFog#coverageEdge1", self.groundFogCoverageEdge1)
    xmlFile:setFloat(key .. ".groundFog#extraHeight", self.groundFogExtraHeight)
    xmlFile:setFloat(key .. ".groundFog#groundLevelDensity", self.groundFogGroundLevelDensity)
    xmlFile:setFloat(key .. ".groundFog#minValleyDepth", self.groundFogMinValleyDepth)
    xmlFile:setInt(key .. ".groundFog#startDayTimeMinutes", self.groundFogStartDayTimeMinutes)
    xmlFile:setInt(key .. ".groundFog#endDayTimeMinutes", self.groundFogEndDayTimeMinutes)
    local weatherTypes = nil
    for weatherType, _ in pairs(self.groundFogWeatherTypes) do
        if weatherTypes == nil then
            weatherTypes = WeatherType.getName(weatherType)
        else
            weatherTypes = weatherTypes .. " " .. WeatherType.getName(weatherType)
        end
    end
    if weatherTypes ~= nil then
        xmlFile:setString(key .. ".groundFog#weatherTypes", weatherTypes)
    end
    xmlFile:setFloat(key .. ".heightFog#maxHeight", self.heightFogMaxHeight)
    xmlFile:setFloat(key .. ".heightFog#groundLevelDensity", self.heightFogGroundLevelDensity)
end
function FogSettings:disableGroundFog()
    self.groundFogGroundLevelDensity = 0
end
function FogSettings:validate(xmlFile, key)
    if MathUtil.getIsOutOfBounds(self.groundFogCoverageEdge0, 0, 1) then
        Logging.xmlWarning(xmlFile, "GroundFog coverageEdge0 \'%.3f\' is out of bounds [0, 1] for \'%s\'", self.groundFogCoverageEdge0, key)
        self.groundFogCoverageEdge0 = math.clamp(self.groundFogCoverageEdge0, 0, 1)
    end
    if MathUtil.getIsOutOfBounds(self.groundFogCoverageEdge1, 0, 1) then
        Logging.xmlWarning(xmlFile, "GroundFog coverageEdge1 \'%.3f\' is out of bounds [0, 1] for \'%s\'", self.groundFogCoverageEdge1, key)
        self.groundFogCoverageEdge1 = math.clamp(self.groundFogCoverageEdge1, 0, 1)
    end
    if self.groundFogCoverageEdge0 > self.groundFogCoverageEdge1 then
        self.groundFogCoverageEdge0 = self.groundFogCoverageEdge1
        self.groundFogCoverageEdge1 = self.groundFogCoverageEdge0
    end
    if MathUtil.getIsOutOfBounds(self.groundFogExtraHeight, 0, 50) then
        Logging.xmlWarning(xmlFile, "GroundFog extraHeight \'%.3f\' is out of bounds [0, 50] for \'%s\'", self.groundFogExtraHeight, key)
        self.groundFogExtraHeight = math.clamp(self.groundFogExtraHeight, 0, 50)
    end
    if MathUtil.getIsOutOfBounds(self.groundFogGroundLevelDensity, 0, 1) then
        Logging.xmlWarning(xmlFile, "GroundFog groundLevelDensity \'%.3f\' is out of bounds [0, 1] for \'%s\'", self.groundFogGroundLevelDensity, key)
        self.groundFogGroundLevelDensity = math.clamp(self.groundFogGroundLevelDensity, 0, 1)
    end
    if MathUtil.getIsOutOfBounds(self.groundFogMinValleyDepth, 0.5, 20) then
        Logging.xmlWarning(xmlFile, "GroundFog minValleyDepth \'%.3f\' is out of bounds [0.5, 20] for \'%s\'", self.groundFogMinValleyDepth, key)
        self.groundFogMinValleyDepth = math.clamp(self.groundFogMinValleyDepth, 0.5, 20)
    end
    if MathUtil.getIsOutOfBounds(self.heightFogMaxHeight, 0, 1500) then
        Logging.xmlWarning(xmlFile, "HeightFog maxHeight \'%.3f\' is out of bounds [0, 1500] for \'%s\'", self.heightFogMaxHeight, key)
        self.heightFogMaxHeight = math.clamp(self.heightFogMaxHeight, 0, 1500)
    end
    if MathUtil.getIsOutOfBounds(self.heightFogGroundLevelDensity, 0, 1) then
        Logging.xmlWarning(xmlFile, "HeightFog groundLevelDensity \'%.3f\' is out of bounds [0, 1] for \'%s\'", self.heightFogGroundLevelDensity, key)
        self.heightFogGroundLevelDensity = math.clamp(self.heightFogGroundLevelDensity, 0, 1)
    end
end