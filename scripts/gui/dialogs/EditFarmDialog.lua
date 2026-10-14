EditFarmDialog = {}
local EditFarmDialog_mt = Class(EditFarmDialog, MessageDialog)
EditFarmDialog.MAX_COLUMNS = 8
function EditFarmDialog.register()
    local editFarmDialog = EditFarmDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/EditFarmDialog.xml", "EditFarmDialog", editFarmDialog)
    EditFarmDialog.INSTANCE = editFarmDialog
end
function EditFarmDialog.show(farmId)
    if EditFarmDialog.INSTANCE ~= nil then
        g_gui:showDialog("EditFarmDialog")
        EditFarmDialog.INSTANCE:setExistingFarm(farmId)
    end
end
function EditFarmDialog.new(target, custom_mt)
    -- upvalues: (copy) EditFarmDialog_mt
    local self = EditFarmDialog:superClass().new(target, custom_mt or EditFarmDialog_mt)
    self.farmId = nil
    self.isCreatingNewFarm = true
    self.availableColorIndexMap = {}
    self.availableColors = {}
    self.selectedColorIndex = 1
    self.currentColorItemList = {}
    self.colorsToAdd = {}
    self.selectedIndex = 1
    self.colorElements = {}
    return self
end
function EditFarmDialog.createFromExistingGui(gui, _)
    EditFarmDialog.register()
    EditFarmDialog.show(gui.farmId)
end
function EditFarmDialog:delete()
    if self.buttonTemplate ~= nil then
        self.buttonTemplate:delete()
    end
    EditFarmDialog:superClass().delete(self)
end
function EditFarmDialog:onClose()
    EditFarmDialog:superClass().onClose(self)
    self.isCreatingNewFarm = true
end
function EditFarmDialog:setColors(colors, defaultColor, defaultColorMaterial)
    local i = #self.colorElements
    local newColors = 1
    local numCols = -1
    for i = i, newColors, numCols do
        self.colorElements[i]:delete()
    end
    if #colors == 0 then
        return
    end
    local numCols = colors[1].color
    local newColors
    if type(numCols) == "table" then
        newColors = colors
    else
        for i, color in ipairs(colors) do
            ({})[i] = {
                ["color"] = color
            }
            if table.equalLists(defaultColor, color) then
                defaultColor = newColors[i]
            end
        end
    end
    self.colors = newColors
    self.colorElements = {}
    self.colorMapping = {}
    self.buttonMapping = {}
    for _, i in ipairs(newColors) do
        if i.uiColor == nil then
            if table.equalLists(defaultColor, i.color) and (defaultColorMaterial == nil or i.material == defaultColorMaterial) then
                self.defaultColor = i
                break
            end
        elseif table.equalLists(defaultColor, i.uiColor) and (defaultColorMaterial == nil or i.material == defaultColorMaterial) then
            self.defaultColor = i
            break
        end
    end
    local newColors = self.buttonTemplate.size[1] + self.buttonTemplate.margin[1] + self.buttonTemplate.margin[3]
    for i, color in ipairs(newColors) do
        if color.isSelectable ~= false then
            local newColorButton = self.buttonTemplate:clone(self.colorButtonLayout)
            newColorButton:setVisible(true)
            self.colorMapping[newColorButton] = i
            self.buttonMapping[color] = newColorButton
            table.insert(self.colorElements, newColorButton)
            local uiColor = color.color
            if color.uiColor ~= nil then
                uiColor = color.uiColor
            end
            newColorButton:setMaterial(nil)
            newColorButton:setColor(uiColor[1] or 1, uiColor[2] or 1, uiColor[3] or 1)
        end
    end
    self.colorButtonLayout:invalidateLayout()
    local i = self.colorButtonLayout.size[1] / newColors
    self:focusLinkColorButtons((math.floor(i)))
    self.defaultColorMaterial = defaultColorMaterial
end
function EditFarmDialog:setCallback(callbackFunction, target, args)
    self.callbackFunction = callbackFunction
    self.target = target
    self.args = args
end
function EditFarmDialog:onCreate()
    EditFarmDialog:superClass().onCreate(self)
    self.defaultOkText = self.okButton.text
    self.defaultBackText = self.backButton.text
    self.buttonTemplate:unlinkElement()
    self.buttonTemplate:setVisible(false)
end
function EditFarmDialog:onClickOk()
    if self.currentSelectedElement == nil then
        return true
    end
    self:onClickColorButton(self.currentSelectedElement)
    return false
end
function EditFarmDialog:onClickBack(_, _)
    self:sendCallback(nil)
    return false
end
function EditFarmDialog:sendCallback(colorIndex)
    self:close()
    if self.callbackFunction ~= nil then
        if self.target ~= nil then
            self.callbackFunction(self.target, colorIndex, self.args)
            return
        end
        self.callbackFunction(colorIndex, self.args)
    end
end
function EditFarmDialog:onFocusColorButton(element)
    self.currentSelectedElement = element
    if self.colorName ~= nil then
        self.colorName:setText(Utils.getNoNil(self.colors[self.colorMapping[element]].name, ""))
    end
end
function EditFarmDialog:onLeaveColorButton(_)
    if self.colorName ~= nil then
        if self.currentSelectedElement ~= nil then
            self.colorName:setText(Utils.getNoNil(self.colors[self.colorMapping[self.currentSelectedElement]].name, ""))
            return
        end
        self.colorName:setText("")
    end
end
function EditFarmDialog:setButtonTexts(okText, backText)
    self.okButton:setText(Utils.getNoNil(okText, self.defaultOkText))
    self.backButton:setText(Utils.getNoNil(backText, self.defaultBackText))
end
function EditFarmDialog:setExistingFarm(farmId)
    self.farmId = farmId
    self:storeAvailableColors(farmId)
    if farmId == nil or (farmId == FarmManager.INVALID_FARM_ID or farmId == FarmManager.SPECTATOR_FARM_ID) then
        self.titleText:setText(g_i18n:getText(EditFarmDialog.L10N_SYMBOL.TITLE_CREATE_FARM))
        self.farmNameInput:setText(g_i18n:getText(EditFarmDialog.L10N_SYMBOL.DEFAULT_FARM_NAME))
        self.farmPasswordInput:setText("")
        self.selectedColorIndex = self.availableColorIndexMap[1]
        self:setButtonTexts(g_i18n:getText(EditFarmDialog.L10N_SYMBOL.BUTTON_CREATE))
    else
        self.isCreatingNewFarm = false
        local farm = g_farmManager:getFarmById(farmId)
        local titleTemplate = g_i18n:getText(EditFarmDialog.L10N_SYMBOL.TITLE_EDIT_FARM_TEMPLATE)
        local title = string.format(titleTemplate, farm.name)
        self.titleText:setText(title)
        self.farmNameInput:setText(farm.name)
        self.farmPasswordInput:setText(farm.password or "")
        self.selectedColorIndex = farm.color
        self:setButtonTexts(g_i18n:getText(EditFarmDialog.L10N_SYMBOL.BUTTON_CONFIRM))
    end
    self.farmIconPreview:setImageSlice(nil, Farm.ICON_SLICE_IDS[self.selectedColorIndex])
    self:setColors(self.availableColors, self.availableColors[1])
    self.dialogButtonLayout:invalidateLayout()
end
function EditFarmDialog:storeAvailableColors(editingFarmId)
    self.availableColors = {}
    self.availableColorIndexMap = {}
    local farms = g_farmManager:getFarms()
    for farmColorIndex, color in ipairs(Farm.COLORS) do
        local colorTaken = false
        for _, farm in pairs(farms) do
            if farm.showInFarmScreen and (farm.farmId ~= editingFarmId and farm.color == farmColorIndex) then
                colorTaken = true
                break
            end
        end
        if not colorTaken then
            table.insert(self.availableColors, color)
            self.availableColorIndexMap[#self.availableColors] = farmColorIndex
        end
    end
end
function EditFarmDialog:resizeDialog(heightOffset) end
function EditFarmDialog:focusLinkColorButtons(numCols)
    local i = 1
    for i = i, #self.colorButtonLayout.elements do
        local leftButton = self.colorButtonLayout.elements[i - 1]
        local rightButton = self.colorButtonLayout.elements[i + 1]
        local topButton = self.colorButtonLayout.elements[i - numCols]
        local bottomButton = self.colorButtonLayout.elements[i + numCols]
        if leftButton == nil then
            FocusManager:linkElements(self.colorButtonLayout.elements[i], FocusManager.LEFT, self.colorButtonLayout.elements[i])
        else
            FocusManager:linkElements(button, FocusManager.LEFT, leftButton)
        end
        if rightButton == nil then
            FocusManager:linkElements(button, FocusManager.RIGHT, button)
        else
            FocusManager:linkElements(button, FocusManager.RIGHT, rightButton)
        end
        if topButton == nil then
            FocusManager:linkElements(button, FocusManager.TOP, button)
        else
            FocusManager:linkElements(button, FocusManager.TOP, topButton)
        end
        if bottomButton == nil then
            FocusManager:linkElements(button, FocusManager.BOTTOM, button)
        else
            FocusManager:linkElements(button, FocusManager.BOTTOM, bottomButton)
        end
    end
    local i = 1
    for i = i, #self.colorButtonLayout.elements do
        local button = self.colorButtonLayout.elements[i]
        FocusManager:linkElements(button, FocusManager.TOP, self.farmPasswordInput)
        FocusManager:linkElements(button, FocusManager.BOTTOM, self.farmNameInput)
    end
    FocusManager:linkElements(self.farmPasswordInput, FocusManager.BOTTOM, self.colorButtonLayout)
end
function EditFarmDialog:onClickColorButton(element)
    self.selectedColorIndex = self.availableColorIndexMap[self.colorMapping[element]]
    self.farmIconPreview:setImageSlice(nil, Farm.ICON_SLICE_IDS[self.selectedColorIndex])
end
function EditFarmDialog:onClickDone()
    local farmName = self.farmNameInput.text
    local password = self.farmPasswordInput.text
    if password == "" then
        password = nil
    end
    local filteredName = filterText(farmName, true, true)
    if farmName ~= "" then
        if farmName == filteredName then
            if self.isCreatingNewFarm then
                g_client:getServerConnection():sendEvent(FarmCreateUpdateEvent.new(farmName, self.selectedColorIndex, password, false, nil))
            else
                g_client:getServerConnection():sendEvent(FarmCreateUpdateEvent.new(farmName, self.selectedColorIndex, password, true, self.farmId))
            end
            self:close()
        else
            self.farmNameInput:setText(filteredName)
            Logging.info("Entered farm name contains profanity and has been adjusted.")
        end
    end
    return false
end
function EditFarmDialog:onClickEdit()
    local focusedElement = FocusManager:getFocusedElement()
    if focusedElement == self.farmNameInput then
        self.farmNameInput:onFocusActivate()
        return
    elseif focusedElement == self.farmPasswordInput then
        self.farmPasswordInput:onFocusActivate()
    else
        for _, button in ipairs(self.colorButtonLayout.elements) do
            if button == focusedElement then
                button:sendAction()
            end
        end
    end
end
EditFarmDialog.L10N_SYMBOL = {
    ["TITLE_CREATE_FARM"] = "ui_createNewFarm",
    ["TITLE_EDIT_FARM_TEMPLATE"] = "ui_editFarm",
    ["DEFAULT_FARM_NAME"] = "ui_defaultFarmName",
    ["BUTTON_CREATE"] = "button_mp_createFarm",
    ["BUTTON_CONFIRM"] = "button_confirm"
}