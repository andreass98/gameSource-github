local data = nil
if ControlBarDisplay ~= nil then
    local old = g_currentMission.hud.controlBarDisplay
    data = {
        ["vehicle"] = old.vehicle,
        ["player"] = old.player,
        ["hud"] = old.hud,
        ["uiScale"] = old.uiScale,
        ["hudAtlasPath"] = old.hudAtlasPath,
        ["controlHudAtlasPath"] = old.controlHudAtlasPath
    }
    old:delete()
end
ControlBarDisplay = {}
ControlBarDisplay.MOVE_ANIMATION_DURATION = 500
ControlBarDisplay.STATE_TOUCH = 0
ControlBarDisplay.STATE_CONTROLLER = 1
ControlBarDisplay.STATE_AI_TOUCH = 2
local old = Class(ControlBarDisplay, HUDDisplayElement)
function ControlBarDisplay.new(hud, hudAtlasPath, controlHudAtlasPath)
    -- upvalues: (copy) old
    local backgroundOverlay = ControlBarDisplay.createBackground()
    local self = ControlBarDisplay:superClass().new(backgroundOverlay, nil, old)
    self.hud = hud
    self.uiScale = 1
    self.hudAtlasPath = hudAtlasPath
    self.controlHudAtlasPath = controlHudAtlasPath
    self.vehicle = nil
    self.lastChildVehicleHash = ""
    self.sowingMachine = nil
    self.player = nil
    self.hudElements = {}
    self.buttons = {}
    self.controlButtons = {}
    self.inputGlyphs = {}
    self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
    self.lastAIState = false
    self.lastGyroscopeSteeringState = false
    self.fillLevelBuffer = {}
    self.fillLevelBufferAddIndex = 0
    self.fillLevelBufferNeedsSorting = false
    self.fillLevelControls = {}
    self.vehicleControls = {}
    self.vehicleControls.attach = {
        ["availableFunc"] = "getShowAttachControlBarAction",
        ["accessibleFunc"] = "getAttachControlBarActionAccessible",
        ["actionFunc"] = "detachAttachedImplement",
        ["triggerType"] = TouchHandler.TRIGGER_UP,
        ["fullTapNeeded"] = true,
        ["controlButton"] = nil,
        ["uvs"] = ControlBarDisplay.UV.DETACH,
        ["prio"] = 3,
        ["inputAction"] = InputAction.ATTACH,
        ["name"] = "attach"
    }
    self.vehicleControls.turnOn = {
        ["allowedFunc"] = "getAreControlledActionsAllowed",
        ["availableFunc"] = "getAreControlledActionsAvailable",
        ["accessibleFunc"] = "getAreControlledActionsAccessible",
        ["getIconsFunc"] = "getControlledActionIcons",
        ["actionFunc"] = "playControlledActions",
        ["triggerType"] = TouchHandler.TRIGGER_UP,
        ["fullTapNeeded"] = true,
        ["directionFunc"] = "getActionControllerDirection",
        ["controlButton"] = nil,
        ["uvs"] = ControlBarDisplay.UV.TURN_ON,
        ["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON,
        ["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        ["prio"] = 4,
        ["inputAction"] = InputAction.VEHICLE_ACTION_CONTROL,
        ["name"] = "turnOn"
    }
    self.vehicleControls.ai = {
        ["availableFunc"] = "getCanToggleAIVehicle",
        ["accessibleFunc"] = "getShowAIToggleActionEvent",
        ["actionFunc"] = "toggleAIVehicle",
        ["triggerType"] = TouchHandler.TRIGGER_UP,
        ["fullTapNeeded"] = true,
        ["directionFunc"] = "getIsAIActive",
        ["controlButton"] = nil,
        ["uvs"] = ControlBarDisplay.UV.AI,
        ["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        ["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
        ["prio"] = 5,
        ["inputAction"] = InputAction.TOGGLE_AI,
        ["name"] = "ai"
    }
    self.vehicleControls.leave = {
        ["availableFunc"] = "getCanLeaveVehicle",
        ["accessibleFunc"] = "getIsLeavingAllowed",
        ["actionFunc"] = "doLeaveVehicle",
        ["triggerType"] = TouchHandler.TRIGGER_UP,
        ["fullTapNeeded"] = true,
        ["controlButton"] = nil,
        ["uvs"] = ControlBarDisplay.UV.LEAVE_VEHICLE,
        ["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        ["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
        ["prio"] = 6,
        ["inputAction"] = InputAction.ENTER,
        ["name"] = "leave"
    }
    self.vehicleControls.unloadFork = {
        ["availableFunc"] = "getCanUnloadFork",
        ["accessibleFunc"] = "getIsForkUnloadingAllowed",
        ["actionFunc"] = "doUnloadFork",
        ["triggerType"] = TouchHandler.TRIGGER_UP,
        ["fullTapNeeded"] = true,
        ["controlButton"] = nil,
        ["uvs"] = ControlBarDisplay.UV.UNLOAD_FORK,
        ["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        ["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
        ["prio"] = 7,
        ["inputAction"] = InputAction.UNLOAD_FORK,
        ["name"] = "unloadFork"
    }
    self.vehicleControls.leave_horse = {
        ["availableFunc"] = "getCanLeaveRideable",
        ["accessibleFunc"] = "getIsLeavingAllowed",
        ["actionFunc"] = "doLeaveVehicle",
        ["triggerType"] = TouchHandler.TRIGGER_UP,
        ["fullTapNeeded"] = true,
        ["controlButton"] = nil,
        ["uvs"] = ControlBarDisplay.UV.LEAVE_HORSE,
        ["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        ["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
        ["prio"] = 6,
        ["inputAction"] = InputAction.ENTER,
        ["name"] = "leave_horse"
    }
    self.playerControls = {}
    self.playerControls.enter_vehicle = {
        ["availableFunc"] = "getCanEnterVehicle",
        ["actionFunc"] = "onInputEnter",
        ["triggerType"] = TouchHandler.TRIGGER_UP,
        ["fullTapNeeded"] = true,
        ["controlButton"] = nil,
        ["uvs"] = ControlBarDisplay.UV.ENTER_VEHICLE,
        ["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        ["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
        ["prio"] = 7,
        ["inputAction"] = InputAction.ENTER,
        ["name"] = "enter_vehicle"
    }
    self.playerControls.enter_horse = {
        ["availableFunc"] = "getCanEnterRideable",
        ["actionFunc"] = "onInputEnter",
        ["triggerType"] = TouchHandler.TRIGGER_UP,
        ["fullTapNeeded"] = true,
        ["controlButton"] = nil,
        ["uvs"] = ControlBarDisplay.UV.ENTER_HORSE,
        ["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        ["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
        ["prio"] = 8,
        ["inputAction"] = InputAction.ENTER,
        ["name"] = "ride_horse"
    }
    self.playerControls.ride = {
        ["availableFunc"] = "getIsRideStateAvailable",
        ["actionFunc"] = "activateRideState",
        ["triggerType"] = TouchHandler.TRIGGER_UP,
        ["fullTapNeeded"] = true,
        ["controlButton"] = nil,
        ["uvs"] = ControlBarDisplay.UV.ENTER_HORSE,
        ["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        ["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
        ["prio"] = 9,
        ["inputAction"] = InputAction.ENTER,
        ["name"] = "ride_horse"
    }
    self.customControls = {}
    self.customControls.activateObject = {
        ["availableFunc"] = self.getIsActivatableObjectAvailable,
        ["actionFunc"] = self.triggerActivatableObject,
        ["triggerType"] = TouchHandler.TRIGGER_UP,
        ["fullTapNeeded"] = true,
        ["controlButton"] = nil,
        ["uvs"] = ControlBarDisplay.UV.ACTIVATABLE_OBJECT,
        ["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        ["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
        ["prio"] = 7,
        ["inputAction"] = InputAction.ACTIVATE_OBJECT,
        ["name"] = "activateObject"
    }
    self:createComponents()
    return self
end
function ControlBarDisplay:createComponents()
    local iconSizeX = {}
    local iconSizeY = getNormalizedScreenValues
    __set_list(iconSizeX, 1, {iconSizeY(unpack(ControlBarDisplay.POSITION.BUTTON_START))})
    self.buttonStartPos = iconSizeX
    local iconSizeX = getNormalizedScreenValues
    self.buttonOffsetX = iconSizeX(unpack(ControlBarDisplay.POSITION.BUTTON_OFFSET))
    local iconSizeX = getNormalizedScreenValues
    local iconSizeX, iconSizeY = iconSizeX(unpack(ControlBarDisplay.SIZE.FILL_LEVEL_ICON))
    self.fillLevelIconSizeX = iconSizeX
    self.fillLevelIconSizeY = iconSizeY
    local iconSizeX = getNormalizedScreenValues
    local iconSizeX, iconSizeY = iconSizeX(unpack(ControlBarDisplay.POSITION.FILL_LEVEL_ICON_OFFSET))
    self.fillLevelIconOffsetX = iconSizeX
    self.fillLevelIconOffsetY = iconSizeY
    self.hudControls = {}
    local iconSizeY = self.hudControls
    table.insert(iconSizeY, self:addFillLevelControl())
    local iconSizeY = self.hudControls
    table.insert(iconSizeY, self:addFillLevelControl())
    local iconSizeX = getNormalizedScreenValues
    local iconSizeX, iconSizeY = iconSizeX(unpack(ControlBarDisplay.SIZE.ICON))
    for _, control in pairs(self.vehicleControls) do
        local button = HUDButtonElement.new(self.hud, 0, 0)
        button:setIcon(self.controlHudAtlasPath, iconSizeX, iconSizeY, GuiUtils.getUVs(control.uvs))
        button:setAction(control.inputAction)
        local control
        function button.buttonCallback()
            -- upvalues: (copy) control
            if not g_sleepManager:getIsSleeping() then
                local vehicle = control.vehicle
                if vehicle ~= nil then
                    if control.allowedFunc ~= nil then
                        local allowed, warning = vehicle[control.allowedFunc](vehicle)
                        if not allowed then
                            g_currentMission:showBlinkingWarning(warning, 2500)
                            return
                        end
                    end
                    vehicle[control.actionFunc](vehicle)
                end
            end
        end
        button:addTouchHandler(button.buttonCallback, self)
        self:addChild(button)
        control.button = button
        table.insert(self.hudControls, control)
    end
    for _, control in pairs(self.playerControls) do
        local button = HUDButtonElement.new(self.hud, 0, 0)
        button:setIcon(self.controlHudAtlasPath, iconSizeX, iconSizeY, GuiUtils.getUVs(control.uvs))
        button:setAction(control.inputAction)
        local control
        function button.buttonCallback()
            -- upvalues: (copy) self, (copy) control
            if not g_sleepManager:getIsSleeping() then
                local player = self.player
                if player ~= nil then
                    player[control.actionFunc](player)
                end
            end
        end
        button:addTouchHandler(button.buttonCallback, self)
        self:addChild(button)
        control.button = button
        table.insert(self.hudControls, control)
    end
    for _, control in pairs(self.customControls) do
        local button = HUDButtonElement.new(self.hud, 0, 0)
        button:setIcon(self.controlHudAtlasPath, iconSizeX, iconSizeY, GuiUtils.getUVs(control.uvs))
        button:setAction(control.inputAction)
        local control
        function button.buttonCallback()
            -- upvalues: (copy) control
            control.actionFunc()
        end
        button:addTouchHandler(button.buttonCallback, self)
        control.button = button
        self:addChild(button)
        table.insert(self.hudControls, control)
    end
    self.buttons = {}
    self.controlButtons = {}
    self.hudElements = {}
    local posX, posY = self:getPosition()
    local control = ControlBarDisplay.POSITION.GAMEPAD_OFFSET
    local offsetX, _ = getNormalizedScreenValues(unpack(control))
    self.positionTouch = { posX + offsetX, posY + _ }
    self.positionGamepad = { posX, posY }
end
function ControlBarDisplay:setVehicle(vehicle)
    self.vehicle = vehicle
    self:updatePositionState()
    self:updateFillLevelBuffers(vehicle)
    self:updateButtons()
    if self.buttonToggleSeeds ~= nil then
        local glyphOverlay = self.buttonToggleSeeds.glyphElement.overlay
        function glyphOverlay.getIsVisible()
            -- upvalues: (copy) glyphOverlay, (copy) self
            return glyphOverlay.visible and self.sowingMachine ~= nil and #self.sowingMachine.spec_sowingMachine.seeds > 1
        end
    end
end
function ControlBarDisplay:setPlayer(player)
    self.player = player
    self:updatePositionState()
end
function ControlBarDisplay:update(dt)
    ControlBarDisplay:superClass().update(self, dt)
    self:updateButtons()
    self:updateButtonPositions()
end
function ControlBarDisplay:updateButtons()
    local currentVehicle = self.vehicle
    self.sowingMachine = nil
    if self.vehicle ~= nil then
        for _, childVehicle in ipairs(self.vehicle.childVehicles) do
            if childVehicle.spec_sowingMachine ~= nil then
                self.sowingMachine = childVehicle
                break
            end
        end
    end
    self:updateFillLevelBuffers(currentVehicle)
    for _, childVehicle in pairs(self.vehicleControls) do
        local vehicle = nil
        local isAvailable = false
        local isAccessible = false
        if currentVehicle ~= nil then
            local availableFunc = currentVehicle[childVehicle.availableFunc]
            if availableFunc ~= nil then
                isAvailable = availableFunc(currentVehicle)
                if isAvailable then
                    vehicle = currentVehicle
                elseif childVehicle.useAttachables and currentVehicle.getAttachedImplements ~= nil then
                    for _, implement in ipairs(currentVehicle:getAttachedImplements()) do
                        local availableFunc = implement.object[childVehicle.availableFunc]
                        if availableFunc ~= nil then
                            isAvailable = availableFunc(implement.object)
                            vehicle = implement.object
                        end
                    end
                end
            end
        end
        if vehicle ~= nil then
            local availableFunc = vehicle[childVehicle.accessibleFunc]
            if availableFunc ~= nil then
                isAccessible = availableFunc(vehicle)
            end
            local iconsChanged = false
            if childVehicle.getIconsFunc ~= nil then
                local getIconsFunc = vehicle[childVehicle.getIconsFunc]
                if getIconsFunc ~= nil then
                    local uvNegStr, _, implement = getIconsFunc(vehicle)
                    local uvs_neg = ControlBarDisplay.UV[uvNegStr]
                    local uvs_pos = ControlBarDisplay.UV[_]
                    local iconColor_neg = ControlBarDisplay.COLOR.BUTTON_ACTIVE
                    local iconColor_pos = ControlBarDisplay.COLOR.BUTTON
                    if not implement then
                        iconColor_neg = ControlBarDisplay.COLOR.BUTTON
                    end
                    if uvs_pos ~= childVehicle.uvs_pos or uvs_neg ~= childVehicle.uvs_neg then
                        childVehicle.uvs_pos = uvs_pos
                        childVehicle.uvs_neg = uvs_neg
                        iconsChanged = true
                    end
                    if iconColor_pos ~= childVehicle.iconColor_pos or iconColor_neg ~= childVehicle.iconColor_neg then
                        childVehicle.iconColor_pos = iconColor_pos
                        childVehicle.iconColor_neg = iconColor_neg
                        iconsChanged = true
                    end
                end
            end
            if childVehicle.directionFunc ~= nil then
                local getIconsFunc = vehicle[childVehicle.directionFunc]
                if getIconsFunc ~= nil then
                    local uvNegStr = getIconsFunc(vehicle)
                    if type(uvNegStr) == "boolean" then
                    end
                    if uvNegStr ~= childVehicle.lastDirection or iconsChanged then
                        local implement = uvNegStr == 1 and childVehicle.uvs_pos or childVehicle.uvs_neg
                        if implement ~= nil and implement ~= childVehicle.uvs then
                            childVehicle.button:setIcon(nil, nil, nil, GuiUtils.getUVs(implement), nil, nil)
                            childVehicle.uvs = implement
                        end
                        local uvs_neg = uvNegStr == 1 and childVehicle.iconColor_pos or childVehicle.iconColor_neg
                        if uvs_neg ~= nil and uvs_neg ~= childVehicle.color then
                            _:setIcon(nil, nil, nil, nil, nil, nil, uvs_neg)
                            childVehicle.color = uvs_neg
                        end
                        childVehicle.lastDirection = uvNegStr
                    end
                end
            end
        end
        childVehicle.vehicle = vehicle
        childVehicle.button:setVisible(isAvailable)
        childVehicle.button:setDisabled(not isAccessible or g_gui:getIsGuiVisible())
    end
    local player = self.player
    for childVehicle, vehicle in pairs(self.playerControls) do
        local isAvailable = false
        if player ~= nil then
            local isAccessible = player[vehicle.availableFunc]
            if isAccessible ~= nil then
                isAvailable = isAccessible(player)
            end
        end
        vehicle.button:setVisible(isAvailable)
        vehicle.button:setDisabled(g_gui:getIsGuiVisible())
    end
    for childVehicle, vehicle in pairs(self.customControls) do
        local isAvailable = vehicle.availableFunc(self)
        vehicle.button:setVisible(isAvailable)
        vehicle.button:setDisabled(g_gui:getIsGuiVisible())
    end
end
function ControlBarDisplay:updateButtonPositions()
    local posX, posY = self:getPosition()
    table.sort(self.hudControls, function(a, b)
        return a.prio < b.prio
    end)
    for _, control in ipairs(self.hudControls) do
        if control.button:getVisible() then
            control.button:setPosition(posX, posY)
            posX = posX + control.button:getWidth() + self.buttonOffsetX * self.uiScale
        end
    end
end
function ControlBarDisplay:onInputHelpModeChange(inputHelpMode, force)
    self.lastInputHelpMode = inputHelpMode
    self:updatePositionState(force)
end
function ControlBarDisplay:onAIVehicleStateChanged(state, _, force)
    self.lastAIState = state
    self:updatePositionState(force)
end
function ControlBarDisplay:onGyroscopeSteeringChanged(state)
    self.lastGyroscopeSteeringState = state
    self:updatePositionState()
end
function ControlBarDisplay:getIsActivatableObjectAvailable()
    return g_currentMission.activatableObjectsSystem:getActivatable() ~= nil
end
function ControlBarDisplay:triggerActivatableObject()
    local object = g_currentMission.activatableObjectsSystem:getActivatable()
    if object ~= nil then
        object:run()
    end
end
function ControlBarDisplay:updatePositionState(force)
    if Platform.hasTouchSliders and (self.player ~= nil and self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD) then
        self:setPositionState(ControlBarDisplay.STATE_TOUCH, force)
        return
    else
        local isControllerInput = not Platform.hasTouchSliders
        if not isControllerInput then
            isControllerInput = true
            if self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD then
                isControllerInput = self.lastGyroscopeSteeringState
            end
        end
        if isControllerInput then
            self:setPositionState(ControlBarDisplay.STATE_CONTROLLER, force)
        else
            self:setPositionState(ControlBarDisplay.STATE_TOUCH, force)
        end
    end
end
function ControlBarDisplay:setPositionState(state, force)
    if Platform.hasTouchSliders then
        if state ~= self.lastPositionState then
            local startX, startY = self:getPosition()
            local targetX = self.positionGamepad[1]
            local targetY = self.positionGamepad[2]
            local speed = ControlBarDisplay.MOVE_ANIMATION_DURATION
            if state == ControlBarDisplay.STATE_TOUCH then
                targetX = self.positionTouch[1]
                targetY = self.positionTouch[2]
                speed = ControlBarDisplay.MOVE_ANIMATION_DURATION / 5
            end
            local sequence = TweenSequence.new(self)
            sequence:insertTween(MultiValueTween.new(self.setPosition, { startX, startY }, { targetX, targetY }, force and 0.01 or speed), 0)
            sequence:start()
            self.animation = sequence
            self.lastPositionState = state
        end
    end
end
function ControlBarDisplay:addFillLevelControl()
    local fillLevelControl = {}
    local button = HUDButtonElement.new(self.hud, 0, 0)
    button:setIcon(nil, self.fillLevelIconSizeX, self.fillLevelIconSizeY, Overlay.DEFAULT_UVS, self.fillLevelIconOffsetX, self.fillLevelIconOffsetY)
    button:setAction(InputAction.TOGGLE_SEEDS)
    button:addTouchHandler(ControlBarDisplay.onChangeSeedCallback, fillLevelControl)
    self:addChild(button)
    fillLevelControl.button = button
    fillLevelControl.prio = #self.fillLevelControls + 1
    table.insert(self.fillLevelControls, fillLevelControl)
    local uvs = GuiUtils.getUVs(ControlBarDisplay.UV.FILL_LEVEL_BAR)
    local posX, posY = button:getPosition()
    local offsetX, offsetY = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.FILL_LEVEL_BAR_OFFSET))
    local sizeX, sizeY = getNormalizedScreenValues(unpack(ControlBarDisplay.SIZE.FILL_LEVEL_BAR))
    Overlay.new(self.hudAtlasPath, posX + offsetX, posY + offsetY, sizeX, sizeY):setColor(unpack(ControlBarDisplay.COLOR.FILL_LEVEL_BAR_BACKGROUND))
    backgroundOverlay:setUVs(uvs)
    local fillLevelBarBackground = HUDElement.new(backgroundOverlay)
    button:addChild(fillLevelBarBackground)
    local fillLevelBarOverlay = Overlay.new(self.hudAtlasPath, posX + offsetX, posY + offsetY, sizeX, sizeY)
    local fillLevelBar = HUDElement.new(fillLevelBarOverlay)
    fillLevelBar:setUVs(uvs)
    fillLevelBar:setColor(unpack(ControlBarDisplay.COLOR.FILL_LEVEL_BAR))
    fillLevelBarBackground:addChild(fillLevelBar)
    fillLevelControl.bar = fillLevelBar
    fillLevelControl.defaultUVs = table.clone(uvs)
    return fillLevelControl
end
function ControlBarDisplay:addFillLevel(fillType, fillLevel, capacity, precision, maxReached)
    local added = false
    local j = 1
    for j = j, #self.fillLevelBuffer do
        local fillLevelInformation = self.fillLevelBuffer[j]
        if fillLevelInformation.fillType == fillType then
            fillLevelInformation.fillLevel = fillLevelInformation.fillLevel + fillLevel
            fillLevelInformation.capacity = fillLevelInformation.capacity + capacity
            fillLevelInformation.precision = precision
            fillLevelInformation.maxReached = maxReached
            if self.fillLevelBufferAddIndex ~= fillLevelInformation.addIndex then
                fillLevelInformation.addIndex = self.fillLevelBufferAddIndex
                self.fillLevelBufferNeedsSorting = true
            end
            added = true
            break
        end
    end
    if not added then
        table.insert(self.fillLevelBuffer, {
            ["fillType"] = fillType,
            ["fillLevel"] = fillLevel,
            ["capacity"] = capacity,
            ["precision"] = precision,
            ["addIndex"] = self.fillLevelBufferAddIndex,
            ["maxReached"] = maxReached
        })
        self.fillLevelBufferNeedsSorting = true
    end
    self.fillLevelBufferAddIndex = self.fillLevelBufferAddIndex + 1
end
function ControlBarDisplay:updateFillLevelBuffers(vehicle)
    local i = 1
    local displayIndex = #self.fillLevelControls
    for i = i, displayIndex do
        self.fillLevelControls[i].fillLevelPct = 0
        self.fillLevelControls[i].button:setVisible(false)
    end
    if vehicle ~= nil then
        local i = 1
        local displayIndex = #self.fillLevelBuffer
        for i = i, displayIndex do
            self.fillLevelBuffer[i].fillLevel = 0
            self.fillLevelBuffer[i].capacity = 0
        end
        self.fillLevelBufferAddIndex = 0
        self.fillLevelBufferNeedsSorting = false
        vehicle:getFillLevelInformation(self)
        if self.fillLevelBufferNeedsSorting then
            table.sort(self.fillLevelBuffer, ControlBarDisplay.sortFillLevelBuffers)
        end
        self.buttonToggleSeeds = nil
        self.buttonShowFillLevel = nil
        local displayIndex = 0
        local i = 1
        local i = 1
        for i = i, #self.fillLevelBuffer, i do
            if self.fillLevelBuffer[i].capacity ~= 0 then
                displayIndex = displayIndex + 1
                local fillLevelControl = self.fillLevelControls[displayIndex]
                if fillLevelControl ~= nil then
                    self:updateFillLevelControl(fillLevelControl, self.fillLevelBuffer[i])
                end
            end
        end
    end
end
function ControlBarDisplay.sortFillLevelBuffers(a, b)
    return a.addIndex < b.addIndex
end
function ControlBarDisplay:updateFillLevelControl(fillLevelControl, fillLevelBuffer)
    local fillLevelPct = fillLevelBuffer.fillLevel / fillLevelBuffer.capacity
    fillLevelControl.fillLevelPct = fillLevelPct
    local bar = fillLevelControl.bar.overlay
    bar.uvs[5] = (fillLevelControl.defaultUVs[5] - fillLevelControl.defaultUVs[1]) * fillLevelPct + fillLevelControl.defaultUVs[1]
    bar.uvs[7] = (fillLevelControl.defaultUVs[7] - fillLevelControl.defaultUVs[3]) * fillLevelPct + fillLevelControl.defaultUVs[3]
    bar:setUVs(bar.uvs)
    bar:setScale(fillLevelPct * self.uiScale, self.uiScale)
    local fillType = g_fillTypeManager:getFillTypeByIndex(fillLevelBuffer.fillType)
    if fillType ~= nil then
        local iconFilename = fillType.hudOverlayFilename
        if iconFilename ~= "" then
            fillLevelControl.button:setIcon(iconFilename)
        end
    end
    fillLevelControl.vehicle = nil
    local iconFilename = fillLevelControl.button
    if self.sowingMachine == nil then
        self.buttonShowFillLevel = iconFilename
    else
        if self.sowingMachine:getSowingMachineSeedFillTypeIndex() == fillLevelBuffer.fillType then
            fillLevelControl.vehicle = self.sowingMachine
        end
        self.buttonToggleSeeds = iconFilename
    end
    iconFilename:setIsActive(fillLevelControl.vehicle ~= nil)
    iconFilename:setVisible(fillLevelBuffer.fillLevel > 0 or fillLevelControl.vehicle ~= nil)
end
function ControlBarDisplay.onChangeSeedCallback(fillLevelControl, _, _)
    if not g_sleepManager:getIsSleeping() then
        if fillLevelControl.vehicle ~= nil and not fillLevelControl.vehicle:getIsAIActive() then
            fillLevelControl.vehicle:changeSeedIndex(1)
        end
    end
end
function ControlBarDisplay:setScale(uiScale)
    ControlBarDisplay:superClass().setScale(self, uiScale, uiScale)
    local currentVisibility = self:getVisible()
    self:setVisible(true, false)
    self.uiScale = uiScale
    local posX, posY = ControlBarDisplay.getBackgroundPosition(uiScale, self:getWidth())
    self:setPosition(posX, posY)
    local offsetX, offsetY = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.GAMEPAD_OFFSET))
    self.positionTouch = { posX + offsetX * uiScale, posY + offsetY * uiScale }
    self.positionGamepad = { posX, posY }
    self:storeOriginalPosition()
    self:setVisible(currentVisibility, false)
    if self.lastPositionState == ControlBarDisplay.STATE_TOUCH then
        self:setPosition(self.positionTouch[1], self.positionTouch[2])
    end
end
function ControlBarDisplay.getBackgroundPosition(scale, _)
    local offX, offY = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.BACKGROUND))
    return offX * scale, offY * scale
end
function ControlBarDisplay.createBackground()
    local width, height = getNormalizedScreenValues(unpack(ControlBarDisplay.SIZE.BACKGROUND))
    local posX, posY = ControlBarDisplay.getBackgroundPosition(1, width)
    return Overlay.new(nil, posX, posY, width, height)
end
ControlBarDisplay.SIZE = {
    ["BACKGROUND"] = { 736, 106 },
    ["ICON"] = { 84, 84 },
    ["FILL_LEVEL_ICON"] = { 75, 75 },
    ["FILL_LEVEL_BAR"] = { 82, 21 },
    ["ENTER_CABIN_GLYPH"] = { 80, 80 }
}
ControlBarDisplay.POSITION = {
    ["BACKGROUND"] = { 320, 50 },
    ["BUTTON_START"] = { 0, 0 },
    ["BUTTON_OFFSET"] = { 20, 0 },
    ["FILL_LEVEL_ICON_OFFSET"] = { 13, 25 },
    ["FILL_LEVEL_BAR_OFFSET"] = { 11, 7 },
    ["GAMEPAD_OFFSET"] = { 515, 0 }
}
ControlBarDisplay.COLOR = {
    ["FILL_LEVEL_BAR"] = {
        0.3763,
        0.6038,
        0.0782,
        1
    },
    ["FILL_LEVEL_BAR_BACKGROUND"] = {
        0.172549,
        0.172549,
        0.172549,
        1
    },
    ["BUTTON"] = {
        1,
        1,
        1,
        1
    },
    ["BUTTON_ACTIVE"] = {
        0.3763,
        0.6038,
        0.0782,
        1
    }
}
ControlBarDisplay.UV = {
    ["FILL_LEVEL_BAR"] = {
        480,
        21,
        82,
        21
    },
    ["DETACH"] = {
        480,
        0,
        96,
        96
    },
    ["TURN_ON"] = {
        384,
        0,
        96,
        96
    },
    ["AUTO_LOAD"] = {
        96,
        0,
        96,
        96
    },
    ["LOAD_LOG"] = {
        192,
        0,
        96,
        96
    },
    ["LOADER_LOWER"] = {
        192,
        96,
        96,
        96
    },
    ["LOADER_LIFT"] = {
        288,
        96,
        96,
        96
    },
    ["WOOD_SAW"] = {
        384,
        96,
        96,
        96
    },
    ["AI"] = {
        288,
        0,
        96,
        96
    },
    ["LEAVE_VEHICLE"] = {
        672,
        0,
        96,
        96
    },
    ["ENTER_VEHICLE"] = {
        576,
        0,
        96,
        96
    },
    ["ENTER_HORSE"] = {
        672,
        96,
        96,
        96
    },
    ["LEAVE_HORSE"] = {
        768,
        96,
        96,
        96
    },
    ["ACTIVATABLE_OBJECT"] = {
        0,
        0,
        96,
        96
    },
    ["UNLOAD_FORK"] = {
        96,
        288,
        96,
        96
    }
}
if data ~= nil then
    local controlBarDisplay = ControlBarDisplay.new(data.hud, data.hudAtlasPath, data.controlHudAtlasPath)
    controlBarDisplay:setScale(data.uiScale)
    controlBarDisplay:setVehicle(data.vehicle)
    controlBarDisplay:setPlayer(data.player)
    for k, elem in ipairs(g_currentMission.hud.displayComponents) do
        if elem == g_currentMission.hud.controlBarDisplay then
            g_currentMission.hud.displayComponents[k] = controlBarDisplay
            break
        end
    end
    g_currentMission.hud.controlBarDisplay = controlBarDisplay
    Logging.info("Reloaded")
end