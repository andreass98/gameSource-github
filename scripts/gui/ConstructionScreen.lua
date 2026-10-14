ConstructionScreen = {}
ConstructionScreen.CELL_NAME_DETAIL = "detailTemplate"
ConstructionScreen.CELL_NAME_FILL_TYPES = "fillTypesTemplate"
ConstructionScreen.INPUT_CONTEXT = "CONSTRUCTION_MENU"
local ConstructionScreen_mt = Class(ConstructionScreen, ScreenElement)
function ConstructionScreen.register()
    local constructionScreen = ConstructionScreen.new()
    g_gui:loadGui("dataS/gui/ConstructionScreen.xml", "ConstructionScreen", constructionScreen)
    if g_addCheatCommands then
        addConsoleCommand("gsConstructionScreenUIToggle", "Toggle construction screen UI", "consoleCommandToggleUI", ConstructionScreen)
    end
    return constructionScreen
end
function ConstructionScreen.new(target, custom_mt)
    -- upvalues: (copy) ConstructionScreen_mt
    local self = ScreenElement.new(target, custom_mt or ConstructionScreen_mt)
    self.isMouseMode = true
    self.camera = GuiTopDownCamera.new()
    self.cursor = GuiTopDownCursor.new()
    self.sound = ConstructionSound.new()
    self.brush = nil
    self.items = {}
    self.menuEvents = {}
    self.brushEvents = {}
    self.configEvents = {}
    self.marqueeBoxes = {}
    self.clonedElements = {}
    self.detailsCache = {}
    self.detailsTemplates = {}
    self.configItemCache = {}
    self.configItemCacheLarge = {}
    return self
end
function ConstructionScreen.createFromExistingGui(gui, guiName)
    local newGui = ConstructionScreen.new()
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    return newGui
end
function ConstructionScreen:delete()
    self.camera:delete()
    self.cursor:delete()
    self.sound:delete()
    if self.selectorBrush ~= nil then
        self.selectorBrush:delete()
    end
    if self.destructBrush ~= nil then
        self.destructBrush:delete()
    end
    for k, clone in pairs(self.clonedElements) do
        clone:delete()
        self.clonedElements[k] = nil
    end
    for k, clone in pairs(self.detailsTemplates) do
        clone:delete()
        self.detailsTemplates[k] = nil
    end
    for k, clone in pairs(self.subCategoryDotBox.elements) do
        clone:delete()
        self.subCategoryDotBox.elements[k] = nil
    end
    for k, clone in pairs(self.detailsCache) do
        for l, clone in pairs(clone) do
            clone:delete()
            self.detailsCache[k][l] = nil
        end
        self.detailsCache[k] = nil
    end
    for k, clone in ipairs(self.configItemCache) do
        clone:delete()
    end
    self.configItemCache = {}
    for k, clone in ipairs(self.configItemCacheLarge) do
        clone:delete()
    end
    self.configItemCacheLarge = {}
    self.subCategoryDotTemplate:delete()
    self.configurationItemTemplate:delete()
    self.configurationItemTemplateLarge:delete()
    ConstructionScreen:superClass().delete(self)
end
function ConstructionScreen:onOpen()
    ConstructionScreen:superClass().onOpen(self)
    g_currentMission.lastConstructionScreenOpenTime = g_time
    g_inputBinding:setContext(ConstructionScreen.INPUT_CONTEXT)
    local viewPortStartX = self.menuBox.absPosition[1] + self.menuBox.absSize[1]
    self.viewPortStartX = viewPortStartX
    self.camera:setTerrainRootNode(g_terrainNode)
    self.camera:setEdgeScrollingOffset(viewPortStartX, 0, 1, 1)
    self.camera:activate()
    self.cursor:activate()
    self.originalSafeFrameOffsetX = g_safeFrameOffsetX
    g_safeFrameOffsetX = viewPortStartX + g_safeFrameOffsetX
    if self.selectorBrush == nil then
        self.selectorBrush = g_constructionBrushTypeManager:getClassObjectByTypeName("select").new(nil, self.cursor)
    end
    self:setBrush(self.selectorBrush, true)
    if self.destructBrush == nil then
        self.destructBrush = g_constructionBrushTypeManager:getClassObjectByTypeName("destruct").new(nil, self.cursor)
    end
    self.destructMode = false
    local class = g_inputBinding.lastInputMode == GS_INPUT_HELP_MODE_KEYBOARD
    self.isMouseMode = class
    g_messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)
    self:rebuildData()
    if self.currentCategory == nil then
        self:setCurrentCategory(1, 1)
    end
    self:updateMenuState()
    FocusManager:setFocus(self.itemList)
    self.originalInputHelpVisibility = g_currentMission.hud.inputHelp:getVisible()
    g_currentMission.hud:setInputHelpVisible(true, true)
    g_messageCenter:subscribe(MessageType.SLOT_USAGE_CHANGED, self.onSlotUsageChanged, self)
    if g_isDevelopmentVersion then
        g_messageCenter:subscribe(MessageType.APP_WINDOW_FOCUS_CHANGED, self.onAppWindowFocusChanged, self)
    end
    if g_localPlayer ~= nil then
        local class = false
        if g_localPlayer:getCurrentVehicle() == nil then
            class = g_localPlayer.camera.isFirstPerson
        end
        self.wasFirstPerson = class
        if self.wasFirstPerson then
            g_localPlayer.graphicsComponent:setModelVisibility(true)
        end
    end
end
function ConstructionScreen:onClose(_)
    if g_localPlayer ~= nil and self.wasFirstPerson then
        g_localPlayer.graphicsComponent:setModelVisibility(false)
        self.wasFirstPerson = nil
    end
    g_messageCenter:unsubscribeAll(self)
    g_currentMission.hud:setInputHelpVisible(self.originalInputHelpVisibility)
    g_currentMission.lastConstructionScreenOpenTime = -1
    self:setBrush(nil, false)
    g_safeFrameOffsetX = self.originalSafeFrameOffsetX
    self.camera:setEdgeScrollingOffset(0, 0, 1, 1)
    self.cursor:deactivate()
    self.camera:deactivate()
    self:removeMenuActionEvents()
    g_inputBinding:revertContext()
    ConstructionScreen:superClass().onClose(self)
end
function ConstructionScreen:onGuiSetupFinished()
    ConstructionScreen:superClass().onGuiSetupFinished(self)
    self.subCategoryDotTemplate:unlinkElement()
    FocusManager:removeElement(self.subCategoryDotTemplate)
    self.configurationItemTemplate:unlinkElement()
    FocusManager:removeElement(self.configurationItemTemplate)
    self.configurationItemTemplateLarge:unlinkElement()
    FocusManager:removeElement(self.configurationItemTemplateLarge)
    self:buildCellDatabase()
end
function ConstructionScreen:update(dt)
    ConstructionScreen:superClass().update(self, dt)
    g_currentMission.hud:updateBlinkingWarning(dt)
    g_currentMission.hud.sideNotifications:update(dt)
    self.camera:setCursorLocked(self.cursor.isCatchingCursor)
    self.camera:update(dt)
    if self.isMouseMode and self.isMouseInMenu then
        self.cursor:setCameraRay(nil)
    else
        self.cursor:setCameraRay(self.camera:getPickRay())
    end
    if self.configurations == nil then
        self.cursor:update(dt)
        self.brush:update(dt)
    end
    if self.brush.inputTextDirty then
        self:updateBrushActionTexts()
        self.brush.inputTextDirty = false
    end
    if self.sound:setActiveSound(self.brush.activeSoundId, self.brush.activeSoundPitchModifier) then
        self.brush.activeSoundId = ConstructionSound.ID.NONE
    end
    self:updateMarqueeAnimation(dt)
end
function ConstructionScreen:setBrush(brush, skipMenuUpdate)
    if brush ~= self.brush then
        if self.brush ~= nil then
            self.brush:deactivate()
            if self.brush ~= self.selectorBrush and self.brush ~= self.destructBrush then
                self.brush:delete()
            end
        end
        self:removeMenuActionEvents()
        self:removeBrushActionEvents()
        self.camera:removeActionEvents()
        self.cursor:removeActionEvents()
        self.brush = brush
        self.camera:registerActionEvents()
        self.cursor:registerActionEvents()
        if self.brush == nil or self.brush == self.selectorBrush then
            self:registerMenuActionEvents(true)
        elseif self.brush ~= nil then
            self:registerMenuActionEvents(false)
        end
        self.buttonPagePrev:setVisible(self.brush ~= self.destructBrush)
        self.buttonPageNext:setVisible(self.brush ~= self.destructBrush)
        if self.brush == self.destructBrush then
            self.buttonBack:setText(g_i18n:getText("ui_demolitionModeExit"))
        else
            self.buttonBack:setText(g_i18n:getText("button_back"))
        end
        if brush ~= nil then
            self.brush:activate()
            if self.brush ~= nil and self.brush:class() == self.brush:class() then
                self.brush:copyState(previousBrush)
            end
            self:registerBrushActionEvents()
        end
        if not skipMenuUpdate then
            self:updateMenuState(previousBrush)
        end
        self:updateBrushActionTexts()
        self:updateMenuActionTexts()
        self.camera:setMovementDisabledForGamepad(self.brush ~= nil)
    end
end
function ConstructionScreen:mouseEvent(posX, posY, isDown, isUp, button, _)
    self.isMouseInMenu = GuiUtils.checkOverlayOverlap(posX, posY, self.menuBox.absPosition[1], self.menuBox.absPosition[2], self.menuBox.absSize[1], self.menuBox.absSize[2])
    if not self.isMouseInMenu then
        self.isMouseInMenu = GuiUtils.checkOverlayOverlap(posX, posY, self.categoryContainer.absPosition[1], self.categoryContainer.absPosition[2], self.categoryContainer.absSize[1], self.categoryContainer.absSize[2])
    end
    self.camera.mouseDisabled = self.isMouseInMenu
    self.cursor.mouseDisabled = self.isMouseInMenu
    self.camera:setMouseEdgeScrollingActive(self.brush ~= self.selectorBrush)
    self.camera:mouseEvent(posX, posY, isDown, isUp, button)
    if self.configurations == nil then
        self.cursor:mouseEvent(posX, posY, isDown, isUp, button)
    end
end
function ConstructionScreen:draw()
    if not ConstructionScreen.uiHidden then
        ConstructionScreen:superClass().draw(self)
        g_currentMission.hud:drawInputHelp(self.helpDisplay.position[1], self.helpDisplay.position[2])
        g_currentMission.hud.gameInfoDisplay:draw()
        g_currentMission.hud:drawSideNotification()
        g_currentMission.hud:drawBlinkingWarning()
        if self.configurations == nil then
            self.cursor:draw()
            if self.brush.draw ~= nil then
                self.brush:draw()
            end
        end
    end
end
function ConstructionScreen:onInputModeChanged(inputMode)
    self.isMouseMode = inputMode[1] == GS_INPUT_HELP_MODE_KEYBOARD
    self:updateMenuState()
    self:updateMenuActionTexts()
end
function ConstructionScreen:onAppWindowFocusChanged(hasFocus)
    if self.camera ~= nil then
        self.camera:setMouseEdgeScrollingActive(hasFocus)
    end
end
function ConstructionScreen:registerMenuActionEvents(hasMenuButtons)
    self.menuEvents = {}
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onButtonMenuAccept, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)
    g_inputBinding:setActionEventTextVisibility(eventId, false)
    self.acceptButtonEvent = eventId
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_BACK, self, self.onButtonMenuBack, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)
    self.backButtonEvent = eventId
    table.insert(self.menuEvents, eventId)
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.PAUSE, g_localPlayer.inputComponent, g_localPlayer.inputComponent.onInputPause, false, true, false, true)
    g_inputBinding:setActionEventTextVisibility(eventId, false)
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.TOGGLE_HELP_TEXT, g_localPlayer.inputComponent, g_localPlayer.inputComponent.onInputToggleHelpText, false, true, false, true)
    g_inputBinding:setActionEventTextVisibility(eventId, false)
    if hasMenuButtons then
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onMenuUpDown, false, true, true, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        table.insert(self.menuEvents, eventId)
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onMenuLeftRight, false, true, true, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        table.insert(self.menuEvents, eventId)
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onReleaseUpDown, true, false, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        table.insert(self.menuEvents, eventId)
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onReleaseLeftRight, true, false, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        table.insert(self.menuEvents, eventId)
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_PAGE_PREV, self, self.onMenuPagePrev, false, true, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        table.insert(self.menuEvents, eventId)
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_PAGE_NEXT, self, self.onMenuPageNext, false, true, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        table.insert(self.menuEvents, eventId)
    end
    self:updateMenuActionTexts()
end
function ConstructionScreen.onMenuUpDown(_, _, inputValue)
    g_gui:onMenuInput(InputAction.MENU_AXIS_UP_DOWN, inputValue)
end
function ConstructionScreen.onMenuLeftRight(_, _, inputValue)
    g_gui:onMenuInput(InputAction.MENU_AXIS_LEFT_RIGHT, inputValue)
end
function ConstructionScreen:onReleaseUpDown(action)
    g_gui:onReleaseMovement(InputAction.MENU_AXIS_UP_DOWN)
end
function ConstructionScreen:onReleaseLeftRight(action)
    g_gui:onReleaseMovement(InputAction.MENU_AXIS_LEFT_RIGHT)
end
function ConstructionScreen:onMenuPagePrev()
    self:onCategoryChanged(nil, nil, true)
end
function ConstructionScreen:onMenuPageNext()
    self:onCategoryChanged(nil, nil, false)
end
function ConstructionScreen:updateMenuActionTexts()
    g_inputBinding:setActionEventTextVisibility(self.backButtonEvent, false)
    if self.brush == self.selectorBrush then
        g_inputBinding:setActionEventText(self.backButtonEvent, g_i18n:getText("input_CONSTRUCTION_EXIT"))
    else
        g_inputBinding:setActionEventText(self.backButtonEvent, g_i18n:getText("input_CONSTRUCTION_CANCEL"))
    end
end
function ConstructionScreen:removeMenuActionEvents()
    for _, event in ipairs(self.menuEvents) do
        g_inputBinding:removeActionEvent(event)
    end
end
function ConstructionScreen:onButtonMenuAccept()
    if self.isMouseMode or self.brush == self.selectorBrush and self.selectorBrush.lastPlaceable == nil or self.configurations ~= nil then
        self.dragIsLocked = true
        g_gui:notifyControls("MENU_ACCEPT")
    else
        self:onButtonPrimary()
    end
end
function ConstructionScreen:onButtonMenuBack()
    if self.brush:canCancel() then
        self.brush:cancel()
        return
    elseif self.brush == self.destructBrush then
        self.destructMode = false
        self:setBrush(self.previousBrush)
        return
    elseif self.configurations == nil then
        if self.brush.isSelector then
            self:changeScreen(nil)
        else
            self:setBrush(self.selectorBrush)
        end
    else
        self:onShowConfigs()
        return
    end
end
function ConstructionScreen:onCategoryChanged(_, _, isLeftButton)
    local oldCategory = self.currentCategory
    local oldCategory
    if isLeftButton then
    end
    local oldCategory
    if oldCategory <= 0 then
        oldCategory = #self.categories
    else
        oldCategory = #self.categories < oldCategory and 1 or oldCategory
    end
    if oldCategory ~= self.currentCategory then
        self:setCurrentCategory(oldCategory)
    end
end
function ConstructionScreen:onSubCategoryChanged(index)
    self:setCurrentTab(index)
end
function ConstructionScreen:registerBrushActionEvents()
    local brush = self.brush
    if brush ~= nil then
        self.brushEvents = {}
        if brush.supportsPrimaryButton then
            local eventId
            if brush.supportsPrimaryDragging then
                _, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_PRIMARY, self, self.onButtonPrimaryDrag, true, true, true, true)
                table.insert(self.brushEvents, eventId)
                self.primaryBrushEvent = eventId
            else
                _, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_PRIMARY, self, self.onButtonPrimary, false, true, false, true)
                table.insert(self.brushEvents, eventId)
                self.primaryBrushEvent = eventId
            end
            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_HIGH)
        end
        if brush.supportsSecondaryButton then
            local eventId
            if brush.supportsSecondaryDragging then
                _, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_SECONDARY, self, self.onButtonSecondaryDrag, true, true, true, true)
                table.insert(self.brushEvents, eventId)
                self.secondaryBrushEvent = eventId
            else
                _, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_SECONDARY, self, self.onButtonSecondary, false, true, false, true)
                table.insert(self.brushEvents, eventId)
                self.secondaryBrushEvent = eventId
            end
            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_HIGH)
        end
        if brush.supportsTertiaryButton then
            _, self.tertiaryBrushEvent = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_TERTIARY, self, self.onButtonTertiary, false, true, false, true)
            g_inputBinding:setActionEventTextPriority(self.tertiaryBrushEvent, GS_PRIO_HIGH)
            table.insert(self.brushEvents, self.tertiaryBrushEvent)
        end
        if brush.supportsFourthButton then
            _, self.fourthBrushEvent = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_FOURTH, self, self.onButtonFourth, false, true, false, true)
            g_inputBinding:setActionEventTextPriority(self.fourthBrushEvent, GS_PRIO_HIGH)
            table.insert(self.brushEvents, self.fourthBrushEvent)
        end
        if brush.placeableHasConfigs then
            _, self.showConfigsEvent = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_SHOW_CONFIGS, self, self.onShowConfigs, false, true, false, true)
            g_inputBinding:setActionEventText(self.showConfigsEvent, g_i18n:getText("input_CONSTRUCTION_SHOW_CONFIGS"))
            g_inputBinding:setActionEventTextPriority(self.showConfigsEvent, GS_PRIO_HIGH)
            table.insert(self.brushEvents, self.showConfigsEvent)
        end
        if brush.supportsPrimaryAxis then
            _, self.primaryBrushAxisEvent = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_ACTION_PRIMARY, self, self.onAxisPrimary, false, not brush.primaryAxisIsContinuous, brush.primaryAxisIsContinuous, true)
            g_inputBinding:setActionEventTextPriority(self.primaryBrushAxisEvent, GS_PRIO_HIGH)
            table.insert(self.brushEvents, self.primaryBrushAxisEvent)
        end
        if brush.supportsSecondaryAxis then
            _, self.secondaryBrushAxisEvent = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_ACTION_SECONDARY, self, self.onAxisSecondary, false, not brush.secondaryAxisIsContinuous, brush.secondaryAxisIsContinuous, true)
            g_inputBinding:setActionEventTextPriority(self.secondaryBrushAxisEvent, GS_PRIO_HIGH)
            table.insert(self.brushEvents, self.secondaryBrushAxisEvent)
        end
        if brush.supportsSnapping then
            _, self.snappingBrushEvent = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_SNAPPING, self, self.onButtonSnapping, false, true, false, true)
            g_inputBinding:setActionEventTextPriority(self.snappingBrushEvent, GS_PRIO_HIGH)
            table.insert(self.brushEvents, self.snappingBrushEvent)
        end
    end
end
function ConstructionScreen:updateBrushActionTexts()
    if self.primaryBrushEvent ~= nil then
        local text = self.brush:getButtonPrimaryText()
        if text ~= nil then
            g_inputBinding:setActionEventText(self.primaryBrushEvent, g_i18n:convertText(text))
        end
        g_inputBinding:setActionEventTextVisibility(self.primaryBrushEvent, text ~= nil)
    end
    if self.secondaryBrushEvent ~= nil then
        local text = self.brush:getButtonSecondaryText()
        if text ~= nil then
            g_inputBinding:setActionEventText(self.secondaryBrushEvent, g_i18n:convertText(text))
        end
        g_inputBinding:setActionEventTextVisibility(self.secondaryBrushEvent, text ~= nil)
    end
    if self.tertiaryBrushEvent ~= nil then
        local text = self.brush:getButtonTertiaryText()
        if text ~= nil then
            g_inputBinding:setActionEventText(self.tertiaryBrushEvent, g_i18n:convertText(text))
        end
        g_inputBinding:setActionEventTextVisibility(self.tertiaryBrushEvent, text ~= nil)
    end
    if self.fourthBrushEvent ~= nil then
        local text = self.brush:getButtonFourthText()
        if text ~= nil then
            g_inputBinding:setActionEventText(self.fourthBrushEvent, g_i18n:convertText(text))
        end
        g_inputBinding:setActionEventTextVisibility(self.fourthBrushEvent, text ~= nil)
    end
    if self.primaryBrushAxisEvent ~= nil then
        local text = self.brush:getAxisPrimaryText()
        if text ~= nil then
            g_inputBinding:setActionEventText(self.primaryBrushAxisEvent, g_i18n:convertText(text))
        end
        g_inputBinding:setActionEventTextVisibility(self.primaryBrushAxisEvent, text ~= nil)
    end
    if self.secondaryBrushAxisEvent ~= nil then
        local text = self.brush:getAxisSecondaryText()
        if text ~= nil then
            g_inputBinding:setActionEventText(self.secondaryBrushAxisEvent, g_i18n:convertText(text))
        end
        g_inputBinding:setActionEventTextVisibility(self.secondaryBrushAxisEvent, text ~= nil)
    end
    if self.snappingBrushEvent ~= nil then
        local text = self.brush:getButtonSnappingText()
        if text ~= nil then
            g_inputBinding:setActionEventText(self.snappingBrushEvent, g_i18n:convertText(text))
        end
        g_inputBinding:setActionEventTextVisibility(self.snappingBrushEvent, text ~= nil)
    end
end
function ConstructionScreen:removeBrushActionEvents()
    for _, event in ipairs(self.brushEvents) do
        g_inputBinding:removeActionEvent(event)
    end
    self.primaryBrushEvent = nil
    self.secondaryBrushEvent = nil
    self.tertiaryBrushEvent = nil
    self.fourthBrushEvent = nil
    self.primaryBrushAxisEvent = nil
    self.secondaryBrushAxisEvent = nil
    self.snappingBrushEvent = nil
    self.showConfigsEvent = nil
end
function ConstructionScreen:onButtonPrimary(_, _, _, _, _)
    if not self.isMouseInMenu and self.configurations == nil then
        self.brush:onButtonPrimary()
    end
end
function ConstructionScreen:onButtonPrimaryDrag(_, inputValue, _, _, _)
    if not self.isMouseInMenu then
        local isDown = false
        if inputValue == 1 then
            isDown = self.previousPrimaryDragValue ~= 1
        end
        local isDrag = false
        if inputValue == 1 then
            isDrag = self.previousPrimaryDragValue == 1
        end
        self.previousPrimaryDragValue = inputValue
        if self.dragIsLocked then
            if inputValue == 0 then
                self.dragIsLocked = false
                return
            end
        else
            self.brush:onButtonPrimary(isDown, isDrag, isUp)
        end
    end
end
function ConstructionScreen:onButtonSecondary(_, _, _, _, _)
    if not self.isMouseInMenu then
        self.brush:onButtonSecondary()
    end
end
function ConstructionScreen:onButtonSecondaryDrag(_, inputValue, _, _, _)
    if not self.isMouseInMenu then
        local isDown = false
        if inputValue == 1 then
            isDown = self.previousSecondaryDragValue ~= 1
        end
        local isDrag = false
        if inputValue == 1 then
            isDrag = self.previousSecondaryDragValue == 1
        end
        self.previousSecondaryDragValue = inputValue
        self.brush:onButtonSecondary(isDown, isDrag, inputValue == 0)
    end
end
function ConstructionScreen:onButtonTertiary(_, _, _, _, _)
    self.brush:onButtonTertiary(self)
end
function ConstructionScreen:onButtonFourth(_, _, _, _, _)
    self.brush:onButtonFourth()
end
function ConstructionScreen:onButtonSnapping(_, _, _, _, _)
    self.brush:onButtonSnapping()
end
function ConstructionScreen:onAxisPrimary(_, inputValue, _, _, _)
    self.brush:onAxisPrimary(inputValue)
end
function ConstructionScreen:onAxisSecondary(_, inputValue, _, _, _)
    self.brush:onAxisSecondary(inputValue)
end
function ConstructionScreen:onShowConfigs()
    if self.configsBox:getIsVisible() then
        self.configsBox:setVisible(false)
        self.listBox:setVisible(true)
        self:registerBrushActionEvents()
        self:updateBrushActionTexts()
        self:updateMenuActionTexts()
        for _, event in ipairs(self.configEvents) do
            g_inputBinding:removeActionEvent(event)
        end
        self.cursor:setRotationEnabled(self.cursorRotationEnabled or false)
        self.configurations = nil
        if self.itemList:getItemCount() > 0 then
            FocusManager:setFocus(self.itemList)
        else
            FocusManager:setFocus(self.subCategorySelector)
        end
        self.categorySelector:setDisabled(false)
    else
        self.configsBox:setVisible(true)
        self.listBox:setVisible(false)
        self:removeBrushActionEvents()
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onMenuUpDown, false, true, true, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        local _ = self.configEvents
        table.insert(_, eventId)
        local storeItem, _ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onMenuLeftRight, false, true, true, true)
        g_inputBinding:setActionEventTextVisibility(_, false)
        local _ = self.configEvents
        table.insert(_, _)
        local storeItem, _ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onReleaseUpDown, true, false, false, true)
        g_inputBinding:setActionEventTextVisibility(_, false)
        local _ = self.configEvents
        table.insert(_, _)
        local storeItem, _ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onReleaseLeftRight, true, false, false, true)
        g_inputBinding:setActionEventTextVisibility(_, false)
        local _ = self.configEvents
        table.insert(_, _)
        self.cursorRotationEnabled = self.cursor.rotationEnabled
        self.cursor:setRotationEnabled(false)
        local storeItem = self.brush.storeItem
        local _ = {}
        if storeItem.defaultConfigurationIds ~= nil then
            for configName, index in pairs(storeItem.defaultConfigurationIds) do
                _[configName] = index
            end
        end
        if self.brush.configurations ~= nil then
            for configName, index in pairs(self.brush.configurations) do
                _[configName] = index
            end
        end
        self.needsRefocus = true
        self.configurations = _
        self.configurationData = {}
        self:processStoreItemConfigurations(storeItem)
        self:updateConfigOptionsDisplay(storeItem)
        self.categorySelector:setDisabled(true)
    end
end
function ConstructionScreen:onClickDestruct()
    if self.destructMode then
        self.destructMode = false
        self:setBrush(self.previousBrush)
    else
        self.destructMode = true
        self.previousBrush = self.brush
        self:setBrush(self.destructBrush)
    end
end
function ConstructionScreen:onFocusConfigurationOption(element)
    self.focusedColorElement = nil
    self.focusedButtonElement = nil
    self.focusedOptionElement = nil
    if element.name == "button" then
        self.focusedButtonElement = element
    elseif element.name == "color" then
        self.focusedColorElement = element
    elseif element.name == "option" then
        self.focusedOptionElement = element
    elseif element.name == "yesNoOption" then
        self.focusedOptionElement = element
    end
    self:updateConfigurationButton()
end
function ConstructionScreen:onLeaveConfigurationOption(_)
    self.focusedColorElement = nil
    self.focusedButtonElement = nil
    self.focusedOptionElement = nil
    self:updateConfigurationButton()
end
function ConstructionScreen:updateConfigurationButton()
    local visible = true
    if self.focusedButtonElement == nil then
        visible = self.focusedColorElement ~= nil
    end
    self.configButton:setVisible(visible)
    self.buttonsPanel:invalidateLayout()
end
function ConstructionScreen:onClickConfigAction()
    if self.focusedColorElement == nil then
        if self.focusedButtonElement ~= nil then
            self.focusedButtonElement:onFocusActivate()
        end
    else
        self.focusedColorElement:onFocusActivate()
    end
end
function ConstructionScreen:getNumberOfItemsInSection(list, _)
    if list == self.categorySelector then
        return #self.categories
    end
    if self.currentCategory == nil or self.currentTab == nil then
        return 0
    end
    local items = self.items[self.currentCategory][self.currentTab]
    return items == nil and 0 or #items
end
function ConstructionScreen:populateCellForItemInSection(list, _, index, cell)
    if list == self.categorySelector then
        local category = self.categories[index]
        local tabButton = cell:getAttribute("tabButton")
        tabButton:setImageFilename(nil, category.iconFilename)
        tabButton:setImageUVs(nil, category.iconUVs)
        tabButton:setImageSlice(nil, category.iconSliceId)
        function tabButton.onClickCallback()
            -- upvalues: (copy) self, (copy) index
            self:setCurrentCategory(index)
        end
        return
    else
        local category = self.items[self.currentCategory][self.currentTab][index]
        cell:getAttribute("price"):setValue(g_i18n:formatMoney(category.price, 0, true, true))
        local tabButton = cell:getAttribute("terrainLayer")
        tabButton:setVisible(category.terrainOverlayLayer ~= nil)
        local tabButton = cell:getAttribute("icon")
        tabButton:setVisible(category.imageFilename ~= nil)
        if category.imageFilename == nil then
            if category.terrainOverlayLayer ~= nil then
                cell:getAttribute("terrainLayer"):setTerrainLayer(g_terrainNode, category.terrainOverlayLayer)
            end
        else
            cell:getAttribute("icon"):setImageFilename(category.imageFilename)
        end
    end
end
function ConstructionScreen:onListSelectionChanged(list, _, index)
    if not g_gui.currentlyReloading then
        if list == self.itemList then
            local selectedBrush = self.items[self.currentCategory][self.currentTab][index]
            if selectedBrush == nil then
                self:assignItemAttributeData(nil)
                return
            end
            self.lastSelectionIndex = index
            self:assignItemAttributeData(selectedBrush)
        end
    end
end
function ConstructionScreen:onListHighlightChanged(list, _, index)
    if not g_gui.currentlyReloading then
        if list == self.itemList then
            if self.items[self.currentCategory][self.currentTab][index or self.lastSelectionIndex] == nil then
                self:assignItemAttributeData(nil)
                return
            end
            self:assignItemAttributeData(selectedBrush)
        end
    end
end
function ConstructionScreen:onClickItem()
    local item = self.items[self.currentCategory][self.currentTab][self.itemList.selectedIndex]
    local brush = item.brushClass.new(nil, self.cursor)
    if item.brushParameters ~= nil then
        brush:setStoreItem(item.storeItem)
        brush:setParameters(unpack(item.brushParameters))
        brush.uniqueIndex = item.uniqueIndex
    end
    self.destructMode = false
    self:setBrush(brush, true)
end
function ConstructionScreen:refreshDetails()
    self:onListSelectionChanged(self.itemList, 1, self.itemList.selectedIndex)
end
function ConstructionScreen:assignItemAttributeData(selectedBrush)
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
    local displayItem = nil
    if selectedBrush ~= nil then
        self.itemDetailsName:setText(selectedBrush.name)
        displayItem = selectedBrush.displayItem
    end
    local brand = self.itemDetailsName
    local k = selectedBrush ~= nil
    brand:setVisible(k)
    local brand = self.attributesLayout
    local k = displayItem ~= nil
    brand:setVisible(k)
    if displayItem == nil then
        self.itemDetailsBrandImage:setVisible(false)
        self.itemDetailsModName:setVisible(false)
        self.itemDetailsDescription:setVisible(false)
    else
        local k = #self.attributesLayout.elements
        local brand = 1
        local modName = -1
        for k = k, brand, modName do
            self:queueDetailsCell(self.attributesLayout.elements[k])
        end
        self:assignItemTextData(displayItem)
        self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, displayItem.fillTypeIconFilenames)
        self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, displayItem.foodFillTypeIconFilenames)
        self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_INPUT, displayItem.prodPointInputFillTypeIconFilenames)
        self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_OUTPUT, displayItem.prodPointOutputFillTypeIconFilenames)
        self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_INPUT, displayItem.sellingStationFillTypesIconFilenames)
        self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_OUTPUT, displayItem.buyingStationFillTypesIconFilenames)
        self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, displayItem.objectStorageFillTypesIconFilenames)
        local brand = nil
        local modName = nil
        local k = nil
        if displayItem.storeItem ~= nil then
            brand = g_brandManager:getBrandByIndex(displayItem.storeItem.brandIndex)
            if brand ~= nil then
                self.itemDetailsBrandImage:setImageFilename(brand.image)
            end
            if displayItem.storeItem.isMod and displayItem.storeItem.dlcTitle == nil then
                modName = "Mod"
            elseif displayItem.storeItem.isMod and displayItem.storeItem.dlcTitle ~= nil then
                modName = displayItem.storeItem.dlcTitle .. " (Mod)"
            elseif displayItem.storeItem.dlcTitle ~= nil then
                modName = displayItem.storeItem.dlcTitle
            end
            self.itemDetailsModName:setText(modName or "")
            self.itemDetailsDescription:setText(displayItem.functionText)
        end
        self.itemDetailsBrandImage:setVisible(brand ~= nil)
        self.itemDetailsModName:setVisible(modName ~= nil)
        self.itemDetailsDescription:setVisible(k ~= nil)
        self.descriptionLayout:invalidateLayout()
        self.attributesLayout:invalidateLayout()
    end
end
function ConstructionScreen:assignItemTextData(displayItem)
    local numAttributesUsed = 0
    if displayItem ~= nil and displayItem.attributeValues ~= nil then
        for i, value in pairs(displayItem.attributeValues) do
            local cell = self:dequeueDetailsCell(ConstructionScreen.CELL_NAME_DETAIL)
            local icon = cell:getDescendantByName("icon")
            local text = cell:getDescendantByName("text")
            local profile = displayItem.attributeIconProfiles[i]
            if profile ~= nil and profile ~= "" then
                if type(value) == "string" then
                    local value = value:gsub("%$SLOTS%$", (string.format("(%0d / %0d)", g_currentMission.slotSystem.slotUsage, g_currentMission.slotSystem.slotLimit)))
                end
                text:setText(value)
                icon:applyProfile(profile)
            end
            cell:setSize(icon.absSize[1] + icon.margin[1] + text.absSize[1], nil)
        end
    end
end
function ConstructionScreen:assignItemFillTypesData(baseIconProfile, iconFilenames)
    if iconFilenames ~= nil and #iconFilenames > 0 then
        local totalWidth = 0
        local cell = self:dequeueDetailsCell(ConstructionScreen.CELL_NAME_FILL_TYPES)
        local cellIcon = cell:getDescendantByName("icon")
        local iconsLayout = cell:getDescendantByName("iconsLayout")
        cellIcon:applyProfile(baseIconProfile)
        for _, iconFilename in pairs(iconFilenames) do
            local icon = self.fruitIconTemplate:clone(iconsLayout)
            icon:setVisible(true)
            table.insert(self.clonedElements, icon)
            icon:applyProfile(ShopItemsFrame.PROFILE.ICON_FRUIT_TYPE)
            icon:setImageFilename(iconFilename)
        end
        local parentSize = math.min(self.attributesLayout.absSize[1] * 0.91, totalWidth)
        local iconsLayoutSize = parentSize + cellIcon.absSize[1] + cellIcon.margin[1]
        iconsLayout:setSize(totalWidth, nil)
        iconsLayout:setPosition(0, nil)
        iconsLayout.parent:setSize(parentSize, nil)
        cell:setSize(iconsLayoutSize, nil)
        iconsLayout:invalidateLayout()
        if iconsLayoutSize < totalWidth then
            self.marqueeBoxes[iconsLayout] = 0
            return
        end
        self.marqueeBoxes[iconsLayout] = nil
    end
end
function ConstructionScreen:updateMarqueeAnimation(dt)
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
function ConstructionScreen:onSlotUsageChanged()
    self:refreshDetails()
end
function ConstructionScreen:processStoreItemConfigurations(placeable)
    self.configSelection = {
        ["title"] = g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIGURATION_LABEL),
        ["texts"] = {},
        ["prices"] = {},
        ["options"] = {}
    }
    self.currentConfigSet = 1
    local configSets = placeable.configurationSets
    local configSets = (placeable.configurationSets == nil or #placeable.configurationSets == 0) and {
        {
            ["name"] = "",
            ["configurations"] = {},
            ["isDefault"] = true
        }
    } or configSets
    if placeable.configurations == nil then
        table.insert(self.configSelection.options, {})
        self.displayableColorCount = 0
    else
        for i, configSet in ipairs(configSets) do
            if configSet.isDefault then
                self.currentConfigSet = i
            end
            if configSet.overwrittenTitle ~= nil then
                self.configSelection.title = configSet.overwrittenTitle
            end
            local price = 0
            for name, index in pairs(configSet.configurations) do

            end
            table.insert(self.configSelection.prices, price)
            table.insert(self.configSelection.texts, configSet.name)
            local setOptions = self:processStoreItemConfigurationSet(placeable, configSet)
            table.insert(self.configSelection.options, setOptions)
        end
        for i, configSet in pairs(configSets[self.currentConfigSet].configurations) do
            self.configurations[i] = configSet
        end
        self.colorPickers = {}
        local defaultSet = 1
        local configurations = g_placeableConfigurationManager:getSortedConfigurationTypes()
        local configSet = 1
        local i = 1
        for configSet = configSet, #configurations, i do
            local price = configurations[configSet]
            if placeable.configurations[price] ~= nil then
                local isColor = g_placeableConfigurationManager:getConfigurationSelectorType(price) == ConfigurationUtil.SELECTOR_COLOR
                if #placeable.configurations[price] > 1 and isColor then
                    self:processStoreItemColorOption(placeable, price, setOptions, defaultSet)
                    defaultSet = defaultSet + 1
                end
            end
        end
        self.displayableColorCount = defaultSet - 1
    end
end
function ConstructionScreen:processStoreItemConfigurationSet(storeItem, configSet)
    local options = {}
    local configurationTypes = g_placeableConfigurationManager:getSortedConfigurationTypes()
    for _, configName in ipairs(configurationTypes) do
        if g_placeableConfigurationManager:getConfigurationSelectorType(configName) ~= ConfigurationUtil.SELECTOR_COLOR then
            local items = storeItem.configurations[configName]
            if items ~= nil and (#items > 1 and configSet.configurations[configName] == nil) then
                local option = self:processStoreItemConfigurationOption(storeItem, configName, items)
                table.insert(options, option)
            end
        end
    end
    return options
end
function ConstructionScreen.processStoreItemConfigurationOption(_, storeItem, configName, configItems)
    local configOption = {
        ["name"] = configName,
        ["title"] = g_placeableConfigurationManager:getConfigurationAttribute(configName, "title"),
        ["texts"] = {},
        ["icons"] = {},
        ["options"] = {},
        ["defaultIndex"] = 1
    }
    local initialIndex = 1
    local overwrittenTitle = nil
    local hasValidIcons = false
    local index = 1
    for _, item in ipairs(configItems) do
        if item.isDefault then
            configOption.defaultIndex = index
            initialIndex = index
        end
        for _, otherConfigItems in pairs(storeItem.configurations) do
            for _, configItem in pairs(otherConfigItems) do
                if configItem.dependentConfigurations ~= nil then
                    for _, dependentConfiguration in pairs(configItem.dependentConfigurations) do
                        if dependentConfiguration.name == configName then
                            return
                        end
                    end
                end
            end
        end
        if item.isSelectable then
            table.insert(configOption.texts, item.name)
            table.insert(configOption.options, item)
            if item.brandIndex ~= nil then
                local iconFilename = g_brandManager:getBrandIconByIndex(item.brandIndex)
                if iconFilename ~= nil then
                    table.insert(configOption.icons, iconFilename)
                    hasValidIcons = true
                end
            end
            if #configOption.icons ~= #configOption.texts then
                table.insert(configOption.icons, item.name)
            end
        end
    end
    configOption.defaultIndex = initialIndex
    configOption.title = overwrittenTitle or configOption.title
    if not hasValidIcons then
        configOption.icons = nil
    end
    if #configOption.options > 1 then
        return configOption
    end
end
function ConstructionScreen:processStoreItemColorOption(_, configName, colorItems, _)
    local overwrittenTitle = nil
    for _, item in ipairs(colorItems) do

    end
    table.insert(self.colorPickers, {
        ["title"] = overwrittenTitle or g_placeableConfigurationManager:getConfigurationAttribute(configName, "title"),
        ["configName"] = configName,
        ["colorItems"] = colorItems
    })
end
function ConstructionScreen:updateConfigOptionsData(storeItem)
    local displayableOptionCount = 0
    local count = 0
    local i = #self.configurationLayout.elements
    for i = i, 1, -1 do
        local item = self.configurationLayout.elements[i]
        item:setVisible(false)
        FocusManager:removeElement(item)
        item:unlinkElement()
        if item.isLargeConfigItem then
            table.insert(self.configItemCacheLarge, item)
        else
            table.insert(self.configItemCache, item)
        end
    end
    self.focusableElementForScroll = nil
    if #self.configSelection.options > 1 then
        count = 1
        self:updateConfigSetOptionElement(1, storeItem)
    end
    for _, option in ipairs(self.configSelection.options[self.currentConfigSet]) do
        count = count + 1
        self:updateConfigOptionElement(count, option, storeItem)
    end
    self.colorElements = {}
    if self.displayableColorCount > 0 then
        for _, option in ipairs(self.colorPickers) do
            local itemsToDisplay = 0
            local hasCustomColorSupport = false
            local j = 1
            local listElement = #option.colorItems
            local colorElement = 1
            for j = j, listElement, colorElement do
                if option.colorItems[j].isSelectable ~= false then
                end
                if option.colorItems[j].isCustomColor then
                    hasCustomColorSupport = true
                end
            end
            if itemsToDisplay > 1 then
                local listElement = self:getOrCreateConfigItem("color")
                local colorElement = listElement:getDescendantByName("color")
                self.colorElements[_] = colorElement
                local j = option.colorItems
                local option, _
                function colorElement.onClickCallback(sourceElement)
                    -- upvalues: (copy) self, (copy) option, (copy) j, (copy) _, (ref) hasCustomColorSupport
                    local configIndex = self.configurations[option.configName]
                    local colorItem = j[configIndex]
                    local color = colorItem.color
                    local materialTemplateName = colorItem.materialTemplateName
                    local data = self.configurationData[option.configName]
                    if data ~= nil and data[configIndex] ~= nil then
                    end
                    g_inputBinding:setShowMouseCursor(true)
                    ColorPickerDialog.show(self.onPickColor, self, {
                        ["configName"] = option.configName,
                        ["colorOptionIndex"] = _
                    }, j, nil, materialTemplateName, color, hasCustomColorSupport, true, true)
                end
                self:onPickColor(self.configurations[option.configName] or self:getDefaultConfigurationColorIndex(option.configName, j), {
                    ["configName"] = option.configName,
                    ["colorOptionIndex"] = _
                }, nil, true)
                listElement:getDescendantByName("title"):setText(option.title)
            end
        end
    end
    self.displayableOptionCount = displayableOptionCount
    return count
end
function ConstructionScreen:updateConfigOptionsDisplay(storeItem)
    FocusManager:setGui("ConstructionScreen")
    local num = self:updateConfigOptionsData(storeItem)
    self.startClipper:setVisible(num > 0)
    self.configSlider.parent:setVisible(num > 0)
    self.configurationLayout:invalidateLayout()
    FocusManager:setGui(FocusManager.currentGui)
    if self.needsRefocus then
        self:selectFirstConfig()
        self.needsRefocus = false
    end
end
function ConstructionScreen:updateConfigSetOptionElement(_, storeItem)
    local isYesNoOption = false
    if #storeItem.configurationSets > 1 then
        isYesNoOption = storeItem.configurationSets[1].isYesNoOption
    end
    local price = isYesNoOption and "yesNoOption" or "option"
    local listElement = self:getOrCreateConfigItem(price)
    local price
    if isYesNoOption then
        price = listElement:getDescendantByName("yesNoOption")
        price:setIsChecked(self.currentConfigSet ~= 1, true)
    else
        price = listElement:getDescendantByName("option")
        price:setState(self.currentConfigSet)
    end
    price:setTexts(self.configSelection.texts)
    price:setDisabled(false)
    function price.onClickCallback(_, configSetIndex)
        -- upvalues: (copy) storeItem, (copy) self
        for name, _ in pairs(storeItem.configurationSets[self.currentConfigSet].configurations) do
            self.configurations[name] = ConfigurationUtil.getDefaultConfigIdFromItems(storeItem.configurations[name])
        end
        for name, _ in pairs(storeItem.configurationSets[configSetIndex].configurations) do
            self.configurations[name] = _
        end
        self.currentConfigSet = configSetIndex
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
        self:selectFirstConfig()
    end
    listElement:getDescendantByName("title"):setText(self.configSelection.title)
    local price = self.configSelection.prices[self.currentConfigSet]
    listElement:getDescendantByName("price"):setText("+" .. g_i18n:formatMoney(price))
end
function ConstructionScreen:updateConfigOptionElement(_, option, storeItem)
    local hasIcons = option.icons ~= nil
    local hasText = not hasIcons
    local isYesNoOption = false
    if #option.options > 1 then
        if option.options[1].isYesNoOption then
            hasIcons = false
            hasText = false
        end
    end
    local listElement = nil
    if hasIcons then
        listElement = self:getOrCreateLargeConfigItem("option")
    elseif hasText then
        listElement = self:getOrCreateConfigItem("option")
    elseif isYesNoOption then
        listElement = self:getOrCreateConfigItem("yesNoOption")
    end
    local configName = isYesNoOption and "yesNoOption" or "option"
    local optionElement = listElement:getDescendantByName(configName)
    optionElement:setVisible(true)
    local configIndex = true
    if #option.options > 1 then
        configIndex = option.isDisabled
    end
    optionElement:setDisabled(configIndex)
    if hasIcons then
        optionElement:setIcons(option.icons)
    elseif hasText then
        optionElement:setTexts(option.texts)
    elseif isYesNoOption then
        optionElement:setTexts(option.texts)
    end
    local priceElement = listElement:getDescendantByName("price")
    local configName = option.name
    local configIndex = 0
    for i, item in pairs(option.options) do
        if item.index == self.configurations[configName] then
            configIndex = i
            break
        end
    end
    if configIndex == 0 or option.options[configIndex] == nil then
        configIndex = option.defaultIndex
    end
    if isYesNoOption then
        optionElement:setIsChecked(configIndex ~= 1, true)
    else
        optionElement:setState(configIndex)
    end
    function optionElement.onClickCallback(_, optionIndex)
        -- upvalues: (copy) self, (copy) option, (copy) configName, (copy) priceElement, (copy) storeItem
        if self.brush.placeable ~= nil then
            local selectedConfigIndex = option.options[optionIndex].index
            self:setConfigPrice(configName, selectedConfigIndex, priceElement)
            self.configurations[configName] = selectedConfigIndex
            self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
            self:loadCurrentConfiguration(storeItem)
        end
    end
    self.configurations[configName] = option.options[configIndex].index
    listElement:getDescendantByName("title"):setText(option.title)
    self:setConfigPrice(configName, option.options[configIndex].index, priceElement)
end
function ConstructionScreen:getOrCreateConfigItem(type)
    local option
    if #self.configItemCache == 0 then
        option = self.configurationItemTemplate:clone(self.configurationLayout)
    else
        self.configItemCache[#self.configItemCache] = nil
        self.configurationLayout:addElement(self.configItemCache[#self.configItemCache])
    end
    option.isLargeConfigItem = false
    option:setVisible(true)
    option.focusId = nil
    local option = false
    local color = false
    local yesNoOption = false
    local focusableElement = nil
    if type == "option" then
        focusableElement = (true):getDescendantByName("option")
    elseif type == "color" then
        color = true
        focusableElement = option:getDescendantByName("color")
    elseif type == "yesNoOption" then
        yesNoOption = true
        focusableElement = option:getDescendantByName("yesNoOption")
    end
    option:getDescendantByName("option"):setVisible(option)
    option:getDescendantByName("color"):setVisible(color)
    option:getDescendantByName("yesNoOption"):setVisible(yesNoOption)
    option:getDescendantByName("price"):setVisible(true)
    if focusableElement ~= nil then
        focusableElement.forceFocusScrollToTop = self.focusableElementForScroll ~= nil
        self.focusableElementForScroll = focusableElement
        option:getDescendantByName("title").getIsSelected = function()
            -- upvalues: (ref) focusableElement
            return focusableElement:getIsFocused()
        end
    end
    return option
end
function ConstructionScreen:getOrCreateLargeConfigItem(_)
    local focusableElement
    if #self.configItemCacheLarge == 0 then
        focusableElement = self.configurationItemTemplateLarge:clone(self.configurationLayout)
    else
        self.configItemCacheLarge[#self.configItemCacheLarge] = nil
        self.configurationLayout:addElement(self.configItemCacheLarge[#self.configItemCacheLarge])
    end
    focusableElement.isLargeConfigItem = true
    focusableElement:setVisible(true)
    focusableElement.focusId = nil
    local focusableElement = focusableElement:getDescendantByName("option")
    focusableElement.forceFocusScrollToTop = self.focusableElementForScroll ~= nil
    self.focusableElementForScroll = focusableElement
    focusableElement:getDescendantByName("title").getIsSelected = function()
        -- upvalues: (copy) focusableElement
        return focusableElement:getIsFocused()
    end
    return focusableElement
end
function ConstructionScreen:setConfigPrice(configName, configIndex, priceTextElement)
    priceTextElement:setText("+" .. g_i18n:formatMoney(self.brush.placeable ~= nil and ConfigurationUtil.hasBoughtConfiguration(self.brush.placeable, configName, configIndex) and 0 or self.brush.storeItem.configurations[configName][configIndex].price) .. "")
    priceTextElement:setVisible(true)
end
function ConstructionScreen:onPickColor(colorIndex, args, customColor, noUpdate)
    if customColor ~= nil then
        local isValid = true
        for index, configItem in pairs(self.brush.storeItem.configurations[args.configName]) do
            if configItem.isCustomColor then
                isValid = true
                colorIndex = index
                break
            end
        end
        if isValid then
            if self.configurationData[configName] == nil then
                self.configurationData[configName] = {}
            end
            self.configurationData[configName][colorIndex] = {}
            self.configurationData[configName][colorIndex].color = { customColor.customColor[1], customColor.customColor[2], customColor.customColor[3] }
            self.configurationData[configName][colorIndex].materialTemplateName = customColor.templateName
        end
    end
    if colorIndex ~= nil then
        local configItems = self.colorElements[args.colorOptionIndex]
        self.configurations[configName] = colorIndex
        local config = self.brush.storeItem.configurations[configName][colorIndex]
        local color = config.color
        local materialTemplateName = config.materialTemplateName
        if self.configurationData[configName] ~= nil then
            local index = self.configurationData[configName][colorIndex]
            if index ~= nil then
            end
        end
        local index = config.isMetallic
        local configItem = config.isMat
        configItems:getDescendantByName("colorImageGlossy"):setVisible(not (index or configItem))
        configItems:getDescendantByName("colorImageMetallic"):setVisible(index)
        configItems:getDescendantByName("colorImageMatte"):setVisible(configItem)
        if MathUtil.getBrightnessFromColor(unpack(color)) >= ColorPickButtonElement.BRIGHTNESS_THRESHOLD then
            configItems:getDescendantByName("colorImageGlossy"):setImageColor(nil, 0, 0, 0)
            configItems:getDescendantByName("colorImageMetallic"):setImageColor(nil, 0, 0, 0)
            configItems:getDescendantByName("colorImageMatte"):setImageColor(nil, 0, 0, 0)
        else
            configItems:getDescendantByName("colorImageGlossy"):setImageColor(nil, 1, 1, 1)
            configItems:getDescendantByName("colorImageMetallic"):setImageColor(nil, 1, 1, 1)
            configItems:getDescendantByName("colorImageMatte"):setImageColor(nil, 1, 1, 1)
        end
        local r, g, b = unpack(color)
        configItems:getDescendantByName("colorImage"):setImageColor(nil, math.clamp(r, 0, 1), math.clamp(g, 0, 1), (math.clamp(b, 0, 1)))
        self:setConfigPrice(configName, colorIndex, configItems.parent:getDescendantByName("price"), self.vehicle)
        if not noUpdate then
            self:loadCurrentConfiguration(self.brush.storeItem)
            self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_SPRAY)
        end
    end
end
function ConstructionScreen:selectFirstConfig()
    local firstElement = self.configurationLayout.elements[1]
    if firstElement == nil then
        FocusManager:unsetFocus(FocusManager:getFocusedElement())
        FocusManager.currentFocusData.focusElement = nil
    else
        local focusElement = firstElement:getDescendantByName("option")
        if not focusElement:getIsVisible() then
            focusElement = firstElement:getDescendantByName("color")
        end
        if not focusElement:getIsVisible() then
            focusElement = firstElement:getDescendantByName("yesNoOption")
        end
        FocusManager:unsetFocus(focusElement)
        FocusManager:setFocus(focusElement)
    end
end
function ConstructionScreen:loadCurrentConfiguration(storeItem)
    local data = PlaceableLoadingData.new()
    data:setConfigurations(self.configurations)
    data:setConfigurationData(self.configurationData)
    data:setPosition(self.brush.placeable:getPosition())
    self.brush:unloadPlaceable(true)
    self.brush:setStoreItem(storeItem, self.configurations, self.configurationData)
    self.brush:loadPlaceable(data)
end
function ConstructionScreen:rebuildData()
    self.categories = g_storeManager:getConstructionCategories()
    self.items = {}
    local numItems = 0
    local maxTabs = 0
    for c, category in ipairs(self.categories) do
        self.items[c] = {}
        local t = 1
        for t = t, #category.tabs do
            self.items[c][t] = {}
        end
        local t = #category.tabs
        maxTabs = math.max(maxTabs, t)
    end
    for c, category in ipairs(g_storeManager:getItems()) do
        if category.brush ~= nil then
            local brushClass = g_constructionBrushTypeManager:getClassObjectByTypeName(category.brush.type)
            local parameters = category.brush.parameters
            local parameters = (parameters == nil or #parameters == 0) and { category.xmlFilename } or parameters
            if brushClass ~= nil then
                local t = g_brandManager:getBrandByIndex(category.brandIndex)
                local brandImage = nil
                if t ~= nil and t.name ~= "NONE" then
                    brandImage = t.image
                end
                local modDlc = ""
                if category.isMod and category.dlcTitle == nil then
                    modDlc = "Mod"
                elseif category.isMod and category.dlcTitle ~= nil then
                    modDlc = category.dlcTitle .. " (Mod)"
                elseif category.dlcTitle ~= nil then
                    modDlc = category.dlcTitle
                end
                table.insert(self.items[category.brush.category.index][category.brush.tab.index], {
                    ["name"] = category.name,
                    ["brushClass"] = brushClass,
                    ["brushParameters"] = parameters,
                    ["price"] = category.price,
                    ["imageFilename"] = category.imageFilename,
                    ["brandFilename"] = brandImage,
                    ["modDlc"] = modDlc,
                    ["storeItem"] = category,
                    ["displayItem"] = g_shopController:makeDisplayItem(category),
                    ["uniqueIndex"] = numItems + 1
                })
                numItems = numItems + 1
            end
        end
    end
    self:buildTerrainSculptBrushes((self:buildTerrainPaintBrushes(numItems)))
    self.categorySelector:reloadData()
end
function ConstructionScreen:buildTerrainPaintBrushes(numItems)
    local landscapingIndex = g_storeManager:getConstructionCategoryByName("landscaping").index
    local paintingIndex = g_storeManager:getConstructionTabByName("painting", "landscaping").index
    local groundTypes = {}
    for typeName, layerName in pairs(g_groundTypeManager.groundTypeMappings) do
        table.insert(groundTypes, typeName)
    end
    table.sort(groundTypes)
    for layerName, typeName in ipairs(groundTypes) do
        local layer = g_groundTypeManager:getTerrainLayerByType(typeName)
        local title = g_groundTypeManager:getTerrainTitleByType(typeName)
        if not ({})[layer] then
            table.insert(self.items[landscapingIndex][paintingIndex], {
                ["name"] = g_i18n:convertText(title),
                ["brushClass"] = ConstructionBrushPaint,
                ["brushParameters"] = { typeName },
                ["price"] = 2,
                ["imageFilename"] = nil,
                ["brandFilename"] = nil,
                ["modDlc"] = "",
                ["terrainOverlayLayer"] = layer,
                ["uniqueIndex"] = numItems + 1
            })
            numItems = numItems + 1
            knownLayers[layer] = true
        end
    end
    return numItems
end
function ConstructionScreen:buildTerrainSculptBrushes(numItems)
    local landscapingIndex = g_storeManager:getConstructionCategoryByName("landscaping").index
    local sculptingIndex = g_storeManager:getConstructionTabByName("sculpting", "landscaping").index
    local sculptTab = self.items[landscapingIndex][sculptingIndex]
    table.insert(sculptTab, {
        ["name"] = g_i18n:getText("construction_item_shift"),
        ["brushClass"] = ConstructionBrushSculpt,
        ["brushParameters"] = { ConstructionBrushSculpt.MODE.SHIFT },
        ["price"] = 10,
        ["imageFilename"] = "dataS/menu/construction/icon_shift.png",
        ["uniqueIndex"] = numItems + 1
    })
    table.insert(sculptTab, {
        ["name"] = g_i18n:getText("construction_item_level"),
        ["brushClass"] = ConstructionBrushSculpt,
        ["brushParameters"] = { ConstructionBrushSculpt.MODE.LEVEL },
        ["price"] = 10,
        ["imageFilename"] = "dataS/menu/construction/icon_level.png",
        ["uniqueIndex"] = numItems + 2
    })
    table.insert(sculptTab, {
        ["name"] = g_i18n:getText("construction_item_soften"),
        ["brushClass"] = ConstructionBrushSculpt,
        ["brushParameters"] = { ConstructionBrushSculpt.MODE.SOFTEN },
        ["price"] = 10,
        ["imageFilename"] = "dataS/menu/construction/icon_soften.png",
        ["uniqueIndex"] = numItems + 3
    })
    table.insert(sculptTab, {
        ["name"] = g_i18n:getText("construction_item_slope"),
        ["brushClass"] = ConstructionBrushSculpt,
        ["brushParameters"] = { ConstructionBrushSculpt.MODE.SLOPE },
        ["price"] = 10,
        ["imageFilename"] = "dataS/menu/construction/icon_slope.png",
        ["uniqueIndex"] = numItems + 4
    })
    return numItems + 4
end
function ConstructionScreen:setCurrentCategory(index, tabIndex)
    if self.currentCategory ~= index then
        self.categorySelector:setSelectedIndex(index)
        self.currentCategory = index
        self.subCategorySelector:setState(tabIndex or 1, true)
        for i, dot in pairs(self.subCategoryDotBox.elements) do
            dot:delete()
            self.subCategoryDotBox.elements[i] = nil
        end
        local subCategoryTexts = {}
        for dot, subCategory in pairs(self.categories[index].tabs) do
            local dot
            self.subCategoryDotTemplate:clone(self.subCategoryDotBox).getIsSelected = function()
                -- upvalues: (copy) self, (copy) dot
                return self.currentTab == dot
            end
            table.insert(subCategoryTexts, subCategory.title)
        end
        self.subCategorySelector:setTexts(subCategoryTexts)
        self.subCategoryDotBox:invalidateLayout()
        self:setBrush(self.selectorBrush, true)
        self:updateMenuState()
    end
end
function ConstructionScreen:setCurrentTab(index)
    self.currentTab = index == nil and 1 or index
    if #self.items[self.currentCategory][self.currentTab] == 0 then
        self:assignItemAttributeData(nil)
    else
        self.itemList:setSelectedIndex(1)
    end
    self:setBrush(self.selectorBrush, true)
    self:updateMenuState()
end
function ConstructionScreen:updateMenuState(_)
    self.itemList:reloadData()
    self:updateMenuActionTexts()
end
function ConstructionScreen:buildCellDatabase()
    self.detailsTemplates = {}
    local i = #self.attributesLayout.elements
    for i = i, 1, -1 do
        local element = self.attributesLayout.elements[i]
        local name = element.name
        self.detailsTemplates[name] = element:clone()
        self.detailsCache[name] = {}
    end
end
function ConstructionScreen:dequeueDetailsCell(name)
    if self.detailsTemplates[name] == nil then
        return nil
    end
    local cache = self.detailsCache[name]
    local cell
    if #cache > 0 then
        cell = cache[#cache]
        cache[#cache] = nil
    else
        cell = self.detailsTemplates[name]:clone(self)
    end
    self.attributesLayout:addElement(cell)
    return cell
end
function ConstructionScreen:queueDetailsCell(cell)
    local cache = self.detailsCache[cell.name]
    cache[#cache + 1] = cell
    self.attributesLayout:removeElement(cell)
    cell:unlinkElement()
end
function ConstructionScreen.consoleCommandToggleUI()
    ConstructionScreen.uiHidden = not ConstructionScreen.uiHidden
end