TourDialog = {}
local TourDialog_mt = Class(TourDialog, MessageDialog)
function TourDialog.register()
    local tourDialog = TourDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/TourDialog.xml", "TourDialog", tourDialog)
    TourDialog.INSTANCE = tourDialog
end
function TourDialog.show(title, text, controlGlyphs, callback, target)
    if TourDialog.INSTANCE ~= nil then
        local dialog = TourDialog.INSTANCE
        dialog.controlGlyphs = controlGlyphs or {}
        dialog:setTitle(title)
        dialog:setText(text)
        dialog:setCallback(callback, target)
        dialog:updateSize()
        g_gui:showDialog("TourDialog")
    end
end
function TourDialog.new(target, custom_mt)
    -- upvalues: (copy) TourDialog_mt
    local self = MessageDialog.new(target, custom_mt or TourDialog_mt)
    self.buttonAction = InputAction.MENU_ACCEPT
    self.isBackAllowed = false
    self.inputDelay = 250
    self.defaultTitle = "Guided Tour"
    self.controlGlyphs = {}
    self.lastInputHelpMode = GS_INPUT_HELP_MODE_TOUCH
    return self
end
function TourDialog.createFromExistingGui(gui, _)
    TourDialog.register()
    TourDialog.show(gui.title, gui.tourText, gui.controlGlyphs, gui.onOk, gui.target)
end
function TourDialog:setTitle(title)
    if self.dialogTitleElement ~= nil then
        self.dialogTitleElement:setText(Utils.getNoNil(title, self.defaultTitle))
    end
end
function TourDialog:setText(text)
    TourDialog:superClass().setText(self, text)
    self.tourText = text
end
function TourDialog:setCallback(onOk, target)
    self.onOk = onOk
    self.target = target
end
function TourDialog:updateSize()
    for i, inputItem in pairs(self.inputItems) do
        local controlGlyph = self.controlGlyphs[i]
        if controlGlyph == nil then
            self.inputItems[i]:setVisible(false)
        else
            self.inputItems[i]:setVisible(true)
            self.description[i]:setText(controlGlyph.text)
            local icon1 = self.icon1[i]
            local icon2 = self.icon2[i]
            if controlGlyph.buttons[2] == nil then
                icon1 = self.icon2[i]
                icon2 = self.icon1[i]
            end
            icon1:setVisible(controlGlyph.buttons[1] ~= nil)
            if controlGlyph.buttons[1] ~= nil then
                icon1:setImageFilename(controlGlyph.buttons[1].filename)
                icon1:setImageUVs(nil, unpack(controlGlyph.buttons[1].uvs))
            end
            local isAccelerateAction = true
            if controlGlyph.actionName ~= "AXIS_ACCELERATE_VEHICLE" then
                isAccelerateAction = controlGlyph.actionName == "AXIS_BRAKE_VEHICLE"
            end
            if isAccelerateAction then
                self.iconSeparator[i]:applyProfile("tourDialogItemIconSeparator")
            else
                self.iconSeparator[i]:applyProfile("tourDialogItemIconPlus")
            end
            self.iconSeparator[i]:setVisible(controlGlyph.buttons[2] ~= nil)
            icon2:setVisible(controlGlyph.buttons[2] ~= nil)
            if controlGlyph.buttons[2] ~= nil then
                icon2:setImageFilename(controlGlyph.buttons[2].filename)
                icon2:setImageUVs(nil, unpack(controlGlyph.buttons[2].uvs))
            end
        end
    end
    local dialogTextElement = self.dialogTextElement
    local textHeight = dialogTextElement:getTextHeight()
    self.dialogTextElement:setSize(nil, textHeight)
    local inputBoxSize = 0
    local i = 0
    local inputItem = self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD
    local controlGlyph = self.inputItems[1].absSize[2]
    if inputItem and #self.controlGlyphs > 0 then
        inputBoxSize = controlGlyph * #self.controlGlyphs + 30 * g_pixelSizeY
    end
    self.inputBox:setVisible(inputItem)
    local icon1 = inputBoxSize + textHeight + dialogTextElement.margin[2] + dialogTextElement.margin[4]
    self.dialogElement:setSize(nil, icon1)
    self.dialogElement:updateAbsolutePosition()
    if inputItem then
        self.inputBox:setPosition(nil, self.dialogTextElement.position[2] - i - textHeight)
        self.inputBox:setSize(nil, controlGlyph * #self.controlGlyphs)
        self.dialogElement:updateAbsolutePosition()
    end
end
function TourDialog:acceptDialog(inputAction, force)
    if inputAction ~= self.buttonAction and not force or self.inputDelay >= self.time then
        return true
    end
    self:close()
    if self.onOk ~= nil then
        if self.target == nil then
            self.onOk(self.args)
        else
            self.onOk(self.target, self.args)
        end
    end
    return false
end
function TourDialog:onClickOk()
    return self:acceptDialog(self.buttonAction, false)
end
function TourDialog:update(dt)
    TourDialog:superClass().update(self, dt)
    local newInputHelpMode = g_inputBinding:getInputHelpMode()
    if newInputHelpMode ~= self.lastInputHelpMode then
        self.lastInputHelpMode = newInputHelpMode
        self:updateSize()
    end
end
function TourDialog:inputEvent(action, value, eventUsed)
    eventUsed = TourDialog:superClass().inputEvent(self, action, value, eventUsed)
    if Platform.isAndroid and (self.inputDisableTime <= 0 and action == InputAction.MENU_BACK) then
        self:onClickOk()
        eventUsed = true
    end
    return eventUsed
end