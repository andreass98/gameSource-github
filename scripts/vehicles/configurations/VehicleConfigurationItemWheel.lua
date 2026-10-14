VehicleConfigurationItemWheel = {}
VehicleConfigurationItemWheel.SELECTOR = ConfigurationUtil.SELECTOR_MULTIOPTION
local VehicleConfigurationItemWheel_mt = Class(VehicleConfigurationItemWheel, VehicleConfigurationItem)
function VehicleConfigurationItemWheel.new(configName, _)
    -- upvalues: (copy) VehicleConfigurationItemWheel_mt
    return VehicleConfigurationItemWheel:superClass().new(configName, VehicleConfigurationItemWheel_mt)
end
function VehicleConfigurationItemWheel:loadFromXML(xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
    if not VehicleConfigurationItemWheel:superClass().loadFromXML(self, xmlFile, baseKey, configKey, baseDirectory, customEnvironment) then
        return false
    end
    local name = xmlFile:getValue(configKey .. "#brand")
    self.wheelBrandKey = configKey
    if name ~= nil then
        local brandDesc = g_brandManager:getBrandByName(name)
        if brandDesc == nil then
            Logging.xmlWarning(xmlFile, "Wheel brand \'%s\' is not defined for \'%s\'!", name, configKey)
        else
            self.wheelBrandName = brandDesc.title
            self.wheelBrandIconFilename = brandDesc.image
        end
    end
    self.maxForwardSpeed = xmlFile:getValue(configKey .. "#maxForwardSpeed")
    self.maxForwardSpeedShop = xmlFile:getValue(configKey .. "#maxForwardSpeedShop")
    local brandDesc = Wheels.createConfigToParentConfigMapping(xmlFile)
    self.baseWheelData = {}
    xmlFile:iterate(configKey .. ".wheels.wheel", function(index, _)
        -- upvalues: (copy) xmlFile, (copy) brandDesc, (copy) baseDirectory, (copy) self
        local wheeXMLObject = WheelXMLObject.new(xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", 1, string.format(".wheels.wheel(%d)", index - 1), brandDesc)
        wheeXMLObject:setXMLLoadKey("")
        local dimension = nil
        local dimensionsStr = wheeXMLObject:getLocalValue("#dimensions")
        if dimensionsStr ~= nil then
            local dimensionParts = dimensionsStr:split(" ")
            if #dimensionParts > 0 then
                dimension = dimensionParts[1]
            end
        end
        local dimensionParts = wheeXMLObject:getLocalValue(".physics#xOffset", 0)
        local rimOffset = wheeXMLObject:getLocalValue("#rimOffset", 0)
        local radius = nil
        local width = nil
        if dimension == nil then
            local filename = wheeXMLObject:getLocalValue("#filename")
            if filename ~= nil then
                local filename = Utils.getFilename(filename, baseDirectory)
                radius, width = g_wheelManager:getWheelRadiusAndWidthFromFilename(filename)
            end
        else
            radius, width = g_wheelManager:getWheelRadiusAndWidthFromDimension(dimension)
        end
        wheeXMLObject:delete()
        if radius ~= nil and width ~= nil then
            self.baseWheelData[index] = {
                ["radius"] = radius,
                ["width"] = width,
                ["xOffset"] = dimensionParts,
                ["rimOffset"] = rimOffset
            }
        end
    end)
    local dimensionCombinations = {}
    local numWheels = 0
    xmlFile:iterate(configKey .. ".wheels.wheel", function(index, _)
        -- upvalues: (copy) xmlFile, (copy) self, (copy) brandDesc, (copy) dimensionCombinations, (ref) numWheels
        local wheeXMLObject = WheelXMLObject.new(xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", self.index, string.format(".wheels.wheel(%d)", index - 1), brandDesc)
        wheeXMLObject:setXMLLoadKey("")
        local dimensionsStr = wheeXMLObject:getLocalValue("#dimensions")
        if dimensionsStr ~= nil then
            local dimensionParts = dimensionsStr:split(" ")
            for i, dimension in ipairs(dimensionParts) do
                if dimensionCombinations[i] == nil then
                    dimensionCombinations[i] = {}
                end
                table.insert(dimensionCombinations[i], index, dimension)
            end
        end
        wheeXMLObject:delete()
    end)
    for i, dimensions in pairs(dimensionCombinations) do
        local i = 1
        for i = i, numWheels do
            if dimensions[i] == nil then
                dimensions[i] = "-"
            end
        end
    end
    if #dimensionCombinations == 0 then
        return true
    end
    if self.wheelBrandName ~= nil then
        Logging.xmlWarning(xmlFile, "Wheel brand defined for dynamic configuration, this is not allowed! (%s)", configKey)
        return true
    end
    local customBrandOrder = xmlFile:getValue("vehicle.wheels.wheelConfigurations#customBrandOrder", nil, true)
    if customBrandOrder ~= nil then
        self.customBrandOrder = {}
        for dimensions, v in ipairs(customBrandOrder) do
            self.customBrandOrder[string.upper(v)] = dimensions
        end
    end
    local tireCategories = xmlFile:getValue(configKey .. "#tireCategories") or xmlFile:getValue("vehicle.wheels.wheelConfigurations#tireCategories")
    if tireCategories ~= nil then
        local configWhitelistedCombinations = tireCategories:split(" ")
        if #configWhitelistedCombinations > 0 then
            self.tireCategories = {}
            for v, category in ipairs(configWhitelistedCombinations) do
                self.tireCategories[category] = true
            end
        end
    end
    self.whitelistedCombinations = {}
    xmlFile:iterate("vehicle.wheels.wheelConfigurations.tireCombination", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) self
        local brandName = xmlFile:getValue(key .. "#brand")
        local brand = g_brandManager:getBrandByName(brandName)
        if brand ~= nil then
            local names = xmlFile:getValue(key .. "#names")
            if names ~= nil then
                if names == "-" then
                    table.insert(self.whitelistedCombinations, {
                        ["brand"] = brand,
                        ["names"] = {}
                    })
                    return
                end
                local names = names:split(" ")
                if #names > 0 then
                    table.insert(self.whitelistedCombinations, {
                        ["brand"] = brand,
                        ["names"] = names
                    })
                end
            end
        end
    end)
    local configWhitelistedCombinations = {}
    local function i(index)
        -- upvalues: (copy) brandDesc, (copy) i, (copy) xmlFile, (copy) configWhitelistedCombinations
        local parentIndex = brandDesc[index]
        if parentIndex ~= nil then
            i(parentIndex)
        end
        xmlFile:iterate(string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d).tireCombination", index - 1), function(_, key)
            -- upvalues: (ref) xmlFile, (ref) configWhitelistedCombinations
            local brandName = xmlFile:getValue(key .. "#brand")
            local brand = g_brandManager:getBrandByName(brandName)
            if brand ~= nil then
                local names = xmlFile:getValue(key .. "#names")
                if names ~= nil then
                    if names == "-" then
                        table.insert(configWhitelistedCombinations, {
                            ["brand"] = brand,
                            ["names"] = {}
                        })
                        return
                    end
                    local names = names:split(" ")
                    if #names > 0 then
                        table.insert(configWhitelistedCombinations, {
                            ["brand"] = brand,
                            ["names"] = names
                        })
                    end
                end
            end
        end)
    end
    i(self.index)
    self.numDynamicConfigurations = xmlFile:getValue(configKey .. "#numDynamicConfigurations", math.huge)
    for i, combination in ipairs(configWhitelistedCombinations) do
        local i = #self.whitelistedCombinations
        for i = i, 1, -1 do
            if self.whitelistedCombinations[i].brand == combination.brand then
                table.remove(self.whitelistedCombinations, i)
            end
        end
    end
    for i, combination in ipairs(configWhitelistedCombinations) do
        table.insert(self.whitelistedCombinations, combination)
    end
    self.dimensionCombinations = dimensionCombinations
    return true
end
function VehicleConfigurationItemWheel:getNeedsRenaming(otherItem)
    if self.wheelBrandName == otherItem.wheelBrandName then
        return VehicleConfigurationItemWheel:superClass().getNeedsRenaming(self, otherItem)
    else
        return false
    end
end
function VehicleConfigurationItemWheel:onSizeLoad(xmlFile, sizeData)
    VehicleConfigurationItemWheel:superClass().onSizeLoad(self, xmlFile, sizeData)
    if self.isDynamicConfig then
        self:applyGeneratedConfiguration(xmlFile)
        if xmlFile:getValue(self.configKey .. ".size#width") ~= nil then
            return
        end
        local configurationIndexToParentConfigIndex = Wheels.createConfigToParentConfigMapping(xmlFile)
        local maxOffset = 0
        for wheelIndex, wheelData in ipairs(self.tireCombination.wheels) do
            if wheelData.path ~= nil then
                local wheelKey = string.format(".wheels.wheel(%d)", wheelIndex - 1)
                local baseWidth = wheelData.width
                local baseXOffset = 0
                local baseRimOffset = 0
                if self.baseConfigItem.baseWheelData ~= nil and self.baseConfigItem.baseWheelData[wheelIndex] ~= nil then
                    baseWidth = self.baseConfigItem.baseWheelData[wheelIndex].width
                    baseXOffset = self.baseConfigItem.baseWheelData[wheelIndex].xOffset
                    baseRimOffset = self.baseConfigItem.baseWheelData[wheelIndex].rimOffset
                end
                local wheeXMLObject = WheelXMLObject.new(xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", self.index, wheelKey, configurationIndexToParentConfigIndex)
                wheeXMLObject:setXMLLoadKey("")
                local xOffsetDifference = (wheeXMLObject:getLocalValue(".physics#xOffset", 0) - baseXOffset) * 2 + (wheeXMLObject:getLocalValue("#rimOffset", 0) - baseRimOffset) * 2
                local key = wheelData.width - baseWidth + xOffsetDifference
                local additionalOffset = math.max(maxOffset, key)
                local additionalOffset = 0
                local i = 0
                while true do
                    local key = string.format(".additionalWheel(%d)", i)
                    local _xmlFile, _ = wheeXMLObject:getXMLFileAndPropertyKey(key)
                    if _xmlFile == nil then
                        break
                    end
                    additionalOffset = additionalOffset + (wheeXMLObject:getLocalValue(key .. "#offset", 0) + wheelData.width)
                    i = i + 1
                end
                maxOffset = math.max(additionalOffset, additionalOffset * 2 + (wheelData.width - baseWidth) + xOffsetDifference)
                wheeXMLObject:delete()
            end
        end
        sizeData.width = sizeData.width + maxOffset
    end
end
function VehicleConfigurationItemWheel.postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
    VehicleConfigurationItemWheel:superClass().postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
    for i, baseConfigItem in ipairs(configurationItems) do
        if baseConfigItem.dimensionCombinations ~= nil and baseConfigItem.isSelectable then
            baseConfigItem.isSelectable = false
            VehicleConfigurationItemWheel.generateConfigurations(configurationItems, xmlFile, configName, baseConfigItem)
        end
    end
    local hasWheelBrands = false
    for baseConfigItem, item in ipairs(configurationItems) do
        if item.wheelBrandName ~= nil then
            hasWheelBrands = true
            break
        end
    end
    if hasWheelBrands then
        for baseConfigItem, item in ipairs(configurationItems) do
            if item.isSelectable and item.wheelBrandName == nil then
                Logging.xmlWarning(xmlFile, "Wheel brand missing for wheel configuration \'%s\'!", item.wheelBrandKey)
            end
        end
    end
end
function VehicleConfigurationItemWheel.getFallbackConfigId(configs, configId, _, _)
    local parts = configId:split("_")
    local maxNumMatches = 0
    local maxNumMatchesConfig = nil
    for _, config in pairs(configs) do
        local otherParts = config.saveId:split("_")
        local numMatches = 0
        local i = 1
        for i = i, math.min(#parts, #otherParts) do
            if parts[i] ~= otherParts[i] then
                break
            end
        end
        if maxNumMatches < numMatches then
            maxNumMatchesConfig = config
            maxNumMatches = numMatches
        end
    end
    if maxNumMatchesConfig == nil then
        return nil, nil
    else
        return maxNumMatchesConfig.index, maxNumMatchesConfig.saveId
    end
end
function VehicleConfigurationItemWheel.generateConfigurations(configurationItems, _, configName, baseConfigItem)
    local tireCombinations = g_wheelManager:getTiresForDimensionCombinations(baseConfigItem.dimensionCombinations, baseConfigItem.tireCategories, baseConfigItem.whitelistedCombinations, baseConfigItem.numDynamicConfigurations, baseConfigItem.customBrandOrder)
    for _, tireCombination in ipairs(tireCombinations) do
        local configItem = VehicleConfigurationItemWheel.new(configName)
        configItem.name = baseConfigItem.name
        if tireCombination.index > 1 then
            configItem.name = string.format("%s (%d)", configItem.name, tireCombination.index)
        end
        configItem.price = baseConfigItem.price
        configItem.wheelBrandName = tireCombination.wheelBrand.name
        configItem.wheelBrandIconFilename = tireCombination.wheelBrand.image
        configItem.isDefault = baseConfigItem.isDefault
        configItem.saveId = baseConfigItem.saveId .. "_" .. tireCombination.wheelSaveId
        configItem.isDynamicConfig = true
        configItem.tireCombination = tireCombination
        configItem.baseConfigItem = baseConfigItem
        configItem.maxForwardSpeed = baseConfigItem.maxForwardSpeed
        configItem.maxForwardSpeedShop = baseConfigItem.maxForwardSpeedShop
        table.insert(configurationItems, configItem)
        local index = #configurationItems
        configItem:setIndex(index)
        configItem.configKey = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", index - 1)
    end
end
function VehicleConfigurationItemWheel:applyGeneratedConfiguration(xmlFile)
    if self.isDynamicConfig then
        xmlFile:copyTree(self.baseConfigItem.configKey, self.configKey, true, ".wheel")
        xmlFile:setValue(self.configKey .. ".wheels#baseConfig", self.baseConfigItem.saveId)
        local configurationIndexToParentConfigIndex = Wheels.createConfigToParentConfigMapping(xmlFile)
        for wheelIndex, wheelData in ipairs(self.tireCombination.wheels) do
            local wheelKey = string.format(".wheels.wheel(%d)", wheelIndex - 1)
            local wheeXMLObject = WheelXMLObject.new(xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", self.baseConfigItem.index, wheelKey, configurationIndexToParentConfigIndex)
            wheeXMLObject:setXMLLoadKey("")
            if wheelData.path == nil then
                xmlFile:setBool(self.configKey .. wheelKey .. "#temp", true)
            else
                local path = wheelData.path
                if string.startsWith(path, "data/shared/wheels") then
                end
                xmlFile:setValue(self.configKey .. wheelKey .. "#filename", path)
                local baseRadius = wheelData.radius
                if self.baseConfigItem.baseWheelData ~= nil and self.baseConfigItem.baseWheelData[wheelIndex] ~= nil then
                    baseRadius = self.baseConfigItem.baseWheelData[wheelIndex].radius
                end
                local baseYOffset = wheeXMLObject:getLocalValue(".physics#yOffset") or 0
                xmlFile:setValue(self.configKey .. wheelKey .. ".physics#yOffset", baseYOffset - (baseRadius - wheelData.radius))
            end
            wheeXMLObject:delete()
        end
    end
end
function VehicleConfigurationItemWheel:applyObjectChanges(vehicle, configurationIndexToParentConfigIndex, index)
    local parentConfigIndex = configurationIndexToParentConfigIndex[index or self.index]
    if parentConfigIndex ~= nil then
        self:applyObjectChanges(vehicle, configurationIndexToParentConfigIndex, parentConfigIndex)
    end
    local key = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", (index or self.index) - 1)
    local objects = {}
    ObjectChangeUtil.loadObjectChangeFromXML(vehicle.xmlFile, key, objects, vehicle.components, vehicle)
    ObjectChangeUtil.setObjectChanges(objects, true, vehicle, vehicle.setMovingToolDirty)
end
function VehicleConfigurationItemWheel.registerXMLPaths(schema, rootPath, configPath)
    VehicleConfigurationItemWheel:superClass().registerXMLPaths(schema, rootPath, configPath)
    schema:register(XMLValueType.STRING, configPath .. "#brand", "Name of wheel brand")
    schema:register(XMLValueType.FLOAT, configPath .. "#maxForwardSpeed", "Max. speed to set on the transmission")
    schema:register(XMLValueType.FLOAT, configPath .. "#maxForwardSpeedShop", "Max. speed to display in the shop")
end