MobileSettingsScreen = {}
MobileSettingsScreen.CLOUD_SYNC = { "cloudSync_wifiOnly", "cloudSync_always" }
local MobileSettingsScreen_mt = Class(MobileSettingsScreen, ScreenElement)
function MobileSettingsScreen.register()
    local MobileSettingsScreen = MobileSettingsScreen.new()
    g_gui:loadGui("dataS/gui/MobileSettingsScreen.xml", "MobileSettingsScreen", MobileSettingsScreen)
    return MobileSettingsScreen
end
function MobileSettingsScreen.new(target, custom_mt)
    -- upvalues: (copy) MobileSettingsScreen_mt
    local self = ScreenElement.new(target, custom_mt or MobileSettingsScreen_mt)
    self:setReturnScreenClass(MainScreen)
    return self
end
function MobileSettingsScreen.createFromExistingGui(gui, guiName)
    local newGui = MobileSettingsScreen.new()
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    return newGui
end
function MobileSettingsScreen:onOpen()
    MobileSettingsScreen:superClass().onOpen(self)
    if Platform.isMobile then
        local mainContainerSize = (g_screenWidth - self.sidebar.absSize[1] * g_screenWidth - 50) * g_pixelSizeX
        self.mainContainer:setSize(mainContainerSize)
        self.languageText:setSize(mainContainerSize - 110 * g_pixelSizeX)
        self.contentContainer:setSize(mainContainerSize - 100 * g_pixelSizeX, (g_screenHeight - 250) * g_pixelSizeY)
        self.contentContainer:setAnchors(0, 1 - (mainContainerSize - self.contentContainer.absSize[1]), 1 - self.contentContainer.absSize[2], 1)
        self.mainContainer.absPosition[1] = 1 - mainContainerSize
        self.mainContainer:setAnchors(self.mainContainer.absPosition[1], 1, 0, 1)
        self.mainContainer:updateAbsolutePosition()
    end
    self:updateTheme()
    self.languageElement:setTexts(g_settingsModel:getLanguageTexts())
    self.languageElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.LANGUAGE))
    if getPlatformId() == PlatformId.ANDROID then
        self.achievementsButton:setDisabled(not getIsUserSignedIn())
    end
    local mainContainerSize = false
    local texts = {}
    for _, setting in pairs(MobileSettingsScreen.CLOUD_SYNC) do
        table.insert(texts, g_i18n:getText(setting))
    end
    self.cloudSyncElement:setTexts(texts)
    self.cloudSyncElement:setVisible(Platform.hasCloudSyncSetting and mainContainerSize)
    self.cloudSyncText:setVisible(Platform.hasCloudSyncSetting and mainContainerSize)
    self.contentContainer:invalidateLayout()
end
function MobileSettingsScreen:updateTheme()
    local filename = Platform.gameLogos[g_languageShort]
    if filename == nil then
        filename = Platform.gameLogos.en
    end
    if self.logo ~= nil then
        self.logo:setImageFilename(filename)
    end
end
function MobileSettingsScreen:onCareerClick(element)
    self:changeScreen(MainScreen)
    FocusManager:setFocus(g_mainScreen.careerButton)
    g_mainScreen:onCareerClick(element)
end
function MobileSettingsScreen:onAchievementsClick(element)
    self:changeScreen(AchievementsScreen)
    FocusManager:setFocus(g_mainScreen.achievementsButton)
    g_mainScreen:onAchievementsClick(element)
end
function MobileSettingsScreen:onCreditsClick(element)
    self:changeScreen(MainScreen)
    FocusManager:setFocus(g_mainScreen.creditsButton)
    g_mainScreen:onCreditsClick(element)
end
function MobileSettingsScreen:onClickOk()
    local languageChanged = setLanguage(g_availableLanguagesTable[self.languageElement.state])
    local message = g_i18n:getText("ui_languageChangeFailed")
    if languageChanged then
        message = string.format(g_i18n:getText("ui_languageChange"), self.languageElement.texts[self.languageElement.state])
    end
    InfoDialog.show(message, function(languageChanged)
        if languageChanged then
            doRestart(false, "")
        end
    end, nil, DialogElement.TYPE_INFO)
end