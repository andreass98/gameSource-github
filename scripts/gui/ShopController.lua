ShopController = {}
local ShopController_mt = Class(ShopController)
ShopController.MAX_ATTRIBUTES_PER_ROW = 5
ShopController.COINS_CATEGORY = "COINS"
ShopController.SALES_CATEGORY = "SALES"
ShopController.EMPTY_FILENAME = "data/store/store_empty.png"
function ShopController.new()
    -- upvalues: (copy) ShopController_mt
    local self = setmetatable({}, ShopController_mt)
    self.client = nil
    self.currentMission = nil
    self.playerFarm = nil
    self.playerFarmId = 0
    self.isInitialized = false
    self.isBuying = false
    self.isSelling = false
    self.buyVehicleNow = 0
    self.buyObjectNow = 0
    self.buyHandToolNow = 0
    self.displayBrands = {}
    self.displayBrandNames = {}
    self.displayBrandCategories = {}
    self.shopCategories = {}
    self.shopDLCCategories = {}
    self.displayPacks = {}
    self.displayDLCs = {}
    self.ownedFarmItems = {}
    self.leasedFarmItems = {}
    self.currentSellStoreItem = nil
    self.currentSellItem = nil
    self.buyItemFilename = nil
    self.buyItemPrice = 0
    self.buyItemIsFreeOfCharge = false
    self.buyItemConfigurations = nil
    self.buyItemIsLeasing = false
    self.buyItemLicensePlateData = nil
    self.updateShopItemsCallback = nil
    self.updateAllItemsCallback = nil
    self.switchToConfigurationCallback = nil
    self.saleItemBoughtCallback = nil
    g_messageCenter:subscribe(BuyVehicleEvent, self.onVehicleBuyEvent, self)
    g_messageCenter:subscribe(BuyObjectEvent, self.onObjectBuyEvent, self)
    g_messageCenter:subscribe(BuyHandToolEvent, self.onHandToolBuyEvent, self)
    g_messageCenter:subscribe(SellVehicleEvent, self.onVehicleSellEvent, self)
    g_messageCenter:subscribe(SellPlaceableEvent, self.onPlaceableSellEvent, self)
    g_messageCenter:subscribe(SellHandToolEvent, self.onHandToolSellEvent, self)
    return self
end
function ShopController:reset()
    self.isInitialized = false
    self.displayBrands = {}
    self.displayBrandNames = {}
    self.displayBrandCategories = {}
    self.shopCategories = {}
    self.shopDLCCategories = {}
    self.displayPacks = {}
    self.displayDLCs = {}
    self.ownedFarmItems = {}
    self.leasedFarmItems = {}
    self.currentSellItem = nil
    self.isBuying = false
    self.isSelling = false
end
function ShopController:delete()
    g_messageCenter:unsubscribeAll(self)
end
function ShopController:addBrandForDisplay(brand)
    table.insert(self.displayBrands, {
        ["id"] = brand.index,
        ["iconFilename"] = brand.imageShopOverview,
        ["label"] = brand.title,
        ["sortValue"] = brand.name
    })
end
function ShopController.addCategoryForDisplay(_, category, categoryList, itemFilename)
    if categoryList[category.type] == nil then
        categoryList[category.type] = {}
    end
    local filename = category.image
    if filename ~= ShopController.EMPTY_FILENAME then
        itemFilename = filename
    end
    table.insert(categoryList[category.type], {
        ["id"] = category.name,
        ["iconFilename"] = itemFilename,
        ["label"] = category.title,
        ["sortValue"] = category.orderId
    })
end
function ShopController:load()
    if not self.isInitialized then
        local displayMods = {}
        local displayDLCs = {}
        for _, storeItem in ipairs(g_storeManager:getItems()) do
            if storeItem.showInStore and (#storeItem.categoryNames ~= 0 and (storeItem.species ~= StoreSpecies.PLACEABLE and (storeItem.species ~= StoreSpecies.ANIMAL and (storeItem.extraContentId == nil or g_extraContentSystem:getIsItemIdUnlocked(storeItem.extraContentId))))) then
                local brand = g_brandManager:getBrandByIndex(storeItem.brandIndex)
                if brand ~= nil and (not ({})[storeItem.brandIndex] and (storeItem.species == StoreSpecies.VEHICLE or storeItem.species == StoreSpecies.HANDTOOL)) then
                    foundBrands[storeItem.brandIndex] = true
                    if brand.name ~= "NONE" then
                        self:addBrandForDisplay(brand)
                    end
                end
                local isDLCItem = false
                if storeItem.customEnvironment ~= nil then
                    isDLCItem = true
                    if storeItem.species ~= StoreSpecies.VEHICLE then
                        isDLCItem = storeItem.species == StoreSpecies.HANDTOOL
                    end
                end
                local i = 1
                local info = #storeItem.categoryNames
                for i = i, info do
                    local category = g_storeManager:getCategoryByName(storeItem.categoryNames[i])
                    if category ~= nil then
                        local categoryName = storeItem.categoryNames[i]
                        if not ({})[categoryName] then
                            foundCategory[categoryName] = true
                            self:addCategoryForDisplay(category, self.shopCategories, storeItem.imageFilename)
                        end
                        if isDLCItem and not ({})[categoryName] then
                            foundDLCCategory[categoryName] = true
                            self:addCategoryForDisplay(category, self.shopDLCCategories, storeItem.imageFilename)
                        end
                    end
                end
                if isDLCItem and ({})[storeItem.customEnvironment] == nil then
                    local info = {
                        ["id"] = storeItem.customEnvironment,
                        ["isMod"] = storeItem.isMod,
                        ["label"] = storeItem.dlcTitle,
                        ["iconFilename"] = g_modManager:getModIconByName(storeItem.customEnvironment)
                    }
                    info.sortValue = (storeItem.isMod and "" or "    ") .. storeItem.dlcTitle
                    foundDLCs[storeItem.customEnvironment] = true
                    if storeItem.isMod then
                        table.insert(displayMods, info)
                    else
                        table.insert(displayDLCs, info)
                    end
                end
            end
        end
        if #displayDLCs > 0 then
            self.displayDLCs[utf8ToUpper(g_i18n:getText(ShopController.L10N_SYMBOL.CATEGORY_DLC))] = displayDLCs
        end
        if #displayMods > 0 then
            self.displayDLCs[utf8ToUpper(g_i18n:getText(ShopController.L10N_SYMBOL.CATEGORY_MODS))] = displayMods
        end
        local displayPacks = {}
        for storeItem, brand in pairs(g_storeManager:getPacks()) do
            table.insert(displayPacks, {
                ["id"] = brand.name,
                ["iconFilename"] = brand.image,
                ["label"] = brand.title,
                ["sortValue"] = brand.orderId
            })
        end
        self.displayPacks[utf8ToUpper(g_i18n:getText(ShopController.L10N_SYMBOL.CATEGORY_PACKS))] = displayPacks
        if Platform.hasInAppPurchases then
            self:addCategoryForDisplay(g_storeManager:getCategoryByName(ShopController.COINS_CATEGORY))
        end
        table.sort(self.displayBrands, ShopController.brandSortFunction)
        local lastLetter = nil
        for brand, isDLCItem in ipairs(self.displayBrands) do
            local info = utf8ToUpper(utf8Substr(isDLCItem.label, 0, 1))
            if lastLetter ~= info then
                self.displayBrandNames[info] = {}
                table.insert(self.displayBrandCategories, {
                    ["name"] = info
                })
                lastLetter = info
            end
            table.insert(self.displayBrandNames[info], isDLCItem)
        end
        for brand, isDLCItem in pairs(self.shopCategories) do
            table.sort(isDLCItem, ShopController.categorySortFunction)
        end
        for brand, isDLCItem in pairs(self.shopDLCCategories) do
            table.sort(isDLCItem, ShopController.categorySortFunction)
        end
        for brand, isDLCItem in pairs(self.displayPacks) do
            table.sort(isDLCItem, ShopController.categorySortFunction)
        end
        for brand, isDLCItem in pairs(self.displayDLCs) do
            table.sort(isDLCItem, ShopController.brandSortFunction)
        end
        self.isInitialized = true
    end
end
function ShopController:setClient(client)
    self.client = client
end
function ShopController:setCurrentMission(currentMission)
    self.currentMission = currentMission
    g_inAppPurchaseController:setMission(currentMission)
end
function ShopController:setPlayerFarm(playerFarm)
    self.playerFarm = playerFarm
    if playerFarm == nil then
        self.playerFarmId = 0
    else
        self.playerFarmId = playerFarm.farmId
    end
end
function ShopController:setUpdateShopItemsCallback(callback, target)
    function self.updateShopItemsCallback()
        -- upvalues: (copy) callback, (copy) target
        callback(target)
    end
end
function ShopController:setUpdateAllItemsCallback(callback, target)
    function self.updateAllItemsCallback()
        -- upvalues: (copy) callback, (copy) target
        callback(target)
    end
end
function ShopController:setSaleItemBoughtCallback(callback, target)
    function self.saleItemBoughtCallback()
        -- upvalues: (copy) callback, (copy) target
        callback(target)
    end
end
function ShopController:setSwitchToConfigurationCallback(callback, target)
    function self.switchToConfigurationCallback(...)
        -- upvalues: (copy) callback, (copy) target
        callback(target, ...)
    end
end
function ShopController.filterOwnedItemsByFarmId(ownedFarmItems, farmId)
    local filteredItems = {}
    for storeItem, itemInfos in pairs(ownedFarmItems) do
        for _, concreteItem in pairs(itemInfos.items) do
            if concreteItem:getOwnerFarmId() == farmId then
                local filteredItemInfos = filteredItems[storeItem]
                if filteredItemInfos == nil then
                    filteredItemInfos = {}
                    filteredItems[storeItem] = filteredItemInfos
                    filteredItemInfos.storeItem = storeItem
                    filteredItemInfos.numItems = 0
                    filteredItemInfos.items = {}
                end
                filteredItemInfos.numItems = filteredItemInfos.numItems + 1
                filteredItemInfos.items[concreteItem] = concreteItem
            end
        end
    end
    return filteredItems
end
function ShopController:setOwnedFarmItems(ownedFarmItems, playerFarmId)
    self.ownedFarmItems = ShopController.filterOwnedItemsByFarmId(ownedFarmItems, playerFarmId)
end
function ShopController:setLeasedFarmItems(leasedFarmItems, playerFarmId)
    self.leasedFarmItems = ShopController.filterOwnedItemsByFarmId(leasedFarmItems, playerFarmId)
end
function ShopController:update(_)
    if self.buyVehicleNow > 0 then
        if self.buyVehicleNow == 2 then
            self.buyVehicleNow = 0
            self.client:getServerConnection():sendEvent(BuyVehicleEvent.new(self.vehicleBuyData))
            if not self.buyItemIsFreeOfCharge then
                self.updateShopItemsCallback()
            end
        else
            self.buyVehicleNow = self.buyVehicleNow + 1
        end
    end
    if self.buyObjectNow > 0 then
        if self.buyObjectNow == 2 then
            self.buyObjectNow = 0
            self.client:getServerConnection():sendEvent(BuyObjectEvent.new(self.buyItemFilename, self.buyItemIsFreeOfCharge, self.playerFarmId))
            if not self.buyItemIsFreeOfCharge then
                self.updateShopItemsCallback()
            end
        else
            self.buyObjectNow = self.buyObjectNow + 1
        end
    end
    if self.buyHandToolNow > 0 then
        if self.buyHandToolNow == 2 then
            self.buyHandToolNow = 0
            self.client:getServerConnection():sendEvent(BuyHandToolEvent.new(self.handToolBuyData))
            if not self.buyItemIsFreeOfCharge then
                self.updateShopItemsCallback()
                return
            end
        else
            self.buyHandToolNow = self.buyHandToolNow + 1
        end
    end
end
function ShopController:makeDisplayItem(storeItem, realItem, configurations, saleItem, ignoreInAppPurchase)
    StoreItemUtil.loadSpecsFromXML(storeItem)
    local attributeIconProfiles = {}
    local attributeValues = {}
    if configurations == nil then
        configurations = storeItem.defaultConfigurationIds
    end
    local usedSpecs = {
        ["fillTypes"] = true,
        ["seedFillTypes"] = true,
        ["animalFoodFillTypes"] = true,
        ["prodPointInputFillTypes"] = true,
        ["prodPointOutputFillTypes"] = true,
        ["sellingStationFillTypes"] = true,
        ["buyingStationFillTypes"] = true,
        ["objectStorageFillTypes"] = true,
        ["powerConfig"] = true
    }
    local function addSpecFromVehicle(specName, specDesc, _storeItem, _realItem, _configurations, _saleItem)
        -- upvalues: (copy) usedSpecs, (copy) attributeIconProfiles, (copy) attributeValues
        if usedSpecs[specName] == nil then
            if _realItem == nil then
                if _saleItem ~= nil then
                    _configurations = _saleItem.configurations
                end
            else
                _configurations = _realItem.configurations
            end
            if specDesc.getValueFunc ~= nil then
                local value, profile = specDesc.getValueFunc(_storeItem, _realItem, _configurations, _saleItem)
                if value ~= nil then
                    local profile = profile or specDesc.profile
                    if profile ~= nil and value ~= nil then
                        table.insert(attributeIconProfiles, profile)
                        table.insert(attributeValues, value)
                    end
                    usedSpecs[specName] = true
                end
            end
        end
    end
    local function addSpec(specName)
        -- upvalues: (copy) storeItem, (copy) addSpecFromVehicle, (copy) realItem, (ref) configurations, (copy) saleItem
        if Platform.gameplay.disabledShopSpecValues[specName] ~= true then
            local desc = g_storeManager:getSpecTypeByName(specName)
            if desc ~= nil and desc.species == storeItem.species then
                addSpecFromVehicle(specName, desc, storeItem, realItem, configurations, saleItem)
                if storeItem.bundleInfo ~= nil then
                    for _, bundleItem in ipairs(storeItem.bundleInfo.bundleItems) do
                        if configurations == nil then
                            configurations = {}
                        end
                        for configName, data in pairs(bundleItem.preSelectedConfigurations) do
                            configurations[configName] = data.configValue
                        end
                        addSpecFromVehicle(specName, desc, bundleItem.item, nil, configurations, saleItem)
                    end
                end
            end
        end
    end
    addSpec("operatingTime")
    addSpec("power")
    addSpec("transmission")
    addSpec("fuel")
    addSpec("electricCharge")
    addSpec("methane")
    addSpec("maxSpeed")
    addSpec("neededPower")
    addSpec("incomePerHour")
    addSpec("capacity")
    addSpec("weight")
    addSpec("additionalWeight")
    addSpec("wheels")
    addSpec("balerBaleDensity")
    addSpec("balerBaleSizeRound")
    addSpec("balerBaleSizeSquare")
    addSpec("baleWrapperBaleSizeRound")
    addSpec("baleWrapperBaleSizeSquare")
    addSpec("inlineWrapperBaleSizeRound")
    addSpec("inlineWrapperBaleSizeSquare")
    addSpec("baleLoaderBaleSizeRound")
    addSpec("baleLoaderBaleSizeSquare")
    addSpec("woodHarvesterMaxTreeSize")
    addSpec("licensePlate")
    if self.currentMission.slotSystem:getAreSlotsVisible() then
        addSpec("slots")
        addSpec("placeableSlots")
    else
        usedSpecs.slots = true
        usedSpecs.placeableSlots = true
    end
    if realItem == nil or (realItem.propertyState == VehiclePropertyState.OWNED or saleItem ~= nil) then
        addSpec("dailyUpkeep")
    else
        usedSpecs.dailyUpkeep = true
    end
    if storeItem.lifetime ~= 0 or saleItem ~= nil then
        addSpec("age")
    end
    for _, specDesc in ipairs(g_storeManager:getSpecTypes()) do
        if usedSpecs[specDesc.name] == nil then
            addSpec(specDesc.name)
        end
    end
    local fillTypesSpec = g_storeManager:getSpecTypeByName("fillTypes")
    local seedFillTypeSpec = g_storeManager:getSpecTypeByName("seedFillTypes")
    local foodFillTypesSpec = g_storeManager:getSpecTypeByName("animalFoodFillTypes")
    local _ = g_storeManager:getSpecTypeByName("prodPointInputFillTypes")
    local specDesc = g_storeManager:getSpecTypeByName("prodPointOutputFillTypes")
    local sellingStationFillTypesSpec = g_storeManager:getSpecTypeByName("sellingStationFillTypes")
    local buyingStationFillTypesSpec = g_storeManager:getSpecTypeByName("buyingStationFillTypes")
    local objectStorageFillTypesSpec = g_storeManager:getSpecTypeByName("objectStorageFillTypes")
    local fillTypeIconFilenames = nil
    local seedTypeIconFilenames = nil
    local foodFillTypeIconFilenames = nil
    local prodPointInputFillTypeIconFilenames = nil
    local prodPointOutputFillTypeIconFilenames = nil
    local sellingStationFillTypesIconFilenames = nil
    local buyingStationFillTypesIconFilenames = nil
    local objectStorageFillTypesIconFilenames = nil
    if storeItem.bundleInfo == nil then
        fillTypeIconFilenames = (function(spec, _storeItem, _realItem, _configurations)
            local iconFilenames = {}
            if spec ~= nil then
                local fillTypeIndicesList = spec.getValueFunc(_storeItem, _realItem, _configurations)
                if fillTypeIndicesList ~= nil then
                    for _, fillTypeIndex in pairs(fillTypeIndicesList) do
                        local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
                        if fillType ~= nil then
                            table.insert(iconFilenames, fillType.hudOverlayFilename)
                        end
                    end
                end
            end
            return iconFilenames
        end)(fillTypesSpec, storeItem, realItem)
        seedTypeIconFilenames = getIconFilenamesForSpec(seedFillTypeSpec, storeItem, realItem)
        foodFillTypeIconFilenames = getIconFilenamesForSpec(foodFillTypesSpec, storeItem, realItem)
        prodPointInputFillTypeIconFilenames = getIconFilenamesForSpec(_, storeItem, realItem)
        prodPointOutputFillTypeIconFilenames = getIconFilenamesForSpec(specDesc, storeItem, realItem)
        sellingStationFillTypesIconFilenames = getIconFilenamesForSpec(sellingStationFillTypesSpec, storeItem, realItem)
        buyingStationFillTypesIconFilenames = getIconFilenamesForSpec(buyingStationFillTypesSpec, storeItem, realItem)
        objectStorageFillTypesIconFilenames = getIconFilenamesForSpec(objectStorageFillTypesSpec, storeItem, realItem)
    else
        for _, bundleItem in ipairs(storeItem.bundleInfo.bundleItems) do
            configurations = configurations == nil and {} or configurations
            for configName, data in pairs(bundleItem.preSelectedConfigurations) do
                configurations[configName] = data.configValue
            end
            fillTypeIconFilenames = getIconFilenamesForSpec(fillTypesSpec, bundleItem.item, nil, configurations)
            seedTypeIconFilenames = getIconFilenamesForSpec(seedFillTypeSpec, bundleItem.item, nil, configurations)
            foodFillTypeIconFilenames = getIconFilenamesForSpec(foodFillTypesSpec, bundleItem.item, nil, configurations)
        end
    end
    local iconFilenames = {
        ["fillTypeIconFilenames"] = fillTypeIconFilenames,
        ["seedTypeIconFilenames"] = seedTypeIconFilenames,
        ["foodFillTypeIconFilenames"] = foodFillTypeIconFilenames,
        ["prodPointInputFillTypeIconFilenames"] = prodPointInputFillTypeIconFilenames,
        ["prodPointOutputFillTypeIconFilenames"] = prodPointOutputFillTypeIconFilenames,
        ["sellingStationFillTypesIconFilenames"] = sellingStationFillTypesIconFilenames,
        ["buyingStationFillTypesIconFilenames"] = buyingStationFillTypesIconFilenames,
        ["objectStorageFillTypesIconFilenames"] = objectStorageFillTypesIconFilenames
    }
    local descriptionText = storeItem.functions and table.concat(storeItem.functions, " ") or ""
    local category = g_storeManager:getCategoryByName(storeItem.categoryName)
    local _ = nil
    local bundleItem = nil
    if g_currentMission ~= nil then
        if StoreItemUtil.getIsLeasable(storeItem) then
            _ = g_currentMission:getNumOwnedItems(storeItem, g_currentMission:getFarmId())
            if not GS_IS_MOBILE_VERSION then
                bundleItem = g_currentMission:getNumLeasedItems(storeItem, g_currentMission:getFarmId())
            end
        elseif not StoreItemUtil.getIsObject(storeItem) then
            _ = g_currentMission:getNumOfItems(storeItem, self.playerFarmId)
        end
    end
    if Platform.hasInAppPurchases and not ignoreInAppPurchase then
        for configName, data in ipairs(g_inAppPurchaseController:getProducts()) do
            if data:isa(IAProductStoreItem) and (data:getIsStoreItemOfProduct(storeItem) and not data:getHasBeenBought()) then
                return data:getDisplayItem(storeItem, realItem, attributeIconProfiles, attributeValues, iconFilenames, descriptionText, category.orderId, _, bundleItem, saleItem)
            end
        end
    end
    if Platform.hasInAppPurchases and not ignoreInAppPurchase then
        for configName, data in ipairs(g_inAppPurchaseController:getProducts()) do
            if data:isa(IAProductStoreItem) and (data:getIsStoreItemOfProduct(storeItem) and not data:getHasBeenBought()) then
                return data:getDisplayItem(storeItem, realItem, attributeIconProfiles, attributeValues, iconFilenames, descriptionText, category.orderId, _, bundleItem, saleItem)
            end
        end
    end
    return ShopDisplayItem.new(storeItem, realItem, attributeIconProfiles, attributeValues, iconFilenames, descriptionText, category.orderId, _, bundleItem, saleItem)
end
function ShopController:updateDisplayItems(displayItems)
    local newDisplayItems = {}
    for _, oldDisplayItem in ipairs(displayItems) do
        local storeItem = g_storeManager:getItemByXMLFilename(oldDisplayItem.storeItem.xmlFilename)
        if storeItem == nil then
            table.insert(newDisplayItems, oldDisplayItem)
        else
            local newDisplayItem = self:makeDisplayItem(storeItem, nil)
            table.insert(newDisplayItems, newDisplayItem)
        end
    end
    return newDisplayItems
end
function ShopController:getOwnedItems()
    local displayItems = {}
    for storeItem, itemInfos in pairs(self.ownedFarmItems) do
        for concreteItem in pairs(itemInfos.items) do
            if storeItem.canBeSold then
                local displayItem = self:makeDisplayItem(storeItem, concreteItem)
                table.insert(displayItems, displayItem)
            end
        end
    end
    table.sort(displayItems, ShopController.displayItemSortFunction)
    return displayItems
end
function ShopController:getLeasedItems()
    local displayItems = {}
    for storeItem, itemInfos in pairs(self.leasedFarmItems) do
        for concreteItem in pairs(itemInfos.items) do
            local displayItem = self:makeDisplayItem(storeItem, concreteItem)
            table.insert(displayItems, displayItem)
        end
    end
    table.sort(displayItems, ShopController.displayItemSortFunction)
    return displayItems
end
function ShopController:getOwnedFarmItems()
    return self.ownedFarmItems
end
function ShopController:getLeasedFarmItems()
    return self.leasedFarmItems
end
function ShopController:getBrands()
    return self.displayBrands
end
function ShopController:getBrandCategories()
    return self.displayBrandCategories
end
function ShopController:getBrandNames()
    return self.displayBrandNames
end
function ShopController:getShopCategories()
    return self.shopCategories
end
function ShopController:getShopDLCCategories()
    return self.shopDLCCategories
end
function ShopController:getVehicleCategories()
    return self.displayVehicleCategories
end
function ShopController:getToolCategories()
    return self.displayToolCategories
end
function ShopController:getObjectCategories()
    return self.displayObjectCategories
end
function ShopController:getPlaceableCategories()
    return self.displayPlaceableCategories
end
function ShopController:getItemsByBrand(brandId)
    local items = {}
    local salesCategory = g_storeManager:getCategoryByName("sales")
    local brand = g_brandManager:getBrandByIndex(brandId)
    for _, storeItem in pairs(g_storeManager:getItems()) do
        local sale = nil
        if g_currentMission ~= nil then
            local isUnlocked, displayItem
            isUnlocked, displayItem, sale = g_currentMission.economyManager:getBuyPrice(storeItem)
        end
        local isUnlocked = true
        if storeItem.extraContentId ~= nil then
            isUnlocked = g_extraContentSystem:getIsItemIdUnlocked(storeItem.extraContentId)
        end
        if not storeItem.isBundleItem and (isUnlocked and (storeItem.showInStore and (storeItem.brandIndex == brandId or sale ~= nil and brand.title == salesCategory.title))) and (storeItem.species == StoreSpecies.VEHICLE or storeItem.species == StoreSpecies.HANDTOOL) then
            local displayItem = self:makeDisplayItem(storeItem)
            table.insert(items, displayItem)
        end
    end
    return items
end
function ShopController:getItemsByStoreItems(storeItems)
    local items = {}
    for _, storeItem in ipairs(storeItems) do
        local displayItem = self:makeDisplayItem(storeItem)
        table.insert(items, displayItem)
    end
    return items
end
function ShopController:getItemsByCategory(categoryName, onlyDLCItems)
    if categoryName == ShopController.COINS_CATEGORY then
        return self:getCoinItems()
    end
    if categoryName == ShopController.SALES_CATEGORY then
        return self:getSaleItems()
    end
    local items = {}
    for _, storeItem in pairs(g_storeManager:getItems()) do
        local isUnlocked = true
        if storeItem.extraContentId ~= nil then
            isUnlocked = g_extraContentSystem:getIsItemIdUnlocked(storeItem.extraContentId)
        end
        local isDLCItem = false
        if storeItem.customEnvironment ~= nil then
            isDLCItem = storeItem.species == StoreSpecies.VEHICLE
        end
        if not storeItem.isBundleItem and (isUnlocked and (storeItem.showInStore and (storeItem.species == StoreSpecies.VEHICLE or storeItem.species == StoreSpecies.HANDTOOL))) then
            local i = 1
            for i = i, #storeItem.categoryNames do
                if categoryName == storeItem.categoryNames[i] and (not onlyDLCItems or isDLCItem) then
                    local displayItem = self:makeDisplayItem(storeItem)
                    table.insert(items, displayItem)
                    break
                end
            end
        end
    end
    return items
end
function ShopController:getSaleItems()
    local list = {}
    local items = g_currentMission.vehicleSaleSystem:getItems()
    for _, item in ipairs(items) do
        local displayItem = self:makeDisplayItem(g_storeManager:getItemByXMLFilename(item.xmlFilename), nil, item.configurations, item)
        table.insert(list, displayItem)
    end
    return list
end
function ShopController:getItemsByCategoryOwnedOrLeased(categoryName, owned, leased)
    if categoryName == ShopController.COINS_CATEGORY then
        return self:getCoinItems()
    end
    local input = {}
    if owned then
        input = self.ownedFarmItems
    elseif leased then
        input = self.leasedFarmItems
    end
    local items = {}
    for storeItem, itemInfos in pairs(input) do
        local add = storeItem.canBeSold and (storeItem.showInStore or storeItem.isBundleItem) and storeItem.categoryName == categoryName and true or false
        if add then
            if owned then
                add = self.ownedFarmItems[storeItem] ~= nil
            elseif leased then
                add = self.leasedFarmItems[storeItem] ~= nil
            end
        end
        if add then
            for concreteItem in pairs(itemInfos.items) do
                local displayItem = self:makeDisplayItem(storeItem, concreteItem)
                table.insert(items, displayItem)
            end
        end
    end
    table.sort(items, ShopController.displayItemSortFunction)
    return items
end
function ShopController:getOwnedCategories()
    local output = {}
    local categories = {}
    for storeItem, itemInfos in pairs(self.ownedFarmItems) do
        if storeItem.canBeSold and (storeItem.showInStore or storeItem.isBundleItem) and (storeItem.species == StoreSpecies.VEHICLE and categories[storeItem.categoryName] == nil) then
            local imageFilename = storeItem.imageFilename
            for _, concreteItem in pairs(itemInfos.items) do
                if concreteItem.getImageFilename ~= nil then
                    imageFilename = concreteItem:getImageFilename()
                end
            end
            categories[storeItem.categoryName] = imageFilename
        end
    end
    for storeItem, itemInfos in pairs(categories) do
        local imageFilename = g_storeManager:getCategoryByName(storeItem)
        if imageFilename ~= nil then
            table.insert(output, {
                ["id"] = imageFilename.name,
                ["iconFilename"] = itemInfos,
                ["label"] = imageFilename.title,
                ["sortValue"] = imageFilename.orderId
            })
        end
    end
    table.sort(output, ShopController.categorySortFunction)
    return output
end
function ShopController:getLeasedCategories()
    local output = {}
    local categories = {}
    for storeItem, _ in pairs(self.leasedFarmItems) do
        categories[storeItem.categoryName] = storeItem.imageFilename
    end
    for storeItem, _ in pairs(categories) do
        local category = g_storeManager:getCategoryByName(storeItem)
        if category ~= nil then
            table.insert(output, {
                ["id"] = category.name,
                ["iconFilename"] = _,
                ["label"] = category.title,
                ["sortValue"] = category.orderId
            })
        end
    end
    return output
end
function ShopController:getDLCCategories()
    return self.displayDLCs
end
function ShopController:getDLCCategoryTypes()
    return {
        {
            ["name"] = utf8ToUpper(g_i18n:getText(ShopController.L10N_SYMBOL.CATEGORY_DLC))
        },
        {
            ["name"] = utf8ToUpper(g_i18n:getText(ShopController.L10N_SYMBOL.CATEGORY_MODS))
        }
    }
end
function ShopController:getStorePacks()
    return self.displayPacks
end
function ShopController:getStorePackTypes()
    return {
        {
            ["name"] = utf8ToUpper(g_i18n:getText(ShopController.L10N_SYMBOL.CATEGORY_PACKS))
        }
    }
end
function ShopController:getItemsByPack(packName)
    local items = {}
    local packItems = g_storeManager:getPackItems(packName)
    if packItems == nil then
        return items
    end
    local i = 1
    for i = i, #packItems do
        local storeItem = g_storeManager:getItemByXMLFilename(packItems[i])
        if storeItem == nil then
            Logging.warning("Vehicle \'%s\' not found! Ignoring it for vehicle pack \'%s\'.", packItems[i], packName)
        elseif not storeItem.isBundleItem and storeItem.showInStore then
            local displayItem = self:makeDisplayItem(storeItem)
            table.insert(items, displayItem)
        end
    end
    return items
end
function ShopController:getItemsByDLC(dlcId)
    local items = {}
    for _, storeItem in pairs(g_storeManager:getItems()) do
        if not storeItem.isBundleItem and (storeItem.showInStore and (storeItem.customEnvironment == dlcId and (storeItem.species == StoreSpecies.VEHICLE or (storeItem.species == StoreSpecies.HANDTOOL or storeItem.species == StoreSpecies.OBJECT)))) then
            local displayItem = self:makeDisplayItem(storeItem)
            table.insert(items, displayItem)
        end
    end
    return items
end
function ShopController:getItemsWithFilenames(filenames)
    local items = {}
    for _, xmlFilename in ipairs(filenames) do
        local storeItem = g_storeManager:getItemByXMLFilename(xmlFilename)
        if storeItem ~= nil and (not storeItem.isBundleItem and storeItem.showInStore) then
            local displayItem = self:makeDisplayItem(storeItem)
            table.insert(items, displayItem)
        end
    end
    return items
end
function ShopController:getItemsFromCombinations(combinations)
    local items = {}
    for _, combinationData in ipairs(combinations) do
        local combinationItems = g_storeManager:getItemsByCombinationData(combinationData)
        for _, item in ipairs(combinationItems) do
            if not ({})[item.storeItem] then
                local displayItem = self:makeDisplayItem(item.storeItem, nil, item.configData)
                displayItem.configurations = item.configData
                alreadyAddedStoreItems[item.storeItem] = true
                table.insert(items, displayItem)
            end
        end
    end
    return items
end
function ShopController:canBeBought(storeItem, price)
    local enoughMoney = true
    if self.currentMission ~= nil then
        enoughMoney = price <= g_currentMission:getMoney()
    end
    local enoughSlots = self.currentMission.slotSystem:hasEnoughSlots(storeItem)
    if enoughMoney then
        if not enoughSlots then
            InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_SLOTS), DialogElement.TYPE_WARNING)
        end
    else
        InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY), DialogElement.TYPE_WARNING)
    end
    local enoughItems = true
    if storeItem.maxItemCount ~= nil then
        enoughItems = false
        if storeItem.maxItemCount ~= nil then
            enoughItems = self.currentMission:getNumOfItems(storeItem, self.playerFarmId) < storeItem.maxItemCount
        end
    end
    if not enoughItems then
        InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_TOO_MANY_PLACEABLES), DialogElement.TYPE_WARNING)
    end
    if enoughSlots then
        if not enoughMoney then
            enoughItems = enoughMoney
        end
    else
        enoughItems = enoughSlots
    end
    return enoughItems
end
function ShopController:buy(storeItem, saleItem, isFreeOfCharge, configurations)
    if self.isSelling then
        return
    else
        local price = 0
        if not isFreeOfCharge then
            if saleItem == nil then
                price = self.currentMission.economyManager:getBuyPrice(storeItem)
            else
                price = saleItem.price
            end
        end
        if StoreItemUtil.getIsVehicle(storeItem) then
            self:buyVehicle(storeItem, saleItem, price, isFreeOfCharge, configurations)
        elseif self:canBeBought(storeItem, price) then
            if StoreItemUtil.getIsObject(storeItem) then
                self:buyObject(storeItem, price, isFreeOfCharge)
                return
            end
            if StoreItemUtil.getIsHandTool(storeItem) then
                self:buyHandTool(storeItem, price, isFreeOfCharge)
            end
        end
    end
end
function ShopController:buyVehicle(vehicleStoreItem, saleItem, price, isFreeOfCharge, configurations)
    self.buyItemFilename = vehicleStoreItem.xmlFilename
    self.buyItemPrice = price
    self.buyItemIsFreeOfCharge = isFreeOfCharge or false
    self.buyItemConfigurations = nil
    self.buyItemLicensePlateData = nil
    self.buyItemIsLeasing = false
    self.buyItemSaleItem = saleItem
    if StoreItemUtil.getCanBeShownInConfigScreen(vehicleStoreItem) and Platform.hasConfigScreen then
        self.switchToConfigurationCallback(vehicleStoreItem, saleItem, configurations)
    elseif self:canBeBought(vehicleStoreItem, price) then
        self:finalizeBuy()
    end
end
function ShopController:onYesNoBuyObject(yes)
    if yes then
        self.isBuying = true
        self.buyObjectNow = 1
    end
end
function ShopController:buyObject(objectStoreItem, price, isFreeOfCharge)
    local text = string.format(g_i18n:getText(ShopController.L10N_SYMBOL.BUY_CONFIRMATION), g_i18n:formatMoney(price, 0, true, true))
    YesNoDialog.show(self.onYesNoBuyObject, self, text)
    self.buyItemFilename = objectStoreItem.xmlFilename
    self.buyItemPrice = price
    self.buyItemIsFreeOfCharge = isFreeOfCharge
    self.buyItemConfigurations = nil
    self.buyItemLicensePlateData = nil
    self.buyItemIsLeasing = false
end
function ShopController:onYesNoBuyHandtool(yes)
    if yes then
        self.isBuying = true
        self.buyHandToolNow = 1
    end
end
function ShopController:buyHandTool(handToolStoreItem, price, _)
    local handToolBuyData = BuyHandToolData.new()
    handToolBuyData:setStoreItem(handToolStoreItem)
    handToolBuyData:setOwnerFarmId(self.playerFarmId)
    handToolBuyData:setPrice(price)
    if handToolBuyData:isValid() then
        handToolBuyData:updatePrice()
        self.handToolBuyData = handToolBuyData
        local text = string.format(g_i18n:getText(ShopController.L10N_SYMBOL.BUY_CONFIRMATION), g_i18n:formatMoney(price, 0, true, true))
        YesNoDialog.show(self.onYesNoBuyHandtool, self, text)
    end
end
function ShopController:sell(storeItem, concreteItem, isDirectSell)
    self.isSelling = true
    self.currentSellStoreItem = storeItem
    self.currentSellItem = concreteItem
    if StoreItemUtil.getIsPlaceable(storeItem) then
        if self.currentMission:getNumOwnedItems(storeItem, g_currentMission:getFarmId()) == 1 then
            local canBeSold, warning = concreteItem:canBeSold()
            if warning == nil then
                self:sellPlaceableWarningInfoClickOk(true)
                return
            elseif canBeSold then
                YesNoDialog.show(self.sellPlaceableWarningInfoClickOk, self, warning, nil, g_i18n:getText("button_ok"), g_i18n:getText("button_cancel"))
            else
                InfoDialog.show(warning, nil, nil, DialogElement.TYPE_WARNING)
                self.isSelling = false
            end
        end
        if self.currentMission:getNumOwnedItems(storeItem, g_currentMission:getFarmId()) > 1 then
            self:onSellCallback(true)
            return
        end
    else
        local warning
        if concreteItem == ShopDisplayItem.NO_CONCRETE_ITEM then
            warning = self.currentMission.economyManager:getSellPrice(storeItem)
        else
            warning = self.currentMission.economyManager:getSellPrice(concreteItem)
        end
        if isDirectSell then
        end
        SellItemDialog.show(self.onSellCallback, self, concreteItem, warning, storeItem, isDirectSell)
    end
end
function ShopController:sellPlaceableWarningInfoClickOk(yes)
    if yes then
        SellItemDialog.show(self.onSellCallback, self, self.currentSellItem, g_currentMission.economyManager:getSellPrice(self.currentSellItem))
    end
end
function ShopController:onSellCallback(yes, isDirectSell)
    self.isSelling = false
    if yes then
        self:onSellItem(self.currentSellStoreItem, self.currentSellItem, isDirectSell)
        self.currentSellItem = nil
    end
end
function ShopController:onSellItem(storeItem, concreteItem, isDirectSell)
    if self.isSelling then
        return
    elseif StoreItemUtil.getIsPlaceable(storeItem) then
        self:sellPlaceable(storeItem, concreteItem)
        return
    elseif StoreItemUtil.getIsHandTool(storeItem) then
        self:sellHandTool(concreteItem)
    else
        self:sellVehicle(concreteItem, isDirectSell)
    end
end
function ShopController:sellHandTool(handTool)
    self.isSelling = true
    if self.currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE) then
        local text = g_i18n:getText(ShopController.L10N_SYMBOL.SELLING_VEHICLE)
        MessageDialog.show(text)
        if NetworkUtil.getObjectId(handTool) == nil then
            self:onHandToolSellFailed(SellVehicleEvent.SELL_NO_PERMISSION)
        else
            self.client:getServerConnection():sendEvent(SellHandToolEvent.new(handTool))
        end
    else
        self:onHandToolSellFailed(SellVehicleEvent.SELL_NO_PERMISSION)
        return
    end
end
function ShopController:sellVehicle(vehicle, isDirectSell)
    self.isSelling = true
    if self.currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE) and vehicle == self.currentMission.controlledVehicle then
        g_localPlayer:leaveVehicle()
    end
    if vehicle.propertyState == VehiclePropertyState.OWNED then
        local text = g_i18n:getText(ShopController.L10N_SYMBOL.SELLING_VEHICLE)
        MessageDialog.show(text)
    else
        local text = g_i18n:getText(ShopController.L10N_SYMBOL.RETURNING_VEHICLE)
        MessageDialog.show(text)
    end
    if NetworkUtil.getObjectId(vehicle) == nil then
        self:onVehicleSellFailed(vehicle.propertyState == VehiclePropertyState.OWNED, SellVehicleEvent.SELL_NO_PERMISSION)
    else
        self.client:getServerConnection():sendEvent(SellVehicleEvent.new(vehicle, isDirectSell and EconomyManager.DIRECT_SELL_MULTIPLIER or 1, isDirectSell))
    end
end
function ShopController:setConfigurations(vehicleBuyData)
    if vehicleBuyData:isValid() then
        vehicleBuyData:updatePrice()
        self.vehicleBuyData = vehicleBuyData
        g_currentMission:setLastCreatedLicensePlate(vehicleBuyData.licensePlateData)
        self:finalizeBuy()
    end
end
function ShopController:finalizeBuy()
    self.isBuying = true
    self.buyVehicleNow = 1
    local text = g_i18n:getText(ShopController.L10N_SYMBOL.BUYING_VEHICLE)
    if self.buyItemIsLeasing then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.LEASING_VEHICLE)
    end
    MessageDialog.show(text)
end
function ShopController:onHandToolSellEvent(errorCode)
    if errorCode == SellHandToolEvent.STATE_SUCCESS then
        self:onHandToolSold()
    else
        self:onHandToolSellFailed(errorCode)
    end
end
function ShopController:onHandToolSold()
    g_gui:closeAllDialogs()
    InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_SUCCESS), self.onSoldCallback, self, DialogElement.TYPE_INFO)
end
function ShopController:onHandToolSellFailed(state)
    g_gui:closeAllDialogs()
    local text = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_FAILED)
    if state == SellHandToolEvent.STATE_IN_USE then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_IN_USE)
    elseif state == SellHandToolEvent.STATE_NO_PERMISSION then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_NO_PERMISSION)
    end
    InfoDialog.show(text, self.onSoldCallback, self, DialogElement.TYPE_WARNING)
end
function ShopController:onVehicleBuyEvent(errorCode, leaseVehicle, price)
    if errorCode == BuyVehicleEvent.STATE_SUCCESS then
        self:onVehicleBought(leaseVehicle, price)
    else
        self:onVehicleBuyFailed(leaseVehicle, errorCode)
    end
end
function ShopController:onVehicleBought(leaseVehicle, _)
    g_gui:closeAllDialogs()
    if leaseVehicle then
        InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.LEASE_VEHICLE_SUCCESS), self.onBoughtCallback, self, DialogElement.TYPE_INFO)
    else
        InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_SUCCESS), self.onBoughtCallback, self, DialogElement.TYPE_INFO)
    end
    self.updateShopItemsCallback()
end
function ShopController:onVehicleBuyFailed(_, errorCode)
    g_gui:closeAllDialogs()
    local text
    if errorCode == BuyVehicleEvent.STATE_NO_SPACE then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NO_SPACE)
    elseif errorCode == BuyVehicleEvent.STATE_NO_PERMISSION then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_NO_PERMISSION)
    elseif errorCode == BuyVehicleEvent.STATE_NOT_ENOUGH_MONEY then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY)
    elseif errorCode == BuyVehicleEvent.STATE_TOO_MANY_BALES then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_TOO_MANY_BALES)
    elseif errorCode == BuyVehicleEvent.STATE_TOO_MANY_PALLETS then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_TOO_MANY_PALLETS)
    else
        text = g_i18n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_FAILED_TO_LOAD)
    end
    InfoDialog.show(text, self.onBoughtCallback, self, DialogElement.TYPE_WARNING)
end
function ShopController:onObjectBuyEvent(errorCode, price)
    if errorCode == BuyObjectEvent.STATE_SUCCESS then
        self:onObjectBought(price)
    else
        self:onObjectBuyFailed(errorCode)
    end
end
function ShopController:onObjectBought(price)
    g_gui:closeAllDialogs()
    self.currentMission:addMoneyChange(-price, self.playerFarmId, MoneyType.SHOP_VEHICLE_BUY)
    InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.BUY_OBJECT_SUCCESS), self.onBoughtCallback, self, DialogElement.TYPE_INFO)
end
function ShopController:onObjectBuyFailed(errorCode)
    g_gui:closeAllDialogs()
    if errorCode == BuyObjectEvent.STATE_NO_SPACE then
        InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NO_SPACE), self.onBoughtCallback, self, DialogElement.TYPE_WARNING)
        return
    elseif errorCode == BuyObjectEvent.STATE_LIMIT_REACHED then
        InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_TOO_MANY_PALLETS), self.onBoughtCallback, self, DialogElement.TYPE_WARNING)
        return
    elseif errorCode == BuyObjectEvent.STATE_NOT_ENOUGH_MONEY then
        InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY), self.onBoughtCallback, self, DialogElement.TYPE_WARNING)
    else
        InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.LOAD_OBJECT_FAILED), self.onBoughtCallback, self, DialogElement.TYPE_WARNING)
    end
end
function ShopController:onHandToolBuyEvent(errorCode, price, wasPickedUp)
    if errorCode == BuyHandToolEvent.STATE_SUCCESS then
        self:onHandToolBought(price, wasPickedUp)
    else
        self:onHandToolBuyFailed(errorCode)
    end
end
function ShopController:onHandToolBought(_, wasPickedUp)
    g_gui:closeAllDialogs()
    if wasPickedUp then
        InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.BUY_HANDTOOL_PICKED_UP), self.onBoughtCallback, self, DialogElement.TYPE_INFO)
    else
        InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.BUY_HANDTOOL_INVENTORY), self.onBoughtCallback, self, DialogElement.TYPE_INFO)
    end
end
function ShopController:onHandToolBuyFailed(errorCode)
    g_gui:closeAllDialogs()
    local text = g_i18n:getText(ShopController.L10N_SYMBOL.LOAD_OBJECT_FAILED)
    if errorCode == BuyHandToolEvent.STATE_NO_PERMISSION then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_NO_PERMISSION)
    elseif errorCode == BuyHandToolEvent.STATE_NOT_ENOUGH_MONEY then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY)
    end
    InfoDialog.show(text, self.onBoughtCallback, self, DialogElement.TYPE_WARNING)
end
function ShopController:onVehicleSellEvent(isDirectSell, errorCode, sellPrice, isOwned)
    g_gui:closeAllDialogs()
    if isDirectSell then
        self:onSoldCallback()
        return
    elseif errorCode == SellVehicleEvent.SELL_SUCCESS then
        self:onVehicleSold(sellPrice, isOwned)
    else
        self:onVehicleSellFailed(isOwned, errorCode)
    end
end
function ShopController:onVehicleSold(_, isOwned)
    g_gui:closeAllDialogs()
    local text = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_SUCCESS)
    if not isOwned then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_SUCCESS)
    end
    InfoDialog.show(text, self.onSoldCallback, self, DialogElement.TYPE_INFO)
end
function ShopController:onVehicleSellFailed(isOwned, errorCode)
    g_gui:closeAllDialogs()
    local text
    if isOwned then
        if errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
            text = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_NO_PERMISSION)
        elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
            text = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_IN_USE)
        elseif errorCode == SellVehicleEvent.SELL_LAST_VEHICLE then
            text = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_LAST_VEHICLE_FAILED)
        else
            text = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_FAILED)
        end
    elseif errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_NO_PERMISSION)
    elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_IN_USE)
    elseif errorCode == SellVehicleEvent.SELL_LAST_VEHICLE then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.RETURN_LAST_VEHICLE_FAILED)
    else
        text = g_i18n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_FAILED)
    end
    InfoDialog.show(text, self.onSoldCallback, self, DialogElement.TYPE_WARNING)
end
function ShopController:onPlaceableSellEvent(errorCode, sellPrice, showSoldPopup)
    if errorCode == SellPlaceableEvent.STATE_SUCCESS then
        if showSoldPopup then
            self:onPlaceableSold(sellPrice)
            return
        end
    else
        self:onPlaceableSellFailed(errorCode)
    end
end
function ShopController:onPlaceableSold(_)
    g_gui:closeAllDialogs()
    InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.SELL_OBJECT_SUCCESS), self.onSoldCallback, self, DialogElement.TYPE_INFO)
end
function ShopController:onPlaceableSellFailed(state)
    g_gui:closeAllDialogs()
    local text = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_OBJECT_FAILED)
    if state == SellPlaceableEvent.STATE_IN_USE then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_OBJECT_IN_USE)
    elseif state == SellPlaceableEvent.STATE_NO_PERMISSION then
        text = g_i18n:getText(ShopController.L10N_SYMBOL.NO_PERMISSION)
    end
    InfoDialog.show(text, self.onSoldCallback, self, DialogElement.TYPE_WARNING)
end
function ShopController:onBoughtCallback()
    self.isBuying = false
    self.updateAllItemsCallback()
    if self.buyItemSaleItem ~= nil then
        self.saleItemBoughtCallback()
    end
end
function ShopController:onSoldCallback()
    self.isSelling = false
    self.updateAllItemsCallback()
end
function ShopController.brandSortFunction(item1, item2)
    return utf8ToUpper(item1.sortValue) < utf8ToUpper(item2.sortValue)
end
function ShopController.categorySortFunction(item1, item2)
    return item1.sortValue < item2.sortValue
end
function ShopController.displayItemSortFunction(item1, item2)
    if item1.orderValue == item2.orderValue then
        local sellPrice1 = item1:getSellPrice()
        local sellPrice2 = item2:getSellPrice()
        if sellPrice1 == sellPrice2 then
            return item1:getSortId() > item2:getSortId()
        else
            return sellPrice2 < sellPrice1
        end
    else
        return item1.orderValue < item2.orderValue
    end
end
function ShopController:getCoinItems()
    local list = {}
    if not g_inAppPurchaseController:getIsAvailable() then
        return list
    end
    for _, product in ipairs(g_inAppPurchaseController:getProducts()) do
        if product:isa(IAProductCoins) then
            table.insert(list, product:getDisplayItem(nil))
        end
    end
    return list
end
ShopController.PROFILE = {
    ["ICON_OWNED"] = "shopListAttributeIconOwned",
    ["ICON_LEASED"] = "shopListAttributeIconLeased"
}
ShopController.L10N_SYMBOL = {
    ["BUY_CONFIRMATION"] = "shop_doYouWantToBuy",
    ["BUY_ALREADY_OWNED"] = "shop_messageAlreadyOwned",
    ["CANNOT_SELL_TOUR_ITEMS"] = "shop_messageTourItemsCannotBeSold",
    ["RETURNING_VEHICLE"] = "shop_messageReturningVehicle",
    ["SELLING_VEHICLE"] = "shop_messageSellingVehicle",
    ["LEASING_VEHICLE"] = "shop_messageLeasingVehicle",
    ["BUYING_VEHICLE"] = "shop_messageBuyingVehicle",
    ["LEASE_VEHICLE_SUCCESS"] = "shop_messageLeasingReady",
    ["BUY_VEHICLE_SUCCESS"] = "shop_messagePurchaseReady",
    ["BUY_VEHICLE_FAILED_TO_LOAD"] = "shop_messageFailedToLoadVehicle",
    ["BUY_VEHICLE_NO_PERMISSION"] = "shop_messageNoPermissionToBuyVehicleText",
    ["BUY_OBJECT_SUCCESS"] = "shop_messageGardenCenterPurchaseReady",
    ["WARNING_NO_SPACE"] = "shop_messageNoSpace",
    ["WARNING_NOT_ENOUGH_SLOTS"] = "shop_messageNotEnoughSlotsToBuy",
    ["WARNING_NOT_ENOUGH_MONEY"] = "shop_messageNotEnoughMoneyToBuy",
    ["WARNING_TOO_MANY_BALES"] = "warning_tooManyBales",
    ["WARNING_TOO_MANY_PALLETS"] = "warning_tooManyPallets",
    ["WARNING_TOO_MANY_PLACEABLES"] = "warning_tooManyPlaceables",
    ["BUY_HANDTOOL_INVENTORY"] = "shop_messageBoughtHandToolInventory",
    ["BUY_HANDTOOL_PICKED_UP"] = "shop_messageBoughtHandToolPickedUp",
    ["LOAD_OBJECT_FAILED"] = "shop_messageFailedToLoadObject",
    ["RETURN_VEHICLE_SUCCESS"] = "shop_messageReturnedVehicle",
    ["RETURN_VEHICLE_NO_PERMISSION"] = "shop_messageNoPermissionToReturnVehicleText",
    ["RETURN_VEHICLE_IN_USE"] = "shop_messageReturnVehicleInUse",
    ["RETURN_VEHICLE_FAILED"] = "shop_messageFailedToReturnVehicle",
    ["RETURN_LAST_VEHICLE_FAILED"] = "shop_messageFailedToReturnLastVehicleText",
    ["SELL_VEHICLE_SUCCESS"] = "shop_messageSoldVehicle",
    ["SELL_VEHICLE_FAILED"] = "shop_messageFailedToSellVehicle",
    ["SELL_VEHICLE_IN_USE"] = "shop_messageSellVehicleInUse",
    ["SELL_VEHICLE_NO_PERMISSION"] = "shop_messageNoPermissionToSellVehicleText",
    ["SELL_LAST_VEHICLE_FAILED"] = "shop_messageFailedToSellLastVehicleText",
    ["SELL_OBJECT_SUCCESS"] = "shop_messageSoldObject",
    ["SELL_OBJECT_FAILED"] = "shop_messageFailedToSellObject",
    ["SELL_OBJECT_IN_USE"] = "shop_messageObjectInUse",
    ["NO_PERMISSION"] = "shop_messageNoPermissionGeneral",
    ["CATEGORY_DLC"] = "modHub_dlc",
    ["CATEGORY_MODS"] = "button_mods",
    ["CATEGORY_PACKS"] = "ui_storePacks"
}