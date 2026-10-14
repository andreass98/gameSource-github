AIParameterLoadingStation = {}
local AIParameterLoadingStation_mt = Class(AIParameterLoadingStation, AIParameter)
function AIParameterLoadingStation.new(customMt)
    -- upvalues: (copy) AIParameterLoadingStation_mt
    local self = AIParameter.new(customMt or AIParameterLoadingStation_mt)
    self.type = AIParameterType.LOADING_STATION
    self.loadingStationId = nil
    self.loadingStationIds = {}
    return self
end
function AIParameterLoadingStation:saveToXMLFile(xmlFile, key, _)
    local loadingStation = self:getLoadingStation()
    if loadingStation ~= nil then
        local owningPlaceable = loadingStation.owningPlaceable
        if owningPlaceable ~= nil then
            local uniqueId = owningPlaceable:getUniqueId()
            if uniqueId ~= nil then
                local index = g_currentMission.storageSystem:getPlaceableLoadingStationIndex(owningPlaceable, loadingStation)
                if index ~= nil then
                    xmlFile:setString(key .. "#stationUniqueId", uniqueId)
                    xmlFile:setInt(key .. "#stationIndex", index)
                end
            end
        end
    end
end
function AIParameterLoadingStation:loadFromXMLFile(xmlFile, key)
    local loadingStationUniqueId = xmlFile:getString(key .. "#stationUniqueId")
    local stationIndex = xmlFile:getInt(key .. "#stationIndex")
    if loadingStationUniqueId ~= nil and (stationIndex ~= nil and not self:setLoadingStationFromUniqueId(loadingStationUniqueId, stationIndex)) then
        g_messageCenter:subscribeOneshot(MessageType.LOADED_ALL_SAVEGAME_PLACEABLES, self.onPlaceableLoaded, self, { loadingStationUniqueId, stationIndex })
    end
end
function AIParameterLoadingStation:onPlaceableLoaded(args)
    self:setLoadingStationFromUniqueId(args[1], args[2])
end
function AIParameterLoadingStation:setLoadingStationFromUniqueId(uniqueId, index)
    local placeable = g_currentMission.placeableSystem:getPlaceableByUniqueId(uniqueId)
    if placeable == nil then
        return false
    end
    self:setLoadingStation((g_currentMission.storageSystem:getPlaceableLoadingStation(placeable, index)))
    return true
end
function AIParameterLoadingStation:readStream(streamId, _)
    if streamReadBool(streamId) then
        self.loadingStationId = NetworkUtil.readNodeObjectId(streamId)
    end
end
function AIParameterLoadingStation:writeStream(streamId, _)
    if streamWriteBool(streamId, self.loadingStationId ~= nil) then
        NetworkUtil.writeNodeObjectId(streamId, self.loadingStationId)
    end
end
function AIParameterLoadingStation:setLoadingStation(loadingStation)
    self.loadingStationId = NetworkUtil.getObjectId(loadingStation)
end
function AIParameterLoadingStation:getLoadingStation()
    local loadingStation = NetworkUtil.getObject(self.loadingStationId)
    if loadingStation == nil or (loadingStation.owningPlaceable == nil or not loadingStation.owningPlaceable:getIsSynchronized()) then
        return nil
    else
        return loadingStation
    end
end
function AIParameterLoadingStation:getString()
    local loadingStation = NetworkUtil.getObject(self.loadingStationId)
    return loadingStation == nil and "" or loadingStation:getName()
end
function AIParameterLoadingStation:setValidLoadingStations(loadingStationIds)
    self.loadingStationIds = {}
    local nextLoadingStationId = nil
    for _, loadingStation in ipairs(loadingStationIds) do
        local id = NetworkUtil.getObjectId(loadingStation)
        if id ~= nil then
            if id == self.loadingStationId then
                nextLoadingStationId = id
            end
            table.insert(self.loadingStationIds, id)
        end
    end
    self.loadingStationId = nextLoadingStationId or self.loadingStationIds[1]
end
function AIParameterLoadingStation:setNextItem()
    local nextIndex = 0
    for k, loadingStationId in ipairs(self.loadingStationIds) do
        if loadingStationId == self.loadingStationId then
            nextIndex = k + 1
        end
    end
    local nextIndex = #self.loadingStationIds < nextIndex and 1 or nextIndex
    self.loadingStationId = self.loadingStationIds[nextIndex]
end
function AIParameterLoadingStation:setPreviousItem()
    local previousIndex = 0
    for k, loadingStationId in ipairs(self.loadingStationIds) do
        if loadingStationId == self.loadingStationId then
            previousIndex = k - 1
        end
    end
    local previousIndex = previousIndex < 1 and #self.loadingStationIds or previousIndex
    self.loadingStationId = self.loadingStationIds[previousIndex]
end
function AIParameterLoadingStation:validate(fillTypeIndex, farmId)
    if self.loadingStationId == nil then
        return false, g_i18n:getText("ai_validationErrorNoLoadingStation")
    end
    local loadingStation = self:getLoadingStation()
    if loadingStation == nil then
        return false, g_i18n:getText("ai_validationErrorLoadingStationDoesNotExistAnymore")
    end
    if fillTypeIndex ~= nil then
        if not loadingStation:getIsFillTypeAISupported(fillTypeIndex) then
            return false, g_i18n:getText("ai_validationErrorFillTypeNotSupportedByLoadingStation")
        end
        if loadingStation:getFillLevel(fillTypeIndex, farmId) <= 0 then
            return false, g_i18n:getText("ai_validationErrorLoadingStationIsEmpty")
        end
    end
    return true, nil
end