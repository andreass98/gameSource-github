AnimalScreen = {}
AnimalScreen.TRANSPORTATION_FEE = 200
AnimalScreen.SELECTION_SOURCE = 1
AnimalScreen.SELECTION_TARGET = 2
AnimalScreen.SELECTION_AMOUNT = 3
AnimalScreen.INPUT_CONTEXT = "AnimalScreen"
local AnimalScreen_mt = Class(AnimalScreen, ScreenElement)
function AnimalScreen.show(husbandry, loadingVehicle, isDealer)
    g_animalScreen:setController(husbandry, loadingVehicle, isDealer)
    g_gui:showGui("AnimalScreen")
end
function AnimalScreen.register()
    local animalScreen = AnimalScreen.new()
    g_gui:loadGui("dataS/gui/AnimalScreen.xml", "AnimalScreen", animalScreen)
    return animalScreen
end
function AnimalScreen.new(custom_mt)
    -- upvalues: (copy) AnimalScreen_mt
    local self = ScreenElement.new(nil, custom_mt or AnimalScreen_mt)
    self.isBuyMode = true
    self.isSourceSelected = true
    self.isOpen = false
    self.lastBalance = 0
    self.numAnimals = 0
    self.selectionState = nil
    self.sourceSelectorStateToAnimalType = {}
    return self
end
function AnimalScreen.createFromExistingGui(gui, guiName)
    local newGui = AnimalScreen.new()
    local controller = gui:getController()
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    newGui:setController(controller.husbandry, controller.loadingVehicle, gui.isDealer)
    g_animalScreen = newGui
    return newGui
end
function AnimalScreen:setController(husbandry, loadingVehicle, isDealer)
    self.isDealer = isDealer
    local controller
    if husbandry == nil then
        if loadingVehicle == nil then
            controller = AnimalScreenDealer.new()
        elseif isDealer then
            controller = AnimalScreenDealerTrailer.new(loadingVehicle)
        else
            controller = AnimalScreenTrailer.new(loadingVehicle)
        end
    elseif loadingVehicle == nil then
        controller = AnimalScreenDealerFarm.new(husbandry)
    else
        controller = AnimalScreenTrailerFarm.new(husbandry, loadingVehicle)
    end
    controller:init()
    self.controller = controller
    self.controller:setAnimalsChangedCallback(self.onAnimalsChanged, self)
    self.controller:setActionTypeCallback(self.onActionTypeChanged, self)
    self.controller:setSourceActionFinishedCallback(self.onSourceActionFinished, self)
    self.controller:setTargetActionFinishedCallback(self.onTargetActionFinished, self)
    self.controller:setErrorCallback(self.onError, self)
    self.sourceList:reloadData(true)
end
function AnimalScreen:getController()
    return self.controller
end
function AnimalScreen:onGuiSetupFinished()
    AnimalScreen:superClass().onGuiSetupFinished(self)
    if GS_IS_MOBILE_VERSION then
        self.infoIcon = self.infoIconMobile
        self.infoName = self.infoNameMobile
        self.infoValue = self.infoValueMobile
        self.infoTitle = self.infoTitleMobile
        self.infoDescription = self.infoDescriptionMobile
        self.buttonSelect:delete()
        self.buttonSelect = nil
        self.buttonApply:delete()
        self.buttonApply = nil
        self.numAnimalsElement = nil
    end
    if not Platform.isMobile then
        self.numAnimalsElement:setTexts({ "1" })
    end
    self.sourceDotTemplate:unlinkElement()
    FocusManager:removeElement(self.sourceDotTemplate)
    FocusManager:linkElements(self.sourceList, FocusManager.TOP, self.sourceSelector)
    FocusManager:linkElements(self.sourceList, FocusManager.BOTTOM, nil)
end
function AnimalScreen:delete()
    for k, clone in pairs(self.sourceDotBox.elements) do
        clone:delete()
        self.sourceDotBox.elements[k] = nil
    end
    self.sourceDotTemplate:delete()
    AnimalScreen:superClass().delete(self)
end
function AnimalScreen:onOpen()
    AnimalScreen:superClass().onOpen(self)
    self.isOpen = true
    g_gameStateManager:setGameState(GameState.MENU_ANIMAL_SHOP)
    self:onClickBuyMode(true)
    if self.sourceList:getItemCount() == 0 then
        self:onClickSellMode(true)
        if self.sourceList:getItemCount() == 0 then
            g_gui:changeScreen(nil)
            InfoDialog.show(g_i18n:getText("ui_noAnimalsToSell"))
            return
        end
    end
    self:onMoneyChange()
    g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChange, self)
    self:toggleCustomInputContext(true, AnimalScreen.INPUT_CONTEXT)
    self:registerActionEvents()
end
function AnimalScreen:initSubcategories()
    for i, dot in pairs(self.sourceDotBox.elements) do
        dot:delete()
        self.sourceDotBox.elements[i] = nil
    end
    local animalTypeTexts = {}
    self.sourceSelectorStateToAnimalType = {}
    for dot, animalType in pairs(self.controller:getSourceAnimalTypes(self.isBuyMode)) do
        local dot
        self.sourceDotTemplate:clone(self.sourceDotBox).getIsSelected = function()
            -- upvalues: (copy) self, (copy) dot
            return self.sourceSelector:getState() == dot
        end
        table.insert(animalTypeTexts, animalType.groupTitle)
        self.sourceSelectorStateToAnimalType[dot] = animalType.typeIndex
    end
    self.sourceSelector:setTexts(animalTypeTexts)
    self.sourceDotBox:invalidateLayout()
    local i = #animalTypeTexts > 1
    self.sourceDotBox:setVisible(i)
end
function AnimalScreen:onClose(_)
    AnimalScreen:superClass().onClose(self)
    self.controller:reset()
    self:removeActionEvents()
    self:toggleCustomInputContext(false, AnimalScreen.INPUT_CONTEXT)
    g_currentMission:resetGameState()
    g_currentMission:showMoneyChange(MoneyType.NEW_ANIMALS_COST)
    g_currentMission:showMoneyChange(MoneyType.SOLD_ANIMALS)
    g_messageCenter:unsubscribeAll(self)
    g_inputBinding:removeActionEventsByTarget(self)
    self.isOpen = false
end
function AnimalScreen:onVehicleLeftTrigger()
    if self.isOpen then
        InfoDialog.show(g_i18n:getText(AnimalScreen.SYMBOL_L10N.ERROR_TRAILER_LEFT), self.onClickOkVehicleLeft, self)
    end
end
function AnimalScreen:onClickOkVehicleLeft()
    self:onClickBack()
end
function AnimalScreen:setSelectionState(state, _)
    if state == AnimalScreen.SELECTION_TARGET and #self.targetSelector.texts == 0 then
        return false
    elseif state == AnimalScreen.SELECTION_TARGET and (#self.targetSelector.texts == 1 and not self.targetSlider.needsSlider) then
        if self.selectionState == AnimalScreen.SELECTION_SOURCE then
            self:setSelectionState(AnimalScreen.SELECTION_AMOUNT)
        else
            self:setSelectionState(AnimalScreen.SELECTION_SOURCE)
        end
    elseif state == AnimalScreen.SELECTION_AMOUNT and not self.numAnimalsBox:getIsVisible() then
        if #self.targetSelector.texts == 1 and not self.targetSlider.needsSlider then
            self:setSelectionState(AnimalScreen.SELECTION_SOURCE)
        else
            self:setSelectionState(AnimalScreen.SELECTION_TARGET)
        end
    else
        self.sourceBoxBg:setSelected(state == AnimalScreen.SELECTION_SOURCE, true)
        self.sourceBoxArrow:setSelected(state == AnimalScreen.SELECTION_SOURCE, true)
        self.targetBoxBg:setSelected(state == AnimalScreen.SELECTION_TARGET)
        self.numAnimalsBoxBg:setSelected(state == AnimalScreen.SELECTION_AMOUNT)
        self.isAutoUpdatingList = true
        if state == AnimalScreen.SELECTION_SOURCE then
            if self.selectionState ~= state then
                if self.sourceList:getItemCount() > 0 then
                    FocusManager:setFocus(self.sourceList)
                else
                    FocusManager:setFocus(self.sourceSelector)
                end
            end
        elseif state == AnimalScreen.SELECTION_TARGET then
            if self.targetSlider.needsSlider then
                FocusManager:setFocus(self.targetSlider)
                FocusManager:linkElements(self.targetSlider, FocusManager.RIGHT, self.numAnimalsElement)
                FocusManager:linkElements(self.targetSlider, FocusManager.TOP, self.targetSelector)
                FocusManager:linkElements(self.targetSelector, FocusManager.BOTTOM, self.targetSlider)
                if #self.targetSelector.texts > 1 then
                    FocusManager:linkElements(self.targetSlider, FocusManager.LEFT, self.targetSelector)
                elseif self.sourceList:getItemCount() > 0 then
                    FocusManager:linkElements(self.targetSlider, FocusManager.LEFT, self.sourceList)
                else
                    FocusManager:linkElements(self.targetSlider, FocusManager.TOP, self.sourceSelector)
                end
                if self.sourceList:getItemCount() > 0 then
                    FocusManager:linkElements(self.targetSelector, FocusManager.TOP, self.sourceList)
                else
                    FocusManager:linkElements(self.targetSelector, FocusManager.TOP, self.sourceSelector)
                end
            else
                FocusManager:setFocus(self.targetSelector)
                FocusManager:linkElements(self.targetSelector, FocusManager.BOTTOM, self.numAnimalsElement)
                if self.sourceList:getItemCount() > 0 then
                    FocusManager:linkElements(self.targetSelector, FocusManager.TOP, self.sourceList)
                else
                    FocusManager:linkElements(self.targetSelector, FocusManager.TOP, self.sourceSelector)
                end
            end
        else
            FocusManager:setFocus(self.numAnimalsElement)
            if self.targetSlider.needsSlider then
                FocusManager:linkElements(self.numAnimalsElement, FocusManager.TOP, self.targetSlider)
                FocusManager:linkElements(self.numAnimalsElement, FocusManager.BOTTOM, self.targetSlider)
            elseif #self.targetSelector.texts > 1 then
                FocusManager:linkElements(self.numAnimalsElement, FocusManager.TOP, self.targetSelector)
                FocusManager:linkElements(self.numAnimalsElement, FocusManager.BOTTOM, self.targetSelector)
            else
                FocusManager:linkElements(self.numAnimalsElement, FocusManager.TOP, self.sourceList)
                FocusManager:linkElements(self.numAnimalsElement, FocusManager.BOTTOM, self.sourceList)
            end
        end
        self.isAutoUpdatingList = false
        self.selectionState = state
        if self.isBuyMode then
            if self.buttonApply == nil then
                if self.buttonBuy ~= nil then
                    self.buttonBuy:setText(self.controller:getSourceActionText())
                end
            else
                self.buttonApply:setText(self.controller:getSourceActionText())
            end
        elseif self.buttonApply == nil then
            if self.buttonSell ~= nil then
                self.buttonSell:setText(self.controller:getTargetActionText())
            end
        else
            self.buttonApply:setText(self.controller:getTargetActionText())
        end
        self.noHusbandriesTextBox:setVisible(#self.targetSelector.texts == 0 and self.isBuyMode)
        self.targetListEmptyText:setVisible(#self.targetSelector.texts > 0 and self.targetList:getItemCount() == 0)
        self.targetIcon:setVisible(#self.targetSelector.texts > 0)
        self.targetSelector:setVisible(#self.targetSelector.texts > 0)
        self.targetText:setVisible(#self.targetSelector.texts > 0)
        self.targetListContainer:setVisible(self.isBuyMode and (self.controller.husbandry == nil or self.controller.trailer ~= nil))
        self.buttonBuy:setVisible(state == AnimalScreen.SELECTION_AMOUNT and self.isBuyMode)
        self.buttonSell:setVisible(state == AnimalScreen.SELECTION_AMOUNT and not self.isBuyMode)
        self.buttonSelect:setVisible(state < AnimalScreen.SELECTION_AMOUNT and (self.sourceList:getItemCount() > 0 and (self.targetContainer:getIsVisible() or not self.isBuyMode)) and self.numAnimalsElement:getIsVisible())
        self.buttonsPanel:invalidateLayout()
        return true
    end
end
function AnimalScreen:updatePrice()
    local hasCosts, price, fee, total = self:getPrice(self.numAnimalsElement:getState())
    self.infoPrice:setValue(0)
    self.infoFee:setValue(0)
    self.infoTotal:setValue(0)
    self.infoPrice:setFormat(hasCosts and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
    self.infoFee:setFormat(hasCosts and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
    self.infoTotal:setFormat(hasCosts and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
    self.infoPrice:setValue(hasCosts and price and price or "-")
    self.infoFee:setValue(hasCosts and fee and fee or "-")
    self.infoTotal:setValue(hasCosts and total and total or "-")
end
function AnimalScreen:updateInfoBox(isSourceSelected)
    if not g_gui.currentlyReloading then
        if isSourceSelected == nil then
            isSourceSelected = self.isSourceSelected
        end
        local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
        local item
        if self.isBuyMode then
            item = self.controller:getSourceItems(animalTypeIndex, self.isBuyMode)[self.sourceList.selectedIndex]
        else
            item = self.controller:getTargetItems()[self.sourceList.selectedIndex]
        end
        local subType = self.infoIcon
        local infos = item ~= nil
        subType:setVisible(infos)
        local subType = self.infoName
        local infos = item ~= nil
        subType:setVisible(infos)
        if item ~= nil then
            self.infoIcon:setImageFilename(item:getFilename())
            self.infoDescription:setText(item:getDescription())
            local subType = g_currentMission.animalSystem:getSubTypeByIndex(item:getSubTypeIndex())
            local itemName = g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex)
            self.infoName:setText(itemName)
            local infos = item:getInfos()
            for k, infoTitle in ipairs(self.infoTitle) do
                local info = infos[k]
                local infoValue = self.infoValue[k]
                infoTitle:setVisible(info ~= nil)
                infoValue:setVisible(info ~= nil)
                if info ~= nil then
                    infoTitle:setText(infos[k].title)
                    infoValue:setText(infos[k].value)
                end
            end
            if not Platform.isMobile then
                self:updatePrice()
            end
        end
    end
end
function AnimalScreen:getPrice(numAnimals)
    local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
    if self.isBuyMode then
        local hasCosts, price, fee, total = self.controller:getSourcePrice(animalTypeIndex, self.sourceList.selectedIndex, numAnimals)
        return hasCosts, price, fee, total
    else
        local hasCosts, price, fee, total = self.controller:getTargetPrice(animalTypeIndex, animalIndex, numAnimals)
        return hasCosts, price, fee, total
    end
end
function AnimalScreen:updateScreen(blockTargetUpdate)
    self.isAutoUpdatingList = true
    self.sourceList:reloadData(true)
    self.isAutoUpdatingList = false
    local targetSelection, hasSourceItems
    if self.isBuyMode then
        targetSelection, hasSourceItems = self.controller:getSourceData(self.sourceSelector:getState())
    else
        targetSelection, hasSourceItems = self.controller:getTargetData(self.sourceSelector:getState())
    end
    self.targetText:setText(hasSourceItems)
    self.targetItems = targetSelection
    local targetSelection = {}
    for _, target in pairs(targetSelection) do
        local animalType = g_currentMission.animalSystem:getTypeByIndex(self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()])
        local numAnimalsText = " (" .. target:getNumOfAnimals() .. "/" .. target:getMaxNumOfAnimals(animalType) .. ")"
        table.insert(targetSelection, target:getName() .. numAnimalsText)
    end
    self.targetSelector:setTexts(targetSelection)
    if blockTargetUpdate ~= true and #targetSelection > 0 then
        self.targetSelector:setState(1)
    end
    self:onTargetSelectionChanged(true)
    self:setSelectionState(AnimalScreen.SELECTION_SOURCE)
    local hasSourceItems = self.sourceList:getItemCount() > 0
    self.detailsContainer:setVisible(hasSourceItems)
    if hasSourceItems then
        self:updatePrice()
        self:updateInfoBox()
    end
    self.tabBuy:setSelected(self.isBuyMode)
    self.tabSell:setSelected(not self.isBuyMode)
end
function AnimalScreen:updateConditionDisplay(husbandry)
    if husbandry == nil then
        self.husbandryInfoContainer:setVisible(false)
    else
        self.husbandryInfoContainer:setVisible(true)
        local infos = husbandry:getConditionInfos()
        for index, row in ipairs(self.conditionRow) do
            local info = infos[index]
            row:setVisible(info ~= nil)
            if info ~= nil then
                local valueText = info.valueText or g_i18n:formatVolume(info.value, 0, info.customUnitText)
                self.conditionLabel[index]:setText(info.title)
                self.conditionValue[index]:setText(valueText)
                self:setStatusBarValue(self.conditionStatusBar[index], info.ratio, info.invertedBar)
            end
        end
    end
end
function AnimalScreen:updateFoodDisplay(husbandry)
    if husbandry == nil then
        self.husbandryInfoContainer:setVisible(false)
    else
        self.husbandryInfoContainer:setVisible(true)
        local infos = husbandry:getFoodInfos()
        local totalCapacity = 0
        local totalValue = 0
        for index, row in ipairs(self.foodRow) do
            local info = infos[index]
            row:setVisible(info ~= nil)
            if info ~= nil then
                local valueText = g_i18n:formatVolume(info.value, 0)
                totalCapacity = math.max(info.capacity, totalCapacity)
                self.foodLabel[index]:setText(info.title)
                self.foodValue[index]:setText(valueText)
                self:setStatusBarValue(self.foodStatusBar[index], info.ratio, info.invertedBar)
            end
        end
        local totalValueText = g_i18n:formatVolume(totalValue, 0)
        local totalRatio = 0
        if totalCapacity > 0 then
            totalRatio = totalValue / totalCapacity
        end
        self.foodRowTotalValue:setText(totalValueText)
        self:setStatusBarValue(self.foodRowTotalStatusBar, totalRatio, false)
        self.foodHeader:setText(string.format("%s (%s)", g_i18n:getText("ui_silos_totalCapacity"), g_i18n:getText("animals_foodMixEffectiveness")))
    end
end
function AnimalScreen.setStatusBarValue(_, statusBarElement, value, invertedBar, disabled)
    local testValue
    if invertedBar then
        testValue = 1 - value
    else
        testValue = value
    end
    if InGameMenuAnimalsFrame.STATUS_BAR_MEDIUM < testValue and testValue <= InGameMenuAnimalsFrame.STATUS_BAR_HIGH then
        statusBarElement:setImageColor(AnimalScreen.COLOR.ORANGE)
    elseif InGameMenuAnimalsFrame.STATUS_BAR_HIGH < testValue then
        statusBarElement:setImageColor(AnimalScreen.COLOR.RED)
    else
        statusBarElement:setImageColor(AnimalScreen.COLOR.GREEN)
    end
    local minSize = 0
    if statusBarElement.startSize ~= nil then
        minSize = statusBarElement.startSize[1] + statusBarElement.endSize[1]
    end
    statusBarElement:setSize(math.max(minSize, (statusBarElement.parent.size[1] - statusBarElement.margin[1] * 2) * math.min(1, value)), nil)
    statusBarElement:setDisabled((Utils.getNoNil(disabled, false)))
end
function AnimalScreen:onMoneyChange()
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
function AnimalScreen:onAnimalsChanged()
    self:initSubcategories()
    self:updateScreen(true)
    if self.sourceSelector:getState() == 0 or not self.isBuyMode and (self.sourceSelector:getState() == 1 and self.sourceList:getItemCount() == 0) then
        self:onPageNext()
    end
end
function AnimalScreen:onFocusTargetSelection()
    if self.selectionState ~= AnimalScreen.SELECTION_TARGET then
        self:setSelectionState(AnimalScreen.SELECTION_TARGET)
    end
end
function AnimalScreen:onTargetSelectionChanged(blockSelectionStateUpdate)
    if not blockSelectionStateUpdate and (self.isBuyMode and self.selectionState ~= AnimalScreen.SELECTION_TARGET) then
        self:setSelectionState(AnimalScreen.SELECTION_TARGET)
    end
    local sourceSelectorState = self.sourceSelector:getState()
    local targetSelectorState = self.targetSelector:getState()
    local animalTypeIndex = self.sourceSelectorStateToAnimalType[sourceSelectorState]
    if self.isBuyMode or not (self.isDealer and sourceSelectorState) then
        sourceSelectorState = targetSelectorState
    end
    self.controller:setCurrentHusbandry(animalTypeIndex, sourceSelectorState, self.isBuyMode)
    if self.isBuyMode then
        self.husbandryInfoContainer:setVisible(false)
    else
        self:updateFoodDisplay(self.controller.husbandry)
        self:updateConditionDisplay(self.controller.husbandry)
        self.husbandryRequirementsLayout:invalidateLayout()
    end
    if targetSelectorState > 0 then
        if self.targetItems[targetSelectorState].storeItem == nil then
            local trailerStoreItem = g_storeManager:getItemByXMLFilename(self.targetItems[targetSelectorState].xmlFile.filename)
            if trailerStoreItem ~= nil then
                self.targetIcon:setImageFilename(trailerStoreItem.imageFilename)
            end
        else
            self.targetIcon:setImageFilename(self.targetItems[targetSelectorState].storeItem.imageFilename)
        end
    end
    if self.isBuyMode then
        self.targetList:reloadData()
    else
        self.sourceList:reloadData(true)
    end
    self:setMaxNumAnimals(animalTypeIndex)
    FocusManager:linkElements(self.targetSlider, FocusManager.RIGHT, self.numAnimalsElement)
    if #self.targetSelector.texts > 1 then
        FocusManager:linkElements(self.targetSlider, FocusManager.LEFT, self.targetSelector)
    elseif self.sourceList:getItemCount() > 0 then
        FocusManager:linkElements(self.targetSlider, FocusManager.LEFT, self.sourceList)
    else
        FocusManager:linkElements(self.targetSlider, FocusManager.TOP, self.sourceSelector)
    end
    if self.targetSlider.needsSlider then
        FocusManager:linkElements(self.targetSelector, FocusManager.BOTTOM, self.targetSlider)
    else
        FocusManager:linkElements(self.targetSelector, FocusManager.BOTTOM, self.numAnimalsElement)
    end
    if self.sourceList:getItemCount() > 0 then
        FocusManager:linkElements(self.targetSelector, FocusManager.TOP, self.sourceList)
    else
        FocusManager:linkElements(self.targetSelector, FocusManager.TOP, self.sourceSelector)
    end
end
function AnimalScreen:setMaxNumAnimals(animalTypeIndex)
    local maxElements = self.controller:getMaxNumAnimals()
    local hasTargetItems = self.isBuyMode
    if not hasTargetItems then
        hasTargetItems = #self.controller:getTargetItems() > 0
    end
    local texts
    if self.isBuyMode then
        if hasTargetItems then
            texts = math.max(0, (math.min(maxElements, self.controller:getSourceMaxNumAnimals(animalTypeIndex, self.sourceList.selectedIndex))))
            if texts then
                goto l10
            end
        end
        texts = 0
    else
        if hasTargetItems then
            texts = math.max(0, (math.min(maxElements, self.controller:getTargetMaxNumAnimals(animalIndex))))
            if texts then
                goto l10
            end
        end
        texts = 0
    end
    ::l10::
    local texts = {}
    local i = 1
    for i = i, texts do
        table.insert(texts, (tostring(i)))
    end
    self.numAnimalsElement:setTexts(texts)
    if #texts >= 1 then
        self.numAnimalsElement:setState(1)
    end
    local i = #texts >= 1
    self.numAnimalsBox:setVisible(i)
    local i = #texts >= 1
    self.infoBox:setVisible(i)
    if hasTargetItems then
        self:updatePrice()
    end
    local i = self.sourceList:getItemCount() > 0 and (self.targetContainer:getIsVisible() or not self.isBuyMode)
    if i then
        i = #texts >= 1
    end
    self.buttonSelect:setVisible(i)
    self.buttonsPanel:invalidateLayout()
end
function AnimalScreen.onActionTypeChanged(_, _, text)
    if text == nil then
        MessageDialog.hide()
    else
        MessageDialog.show(text)
    end
end
function AnimalScreen:onSourceActionFinished(isWarning, text)
    local msgType = DialogElement.TYPE_INFO
    if isWarning then
        msgType = DialogElement.TYPE_WARNING
    end
    InfoDialog.show(text, self.updateScreen, self, msgType, nil, nil, true)
end
function AnimalScreen:onTargetActionFinished(isWarning, text)
    local msgType = DialogElement.TYPE_INFO
    if isWarning then
        msgType = DialogElement.TYPE_WARNING
    end
    InfoDialog.show(text, self.updateScreen, self, msgType, nil, nil, true)
end
function AnimalScreen.onError(_, text)
    InfoDialog.show(text, nil, nil, DialogElement.TYPE_WARNING)
end
function AnimalScreen:onClickBack()
    AnimalScreen:superClass().onClickBack(self)
    if Platform.isMobile or self.selectionState <= AnimalScreen.SELECTION_SOURCE then
        self:changeScreen(nil)
        return
    elseif self.isBuyMode then
        self:setSelectionState(self.selectionState - 1)
    else
        self:setSelectionState(self.selectionState - 2)
    end
end
function AnimalScreen:onClickSelect()
    if self.selectionState < AnimalScreen.SELECTION_AMOUNT then
        if self.isBuyMode then
            self:setSelectionState(self.selectionState + 1)
        else
            self:setSelectionState(self.selectionState + 2)
        end
    end
    return true
end
function AnimalScreen:onAnimalsTradedCallback(buying, tradeAccepted, animalTypeIndex, animalIndex, numAnimals)
    self.numAnimals = numAnimals
    if not tradeAccepted then
        return false
    end
    if buying then
        YesNoDialog.show(self.onYesNoSource, self, self.controller:getApplySourceConfirmationText(animalTypeIndex, animalIndex, numAnimals))
    else
        YesNoDialog.show(self.onYesNoTarget, self, self.controller:getApplyTargetConfirmationText(animalTypeIndex, animalIndex, numAnimals))
    end
    return true
end
function AnimalScreen:onClickBuyMode(isAutoUpdatingList, isRecursion)
    self.isBuyMode = true
    self.targetSelector.leftButtonElement:setVisible(true)
    self.targetSelector.rightButtonElement:setVisible(true)
    self:initSubcategories()
    self.sourceList:setSelectedItem(1, 1, nil, true)
    self.sourceSelector:setState(1, true)
    self.isAutoUpdatingList = isAutoUpdatingList
    self:updateScreen()
    self.isAutoUpdatingList = false
    self:setSelectionState(AnimalScreen.SELECTION_SOURCE, true)
    if #self.sourceSelector.texts == 0 or #self.sourceSelector.texts == 1 and self.sourceList:getItemCount() == 0 then
        if isRecursion ~= true then
            self:onClickSellMode(isAutoUpdatingList, true)
        end
        if #self.targetSelector.texts == 0 or #self.targetSelector.texts == 1 and self.sourceList:getItemCount() == 0 then
            g_gui:changeScreen(nil)
        end
        if isAutoUpdatingList ~= true then
            InfoDialog.show(g_i18n:getText("ui_noAnimalsToSell"))
        end
    end
end
function AnimalScreen:onClickSellMode(isAutoUpdatingList, isRecursion)
    self.isBuyMode = false
    self.targetSelector.leftButtonElement:setVisible(false)
    self.targetSelector.rightButtonElement:setVisible(false)
    self:initSubcategories()
    self.sourceList:setSelectedItem(1, 1)
    self.sourceSelector:setState(1, true)
    self.isAutoUpdatingList = isAutoUpdatingList
    self:updateScreen()
    self.isAutoUpdatingList = false
    self:setSelectionState(AnimalScreen.SELECTION_SOURCE, true)
    if #self.targetSelector.texts == 0 or #self.targetSelector.texts == 1 and self.sourceList:getItemCount() == 0 then
        if isRecursion ~= true then
            self:onClickBuyMode(isAutoUpdatingList, true)
        end
        if #self.sourceSelector.texts == 0 or #self.sourceSelector.texts == 1 and self.sourceList:getItemCount() == 0 then
            g_gui:changeScreen(nil)
        end
        if isAutoUpdatingList ~= true then
            InfoDialog.show(g_i18n:getText("ui_noAnimalsToSell"))
        end
    end
end
function AnimalScreen:onPagePrevious()
    if self.isBuyMode then
        self:onClickSellMode()
    else
        self:onClickBuyMode()
    end
end
function AnimalScreen:onPageNext()
    if self.isBuyMode then
        self:onClickSellMode()
    else
        self:onClickBuyMode()
    end
end
function AnimalScreen:onClickBuy()
    self.numAnimals = self.numAnimalsElement:getState()
    local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
    local text = self.controller:getApplySourceConfirmationText(animalTypeIndex, self.sourceList.selectedIndex, self.numAnimals)
    local buttonText = self.controller:getSourceActionText()
    YesNoDialog.show(self.onYesNoSource, self, text, g_i18n:getText("ui_attention"), buttonText, g_i18n:getText("button_back"))
    return true
end
function AnimalScreen:onClickSell()
    self.numAnimals = self.numAnimalsElement:getState()
    local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
    local text = self.controller:getApplyTargetConfirmationText(animalTypeIndex, self.sourceList.selectedIndex, self.numAnimals)
    local buttonText = self.controller:getTargetActionText()
    YesNoDialog.show(self.onYesNoTarget, self, text, g_i18n:getText("ui_attention"), buttonText, g_i18n:getText("button_back"))
    return true
end
function AnimalScreen:onYesNoSource(yes)
    if yes then
        local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
        self.controller:applySource(animalTypeIndex, self.sourceList.selectedIndex, self.numAnimals)
    end
end
function AnimalScreen:onYesNoTarget(yes)
    if yes then
        local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
        self.controller:applyTarget(animalTypeIndex, self.sourceList.selectedIndex, self.numAnimals)
    end
end
function AnimalScreen:registerActionEvents()
    g_inputBinding:registerActionEvent(InputAction.AXIS_MTO_SCROLL, self, self.onInputScrollMTO, false, false, true, true)
end
function AnimalScreen:removeActionEvents()
    g_inputBinding:removeActionEventsByTarget(self)
end
function AnimalScreen:onInputScrollMTO(_, inputValue)
    if inputValue ~= 0 and self.selectionState == AnimalScreen.SELECTION_AMOUNT then
        self.numAnimalsElement:setState(self.numAnimalsElement:getState() + inputValue)
        self:setSelectionState(AnimalScreen.SELECTION_AMOUNT)
        self:updatePrice()
    end
end
function AnimalScreen:onFocusEnterList(isEnteringSourceList, enteredList, previousList)
    if enteredList:getItemCount() == 0 then
        if previousList:getItemCount() > 0 then
            FocusManager:setFocus(previousList)
        end
    else
        FocusManager:unsetFocus(previousList)
        self.isSourceSelected = isEnteringSourceList
        self:updateInfoBox(isEnteringSourceList)
        if enteredList.selectedIndex == 0 then
            enteredList:setSelectedIndex(1)
        end
    end
end
function AnimalScreen:getCellTypeForItemInSection(list, _, index)
    if list ~= self.sourceList then
        return nil
    end
    local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
    local item
    if self.isBuyMode then
        item = self.controller:getSourceItems(animalTypeIndex, self.isBuyMode)
    else
        item = self.controller:getTargetItems()
    end
    local item = item[index]
    local prevItem = item[index - 1]
    return (prevItem == nil or item:getSubTypeIndex() ~= prevItem:getSubTypeIndex()) and "sectionCell" or "defaultCell"
end
function AnimalScreen:getNumberOfItemsInSection(list, _)
    if not self.isOpen then
        return 0
    end
    local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
    return list == self.sourceList and (self.isBuyMode and #self.controller:getSourceItems(animalTypeIndex, self.isBuyMode) or #self.controller:getTargetItems()) or (self.isBuyMode and #self.controller:getTargetItems() or 0)
end
function AnimalScreen:populateCellForItemInSection(list, _, index, cell)
    local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
    if list == self.sourceList then
        local item
        if self.isBuyMode then
            item = self.controller:getSourceItems(animalTypeIndex, self.isBuyMode)[index]
        else
            item = self.controller:getTargetItems()[index]
        end
        local subType = g_currentMission.animalSystem:getSubTypeByIndex(item:getSubTypeIndex())
        self.isHorse = subType.typeIndex == AnimalType.HORSE
        if cell.name == "sectionCell" then
            cell:getAttribute("title"):setText(g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex))
        end
        cell:getAttribute("icon"):setImageFilename(item:getFilename())
        cell:getAttribute("name"):setText(item:getName())
        cell:getAttribute("price"):setValue(item:getPrice())
        if self.isHorse then
            cell:getAttribute("amount"):setValue("")
        else
            cell:getAttribute("amount"):setText(item.cluster ~= nil and "x" .. item.cluster.numAnimals or "")
        end
    else
        if list == self.targetList then
            local item
            if self.isBuyMode then
                item = self.controller:getTargetItems()[index]
            else
                item = self.controller:getSourceItems(animalTypeIndex, self.isBuyMode)[index]
            end
            self.isHorse = g_currentMission.animalSystem:getSubTypeByIndex(item:getSubTypeIndex()).typeIndex == AnimalType.HORSE
            cell:getAttribute("icon"):setImageFilename(item:getFilename())
            cell:getAttribute("name"):setText(item:getName())
            cell:getAttribute("separator"):setVisible(index > 1)
            if self.isHorse then
                cell:getAttribute("amount"):setValue("")
                return
            end
            cell:getAttribute("amount"):setText(item.cluster ~= nil and "x" .. item.cluster.numAnimals or "")
        end
        return
    end
end
function AnimalScreen:onListSelectionChanged(list, _, _)
    if not self.isAutoUpdatingList then
        if list == self.sourceList then
            self:setSelectionState(AnimalScreen.SELECTION_SOURCE)
            local sourceSelectorState = self.sourceSelector:getState()
            self:setMaxNumAnimals(self.sourceSelectorStateToAnimalType[sourceSelectorState])
        end
        self:updateInfoBox()
    end
end
function AnimalScreen:onDoubleClickSourceList(_, _, _)
    self:setSelectionState(AnimalScreen.SELECTION_TARGET)
end
function AnimalScreen:onDoubleClickTargetList(_, _, _)
    self:setSelectionState(AnimalScreen.SELECTION_AMOUNT)
end
function AnimalScreen:onClickNumAnimals()
    if self.selectionState ~= AnimalScreen.SELECTION_AMOUNT then
        self:setSelectionState(AnimalScreen.SELECTION_AMOUNT)
    end
    self:updatePrice()
end
function AnimalScreen:onFocusNumAnimals()
    if self.selectionState ~= AnimalScreen.SELECTION_AMOUNT then
        self:setSelectionState(AnimalScreen.SELECTION_AMOUNT)
    end
end
function AnimalScreen:updateChangedList(listElement, fallbackListElement, _)
    self.isAutoUpdatingList = true
    listElement:reloadData()
    self.isAutoUpdatingList = false
    if listElement:getItemCount() == 0 then
        FocusManager:setFocus(fallbackListElement)
        fallbackListElement:setSelectedIndex(1)
    end
    self:updateInfoBox()
    if not Platform.isMobile then
        self:updatePrice()
    end
end
AnimalScreen.SYMBOL_L10N = {
    ["TEXT_BUY"] = "button_buy",
    ["TEXT_SELL"] = "button_sell",
    ["TEXT_LOAD"] = "button_load",
    ["TEXT_UNLOAD"] = "button_unload",
    ["TEXT_PIECES"] = "unit_pieces",
    ["ERROR_TRAILER_LEFT"] = "animals_transportTargetLeftTrigger"
}
AnimalScreen.COLOR = {
    ["GREEN"] = {
        0.3763,
        0.6038,
        0.0782,
        1
    },
    ["ORANGE"] = {
        0.8,
        0.4,
        0,
        1
    },
    ["RED"] = {
        0.8069,
        0.0097,
        0.0097,
        1
    }
}