PlaceableNPCSpot = {}
function PlaceableNPCSpot.prerequisitesPresent(specializations)
    return true
end
function PlaceableNPCSpot.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableNPCSpot)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableNPCSpot)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableNPCSpot)
end
function PlaceableNPCSpot.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("NPCSpot")
    NPCSpot.registerXMLPaths(schema, basePath .. ".npcSpots.spot(?)")
    schema:setXMLSpecializationType()
end
function PlaceableNPCSpot:onLoad(_)
    local placeableUniqueId = self:getUniqueId()
    local spots = {}
    for index, key in self.xmlFile:iterator("placeable.npcSpots.spot") do
        local uniqueId = string.format("PlaceableNPCSpot_%s_%d", placeableUniqueId, index)
        local spot = NPCSpot.new()
        if spot:loadFromXMLFile(self.xmlFile, key, self.components, self.i3dMappings, uniqueId) then
            table.insert(spots, spot)
        else
            spot:delete()
        end
    end
    if #spots > 0 then
        self.spec_npcSpot.spots = spots
    end
end
function PlaceableNPCSpot:onFinalizePlacement()
    local spec = self.spec_npcSpot
    if spec.spots ~= nil then
        for _, spot in ipairs(spec.spots) do
            g_npcManager:addSpot(spot)
        end
    end
end
function PlaceableNPCSpot:onDelete()
    local spec = self.spec_npcSpot
    if spec.spots ~= nil then
        for _, spot in ipairs(spec.spots) do
            g_npcManager:removeSpot(spot)
        end
    end
end