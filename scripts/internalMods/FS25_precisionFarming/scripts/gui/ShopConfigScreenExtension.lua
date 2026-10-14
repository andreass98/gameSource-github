ShopConfigScreenExtension = {}
ShopConfigScreenExtension.MOD_NAME = g_currentModName
ShopConfigScreenExtension.MOD_DIR = g_currentModDirectory
ShopConfigScreenExtension.GUI_EXT_XML = g_currentModDirectory .. "gui/ShopConfigScreenExtension.xml"
ShopConfigScreenExtension.HEADER_SIZE = 75
local ShopConfigScreenExtension_mt = Class(ShopConfigScreenExtension)
function ShopConfigScreenExtension.new(customMt)
    -- upvalues: (copy) ShopConfigScreenExtension_mt
    return setmetatable({}, customMt or ShopConfigScreenExtension_mt)
end
function ShopConfigScreenExtension:unloadMapData() end
function ShopConfigScreenExtension:delete() end
function ShopConfigScreenExtension:update(dt) end
function ShopConfigScreenExtension.getConfigWorkingWidth(storeItem, configurations)
    if storeItem.specs.workingWidthConfig == nil then
        if storeItem.specs.workingWidth ~= nil then
            return storeItem.specs.workingWidth.width or 0
        end
    else
        for configName, config in pairs(configurations) do
            if storeItem.specs.workingWidthConfig[configName] ~= nil then
                local configData = storeItem.specs.workingWidthConfig[configName][config]
                if configData ~= nil then
                    return configData.width
                end
            end
        end
    end
    return 0
end
function ShopConfigScreenExtension.updateConfigPrices(_, storeItem, configurations)
    StoreItemUtil.loadSpecsFromXML(storeItem)
    if storeItem.configurations ~= nil then
        local workingWidth = ShopConfigScreenExtension.getConfigWorkingWidth(storeItem, configurations)
        local priceSpotSpray, priceSeeAndSpray, pricePwm = g_precisionFarming:getSprayerConfigPrices()
        local spotSprayConfigs = storeItem.configurations.weedSpotSpray
        if spotSprayConfigs ~= nil then
            if spotSprayConfigs[2].overwrittenTitle == nil then
                spotSprayConfigs[2].price = priceSpotSpray * math.floor(workingWidth)
            else
                spotSprayConfigs[2].price = priceSeeAndSpray * math.floor(workingWidth)
            end
        end
        local pwmConfigs = storeItem.configurations.pulseWidthModulation
        if pwmConfigs ~= nil then
            pwmConfigs[2].price = pricePwm * math.floor(workingWidth)
        end
    end
end
function ShopConfigScreenExtension.getIsConfigurationInConfigSet(_, storeItem, configSetIndex, configName)
    if storeItem ~= nil and #storeItem.configurationSets > 0 then
        local configSet = storeItem.configurationSets[configSetIndex]
        if configSet ~= nil and configSet.configurations[configName] then
            return true
        end
    end
    return false
end
function ShopConfigScreenExtension:overwriteGameFunctions(pfModule)
    pfModule:overwriteGameFunction(ShopConfigScreen, "loadMapData", function(superFunc, _self, ...)
        -- upvalues: (copy) self
        superFunc(_self, ...)
        self.precisionFarmingInfoContainer = PrecisionFarmingGUI.loadAdditionalGUI("gui/ShopConfigScreenExtension.xml", _self, _self.elements[1])
        _self.precisionFarmingInfoWindowBackgroundSizeOffset = _self.precisionFarmingInfoWindowBackground.size[2] - _self.precisionFarmingInfoWindow.size[2]
        self.precisionFarmingTexts = {}
        self.precisionFarmingTexts.cropSensorHeader = g_i18n:getText("shopInfo_cropSensorHeader", ShopConfigScreenExtension.MOD_NAME)
        self.precisionFarmingTexts.cropSensorText = g_i18n:getText("shopInfo_cropSensorText", ShopConfigScreenExtension.MOD_NAME)
        self.precisionFarmingTexts.manureSensorHeader = g_i18n:getText("shopInfo_manureSensorHeader", ShopConfigScreenExtension.MOD_NAME)
        self.precisionFarmingTexts.manureSensorText = g_i18n:getText("shopInfo_manureSensorText", ShopConfigScreenExtension.MOD_NAME)
        self.precisionFarmingTexts.weedSpotSprayHeader = g_i18n:getText("shopInfo_weedSpotSprayHeader", ShopConfigScreenExtension.MOD_NAME)
        self.precisionFarmingTexts.weedSpotSprayText = g_i18n:getText("shopInfo_weedSpotSprayText", ShopConfigScreenExtension.MOD_NAME)
        self.pfShopConfigurations = {
            ["cropSensor"] = {
                ["lastIndex"] = 1,
                ["lastChangeTime"] = 0,
                ["title"] = g_i18n:getText("shopInfo_cropSensorHeader", ShopConfigScreenExtension.MOD_NAME),
                ["text"] = g_i18n:getText("shopInfo_cropSensorText", ShopConfigScreenExtension.MOD_NAME)
            },
            ["manureSensor"] = {
                ["lastIndex"] = 1,
                ["lastChangeTime"] = 0,
                ["title"] = g_i18n:getText("shopInfo_manureSensorHeader", ShopConfigScreenExtension.MOD_NAME),
                ["text"] = g_i18n:getText("shopInfo_manureSensorText", ShopConfigScreenExtension.MOD_NAME)
            },
            ["weedSpotSpray"] = {
                ["lastIndex"] = 1,
                ["lastChangeTime"] = 0,
                ["title"] = g_i18n:getText("shopInfo_weedSpotSprayHeader", ShopConfigScreenExtension.MOD_NAME),
                ["text"] = g_i18n:getText("shopInfo_weedSpotSprayText", ShopConfigScreenExtension.MOD_NAME)
            },
            ["pulseWidthModulation"] = {
                ["lastIndex"] = 1,
                ["lastChangeTime"] = 0,
                ["title"] = g_i18n:getText("shopInfo_pulseWidthModulationHeader", ShopConfigScreenExtension.MOD_NAME),
                ["text"] = g_i18n:getText("shopInfo_pulseWidthModulationText", ShopConfigScreenExtension.MOD_NAME)
            }
        }
    end)
    pfModule:overwriteGameFunction(ShopConfigScreen, "onOpen", function(superFunc, _self, ...)
        -- upvalues: (copy) self
        superFunc(_self, ...)
        self.pfLastCropSensorConfigurationIndex = nil
        self.pfLastManureSensorConfigurationIndex = nil
        self.pfLastWeedSpotSpraySensorConfigurationIndex = nil
        if self.pfShopConfigurations ~= nil then
            for _, configData in pairs(self.pfShopConfigurations) do
                configData.lastIndex = 1
                configData.lastChangeTime = 0
            end
        end
    end)
    pfModule:overwriteGameFunction(ShopConfigScreen, "loadCurrentConfiguration", function(superFunc, _self, ...)
        -- upvalues: (copy) self
        superFunc(_self, ...)
        if _self.configurations ~= nil and self.pfShopConfigurations ~= nil then
            for configName, configData in pairs(self.pfShopConfigurations) do
                local index = _self.configurations[configName]
                if index ~= nil and configData.lastIndex ~= index then
                    configData.lastIndex = index
                    configData.lastChangeTime = g_time
                end
            end
            local configDataToShow = nil
            local maxTime = 0
            for index, configData in pairs(self.pfShopConfigurations) do
                if not self:getIsConfigurationInConfigSet(_self.storeItem, _self.currentConfigSet, index) then
                    local index = _self.configurations[index]
                    if index ~= nil and (index > 1 and maxTime < configData.lastChangeTime) then
                        maxTime = configData.lastChangeTime
                        configDataToShow = configData
                    end
                end
            end
            if configDataToShow == nil then
                for index, configData in pairs(self.pfShopConfigurations) do
                    if not self:getIsConfigurationInConfigSet(_self.storeItem, _self.currentConfigSet, index) then
                        local index = _self.configurations[index]
                        if index ~= nil and index > 1 then
                            configDataToShow = configData
                            break
                        end
                    end
                end
            end
            local _ = _self.precisionFarmingInfoWindow
            local configData = configDataToShow ~= nil
            _:setVisible(configData)
            if configDataToShow ~= nil then
                _self.precisionFarmingInfoHeader:setText(configDataToShow.title)
                _self.precisionFarmingInfoText:setText(configDataToShow.text)
                local _, configName = getNormalizedScreenValues(0, ShopConfigScreenExtension.HEADER_SIZE)
                local configData = _self.precisionFarmingInfoText:getTextHeight(true) + configName
                _self.precisionFarmingInfoWindow:setSize(nil, configData)
                _self.precisionFarmingInfoWindowBackground:setSize(nil, configData + _self.precisionFarmingInfoWindowBackgroundSizeOffset)
            end
        end
    end)
    pfModule:overwriteGameFunction(ShopConfigScreen, "updateDisplay", function(superFunc, _self, storeItem, vehicle, saleItem, doNotReload, ...)
        -- upvalues: (copy) self
        self:updateConfigPrices(_self.storeItem, _self.configurations)
        return superFunc(_self, storeItem, vehicle, saleItem, doNotReload, ...)
    end)
    pfModule:overwriteGameFunction(ShopConfigScreen, "updateData", function(superFunc, _self, storeItem, vehicle, saleItem, ...)
        -- upvalues: (copy) self
        self:updateConfigPrices(_self.storeItem, _self.configurations)
        local listElement = _self.configurationToListElement.weedSpotSpray
        if listElement ~= nil then
            local priceElement = listElement:getDescendantByName("price")
            _self:setConfigPrice("weedSpotSpray", _self.configurations.weedSpotSpray, priceElement, vehicle)
        end
        local priceElement = _self.configurationToListElement.pulseWidthModulation
        if priceElement ~= nil then
            local priceElement = priceElement:getDescendantByName("price")
            _self:setConfigPrice("pulseWidthModulation", _self.configurations.pulseWidthModulation, priceElement, vehicle)
        end
        return superFunc(_self, storeItem, vehicle, saleItem, ...)
    end)
    pfModule:overwriteGameFunction(BuyVehicleData, "updatePrice", function(superFunc, _self, ...)
        -- upvalues: (copy) self
        self:updateConfigPrices(_self.storeItem, _self.configurations)
        return superFunc(_self, ...)
    end)
end