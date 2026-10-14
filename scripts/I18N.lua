I18N = {}
local I18N_mt = Class(I18N)
I18N.L10N_FILES_DIRECTORY = "dataS/l10n/"
I18N.MONEY_MAX_DISPLAY_VALUE = 999999999
I18N.MONEY_MIN_DISPLAY_VALUE = -999999999
g_xmlManager:addEarlyCreateSchemaFunction(function()
    I18N.xmlSchema = XMLSchema.new("l18n")
    I18N.registerXMLPaths(I18N.xmlSchema)
end)
function I18N.registerXMLPaths(xmlSchema)
    xmlSchema:register(XMLValueType.FLOAT, "l10n.fluid#factor", "", 1)
    xmlSchema:register(XMLValueType.FLOAT, "l10n.power#factor", "", 1)
    xmlSchema:register(XMLValueType.STRING, "l10n.elements.e(?)#k", "The name of the string", nil)
    xmlSchema:register(XMLValueType.STRING, "l10n.elements.e(?)#v", "The text of the string", nil)
end
function I18N.new()
    -- upvalues: (copy) I18N_mt
    local self = setmetatable({}, I18N_mt)
    self.texts = {}
    self.modEnvironments = {}
    if g_addTestCommands then
        addConsoleCommand("gsI18nVerify", "Checks all localization files for empty or \'TODO\' texts, warns if placeholders mismatch between languages", "consoleCommandVerifyAll", self, "[ignoreTodos=false]; [l10nDir]; [l10nFilePrefix]")
    end
    self.debugActive = StartParams.getIsSet("debugI18N")
    if self.debugActive then
        print("debugI18N active")
        if not StartParams.getIsSet("scriptDebug") then
            Logging.devWarning("\'-debugI18N\' start parameter should only be used in combination with \'-scriptDebug\' start parameter")
        end
        self.usedTexts = {}
        self.printedWarnings = {}
        self:loadUsedKeysFromXML()
        addConsoleCommand("gsI18nSaveUsedKeysXml", "", "saveUsedKeysToXML", self)
        g_messageCenter:subscribe(MessageType.GUI_INGAME_OPEN, self.saveUsedKeysToXML, self)
        g_messageCenter:subscribe(MessageType.GUI_MAIN_SCREEN_OPEN, self.saveUsedKeysToXML, self)
    end
    return self
end
function I18N:load()
    self.texts = {}
    if not g_isDevelopmentVersion and g_languageShort ~= "en" then
        local baseXMLFile = XMLFile.load("l10n_en", I18N.L10N_FILES_DIRECTORY .. "l10n_en.xml")
        self:loadEntriesFromXML(baseXMLFile, self.texts, true)
        baseXMLFile:delete()
    end
    local baseXMLFile = XMLFile.load("l10n" .. g_languageSuffix, I18N.L10N_FILES_DIRECTORY .. "l10n" .. g_languageSuffix .. ".xml")
    self:loadEntriesFromXML(baseXMLFile, self.texts, true)
    self:mergePlatformText(self.texts)
    self.fluidFactor = baseXMLFile:getFloat("l10n.fluid#factor", 1)
    self.powerFactorHP = baseXMLFile:getFloat("l10n.power#factor", 1)
    self.powerFactorKW = 0.735499
    self.moneyUnit = GS_MONEY_EURO
    self.useMiles = false
    self.useFahrenheit = false
    self.useAcre = false
    baseXMLFile:delete()
    self.thousandsGroupingChar = self:getText("unit_digitGroupingSymbol")
    if self.thousandsGroupingChar ~= " " and (self.thousandsGroupingChar ~= "." and self.thousandsGroupingChar ~= ",") then
        self.thousandsGroupingChar = " "
    end
    self.decimalSeparator = self:getText("unit_decimalSymbol") or "."
    if g_gameSettings ~= nil then
        self.moneyUnit = g_gameSettings:getValue(GameSettings.SETTING.MONEY_UNIT)
        self.useMiles = g_gameSettings:getValue(GameSettings.SETTING.USE_MILES)
        self.useFahrenheit = g_gameSettings:getValue(GameSettings.SETTING.USE_FAHRENHEIT)
        self.useAcre = g_gameSettings:getValue(GameSettings.SETTING.USE_ACRE)
    end
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MONEY_UNIT], self.setMoneyUnit, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_MILES], self.setUseMiles, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_ACRE], self.setUseAcre, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self.setUseFahrenheit, self)
end
function I18N:delete()
    g_messageCenter:unsubscribeAll(self)
end
function I18N:loadFromXMLFile(xmlFilename)
    self.texts = {}
    local xmlFile = XMLFile.load("l10n", xmlFilename)
    self:loadEntriesFromXML(xmlFile, self.texts, false)
    xmlFile:delete()
end
function I18N:loadEntriesFromXML(xmlFile, outputEntries, overwriteExistingText)
    for nodeIndex, nodeKey in xmlFile:iterator("l10n.elements.e") do
        local name = xmlFile:getString(nodeKey .. "#k")
        if string.isNilOrWhitespace(name) then
            Logging.xmlWarning(xmlFile, "Node at path %q is missing a name (k attribute)", nodeKey)
        elseif outputEntries[name] == nil or overwriteExistingText then
            local text = xmlFile:getString(nodeKey .. "#v")
            if string.isNilOrWhitespace(text) then
                Logging.xmlWarning(xmlFile, "Node at path %q is missing a text (v attribute)", nodeKey)
            else
                if string.trim(utf8ToUpper(text)) == "TODO" then
                    text = "TODO:" .. name
                    if self.debugActive and self.printedWarnings[name] == nil then
                        Logging.devWarning("TODO text set for loca key \'%s\' in %q", name, xmlFile:getFilename())
                        self.printedWarnings[name] = true
                    end
                end
                outputEntries[name] = string.gsub(text, "\r\n", "\n")
            end
        end
    end
end
function I18N.mergePlatformText(_, texts)
    for key, text in pairs(texts) do
        for _, postfix in ipairs(Platform.l10nPostfixes) do
            local postfixKey = key .. postfix
            if texts[postfixKey] ~= nil then
                texts[key] = texts[postfixKey]
                break
            end
        end
        if texts[key] ~= text then
            Logging.devInfo("I18N platform specific text %s: \'%s\'", key, texts[key])
        end
    end
end
function I18N:saveUsedKeysToXML()
    local fileName = getUserProfileAppPath() .. "l10n_usedKeys.xml"
    local xmlFile = createXMLFile("l10n_usedKeys", fileName, "l10n")
    if xmlFile == 0 then
        Logging.error("Failed to create l10n_usedKeys xml file")
    else
        local usedCount = 0
        for key in pairs(self.usedTexts) do
            setXMLString(xmlFile, string.format("l10n.used(%d)#k", usedCount), key)
            usedCount = usedCount + 1
        end
        saveXMLFile(xmlFile)
        delete(xmlFile)
        local textsCount = table.size(self.texts)
        print(string.format("I18N debug: saved \'%s\': %i unused, %i used, %i total keys ", fileName, textsCount - usedCount, usedCount, textsCount))
    end
end
function I18N:loadUsedKeysFromXML()
    local fileName = getUserProfileAppPath() .. "l10n_usedKeys.xml"
    local xmlFile = XMLFile.loadIfExists("l10n_usedKeys", fileName)
    if xmlFile then
        xmlFile:iterate("l10n.used", function(_, key)
            -- upvalues: (copy) self, (copy) xmlFile
            self.usedTexts[xmlFile:getString(key .. "#k")] = true
        end)
        print(string.format("I18N debug: loaded \'%s\': %i used keys ", fileName, table.size(self.usedTexts)))
        xmlFile:delete()
    else
        Logging.devWarning("I18N debug: Unable to load used loca keys file %s", fileName)
    end
end
function I18N:addModI18N(modName)
    local modi18n = {
        ["texts"] = {}
    }
    setmetatable(modi18n, {
        ["__index"] = self
    })
    setmetatable(modi18n.texts, {
        ["__index"] = self.texts
    })
    self.modEnvironments[modName] = modi18n
    function modi18n.setText(i18nInstance, name, value)
        i18nInstance.texts[name] = value
    end
    function modi18n.hasModText(i18nInstance, name)
        return i18nInstance.texts[name] ~= nil
    end
    function modi18n.setGlobalText(_, name, value)
        -- upvalues: (copy) modName, (copy) self
        name = modName .. "." .. name
        if self.texts[name] == nil then
            self.texts[name] = value
        end
    end
    return modi18n
end
function I18N:getText(name, customEnv)
    local ret = nil
    if customEnv ~= nil then
        local modEnv = self.modEnvironments[customEnv]
        if modEnv ~= nil then
            ret = modEnv.texts[name]
        end
    end
    if ret == nil then
        ret = self.texts[name]
        if ret == nil then
            ret = string.format("Missing \'%s\' in l10n%s.xml", name, g_languageSuffix)
            if g_showDevelopmentWarnings then
                Logging.devWarning(ret)
            end
        end
    end
    return ret
end
function I18N:hasText(name, customEnv)
    if name == nil then
        return false
    end
    local ret = nil
    if customEnv ~= nil then
        local modEnv = self.modEnvironments[customEnv]
        if modEnv ~= nil then
            ret = modEnv.texts[name]
        end
    end
    if ret == nil then
        ret = self.texts[name]
    end
    local modEnv = ret ~= nil
    return modEnv
end
function I18N:setText(name, value)
    self.texts[name] = value
end
function I18N:setMoneyUnit(unit)
    self.moneyUnit = unit
end
function I18N:setUseMiles(useMiles)
    self.useMiles = useMiles
end
function I18N:setUseFahrenheit(useFahrenheit)
    self.useFahrenheit = useFahrenheit
end
function I18N:setUseAcre(useAcre)
    self.useAcre = useAcre
end
function I18N:getCurrency(currency)
    return currency * self:getCurrencyFactor()
end
function I18N:getCurrencyFactor()
    return self.moneyUnit == GS_MONEY_EURO and 1 or (self.moneyUnit == GS_MONEY_POUND and 0.79 or 1.34)
end
function I18N:getMeasuringUnit(useLongName)
    if self.useMiles then
        return self.texts["unit_miles" .. (useLongName and "" or "Short")]
    else
        return self.texts["unit_km" .. postfix]
    end
end
function I18N:getVolumeUnit(useLongName)
    return self.texts["unit_liter" .. (useLongName and "" or "Short")]
end
function I18N.getVolume(_, liters)
    return liters
end
function I18N:getSpeedMeasuringUnit()
    if self.useMiles then
        return self.texts.unit_mph
    else
        return self.texts.unit_kmh
    end
end
function I18N:getSpeed(speedKmh)
    if self.useMiles then
        return speedKmh * 0.62137
    else
        return speedKmh
    end
end
function I18N:getTemperature(temperatureCelsius)
    if self.useFahrenheit then
        return temperatureCelsius * 1.8 + 32
    else
        return temperatureCelsius
    end
end
function I18N:formatTemperature(temperatureCelsius, precision, useLongName)
    local temperature = self:getTemperature(temperatureCelsius)
    local str = self:getTemperatureUnit(useLongName)
    return string.format("%1." .. (precision or 0) .. "f%s", temperature, str)
end
function I18N:getTemperatureUnit(useLongName)
    if self.useFahrenheit then
        return self.texts["unit_fahrenheit" .. (useLongName and "" or "Short")]
    else
        return self.texts["unit_celsius" .. postfix]
    end
end
function I18N:getAreaUnit(useLongName)
    if self.useAcre then
        return self.texts["unit_acre" .. (useLongName and "" or "Short")]
    else
        return self.texts["unit_ha" .. postfix]
    end
end
function I18N:getArea(ha)
    if self.useAcre then
        return ha * 2.4711
    else
        return ha
    end
end
function I18N:formatArea(areaInHa, precision, useLongName)
    local area = self:getArea(areaInHa)
    local str = self:getAreaUnit(useLongName)
    return MathUtil.round(area, precision) .. " " .. str
end
function I18N:getDistanceUnit(useLongName)
    if self.useMiles then
        return self.texts["unit_ft" .. (useLongName and "" or "Short")]
    else
        return self.texts["unit_m" .. postfix]
    end
end
function I18N:getDistance(distance, isDistanceInMeter)
    if self.useMiles then
        if isDistanceInMeter then
            return distance * 3.28084
        else
            return distance * 0.62137
        end
    else
        return distance
    end
end
function I18N:formatDistance(distanceInMeter, precision, useLongName)
    local distance = self:getDistance(distanceInMeter, true)
    local str = self:getDistanceUnit(useLongName)
    return MathUtil.round(distance, precision) .. " " .. str
end
function I18N:getFluid(fluid)
    return fluid * self.fluidFactor
end
function I18N:formatFluid(liters)
    return string.format("%s %s", self:formatNumber(self:getFluid(liters)), g_i18n:getText("unit_literShort"))
end
function I18N:formatVolume(liters, precision, unit)
    return string.format("%s %s", self:formatNumber(self:getVolume(liters), precision), unit or self:getVolumeUnit())
end
function I18N:formatMass(mass, maxMass, showKg)
    local unit = "unit_tonsShort"
    local precision = 1
    if showKg ~= false then
        if mass < 1 and (maxMass == nil or maxMass == 0) then
            unit = "unit_kg"
            precision = 0
        elseif mass < 1 and (maxMass ~= nil and maxMass ~= 0) then
            unit = "unit_kg"
            precision = 0
        end
    end
    if maxMass == nil or maxMass == 0 then
        return string.format("%s %s", self:formatNumber(MathUtil.round(mass, precision), precision), g_i18n:getText(unit))
    else
        return string.format("%s-%s %s", self:formatNumber(MathUtil.round(mass, precision), precision), self:formatNumber(MathUtil.round(maxMass, precision), precision), g_i18n:getText(unit))
    end
end
function I18N:getPower(power)
    return power * self.powerFactorHP, power * self.powerFactorKW
end
function I18N:formatNumber(number, precision, forcePrecision)
    if number == math.huge then
        return "inf"
    end
    if number == -math.huge then
        return "-inf"
    end
    precision = precision or 0
    if precision == 0 then
        if number == nil then
            printCallstack()
        end
        if number < 0 then
            number = math.ceil(number)
        else
            number = math.floor(number)
        end
    end
    local baseString = tostring(MathUtil.round(number, precision))
    local prefix, thousandsPart, decimalPart = string.match(baseString, "^([^%d]*%d)(%d*)[.]?(%d*)")
    if thousandsPart == nil then
        printCallstack()
        error(string.format("I18N:formatNumber: unable to split string %q (number %q)", baseString, (tostring(number))))
    end
    local thousandsPartReversed = string.reverse(thousandsPart)
    local formattedNumber = string.gsub(thousandsPartReversed, "(%d%d%d)", "%1" .. self.thousandsGroupingChar)
    local formattedNumber = prefix .. string.reverse(formattedNumber)
    if precision > 0 and (string.len(decimalPart) > 0 and (forcePrecision or tonumber(decimalPart) ~= 0)) then
        formattedNumber = formattedNumber .. self.decimalSeparator .. string.sub(decimalPart, 1, precision)
    end
    return formattedNumber
end
function I18N:formatMoney(number, precision, addCurrency, prefixCurrencySymbol)
    local currencyString = self:formatNumber(math.clamp(number, I18N.MONEY_MIN_DISPLAY_VALUE, I18N.MONEY_MAX_DISPLAY_VALUE), precision)
    if addCurrency == nil or addCurrency then
        if prefixCurrencySymbol == nil or not prefixCurrencySymbol then
            return currencyString .. "\194\160" .. self:getCurrencySymbol(true)
        end
        currencyString = self:getCurrencySymbol(true) .. "\194\160" .. currencyString
    end
    return currencyString
end
function I18N:getCurrencySymbol(useShort)
    if self.moneyUnit == GS_MONEY_EURO then
        return self:getText("unit_euro" .. (useShort and "Short" or ""))
    elseif self.moneyUnit == GS_MONEY_POUND then
        return self:getText("unit_pound" .. postFix)
    else
        return self:getText("unit_dollar" .. postFix)
    end
end
function I18N.convertText(_, textOrKey, customEnv)
    if textOrKey ~= nil then
        if string.startsWith(textOrKey, "$l10n_") then
            textOrKey = g_i18n:getText(string.sub(textOrKey, 7), customEnv)
        end
        return textOrKey
    end
    Logging.warning("Text to convert is nil")
    printCallstack()
    return nil
end
function I18N:insertTextParams(text, paramsStr, customEnvironment, xmlFile)
    local _, count = string.gsub(text, "%%s", "")
    local params = string.split(paramsStr, "|")
    if #params == count then
        local i = 1
        for i = i, #params do
            params[i] = self:convertText(params[i], customEnvironment)
        end
        return string.format(text, unpack(params))
    elseif xmlFile == nil then
        Logging.warning("Unable to insert parameters into text. Invalid number of params. (%d found in string \'%s\', %d params given in \'%s\')", count, text, #params, paramsStr)
        return text
    else
        Logging.xmlWarning(xmlFile, "Unable to insert parameters into text. Invalid number of params. (%d found in string \'%s\', %d params given in \'%s\')", count, text, #params, paramsStr)
        return text
    end
end
function I18N:getCurrentDate()
    if g_languageShort == "en" then
        return getDate("%Y-%m-%d")
    elseif g_languageShort == "de" then
        return getDate("%d.%m.%Y")
    elseif g_languageShort == "jp" then
        return getDate("%Y/%m/%d")
    else
        return getDate("%d/%m/%Y")
    end
end
function I18N:consoleCommandVerifyAll(ignoreTodos, l10nDir, l10nFilePrefix)
    self:verifyLocaFiles(Utils.stringToBoolean(ignoreTodos), l10nDir or I18N.L10N_FILES_DIRECTORY, l10nFilePrefix or "l10n_")
end
function I18N:verifyLocaFiles(ignoreTodos, l10nDir, l10nFilePrefix)
    print("Verifying i18n files:")
    setFileLogPrefixTimestamp(false)
    if ignoreTodos then
        printWarning("Warning: Ignoring \'TODO\' and \'\' texts")
    end
    local langToKeys = {}
    local allKeysSet = {}
    local masterLang = nil
    print("loading lang files")
    local langIndex = 0
    local enFormatStrings = getNumOfLanguages() - 1
    for langIndex = langIndex, enFormatStrings do
        local code = getLanguageCode(langIndex)
        local filenameShort = l10nFilePrefix .. code .. ".xml"
        if code == "en" then
            masterLang = filenameShort
        end
        local xmlFilename = l10nDir .. filenameShort
        if fileExists(xmlFilename) then
            local keys = {}
            local xmlFile = XMLFile.load("l10n" .. g_languageSuffix, xmlFilename)
            self:loadEntriesFromXML(xmlFile, keys)
            xmlFile:delete()
            self:mergePlatformText(keys)
            langToKeys[filenameShort] = keys
            for key, _ in pairs(keys) do
                allKeysSet[key] = true
            end
            print(string.format("loaded %d entries from %s", table.size(keys), xmlFilename))
        else
            printWarning(string.format("Warning: unable to find xml file %s for langIndex %d", xmlFilename, langIndex))
        end
    end
    if next(langToKeys) == nil then
        return "Error: no l10n entries were loaded"
    end
    for code, filenameShort in pairs(allKeysSet) do
        for lang, keys in pairs(langToKeys) do
            local text = keys[code]
            if text == nil then
                printWarning(string.format("Warning: Missing text for %s in %s", code, lang))
            elseif not ignoreTodos and (text:trim() == "" or text:find("TODO")) then
                printWarning(string.format("Warning: Empty or todo text for %s in %s", code, lang))
            end
        end
    end
    local enFormatStrings = {}
    for filenameShort, xmlFilename in pairs(langToKeys[masterLang]) do
        local lang = ""
        for formatIdentifier, _ in xmlFilename:gmatch("%%%d?%.?%d*%a") do

        end
        local xmlFile
        if lang == "" then
            lang = nil
            xmlFile = nil
        else
            local text, key = xmlFilename:gsub("%%", "")
            xmlFile = key % 2
        end
        if lang ~= nil then
            enFormatStrings[filenameShort] = { lang, xmlFile }
            local lang, keys = string.gsub(lang, "%%", "")
            if keys > 1 then
                printError(string.format("Error: Multiple unnamed format specifiers (%s) in %q", lang, filenameShort))
            end
        end
    end
    for filenameShort, xmlFilename in pairs(langToKeys) do
        if filenameShort ~= masterLang then
            print(filenameShort)
            for keys, text in pairs(xmlFilename) do
                getTextHeight(1, text)
                local formatIdentifier = ""
                for formatIdentifier, _ in text:gmatch("%%%d?%.?%d*%a") do

                end
                local _
                if formatIdentifier == "" then
                    formatIdentifier = nil
                    _ = nil
                else
                    local _, count = text:gsub("%%", "")
                    _ = count % 2
                end
                local formatIdentifier = enFormatStrings[keys]
                if formatIdentifier then
                    formatIdentifier = enFormatStrings[keys][1]
                end
                local _ = enFormatStrings[keys] and enFormatStrings[keys][2]
                if formatIdentifier then
                    if utf8ToUpper(text) ~= "TODO" then
                        if formatIdentifier ~= formatIdentifier then
                            printError(string.format("Error: Mismatching format strings for key \'%s\' in %s: \'%s\' <-> \'%s\'", keys, filenameShort, formatIdentifier or "no placeholder", formatIdentifier or "no placeholder"))
                            print(string.format("    %s: %s", masterLang, langToKeys[masterLang][keys]))
                            print(string.format("    %s: %s", filenameShort, text))
                        end
                        if _ ~= _ then
                            printError(string.format("Error: Mismatching \'%%\' characters (possible unescaped \'%%\') for key \'%s\' in %s", keys, filenameShort))
                            print(string.format("    %s: %s", masterLang, count))
                            print(string.format("    %s: %s", filenameShort, text))
                        end
                    end
                    local text
                    if enFormatStrings[keys] and not pcall(function()
                        -- upvalues: (copy) text
                        string.format(text, 1, 2, 3, 4, 5, 6, 7, 8, 9)
                    end) then
                        printError(string.format("Error: String format cannot be applied on string \'%s\' in %s:\n    en: \'%s\'\n<->\n    %s: \'%s\'", keys, filenameShort, langToKeys[masterLang][keys], filenameShort, text))
                    end
                end
            end
        end
    end
    setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
    return "Verified all i18n files"
end
function I18N:formatMinutes(minutes)
    if minutes == nil then
        return self:getText("ui_hours_none")
    end
    local hours = math.floor(minutes / 60)
    return string.format(self:getText("ui_hours"), hours, minutes - hours * 60)
end
function I18N:formatPeriod(period, useShort)
    local isSouthern = false
    if g_currentMission ~= nil and g_currentMission.environment ~= nil then
        isSouthern = g_currentMission.environment.daylight.latitude < 0
        if period == nil then
            period = g_currentMission.environment.currentPeriod
        end
    end
    if period == nil then
        return nil
    end
    local month = period + 2
    if isSouthern then
    end
    local month = (month - 1) % 12 + 1
    return self:getText("ui_month" .. month .. (useShort and "_short" or ""))
end
function I18N:formatDayInPeriod(dayInPeriod, period, useShort)
    if g_currentMission == nil or g_currentMission.environment == nil then
        return nil
    else
        if dayInPeriod == nil then
            dayInPeriod = g_currentMission.environment.currentDayInPeriod
        end
        if period == nil then
            period = g_currentMission.environment.currentPeriod
        end
        local periodString = self:formatPeriod(period, useShort)
        if g_currentMission.environment.daysPerPeriod == 1 then
            return periodString
        else
            return string.format("%s %d", periodString, dayInPeriod)
        end
    end
end
function I18N:formatNumMonth(numMonth)
    return string.format("%d %s", numMonth, self:getText(numMonth == 1 and "ui_month" or "ui_months"))
end
function I18N:formatNumDay(numDay)
    return string.format("%d %s", numDay, self:getText(numDay == 1 and "ui_day" or "ui_days"))
end
function I18N:formatCurrentTime()
    if g_currentMission ~= nil and g_currentMission.environment ~= nil then
        local currentTime = g_currentMission.environment.dayTime / 3600000
        local timeHours = math.floor(currentTime)
        local timeMinutes = math.floor((currentTime - timeHours) * 60)
        return string.format("%02d:%02d", timeHours, timeMinutes)
    end
end