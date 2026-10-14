InGameMenuStatisticsFrame = {}
local InGameMenuStatisticsFrame_mt = Class(InGameMenuStatisticsFrame, TabbedMenuFrameElement)
InGameMenuStatisticsFrame.COLUMN_NAME = 1
InGameMenuStatisticsFrame.COLUMN_AGE = 2
InGameMenuStatisticsFrame.COLUMN_HOURS = 3
InGameMenuStatisticsFrame.COLUMN_HOLDER = 3
InGameMenuStatisticsFrame.COLUMN_DAMAGE = 4
InGameMenuStatisticsFrame.COLUMN_LEASING = 5
InGameMenuStatisticsFrame.COLUMN_VALUE = 6
InGameMenuStatisticsFrame.SORT_ORDER_DESC = 1
InGameMenuStatisticsFrame.SORT_ORDER_ASC = 2
InGameMenuStatisticsFrame.FINANCES = {
    ["PAST_PERIOD_COUNT"] = GS_IS_MOBILE_VERSION and 3 or 4,
    ["LOAN_STEP"] = 5000
}
InGameMenuStatisticsFrame.SUB_CATEGORY = {
    ["PRICES"] = 1,
    ["VEHICLE_OVERVIEW"] = 2,
    ["HANDTOOLS"] = 3,
    ["FINANCES"] = 4,
    ["STATISTICS"] = 5
}
InGameMenuStatisticsFrame.CELL_NAME_DETAIL = "detailTemplate"
InGameMenuStatisticsFrame.CELL_NAME_VALUE = "valueTemplate"
InGameMenuStatisticsFrame.CELL_NAME_FILL_TYPES = "fillTypesTemplate"
InGameMenuStatisticsFrame.CELL_NAME_PRODUCT = "fillTypeCell"
InGameMenuStatisticsFrame.CELL_NAME_STATION = "sellingStationCell"
function InGameMenuStatisticsFrame.register()
    local inGameMenuStatisticsFrame = InGameMenuStatisticsFrame.new()
    g_gui:loadGui("dataS/gui/InGameMenuStatisticsFrame.xml", "StatisticsFrame", inGameMenuStatisticsFrame, true)
end
function InGameMenuStatisticsFrame.new(target, custom_mt)
    -- upvalues: (copy) InGameMenuStatisticsFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuStatisticsFrame_mt)
    self.isInitialized = false
    self.statsIndices = {}
    self.statisticsLists = {}
    self.client = nil
    self.environment = nil
    self.playerFarm = nil
    self.currentMoneyUnitText = ""
    self.updateTimeFinancesStats = 0
    self.menuButtonInfo = {}
    self.hasCustomMenuButtons = true
    self.fillTypes = {}
    self.currentStationData = {}
    self.currentAcceptedFillTypes = {}
    self.clonedPricesElements = {}
    self.monthTexts = {}
    self.fluctuationPoints = {}
    self.sellingStationMode = false
    self.vehicles = {}
    self.sortByColumn = InGameMenuStatisticsFrame.COLUMN_NAME
    self.sortOrder = InGameMenuStatisticsFrame.SORT_ORDER_ASC
    self.sortIcons = {}
    self.detailsCache = {}
    self.detailsTemplates = {}
    self.clonedElements = {}
    self.marqueeBoxes = {}
    self.handTools = {}
    self.sortByColumnHandTools = InGameMenuStatisticsFrame.COLUMN_NAME
    self.sortOrderHandTools = InGameMenuStatisticsFrame.SORT_ORDER_ASC
    self.sortIconsHandTools = {}
    return self
end
function InGameMenuStatisticsFrame.createFromExistingGui(gui, guiName)
    local newGui = InGameMenuStatisticsFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function InGameMenuStatisticsFrame:delete()
    self.separatorTemplate:delete()
    self.monthTextTemplate:delete()
    for k, clonedElement in pairs(self.clonedPricesElements) do
        clonedElement:delete()
        self.clonedPricesElements[k] = nil
    end
    for k, clonedElement in pairs(self.clonedElements) do
        clonedElement:delete()
        self.clonedElements[k] = nil
    end
    for k, clonedElement in pairs(self.detailsTemplates) do
        clonedElement:delete()
        self.detailsTemplates[k] = nil
    end
    for k, clonedElement in pairs(self.detailsCache) do
        for l, clone in pairs(clonedElement) do
            clone:delete()
            self.detailsCache[k][l] = nil
        end
        self.detailsCache[k] = nil
    end
    self.vehicles = {}
    self.handTools = {}
    InGameMenuStatisticsFrame:superClass().delete(self)
end
function InGameMenuStatisticsFrame:initialize()
    InGameMenuStatisticsFrame:superClass().initialize(self)
    for index, button in pairs(self.subCategoryTabs) do
        local index
        button:getDescendantByName("background").getIsSelected = function()
            -- upvalues: (copy) index, (copy) self
            return index == self.subCategoryPaging:getState()
        end
        function button.getIsSelected()
            -- upvalues: (copy) index, (copy) self
            return index == self.subCategoryPaging:getState()
        end
    end
    self.separatorTemplate:unlinkElement()
    self.monthTextTemplate:unlinkElement()
    FocusManager:removeElement(self.separatorTemplate)
    FocusManager:removeElement(self.monthTextTemplate)
    self.separatorTemplate:clone(self.fluctuationsLayoutBg)
    local button = 1
    local oldSmoothScrollTo = 12
    local index = 1
    for button = button, oldSmoothScrollTo, index do
        local clonedText = self.monthTextTemplate:clone(self.fluctuationsLayoutBg)
        clonedText:setText(g_i18n:formatPeriod(button, true))
        table.insert(self.clonedPricesElements, clonedText)
        table.insert(self.monthTexts, clonedText)
        local clonedSeparator = self.separatorTemplate:clone(self.fluctuationsLayoutBg)
        table.insert(self.clonedPricesElements, clonedSeparator)
    end
    self.fluctuationsLayoutBg:invalidateLayout()
    self.backButtonInfo = {
        ["inputAction"] = InputAction.MENU_BACK
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
    self.menuButtonInfoDefault = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    self.hotspotButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = InGameMenuStatisticsFrame.L10N_SYMBOL.SET_MARKER,
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonHotspot()
        end
    }
    self.sellingStationModeButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = InGameMenuStatisticsFrame.L10N_SYMBOL.LIST_STATIONS,
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonChangeSellingStationMode()
        end
    }
    self.menuButtonInfoPrices = {
        self.backButtonInfo,
        self.nextPageButtonInfo,
        self.prevPageButtonInfo,
        self.sellingStationModeButtonInfo
    }
    self.menuButtonInfoPricesWithHotspot = {
        self.backButtonInfo,
        self.nextPageButtonInfo,
        self.prevPageButtonInfo,
        self.sellingStationModeButtonInfo,
        self.hotspotButtonInfo
    }
    self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES] = self.menuButtonInfoDefault
    self.sellVehicleButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText("button_sell"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonSell()
        end
    }
    self.returnVehicleButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText("button_return"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonSell()
        end
    }
    self.viewVehicleOnMapButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText("button_viewOnMap"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onVehicleViewOnMap()
        end
    }
    self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW] = {
        self.backButtonInfo,
        self.nextPageButtonInfo,
        self.prevPageButtonInfo,
        self.viewVehicleOnMapButtonInfo,
        self.sellVehicleButtonInfo
    }
    self:buildCellDatabase()
    self.sellHandToolButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText("button_sell"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonSellHandTool()
        end
    }
    self.storeHandToolButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText("button_store"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onStoreHandTool()
        end
    }
    self.pickUpHandToolButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText("button_pickUp"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onPickUpHandTool()
        end
    }
    self.borrowButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = "",
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonBorrow()
        end
    }
    self.repayButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = "",
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonRepay()
        end
    }
    self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.FINANCES] = {
        self.backButtonInfo,
        self.nextPageButtonInfo,
        self.prevPageButtonInfo,
        self.borrowButtonInfo,
        self.repayButtonInfo
    }
    self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.STATISTICS] = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    local oldSmoothScrollTo = self.statisticsList1.smoothScrollTo
    function self.statisticsList1.smoothScrollTo(_, offset)
        -- upvalues: (copy) oldSmoothScrollTo, (copy) self
        oldSmoothScrollTo(self.statisticsList1, offset)
        oldSmoothScrollTo(self.statisticsList2, offset)
    end
    function self.statisticsList2.smoothScrollTo(_, offset)
        -- upvalues: (copy) oldSmoothScrollTo, (copy) self
        oldSmoothScrollTo(self.statisticsList1, offset)
        oldSmoothScrollTo(self.statisticsList2, offset)
    end
    local index = self.statisticsList1.onSliderValueChanged
    function self.statisticsList1.onSliderValueChanged(_, slider, newValue, immediateMode)
        -- upvalues: (copy) index, (copy) self
        index(self.statisticsList1, slider, newValue, immediateMode)
        index(self.statisticsList2, slider, newValue, immediateMode)
    end
    self.subCategoryPaging:setState(1)
end
function InGameMenuStatisticsFrame:onGuiSetupFinished()
    InGameMenuStatisticsFrame:superClass().onGuiSetupFinished(self)
    local previousButton = nil
    for _, icon in pairs(self.sortIcons) do
        local button = icon[InGameMenuStatisticsFrame.SORT_ORDER_ASC].parent
        if previousButton == nil then
            FocusManager:linkElements(self.vehiclesList, FocusManager.TOP, button)
            FocusManager:linkElements(self.vehiclesList, FocusManager.LEFT, button)
        else
            FocusManager:linkElements(button, FocusManager.LEFT, previousButton)
            FocusManager:linkElements(previousButton, FocusManager.RIGHT, button)
        end
        previousButton = button
    end
    FocusManager:linkElements(self.vehiclesList, FocusManager.RIGHT, previousButton)
end
function InGameMenuStatisticsFrame:initializeLists()
    if not self.isInitialized then
        local list = self.statisticsLists
        local statsPerList = self.statisticsList1
        table.insert(list, statsPerList)
        if self.statisticsList2 ~= nil then
            if GS_IS_MOBILE_VERSION then
                self.statisticsList2:delete()
            else
                table.insert(self.statisticsLists, self.statisticsList2)
            end
        end
        local listIndex = 0
        local list = nil
        self.statsData = self.playerFarm.stats:getStatisticData()
        local statsPerList = math.ceil(#self.statsData / 2)
        for k, _ in ipairs(self.statsData) do
            if list == nil or statsPerList <= #self.statsIndices[list] then
                listIndex = listIndex + 1
                list = self.statisticsLists[listIndex]
                if list == nil then
                    break
                end
                self.statsIndices[list] = {}
            end
            table.insert(self.statsIndices[list], k)
        end
        self.isInitialized = true
    end
end
function InGameMenuStatisticsFrame:getMenuButtonInfo()
    return self.menuButtonInfo[self.subCategoryPaging:getState()]
end
function InGameMenuStatisticsFrame:onFrameOpen(_)
    local mission = g_currentMission
    self.itemDetailsMap:setIngameMap(mission.hud:getIngameMap())
    InGameMenuStatisticsFrame:superClass().onFrameOpen(self)
    local isMultiplayer = mission.missionDynamicInfo.isMultiplayer
    local isSingleplayerOrIsInFarm = not isMultiplayer
    if not isSingleplayerOrIsInFarm then
        isSingleplayerOrIsInFarm = g_localPlayer.farmId ~= FarmManager.SPECTATOR_FARM_ID
    end
    local subCategories = {}
    for index, button in pairs(self.subCategoryTabs) do
        if index == InGameMenuStatisticsFrame.SUB_CATEGORY.STATISTICS then
            button:setVisible(not isMultiplayer)
            if not isMultiplayer then
                table.insert(subCategories, (tostring(index)))
            end
        else
            button:setVisible(isSingleplayerOrIsInFarm)
            if isSingleplayerOrIsInFarm then
                table.insert(subCategories, (tostring(index)))
            end
        end
    end
    self.subCategoryBox:invalidateLayout()
    self.subCategoryPaging:setTexts(subCategories)
    self.subCategoryPaging:setSize(self.subCategoryBox.maxFlowSize + 140 * g_pixelSizeScaledX)
    self:onMoneyChange()
    g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChange, self)
    self:updateMoneyUnit()
    self:updateFinances()
    self:updateFinancesLoanButtons()
    g_messageCenter:subscribe(PlayerPermissionsEvent, self.updateFinancesLoanButtons, self)
    g_messageCenter:subscribe(ChangeLoanEvent, self.updateFinances, self)
    self:initializeLists()
    self:updateStatistics()
    self:updateVehicles()
    local subCategoryIndex = self.detailBox
    subCategoryIndex:setVisible(#self.vehicles > 0)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MONEY_UNIT], self.updateVehicles, self)
    g_messageCenter:subscribe(MessageType.VEHICLE_REMOVED, self.onVehicleSellEvent, self)
    g_messageCenter:subscribe(MessageType.VEHICLE_ADDED, self.onVehicleBuyEvent, self)
    if self.customFilter ~= nil then
        self.ingameMapBase:applyCustomFilter(self.customFilter)
    end
    self:updateHandTools()
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MONEY_UNIT], self.updateHandTools, self)
    g_messageCenter:subscribe(MessageType.HANDTOOL_REMOVED, self.onHandToolSellEvent, self)
    g_messageCenter:subscribe(MessageType.HANDTOOL_ADDED, self.onHandToolBuyEvent, self)
    g_messageCenter:subscribe(HandToolSetHolderEvent, self.onHandToolSetHolderEvent, self)
    self:rebuildTable()
    self:updateTodayBar()
    g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
    local subCategoryIndex = self.subCategoryPaging:getState()
    self:updateSubCategoryPages(subCategoryIndex)
    if subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES then
        FocusManager:setFocus(self.productList)
        return
    elseif subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW then
        FocusManager:setFocus(self.vehiclesList)
        return
    elseif subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.FINANCES then
        FocusManager:setFocus(self.financesList)
    end
end
function InGameMenuStatisticsFrame:onFrameClose()
    InGameMenuStatisticsFrame:superClass().onFrameClose(self)
    g_messageCenter:unsubscribeAll(self)
    g_currentMission:showMoneyChange(MoneyType.LOAN)
    self.itemDetailsMap:onClose()
    self.ingameMapBase:restoreDefaultFilter()
    self.currentStationData = {}
end
function InGameMenuStatisticsFrame:setInGameMap(ingameMap)
    self.itemDetailsMap:setIngameMap(ingameMap)
    self.ingameMapBase = ingameMap
    if ingameMap ~= nil then
        self.customFilter = ingameMap:createCustomFilter(true)
    end
end
function InGameMenuStatisticsFrame:update(dt)
    InGameMenuStatisticsFrame:superClass().update(self, dt)
    self:updateMarqueeAnimation(dt)
    local mission = g_currentMission
    if not mission:getIsServer() and self.updateTimeFinancesStats < mission.time then
        self.updateTimeFinancesStats = mission.time + 5000
        local farm = g_farmManager:getFarmById(g_localPlayer.farmId)
        if farm.stats.financesHistoryVersionCounter ~= farm.stats.financesHistoryVersionCounterLocal then
            farm.stats.financesHistoryVersionCounterLocal = farm.stats.financesHistoryVersionCounter
            local i = 1
            for i = i, InGameMenuStatisticsFrame.FINANCES.PAST_PERIOD_COUNT do
                self.client:getServerConnection():sendEvent(FinanceStatsEvent.new(i, farm.farmId))
            end
        end
    end
end
function InGameMenuStatisticsFrame:draw()
    local isPricesFrame = self.subCategoryPaging:getState() == InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES
    if isPricesFrame and (self.hasAnyFluctuations and not self.sellingStationMode) then
        drawDashedLine(self.todayBar.absPosition[1], self.todayBar.absPosition[2] + self.todayBar.absSize[2], self.todayBar.absSize[1], self.todayBar.absSize[2], -7 * g_pixelSizeY, -6 * g_pixelSizeY, 1, 1, 1, 1, false)
    end
    InGameMenuStatisticsFrame:superClass().draw(self)
    if isPricesFrame and (self.hasAnyFluctuations and not self.sellingStationMode) then
        for i, yPos in pairs(self.fluctuationPoints) do
            local yPosEnd = self.fluctuationPoints[i + 1]
            if yPosEnd ~= nil then
                drawLine2D(self.monthTexts[i].absPosition[1] + self.monthTexts[i].absSize[1] * 0.5, yPos + self.fluctuationsContainer.absPosition[2], self.monthTexts[i + 1].absPosition[1] + self.monthTexts[i + 1].absSize[1] * 0.5, yPosEnd + self.fluctuationsContainer.absPosition[2], g_pixelSizeX * 4, 1, 1, 1, 1)
            end
        end
    end
end
function InGameMenuStatisticsFrame:updateMarqueeAnimation(dt)
    for box, time in pairs(self.marqueeBoxes) do
        local contentWidth = box.absSize[1]
        local visibleWidth = box.parent.absSize[1]
        local scrollDuration = 5000 * (contentWidth / visibleWidth)
        local time = time + dt
        if scrollDuration <= time then
            time = -scrollDuration
        end
        box:setPosition(-((contentWidth - visibleWidth) * MathUtil.smoothstep(0.1, 0.9, math.abs(time) / scrollDuration)))
        self.marqueeBoxes[box] = time
    end
end
function InGameMenuStatisticsFrame:getData()
    return self.playerFarm.stats:getStatisticData()
end
function InGameMenuStatisticsFrame:updateVehicles()
    self.vehicles = {}
    if g_localPlayer ~= nil then
        local mission = g_currentMission
        for _, vehicle in ipairs(mission.vehicleSystem.vehicles) do
            if mission.accessHandler:canPlayerAccess(vehicle) and (vehicle:getShowInVehiclesOverview() and g_localPlayer.farmId == vehicle:getOwnerFarmId()) then
                local item = {
                    ["vehicle"] = vehicle,
                    ["columns"] = {}
                }
                local name = vehicle:getFullName()
                item.columns[InGameMenuStatisticsFrame.COLUMN_NAME] = {
                    ["text"] = name,
                    ["value"] = name
                }
                local damageText = {
                    ["text"] = Vehicle.getSpecValueAge(nil, vehicle),
                    ["value"] = vehicle.age
                }
                item.columns[InGameMenuStatisticsFrame.COLUMN_AGE] = damageText
                local opHoursText = "-"
                local opHoursValue = 0
                if vehicle.getOperatingTime ~= nil then
                    opHoursText = Vehicle.getSpecValueOperatingTime(nil, vehicle)
                    opHoursValue = vehicle:getOperatingTime()
                end
                item.columns[InGameMenuStatisticsFrame.COLUMN_HOURS] = {
                    ["text"] = opHoursText,
                    ["value"] = opHoursValue
                }
                local damageText = "-"
                local damageValue = 0
                if SpecializationUtil.hasSpecialization(Wearable, vehicle.specializations) then
                    damageValue = vehicle:getDamageAmount()
                    damageText = g_i18n:formatNumber(math.ceil((1 - damageValue) * 100), 0) .. " %"
                end
                item.columns[InGameMenuStatisticsFrame.COLUMN_DAMAGE] = {
                    ["text"] = damageText,
                    ["value"] = damageValue
                }
                local leasingText = "-"
                local leasingValue = 0
                if vehicle.propertyState == VehiclePropertyState.LEASED then
                    leasingText = g_i18n:formatMoney(vehicle.price * (EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR + EconomyManager.PER_DAY_LEASING_FACTOR))
                end
                item.columns[InGameMenuStatisticsFrame.COLUMN_LEASING] = {
                    ["text"] = leasingText,
                    ["value"] = leasingValue
                }
                local sellValueText = "-"
                local sellValue = 0
                if vehicle.propertyState == VehiclePropertyState.OWNED then
                    sellValue = vehicle:getSellPrice()
                    sellValueText = g_i18n:formatMoney(sellValue)
                end
                item.columns[InGameMenuStatisticsFrame.COLUMN_VALUE] = {
                    ["text"] = sellValueText,
                    ["value"] = sellValue
                }
                table.insert(self.vehicles, item)
            end
        end
    end
    self:updateView()
end
function InGameMenuStatisticsFrame:updateView()
    local sortByColumn = self.sortByColumn
    local sortOrder = self.sortOrder
    for column, icons in pairs(self.sortIcons) do
        local isSortedByColumn = column == sortByColumn
        icons[InGameMenuStatisticsFrame.SORT_ORDER_DESC]:setVisible(isSortedByColumn and sortOrder == InGameMenuStatisticsFrame.SORT_ORDER_DESC)
        if isSortedByColumn then
            isSortedByColumn = sortOrder == InGameMenuStatisticsFrame.SORT_ORDER_ASC
        end
        icons[InGameMenuStatisticsFrame.SORT_ORDER_ASC]:setVisible(isSortedByColumn)
    end
    table.sort(self.vehicles, function(itemA, itemB)
        -- upvalues: (copy) sortByColumn, (copy) sortOrder
        local valueA = itemA.columns[sortByColumn].value
        local valueB = itemB.columns[sortByColumn].value
        if valueA == valueB then
            valueA = itemA.columns[InGameMenuStatisticsFrame.COLUMN_NAME].value
            valueB = itemB.columns[InGameMenuStatisticsFrame.COLUMN_NAME].value
            if valueA == valueB then
                valueA = itemA.columns[InGameMenuStatisticsFrame.COLUMN_VALUE].value
                valueB = itemB.columns[InGameMenuStatisticsFrame.COLUMN_VALUE].value
            end
        end
        if sortOrder == InGameMenuStatisticsFrame.SORT_ORDER_DESC then
            return valueB < valueA
        else
            return valueA < valueB
        end
    end)
    self.vehiclesList:reloadData()
    self.detailBox:setVisible(self.vehiclesList:getItemCount() > 0)
    self:updateMenuButtons()
end
function InGameMenuStatisticsFrame.getStoreItemDisplayPrice(_, storeItem, saleItem)
    if saleItem == nil then
        if storeItem.isInAppPurchase then
            return storeItem.price
        end
        local defaultPrice = g_currentMission.economyManager:getBuyPrice(storeItem)
        return g_i18n:formatMoney(defaultPrice, 0, true, true)
    end
    local defaultPrice = StoreItemUtil.getPriceWithBoughtConfigurations(storeItem, saleItem.boughtConfigurations, "price")
    local discount = 0
    if defaultPrice > 0 then
        discount = -(1 - saleItem.price / defaultPrice) * 100
    end
    return string.format("%s (%d%%)", g_i18n:formatMoney(saleItem.price, 0, true, true), discount)
end
function InGameMenuStatisticsFrame:assignItemAttributeData(displayItem)
    local layoutsToInvalidate = {}
    for k, clone in pairs(self.clonedElements) do
        if layoutsToInvalidate[clone.parent] == nil then
            layoutsToInvalidate[clone.parent] = true
        end
        clone:delete()
        self.clonedElements[k] = nil
    end
    for k, clone in pairs(layoutsToInvalidate) do
        k:invalidateLayout()
    end
    for k, clone in pairs(self.marqueeBoxes) do
        self.marqueeBoxes[k] = nil
    end
    local i = #self.attributesLayout.elements
    local name = 1
    local brand = -1
    for i = i, name, brand do
        self:queueDetailsCell(self.attributesLayout.elements[i])
    end
    self:assignItemTextData(displayItem)
    self:assignItemFillTypesData(InGameMenuStatisticsFrame.PROFILE.ICON_FILL_TYPES, displayItem.fillTypeIconFilenames)
    self:assignItemFillTypesData(InGameMenuStatisticsFrame.PROFILE.ICON_FILL_TYPES, displayItem.foodFillTypeIconFilenames)
    self:assignItemFillTypesData(InGameMenuStatisticsFrame.PROFILE.ICON_SEED_FILL_TYPES, displayItem.seedTypeIconFilenames)
    local name = displayItem.storeItem.name
    if displayItem.concreteItem ~= nil and displayItem.concreteItem.getName ~= nil then
        name = displayItem.concreteItem:getName()
    end
    local brand = g_brandManager:getBrandByIndex(displayItem.storeItem.brandIndex)
    if displayItem.concreteItem ~= nil and displayItem.concreteItem.getBrand ~= nil then
        brand = g_brandManager:getBrandByIndex(displayItem.concreteItem:getBrand())
    end
    if brand ~= nil and brand.name ~= "NONE" then
    end
    self.itemDetailsName:setText(name)
    local i = self.itemDetailsImage
    local clone = displayItem.storeItem ~= nil
    i:setVisible(clone)
    if displayItem.concreteItem ~= nil then
        self.itemDetailsImage:setImageFilename(displayItem.concreteItem:getImageFilename())
    end
    self.attributesLayout:invalidateLayout()
end
function InGameMenuStatisticsFrame:assignItemTextData(displayItem)
    if Platform.isMobile and self.attrVehicleValue ~= nil then
        local storeItem = displayItem.storeItem
        self.attrVehicleValue:setText(self:getStoreItemDisplayPrice(storeItem))
        self.attrVehicleValue:setVisible(not storeItem.isInAppPurchase)
        self.attrVehicleValueIcon:setVisible(not storeItem.isInAppPurchase)
    end
    for i, value in pairs(displayItem.attributeValues) do
        local cell = self:dequeueDetailsCell(InGameMenuStatisticsFrame.CELL_NAME_DETAIL)
        local icon = cell:getDescendantByName("icon")
        local text = cell:getDescendantByName("text")
        local profile = displayItem.attributeIconProfiles[i]
        if profile ~= nil and profile ~= "" then
            text:setText(value)
            icon:applyProfile(profile)
        end
        cell:setSize(icon.absSize[1] + icon.margin[1] + text.absSize[1], nil)
    end
end
function InGameMenuStatisticsFrame:assignItemFillTypesData(baseIconProfile, iconFilenames)
    if #iconFilenames > 0 then
        local totalWidth = 0
        local cell = self:dequeueDetailsCell(InGameMenuStatisticsFrame.CELL_NAME_FILL_TYPES)
        local cellIcon = cell:getDescendantByName("icon")
        local iconsLayout = cell:getDescendantByName("iconsLayout")
        cellIcon:applyProfile(baseIconProfile)
        for _, iconFilename in pairs(iconFilenames) do
            local icon = self.fruitIconTemplate:clone(iconsLayout)
            icon:setVisible(true)
            table.insert(self.clonedElements, icon)
            icon:applyProfile(InGameMenuStatisticsFrame.PROFILE.ICON_FRUIT_TYPE)
            icon:setImageFilename(iconFilename)
        end
        local parentSize = math.min(self.attributesLayout.absSize[1] * 0.91, totalWidth)
        iconsLayout:setSize(totalWidth, nil)
        iconsLayout:setPosition(0, nil)
        iconsLayout.parent:setSize(parentSize, nil)
        iconsLayout:invalidateLayout()
        if parentSize + cellIcon.absSize[1] + cellIcon.margin[1] < totalWidth then
            self.marqueeBoxes[iconsLayout] = 0
            return
        end
        self.marqueeBoxes[iconsLayout] = nil
    end
end
function InGameMenuStatisticsFrame:updateHandTools()
    self.handTools = {}
    if g_localPlayer ~= nil then
        local mission = g_currentMission
        for _, handTool in ipairs(mission.handToolSystem.handTools) do
            if mission.accessHandler:canPlayerAccess(handTool) and (handTool:getShowInHandToolsOverview() and g_localPlayer.farmId == handTool:getOwnerFarmId()) then
                local item = {
                    ["handTool"] = handTool,
                    ["columns"] = {}
                }
                local name = handTool:getName()
                local brand = handTool.brand
                if brand ~= nil and brand.title ~= "None" then
                end
                item.columns[InGameMenuStatisticsFrame.COLUMN_NAME] = {
                    ["text"] = name,
                    ["value"] = name
                }
                item.columns[InGameMenuStatisticsFrame.COLUMN_AGE] = {
                    ["text"] = Vehicle.getSpecValueAge(nil, handTool),
                    ["value"] = handTool.age
                }
                local holderText = "-"
                local holder = handTool:getHolder()
                if holder ~= nil then
                    holderText = holder:getHolderName()
                end
                item.columns[InGameMenuStatisticsFrame.COLUMN_HOLDER] = {
                    ["text"] = holderText,
                    ["value"] = holderText
                }
                table.insert(self.handTools, item)
            end
        end
    end
    self:updateViewHandTools()
end
function InGameMenuStatisticsFrame:updateViewHandTools()
    local sortByColumn = self.sortByColumnHandTools
    local sortOrder = self.sortOrderHandTools
    for column, icons in pairs(self.sortIconsHandTools) do
        local isSortedByColumn = column == sortByColumn
        icons[InGameMenuStatisticsFrame.SORT_ORDER_DESC]:setVisible(isSortedByColumn and sortOrder == InGameMenuStatisticsFrame.SORT_ORDER_DESC)
        if isSortedByColumn then
            isSortedByColumn = sortOrder == InGameMenuStatisticsFrame.SORT_ORDER_ASC
        end
        icons[InGameMenuStatisticsFrame.SORT_ORDER_ASC]:setVisible(isSortedByColumn)
    end
    table.sort(self.handTools, function(itemA, itemB)
        -- upvalues: (copy) sortByColumn, (copy) sortOrder
        local valueA = itemA.columns[sortByColumn].value
        local valueB = itemB.columns[sortByColumn].value
        if valueA == valueB then
            valueA = itemA.columns[InGameMenuStatisticsFrame.COLUMN_NAME].value
            valueB = itemB.columns[InGameMenuStatisticsFrame.COLUMN_NAME].value
            if valueA == valueB then
                valueA = itemA.columns[InGameMenuStatisticsFrame.COLUMN_HOLDER].value
                valueB = itemB.columns[InGameMenuStatisticsFrame.COLUMN_HOLDER].value
            end
        end
        if sortOrder == InGameMenuStatisticsFrame.SORT_ORDER_DESC then
            return valueB < valueA
        else
            return valueA < valueB
        end
    end)
    self.handToolsList:reloadData()
end
function InGameMenuStatisticsFrame:updateStatistics()
    self.statsData = self.playerFarm.stats:getStatisticData()
    for _, list in ipairs(self.statisticsLists) do
        list:reloadData()
    end
end
function InGameMenuStatisticsFrame:setClient(client)
    self.client = client
end
function InGameMenuStatisticsFrame:setEnvironment(environment)
    self.environment = environment
end
function InGameMenuStatisticsFrame:setPlayerFarm(playerFarm)
    self.playerFarm = playerFarm
end
function InGameMenuStatisticsFrame:updateFinances()
    local currentPeriod = self.environment.currentPeriod
    local i = 1
    for i = i, InGameMenuStatisticsFrame.FINANCES.PAST_PERIOD_COUNT do
        self.pastDayHeader[i]:setText(g_i18n:formatPeriod(currentPeriod - i, false))
    end
    self.pastDayHeader[0]:setText(g_i18n:formatPeriod(currentPeriod, false))
    self.financesList:reloadData()
    self:updateFinancesFooter(self.playerFarm.stats.finances, self.playerFarm.stats.financesHistory)
    self:updateFinancesLoanButtons()
end
function InGameMenuStatisticsFrame:updateFinancesLoanButtons()
    if Platform.gameplay.hasLoans then
        local allowChangeLoan = self:hasPlayerLoanPermission()
        local isBorrowEnabled
        if self.playerFarm.loan < self.playerFarm.loanMax then
            isBorrowEnabled = allowChangeLoan
        else
            isBorrowEnabled = false
        end
        local isRepayEnabled = false
        if self.playerFarm.loan > 0 then
            if self.playerFarm.money < InGameMenuStatisticsFrame.FINANCES.LOAN_STEP then
                allowChangeLoan = false
            end
        else
            allowChangeLoan = isRepayEnabled
        end
        self.borrowButtonInfo.disabled = not isBorrowEnabled
        self.repayButtonInfo.disabled = not allowChangeLoan
        self:setMenuButtonInfoDirty()
    end
end
function InGameMenuStatisticsFrame:updateMoneyUnit()
    self.currentMoneyUnitText = g_i18n:getCurrencySymbol(true)
    if Platform.gameplay.hasLoans then
        local borrowTemplate = g_i18n:getText(InGameMenuStatisticsFrame.L10N_SYMBOL.BUTTON_BORROW)
        local text = string.gsub(borrowTemplate, InGameMenuStatisticsFrame.L10N_SYMBOL.CURRENCY, self.currentMoneyUnitText)
        self.borrowButtonInfo.text = text
        local repayTemplate = g_i18n:getText(InGameMenuStatisticsFrame.L10N_SYMBOL.BUTTON_REPAY)
        local text = string.gsub(repayTemplate, InGameMenuStatisticsFrame.L10N_SYMBOL.CURRENCY, self.currentMoneyUnitText)
        self.repayButtonInfo.text = text
    end
end
function InGameMenuStatisticsFrame:updateFinancesFooter(currentFinances, pastFinances)
    self:updateBalance()
    if Platform.gameplay.hasLoans then
        self:updateLoan()
    end
    self:updateDayTotals(currentFinances, pastFinances)
end
function InGameMenuStatisticsFrame:updateBalance()
    local currentBalance = self.playerFarm:getBalance()
    local balanceMoneyText = g_i18n:formatMoney(currentBalance, 0, false)
    local balanceProfile = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEUTRAL
    if math.floor(currentBalance) <= -1 then
        balanceProfile = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEGATIVE
    end
    self.balanceText:applyProfile(balanceProfile, true)
    self.balanceText:setText(balanceMoneyText .. " " .. self.currentMoneyUnitText)
end
function InGameMenuStatisticsFrame:updateDayTotals(currentFinances, pastFinances)
    local i = 1
    for i = i, InGameMenuStatisticsFrame.FINANCES.PAST_PERIOD_COUNT + 1 do
        local dayFinances
        if i > 1 then
            dayFinances = pastFinances[#pastFinances - (i - 2)]
        else
            dayFinances = currentFinances
        end
        local pastIndex = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEUTRAL
        if dayFinances == nil then
            self.totalText[i]:setText("")
        else
            local dayTotal = 0
            for _, statName in pairs(dayFinances.statNames) do

            end
            local totalMoneyText = g_i18n:formatMoney(dayTotal, 0, false)
            if math.floor(dayTotal) <= -1 then
                pastIndex = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEGATIVE
            end
            self.totalText[i]:setText(totalMoneyText .. " " .. self.currentMoneyUnitText)
        end
        self.totalText[i]:applyProfile(pastIndex, true)
    end
end
function InGameMenuStatisticsFrame:updateLoan()
    local currentLoan = self.playerFarm:getLoan()
    local loanMoneyText = g_i18n:formatMoney(-currentLoan, 0, false)
    local loanProfile = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEUTRAL
    if currentLoan > 0 then
        loanProfile = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEGATIVE
    end
    self.loanText:applyProfile(loanProfile, true)
    self.loanText:setText(loanMoneyText .. " " .. self.currentMoneyUnitText)
end
function InGameMenuStatisticsFrame:hasPlayerLoanPermission()
    return g_currentMission:getHasPlayerPermission("farmManager")
end
function InGameMenuStatisticsFrame:updateMenuButtons()
    local subCategoryIndex = self.subCategoryPaging:getState()
    if subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES then
        if self.sellingStationMode then
            self.sellingStationModeButtonInfo.text = g_i18n:getText(InGameMenuStatisticsFrame.L10N_SYMBOL.LIST_COMMODITIES)
        else
            self.sellingStationModeButtonInfo.text = g_i18n:getText(InGameMenuStatisticsFrame.L10N_SYMBOL.LIST_STATIONS)
        end
        local hotspot = self:getSelectedHotspot()
        if hotspot == nil or (self.sellingStationMode or FocusManager:getFocusedElement() ~= self.priceList) and (not self.sellingStationMode or FocusManager:getFocusedElement() ~= self.productList) then
            self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES] = self.menuButtonInfoPrices
        else
            if hotspot == g_currentMission.currentMapTargetHotspot then
                self.hotspotButtonInfo.text = g_i18n:getText(InGameMenuStatisticsFrame.L10N_SYMBOL.REMOVE_MARKER)
            else
                self.hotspotButtonInfo.text = g_i18n:getText(InGameMenuStatisticsFrame.L10N_SYMBOL.SET_MARKER)
            end
            self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES] = self.menuButtonInfoPricesWithHotspot
        end
    elseif subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW then
        table.removeElement(self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW], self.viewVehicleOnMapButtonInfo)
        table.removeElement(self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW], self.sellVehicleButtonInfo)
        table.removeElement(self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW], self.returnVehicleButtonInfo)
        local hotspot = self.vehicles[self.vehiclesList:getSelectedIndexInSection()]
        if hotspot ~= nil and hotspot.vehicle ~= nil then
            table.addElement(self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW], self.viewVehicleOnMapButtonInfo)
            local vehicle = hotspot.vehicle
            if g_storeManager:getItemByXMLFilename(vehicle.configFileName).canBeSold then
                if vehicle.propertyState == VehiclePropertyState.LEASED then
                    table.addElement(self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW], self.returnVehicleButtonInfo)
                else
                    table.addElement(self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW], self.sellVehicleButtonInfo)
                end
            end
        end
    elseif subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.HANDTOOLS then
        local hotspot, vehicle = self.handToolsList:getSelectedPath()
        local storeItem = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
        if self.handToolsList:getItemCount() > 0 and self.handTools[vehicle] ~= nil then
            local currentHandTool = self.handTools[vehicle]
            local holder = currentHandTool.handTool:getHolder()
            if holder == nil then
                table.insert(storeItem, self.sellHandToolButtonInfo)
                table.insert(storeItem, self.pickUpHandToolButtonInfo)
            else
                if holder:getCanPickupHandToolFromMenu(currentHandTool) then
                    table.insert(storeItem, self.pickUpHandToolButtonInfo)
                end
                if holder == g_localPlayer then
                    table.insert(storeItem, self.sellHandToolButtonInfo)
                    table.insert(storeItem, self.storeHandToolButtonInfo)
                end
            end
        end
        self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.HANDTOOLS] = storeItem
    end
    self:setMenuButtonInfoDirty()
end
function InGameMenuStatisticsFrame:updateFluctuations()
    if not self.sellingStationMode then
        local section, index = self.productList:getSelectedPath()
        local min = math.huge
        local max = 0
        local i = 1
        for i = i, 12 do
            min = math.min(min, self.fillTypes[section][index].economy.history[i])
            max = math.max(max, prices[i])
        end
        local minPrice = min * 1000 * EconomyManager.getPriceMultiplier()
        local maxPrice = max * 1000 * EconomyManager.getPriceMultiplier()
        local i = max - min
        local minPercent = min - i * 0.2
        local hasAnyFluctuations = math.max(minPercent, 0)
        local max = max + i * 0.2
        local hasAnyFluctuations = hasAnyFluctuations ~= max
        self.noFluctuationsText:setVisible(not hasAnyFluctuations)
        self.fluctuationsLayoutBg:setVisible(hasAnyFluctuations)
        self.fluctuationPoints = {}
        self.fluctuationHigh:setVisible(hasAnyFluctuations)
        self.fluctuationHigh:setValue(maxPrice)
        self.fluctuationLow:setVisible(hasAnyFluctuations)
        self.fluctuationLow:setValue(minPrice)
        self.hasAnyFluctuations = hasAnyFluctuations
        if not hasAnyFluctuations then
            return
        end
        local minPercent = math.huge
        local maxPercent = 0
        local month = 1
        for month = month, 12 do
            local percentageInView = (prices[month] - hasAnyFluctuations) / (max - hasAnyFluctuations)
            self.fluctuationPoints[month] = percentageInView * self.fluctuationsContainer.absSize[2]
            if percentageInView < minPercent then
                self.fluctuationLow:setAbsolutePosition(self.monthTexts[month].absPosition[1] + self.monthTexts[month].absSize[1] * 0.5 - self.fluctuationLow.absSize[1] * 0.5, nil)
                minPercent = percentageInView
            end
            if maxPercent < percentageInView then
                self.fluctuationHigh:setAbsolutePosition(self.monthTexts[month].absPosition[1] + self.monthTexts[month].absSize[1] * 0.5 - self.fluctuationHigh.absSize[1] * 0.5, nil)
                maxPercent = percentageInView
            end
        end
    end
    self.priceList:reloadData()
end
function InGameMenuStatisticsFrame:updateTodayBar()
    local env = g_currentMission.environment
    local intoSeason = (env.currentDayInSeason - 1) / env:getDaysPerSeason()
    local parentSize = self.todayBar.parent.size[1]
    self.todayBar:setPosition(parentSize * ((env.currentSeason - 1) * 0.25 + intoSeason * 0.25) + parentSize / (env:getDaysPerSeason() * 4) * 0.5, nil)
end
function InGameMenuStatisticsFrame:rebuildTable()
    local fruitTypes = {}
    local otherTypes = {}
    self.fillTypes = { fruitTypes, otherTypes }
    for _, fillTypeDesc in pairs(g_fillTypeManager:getFillTypes()) do
        if fillTypeDesc.showOnPriceTable then
            if g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(fillTypeDesc.index) then
                table.insert(fruitTypes, fillTypeDesc)
            else
                table.insert(otherTypes, fillTypeDesc)
            end
        end
    end
    local function fillTypeSortFunc(a, b)
        return a.title < b.title
    end
    table.sort(fruitTypes, fillTypeSortFunc)
    table.sort(otherTypes, fillTypeSortFunc)
    self:updateStationData()
    self.productList:reloadData()
end
function InGameMenuStatisticsFrame:getSelectedHotspot()
    local selectedIndex = self.priceList:getSelectedIndexInSection()
    if self.sellingStationMode then
        selectedIndex = self.productList:getSelectedIndexInSection()
    end
    if selectedIndex < 1 then
        return nil
    else
        local stationData = self.currentStationData[selectedIndex]
        if stationData == nil or stationData.owningPlaceable == nil then
            return nil
        else
            return stationData.owningPlaceable:getHotspot(1)
        end
    end
end
function InGameMenuStatisticsFrame.getStorageFillLevel(_, fillType, farmSilo, usedStorages)
    local totalCapacity = 0
    local usedCapacity = 0
    local mission = g_currentMission
    local farmId = mission:getFarmId()
    for _, storage in pairs(mission.storageSystem:getStorages()) do
        if usedStorages[storage] == nil and (storage:getOwnerFarmId() == farmId and (storage.foreignSilo ~= farmSilo and storage:getIsFillTypeSupported(fillType.index))) then
            usedStorages[storage] = true
            usedCapacity = usedCapacity + storage:getFillLevel(fillType.index)
            totalCapacity = totalCapacity + storage:getCapacity(fillType.index)
        end
    end
    if totalCapacity > 0 then
        return usedCapacity, totalCapacity
    else
        return -1, -1
    end
end
function InGameMenuStatisticsFrame:onButtonHotspot()
    local hotspot = self:getSelectedHotspot()
    if hotspot == nil then
        g_currentMission:setMapTargetHotspot(nil)
    else
        if mission.currentMapTargetHotspot == hotspot then
            mission:setMapTargetHotspot(nil)
        else
            mission:setMapTargetHotspot(hotspot)
        end
        self:updateMenuButtons()
    end
end
function InGameMenuStatisticsFrame:onButtonChangeSellingStationMode()
    self.sellingStationMode = not self.sellingStationMode
    if self.sellingStationMode then
        self.priceList:applyProfile("fs25_pricesPriceListFull")
        self.priceListSliderBox:applyProfile("fs25_pricesPriceSliderBoxFull")
    else
        self.priceList:applyProfile("fs25_pricesPriceList")
        self.priceListSliderBox:applyProfile("fs25_pricesPriceSliderBox")
    end
    self.fluctuationsLayoutBg:setVisible(not self.sellingStationMode)
    self.fluctuationsContainer:setVisible(not self.sellingStationMode)
    self.headerProducts:setVisible(not self.sellingStationMode)
    self.headerStations:setVisible(self.sellingStationMode)
    self:updateStationData()
    self.productList:reloadData()
    self.priceList:reloadData()
end
function InGameMenuStatisticsFrame:onButtonSell()
    local item = self.vehicles[self.vehiclesList:getSelectedIndexInSection()]
    if item ~= nil and item.vehicle ~= nil then
        local vehicle = item.vehicle
        local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
        g_shopController:sell(storeItem, vehicle)
    end
end
function InGameMenuStatisticsFrame:onVehicleViewOnMap()
    local item = self.vehicles[self.vehiclesList:getSelectedIndexInSection()]
    local inGameMenu = g_inGameMenu
    inGameMenu:openMapOverview()
    local mapPage = inGameMenu.pageMapOverview
    if Platform.isMobile then
        mapPage = inGameMenu.pageMapMobile
    end
    mapPage:showMapHotspot(item.vehicle:getMapHotspot())
end
function InGameMenuStatisticsFrame:onButtonSellHandTool()
    local item = self.handTools[self.handToolsList:getSelectedIndexInSection()]
    if item ~= nil and item.handTool ~= nil then
        local handTool = item.handTool
        local storeItem = g_storeManager:getItemByXMLFilename(handTool.configFileName)
        g_shopController:sell(storeItem, handTool)
    end
end
function InGameMenuStatisticsFrame:onStoreHandTool()
    local _, index = self.handToolsList:getSelectedPath()
    local item = self.handTools[index]
    if item ~= nil and item.handTool ~= nil then
        local itemName = item.handTool:getName()
        local brand = item.handTool.brand
        if brand ~= nil and brand.title ~= "None" then
        end
        local title = g_i18n:getText("ui_handToolStoreTitle")
        local text = string.format(g_i18n:getText("ui_confirmationStoreHandtool"), itemName)
        YesNoDialog.show(self.onYesNoStoreHandTool, self, text, title)
    end
end
function InGameMenuStatisticsFrame:onYesNoStoreHandTool(yes)
    if yes then
        local section, index = self.handToolsList:getSelectedPath()
        local item = self.handTools[index]
        if item ~= nil and item.handTool ~= nil then
            item.handTool:setHolder(nil)
            local cell = self.handToolsList.sections[section].cells[index]
            if cell ~= nil then
                cell:getAttribute("holder"):setText("-")
            end
        end
        self.handToolInfoDirty = true
        self:updateMenuButtons()
    end
end
function InGameMenuStatisticsFrame:onPickUpHandTool()
    local _, index = self.handToolsList:getSelectedPath()
    local item = self.handTools[index]
    if item ~= nil and item.handTool ~= nil then
        local handTool = item.handTool
        if g_localPlayer:getReachedHandToolLimit(handTool) then
            InfoDialog.show(g_i18n:getText("ui_handToolLimitReached"))
            return
        end
        if not g_localPlayer:getCanPickupHandTool(handTool) then
            InfoDialog.show(g_i18n:getText("ui_handToolCannotBePickedUp"))
            return
        end
        local itemName = handTool:getName()
        local brand = handTool.brand
        if brand ~= nil and brand.title ~= "None" then
        end
        local title = g_i18n:getText("ui_handToolPickupTitle")
        local text = string.format(g_i18n:getText("ui_confirmationPickupHandtool"), itemName)
        YesNoDialog.show(self.onYesNoPickUpHandTool, self, text, title)
    end
end
function InGameMenuStatisticsFrame:onYesNoPickUpHandTool(yes)
    if yes then
        local section, index = self.handToolsList:getSelectedPath()
        local item = self.handTools[index]
        if item ~= nil and item.handTool ~= nil then
            item.handTool:setHolder(g_localPlayer)
            local cell = self.handToolsList.sections[section].cells[index]
            if cell ~= nil then
                cell:getAttribute("holder"):setText(g_localPlayer:getHolderName())
            end
        end
        self:updateMenuButtons()
    end
end
function InGameMenuStatisticsFrame:onButtonBorrow()
    if self:hasPlayerLoanPermission() then
        self.client:getServerConnection():sendEvent(ChangeLoanEvent.new(InGameMenuStatisticsFrame.FINANCES.LOAN_STEP, self.playerFarm.farmId))
    end
end
function InGameMenuStatisticsFrame:onButtonRepay()
    if self:hasPlayerLoanPermission() then
        self.client:getServerConnection():sendEvent(ChangeLoanEvent.new(-InGameMenuStatisticsFrame.FINANCES.LOAN_STEP, self.playerFarm.farmId))
    end
end
function InGameMenuStatisticsFrame:onHourChanged()
    self:updateFluctuations()
    self:updateTodayBar()
end
function InGameMenuStatisticsFrame:onMoneyChange()
    if g_localPlayer ~= nil then
        local farm = g_farmManager:getFarmById(g_localPlayer.farmId)
        if farm.money <= -1 then
            self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE, nil, true)
        else
            self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY, nil, true)
        end
        local moneyText = g_i18n:formatMoney(farm.money, 0, true, false)
        self.currentBalanceText:setText(moneyText)
        if self.shopMoneyBox ~= nil then
            self.shopMoneyBox:invalidateLayout()
            self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
        end
    end
end
function InGameMenuStatisticsFrame:onVehicleSellEvent()
    self:updateVehicles()
end
function InGameMenuStatisticsFrame:onVehicleBuyEvent()
    self:updateVehicles()
end
function InGameMenuStatisticsFrame:onHandToolSellEvent()
    self:updateHandTools()
end
function InGameMenuStatisticsFrame:onHandToolBuyEvent()
    self:updateHandTools()
end
function InGameMenuStatisticsFrame:onHandToolSetHolderEvent()
    self:updateHandTools()
end
function InGameMenuStatisticsFrame:onClickPrices()
    self.subCategoryPaging:setState(InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES, true)
end
function InGameMenuStatisticsFrame:onClickVehicleOverview()
    self.subCategoryPaging:setState(InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW, true)
end
function InGameMenuStatisticsFrame:onClickHandTools()
    self.subCategoryPaging:setState(InGameMenuStatisticsFrame.SUB_CATEGORY.HANDTOOLS, true)
end
function InGameMenuStatisticsFrame:onClickFinances()
    self.subCategoryPaging:setState(InGameMenuStatisticsFrame.SUB_CATEGORY.FINANCES, true)
end
function InGameMenuStatisticsFrame:onClickStatistics()
    self.subCategoryPaging:setState(InGameMenuStatisticsFrame.SUB_CATEGORY.STATISTICS, true)
end
function InGameMenuStatisticsFrame:updateSubCategoryPages(subCategoryIndex)
    for index, page in pairs(self.subCategoryPages) do
        page:setVisible(index == subCategoryIndex)
    end
    self.categoryHeaderIcon:setImageSlice(nil, InGameMenuStatisticsFrame.HEADER_SLICES[subCategoryIndex])
    self.categoryHeaderText:setText(g_i18n:getText(InGameMenuStatisticsFrame.HEADER_TITLES[subCategoryIndex]))
    self.statisticsSlider:setHandleFocus(false)
    self.statisticsSliderBox:setVisible(true)
    if subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES then
        self.statisticsSliderBox:setVisible(false)
    elseif subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW then
        self.statisticsSlider:setDataElement(self.vehiclesList)
    elseif subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.HANDTOOLS then
        self.statisticsSlider:setDataElement(self.handToolsList)
    elseif subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.FINANCES then
        self.statisticsSlider:setDataElement(self.financesList)
        self:updateFinances()
    elseif subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.STATISTICS then
        self.statisticsSlider:setDataElement(self.statisticsList1)
        self.statisticsSlider:setHandleFocus(true)
    else
        self.statisticsSliderBox:setVisible(false)
    end
    FocusManager:setFocus(self.subCategoryPaging)
    self:updateMenuButtons()
end
function InGameMenuStatisticsFrame:getNumberOfSections(list)
    return list == self.productList and not self.sellingStationMode and #self.fillTypes or 1
end
function InGameMenuStatisticsFrame:getNumberOfItemsInSection(list, section)
    return list == self.financesList and #FinanceStats.statNames or (list == self.productList and not self.sellingStationMode and #self.fillTypes[section] or (list == self.priceList and self.sellingStationMode and #self.currentAcceptedFillTypes or ((list == self.productList and self.sellingStationMode or list == self.priceList and not self.sellingStationMode) and #self.currentStationData or (list == self.vehiclesList and #self.vehicles or (list == self.handToolsList and #self.handTools or (self.statsIndices == nil and 0 or (self.statsIndices[self.statisticsList1] ~= nil and #self.statsIndices[self.statisticsList1] or 0)))))))
end
function InGameMenuStatisticsFrame:getTitleForSectionHeader(list, section)
    if list == self.productList and not self.sellingStationMode then
        return g_i18n:getText(InGameMenuStatisticsFrame.PRICE_SECTIONS[section])
    else
        return nil
    end
end
function InGameMenuStatisticsFrame:populateCellForItemInSection(list, section, index, cell)
    if list == self.financesList then
        local stats = self.playerFarm.stats
        local pastFinances = stats.financesHistory
        local statsName = FinanceStats.statNames[index]
        cell:getAttribute("name"):setText(FinanceStats.statNamesI18n[statsName])
        self:setPastDayFinances(cell:getAttribute("todayMinusFour"), pastFinances, 4, statsName)
        self:setPastDayFinances(cell:getAttribute("todayMinusThree"), pastFinances, 3, statsName)
        self:setPastDayFinances(cell:getAttribute("todayMinusTwo"), pastFinances, 2, statsName)
        self:setPastDayFinances(cell:getAttribute("todayMinusOne"), pastFinances, 1, statsName)
        self:setPastDayFinances(cell:getAttribute("today"), stats.finances, 0, statsName)
    elseif list == self.productList and not self.sellingStationMode or list == self.priceList and self.sellingStationMode then
        local stats = self.fillTypes[section][index]
        if self.sellingStationMode then
            stats = g_fillTypeManager:getFillTypeByIndex(self.currentAcceptedFillTypes[index])
        end
        cell:getAttribute("icon"):setVisible(true)
        cell:getAttribute("icon"):setImageFilename(stats.hudOverlayFilename)
        cell:getAttribute("title"):setText(stats.title)
        local currentFinances = {}
        local pastFinances = self:getStorageFillLevel(stats, true, currentFinances)
        local statsName = self:getStorageFillLevel(stats, false, currentFinances)
        if pastFinances < 0 and statsName < 0 then
            cell:getAttribute("info"):setText("-")
        else
            cell:getAttribute("info"):setText(g_i18n:formatVolume(math.max(pastFinances, 0) + math.max(statsName, 0)))
        end
        cell:getAttribute("hotspot"):setVisible(false)
        cell:getAttribute("iconTrain"):setVisible(false)
        cell:getAttribute("iconPallet"):setVisible(false)
        if not self.sellingStationMode then
            return
        end
        local statsNameText = self.currentStationData[self.currentStationIndex]
        local profile = InGameMenuStatisticsFrame.PROFILE.PRICE_NORMAL
        local sellingStation = statsNameText.sellingStation
        local sellingAllowed = false
        if sellingStation ~= nil then
            sellingAllowed = sellingStation:getIsFillTypeAllowed(stats.index)
        end
        local price = cell:getAttribute("price")
        local isBuyingStation
        if sellingStation == nil then
            isBuyingStation = false
        else
            isBuyingStation = sellingAllowed
        end
        price:setVisible(isBuyingStation)
        if sellingStation ~= nil and sellingAllowed then
            local price = sellingStation:getEffectiveFillTypePrice(stats.index) * 1000
            cell:getAttribute("price"):setValue((tostring(price)))
            local priceTrend = sellingStation:getCurrentPricingTrend(stats.index)
            if priceTrend ~= nil then
                if Utils.isBitSet(priceTrend, SellingStation.PRICE_GREAT_DEMAND) then
                    profile = InGameMenuStatisticsFrame.PROFILE.PRICE_GREAT_DEMAND
                elseif Utils.isBitSet(priceTrend, SellingStation.PRICE_CLIMBING) then
                    profile = InGameMenuStatisticsFrame.PROFILE.PRICE_CLIMBING
                elseif Utils.isBitSet(priceTrend, SellingStation.PRICE_FALLING) then
                    profile = InGameMenuStatisticsFrame.PROFILE.PRICE_FALLING
                end
            end
        end
        cell:getAttribute("priceTrend"):applyProfile(profile)
        local price = statsNameText.buyingStation
        local priceTrend = statsNameText.palletBuyingStation
        local isBuyingStation = true
        if price == nil then
            isBuyingStation = priceTrend ~= nil
        end
        cell:getAttribute("buyPrice"):setVisible(isBuyingStation)
        if isBuyingStation then
            local price = nil
            if price == nil then
                if priceTrend:getHasPalletForFillType(stats.index) then
                    price = priceTrend:getEffectivePricePerPallet(stats.index)
                end
            else
                price = price:getEffectiveFillTypePrice(stats.index) * 1000
            end
            if price == nil then
                cell:getAttribute("buyPrice"):setVisible(false)
            else
                cell:getAttribute("buyPrice"):setValue((tostring(price)))
            end
        end
    elseif list == self.productList and self.sellingStationMode or list == self.priceList and not self.sellingStationMode then
        local stats = self.currentStationData[index]
        local currentFinances, pastFinances = self.productList:getSelectedPath()
        local statsNameText = stats.owningPlaceable ~= nil and stats.owningPlaceable:getHotspot(1) or nil
        local profile = cell:getAttribute("hotspot")
        local sellingAllowed = statsNameText ~= nil
        profile:setVisible(sellingAllowed)
        if statsNameText ~= nil then
            cell:getAttribute("hotspot").getIsSelected = function()
                -- upvalues: (copy) statsNameText
                local mission = g_currentMission
                local isTagActive = false
                if mission.currentMapTargetHotspot ~= nil then
                    isTagActive = statsNameText == mission.currentMapTargetHotspot
                end
                return isTagActive
            end
        end
        cell:getAttribute("title"):setText(stats.name)
        cell:getAttribute("iconTrain"):setVisible(stats.isTrainStation)
        cell:getAttribute("iconPallet"):setVisible(stats.isPalletStation)
        local profile = "-"
        if statsNameText ~= nil then
            local sellingStation, sellingAllowed, price = getWorldTranslation(g_cameraManager:getActiveCamera())
            local priceTrend, isBuyingStation = statsNameText:getWorldPosition()
            local price = MathUtil.vector2Length(sellingStation - priceTrend, price - isBuyingStation)
            profile = g_i18n:formatDistance(price, 0)
        end
        cell:getAttribute("info"):setText(profile)
        cell:getAttribute("icon"):setVisible(false)
        if self.sellingStationMode then
            return
        end
        local sellingStation = InGameMenuStatisticsFrame.PROFILE.PRICE_NORMAL
        local sellingAllowed = stats.sellingStation
        local price = cell:getAttribute("price")
        local isBuyingStation = sellingAllowed ~= nil
        price:setVisible(isBuyingStation)
        if sellingAllowed ~= nil then
            local price = sellingAllowed:getEffectiveFillTypePrice(self.fillTypes[currentFinances][pastFinances].index) * 1000
            cell:getAttribute("price"):setValue((tostring(price)))
            local priceTrend = sellingAllowed:getCurrentPricingTrend(statsName.index)
            if priceTrend ~= nil then
                if Utils.isBitSet(priceTrend, SellingStation.PRICE_GREAT_DEMAND) then
                    sellingStation = InGameMenuStatisticsFrame.PROFILE.PRICE_GREAT_DEMAND
                elseif Utils.isBitSet(priceTrend, SellingStation.PRICE_CLIMBING) then
                    sellingStation = InGameMenuStatisticsFrame.PROFILE.PRICE_CLIMBING
                elseif Utils.isBitSet(priceTrend, SellingStation.PRICE_FALLING) then
                    sellingStation = InGameMenuStatisticsFrame.PROFILE.PRICE_FALLING
                end
            end
        end
        cell:getAttribute("priceTrend"):applyProfile(sellingStation)
        local price = stats.buyingStation
        local priceTrend = stats.palletBuyingStation
        local isBuyingStation = true
        if price == nil then
            isBuyingStation = priceTrend ~= nil
        end
        cell:getAttribute("buyPrice"):setVisible(isBuyingStation)
        if isBuyingStation then
            local leasingElement
            if price == nil then
                leasingElement = priceTrend:getEffectivePricePerPallet(statsName.index)
            else
                leasingElement = price:getEffectiveFillTypePrice(statsName.index) * 1000
            end
            cell:getAttribute("buyPrice"):setValue((tostring(leasingElement)))
            return
        end
    elseif list == self.vehiclesList then
        local stats = self.vehicles[index]
        local currentFinances = stats.vehicle
        local pastFinances = g_storeManager:getItemByXMLFilename(currentFinances.configFileName)
        if pastFinances ~= nil then
            cell:getAttribute("name"):setText(stats.columns[InGameMenuStatisticsFrame.COLUMN_NAME].text)
            local profile = LicensePlates.getSpecValuePlateText(nil, currentFinances) or "-"
            cell:getAttribute("licensePlate"):setText(profile)
            local sellingStation = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEUTRAL
            if pastFinances.lifetime <= currentFinances.age then
                sellingStation = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEGATIVE
            end
            local price = cell:getAttribute("age")
            price:setText(stats.columns[InGameMenuStatisticsFrame.COLUMN_AGE].text)
            price:applyProfile(sellingStation, true)
            cell:getAttribute("operatingHours"):setText(stats.columns[InGameMenuStatisticsFrame.COLUMN_HOURS].text)
            local isBuyingStation = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEUTRAL
            local statsNameText = stats.columns[InGameMenuStatisticsFrame.COLUMN_DAMAGE]
            if statsNameText.value >= InGameMenuStatisticsFrame.DAMAGE_NEGATIVE_THRESHOLD then
                isBuyingStation = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEGATIVE
            end
            local price = cell:getAttribute("damage")
            price:setText(statsNameText.text)
            price:applyProfile(isBuyingStation, true)
            cell:getAttribute("leasing"):setText(stats.columns[InGameMenuStatisticsFrame.COLUMN_LEASING].text)
            cell:getAttribute("value"):setText(stats.columns[InGameMenuStatisticsFrame.COLUMN_VALUE].text)
            return
        end
    elseif list == self.handToolsList then
        local stats = self.handTools[index]
        local currentFinances = stats.handTool
        local pastFinances = g_storeManager:getItemByXMLFilename(currentFinances.configFileName)
        if pastFinances ~= nil then
            cell:getAttribute("name"):setText(stats.columns[InGameMenuStatisticsFrame.COLUMN_NAME].text)
            local profile = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEUTRAL
            if pastFinances.lifetime <= currentFinances.age then
                profile = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEGATIVE
            end
            local sellingAllowed = cell:getAttribute("age")
            sellingAllowed:setText(stats.columns[InGameMenuStatisticsFrame.COLUMN_AGE].text)
            sellingAllowed:applyProfile(profile, true)
            cell:getAttribute("holder"):setText(stats.columns[InGameMenuStatisticsFrame.COLUMN_HOLDER].text)
            return
        end
    else
        local stats = self.statsIndices[list][index]
        if stats == nil then
            cell:getAttribute("name"):setText("")
            cell:getAttribute("session"):setText("")
            cell:getAttribute("total"):setText("")
            return
        end
        local currentFinances = self.statsData[stats]
        cell:getAttribute("name"):setText(currentFinances.name)
        cell:getAttribute("session"):setText(currentFinances.valueSession)
        cell:getAttribute("total"):setText(currentFinances.valueTotal)
    end
end
function InGameMenuStatisticsFrame:setPastDayFinances(cell, financesData, dayIndex, statsName)
    if InGameMenuStatisticsFrame.FINANCES.PAST_PERIOD_COUNT >= dayIndex then
        local value = "-"
        local profile = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEUTRAL
        if dayIndex > 0 then
            financesData = financesData[#financesData - (dayIndex - 1)]
        end
        if financesData ~= nil then
            local pastIndex = financesData[statsName]
            value = g_i18n:formatMoney(pastIndex, 0, false) .. " " .. self.currentMoneyUnitText
            if math.floor(pastIndex) <= -1 then
                profile = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEGATIVE
            end
        end
        cell:applyProfile(profile, true)
        cell:setText(value)
    end
end
function InGameMenuStatisticsFrame:onListSelectionChanged(list, section, index)
    if list == self.productList then
        if self.sellingStationMode then
            self.currentStationIndex = index
            self:updateAcceptedFillTypes(self.currentStationData[index])
            self.priceList:reloadData()
            self:updateMenuButtons()
        else
            self:updateStationData(self.fillTypes[section][index])
            self.noSellpointsText:setVisible(#self.currentStationData == 0)
            self.priceList:reloadData()
            self:updateFluctuations()
            self:updateMenuButtons()
        end
    elseif list == self.priceList then
        self:updateMenuButtons()
        return
    elseif list == self.vehiclesList then
        self:updateItemAttributeData(index)
        self:updateMenuButtons()
    elseif list == self.handToolsList then
        self:updateMenuButtons()
    end
end
function InGameMenuStatisticsFrame:updateStationData(fillTypeDesc)
    self.currentStationData = {}
    local mission = g_currentMission
    for _, station in pairs(mission.storageSystem:getUnloadingStations()) do
        if station:isa(SellingStation) and (not station.hideFromPricesMenu and (fillTypeDesc == nil or station:getIsFillTypeAllowed(fillTypeDesc.index))) then
            local owningPlaceable = station.owningPlaceable
            local stationData = ({})[owningPlaceable]
            if stationData == nil then
                local foundFillType = false
                for fillTypeIndex, _ in pairs(station.supportedFillTypes) do
                    local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
                    if fillType ~= nil then
                        if fillType.showOnPriceTable then
                            foundFillType = true
                        end
                    end
                end
                if foundFillType then
                    stationData = {
                        ["name"] = station:getName(),
                        ["owningPlaceable"] = owningPlaceable
                    }
                    table.addElement(self.currentStationData, stationData)
                    if owningPlaceable ~= nil then
                        placeableToStation[owningPlaceable] = stationData
                    end
                    goto l8
                end
            else
                ::l8::
                if station.isTrainStation then
                    stationData.isTrainStation = true
                end
                if station.isPalletStation then
                    stationData.isPalletStation = true
                end
                stationData.sellingStation = station
            end
        end
    end
    for _, station in pairs(mission.storageSystem:getLoadingStations()) do
        if station:isa(BuyingStation) and (fillTypeDesc == nil or station:getIsFillTypeSupported(fillTypeDesc.index)) then
            local owningPlaceable = station.owningPlaceable
            local stationData = placeableToStation[owningPlaceable]
            if stationData == nil then
                local foundFillType = false
                for fillTypeIndex, _ in pairs(station.supportedFillTypes) do
                    local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
                    if fillType ~= nil then
                        if fillType.showOnPriceTable then
                            foundFillType = true
                        end
                    end
                end
                if foundFillType then
                    stationData = {
                        ["name"] = station:getName(),
                        ["owningPlaceable"] = owningPlaceable
                    }
                    table.addElement(self.currentStationData, stationData)
                    if owningPlaceable ~= nil then
                        placeableToStation[owningPlaceable] = stationData
                    end
                    goto l28
                end
            else
                ::l28::
                stationData.buyingStation = station
            end
        end
    end
    for _, station in pairs(mission.storageSystem:getPalletBuyingStations()) do
        if fillTypeDesc == nil or station:getHasPalletForFillType(fillTypeDesc.index) then
            local owningPlaceable = placeableToStation[station]
            if owningPlaceable == nil then
                owningPlaceable = {
                    ["name"] = station:getName(),
                    ["owningPlaceable"] = station
                }
                table.addElement(self.currentStationData, owningPlaceable)
                placeableToStation[station] = owningPlaceable
            end
            owningPlaceable.isPalletStation = true
            owningPlaceable.palletBuyingStation = station
        end
    end
    table.sort(self.currentStationData, function(station1, station2)
        return station1.name < station2.name
    end)
end
function InGameMenuStatisticsFrame:updateAcceptedFillTypes(placeable)
    self.currentAcceptedFillTypes = {}
    if placeable ~= nil then
        local sellingStation = placeable.sellingStation
        if sellingStation ~= nil then
            for fillTypeIndex, fillTypeDesc in pairs(sellingStation.acceptedFillTypes) do
                table.addElement(self.currentAcceptedFillTypes, fillTypeIndex)
            end
        end
        local buyingStation = placeable.buyingStation
        if buyingStation ~= nil then
            for fillTypeDesc, _ in pairs(buyingStation.supportedFillTypes) do
                table.addElement(self.currentAcceptedFillTypes, fillTypeDesc)
            end
        end
        local palletBuyingStation = placeable.palletBuyingStation
        if palletBuyingStation ~= nil then
            for _, _ in pairs(palletBuyingStation.spec_palletBuyingStation.fillTypeIndexToPallet) do
                table.addElement(self.currentAcceptedFillTypes, _)
            end
        end
    end
end
function InGameMenuStatisticsFrame:updateItemAttributeData(index)
    local vehicle = index or self.vehiclesList.selectedIndex
    local vehicle = self.vehicles[vehicle].vehicle
    if vehicle ~= nil and vehicle:getMapHotspot() ~= nil then
        local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
        local displayItem = g_shopController:makeDisplayItem(storeItem, vehicle, vehicle.configurations)
        local x, z = vehicle:getMapHotspot():getWorldPosition()
        self.itemDetailsMap:setCenterToWorldPosition(x, z)
        self.itemDetailsMap:setMapZoom(7)
        self.itemDetailsMap:setMapAlpha(1)
        if displayItem ~= nil and self:getIsVisible() then
            self:assignItemAttributeData(displayItem)
            return
        end
    end
    self.detailBox:setVisible(false)
end
function InGameMenuStatisticsFrame:buildCellDatabase()
    for k, clone in pairs(self.detailsTemplates) do
        clone:delete()
        self.detailsTemplates[k] = nil
    end
    self.detailsTemplates = {}
    local i = #self.attributesLayout.elements
    for i = i, 1, -1 do
        local k = self.attributesLayout.elements[i]
        local clone = k.name
        self.detailsTemplates[clone] = k:clone()
        self.detailsCache[clone] = {}
    end
end
function InGameMenuStatisticsFrame:dequeueDetailsCell(name)
    if self.detailsTemplates[name] == nil then
        return nil
    end
    local cache = self.detailsCache[name]
    local cell
    if #cache > 0 then
        cell = cache[#cache]
        cache[#cache] = nil
    else
        cell = self.detailsTemplates[name]:clone()
    end
    self.attributesLayout:addElement(cell)
    return cell
end
function InGameMenuStatisticsFrame:queueDetailsCell(cell)
    local cache = self.detailsCache[cell.name]
    cache[#cache + 1] = cell
    self.attributesLayout:removeElement(cell)
    cell:unlinkElement()
end
function InGameMenuStatisticsFrame:applySorting(column)
    if self.sortByColumn == column and self.sortOrder ~= InGameMenuStatisticsFrame.SORT_ORDER_ASC then
        self.sortOrder = InGameMenuStatisticsFrame.SORT_ORDER_ASC
    else
        self.sortOrder = InGameMenuStatisticsFrame.SORT_ORDER_DESC
    end
    self.sortByColumn = column
    self:updateView()
end
function InGameMenuStatisticsFrame:onClickButtonSortByName()
    self:applySorting(InGameMenuStatisticsFrame.COLUMN_NAME)
end
function InGameMenuStatisticsFrame:onClickButtonSortByAge()
    self:applySorting(InGameMenuStatisticsFrame.COLUMN_AGE)
end
function InGameMenuStatisticsFrame:onClickButtonSortByHours()
    self:applySorting(InGameMenuStatisticsFrame.COLUMN_HOURS)
end
function InGameMenuStatisticsFrame:onClickButtonSortByDamage()
    self:applySorting(InGameMenuStatisticsFrame.COLUMN_DAMAGE)
end
function InGameMenuStatisticsFrame:onClickButtonSortByLeasing()
    self:applySorting(InGameMenuStatisticsFrame.COLUMN_LEASING)
end
function InGameMenuStatisticsFrame:onClickButtonSortByValue()
    self:applySorting(InGameMenuStatisticsFrame.COLUMN_VALUE)
end
function InGameMenuStatisticsFrame:onCreateButtonSortByName(element)
    self.sortIcons[InGameMenuStatisticsFrame.COLUMN_NAME] = {
        [InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
        [InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
    }
end
function InGameMenuStatisticsFrame:onCreateButtonSortByAge(element)
    self.sortIcons[InGameMenuStatisticsFrame.COLUMN_AGE] = {
        [InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
        [InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
    }
end
function InGameMenuStatisticsFrame:onCreateButtonSortByHours(element)
    self.sortIcons[InGameMenuStatisticsFrame.COLUMN_HOURS] = {
        [InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
        [InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
    }
end
function InGameMenuStatisticsFrame:onCreateButtonSortByDamage(element)
    self.sortIcons[InGameMenuStatisticsFrame.COLUMN_DAMAGE] = {
        [InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
        [InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
    }
end
function InGameMenuStatisticsFrame:onCreateButtonSortByLeasing(element)
    self.sortIcons[InGameMenuStatisticsFrame.COLUMN_LEASING] = {
        [InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
        [InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
    }
end
function InGameMenuStatisticsFrame:onCreateButtonSortByValue(element)
    self.sortIcons[InGameMenuStatisticsFrame.COLUMN_VALUE] = {
        [InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
        [InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
    }
end
function InGameMenuStatisticsFrame:applySortingHandTools(column)
    if self.handToolInfoDirty then
        self:updateHandTools()
    end
    if self.sortByColumnHandTools == column and self.sortOrderHandTools ~= InGameMenuStatisticsFrame.SORT_ORDER_ASC then
        self.sortOrderHandTools = InGameMenuStatisticsFrame.SORT_ORDER_ASC
    else
        self.sortOrderHandTools = InGameMenuStatisticsFrame.SORT_ORDER_DESC
    end
    self.sortByColumnHandTools = column
    self:updateViewHandTools()
end
function InGameMenuStatisticsFrame:onClickButtonSortByNameHandTools()
    self:applySortingHandTools(InGameMenuStatisticsFrame.COLUMN_NAME)
end
function InGameMenuStatisticsFrame:onClickButtonSortByAgeHandTools()
    self:applySortingHandTools(InGameMenuStatisticsFrame.COLUMN_AGE)
end
function InGameMenuStatisticsFrame:onClickButtonSortByHolder()
    self:applySortingHandTools(InGameMenuStatisticsFrame.COLUMN_HOLDER)
end
function InGameMenuStatisticsFrame:onCreateButtonSortByNameHandTools(element)
    self.sortIconsHandTools[InGameMenuStatisticsFrame.COLUMN_NAME] = {
        [InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
        [InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
    }
end
function InGameMenuStatisticsFrame:onCreateButtonSortByAgeHandTools(element)
    self.sortIconsHandTools[InGameMenuStatisticsFrame.COLUMN_AGE] = {
        [InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
        [InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
    }
end
function InGameMenuStatisticsFrame:onCreateButtonSortByHolder(element)
    self.sortIconsHandTools[InGameMenuStatisticsFrame.COLUMN_HOLDER] = {
        [InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
        [InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
    }
end
InGameMenuStatisticsFrame.DAMAGE_NEGATIVE_THRESHOLD = 0.8
InGameMenuStatisticsFrame.L10N_SYMBOL = {
    ["WEEK_DAY_TEMPLATE"] = "ui_financesDay",
    ["BUTTON_BORROW"] = "button_borrow5000",
    ["BUTTON_REPAY"] = "button_repay5000",
    ["BUTTON_NEXT"] = "",
    ["BUTTON_PREV"] = "",
    ["CURRENCY"] = "$CURRENCY_SYMBOL",
    ["SILO_CAPACITY"] = "ui_silos_totalCapacity",
    ["SET_MARKER"] = "action_tag",
    ["REMOVE_MARKER"] = "action_untag",
    ["LIST_STATIONS"] = "action_listStations",
    ["LIST_COMMODITIES"] = "action_listCommodities"
}
InGameMenuStatisticsFrame.PROFILE = {
    ["VALUE_CELL_NEUTRAL"] = "fs25_statisticsTextWhite",
    ["VALUE_CELL_NEGATIVE"] = "fs25_statisticsTextRed",
    ["PRICE_NORMAL"] = "fs25_pricesPriceListArrow",
    ["PRICE_FALLING"] = "fs25_pricesPriceListArrowFalling",
    ["PRICE_CLIMBING"] = "fs25_pricesPriceListArrowClimbing",
    ["PRICE_GREAT_DEMAND"] = "fs25_pricesPriceListArrowGreatDemand",
    ["ICON_FRUIT_TYPE"] = "fs25_itemDetailsFruitIcon",
    ["ICON_FILL_TYPES"] = "shopListAttributeIconFillTypes",
    ["ICON_SEED_FILL_TYPES"] = "shopListAttributeIconSeeds",
    ["ICON_INPUT"] = "shopListAttributeIconInput",
    ["ICON_OUTPUT"] = "shopListAttributeIconOutput"
}
InGameMenuStatisticsFrame.HEADER_SLICES = {
    [InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES] = "gui.icon_ingameMenu_prices",
    [InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW] = "gui.icon_vehicleDealer_machines",
    [InGameMenuStatisticsFrame.SUB_CATEGORY.HANDTOOLS] = "gui.icon_ingameMenu_handToolsOverview",
    [InGameMenuStatisticsFrame.SUB_CATEGORY.FINANCES] = "gui.icon_ingameMenu_finances",
    [InGameMenuStatisticsFrame.SUB_CATEGORY.STATISTICS] = "gui.icon_ingameMenu_finances"
}
InGameMenuStatisticsFrame.HEADER_TITLES = {
    [InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES] = "ui_prices",
    [InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW] = "ui_garageOverview",
    [InGameMenuStatisticsFrame.SUB_CATEGORY.HANDTOOLS] = "ui_handTools",
    [InGameMenuStatisticsFrame.SUB_CATEGORY.FINANCES] = "ui_finances",
    [InGameMenuStatisticsFrame.SUB_CATEGORY.STATISTICS] = "ui_statistics"
}
InGameMenuStatisticsFrame.PRICE_SECTIONS = { "helpLine_IconOverview_fillType", "ui_other" }