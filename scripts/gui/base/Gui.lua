Gui = {}
local Gui_mt = Class(Gui)
Gui.CONFIGURATION_CLASS_MAPPING = {}
Gui.ELEMENT_PROCESSING_FUNCTIONS = {}
Gui.NAV_AXES = {
    InputAction.MENU_AXIS_LEFT_RIGHT,
    InputAction.MENU_AXIS_UP_DOWN,
    InputAction.MENU_LIST_PAGE_START_GAMEPAD,
    InputAction.MENU_LIST_PAGE_END_GAMEPAD
}
Gui.NAV_ACTIONS = {
    InputAction.MENU_ACCEPT,
    InputAction.MENU_ACTIVATE,
    InputAction.MENU_CANCEL,
    InputAction.MENU_BACK,
    InputAction.MENU,
    InputAction.TOGGLE_STORE,
    InputAction.TOGGLE_MAP,
    InputAction.MENU_PAGE_PREV,
    InputAction.MENU_PAGE_NEXT,
    InputAction.MENU_EXTRA_1,
    InputAction.MENU_EXTRA_2,
    InputAction.MENU_LIST_PAGE_START,
    InputAction.MENU_LIST_PAGE_END,
    InputAction.MENU_LIST_PAGE_PREV,
    InputAction.MENU_LIST_PAGE_NEXT
}
Gui.GUI_PROFILE_BASE = "baseReference"
Gui.GUI_PROFILE_TYPE_NAME = string.upper("GUIProfiles")
Gui.INPUT_CONTEXT_MENU = "MENU"
Gui.INPUT_CONTEXT_DIALOG = "DIALOG"
function Gui.new()
    -- upvalues: (copy) Gui_mt
    local self = setmetatable({}, Gui_mt)
    self.guiSoundPlayer = GuiSoundPlayer.new(g_soundManager)
    FocusManager:setSoundPlayer(self.guiSoundPlayer)
    self.screens = {}
    self.screenControllers = {}
    self.dialogs = {}
    self.profiles = {}
    self.traits = {}
    self.presets = {}
    self.focusElements = {}
    self.guis = {}
    self.nameScreenTypes = {}
    self.currentGuiName = ""
    self.currentlyReloading = false
    self.frames = {}
    self.isInputListening = false
    self.actionEventIds = {}
    self.frameInputTarget = nil
    self.frameInputHandled = false
    self.changeScreenClosure = self:makeChangeScreenClosure()
    self.toggleCustomInputContextClosure = self:makeToggleCustomInputContextClosure()
    self.playSampleClosure = self:makePlaySampleClosure()
    g_adsSystem:clearGroupRegion(AdsSystem.OCCLUSION_GROUP.UI)
    g_adsSystem:addGroupRegion(AdsSystem.OCCLUSION_GROUP.UI, 0, 0, 1, 1)
    g_adsSystem:setGroupActive(AdsSystem.OCCLUSION_GROUP.UI, false)
    return self
end
function Gui:delete()
    self.guiSoundPlayer:delete()
    for name, gui in pairs(self.guis) do
        gui:delete()
        gui.target:delete()
    end
    for name, gui in pairs(self.frames) do
        gui.target:delete()
        gui:delete()
    end
    self.currentGui = nil
end
function Gui:loadPresets(xmlFile, rootKey)
    local presets = {}
    local i = 0
    while true do
        local key = string.format("%s.Preset(%d)", rootKey, i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local name = getXMLString(xmlFile, key .. "#name")
        local value = getXMLString(xmlFile, key .. "#value")
        if name ~= nil and value ~= nil then
            if value:startsWith("$preset_") then
                local preset = string.gsub(value, "$preset_", "")
                if presets[preset] == nil then
                    Logging.devWarning("Preset \'%s\' is not defined in Preset!", preset)
                else
                    value = presets[preset]
                end
            end
            if self.presets[name] == nil or self.currentlyReloading then
                presets[name] = value
                self.presets[name] = value
            else
                Logging.xmlDevError(xmlFile, "GUI-Preset name \'%s\' already defined!", name)
            end
        end
        i = i + 1
    end
    return presets
end
function Gui:loadTraits(xmlFile, rootKey, presets)
    local i = 0
    while true do
        local trait = GuiProfile.new(self.profiles, self.traits)
        local key = rootKey .. ".Trait(" .. i .. ")"
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        trait:loadFromXML(xmlFile, key, presets, true)
        if self.traits[trait.name] == nil or self.currentlyReloading then
            self.traits[trait.name] = trait
        else
            Logging.xmlDevError(xmlFile, "GUI-Trait name \'%s\' already defined!", trait.name)
        end
        i = i + 1
    end
end
function Gui:loadProfileSet(xmlFile, rootKey, presets, categoryName)
    local i = 0
    while true do
        local profile = GuiProfile.new(self.profiles, self.traits)
        local key = rootKey .. ".Profile(" .. i .. ")"
        if not hasXMLProperty(xmlFile, key) then
            return
        end
        profile:loadFromXML(xmlFile, key, presets, false)
        if self.profiles[profile.name] == nil or self.currentlyReloading then
            profile.category = categoryName
            self.profiles[profile.name] = profile
            local j = 0
            while true do
                local k = rootKey .. ".Profile(" .. i .. ").Variant(" .. j .. ")"
                if not hasXMLProperty(xmlFile, k) then
                    break
                end
                local variantName = getXMLString(xmlFile, k .. "#name")
                if variantName ~= nil then
                    local variantProfile = GuiProfile.new(self.profiles, self.traits)
                    if not hasXMLProperty(xmlFile, k) then
                        break
                    end
                    variantProfile:loadFromXML(xmlFile, k, presets, false, true)
                    if variantProfile.parent == nil then
                        variantProfile.parent = profile.name
                    end
                    variantProfile.category = categoryName
                    variantProfile.name = variantName .. "_" .. profile.name
                    if self.profiles[variantProfile.name] == nil or self.currentlyReloading then
                        self.profiles[variantProfile.name] = variantProfile
                    else
                        Logging.xmlDevError(xmlFile, "GUI-Profile name \'%s\' already defined!", variantProfile.name)
                    end
                end
                j = j + 1
            end
        else
            Logging.xmlDevError(xmlFile, "GUI-Profile name \'%s\' already defined!", profile.name)
        end
        i = i + 1
    end
end
function Gui:loadProfiles(xmlFilename)
    local xmlFile = loadXMLFile("Temp", xmlFilename)
    if xmlFile == nil or xmlFile == 0 then
        Logging.error("Could not open guiProfile-config \'%s\'!", xmlFilename)
        return false
    end
    self:loadPresets(xmlFile, "GuiProfiles.Presets")
    self:loadTraits(xmlFile, "GuiProfiles.Traits", self.presets)
    self:loadProfileSet(xmlFile, "GuiProfiles", self.presets)
    local i = 0
    while true do
        local key = string.format("GuiProfiles.Category(%d)", i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local categoryName = getXMLString(xmlFile, key .. "#name")
        self:loadProfileSet(xmlFile, key, self.presets, categoryName)
        i = i + 1
    end
    delete(xmlFile)
    return true
end
function Gui:loadGui(xmlFilename, name, controller, isFrame)
    local xmlFile = loadXMLFile("Temp", xmlFilename)
    local gui = nil
    if (xmlFile == nil or xmlFile == 0) and not self.currentlyReloading then
        Logging.error("Could not open gui-config \'%s\'!", xmlFilename)
        controller:delete()
        return gui
    end
    self:loadProfileSet(xmlFile, "GUI.GuiProfiles", self.presets)
    FocusManager:setGui(name)
    local gui = GuiElement.new(controller)
    gui.name = name
    gui.xmlFilename = xmlFilename
    controller.name = name
    controller.xmlFilename = xmlFilename
    gui:loadFromXML(xmlFile, "GUI")
    if g_screenWidth ~= g_unsafeScreenWidth or g_screenHeight ~= g_unsafeScreenHeight then
        gui:setPosition(g_safeFrameScreenOffsetX * g_pixelSizeX, g_safeFrameScreenOffsetY * g_pixelSizeY)
        gui:setSize(g_screenWidth / g_unsafeScreenWidth, g_screenHeight / g_unsafeScreenHeight, true)
    end
    if isFrame then
        controller.name = gui.name
        gui.isFrame = true
    end
    self:loadGuiRec(xmlFile, "GUI", gui, controller)
    controller:addElement(gui)
    if not isFrame then
        controller:updateAbsolutePosition()
    end
    controller:exposeControlsAsFields(name)
    controller:onGuiSetupFinished()
    gui:raiseCallback("onCreateCallback", gui, gui.onCreateArgs)
    if isFrame then
        self:addFrame(controller, gui)
    else
        self.guis[name] = gui
        self.nameScreenTypes[name] = controller:class()
        self:addScreen(controller:class(), controller, gui)
    end
    delete(xmlFile)
    return gui
end
function Gui:loadGuiRec(xmlFile, xmlNodePath, parentGuiElement, target)
    local index = 0
    for index = index, getXMLNumOfChildren(xmlFile, xmlNodePath) - 1 do
        local typeName = getXMLElementName(xmlFile, string.format("%s.*(%i)", xmlNodePath, index))
        local currentXmlPath = string.format("%s.*(%i)", xmlNodePath, index)
        local upperCaseTypeName = string.upper(typeName)
        if upperCaseTypeName ~= Gui.GUI_PROFILE_TYPE_NAME then
            local elementClass = Gui.CONFIGURATION_CLASS_MAPPING[upperCaseTypeName]
            if elementClass then
                local processingFunction = elementClass.new(target)
                processingFunction.typeName = typeName
                parentGuiElement:addElement(processingFunction)
                processingFunction:loadFromXML(xmlFile, currentXmlPath)
                local processingFunction = Gui.ELEMENT_PROCESSING_FUNCTIONS[upperCaseTypeName]
                if processingFunction then
                    processingFunction = processingFunction(self, processingFunction)
                end
                self:loadGuiRec(xmlFile, currentXmlPath, processingFunction, target)
                processingFunction:raiseCallback("onCreateCallback", processingFunction, processingFunction.onCreateArgs)
            else
                Logging.xmlWarning(xmlFile, string.format("Could not find type name %s in registered GUI element classes", typeName))
            end
        end
    end
end
function Gui:resolveFrameReference(frameRefElement)
    local refName = frameRefElement.referencedFrameName or ""
    local frame = self.frames[refName]
    if frame == nil then
        return frameRefElement
    end
    local frameName = frameRefElement.name or refName
    local frameController = frame.parent
    local frameParent = frameRefElement.parent
    local controllerClone = frameController:clone(frameParent, true, true, true)
    controllerClone.name = frameName
    FocusManager:setGui(frameName)
    controllerClone.positionOrigin = frameParent.positionOrigin
    controllerClone.screenAlign = frameParent.screenAlign
    controllerClone:setSize(unpack(frameParent.size))
    local cloneRoot = controllerClone:getRootElement()
    cloneRoot.positionOrigin = frameParent.positionOrigin
    cloneRoot.screenAlign = frameParent.screenAlign
    cloneRoot:setSize(unpack(frameParent.size))
    controllerClone:setTarget(controllerClone, frameController, true)
    local frameId = frameRefElement.id
    controllerClone.id = frameId
    if frameRefElement.target then
        frameRefElement.target[frameId] = controllerClone
    end
    FocusManager:loadElementFromCustomValues(controllerClone, nil, nil, false, false)
    frameRefElement:unlinkElement()
    frameRefElement:delete()
    return controllerClone
end
function Gui:getProfile(profileName)
    if profileName ~= nil then
        local specialized = false
        for _, prefix in ipairs(Platform.guiPrefixes) do
            local customProfileName = prefix .. profileName
            if self.profiles[customProfileName] ~= nil then
                specialized = true
                profileName = customProfileName
            end
        end
        local consoleProfileName
        if specialized or not Platform.isConsole then
            consoleProfileName = profileName
        else
            consoleProfileName = "console_" .. profileName
            if self.profiles[consoleProfileName] == nil then
                consoleProfileName = profileName
            else
                specialized = true
            end
        end
        if specialized or not Platform.isMobile then
            profileName = consoleProfileName
        else
            profileName = "mobile_" .. consoleProfileName
            if self.profiles[profileName] == nil then
                profileName = consoleProfileName
            end
        end
    end
    if not (profileName and self.profiles[profileName]) then
        if profileName and profileName ~= "" then
            Logging.warning("Could not retrieve GUI profile \'%s\'. Using base reference profile instead.", (tostring(profileName)))
        end
        profileName = Gui.GUI_PROFILE_BASE
    end
    return self.profiles[profileName]
end
function Gui:getIsGuiVisible()
    return self.currentGui ~= nil or self:getIsDialogVisible()
end
function Gui:getIsMenuVisible()
    return self.currentGui ~= nil
end
function Gui:getIsDialogVisible()
    return #self.dialogs > 0
end
function Gui:getIsOverlayGuiVisible()
    return false
end
function Gui:showGui(guiName)
    return self:changeScreen(self.guis[self.currentGui], self.nameScreenTypes[guiName == nil and "" or guiName])
end
function Gui:showDialog(guiName, closeAllOthers)
    local gui = self.guis[guiName]
    self.currentDialogName = guiName
    self.currentDialog = guiName
    if gui ~= nil then
        if closeAllOthers then
            for _, v in ipairs(self.dialogs) do
                if v ~= gui then
                    self:closeDialog(v)
                end
            end
        end
        local list = self.currentListener
        if self.currentListener == gui then
            return gui
        end
        if self.currentListener ~= nil then
            self.focusElements[self.currentListener] = FocusManager:getFocusedElement()
        end
        if gui.target.needInput == nil or gui.target.needInput == true then
            if not self:getIsGuiVisible() then
                self:enterMenuContext()
            end
            self:enterMenuContext(Gui.INPUT_CONTEXT_DIALOG .. "_" .. tostring(guiName))
        end
        FocusManager:setGui(guiName)
        local y = self.dialogs
        table.insert(y, gui)
        gui:onOpen()
        self.currentListener = gui
        local x = g_messageCenter
        local width = MessageType.GUI_DIALOG_OPENED
        local v = false
        if list ~= nil then
            v = list ~= gui
        end
        x:publish(width, guiName, v)
        gui.blurAreaActive = false
        if gui.target.getBlurArea ~= nil then
            local x, y, width, _ = gui.target:getBlurArea()
            if x ~= nil then
                gui.blurAreaActive = true
                g_depthOfFieldManager:pushArea(x, y, width, _)
            end
        end
    end
    return gui
end
function Gui:closeDialogByName(guiName)
    local gui = self.guis[guiName]
    if gui ~= nil then
        self:closeDialog(gui)
    end
end
function Gui:closeDialog(gui)
    for k, v in ipairs(self.dialogs) do
        if v == gui then
            v:onClose()
            table.remove(self.dialogs, k)
            if gui.blurAreaActive then
                g_depthOfFieldManager:popArea()
                gui.blurAreaActive = false
            end
            if self.currentListener == gui then
                if #self.dialogs > 0 then
                    self.currentListener = self.dialogs[#self.dialogs]
                elseif self.currentGui == gui then
                    self.currentListener = nil
                    self.currentGui = nil
                else
                    self.currentListener = self.currentGui
                end
                if self.currentListener ~= nil then
                    FocusManager:setGui(self.currentListener.name)
                    if self.focusElements[self.currentListener] ~= nil then
                        FocusManager:setFocus(self.focusElements[self.currentListener])
                        self.focusElements[self.currentListener] = nil
                    end
                end
            end
            if gui.target.needInput == nil or gui.target.needInput == true then
                g_inputBinding:revertContext(false)
            end
            break
        end
    end
    if not self:getIsGuiVisible() then
        self:changeScreen(nil)
    end
end
function Gui:closeAllDialogs()
    for _, v in ipairs(self.dialogs) do
        self:closeDialog(v)
    end
end
function Gui:registerMenuInput()
    self.actionEventIds = {}
    for _, actionName in ipairs(Gui.NAV_ACTIONS) do
        local _, eventId = g_inputBinding:registerActionEvent(actionName, self, self.onMenuInput, false, true, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        if self.actionEventIds[actionName] == nil then
            self.actionEventIds[actionName] = {}
        end
        table.addElement(self.actionEventIds[actionName], eventId)
        if actionName == InputAction.MENU_PAGE_PREV or actionName == InputAction.MENU_PAGE_NEXT then
            local _, eventId = g_inputBinding:registerActionEvent(actionName, self, self.onReleaseInput, true, false, false, true)
            g_inputBinding:setActionEventTextVisibility(eventId, false)
            table.addElement(self.actionEventIds[actionName], eventId)
        end
    end
    for _, actionName in pairs(Gui.NAV_AXES) do
        local _, eventId = g_inputBinding:registerActionEvent(actionName, self, self.onMenuInput, false, true, true, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        if self.actionEventIds[actionName] == nil then
            self.actionEventIds[actionName] = {}
        end
        table.addElement(self.actionEventIds[actionName], eventId)
        local _, eventId = g_inputBinding:registerActionEvent(actionName, self, self.onReleaseMovement, true, false, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        table.addElement(self.actionEventIds[actionName], eventId)
    end
    self.isInputListening = true
end
function Gui:mouseEvent(posX, posY, isDown, isUp, button)
    local eventUsed = false
    if self.currentListener ~= nil then
        eventUsed = self.currentListener:mouseEvent(posX, posY, isDown, isUp, button)
    end
    if not eventUsed and (self.currentListener ~= nil and (self.currentListener.target ~= nil and self.currentListener.target.mouseEvent ~= nil)) then
        self.currentListener.target:mouseEvent(posX, posY, isDown, isUp, button)
    end
end
function Gui:touchEvent(posX, posY, isDown, isUp, touchId)
    local eventUsed = false
    if self.currentListener ~= nil and self.currentListener.touchEvent ~= nil then
        eventUsed = self.currentListener:touchEvent(posX, posY, isDown, isUp, touchId)
    end
    if not eventUsed and (self.currentListener ~= nil and (self.currentListener.target ~= nil and self.currentListener.target.touchEvent ~= nil)) then
        self.currentListener.target:touchEvent(posX, posY, isDown, isUp, touchId)
    end
end
function Gui:keyEvent(unicode, sym, modifier, isDown)
    local eventUsed = false
    if self.currentListener ~= nil then
        eventUsed = self.currentListener:keyEvent(unicode, sym, modifier, isDown)
    end
    if self.currentListener ~= nil and (self.currentListener.target ~= nil and (not eventUsed and self.currentListener.target.keyEvent ~= nil)) then
        self.currentListener.target:keyEvent(unicode, sym, modifier, isDown, eventUsed)
    end
end
function Gui:update(dt)
    for _, v in pairs(self.dialogs) do
        if v.target ~= nil then
            v.target:update(dt)
        end
    end
    local currentGui = self.currentGui
    if currentGui ~= nil then
        if currentGui.target ~= nil and currentGui.target.preUpdate ~= nil then
            currentGui.target:preUpdate(dt)
        end
        if currentGui == self.currentGui and (currentGui == self.currentGui and (currentGui.target ~= nil and currentGui.target.update ~= nil)) then
            currentGui.target:update(dt)
        end
    end
    self.frameInputTarget = nil
    self.frameInputHandled = false
end
function Gui:draw()
    if self.currentGui ~= nil and (self.currentGui.target ~= nil and self.currentGui.target.draw ~= nil) then
        self.currentGui.target:draw()
    end
    for _, v in pairs(self.dialogs) do
        if v.target ~= nil then
            v.target:draw()
        end
    end
    if g_uiDebugEnabled then
        local e = FocusManager.currentFocusData.focusElement
        setTextAlignment(RenderText.ALIGN_CENTER)
        local xPixel = renderText
        local _ = 0.5
        local v = 0.94
        xPixel(_, v, 0.02, "Focused element: " .. (e == nil and "none" or (e.id or (e.profile or e.name))))
        if e ~= nil then
            local e, _ = FocusManager:getNextFocusElement(e, FocusManager.TOP)
            renderText(0.5, 0.92, 0.02, "Top element: " .. (e == nil and "none" or (e.id or (e.profile or e.name))))
            local e, _ = FocusManager:getNextFocusElement(e, FocusManager.BOTTOM)
            renderText(0.5, 0.9, 0.02, "Bottom element: " .. (e == nil and "none" or (e.id or (e.profile or e.name))))
            local e, _ = FocusManager:getNextFocusElement(e, FocusManager.LEFT)
            renderText(0.5, 0.88, 0.02, "Left element: " .. (e == nil and "none" or (e.id or (e.profile or e.name))))
            local e, _ = FocusManager:getNextFocusElement(e, FocusManager.RIGHT)
            renderText(0.5, 0.86, 0.02, "Right element: " .. (e == nil and "none" or (e.id or (e.profile or e.name))))
            drawFilledRect(e.absPosition[1] - 3 * g_pixelSizeX, e.absPosition[2] - 3 * g_pixelSizeY, e.absSize[1] + 2 * (3 * g_pixelSizeX), 3 * g_pixelSizeY, 1, 0.5, 0, 1)
            drawFilledRect(e.absPosition[1] - xPixel, e.absPosition[2] + e.absSize[2], e.absSize[1] + 2 * xPixel, _, 1, 0.5, 0, 1)
            drawFilledRect(e.absPosition[1] - xPixel, e.absPosition[2], xPixel, e.absSize[2], 1, 0.5, 0, 1)
            drawFilledRect(e.absPosition[1] + e.absSize[1], e.absPosition[2], xPixel, e.absSize[2], 1, 0.5, 0, 1)
        end
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end
function Gui:notifyControls(action, value)
    local eventUsed = false
    if self.frameInputTarget == nil then
        self.frameInputTarget = self.currentListener
    end
    if not FocusManager:isFocusInputLocked(action, value) then
        if not eventUsed and self.frameInputTarget ~= nil then
            eventUsed = self.frameInputTarget:inputEvent(action, value)
        end
        if not eventUsed and (self.frameInputTarget ~= nil and self.frameInputTarget.target ~= nil) then
            eventUsed = self.frameInputTarget.target:inputEvent(action, value)
        end
        local focusedElement = FocusManager:getFocusedElement()
        if not eventUsed and (focusedElement ~= nil and focusedElement:getIsActive()) then
            eventUsed = focusedElement:inputEvent(action, value)
        end
        eventUsed = eventUsed or FocusManager:inputEvent(action, value, eventUsed)
    end
    self.frameInputHandled = eventUsed
end
function Gui:onMenuInput(actionName, inputValue)
    if not self.frameInputHandled and self.isInputListening then
        self:notifyControls(actionName, inputValue)
    end
end
function Gui:onReleaseMovement(action)
    self:onReleaseInput(action)
    FocusManager:releaseMovementFocusInput(action)
end
function Gui:onReleaseInput(action)
    if not self.frameInputHandled and (self.isInputListening and not FocusManager:isFocusInputLocked(action)) then
        if self.frameInputTarget ~= nil then
            self.frameInputTarget:inputReleaseEvent(action)
        end
        if self.frameInputTarget ~= nil and self.frameInputTarget.target ~= nil then
            self.frameInputTarget.target:inputReleaseEvent(action)
        end
        local focusedElement = FocusManager:getFocusedElement()
        if focusedElement ~= nil and focusedElement:getIsActive() then
            focusedElement:inputReleaseEvent(action)
        end
    end
end
function Gui:hasElementInputFocus(element)
    return self.currentListener ~= nil and self.currentListener.target == element
end
function Gui:getScreenInstanceByClass(screenClass)
    return self.screenControllers[screenClass]
end
function Gui:changeScreen(sourceScreen, screenClass, returnScreenClass)
    local screenController = self.screenControllers[screenClass]
    if screenClass ~= nil and screenController == nil then
        Logging.devWarning("UI \'%s\' not found", ClassUtil.getClassName(screenClass))
        return nil
    end
    self:closeAllDialogs()
    local isMenuOpening = not self:getIsGuiVisible()
    local screenElement = self.screens[screenClass]
    if sourceScreen == nil then
        if self.currentGui ~= nil then
            self.currentGui:onClose()
        end
    else
        sourceScreen:onClose()
    end
    local screenName = screenElement and screenElement.name or ""
    self.currentGui = screenElement
    self.currentGuiName = screenName
    self.currentListener = screenElement
    if screenElement ~= nil and isMenuOpening then
        g_messageCenter:publish(MessageType.GUI_BEFORE_OPEN)
        self:enterMenuContext()
    end
    FocusManager:setGui(screenName)
    if screenElement ~= nil and screenController ~= nil then
        screenController:setReturnScreenClass(returnScreenClass or screenController.returnScreenClass)
        screenElement:onOpen()
        if isMenuOpening then
            g_messageCenter:publish(MessageType.GUI_AFTER_OPEN)
        end
    end
    if not self:getIsGuiVisible() then
        g_messageCenter:publish(MessageType.GUI_BEFORE_CLOSE)
        self:leaveMenuContext()
        g_messageCenter:publish(MessageType.GUI_AFTER_CLOSE)
    end
    g_adsSystem:setGroupActive(AdsSystem.OCCLUSION_GROUP.UI, self.currentGui ~= nil)
    return screenElement
end
function Gui:makeChangeScreenClosure()
    return function(source, screenClass, returnScreenClass)
        -- upvalues: (copy) self
        self:changeScreen(source, screenClass, returnScreenClass)
    end
end
function Gui:toggleCustomInputContext(isActive, contextName)
    if isActive then
        self:enterMenuContext(contextName)
    else
        self:leaveMenuContext()
    end
end
function Gui:makeToggleCustomInputContextClosure()
    return function(isActive, contextName)
        -- upvalues: (copy) self
        self:toggleCustomInputContext(isActive, contextName)
    end
end
function Gui:makePlaySampleClosure()
    return function(sampleName)
        -- upvalues: (copy) self
        self.guiSoundPlayer:playSample(sampleName)
    end
end
function Gui:assignPlaySampleCallback(guiElement)
    if guiElement:hasIncluded(PlaySampleMixin) then
        guiElement:setPlaySampleCallback(self.playSampleClosure)
    end
    return guiElement
end
function Gui:enterMenuContext(contextName)
    g_inputBinding:setContext(contextName or Gui.INPUT_CONTEXT_MENU, true, false)
    self:registerMenuInput()
    self.isInputListening = true
end
function Gui:leaveMenuContext()
    if self.isInputListening then
        g_inputBinding:revertContext(false)
        self.isInputListening = self:getIsGuiVisible()
    end
end
function Gui:addFrame(frameController, frameRootElement)
    self.frames[frameController.name] = frameRootElement
    frameController:setChangeScreenCallback(self.changeScreenClosure)
    frameController:setInputContextCallback(self.toggleCustomInputContextClosure)
    frameController:setPlaySampleCallback(self.playSampleClosure)
end
function Gui:addScreen(screenClass, screenInstance, screenRootElement)
    self.screens[screenClass] = screenRootElement
    self.screenControllers[screenClass] = screenInstance
    screenInstance:setChangeScreenCallback(self.changeScreenClosure)
    screenInstance:setInputContextCallback(self.toggleCustomInputContextClosure)
    screenInstance:setPlaySampleCallback(self.playSampleClosure)
end
function Gui:setCurrentMission(currentMission)
    for _, controller in pairs(self.screenControllers) do
        if controller.setCurrentMission ~= nil then
            controller:setCurrentMission(currentMission)
        end
    end
end
function Gui:loadMapData(mapXmlFile, missionInfo, baseDirectory)
    if not Platform.isMobile then
        self.screenControllers[ShopConfigScreen]:loadMapData(mapXmlFile, missionInfo, baseDirectory)
        self.screenControllers[LicensePlateDialog]:loadMapData(mapXmlFile, missionInfo, baseDirectory)
        self.screenControllers[ColorPickerDialog]:loadMapData(mapXmlFile, missionInfo, baseDirectory)
    end
    if Platform.hasWardrobe then
        self.screenControllers[WardrobeScreen]:loadMapData(mapXmlFile, missionInfo, baseDirectory)
    end
end
function Gui:unloadMapData()
    self.screenControllers[InGameMenu]:unloadMapData()
    self.screenControllers[ShopConfigScreen]:unloadMapData()
    self.screenControllers[LicensePlateDialog]:unloadMapData()
    self.screenControllers[ColorPickerDialog]:unloadMapData()
    if Platform.hasWardrobe then
        self.screenControllers[WardrobeScreen]:unloadMapData()
    end
end
function Gui:setClient(client)
    for _, controller in pairs(self.screenControllers) do
        if controller.setClient ~= nil then
            controller:setClient(client)
        end
    end
end
function Gui:setServer(server)
    for _, controller in pairs(self.screenControllers) do
        if controller.setServer ~= nil then
            controller:setServer(server)
        end
    end
end
function Gui:setIsMultiplayer(isMultiplayer)
    for _, class in pairs({ CareerScreen }) do
        local controller = self.screenControllers[class]
        if controller ~= nil then
            controller:setIsMultiplayer(isMultiplayer)
        end
    end
end
function Gui.initGuiLibrary(baseDir)
    source(baseDir .. "/base/GuiProfile.lua")
    source(baseDir .. "/base/GuiUtils.lua")
    source(baseDir .. "/base/GuiOverlay.lua")
    source(baseDir .. "/base/GuiDataSource.lua")
    source(baseDir .. "/base/GuiMixin.lua")
    source(baseDir .. "/base/IndexChangeSubjectMixin.lua")
    source(baseDir .. "/base/PlaySampleMixin.lua")
    source(baseDir .. "/base/Tween.lua")
    source(baseDir .. "/base/MultiValueTween.lua")
    source(baseDir .. "/base/TweenSequence.lua")
    source(baseDir .. "/elements/GuiElement.lua")
    source(baseDir .. "/elements/FrameElement.lua")
    source(baseDir .. "/elements/ScreenElement.lua")
    source(baseDir .. "/elements/DialogElement.lua")
    source(baseDir .. "/elements/BitmapElement.lua")
    source(baseDir .. "/elements/ClearElement.lua")
    source(baseDir .. "/elements/TextElement.lua")
    source(baseDir .. "/elements/ButtonElement.lua")
    source(baseDir .. "/elements/ToggleButtonElement.lua")
    source(baseDir .. "/elements/ColorPickButtonElement.lua")
    source(baseDir .. "/elements/VideoElement.lua")
    source(baseDir .. "/elements/SliderElement.lua")
    source(baseDir .. "/elements/TextInputElement.lua")
    source(baseDir .. "/elements/MultiTextOptionElement.lua")
    source(baseDir .. "/elements/OptionSliderElement.lua")
    source(baseDir .. "/elements/CheckedOptionElement.lua")
    source(baseDir .. "/elements/BinaryOptionElement.lua")
    source(baseDir .. "/elements/ListItemElement.lua")
    source(baseDir .. "/elements/AnimationElement.lua")
    source(baseDir .. "/elements/TimerElement.lua")
    source(baseDir .. "/elements/BoxLayoutElement.lua")
    source(baseDir .. "/elements/PagingElement.lua")
    source(baseDir .. "/elements/TableHeaderElement.lua")
    source(baseDir .. "/elements/IngameMapElement.lua")
    source(baseDir .. "/elements/IngameMapPreviewElement.lua")
    source(baseDir .. "/elements/IndexStateElement.lua")
    source(baseDir .. "/elements/FrameReferenceElement.lua")
    source(baseDir .. "/elements/RenderElement.lua")
    source(baseDir .. "/elements/BreadcrumbsElement.lua")
    source(baseDir .. "/elements/ThreePartBitmapElement.lua")
    source(baseDir .. "/elements/PictureElement.lua")
    source(baseDir .. "/elements/ScrollingLayoutElement.lua")
    source(baseDir .. "/elements/MultiOptionElement.lua")
    source(baseDir .. "/elements/TextBackdropElement.lua")
    source(baseDir .. "/elements/InputGlyphElementUI.lua")
    source(baseDir .. "/elements/TerrainLayerElement.lua")
    source(baseDir .. "/elements/SmoothListElement.lua")
    source(baseDir .. "/elements/DynamicFadedBitmapElement.lua")
    source(baseDir .. "/elements/PlatformIconElement.lua")
    source(baseDir .. "/elements/OptionToggleElement.lua")
    source(baseDir .. "/elements/RoundCornerElement.lua")
    source(baseDir .. "/elements/SafeFrameElement.lua")
end
function Gui.registerGuiElement(name, class)
    name = string.upper(name)
    Gui.CONFIGURATION_CLASS_MAPPING[name] = class
end
function Gui.registerGuiElementProcFunction(name, procFunction)
    name = string.upper(name)
    Gui.ELEMENT_PROCESSING_FUNCTIONS[name] = procFunction
end