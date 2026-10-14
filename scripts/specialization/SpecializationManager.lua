SpecializationManager = {}
local SpecializationManager_mt = Class(SpecializationManager, AbstractManager)
g_xmlManager:addEarlyCreateSchemaFunction(function()
    SpecializationManager.xmlSchema = XMLSchema.new("specializations")
    SpecializationManager.registerXMLPaths(SpecializationManager.xmlSchema, "specializations.specialization(?)")
end)
function SpecializationManager.registerXMLPaths(xmlSchema, baseKey)
    xmlSchema:register(XMLValueType.STRING, baseKey .. "#name", "The name of the specialization", nil, true)
    xmlSchema:register(XMLValueType.STRING, baseKey .. "#className", "The name of the specialization class", nil, true)
    xmlSchema:register(XMLValueType.STRING, baseKey .. "#filename", "The path of the specialization file", nil, true)
end
function SpecializationManager.new(typeName, xmlFilename, customMt)
    -- upvalues: (copy) SpecializationManager_mt
    local self = AbstractManager.new(customMt or SpecializationManager_mt)
    self.typeName = typeName
    self.xmlFilename = xmlFilename
    return self
end
function SpecializationManager:initDataStructures()
    self.specializations = {}
    self.sortedSpecializations = {}
end
function SpecializationManager:loadMapData()
    SpecializationManager:superClass().loadMapData(self)
    local xmlFile = XMLFile.loadIfExists("SpecializationsXML", self.xmlFilename, SpecializationManager.xmlSchema)
    if xmlFile == nil then
        Logging.error("Specializations XML for %q could not be loaded from %q!", self.typeName, self.xmlFilename)
        return false
    end
    for nodeIndex, nodeKey in xmlFile:iterator("specializations.specialization") do
        local typeName = xmlFile:getValue(nodeKey .. "#name")
        if string.isNilOrWhitespace(typeName) then
            Logging.xmlWarning(xmlFile, "Specialization node %q has missing name!", nodeKey)
        else
            local className = xmlFile:getValue(nodeKey .. "#className")
            if string.isNilOrWhitespace(className) then
                Logging.xmlWarning(xmlFile, "Specialization node %q has missing class name!", nodeKey)
            else
                local filename = xmlFile:getValue(nodeKey .. "#filename")
                if string.isNilOrWhitespace(filename) then
                    Logging.xmlWarning(xmlFile, "Specialization node %q has missing filename!", nodeKey)
                else
                    g_asyncTaskManager:addSubtask(function()
                        -- upvalues: (copy) self, (copy) typeName, (copy) className, (copy) filename
                        self:addSpecialization(typeName, className, filename, "")
                    end, string.format("SpecializationManager - Add Specialization \'%s\'", className))
                end
            end
        end
    end
    xmlFile:delete()
    g_asyncTaskManager:addSubtask(function()
        -- upvalues: (copy) self
        Logging.info("Loaded %q specializations", self.typeName)
    end)
    return true
end
function SpecializationManager:unloadMapData()
    local i = #self.sortedSpecializations
    for i = i, 1, -1 do
        local specialization = self:getSpecializationObjectByName(self.sortedSpecializations[i].name)
        if specialization ~= nil and specialization.terminateSpecialization ~= nil then
            specialization.terminateSpecialization()
        end
    end
    SpecializationManager:superClass().unloadMapData(self)
end
function SpecializationManager:addSpecialization(name, className, filename, customEnvironment)
    if self.specializations[name] ~= nil then
        Logging.error("Specialization \'%s\' already exists. Ignoring it!", (tostring(name)))
        return false
    end
    if className == nil then
        Logging.error("No className specified for specialization \'%s\'", (tostring(name)))
        return false
    end
    if filename == nil then
        Logging.error("No filename specified for specialization \'%s\'", (tostring(name)))
        return false
    end
    local specialization = {
        ["name"] = name,
        ["className"] = className,
        ["filename"] = filename
    }
    source(filename, customEnvironment)
    local specializationObject = ClassUtil.getClassObject(className)
    if specializationObject == nil then
        Logging.warning("Specialization %q could not resolve its class! Filepath: %q", name, className)
    else
        specializationObject.className = className
    end
    self.specializations[name] = specialization
    table.insert(self.sortedSpecializations, specialization)
    return true
end
function SpecializationManager:initSpecializations()
    local i = 1
    for i = i, #self.sortedSpecializations do
        local specialization = self:getSpecializationObjectByName(self.sortedSpecializations[i].name)
        if specialization ~= nil and specialization.initSpecialization ~= nil then
            g_asyncTaskManager:addSubtask(function()
                -- upvalues: (copy) specialization
                specialization.initSpecialization()
            end, string.format("SpecializationManager-initSpecializations - \'%s\'", self.sortedSpecializations[i].name))
        end
    end
end
function SpecializationManager:postInitSpecializations()
    local i = 1
    for i = i, #self.sortedSpecializations do
        local specialization = self:getSpecializationObjectByName(self.sortedSpecializations[i].name)
        if specialization ~= nil and specialization.postInitSpecialization ~= nil then
            g_asyncTaskManager:addSubtask(function()
                -- upvalues: (copy) specialization
                specialization.postInitSpecialization()
            end, string.format("SpecializationManager-postInitSpecializations - \'%s\'", self.sortedSpecializations[i].name))
        end
    end
end
function SpecializationManager:getSpecializationByName(name)
    if name == nil then
        return nil
    else
        return self.specializations[name]
    end
end
function SpecializationManager:getSpecializationObjectByName(name)
    local entry = self.specializations[name]
    if entry == nil then
        return nil
    else
        return ClassUtil.getClassObject(entry.className)
    end
end
function SpecializationManager:getSpecializations()
    return self.specializations
end
g_specializationManager = SpecializationManager.new("vehicle", "dataS/specializations.xml")
g_placeableSpecializationManager = SpecializationManager.new("placeable", "dataS/placeableSpecializations.xml")
g_handToolSpecializationManager = SpecializationManager.new("handTool", "dataS/handToolSpecializations.xml")