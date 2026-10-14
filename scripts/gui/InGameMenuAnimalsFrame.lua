InGameMenuAnimalsFrame = {}
local InGameMenuAnimalsFrame_mt = Class(InGameMenuAnimalsFrame, TabbedMenuFrameElement)
InGameMenuAnimalsFrame.UPDATE_INTERVAL = 5000
InGameMenuAnimalsFrame.HORSE_TYPE = "HORSE"
InGameMenuAnimalsFrame.CHICKEN_TYPE = "CHICKEN"
InGameMenuAnimalsFrame.ANIMAL_PRODUCT_FILL_TYPES = {
    ["MILK"] = "MILK",
    ["WOOL"] = "WOOL",
    ["EGG"] = "EGG"
}
InGameMenuAnimalsFrame.MAX_ANIMAL_NAME_LENGTH = 16
function InGameMenuAnimalsFrame.register()
    local inGameMenuAnimalsFrame = InGameMenuAnimalsFrame.new()
    g_gui:loadGui("dataS/gui/InGameMenuAnimalsFrame.xml", "AnimalsFrame", inGameMenuAnimalsFrame, true)
end
function InGameMenuAnimalsFrame.new(target, custom_mt)
    -- upvalues: (copy) InGameMenuAnimalsFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuAnimalsFrame_mt)
    self.sortedHusbandries = {}
    self.selectedClusterIsHorse = false
    self.selectedCluster = nil
    self.selectedHusbandry = nil
    self.animalDataUpdateTime = InGameMenuAnimalsFrame.UPDATE_INTERVAL
    self.hasCustomMenuButtons = true
    self.renameButtonInfo = {}
    return self
end
function InGameMenuAnimalsFrame.createFromExistingGui(gui, guiName)
    local newGui = InGameMenuAnimalsFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function InGameMenuAnimalsFrame:delete()
    for k, clone in pairs(self.subCategoryDotBox.elements) do
        clone:delete()
        self.subCategoryDotBox.elements[k] = nil
    end
    self.subCategoryDotTemplate:delete()
    InGameMenuAnimalsFrame:superClass().delete(self)
end
function InGameMenuAnimalsFrame:onFrameOpen()
    InGameMenuAnimalsFrame:superClass().onFrameOpen(self)
    g_messageCenter:subscribe(MessageType.HUSBANDRY_ANIMALS_CHANGED, self.onAnimalDataChanged, self)
    g_messageCenter:subscribe(MessageType.HUSBANDRY_SYSTEM_ADDED_PLACEABLE, self.updateHusbandries, self)
    g_messageCenter:subscribe(MessageType.HUSBANDRY_SYSTEM_REMOVED_PLACEABLE, self.updateHusbandries, self)
    self:updateHusbandries()
    self:updateMenuButtons()
    self.subCategorySelector:setState(self.subCategorySelector:getState(), true)
    if self.list:getItemCount() == 0 then
        FocusManager:setFocus(self.subCategorySelector)
    else
        FocusManager:setFocus(self.list)
    end
end
function InGameMenuAnimalsFrame:onFrameClose()
    g_messageCenter:unsubscribe(MessageType.HUSBANDRY_ANIMALS_CHANGED, self)
    g_messageCenter:unsubscribe(MessageType.HUSBANDRY_SYSTEM_ADDED_PLACEABLE, self)
    g_messageCenter:unsubscribe(MessageType.HUSBANDRY_SYSTEM_REMOVED_PLACEABLE, self)
    self.selectedHusbandry = nil
    InGameMenuAnimalsFrame:superClass().onFrameClose(self)
end
function InGameMenuAnimalsFrame:initialize()
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
    self.renameButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_RENAME),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonRename()
        end,
        ["profile"] = "buttonRename"
    }
    self.hotspotButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_HOTSPOT),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonHotspot()
        end,
        ["profile"] = "buttonHotspot"
    }
    self.subCategoryDotTemplate:unlinkElement()
    FocusManager:removeElement(self.subCategoryDotTemplate)
    FocusManager:linkElements(self.list, FocusManager.LEFT, nil)
    FocusManager:linkElements(self.list, FocusManager.RIGHT, nil)
    FocusManager:linkElements(self.list, FocusManager.BOTTOM, nil)
    self.subCategorySelector:setState(1, true)
end
function InGameMenuAnimalsFrame:onAnimalDataChanged()
    self:updateAnimalData()
end
function InGameMenuAnimalsFrame:setPlayerFarm(playerFarm)
    self.playerFarm = playerFarm
    self:updateAnimalData()
end
function InGameMenuAnimalsFrame:update(dt)
    InGameMenuAnimalsFrame:superClass().update(self, dt)
    if self.selectedHusbandry ~= nil and self.selectedCluster ~= nil then
        self.animalDataUpdateTime = self.animalDataUpdateTime - dt
        if self.animalDataUpdateTime < 0 then
            self:updateAnimalData()
            self:displayCluster(self.selectedCluster, self.selectedHusbandry)
            self.animalDataUpdateTime = InGameMenuAnimalsFrame.UPDATE_INTERVAL
        end
    end
end
local function sortClusters(a, b)
    local animalSystem = g_currentMission.animalSystem
    local aSubType = animalSystem:getSubTypeByIndex(a:getSubTypeIndex())
    local bSubType = animalSystem:getSubTypeByIndex(b:getSubTypeIndex())
    local aName = g_fillTypeManager:getFillTypeTitleByIndex(aSubType.fillTypeIndex)
    local bName = g_fillTypeManager:getFillTypeTitleByIndex(bSubType.fillTypeIndex)
    if aName == bName then
        return a:getAge() > b:getAge()
    else
        return bName < aName
    end
end
local function sortHusbandries(a, b)
    local aTypeIndex = a:getAnimalTypeIndex()
    local bTypeIndex = b:getAnimalTypeIndex()
    if aTypeIndex ~= bTypeIndex then
        if aTypeIndex == AnimalType.HORSE then
            return false
        end
        if bTypeIndex == AnimalType.HORSE then
            return true
        end
    end
    local aHotspot = nil
    local bHotspot = nil
    if a.getHotspot ~= nil then
        aHotspot = a:getHotspot(1)
    end
    if b.getHotspot ~= nil then
        bHotspot = b:getHotspot(1)
    end
    local aX, aZ = aHotspot:getWorldPosition()
    local bX, bZ = bHotspot:getWorldPosition()
    if aX == bX then
        return aZ < bZ
    else
        return aX < bX
    end
end
function InGameMenuAnimalsFrame:updateHusbandries()
    -- upvalues: (copy) sortHusbandries, (copy) sortClusters
    self.sortedHusbandries = g_currentMission.husbandrySystem:getPlaceablesByFarm(self.playerFarm.farmId)
    table.sort(self.sortedHusbandries, sortHusbandries)
    local husbandryNames = {}
    for i, dot in pairs(self.subCategoryDotBox.elements) do
        dot:delete()
        self.subCategoryDotBox.elements[i] = nil
    end
    for i, dot in ipairs(self.sortedHusbandries) do
        local clusters = {}
        for _, cluster in ipairs(dot:getClusters()) do
            table.insert(clusters, cluster)
        end
        table.sort(clusters, sortClusters)
        dot.sortedClusters = clusters
        table.insert(husbandryNames, dot:getName())
        local i
        self.subCategoryDotTemplate:clone(self.subCategoryDotBox).getIsSelected = function()
            -- upvalues: (copy) self, (copy) i
            return self.subCategorySelector:getState() == i
        end
    end
    self:updateAnimalData()
    self.subCategorySelector:setTexts(husbandryNames)
    self.subCategoryDotBox:invalidateLayout()
    self.subCategoryDotBox:setVisible(#husbandryNames > 1)
end
function InGameMenuAnimalsFrame:updateAnimalData()
    self:reloadList()
end
function InGameMenuAnimalsFrame.setStatusBarValue(_, statusBarElement, value, invertedBar, disabled)
    local testValue
    if invertedBar then
        testValue = 1 - value
    else
        testValue = value
    end
    if InGameMenuAnimalsFrame.STATUS_BAR_MEDIUM < testValue and testValue <= InGameMenuAnimalsFrame.STATUS_BAR_HIGH then
        statusBarElement:setImageColor(InGameMenuAnimalsFrame.COLOR.ORANGE)
    elseif InGameMenuAnimalsFrame.STATUS_BAR_HIGH < testValue then
        statusBarElement:setImageColor(InGameMenuAnimalsFrame.COLOR.RED)
    else
        statusBarElement:setImageColor(InGameMenuAnimalsFrame.COLOR.GREEN)
    end
    local minSize = 0
    if statusBarElement.startSize ~= nil then
        minSize = statusBarElement.startSize[1] + statusBarElement.endSize[1]
    end
    statusBarElement:setSize(math.max(minSize, (statusBarElement.parent.size[1] - statusBarElement.margin[1] * 2) * math.min(1, value)), nil)
    statusBarElement:setDisabled((Utils.getNoNil(disabled, false)))
end
function InGameMenuAnimalsFrame:updateHusbandryDisplay(husbandry)
    local infos = self.husbandryBox
    local totalCapacity = husbandry ~= nil
    infos:setVisible(totalCapacity)
    if husbandry ~= nil then
        self.husbandryIcon:setImageFilename(husbandry.storeItem.imageFilename)
        local infos = husbandry:getConditionInfos()
        for index, row in ipairs(self.conditionRow) do
            local info = infos[index]
            local info = info ~= nil
            row:setVisible(info)
            if info ~= nil then
                local valueText = info.valueText or g_i18n:formatVolume(info.value, 0, info.customUnitText)
                self.conditionLabel[index]:setText(info.title)
                self.conditionValue[index]:setText(valueText)
                self:setStatusBarValue(self.conditionStatusBar[index], info.ratio, info.invertedBar, info.disabled)
            end
        end
        local foodInfos = husbandry:getFoodInfos()
        local totalCapacity = 0
        local totalValue = 0
        for valueText, row in ipairs(self.foodRow) do
            local info = foodInfos[valueText]
            row:setVisible(info ~= nil)
            if info ~= nil then
                local valueText = g_i18n:formatVolume(info.value, 0)
                if not info.ignoreCapacity then
                    totalCapacity = math.max(info.capacity, totalCapacity)
                end
                self.foodLabel[valueText]:setText(info.title)
                self.foodValue[valueText]:setText(valueText)
                self:setStatusBarValue(self.foodStatusBar[valueText], info.ratio, info.invertedBar, info.disabled)
            end
        end
        local index = g_i18n:formatVolume(totalValue, 0)
        local row = 0
        if totalCapacity > 0 then
            row = totalValue / totalCapacity
        end
        self.foodRowTotalValue:setText(index)
        self:setStatusBarValue(self.foodRowTotalStatusBar, row, false)
        self.requirementsLayout:invalidateLayout()
        self.foodHeader:setText(string.format("%s (%s)", g_i18n:getText("ui_silos_totalCapacity"), g_i18n:getText("animals_foodMixEffectiveness")))
    end
end
function InGameMenuAnimalsFrame:displayCluster(cluster, husbandry)
    if cluster ~= nil and husbandry ~= nil then
        local subTypeIndex = cluster:getSubTypeIndex()
        local age = cluster:getAge()
        local visual = g_currentMission.animalSystem:getVisualByAge(subTypeIndex, age)
        if visual ~= nil then
            local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
            local name = g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex)
            if cluster.getName ~= nil then
                name = cluster:getName()
            end
            self.animalDetailTypeNameText:setText(name)
            self.animalDetailTypeImage:setImageFilename(visual.store.imageFilename)
            local ageText = g_i18n:formatNumMonth(age)
            self.animalAgeText:setText(ageText)
            local infos = husbandry:getAnimalInfos(cluster)
            for index, row in ipairs(self.infoRow) do
                local info = infos[index]
                row:setVisible(info ~= nil)
                if info ~= nil then
                    local valueText = info.valueText or g_i18n:formatVolume(info.value, 0, info.customUnitText)
                    self.infoLabel[index]:setText(info.title)
                    self.infoValue[index]:setText(valueText)
                    self:setStatusBarValue(self.infoStatusBar[index], info.ratio, info.invertedBar, info.disabled)
                end
            end
            local animalDescriptionText = husbandry:getAnimalDescription(cluster)
            self.detailDescriptionText:setText(animalDescriptionText)
        end
    end
end
function InGameMenuAnimalsFrame:updateMenuButtons()
    self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    if self.selectedHusbandry ~= nil then
        local hotspot = nil
        if self.selectedHusbandry.getHotspot ~= nil then
            hotspot = self.selectedHusbandry:getHotspot(1)
        end
        if hotspot ~= nil then
            if hotspot == g_currentMission.currentMapTargetHotspot then
                self.hotspotButtonInfo.text = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.REMOVE_MARKER)
            else
                self.hotspotButtonInfo.text = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.SET_MARKER)
            end
            table.insert(self.menuButtonInfo, self.hotspotButtonInfo)
        end
    end
    if self.selectedClusterIsHorse and Platform.gameplay.canRenameHorses then
        table.insert(self.menuButtonInfo, self.renameButtonInfo)
    end
    self:setMenuButtonInfoDirty()
end
function InGameMenuAnimalsFrame:renameCurrentHorse(newName, hasConfirmed)
    if hasConfirmed and (self.selectedClusterIsHorse and Platform.gameplay.canRenameHorses) then
        self.selectedHusbandry:renameAnimal(self.selectedCluster.id, newName)
    end
end
function InGameMenuAnimalsFrame.getFoodDescription(_, animalTypeIndex)
    if g_currentMission.animalFoodSystem:getAnimalFood(animalTypeIndex).consumptionType == AnimalFoodSystem.FOOD_CONSUME_TYPE_PARALLEL then
        return g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.FOOD_DESCRIPTION_PARALLEL)
    else
        return g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.FOOD_DESCRIPTION_SERIAL)
    end
end
function InGameMenuAnimalsFrame:reloadList()
    local selectorState = self.subCategorySelector:getState()
    local husbandry = self.sortedHusbandries[selectorState]
    self.husbandrySubTypes = {}
    self.subTypeIndexToClusters = {}
    if husbandry ~= nil then
        for index, cluster in ipairs(husbandry.sortedClusters) do
            local subTypeIndex = cluster:getSubTypeIndex()
            table.addElement(self.husbandrySubTypes, subTypeIndex)
            if self.subTypeIndexToClusters[subTypeIndex] == nil then
                self.subTypeIndexToClusters[subTypeIndex] = {}
            end
            table.insert(self.subTypeIndexToClusters[subTypeIndex], cluster)
        end
    end
    local hasAnimals = self.detailsBox
    hasAnimals:setVisible(husbandry ~= nil)
    local hasAnimals = self.noHusbandriesText
    hasAnimals:setVisible(husbandry ~= nil)
    self:updateHusbandryDisplay(husbandry)
    self.list:reloadData()
    local hasAnimals = #self.husbandrySubTypes > 0
    self.animalBox:setVisible(hasAnimals)
    self.detailDescriptionText:setVisible(hasAnimals)
    local index = false
    if husbandry ~= nil then
        index = not hasAnimals
    end
    self.noAnimalsText:setVisible(index)
end
function InGameMenuAnimalsFrame:getNumberOfSections(_)
    return #self.husbandrySubTypes
end
function InGameMenuAnimalsFrame:getTitleForSectionHeader(_, section)
    local subType = g_currentMission.animalSystem:getSubTypeByIndex(self.husbandrySubTypes[section])
    return g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex)
end
function InGameMenuAnimalsFrame:getNumberOfItemsInSection(_, section)
    return #self.subTypeIndexToClusters[self.husbandrySubTypes[section]]
end
function InGameMenuAnimalsFrame:populateCellForItemInSection(_, section, index, cell)
    local subTypeIndex = self.husbandrySubTypes[section]
    local cluster = self.subTypeIndexToClusters[subTypeIndex][index]
    local age = cluster:getAge()
    local visual = g_currentMission.animalSystem:getVisualByAge(subTypeIndex, age)
    local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
    if visual ~= nil then
        local price
        if cluster.getName == nil then
            price = g_i18n:formatNumMonth(age)
        else
            price = cluster:getName()
        end
        local price = cluster:getSellPrice()
        local priceText = g_i18n:formatMoney(price, 0, true, true)
        cell:getAttribute("priceValue"):setText(priceText)
        cell:getAttribute("count"):setText(cluster ~= nil and "x" .. cluster.numAnimals or "")
        cell:getAttribute("count"):setVisible(subType.typeIndex ~= AnimalType.HORSE)
        cell:getAttribute("name"):setText(price)
        cell:getAttribute("typeIcon"):setImageFilename(visual.store.imageFilename)
    end
end
function InGameMenuAnimalsFrame:onHusbandryChanged(index)
    self.selectedCluster = nil
    self:updateAnimalData()
    local husbandry = self.sortedHusbandries[index]
    if husbandry ~= nil then
        self.selectedHusbandry = husbandry
        self:updateMenuButtons()
        self.list:setSelectedIndex(1)
    end
end
function InGameMenuAnimalsFrame:onButtonRename()
    if Platform.gameplay.canRenameHorses then
        local promptText = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.PROMPT_RENAME)
        local imePromptText = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.IME_PROMPT_RENAME)
        local confirmText = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_CONFIRM)
        TextInputDialog.show(self.renameCurrentHorse, self, self.selectedCluster:getName(), promptText, imePromptText, InGameMenuAnimalsFrame.MAX_ANIMAL_NAME_LENGTH, confirmText, nil, nil, true)
    end
end
function InGameMenuAnimalsFrame:onButtonHotspot()
    local hotspot = nil
    if self.selectedHusbandry.getHotspot ~= nil then
        hotspot = self.selectedHusbandry:getHotspot(1)
    end
    if self.selectedHusbandry and hotspot ~= nil then
        if hotspot == g_currentMission.currentMapTargetHotspot then
            g_currentMission:setMapTargetHotspot()
        else
            g_currentMission:setMapTargetHotspot(hotspot)
        end
        self:updateMenuButtons()
    end
end
function InGameMenuAnimalsFrame:onButtonInfo()
    InfoDialog.show(self.detailDescriptionText.text)
end
function InGameMenuAnimalsFrame:onListSelectionChanged(_, section, index)
    if g_gui.currentlyReloading == false then
        local cluster = self.subTypeIndexToClusters[self.husbandrySubTypes[section]][index]
        local husbandry = self.sortedHusbandries[self.subCategorySelector:getState()]
        local isHorse = g_currentMission.animalSystem:getSubTypeByIndex(cluster:getSubTypeIndex()).typeIndex == AnimalType.HORSE
        self.selectedClusterIsHorse = isHorse
        self.selectedCluster = cluster
        self:displayCluster(self.selectedCluster, husbandry)
        self.livestockAttributesLayout:invalidateLayout()
        self:updateMenuButtons()
    end
end
InGameMenuAnimalsFrame.FILL_TYPE_SEPARATOR = " / "
InGameMenuAnimalsFrame.L10N_SYMBOL = {
    ["HORSE_FITNESS"] = "ui_horseFitness",
    ["CLEANLINESS"] = "statistic_cleanliness",
    ["WATER"] = "statistic_water",
    ["STRAW"] = "statistic_strawStorage",
    ["BUTTON_RENAME"] = "button_rename",
    ["BUTTON_CONFIRM"] = "button_confirm",
    ["BUTTON_HOTSPOT"] = "button_showOnMap",
    ["SET_MARKER"] = "action_tag",
    ["REMOVE_MARKER"] = "action_untag",
    ["PROMPT_RENAME"] = "ui_enterHorseName",
    ["IME_PROMPT_RENAME"] = "ui_horseName",
    ["FOOD_MIX_QUANITITY"] = "animals_foodMixQuantity",
    ["FOOD_DESCRIPTION_PARALLEL"] = "animals_foodMixDescriptionParallel",
    ["FOOD_DESCRIPTION_SERIAL"] = "animals_foodMixDescriptionSerial"
}
InGameMenuAnimalsFrame.STATUS_BAR_HIGH = 0.66
InGameMenuAnimalsFrame.STATUS_BAR_MEDIUM = 0.33
InGameMenuAnimalsFrame.COLOR = {
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