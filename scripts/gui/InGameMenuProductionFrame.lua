InGameMenuProductionFrame = {}
local InGameMenuProductionFrame_mt = Class(InGameMenuProductionFrame, TabbedMenuFrameElement)
InGameMenuProductionFrame.UPDATE_INTERVAL = 5000
InGameMenuProductionFrame.STATUS_BAR_LOW = 0.2
InGameMenuProductionFrame.STATUS_BAR_HIGH = 0.8
InGameMenuProductionFrame.POINTS_OWNED = 1
InGameMenuProductionFrame.POINTS_UNOWNED = 2
function InGameMenuProductionFrame.register()
    local inGameMenuProductionFrame = InGameMenuProductionFrame.new()
    g_gui:loadGui("dataS/gui/InGameMenuProductionFrame.xml", "ProductionFrame", inGameMenuProductionFrame, true)
end
function InGameMenuProductionFrame.new(target, custom_mt)
    -- upvalues: (copy) InGameMenuProductionFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuProductionFrame_mt)
    self.hasCustomMenuButtons = true
    self.timeSinceLastStateUpdate = 0
    self.productionPoints = {}
    return self
end
function InGameMenuProductionFrame.createFromExistingGui(gui, guiName)
    local newGui = InGameMenuProductionFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function InGameMenuProductionFrame:delete()
    self.recipeItemTemplate:delete()
    InGameMenuProductionFrame:superClass().delete(self)
end
function InGameMenuProductionFrame:initialize()
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
    self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    self.recipeItemTemplate:unlinkElement()
    self.hotspotButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_HOTSPOT),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonHotspot()
        end,
        ["profile"] = "buttonHotspot"
    }
    self.visitButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText("action_visit"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonVisit()
        end,
        ["profile"] = "buttonVisitPlace"
    }
    self.activateButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText("button_activate"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonActivate()
        end,
        ["profile"] = "buttonOK"
    }
    self.toggleStorageModeButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText("ui_production_changeOutputMode"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonToggleOutputMode()
        end,
        ["profile"] = "buttonOK"
    }
    self.pointsSelector:setTexts({ g_i18n:getText(InGameMenuProductionFrame.SYMBOL_L10N.TEXT_OWNED), g_i18n:getText(InGameMenuProductionFrame.SYMBOL_L10N.TEXT_UNOWNED) })
    local i = 1
    local isNotReloading = 2
    for i = i, isNotReloading do
        self.pointsDotBox.elements[i].getIsSelected = function()
            -- upvalues: (copy) self, (copy) i
            return self.pointsSelector:getState() == i
        end
    end
    self.pointsDotBox:invalidateLayout()
    FocusManager:linkElements(self.pointsList, FocusManager.LEFT, nil)
    FocusManager:linkElements(self.pointsList, FocusManager.RIGHT, self.productsList)
    FocusManager:linkElements(self.pointsList, FocusManager.TOP, self.pointsSelector)
    FocusManager:linkElements(self.pointsList, FocusManager.BOTTOM, nil)
    FocusManager:linkElements(self.productsList, FocusManager.LEFT, self.pointsList)
    FocusManager:linkElements(self.productsList, FocusManager.RIGHT, self.detailsSlider)
    FocusManager:linkElements(self.productsList, FocusManager.TOP, nil)
    FocusManager:linkElements(self.productsList, FocusManager.BOTTOM, nil)
    FocusManager:linkElements(self.detailsSlider, FocusManager.LEFT, self.productsList)
    FocusManager:linkElements(self.detailsSlider, FocusManager.RIGHT, nil)
    FocusManager:linkElements(self.detailsSlider, FocusManager.TOP, nil)
    FocusManager:linkElements(self.detailsSlider, FocusManager.BOTTOM, nil)
    local isNotReloading = not self.isReloading
    if isNotReloading then
        isNotReloading = not g_gui.currentlyReloading
    end
    function self.pointsBoxBg.getIsSelected()
        -- upvalues: (copy) self, (copy) isNotReloading
        return self.pointsList:getIsFocused() and isNotReloading
    end
    function self.pointsBoxArrow.getIsSelected()
        -- upvalues: (copy) self, (copy) isNotReloading
        return self.pointsList:getIsFocused() and isNotReloading
    end
    function self.productsBoxBg.getIsSelected()
        -- upvalues: (copy) self, (copy) isNotReloading
        return self.productsList:getIsFocused() and isNotReloading
    end
    function self.productsBoxBgTop.getIsSelected()
        -- upvalues: (copy) self, (copy) isNotReloading
        return self.productsList:getIsFocused() and isNotReloading
    end
    function self.productsBoxBgArrow.getIsSelected()
        -- upvalues: (copy) self, (copy) isNotReloading
        return self.productsList:getIsFocused() and isNotReloading
    end
    function self.detailsBoxBg.getIsSelected()
        -- upvalues: (copy) self, (copy) isNotReloading
        return self.detailsSlider:getIsFocused() and isNotReloading
    end
    function self.detailsBoxBgTop.getIsSelected()
        -- upvalues: (copy) self, (copy) isNotReloading
        return self.detailsSlider:getIsFocused() and isNotReloading
    end
end
function InGameMenuProductionFrame:onFrameOpen()
    InGameMenuProductionFrame:superClass().onFrameOpen(self)
    self.chainManager = g_currentMission.productionChainManager
    self:updateProductionLists()
    if #self.productionPoints == 0 then
        self.pointsSelector:setState(InGameMenuProductionFrame.POINTS_UNOWNED, true)
    end
    if self.pointsList:getItemCount() > 0 then
        FocusManager:setFocus(self.pointsList)
    else
        FocusManager:setFocus(self.pointsSelector)
    end
end
function InGameMenuProductionFrame:unloadMapData()
    self.selectedProductionPoint = nil
end
function InGameMenuProductionFrame:setPlayerFarm(playerFarm)
    self.playerFarm = playerFarm
end
function InGameMenuProductionFrame:getProductionPoints()
    return self.productionPoints
end
function InGameMenuProductionFrame:setSelectedProductionPoint(productionPoint)
    local productions
    if productionPoint.isOwned then
        self.pointsSelector:setState(InGameMenuProductionFrame.POINTS_OWNED, true)
        productions = self.productionPoints
    else
        self.pointsSelector:setState(InGameMenuProductionFrame.POINTS_UNOWNED, true)
        productions = self.unownedProductionPoints
    end
    for index, listProdPoint in ipairs(productions) do
        if listProdPoint == productionPoint then
            self.pointsList:setSelectedIndex(index)
            return
        end
    end
end
function InGameMenuProductionFrame:updateMenuButtons()
    self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    if self.pointsList:getIsFocused() then
        local _, productionPoint = self:getSelectedProduction()
        if productionPoint ~= nil then
            local hotspot = nil
            if productionPoint.owningPlaceable ~= nil then
                hotspot = productionPoint.owningPlaceable:getHotspot()
            end
            if hotspot == nil and productionPoint.getHotspot ~= nil then
                hotspot = productionPoint:getHotspot()
            end
            if hotspot ~= nil then
                if hotspot == g_currentMission.currentMapTargetHotspot then
                    self.hotspotButtonInfo.text = g_i18n:getText("action_untag")
                else
                    self.hotspotButtonInfo.text = g_i18n:getText("action_tag")
                end
                table.insert(self.menuButtonInfo, self.hotspotButtonInfo)
                if hotspot:getBeVisited() and Platform.gameplay.canVisitPOI then
                    table.insert(self.menuButtonInfo, self.visitButtonInfo)
                end
            end
        end
    elseif (self.productsList:getIsFocused() or self.detailsSlider:getIsFocused()) and self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED then
        local _, productionPoint = self:getSelectedProduction()
        if _ ~= nil and not _.outputs[1].isFactory then
            if productionPoint.getIsProductionEnabled ~= nil then
                local hotspot = productionPoint:getIsProductionEnabled(_.id)
                self.activateButtonInfo.text = hotspot and g_i18n:getText("button_deactivate") or g_i18n:getText("button_activate")
                table.insert(self.menuButtonInfo, self.activateButtonInfo)
            end
            if _.primaryProductFillType ~= FillType.UNKNOWN then
                table.insert(self.menuButtonInfo, self.toggleStorageModeButtonInfo)
            end
        end
    end
    self:setMenuButtonInfoDirty()
end
function InGameMenuProductionFrame:getSelectedProduction()
    return self.selectedProduction, self.selectedProductionPoint
end
function InGameMenuProductionFrame:update(dt)
    InGameMenuProductionFrame:superClass().update(self, dt)
    self.timeSinceLastStateUpdate = self.timeSinceLastStateUpdate + dt
    if self.timeSinceLastStateUpdate >= InGameMenuProductionFrame.UPDATE_INTERVAL then
        self.timeSinceLastStateUpdate = 0
        self:updateProductionLists()
    end
end
function InGameMenuProductionFrame:getNumberOfSections(list, _)
    return list == self.detailsList and (self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED and (self.selectedProduction.outputs[1].isFactory and 3 or 4) or 2) or 1
end
function InGameMenuProductionFrame:getTitleForSectionHeader(list, section)
    if list == self.detailsList then
        if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_UNOWNED and true or false then
            if section == 1 then
                return g_i18n:getText("ui_productions_outgoingProducts")
            end
            if section == 2 then
                local production = self:getSelectedProduction()
                local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(production.primaryProductFillType)
                return g_i18n:getText("ui_productions_recipe") .. ": " .. (production.name or fillTypeDesc.title)
            end
        else
            if section == 1 then
                return g_i18n:getText("ui_productions_incomingMaterials")
            end
            if section == 2 and not self.selectedProduction.outputs[1].isFactory then
                return g_i18n:getText("ui_productions_outgoingProducts")
            end
            if section == 4 or section == 3 and self.selectedProduction.outputs[1].isFactory then
                local production = self:getSelectedProduction()
                local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(production.primaryProductFillType)
                return g_i18n:getText("ui_productions_recipe") .. ": " .. (production.name or fillTypeDesc.title)
            end
        end
    end
    return nil
end
function InGameMenuProductionFrame:getNumberOfItemsInSection(list, section)
    if list == self.pointsList then
        return self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED and #self.productionPoints or #self.unownedProductionPoints
    end
    if list ~= self.productsList then
        return list == self.detailsList and (self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED and (section == 1 and #self.selectedProductionPoint.sortedInputFillTypes or (section == 2 and #self.selectedProductionPoint.sortedOutputFillTypes or 1)) or 1) or 0
    end
    local _, productionPoint = self:getSelectedProduction()
    return productionPoint ~= nil and #productionPoint.sortedProductions or 0
end
function InGameMenuProductionFrame:getCellTypeForItemInSection(list, section, _)
    if list == self.detailsList then
        local isOwned = true
        if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_UNOWNED then
            isOwned = false
        end
        if self.selectedProduction.outputs[1].isFactory and isOwned then
            if section == 1 then
                return "fillTypeCell"
            end
            if section == 2 then
                return "detailsCell"
            end
            if section == 3 then
                return "recipeCell"
            end
        else
            if section <= 2 then
                return "fillTypeCell"
            end
            if section == 3 then
                return "detailsCell"
            end
            if section == 4 then
                return "recipeCell"
            end
        end
    end
    return nil
end
function InGameMenuProductionFrame:populateCellForItemInSection(list, section, index, cell)
    if list == self.pointsList then
        local productionPoint = self.productionPoints[index]
        if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_UNOWNED then
            productionPoint = self.unownedProductionPoints[index]
        end
        cell:getAttribute("name"):setText(productionPoint:getName())
        local icon, isPreplaced
        if productionPoint.owningPlaceable == nil then
            icon = productionPoint:getImageFilename()
            isPreplaced = productionPoint.customImageFilename ~= nil
        else
            icon = productionPoint.owningPlaceable:getImageFilename()
            isPreplaced = productionPoint.owningPlaceable.customImageFilename ~= nil
        end
        local icon = cell:getAttribute("icon")
        local fillType = false
        if icon ~= nil then
            fillType = not isPreplaced
        end
        icon:setVisible(fillType)
        local iconPreplaced = cell:getAttribute("iconPreplaced")
        local outputMode
        if icon == nil then
            outputMode = false
        else
            outputMode = isPreplaced
        end
        iconPreplaced:setVisible(outputMode)
        if isPreplaced then
            iconPreplaced:setImageFilename(icon)
        else
            icon:setImageFilename(icon)
        end
    elseif list == self.productsList then
        local productionPoint, filename = self:getSelectedProduction()
        local isPreplaced = filename.sortedProductions[index]
        local icon = g_fillTypeManager:getFillTypeByIndex(isPreplaced.primaryProductFillType)
        if icon ~= nil then
            cell:getAttribute("icon"):setImageFilename(icon.hudOverlayFilename)
        end
        local iconPreplaced = cell:getAttribute("icon")
        local fillType = icon ~= nil
        iconPreplaced:setVisible(fillType)
        cell:getAttribute("icon").getIsSelected = function()
            -- upvalues: (copy) isPreplaced
            return isPreplaced.status ~= ProductionPoint.PROD_STATUS.INACTIVE
        end
        cell:getAttribute("warning").getDoRenderText = function()
            -- upvalues: (copy) isPreplaced
            local status = isPreplaced.status
            local isError = true
            if status ~= ProductionPoint.PROD_STATUS.MISSING_INPUTS then
                isError = status == ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE
            end
            return isError
        end
        cell:getAttribute("name"):setText(isPreplaced.name or icon.title)
        local outputModeText = ""
        local fillType = isPreplaced.primaryProductFillType
        if filename.getOutputDistributionMode ~= nil then
            local outputMode = filename:getOutputDistributionMode(fillType)
            outputModeText = g_i18n:getText("ui_production_output_storing")
            if outputMode == ProductionPoint.OUTPUT_MODE.DIRECT_SELL then
                outputModeText = g_i18n:getText("ui_production_output_selling")
            elseif outputMode == ProductionPoint.OUTPUT_MODE.AUTO_DELIVER then
                outputModeText = g_i18n:getText("ui_production_output_distributing")
            end
        end
        cell:getAttribute("activity"):setText(outputModeText)
    elseif list == self.detailsList then
        local productionPoint, filename = self:getSelectedProduction()
        local isPreplaced = productionPoint.primaryProductFillType
        if cell.name == "fillTypeCell" then
            if section == 1 then
                isPreplaced = filename.sortedInputFillTypes[index]
            else
                isPreplaced = filename.sortedOutputFillTypes[index]
            end
        end
        local icon = g_fillTypeManager:getFillTypeByIndex(isPreplaced)
        if isPreplaced ~= FillType.UNKNOWN then
            if cell.name == "recipeCell" then
                local function iconPreplaced(layout, list)
                    -- upvalues: (copy) self
                    for i = 1, #layout.elements do
                        layout.elements[1]:delete()
                    end
                    for index, item in pairs(list) do
                        local template = self.recipeItemTemplate:clone(layout)
                        local recipeFillType = g_fillTypeManager:getFillTypeByIndex(item.type)
                        template:getDescendantByName("amount"):setText(g_i18n:formatNumber(item.amount, 2))
                        template:getDescendantByName("name"):setText("x " .. recipeFillType.title)
                        template:getDescendantByName("icon"):setImageFilename(recipeFillType.hudOverlayFilename)
                    end
                end
                local outputModeText = cell:getAttribute("inputLayout")
                iconPreplaced(outputModeText, productionPoint.inputs)
                outputModeText:invalidateLayout()
                cell:setSize(nil, outputModeText.maxFlowSize)
                self.detailsList.cellDatabase.recipeCell.size[2] = outputModeText.maxFlowSize
                cell:getAttribute("arrowLayout"):invalidateLayout()
                local fillType = cell:getAttribute("outputLayout")
                iconPreplaced(fillType, productionPoint.outputs)
                fillType:invalidateLayout()
                if fillType.maxFlowSize > outputModeText.maxFlowSize then
                    cell:setSize(nil, fillType.maxFlowSize)
                    self.detailsList.cellDatabase.recipeCell.size[2] = fillType.maxFlowSize
                    outputModeText:invalidateLayout()
                    cell:getAttribute("arrowLayout"):invalidateLayout()
                    fillType:invalidateLayout()
                end
                self.detailsList:buildSectionInfo()
                return
            end
            if cell.name == "fillTypeCell" then
                cell:getAttribute("icon"):setImageFilename(icon.hudOverlayFilename)
                cell:getAttribute("fillType"):setText(icon.title)
                local iconPreplaced = filename:getFillLevel(isPreplaced)
                local outputModeText = filename:getCapacity(isPreplaced)
                cell:getAttribute("fillLevel"):setText(g_i18n:formatVolume(iconPreplaced, 0) .. " / " .. g_i18n:formatVolume(outputModeText, 0))
                if outputModeText >= 1 then
                    cell:getAttribute("fillPercent"):setText(g_i18n:formatNumber(iconPreplaced / outputModeText * 100, 0) .. "%")
                    self:setStatusBarValue(cell:getAttribute("bar"), iconPreplaced / outputModeText, true)
                else
                    cell:getAttribute("fillPercent"):setText("0%")
                    self:setStatusBarValue(cell:getAttribute("bar"), 0, true)
                end
            end
            if cell.name == "detailsCell" then
                local iconPreplaced = cell:getAttribute("separator")
                local fillType = section ~= 1
                iconPreplaced:setVisible(fillType)
                cell:getAttribute("iconLarge"):setImageFilename(icon.hudOverlayFilename)
                local iconPreplaced = productionPoint.status
                local fillType = true
                if iconPreplaced ~= ProductionPoint.PROD_STATUS.MISSING_INPUTS then
                    fillType = true
                    if iconPreplaced ~= ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE then
                        fillType = iconPreplaced == ProductionPoint.PROD_STATUS.INACTIVE
                    end
                end
                cell:getAttribute("infoStatus").getIsSelected = function()
                    -- upvalues: (copy) fillType
                    return fillType
                end
                cell:getAttribute("infoStatus"):setLocaKey(ProductionPoint.PROD_STATUS_TO_L10N[productionPoint.status] or ProductionPoint.PROD_STATUS_TO_L10N[ProductionPoint.PROD_STATUS.RUNNING])
                cell:getAttribute("infoCycles"):setText(MathUtil.round(productionPoint.cyclesPerMonth, 2))
                cell:getAttribute("infoCosts"):setValue(g_i18n:formatMoney(productionPoint.costsPerActiveMonth, 0, true))
            end
        end
    end
end
function InGameMenuProductionFrame.setStatusBarValue(_, statusBarElement, value, lowIsDanger)
    local profile = InGameMenuProductionFrame.PROFILES.STATUS_BAR
    if lowIsDanger and value < InGameMenuProductionFrame.STATUS_BAR_LOW or not lowIsDanger and InGameMenuProductionFrame.STATUS_BAR_HIGH < value then
        profile = InGameMenuProductionFrame.PROFILES.STATUS_BAR_DANGER
    end
    statusBarElement:applyProfile(profile)
    local minSize = 0
    if statusBarElement.startSize ~= nil then
        minSize = statusBarElement.startSize[1] + statusBarElement.endSize[1]
    end
    statusBarElement:setSize(math.max(minSize, (statusBarElement.parent.absSize[1] - statusBarElement.margin[1] * 2) * math.min(1, value)), nil)
end
function InGameMenuProductionFrame:onListSelectionChanged(list, _, index)
    if list == self.pointsList then
        if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED then
            self.selectedProductionPoint = self.productionPoints[index]
        else
            self.selectedProductionPoint = self.unownedProductionPoints[index]
        end
        if self.selectedProductionPoint ~= nil then
            self.selectedProduction = self.selectedProductionPoint.sortedProductions[self.productsList:getSelectedIndexInSection()]
            self.selectedStorage = nil
            self.productsList:reloadData()
            if not self.isReloading then
                self.productsList:setSelectedIndex(1)
            end
        end
    elseif list == self.productsList and self.selectedProductionPoint ~= nil then
        self.selectedProduction = self.selectedProductionPoint.sortedProductions[self.productsList:getSelectedIndexInSection()]
        self.selectedStorage = nil
        local e = #self.detailsList.elements
        for e = e, 1, -1 do
            self.detailsList:queueReusableCell(self.detailsList.elements[e])
        end
        self.detailsList:buildSectionInfo()
        self.detailsList:updateView()
    end
    if self.selectedProductionPoint ~= nil then
        if self.selectedProductionPoint.storage == nil then
            if self.selectedProductionPoint.spec_factory ~= nil then
                self.selectedStorage = self.selectedProductionPoint.spec_factory.storage.sortedFillTypes[index]
            end
        else
            self.selectedStorage = self.selectedProductionPoint.storage.sortedFillTypes[index]
        end
        self:updateMenuButtons()
    end
end
function InGameMenuProductionFrame:onButtonActivate()
    if g_currentMission:getHasPlayerPermission("manageProductions") then
        local production, productionPoint = self:getSelectedProduction()
        if production ~= nil then
            local state = productionPoint:getIsProductionEnabled(production.id)
            productionPoint:setProductionState(production.id, not state)
            self:updateProductionLists()
        end
    else
        InfoDialog.show(g_i18n:getText("shop_messageNoPermissionGeneral"), nil, nil, DialogElement.TYPE_WARNING)
    end
end
function InGameMenuProductionFrame:onButtonToggleOutputMode()
    if g_currentMission:getHasPlayerPermission("manageProductions") then
        local production, productionPoint = self:getSelectedProduction()
        local fillType = production.primaryProductFillType
        if fillType ~= FillType.UNKNOWN then
            productionPoint:toggleOutputDistributionMode(fillType)
            self.productsList:reloadData()
        end
    else
        InfoDialog.show(g_i18n:getText("shop_messageNoPermissionGeneral"), nil, nil, DialogElement.TYPE_WARNING)
    end
end
function InGameMenuProductionFrame:onButtonHotspot()
    local _, productionPoint = self:getSelectedProduction()
    if productionPoint ~= nil then
        local hotspot = productionPoint.owningPlaceable ~= nil and productionPoint.owningPlaceable:getHotspot() or productionPoint:getHotspot()
        if hotspot ~= nil then
            if g_currentMission.currentMapTargetHotspot == hotspot then
                g_currentMission:setMapTargetHotspot(nil)
            else
                g_currentMission:setMapTargetHotspot(hotspot)
            end
            self:updateMenuButtons()
            return
        end
        g_currentMission:setMapTargetHotspot(nil)
    end
end
function InGameMenuProductionFrame:onButtonVisit()
    local _, productionPoint = self:getSelectedProduction()
    if productionPoint ~= nil then
        local hotspot = productionPoint.owningPlaceable ~= nil and productionPoint.owningPlaceable:getHotspot() or productionPoint:getHotspot()
        if hotspot ~= nil then
            local x, y, z = hotspot:getTeleportWorldPosition()
            if x ~= nil and (y ~= nil and z ~= nil) then
                if g_localPlayer:getCurrentVehicle() ~= nil then
                    g_localPlayer:leaveVehicle()
                end
                g_localPlayer:teleportTo(x, y, z)
                g_gui:changeScreen(nil)
            end
        end
    end
end
function InGameMenuProductionFrame:updateProductionLists()
    local productionPoints = table.copyIndex(self.chainManager:getProductionPointsForFarmId(self.playerFarm.farmId))
    self.productionPoints = {}
    local unownedProductionPoints = table.copyIndex(self.chainManager:getUnownedProductionPoints())
    self.unownedProductionPoints = {}
    local factories = self.chainManager:getFactoriesForFarmId(self.playerFarm.farmId)
    for _, factory in pairs(factories) do
        table.insert(productionPoints, factory)
    end
    local unownedFactories = self.chainManager:getUnownedFactories()
    for factory, factory in pairs(unownedFactories) do
        table.insert(unownedProductionPoints, factory)
    end
    local function pointSortFunc(pointsTable, targetTable)
        for _, productionPoint in ipairs(pointsTable) do
            table.insert(targetTable, productionPoint)
            productionPoint.sortedProductions = {}
            if productionPoint.productions ~= nil then
                for _, production in ipairs(productionPoint.productions) do
                    table.insert(productionPoint.sortedProductions, production)
                end
                table.sort(productionPoint.sortedProductions, function(productionA, productionB)
                    local nameA = productionA.name
                    if nameA == nil then
                        nameA = g_fillTypeManager:getFillTypeTitleByIndex(productionA.primaryProductFillType)
                    end
                    local nameB = productionB.name
                    if nameB == nil then
                        nameB = g_fillTypeManager:getFillTypeTitleByIndex(productionB.primaryProductFillType)
                    end
                    return nameA < nameB
                end)
                productionPoint.sortedInputFillTypes = {}
                productionPoint.sortedOutputFillTypes = {}
                for _, production in ipairs(productionPoint.inputFillTypeIdsArray) do
                    table.insert(productionPoint.sortedInputFillTypes, production)
                end
                table.sort(productionPoint.sortedInputFillTypes, function(a, b)
                    return g_fillTypeManager:getFillTypeTitleByIndex(a) < g_fillTypeManager:getFillTypeTitleByIndex(b)
                end)
                for _, production in ipairs(productionPoint.outputFillTypeIdsArray) do
                    table.insert(productionPoint.sortedOutputFillTypes, production)
                end
                table.sort(productionPoint.sortedOutputFillTypes, function(a, b)
                    return g_fillTypeManager:getFillTypeTitleByIndex(a) < g_fillTypeManager:getFillTypeTitleByIndex(b)
                end)
            end
        end
    end
    pointSortFunc(productionPoints, self.productionPoints)
    pointSortFunc(unownedProductionPoints, self.unownedProductionPoints)
    table.sort(self.productionPoints, function(a, b)
        return a:getName() < b:getName()
    end)
    table.sort(self.unownedProductionPoints, function(a, b)
        return a:getName() < b:getName()
    end)
    self.isReloading = true
    self.pointsList:reloadData()
    local hasPoints = self.pointsList:getItemCount() > 0
    self.productsBoxBg:setVisible(hasPoints)
    self.productsContainer:setVisible(hasPoints)
    local factory = not hasPoints
    if factory then
        factory = self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED
    end
    self.noPointsOwnedText:setVisible(factory)
    local factory = not hasPoints
    if factory then
        factory = self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_UNOWNED
    end
    self.allPointsBoughtText:setVisible(factory)
    if hasPoints then
        self.productsList:reloadData()
    end
    self.detailsBoxBg:setVisible(hasPoints)
    self.detailsContainer:setVisible(hasPoints)
    self.isReloading = false
    self:updateMenuButtons()
end
InGameMenuProductionFrame.SYMBOL_L10N = {
    ["TEXT_OWNED"] = "ui_productionsOwned",
    ["TEXT_UNOWNED"] = "ui_productionsAvailable",
    ["TEXT_NO_POINTS"] = "ui_noProductionPoints",
    ["TEXT_ALL_POINTS_OWNED"] = "ui_allProductionPointsOwned",
    ["TEXT_STORAGE"] = "statistic_storage",
    ["TEXT_OUTGOING"] = "ui_productionsOutgoing",
    ["TEXT_DEACTIVATED"] = "ui_productionsDeactivated"
}
InGameMenuProductionFrame.PROFILES = {
    ["STATUS_BAR"] = "fs25_productionDetailsListItemBar",
    ["STATUS_BAR_DANGER"] = "fs25_productionDetailsListItemBarDanger"
}