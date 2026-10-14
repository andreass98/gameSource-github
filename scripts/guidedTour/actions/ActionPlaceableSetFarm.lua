ActionPlaceableSetFarm = {}
ActionPlaceableSetFarm.NAME = "placeableSetFarm"
local ActionPlaceableSetFarm_mt = Class(ActionPlaceableSetFarm)
function ActionPlaceableSetFarm.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#placeable", "Name of the placeable", nil, true)
    schema:register(XMLValueType.STRING, basePath .. "#farmId", "The owner farm id of the placeable", nil, true)
end
function ActionPlaceableSetFarm.new(placeableName, farmId, customMt)
    -- upvalues: (copy) ActionPlaceableSetFarm_mt
    local self = setmetatable({}, customMt or ActionPlaceableSetFarm_mt)
    self.placeableName = placeableName
    self.farmId = farmId
    return self
end
function ActionPlaceableSetFarm:run(_, _)
    local placeable = g_guidedTourManager:getPlaceableByName(self.placeableName)
    if placeable == nil then
        Logging.warning("ActionPlaceableSetFarm.run: Placeable \'%s\' not found", self.placeableName)
        return true
    else
        placeable:setOwnerFarmId(self.farmId, false)
        return true
    end
end
function ActionPlaceableSetFarm.createFromXML(xmlFile, key, _, _)
    local placeableName = xmlFile:getValue(key .. "#placeable")
    local farmIdStr = xmlFile:getValue(key .. "#farmId")
    local farmIdStrLower = string.lower(farmIdStr)
    local farmId
    if farmIdStrLower == "spectator" then
        farmId = FarmManager.SPECTATOR_FARM_ID
    elseif farmIdStrLower == "tour" then
        farmId = FarmManager.GUIDED_TOUR_FARM_ID
    elseif farmIdStrLower == "nobody" then
        farmId = AccessHandler.NOBODY
    elseif farmIdStrLower == "default" then
        farmId = FarmManager.SINGLEPLAYER_FARM_ID
    else
        farmId = tonumber(farmIdStr)
    end
    if placeableName == nil or farmId == nil then
        return nil
    else
        return ActionPlaceableSetFarm.new(placeableName, farmId)
    end
end
g_guidedTourManager:registerActionClass(ActionPlaceableSetFarm.NAME, ActionPlaceableSetFarm)