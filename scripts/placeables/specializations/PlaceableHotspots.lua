PlaceableHotspots = {}
function PlaceableHotspots.prerequisitesPresent(specializations)
    return true
end
function PlaceableHotspots.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "getHotspot", PlaceableHotspots.getHotspot)
    SpecializationUtil.registerFunction(placeableType, "updateHotspots", PlaceableHotspots.updateHotspots)
    SpecializationUtil.registerFunction(placeableType, "setHotspotVisible", PlaceableHotspots.setHotspotVisible)
end
function PlaceableHotspots.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHotspots)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHotspots)
    SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableHotspots)
    SpecializationUtil.registerEventListener(placeableType, "onOwnerChanged", PlaceableHotspots)
end
function PlaceableHotspots.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Hotspots")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".hotspots.hotspot(?)#linkNode", "Node where hotspot is linked to")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".hotspots.hotspot(?)#teleportNode", "Node where player is teleported to. Teleporting is only available if this is set")
    schema:register(XMLValueType.STRING, basePath .. ".hotspots.hotspot(?)#type", "Placeable hotspot type", "UNLOADING", false, table.toList(PlaceableHotspot.TYPE))
    schema:register(XMLValueType.VECTOR_2, basePath .. ".hotspots.hotspot(?)#worldPosition", "Placeable world position")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".hotspots.hotspot(?)#teleportWorldPosition", "Placeable teleport world position")
    schema:register(XMLValueType.STRING, basePath .. ".hotspots.hotspot(?)#text", "Placeable hotspot text")
    schema:setXMLSpecializationType()
end
function PlaceableHotspots:onLoad(_)
    local spec = self.spec_hotspots
    spec.mapHotspots = {}
    self.xmlFile:iterate("placeable.hotspots.hotspot", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local hotspot = PlaceableHotspot.new()
        hotspot:setPlaceable(self)
        local hotspotTypeName = self.xmlFile:getValue(key .. "#type", "UNLOADING")
        local hotspotType = PlaceableHotspot.getTypeByName(hotspotTypeName)
        if hotspotType == nil then
            Logging.xmlWarning(self.xmlFile, "Unknown placeable hotspot type \'%s\'. Falling back to type \'UNLOADING\'\nAvailable types: %s", hotspotTypeName, table.concatKeys(PlaceableHotspot.TYPE, " "))
            hotspotType = PlaceableHotspot.TYPE.UNLOADING
        end
        hotspot:setPlaceableType(hotspotType)
        local linkNode = self.xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings) or self.rootNode
        if linkNode ~= nil then
            local x, _, z = getWorldTranslation(linkNode)
            hotspot:setWorldPosition(x, z)
        end
        local x = self.xmlFile:getValue(key .. "#teleportNode", nil, self.components, self.i3dMappings)
        if x ~= nil then
            local _, z, z = getWorldTranslation(x)
            hotspot:setTeleportWorldPosition(_, z, z)
        end
        local _, z = self.xmlFile:getValue(key .. "#worldPosition", nil)
        if _ ~= nil then
            hotspot:setWorldPosition(_, z)
        end
        local z, teleportY, teleportZ = self.xmlFile:getValue(key .. "#teleportWorldPosition", nil)
        if z ~= nil then
            if g_currentMission ~= nil then
                teleportY = math.max(teleportY, getTerrainHeightAtWorldPos(g_terrainNode, z, 0, teleportZ))
            end
            hotspot:setTeleportWorldPosition(z, teleportY, teleportZ)
        end
        local text = self.xmlFile:getValue(key .. "#text", nil)
        if text ~= nil then
            hotspot:setName((g_i18n:convertText(text, self.customEnvironment)))
        end
        table.insert(spec.mapHotspots, hotspot)
    end)
end
function PlaceableHotspots:onDelete()
    local spec = self.spec_hotspots
    g_messageCenter:unsubscribeAll(self)
    if spec.mapHotspots ~= nil then
        for _, hotspot in ipairs(spec.mapHotspots) do
            g_currentMission:removeMapHotspot(hotspot)
            hotspot:delete()
        end
    end
end
function PlaceableHotspots:onPostFinalizePlacement()
    for _, hotspot in ipairs(self.spec_hotspots.mapHotspots) do
        g_currentMission:addMapHotspot(hotspot)
    end
    self:updateHotspots()
end
function PlaceableHotspots:onOwnerChanged()
    self:updateHotspots()
end
function PlaceableHotspots:updateHotspots()
    local spec = self.spec_hotspots
    if spec.mapHotspots ~= nil then
        for _, hotspot in ipairs(spec.mapHotspots) do
            hotspot:setOwnerFarmId(self.ownerFarmId)
            local isVisible = true
            if spec.hiddenMapHotspots ~= nil and spec.hiddenMapHotspots[hotspot] then
                isVisible = false
            end
            if isVisible then
                isVisible = self.ownerFarmId ~= AccessHandler.NOBODY
            end
            hotspot:setVisible(isVisible)
        end
    end
end
function PlaceableHotspots:getHotspot(index)
    return self.spec_hotspots.mapHotspots[index or 1]
end
function PlaceableHotspots:setHotspotVisible(index, isVisible)
    local spec = self.spec_hotspots
    if spec.mapHotspots ~= nil then
        local hotspot = spec.mapHotspots[index]
        if hotspot == nil then
            Logging.warning("Placeable hotspot \'%s\' not defined in \'%s\'", index, self.configFileName)
        else
            if not isVisible then
                if spec.hiddenMapHotspots == nil then
                    spec.hiddenMapHotspots = {}
                end
                spec.hiddenMapHotspots[hotspot] = true
                return
            end
            if spec.hiddenMapHotspots ~= nil then
                spec.hiddenMapHotspots[hotspot] = nil
                if next(spec.hiddenMapHotspots) == nil then
                    spec.hiddenMapHotspots = nil
                    return
                end
            end
        end
    end
end