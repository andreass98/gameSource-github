ShopMenu = {}
local ShopMenu_mt = Class(ShopMenu, TabbedMenuWithDetails)
ShopMenu.LIST_CELL_NAME_CATEGORY = "category"
ShopMenu.LIST_CELL_NAME_BRAND = "brand"
ShopMenu.LIST_CELL_NAME_PACKS = "packs"
ShopMenu.LIST_CELL_NAME_DLC = "dlc"
ShopMenu.LIST_EMPTY_CELL_NAME_CATEGORY = "categoryEmpty"
ShopMenu.LIST_EMPTY_CELL_NAME_BRAND = "brandEmpty"
ShopMenu.LIST_EMPTY_CELL_NAME_DLC = "dlcEmpty"
ShopMenu.SLOTS_USAGE_CRITICAL_THRESHOLD = 0.9
function ShopMenu.register()
    ShopCategoriesFrame.register()
    ShopItemsFrame.register()
    ShopOthersFrame.register()
    local shopMenu = ShopMenu.new()
    g_gui:loadGui("dataS/gui/ShopMenu.xml", "ShopMenu", shopMenu)
    return shopMenu
end
function ShopMenu.new(target, customMt)
    -- upvalues: (copy) ShopMenu_mt
    local self = TabbedMenuWithDetails.new(target, customMt or ShopMenu_mt)
    self.performBackgroundBlur = true
    self.gameState = GameState.MENU_SHOP
    self.restorePageIndex = 2
    self.useStack = true
    self.playerFarm = nil
    self.playerFarmId = 0
    self.currentUserId = -1
    self.paused = false
    self.client = nil
    self.server = nil
    self.isMasterUser = false
    self.isServer = false
    self.selectedDisplayElement = nil
    self.currentDisplayItems = nil
    self.defaultMenuButtonInfo = {}
    self.shopMenuButtonInfo = {}
    self.buyButtonInfo = {}
    self.shopDetailsButtonInfo = {}
    self.shopDetailsButtonInfoWithCombinations = {}
    self.itemDetailsButtonInfo = {}
    self.garageMenuButtonInfo = {}
    self.switchOwnedLeasedButtonInfo = {}
    self.sellButtonInfo = {}
    self.showCategoriesButtonInfo = {}
    self.showDLCsButtonInfo = {}
    self.showDLCVehiclesButtonInfo = {}
    self.backButtonInfo = {}
    g_shopConfigScreen:setRequestExitCallback(self:makeSelfCallback(self.exitMenuFromConfig))
    g_messageCenter:subscribe(MessageType.STORE_ITEMS_RELOADED, self.onStoreItemsReloaded, self)
    g_messageCenter:subscribe(MessageType.CURRENT_MISSION_LOADED, self.onMissionLoaded, self)
    self.showDLCsPage = true
    return self
end
function ShopMenu.createFromExistingGui(gui, guiName)
    ShopCategoriesFrame.createFromExistingGui(g_gui.frames.shopCategories.target, "ShopCategoriesFrame")
    ShopItemsFrame.createFromExistingGui(g_gui.frames.shopItems.target, "ShopItemsFrame")
    ShopOthersFrame.createFromExistingGui(g_gui.frames.shopOthers.target, "ShopOthersFrame")
    local newGui = ShopMenu.new()
    g_gui.guis.ShopMenu:delete()
    g_gui.guis.ShopMenu.target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    newGui.client = gui.client
    newGui.server = gui.server
    newGui:onLoadMapFinished()
    newGui:setPlayerFarm(gui.playerFarm)
    newGui:setCurrentUserId(gui.currentUserId)
    return newGui
end
function ShopMenu:setClient(client)
    self.client = client
    g_shopController:setClient(client)
end
function ShopMenu:setServer(server)
    self.server = server
    self.isServer = server ~= nil
end
function ShopMenu:onVehicleSaleChanged()
    self.pageUsedSale:setDisplayItems(g_shopController:getItemsByCategory(ShopController.SALES_CATEGORY))
end
function ShopMenu:onMissionLoaded()
    local vehicleFilename = StartParams.getValue("viewVehicleFilename")
    if vehicleFilename ~= nil then
        self:viewVehicle(vehicleFilename)
    end
end
function ShopMenu:onLoadMapFinished()
    self:initializePages()
end
function ShopMenu:initializePages()
    g_inAppPurchaseController:load()
    self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)
    g_shopController:setCurrentMission(g_currentMission)
    g_shopController:setClient(g_client)
    g_shopController:setUpdateShopItemsCallback(self:makeSelfCallback(self.updateCurrentDisplayItems))
    g_shopController:setUpdateAllItemsCallback(self:makeSelfCallback(self.updateCurrentDisplayItems))
    g_shopController:setSaleItemBoughtCallback(self.closeConfigScreen, self)
    g_shopController:setSwitchToConfigurationCallback(self.showConfigurationScreen, self)
    g_shopController:load()
    local selectCategoryCallback = self:makeSelfCallback(self.onSelectCategory)
    self.pageShopBrands:initialize(g_shopController:getBrandCategories(), g_shopController:getBrandNames(), self:makeSelfCallback(self.onClickBrand), selectCategoryCallback, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_BRANDS), ShopMenu.SLICE_ID.BRANDS, ShopMenu.LIST_CELL_NAME_BRAND, ShopMenu.LIST_EMPTY_CELL_NAME_CATEGORY)
    local clickItemCategoryCallback = self:makeSelfCallback(self.onClickItemCategory)
    self.pageShopVehicles:initialize(g_storeManager:getCategoryTypes(), g_shopController:getShopCategories(), clickItemCategoryCallback, selectCategoryCallback, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_VEHICLES), ShopMenu.SLICE_ID.VEHICLES, ShopMenu.LIST_CELL_NAME_CATEGORY, ShopMenu.LIST_EMPTY_CELL_NAME_CATEGORY)
    self.pageShopDLCs:initialize(g_shopController:getDLCCategoryTypes(), g_shopController:getDLCCategories(), self:makeSelfCallback(self.onClickDLCs), selectCategoryCallback, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_DLCS), ShopMenu.SLICE_ID.DLCS, ShopMenu.LIST_CELL_NAME_DLC, ShopMenu.LIST_EMPTY_CELL_NAME_DLC)
    self.pageShopDLCVehicles:initialize(g_storeManager:getCategoryTypes(), g_shopController:getShopDLCCategories(), self:makeSelfCallback(self.onClickDLCCategory), selectCategoryCallback, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_DLCS), ShopMenu.SLICE_ID.DLCS, ShopMenu.LIST_CELL_NAME_CATEGORY, ShopMenu.LIST_EMPTY_CELL_NAME_CATEGORY)
    self.pageShopPacks:initialize(g_shopController:getStorePackTypes(), g_shopController:getStorePacks(), self:makeSelfCallback(self.onClickPack), selectCategoryCallback, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_PACKS), ShopMenu.SLICE_ID.PACKS, ShopMenu.LIST_CELL_NAME_PACKS, ShopMenu.LIST_EMPTY_CELL_NAME_CATEGORY)
    self.pageShopOthers:initialize(selectCategoryCallback, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_OTHERS), ShopMenu.SLICE_ID.OTHERS)
    self.pageUsedSale:initialize()
    self.pageUsedSale:setItemClickCallback(self:makeClickBuyItemCallback())
    self.pageUsedSale:setItemSelectCallback(self:makeSelfCallback(self.onSelectItemBuyDetail))
    self.pageUsedSale:setHeader(g_i18n:getText("ui_usedVehicleSale"), ShopMenu.SLICE_ID.SALE)
    self.pageUsedSale:setCategory(nil, g_i18n:getText("ui_usedVehicleSale"))
    self.pageShopItemDetails:initialize()
    self.pageShopItemDetails:setItemClickCallback(self:makeClickBuyItemCallback())
    self.pageShopItemDetails:setItemSelectCallback(self:makeSelfCallback(self.onSelectItemBuyDetail))
    self.pageShopItemCombinations:initialize()
    self.pageShopItemCombinations:setItemClickCallback(self:makeClickBuyItemCallback())
    self.pageShopItemCombinations:setItemSelectCallback(self:makeSelfCallback(self.onSelectItemBuyDetail))
end
function ShopMenu:setupMenuPages()
    local orderedDefaultPages = {
        { self.pageShopBrands, self:makeIsShopBrandsEnabledPredicate(), ShopMenu.SLICE_ID.BRANDS },
        { self.pageShopVehicles, self:makeIsShopVehiclesEnabledPredicate(), ShopMenu.SLICE_ID.VEHICLES },
        { self.pageShopPacks, self:makeIsShopPacksEnabledPredicate(), ShopMenu.SLICE_ID.PACKS },
        { self.pageUsedSale, self:makeIsShopUsedEnabledPredicate(), ShopMenu.SLICE_ID.SALE },
        { self.pageShopDLCs, self:makeIsDLCPageEnabledPredicate(), ShopMenu.SLICE_ID.DLCS },
        { self.pageShopDLCVehicles, self:makeIsDLCVehiclesPageEnabledPredicate(), ShopMenu.SLICE_ID.DLCS },
        { self.pageShopOthers, self:makeIsShopOthersEnabledPredicate(), ShopMenu.SLICE_ID.OTHERS },
        { self.pageShopItemDetails, self:makeIsShopItemsEnabledPredicate(), ShopMenu.SLICE_ID.VEHICLES },
        { self.pageShopItemCombinations, self:makeIsShopCombinationsEnabledPredicate(), ShopMenu.SLICE_ID.SALE }
    }
    for i, pageDef in ipairs(orderedDefaultPages) do
        local page, predicate, sliceId = unpack(pageDef)
        self:registerPage(page, i, predicate)
        self:addPageTab(page, nil, nil, sliceId)
    end
    self:rebuildTabList()
end
function ShopMenu:setupMenuButtonInfo()
    ShopMenu:superClass().setupMenuButtonInfo(self)
    self.backButtonInfo = {
        ["inputAction"] = InputAction.MENU_BACK,
        ["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BACK),
        ["callback"] = self.clickBackCallback
    }
    self.nextPageButtonInfo = {
        ["inputAction"] = InputAction.MENU_PAGE_NEXT,
        ["text"] = g_i18n:getText("ui_ingameMenuNext"),
        ["callback"] = self.onPageNext
    }
    self.prevPageButtonInfo = {
        ["inputAction"] = InputAction.MENU_PAGE_PREV,
        ["text"] = g_i18n:getText("ui_ingameMenuPrev"),
        ["callback"] = self.onPagePrevious
    }
    self.selectButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText("button_select"),
        ["callback"] = self.onButtonSelect
    }
    self.searchButtonInfo = {
        ["inputAction"] = InputAction.MENU_EXTRA_2,
        ["text"] = g_i18n:getText("button_search"),
        ["callback"] = self.onButtonSearch
    }
    self.defaultMenuButtonInfo = {
        self.backButtonInfo,
        self.nextPageButtonInfo,
        self.prevPageButtonInfo,
        self.selectButtonInfo
    }
    self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
    self.defaultButtonActionCallbacks = {
        [InputAction.MENU_BACK] = self.clickBackCallback
    }
    if Platform.isMobile then
        self.shopMenuButtonInfo = { self.backButtonInfo }
    else
        self.shopMenuButtonInfo = {
            self.backButtonInfo,
            self.nextPageButtonInfo,
            self.prevPageButtonInfo,
            self.selectButtonInfo
        }
    end
    self.showCategoriesButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SHOW_CATEGORIES),
        ["callback"] = self:makeSelfCallback(self.showCategories),
        ["profile"] = "buttonSwitch"
    }
    self.showBrandsButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SHOW_BRANDS),
        ["callback"] = self:makeSelfCallback(self.showBrands),
        ["profile"] = "buttonSwitch"
    }
    if Platform.isMobile then
        self.shopMenuButtonInfoBrands = { self.backButtonInfo, self.showBrandsButtonInfo }
    else
        self.shopMenuButtonInfoBrands = {
            self.backButtonInfo,
            self.nextPageButtonInfo,
            self.prevPageButtonInfo,
            self.selectButtonInfo,
            self.searchButtonInfo
        }
    end
    if Platform.isMobile then
        self.shopMenuButtonInfoCategories = { self.backButtonInfo, self.showCategoriesButtonInfo }
    else
        self.shopMenuButtonInfoCategories = {
            self.backButtonInfo,
            self.nextPageButtonInfo,
            self.prevPageButtonInfo,
            self.selectButtonInfo,
            self.searchButtonInfo
        }
    end
    self.showDLCsButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SHOW_PACKS),
        ["callback"] = self:makeSelfCallback(self.showDLCs),
        ["profile"] = "buttonSwitch"
    }
    self.showDLCVehiclesButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SHOW_CATEGORIES),
        ["callback"] = self:makeSelfCallback(self.showDLCVehicles),
        ["profile"] = "buttonSwitch"
    }
    self.shopMenuButtonInfoDLCs = {
        self.backButtonInfo,
        self.nextPageButtonInfo,
        self.prevPageButtonInfo,
        self.showDLCVehiclesButtonInfo,
        self.selectButtonInfo
    }
    self.shopMenuButtonInfoDLCVehicles = {
        self.backButtonInfo,
        self.nextPageButtonInfo,
        self.prevPageButtonInfo,
        self.showDLCsButtonInfo,
        self.selectButtonInfo
    }
    self.shopMenuButtonsInfoOthers = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    self.buyButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BUY),
        ["callback"] = self:makeSelfCallback(self.onButtonAcceptItem),
        ["profile"] = "buttonBuy"
    }
    self.itemDetailsButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_INFO),
        ["callback"] = self:makeSelfCallback(self.onButtonInfo),
        ["profile"] = "buttonShowInfo"
    }
    if Platform.isMobile then
        self.shopDetailsButtonInfo = { self.backButtonInfo, self.buyButtonInfo, self.itemDetailsButtonInfo }
    else
        self.shopDetailsButtonInfo = {
            self.backButtonInfo,
            self.nextPageButtonInfo,
            self.prevPageButtonInfo,
            self.buyButtonInfo
        }
    end
    self.combinationsButtonInfo = {
        ["inputAction"] = InputAction.MENU_EXTRA_2,
        ["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_COMBINATIONS),
        ["callback"] = self:makeSelfCallback(self.onButtonCombinations),
        ["profile"] = "buttonCombinations"
    }
    if Platform.isMobile then
        self.shopDetailsButtonInfoWithCombinations = {
            self.backButtonInfo,
            self.buyButtonInfo,
            self.combinationsButtonInfo,
            self.itemDetailsButtonInfo
        }
    else
        self.shopDetailsButtonInfoWithCombinations = {
            self.backButtonInfo,
            self.nextPageButtonInfo,
            self.prevPageButtonInfo,
            self.combinationsButtonInfo,
            self.buyButtonInfo
        }
    end
    self.sellButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SELL),
        ["callback"] = self:makeSelfCallback(self.onButtonAcceptItem),
        ["profile"] = "buttonSell"
    }
    self.hotspotButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_HOTSPOT),
        ["callback"] = self:makeSelfCallback(self.onButtonToggleHotspot),
        ["profile"] = "buttonHotspot"
    }
    if Platform.isMobile then
        self.garageMenuButtonInfo = { self.backButtonInfo }
    else
        self.garageMenuButtonInfo = {
            self.backButtonInfo,
            self.nextPageButtonInfo,
            self.prevPageButtonInfo,
            self.hotspotButtonInfo
        }
    end
end
function ShopMenu:onGuiSetupFinished()
    ShopMenu:superClass().onGuiSetupFinished(self)
    self:setupMenuPages()
end
function ShopMenu:setPlayerFarm(farm)
    self.playerFarm = farm
    if farm == nil then
        self.playerFarmId = 0
    else
        self.playerFarmId = farm.farmId
    end
    g_shopController:setPlayerFarm(farm)
    if self:getIsOpen() then
        self:updatePages()
    end
end
function ShopMenu.setCurrentMission(_, currentMission)
    g_shopController:setCurrentMission(currentMission)
end
function ShopMenu:setCurrentUserId(currentUserId)
    self.currentUserId = currentUserId
end
function ShopMenu:exitMenuFromConfig()
    g_shopConfigScreen:changeScreen(ShopMenu)
    self:exitMenu()
end
function ShopMenu:reset()
    ShopMenu:superClass().reset(self)
    g_shopController:reset()
    self.isMasterUser = false
    self.isServer = false
    self.selectedDisplayElement = nil
    self.selectedCategory = nil
    if GS_IS_MOBILE_VERSION then
        self.restorePageIndex = 2
    end
end
function ShopMenu:onOpen()
    self:onVehicleSaleChanged()
    ShopMenu:superClass().onOpen(self)
    self:onMoneyChange()
    g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChange, self)
    g_messageCenter:subscribe(MessageType.VEHICLE_REPAIRED, self.onVehicleRepairRepaintEvent, self)
    g_messageCenter:subscribe(MessageType.VEHICLE_REPAINTED, self.onVehicleRepairRepaintEvent, self)
    g_messageCenter:subscribe(MessageType.VEHICLE_SALES_CHANGED, self.onVehicleSaleChanged, self)
end
function ShopMenu:onClose(_)
    ShopMenu:superClass().onClose(self)
    self.mouseDown = false
    self.alreadyClosed = true
    if not self.closingForConfigurationScreen then
        self.currentDisplayItems = nil
        local mission = g_currentMission
        mission:showMoneyChange(MoneyType.SHOP_VEHICLE_BUY)
        mission:showMoneyChange(MoneyType.SHOP_VEHICLE_SELL)
        mission:showMoneyChange(MoneyType.SHOP_PROPERTY_BUY)
        mission:showMoneyChange(MoneyType.SHOP_PROPERTY_SELL)
        mission:showMoneyChange(MoneyType.SHOP_HANDTOOL_BUY)
        mission:showMoneyChange(MoneyType.SHOP_HANDTOOL_SELL)
        mission:showMoneyChange(MoneyType.LEASING_COSTS)
        mission:showMoneyChange(MoneyType.PURCHASE_SEEDS)
        mission:showMoneyChange(MoneyType.PURCHASE_FERTILIZER)
        mission:showMoneyChange(MoneyType.PURCHASE_FUEL)
        mission:showMoneyChange(MoneyType.PURCHASE_SAPLINGS)
        mission:showMoneyChange(MoneyType.PURCHASE_PALLETS)
        mission:showMoneyChange(MoneyType.PURCHASE_BALES)
        mission:showMoneyChange(MoneyType.OTHER)
        mission:showMoneyChange(MoneyType.BOUGHT_MATERIALS)
    end
    self.closingForConfigurationScreen = false
    g_messageCenter:unsubscribe(MessageType.MONEY_CHANGED, self)
    g_messageCenter:unsubscribe(MessageType.VEHICLE_REPAIRED, self)
    g_messageCenter:unsubscribe(MessageType.VEHICLE_REPAINTED, self)
    g_messageCenter:unsubscribe(MessageType.VEHICLE_SALES_CHANGED, self)
    if self.pageShopVehicles.overlayCache ~= nil then
        self.pageShopVehicles.overlayCache:clearCache()
    end
    if self.pageShopBrands.overlayCache ~= nil then
        self.pageShopBrands.overlayCache:clearCache()
    end
    if self.pageShopPacks.overlayCache ~= nil then
        self.pageShopPacks.overlayCache:clearCache()
    end
    if self.pageShopDLCs.overlayCache ~= nil then
        self.pageShopDLCs.overlayCache:clearCache()
    end
    if self.pageShopDLCVehicles.overlayCache ~= nil then
        self.pageShopDLCVehicles.overlayCache:clearCache()
    end
    if self.pageUsedSale.overlayCache ~= nil then
        self.pageUsedSale.overlayCache:clearCache()
    end
end
function ShopMenu:onButtonSelect()
    if self.selectedCategory == nil or self:getIsDetailMode() then
        if self.currentPage == self.pageShopOthers then
            self.pageShopOthers:onMenuAccept()
        end
    else
        self:getTopFrame():onOpenCategory()
    end
end
function ShopMenu:onButtonInfo()
    InfoDialog.show(self.selectedDisplayElement.functionText)
end
function ShopMenu:onButtonShop()
    self:popDetail()
end
function ShopMenu:onButtonCombinations()
    local items = g_shopController:getItemsFromCombinations(self.selectedDisplayElement.storeItem.specs.combinations)
    self.pageShopItemCombinations:setDisplayItems(items, false)
    local details = self.pageShopItemDetails
    local title = string.format(g_i18n:getText("ui_combinationsFor"), self.selectedDisplayElement.storeItem.name)
    self.pageShopItemCombinations:setCategory(details.rootName, details.categoryName, nil, title)
    self:pushDetail(self.pageShopItemCombinations)
    self.currentDisplayItems = items
end
function ShopMenu:onButtonSearch()
    self:openSeachDialog(nil)
end
function ShopMenu:openSeachDialog(defaultText)
    local text = g_i18n:getText("modHub_search")
    TextInputDialog.show(self.onSearchTextEntered, self, defaultText, text, text, 40, text, nil, nil, false)
end
function ShopMenu:onSearchTextEntered(text, ok)
    if ok then
        local isSearching = true
        if g_storeManager:search(text, function(results)
            -- upvalues: (ref) isSearching, (copy) self, (copy) text
            MessageDialog.hide()
            isSearching = false
            if #results == 0 then
                InfoDialog.show(g_i18n:getText("ui_storeSearchingNoResults"), function()
                    -- upvalues: (ref) self, (ref) text
                    self:openSeachDialog(text)
                end)
            else
                local storeItems = {}
                for _, data in ipairs(results) do
                    table.insert(storeItems, data.ref)
                end
                local items = g_shopController:getItemsByStoreItems(storeItems)
                self.currentCategoryName = "Search results"
                self.currentDisplayItems = items
                self.currentCategoryFilter = nil
                self.currentItemDetailsType = ShopMenu.DETAILS.VEHICLE
                self.pageShopItemDetails:setDisplayItems(items)
                self.pageShopItemDetails:setCategory("", string.format("\"%s\"", text), ShopMenu.SLICE_ID.SEARCH)
                self:pushDetail(self.pageShopItemDetails)
                self.pageShopItemDetails:resetListSelection()
            end
        end) then
            if isSearching then
                MessageDialog.show(g_i18n:getText("ui_storeSearching"))
            end
        else
            InfoDialog.show(g_i18n:getText("ui_storeSearchingNoResults"), function()
                -- upvalues: (copy) self, (copy) text
                self:openSeachDialog(text)
            end)
        end
    end
end
function ShopMenu:onVehicleRepairRepaintEvent(vehicle, _)
    if self.selectedDisplayElement ~= nil and self.selectedDisplayElement.concreteItem == vehicle then
        self:updateGarageButtonInfo(true, 1, self.selectedDisplayElement:hasCombinationInfo())
    end
end
function ShopMenu:onButtonAcceptItem()
    if self:getIsDetailMode() then
        self:getTopFrame():onOpenItem(nil, nil, nil, nil, true)
    end
end
function ShopMenu:setIsGamePaused(paused)
    self.paused = paused
    if self.currentPage ~= nil then
        self:updateButtonsPanel(self.currentPage)
    end
end
function ShopMenu:onDetailClosed(_)
    self.currentDisplayItems = nil
end
function ShopMenu:update(dt)
    ShopMenu:superClass().update(self, dt)
    g_shopController:update(dt)
end
function ShopMenu.setConfigurations(_, vehicleBuyData)
    g_shopController:setConfigurations(vehicleBuyData)
end
function ShopMenu:showConfigurationScreen(storeItem, saleItem, configurations)
    if g_currentMission.slotSystem:hasEnoughSlots(storeItem) then
        self.closingForConfigurationScreen = true
        self:changeScreen(ShopConfigScreen)
        g_shopConfigScreen:setReturnScreenClass(ShopMenu)
        g_shopConfigScreen:setStoreItem(storeItem, nil, saleItem, nil, configurations)
        g_shopConfigScreen:setCallbacks(self.setConfigurations, self)
    else
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
        InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS))
    end
end
function ShopMenu:updateCurrentDisplayItems()
    if self.currentDisplayItems ~= nil then
        local updatedDisplayItems = g_shopController:updateDisplayItems(self.currentDisplayItems)
        if #updatedDisplayItems == 0 then
            self:onButtonBack()
            return
        end
        if self:getTopFrame() == self.pageShopItemCombinations then
            self.pageShopItemCombinations:setDisplayItems(updatedDisplayItems, false)
            return
        end
        self.pageShopItemDetails:setDisplayItems(updatedDisplayItems, false)
    end
end
function ShopMenu:onStoreItemsReloaded()
    self:updateCurrentDisplayItems()
end
function ShopMenu:inputEvent(action, value, eventUsed)
    eventUsed = ShopMenu:superClass().inputEvent(self, action, value, eventUsed)
    if not eventUsed and action == InputAction.TOGGLE_STORE then
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.BACK)
        self:exitMenu()
        eventUsed = true
    end
    return eventUsed
end
function ShopMenu:onClickMenu()
    self:exitMenu()
    return true
end
function ShopMenu:exitMenu()
    self.pageShopItemDetails:setDisplayItems(nil)
    self.pageShopItemCombinations:setDisplayItems(nil)
    self.pageUsedSale:setDisplayItems(nil)
    self.selectedDisplayElement = nil
    self.currentDisplayItems = nil
    ShopMenu:superClass().exitMenu(self)
end
function ShopMenu:onPageNext()
    if not Platform.isMobile then
        self:popToRoot()
        ShopMenu:superClass().onPageNext(self)
    end
end
function ShopMenu:onPagePrevious()
    if not Platform.isMobile then
        self:popToRoot()
        ShopMenu:superClass().onPagePrevious(self)
    end
end
function ShopMenu:onMoneyChange()
    if g_localPlayer ~= nil then
        local farm = g_farmManager:getFarmById(g_localPlayer.farmId)
        local balanceMoneyText = g_i18n:formatMoney(farm.money, 0, true, false)
        self.pageShopItemDetails:setCurrentBalance(farm.money, balanceMoneyText)
        self.pageShopItemCombinations:setCurrentBalance(farm.money, balanceMoneyText)
        self.pageUsedSale:setCurrentBalance(farm.money, balanceMoneyText)
        self.pageShopVehicles:setCurrentBalance(farm.money, balanceMoneyText)
        self.pageShopBrands:setCurrentBalance(farm.money, balanceMoneyText)
        self.pageShopPacks:setCurrentBalance(farm.money, balanceMoneyText)
        self.pageShopDLCs:setCurrentBalance(farm.money, balanceMoneyText)
        self.pageShopDLCVehicles:setCurrentBalance(farm.money, balanceMoneyText)
    end
end
function ShopMenu:onSlotUsageChanged(currentSlotUsage, maxSlotUsage)
    if self.pageShopItemDetails ~= nil then
        self.pageShopItemDetails:setSlotsUsage(currentSlotUsage, maxSlotUsage)
    end
    if self.pageShopItemCombinations ~= nil then
        self.pageShopItemCombinations:setSlotsUsage(currentSlotUsage, maxSlotUsage)
    end
    if self.pageUsedSale ~= nil then
        self.pageUsedSale:setSlotsUsage(currentSlotUsage, maxSlotUsage)
    end
    if self.pageShopVehicles ~= nil then
        self.pageShopVehicles:setSlotsUsage(currentSlotUsage, maxSlotUsage)
    end
end
function ShopMenu:onSelectCategory(category, _)
    self.selectedCategory = category
end
function ShopMenu:onSelectItemBuyDetail(displayItem, _)
    self.selectedDisplayElement = displayItem
    local isVehicle = StoreItemUtil.getIsVehicle(displayItem.storeItem)
    local isConfigurable = StoreItemUtil.getIsConfigurable(displayItem.storeItem)
    if isVehicle and (isConfigurable and not Platform.isMobile) then
        self.buyButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_CUSTOMIZE)
    elseif isConfigurable or (StoreItemUtil.getIsHandTool(displayItem.storeItem) or Platform.isMobile) then
        self.buyButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BUY)
    else
        self.buyButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_DETAILS)
    end
    if isVehicle and (Platform.isMobile and displayItem.storeItem.canBeRecovered) then
        self.buyButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_RECOVER)
        self.buyButtonInfo.profile = "buttonRecover"
    elseif displayItem.storeItem.isInAppPurchase then
        if not displayItem.storeItem.isInAppPurchaseConsumable then
            self.buyButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_UNLOCK)
        end
        self.buyButtonInfo.profile = "buttonBuyIAP"
    elseif displayItem.storeItem.isInAppPurchase then
        self.buyButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_UNLOCK)
        self.buyButtonInfo.profile = "buttonBuyIAP"
    else
        self.buyButtonInfo.profile = "buttonBuy"
    end
    self:updateButtonsPanel(self.pageShopItemDetails)
end
function ShopMenu:onSelectItemSellDetail(displayItem, _)
    self.selectedDisplayElement = displayItem
    local itemPropertyState = displayItem.concreteItem.propertyState
    local isOwned = true
    if itemPropertyState ~= nil then
        isOwned = itemPropertyState ~= VehiclePropertyState.LEASED
    end
    self:updateGarageButtonInfo(isOwned, 1, displayItem:hasCombinationInfo())
end
function ShopMenu:updateGarageButtonInfo(isOwned, numItems, hasCombinations)
    local buttons = self:getPageButtonInfo(self.pageShopItemDetails)
    local i = 1
    for i = i, #buttons do
        buttons[i] = nil
    end
    local i = self.backButtonInfo
    table.insert(buttons, i)
    if numItems > 0 then
        table.insert(buttons, self.sellButtonInfo)
        if isOwned then
            self.sellButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SELL)
        else
            self.sellButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_RETURN)
        end
    end
    if not Platform.isMobile and (self.selectedDisplayElement ~= nil and self.selectedDisplayElement.concreteItem.getMapHotspot ~= nil) then
        table.insert(buttons, self.hotspotButtonInfo)
    end
    if hasCombinations then
        table.insert(buttons, self.combinationsButtonInfo)
    end
    self:updateButtonsPanel(self.pageShopItemDetails)
end
function ShopMenu:getPageButtonInfo(page)
    if self:getIsDetailMode() then
        if self.selectedDisplayElement == nil or (not self.selectedDisplayElement:hasCombinationInfo() or self:getTopFrame() == self.pageShopItemCombinations) then
            return self.shopDetailsButtonInfo
        else
            return self.shopDetailsButtonInfoWithCombinations
        end
    elseif page == self.pageShopItemDetails then
        if self.selectedDisplayElement:hasCombinationInfo() and self:getTopFrame() ~= self.pageShopItemCombinations then
            return self.shopDetailsButtonInfoWithCombinations
        else
            return self.shopDetailsButtonInfo
        end
    elseif page == self.pageShopBrands then
        return self.shopMenuButtonInfoCategories
    elseif page == self.pageShopVehicles then
        return self.shopMenuButtonInfoBrands
    elseif page == self.pageShopDLCs then
        return self.shopMenuButtonInfoDLCs
    elseif page == self.pageShopDLCVehicles then
        return self.shopMenuButtonInfoDLCVehicles
    elseif page == self.pageShopOthers and self.pageShopOthers.gameplayHintSelector:getIsFocused() then
        return self.shopMenuButtonsInfoOthers
    else
        return self.shopMenuButtonInfo
    end
end
function ShopMenu:onClickBrand(brandId, categoryDisplayName, _, categorySliceId)
    local brandItems = g_shopController:getItemsByBrand(brandId)
    self.currentDisplayItems = brandItems
    self.pageShopItemDetails:setDisplayItems(brandItems, false)
    self.pageShopItemDetails:setCategory(g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_BRANDS), categoryDisplayName, categorySliceId)
    self.currentItemDetailsType = ShopMenu.DETAILS.BRAND
    self.currentBrandId = brandId
    self:pushDetail(self.pageShopItemDetails)
    self.pageShopItemDetails:resetListSelection()
end
function ShopMenu:onClickPack(packName, categoryDisplayName, _, categorySliceId)
    local items = g_shopController:getItemsByPack(packName)
    self.currentDisplayItems = items
    self.pageShopItemDetails:setDisplayItems(items, false)
    self.pageShopItemDetails:setCategory(g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_PACKS), categoryDisplayName, categorySliceId)
    self:pushDetail(self.pageShopItemDetails)
    self.pageShopItemDetails:resetListSelection()
end
function ShopMenu:onClickDLCs(dlcId, categoryDisplayName, dlcLabel, categorySliceId)
    local items = g_shopController:getItemsByDLC(dlcId)
    self.currentDisplayItems = items
    self.pageShopItemDetails:setDisplayItems(items, false)
    self.pageShopItemDetails:setCategory(g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_DLCS), categoryDisplayName, categorySliceId, dlcLabel)
    self:pushDetail(self.pageShopItemDetails)
    self.pageShopItemDetails:resetListSelection()
end
function ShopMenu:onClickDLCCategory(categoryName, baseCategoryDisplayName, categoryDisplayName, categorySliceId, filter)
    local categoryItems = g_shopController:getItemsByCategory(categoryName, true)
    self.currentCategoryName = categoryName
    self.currentDisplayItems = categoryItems
    self.currentCategoryFilter = filter
    self.currentItemDetailsType = ShopMenu.DETAILS.VEHICLE
    self.pageShopItemDetails:setDisplayItems(categoryItems)
    self.pageShopItemDetails:setCategory(baseCategoryDisplayName, categoryDisplayName, categorySliceId)
    self:pushDetail(self.pageShopItemDetails)
    self.pageShopItemDetails:resetListSelection()
end
function ShopMenu:onClickItemCategory(categoryName, baseCategoryDisplayName, categoryDisplayName, headerIconSlice, filter)
    local categoryItems = g_shopController:getItemsByCategory(categoryName)
    self.currentCategoryName = categoryName
    self.currentDisplayItems = categoryItems
    self.currentCategoryFilter = filter
    self.currentItemDetailsType = ShopMenu.DETAILS.VEHICLE
    self.pageShopItemDetails:setDisplayItems(categoryItems)
    if categoryName == ShopController.COINS_CATEGORY and not g_inAppPurchaseController:getIsAvailable() then
        InfoDialog.show(g_i18n:getText("ui_iap_notAvailable"), nil, nil, DialogElement.TYPE_INFO)
        return
    end
    local hasInAppPurchases = false
    local i = 1
    for i = i, #self.currentDisplayItems do
        if self.currentDisplayItems[i].storeItem.isInAppPurchase then
            hasInAppPurchases = true
            break
        end
    end
    if hasInAppPurchases then
        g_inAppPurchaseController:setPendingPurchaseCallback(function()
            -- upvalues: (copy) self
            if self:getIsOpen() then
                self:updateCurrentDisplayItems()
            end
        end)
    else
        g_inAppPurchaseController:setPendingPurchaseCallback(nil)
    end
    self.pageShopItemDetails:setCategory(baseCategoryDisplayName, categoryDisplayName, headerIconSlice)
    self:pushDetail(self.pageShopItemDetails)
    self.pageShopItemDetails:resetListSelection()
end
function ShopMenu:buyItem(displayItem)
    if GS_IS_MOBILE_VERSION then
        local storeItem = displayItem.storeItem
        if storeItem.isInAppPurchase then
            self:purchaseInAppProduct(storeItem.product)
            return
        else
            local enoughMoney = true
            local price = g_currentMission.economyManager:getBuyPrice(storeItem)
            if price > 0 then
                enoughMoney = price <= g_currentMission:getMoney()
            end
            local enoughSlots = g_currentMission.slotSystem:hasEnoughSlots(storeItem)
            if enoughMoney then
                if enoughSlots then
                    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
                    local callback = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIRM_BUY), g_i18n:formatMoney(price, 0, true, true))
                    self.currentBuyDialogItem = displayItem
                    YesNoDialog.show(self.onYesNoBuy, self, callback)
                else
                    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
                    InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS))
                end
            else
                self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
                if g_inAppPurchaseController:getIsAvailable() then
                    YesNoDialog.show(function(self, yes)
                        if yes then
                            self:showCoinShop()
                        end
                    end, self, g_i18n:getText("shop_messageNotEnoughMoneyToBuy_buyCoins"), g_i18n:getText("ui_buy"))
                else
                    InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_BUY))
                end
            end
        end
    else
        g_shopController:buy(displayItem.storeItem, displayItem.saleItem, false, displayItem.configurations)
        return
    end
end
function ShopMenu:onYesNoBuy(yes)
    if yes then
        g_shopController:buy(self.currentBuyDialogItem.storeItem, self.currentBuyDialogItem.saleItem, false)
    end
    self.currentBuyDialogItem = nil
end
function ShopMenu:purchaseInAppProduct(product)
    if not g_inAppPurchaseController:tryPerformPendingPurchase(product, function(success, warningText)
        -- upvalues: (copy) self
        if success then
            InfoDialog.show(g_i18n:getText(ShopMenu.IAP_ERROR_TEXTS[InAppPurchase.ERROR_OK]), nil, nil, DialogElement.TYPE_INFO)
            self:updateCurrentDisplayItems()
        else
            local text = g_i18n:getText(ShopMenu.IAP_ERROR_TEXTS[InAppPurchase.ERROR_FAILED])
            if warningText ~= nil then
            end
            InfoDialog.show(text, nil, nil, DialogElement.TYPE_INFO)
        end
    end) then
        if not g_inAppPurchaseController:getIsAvailable() then
            InfoDialog.show(g_i18n:getText("ui_iap_notAvailable"), nil, nil, DialogElement.TYPE_INFO)
            return
        end
        g_inAppPurchaseController:purchase(product, function(_, cancelled, errorCode)
            if not cancelled then
                InfoDialog.show(g_i18n:getText(ShopMenu.IAP_ERROR_TEXTS[errorCode]), nil, nil, DialogElement.TYPE_INFO)
            end
        end)
    end
end
function ShopMenu:showCoinShop()
    self:changeScreen(ShopMenu)
    self:goToPage(self.pageShopVehicles)
    self:onClickItemCategory(ShopController.COINS_CATEGORY, nil, g_i18n:getText("ui_coins"))
end
function ShopMenu:onButtonToggleHotspot()
    if self:getIsDetailMode() then
        local vehicle = self:getTopFrame():getSelectedDisplayItem().concreteItem
        if vehicle:getMapHotspot() == g_currentMission.currentMapTargetHotspot then
            g_currentMission:setMapTargetHotspot()
            return
        end
        g_currentMission:setMapTargetHotspot(vehicle:getMapHotspot())
    end
end
function ShopMenu:showCategories()
    self:goToPage(self.pageShopVehicles)
end
function ShopMenu:showBrands()
    self:goToPage(self.pageShopBrands)
end
function ShopMenu:showDLCs()
    self.showDLCsPage = true
    self:updatePages()
    self:goToPage(self.pageShopDLCs)
end
function ShopMenu:showDLCVehicles()
    self.showDLCsPage = false
    self:updatePages()
    self:goToPage(self.pageShopDLCVehicles)
end
function ShopMenu:closeConfigScreen()
    g_shopConfigScreen:changeScreen(ShopMenu)
end
function ShopMenu:onButtonConstruction()
    self:changeScreen(ConstructionScreen)
end
function ShopMenu:viewVehicle(vehicleFilename)
    local basePath = vehicleFilename:gsub("\\", "/")
    local basePath = getAppBasePath()
    if basePath:startsWith(basePath) then
        basePath = basePath:sub(basePath:len() + 1)
    end
    local storeItem = g_storeManager:getItemByXMLFilename(basePath)
    if storeItem ~= nil then
        g_gui:changeScreen(nil, ShopMenu)
        local category = nil
        local i = 1
        for i = i, #storeItem.categoryNames do
            category = g_storeManager:getCategoryByName(storeItem.categoryNames[i])
            if category ~= nil then
                break
            end
        end
        if category ~= nil then
            self:onClickItemCategory(category.name, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_VEHICLES), category.title, self.currentCategoryFilter)
        end
        g_shopMenu:showConfigurationScreen(storeItem, nil, nil)
    end
end
function ShopMenu:getIsDetailMode()
    return ShopMenu:superClass().getIsDetailMode(self) or self.currentPage == self.pageUsedSale
end
function ShopMenu:makeIsShopBrandsEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        return not self:getIsDetailMode() or self.currentPage == self.pageUsedSale
    end
end
function ShopMenu:makeIsShopVehiclesEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        return not self:getIsDetailMode() or self.currentPage == self.pageUsedSale
    end
end
function ShopMenu:makeIsShopToolsEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        if self:getIsDetailMode() then
            if self.currentPage ~= self.pageUsedSale then
                ::l3::
                return false
            end
        end
        local v17_ = not GS_IS_MOBILE_VERSION
        goto l3
    end
end
function ShopMenu:makeIsShopObjectsEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        if self:getIsDetailMode() then
            if self.currentPage ~= self.pageUsedSale then
                ::l3::
                return false
            end
        end
        local v18_ = not GS_IS_MOBILE_VERSION
        goto l3
    end
end
function ShopMenu:makeIsShopPacksEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        if self:getIsDetailMode() then
            if self.currentPage ~= self.pageUsedSale then
                ::l3::
                return false
            end
        end
        local v19_ = not GS_IS_MOBILE_VERSION
        goto l3
    end
end
function ShopMenu:makeIsShopUsedEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        if self:getIsDetailMode() then
            if self.currentPage ~= self.pageUsedSale then
                ::l3::
                return false
            end
        end
        local v20_ = not GS_IS_MOBILE_VERSION
        goto l3
    end
end
function ShopMenu:makeIsShopGarageEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        return not self:getIsDetailMode() or self.currentPage == self.pageUsedSale
    end
end
function ShopMenu:makeIsShopLeasedEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        if self:getIsDetailMode() then
            if self.currentPage ~= self.pageUsedSale then
                ::l3::
                return false
            end
        end
        local v22_ = not GS_IS_MOBILE_VERSION
        goto l3
    end
end
function ShopMenu:makeIsShopOthersEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        if self:getIsDetailMode() then
            if self.currentPage ~= self.pageUsedSale then
                ::l3::
                return false
            end
        end
        local v23_ = not GS_IS_MOBILE_VERSION
        goto l3
    end
end
function ShopMenu:makeIsShopItemsEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        return ShopMenu:superClass().getIsDetailMode(self) and (self:getTopFrame() == self.pageShopItemDetails or self.currentPage == self.pageUsedSale)
    end
end
function ShopMenu:makeIsShopCombinationsEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        return self:getIsDetailMode() and self:getTopFrame() == self.pageShopItemCombinations and not GS_IS_MOBILE_VERSION
    end
end
function ShopMenu:makeIsDLCPageEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        return Platform.supportsMods and table.size(g_shopController:getDLCCategories()) > 0 and self.showDLCsPage
    end
end
function ShopMenu:makeIsDLCVehiclesPageEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        return Platform.supportsMods and table.size(g_shopController:getDLCCategories()) > 0 and not self.showDLCsPage
    end
end
function ShopMenu:makeClickBuyItemCallback()
    return function(displayItem)
        -- upvalues: (copy) self
        self:buyItem(displayItem)
    end
end
function ShopMenu:makeClickSellItemCallback()
    return function(displayItem)
        g_shopController:sell(displayItem.storeItem, displayItem.concreteItem)
    end
end
ShopMenu.SLICE_ID = {
    ["VEHICLES"] = "gui.icon_vehicleDealer_machines",
    ["BRANDS"] = "gui.icon_vehicleDealer_brands",
    ["DLCS"] = "gui.icon_vehicleDealer_mods",
    ["PACKS"] = "gui.icon_vehicleDealer_packs",
    ["SALE"] = "gui.icon_vehicleDealer_sale",
    ["OTHERS"] = "gui.icon_others",
    ["SEARCH"] = "gui.icon_vehicleDealer_search"
}
ShopMenu.L10N_SYMBOL = {
    ["HEADER_BRANDS"] = "ui_brands",
    ["HEADER_VEHICLES"] = GS_IS_MOBILE_VERSION and "ui_categories" or "ui_vehicles",
    ["HEADER_TOOLS"] = "ui_tools",
    ["HEADER_PLACEABLES"] = "category_placeables",
    ["HEADER_OBJECTS"] = "ui_objects",
    ["HEADER_ANIMALS"] = "category_animals",
    ["HEADER_SALES"] = "category_sales",
    ["HEADER_GARAGE_OWNED"] = "ui_garageOwned",
    ["HEADER_GARAGE_LEASED"] = "ui_garageLeased",
    ["HEADER_PACKS"] = "ui_storePacks",
    ["HEADER_OTHERS"] = "ui_storeOthers",
    ["HEADER_DLCS"] = "ui_modsAndDlcs",
    ["LEASED_ITEMS"] = "shop_leasedItems",
    ["OWNED_ITEMS"] = "shop_ownedItems",
    ["BUTTON_BACK"] = "button_back",
    ["BUTTON_GARAGE"] = "button_garage",
    ["BUTTON_INFO"] = "button_detail",
    ["BUTTON_SHOP"] = "ui_shop",
    ["BUTTON_CUSTOMIZE"] = "button_configurate",
    ["BUTTON_BUY"] = "button_buy",
    ["BUTTON_DETAILS"] = "button_detail",
    ["BUTTON_SELL"] = "button_sell",
    ["BUTTON_RETURN"] = "button_return",
    ["BUTTON_BRANDS"] = "button_shop_brands",
    ["BUTTON_CATEGORIES"] = "button_shop_categories",
    ["BUTTON_RECOVER"] = "button_recover",
    ["BUTTON_UNLOCK"] = "ui_iap_unlock",
    ["BUTTON_COMBINATIONS"] = "ui_combinations",
    ["BUTTON_HOTSPOT"] = "button_showOnMap",
    ["BUTTON_SHOW_CATEGORIES"] = "button_showCategories",
    ["BUTTON_SHOW_BRANDS"] = "button_showBrands",
    ["BUTTON_SHOW_PACKS"] = "button_showPacks",
    ["NOT_ENOUGH_MONEY_BUY"] = "shop_messageNotEnoughMoneyToBuy",
    ["MESSAGE_NO_PERMISSION"] = "shop_messageNoPermissionGeneral"
}
ShopMenu.DETAILS = {
    ["BRAND"] = 1,
    ["VEHICLE"] = 2
}
ShopMenu.FILTER = {
    ["OWNED"] = 1,
    ["LEASED"] = 2
}
ShopMenu.GUI_PROFILE = {
    ["SHOP_MONEY"] = "fs25_shopMoney",
    ["SHOP_MONEY_NEGATIVE"] = "fs25_shopMoneyNeg",
    ["SHOP_MONEY_BG"] = "fs25_shopMoneyBoxBg",
    ["SHOP_MONEY_SLOTS_BG"] = "fs25_shopMoneySlotsBoxBg"
}
ShopMenu.IAP_ERROR_TEXTS = {
    [InAppPurchase.ERROR_FAILED] = "ui_iap_errorFailed",
    [InAppPurchase.ERROR_NETWORK_UNAVAILABLE] = "ui_iap_errorNetworkUnavailable",
    [InAppPurchase.ERROR_CANCELLED] = "ui_iap_errorCancelled",
    [InAppPurchase.ERROR_PURCHASE_IN_PROGRESS] = "ui_iap_purchaseInProgress",
    [InAppPurchase.ERROR_OK] = "ui_iap_purchaseComplete",
    [InAppPurchase.ERROR_PENDING_PAYMENT] = "ui_iap_pendingPayment"
}
ShopMenu.IAP_ERROR_TEXTS = {
    [InAppPurchase.ERROR_FAILED] = "ui_iap_errorFailed",
    [InAppPurchase.ERROR_NETWORK_UNAVAILABLE] = "ui_iap_errorNetworkUnavailable",
    [InAppPurchase.ERROR_CANCELLED] = "ui_iap_errorCancelled",
    [InAppPurchase.ERROR_PURCHASE_IN_PROGRESS] = "ui_iap_purchaseInProgress",
    [InAppPurchase.ERROR_OK] = "ui_iap_purchaseComplete",
    [InAppPurchase.ERROR_PENDING_PAYMENT] = "ui_iap_pendingPayment"
}