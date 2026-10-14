InGameMenuContractsFrame = {}
local InGameMenuContractsFrame_mt = Class(InGameMenuContractsFrame, TabbedMenuFrameElement)
InGameMenuContractsFrame.CONTRACT_STATE = {
    ["NEW"] = 1,
    ["ACTIVE"] = 2,
    ["FINISHED"] = 3
}
InGameMenuContractsFrame.BUTTON_STATE = {
    ["POSSIBLE"] = 0,
    ["ACTIVE"] = 1,
    ["FINISHED"] = 2,
    ["EMPTY"] = 3
}
InGameMenuContractsFrame.CONTRACT_STATE_TEXTS = { "ui_contractsNew", "ui_contractsActive" }
function InGameMenuContractsFrame.register()
    local inGameMenuContractsFrame = InGameMenuContractsFrame.new()
    g_gui:loadGui("dataS/gui/InGameMenuContractsFrame.xml", "ContractsFrame", inGameMenuContractsFrame, true)
end
function InGameMenuContractsFrame.new(target, custom_mt)
    -- upvalues: (copy) InGameMenuContractsFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuContractsFrame_mt)
    self.hasCustomMenuButtons = true
    self.vehicleElements = {}
    self.contracts = {}
    self.sectionContracts = {}
    self.updateTime = 0
    self.marqueeTime = 0
    return self
end
function InGameMenuContractsFrame.createFromExistingGui(gui, guiName)
    local newGui = InGameMenuContractsFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function InGameMenuContractsFrame:initialize()
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
    self.acceptButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText("button_acceptContract"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonAccept()
        end
    }
    self.leaseButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText("button_borrowItems"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonLease()
        end
    }
    self.dismissButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText("button_contract_complete"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonDismiss()
        end
    }
    self.cancelButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText("button_cancel"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonCancel()
        end
    }
    self.vehicleTemplate:unlinkElement()
    local selectorTexts = {}
    for index, text in ipairs(InGameMenuContractsFrame.CONTRACT_STATE_TEXTS) do
        local index
        self.subCategoryDotTemplate:clone(self.subCategoryDotBox).getIsSelected = function()
            -- upvalues: (copy) self, (copy) index
            return self.subCategorySelector:getState() == index
        end
        table.insert(selectorTexts, g_i18n:getText(text))
    end
    self.subCategoryDotBox:invalidateLayout()
    self.subCategorySelector:setTexts(selectorTexts)
    g_messageCenter:subscribe(MessageType.MISSION_DELETED, self.onMissionDeleted, self)
end
function InGameMenuContractsFrame:delete()
    if self.vehicleTemplate ~= nil then
        self.vehicleTemplate:delete()
    end
    InGameMenuContractsFrame:superClass().delete(self)
    g_messageCenter:unsubscribeAll(self)
end
function InGameMenuContractsFrame:update(dt)
    InGameMenuContractsFrame:superClass().update(self, dt)
    local missionTime = g_currentMission.time
    if self.updateTime < missionTime then
        self.updateTime = missionTime + 5000
        local section, index = self.contractsList:getSelectedPath()
        self:updateDetailContents(section, index)
    end
    self:updateMarqueeAnimation(dt)
    if self.needsListFocus and FocusManager.currentGui == self.name then
        FocusManager:setFocus(self.contractsList)
        self.needsListFocus = false
    end
end
function InGameMenuContractsFrame:onFrameOpen(_)
    InGameMenuContractsFrame:superClass().onFrameOpen(self)
    g_messageCenter:subscribe(MissionStartedEvent, self.onMissionStart, self)
    g_messageCenter:subscribe(MessageType.MISSION_GENERATED, self.updateList, self)
    g_messageCenter:subscribe(MessageType.MISSION_DELETED, self.updateList, self)
    g_messageCenter:subscribe(MessageType.MISSION_STATUS_CHANGED, self.updateList, self)
    g_messageCenter:subscribe(PlayerPermissionsEvent, self.updateButtonsForPermissions, self)
    self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.POSSIBLE)
    self:setSoundSuppressed(true)
    self:updateList()
    FocusManager:setFocus(self.contractsList)
    self:setSoundSuppressed(false)
    self.ingameMap:onOpen()
    if self.customFilter ~= nil then
        self.ingameMapBase:applyCustomFilter(self.customFilter)
    end
    self.isOpen = true
end
function InGameMenuContractsFrame:onFrameClose(_)
    InGameMenuContractsFrame:superClass().onFrameClose(self)
    self.isOpen = false
    self.contracts = {}
    self.sectionContracts = {}
    self.ingameMap:onClose()
    self.ingameMapBase:restoreDefaultFilter()
    g_messageCenter:unsubscribe(MissionStartedEvent, self)
    g_messageCenter:unsubscribe(MessageType.MISSION_GENERATED, self)
    g_messageCenter:unsubscribe(MessageType.MISSION_DELETED, self, self.updateList)
    g_messageCenter:unsubscribe(MessageType.MISSION_STATUS_CHANGED, self)
    g_messageCenter:unsubscribe(PlayerPermissionsEvent, self)
end
function InGameMenuContractsFrame:setInGameMap(ingameMap)
    self.ingameMap:setIngameMap(ingameMap)
    self.ingameMapBase = ingameMap
    if ingameMap ~= nil then
        self.customFilter = ingameMap:createCustomFilter(true)
        self.customFilter[MapHotspot.CATEGORY_MISSION] = false
    end
end
function InGameMenuContractsFrame:updateButtonsForPermissions()
    local section, index = self.contractsList:getSelectedPath()
    self:updateDetailContents(section, index)
end
function InGameMenuContractsFrame:setButtonsForState(state, canLease)
    local info = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    local hasPermission = g_currentMission:getHasPlayerPermission(Farm.PERMISSION.MANAGE_CONTRACTS)
    if state == InGameMenuContractsFrame.BUTTON_STATE.FINISHED then
        table.insert(info, self.dismissButtonInfo)
        self.dismissButtonInfo.disabled = not hasPermission
    elseif state == InGameMenuContractsFrame.BUTTON_STATE.ACTIVE then
        table.insert(info, self.cancelButtonInfo)
        self.cancelButtonInfo.disabled = not hasPermission
    elseif self.contractsList:getItemCount() > 0 then
        table.insert(info, self.acceptButtonInfo)
        self.acceptButtonInfo.disabled = not hasPermission
        if canLease then
            table.insert(info, self.leaseButtonInfo)
            self.leaseButtonInfo.disabled = not hasPermission
        end
    end
    self.menuButtonInfo = info
    self:setMenuButtonInfoDirty()
end
function InGameMenuContractsFrame:onContractsChanged()
    self.contractsList:updateView()
end
function InGameMenuContractsFrame:onMissionDeleted(mission)
    if self.lastStartedMission == mission then
        self.lastStartedMission = nil
    end
    if self.currentContract ~= nil and self.currentContract.mission == mission then
        self.currentContract = nil
    end
end
function InGameMenuContractsFrame:onMissionStart()
    if self.currentContract ~= nil then
        self.lastStartedMission = self.currentContract.mission
    end
    self:updateList()
end
function InGameMenuContractsFrame:updateList()
    local list = g_missionManager:getMissionsByFarmId(g_currentMission:getFarmId())
    local hasMissions = #list ~= 0
    self.contractsListBox:setVisible(hasMissions)
    self.detailsList:setVisible(hasMissions)
    local selectedContract = self:getSelectedContract()
    if selectedContract == nil then
        self.storedSelected = nil
    else
        self.storedSelected = selectedContract.mission.generationTime
    end
    self.contracts = {}
    for _, mission in ipairs(list) do
        local sameFarm = false
        if g_localPlayer ~= nil then
            sameFarm = mission.farmId == g_localPlayer:getFarmId()
        end
        local status = mission.status
        local isActive = true
        if status ~= MissionStatus.RUNNING then
            isActive = status == MissionStatus.PREPARING
        end
        local isFinished = true
        if status ~= MissionStatus.FINISHED then
            isFinished = status == MissionStatus.DISMISSED
        end
        if not mission:getWasStarted() or sameFarm then
            table.insert(self.contracts, {
                ["mission"] = mission,
                ["active"] = isActive,
                ["isPreparing"] = status == MissionStatus.PREPARING,
                ["finished"] = isFinished,
                ["possible"] = status == MissionStatus.CREATED
            })
        end
    end
    self:sortList()
    self.contractsList:reloadData()
    self.contentContainer:setVisible(self.contractsList:getItemCount() > 0)
end
function InGameMenuContractsFrame:updateProgressBar(value)
    local fullWidth = self.progressBarBg.size[1] - self.progressBar.margin[1] * 2
    value = math.max(value, self.progressBar.startSize[1] * 2 / fullWidth)
    self.progressBar:setSize(fullWidth * math.min(value, 1), nil)
end
function InGameMenuContractsFrame:onDrawPostIngameMapHotspots()
    if self.currentContract ~= nil then
        local hotspots = self.currentContract.mission:getMapHotspots()
        if hotspots ~= nil then
            for _, hotspot in ipairs(hotspots) do
                self.ingameMap:drawHotspot(hotspot, false)
            end
        end
    end
end
function InGameMenuContractsFrame:updateDetailContents(section, index)
    local contract = nil
    local sectionContracts = self.sectionContracts[self.subCategorySelector:getState()][section]
    if sectionContracts ~= nil then
        contract = sectionContracts.contracts[index]
        self.currentContract = contract
        local hotspots = contract.mission:getMapHotspots()
        if hotspots ~= nil then
            for _, hotspot in ipairs(hotspots) do
                hotspot:postUpdate(9999)
            end
        end
        self.detailsList:reloadData()
    end
    for _, elem in pairs(self.vehicleElements) do
        elem:delete()
    end
    self.vehicleElements = {}
    self.vehiclesBox:invalidateLayout()
    if contract == nil then
        self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.EMPTY)
    else
        local mission = contract.mission
        self:updateFarmersBox(mission.field, mission:getNPC())
        local hotspots = mission:getReward()
        self.titleText:setText(mission:getTitle())
        self.contractDescriptionText:setText(mission:getDescription())
        self.rewardTitle:setText(g_i18n:getText("contract_reward"))
        self.equipmentBox:setVisible(contract.possible)
        self.progressBox:setVisible(contract.active)
        self.mapBox:setVisible(not contract.finshed)
        self.collectRewardsBox:setVisible(contract.finshed)
        if contract.active then
            self.progressText:setText(string.format("%.0f%%", mission.completion * 100))
            self.extraProgressText:setText(mission:getExtraProgressText())
            self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.ACTIVE)
            self:updateProgressBar(mission.completion)
        elseif contract.possible then
            local hasLeasing = mission:hasLeasableVehicles()
            self.useOwnEquipementText:setVisible(hasLeasing)
            self.equipmentTitle:setVisible(hasLeasing)
            if hasLeasing then
                local elem = g_i18n:formatMoney(mission:getVehicleCosts(), 0, true, true)
                self.useOwnEquipementText:setText((string.format(g_i18n:getText("contract_desc_useOwnEquipment"), elem)))
                local hotspot = 0
                for i, v in ipairs(mission.vehiclesToLoad) do
                    local storeItem = g_storeManager:getItemByXMLFilename(v.filename)
                    if storeItem == nil then
                        Logging.error("Mission uses non-existent vehicle at \'%s\'", v.filename)
                    end
                    local imageFilename = storeItem.imageFilename
                    if v.configurations ~= nil and storeItem.configurations ~= nil then
                        for configName, _ in pairs(storeItem.configurations) do
                            local config = storeItem.configurations[configName][v.configurations[configName]]
                            if config ~= nil and (config.vehicleIcon ~= nil and config.vehicleIcon ~= "") then
                                imageFilename = config.vehicleIcon
                                break
                            end
                        end
                    end
                    local element = self.vehicleTemplate:clone(self.vehiclesBox)
                    element:setImageFilename(imageFilename)
                    element:setImageColor(nil, nil, nil, nil, 1)
                    local z = self.vehicleElements
                    table.insert(z, element)
                end
                self.vehiclesBox:setSize(hotspot)
                self.vehiclesBox:invalidateLayout()
                if self.vehiclesBox.maxFlowSize > self.vehiclesBox.parent.absSize[1] and self.vehiclesBox.pivot[1] ~= 0 then
                    self.vehiclesBox:setPivot(0, 0.5)
                elseif self.vehiclesBox.maxFlowSize <= self.vehiclesBox.parent.absSize[1] and self.vehiclesBox.pivot[1] ~= 0.5 then
                    self.vehiclesBox:setPivot(0.5, 0.5)
                end
                self.vehiclesBox:setPosition(0)
            end
            self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.POSSIBLE, hasLeasing)
        elseif contract.finished then
            self.rewardTitle:setText(g_i18n:getText("contract_total"))
            self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.FINISHED)
            hotspots = mission:getTotalReward()
        end
        self.rewardText:setText(g_i18n:formatMoney(hotspots, 0, true, true))
        if hotspots > 0 then
            self.rewardText:applyProfile("fs25_contractsContractRewardValue")
        else
            self.rewardText:applyProfile("fs25_contractsContractRewardValueNegative")
        end
        if self.isOpen then
            local hasLeasing, _ = mission:getWorldPosition()
            local elem = mission:getMapHotspots()
            local _ = 650
            local hotspot = 650
            if elem ~= nil and #elem > 0 then
                local vehicles = -math.huge
                local maxX = math.huge
                local minZ = -math.huge
                local maxZ = math.huge
                local hasLeasing = 0
                local _ = 0
                for imageFilename, element in ipairs(elem) do
                    local x, z = element:getWorldPosition()
                    vehicles = math.max(x, vehicles)
                    minZ = math.max(z, minZ)
                    maxX = math.min(x, maxX)
                    maxZ = math.min(z, maxZ)
                end
                hasLeasing = hasLeasing / #elem
                _ = _ / #elem
                local element = maxX - vehicles
                local storeItem = math.abs(element) + 100
                _ = math.max(storeItem, _)
                local element = maxZ - minZ
                local storeItem = math.abs(element) + 100
                hotspot = math.max(storeItem, hotspot)
            end
            if hasLeasing ~= nil then
                self.ingameMap:fitToBoundary(hasLeasing - _ * 0.5, hasLeasing + _ * 0.5, _ - hotspot * 0.5, _ + hotspot * 0.5, 0.1)
                self.ingameMap:setCenterToWorldPosition(hasLeasing, _)
                return
            end
        end
    end
end
function InGameMenuContractsFrame:updateFarmersBox(_, npc)
    self.farmerBox:setVisible(npc ~= nil)
    if npc ~= nil then
        self.farmerName:setText(npc.title)
        self.farmerImage:setImageFilename(npc.imageFilename)
    end
end
function InGameMenuContractsFrame:getSelectedContract()
    if self.sectionContracts[self.subCategorySelector:getState()] == nil then
        return nil
    else
        local section, index = self.contractsList:getSelectedPath()
        local sectionContracts = self.sectionContracts[self.subCategorySelector:getState()][section]
        if sectionContracts == nil then
            return nil
        else
            return sectionContracts.contracts[index]
        end
    end
end
function InGameMenuContractsFrame:startContract(leaseVehicles)
    local contract = self:getSelectedContract()
    if contract == nil then
        return
    else
        local farmId = g_currentMission:getFarmId()
        if leaseVehicles and not contract.mission:isSpawnSpaceAvailable() then
            InfoDialog.show(g_i18n:getText("warning_noFreeMissionSpace"), nil, nil, DialogElement.TYPE_WARNING)
        else
            g_messageCenter:subscribe(MissionStartEvent, self.onMissionStarted, self)
            g_client:getServerConnection():sendEvent(MissionStartEvent.new(contract.mission, farmId, leaseVehicles))
        end
    end
end
function InGameMenuContractsFrame:onMissionStarted(startState, leaseVehicles)
    g_messageCenter:unsubscribe(MissionStartEvent, self)
    if startState == MissionStartState.OK then
        if leaseVehicles then
            InfoDialog.show(g_i18n:getText("contract_vehiclesAtShop"), function()
                -- upvalues: (copy) self
                self.subCategorySelector:setState(2, true)
                for section, sectionContract in pairs(self.sectionContracts[2]) do
                    for index, contract in pairs(sectionContract.contracts) do
                        if contract.mission == self.lastStartedMission then
                            self.contractsList:setSelectedItem(section, index)
                            self.needsListFocus = true
                        end
                    end
                end
            end, nil, DialogElement.TYPE_INFO)
        else
            InfoDialog.show(g_i18n:getText("contract_started"), changeSubcategoryFunc, nil, DialogElement.TYPE_INFO)
        end
    elseif startState == MissionStartState.LIMIT_REACHED then
        InfoDialog.show(g_i18n:getText("contract_limitedReached"), nil, nil, DialogElement.TYPE_WARNING)
        return
    elseif startState == MissionStartState.ALREADY_STARTED then
        InfoDialog.show(g_i18n:getText("contract_alreadyStarted"), nil, nil, DialogElement.TYPE_WARNING)
        return
    elseif startState == MissionStartState.NOT_AVAILABLE_ANYMORE then
        InfoDialog.show(g_i18n:getText("contract_notAvailableAnymore"), nil, nil, DialogElement.TYPE_WARNING)
        return
    elseif startState == MissionStartState.NO_ACCESS then
        InfoDialog.show(g_i18n:getText("contract_noAccess"), nil, nil, DialogElement.TYPE_WARNING)
        return
    elseif startState == MissionStartState.CANNOT_BE_STARTED_NOW then
        InfoDialog.show(g_i18n:getText("contract_cannotBeStartedNow"), nil, nil, DialogElement.TYPE_WARNING)
        return
    elseif startState == MissionStartState.PENDING_MISSION then
        InfoDialog.show(g_i18n:getText("contract_pendingMissionStart"), nil, nil, DialogElement.TYPE_WARNING)
        return
    elseif startState == MissionStartState.NO_PERMISSION then
        InfoDialog.show(g_i18n:getText("contract_noPermission"), nil, nil, DialogElement.TYPE_WARNING)
    else
        InfoDialog.show(g_i18n:getText("contract_startFailed"), nil, nil, DialogElement.TYPE_WARNING)
    end
end
function InGameMenuContractsFrame:sortList()
    table.sort(self.contracts, function(a, b)
        if a.active == b.active then
            if a.finished == b.finished then
                local aMission = a.mission
                local bMission = b.mission
                if aMission.type == bMission.type then
                    local fieldA = aMission.field
                    local fieldB = bMission.field
                    local fieldNameA = fieldA and fieldA:getName() or aMission.farmlandId
                    local fieldNameB = fieldB and fieldB:getName() or aMission.farmlandId
                    if fieldNameA == nil or fieldNameB == nil then
                        return aMission.id < bMission.id
                    else
                        return fieldNameA < fieldNameB
                    end
                else
                    local fieldA = aMission:getTitle() < bMission:getTitle()
                    return fieldA
                end
            else
                return a.finished
            end
        else
            return a.active
        end
    end)
    local selectorTexts = {}
    self.sectionContracts = {}
    for _, text in ipairs(InGameMenuContractsFrame.CONTRACT_STATE_TEXTS) do
        table.insert(self.sectionContracts, {})
        table.insert(selectorTexts, g_i18n:getText(text))
    end
    for text, contract in ipairs(self.contracts) do
        local stateIndex = InGameMenuContractsFrame.CONTRACT_STATE.NEW
        if contract.active or contract.finished then
            stateIndex = InGameMenuContractsFrame.CONTRACT_STATE.ACTIVE
        end
        local title = contract.mission:getTitle()
        if ({})[stateIndex] ~= title then
            table.insert(self.sectionContracts[stateIndex], {
                ["title"] = title,
                ["contracts"] = {}
            })
            lastTitle[stateIndex] = title
        end
        table.insert(self.sectionContracts[stateIndex][#self.sectionContracts[stateIndex]].contracts, contract)
    end
    if #self.sectionContracts[InGameMenuContractsFrame.CONTRACT_STATE.NEW] == 0 then
        if #self.sectionContracts[InGameMenuContractsFrame.CONTRACT_STATE.ACTIVE] > 0 then
            self.subCategorySelector:setState(InGameMenuContractsFrame.CONTRACT_STATE.ACTIVE)
        elseif self.sectionContracts[InGameMenuContractsFrame.CONTRACT_STATE.FINISHED] ~= nil and #self.sectionContracts[InGameMenuContractsFrame.CONTRACT_STATE.FINISHED] > 0 then
            self.subCategorySelector:setState(InGameMenuContractsFrame.CONTRACT_STATE.FINISHED)
        end
    end
    self.subCategorySelector:setTexts(selectorTexts)
end
function InGameMenuContractsFrame:updateMarqueeAnimation(dt)
    local contentWidth = self.vehiclesBox.absSize[1]
    local visibleWidth = self.vehiclesBox.parent.absSize[1]
    local scrollLengthFactor = contentWidth / visibleWidth
    if scrollLengthFactor > 1 then
        local scrollDuration = 5000 * scrollLengthFactor
        self.marqueeTime = self.marqueeTime + dt
        if scrollDuration <= self.marqueeTime then
            self.marqueeTime = -scrollDuration
        end
        local offset = (contentWidth - visibleWidth) * MathUtil.smoothstep(0.2, 0.8, math.abs(self.marqueeTime) / scrollDuration)
        self.vehiclesBox:setPosition(-offset)
    end
end
function InGameMenuContractsFrame:getNumberOfSections(list)
    return list == self.detailsList and 1 or #self.sectionContracts[self.subCategorySelector:getState()]
end
function InGameMenuContractsFrame:getNumberOfItemsInSection(list, section)
    if list ~= self.detailsList then
        return #self.sectionContracts[self.subCategorySelector:getState()][section].contracts
    end
    local mission = self.currentContract.mission
    return mission:getIsFinished() and #mission:getFinishedDetails() or #mission:getDetails()
end
function InGameMenuContractsFrame:getTitleForSectionHeader(list, section)
    return list == self.detailsList and "" or self.sectionContracts[self.subCategorySelector:getState()][section].title
end
function InGameMenuContractsFrame:populateCellForItemInSection(list, section, index, cell)
    if list == self.detailsList then
        local mission = self.currentContract.mission
        local detail
        if mission:getIsFinished() then
            detail = mission:getFinishedDetails()
        else
            detail = mission:getDetails()
        end
        local detail = detail[index]
        cell:getAttribute("title"):setText(detail.title)
        cell:getAttribute("info"):setText(detail.value)
    else
        local mission = self.sectionContracts[self.subCategorySelector:getState()][section].contracts[index]
        local isFinished = mission.mission
        if isFinished ~= nil then
            local details = isFinished:getNPC()
            local detail = cell:getAttribute("icon")
            detail:setVisible(details ~= nil)
            if details ~= nil then
                cell:getAttribute("icon"):setImageFilename(details.imageFilename)
            end
            cell:getAttribute("field"):setText(isFinished:getLocation())
            cell:getAttribute("reward"):setText(g_i18n:formatMoney(isFinished:getReward(), 0, true, true))
            local detail = cell:getAttribute("reward")
            detail:setVisible(not mission.finished and not mission.isPreparing)
            local detail = nil
            local minutesLeft = isFinished:getMinutesLeft()
            if mission.isPreparing then
                detail = g_i18n:getText("contract_preparing")
            elseif minutesLeft ~= nil and (not mission.finished and isFinished.finishState ~= MissionFinishState.SUCCESS) then
                detail = g_i18n:formatMinutes(minutesLeft)
            end
            cell:getAttribute("time"):setVisible(detail ~= nil)
            if detail ~= nil then
                cell:getAttribute("time"):setText(detail)
            end
            cell:getAttribute("indicatorFinished"):setVisible(mission.finished and isFinished.finishState == MissionFinishState.SUCCESS)
            cell:getAttribute("indicatorFailed"):setVisible(mission.finished and isFinished.finishState == MissionFinishState.FAILED)
            cell:getAttribute("indicatorTimedOut"):setVisible(mission.finished and isFinished.finishState == MissionFinishState.TIMED_OUT)
            cell:getAttribute("indicatorCanceled"):setVisible(mission.finished and isFinished.finishState == MissionFinishState.CANCELED)
        end
    end
end
function InGameMenuContractsFrame:onButtonAccept()
    self:startContract(false)
end
function InGameMenuContractsFrame:onButtonLease()
    self:startContract(true)
end
function InGameMenuContractsFrame:onButtonDismiss()
    local contract = self:getSelectedContract()
    if contract ~= nil then
        g_messageCenter:subscribe(MissionDismissEvent, self.onMissionDismissed, self)
        g_client:getServerConnection():sendEvent(MissionDismissEvent.new(contract.mission))
    end
end
function InGameMenuContractsFrame:onMissionDismissed(success)
    g_messageCenter:unsubscribe(MissionDismissEvent, self)
    if success then
        InfoDialog.show(g_i18n:getText("contract_missionDismissSuccess"), nil, nil, DialogElement.TYPE_INFO)
    else
        InfoDialog.show(g_i18n:getText("contract_missionDismissFailed"), nil, nil, DialogElement.TYPE_INFO)
    end
    self:updateList()
    self:updateDetailContents(self.contractsList:getSelectedPath())
end
function InGameMenuContractsFrame:onButtonCancel()
    YesNoDialog.show(self.onCancelDialog, self, g_i18n:getText("contract_end"))
end
function InGameMenuContractsFrame:onCancelDialog(yes)
    if yes then
        local contract = self:getSelectedContract()
        if contract ~= nil then
            g_messageCenter:subscribe(MissionCancelEvent, self.onMissionCanceled, self)
            g_client:getServerConnection():sendEvent(MissionCancelEvent.new(contract.mission))
        end
    end
end
function InGameMenuContractsFrame:onMissionCanceled(success)
    g_messageCenter:unsubscribe(MissionCancelEvent, self)
    if success then
        InfoDialog.show(g_i18n:getText("contract_missionCancelSuccess"), nil, nil, DialogElement.TYPE_INFO)
    else
        InfoDialog.show(g_i18n:getText("contract_missionCancelFailed"), nil, nil, DialogElement.TYPE_INFO)
    end
    self:updateList()
end
function InGameMenuContractsFrame:onListSelectionChanged(list, section, index)
    if not g_gui.currentlyReloading and list ~= self.detailsList then
        local sectionContracts = self.sectionContracts[self.subCategorySelector:getState()][section]
        if sectionContracts ~= nil and sectionContracts.contracts[index] ~= nil then
            self:updateDetailContents(section, index)
            self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
            self.marqueeTime = 0
        end
    end
end
function InGameMenuContractsFrame:onChangeSubCategory()
    self.contractsList:reloadData()
    self.contentContainer:setVisible(self.contractsList:getItemCount() > 0)
    self:updateDetailContents(self.contractsList:getSelectedPath())
end