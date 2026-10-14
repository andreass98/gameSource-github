ShopOthersFrame = {}
ShopOthersFrame.NUM_GAMEPLAY_HINTS = 4
local ShopOthersFrame_mt = Class(ShopOthersFrame, TabbedMenuFrameElement)
function ShopOthersFrame.register()
    local shopOthersFrame = ShopOthersFrame.new()
    g_gui:loadGui("dataS/gui/ShopOthersFrame.xml", "ShopOthersFrame", shopOthersFrame, true)
end
function ShopOthersFrame.new(target, custom_mt)
    -- upvalues: (copy) ShopOthersFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or ShopOthersFrame_mt)
    self.headerLabelText = ""
    self.gameplayHintsInitialized = false
    self.gameplayHintDuration = 6500
    self.gameplayHintTime = self.gameplayHintDuration
    return self
end
function ShopOthersFrame.createFromExistingGui(gui, guiName)
    local newGui = ShopOthersFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function ShopOthersFrame:initialize(categorySelectedCallback, headerText, headerIconSlice)
    self.headerLabelText = headerText
    self.notifySelectedCategoryCallback = categorySelectedCallback
    if self.categoryHeaderText ~= nil then
        self.categoryHeaderText:setText(headerText)
        self.categoryHeaderText:updateAbsolutePosition()
        self.categoryHeaderIcon:setImageSlice(nil, headerIconSlice)
    end
    self:setTitle(headerText)
end
function ShopOthersFrame:onFrameOpen()
    ShopOthersFrame:superClass().onFrameOpen(self)
    self.notifySelectedCategoryCallback(nil)
    if g_gameplayHintManager:getIsLoaded() then
        local hints = g_gameplayHintManager:getRandomGameplayHint(InGameMenuSaveFrame.NUM_GAMEPLAY_HINTS)
        if hints ~= nil then
            local texts = {}
            for _, hint in ipairs(hints) do
                local text = string.gsub(hint, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
                table.insert(texts, text)
            end
            self.gameplayHintsInitialized = true
            self.gameplayHintSelector:setTexts(texts)
            self.hintStateBox:setPageCount(InGameMenuSaveFrame.NUM_GAMEPLAY_HINTS)
        end
        self.gameplayHintTime = self.gameplayHintDuration
    end
end
function ShopOthersFrame:onFrameClose()
    ShopOthersFrame:superClass().onFrameClose(self)
    self:setSoundSuppressed(true)
end
function ShopOthersFrame:update(dt)
    ShopOthersFrame:superClass().update(self, dt)
    if self.gameplayHintsInitialized then
        self.gameplayHintTime = self.gameplayHintTime - dt
        if self.gameplayHintTime <= 0 then
            self.gameplayHintTime = self.gameplayHintDuration
            self.gameplayHintSelector.soundDisabled = true
            self.gameplayHintSelector:onRightButtonClicked(nil, true)
            self.gameplayHintSelector.soundDisabled = false
            return
        end
    elseif g_gameplayHintManager:getIsLoaded() then
        local hints = g_gameplayHintManager:getRandomGameplayHint(ShopOthersFrame.NUM_GAMEPLAY_HINTS)
        if hints ~= nil then
            local texts = {}
            for _, hint in ipairs(hints) do
                local text = string.gsub(hint, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
                table.insert(texts, text)
            end
            self.gameplayHintsInitialized = true
            self.gameplayHintSelector:setTexts(texts)
            self.hintStateBox:setPageCount(ShopOthersFrame.NUM_GAMEPLAY_HINTS)
        end
        self.gameplayHintTime = self.gameplayHintDuration
    end
end
function ShopOthersFrame:updateMenuButtons()
    g_shopMenu:updateButtonsPanel(g_shopMenu.pageShopOthers)
end
function ShopOthersFrame:onButtonFocused(button)
    FocusManager:linkElements(self.gameplayHintSelector, FocusManager.TOP, button)
    FocusManager:linkElements(self.gameplayHintSelector, FocusManager.BOTTOM, button)
end
function ShopOthersFrame:onMenuAccept()
    local focusedButton = FocusManager:getFocusedElement()
    if focusedButton.onClickCallback ~= nil then
        focusedButton:onClickCallback()
    end
end
function ShopOthersFrame:onOpenAnimalDealer()
    AnimalScreen.show(nil, nil, true)
end
function ShopOthersFrame:onOpenWardrobeScreen()
    g_gui:changeScreen(nil, WardrobeScreen)
end
function ShopOthersFrame:onOpenConstructionScreen()
    g_gui:changeScreen(nil, ConstructionScreen)
end
function ShopOthersFrame:onOpenFarmlandScreen()
    g_gui:changeScreen(nil, InGameMenu)
    g_inGameMenu:openFarmlandsScreen()
end
function ShopOthersFrame:onOpenVehicleOverview()
    g_gui:changeScreen(nil, InGameMenu)
    g_inGameMenu:onOpenVehicleOverview()
end