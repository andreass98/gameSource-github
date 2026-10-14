AnimalTradingDialog = {}
local AnimalTradingDialog_mt = Class(AnimalTradingDialog, MessageDialog)
function AnimalTradingDialog.register()
    local animalTradingDialog = AnimalTradingDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/AnimalTradingDialog.xml", "AnimalTradingDialog", animalTradingDialog)
    AnimalTradingDialog.INSTANCE = animalTradingDialog
end
function AnimalTradingDialog.show(callback, target, animalIndex, isHorse, infoIcon, maxAnimals, isBuying, selectionState, getPriceFunc, buyText, sellText)
    if AnimalTradingDialog.INSTANCE ~= nil then
        local dialog = AnimalTradingDialog.INSTANCE
        dialog:setCallback(callback, target)
        dialog:setAnimalIndex(animalIndex)
        dialog:setIsHorse(isHorse)
        dialog:setInfoIcon(infoIcon)
        dialog:setMaxAnimals(maxAnimals)
        dialog:setIsBuying(isBuying)
        dialog:setSelectionState(selectionState)
        dialog:setGetPriceFunc(getPriceFunc)
        dialog:setButtonTexts(buyText, sellText, nil)
        g_gui:showDialog("AnimalTradingDialog")
    end
end
function AnimalTradingDialog.new(target, custom_mt)
    -- upvalues: (copy) AnimalTradingDialog_mt
    local self = YesNoDialog.new(target, custom_mt or AnimalTradingDialog_mt)
    self.inputDelay = 250
    return self
end
function AnimalTradingDialog.createFromExistingGui(gui, guiName)
    local newGui = AnimalTradingDialog.new()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    AnimalTradingDialog.show(gui.callbackFunc, gui.target, gui.animalIndex, gui.target.isHorse, gui.infoIcon, gui.maxAnimals, gui.buying, gui.selectionState, gui.getPrice)
    return newGui
end
function AnimalTradingDialog:onCreate()
    AnimalTradingDialog:superClass().onCreate(self)
    self.numAnimalsElement:setTexts({ "1" })
    self.defaultBuyText = self.buyButton.text
    self.defaultSellText = self.sellButton.text
    self.defaultCancelText = self.backButton.text
end
function AnimalTradingDialog:onOpen()
    AnimalTradingDialog:superClass().onOpen(self)
    self.inputDelay = self.time + 250
    self:updatePrice()
end
function AnimalTradingDialog:onClose()
    self:setDialogType(DialogElement.TYPE_QUESTION)
    self:setText(nil)
    self:setButtonTexts(self.defaultYesText, self.defaultNoText)
    AnimalTradingDialog:superClass().onClose(self)
end
function AnimalTradingDialog:sendCallback(tradeAccepted)
    if self.inputDelay >= self.time then
        return true
    end
    self:close()
    if self.callbackFunc ~= nil then
        local numAnimals = self.numAnimalsElement:getState()
        if self.target == nil then
            self.callbackFunc(self.buying, tradeAccepted, self.animalIndex, numAnimals)
        else
            self.callbackFunc(self.target, self.buying, tradeAccepted, self.animalIndex, numAnimals)
        end
    end
    return false
end
function AnimalTradingDialog:setCallback(callbackFunc, target, args)
    self.callbackFunc = callbackFunc
    self.target = target
    self.callbackArgs = args
end
function AnimalTradingDialog:setButtonTexts(buyText, sellText, cancelText)
    self.buyButton:setText(Utils.getNoNil(buyText, self.defaultBuyText))
    self.sellButton:setText(Utils.getNoNil(sellText, self.defaultSellText))
    self.backButton:setText(Utils.getNoNil(cancelText, self.defaultCancelText))
end
function AnimalTradingDialog:setAnimalIndex(animalIndex)
    self.animalIndex = animalIndex
end
function AnimalTradingDialog:setIsHorse(isHorse)
    if isHorse then
        self.numAnimalsElement:setVisible(false)
    else
        self.numAnimalsElement:setVisible(true)
        FocusManager:setFocus(self.numAnimalsElement)
    end
end
function AnimalTradingDialog:setInfoIcon(infoIcon)
    self.infoIcon:setImageFilename(infoIcon.overlay.filename)
end
function AnimalTradingDialog:setMaxAnimals(maxAnimals)
    self.maxAnimals = maxAnimals
    local texts = {}
    local i = 1
    for i = i, self.maxAnimals do
        table.insert(texts, (tostring(i)))
    end
    self.numAnimalsElement:setTexts(texts)
    self.numAnimalsElement:setState(1)
end
function AnimalTradingDialog:setIsBuying(buying)
    self.buying = buying
    self.buyButton:setVisible(self.buying)
    self.sellButton:setVisible(not self.buying)
end
function AnimalTradingDialog:setSelectionState(selectionState)
    self.selectionState = selectionState
end
function AnimalTradingDialog:setGetPriceFunc(getPriceFunc)
    self.getPrice = getPriceFunc
end
function AnimalTradingDialog:setTitle() end
function AnimalTradingDialog:updatePrice()
    local hasCosts, price, fee, total = self.getPrice(self.target, self.numAnimalsElement:getState())
    self.infoPrice:setValue(0)
    self.infoFee:setValue(0)
    self.infoTotal:setValue(0)
    self.infoPrice:setFormat(hasCosts and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
    self.infoFee:setFormat(hasCosts and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
    self.infoTotal:setFormat(hasCosts and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
    self.infoPrice:setValue(hasCosts and price and price or "-")
    self.infoFee:setValue(hasCosts and fee and fee or "-")
    self.infoTotal:setValue(hasCosts and total and total or "-")
end
function AnimalTradingDialog:onClickNumAnimals(_)
    local texts = {}
    local i = 1
    for i = i, self.maxAnimals do
        table.insert(texts, (tostring(i)))
    end
    self.numAnimalsElement:setTexts(texts)
    self:updatePrice()
end
function AnimalTradingDialog:onBuy(_)
    self:sendCallback(true)
end
function AnimalTradingDialog:onSell(_)
    self:sendCallback(true)
end
function AnimalTradingDialog:onClickBack(_)
    self:sendCallback(false)
end