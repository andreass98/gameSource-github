WheelManager = {}
WheelManager.DEFAULT_FILENAME = "data/shared/wheels/wheels.xml"
WheelManager.BRAND_TO_SORT_INDEX = {}
WheelManager.BRAND_TO_SORT_INDEX.TRELLEBORG = 1
WheelManager.BRAND_TO_SORT_INDEX.MICHELIN = 2
WheelManager.BRAND_TO_SORT_INDEX.CONTINENTAL = 3
WheelManager.BRAND_TO_SORT_INDEX.MITAS = 4
WheelManager.BRAND_TO_SORT_INDEX.BKT = 5
WheelManager.BRAND_TO_SORT_INDEX.VREDESTEIN = 6
WheelManager.BRAND_TO_SORT_INDEX.NOKIAN = 7
local WheelManager_mt = Class(WheelManager, AbstractManager)
function WheelManager.new(customMt)
    -- upvalues: (copy) WheelManager_mt
    return AbstractManager.new(customMt or WheelManager_mt)
end
function WheelManager:initDataStructures()
    self.wheels = {}
    self.wheelsByBasePath = {}
    self.sortedTypedWheels = {}
    self.wheelFilenameToAttributes = {}
end
function WheelManager:loadMapData(_, _, baseDirectory)
    WheelManager:superClass().loadMapData(self)
    self.baseDirectory = baseDirectory
    local wheelsXMLFile = XMLFile.load("wheelsXML", WheelManager.DEFAULT_FILENAME)
    if wheelsXMLFile ~= nil then
        self:loadWheelsFromXML(wheelsXMLFile, "wheels", baseDirectory)
        wheelsXMLFile:delete()
    end
    return true
end
function WheelManager:loadWheelsFromXML(xmlFile, key, baseDirectory)
    xmlFile:iterate(key .. ".wheel", function(_, wheelKey)
        -- upvalues: (copy) xmlFile, (copy) baseDirectory, (copy) self
        local wheel = {
            ["path"] = xmlFile:getString(wheelKey .. "#filename")
        }
        if wheel.path == nil then
            Logging.xmlWarning(xmlFile, "Missing filename for wheel \'%s\'", wheelKey)
            return
        else
            wheel.path = Utils.getFilename(wheel.path, baseDirectory)
            wheel.radius = xmlFile:getFloat(wheelKey .. "#radius")
            if wheel.radius == nil then
                Logging.xmlWarning(xmlFile, "Missing radius for wheel \'%s\'", wheelKey)
                return
            else
                wheel.width = xmlFile:getFloat(wheelKey .. "#width")
                if wheel.width == nil then
                    Logging.xmlWarning(xmlFile, "Missing width for wheel \'%s\'", wheelKey)
                else
                    wheel.category = xmlFile:getString(wheelKey .. "#category", "UNKNOWN")
                    wheel.allowMixture = xmlFile:getBool(wheelKey .. "#allowMixture", true)
                    wheel.priority = xmlFile:getFloat(wheelKey .. "#priority", 1)
                    wheel.filename = Utils.getFilenameFromPath(wheel.path)
                    wheel.filename = string.split(wheel.filename, ".")[1]
                    wheel.basePath = Utils.getDirectory(wheel.path)
                    local pathParts = wheel.basePath:split("/")
                    wheel.wheelBrand = g_brandManager:getBrandByName(pathParts[#pathParts - 2]) or g_brandManager:getBrandByIndex(Brand.NONE)
                    wheel.wheelName = pathParts[#pathParts - 1] or "Unknown"
                    if self.wheelFilenameToAttributes[wheel.filename] == nil then
                        self.wheelFilenameToAttributes[wheel.filename] = {
                            ["baseFilename"] = wheel.path,
                            ["radius"] = wheel.radius,
                            ["width"] = wheel.width
                        }
                    else
                        local targetAttributes = self.wheelFilenameToAttributes[wheel.filename]
                        if math.abs(wheel.radius - targetAttributes.radius) > 0.001 then
                            Logging.xmlWarning(xmlFile, "Invalid radius for wheel \'%s\'. Does not equal the default radius for this tire size. (Base: %.3f from %s)", wheel.path, targetAttributes.radius, targetAttributes.baseFilename)
                        end
                        if math.abs(wheel.width - targetAttributes.width) > 0.001 then
                            Logging.xmlWarning(xmlFile, "Invalid width for wheel \'%s\'. Does not equal the default width for this tire size. (Base: %.3f from %s)", wheel.path, targetAttributes.width, targetAttributes.baseFilename)
                        end
                    end
                    table.insert(self.wheels, wheel)
                    if self.wheelsByBasePath[wheel.basePath] == nil then
                        self.wheelsByBasePath[wheel.basePath] = {}
                        table.insert(self.sortedTypedWheels, self.wheelsByBasePath[wheel.basePath])
                    end
                    table.insert(self.wheelsByBasePath[wheel.basePath], wheel)
                end
            end
        end
    end)
    table.sort(self.sortedTypedWheels, function(a, b)
        if a[1].wheelBrand.name == b[1].wheelBrand.name then
            if a[1].priority == b[1].priority then
                return a[1].wheelName < b[1].wheelName
            else
                return a[1].priority > b[1].priority
            end
        else
            return a[1].wheelBrand.name < b[1].wheelBrand.name
        end
    end)
end
function WheelManager:getTiresForDimensionCombinations(dimensionCombinations, tireCategories, whitelistedCombinations, numDynamicConfigurations, customBrandOrder)
    local tireCombinations = {}
    for dimensionIndex, dimensionCombination in ipairs(dimensionCombinations) do
        for _, wheels in ipairs(self.sortedTypedWheels) do
            local wheelsAllowed = true
            if #whitelistedCombinations > 0 then
                local brandFound = false
                local wheelFound = false
                for _, whitelistedCombination in pairs(whitelistedCombinations) do
                    if whitelistedCombination.brand == wheels[1].wheelBrand then
                        brandFound = true
                        for _, name in ipairs(whitelistedCombination.names) do
                            if name == wheels[1].wheelName then
                                wheelFound = true
                            end
                        end
                    end
                end
                wheelsAllowed = not brandFound or brandFound and wheelFound
            end
            if wheelsAllowed then
                local brandFound = {
                    ["wheels"] = {},
                    ["wheelBrand"] = nil,
                    ["wheelSaveId"] = ""
                }
                for wheelIndex, _ in ipairs(dimensionCombination) do
                    for _, _ in ipairs(wheels) do
                        if _.filename == _ and (tireCategories == nil or tireCategories[_.category] == true) then
                            brandFound.wheels[wheelIndex] = _
                            break
                        end
                        if _ == "-" then
                            brandFound.wheels[wheelIndex] = {}
                        end
                    end
                end
                local wheelFound = false
                local numWheels = table.size(brandFound.wheels)
                if numWheels > 0 and numWheels ~= #dimensionCombination then
                    self:fillCombinationWithMixedTires(dimensionCombination, brandFound, tireCategories, whitelistedCombinations)
                    wheelFound = true
                end
                if table.size(brandFound.wheels) == #dimensionCombination then
                    local firstWheel = nil
                    for _, wheel in pairs(brandFound.wheels) do
                        if wheel.wheelBrand ~= nil then
                            firstWheel = wheel
                        end
                    end
                    local wheelIndex = firstWheel ~= nil
                    if numDynamicConfigurations ~= math.huge then
                        local _ = 0
                        for _, _ in ipairs(tireCombinations) do
                            if _.wheelBrand == firstWheel.wheelBrand then
                                _ = _ + 1
                                if numDynamicConfigurations <= _ then
                                    wheelIndex = false
                                    break
                                end
                            end
                        end
                    end
                    if wheelFound then
                        for wheel, _ in ipairs(tireCombinations) do
                            local _ = true
                            local i = 1
                            for i = i, #brandFound.wheels do
                                if brandFound.wheels[i].path ~= _.wheels[i].path then
                                    _ = false
                                    break
                                end
                            end
                            if _ then
                                wheelIndex = false
                            end
                        end
                    end
                    if wheelIndex then
                        ({})[firstWheel.wheelBrand] = (({})[firstWheel.wheelBrand] or 0) + 1
                        brandFound.index = indexByBrand[firstWheel.wheelBrand]
                        brandFound.wheelBrand = firstWheel.wheelBrand
                        brandFound.wheelSaveId = firstWheel.wheelBrand.name .. "_" .. firstWheel.wheelName
                        local _ = 0
                        if customBrandOrder ~= nil then
                        end
                        if _ == 0 then
                            _ = 100 + (WheelManager.BRAND_TO_SORT_INDEX[firstWheel.wheelBrand.name] or math.huge)
                        end
                        brandFound.sortIndex = _ + brandFound.index * 0.01
                        table.insert(tireCombinations, brandFound)
                    end
                end
            end
        end
    end
    table.sort(tireCombinations, function(a, b)
        return a.sortIndex < b.sortIndex
    end)
    return tireCombinations
end
function WheelManager:fillCombinationWithMixedTires(dimensionCombination, tireCombination, tireCategories, whitelistedCombinations)
    local firstWheel = tireCombination.wheels[next(tireCombination.wheels)]
    if not firstWheel.allowMixture then
        return
    end
    local limitedTireNames = nil
    if #whitelistedCombinations > 0 then
        local foundBrand = false
        for _, whitelistedCombination in pairs(whitelistedCombinations) do
            if whitelistedCombination.brand == firstWheel.wheelBrand then
                foundBrand = true
                for _, name in ipairs(whitelistedCombination.names) do
                    if name == firstWheel.wheelName then
                        limitedTireNames = whitelistedCombination.names
                    end
                end
            end
        end
        if limitedTireNames == nil and foundBrand then
            return
        end
    end
    for _, _ in ipairs(self.sortedTypedWheels) do
        for wheelIndex, _ in ipairs(dimensionCombination) do
            if tireCombination.wheels[wheelIndex] == nil then
                for _, wheel in ipairs(_) do
                    if wheel.allowMixture and (wheel.filename == _ and (wheel.wheelBrand == wheelBrand and (tireCategories == nil or (tireCategories[wheel.category] == true or limitedTireNames ~= nil)))) then
                        local isAllowed = limitedTireNames ~= nil
                        if limitedTireNames ~= nil then
                            for _, name in ipairs(limitedTireNames) do
                                if name == wheel.wheelName then
                                    isAllowed = true
                                    break
                                end
                            end
                        end
                        if isAllowed then
                            tireCombination.wheels[wheelIndex] = wheel
                        end
                    end
                end
            end
        end
    end
end
function WheelManager:getWheelRadiusAndWidthFromDimension(dimension)
    for _, wheels in ipairs(self.sortedTypedWheels) do
        for _, wheel in ipairs(wheels) do
            if wheel.filename == dimension then
                return wheel.radius, wheel.width
            end
        end
    end
    return nil, nil
end
function WheelManager:getWheelRadiusAndWidthFromFilename(filename)
    for _, wheels in ipairs(self.sortedTypedWheels) do
        for _, wheel in ipairs(wheels) do
            if wheel.path == filename then
                return wheel.radius, wheel.width
            end
        end
    end
    return nil, nil
end
g_wheelManager = WheelManager.new()