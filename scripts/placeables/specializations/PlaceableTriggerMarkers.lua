PlaceableTriggerMarkers = {}
function PlaceableTriggerMarkers.prerequisitesPresent(specializations)
    return true
end
function PlaceableTriggerMarkers.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableTriggerMarkers)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableTriggerMarkers)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableTriggerMarkers)
    SpecializationUtil.registerEventListener(placeableType, "onOwnerChanged", PlaceableTriggerMarkers)
end
function PlaceableTriggerMarkers.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onPlayerFarmChanged", PlaceableTriggerMarkers.onPlayerFarmChanged)
    SpecializationUtil.registerFunction(placeableType, "onMarkerFileLoaded", PlaceableTriggerMarkers.onMarkerFileLoaded)
    SpecializationUtil.registerFunction(placeableType, "getTriggerMarkerPosition", PlaceableTriggerMarkers.getTriggerMarkerPosition)
    SpecializationUtil.registerFunction(placeableType, "setShowMarkers", PlaceableTriggerMarkers.setShowMarkers)
end
function PlaceableTriggerMarkers.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("TriggerMarkers")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".triggerMarkers.triggerMarker(?)#node", "Trigger marker node")
    schema:register(XMLValueType.FILENAME, basePath .. ".triggerMarkers.triggerMarker(?)#filename", "Trigger marker i3d filename")
    schema:register(XMLValueType.BOOL, basePath .. ".triggerMarkers.triggerMarker(?)#adjustToGround", "Trigger marker adjusted to ground")
    schema:register(XMLValueType.FLOAT, basePath .. ".triggerMarkers.triggerMarker(?)#groundOffset", "Height of the trigger marker above the ground if adjustToGround is enabled", 0.03)
    schema:register(XMLValueType.BOOL, basePath .. ".triggerMarkers.triggerMarker(?)#showAllPlayers", "Show marker for all players even if they do not have access to the placeable", false)
    schema:register(XMLValueType.BOOL, basePath .. ".triggerMarkers.triggerMarker(?)#showOnlyIfOwned", "Show marker only if owned", false)
    schema:setXMLSpecializationType()
end
function PlaceableTriggerMarkers:onLoad(_)
    local spec = self.spec_triggerMarkers
    local xmlFile = self.xmlFile
    spec.sharedLoadRequestIds = {}
    spec.triggerMarkers = {}
    for _, key in xmlFile:iterator("placeable.triggerMarkers.triggerMarker") do
        local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        if node == nil then
            Logging.xmlWarning(xmlFile, "Missing trigger marker node for \'%s\'", key)
        else
            local adjustToGround = xmlFile:getValue(key .. "#adjustToGround", false)
            local groundOffset = xmlFile:getValue(key .. "#groundOffset")
            if groundOffset ~= nil and not adjustToGround then
                Logging.xmlWarning(xmlFile, "\'groundOffset=%.2f\' given but \'adjustToGround\' is false for \'%s\'", groundOffset, key)
            end
            local i3dFilename = self.xmlFile:getValue(key .. "#filename", nil, self.baseDirectory)
            local marker = {
                ["node"] = node,
                ["i3dFilename"] = i3dFilename,
                ["adjustToGround"] = adjustToGround,
                ["groundOffset"] = groundOffset or 0.03,
                ["showAllPlayers"] = self.xmlFile:getValue(key .. "#showAllPlayers", false),
                ["showOnlyIfOwned"] = self.xmlFile:getValue(key .. "#showOnlyIfOwned", false)
            }
            if i3dFilename ~= nil then
                local args = {
                    ["marker"] = marker,
                    ["loadingTask"] = self:createLoadingTask()
                }
                local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(i3dFilename, false, false, self.onMarkerFileLoaded, self, args)
                table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
            end
            local args = spec.triggerMarkers
            table.insert(args, marker)
        end
    end
end
function PlaceableTriggerMarkers:onMarkerFileLoaded(i3dNode, _, args)
    if i3dNode ~= 0 then
        link(args.marker.node, i3dNode)
        args.marker.node = i3dNode
    end
    self:finishLoadingTask(args.loadingTask)
end
function PlaceableTriggerMarkers:onDelete()
    local spec = self.spec_triggerMarkers
    if spec.sharedLoadRequestIds ~= nil then
        for _, sharedLoadRequestId in ipairs(spec.sharedLoadRequestIds) do
            g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
        end
        spec.sharedLoadRequestIds = nil
    end
    if spec.triggerMarkers ~= nil then
        for _, sharedLoadRequestId in ipairs(spec.triggerMarkers) do
            g_currentMission:removeTriggerMarker(sharedLoadRequestId.node)
        end
    end
    g_messageCenter:unsubscribe(MessageType.PLAYER_FARM_CHANGED, self)
    g_messageCenter:unsubscribe(MessageType.PLAYER_CREATED, self)
end
function PlaceableTriggerMarkers:onFinalizePlacement()
    if g_terrainNode ~= nil then
        for _, marker in ipairs(self.spec_triggerMarkers.triggerMarkers) do
            if marker.adjustToGround then
                local x, _, z = getWorldTranslation(marker.node)
                local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + marker.groundOffset
                setWorldTranslation(marker.node, x, y, z)
            end
        end
    end
    self:setShowMarkers(g_currentMission.accessHandler:canPlayerAccess(self))
    g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.onPlayerFarmChanged, self)
    g_messageCenter:subscribe(MessageType.PLAYER_CREATED, self.onPlayerFarmChanged, self)
end
function PlaceableTriggerMarkers:onOwnerChanged()
    self:setShowMarkers(g_currentMission.accessHandler:canPlayerAccess(self))
end
function PlaceableTriggerMarkers:onPlayerFarmChanged()
    self:setShowMarkers(g_currentMission.accessHandler:canPlayerAccess(self))
end
function PlaceableTriggerMarkers:setShowMarkers(doShow)
    local ownerFarmId = self:getOwnerFarmId()
    local isOwned = false
    if ownerFarmId ~= AccessHandler.EVERYONE then
        isOwned = ownerFarmId ~= AccessHandler.NOBODY
    end
    for _, marker in ipairs(self.spec_triggerMarkers.triggerMarkers) do
        local show = doShow or marker.showAllPlayers
        if marker.showOnlyIfOwned and not isOwned then
            show = false
        end
        if show then
            g_currentMission:addTriggerMarker(marker.node)
        else
            g_currentMission:removeTriggerMarker(marker.node)
        end
    end
end
function PlaceableTriggerMarkers:getTriggerMarkerPosition(index)
    local marker = self.spec_triggerMarkers.triggerMarkers[index]
    if marker == nil then
        return nil
    else
        return getWorldTranslation(marker.node)
    end
end