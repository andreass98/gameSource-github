OnCreateObjectSystem = {}
local OnCreateObjectSystem_mt = Class(OnCreateObjectSystem)
g_xmlManager:addCreateSchemaFunction(function()
    OnCreateObjectSystem.xmlSchemaSavegame = XMLSchema.new("onCreateObjects")
end)
g_xmlManager:addInitSchemaFunction(function()
    OnCreateObjectSystem.xmlSchemaSavegame:register(XMLValueType.STRING, "onCreateLoadedObjects.object(?)#saveId", "SaveID of the object")
end)
function OnCreateObjectSystem.new(mission, customMt)
    -- upvalues: (copy) OnCreateObjectSystem_mt
    local self = setmetatable({}, customMt or OnCreateObjectSystem_mt)
    self.mission = mission
    self.objects = {}
    self.objectsToSave = {}
    return self
end
function OnCreateObjectSystem:delete() end
function OnCreateObjectSystem:save(xmlFilename, usedModNames)
    local xmlFile = XMLFile.create("onCreateObjectsXMLFile", xmlFilename, "onCreateLoadedObjects", OnCreateObjectSystem.xmlSchemaSavegame)
    xmlFile:setTable("onCreateLoadedObjects.object", self.objectsToSave, function(key, object, saveId)
        -- upvalues: (copy) xmlFile, (copy) usedModNames
        xmlFile:setValue(key .. "#saveId", saveId)
        object:saveToXMLFile(xmlFile, key, usedModNames)
    end)
    xmlFile:save()
    xmlFile:delete()
end
function OnCreateObjectSystem:load(xmlFilename)
    local xmlFile = XMLFile.load("onCreateLoadedObjectsXML", xmlFilename, OnCreateObjectSystem.xmlSchemaSavegame)
    for i, key in xmlFile:iterator("onCreateLoadedObjects.object") do
        local saveId = xmlFile:getValue(key .. "#saveId")
        if saveId ~= nil then
            local object = self.objectsToSave[saveId]
            if object == nil then
                Logging.error("Corrupt savegame, onCreateLoadedObject %d has invalid saveId \'%s\'", i, saveId)
            elseif object.loadFromXMLFile == nil or not object:loadFromXMLFile(xmlFile, key) then
                Logging.warning("Corrupt savegame, onCreateLoadedObject %d with saveId %s could not be loaded", i, saveId)
            end
        end
    end
    xmlFile:delete()
end
function OnCreateObjectSystem:add(object, saved)
    if self.mission.isLoaded then
        Logging.error("OnCreateObjectSystem:add(): only allowed to add objects while loading maps")
        printCallstack()
        return
    elseif self.mission.userManager:getNumberOfUsers() > 1 then
        Logging.error("OnCreateObjectSystem:add() is only allowed during map loading when no client is connected")
        printCallstack()
    else
        if saved then
            if object.saveToXMLFile == nil then
                Logging.error("Adding onCreate loaded object so save which does not have a saveToXMLFile function")
                return
            end
            if object.saveId == nil then
                Logging.error("Adding onCreate loaded object with invalid saveId")
                return
            end
            local prevObject = self.objectsToSave[object.saveId]
            if prevObject == object then
                return
            end
            if prevObject ~= nil then
                Logging.error("Adding onCreate loaded object with duplicate saveId %s", object.saveId)
                return
            end
            self.objectsToSave[object.saveId] = object
        end
        table.insert(self.objects, object)
    end
end
function OnCreateObjectSystem:remove(object)
    table.removeElement(self.objects, object)
    if object.saveId ~= nil and self.objectsToSave[object.saveId] == object then
        self.objectsToSave[object.saveId] = nil
    end
end
function OnCreateObjectSystem:getNumObjects()
    return #self.objects
end
function OnCreateObjectSystem:get(index)
    return self.objects[index]
end