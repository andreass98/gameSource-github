WardrobeOutfitsFrame = {}
local WardrobeOutfitsFrame_mt = Class(WardrobeOutfitsFrame, TabbedMenuFrameElement)
function WardrobeOutfitsFrame.register()
    local wardrobeOutfitsFrame = WardrobeOutfitsFrame.new()
    g_gui:loadGui("dataS/gui/WardrobeOutfitsFrame.xml", "WardrobeOutfitsFrame", wardrobeOutfitsFrame, true)
end
function WardrobeOutfitsFrame.new(target, custom_mt)
    -- upvalues: (copy) WardrobeOutfitsFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or WardrobeOutfitsFrame_mt)
    self.backButtonInfo = {
        ["inputAction"] = InputAction.MENU_BACK,
        ["text"] = g_i18n:getText("button_confirm")
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
    self.equipButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText("button_select"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onClickSelect()
        end
    }
    self.colorButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText("button_selectColor"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onClickSelectColor()
        end
    }
    self.hasCustomMenuButtons = true
    self.menuButtonInfo = {
        self.backButtonInfo,
        self.nextPageButtonInfo,
        self.prevPageButtonInfo,
        self.equipButtonInfo
    }
    self.indexMapping = {}
    self.isShowingColors = false
    return self
end
function WardrobeOutfitsFrame.createFromExistingGui(gui, guiName)
    local newGui = WardrobeOutfitsFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function WardrobeOutfitsFrame:initialize(delegate, titleKey, sliceId)
    self.delegate = delegate
    self.title:setLocaKey(titleKey)
    self.headerIcon:setImageSlice(nil, sliceId)
end
function WardrobeOutfitsFrame:setPlayerStyle(playerStyle, savedPlayerStyle)
    self.playerStyle = playerStyle
    self.savedPlayerStyle = savedPlayerStyle
    self:resetList()
end
function WardrobeOutfitsFrame:onFrameOpen()
    WardrobeOutfitsFrame:superClass().onFrameOpen(self)
    if self.lastPlayerStyle == nil then
        self.lastPlayerStyle = PlayerStyle.new()
    end
    self.lastPlayerStyle:copyFrom(self.savedPlayerStyle)
    if not self.isShowingColors then
        self.delegate:onItemSelectionStart()
        self:resetList()
    end
end
function WardrobeOutfitsFrame:resetList()
    if self.playerStyle ~= nil then
        self.indexMapping = {
            { -1 },
            {}
        }
        self.currentlyUsedPreset = self:getCurrentlySelectedPresetIndex()
        local selectedIndex = 1
        local selectedSection = 1
        for i, preset in ipairs(self.playerStyle.presets) do
            if preset.brandName ~= nil then
                preset.brand = g_brandManager:getBrandByName(preset.brandName)
                if preset.brand ~= nil then
                    preset.brandName = nil
                end
            end
            local isCurrentSelection = self.currentlyUsedPreset == i
            if preset.isSelectable and (isCurrentSelection or (preset.extraContentId == nil or g_extraContentSystem:getIsItemIdUnlocked(preset.extraContentId))) then
                table.insert(self.indexMapping[preset.brand == nil and 1 or 2], i)
                if isCurrentSelection then
                    selectedIndex = #self.indexMapping[section]
                    selectedSection = section
                end
            end
        end
        self.itemList:reloadData()
        self.itemList:setSelectedItem(selectedSection, selectedIndex)
    end
end
function WardrobeOutfitsFrame:getCurrentlySelectedPresetIndex()
    for i, preset in ipairs(self.playerStyle.presets) do
        if preset:getDoesStyleUse(self.savedPlayerStyle) then
            return i
        end
    end
    return -1
end
function WardrobeOutfitsFrame:onFrameClose()
    if not self.isShowingColors then
        for _, cell in ipairs(self.itemList.elements) do
            if not cell.isHeader and cell:getAttribute("icon") ~= nil then
                cell:getAttribute("icon"):setImageFilename(g_baseUIFilename)
            end
        end
    end
    WardrobeOutfitsFrame:superClass().onFrameClose(self)
end
function WardrobeOutfitsFrame:updateSelectionButton()
    local item = self:getSelectedPreset()
    local hasColors = false
    if item ~= nil then
        hasColors = self:getPresetHasColors(item)
    end
    self.menuButtonInfo = {
        self.backButtonInfo,
        self.nextPageButtonInfo,
        self.prevPageButtonInfo,
        self.equipButtonInfo,
        hasColors and self.colorButtonInfo or nil
    }
    self:setMenuButtonInfoDirty()
end
function WardrobeOutfitsFrame:getNumberOfSections()
    return #self.indexMapping[2] > 0 and 2 or 1
end
function WardrobeOutfitsFrame:getTitleForSectionHeader(list, section)
    if section == 2 then
        return g_i18n:getText("character_section_branded")
    else
        return self:getNumberOfItemsInSection(list, section) > 0 and "" or nil
    end
end
function WardrobeOutfitsFrame:getNumberOfItemsInSection(_, section)
    return #self.indexMapping[section]
end
function WardrobeOutfitsFrame:populateCellForItemInSection(_, section, index, cell)
    local presetIndex = self.indexMapping[section][index]
    if presetIndex == -1 then
        cell:getAttribute("icon"):setVisible(false)
        cell:getAttribute("hasColors"):setVisible(false)
        cell:getAttribute("background").getIsSelected = function()
            -- upvalues: (copy) self
            return self.currentlyUsedPreset == -1
        end
        cell:getAttribute("background").getIsFocused = function()
            -- upvalues: (copy) cell, (copy) self, (copy) section, (copy) index
            return cell.selected or self.currentHoveredSection == section and self.currentHoveredIndex == index
        end
    else
        local preset = self.playerStyle.presets[presetIndex]
        if preset ~= nil then
            cell:getAttribute("icon"):setImageFilename(preset.iconFilename)
            cell:getAttribute("icon"):setVisible(preset.iconFilename ~= nil)
            cell:getAttribute("icon").getIsSelected = function()
                -- upvalues: (copy) self, (copy) presetIndex
                return self.currentlyUsedPreset == presetIndex
            end
            cell:getAttribute("background").getIsSelected = getIsSelectedFunc
            cell:getAttribute("background").getIsFocused = getIsFocusedFunc
            cell:getAttribute("hasColors"):setVisible(self:getPresetHasColors(preset))
            cell:getAttribute("hasColors").getIsSelected = getIsSelectedFunc
            return
        end
    end
end
function WardrobeOutfitsFrame:onListSelectionChanged(_, section, index)
    if not g_gui.currentlyReloading then
        local preset = self:getPresetFromItem(section, index)
        if preset == nil then
            if self.currentlyUsedPreset == -1 or self.lastPlayerStyle == nil then
                self.delegate:onItemSelectionCancelled()
            else
                self.playerStyle:copyFrom(self.lastPlayerStyle)
                self.delegate:onItemSelectionChanged()
            end
        else
            preset:applyToStyle(self.playerStyle, self.currentlyUsedPreset ~= self.indexMapping[section][index])
            self.delegate:onItemSelectionChanged()
        end
        self:updateSelectionButton()
    end
end
function WardrobeOutfitsFrame:onListHighlightChanged(_, section, index)
    self.currentHoveredSection = section
    self.currentHoveredIndex = index
    if index == nil then
        self.delegate:onItemSelectionCancelled()
        return
    else
        local preset = self:getPresetFromItem(section, index)
        if preset == nil then
            if self.currentlyUsedPreset == -1 then
                self.delegate:onItemSelectionCancelled()
            else
                self.playerStyle:copyFrom(self.lastPlayerStyle)
                self.delegate:onItemSelectionChanged()
            end
        else
            preset:applyToStyle(self.playerStyle, self.currentlyUsedPreset ~= self:getCurrentlySelectedPresetIndex())
            self.delegate:onItemSelectionChanged()
            return
        end
    end
end
function WardrobeOutfitsFrame:onClickSelect()
    self.delegate:onItemSelectionConfirmed()
    self.currentlyUsedPreset = self:getCurrentlySelectedPresetIndex()
    self.itemList:reloadData()
end
function WardrobeOutfitsFrame:onClickSelectColor()
    local preset = self:getSelectedPreset()
    self.isShowingColors = true
    local item = nil
    if preset.configs.onepiece ~= nil and not string.isNilOrWhitespace(preset.configs.onepiece.selectionName) then
        item = self.playerStyle.configs.onepiece.itemsByName[preset.configs.onepiece.selectionName]
    end
    local originalColor = self.playerStyle.configs.onepiece.selectedColorIndex
    self.delegate:onItemShowColors("onepiece", item, function(confirmed, keepOpen)
        -- upvalues: (copy) self, (ref) originalColor
        if not keepOpen then
            self.isShowingColors = false
        end
        if confirmed then
            originalColor = self.playerStyle.configs.onepiece.selectedColorIndex
        else
            self.playerStyle.configs.onepiece:setSelectedColorIndex(originalColor)
            self.delegate:onItemSelectionChanged()
        end
    end)
end
function WardrobeOutfitsFrame:getSelectedPreset()
    return self:getPresetFromItem(self.itemList.selectedSectionIndex, self.itemList.selectedIndex)
end
function WardrobeOutfitsFrame:getPresetFromItem(section, index)
    local presetIndex = self.indexMapping[section][index]
    if presetIndex == -1 then
        return nil
    else
        return self.playerStyle.presets[presetIndex]
    end
end
function WardrobeOutfitsFrame:getPresetHasColors(preset)
    if preset.configs.onepiece ~= nil and not string.isNilOrWhitespace(preset.configs.onepiece.selectionName) then
        local onepiece = self.playerStyle.configs.onepiece.itemsByName[preset.configs.onepiece.selectionName]
        if onepiece ~= nil then
            return onepiece.colorableSlots > 0
        end
    end
    return false
end