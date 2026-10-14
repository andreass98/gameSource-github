local data = nil
if GameInfoDisplay ~= nil then
    local old = g_currentMission.hud.gameInfoDisplay
    data = {
        ["uiScale"] = old.uiScale,
        ["isVisible"] = old:getVisible()
    }
    old:delete()
end
GameInfoDisplay = {}
GameInfoDisplay.HELP_ANCHOR_MONEY = 1
GameInfoDisplay.HELP_ANCHOR_CALENDAR = 2
GameInfoDisplay.HELP_ANCHOR_WEATHER = 3
GameInfoDisplay.HELP_ANCHOR_CLOCK = 4
local old = Class(GameInfoDisplay, HUDDisplay)
function GameInfoDisplay.new()
    -- upvalues: (copy) old
    local self = GameInfoDisplay:superClass().new(old)
    local activeColor = HUD.COLOR.ACTIVE
    local r = 0
    local g = 0
    local b = 0
    local a = 0.8
    self.moneyBgRight = g_overlayManager:createOverlay("gui.gameInfo_right", 0, 0, 0, 0)
    self.moneyBgRight:setColor(r, g, b, a)
    self.moneyBgScale = g_overlayManager:createOverlay("gui.gameInfo_middle", 0, 0, 0, 0)
    self.moneyBgScale:setColor(r, g, b, a)
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.infoBgScale = g_overlayManager:createOverlay("gui.gameInfo_middle", 0, 0, 0, 0)
    self.infoBgScale:setColor(r, g, b, a)
    self.infoBgLeft = g_overlayManager:createOverlay("gui.gameInfo_left", 0, 0, 0, 0)
    self.infoBgLeft:setColor(r, g, b, a)
    self.calendarIcon = g_overlayManager:createOverlay("gui.icon_calendar", 0, 0, 0, 0)
    self.calendarIcon:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
    self.weatherIcon = g_overlayManager:createOverlay("gui.icon_weather_sun", 0, 0, 0, 0)
    self.weatherIcon:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
    self.weatherNextIcon = g_overlayManager:createOverlay("gui.icon_weather_sun", 0, 0, 0, 0)
    self.weatherNextIcon:setColor(1, 1, 1, 0.2)
    self.clockIcon = g_overlayManager:createOverlay("gui.icon_clock", 0, 0, 0, 0)
    self.clockIcon:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
    self.clockHandHour = g_overlayManager:createOverlay("gui.clockhand_hour", 0, 0, 0, 0)
    self.clockHandHour:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
    self.clockHandMinute = g_overlayManager:createOverlay("gui.clockhand_minute", 0, 0, 0, 0)
    self.clockHandMinute:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
    self.fastForwardIcon = g_overlayManager:createOverlay("gui.fastforward", 0, 0, 0, 0)
    self.fastForwardIcon:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
    self.fastForwardArrowIcon = g_overlayManager:createOverlay("gui.fastforward_arrow", 0, 0, 0, 0)
    self.fastForwardArrowIcon:setColor(0, 0, 0, 1)
    self.weatherSliceIds = {}
    self.weatherSliceIds[WeatherType.SUN] = "gui.icon_weather_sun"
    self.weatherSliceIds[WeatherType.PARTIALLY_CLOUDY] = "gui.icon_weather_partiallyCloudy"
    self.weatherSliceIds[WeatherType.CLOUDY] = "gui.icon_weather_cloudy"
    self.weatherSliceIds[WeatherType.RAIN] = "gui.icon_weather_rain"
    self.weatherSliceIds[WeatherType.SNOW] = "gui.icon_weather_snow"
    self.weatherSliceIds[WeatherType.HAIL] = "gui.icon_weather_hail"
    self.weatherSliceIds[WeatherType.TWISTER] = "gui.icon_weather_twister"
    self.weatherSliceIds[WeatherType.THUNDER] = "gui.icon_weather_thunder"
    return self
end
function GameInfoDisplay:delete()
    self.moneyBgRight:delete()
    self.moneyBgScale:delete()
    self.infoBgScale:delete()
    self.infoBgLeft:delete()
    self.calendarIcon:delete()
    self.weatherIcon:delete()
    self.weatherNextIcon:delete()
    self.clockIcon:delete()
    self.fastForwardIcon:delete()
    self.fastForwardArrowIcon:delete()
    self.clockHandHour:delete()
    self.clockHandMinute:delete()
    GameInfoDisplay:superClass().delete(self)
end
function GameInfoDisplay:storeScaledValues()
    self:setPosition(g_hudAnchorRight, g_hudAnchorTop)
    self.helpAnchorOffsetY = self:scalePixelToScreenHeight(-80)
    local moneyBgRightWidth, infoBgHeight = self:scalePixelValuesToScreenVector(10, 65)
    self.moneyBgRight:setDimension(moneyBgRightWidth, infoBgHeight)
    self.moneyBgScale:setDimension(0, infoBgHeight)
    self.moneyTextSize = self:scalePixelToScreenHeight(17)
    self.moneyTextSpacing = self:scalePixelToScreenWidth(20)
    local infoBgLeftWidth, calendarIconWidth = self:scalePixelValuesToScreenVector(-20, 27)
    self.moneyTextOffsetX = infoBgLeftWidth
    self.moneyTextOffsetY = calendarIconWidth
    self.moneyHelpOffsetX = self:scalePixelToScreenWidth(-60)
    local infoBgLeftWidth = self:scalePixelToScreenWidth(10)
    self.infoBgScale:setDimension(0, infoBgHeight)
    self.infoBgLeft:setDimension(infoBgLeftWidth, infoBgHeight)
    local calendarIconWidth, calendarIconHeight = self:scalePixelValuesToScreenVector(48, 48)
    self.calendarIcon:setDimension(calendarIconWidth, calendarIconHeight)
    self.calendarIconOffsetY = self:scalePixelToScreenHeight(10)
    self.calendarTextSize = self:scalePixelToScreenHeight(17)
    self.calendarTextOffsetY = self:scalePixelToScreenHeight(27)
    self.calendarHelpOffsetX = self:scalePixelToScreenWidth(-60)
    local weatherIconWidth, weatherIconHeight = self:scalePixelValuesToScreenVector(48, 48)
    self.weatherIcon:setDimension(weatherIconWidth, weatherIconHeight)
    self.weatherIconOffsetY = self:scalePixelToScreenHeight(8)
    local weatherIconNextWidth, weatherIconNextHeight = self:scalePixelValuesToScreenVector(32, 32)
    self.weatherNextIcon:setDimension(weatherIconNextWidth, weatherIconNextHeight)
    local clockIconWidth, clockIconHeight = self:scalePixelValuesToScreenVector(55, 8)
    self.weatherNextIconOffsetX = clockIconWidth
    self.weatherNextIconOffsetY = clockIconHeight
    self.weatherNextIconSpacing = self:scalePixelToScreenWidth(42)
    self.weatherHelpOffsetX = self:scalePixelToScreenWidth(-60)
    local clockIconWidth, clockIconHeight = self:scalePixelValuesToScreenVector(48, 48)
    self.clockIcon:setDimension(clockIconWidth, clockIconHeight)
    local clockHandHourWidth, clockHandHourHeight = self:scalePixelValuesToScreenVector(2, 8)
    self.clockHandHour:setDimension(clockHandHourWidth, clockHandHourHeight)
    local clockHandMinuteWidth, clockHandMinuteHeight = self:scalePixelValuesToScreenVector(2, 12)
    self.clockHandMinute:setDimension(clockHandMinuteWidth, clockHandMinuteHeight)
    self.clockIconOffsetY = self:scalePixelToScreenHeight(8)
    self.clockTextSize = self:scalePixelToScreenHeight(17)
    self.clockTextOffsetY = self:scalePixelToScreenHeight(27)
    local fastForwardWidth, fastForwardHeight = self:scalePixelValuesToScreenVector(10, 10)
    self.clockHandSmallX = fastForwardWidth
    self.clockHandSmallY = fastForwardHeight
    local fastForwardWidth, fastForwardHeight = self:scalePixelValuesToScreenVector(23, 14)
    self.fastForwardIcon:setDimension(fastForwardWidth, fastForwardHeight)
    local fastForwardArrowWidth, fastForwardArrowHeight = self:scalePixelValuesToScreenVector(6, 6)
    self.fastForwardArrowIcon:setDimension(fastForwardArrowWidth, fastForwardArrowHeight)
    self.fastForwardOffsetX, self.fastForwardOffsetY = self:scalePixelValuesToScreenVector(10, 26)
    self.fastForwardTextOffsetX, self.fastForwardTextOffsetY = self:scalePixelValuesToScreenVector(5, 27)
    self.fastForwardTextSize = self:scalePixelToScreenHeight(17)
    self.fastForwardArrowOffsetX, self.fastForwardArrowOffsetY = self:scalePixelValuesToScreenVector(9, 4)
    self.fastForwardArrow1OffsetX, self.fastForwardArrow1OffsetY = self:scalePixelValuesToScreenVector(6, 4)
    self.fastForwardArrow2OffsetX, self.fastForwardArrow2OffsetY = self:scalePixelValuesToScreenVector(13, 4)
    self.separatorWidth = self:scalePixelToScreenWidth(2)
    self.separatorHeight = self:scalePixelToScreenHeight(35)
    self.separatorOffsetY = self:scalePixelToScreenHeight(17)
    self.spacing = self:scalePixelToScreenWidth(20)
end
function GameInfoDisplay:draw()
    GameInfoDisplay:superClass().draw(self)
    local environment = g_currentMission.environment
    local posX, posY = self:getPosition()
    local posY = posY - self.moneyBgRight.height
    local activeColor = HUD.COLOR.ACTIVE
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    setTextColor(1, 1, 1, 1)
    local money = 0
    if g_localPlayer ~= nil then
        money = g_farmManager:getFarmById(g_localPlayer.farmId).money
    end
    local farm = g_i18n:formatMoney(money, 0, false, true)
    local moneyCurrencyText = g_i18n:getCurrencySymbol(true)
    local moneyTextWidth = getTextWidth(self.moneyTextSize, farm)
    local moneyCurrencyTextWidth = getTextWidth(self.moneyTextSize, moneyCurrencyText)
    self.moneyBgRight:setPosition(posX - self.moneyBgRight.width, posY)
    self.moneyBgRight:render()
    self.moneyBgScale:setDimension(moneyTextWidth + moneyCurrencyTextWidth + 2 * self.moneyTextSpacing - self.moneyBgRight.width, nil)
    self.moneyBgScale:setPosition(self.moneyBgRight.x - self.moneyBgScale.width, posY)
    self.moneyBgScale:render()
    self.helpOffsetXMoney = self.moneyBgScale.x + self.moneyBgScale.width * 0.5
    local moneyTextPosY = posY + self.moneyTextOffsetY
    renderText(posX + self.moneyTextOffsetX, moneyTextPosY, self.moneyTextSize, farm)
    setTextColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
    renderText(moneyTextPosX - moneyTextWidth, moneyTextPosY, self.moneyTextSize, moneyCurrencyText)
    local calendarText = utf8ToUpper(g_i18n:formatDayInPeriod(nil, nil, true))
    local calendarTextWidth = getTextWidth(self.calendarTextSize, calendarText)
    local currentTime = environment.dayTime / 3600000
    local timeHours = math.floor(currentTime)
    local timeMinutes = math.floor((currentTime - timeHours) * 60)
    local clockTextWidth = getTextWidth(self.clockTextSize, (string.format("%02d:%02d", timeHours, timeMinutes)))
    local timeScale = g_currentMission:getEffectiveTimeScale()
    local fastForwardTextWidth
    if timeScale < 1 then
        fastForwardTextWidth = string.format("%0.1f", timeScale)
    else
        fastForwardTextWidth = string.format("%d", timeScale)
    end
    local fastForwardTextWidth = getTextWidth(self.fastForwardTextSize, fastForwardTextWidth)
    local dayPlus6h, timePlus6h = environment:getDayAndDayTime(environment.dayTime + 21600000, environment.currentMonotonicDay)
    local weatherState = environment.weather:getCurrentWeatherType()
    local nextWeatherState = environment.weather:getNextWeatherType(dayPlus6h, timePlus6h)
    if weatherState ~= self.lastWeatherState then
        self.lastWeatherState = weatherState
        self.weatherIcon:setSliceId(self.weatherSliceIds[weatherState])
    end
    if nextWeatherState ~= self.lastNextWeatherState then
        self.lastNextWeatherState = nextWeatherState
        self.weatherNextIcon:setSliceId(self.weatherSliceIds[nextWeatherState])
    end
    local nextWeatherOffset = 0
    if weatherState ~= nextWeatherState then
        nextWeatherOffset = self.weatherNextIconSpacing
    end
    self.infoBgScale:setDimension(self.calendarIcon.width + self.weatherIcon.width + nextWeatherOffset + self.clockIcon.width + self.fastForwardIcon.width + self.fastForwardOffsetX + self.fastForwardTextOffsetX + 6 * self.spacing + 2 * self.separatorWidth + calendarTextWidth + clockTextWidth + fastForwardTextWidth - self.infoBgLeft.width, nil)
    self.infoBgScale:setPosition(self.moneyBgScale.x - self.infoBgScale.width, posY)
    self.infoBgScale:render()
    self.infoBgLeft:setPosition(self.infoBgScale.x - self.infoBgLeft.width, posY)
    self.infoBgLeft:render()
    self.weatherIcon:setPosition(self.infoBgLeft.x + self.spacing, posY + self.weatherIconOffsetY)
    self.weatherIcon:render()
    self.helpOffsetXWeather = self.infoBgLeft.x + self.spacing + self.weatherIcon.width * 0.5
    if weatherState ~= nextWeatherState then
        self.weatherNextIcon:setPosition(self.weatherIcon.x + self.weatherNextIconOffsetX, self.weatherIcon.y + self.weatherNextIconOffsetY)
        self.weatherNextIcon:render()
    end
    local separatorPosX = nextWeatherOffset + self.weatherIcon.x + self.weatherIcon.width + self.spacing
    local separatorPosY = posY + self.separatorOffsetY
    local separatorPosYEnd = posY + self.separatorOffsetY + self.separatorHeight
    drawLine2D(separatorPosX, separatorPosY, separatorPosX, separatorPosYEnd, self.separatorWidth, 1, 1, 1, 0.2)
    self.calendarIcon:setPosition(separatorPosX + self.spacing, posY + self.calendarIconOffsetY)
    self.calendarIcon:render()
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    renderText(self.calendarIcon.x + self.calendarIcon.width, posY + self.calendarTextOffsetY, self.calendarTextSize, calendarText)
    self.helpOffsetXCalendar = self.calendarIcon.x + self.calendarIcon.width + calendarTextWidth * 0.5
    local separatorPosX = self.calendarIcon.x + self.calendarIcon.width + calendarTextWidth + self.spacing
    drawLine2D(separatorPosX, separatorPosY, separatorPosX, separatorPosYEnd, self.separatorWidth, 1, 1, 1, 0.2)
    self.clockIcon:setPosition(separatorPosX + self.spacing, posY + self.clockIconOffsetY)
    self.clockIcon:render()
    local clockHandPosX = self.clockIcon.x + self.clockIcon.width * 0.5
    local clockHandPosY = self.clockIcon.y + self.clockIcon.height * 0.5
    self.clockHandMinute:setPosition(clockHandPosX, clockHandPosY)
    self.clockHandMinute:setRotation(-(currentTime - timeHours) * 3.141592653589793 * 2, self.clockHandMinute.width * 0.5, 0)
    self.clockHandMinute:render()
    self.clockHandHour:setPosition(clockHandPosX, clockHandPosY)
    self.clockHandHour:setRotation(-(currentTime % 12 / 12) * 3.141592653589793 * 2, self.clockHandHour.width * 0.5, 0)
    self.clockHandHour:render()
    self.helpOffsetXClock = self.clockIcon.x + self.clockIcon.width + clockTextWidth * 0.5
    renderText(self.clockIcon.x + self.clockIcon.width, posY + self.clockTextOffsetY, self.clockTextSize, clockText)
    self.fastForwardIcon:setPosition(self.clockIcon.x + self.clockIcon.width + clockTextWidth + self.fastForwardOffsetX, posY + self.fastForwardOffsetY)
    self.fastForwardIcon:render()
    if timeScale > 1 then
        self.fastForwardArrowIcon:setPosition(self.fastForwardIcon.x + self.fastForwardArrow1OffsetX, self.fastForwardIcon.y + self.fastForwardArrow1OffsetY)
        self.fastForwardArrowIcon:render()
        self.fastForwardArrowIcon:setPosition(self.fastForwardIcon.x + self.fastForwardArrow2OffsetX, self.fastForwardIcon.y + self.fastForwardArrow2OffsetY)
        self.fastForwardArrowIcon:render()
    else
        self.fastForwardArrowIcon:setPosition(self.fastForwardIcon.x + self.fastForwardArrowOffsetX, self.fastForwardIcon.y + self.fastForwardArrowOffsetY)
        self.fastForwardArrowIcon:render()
    end
    renderText(self.fastForwardIcon.x + self.fastForwardIcon.width + self.fastForwardTextOffsetX, posY + self.fastForwardTextOffsetY, self.fastForwardTextSize, fastForwardTextWidth)
    setTextBold(false)
end
function GameInfoDisplay:getHelpAnchorPosition(typeId)
    local posX, posY = self:getPosition()
    if typeId == GameInfoDisplay.HELP_ANCHOR_MONEY then
        posX = self.helpOffsetXMoney
    elseif typeId == GameInfoDisplay.HELP_ANCHOR_CALENDAR then
        posX = self.helpOffsetXCalendar
    elseif typeId == GameInfoDisplay.HELP_ANCHOR_CLOCK then
        posX = self.helpOffsetXClock
    elseif typeId == GameInfoDisplay.HELP_ANCHOR_WEATHER then
        posX = self.helpOffsetXWeather
    end
    return posX or 0, posY + self.helpAnchorOffsetY
end
if data ~= nil then
    local gameInfoDisplay = GameInfoDisplay.new()
    gameInfoDisplay:setScale(data.uiScale)
    gameInfoDisplay:setVisible(data.isVisible)
    g_currentMission.hud.gameInfoDisplay = gameInfoDisplay
    g_currentMission.hud.displayComponents.gameInfoDisplay = gameInfoDisplay
    Logging.info("Reloaded")
end