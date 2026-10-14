MapManager = {}
local MapManager_mt = Class(MapManager, AbstractManager)
function MapManager.new(customMt)
    -- upvalues: (copy) MapManager_mt
    return AbstractManager.new(customMt or MapManager_mt)
end
function MapManager:initDataStructures()
    self.maps = {}
    self.idToMap = {}
end
function MapManager:addMapItem(id, scriptFilename, className, configFile, defaultVehiclesXMLFilename, defaultHandToolsXMLFilename, defaultPlaceablesXMLFilename, defaultItemsXMLFilename, title, description, iconFilename, baseDirectory, customEnvironment, isMultiplayerSupported, isModMap, prohibitOtherMods, isSelectable)
    if self.idToMap[id] ~= nil then
        Logging.warning("Duplicate map id \'%s\'. Ignoring this map definition.", id)
        return false
    end
    local item = {
        ["id"] = tostring(id),
        ["scriptFilename"] = scriptFilename,
        ["mapXMLFilename"] = configFile,
        ["className"] = className,
        ["defaultVehiclesXMLFilename"] = defaultVehiclesXMLFilename,
        ["defaultHandToolsXMLFilename"] = defaultHandToolsXMLFilename,
        ["defaultPlaceablesXMLFilename"] = defaultPlaceablesXMLFilename,
        ["defaultItemsXMLFilename"] = defaultItemsXMLFilename,
        ["title"] = title,
        ["description"] = description,
        ["iconFilename"] = iconFilename,
        ["baseDirectory"] = baseDirectory,
        ["customEnvironment"] = customEnvironment,
        ["isMultiplayerSupported"] = isMultiplayerSupported,
        ["isModMap"] = isModMap,
        ["prohibitOtherMods"] = prohibitOtherMods,
        ["isSelectable"] = isSelectable
    }
    table.insert(self.maps, item)
    self.idToMap[id] = item
    return true
end
function MapManager:loadMapFromXML(xmlFile, baseName, modDir, modName, isMultiplayerSupported, isDLCFile, isModMap, isInternalMod)
    local mapId = xmlFile:getString(baseName .. "#id", "")
    if mapId == "" then
        Logging.error("Failed to load map \'%s\'. Missing attribute \'%s#id\'.", modName or "Basemap", baseName)
        return false
    end
    local name
    if modName == nil then
        name = nil
    else
        name = modName
    end
    local defaultVehiclesXMLFilename = xmlFile:getString(baseName .. "#defaultVehiclesXMLFilename", "")
    local defaultHandToolsXMLFilename = xmlFile:getString(baseName .. "#defaultHandToolsXMLFilename", "")
    local defaultPlaceablesXMLFilename = xmlFile:getString(baseName .. "#defaultPlaceablesXMLFilename", "")
    local defaultItemsXMLFilename = xmlFile:getString(baseName .. "#defaultItemsXMLFilename", "")
    local mapTitle = xmlFile:getI18NValue(baseName .. ".title", "", name, true)
    local mapDesc = xmlFile:getI18NValue(baseName .. ".description", "", name, true)
    local mapClassName = xmlFile:getString(baseName .. "#className", "Mission00")
    local mapFilename = xmlFile:getString(baseName .. "#filename", "$dataS/scripts/mission00.lua")
    local configFilename = xmlFile:getString(baseName .. "#configFilename", "")
    local mapIconFilename = xmlFile:getI18NValue(baseName .. ".iconFilename", "", name, true)
    local mapName
    if modName == nil then
        mapName = mapId
    else
        mapName = mapId .. " " .. mapId
    end
    if mapClassName:find("[^%w_]") ~= nil then
        Logging.error("Failed to load map \'%s\'. Invalid map class name: \'%s\'. No whitespaces allowed.", mapName, mapClassName)
        return false
    end
    if mapClassName == "" then
        Logging.error("Failed to load map \'%s\'. Missing attribute \'%s#className\'.", mapName, baseName)
        return false
    end
    if mapTitle == "" then
        Logging.error("Failed to load map \'%s\'. Missing element \'%s.title\'.", mapName, baseName)
        return false
    end
    if mapFilename == "" then
        Logging.error("Failed to load map \'%s\'. Missing attribute \'%s#filename\'.", mapName, baseName)
        return false
    end
    if defaultVehiclesXMLFilename == "" then
        Logging.error("Failed to load map \'%s\'. Missing attribute \'%s#defaultVehiclesXMLFilename\'.", mapName, baseName)
        return false
    end
    if defaultHandToolsXMLFilename == "" then
        Logging.error("Failed to load map \'%s\'. Missing attribute \'%s#defaultHandToolsXMLFilename\'.", mapName, baseName)
        return false
    end
    if defaultPlaceablesXMLFilename == "" then
        Logging.error("Failed to load map \'%s\'. Missing attribute \'%s#defaultPlaceablesXMLFilename\'.", mapName, baseName)
        return false
    end
    if defaultItemsXMLFilename == "" then
        Logging.error("Failed to load map \'%s\'. Missing attribute \'%s#defaultItemsXMLFilename\'.", mapName, baseName)
        return false
    end
    if mapIconFilename == "" then
        Logging.error("Failed to load map \'%s\'. Missing element \'%s.iconFilename\'.", mapName, baseName)
        return false
    end
    local prohibitOtherMods, isSelectable = Utils.getFilename(mapFilename, modDir)
    if isSelectable then
    end
    local prohibitOtherMods = nil
    if isDLCFile or isInternalMod then
        prohibitOtherMods = xmlFile:getBool(baseName .. ".prohibitOtherMods", nil) or nil
    end
    local isSelectable = true
    if isDLCFile or isInternalMod then
        isSelectable = xmlFile:getBool(baseName .. ".isSelectable", isSelectable)
    end
    local fullConfigFilename = Utils.getFilename(configFilename, modDir)
    local customEnvironment, _ = Utils.getModNameAndBaseDirectory(fullConfigFilename)
    if modName ~= nil then
    end
    local mapIconFilename = Utils.getFilename(mapIconFilename, modDir)
    local defaultVehiclesXMLFilename = Utils.getFilename(defaultVehiclesXMLFilename, modDir)
    local defaultHandToolsXMLFilename = Utils.getFilename(defaultHandToolsXMLFilename, modDir)
    local defaultPlaceablesXMLFilename = Utils.getFilename(defaultPlaceablesXMLFilename, modDir)
    local defaultItemsXMLFilename = Utils.getFilename(defaultItemsXMLFilename, modDir)
    if not GS_IS_CONSOLE_VERSION or (isDLCFile or (not isSelectable or isInternalMod)) then
        return self:addMapItem(mapId, prohibitOtherMods, mapClassName, configFilename, defaultVehiclesXMLFilename, defaultHandToolsXMLFilename, defaultPlaceablesXMLFilename, defaultItemsXMLFilename, mapTitle, mapDesc, mapIconFilename, modDir, customEnvironment, isMultiplayerSupported, isModMap, prohibitOtherMods, isSelectable)
    end
    Logging.error("Can\'t register map \'%s\' with scripts on consoles.", mapId)
    return false
end
function MapManager.getModNameFromMapId(_, mapId)
    local parts = string.split(mapId, ".")
    if #parts > 1 then
        return parts[1]
    else
        return nil
    end
end
function MapManager:getMapById(id)
    return self.idToMap[id]
end
function MapManager:removeMapItem(index)
    local item = self.maps[index]
    if item ~= nil then
        self.idToMap[item.id] = nil
        table.remove(self.maps, index)
    end
end
function MapManager:getNumOfMaps()
    return #self.maps
end
function MapManager:getMapDataByIndex(index)
    return self.maps[index]
end
function MapManager:getMapByConfigFilename(xmlFilename)
    for _, map in ipairs(self.maps) do
        if map.mapXMLFilename == xmlFilename then
            return map
        end
    end
    return nil
end
g_mapManager = MapManager.new()