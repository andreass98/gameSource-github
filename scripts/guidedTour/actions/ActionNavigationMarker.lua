ActionNavigationMarker = {}
ActionNavigationMarker.NAME = "navigationMarker"
ActionNavigationMarker.HOTSPOT = nil
local ActionNavigationMarker_mt = Class(ActionNavigationMarker)
function ActionNavigationMarker.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. "#isActive", "If the marker should be active", true, false)
    schema:register(XMLValueType.VECTOR_2, basePath .. "#worldPosition", "World position of the marker", nil, false)
    schema:register(XMLValueType.FLOAT, basePath .. "#terrainOffsetY", "Y terrain offset", 0, false)
end
function ActionNavigationMarker.new(isActive, worldPosX, worldPosZ, terrainOffsetY, customMt)
    -- upvalues: (copy) ActionNavigationMarker_mt
    local self = setmetatable({}, customMt or ActionNavigationMarker_mt)
    self.isActive = isActive
    self.worldPosX = worldPosX
    self.worldPosZ = worldPosZ
    self.terrainOffsetY = terrainOffsetY
    return self
end
function ActionNavigationMarker:run(_, _)
    if self.isActive then
        local worldPosY = getTerrainHeightAtWorldPos(g_terrainNode, self.worldPosX, 0, self.worldPosZ) + self.terrainOffsetY
        g_currentMission.navigationSystem:navigateTo(self.worldPosX, worldPosY, self.worldPosZ)
        local hotspot = ActionNavigationMarker.HOTSPOT
        if hotspot == nil then
            hotspot = TourHotspot.new()
            ActionNavigationMarker.HOTSPOT = hotspot
        end
        g_currentMission:addMapHotspot(hotspot)
        hotspot:setWorldPosition(self.worldPosX, self.worldPosZ)
    else
        g_currentMission.navigationSystem:stop()
        local hotspot = ActionNavigationMarker.HOTSPOT
        if hotspot ~= nil then
            g_currentMission:removeMapHotspot(hotspot)
            hotspot:delete()
        end
    end
    return true
end
function ActionNavigationMarker.createFromXML(xmlFile, key, _, _)
    local isActive = xmlFile:getValue(key .. "#isActive")
    if isActive == nil then
        return nil
    end
    local worldPosX, worldPosZ = xmlFile:getValue(key .. "#worldPosition")
    if isActive and (worldPosX == nil or worldPosZ == nil) then
        return nil
    end
    local terrainOffsetY = xmlFile:getValue(key .. "#terrainOffsetY", 0)
    return ActionNavigationMarker.new(isActive, worldPosX, worldPosZ, terrainOffsetY)
end
g_guidedTourManager:registerActionClass(ActionNavigationMarker.NAME, ActionNavigationMarker)