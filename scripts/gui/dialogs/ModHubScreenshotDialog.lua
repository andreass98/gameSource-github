ModHubScreenshotDialog = {}
local ModHubScreenshotDialog_mt = Class(ModHubScreenshotDialog, DialogElement)
function ModHubScreenshotDialog.register()
    local modHubScreenshotDialog = ModHubScreenshotDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/ModHubScreenshotDialog.xml", "ModHubScreenshotDialog", modHubScreenshotDialog)
    ModHubScreenshotDialog.INSTANCE = modHubScreenshotDialog
end
function ModHubScreenshotDialog.show(modInfo)
    if ModHubScreenshotDialog.INSTANCE ~= nil then
        ModHubScreenshotDialog.INSTANCE:setModInfo(modInfo)
        g_gui:showDialog("ModHubScreenshotDialog")
    end
end
function ModHubScreenshotDialog.new(target, custom_mt)
    -- upvalues: (copy) ModHubScreenshotDialog_mt
    return DialogElement.new(target, custom_mt or ModHubScreenshotDialog_mt)
end
function ModHubScreenshotDialog.createFromExistingGui(gui, _)
    ModHubScreenshotDialog.register()
    ModHubScreenshotDialog.show(gui.modInfo)
end
function ModHubScreenshotDialog:onCreate()
    local oldSliderFunc = self.list.onSliderValueChanged
    function self.list.onSliderValueChanged(elem, slider, newValue, immediateMode)
        -- upvalues: (copy) oldSliderFunc, (copy) self
        oldSliderFunc(elem, slider, newValue, immediateMode)
        elem:setSelectedItem(1, self.listSlider.currentValue)
    end
end
function ModHubScreenshotDialog:onOpen()
    ModHubScreenshotDialog:superClass().onOpen(self)
    self.list:setSelectedIndex(1)
end
function ModHubScreenshotDialog:onClose()
    ModHubScreenshotDialog:superClass().onClose(self)
end
function ModHubScreenshotDialog:setModInfo(modInfo)
    self.filenames = modInfo:getScreenshots()
    self.list:reloadData()
    self.modInfo = modInfo
end
function ModHubScreenshotDialog:getNumberOfItemsInSection(_, _)
    return #self.filenames
end
function ModHubScreenshotDialog:populateCellForItemInSection(_, _, index, cell)
    cell:getAttribute("image"):setImageFilename(self.filenames[index])
end
function ModHubScreenshotDialog:onListSelectionChanged(_, _, _)
    self:updateSelectors()
end
function ModHubScreenshotDialog:inputEvent(action, value, eventUsed)
    local curIndex = ModHubScreenshotDialog:superClass().inputEvent(self, action, value, eventUsed)
    if not curIndex and (action == InputAction.MENU_PAGE_PREV or action == InputAction.MENU_PAGE_NEXT) then
        if action == InputAction.MENU_PAGE_PREV then
            self.list:setSelectedIndex((math.max(self.list.selectedIndex - 1, 1)))
        else
            self.list:setSelectedIndex(curIndex + 1)
        end
        self:updateSelectors()
    end
    return curIndex
end
function ModHubScreenshotDialog:updateSelectors()
    self.selectorLeftGamepad:setVisible(self.list.selectedIndex ~= 1)
    self.selectorRightGamepad:setVisible(self.list.selectedIndex ~= #self.filenames)
end
function ModHubScreenshotDialog:onClickBack(_, usedMenuButton)
    return usedMenuButton and true or self:close()
end