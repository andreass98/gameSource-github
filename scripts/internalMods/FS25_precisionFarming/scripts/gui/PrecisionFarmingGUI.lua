PrecisionFarmingGUI = {}
PrecisionFarmingGUI.MOD_NAME = g_currentModName
PrecisionFarmingGUI.MOD_DIR = g_currentModDirectory
function PrecisionFarmingGUI.loadAdditionalGUI(filename, parentTarget, parentElement)
    local newElement = nil
    local xmlFile = loadXMLFile("Temp", PrecisionFarmingGUI.MOD_DIR .. filename)
    if xmlFile ~= nil and xmlFile ~= 0 then
        if parentElement ~= nil then
            g_gui:loadProfileSet(xmlFile, "GUI.GuiProfiles", g_gui.presets)
            g_gui:loadGuiRec(xmlFile, "GUI", parentElement, parentTarget)
            parentElement.elements[#parentElement.elements]:updateAbsolutePosition()
            parentTarget:exposeControlsAsFields()
            parentTarget:onGuiSetupFinished()
        end
        delete(xmlFile)
    end
    return newElement
end
function PrecisionFarmingGUI.initializeGUI()
    g_gui:loadProfiles(PrecisionFarmingGUI.MOD_DIR .. "gui/guiProfiles.xml")
    g_overlayManager:addTextureConfigFile(PrecisionFarmingGUI.MOD_DIR .. "gui/ui_elements.xml", "precisionFarming")
    g_overlayManager:addTextureConfigFile(PrecisionFarmingGUI.MOD_DIR .. "gui/helplinePrecisionFarmingSmall.xml", "precisionFarmingHelplineSmall")
end
if g_gui ~= nil then
    PrecisionFarmingGUI.initializeGUI()
end