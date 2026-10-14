XMLUtil = {}
function XMLUtil.getXMLI18NValue(xmlFile, baseKey, func, name, defaultValue, customEnvironment, showWarning)
    local i18n = g_i18n
    if customEnvironment ~= nil then
        i18n = _G[customEnvironment].g_i18n
    end
    name = (name == nil or name == "") and "" or "." .. name
    local defaultVal = func(xmlFile, baseKey .. ".en" .. name)
    if defaultVal == nil then
        local s = func(xmlFile, baseKey .. name .. ".en")
        if s == nil then
            local s = func(xmlFile, baseKey .. ".de" .. name)
            if s == nil then
                local s = func(xmlFile, baseKey .. name .. ".de")
                if s == nil then
                    local s = func(xmlFile, baseKey .. name)
                    if s == nil then
                    elseif type(s) == "string" and string.startsWith(s, "$l10n_") then
                        s = i18n:getText(s:sub(7))
                    end
                    if s == nil then
                        if i18n:hasText(defaultValue) then
                            defaultValue = i18n:getText(defaultValue)
                        end
                    else
                        defaultValue = s
                    end
                else
                    defaultValue = s
                end
            else
                defaultValue = s
            end
        else
            defaultValue = s
        end
    else
        defaultValue = defaultVal
    end
    if defaultValue == nil and (showWarning == nil or showWarning) then
        print("Error: loading xml I18N item, missing \'en\' or global value of attribute \'" .. baseKey .. name .. "\'")
        return nil
    end
    local s = getXMLString(xmlFile, baseKey .. "." .. g_languageShort .. name)
    if s == nil then
        local s = getXMLString(xmlFile, baseKey .. name .. "." .. g_languageShort)
        if s ~= nil then
            defaultValue = s
        end
    else
        defaultValue = s
    end
    return defaultValue
end
function XMLUtil.checkDeprecatedXMLElements(xmlFile, oldElement, newElement, oldValue, checkForValue)
    local found = false
    local extraWarning = ""
    if oldValue == nil then
        if xmlFile:getString(oldElement) ~= nil or xmlFile:hasProperty(oldElement) and not (oldElement:find("#") or checkForValue) then
            found = true
        end
    elseif xmlFile:getString(oldElement) == oldValue then
        found = true
        extraWarning = string.format(" with value \'%s\'", oldValue)
    end
    if found then
        if newElement ~= nil then
            Logging.xmlWarning(xmlFile, "\'%s\'%s is not supported anymore, use \'%s\' instead!", oldElement, extraWarning, newElement)
            return
        end
        Logging.xmlWarning(xmlFile, "\'%s\'%s is not supported anymore!", oldElement, extraWarning)
    end
end
function XMLUtil.checkDeprecatedUserAttribute(node, name, xmlFile, xmlKey)
    if getUserAttribute(node, name) ~= nil then
        Logging.warning("User attribute \'%s\' of node \'%s\' is not supported anymore.", name, getName(node))
        if xmlFile ~= nil then
            Logging.warning("Please replace with \'%s\' in file \'%s\'", xmlKey, xmlFile:getFilename())
        end
    end
end
function XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, name, node)
    local value = nil
    if type(node) == "number" then
        value = getUserAttribute(node, name)
    end
    if value == nil and xmlFile ~= nil then
        value = xmlFile:getValue(xmlNode .. "#" .. name)
    end
    return value
end
function XMLUtil.getXMLStringWithDefault(xmlFile, key, defkey, overridekey, attrname)
    local r = getXMLString(xmlFile, key .. "#" .. attrname)
    if not r and defkey then
        r = getXMLString(xmlFile, defkey .. "#" .. attrname)
    end
    if overridekey then
        r = getXMLString(xmlFile, overridekey .. "#" .. attrname) or r
    end
    return r
end
function XMLUtil.getXMLIntWithDefault(xmlFile, key, defkey, overridekey, attrname)
    local r = getXMLInt(xmlFile, key .. "#" .. attrname)
    if not r and defkey then
        r = getXMLInt(xmlFile, defkey .. "#" .. attrname)
    end
    if overridekey then
        r = getXMLInt(xmlFile, overridekey .. "#" .. attrname) or r
    end
    return r
end
function XMLUtil.getXMLFloatWithDefault(xmlFile, key, defkey, overridekey, attrname)
    local r = getXMLFloat(xmlFile, key .. "#" .. attrname)
    if not r and defkey then
        r = getXMLFloat(xmlFile, defkey .. "#" .. attrname)
    end
    if overridekey then
        r = getXMLFloat(xmlFile, overridekey .. "#" .. attrname) or r
    end
    return r
end
function XMLUtil.getXMLOverwrittenValue(xmlFile, key, subKey, param, defaultValue, ...)
    local value = nil
    if key ~= nil then
        if getXMLString(xmlFile.handle, key .. subKey) == "-" then
            return nil
        end
        value = xmlFile:getValue(key .. subKey .. param, defaultValue, ...)
    end
    return value
end
function XMLUtil.loadDataFromMapXML(mapXMLFile, xmlKey, baseDirectory, loadTarget, loadFunc, ...)
    local filename = getXMLString(mapXMLFile, string.format("map.%s#filename", xmlKey))
    local xmlFile
    if filename == nil then
        xmlFile = mapXMLFile
    else
        local xmlFilename = Utils.getFilename(filename, baseDirectory)
        xmlFile = loadXMLFile("mapDataXML", xmlFilename)
        if xmlFile == 0 then
            return false
        end
    end
    local xmlFilename = loadFunc(loadTarget, xmlFile, ...)
    if xmlFile ~= mapXMLFile then
        delete(xmlFile)
    end
    return xmlFilename
end