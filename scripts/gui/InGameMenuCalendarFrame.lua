InGameMenuCalendarFrame = {}
local InGameMenuCalendarFrame_mt = Class(InGameMenuCalendarFrame, TabbedMenuFrameElement)
InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE = 1
InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE = 2
InGameMenuCalendarFrame.BLOCK_COLORS = {
    [false] = {
        [InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE] = {
            0.22323,
            0.40724,
            0.00368,
            1
        },
        [InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE] = {
            0.53328,
            0.06301,
            0.00335,
            1
        }
    },
    [true] = {
        [InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE] = {
            0.2122,
            0.1779,
            0.0027,
            0.95
        },
        [InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE] = {
            0.3372,
            0.4397,
            0.9911,
            0.95
        }
    }
}
function InGameMenuCalendarFrame.register()
    local inGameMenuCalendarFrame = InGameMenuCalendarFrame.new()
    g_gui:loadGui("dataS/gui/InGameMenuCalendarFrame.xml", "CalendarFrame", inGameMenuCalendarFrame, true)
end
function InGameMenuCalendarFrame.new(target, custom_mt)
    -- upvalues: (copy) InGameMenuCalendarFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuCalendarFrame_mt)
    self.isColorBlindMode = false
    self.scrollInputDelay = 0
    self.scrollInputDelayDir = 0
    self.fruitTypes = {}
    self.calendarHeader = {}
    self.clonedElements = {}
    return self
end
function InGameMenuCalendarFrame.createFromExistingGui(gui, guiName)
    local newGui = InGameMenuCalendarFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function InGameMenuCalendarFrame:delete()
    if self.fruitRowTemplate ~= nil then
        self.fruitRowTemplate:delete()
    end
    for _, clonedElement in pairs(self.clonedElements) do
        clonedElement:delete()
    end
    self.separatorBigTemplate:delete()
    self.separatorTemplate:delete()
    self.monthTextTemplate:delete()
    InGameMenuCalendarFrame:superClass().delete(self)
end
function InGameMenuCalendarFrame:initialize()
    InGameMenuCalendarFrame:superClass().initialize(self)
    self.separatorBigTemplate:unlinkElement()
    self.separatorTemplate:unlinkElement()
    self.monthTextTemplate:unlinkElement()
    FocusManager:removeElement(self.separatorBigTemplate)
    FocusManager:removeElement(self.separatorTemplate)
    FocusManager:removeElement(self.monthTextTemplate)
    self.separatorBigTemplate:clone(self.tableHeaderBox)
    local i = 1
    for i = i, 12 do
        local clonedText = self.monthTextTemplate:clone(self.tableHeaderBox)
        table.insert(self.clonedElements, clonedText)
        self.calendarHeader[i] = clonedText
        local clonedSeparator
        if i % 3 == 0 then
            clonedSeparator = self.separatorBigTemplate:clone(self.tableHeaderBox)
        else
            clonedSeparator = self.separatorTemplate:clone(self.tableHeaderBox)
        end
        table.insert(self.clonedElements, clonedSeparator)
    end
    self.tableHeaderBox:invalidateLayout()
end
function InGameMenuCalendarFrame:onFrameOpen()
    InGameMenuCalendarFrame:superClass().onFrameOpen(self)
    self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
    self:rebuildTable()
    self:updateTodayBar()
    self:setPeriodTitles()
    self:updateLegend()
    g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.setColorBlindMode, self)
    FocusManager:setFocus(self.slider)
    g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self.onTemperatureUnitChanged, self)
    if g_currentMission ~= nil then
        self.forecast = g_currentMission.environment.weather.forecast
    end
    self:reloadWeatherData()
end
function InGameMenuCalendarFrame:onFrameClose()
    g_messageCenter:unsubscribe(MessageType.DAY_CHANGED, self)
    g_messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self)
    g_messageCenter:unsubscribe(MessageType.HOUR_CHANGED, self)
    g_messageCenter:unsubscribe(MessageType.DAY_CHANGED, self)
    g_messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self)
    InGameMenuCalendarFrame:superClass().onFrameClose(self)
end
function InGameMenuCalendarFrame:updateTodayBar()
    local env = g_currentMission.environment
    local intoSeason = (env.currentDayInSeason - 1) / env:getDaysPerSeason()
    local parentSize = self.todayBar.parent.size[1]
    self.todayBar:setPosition(parentSize * ((env.currentSeason - 1) * 0.25 + intoSeason * 0.25) + parentSize / (env:getDaysPerSeason() * 4) * 0.5, nil)
end
function InGameMenuCalendarFrame:setPeriodTitles()
    local i = 1
    for i = i, 12 do
        self.calendarHeader[i]:setText(g_i18n:formatPeriod(i, true))
    end
end
function InGameMenuCalendarFrame:updateLegend()
    self.legendPlantingSeason:setImageColor(nil, unpack(InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE]))
    self.legendHarvestSeason:setImageColor(nil, unpack(InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE]))
    self.legendHarvestSeason.parent:invalidateLayout()
end
function InGameMenuCalendarFrame:rebuildTable()
    self.fruitTypes = {}
    for _, fruitDesc in pairs(g_fruitTypeManager:getFruitTypes()) do
        if fruitDesc.shownOnMap then
            table.insert(self.fruitTypes, fruitDesc)
        end
    end
    table.sort(self.fruitTypes, function(a, b)
        local fillTypeA = g_fruitTypeManager:getFillTypeByFruitTypeIndex(a.index)
        local fillTypeB = g_fruitTypeManager:getFillTypeByFruitTypeIndex(b.index)
        return fillTypeA.title < fillTypeB.title
    end)
    self.calendar:reloadData()
end
function InGameMenuCalendarFrame:reloadWeatherData()
    self.forecastHourlyList:reloadData()
    self.forecastDailyList:reloadData()
    self:updateTodayView()
end
function InGameMenuCalendarFrame:updateTodayView()
    local now = self.forecast:getCurrentWeather()
    self.nowTemperature:setValue(now.temperature)
    self.nowWindSpeed:setValue(self:meterPerSecondToBeaufort(now.windSpeed))
    self.nowWeatherIcon:setImageSlice(nil, InGameMenuCalendarFrame.ICON_SLICES[now.forecastType])
    self.nowWeatherMonth:setText(g_i18n:formatDayInPeriod(g_currentMission.environment.currentDayInPeriod, g_currentMission.environment.currentPeriod, false))
    if Platform.isMobile then
        self.nowWindDirection:applyProfile((self:getWindDirectionIconProfileByAngle(now.windDirection)))
    else
        dir:setImageRotation(math.rad(now.windDirection) + 3.141592653589793)
    end
end
function InGameMenuCalendarFrame:getNumberOfItemsInSection(list, _)
    return list == self.calendar and #self.fruitTypes or (self.forecast == nil and 0 or (list == self.forecastHourlyList and 12 or 6))
end
function InGameMenuCalendarFrame:populateCellForItemInSection(list, _, index, cell)
    if list == self.calendar then
        local fruitDesc = self.fruitTypes[index]
        local fillType = g_fruitTypeManager:getFillTypeByFruitTypeIndex(fruitDesc.index)
        cell:getAttribute("fruitIcon"):setImageFilename(fillType.hudOverlayFilename)
        cell:getAttribute("fruitName"):setText(fillType.title)
        cell:getAttribute("fruitPlanting2"):setVisible(false)
        cell:getAttribute("fruitHarvesting2"):setVisible(false)
        local plantElementIndex = 1
        local harvestElementIndex = 1
        local plantStart = nil
        local plantEnd = nil
        local harvestStart = nil
        local harvestEnd = nil
        local i = 1
        for i = i, 12 do
            local isPlantable = fruitDesc:getIsPlantableInPeriod(g_currentMission.missionInfo.growthMode, i)
            if plantStart == nil and (isPlantable and i) then
                plantStart = i
            end
            if plantStart ~= nil and not isPlantable then
            end
            plantEnd = i == 12 and 12 or plantEnd
            if plantStart ~= nil and plantEnd ~= nil then
                local plantElement = cell:getAttribute("fruitPlanting" .. plantElementIndex)
                plantElement:setSize(self.calendarHeader[plantEnd].absPosition[1] - self.calendarHeader[plantStart].absPosition[1] + self.calendarHeader[plantStart].absSize[1])
                plantElement:setPosition(self.calendarHeader[plantStart].absPosition[1] - self.calendar.absPosition[1])
                plantElement:setImageColor(nil, unpack(InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE]))
                plantElement:setVisible(true)
                plantStart = nil
            end
            local plantElement = fruitDesc:getIsHarvestableInPeriod(growthMode, i)
            if harvestStart == nil and (plantElement and i) then
                harvestStart = i
            end
            if harvestStart ~= nil and not plantElement then
            end
            harvestEnd = i == 12 and 12 or harvestEnd
            if harvestStart ~= nil and harvestEnd ~= nil then
                local harvestElement = cell:getAttribute("fruitHarvesting" .. harvestElementIndex)
                harvestElement:setSize(self.calendarHeader[harvestEnd].absPosition[1] - self.calendarHeader[harvestStart].absPosition[1] + self.calendarHeader[harvestStart].absSize[1])
                harvestElement:setPosition(self.calendarHeader[harvestStart].absPosition[1] - self.calendar.absPosition[1])
                harvestElement:setImageColor(nil, unpack(InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE]))
                harvestElement:setVisible(true)
                harvestStart = nil
            end
        end
    elseif list == self.forecastHourlyList then
        local fruitDesc = self.forecast:getHourlyForecast((index - 1) * 2)
        if fruitDesc ~= nil then
            local plantElementIndex = fruitDesc.time / 3600000 + 0.0001
            local fillType = math.floor(plantElementIndex)
            cell:getAttribute("icon"):setImageSlice(nil, InGameMenuCalendarFrame.ICON_SLICES[fruitDesc.forecastType])
            cell:getAttribute("time"):setText(string.format("%02d:00", fillType))
            cell:getAttribute("temperature"):setValue(fruitDesc.temperature)
            cell:getAttribute("windSpeed"):setValue(self:meterPerSecondToBeaufort(fruitDesc.windSpeed))
            if Platform.isMobile then
                local plantElementIndex = self:getWindDirectionIconProfileByAngle(fruitDesc.windDirection)
                cell:getAttribute("windDirection"):applyProfile(plantElementIndex)
            else
                local plantElementIndex = cell:getAttribute("windDirection")
                plantElementIndex:setImageRotation(math.rad(fruitDesc.windDirection) + 3.141592653589793)
            end
        end
    else
        local fruitDesc = g_currentMission.environment.weather.forecast:getDailyForecast(index)
        local fillType = g_currentMission.environment:getPeriodFromDay(fruitDesc.day)
        local plantElementIndex = g_currentMission.environment:getDayInPeriodFromDay(fruitDesc.day)
        cell:getAttribute("day"):setText(g_i18n:formatDayInPeriod(plantElementIndex, fillType, true))
        cell:getAttribute("icon"):setImageSlice(nil, InGameMenuCalendarFrame.ICON_SLICES[fruitDesc.forecastType])
        cell:getAttribute("highTemperature"):setValue(fruitDesc.highTemperature)
        cell:getAttribute("lowTemperature"):setValue(fruitDesc.lowTemperature)
    end
end
function InGameMenuCalendarFrame.meterPerSecondToBeaufort(_, mps)
    return math.floor((math.pow(math.ceil(mps) / 0.836, 0.6666666666666666)))
end
function InGameMenuCalendarFrame.getWindDirectionIconProfileByAngle(_, angle)
    angle = MathUtil.snapValue(angle % 360, 45)
    return InGameMenuCalendarFrame.WIND_DIRECTION_PROFILES[angle]
end
function InGameMenuCalendarFrame:onDayChanged()
    self:updateTodayBar()
    self:reloadWeatherData()
end
function InGameMenuCalendarFrame:onHourChanged()
    self:reloadWeatherData()
end
function InGameMenuCalendarFrame:onTemperatureUnitChanged()
    self:updateTodayView()
end
function InGameMenuCalendarFrame:setColorBlindMode(isActive)
    if self.isColorBlindMode ~= isActive then
        self.isColorBlindMode = isActive
        self:rebuildTable()
        self:updateLegend()
    end
end
function InGameMenuCalendarFrame:draw()
    InGameMenuCalendarFrame:superClass().draw(self)
    drawDashedLine(self.todayBar.absPosition[1], self.todayBar.absPosition[2] + self.todayBar.absSize[2], self.todayBar.absSize[1], self.todayBar.absSize[2], -7 * g_pixelSizeY, -6 * g_pixelSizeY, 1, 1, 1, 1, false)
end
InGameMenuCalendarFrame.ICON_SLICES = {
    [WeatherType.SUN] = "gui.icon_weather_sun",
    [WeatherType.PARTIALLY_CLOUDY] = "gui.icon_weather_partiallyCloudy",
    [WeatherType.CLOUDY] = "gui.icon_weather_cloudy",
    [WeatherType.RAIN] = "gui.icon_weather_rain",
    [WeatherType.SNOW] = "gui.icon_weather_snow",
    [WeatherType.HAIL] = "gui.icon_weather_hail",
    [WeatherType.THUNDER] = "gui.icon_weather_thunder",
    [WeatherType.TWISTER] = "gui.icon_weather_twister"
}
InGameMenuCalendarFrame.WIND_DIRECTION_PROFILES = {
    [0] = "ingameMenuWeatherWindIndicatorIcon",
    [45] = "ingameMenuWeatherWindIndicatorIcon45",
    [90] = "ingameMenuWeatherWindIndicatorIcon90",
    [135] = "ingameMenuWeatherWindIndicatorIcon135",
    [180] = "ingameMenuWeatherWindIndicatorIcon180",
    [225] = "ingameMenuWeatherWindIndicatorIcon225",
    [270] = "ingameMenuWeatherWindIndicatorIcon270",
    [315] = "ingameMenuWeatherWindIndicatorIcon315"
}