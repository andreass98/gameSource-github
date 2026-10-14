PrecisionFarmingDensityMapUpdater = {}
PrecisionFarmingDensityMapUpdater.MOD_NAME = g_currentModName
local PrecisionFarmingDensityMapUpdater_mt = Class(PrecisionFarmingDensityMapUpdater)
function PrecisionFarmingDensityMapUpdater.new(precisionFarming, customMt)
    -- upvalues: (copy) PrecisionFarmingDensityMapUpdater_mt
    local self = setmetatable({}, customMt or PrecisionFarmingDensityMapUpdater_mt)
    self.precisionFarming = precisionFarming
    self.pendingUpdateTasks = {}
    self.activeUpdateTask = nil
    return self
end
function PrecisionFarmingDensityMapUpdater:addUpdateTask(updateTask, immediate)
    if immediate then
        updateTask:start()
        while not updateTask:getIsFinished() do
            updateTask:update(9999)
        end
    else
        table.insert(self.pendingUpdateTasks, updateTask)
    end
end
function PrecisionFarmingDensityMapUpdater:update(dt)
    if self.activeUpdateTask == nil and #self.pendingUpdateTasks > 0 then
        self.activeUpdateTask = table.remove(self.pendingUpdateTasks, 1)
        if not self.activeUpdateTask:start() then
            self.activeUpdateTask = nil
        end
    end
    if self.activeUpdateTask ~= nil then
        self.activeUpdateTask:update(dt)
        if self.activeUpdateTask:getIsFinished() then
            self.activeUpdateTask = nil
        end
    end
end
local function getClassObject(className)
    local parts = string.split(className, ".")
    local currentTable = _G[parts[1]]
    if type(currentTable) ~= "table" then
        return nil
    end
    local i = 2
    for i = i, #parts do
        currentTable = currentTable[parts[i]]
        if type(currentTable) ~= "table" then
            return nil
        end
    end
    return currentTable
end
local function getClassName(classObject)
    for k, v in pairs(_G) do
        if v == classObject then
            return k
        end
    end
end
local function getClassNameByObject(object)
    -- upvalues: (copy) getClassName
    if object == nil or object.class == nil then
        return nil
    else
        return getClassName((object:class()))
    end
end
function PrecisionFarmingDensityMapUpdater:loadFromItemsXML(xmlFile, key)
    -- upvalues: (copy) getClassObject
    xmlFile:iterate((key .. ".densityMapUpdater") .. ".updateTask", function(_, baseKey)
        -- upvalues: (copy) xmlFile, (ref) getClassObject, (copy) self
        local className = xmlFile:getString(baseKey .. "#className")
        if className ~= nil then
            local class = getClassObject(className)
            if class ~= nil then
                local updateTask = class.new()
                if updateTask:loadFromXMLFile(xmlFile, baseKey) then
                    self:addUpdateTask(updateTask)
                end
            end
        end
    end)
end
function PrecisionFarmingDensityMapUpdater:saveToXMLFile(xmlFile, key, _)
    -- upvalues: (copy) getClassNameByObject
    key = key .. ".densityMapUpdater"
    local i = 0
    if self.activeUpdateTask ~= nil then
        local baseKey = string.format("%s.updateTask(0)", key)
        xmlFile:setString(baseKey .. "#className", getClassNameByObject(self.activeUpdateTask))
        self.activeUpdateTask:saveToXMLFile(xmlFile, baseKey)
        i = 1
    end
    for _, updateTask in pairs(self.pendingUpdateTasks) do
        local baseKey = string.format("%s.updateTask(%d)", key, i)
        xmlFile:setString(baseKey .. "#className", getClassNameByObject(updateTask))
        updateTask:saveToXMLFile(xmlFile, baseKey)
        i = i + 1
    end
end
function PrecisionFarmingDensityMapUpdater:overwriteGameFunctions(pfModule) end