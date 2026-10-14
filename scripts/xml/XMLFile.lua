source("dataS/scripts/xml/XMLValueType.lua")
XMLFile = {}
local XMLFile_mt = Class(XMLFile)
function XMLFile.load(objectName, filename, schema)
    local handle = loadXMLFile(objectName, filename)
    if handle == 0 then
        return nil
    else
        return XMLFile.new(objectName, filename, handle, schema)
    end
end
function XMLFile.loadIfExists(objectName, filename, schema)
    if filename == nil or not fileExists(filename) then
        return nil
    else
        return XMLFile.load(objectName, filename, schema)
    end
end
function XMLFile.create(objectName, filepath, rootNodeName, schema)
    local handle = createXMLFile(objectName, filepath, rootNodeName)
    if handle ~= 0 then
        return XMLFile.new(objectName, filepath, handle, schema)
    end
    Logging.error("Failed to create \'%s\' xml file", objectName)
    return nil
end
function XMLFile.new(objectName, filename, handle, schema)
    -- upvalues: (copy) XMLFile_mt
    if type(schema) ~= "table" and schema ~= nil then
        schema = nil
        if g_isDevelopmentVersion then
            Logging.devError("XMLFile.new: schema is not a table or nil")
            printCallstack()
        end
    end
    local self = setmetatable({}, XMLFile_mt)
    self.objectName = objectName
    self.filename = filename
    self.schema = schema
    self.handle = handle
    self:initInheritance()
    if g_xmlManager ~= nil then
        g_xmlManager:addFile(self)
    end
    return self
end
function XMLFile.wrap(handle, schema)
    local self = XMLFile.new(getName(handle) .. "<wrapped>", getXMLFilename(handle), handle, schema)
    self.noDeletion = true
    return self
end
function XMLFile:delete()
    if not self.noDeletion then
        delete(self.handle)
    end
    if g_xmlManager ~= nil then
        g_xmlManager:removeFile(self)
    end
end
function XMLFile:getHandle()
    return self.handle
end
function XMLFile:getFilename()
    return self.filename
end
function XMLFile:getAsString()
    return saveXMLFileToMemory(self.handle)
end
function XMLFile:hasProperty(property)
    local hasElementOrAttribute, hasElement = hasXMLProperty(self.handle, property)
    return hasElementOrAttribute, hasElement
end
function XMLFile:getNumOfChildren(elementPath)
    return getXMLNumOfChildren(self.handle, elementPath)
end
function XMLFile:getNumOfElements(elementPath)
    return getXMLNumOfElements(self.handle, elementPath)
end
function XMLFile:getElementName(elementPath)
    return getXMLElementName(self.handle, elementPath)
end
function XMLFile:getLineNumber(path)
    return getXMLLineNum(self.handle, path)
end
function XMLFile:save(printToLog, ignoreError)
    if saveXMLFile(self.handle) then
        if printToLog then
            Logging.info("Saved xml file \'%s\' to \'%s\'", self.objectName, self.filename)
        end
        return true
    else
        if not ignoreError then
            Logging.error("Could not save xml file \'%s\' to \'%s\'", self.objectName, self.filename)
        end
        return false
    end
end
function XMLFile:saveTo(filepath, printToLog, ignoreError)
    if saveXMLFileTo(self.handle, filepath) then
        if printToLog then
            Logging.info("Saved xml file \'%s\' to \'%s\'", self.objectName, filepath)
        end
        return true
    else
        if not ignoreError then
            Logging.error("Could not save xml file \'%s\' to \'%s\'", self.objectName, filepath)
        end
        return false
    end
end
function XMLFile:removeProperty(path)
    removeXMLProperty(self.handle, path)
end
function XMLFile:setString(path, value)
    setXMLString(self.handle, path, value)
end
function XMLFile:setFloat(path, value)
    setXMLFloat(self.handle, path, value)
end
function XMLFile:setInt(path, value)
    setXMLInt(self.handle, path, value)
end
function XMLFile:setUInt(path, value)
    setXMLUInt(self.handle, path, value)
end
function XMLFile:setBool(path, value)
    setXMLBool(self.handle, path, value)
end
function XMLFile:addComment(path, comment)
    addXMLComment(self.handle, path, comment)
end
function XMLFile:getString(path, default)
    return getXMLString(self.handle, path) or default
end
function XMLFile:getFloat(path, default)
    return getXMLFloat(self.handle, path) or default
end
function XMLFile:getAngle(path, default)
    local angle = self:getFloat(path, default)
    if angle == nil then
        return nil
    else
        return math.rad(angle)
    end
end
function XMLFile:getInt(path, default)
    return getXMLInt(self.handle, path) or default
end
function XMLFile:getUInt(path, default)
    return getXMLUInt(self.handle, path) or default
end
function XMLFile:getBool(path, default)
    local v = getXMLBool(self.handle, path)
    if v == nil then
        return default
    else
        return v
    end
end
function XMLFile:getNode(path, default, components, i3dMappings)
    return XMLValueType.getXMLNode(self.handle, path, default, components, i3dMappings)
end
function XMLFile:getRootName()
    return getXMLRootName(self.handle)
end
function XMLFile:getValue(path, default, ...)
    local valueType = XMLFile.getValueType(self, path)
    if valueType == nil then
        return nil
    elseif valueType.isBasicFunction then
        local value = valueType.get(self.handle, path)
        if value == nil then
            return default
        else
            return value
        end
    else
        return valueType.get(self.handle, path, default, ...)
    end
end
function XMLFile:setValue(path, ...)
    local valueType = XMLFile.getValueType(self, path)
    if valueType ~= nil then
        valueType.set(self.handle, path, ...)
    end
end
function XMLFile:iterate(path, closure)
    local i = 0
    for i = i, getXMLNumOfElements(self.handle, path) - 1 do
        if closure(i + 1, path .. "(" .. i .. ")") == false then
            break
        end
    end
end
function XMLFile:iterator(path)
    local currentIndex = 0
    local numElements = getXMLNumOfElements(self.handle, path)
    return function()
        -- upvalues: (ref) currentIndex, (copy) numElements, (copy) path
        if numElements <= currentIndex then
            return nil
        end
        currentIndex = currentIndex + 1
        return currentIndex, path .. "(" .. currentIndex - 1 .. ")"
    end
end
function XMLFile:iterator_reverse(path)
    local currentIndex = 0
    local numElements = getXMLNumOfElements(self.handle, path)
    return function()
        -- upvalues: (ref) currentIndex, (copy) numElements, (copy) path
        if numElements <= currentIndex then
            return nil
        end
        currentIndex = currentIndex + 1
        return currentIndex, path .. "(" .. numElements - currentIndex .. ")"
    end
end
function XMLFile:iterateRecursively(path, closure, depth)
    depth = depth or 0
    local i = 0
    for i = i, getXMLNumOfChildren(self.handle, path) - 1 do
        local childName = getXMLElementName(self.handle, path .. ".*(" .. i .. ")")
        local childPath = path .. ".*(" .. i .. ")"
        if closure(childName, childPath, i + 1, depth) == false then
            return false
        end
        if getXMLNumOfChildren(self.handle, childPath) > 0 and self:iterateRecursively(childPath, closure, depth + 1) == false then
            return false
        end
    end
    return true
end
function XMLFile:iteratorChildren(path)
    local currentIndex = 0
    local numElements = getXMLNumOfChildren(self.handle, path)
    local currentPath = nil
    path = path .. ".*"
    return function()
        -- upvalues: (ref) currentIndex, (copy) numElements, (ref) currentPath, (ref) path, (copy) self
        if numElements <= currentIndex then
            return nil
        end
        currentIndex = currentIndex + 1
        currentPath = path .. "(" .. currentIndex - 1 .. ")"
        return currentIndex, currentPath, getXMLElementName(self.handle, currentPath)
    end
end
function XMLFile.setTable(_, path, tbl, closure)
    local i = 0
    for key, value in pairs(tbl) do
        local res = closure((path .. "(") .. i .. ")", value, key)
        if res == false then
            break
        end
        if res ~= 0 then
        end
    end
    return i
end
function XMLFile.setSortedTable(_, path, tbl, closure)
    local i = 0
    for index, value in ipairs(tbl) do
        local res = closure((path .. "(") .. i .. ")", value, index)
        if res == false then
            break
        end
        if res ~= 0 then
        end
    end
    return i
end
function XMLFile:getValueType(path)
    local schema = self.schema
    if schema == nil then
        Logging.xmlError(self, "Unable to get schema for xml file.")
        printCallstack()
        return
    elseif path == nil then
        Logging.xmlError(self, "Unable to get value from unknown path.")
        printCallstack()
    else
        local normalizedPath = string.gsub(path, "%(%d*%)", "(?)")
        local pathData = schema.paths[normalizedPath]
        if pathData == nil then
            local normalizedPath = normalizedPath:gsub("%d+%.", "%?%."):gsub("%d+#", "%?#"):gsub("%d+$", "%?")
            pathData = schema.paths[normalizedPath]
        end
        if pathData ~= nil then
            return XMLValueType.TYPES[pathData.valueTypeId]
        end
        Logging.xmlError(self, "Failed to validate xml path \'%s\' for schema \'%s\'. Path not registered.", path, schema.name)
        printCallstack()
    end
end
function XMLFile:setVector(path, vector)
    setXMLString(self.handle, path, table.concat(vector, " "))
end
function XMLFile:getVector(path, default, size)
    local vector = getXMLString(self.handle, path)
    if vector == nil then
        return default
    else
        return string.getVector(vector, size)
    end
end
function XMLFile:setTranslation(path, x, y, z, precision)
    precision = precision or 3
    setXMLString(self.handle, path, string.format("%." .. precision .. "f %." .. precision .. "f %." .. precision .. "f", x, y, z))
end
function XMLFile:getTranslation(path, default)
    return XMLValueType.getXMLVector3(self.handle, path, default, false)
end
function XMLFile:setRotation(path, x, y, z)
    XMLValueType.setXMLVector3Angle(self.handle, path, x, y, z)
end
function XMLFile:getRotation(path, default)
    return XMLValueType.getXMLVector3Angle(self.handle, path, default, false)
end
function XMLFile:getScale(path, default)
    return XMLValueType.getXMLVector3(self.handle, path, default, false)
end
function XMLFile:getStringList(path, default, numItems)
    return XMLValueType.getXMLStringList(self.handle, path, default, numItems) or default
end
function XMLFile:getRadiansVector(path, default, size)
    local vector = getXMLString(self.handle, path)
    if vector == nil then
        return default
    else
        return string.getRadians(vector, size)
    end
end
function XMLFile:getI18NValue(path, default, customEnvironment, showWarning)
    return XMLUtil.getXMLI18NValue(self.handle, path, getXMLString, nil, default, customEnvironment, showWarning)
end
function XMLFile:initInheritance()
    local rootName = self:getRootName()
    local parentFilename = self:getString(rootName .. ".parentFile#xmlFilename")
    if parentFilename ~= nil then
        if string.contains(parentFilename, "$pdlcdir") or string.contains(parentFilename, "$moddir") then
            Logging.xmlError(self, "Overwriting of dlc or mod files is not allowed!")
            return
        end
        local _, baseDirectory = Utils.getModNameAndBaseDirectory(self.filename)
        local parentHandle = Utils.getFilename(parentFilename, baseDirectory)
        local parentHandle = loadXMLFile(self.objectName, parentHandle)
        if parentHandle ~= 0 then
            self:iterate(rootName .. ".parentFile.attributes.remove", function(_, key)
                -- upvalues: (copy) self, (copy) parentHandle
                local attributePath = self:getString(key .. "#path")
                removeXMLProperty(parentHandle, attributePath)
            end)
            self:iterate(rootName .. ".parentFile.attributes.set", function(_, key)
                -- upvalues: (copy) self, (copy) parentHandle
                local attributePath = self:getString(key .. "#path")
                local attributeValue = self:getString(key .. "#value")
                setXMLString(parentHandle, attributePath, attributeValue)
            end)
            self:iterate(rootName .. ".parentFile.attributes.clearList", function(_, key)
                -- upvalues: (copy) self, (copy) parentHandle
                local attributePath = self:getString(key .. "#path")
                local keepIndex = self:getInt(key .. "#keepIndex")
                local numItems = 0
                while hasXMLProperty(parentHandle, string.format(attributePath .. "(%d)", numItems)) do
                    numItems = numItems + 1
                end
                for numItems = numItems, 1, -1 do
                    if numItems ~= keepIndex then
                        removeXMLProperty(parentHandle, string.format(attributePath .. "(%d)", numItems - 1))
                    end
                end
            end)
            delete(self.handle)
            self.handle = parentHandle
            return
        end
        Logging.xmlWarning(self, "Failed to load parent xml file \'%s\'", parentHandle)
    end
end
function XMLFile:copyTree(oldPath, newPath, excludeFirstLevel, excludeSubAttribute)
    if not excludeFirstLevel then
        local atributeIndex = 1
        local name = getXMLNumOfAttributes(self.handle, oldPath)
        for atributeIndex = atributeIndex, name do
            local name = getXMLAttributeName(self.handle, oldPath, atributeIndex - 1)
            setXMLString(self.handle, newPath .. "#" .. name, getXMLString(self.handle, oldPath .. "#" .. name))
        end
    end
    local name = 1
    local elementName = getXMLNumOfChildren(self.handle, oldPath)
    local atributeIndex = 1
    for name = name, elementName, atributeIndex do
        local elementName = getXMLElementName(self.handle, string.format("%s.*(%d)", oldPath, name - 1))
        if ({})[elementName] == nil then
            usedElementNames[elementName] = true
            local j = 1
            local tagName = getXMLNumOfElements(self.handle, oldPath .. "." .. elementName)
            for j = j, tagName do
                local tagName = string.format(".%s(%d)", elementName, j - 1)
                local allowed = true
                if excludeSubAttribute ~= nil and string.endsWith(oldPath .. "." .. elementName, excludeSubAttribute) then
                    allowed = false
                end
                if allowed then
                    self:copyTree(oldPath .. "." .. elementName, newPath .. "." .. elementName, false, excludeSubAttribute)
                    self:copyTree(oldPath .. tagName, newPath .. tagName, false, excludeSubAttribute)
                end
            end
        end
    end
end