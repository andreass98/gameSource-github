BuyPlaceableData = {}
local BuyPlaceableData_mt = Class(BuyPlaceableData)
function BuyPlaceableData.new(customMt)
    -- upvalues: (copy) BuyPlaceableData_mt
    local self = setmetatable({}, customMt or BuyPlaceableData_mt)
    self.storeItem = nil
    self.isFreeOfCharge = false
    self.configurations = {}
    self.boughtConfigurations = {}
    self.configurationData = {}
    self.ownerFarmId = AccessHandler.EVERYONE
    self.price = 0
    self.displacementCosts = 0
    self.modifyTerrain = false
    self.realignToTerrain = true
    self.position = { 0, 0, 0 }
    self.rotation = { 0, 0, 0 }
    return self
end
function BuyPlaceableData:isValid()
    if self.storeItem == nil then
        return false
    else
        return (not GS_IS_CONSOLE_VERSION or fileExists(self.storeItem.xmlFilename)) and true or false
    end
end
function BuyPlaceableData:setStoreItem(storeItem)
    self.storeItem = storeItem
end
function BuyPlaceableData:setPosition(x, y, z)
    self.position[1] = x
    self.position[2] = y
    self.position[3] = z
end
function BuyPlaceableData:setRotation(rx, ry, rz)
    self.rotation[1] = rx
    self.rotation[2] = ry
    self.rotation[3] = rz
end
function BuyPlaceableData:setIsFreeOfCharge(isFreeOfCharge)
    self.isFreeOfCharge = isFreeOfCharge
end
function BuyPlaceableData:setConfigurations(configurations, boughtConfigurations)
    self.configurations = configurations or self.configurations
    self.boughtConfigurations = boughtConfigurations or self.boughtConfigurations
    for configName, index in pairs(self.configurations) do
        if self.boughtConfigurations[configName] == nil then
            self.boughtConfigurations[configName] = {}
        end
        self.boughtConfigurations[configName][index] = true
    end
end
function BuyPlaceableData:setConfigurationData(configurationData)
    self.configurationData = configurationData or self.configurationData
end
function BuyPlaceableData:setOwnerFarmId(ownerFarmId)
    self.ownerFarmId = ownerFarmId
end
function BuyPlaceableData:setPrice(price)
    self.price = price
end
function BuyPlaceableData:updatePrice()
    self.price = g_currentMission.economyManager:getBuyPrice(self.storeItem, self.configurations, nil)
end
function BuyPlaceableData:setDisplacementCosts(displacementCosts)
    self.displacementCosts = displacementCosts
end
function BuyPlaceableData:setModifyTerrain(modifyTerrain)
    self.modifyTerrain = modifyTerrain
end
function BuyPlaceableData:setRealignToTerrainAfterLeveling(realignToTerrain)
    self.realignToTerrain = realignToTerrain
end
function BuyPlaceableData:readStream(streamId, connection)
    local xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
    self.storeItem = g_storeManager:getItemByXMLFilename(string.lower(xmlFilename))
    self.position[1] = streamReadFloat32(streamId)
    self.position[2] = streamReadFloat32(streamId)
    self.position[3] = streamReadFloat32(streamId)
    self.rotation[1] = streamReadFloat32(streamId)
    self.rotation[2] = streamReadFloat32(streamId)
    self.rotation[3] = streamReadFloat32(streamId)
    self.configurations, self.boughtConfigurations, self.configurationData = ConfigurationUtil.readConfigurationsFromStream(g_placeableConfigurationManager, streamId, connection, xmlFilename)
    self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.isFreeOfCharge = streamReadBool(streamId)
    self.displacementCosts = streamReadInt32(streamId)
    self.modifyTerrain = streamReadBool(streamId)
    self.realignToTerrain = streamReadBool(streamId)
end
function BuyPlaceableData:writeStream(streamId, connection)
    streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.storeItem.xmlFilename))
    streamWriteFloat32(streamId, self.position[1])
    streamWriteFloat32(streamId, self.position[2])
    streamWriteFloat32(streamId, self.position[3])
    streamWriteFloat32(streamId, self.rotation[1])
    streamWriteFloat32(streamId, self.rotation[2])
    streamWriteFloat32(streamId, self.rotation[3])
    ConfigurationUtil.writeConfigurationsToStream(g_placeableConfigurationManager, streamId, connection, self.storeItem.xmlFilename, self.configurations, self.boughtConfigurations, self.configurationData)
    streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    streamWriteBool(streamId, self.isFreeOfCharge)
    streamWriteInt32(streamId, self.displacementCosts)
    streamWriteBool(streamId, self.modifyTerrain)
    streamWriteBool(streamId, self.realignToTerrain)
end
function BuyPlaceableData:buy(callback, callbackTarget, callbackArguments)
    local data = PlaceableLoadingData.new()
    data:setStoreItem(self.storeItem)
    data:setConfigurations(self.configurations, self.boughtConfigurations)
    data:setConfigurationData(self.configurationData)
    data:setOwnerFarmId(self.ownerFarmId)
    data:setPosition(self.position[1], self.position[2], self.position[3])
    data:setRotation(self.rotation[1], self.rotation[2], self.rotation[3])
    data:load(self.onLoaded, self, {
        ["callback"] = callback,
        ["callbackTarget"] = callbackTarget,
        ["callbackArguments"] = callbackArguments
    })
end
function BuyPlaceableData:onLoaded(placeable, loadingState, arguments)
    if loadingState == PlaceableLoadingState.OK then
        if self.modifyTerrain and placeable.applyDeformation ~= nil then
            placeable:applyDeformation(false, function(errorCode, displacedVolume, _)
                -- upvalues: (copy) placeable, (copy) self, (copy) arguments, (copy) loadingState
                if errorCode == TerrainDeformation.STATE_SUCCESS then
                    if displacedVolume > 0 and self.realignToTerrain then
                        local x, y, z = placeable:getPosition()
                        placeable:setPose(nil, getTerrainHeightAtWorldPos(g_terrainNode, x, y, z), nil)
                    end
                    self:onBought(placeable, loadingState, arguments)
                else
                    placeable:delete()
                    self:onBought(nil, PlaceableLoadingState.DEFORMATION_FAILED, arguments)
                end
            end)
        else
            deformationCallback(TerrainDeformation.STATE_SUCCESS, 0, nil)
        end
    else
        self:onBought(placeable, loadingState, arguments)
        return
    end
end
function BuyPlaceableData:onBought(placeable, loadingState, arguments)
    if loadingState == PlaceableLoadingState.OK then
        if not self.isFreeOfCharge then
            local financeCategory = MoneyType.getMoneyTypeByName(self.storeItem.financeCategory) or MoneyType.SHOP_PROPERTY_BUY
            g_currentMission:addMoney(-(self.price + self.displacementCosts), self.ownerFarmId, financeCategory, true, true)
        end
        placeable.undoTimer = g_time
        placeable:finalizePlacement()
        placeable:onBuy()
    end
    if arguments.callback ~= nil then
        arguments.callback(arguments.callbackTarget, placeable, loadingState, arguments.callbackArguments)
    end
end