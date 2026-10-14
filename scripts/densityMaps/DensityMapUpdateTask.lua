DensityMapUpdateTask = {}
local DensityMapUpdateTask_mt = Class(DensityMapUpdateTask)
function DensityMapUpdateTask.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#customName", "Custom name of the task", nil, false)
    schema:register(XMLValueType.STRING, basePath .. "#status", "Status of the task", nil, false)
    schema:register(XMLValueType.FLOAT, basePath .. ".area#currentMinY", "Current polygon minY clip region", nil, false)
    schema:register(XMLValueType.FLOAT, basePath .. ".area#currentMaxY", "Current polygon minY clip region", nil, false)
    DensityMapCircle.registerXMLPaths(schema, basePath .. ".area")
    DensityMapParallelogram.registerXMLPaths(schema, basePath .. ".area")
    DensityMapPolygon.registerXMLPaths(schema, basePath .. ".area")
end
function DensityMapUpdateTask.new(customMt)
    -- upvalues: (copy) DensityMapUpdateTask_mt
    local self = setmetatable({}, customMt or DensityMapUpdateTask_mt)
    self.customName = nil
    self.area = nil
    self.state = DensityMapUpdateTaskState.CREATED
    self.minY = nil
    self.maxY = nil
    self.currentMinY = nil
    self.currentMaxY = nil
    self.needsSaving = nil
    self.maxRegionPerFrame = 30
    return self
end
function DensityMapUpdateTask:saveToXMLFile(xmlFile, key)
    if self.customName ~= nil then
        xmlFile:setValue(key .. "#customName", self.customName)
    end
    xmlFile:setValue(key .. "#status", DensityMapUpdateTaskState.getName(self.state))
    if self.state == DensityMapUpdateTaskState.RUNNING then
        xmlFile:setValue(key .. ".area#currentMinY", self.currentMinY)
        xmlFile:setValue(key .. ".area#currentMaxY", self.currentMaxY)
    end
    if self.area ~= nil then
        self.area:saveToXMLFile(xmlFile, key .. ".area")
    end
end
function DensityMapUpdateTask:loadFromXMLFile(xmlFile, key)
    self.customName = xmlFile:getValue(key .. "#customName") or self.customName
    self.state = DensityMapUpdateTaskState.getByName(xmlFile:getValue(key .. "#status")) or DensityMapUpdateTaskState.CREATED
    if self.state == DensityMapUpdateTaskState.RUNNING then
        self.currentMinY = xmlFile:getValue(key .. ".area#currentMinY")
        self.currentMaxY = xmlFile:getValue(key .. ".area#currentMaxY")
    end
    if self.area == nil then
        local area = DensityMapParallelogram.createFromXMLFile(xmlFile, key .. ".area")
        if area == nil then
            area = DensityMapPolygon.createFromXMLFile(xmlFile, key .. ".area")
            if area == nil then
                area = DensityMapCircle.createFromXMLFile(xmlFile, key .. ".area")
            end
        end
        self.area = area
    end
    return true
end
function DensityMapUpdateTask:setArea(area)
    self.area = area
end
function DensityMapUpdateTask:getName()
    return self.customName or tostring(self)
end
function DensityMapUpdateTask:setName(name)
    self.customName = name
end
function DensityMapUpdateTask:cancel()
    if self.state == DensityMapUpdateTaskState.RUNNING then
        self.state = DensityMapUpdateTaskState.FINISHED
        local taskName = self:getName()
        Logging.devInfo("Canceled DensityMapUpdateTask for %s", taskName)
    end
end
function DensityMapUpdateTask:getIsFinished()
    return self.state == DensityMapUpdateTaskState.FINISHED
end
function DensityMapUpdateTask:setFinished()
    local taskName = self:getName()
    Logging.devInfo("Finished DensityMapUpdateTask for %s", taskName)
    self.state = DensityMapUpdateTaskState.FINISHED
end
function DensityMapUpdateTask:setNeedsSaving(needsSaving)
    self.needsSaving = needsSaving
end