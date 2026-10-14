WheelXMLObject = {}
local WheelXMLObject_mt = Class(WheelXMLObject)
function WheelXMLObject.new(xmlFile, baseKey, configIndex, wheelKey, indexToParentIndex)
    -- upvalues: (copy) WheelXMLObject_mt
    local self = setmetatable({}, WheelXMLObject_mt)
    self.xmlFile = xmlFile
    self.baseKey = baseKey
    self.configIndex = configIndex
    self.baseWheelKey = wheelKey
    self.wheelKey = wheelKey
    self.indexToParentIndex = indexToParentIndex
    _, self.baseDirectory = Utils.getModNameAndBaseDirectory(self.xmlFile.filename)
    self:setXMLLoadKey("")
    return self
end
function WheelXMLObject:delete()
    if self.externalXMLFile ~= nil then
        self.externalXMLFile:delete()
        self.externalXMLFile = nil
    end
end
function WheelXMLObject:getXMLFileAndKey(configIndex, attributeKey, altAttributeKey, ignoreExternalFile)
    local key = self.baseKey .. "(" .. tostring(configIndex - 1) .. ")" .. self.wheelKey .. attributeKey
    if self.xmlFile:getString(key) ~= nil then
        return self.xmlFile, key
    end
    if altAttributeKey ~= nil then
        local altKey = self.baseKey
        local altKey = altKey .. "(" .. tostring(configIndex - 1) .. ")" .. self.wheelKey .. altAttributeKey
        if self.xmlFile:getString(altKey) ~= nil then
            return self.xmlFile, altKey
        end
    end
    local altKey = self.indexToParentIndex[configIndex]
    if altKey ~= nil then
        return self:getXMLFileAndKey(altKey, attributeKey, altAttributeKey, ignoreExternalFile)
    end
    if self.externalFilename ~= nil and not ignoreExternalFile then
        if self.externalXMLFile == nil and not self:loadExternalXMLFile() then
            return nil
        end
        if self.externalConfigKey ~= nil then
            local key = self.externalConfigKey .. attributeKey
            if self.externalXMLFile:getString(key) ~= nil then
                return self.externalXMLFile, key
            end
            if altAttributeKey ~= nil then
                local altKey = self.externalConfigKey .. altAttributeKey
                if self.externalXMLFile:getString(altKey) ~= nil then
                    return self.externalXMLFile, altKey
                end
            end
        end
        local key = "wheel.default" .. attributeKey
        if self.externalXMLFile:getString(key) ~= nil then
            return self.externalXMLFile, key
        end
        if altAttributeKey ~= nil then
            local altKey = "wheel.default" .. altAttributeKey
            if self.externalXMLFile:getString(altKey) ~= nil then
                return self.externalXMLFile, altKey
            end
        end
    end
    return nil
end
function WheelXMLObject:getXMLFileAndPropertyKey(property, configIndex)
    local key = configIndex or self.configIndex
    local parentIndex = self.baseKey
    local key = parentIndex .. "(" .. tostring(key - 1) .. ")" .. self.wheelKey .. property
    if self.xmlFile:hasProperty(key) then
        return self.xmlFile, key
    end
    local parentIndex = self.indexToParentIndex[key]
    if parentIndex ~= nil then
        return self:getXMLFileAndPropertyKey(property, parentIndex)
    end
    if self.externalFilename ~= nil then
        if self.externalXMLFile == nil and not self:loadExternalXMLFile() then
            return nil
        end
        if self.externalConfigKey ~= nil then
            local key = self.externalConfigKey .. property
            if self.externalXMLFile:hasProperty(key) then
                return self.externalXMLFile, key
            end
        end
        local key = "wheel.default" .. property
        if self.externalXMLFile:hasProperty(key) then
            return self.externalXMLFile, key
        end
    end
    return nil
end
function WheelXMLObject:getValue(attributeKey, ...)
    local xmlFile, key = self:getXMLFileAndKey(self.configIndex, attributeKey)
    if xmlFile == nil then
        local defaultKey = self.baseKey .. "(" .. tostring(self.configIndex - 1) .. ")" .. self.wheelKey .. attributeKey
        return self.xmlFile:getValue(defaultKey, ...)
    elseif xmlFile:getString(key) == "-" then
        return nil
    else
        return xmlFile:getValue(key, ...)
    end
end
function WheelXMLObject:getLocalValue(attributeKey, ...)
    local xmlFile, key = self:getXMLFileAndKey(self.configIndex, attributeKey, nil, true)
    if xmlFile == nil then
        local defaultKey = self.baseKey .. "(" .. tostring(self.configIndex - 1) .. ")" .. self.wheelKey .. attributeKey
        return self.xmlFile:getValue(defaultKey, ...)
    elseif xmlFile:getString(key) == "-" then
        return nil
    else
        return xmlFile:getValue(key, ...)
    end
end
function WheelXMLObject:getValueAlternative(attributeKey, altAttributeKey, ...)
    local xmlFile, key = self:getXMLFileAndKey(self.configIndex, attributeKey, altAttributeKey)
    if xmlFile == nil then
        local defaultKey = self.baseKey .. "(" .. tostring(self.configIndex - 1) .. ")" .. self.wheelKey .. attributeKey
        return self.xmlFile:getValue(defaultKey, ...)
    elseif xmlFile:getString(key) == "-" then
        return nil
    else
        return xmlFile:getValue(key, ...)
    end
end
function WheelXMLObject.getValueStatic(configIndex, indexToParentIndex, xmlFile, baseKey, wheelKey, attributeKey, ...)
    local key = baseKey .. "(" .. tostring(configIndex - 1) .. ")" .. wheelKey .. attributeKey
    local value = xmlFile:getString(key)
    if value == nil then
        local parentIndex = indexToParentIndex[configIndex]
        if parentIndex ~= nil then
            return WheelXMLObject.getValueStatic(parentIndex, indexToParentIndex, xmlFile, baseKey, wheelKey, attributeKey, ...)
        end
        return xmlFile:getValue(baseKey .. "(" .. tostring(configIndex - 1) .. ")" .. wheelKey .. attributeKey, ...)
    elseif value == "-" then
        return nil
    else
        return xmlFile:getValue(key, ...)
    end
end
function WheelXMLObject:xmlWarning(attributeKey, text, ...)
    Logging.xmlWarning(self.xmlFile, text .. " (" .. self.baseKey .. "(" .. tostring(self.configIndex - 1) .. ")" .. self.wheelKey .. attributeKey .. ")", ...)
end
function WheelXMLObject:checkDeprecatedXMLElements(oldAttributeKey, newAttribute)
    local baseKey = self.baseKey .. "(" .. tostring(self.configIndex - 1) .. ")" .. self.wheelKey
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseKey .. oldAttributeKey, baseKey .. newAttribute)
end
function WheelXMLObject:setXMLLoadKey(key, alternativeFilename)
    self.wheelKey = self.baseWheelKey .. key
    local filename = self:getLocalValue("#filename", alternativeFilename)
    if filename == nil or filename == "" then
        if self.externalXMLFile ~= nil then
            self.externalXMLFile:delete()
            self.externalXMLFile = nil
        end
        self.externalFilename = nil
        self.externalConfigId = nil
    else
        self:setExternalFilename(filename, (self:getLocalValue("#configId", "default")))
    end
end
function WheelXMLObject:setExternalFilename(externalFilename, configId)
    externalFilename = Utils.getFilename(externalFilename, self.baseDirectory)
    if externalFilename ~= self.externalFilename or configId ~= self.externalConfigId then
        self.externalFilename = externalFilename
        self.externalConfigId = configId
        if self.externalXMLFile ~= nil then
            self.externalXMLFile:delete()
            self.externalXMLFile = nil
        end
        self.externalWheelName = nil
    end
end
function WheelXMLObject:loadExternalXMLFile()
    if self.externalXMLFile ~= nil then
        self.externalXMLFile:delete()
        self.externalXMLFile = nil
    end
    local xmlFile = XMLFile.load("wheelXML", self.externalFilename, Wheels.xmlSchema)
    if xmlFile == nil then
        self.externalFilename = nil
        self.externalXMLFile = nil
        self.externalConfigId = nil
        return false
    else
        self.externalXMLFile = xmlFile
        self.externalWheelName = self.externalXMLFile:getValue("wheel.metadata#name")
        xmlFile:iterate("wheel.configurations.configuration", function(_, key)
            -- upvalues: (copy) xmlFile, (copy) self
            if xmlFile:getValue(key .. "#id") == self.externalConfigId then
                self.externalConfigKey = key
            end
        end)
        return true
    end
end
WheelXMLObject.wheelMassCache = {}
function WheelXMLObject:cacheWheelMass()
    local vehicleXMLMass = self:getLocalValue(".physics#mass", nil)
    if vehicleXMLMass ~= nil then
        return vehicleXMLMass
    end
    if self.externalFilename == nil then
        return 0.1
    end
    if WheelXMLObject.wheelMassCache[self.externalFilename] == nil then
        WheelXMLObject.wheelMassCache[self.externalFilename] = {}
    end
    local mass = WheelXMLObject.wheelMassCache[self.externalFilename][self.externalConfigId]
    if mass ~= nil then
        return mass
    end
    local mass = self:getValue(".physics#mass", 0.1)
    for name, _ in pairs(WheelVisual.PARTS) do
        local i = 0
        while true do
            local keyAdditional = string.format(".%s(%d)", name, i)
            local xmlFile, _ = self:getXMLFileAndPropertyKey(keyAdditional)
            if xmlFile == nil then
                break
            end
            mass = mass + self:getValue(keyAdditional .. "#mass", 0)
            i = i + 1
        end
    end
    if self.externalFilename == nil or self.externalConfigId == nil then
        return 0
    end
    WheelXMLObject.wheelMassCache[self.externalFilename][self.externalConfigId] = mass
    return mass
end