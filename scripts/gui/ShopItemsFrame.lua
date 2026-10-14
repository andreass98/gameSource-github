ShopItemsFrame = {}
local ShopItemsFrame_mt = Class(ShopItemsFrame, TabbedMenuFrameElement)
ShopItemsFrame.CELL_NAME_DETAIL = "detailTemplate"
ShopItemsFrame.CELL_NAME_VALUE = "valueTemplate"
ShopItemsFrame.CELL_NAME_FILL_TYPES = "fillTypesTemplate"
local function NO_CALLBACK() end
function ShopItemsFrame.register()
    local shopItemsFrame = ShopItemsFrame.new()
    g_gui:loadGui("dataS/gui/ShopItemsFrame.xml", "ShopItemsFrame", shopItemsFrame, true)
end
function ShopItemsFrame.new(target, custom_mt)
    -- upvalues: (copy) ShopItemsFrame_mt, (copy) NO_CALLBACK
    local self = ShopItemsFrame:superClass().new(target, custom_mt or ShopItemsFrame_mt)
    self.notifyActivatedDisplayItemCallback = NO_CALLBACK
    self.notifySelectedDisplayItemCallback = NO_CALLBACK
    self.displayItems = {}
    self.detailsCache = {}
    self.detailsTemplates = {}
    self.clonedElements = {}
    self.marqueeBoxes = {}
    self.overlayCache = OverlayCache.new()
    return self
end
function ShopItemsFrame.createFromExistingGui(gui, guiName)
    local newGui = ShopItemsFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function ShopItemsFrame:initialize()
    local slotsVisible = g_currentMission.slotSystem:getAreSlotsVisible()
    self.shopSlotsIcon:setVisible(slotsVisible)
    self.shopSlotsText:setVisible(slotsVisible)
    self:buildCellDatabase()
end
function ShopItemsFrame:delete()
    for k, clone in pairs(self.clonedElements) do
        clone:delete()
        self.clonedElements[k] = nil
    end
    for k, clone in pairs(self.detailsTemplates) do
        clone:delete()
        self.detailsTemplates[k] = nil
    end
    for k, clone in pairs(self.detailsCache) do
        for l, clone in pairs(clone) do
            clone:delete()
            self.detailsCache[k][l] = nil
        end
        self.detailsCache[k] = nil
    end
    ShopItemsFrame:superClass().delete(self)
end
function ShopItemsFrame:onFrameOpen()
    ShopItemsFrame:superClass().onFrameOpen(self)
    self:setSoundSuppressed(true)
    FocusManager:setFocus(self.itemsList)
    self:setSoundSuppressed(false)
    self.detailBox:setVisible(#self.displayItems > 0)
    self.noItemsText:setVisible(#self.displayItems == 0)
    if self.shopMoneyBox ~= nil then
        self.shopMoneyBox:invalidateLayout()
        self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
        self.itemsHeaderText:setSize(self.itemsHeaderText.parent.absSize[1] - self.shopMoneyBoxBg.absSize[1] - 180 * g_pixelSizeScaledX)
    end
end
function ShopItemsFrame:onFrameClose()
    ShopItemsFrame:superClass().onFrameClose(self)
    self.overlayCache:clearCache()
end
function ShopItemsFrame:setItemClickCallback(itemClickedCallback)
    -- upvalues: (copy) NO_CALLBACK
    self.notifyActivatedDisplayItemCallback = itemClickedCallback or NO_CALLBACK
end
function ShopItemsFrame:setItemSelectCallback(itemSelectedCallback)
    -- upvalues: (copy) NO_CALLBACK
    self.notifySelectedDisplayItemCallback = itemSelectedCallback or NO_CALLBACK
end
function ShopItemsFrame:setHeader(headerText, headerIconSlice)
    self.itemsHeaderText:setText(headerText)
    self.itemsHeaderText:updateAbsolutePosition()
    self.itemsHeaderIcon:setImageSlice(nil, headerIconSlice)
end
function ShopItemsFrame:setCategory(rootName, categoryName, categorySliceId, secondaryCategoryName, headerTitleOverride)
    self:setHeader(headerTitleOverride or (secondaryCategoryName or categoryName), categorySliceId)
    if self.categoryName ~= categoryName then
        self.itemsList.setNextOpenIndex = 1
    end
    self.rootName = rootName
    self.categoryName = categoryName
    self.secondaryCategoryName = secondaryCategoryName
    self:setTitle(headerTitleOverride or (secondaryCategoryName or categoryName))
end
function ShopItemsFrame:setShowBalance(doShowBalance)
    self.currentBalanceLabel:setVisible(doShowBalance)
    self.currentBalanceText:setVisible(doShowBalance)
end
function ShopItemsFrame:setShowNavigation(doShowNavigation)
    if self.breadcrumbs ~= nil then
        self.breadcrumbs:setVisible(doShowNavigation)
    end
end
function ShopItemsFrame:setCurrentBalance(balance, balanceString)
    local balanceProfile = ShopMenu.GUI_PROFILE.SHOP_MONEY
    if math.floor(balance) <= -1 then
        balanceProfile = ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE
    end
    self.currentBalanceText:applyProfile(balanceProfile, nil, true)
    self.currentBalanceText:setText(balanceString)
    if self.shopMoneyBox ~= nil then
        self.shopMoneyBox:invalidateLayout()
        self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
    end
end
function ShopItemsFrame:setSlotsUsage(slotsUsage, maxSlots)
    local slotsVisible = g_currentMission.slotSystem:getAreSlotsVisible()
    if slotsVisible then
        local text = string.format("%0d / %0d", slotsUsage, maxSlots)
        local profile = ShopMenu.GUI_PROFILE.SHOP_MONEY
        if slotsUsage / maxSlots >= ShopMenu.SLOTS_USAGE_CRITICAL_THRESHOLD then
            profile = ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE
        end
        if self.shopSlotsText.profile ~= profile then
            self.shopSlotsText:applyProfile(profile)
        end
        self.shopSlotsText:setText(text)
    end
    self.shopSlotsIcon:setVisible(slotsVisible)
    self.shopSlotsText:setVisible(slotsVisible)
    if self.shopMoneyBox ~= nil then
        self.shopMoneyBox:invalidateLayout()
        self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
    end
end
function ShopItemsFrame:setDisplayItems(displayItems)
    self:setSoundSuppressed(true)
    self.displayItems = displayItems or {}
    self.itemsList:reloadData()
    self.detailBox:setVisible(#self.displayItems > 0)
    self.noItemsText:setVisible(#self.displayItems == 0)
end
function ShopItemsFrame.getStoreItemDisplayPrice(_, storeItem, saleItem)
    if saleItem ~= nil then
        return g_i18n:formatMoney(saleItem.price, 0, true, true)
    end
    if storeItem.isInAppPurchase then
        return storeItem.price
    end
    local price = g_currentMission.economyManager:getBuyPrice(storeItem)
    return g_i18n:formatMoney(price, 0, true, true)
end
function ShopItemsFrame:assignItemAttributeData(displayItem)
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
    self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, displayItem.fillTypeIconFilenames)
    self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, displayItem.foodFillTypeIconFilenames)
    self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_SEED_FILL_TYPES, displayItem.seedTypeIconFilenames)
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
    self.itemDetailsDescription:setText(displayItem.functionText)
    self.itemDetailsOwned:setText(displayItem.numOwned or "")
    self.itemDetailsLeased:setText(displayItem.numLeased or "")
    local i = self.itemDetailsAmountBox
    local clone = self.itemDetailsLeased.text ~= ""
    i:setVisible(clone)
    self.attributesLayout:invalidateLayout()
end
function ShopItemsFrame:assignItemTextData(displayItem)
    if Platform.isMobile and self.attrVehicleValue ~= nil then
        local storeItem = displayItem.storeItem
        self.attrVehicleValue:setText(self:getStoreItemDisplayPrice(storeItem))
        self.attrVehicleValue:setVisible(not storeItem.isInAppPurchase)
        self.attrVehicleValueIcon:setVisible(not storeItem.isInAppPurchase)
    end
    for i, value in pairs(displayItem.attributeValues) do
        local cell = self:dequeueDetailsCell(ShopItemsFrame.CELL_NAME_DETAIL)
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
function ShopItemsFrame:assignItemFillTypesData(baseIconProfile, iconFilenames)
    if #iconFilenames > 0 then
        local totalWidth = 0
        local cell = self:dequeueDetailsCell(ShopItemsFrame.CELL_NAME_FILL_TYPES)
        local cellIcon = cell:getDescendantByName("icon")
        local iconsLayout = cell:getDescendantByName("iconsLayout")
        cellIcon:applyProfile(baseIconProfile)
        for _, iconFilename in pairs(iconFilenames) do
            local icon = self.fruitIconTemplate:clone(iconsLayout)
            icon:setVisible(true)
            table.insert(self.clonedElements, icon)
            icon:applyProfile(ShopItemsFrame.PROFILE.ICON_FRUIT_TYPE)
            icon:setImageFilename(iconFilename)
            self.overlayCache:addOverlay(iconFilename)
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
function ShopItemsFrame:onOpenItem(_, _, _, _, wasAlreadySelected)
    local displayItem = self.displayItems[self.itemsList.selectedIndex]
    local lastInputMode = g_inputBinding:getLastInputMode()
    if displayItem ~= nil and (lastInputMode == GS_INPUT_HELP_MODE_TOUCH and wasAlreadySelected or lastInputMode ~= GS_INPUT_HELP_MODE_TOUCH) then
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
        self.notifyActivatedDisplayItemCallback(displayItem)
    end
end
function ShopItemsFrame:onListSelectionChanged(_, _, index)
    self:updateItemAttributeData(index)
end
function ShopItemsFrame:updateItemAttributeData(index)
    local displayItem = index or self.itemsList.selectedIndex
    local displayItem = self.displayItems[displayItem]
    if displayItem ~= nil and self:getIsVisible() then
        self:assignItemAttributeData(displayItem)
        self.notifySelectedDisplayItemCallback(displayItem, displayItem)
    end
end
function ShopItemsFrame:getSelectedDisplayItem()
    return self.displayItems[self.itemsList.selectedIndex]
end
function ShopItemsFrame:getNumberOfItemsInSection(_, _)
    return #self.displayItems
end
function ShopItemsFrame:populateCellForItemInSection(_, _, index, cell)
    local displayItem = self.displayItems[index]
    local storeItem = displayItem.storeItem
    if storeItem.brandIndex == nil then
        cell:getAttribute("brandIcon"):setVisible(false)
        cell:getAttribute("icon"):applyProfile("fs25_shopItemsListItemImageWithoutBrand")
    else
        local brandIcon = cell:getAttribute("brandIcon")
        local brandIndex = storeItem.brandIndex
        if displayItem.concreteItem.getBrand ~= nil then
            brandIndex = displayItem.concreteItem:getBrand()
        end
        local itemBrand = g_brandManager:getBrandByIndex(brandIndex)
        brandIcon:setImageFilename(storeItem.customBrandIcon or itemBrand.image)
        brandIcon:setVisible(true)
        self.overlayCache:addOverlay(storeItem.customBrandIcon or itemBrand.image)
        cell:getAttribute("icon"):applyProfile("fs25_shopItemsListItemImage")
    end
    if storeItem.isInAppPurchase then
        local brandIcon = cell:getAttribute("priceTag")
        local brandIndex = cell:getAttribute("priceTagText")
        cell:getAttribute("icon"):setImageFilename(storeItem.imageFilename)
        cell:getAttribute("title"):setText(storeItem.title)
        if storeItem.canBeRecovered then
            brandIcon:applyProfile("fs25_shopItemsListItemPriceTagRecoverable")
        else
            brandIcon:applyProfile("fs25_shopItemsListItemPriceTag")
        end
        local itemBrand = getTextWidth(brandIndex.textSize, storeItem.priceText) + CORNER_WIDTH * 2
        brandIcon:setSize(itemBrand)
        brandIcon:setVisible(true)
        brandIndex:setSize(itemBrand)
        brandIndex:setText(storeItem.priceText)
    else
        local brandIcon = storeItem.imageFilename
        local brandIndex = displayItem.saleItem
        if displayItem.concreteItem.getImageFilename ~= nil then
            brandIcon = displayItem.concreteItem:getImageFilename()
        end
        cell:getAttribute("icon"):setImageFilename(brandIcon)
        self.overlayCache:addOverlay(brandIcon)
        local itemBrand = storeItem.name
        if displayItem.concreteItem.getName ~= nil then
            itemBrand = displayItem.concreteItem:getName()
        end
        cell:getAttribute("title"):setText(itemBrand)
        if Platform.isMobile then
            cell:getAttribute("value"):setVisible(false)
        else
            cell:getAttribute("value"):setText(self:getStoreItemDisplayPrice(storeItem, brandIndex))
        end
        if storeItem.isMod and storeItem.dlcTitle == nil then
            cell:getAttribute("modDlc"):setText("Mod")
        elseif storeItem.isMod and storeItem.dlcTitle ~= nil then
            cell:getAttribute("modDlc"):setText(storeItem.dlcTitle .. " (Mod)")
        elseif storeItem.dlcTitle == nil then
            cell:getAttribute("modDlc"):setText("")
        else
            cell:getAttribute("modDlc"):setText(storeItem.dlcTitle)
        end
        if brandIndex ~= nil then
            local defaultPrice = StoreItemUtil.getPriceWithBoughtConfigurations(storeItem, brandIndex.boughtConfigurations, "price")
            local discount = 0
            if defaultPrice > 0 then
                discount = -(1 - brandIndex.price / defaultPrice) * 100
            end
            local priceStr = string.format("%d%%", discount)
            cell:getAttribute("priceTagText"):setText(priceStr)
        end
        local defaultPrice = cell:getAttribute("priceTag")
        local priceStr = brandIndex ~= nil
        defaultPrice:setVisible(priceStr)
    end
end
function ShopItemsFrame:resetListSelection()
    self:setSoundSuppressed(true)
    self.itemsList:setSelectedIndex(1, nil, true)
    self.itemsList:makeCellVisible(1, 1, true)
    self:setSoundSuppressed(false)
end
function ShopItemsFrame:buildCellDatabase()
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
function ShopItemsFrame:dequeueDetailsCell(name)
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
function ShopItemsFrame:queueDetailsCell(cell)
    local cache = self.detailsCache[cell.name]
    cache[#cache + 1] = cell
    self.attributesLayout:removeElement(cell)
    cell:unlinkElement()
end
function ShopItemsFrame:update(dt)
    ShopItemsFrame:superClass().update(self, dt)
    self:updateMarqueeAnimation(dt)
end
function ShopItemsFrame:updateMarqueeAnimation(dt)
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
ShopItemsFrame.PROFILE = {
    ["ICON_FRUIT_TYPE"] = "fs25_itemDetailsFruitIcon",
    ["ICON_FILL_TYPES"] = "shopListAttributeIconFillTypes",
    ["ICON_SEED_FILL_TYPES"] = "shopListAttributeIconSeeds",
    ["ICON_INPUT"] = "shopListAttributeIconInput",
    ["ICON_OUTPUT"] = "shopListAttributeIconOutput"
}