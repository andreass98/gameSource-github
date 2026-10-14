HelplineExtension = {}
HelplineExtension.MOD_NAME = g_currentModName
HelplineExtension.MOD_DIR = g_currentModDirectory
HelplineExtension.GUI_EXT_XML = g_currentModDirectory .. "gui/HelpFrameSeedRateExtension.xml"
local HelplineExtension_mt = Class(HelplineExtension)
function HelplineExtension.new(pfModule, customMt)
    -- upvalues: (copy) HelplineExtension_mt
    local self = setmetatable({}, customMt or HelplineExtension_mt)
    self.pfModule = pfModule
    return self
end
function HelplineExtension:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
    return true
end
function HelplineExtension:delete()
    if self.precisionFarmingSeedRateContainer ~= nil then
        self.precisionFarmingSeedRateContainer:delete()
        self.precisionFarmingSeedRateContainer = nil
    end
end
function HelplineExtension:getAllowFirstTimeEvent()
    return not g_currentMission.hud:isInGameMessageVisible() and not g_gui:getIsGuiVisible()
end
function HelplineExtension:onFirstTimeRun()
    YesNoDialog.show(self.onFirstTimeRunDialog, self, g_i18n:getText("precisionFarming_firstStart", HelplineExtension.MOD_NAME))
end
function HelplineExtension:onFirstTimeRunDialog(yes)
    if yes then
        self:openHelpMenu(1)
    end
end
function HelplineExtension.openHelpMenu(_, offsetIndex)
    if g_gui.currentGuiName ~= "InGameMenu" then
        g_gui:showGui("InGameMenu")
    end
    if g_currentMission ~= nil then
        g_inGameMenu:openHelpLine(1, 1)
        g_inGameMenu.pageHelpLine:openPage(1, offsetIndex, HelplineExtension.MOD_NAME)
    end
end
function HelplineExtension:fillSeedRateRows(contentBox, template)
    if self.pfModule.seedRateMap ~= nil then
        self.pfModule.seedRateMap:createHelpMenuSeedRateTable(contentBox, template)
    end
end
function HelplineExtension.overwriteGameFunctions(helplineExtension, pfModule)
    pfModule:overwriteGameFunction(InGameMenuHelpFrame, "updateContents", function(superFunc, _self, page)
        -- upvalues: (copy) helplineExtension, (copy) helplineExtension
        superFunc(_self, page)
        if #page.paragraphs > 0 then
            local lastParagraph = page.paragraphs[#page.paragraphs]
            if lastParagraph.text == "$l10n_helpText_07_part03" and lastParagraph.customEnvironment == HelplineExtension.MOD_NAME then
                helplineExtension:fillSeedRateRows(_self.helpLineContentBox, helplineExtension.precisionFarmingSeedRateRowTemplate)
            end
        end
    end)
    pfModule:overwriteGameFunction(InGameMenuHelpFrame, "onFrameOpen", function(superFunc, _self)
        -- upvalues: (copy) helplineExtension
        if helplineExtension.precisionFarmingSeedRateContainer == nil then
            helplineExtension.precisionFarmingSeedRateContainer = PrecisionFarmingGUI.loadAdditionalGUI("gui/HelpFrameSeedRateExtension.xml", _self, _self.elements[1])
            helplineExtension.precisionFarmingSeedRateContainer:unlinkElement()
            helplineExtension.precisionFarmingSeedRateContainer:setVisible(false)
            helplineExtension.precisionFarmingSeedRateRowTemplate = helplineExtension.precisionFarmingSeedRateContainer.elements[1]
        end
        superFunc(_self)
    end)
end