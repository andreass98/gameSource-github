InGameMenuMultiplayerFrame = {}
local InGameMenuMultiplayerFrame_mt = Class(InGameMenuMultiplayerFrame, TabbedMenuFrameElement)
InGameMenuMultiplayerFrame.ELEMENT_NAME = {
    ["ROW_PLAYER_NAME"] = "playerName",
    ["ROW_FARM_NAME"] = "farmName",
    ["ROW_FARM_COLOR"] = "farmColor"
}
InGameMenuMultiplayerFrame.TRANSFER_AMOUNT = {
    ["SMALL"] = 5000,
    ["MEDIUM"] = 50000,
    ["LARGE"] = 250000
}
InGameMenuMultiplayerFrame.ELEMENT_NAME = {
    ["ROW_PLAYER_NAME"] = "playerName",
    ["ROW_FARM_NAME"] = "farmName",
    ["ROW_FARM_COLOR"] = "farmColor"
}
InGameMenuMultiplayerFrame.TRANSFER_AMOUNT = {
    ["SMALL"] = 5000,
    ["MEDIUM"] = 50000,
    ["LARGE"] = 250000
}
InGameMenuMultiplayerFrame.SUB_CATEGORY_FARMS = 1
InGameMenuMultiplayerFrame.SUB_CATEGORY_USERS = 2
function InGameMenuMultiplayerFrame.register()
    local inGameMenuMultiplayerFrame = InGameMenuMultiplayerFrame.new()
    g_gui:loadGui("dataS/gui/InGameMenuMultiplayerFrame.xml", "MultiplayerFrame", inGameMenuMultiplayerFrame, true)
end
function InGameMenuMultiplayerFrame.new(target, custom_mt)
    -- upvalues: (copy) InGameMenuMultiplayerFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuMultiplayerFrame_mt)
    self.currentUser = User.new()
    self.playerFarm = nil
    self.player = nil
    self.playerFarm = nil
    self.hasAskedForPassword = false
    self.timeSinceLastMoneyUpdate = 0
    self.elementFarmIdMap = {}
    self.farmIdBalanceMap = {}
    self.farmIdPlayerCountMap = {}
    self.newFarmListIndex = 0
    self.hasCustomMenuButtons = true
    self.menuButtonInfo = {}
    self.selectedUserId = nil
    self.selectedUserFarm = nil
    self.isNavigatingUsers = false
    self.users = {}
    self.listRowUser = {}
    self.permissionCheckboxes = {}
    self.checkboxPermissions = {}
    self.timeSinceLastRefresh = 0
    return self
end
function InGameMenuMultiplayerFrame.createFromExistingGui(gui, guiName)
    local newGui = InGameMenuMultiplayerFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function InGameMenuMultiplayerFrame:initialize()
    InGameMenuMultiplayerFrame:superClass().initialize(self)
    self.backButtonInfo = {
        ["inputAction"] = InputAction.MENU_BACK
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
    self.joinMenuButton = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_JOIN_FARM),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:joinFarm(self.selectedFarmId)
        end
    }
    self.leaveMenuButton = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_LEAVE_FARM),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:leaveFarm()
        end
    }
    self.editMenuButton = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_EDIT_FARM),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:editFarm(self.selectedFarmId)
        end
    }
    self.createMenuButton = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_CREATE_FARM),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:createFarm()
        end
    }
    self.deleteMenuButton = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_DELETE_FARM),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:deleteFarm(self.selectedFarmId)
        end
    }
    self.playerNameTemplate:unlinkElement()
    local subCategories = {}
    for index, button in pairs(self.subCategoryTabs) do
        local index
        button:getDescendantByName("background").getIsSelected = function()
            -- upvalues: (copy) index, (copy) self
            return index == self.subCategoryPaging:getState()
        end
        function button.getIsSelected()
            -- upvalues: (copy) index, (copy) self
            return index == self.subCategoryPaging:getState()
        end
        table.insert(subCategories, (tostring(index)))
    end
    self.subCategoryPaging:setTexts(subCategories)
    self.subCategoryPaging:setSize(self.subCategoryBox.maxFlowSize + 140 * g_pixelSizeScaledX)
    self:setupUserListFocusContext()
    self.unblockButtonInfo = {
        ["inputAction"] = InputAction.MENU_EXTRA_1,
        ["text"] = g_i18n:getText("button_blocklist"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonUnBan()
        end
    }
    self.unblockRemoteButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText("button_blocklist"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonUnBanRemote()
        end
    }
    self.adminButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText("button_adminLogin"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonAdminLogin()
        end
    }
    self.inviteFriendsInfo = {
        ["inputAction"] = InputAction.MENU_EXTRA_2,
        ["text"] = g_i18n:getText("ui_inviteScreen"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonInviteFriends()
        end
    }
    self.permissionCheckboxes = {
        [Farm.PERMISSION.BUY_VEHICLE] = self.buyVehiclePermissionCheckbox,
        [Farm.PERMISSION.SELL_VEHICLE] = self.sellVehiclePermissionCheckbox,
        [Farm.PERMISSION.RESET_VEHICLE] = self.resetVehiclePermissionCheckbox,
        [Farm.PERMISSION.BUY_PLACEABLE] = self.buyPlaceablePermissionCheckbox,
        [Farm.PERMISSION.SELL_PLACEABLE] = self.sellPlaceablePermissionCheckbox,
        [Farm.PERMISSION.HIRE_ASSISTANT] = self.hireAssistantPermissionCheckbox,
        [Farm.PERMISSION.MANAGE_CONTRACTS] = self.manageMissionsPermissionCheckbox,
        [Farm.PERMISSION.MANAGE_PRODUCTIONS] = self.manageProductionsPermissionCheckbox,
        [Farm.PERMISSION.TRADE_ANIMALS] = self.tradeAnimalsPermissionCheckbox,
        [Farm.PERMISSION.CUT_TREES] = self.cutTreesPermissionCheckbox,
        [Farm.PERMISSION.CREATE_FIELDS] = self.createFieldsPermissionCheckbox,
        [Farm.PERMISSION.LANDSCAPING] = self.landscapingPermissionCheckbox
    }
    self.reportReasons = {
        [ReportUserReason.PLAYER_NAME + 1] = g_i18n:getText("ui_reportPlayer_reason_name"),
        [ReportUserReason.VOICE_CHAT + 1] = g_i18n:getText("ui_reportPlayer_reason_voice"),
        [ReportUserReason.TEXT_CHAT + 1] = g_i18n:getText("ui_reportPlayer_reason_text"),
        [ReportUserReason.BEHAVIOR + 1] = g_i18n:getText("ui_reportPlayer_reason_behavior"),
        [ReportUserReason.CHEATING + 1] = g_i18n:getText("ui_reportPlayer_reason_cheating")
    }
    self.checkboxPermissions = {}
    for index, button in pairs(self.permissionCheckboxes) do
        self.checkboxPermissions[button] = index
    end
end
function InGameMenuMultiplayerFrame:delete()
    self.playerNameTemplate:delete()
    InGameMenuMultiplayerFrame:superClass().delete(self)
end
function InGameMenuMultiplayerFrame:onFrameOpen()
    InGameMenuMultiplayerFrame:superClass().onFrameOpen(self)
    g_messageCenter:subscribe(MessageType.FARM_CREATED, self.onFarmCreated, self)
    g_messageCenter:subscribe(MessageType.FARM_SETTINGS_CHANGED, self.onFarmsChanged, self)
    g_messageCenter:subscribe(MessageType.FARM_DELETED, self.onFarmsChanged, self)
    g_messageCenter:subscribe(MessageType.PLAYER_NICKNAME_CHANGED, self.onFarmsChanged, self)
    g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.onPlayerFarmChanged, self)
    g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onFarmMoneyChanged, self)
    g_messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
    g_messageCenter:subscribe(PlayerSetFarmAnswerEvent, self.onPlayerSetFarmAnswer, self)
    g_messageCenter:subscribe(PlayerPermissionsEvent, self.onPermissionChanged, self)
    g_messageCenter:subscribe(GetAdminAnswerEvent, self.onAdminLoginSuccess, self)
    g_messageCenter:subscribe(ContractingStateEvent, self.onContractingStateChanged, self)
    g_messageCenter:subscribe(MessageType.USER_ADDED, self.onUserAdded, self)
    g_messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
    self:setCurrentUserId(g_currentMission.playerUserId)
    self.subCategoryPaging:setState(1, true)
    self.selectedFarmId = nil
    if self.farmList:getItemCount() > 0 then
        local listIndex = 1
        if self.playerFarm ~= nil then
            listIndex = self:getListFarmIndex(self.playerFarm.farmId)
        end
        self.farmList:setSelectedIndex(listIndex, true)
        FocusManager:setFocus(self.farmList)
    else
        self.farmList:setDisabled(true)
        FocusManager:setFocus(self.subCategoryPaging)
    end
end
function InGameMenuMultiplayerFrame:onFrameClose()
    self.farms = {}
    g_messageCenter:unsubscribeAll(self)
    InGameMenuMultiplayerFrame:superClass().onFrameClose(self)
end
function InGameMenuMultiplayerFrame:reset()
    InGameMenuMultiplayerFrame:superClass().reset(self)
    self.currentUser = User.new()
    self.users = {}
    self.player = nil
    self.playerFarm = nil
    self.hasAskedForPassword = false
    self.elementFarmIdMap = {}
    self.farmIdBalanceMap = {}
    self.farmIdPlayerCountMap = {}
    self.newFarmListIndex = 0
end
function InGameMenuMultiplayerFrame:setupUserListFocusContext()
    function self.userList.onFocusEnter()
        -- upvalues: (copy) self
        self.isNavigatingUsers = true
        self:updateMenuButtons()
    end
    function self.userList.onFocusLeave()
        -- upvalues: (copy) self
        self.isNavigatingUsers = false
        self:updateMenuButtons()
    end
end
function InGameMenuMultiplayerFrame:setCurrentUserId(currentUserId)
    self.currentUserId = currentUserId
    self.currentUser = g_currentMission.userManager:getUserByUserId(currentUserId) or self.currentUser
    self:updateMenuButtons()
end
function InGameMenuMultiplayerFrame:setUsers(users)
    self.users = self:getSortedUsers(users)
    self.shouldRebuildUserList = true
    self:updateMenuButtons()
end
function InGameMenuMultiplayerFrame:getSortedUsers(users)
    local sortedUsers = {}
    for _, user in pairs(users) do
        if not g_currentMission.connectedToDedicatedServer or user:getId() ~= g_currentMission:getServerUserId() then
            table.insert(sortedUsers, user)
        end
    end
    table.sort(sortedUsers, function(user1, user2)
        -- upvalues: (copy) self
        local user1Id = user1:getId()
        local user2Id = user2:getId()
        if user1Id == nil and user2Id == nil then
            return false
        end
        local farm1 = g_farmManager:getFarmByUserId(user1Id)
        local farm2 = g_farmManager:getFarmByUserId(user2Id)
        if farm1 == nil and farm2 == nil then
            if user1Id == nil then
                return false
            end
            if user2Id == nil then
                return true
            end
            return user1Id < user2Id
        end
        if farm1 == nil then
            return false
        end
        if farm2 == nil then
            return true
        end
        local farm1Id = farm1.farmId
        local farm2Id = farm2.farmId
        local farm1Id = self.playerFarm ~= nil and farm1Id == self.playerFarm.farmId and -math.huge or farm1Id
        local farm2Id = self.playerFarm ~= nil and farm2Id == self.playerFarm.farmId and -math.huge or farm2Id
        local farm1Id = farm1Id == FarmManager.SPECTATOR_FARM_ID and math.huge or farm1Id
        local farm2Id = farm2Id == FarmManager.SPECTATOR_FARM_ID and math.huge or farm2Id
        if farm1Id ~= farm2Id then
            return farm1Id < farm2Id
        end
        local nickname1 = user1:getNickname()
        local nickname2 = user2:getNickname()
        if nickname1 == nickname2 then
            return true
        end
        return nickname1 < nickname2
    end)
    return sortedUsers
end
function InGameMenuMultiplayerFrame:setPlayer(player)
    self.player = player
end
function InGameMenuMultiplayerFrame:setPlayerFarm(farm)
    self.playerFarm = farm
end
function InGameMenuMultiplayerFrame:getListFarmIndex(farmId)
    if farmId ~= FarmManager.SPECTATOR_FARM_ID then
        for i, farm in ipairs(self.farms) do
            if farm.farmId == farmId then
                return i
            end
        end
    end
    return 1
end
function InGameMenuMultiplayerFrame:setFarmBalance(farmId, balance)
    if balance == nil then
        balance = g_farmManager:getFarmById(farmId):getBalance()
    end
    if self.farmIdBalanceMap[farmId] ~= nil then
        self.farmIdBalanceMap[farmId]:setValue(balance)
    end
end
function InGameMenuMultiplayerFrame:getSortedFarmList()
    local list = {}
    local farms = g_farmManager:getFarms()
    local spectatorFarm = nil
    table.insert(list, self.playerFarm)
    for _, farm in pairs(farms) do
        if not farm.isSpectator and (farm ~= self.playerFarm and farm.showInFarmScreen) then
            table.insert(list, farm)
        end
        if farm.isSpectator then
            spectatorFarm = farm
        end
    end
    if spectatorFarm:getNumActivePlayers() > 0 and spectatorFarm ~= self.playerFarm then
        table.insert(list, spectatorFarm)
    end
    return list
end
function InGameMenuMultiplayerFrame:updateElements()
    local isFarmManager = self.playerFarm:isUserFarmManager(self.currentUserId)
    local hasHighPrivilege = isFarmManager or self.currentUser:getIsMasterUser()
    local isOwnFarmSelected = self.selectedUserFarm == self.playerFarm
    local isSpectatorSelected = self.selectedUserFarm.isSpectator
    local isSelfSelected = self.selectedUserId == self.currentUserId
    local isSelectedUserFarmManager = false
    if self.selectedUserId ~= nil then
        isSelectedUserFarmManager = self.selectedUserFarm:isUserFarmManager(self.selectedUserId)
    end
    local canManageSelectedFarm = isFarmManager and isOwnFarmSelected and isOwnFarmSelected or self.currentUser:getIsMasterUser()
    local isOtherAdminSelected = false
    local selectionIsUser = self.selectedUserId ~= nil
    local user = nil
    if selectionIsUser then
        user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
        isOtherAdminSelected = false
        if user ~= nil then
            isOtherAdminSelected = false
            if self.selectedUserId ~= self.currentUserId then
                isOtherAdminSelected = user:getIsMasterUser()
            end
        end
    end
    local volumeText = not (selectionIsUser or isOwnFarmSelected)
    if volumeText then
        if isFarmManager then
            isFarmManager = not isSpectatorSelected
        end
    else
        isFarmManager = volumeText
    end
    self.transferButton:setVisible(isFarmManager)
    local volumeText = user ~= nil and (selectionIsUser and (canManageSelectedFarm and not (isSelfSelected or isSpectatorSelected)))
    if volumeText then
        local rawVolume = user:getIsMasterUser()
        if rawVolume then
            rawVolume = not self.currentUser:getIsMasterUser()
        end
        volumeText = not rawVolume
    end
    self.removeButton:setVisible(volumeText)
    local volumeText = selectionIsUser and (canManageSelectedFarm and not isSpectatorSelected)
    if volumeText then
        volumeText = not isOtherAdminSelected
    end
    self.promoteButton:setVisible(volumeText)
    local volumeText = g_i18n
    self.promoteButton:setText(volumeText:getText(isSelectedUserFarmManager and "button_mp_dimiss" or "button_mp_promote"))
    local isContracting = self.selectedUserFarm:getIsContractingFor(self.playerFarm.farmId)
    local texts = self.contractorButton
    local rawVolume = not selectionIsUser and (hasHighPrivilege and not (isOwnFarmSelected or isSpectatorSelected))
    if rawVolume then
        rawVolume = not self.playerFarm.isSpectator
    end
    texts:setVisible(rawVolume)
    local texts = self.contractorButton
    local rawVolume = g_i18n
    local i = isContracting and "button_mp_ungrant" or "button_mp_grant"
    texts:setText(rawVolume:getText(i))
    local texts = self.kickButton
    local rawVolume = selectionIsUser and not isSelfSelected
    if rawVolume then
        rawVolume = self.currentUser:getIsMasterUser()
    end
    texts:setVisible(rawVolume)
    local texts = self.blockFromServerButton
    local rawVolume = selectionIsUser and not isSelfSelected and (self.currentUser:getIsMasterUser() and not g_currentMission:getIsServer())
    if rawVolume then
        rawVolume = self.selectedUserId ~= g_currentMission:getServerUserId()
    end
    texts:setVisible(rawVolume)
    local texts = self.blockButton
    local rawVolume = selectionIsUser and not isSelfSelected
    texts:setVisible(rawVolume)
    if selectionIsUser then
        local i = (user == nil or not user:getIsBlocked()) and "button_block" or "button_unblock"
        self.blockButton:setText(g_i18n:getText(i))
    end
    local texts = self.muteButton
    local rawVolume = selectionIsUser and (isSelfSelected and VoiceChatUtil.getHasRecordingDevice())
    if rawVolume then
        rawVolume = not VoiceChatUtil.getIsVoiceRestricted()
    end
    texts:setVisible(rawVolume)
    if selectionIsUser then
        local i = (user == nil or not user:getVoiceMuted()) and "button_mute" or "button_unmute"
        self.muteButton:setText(g_i18n:getText(i))
    end
    local texts = self.peerVolumeOption
    local rawVolume = selectionIsUser and not isSelfSelected
    if rawVolume then
        rawVolume = not VoiceChatUtil.getIsVoiceRestricted()
    end
    texts:setVisible(rawVolume)
    if selectionIsUser then
        local texts = { g_i18n:getText("button_mute") }
        local volumeText = g_i18n:getText("ui_volumeSound")
        local i = 1
        for i = i, 10 do
            table.insert(texts, string.format("%s: %d%%", volumeText, i * 10))
        end
        self.peerVolumeOption:setTexts(texts)
        self.peerVolumeOption:setState(MathUtil.round((user ~= nil and user:getVoiceVolume() or 0) / 0.1 + 1, 0))
    end
    if selectionIsUser and user ~= nil then
        local rawVolume = Platform.hasNativeProfiles
        if rawVolume then
            rawVolume = getPlatformIdsAreCompatible(user:getPlatformId(), getPlatformId())
        end
        self.showProfileButton:setVisible(rawVolume)
        local rawVolume = not isSelfSelected
        if rawVolume then
            rawVolume = not (Platform.hasNativeProfiles and getPlatformIdsAreCompatible(user:getPlatformId(), getPlatformId()))
        end
        self.reportButton:setVisible(rawVolume)
    else
        self.showProfileButton:setVisible(false)
        self.reportButton:setVisible(false)
    end
    if selectionIsUser and user ~= nil then
        local texts = not isSpectatorSelected and (canManageSelectedFarm and not isSelectedUserFarmManager)
        if texts then
            texts = not user:getIsMasterUser()
        end
        local volumeText = self.selectedUserFarm:getUserPermissions(self.selectedUserId)
        for permissionKey, checkbox in pairs(self.permissionCheckboxes) do
            checkbox:setIsChecked(volumeText[permissionKey] or user:getIsMasterUser(), true)
            checkbox:setDisabled(not texts)
        end
        self.permissionsBox:setVisible(true)
        self.permissionsTitle:setVisible(true)
        if self.subCategoryPaging:getState() == InGameMenuMultiplayerFrame.SUB_CATEGORY_USERS then
            self.multiplayerSlider:setVisible(true)
        end
    else
        self.permissionsBox:setVisible(false)
        self.permissionsTitle:setVisible(false)
        if self.subCategoryPaging:getState() == InGameMenuMultiplayerFrame.SUB_CATEGORY_USERS then
            self.multiplayerSlider:setVisible(false)
        end
    end
    self.actionsBox:invalidateLayout()
    self.permissionsBox:invalidateLayout()
end
function InGameMenuMultiplayerFrame:updateMenuButtons()
    if not g_gui.currentlyReloading then
        self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
        if self.subCategoryPaging:getState() == InGameMenuMultiplayerFrame.SUB_CATEGORY_FARMS then
            if self.farmList:getIsFocused() then
                if self.selectedFarmId == nil then
                    if self.currentUser:getIsMasterUser() then
                        table.insert(self.menuButtonInfo, self.createMenuButton)
                    elseif g_currentMission ~= nil and (g_currentMission.connectedToDedicatedServer and not self.currentUser:getIsMasterUser()) then
                        table.insert(self.menuButtonInfo, self.adminButtonInfo)
                    end
                else
                    if self.selectedFarmId == self.playerFarm.farmId then
                        table.insert(self.menuButtonInfo, self.leaveMenuButton)
                    else
                        table.insert(self.menuButtonInfo, self.joinMenuButton)
                    end
                    if self.currentUser:getIsMasterUser() then
                        table.insert(self.menuButtonInfo, self.editMenuButton)
                        table.insert(self.menuButtonInfo, self.deleteMenuButton)
                    elseif g_currentMission ~= nil and (g_currentMission.connectedToDedicatedServer and not self.currentUser:getIsMasterUser()) then
                        table.insert(self.menuButtonInfo, self.adminButtonInfo)
                    end
                end
            end
        else
            if getNumOfBlockedUsers() > 0 then
                table.insert(self.menuButtonInfo, self.unblockButtonInfo)
            end
            if g_currentMission ~= nil then
                if self.currentUser:getIsMasterUser() then
                    if g_currentMission.connectedToDedicatedServer then
                        table.insert(self.menuButtonInfo, self.unblockRemoteButtonInfo)
                    end
                elseif g_currentMission ~= nil and (g_currentMission.connectedToDedicatedServer and not self.currentUser:getIsMasterUser()) then
                    table.insert(self.menuButtonInfo, self.adminButtonInfo)
                end
                if Platform.hasFriendInvitation and PlatformPrivilegeUtil.getCanInvitePlayer(g_currentMission) then
                    table.insert(self.menuButtonInfo, self.inviteFriendsInfo)
                end
            end
        end
        self:setMenuButtonInfoDirty()
    end
end
function InGameMenuMultiplayerFrame:update(dt)
    InGameMenuMultiplayerFrame:superClass().update(self, dt)
    if self.subCategoryPaging:getState() == InGameMenuMultiplayerFrame.SUB_CATEGORY_USERS then
        if self.timeSinceLastRefresh > 1000 then
            self.shouldRebuildUserList = true
        end
        self.timeSinceLastRefresh = self.timeSinceLastRefresh + dt
        if self.shouldRebuildUserList then
            self.shouldRebuildUserList = false
            self.timeSinceLastRefresh = 0
            self.sortedFarms = self:getSortedFarmList()
            self.isAutoReloading = true
            self.userList:reloadData()
            self.isAutoReloading = false
        end
    end
end
function InGameMenuMultiplayerFrame:updateDisplay()
    self.sortedFarms = self:getSortedFarmList()
    self.userList:reloadData()
    if self.selectedUserId ~= nil and self.selectedUserFarm ~= nil then
        if not self.isAutoReloading then
            self:updateElements()
        end
        self:updateMenuButtons()
    end
end
function InGameMenuMultiplayerFrame:joinFarm(farmId)
    local currentFarmId = self.playerFarm.farmId
    if self.playerFarm ~= nil and farmId ~= currentFarmId then
        if currentFarmId ~= FarmManager.SPECTATOR_FARM_ID then
            local text = string.format(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.LEAVE_FARM_CONFIRM), self.playerFarm.name)
            local title = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_LEAVE_FARM)
            YesNoDialog.show(self.doJoinFarm, self, text, title)
            return
        end
        self:doJoinFarm(true, farmId)
    end
end
function InGameMenuMultiplayerFrame:doJoinFarm(yesNo)
    if yesNo then
        local farm = g_farmManager:getFarmById(self.selectedFarmId)
        g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(self.player, self.selectedFarmId, farm.password))
    end
end
function InGameMenuMultiplayerFrame:leaveFarm()
    local text = string.format(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.LEAVE_FARM_CONFIRM), self.playerFarm.name)
    local title = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_LEAVE_FARM)
    YesNoDialog.show(self.doLeaveFarm, self, text, title)
end
function InGameMenuMultiplayerFrame:doLeaveFarm(yesNo)
    if yesNo then
        g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(self.player, FarmManager.SPECTATOR_FARM_ID))
    end
end
function InGameMenuMultiplayerFrame:deleteFarm(farmId)
    local canDestroy, messageCannotDestroy = g_farmManager:getFarmById(farmId):canBeDestroyed()
    if canDestroy then
        local text = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DELETE_FARM_CONFIRM)
        local title = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_DELETE_FARM)
        YesNoDialog.show(self.onDeleteFarmYesNo, self, text, title)
    else
        InfoDialog.show(g_i18n:getText(messageCannotDestroy))
    end
end
function InGameMenuMultiplayerFrame.editFarm(_, farmId)
    EditFarmDialog.show(farmId)
end
function InGameMenuMultiplayerFrame:createFarm()
    EditFarmDialog.show()
end
function InGameMenuMultiplayerFrame:reloadFarms()
    self.farms = {}
    local farms = g_farmManager:getFarms()
    for _, farm in ipairs(farms) do
        if farm.showInFarmScreen then
            table.insert(self.farms, farm)
        end
    end
    self.farmList:reloadData()
    if self.subCategoryPaging:getState() == InGameMenuMultiplayerFrame.SUB_CATEGORY_FARMS then
        if self.farmList:getItemCount() == 0 then
            self.farmList:setVisible(false)
            self.farmList:setDisabled(true)
            self.multiplayerSlider:setVisible(false)
        else
            self.farmList:setVisible(true)
            self.farmList:setDisabled(false)
            self.multiplayerSlider:setVisible(true)
        end
        self.noFarmsText:setVisible(#self.farms == 0 and not self.currentUser:getIsMasterUser())
    end
end
function InGameMenuMultiplayerFrame:onPlayerSetFarmAnswer(answerState, farmId, password)
    if answerState == PlayerSetFarmAnswerEvent.STATE.OK then
        g_farmManager:getFarmById(farmId).password = password
        self.hasAskedForPassword = false
        self.farmList:setSelectedIndex(self:getListFarmIndex(farmId))
    elseif answerState == PlayerSetFarmAnswerEvent.STATE.PASSWORD_REQUIRED then
        if not self.hasAskedForPassword then
            self.hasAskedForPassword = true
            PasswordDialog.show(self.onFarmPasswordEntered, self, farmId, "", g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_JOIN_FARM))
            return
        end
        InfoDialog.show(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.WRONG_PASSWORD))
        self.hasAskedForPassword = false
    end
end
function InGameMenuMultiplayerFrame:onFarmPasswordEntered(password, hasConfirmed, farmId)
    if hasConfirmed then
        g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(self.player, farmId, password))
    else
        self.hasAskedForPassword = false
    end
end
function InGameMenuMultiplayerFrame:onPermissionChanged(userId)
    if userId == self.currentUserId then
        self:updateMenuButtons()
    end
    self:updateDisplay()
end
function InGameMenuMultiplayerFrame:onFarmCreated(newFarmId)
    self:reloadFarms()
    if self.currentUser:getIsMasterUser() then
        local newIndex = self:getListFarmIndex(newFarmId)
        self.farmList:setSelectedIndex(newIndex, true)
    end
end
function InGameMenuMultiplayerFrame:onFarmsChanged(_)
    self:reloadFarms()
    self:updateDisplay()
    self:onListSelectionChanged(self.userList, self.userList:getSelectedPath())
end
function InGameMenuMultiplayerFrame:onPlayerFarmChanged(_)
    self:reloadFarms()
    self:updateDisplay()
    self:updateMenuButtons()
end
function InGameMenuMultiplayerFrame:onFarmMoneyChanged(farmId, balance)
    if self.farmIdBalanceMap[farmId] ~= nil then
        self.farmIdBalanceMap[farmId]:setValue(balance)
    end
end
function InGameMenuMultiplayerFrame:onMasterUserAdded(_)
    self:reloadFarms()
    self:updateDisplay()
    self:updateMenuButtons()
end
function InGameMenuMultiplayerFrame:onDoubleClickFarm(_, _, index)
    if index == self.newFarmListIndex then
        self:createFarm()
        return
    else
        local farm = self.farms[index]
        if farm == nil then
            Logging.warning("Farm does not exist anymore")
        else
            self.selectedFarmId = farm.farmId
            self:joinFarm(self.selectedFarmId)
        end
    end
end
function InGameMenuMultiplayerFrame:onDeleteFarmYesNo(yes)
    if yes and g_farmManager:getFarmById(self.selectedFarmId):canBeDestroyed() then
        g_client:getServerConnection():sendEvent(FarmDestroyEvent.new(self.selectedFarmId))
    end
end
function InGameMenuMultiplayerFrame:onClickUsers()
    self.subCategoryPaging:setState(InGameMenuMultiplayerFrame.SUB_CATEGORY_USERS, true)
    FocusManager:setFocus(self.userList)
end
function InGameMenuMultiplayerFrame:onClickFarms()
    self.subCategoryPaging:setState(InGameMenuMultiplayerFrame.SUB_CATEGORY_FARMS, true)
    if self.farmList:getItemCount() > 0 then
        FocusManager:setFocus(self.farmList)
    else
        FocusManager:setFocus(self.subCategoryPaging)
    end
end
function InGameMenuMultiplayerFrame:updateSubCategoryPages(subCategoryIndex)
    for index, page in pairs(self.subCategoryPages) do
        page:setVisible(index == subCategoryIndex)
    end
    self:reloadFarms()
    self:updateDisplay()
    if subCategoryIndex == InGameMenuMultiplayerFrame.SUB_CATEGORY_FARMS then
        self.multiplayerSlider:applyProfile("fs25_sliderDocked")
        self.multiplayerSlider:setDataElement(self.farmList)
    else
        self.multiplayerSlider:applyProfile("fs25_multiplayerSliderDocked")
        self.multiplayerSlider:setDataElement(self.permissionsBox)
    end
    self:updateMenuButtons()
end
function InGameMenuMultiplayerFrame:onButtonKick()
    if self.selectedUserId == nil or self.selectedUserId == g_currentMission:getServerUserId() then
        InfoDialog.show(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.INFO_CANNOT_KICK_SERVER))
    else
        local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
        local text = string.format(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_KICK_CONFIRM), user:getNickname())
        local title = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_KICK_TITLE)
        YesNoDialog.show(self.onYesNoKick, self, text, title)
    end
end
function InGameMenuMultiplayerFrame:onYesNoKick(yes)
    if yes then
        g_client:getServerConnection():sendEvent(KickBanEvent.new(true, self.selectedUserId))
    end
end
function InGameMenuMultiplayerFrame:onButtonUnBan()
    UnBanDialog.show(function()
        -- upvalues: (copy) self
        self:updateElements()
        self:updateMenuButtons()
    end, self, true)
end
function InGameMenuMultiplayerFrame:onButtonUnBanRemote()
    UnBanDialog.show(function()
        -- upvalues: (copy) self
        self:updateElements()
        self:updateMenuButtons()
    end, self, false)
end
function InGameMenuMultiplayerFrame:onButtonShowProfile()
    if self.selectedUserId ~= nil then
        local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
        local nickname = user:getPlatformUserId()
        if nickname == "" then
            nickname = user:getNickname()
        end
        showUserProfile(nickname)
    end
end
function InGameMenuMultiplayerFrame:onButtonInviteFriends()
    if Platform.hasFriendInvitation then
        if g_currentMission ~= nil then
            openMpFriendInvitation(#g_currentMission.userManager:getUsers(), g_currentMission.missionDynamicInfo.capacity)
            return
        end
        openMpFriendInvitation(1, 6)
    end
end
function InGameMenuMultiplayerFrame:onButtonAdminLogin()
    PasswordDialog.show(self.onAdminPassword, self, nil, "", g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.PROMPT_ADMIN_PASSWORD))
end
function InGameMenuMultiplayerFrame:onClickPermission(_, binaryOption, isLeftButton)
    self.selectedUserFarm:setUserPermission(self.selectedUserId, self.checkboxPermissions[binaryOption], not isLeftButton)
end
function InGameMenuMultiplayerFrame:onClickTransferButton()
    TransferMoneyDialog.show(self.transferMoney, self, self.selectedUserFarm)
end
function InGameMenuMultiplayerFrame:transferMoney(amount)
    if amount > 0 then
        g_farmManager:transferMoney(self.selectedUserFarm, amount)
    end
end
function InGameMenuMultiplayerFrame:onClickRemoveFromFarm()
    local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
    local text = string.format(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_REMOVE_CONFIRM), user:getNickname())
    local title = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_REMOVE_TITLE)
    YesNoDialog.show(self.onYesNoRemoveFromFarm, self, text, title)
end
function InGameMenuMultiplayerFrame:onYesNoRemoveFromFarm(yes)
    if yes then
        g_farmManager:removeUserFromFarm(self.selectedUserId)
    end
end
function InGameMenuMultiplayerFrame:onClickPromote()
    if self.selectedUserFarm:isUserFarmManager(self.selectedUserId) then
        self.selectedUserFarm:demoteUser(self.selectedUserId)
        self:updateElements()
    else
        local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
        local text = string.format(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_PROMOTE_CONFIRM), user:getNickname())
        local title = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_PROMOTE_TITLE)
        YesNoDialog.show(self.onYesNoPromoteToFarmManager, self, text, title)
    end
end
function InGameMenuMultiplayerFrame:onYesNoPromoteToFarmManager(yes)
    if yes then
        self.selectedUserFarm:promoteUser(self.selectedUserId)
        self:updateElements()
    end
end
function InGameMenuMultiplayerFrame:onClickContractor()
    local confirmTextTemplateSymbol
    if self.selectedUserFarm:getIsContractingFor(self.playerFarm.farmId) then
        confirmTextTemplateSymbol = InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_DENY_CONTRACTOR_CONFIRM
    else
        confirmTextTemplateSymbol = InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_GRANT_CONTRACTOR_CONFIRM
    end
    local text = string.format(g_i18n:getText(confirmTextTemplateSymbol), self.selectedUserFarm.name)
    local title = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_CONTRACTOR_STATE_TITLE)
    YesNoDialog.show(self.onYesNoToggleContractorState, self, text, title)
end
function InGameMenuMultiplayerFrame:onYesNoToggleContractorState(yes)
    if yes then
        local isContracting = self.selectedUserFarm:getIsContractingFor(self.playerFarm.farmId)
        self.selectedUserFarm:setIsContractingFor(self.playerFarm.farmId, not isContracting, false)
    end
end
function InGameMenuMultiplayerFrame:onUserAdded()
    self:updateDisplay()
end
function InGameMenuMultiplayerFrame:onUserRemoved()
    self:reloadFarms()
    self:updateDisplay()
end
function InGameMenuMultiplayerFrame:onContractingStateChanged()
    self:updateDisplay()
end
function InGameMenuMultiplayerFrame.onAdminPassword(_, password, yes)
    if yes then
        g_client:getServerConnection():sendEvent(GetAdminEvent.new(password))
    end
end
function InGameMenuMultiplayerFrame:onAdminLoginSuccess()
    self:updateDisplay()
    if self.playerFarm ~= nil and self.playerFarm.farmId ~= FarmManager.SPECTATOR_FARM_ID then
        self.playerFarm:promoteUser(self.currentUserId)
    end
end
function InGameMenuMultiplayerFrame:onButtonBlock()
    local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
    if user:getIsBlocked() then
        user:unblock()
        self:updateDisplay()
        return
    elseif Platform.hasNativeProfiles and getPlatformIdsAreCompatible(user:getPlatformId(), getPlatformId()) then
        user:block()
    else
        local title = g_i18n:getText("ui_doYouWantToBlockThisServer_title")
        local text = string.format(g_i18n:getText("ui_blockPlayerConfirm"), user:getNickname())
        YesNoDialog.show(function(yes)
            -- upvalues: (copy) user, (copy) self
            if yes then
                g_currentMission:banUser(user)
                self:updateDisplay()
            end
        end, nil, text, title)
    end
end
function InGameMenuMultiplayerFrame:onButtonBlockFromServer()
    local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
    local text = string.format(g_i18n:getText("ui_banConfirm"), user:getNickname())
    local title = g_i18n:getText("ui_banTitle")
    YesNoDialog.show(function(yes)
        -- upvalues: (copy) self
        if yes then
            g_client:getServerConnection():sendEvent(KickBanEvent.new(false, self.selectedUserId))
        end
    end, nil, text, title)
end
function InGameMenuMultiplayerFrame:onButtonReport()
    local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
    local title = g_i18n:getText("ui_reportPlayer_title")
    local text = string.format(g_i18n:getText("ui_reportPlayer_confirm"), user:getNickname())
    OptionDialog.show(function(item)
        -- upvalues: (copy) user
        if item > 0 then
            user:report(item - 1)
        end
    end, text, title, self.reportReasons)
end
function InGameMenuMultiplayerFrame:onButtonMute()
    local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
    if user:getVoiceMuted() then
        user:setVoiceMuted(false)
    else
        user:setVoiceMuted(true)
    end
    self:updateDisplay()
end
function InGameMenuMultiplayerFrame:onPeerVolumeChanged(state)
    g_currentMission.userManager:getUserByUserId(self.selectedUserId):setVoiceVolume((state - 1) * 0.1)
end
function InGameMenuMultiplayerFrame:getNumberOfSections(list)
    return list == self.userList and #self.sortedFarms or 1
end
function InGameMenuMultiplayerFrame:getCellTypeForItemInSection(list, _, index)
    return list == self.userList and (index == 1 and "farm" or "user") or nil
end
function InGameMenuMultiplayerFrame:getNumberOfItemsInSection(list, section)
    if list ~= self.farmList then
        return #self.sortedFarms[section]:getActiveUsers() + 1
    end
    local numFarms = #self.farms
    self.newFarmListIndex = nil
    if numFarms < FarmManager.MAX_NUM_FARMS and self.currentUser:getIsMasterUser() then
        numFarms = numFarms + 1
        self.newFarmListIndex = numFarms
    end
    return numFarms
end
function InGameMenuMultiplayerFrame:populateCellForItemInSection(list, section, index, cell)
    if list == self.farmList then
        local farm = self.farms[index]
        local farmId = cell:getAttribute("existingFarm")
        local user = farm ~= nil
        farmId:setVisible(user)
        local farmId = cell:getAttribute("newFarm")
        local user = farm ~= nil
        farmId:setVisible(user)
        if farm ~= nil then
            local farmId = self.elementFarmIdMap[cell]
            if farmId ~= nil then
                self.farmIdBalanceMap[farmId] = nil
            end
            cell:getAttribute("farmName"):setText(farm.name)
            cell:getAttribute("farmIcon"):setImageSlice(nil, farm:getIconSliceId())
            self.farmIdBalanceMap[farm.farmId] = cell:getAttribute("farmBalance")
            cell:getAttribute("farmBalance"):setValue(farm:getBalance())
            local playerNameLayout = cell:getAttribute("playerNameLayout")
            playerNameLayout:updateAbsolutePosition()
            local user = #playerNameLayout.elements
            for i = 1, user do
                playerNameLayout.elements[1]:delete()
            end
            for _, player in ipairs(farm:getActiveUsers()) do
                local user = g_currentMission.userManager:getUserByUserId(player.userId)
                if user ~= nil then
                    local nickname = user:getNickname()
                    self.playerNameTemplate:clone(playerNameLayout):setText(nickname)
                end
            end
            playerNameLayout:invalidateLayout()
            self.elementFarmIdMap[cell] = farm.farmId
            return
        end
    else
        local farm = self.sortedFarms[section]
        if index == 1 then
            if farm.farmId == FarmManager.SPECTATOR_FARM_ID then
                cell:getAttribute("title"):setText(g_i18n:getText("ui_noFarm"))
                cell:getAttribute("farmBalance"):setVisible(false)
            else
                cell:getAttribute("title"):setText(farm.name)
                cell:getAttribute("farmBalance"):setVisible(true)
                cell:getAttribute("farmBalance"):setValue(farm:getBalance())
            end
            cell:getAttribute("dot").color = farm:getColor()
            return
        end
        local playerNameLayout = farm:getActiveUsers()[index - 1]
        local user = g_currentMission.userManager:getUserByUserId(playerNameLayout.userId)
        if user == nil then
            return
        end
        cell:getAttribute("playerName"):setText(user:getNickname())
        cell:getAttribute("platform"):setPlatformId(user:getPlatformId())
        if not g_currentMission.connectedToDedicatedServer or user:getId() ~= g_currentMission:getServerUserId() then
            local isFarmManager = farm:isUserFarmManager(user:getId())
            local i = voiceChatGetConnectionStatus(user:getUniqueUserId()) == VoiceChatConnectionStatus.UNAVAILABLE
            cell:getAttribute("noMicrophone"):setVisible(i)
            local _ = cell:getAttribute("muted")
            local userId = not i
            if userId then
                userId = user:getVoiceMuted()
            end
            _:setVisible(userId)
            cell:getAttribute("farmManager"):setVisible(isFarmManager)
            cell:getAttribute("admin"):setVisible(user:getIsMasterUser())
            cell:getAttribute("admin").parent:invalidateLayout()
        end
    end
end
function InGameMenuMultiplayerFrame:onListSelectionChanged(list, section, index)
    if list == self.farmList then
        self.selectedFarmId = nil
        if index ~= self.newFarmListIndex then
            local farm = self.farms[index]
            if farm ~= nil then
                self.selectedFarmId = farm.farmId
            end
        end
    else
        self.actionsTitle:setVisible(false)
        if index == 1 then
            self.selectedUserId = nil
            self.selectedUserFarm = self.sortedFarms[section]
        else
            local user = farm:getActiveUsers()[index - 1]
            if user ~= nil then
                self.selectedUserId = user.userId
                self.selectedUserFarm = farm
                if user.lastNickname == nil and farm ~= nil then
                    farm:updateLastNickname(user.userId)
                end
                self.actionsTitle:setVisible(true)
                self.actionsTitle:setText(user.lastNickname)
            end
        end
        if self.selectedUserFarm ~= nil and not self.isAutoReloading then
            self:updateElements()
        end
    end
    self:updateMenuButtons()
end
InGameMenuMultiplayerFrame.L10N_SYMBOL = {
    ["PLAYER_COUNT"] = "ui_players",
    ["DELETE_FARM_CONFIRM"] = "ui_farmDeleteConfirmation",
    ["WRONG_PASSWORD"] = "ui_wrongPassword",
    ["BUTTON_CREATE_FARM"] = "button_mp_createFarm",
    ["BUTTON_JOIN_FARM"] = "button_mp_joinFarm",
    ["BUTTON_LEAVE_FARM"] = "button_mp_leaveFarm",
    ["BUTTON_DELETE_FARM"] = "button_mp_deleteFarm",
    ["BUTTON_EDIT_FARM"] = "button_mp_editFarm",
    ["LEAVE_FARM_CONFIRM"] = "ui_farmLeaveConfirmation",
    ["MONEY_BUTTON_TEMPLATE"] = "button_mp_transferMoney",
    ["BUTTON_UNBAN"] = "button_unban",
    ["BUTTON_ADMIN"] = "button_adminLogin",
    ["BUTTON_CONTRACT"] = "button_mp_grant",
    ["BUTTON_UNCONTRACT"] = "button_mp_ungrant",
    ["BUTTON_INVITE_FRIENDS"] = "ui_inviteScreen",
    ["PROMPT_ADMIN_PASSWORD"] = "button_adminLogin",
    ["INFO_CANNOT_BAN_SERVER"] = "ui_serverCannotBeBanned",
    ["INFO_CANNOT_KICK_SERVER"] = "ui_serverCannotBeKicked",
    ["DIALOG_KICK_TITLE"] = "ui_kickTitle",
    ["DIALOG_KICK_CONFIRM"] = "ui_kickConfirm",
    ["DIALOG_REMOVE_TITLE"] = "ui_removeFromFarmTitle",
    ["DIALOG_REMOVE_CONFIRM"] = "ui_removeFromFarmConfirm",
    ["DIALOG_PROMOTE_CONFIRM"] = "ui_promoteToFarmManagerConfirm",
    ["DIALOG_PROMOTE_TITLE"] = "ui_promoteToFarmManagerTitle",
    ["DIALOG_CONTRACTOR_STATE_TITLE"] = "ui_contractorStateChangeTitle",
    ["DIALOG_GRANT_CONTRACTOR_CONFIRM"] = "ui_contractorGrantConfirm",
    ["DIALOG_DENY_CONTRACTOR_CONFIRM"] = "ui_contractorUngrantConfirm"
}
InGameMenuMultiplayerFrame.PROFILE = {
    ["BALANCE_POSITIVE"] = "shopMoney",
    ["BALANCE_NEGATIVE"] = "shopMoneyNeg",
    ["CURRENT_PLAYER_TEXT"] = "ingameMenuMPUsersListRowTextCurrentPlayer"
}