TourIconsMobile = {}
local TourIconsMobile_mt = Class(TourIconsMobile)
function TourIconsMobile.onCreate(_, id)
    local tourIcons = TourIconsMobile.new(id)
    g_currentMission:addUpdateable(tourIcons)
    g_currentMission.tourIconsBase = tourIcons
end
function TourIconsMobile.new(id)
    -- upvalues: (copy) TourIconsMobile_mt
    local self = setmetatable({}, TourIconsMobile_mt)
    self.me = id
    local num = getNumOfChildren(self.me)
    self.tourIcons = {}
    local i = 0
    for i = i, num - 1 do
        local tourIconTriggerId = getChildAt(self.me, i)
        local tourIconId = getChildAt(tourIconTriggerId, 0)
        addTrigger(tourIconTriggerId, "triggerCallback", self)
        setVisibility(tourIconId, false)
        table.insert(self.tourIcons, {
            ["tourIconTriggerId"] = tourIconTriggerId,
            ["tourIconId"] = tourIconId
        })
    end
    self.visible = false
    self.mapHotspot = nil
    self.currentTourIconNumber = 1
    self.alpha = 0.25
    self.alphaDirection = 1
    self.startTourDialog = false
    self.startTourDialogDelay = 0
    self.permanentMessageDelay = 0
    self.isPaused = false
    self.pauseTime = 0
    self.soldStuffAtGrainElevator = false
    self.plowLevelMaxValue = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL)
    self.limeLevelMaxValue = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL)
    local i, tourIconTriggerId = getNormalizedScreenValues(0, 28)
    _ = i
    self.permanentTextSize = tourIconTriggerId
    return self
end
function TourIconsMobile:delete()
    g_currentMission:removeUpdateable(self)
    for _, tourIcon in pairs(self.tourIcons) do
        removeTrigger(tourIcon.tourIconTriggerId)
    end
    if self.me ~= 0 then
        delete(self.me)
        self.me = 0
    end
end
function TourIconsMobile:showTourDialog()
    YesNoDialog.show(self.reactToDialog, self, g_i18n:getText("tour_text_start"), "")
end
function TourIconsMobile:reactToDialog(yes)
    if yes then
        self.visible = true
        self:activateNextIcon()
        if g_currentMission.helpIconsBase ~= nil then
            g_currentMission.helpIconsBase:showHelpIcons(false, true)
            return
        end
    else
        self.visible = false
        InfoDialog.show(g_i18n:getText("tour_mobile_abort"))
        self:delete()
    end
end
function TourIconsMobile:update(dt)
    if not g_currentMission.missionInfo.isValid and (g_server ~= nil and (self.initDone == nil and g_currentMission:getIsTourSupported())) then
        self.initDone = true
        g_currentMission:fadeScreen(-1, 3000, function()
            -- upvalues: (copy) self
            self.canStart = true
        end, self)
        Logging.devWarning("TourIconsMobile:update not yet implemented with new polygon system")
    end
    if self.startTourDialog and self.canStart then
        self.startTourDialogDelay = self.startTourDialogDelay - dt
        if self.startTourDialogDelay < 0 then
            self.startTourDialog = false
            self:showTourDialog()
        end
    end
    if g_gui:getIsGuiVisible() then
        return
    elseif self.queuedMessage == nil then
        if self.isPaused then
            if self.pauseTime > 0 then
                self.pauseTime = self.pauseTime - dt
            else
                self.pauseTime = 0
                self.isPaused = false
                self:activateNextIcon()
            end
        end
        if self.visible and not self.isPaused then
            if self.currentTourIconNumber == 2 then
                if g_localPlayer:getCurrentVehicle() ~= nil and (g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourCombine and g_currentMission.tourVehicles.tourCombine:getActionControllerDirection() < 0) then
                    self.pauseTime = 2000
                    self.isPaused = true
                    return
                end
            elseif self.currentTourIconNumber == 4 then
                if g_currentMission.tourVehicles.tourCombine:getIsTurnedOn() and g_currentMission.tourVehicles.tourCombine:getIsAIActive() then
                    self.pauseTime = 1000
                    self.isPaused = true
                    return
                end
            elseif self.currentTourIconNumber == 5 then
                if g_localPlayer:getCurrentVehicle() ~= nil and g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor1 then
                    self.pauseTime = 1000
                    self.isPaused = true
                    return
                end
            elseif self.currentTourIconNumber == 6 then
                if g_localPlayer:getCurrentVehicle() ~= nil and (g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor1 and g_currentMission.tourVehicles.tourTractor1:getActionControllerDirection() < 0) then
                    self.pauseTime = 1000
                    self.isPaused = true
                    return
                end
            elseif self.currentTourIconNumber == 8 then
                if g_localPlayer:getCurrentVehicle() ~= nil and g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor2 then
                    self.pauseTime = 1000
                    self.isPaused = true
                    return
                end
            elseif self.currentTourIconNumber == 9 then
                if g_localPlayer:getCurrentVehicle() ~= nil and (g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor2 and g_currentMission.tourVehicles.tourSowingMachine.rootVehicle == g_currentMission.tourVehicles.tourTractor2) then
                    self.pauseTime = 1000
                    self.isPaused = true
                    return
                end
            elseif self.currentTourIconNumber == 11 then
                if g_localPlayer:getCurrentVehicle() ~= nil and g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor1 then
                    self.pauseTime = 1000
                    self.isPaused = true
                    return
                end
            elseif self.currentTourIconNumber == 13 then
                if g_currentMission.tourVehicles.tourCultivator.rootVehicle == g_currentMission.tourVehicles.tourCultivator then
                    self.pauseTime = 1000
                    self.isPaused = true
                    return
                end
            elseif self.currentTourIconNumber == 14 then
                if g_localPlayer:getCurrentVehicle() ~= nil and (g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor1 and g_currentMission.tourVehicles.tourTrailer.rootVehicle == g_currentMission.tourVehicles.tourTractor1) then
                    self.pauseTime = 1000
                    self.isPaused = true
                    return
                end
            elseif self.currentTourIconNumber == 15 then
                if g_localPlayer:getCurrentVehicle() ~= nil and (g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor1 and g_currentMission.tourVehicles.tourTrailer:getFillUnitFillLevel(1) > 800) then
                    self.pauseTime = 1000
                    self.isPaused = true
                    return
                end
            elseif self.currentTourIconNumber == 17 and (g_localPlayer:getCurrentVehicle() ~= nil and (g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor1 and g_currentMission.tourVehicles.tourTrailer:getFillUnitFillLevel(1) <= 2)) then
                self.pauseTime = 1000
                self.isPaused = true
            end
        end
    else
        g_currentMission.hud.ingameMap:toggleSize(IngameMapMobile.STATE_HIDDEN, true)
        InfoDialog.show(self.queuedMessage)
        self.queuedMessage = nil
    end
end
function TourIconsMobile:makeIconVisible(tourIconId)
    setVisibility(tourIconId, true)
    local x, y, z = getWorldTranslation(tourIconId)
    if self.mapHotspot == nil then
        self.mapHotspot = TourHotspot.new()
        g_currentMission:addMapHotspot(self.mapHotspot)
    end
    self.mapHotspot:setWorldPosition(x, z)
    if getTerrainHeightAtWorldPos(g_terrainNode, x, y, z) < y then
        g_currentMission:setMapTargetHotspot(self.mapHotspot)
        g_currentMission.disableMapTargetHotspotHiding = true
    else
        g_currentMission:setMapTargetHotspot(nil)
        g_currentMission.disableMapTargetHotspotHiding = false
    end
end
function TourIconsMobile:triggerCallback(triggerId, otherId, onEnter, _, _)
    local object = g_currentMission:getNodeObject(otherId)
    if object ~= nil and (object:isa(Vehicle) and (onEnter and (self.tourIcons[self.currentTourIconNumber] ~= nil and (self.tourIcons[self.currentTourIconNumber].tourIconTriggerId == triggerId and getVisibility(self.tourIcons[self.currentTourIconNumber].tourIconId))))) then
        self:activateNextIcon()
    end
end
function TourIconsMobile:activateNextIcon()
    local i = 1
    local title = self.currentTourIconNumber
    local text = 1
    for i = i, title, text do
        local tourIcon = self.tourIcons[i]
        if getVisibility(tourIcon.tourIconId) then
            setVisibility(tourIcon.tourIconId, false)
            setCollisionFilterMask(tourIcon.tourIconTriggerId, 0)
        end
    end
    if self.tourIcons[self.currentTourIconNumber + 1] == nil then
        if self.mapHotspot ~= nil then
            g_currentMission:removeMapHotspot(self.mapHotspot)
            self.mapHotspot:delete()
            self.mapHotspot = nil
        end
        if g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_ICONS) and g_currentMission.helpIconsBase ~= nil then
            g_currentMission.helpIconsBase:showHelpIcons(true, true)
        end
        self.visible = false
        g_messageCenter:publish(MessageType.GUIDED_TOUR_FINISHED)
        self:delete()
    else
        self:makeIconVisible(self.tourIcons[self.currentTourIconNumber + 1].tourIconId)
    end
    local title = g_i18n:getText("ui_tour")
    local text = ""
    if self.currentTourIconNumber == 1 then
        text = g_i18n:getText("tour_mobile_part01_activate")
    elseif self.currentTourIconNumber == 2 then
        text = g_i18n:getText("tour_mobile_part01_drive")
    elseif self.currentTourIconNumber == 3 then
        text = g_i18n:getText("tour_mobile_part01_helper")
    elseif self.currentTourIconNumber == 4 then
        text = g_i18n:getText("tour_mobile_part01_finished")
    elseif self.currentTourIconNumber == 5 then
        text = g_i18n:getText("tour_mobile_part02_activate")
    elseif self.currentTourIconNumber == 6 then
        text = g_i18n:getText("tour_mobile_part02_drive")
    elseif self.currentTourIconNumber == 7 then
        text = g_i18n:getText("tour_mobile_part02_finished")
    elseif self.currentTourIconNumber == 8 then
        text = g_i18n:getText("tour_mobile_part03_attach")
    elseif self.currentTourIconNumber == 9 then
        text = g_i18n:getText("tour_mobile_part03_activateDrive")
    elseif self.currentTourIconNumber == 10 then
        text = g_i18n:getText("tour_mobile_part03_finished")
    elseif self.currentTourIconNumber == 11 then
        text = g_i18n:getText("tour_mobile_part04_driveToYard")
    elseif self.currentTourIconNumber == 12 then
        text = g_i18n:getText("tour_mobile_part04_detach")
    elseif self.currentTourIconNumber == 13 then
        text = g_i18n:getText("tour_mobile_part04_attachTrailer")
    elseif self.currentTourIconNumber == 14 then
        text = g_i18n:getText("tour_mobile_part04_driveToHarvester")
    elseif self.currentTourIconNumber == 15 then
        text = g_i18n:getText("tour_mobile_part04_driveToSellpoint")
    elseif self.currentTourIconNumber == 16 then
        text = g_i18n:getText("tour_mobile_part04_Unload")
    elseif self.currentTourIconNumber == 17 then
        text = g_i18n:getText("tour_mobile_end")
    end
    if g_localPlayer:getCurrentVehicle() ~= nil and g_localPlayer:getCurrentVehicle().setCruiseControlState ~= nil then
        g_localPlayer:getCurrentVehicle():setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
    end
    if g_gui:getIsGuiVisible() then
        self.queuedMessage = {
            ["title"] = title,
            ["text"] = text
        }
    else
        g_currentMission.hud.ingameMap:toggleSize(IngameMapMobile.STATE_HIDDEN, true)
        InfoDialog.show(text)
    end
    self.currentTourIconNumber = self.currentTourIconNumber + 1
    self.permanentMessageDelay = 250
end