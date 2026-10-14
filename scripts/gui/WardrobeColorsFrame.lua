WardrobeColorsFrame = {}
local WardrobeColorsFrame_mt = Class(WardrobeColorsFrame, TabbedMenuFrameElement)
function WardrobeColorsFrame.register()
    local wardrobeColorsFrame = WardrobeColorsFrame.new()
    g_gui:loadGui("dataS/gui/WardrobeColorsFrame.xml", "WardrobeColorsFrame", wardrobeColorsFrame, true)
end
function WardrobeColorsFrame.new(target, custom_mt)
    -- upvalues: (copy) WardrobeColorsFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or WardrobeColorsFrame_mt)
    self.backButtonInfo = {
        ["inputAction"] = InputAction.MENU_BACK,
        ["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BACK),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onClickBack()
        end
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
    self.hasCustomMenuButtons = true
    self.menuButtonInfo = {
        self.backButtonInfo,
        self.nextPageButtonInfo,
        self.prevPageButtonInfo,
        self.equipButtonInfo
    }
    return self
end
function WardrobeColorsFrame.createFromExistingGui(gui, guiName)
    local newGui = WardrobeColorsFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function WardrobeColorsFrame:onGuiSetupFinished()
    WardrobeColorsFrame:superClass().onGuiSetupFinished(self)
    self.primaryList:setDataSource(self)
    self.primaryList:setDelegate(self)
end
function WardrobeColorsFrame:initialize(delegate)
    self.delegate = delegate
end
function WardrobeColorsFrame:setPlayerStyle(playerStyle, savedPlayerStyle)
    self.playerStyle = playerStyle
    self.savedPlayerStyle = savedPlayerStyle
end
function WardrobeColorsFrame:setConfigAndItem(configName, item)
    self.configName = configName
    self.item = item
    self.primaryList:reloadData()
    FocusManager:setFocus(self.primaryList)
    self.primaryList:setSelectedIndex(self.playerStyle.configs[self.configName].selectedColorIndex)
end
function WardrobeColorsFrame:onFrameOpen()
    WardrobeColorsFrame:superClass().onFrameOpen(self)
end
function WardrobeColorsFrame:getNumberOfItemsInSection(_, _)
    return (self.delegate == nil or self.item == nil) and 0 or #self.item.possibleColors
end
function WardrobeColorsFrame:populateCellForItemInSection(_, _, index, cell)
    local color = self.item.possibleColors[index].primary
    cell:getAttribute("icon"):setImageColor(nil, color.r, color.g, color.b, 1)
    cell:getAttribute("selected"):setVisible(self.savedPlayerStyle.configs[self.configName].selectedItemIndex == self.item.itemIndex and self.savedPlayerStyle.configs[self.configName].selectedColorIndex == index)
end
function WardrobeColorsFrame:onListSelectionChanged(_, _, index)
    self.playerStyle.configs[self.configName]:setSelectedColorIndex(index)
    self.delegate:onColorSelectionChanged()
end
function WardrobeColorsFrame:onListHighlightChanged(_, _, index)
    if index == nil then
        self.delegate:onColorSelectionCancelled(true)
    else
        self.playerStyle.configs[self.configName]:setSelectedColorIndex(index)
        self.delegate:onColorSelectionChanged()
    end
end
function WardrobeColorsFrame:onClickSelect()
    self.delegate:onColorSelectionConfirmed(true)
    self.primaryList:reloadData()
end
function WardrobeColorsFrame:onDoubleClickSelect()
    self.delegate:onColorSelectionConfirmed()
end
function WardrobeColorsFrame:onClickBack()
    self.delegate:onColorSelectionCancelled()
end