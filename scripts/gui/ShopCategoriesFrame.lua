ShopCategoriesFrame = {}
local ShopCategoriesFrame_mt = Class(ShopCategoriesFrame, TabbedMenuFrameElement)
function ShopCategoriesFrame.register()
    local shopCategoriesFrame = ShopCategoriesFrame.new()
    g_gui:loadGui("dataS/gui/ShopCategoriesFrame.xml", "ShopCategoriesFrame", shopCategoriesFrame, true)
end
local function NO_CALLBACK() end
function ShopCategoriesFrame.new(target, custom_mt)
    -- upvalues: (copy) ShopCategoriesFrame_mt, (copy) NO_CALLBACK
    local self = TabbedMenuFrameElement.new(target, custom_mt or ShopCategoriesFrame_mt)
    self.notifyActivatedCategoryCallback = NO_CALLBACK
    self.headerLabelText = ""
    self.categories = {}
    self.categoryTypes = {}
    self.useSections = true
    self.overlayCache = OverlayCache.new()
    return self
end
function ShopCategoriesFrame.createFromExistingGui(gui, guiName)
    local newGui = ShopCategoriesFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function ShopCategoriesFrame:initialize(categoryTypes, categories, categoryClickedCallback, categorySelectedCallback, headerText, headerIconSlice, listCellName, listEmptyCellName)
    -- upvalues: (copy) NO_CALLBACK
    self.headerLabelText = headerText
    self.headerIconSlice = headerIconSlice
    self.listCellName = listCellName
    self.listEmptyCellName = listEmptyCellName
    self:setCategories(categoryTypes, categories, false)
    self.notifyActivatedCategoryCallback = categoryClickedCallback or NO_CALLBACK
    self.notifySelectedCategoryCallback = categorySelectedCallback or NO_CALLBACK
    if self.categoryHeaderText ~= nil then
        self.categoryHeaderText:setText(headerText)
        self.categoryHeaderText:updateAbsolutePosition()
        self.categoryHeaderIcon:setImageSlice(nil, headerIconSlice)
    end
    self:setTitle(headerText)
    local slotsVisible = g_currentMission.slotSystem:getAreSlotsVisible()
    self.shopSlotsIcon:setVisible(slotsVisible)
    self.shopSlotsText:setVisible(slotsVisible)
end
function ShopCategoriesFrame:setCategories(categoryTypes, categories, doReloadList)
    for _, category in pairs(categoryTypes) do
        if categories[category.name] ~= nil then
            table.insert(self.categoryTypes, category)
        end
    end
    self.categories = categories
    if doReloadList == nil or doReloadList == true then
        self.categoryList:reloadData()
    end
end
function ShopCategoriesFrame:onFrameOpen()
    ShopCategoriesFrame:superClass().onFrameOpen(self)
    self.notifySelectedCategoryCallback(nil)
    self.categoryList:reloadData()
    self:setSoundSuppressed(true)
    FocusManager:setFocus(self.categoryList)
    self:setSoundSuppressed(false)
    if self.shopMoneyBox ~= nil then
        self.shopMoneyBox:invalidateLayout()
        self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
    end
end
function ShopCategoriesFrame:setCurrentBalance(balance, balanceString)
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
function ShopCategoriesFrame:setSlotsUsage(slotsUsage, maxSlots)
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
function ShopCategoriesFrame:onOpenCategory()
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    local categoryType = self.categories[self.categoryTypes[self.categoryList.selectedSectionIndex].name]
    if categoryType ~= nil then
        local category = categoryType[self.categoryList.selectedIndex]
        if category ~= nil then
            self.notifyActivatedCategoryCallback(category.id, self.headerLabelText, category.label, self.headerIconSlice, self.filter)
        end
    end
end
function ShopCategoriesFrame:onListSelectionChanged(_, section, index)
    self.notifySelectedCategoryCallback(self.categories[self.categoryTypes[section].name][index])
end
function ShopCategoriesFrame:onPageChanged(page, fromPage)
    ShopCategoriesFrame:superClass().onPageChanged(self, page, fromPage)
    self.categoryList:scrollTo((page - 1) * (self.categoryList.numVisibleItems * self.categoryList.itemsPerCol) + 1)
end
function ShopCategoriesFrame:getNumberOfSections(_)
    return #self.categoryTypes
end
function ShopCategoriesFrame:getNumberOfItemsInSection(_, section)
    return self.categories[self.categoryTypes[section].name] ~= nil and #self.categories[self.categoryTypes[section].name] or 0
end
function ShopCategoriesFrame:populateCellForItemInSection(_, section, index, cell)
    local category = self.categories[self.categoryTypes[section].name][index]
    if Platform.isMobile then
        if self.id == "pageShopVehicles" then
            cell:getAttribute("icon"):applyProfile("shopCategoryItemImageVehicle")
        else
            cell:getAttribute("icon"):applyProfile("shopCategoryItemImageBrand")
        end
    end
    cell:getAttribute("title"):setText(category.label)
    cell:getAttribute("icon"):setImageFilename(category.iconFilename)
    self.overlayCache:addOverlay(category.iconFilename)
    local attr = cell:getAttribute("coinBg")
    if attr ~= nil then
        attr:setVisible(Platform.hasInAppPurchases and category.id == "COINS")
    end
end
function ShopCategoriesFrame:getTitleForSectionHeader(_, section)
    return self.categoryTypes[section].title or (self.categoryTypes[section].name or "")
end
function ShopCategoriesFrame:getCellTypeForItemInSection(_, _, _)
    return self.listCellName
end
function ShopCategoriesFrame:getEmptyCellType(list)
    if list == self.categoryList then
        return self.listEmptyCellName
    else
        return nil
    end
end