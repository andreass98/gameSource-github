AchievementsScreen = {}
local AchievementsScreen_mt = Class(AchievementsScreen, ScreenElement)
function AchievementsScreen.register()
    local achievementsScreen = AchievementsScreen.new()
    g_gui:loadGui("dataS/gui/AchievementsScreen.xml", "AchievementsScreen", achievementsScreen)
    return achievementsScreen
end
function AchievementsScreen.new(target, custom_mt)
    -- upvalues: (copy) AchievementsScreen_mt
    local self = ScreenElement.new(target, custom_mt or AchievementsScreen_mt)
    self.achievements = {}
    self.needAchievementSync = false
    self:setReturnScreenClass(MainScreen)
    return self
end
function AchievementsScreen.createFromExistingGui(gui, guiName)
    local newGui = AchievementsScreen.new()
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    return newGui
end
function AchievementsScreen:onOpen()
    AchievementsScreen:superClass().onOpen(self)
    if Platform.hasMainScreenLanguageSelection then
        self.changeLanguageButton:setVisible(true)
        self.buttonBox:invalidateLayout()
    end
    if self:checkAchievementSynchronization() then
        self:getAchievements()
    else
        self:assignAchievementsStatsValue(false)
        self.achievementList:reloadData()
    end
    self:updateTheme()
    FocusManager:setFocus(self.achievementList)
    g_messageCenter:subscribe(MessageType.INSETS_CHANGED, self.updateInsets, self)
end
function AchievementsScreen:onClose()
    g_messageCenter:unsubscribe(MessageType.INSETS_CHANGED, self)
    AchievementsScreen:superClass().onClose(self)
end
function AchievementsScreen:updateInsets()
    local _, rightInset, _, _ = getSafeFrameInsets()
    self.contentBox:setSize(1 - rightInset, 1)
    self.contentBox:updateAbsolutePosition()
    local listPosX = self.achievementList.absPosition[1]
    local maxPosX = 1 - rightInset
    if maxPosX < listPosX + self.achievementList.absSize[1] then
        self.achievementList.absSize[1] = maxPosX - listPosX
    end
    self.achievementList:updateView()
end
function AchievementsScreen:getAchievements()
    self.achievements = g_achievementManager.achievementList
    self:assignAchievementsStatsValue(true)
    self.achievementList:reloadData()
end
function AchievementsScreen:assignAchievementsStatsValue(achievementsAvailable)
    self.statsValue:setText(string.format("%d/%d", achievementsAvailable and g_achievementManager.numberOfUnlockedAchievements or 0, g_achievementManager.numberOfAchievements))
    self.statsBox:invalidateLayout()
    self.statsBoxBg:setSize(self.statsBox.flowSizes[1] + 65 * g_pixelSizeScaledX)
end
function AchievementsScreen:onCancelAchievementsSync()
    self.needAchievementSync = false
    self:changeScreen(MainScreen)
end
function AchievementsScreen:checkAchievementSynchronization()
    local _, achievementsLoaded = areAchievementsAvailable()
    if achievementsLoaded or self.needAchievementSync then
        if achievementsLoaded and self.needAchievementSync then
            self.needAchievementSync = false
            self:getAchievements()
            g_gui:closeAllDialogs()
        end
        return achievementsLoaded
    end
    self.needAchievementSync = true
    InfoDialog.show(g_i18n:getText("ui_achievementsSynchronizing"), self.onCancelAchievementsSync, self, DialogElement.TYPE_LOADING, g_i18n:getText("button_cancel"), InputAction.MENU_BACK)
    return achievementsLoaded
end
function AchievementsScreen:update(dt)
    AchievementsScreen:superClass().update(self, dt)
    if Platform.hasOnlineAchievements and getNetworkError() then
        ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
        return
    elseif getPlatformId() == PlatformId.ANDROID and not getIsUserSignedIn() then
        g_gui:changeScreen(nil, MainScreen)
    else
        self:checkAchievementSynchronization()
    end
end
function AchievementsScreen:updateTheme()
    local filename = Platform.gameLogos[g_languageShort]
    if filename == nil then
        filename = Platform.gameLogos.en
    end
    if self.logo ~= nil then
        self.logo:setImageFilename(filename)
    end
end
function AchievementsScreen:getNumberOfItemsInSection(_, _)
    return #self.achievements
end
function AchievementsScreen:populateCellForItemInSection(_, _, index, cell)
    local achievement = self.achievements[index]
    cell:setDisabled(not achievement.unlocked)
    cell:getAttribute("title"):setText(achievement.name)
    cell:getAttribute("description"):setText(achievement.description)
    local icon = cell:getAttribute("icon")
    if achievement.unlocked then
        icon:setImageFilename(achievement.imageFilename)
        local v0, u0, v1, u1, v2, u2, v3, u3 = unpack(achievement.imageUVs)
        icon:setImageUVs(nil, v0, u0, v1, u1, v2, u2, v3, u3)
    else
        local v0, u0 = g_achievementManager:getLockedImageData()
        icon:setImageFilename(v0)
        local v1, u1, v2, u2, v3, u3, v3, u3 = unpack(u0)
        icon:setImageUVs(nil, v1, u1, v2, u2, v3, u3, v3, u3)
    end
end