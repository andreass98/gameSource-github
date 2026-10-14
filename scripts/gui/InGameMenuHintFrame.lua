InGameMenuHintFrame = {}
local InGameMenuHintFrame_mt = Class(InGameMenuHintFrame, TabbedMenuFrameElement)
function InGameMenuHintFrame.register()
    local inGameMenuHintFrame = InGameMenuHintFrame.new()
    g_gui:loadGui("dataS/gui/InGameMenuHintFrame.xml", "HintFrame", inGameMenuHintFrame, true)
end
function InGameMenuHintFrame.new(target, custom_mt)
    -- upvalues: (copy) InGameMenuHintFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuHintFrame_mt)
    self.hasCustomMenuButtons = true
    return self
end
function InGameMenuHintFrame.createFromExistingGui(gui, guiName)
    local newGui = InGameMenuHintFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function InGameMenuHintFrame:delete()
    self.contentItem:delete()
    self.controlItem:delete()
    InGameMenuHintFrame:superClass().delete(self)
end
function InGameMenuHintFrame:initialize()
    self.contentItem:unlinkElement()
    self.controlItem:unlinkElement()
end
function InGameMenuHintFrame:onFrameOpen()
    InGameMenuHintFrame:superClass().onFrameOpen(self)
    self:updateContents()
    self.layout:registerActionEvents()
    self.menuButtonInfo = {
        {
            ["inputAction"] = InputAction.MENU_BACK
        }
    }
end
function InGameMenuHintFrame:onFrameClose()
    self.layout:removeActionEvents()
    InGameMenuHintFrame:superClass().onFrameClose(self)
end
function InGameMenuHintFrame:updateContents()
    self.headerText:setLocaKey("ui_hint")
    local i = #self.layout.elements
    local hints = 1
    for i = i, hints, -1 do
        self.layout.elements[i]:delete()
    end
    self.layout:invalidateLayout()
    local hints = g_currentMission.introductionHelpSystem:getShownHints()
    local _, i = getNormalizedScreenValues(0, 60)
    for index, hintText in ipairs(hints) do
        local row = self.contentItem:clone(self.layout)
        local textElement = row:getDescendantByName("text")
        row:applyProfile(index == #hints and "hintMenuItemCurrent" or (index % 2 == 1 and "hintMenuItemAlt" or "hintMenuItem"))
        textElement:setText(hintText)
        local height = textElement:getTextHeight()
        textElement:setSize(nil, height)
        row:setSize(nil, height + i)
    end
    self.layout:invalidateLayout()
    self.layout:scrollToEnd()
end