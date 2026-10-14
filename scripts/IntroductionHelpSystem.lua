IntroductionHelpSystem = {}
local IntroductionHelpSystem_mt = Class(IntroductionHelpSystem)
IntroductionHelpSystem.FILENAME = "dataS/introductionHints.xml"
function IntroductionHelpSystem.new(custom_mt)
    -- upvalues: (copy) IntroductionHelpSystem_mt
    local self = setmetatable({}, custom_mt or IntroductionHelpSystem_mt)
    self.registeredElements = {}
    self.registeredHints = {}
    self.shownHints = {}
    self.drawHelpQueue = {}
    g_messageCenter:subscribe(MessageType.GUI_BEFORE_OPEN, self.onMenuOpen, self)
    g_messageCenter:subscribe(MessageType.APP_SUSPENDED, self.onAppSuspended, self)
    return self
end
function IntroductionHelpSystem:delete()
    g_messageCenter:unsubscribeAll(self)
end
function IntroductionHelpSystem:registerHelp(name, target, drawFunction, availableFunction, registerCustomInputFunction, unregisterCustomInputFunction)
    if drawFunction == nil then
        Logging.devError("Could not register introduction help. Drawfunction is not defined!")
        printCallstack()
    else
        local helpItem = self.registeredElements[name]
        if helpItem == nil then
            self.registeredElements[name] = {
                ["name"] = name,
                ["alreadyShown"] = false,
                ["waitingForDraw"] = false,
                ["canReset"] = true
            }
        end
        helpItem.drawFunction = drawFunction
        helpItem.availableFunction = availableFunction
        helpItem.registerCustomInputFunction = registerCustomInputFunction
        helpItem.unregisterCustomInputFunction = unregisterCustomInputFunction
        helpItem.target = target
    end
end
function IntroductionHelpSystem:registerHint(name, text, isInitialActive)
    if self.registeredHints[name] == nil then
        local hint = {
            ["name"] = name,
            ["text"] = text,
            ["alreadyShown"] = Utils.getNoNil(isInitialActive, false)
        }
        if isInitialActive then
            table.insert(self.shownHints, text)
        end
        self.registeredHints[name] = hint
    end
end
function IntroductionHelpSystem:loadShownElements()
    local missionInfo = g_currentMission.missionInfo
    local shownElements = ""
    if missionInfo ~= nil then
        shownElements = missionInfo.introductionHelpShownElements
    end
    local shownElementsStr = string.split(shownElements, " ")
    for _, elementName in ipairs(shownElementsStr) do
        if elementName ~= "" then
            if self.registeredElements[elementName] == nil then
                self.registeredElements[elementName] = {}
            end
            self.registeredElements[elementName].alreadyShown = true
            self.registeredElements[elementName].canReset = false
        end
    end
    local shownHints = ""
    if missionInfo ~= nil then
        shownHints = missionInfo.introductionHelpShownHints
    end
    local shownHintsStr = string.split(shownHints, " ")
    for _, hintName in ipairs(shownHintsStr) do
        if hintName ~= "" and self.registeredHints[hintName] == false then
            self.registeredHints[hintName].alreadyShown = true
            table.insert(self.shownHints, self.registeredHints[hintName].text)
        end
    end
end
function IntroductionHelpSystem:loadHelpElementsFromXML()
    local xmlFile = XMLFile.load("introductionHelpElementsXML", IntroductionHelpSystem.FILENAME)
    if xmlFile then
        xmlFile:iterate("hints.hint", function(_, key)
            -- upvalues: (copy) xmlFile, (copy) self
            local id = xmlFile:getString(key .. "#id")
            local text = xmlFile:getString(key .. "#text")
            if id ~= nil and text ~= nil then
                self:registerHint(id, g_i18n:convertText(text), (xmlFile:getBool(key .. "#initialActive", false)))
            end
        end)
        xmlFile:delete()
    end
end
function IntroductionHelpSystem:saveShownElements()
    local shownElements = ""
    for elementName, element in pairs(self.registeredElements) do
        if element.alreadyShown then
        end
    end
    local missionInfo = g_currentMission.missionInfo
    if missionInfo ~= nil then
        missionInfo.introductionHelpShownElements = shownElements
    end
    local shownHints = ""
    for hintName, hint in pairs(self.registeredHints) do
        if hint.alreadyShown then
        end
    end
    if missionInfo ~= nil then
        missionInfo.introductionHelpShownHints = shownHints
    end
end
function IntroductionHelpSystem.setIsActive(_, isActive)
    local missionInfo = g_currentMission.missionInfo
    if missionInfo ~= nil then
        missionInfo.introductionHelpActive = isActive
    end
end
function IntroductionHelpSystem:getIsActive()
    return not g_guidedTourManager:getIsTourRunning() and g_currentMission.missionInfo.introductionHelpActive
end
function IntroductionHelpSystem:getIsHelpVisible()
    return self.currentElement ~= nil
end
function IntroductionHelpSystem:showHelp(name, forced, blockInput, customText, callback, callbackTarget)
    local element = self.registeredElements[name]
    if element == nil or element.drawFunction == nil or (element.alreadyShown or element.waitingForDraw) and not forced then
        if callback ~= nil then
            callback(callbackTarget)
        end
    else
        element.waitingForDraw = true
        element.blockInput = Utils.getNoNil(blockInput, true)
        element.customText = customText
        element.callback = callback
        element.callbackTarget = callbackTarget
        table.addElement(self.drawHelpQueue, element)
    end
end
function IntroductionHelpSystem:hideHelp(name, forced)
    local element = self.registeredElements[name]
    if element ~= nil and (element.canReset or forced) then
        element.waitingForDraw = false
        table.removeElement(self.drawHelpQueue, element)
        if element == self.currentElement then
            self:revertInputContext()
            if self.currentElement.callback ~= nil then
                self.currentElement.callback(self.currentElement.callbackTarget)
            end
            self.currentElement = nil
        end
    end
end
function IntroductionHelpSystem:hideAll()
    for _, element in ipairs(self.drawHelpQueue) do
        self.registeredElements[element.name].alreadyShown = true
    end
    self:saveShownElements()
    self.drawHelpQueue = {}
    if self.currentElement ~= nil then
        self:onContinueNext()
    end
end
function IntroductionHelpSystem:showHint(name, callback, target)
    local hint = self.registeredHints[name]
    if hint ~= nil and not hint.alreadyShown then
        InfoDialog.show(hint.text, callback, target)
        table.insert(self.shownHints, hint.text)
        hint.alreadyShown = true
        self:saveShownElements()
    end
end
function IntroductionHelpSystem:resetElement(elementName, forced)
    local element = self.registeredElements[elementName]
    if element ~= nil and (element.canReset or forced) then
        element.alreadyShown = false
        element.waitingForDraw = false
        table.removeElement(self.drawHelpQueue, element)
        if element == self.currentElement then
            self:revertInputContext()
            if self.currentElement.callback ~= nil then
                self.currentElement.callback(self.currentElement.callbackTarget)
            end
            self.currentElement = nil
        end
    end
end
function IntroductionHelpSystem:getCanShowHelp()
    if g_gui:getIsGuiVisible() then
        return false
    else
        return not g_appIsSuspended
    end
end
function IntroductionHelpSystem:update(_)
    if self.currentElement == nil and self:getCanShowHelp() then
        while #self.drawHelpQueue > 0 do
            local element = table.remove(self.drawHelpQueue, 1)
            self.registeredElements[element.name].alreadyShown = true
            self:saveShownElements()
            if element.availableFunction ~= nil and not element.availableFunction(element.target) then
                element = nil
            end
            if element ~= nil then
                if element.blockInput then
                    if element.registerCustomInputFunction == nil then
                        g_inputBinding:setContext(element.name)
                        local isAvailable, eventId = g_inputBinding:registerActionEvent(InputAction.INTRODUCTION_HELP_SKIP, self, self.onContinueNext, false, true, false, true)
                        g_inputBinding:setActionEventText(eventId, g_i18n:getText("button_continue"))
                        if g_touchHandler ~= nil then
                            g_touchHandler:setCustomContext(element.name, true)
                            self.currentTouchArea = g_touchHandler:registerTouchArea(0, 0, 1, 1, 0, 0, TouchHandler.TRIGGER_UP, self.onContinueNextTouch, self)
                        end
                    else
                        element.registerCustomInputFunction(element.target)
                    end
                end
                self.currentElement = element
                break
            end
        end
    end
    if self.currentElement ~= nil and (self.currentElement.availableFunction ~= nil and not self.currentElement.availableFunction(self.currentElement.target)) then
        self:onContinueNext()
    end
end
function IntroductionHelpSystem:draw()
    if self.currentElement ~= nil then
        new2DLayer()
        self.currentElement.drawFunction(self.currentElement.target, self.currentElement.customText)
    end
end
function IntroductionHelpSystem:onMenuOpen()
    local _ = self.currentElement == nil
end
function IntroductionHelpSystem:onAppSuspended()
    local _ = self.currentElement == nil
end
function IntroductionHelpSystem:revertInputContext()
    local element = self.currentElement
    if element ~= nil and element.blockInput then
        if element.unregisterCustomInputFunction == nil then
            if g_touchHandler ~= nil then
                g_touchHandler:revertCustomContext()
                if self.currentTouchArea ~= nil then
                    g_touchHandler:removeTouchArea(self.currentTouchArea)
                    self.currentTouchArea = nil
                end
            end
            g_inputBinding:removeActionEventsByTarget(self)
            g_inputBinding:revertContext()
            return
        end
        element.unregisterCustomInputFunction(element.target)
    end
end
function IntroductionHelpSystem:onContinueNextTouch()
    if not g_gui:getIsGuiVisible() then
        self:onContinueNext()
    end
end
function IntroductionHelpSystem:onContinueNext()
    if self.currentElement ~= nil then
        self.currentElement.canReset = false
        self:revertInputContext()
        if self.currentElement.callback ~= nil then
            self.currentElement.callback(self.currentElement.callbackTarget)
        end
        self.currentElement = nil
    end
end
function IntroductionHelpSystem:getShownHints()
    return self.shownHints
end
function IntroductionHelpSystem:resetHelpSystem()
    for _, element in pairs(self.registeredElements) do
        element.alreadyShown = false
        if element.waitingForDraw ~= nil then
            element.waitingForDraw = false
        end
    end
end
function IntroductionHelpSystem:resetHelpSystemWithDraw()
    for _, element in pairs(self.registeredElements) do
        if element.alreadyShown == true then
            element.waitingForDraw = true
            element.alreadyShown = false
            table.insert(self.drawHelpQueue, element)
        end
    end
end