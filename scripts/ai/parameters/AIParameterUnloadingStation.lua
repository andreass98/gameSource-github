AIParameterUnloadingStation = {}
local AIParameterUnloadingStation_mt = Class(AIParameterUnloadingStation, AIParameter)
function AIParameterUnloadingStation.new(customMt)
    -- upvalues: (copy) AIParameterUnloadingStation_mt
    local self = AIParameter.new(customMt or AIParameterUnloadingStation_mt)
    self.type = AIParameterType.UNLOADING_STATION
    self.unloadingStationId = nil
    self.unloadingStationIds = {}
    return self
end
function AIParameterUnloadingStation:saveToXMLFile(xmlFile, key, _)
    local unloadingStation = self:getUnloadingStation()
    if unloadingStation ~= nil then
        local owningPlaceable = unloadingStation.owningPlaceable
        if owningPlaceable ~= nil then
            local uniqueId = owningPlaceable:getUniqueId()
            if uniqueId ~= nil then
                local index = g_currentMission.storageSystem:getPlaceableUnloadingStationIndex(owningPlaceable, unloadingStation)
                if index ~= nil then
                    xmlFile:setString(key .. "#stationUniqueId", uniqueId)
                    xmlFile:setInt(key .. "#stationIndex", index)
                end
            end
        end
    end
end
function AIParameterUnloadingStation:loadFromXMLFile(xmlFile, key)
    local unloadingStationUniqueId = xmlFile:getString(key .. "#stationUniqueId")
    local stationIndex = xmlFile:getInt(key .. "#stationIndex")
    if unloadingStationUniqueId ~= nil and (stationIndex ~= nil and not self:setUnloadingStationFromUniqueId(unloadingStationUniqueId, stationIndex)) then
        g_messageCenter:subscribeOneshot(MessageType.LOADED_ALL_SAVEGAME_PLACEABLES, self.onPlaceableLoaded, self, { unloadingStationUniqueId, stationIndex })
    end
end
function AIParameterUnloadingStation:onPlaceableLoaded(args)
    self:setUnloadingStationFromUniqueId(args[1], args[2])
end
function AIParameterUnloadingStation:setUnloadingStationFromUniqueId(uniqueId, index)
    local placeable = g_currentMission.placeableSystem:getPlaceableByUniqueId(uniqueId)
    if placeable == nil then
        return false
    end
    self:setUnloadingStation((g_currentMission.storageSystem:getPlaceableUnloadingStation(placeable, index)))
    return true
end
function AIParameterUnloadingStation:readStream(streamId, _)
    if streamReadBool(streamId) then
        self.unloadingStationId = NetworkUtil.readNodeObjectId(streamId)
    end
end
function AIParameterUnloadingStation:writeStream(streamId, _)
    if streamWriteBool(streamId, self.unloadingStationId ~= nil) then
        NetworkUtil.writeNodeObjectId(streamId, self.unloadingStationId)
    end
end
function AIParameterUnloadingStation:setUnloadingStation(unloadingStation)
    self.unloadingStationId = NetworkUtil.getObjectId(unloadingStation)
end
function AIParameterUnloadingStation:getUnloadingStation()
    local unloadingStation = NetworkUtil.getObject(self.unloadingStationId)
    if unloadingStation == nil or (unloadingStation.owningPlaceable == nil or not unloadingStation.owningPlaceable:getIsSynchronized()) then
        return nil
    else
        return unloadingStation
    end
end
function AIParameterUnloadingStation:getString()
    local unloadingStation = NetworkUtil.getObject(self.unloadingStationId)
    return unloadingStation == nil and "" or unloadingStation:getName()
end
function AIParameterUnloadingStation:setValidUnloadingStations(unloadingStations)
    self.unloadingStationIds = {}
    local nextUnloadingStationId = nil
    for _, unloadingStation in ipairs(unloadingStations) do
        local id = NetworkUtil.getObjectId(unloadingStation)
        if id ~= nil then
            if id == self.unloadingStationId then
                nextUnloadingStationId = id
            end
            table.insert(self.unloadingStationIds, id)
        end
    end
    self.unloadingStationId = nextUnloadingStationId or self.unloadingStationIds[1]
end
function AIParameterUnloadingStation:setNextItem()
    local nextIndex = 0
    for k, unloadingStationId in ipairs(self.unloadingStationIds) do
        if unloadingStationId == self.unloadingStationId then
            nextIndex = k + 1
        end
    end
    local nextIndex = #self.unloadingStationIds < nextIndex and 1 or nextIndex
    self.unloadingStationId = self.unloadingStationIds[nextIndex]
end
function AIParameterUnloadingStation:setPreviousItem()
    local previousIndex = 0
    for k, unloadingStationId in ipairs(self.unloadingStationIds) do
        if unloadingStationId == self.unloadingStationId then
            previousIndex = k - 1
        end
    end
    local previousIndex = previousIndex < 1 and #self.unloadingStationIds or previousIndex
    self.unloadingStationId = self.unloadingStationIds[previousIndex]
end
function AIParameterUnloadingStation:validate(fillTypeIndex, farmId)
    if self.unloadingStationId == nil then
        return false, g_i18n:getText("ai_validationErrorNoUnloadingStation")
    end
    local unloadingStation = self:getUnloadingStation()
    if unloadingStation == nil then
        return false, g_i18n:getText("ai_validationErrorUnloadingStationDoesNotExistAnymore")
    end
    if fillTypeIndex ~= nil then
        if not unloadingStation:getIsFillTypeAISupported(fillTypeIndex) then
            return false, g_i18n:getText("ai_validationErrorFillTypeNotSupportedByUnloadingStation")
        end
        if unloadingStation:getFreeCapacity(fillTypeIndex, farmId) <= 0 then
            return false, g_i18n:getText("ai_validationErrorUnloadingStationIsFull")
        end
    end
    return true, nil
end