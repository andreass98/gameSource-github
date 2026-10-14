InGameMenuTourFrame = {}
local InGameMenuTourFrame_mt = Class(InGameMenuTourFrame, TabbedMenuFrameElement)
function InGameMenuTourFrame.register()
    local inGameMenuTourFrame = InGameMenuTourFrame.new()
    g_gui:loadGui("dataS/gui/InGameMenuTourFrame.xml", "TourFrame", inGameMenuTourFrame, true)
end
function InGameMenuTourFrame.new(target, custom_mt)
    -- upvalues: (copy) InGameMenuTourFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuTourFrame_mt)
    self.hasCustomMenuButtons = true
    return self
end
function InGameMenuTourFrame.createFromExistingGui(gui, guiName)
    local newGui = InGameMenuTourFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function InGameMenuTourFrame:delete()
    self.contentItem:delete()
    self.controlItem:delete()
    InGameMenuTourFrame:superClass().delete(self)
end
function InGameMenuTourFrame:initialize()
    InGameMenuTourFrame:superClass().initialize()
    self.contentItem:unlinkElement()
    self.controlItem:unlinkElement()
    self.abortButton = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText("button_abortTour"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonCancel()
        end,
        ["profile"] = "buttonCancel"
    }
end
function InGameMenuTourFrame:onFrameOpen()
    InGameMenuTourFrame:superClass().onFrameOpen(self)
    self:updateContents()
    self.layout:registerActionEvents()
    self:updateMenuButtons()
end
function InGameMenuTourFrame:onFrameClose()
    self.layout:removeActionEvents()
    InGameMenuTourFrame:superClass().onFrameClose(self)
end
function InGameMenuTourFrame:updateMenuButtons()
    self.menuButtonInfo = {
        {
            ["inputAction"] = InputAction.MENU_BACK
        }
    }
    local tour = g_guidedTourManager:getActiveTour()
    if tour ~= nil and tour:getCanAbort() then
        table.insert(self.menuButtonInfo, self.abortButton)
    end
    self:setMenuButtonInfoDirty()
end
function InGameMenuTourFrame:onButtonCancel()
    if g_guidedTourManager:getIsTourRunning() and g_guidedTourManager:getActiveTour():getCanAbort() then
        YesNoDialog.show(self.onAbortTourAnswer, self, g_i18n:getText("guidedTour_abort_question"), "")
    end
end
function InGameMenuTourFrame.onAbortTourAnswer(_, yes)
    if yes then
        local tour = g_guidedTourManager:getActiveTour()
        if tour ~= nil and tour:getCanAbort() then
            g_guidedTourManager:abortTour()
            g_gui:changeScreen(nil)
        end
    end
end
function InGameMenuTourFrame:update(dt)
    InGameMenuTourFrame:superClass().update(self, dt)
    if g_inputBinding:getInputHelpMode() ~= self.currentInputHelpMode then
        self:updateContents()
    end
end
function InGameMenuTourFrame:updateContents()
    self.currentInputHelpMode = g_inputBinding:getInputHelpMode()
    local i = #self.layout.elements
    local tour = 1
    local steps = -1
    for i = i, tour, steps do
        self.layout.elements[i]:delete()
    end
    self.layout:invalidateLayout()
    local tour = g_guidedTourManager:getActiveTour()
    if tour ~= nil then
        local steps = tour:getPassedStepsInfo()
        local i = #steps
        local i = 1
        for i = i, i, -1 do
            local step = steps[i]
            local row = self.contentItem:clone(self.layout)
            local textElement = row:getDescendantByName("text")
            local controlsElement = row:getDescendantByName("controls")
            textElement:setText(g_i18n:convertText(step.text))
            local height = textElement:getTextHeight()
            textElement:setSize(nil, height)
            local numVisibleControls = 0
            if step.inputs ~= nil then
                for _, input in ipairs(step.inputs) do
                    if not (input.keyboardOnly and self.currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD) and (not input.gamepadOnly or self.currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD) then
                        local controlItem = self.controlItem:clone(controlsElement)
                        numVisibleControls = numVisibleControls + 1
                        controlItem.hasFrame = numVisibleControls > 1
                        controlItem:getDescendantByName("glyph"):setActions({ InputAction[input.actionName], input.actionName2 ~= nil and InputAction[input.actionName2] or nil })
                        controlItem:getDescendantByName("text"):setText(g_i18n:convertText(input.text))
                    end
                end
            end
            controlsElement:setVisible(numVisibleControls > 0)
            if numVisibleControls > 0 then
                controlsElement:setSize(nil, numVisibleControls * controlsElement.elements[1].absSize[2])
                controlsElement:invalidateLayout()
                height = math.max(height, controlsElement.absSize[2] - 20 * g_pixelSizeY)
            end
            row:setSize(nil, row.size[2] + height)
        end
        self.layout:invalidateLayout()
    end
end