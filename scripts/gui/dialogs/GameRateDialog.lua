GameRateDialog = {}
local GameRateDialog_mt = Class(GameRateDialog, MessageDialog)
function GameRateDialog.register()
    local gameRateDialog = GameRateDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/GameRateDialog.xml", "GameRateDialog", gameRateDialog)
end
function GameRateDialog.show()
    g_gui:showDialog("GameRateDialog")
end
function GameRateDialog.new(target, custom_mt)
    -- upvalues: (copy) GameRateDialog_mt
    local self = MessageDialog.new(target, custom_mt or GameRateDialog_mt)
    self.isBackAllowed = false
    self.inputDelay = 250
    self.value = 0
    return self
end
function GameRateDialog.createFromExistingGui(gui, guiName)
    GameRateDialog.register()
    GameRateDialog.show()
end
function GameRateDialog:onOpen()
    GameRateDialog:superClass().onOpen(self)
    self:setValue(0)
    FocusManager:setFocus(self.ratingLayout)
end
function GameRateDialog:onClose()
    GameRateDialog:superClass().onClose(self)
end
function GameRateDialog:onClickOk()
    self:close()
    openWebFile(Platform.urlRating, "rating=" .. self.value)
    return true
end
function GameRateDialog:onClickBack()
    self:close()
    return true
end
function GameRateDialog.onStarHighlight(_, element)
    FocusManager:setFocus(element)
end
function GameRateDialog:onStarHighlightRemove()
    self:setStars(self.value)
end
function GameRateDialog:onStarFocus(element)
    self:setValue((self:getValueForElement(element)))
end
function GameRateDialog:onStarClick(element)
    self:setValue(self:getValueForElement(element))
end
function GameRateDialog:setValue(value)
    self.value = value or 5
    self:setStars(self.value)
    if self.stars ~= 0 then
        FocusManager:setFocus(self.stars[value])
    end
    self.okButton:setDisabled(self.value == 0)
end
function GameRateDialog:setStars(value)
    local i = 1
    for i = i, value do
        self.stars[i]:applyProfile("gameRateDialogStarButtonActive")
    end
    local i = value + 1
    for i = i, 5 do
        self.stars[i]:applyProfile("gameRateDialogStarButton")
    end
end
function GameRateDialog:getValueForElement(element)
    for i, elem in ipairs(self.stars) do
        if element == elem then
            return i
        end
    end
    return nil
end