local data = nil
if SpeedMeterDisplay ~= nil then
    local old = g_currentMission.hud.speedMeter
    data = {
        ["vehicle"] = old.vehicle,
        ["uiScale"] = old.uiScale,
        ["isVisible"] = old:getVisible()
    }
    old:delete()
end
SpeedMeterDisplay = {}
SpeedMeterDisplay.GAUGE_MODE_RPM = 1
SpeedMeterDisplay.GAUGE_MODE_SPEED = 2
SpeedMeterDisplay.NUMBER_OF_INDICATORS = 24
SpeedMeterDisplay.FUEL_LOW_PERCENTAGE = 0.1
local old = Class(SpeedMeterDisplay, HUDDisplay)
function SpeedMeterDisplay.new()
    -- upvalues: (copy) old
    local self = SpeedMeterDisplay:superClass().new(old)
    self.vehicle = nil
    self.isVehicleDrawSafe = false
    local r, g, b, a = unpack(HUD.COLOR.ACTIVE)
    self.speedBg = g_overlayManager:createOverlay("gui.speedBg", 0, 0, 0, 0)
    self.speedBgScale = g_overlayManager:createOverlay("gui.speedBgScale", 0, 0, 0, 0)
    self.speedBgRight = g_overlayManager:createOverlay("gui.speedBgRight", 0, 0, 0, 0)
    self.speedIndicatorBg = g_overlayManager:createOverlay("gui.speedGaugeBg", 0, 0, 0, 0)
    self.workingHours = g_overlayManager:createOverlay("gui.icon_usage", 0, 0, 0, 0)
    self.workingHours:setColor(r, g, b, a)
    self.cruiseControl = g_overlayManager:createOverlay("gui.icon_tempomat", 0, 0, 0, 0)
    self.cruiseControl:setColor(r, g, b, a)
    self.aiWorkerIcon = g_overlayManager:createOverlay("gui.icon_gps", 0, 0, 0, 0)
    self.aiWorkerIcon:setColor(r, g, b, a)
    self.aiSteeringIcon = g_overlayManager:createOverlay("gui.icon_guidance", 0, 0, 0, 0)
    self.aiSteeringIcon:setColor(r, g, b, a)
    self.fuelIcon = g_overlayManager:createOverlay("gui.icon_fuel", 0, 0, 0, 0)
    self.repairIcon = g_overlayManager:createOverlay("gui.icon_repair", 0, 0, 0, 0)
    self.bar = ThreePartOverlay.new()
    self.bar:setLeftPart("gui.progressbar_left", 0, 0)
    self.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
    self.bar:setRightPart("gui.progressbar_right", 0, 0)
    self.bar:setRotation(1.5707963267948966)
    self.gearIcon = g_overlayManager:createOverlay("gui.icon_gear", 0, 0, 0, 0)
    self.gearBg = g_overlayManager:createOverlay("gui.gearBg", 0, 0, 0, 0)
    self.gearBg:setColor(r, g, b, a)
    self.gearTexts = { "A", "B", "C" }
    self.gearWarningTime = 0
    self.lastGaugeValue = 0
    self.rpmUnitText = g_i18n:getText("unit_rpmShort")
    self.kmhUnitText = g_i18n:getText("unit_kmh")
    self.mphUnitText = g_i18n:getText("unit_mph")
    self.aiInactiveText = g_i18n:getText("ui_gpsInactive")
    self.aiReadyText = g_i18n:getText("ui_gpsReady")
    self.aiActiveText = g_i18n:getText("ui_gpsActive")
    return self
end
function SpeedMeterDisplay:delete()
    self.speedBg:delete()
    self.speedBgScale:delete()
    self.speedBgRight:delete()
    self.speedIndicatorBg:delete()
    self.workingHours:delete()
    self.cruiseControl:delete()
    self.fuelIcon:delete()
    self.repairIcon:delete()
    self.gearIcon:delete()
    self.gearBg:delete()
    self.bar:delete()
    self.aiWorkerIcon:delete()
    self.aiSteeringIcon:delete()
end
function SpeedMeterDisplay:storeScaledValues()
    self:setPosition(g_hudAnchorRight, g_hudAnchorBottom)
    local speedBgWidth, speedBgHeight = self:scalePixelValuesToScreenVector(232, 232)
    self.speedBg:setDimension(speedBgWidth, speedBgHeight)
    self.speedBgScale:setDimension(0, speedBgHeight)
    local speedBgRightWidth, speedBgRightHeight = self:scalePixelValuesToScreenVector(23, 232)
    self.speedBgRight:setDimension(speedBgRightWidth, speedBgRightHeight)
    local speedGaugeBgWidth, speedGaugeBgHeight = self:scalePixelValuesToScreenVector(13, 23)
    self.speedIndicatorBg:setDimension(speedGaugeBgWidth, speedGaugeBgHeight)
    local addOffset, x = self:scalePixelValuesToScreenVector(117, 116)
    self.speedGaugeCenterOffsetX = addOffset
    self.speedGaugeCenterOffsetY = x
    local addOffset, x = self:scalePixelValuesToScreenVector(68, 68)
    self.speedGaugeRadiusX = addOffset
    self.speedGaugeRadiusY = x
    self.gaugeTextOffsets = {}
    local cruiseControlHeight, fuelIconWidth = self:scalePixelValuesToScreenVector(-57, -33)
    table.insert(self.gaugeTextOffsets, {
        ["offsetX"] = cruiseControlHeight,
        ["offsetY"] = fuelIconWidth,
        ["alignment"] = RenderText.ALIGN_LEFT
    })
    local cruiseControlHeight, fuelIconWidth = self:scalePixelValuesToScreenVector(-64, -7)
    table.insert(self.gaugeTextOffsets, {
        ["offsetX"] = cruiseControlHeight,
        ["offsetY"] = fuelIconWidth,
        ["alignment"] = RenderText.ALIGN_LEFT
    })
    local cruiseControlHeight, fuelIconWidth = self:scalePixelValuesToScreenVector(-60, 19)
    table.insert(self.gaugeTextOffsets, {
        ["offsetX"] = cruiseControlHeight,
        ["offsetY"] = fuelIconWidth,
        ["alignment"] = RenderText.ALIGN_LEFT
    })
    local cruiseControlHeight, fuelIconWidth = self:scalePixelValuesToScreenVector(-46, 40)
    table.insert(self.gaugeTextOffsets, {
        ["offsetX"] = cruiseControlHeight,
        ["offsetY"] = fuelIconWidth,
        ["alignment"] = RenderText.ALIGN_LEFT
    })
    local cruiseControlHeight, fuelIconWidth = self:scalePixelValuesToScreenVector(-22, 54)
    table.insert(self.gaugeTextOffsets, {
        ["offsetX"] = cruiseControlHeight,
        ["offsetY"] = fuelIconWidth,
        ["alignment"] = RenderText.ALIGN_LEFT
    })
    local cruiseControlHeight, fuelIconWidth = self:scalePixelValuesToScreenVector(22, 54)
    table.insert(self.gaugeTextOffsets, {
        ["offsetX"] = cruiseControlHeight,
        ["offsetY"] = fuelIconWidth,
        ["alignment"] = RenderText.ALIGN_RIGHT
    })
    local cruiseControlHeight, fuelIconWidth = self:scalePixelValuesToScreenVector(46, 40)
    table.insert(self.gaugeTextOffsets, {
        ["offsetX"] = cruiseControlHeight,
        ["offsetY"] = fuelIconWidth,
        ["alignment"] = RenderText.ALIGN_RIGHT
    })
    local cruiseControlHeight, fuelIconWidth = self:scalePixelValuesToScreenVector(60, 19)
    table.insert(self.gaugeTextOffsets, {
        ["offsetX"] = cruiseControlHeight,
        ["offsetY"] = fuelIconWidth,
        ["alignment"] = RenderText.ALIGN_RIGHT
    })
    local cruiseControlHeight, fuelIconWidth = self:scalePixelValuesToScreenVector(64, -7)
    table.insert(self.gaugeTextOffsets, {
        ["offsetX"] = cruiseControlHeight,
        ["offsetY"] = fuelIconWidth,
        ["alignment"] = RenderText.ALIGN_RIGHT
    })
    local cruiseControlHeight, fuelIconWidth = self:scalePixelValuesToScreenVector(57, -33)
    table.insert(self.gaugeTextOffsets, {
        ["offsetX"] = cruiseControlHeight,
        ["offsetY"] = fuelIconWidth,
        ["alignment"] = RenderText.ALIGN_RIGHT
    })
    local x, y = self:scalePixelValuesToScreenVector(58, 58)
    self.gaugeTextRadiusX = x
    self.gaugeTextRadiusY = y
    self.gaugeUnitTextSize = self:scalePixelToScreenHeight(9)
    self.gaugeFactorTextSize = self:scalePixelToScreenHeight(9)
    local x, y = self:scalePixelValuesToScreenVector(-64, -50)
    self.gaugeUnitOffsetX = x
    self.gaugeUnitOffsetY = y
    local x, y = self:scalePixelValuesToScreenVector(64, -50)
    self.gaugeFactorOffsetX = x
    self.gaugeFactorOffsetY = y
    self.speedTextSize = self:scalePixelToScreenHeight(52)
    local x, y = self:scalePixelValuesToScreenVector(0, -12)
    self.speedTextOffsetX = x
    self.speedTextOffsetY = y
    self.speedUnitTextSize = self:scalePixelToScreenHeight(15)
    local x, y = self:scalePixelValuesToScreenVector(0, -27)
    self.speedUnitTextOffsetX = x
    self.speedUnitTextOffsetY = y
    local x, y = self:scalePixelValuesToScreenVector(-45, -73)
    self.workingHoursOffsetX = x
    self.workingHoursOffsetY = y
    local x, y = self:scalePixelValuesToScreenVector(30, 30)
    self.workingHours:setDimension(x, y)
    self.workingHoursTextSize = self:scalePixelToScreenHeight(17)
    local alignment, cruiseControlHeight = self:scalePixelValuesToScreenVector(35, -64)
    self.workingHoursTextOffsetX = alignment
    self.workingHoursTextOffsetY = cruiseControlHeight
    local alignment, cruiseControlHeight = self:scalePixelValuesToScreenVector(-39, -43)
    self.workingHoursSeperatorOffsetX = alignment
    self.workingHoursSeperatorOffsetY = cruiseControlHeight
    local alignment, cruiseControlHeight = self:scalePixelValuesToScreenVector(-30, -100)
    self.cruiseControlOffsetX = alignment
    self.cruiseControlOffsetY = cruiseControlHeight
    local alignment, cruiseControlHeight = self:scalePixelValuesToScreenVector(30, 30)
    self.cruiseControl:setDimension(alignment, cruiseControlHeight)
    self.cruiseControlTextSize = self:scalePixelToScreenHeight(17)
    local fuelIconWidth, fuelIconHeight = self:scalePixelValuesToScreenVector(2, -94)
    self.cruiseControlTextOffsetX = fuelIconWidth
    self.cruiseControlTextOffsetY = fuelIconHeight
    local fuelIconWidth, fuelIconHeight = self:scalePixelValuesToScreenVector(-39, -73)
    self.cruiseControlSeperatorOffsetX = fuelIconWidth
    self.cruiseControlSeperatorOffsetY = fuelIconHeight
    self.seperatorWidth = self:scalePixelToScreenWidth(78)
    local fuelIconWidth, fuelIconHeight = self:scalePixelValuesToScreenVector(9, 47)
    self.sectionOffsetX = fuelIconWidth
    self.sectionOffsetY = fuelIconHeight
    local fuelIconWidth, fuelIconHeight = self:scalePixelValuesToScreenVector(30, 30)
    self.fuelIcon:setDimension(fuelIconWidth, fuelIconHeight)
    local repairWidth, repairHeight = self:scalePixelValuesToScreenVector(-16, 144)
    self.fuelIconOffsetX = repairWidth
    self.fuelIconOffsetY = repairHeight
    self.fuelBarScaleWidth = self:scalePixelToScreenWidth(21)
    local repairWidth, repairHeight = self:scalePixelValuesToScreenVector(0, 0)
    self.fuelBarOffsetX = repairWidth
    self.fuelBarOffsetY = repairHeight
    local repairWidth, repairHeight = self:scalePixelValuesToScreenVector(-30, 0)
    self.fuelOffsetX = repairWidth
    self.fuelOffsetY = repairHeight
    local repairWidth, repairHeight = self:scalePixelValuesToScreenVector(25, 30)
    self.repairIcon:setDimension(repairWidth, repairHeight)
    local gearWidth, gearHeight = self:scalePixelValuesToScreenVector(-16, 144)
    self.repairIconOffsetX = gearWidth
    self.repairIconOffsetY = gearHeight
    local gearWidth, gearHeight = self:scalePixelValuesToScreenVector(0, 0)
    self.repairBarOffsetX = gearWidth
    self.repairBarOffsetY = gearHeight
    self.repairBarScaleWidth = self:scalePixelToScreenWidth(21)
    local gearWidth, gearHeight = self:scalePixelValuesToScreenVector(-30, 0)
    self.repairOffsetX = gearWidth
    self.repairOffsetY = gearHeight
    local gearWidth, gearHeight = self:scalePixelValuesToScreenVector(30, 30)
    self.gearIcon:setDimension(gearWidth, gearHeight)
    local gearBgWidth, gearBgHeight = self:scalePixelValuesToScreenVector(-16, 144)
    self.gearIconOffsetX = gearBgWidth
    self.gearIconOffsetY = gearBgHeight
    self.gearBarScaleWidth = self:scalePixelToScreenWidth(30)
    local gearBgWidth, gearBgHeight = self:scalePixelValuesToScreenVector(-30, 0)
    self.gearOffsetX = gearBgWidth
    self.gearOffsetY = gearBgHeight
    local gearBgWidth, gearBgHeight = self:scalePixelValuesToScreenVector(26, 26)
    self.gearBg:setDimension(gearBgWidth, gearBgHeight)
    self.gearTextOffsetY = {}
    self.gearTextOffsetY[1] = self:scalePixelToScreenHeight(9)
    self.gearTextOffsetY[2] = self:scalePixelToScreenHeight(37)
    self.gearTextOffsetY[3] = self:scalePixelToScreenHeight(65)
    self.gearGroupTextOffsetY = self:scalePixelToScreenHeight(102)
    self.gearTextSize = self:scalePixelToScreenHeight(12)
    self.gearBgOffsetX = self:scalePixelToScreenWidth(-13)
    local offsetY = self:scalePixelToScreenHeight(-8)
    self.gearBgOffsetY = {}
    self.gearBgOffsetY[1] = self.gearTextOffsetY[1] + offsetY
    self.gearBgOffsetY[2] = self.gearTextOffsetY[2] + offsetY
    self.gearBgOffsetY[3] = self.gearTextOffsetY[3] + offsetY
    local barPartWidth, barPartHeight = self:scalePixelValuesToScreenVector(6, 6)
    local barTotalWidth, _ = self:scalePixelValuesToScreenVector(130, 0)
    self.barMaxScaleWidth = barTotalWidth - 2 * barPartWidth
    self.bar:setLeftPart(nil, barPartWidth, barPartHeight)
    self.bar:setMiddlePart(nil, self.barMaxScaleWidth, barPartHeight)
    self.bar:setRightPart(nil, barPartWidth, barPartHeight)
    local aiIconWidth, aiIconHeight = self:scalePixelValuesToScreenVector(30, 30)
    self.aiWorkerIcon:setDimension(aiIconWidth, aiIconHeight)
    self.aiSteeringIcon:setDimension(aiIconWidth, aiIconHeight)
    self.aiIconOffsetX, self.aiIconOffsetY = self:scalePixelValuesToScreenVector(-109, 2)
    self.aiTextOffsetX, self.aiTextOffsetY = self:scalePixelValuesToScreenVector(-49, 12)
    self.aiTextSize = self:scalePixelToScreenHeight(16)
    self.aiSeperatorOffsetX, self.aiSeperatorOffsetY = self:scalePixelValuesToScreenVector(-114, 34)
    self.aiSeperatorWidth = self:scalePixelToScreenWidth(100)
end
function SpeedMeterDisplay:update(dt)
    SpeedMeterDisplay:superClass().update(self, dt)
    self.isVehicleDrawSafe = true
end
function SpeedMeterDisplay:draw()
    local vehicle = self.vehicle
    if vehicle ~= nil and self.isVehicleDrawSafe then
        local scaleWidth = 0
        local hasFuel = false
        local fuelLevel = nil
        local fuelCapacity = nil
        if vehicle.spec_motorized ~= nil then
            local posX
            fuelLevel, fuelCapacity, posX = SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
            hasFuel = fuelCapacity ~= nil
        end
        local hasRepair = false
        if vehicle.getDamageAmount ~= nil and vehicle:getDamageAmount() ~= nil then
            hasRepair = true
        end
        local scaleWidth = scaleWidth + self.gearBarScaleWidth
        local posX, posY = self:getPosition()
        self.speedBgRight:setPosition(posX - self.speedBgRight.width, posY)
        self.speedBgScale:setDimension(scaleWidth, nil)
        self.speedBgScale:setPosition(self.speedBgRight.x - self.speedBgScale.width, posY)
        self.speedBg:setPosition(self.speedBgScale.x - self.speedBg.width, posY)
        self.speedBg:render()
        self.speedBgScale:render()
        self.speedBgRight:render()
        self:drawSpeedMeter(self.speedBg.x + self.speedGaugeCenterOffsetX, self.speedBg.y + self.speedGaugeCenterOffsetY)
        if vehicle.getAIAutomaticSteeringState ~= nil then
            local selectedAIMode = vehicle:getAIModeSelection()
            local activeColor = HUD.COLOR.ACTIVE
            local startX = posX + self.aiSeperatorOffsetX
            local startY = posY + self.aiSeperatorOffsetY
            drawLine2D(startX, startY, startX + self.aiSeperatorWidth, startY, g_pixelSizeY, activeColor[1], activeColor[2], activeColor[3], activeColor[4])
            local timeSinceLastModeChange = g_time - vehicle.spec_aiModeSelection.lastModeChangeTime
            if timeSinceLastModeChange < 2500 then
                local modeName = g_i18n:getText(AIModeSelection.MODE_TEXTS[selectedAIMode])
                local alpha = math.sin(timeSinceLastModeChange / 2500 * 3.141592653589793 * 3 - 1.5707963267948966) * 0.5 + 0.5
                setTextColor(HUD.COLOR.ACTIVE[1], HUD.COLOR.ACTIVE[2], HUD.COLOR.ACTIVE[3], alpha)
                setTextAlignment(RenderText.ALIGN_CENTER)
                renderText(startX + self.aiSeperatorWidth * 0.5, posY + self.aiTextOffsetY, self.aiTextSize, modeName)
            else
                local modeName = self.aiWorkerIcon
                local alpha = self.aiInactiveText
                local r = 1
                local g = 1
                local b = 1
                local a = 1
                if selectedAIMode == AIModeSelection.MODE.STEERING_ASSIST then
                    modeName = self.aiSteeringIcon
                    local steeringState = vehicle:getAIAutomaticSteeringState()
                    if steeringState == AIAutomaticSteering.STATE.AVAILABLE then
                        r = HUD.COLOR.AVAILABLE[1]
                        g = HUD.COLOR.AVAILABLE[2]
                        b = HUD.COLOR.AVAILABLE[3]
                        a = HUD.COLOR.AVAILABLE[4]
                        alpha = self.aiReadyText
                    elseif steeringState == AIAutomaticSteering.STATE.ACTIVE then
                        r = HUD.COLOR.ACTIVE[1]
                        g = HUD.COLOR.ACTIVE[2]
                        b = HUD.COLOR.ACTIVE[3]
                        a = HUD.COLOR.ACTIVE[4]
                        alpha = self.aiActiveText
                    end
                elseif vehicle:getIsAIActive() then
                    r = HUD.COLOR.ACTIVE[1]
                    g = HUD.COLOR.ACTIVE[2]
                    b = HUD.COLOR.ACTIVE[3]
                    a = HUD.COLOR.ACTIVE[4]
                    alpha = self.aiActiveText
                end
                local steeringState = posX + self.aiTextOffsetX
                setTextColor(1, 1, 1, 1)
                setTextAlignment(RenderText.ALIGN_CENTER)
                renderText(steeringState, posY + self.aiTextOffsetY, self.aiTextSize, alpha)
                modeName:setColor(r, g, b, a)
                modeName:setPosition(posX + self.aiIconOffsetX, posY + self.aiIconOffsetY)
                modeName:render()
            end
            setTextBold(false)
            setTextColor(1, 1, 1, 1)
            setTextAlignment(RenderText.ALIGN_LEFT)
        end
        local selectedAIMode = posX + self.sectionOffsetX
        local activeColor = posY + self.sectionOffsetY
        if hasFuel then
            selectedAIMode = selectedAIMode + self.fuelOffsetX
            local startX = activeColor + self.fuelOffsetY
            self.fuelIcon:setPosition(selectedAIMode + self.fuelIconOffsetX, startX + self.fuelIconOffsetY)
            self.fuelIcon:render()
            self.bar:setColor(0, 0, 0, 1)
            self.bar:setMiddlePart(nil, self.barMaxScaleWidth, nil)
            self.bar:setPosition(selectedAIMode + self.fuelBarOffsetX, startX + self.fuelBarOffsetY)
            self.bar:render()
            local startY = fuelLevel / fuelCapacity
            if startY > 0 then
                if startY > 0.1 then
                    self.bar:setColor(1, 0.4287, 0.0006, 1)
                else
                    local b = math.cos(g_time / 300)
                    self.bar:setColor(1, 0.1233, 0, (math.abs(b)))
                end
                local endX = math.clamp(self.barMaxScaleWidth * startY, 0, self.barMaxScaleWidth)
                self.bar:setMiddlePart(nil, endX, nil)
                self.bar:setPosition(selectedAIMode + self.fuelBarOffsetX, startX + self.fuelBarOffsetY)
                self.bar:render()
            end
        end
        if hasRepair then
            selectedAIMode = selectedAIMode + self.repairOffsetX
            local startX = activeColor + self.repairOffsetY
            self.repairIcon:setPosition(selectedAIMode + self.repairIconOffsetX, startX + self.repairIconOffsetY)
            self.repairIcon:render()
            self.bar:setColor(0, 0, 0, 1)
            self.bar:setMiddlePart(nil, self.barMaxScaleWidth, nil)
            self.bar:setPosition(selectedAIMode + self.repairBarOffsetX, startX + self.repairBarOffsetY)
            self.bar:render()
            local startY = 1
            for r, g in ipairs(vehicle.rootVehicle.childVehicles) do
                if g.getDamageShowOnHud ~= nil and g:getDamageShowOnHud() then
                    local steeringState = 1 - g:getDamageAmount()
                    startY = math.min(startY, steeringState)
                end
            end
            if startY > 0 then
                if startY > 0.2 then
                    self.bar:setColor(0.0097, 0.4287, 0.6445, 1)
                else
                    self.bar:setColor(1, 0.1233, 0, 1)
                end
                local timeSinceLastModeChange = math.clamp(self.barMaxScaleWidth * startY, 0, self.barMaxScaleWidth)
                self.bar:setMiddlePart(nil, timeSinceLastModeChange, nil)
                self.bar:setPosition(selectedAIMode + self.repairBarOffsetX, startX + self.repairBarOffsetY)
                self.bar:render()
            end
        end
        local selectedAIMode = selectedAIMode + self.gearOffsetX
        local startX = activeColor + self.gearOffsetY
        self.gearIcon:setPosition(selectedAIMode + self.gearIconOffsetX, startX + self.gearIconOffsetY)
        self.gearIcon:render()
        self:drawGearText(selectedAIMode, startX)
    end
end
function SpeedMeterDisplay:drawSpeedMeter(centerX, centerY)
    local vehicle = self.vehicle
    if vehicle ~= nil then
        local speedGaugeUseMiles = g_gameSettings:getValue(GameSettings.SETTING.USE_MILES)
        local speedGaugeMode = g_gameSettings:getValue(GameSettings.SETTING.HUD_SPEED_GAUGE)
        local motorizedSpec = vehicle.spec_motorized
        if motorizedSpec.forceSpeedHudDisplay then
            speedGaugeMode = SpeedMeterDisplay.GAUGE_MODE_SPEED
        elseif motorizedSpec.forceRpmHudDisplay then
            speedGaugeMode = SpeedMeterDisplay.GAUGE_MODE_RPM
        end
        local lastSpeed = vehicle:getLastSpeed()
        local speed = math.floor((g_i18n:getSpeed(math.clamp(lastSpeed * vehicle.spec_motorized.speedDisplayScale, 0, 999) < 0.5 and 0 or math.clamp(lastSpeed * vehicle.spec_motorized.speedDisplayScale, 0, 999))))
        if math.abs(speedKmh - speed) > 0.5 then
        end
        local motor = vehicle:getMotor()
        local fixedLowerLimit = false
        local unitText, scale, scale, gaugeRounding, scale
        if speedGaugeMode == SpeedMeterDisplay.GAUGE_MODE_RPM then
            unitText = self.rpmUnitText
            scale = motor:getMinRpm()
            scale = motor:getMaxRpm()
            gaugeRounding = 200
            scale = vehicle:getMotorRpmReal()
        else
            unitText = self.kmhUnitText
            local scale = 1
            if speedGaugeUseMiles then
                scale = 0.621371
                unitText = self.mphUnitText
            end
            scale = 0
            scale = motor:getMaximumForwardSpeed() * 3.6 * scale
            gaugeRounding = 5
            fixedLowerLimit = true
            scale = lastSpeed * scale
        end
        local maxValue = (scale - scale) / 8 / gaugeRounding
        local stepDistance = math.ceil(maxValue) * gaugeRounding
        local minValue = math.floor(scale / gaugeRounding) * gaugeRounding - stepDistance
        local maxValue = math.floor(scale / gaugeRounding) * gaugeRounding + stepDistance
        if not fixedLowerLimit then
            scale = minValue
        end
        self.lastGaugeValue = self.lastGaugeValue * 0.95 + scale * 0.05
        local activeColor = HUD.COLOR.ACTIVE
        local i = SpeedMeterDisplay.NUMBER_OF_INDICATORS
        for i = i, 1, -1 do
            local rotation = i * 0.17453292519943295 + -0.6108652381980153
            local cosRot = math.cos(rotation)
            local sinRot = math.sin(rotation)
            self.speedIndicatorBg:setPosition(centerX + cosRot * self.speedGaugeRadiusX - self.speedIndicatorBg.width * 0.5, centerY + sinRot * self.speedGaugeRadiusY - 0)
            self.speedIndicatorBg:setRotation(rotation - 1.5707963267948966, pivotX, 0)
            local indicatorValue = MathUtil.lerp(scale, maxValue, 1 - i / SpeedMeterDisplay.NUMBER_OF_INDICATORS)
            local r, g, b, a
            if scale > 0.5 and indicatorValue < scale then
                r = activeColor[1]
                g = activeColor[2]
                b = activeColor[3]
                a = activeColor[4]
            else
                r = HUD.COLOR.INACTIVE[1]
                g = inactiveColor[2]
                b = inactiveColor[3]
                a = inactiveColor[4]
            end
            self.speedIndicatorBg:setColor(r, g, b, a)
            self.speedIndicatorBg:render()
        end
        setTextColor(1, 1, 1, 1)
        setTextAlignment(RenderText.ALIGN_CENTER)
        local i = 1
        for i = i, 10 do
            local rotation = self.gaugeTextOffsets[i]
            setTextAlignment(rotation.alignment)
            setTextBold(true)
            local indicatorPosX = MathUtil.lerp(scale, maxValue, (i - 1) / 9)
            if speedGaugeMode == SpeedMeterDisplay.GAUGE_MODE_RPM then
            end
            local indicatorPosY = string.format("%d", indicatorPosX)
            renderText(centerX + rotation.offsetX, centerY + rotation.offsetY, self.gaugeUnitTextSize, indicatorPosY)
        end
        setTextRotation(0.5235987755982988, centerX + self.gaugeUnitOffsetX, centerY + self.gaugeUnitOffsetY)
        setTextBold(true)
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
        renderText(gaugeUnitPosX, gaugeUnitPosY, self.gaugeUnitTextSize, unitText)
        setTextColor(1, 1, 1, 1)
        if speedGaugeMode == SpeedMeterDisplay.GAUGE_MODE_RPM then
            local i = centerX + self.gaugeFactorOffsetX
            local rotation = centerY + self.gaugeFactorOffsetY
            setTextRotation(-0.5235987755982988, i, rotation)
            renderText(i, rotation, self.gaugeFactorTextSize, "x100")
        end
        setTextRotation(0, 0, 0)
        local i = centerX + self.speedTextOffsetX
        local rotation = centerY + self.speedTextOffsetY
        setTextBold(true)
        renderText(i, rotation, self.speedTextSize, string.format("%1d", speed))
        local cosRot = utf8ToUpper(g_i18n:getSpeedMeasuringUnit())
        local sinRot = centerX + self.speedUnitTextOffsetX
        local indicatorPosX = centerY + self.speedUnitTextOffsetY
        setTextColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
        renderText(sinRot, indicatorPosX, self.speedUnitTextSize, cosRot)
        setTextColor(1, 1, 1, 1)
        local indicatorPosY = centerX + self.workingHoursSeperatorOffsetX
        local indicatorValue = centerY + self.workingHoursSeperatorOffsetY
        local r = indicatorPosY + self.seperatorWidth
        drawLine2D(indicatorPosY, indicatorValue, r, indicatorValue, g_pixelSizeY, activeColor[1], activeColor[2], activeColor[3], activeColor[4])
        local b = centerX + self.workingHoursTextOffsetX
        local a = centerY + self.workingHoursTextOffsetY
        if vehicle.operatingTime == nil then
            setTextColor(1, 1, 1, 1)
            renderText(b, a, self.workingHoursTextSize, "-/-")
        else
            local minutes = vehicle.operatingTime / 60000
            local hours = math.floor(minutes / 60)
            local cruiseControlPosX = math.floor((minutes - hours * 60) / 6)
            setTextAlignment(RenderText.ALIGN_RIGHT)
            setTextColor(1, 1, 1, 0.3)
            renderText(b, a, self.workingHoursTextSize, string.format("%03d.%dh", hours, cruiseControlPosX))
            setTextColor(1, 1, 1, 1)
            renderText(b, a, self.workingHoursTextSize, string.format("%d.%dh", hours, cruiseControlPosX))
        end
        self.workingHours:setPosition(centerX + self.workingHoursOffsetX, centerY + self.workingHoursOffsetY)
        self.workingHours:render()
        setTextAlignment(RenderText.ALIGN_LEFT)
        local indicatorPosY = centerX + self.cruiseControlSeperatorOffsetX
        local indicatorValue = centerY + self.cruiseControlSeperatorOffsetY
        local r = indicatorPosY + self.seperatorWidth
        drawLine2D(indicatorPosY, indicatorValue, r, indicatorValue, g_pixelSizeY, activeColor[1], activeColor[2], activeColor[3], activeColor[4])
        local minutes, hours = self.vehicle:getCruiseControlDisplayInfo()
        local cruiseControlPosX = string.format("%d", g_i18n:getSpeed(minutes))
        if hours then
            setTextColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
        else
            setTextColor(1, 1, 1, 1)
        end
        local cruiseControlPosX = centerX + self.cruiseControlTextOffsetX
        local cruiseControlPosY = centerY + self.cruiseControlTextOffsetY
        renderText(cruiseControlPosX, cruiseControlPosY, self.cruiseControlTextSize, (tostring(cruiseControlPosX)))
        self.cruiseControl:setPosition(centerX + self.cruiseControlOffsetX, centerY + self.cruiseControlOffsetY)
        self.cruiseControl:render()
    end
end
function SpeedMeterDisplay:drawGearText(x, y)
    if self.vehicle ~= nil then
        local gearName, gearGroupName, _gearsAvailable, isAutomatic, prevGearName, nextGearName, prevPrevGearName, nextNextGearName, isGearChanging, showNeutralWarning = self.vehicle:getGearInfoToDisplay()
        local gearSelectedIndex = 1
        local gearGroupText = ""
        if gearName == nil or isAutomatic then
            if gearName ~= nil and isAutomatic then
                self.gearTexts[1] = "R"
                self.gearTexts[2] = "N"
                self.gearTexts[3] = "D"
                if gearName == "N" then
                    gearSelectedIndex = 2
                elseif gearName == "D" then
                    gearSelectedIndex = 3
                elseif gearName == "R" then
                    gearSelectedIndex = 1
                end
            end
        else
            gearGroupText = gearGroupName or ""
            if nextGearName == nil and prevGearName == nil then
                self.gearTexts[1] = ""
                self.gearTexts[2] = gearName
                self.gearTexts[3] = ""
                gearSelectedIndex = 2
            elseif nextGearName == nil then
                if prevPrevGearName == nil then
                    self.gearTexts[1] = prevGearName
                    self.gearTexts[2] = gearName
                    self.gearTexts[3] = ""
                    gearSelectedIndex = 2
                else
                    self.gearTexts[1] = prevPrevGearName
                    self.gearTexts[2] = prevGearName
                    self.gearTexts[3] = gearName
                    gearSelectedIndex = 3
                end
            elseif prevGearName == nil then
                self.gearTexts[1] = gearName
                self.gearTexts[2] = nextGearName
                self.gearTexts[3] = nextNextGearName or ""
                gearSelectedIndex = 1
            else
                self.gearTexts[1] = prevGearName
                self.gearTexts[2] = gearName
                self.gearTexts[3] = nextGearName
                gearSelectedIndex = 2
            end
        end
        if showNeutralWarning then
            self.gearWarningTime = self.gearWarningTime + g_currentDt
        else
            self.gearWarningTime = 0
        end
        setTextColor(1, 1, 1, 1)
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextBold(true)
        if gearGroupText ~= nil then
            renderText(x, y + self.gearGroupTextOffsetY, self.gearTextSize, gearGroupText)
        end
        local i = 1
        for i = i, 3 do
            local alpha = 1
            local renderBg = false
            if i == 2 then
                alpha = math.abs((math.cos(self.gearWarningTime / 200)))
            end
            if gearSelectedIndex == i then
                if isGearChanging then
                end
                renderBg = true
            end
            if renderBg then
                self.gearBg:setColor(nil, nil, nil, alpha)
                self.gearBg:setPosition(x + self.gearBgOffsetX, y + self.gearBgOffsetY[i])
                self.gearBg:render()
            end
            renderText(x, y + self.gearTextOffsetY[i], self.gearTextSize, self.gearTexts[i])
        end
        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end
function SpeedMeterDisplay:setVehicle(vehicle)
    self.vehicle = nil
    local hasVehicle = vehicle ~= nil
    if hasVehicle and (hasVehicle and vehicle.spec_motorized ~= nil) then
        self.vehicle = vehicle
        local _, capacity, fuelType = SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
        if capacity ~= nil then
            self.fuelIcon:setSliceId(fuelType == FillType.ELECTRICCHARGE and "gui.icon_electricCharge" or (fuelType == FillType.METHANE and "gui.icon_methane" or "gui.icon_fuel"))
        end
    end
    local fuelType = self.vehicle ~= nil
    self:setVisible(fuelType)
    self.isVehicleDrawSafe = false
end
function SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
    local fuelType = FillType.DIESEL
    local fillUnitIndex = vehicle:getConsumerFillUnitIndex(fuelType)
    if fillUnitIndex == nil then
        fuelType = FillType.ELECTRICCHARGE
        fillUnitIndex = vehicle:getConsumerFillUnitIndex(fuelType)
        if fillUnitIndex == nil then
            fillUnitIndex = vehicle:getConsumerFillUnitIndex(FillType.METHANE)
        end
    end
    return vehicle:getFillUnitFillLevel(fillUnitIndex), vehicle:getFillUnitCapacity(fillUnitIndex), fuelType
end
if data ~= nil then
    local speedMeter = SpeedMeterDisplay.new()
    speedMeter:setVehicle(data.vehicle)
    speedMeter:setScale(data.uiScale)
    speedMeter:setVisible(data.isVisible)
    g_currentMission.hud.speedMeter = speedMeter
    g_currentMission.hud.displayComponents.speedMeter = speedMeter
    Logging.info("Reloaded")
end