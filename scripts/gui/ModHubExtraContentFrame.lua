ModHubExtraContentFrame = {}
local ModHubExtraContentFrame_mt = Class(ModHubExtraContentFrame, TabbedMenuFrameElement)
function ModHubExtraContentFrame.register()
    local modHubExtraContentFrame = ModHubExtraContentFrame.new()
    g_gui:loadGui("dataS/gui/ModHubExtraContentFrame.xml", "ModHubExtraContentFrame", modHubExtraContentFrame, true)
end
function ModHubExtraContentFrame.new(target, custom_mt)
    -- upvalues: (copy) ModHubExtraContentFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or ModHubExtraContentFrame_mt)
    self.items = {}
    return self
end
function ModHubExtraContentFrame.createFromExistingGui(gui, guiName)
    local newGui = ModHubExtraContentFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function ModHubExtraContentFrame:onGuiSetupFinished()
    ModHubExtraContentFrame:superClass().onGuiSetupFinished(self)
    self.itemsList:setDataSource(self)
    self.itemsList:setDelegate(self)
end
function ModHubExtraContentFrame:initialize(title)
    self.headerText:setText(title)
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
    self.unlockButton = {
        ["inputAction"] = InputAction.MENU_EXTRA_2,
        ["text"] = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.BUTTON_UNLOCK),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonUnlock()
        end
    }
end
function ModHubExtraContentFrame:onFrameOpen()
    ModHubExtraContentFrame:superClass().onFrameOpen(self)
    self:updateList()
    self:setSoundSuppressed(true)
    FocusManager:setFocus(self.itemsList)
    self:setSoundSuppressed(false)
end
function ModHubExtraContentFrame:getMenuButtonInfo()
    local buttons = {}
    table.insert(buttons, self.backButtonInfo)
    table.insert(buttons, self.nextPageButtonInfo)
    table.insert(buttons, self.prevPageButtonInfo)
    if g_extraContentSystem:getHasLockedItems() then
        table.insert(buttons, self.unlockButton)
    end
    return buttons
end
function ModHubExtraContentFrame:reload()
    self:updateList()
end
function ModHubExtraContentFrame:updateList()
    self.items = g_extraContentSystem:getUnlockedItems()
    self.itemsList:reloadData()
    self.modAttributeBox:setVisible(#self.items > 0)
    self.noItemsElement:setVisible(#self.items == 0)
    self:setMenuButtonInfoDirty()
end
function ModHubExtraContentFrame:getMainElementSize()
    return self.modAttributeBox.size
end
function ModHubExtraContentFrame:getMainElementPosition()
    return self.modAttributeBox.absPosition
end
function ModHubExtraContentFrame:onClickLeft()
    self.itemsList:scrollTo(self.itemsList.firstVisibleItem - self.itemsList.itemsPerCol)
end
function ModHubExtraContentFrame:onClickRight()
    self.itemsList:scrollTo(self.itemsList.firstVisibleItem + self.itemsList.itemsPerCol)
end
function ModHubExtraContentFrame:onListSelectionChanged(_, _, index)
    local item = self.items[index]
    if item ~= nil then
        self.modAttributeName:setText(item.description)
        self.modAttributeBox:invalidateLayout()
    end
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end
function ModHubExtraContentFrame:onButtonUnlock(defaultText)
    local dialogPrompt = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.UNLOCK_ITEM_KEY)
    local imePrompt = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.UNLOCK_ITEM_KEY)
    local confirmText = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.UNLOCK_ITEM)
    TextInputDialog.show(self.onExtraContentKeyEntered, self, defaultText or "", dialogPrompt, imePrompt, GS_PLATFORM_PC and 24 or ExtraContentSystem.KEY_LENGTH, confirmText, nil, nil, false)
end
function ModHubExtraContentFrame:onExtraContentKeyEntered(text, ok, _)
    if ok then
        local upperText = utf8ToUpper(text)
        local length = utf8Strlen(text)
        if GS_PLATFORM_PC and (length >= 20 and length <= 24) then
            YesNoDialog.show(self.onEShopOpen, self, g_i18n:getText("extraContent_eshopWarning"), "", g_i18n:getText("extraContent_eshopVisitShop"), g_i18n:getText("button_back"), nil, nil, nil, text)
            return
        end
        local item, errorCode = g_extraContentSystem:unlockItem(upperText, false)
        if errorCode == ExtraContentSystem.UNLOCKED then
            self:updateList()
            InfoDialog.show(string.format(g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.UNLOCKED_ITEM), item.title))
            return
        end
        local message
        if errorCode == ExtraContentSystem.ERROR_ALREADY_UNLOCKED then
            message = string.format(g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.ALREADY_UNLOCKED_ITEM), item.title)
        elseif errorCode == ExtraContentSystem.ERROR_KEY_INVALID_FORMAT then
            message = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.INVALID_KEY_FORMAT)
        else
            message = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.INVALID_KEY)
        end
        InfoDialog.show(message, self.onButtonUnlock, self, nil, nil, nil, text)
    end
end
function ModHubExtraContentFrame:onEShopOpen(yes, text)
    if yes then
        openWebFile(Platform.urlEshop, "key=" .. text)
    else
        self:onButtonUnlock(text)
    end
end
function ModHubExtraContentFrame:getNumberOfItemsInSection(_, _)
    local total = #self.items
    if self.listSizeLimit == nil then
        return total
    end
    return math.min(total, self.listSizeLimit)
end
function ModHubExtraContentFrame:populateCellForItemInSection(_, _, index, cell)
    local item = self.items[index]
    cell:getAttribute("icon"):setImageFilename(item.imageFilename)
    cell:getAttribute("nameLabel"):setText(item.title)
end
ModHubExtraContentFrame.L10N_SYMBOL = {
    ["BUTTON_UNLOCK"] = "modHub_unlock",
    ["UNLOCK_ITEM"] = "modHub_unlock",
    ["UNLOCK_ITEM_KEY"] = "modHub_unlock_key",
    ["UNLOCKED_ITEM"] = "modHub_unlocked_item",
    ["ALREADY_UNLOCKED_ITEM"] = "modHub_already_unlocked_item",
    ["INVALID_KEY"] = "modHub_invalid_key",
    ["INVALID_KEY_FORMAT"] = "modHub_invalid_key_format"
}