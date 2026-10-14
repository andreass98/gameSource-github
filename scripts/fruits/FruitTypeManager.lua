source("dataS/scripts/fruits/FruitTypeDesc.lua")
FruitType = nil
FruitTypeCategory = nil
FruitTypeConverter = nil
FruitTypeManager = {}
FruitTypeManager.SEND_NUM_BITS = 6
g_xmlManager:addCreateSchemaFunction(function()
    FruitTypeManager.xmlSchema = XMLSchema.new("fruitTypes")
end)
g_xmlManager:addInitSchemaFunction(function()
    FruitTypeManager.registerXMLPaths(FruitTypeManager.xmlSchema, "map")
    FruitTypeManager.registerXMLPaths(Mission00.xmlSchema, "map")
end)
function FruitTypeManager.registerXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. ".fruitTypes.fruitType(?)#filename", "")
    local fruitTypeCategoriesKey = key .. ".fruitTypeCategories.fruitTypeCategory(?)"
    schema:register(XMLValueType.STRING, fruitTypeCategoriesKey .. "#name", "")
    schema:register(XMLValueType.STRING, fruitTypeCategoriesKey, "")
    local fruitTypeConverterssKey = key .. ".fruitTypeConverters.fruitTypeConverter(?)"
    schema:register(XMLValueType.STRING, fruitTypeConverterssKey .. "#name", "")
    schema:register(XMLValueType.STRING, fruitTypeConverterssKey .. ".converter(?)#from", "")
    schema:register(XMLValueType.STRING, fruitTypeConverterssKey .. ".converter(?)#to", "")
    schema:register(XMLValueType.FLOAT, fruitTypeConverterssKey .. ".converter(?)#factor", "")
end
local FruitTypeManager_mt = Class(FruitTypeManager, AbstractManager)
function FruitTypeManager.new(customMt)
    -- upvalues: (copy) FruitTypeManager_mt
    local self = AbstractManager.new(customMt or FruitTypeManager_mt)
    addConsoleCommand("gsFruitTypesExportStats", "Exports the fruit type stats into a text file", "consoleCommandExportStats", self)
    return self
end
function FruitTypeManager:initDataStructures()
    self.fruitTypes = {}
    self.indexToFruitType = {}
    self.nameToIndex = {}
    self.nameToFruitType = {}
    self.fruitTypeIndexToFillType = {}
    self.fillTypeIndexToFruitTypeIndex = {}
    self.densityTypeIndexToFruitType = {}
    self.filenameToFruitType = {}
    self.fruitTypeConverters = {}
    self.fruitTypeConverterLoadData = {}
    self.converterNameToIndex = {}
    self.nameToConverter = {}
    self.windrowFillTypes = {}
    self.fruitTypeIndexToWindrowFillTypeIndex = {}
    self.windrowCutFillTypeIndexToFruitTypeIndex = {}
    self.modFoliageTypesToLoad = {}
    self.numCategories = 0
    self.categories = {}
    self.indexToCategory = {}
    self.categoryIndexToFruitTypeIndex = {}
    FruitType = self.nameToIndex
    FruitType.UNKNOWN = 0
    FruitTypeCategory = self.categories
    FruitTypeConverter = self.converterNameToIndex
    self.defaultDataPlaneId = nil
end
function FruitTypeManager:loadDefaultTypes()
    local xmlFile = loadXMLFile("fuitTypes", "data/maps/maps_fruitTypes.xml")
    self:loadFruitTypes(xmlFile, nil, "", true)
    delete(xmlFile)
end
function FruitTypeManager:loadMapData(xmlFileHandle, missionInfo, baseDirectory)
    FruitTypeManager:superClass().loadMapData(self)
    self.modFruitTypes = {}
    XMLUtil.loadDataFromMapXML(xmlFileHandle, "fruitTypes", baseDirectory, self, self.loadMapFruitTypes, missionInfo, baseDirectory)
    self:loadDefaultTypes()
    XMLUtil.loadDataFromMapXML(xmlFileHandle, "fruitTypes", baseDirectory, self, self.loadMapCategoriesAndConverters, missionInfo, baseDirectory)
    self:initializeFruitTypeConverters()
    return true
end
function FruitTypeManager:loadMapFruitTypes(xmlFileHandle, _, baseDirectory)
    local xmlFile = XMLFile.wrap(xmlFileHandle)
    for _, key in xmlFile:iterator(xmlFile:getRootName() .. ".fruitTypes.fruitType") do
        local filename = xmlFile:getString(key .. "#filename")
        if filename ~= nil then
            local fruitTypeDesc = Utils.getFilename(filename, baseDirectory)
            local fruitTypeDesc = FruitTypeDesc.new()
            if fruitTypeDesc:loadFromFoliageXMLFile(fruitTypeDesc) then
                table.insert(self.modFruitTypes, fruitTypeDesc)
            end
        end
    end
    xmlFile:delete()
end
function FruitTypeManager:loadFruitTypeFromXML(xmlFilename)
    local fruitTypeDesc = FruitTypeDesc.new()
    if fruitTypeDesc:loadFromFoliageXMLFile(xmlFilename) then
        self:addFruitType(fruitTypeDesc)
    end
end
function FruitTypeManager:loadMapCategoriesAndConverters(xmlFileHandle, _, _)
    local xmlFile = XMLFile.wrap(xmlFileHandle)
    local rootName = xmlFile:getRootName()
    self:loadCategoriesFromXML(xmlFile, rootName, false)
    self:loadConvertersFromXML(xmlFile, rootName, false)
    xmlFile:delete()
end
function FruitTypeManager:initializeFruitTypeConverters()
    for converter, converterData in pairs(self.fruitTypeConverterLoadData) do
        if self.fruitTypeConverters[converter] ~= nil then
            for _, data in ipairs(converterData) do
                local fruitType = self:getFruitTypeByName(data.fruitTypeName)
                local fillType = g_fillTypeManager:getFillTypeByName(data.fillTypeName)
                if fruitType ~= nil and fillType ~= nil then
                    self.fruitTypeConverters[converter][fruitType.index] = {
                        ["fillTypeIndex"] = fillType.index,
                        ["conversionFactor"] = data.conversionFactor
                    }
                end
            end
        end
    end
    self.fruitTypeConverterLoadData = {}
end
function FruitTypeManager:addFruitType(fruitTypeDesc)
    Logging.info("Loaded fruit type \'%s\' from \'%s\'", fruitTypeDesc.name, fruitTypeDesc.xmlFilename)
    table.insert(self.fruitTypes, fruitTypeDesc)
    fruitTypeDesc.index = #self.fruitTypes
    self.nameToFruitType[fruitTypeDesc.name] = fruitTypeDesc
    self.nameToIndex[fruitTypeDesc.name] = fruitTypeDesc.index
    self.indexToFruitType[fruitTypeDesc.index] = fruitTypeDesc
    self.filenameToFruitType[fruitTypeDesc.xmlFilename] = fruitTypeDesc
    self.fillTypeIndexToFruitTypeIndex[fruitTypeDesc.fillType.index] = fruitTypeDesc.index
    self.fruitTypeIndexToFillType[fruitTypeDesc.index] = fruitTypeDesc.fillType
    local windrowFillType = fruitTypeDesc.windrowFillType
    if windrowFillType ~= nil then
        self.windrowFillTypes[windrowFillType.index] = true
        self.fruitTypeIndexToWindrowFillTypeIndex[fruitTypeDesc.index] = windrowFillType.index
        self.fillTypeIndexToFruitTypeIndex[windrowFillType.index] = fruitTypeDesc.index
    end
    if fruitTypeDesc.windrowCutFillType ~= nil then
        self.windrowCutFillTypeIndexToFruitTypeIndex[fruitTypeDesc.windrowCutFillType.index] = fruitTypeDesc.index
    end
end
function FruitTypeManager:loadFruitTypes(xmlFileHandle, _, baseDirectory, isBaseType)
    local xmlFile = XMLFile.wrap(xmlFileHandle)
    local rootName = xmlFile:getRootName()
    for _, key in xmlFile:iterator(rootName .. ".fruitTypes.fruitType") do
        if 2 ^ FruitTypeManager.SEND_NUM_BITS - 1 <= #self.fruitTypes then
            Logging.xmlError(xmlFile, "FruitTypeManager.loadFruitTypes: too many fruit types. Only %d fruit types are supported", maxNumFruitTypes)
        end
        local filename = xmlFile:getString(key .. "#filename")
        if filename == nil then
            Logging.xmlWarning(xmlFile, "FruitTypeManager.loadFruitTypes: Missing fruit type filename for \'%s\'", key)
        else
            local fruitTypeDesc = Utils.getFilename(filename, baseDirectory)
            local fruitTypeDesc = FruitTypeDesc.new()
            if fruitTypeDesc:loadFromFoliageXMLFile(fruitTypeDesc) then
                if self.modFruitTypes ~= nil then
                    for k, modFruitTypeDesc in ipairs(self.modFruitTypes) do
                        if modFruitTypeDesc.name == fruitTypeDesc.name then
                            fruitTypeDesc:delete()
                            table.remove(self.modFruitTypes, k)
                            break
                        end
                    end
                end
                self:addFruitType(fruitTypeDesc)
            end
        end
    end
    if self.modFruitTypes ~= nil then
        for _, key in ipairs(self.modFruitTypes) do
            self:addFruitType(key)
        end
    end
    self.modFruitTypes = nil
    self:loadCategoriesFromXML(xmlFile, rootName, isBaseType)
    self:loadConvertersFromXML(xmlFile, rootName, isBaseType)
    xmlFile:delete()
end
function FruitTypeManager:loadCategoriesFromXML(xmlFile, rootName, isBaseType)
    for _, key in xmlFile:iterator(rootName .. ".fruitTypeCategories.fruitTypeCategory") do
        local name = xmlFile:getString(key .. "#name")
        local fruitTypesStr = xmlFile:getString(key)
        local fruitTypeCategoryIndex = self:addFruitTypeCategory(name, isBaseType)
        if fruitTypeCategoryIndex ~= nil then
            local fruitTypeNames = string.split(fruitTypesStr, " ")
            for _, fruitTypeName in ipairs(fruitTypeNames) do
                local fruitType = self:getFruitTypeByName(fruitTypeName)
                if fruitType == nil then
                    Logging.xmlWarning(xmlFile, "FruitTypeManager.loadFruitTypes: FruitType \'%s\' referenced in fruitTypeCategory \'%s\' is not defined!", fruitTypeName, name)
                elseif not self:addFruitTypeToCategory(fruitType.index, fruitTypeCategoryIndex) then
                    Logging.xmlWarning(xmlFile, "FruitTypeManager.loadFruitTypes: Could not add fruitType \'%s\' to fruitTypeCategory \'%s\'!", fruitTypeName, name)
                end
            end
        end
    end
end
function FruitTypeManager:loadConvertersFromXML(xmlFile, rootName, isBaseType)
    for _, key in xmlFile:iterator(rootName .. ".fruitTypeConverters.fruitTypeConverter") do
        local converter = self:addFruitTypeConverter(xmlFile:getString(key .. "#name"), isBaseType)
        if converter ~= nil then
            for _, converterKey in xmlFile:iterator(key .. ".converter") do
                self:addFruitTypeConversion(converter, xmlFile:getString(converterKey .. "#from"), xmlFile:getString(converterKey .. "#to"), (xmlFile:getFloat(converterKey .. "#factor", 1)))
            end
        end
    end
end
function FruitTypeManager:getFruitTypeByIndex(index)
    return self.indexToFruitType[index]
end
function FruitTypeManager:getFruitTypeNameByIndex(index)
    local fruitType = self.indexToFruitType[index]
    if fruitType == nil then
        return index == FruitType.UNKNOWN and "UNKNOWN" or nil
    else
        return fruitType.name
    end
end
function FruitTypeManager:getFruitTypeByName(name)
    if name == nil then
        return nil
    else
        return self.nameToFruitType[string.upper(name)]
    end
end
function FruitTypeManager:getFruitTypeIndexByName(name)
    local fruitType = self:getFruitTypeByName(name)
    if fruitType == nil then
        return nil
    else
        return fruitType.index
    end
end
function FruitTypeManager:getFruitTypes()
    return self.fruitTypes
end
function FruitTypeManager:getFruitTypeIndexByFillTypeIndex(index)
    return self.fillTypeIndexToFruitTypeIndex[index]
end
function FruitTypeManager:getFruitTypeByFillTypeIndex(index)
    return self.fruitTypes[self.fillTypeIndexToFruitTypeIndex[index]]
end
function FruitTypeManager:getFillTypeIndexByFruitTypeIndex(index)
    local fillType = self.fruitTypeIndexToFillType[index]
    if fillType == nil then
        return nil
    else
        return fillType.index
    end
end
function FruitTypeManager:getFillTypeByFruitTypeIndex(index)
    return self.fruitTypeIndexToFillType[index]
end
function FruitTypeManager:getFillTypeNameByFruitTypeIndex(index)
    local fillTypeIndex = self.fruitTypeIndexToFillType[index]
    return fillTypeIndex and fillTypeIndex.name or nil
end
function FruitTypeManager:getCutHeightByFruitTypeIndex(index, isForageCutter)
    local fruitType = self.indexToFruitType[index]
    return isForageCutter and (fruitType and (fruitType.forageCutHeight or fruitType.cutHeight) or 0.15) or (fruitType and fruitType.cutHeight or 0.15)
end
function FruitTypeManager:getFruitTypeAreaLiters(fruitTypeIndex, area, useWindrow)
    local fruitType = self.indexToFruitType[fruitTypeIndex]
    return fruitType == nil and 0 or fruitType:getAreaLiters(area, useWindrow)
end
function FruitTypeManager:addFruitTypeCategory(name, isBaseType)
    if not ClassUtil.getIsValidIndexName(name) then
        printWarning("Warning: \'" .. tostring(name) .. "\' is not a valid name for a fruitTypeCategory. Ignoring fruitTypeCategory!")
        return nil
    end
    local index = string.upper(name)
    if isBaseType and self.categories[index] ~= nil then
        printWarning("Warning: FruitTypeCategory \'" .. tostring(index) .. "\' already exists. Ignoring fruitTypeCategory!")
        return nil
    end
    local index = self.categories[index]
    if index == nil then
        self.numCategories = self.numCategories + 1
        self.categories[index] = self.numCategories
        self.indexToCategory[self.numCategories] = index
        self.categoryIndexToFruitTypeIndex[self.numCategories] = {}
        index = self.numCategories
    end
    return index
end
function FruitTypeManager:addFruitTypeToCategory(fruitTypeIndex, categoryIndex)
    if categoryIndex == nil or fruitTypeIndex == nil then
        return false
    end
    table.insert(self.categoryIndexToFruitTypeIndex[categoryIndex], fruitTypeIndex)
    return true
end
function FruitTypeManager:getFruitTypesByCategoryNames(names, warning)
    local fruitTypes = {}
    local categories = string.split(names, " ")
    for _, categoryName in pairs(categories) do
        local categoryIndex = string.upper(categoryName)
        local categoryIndex = self.categories[categoryIndex]
        local categoryFruitTypeIndices = self.categoryIndexToFruitTypeIndex[categoryIndex]
        if categoryFruitTypeIndices == nil then
            if warning ~= nil then
                printWarning(string.format(warning, categoryIndex))
            end
        else
            for _, fruitTypeIndex in ipairs(categoryFruitTypeIndices) do
                local fruitType = self.indexToFruitType[fruitTypeIndex]
                if ({})[fruitType] == nil then
                    table.insert(fruitTypes, fruitType)
                    alreadyAdded[fruitType] = true
                end
            end
        end
    end
    return fruitTypes
end
function FruitTypeManager:getFruitTypeIndicesByCategoryNames(names, warning)
    local fruitTypes = self:getFruitTypesByCategoryNames(names, warning)
    for index, fruitType in ipairs(fruitTypes) do
        fruitTypes[index] = fruitType.index
    end
    return fruitTypes
end
function FruitTypeManager:getFruitTypesByNames(names, warning)
    local fruitTypes = {}
    local fruitTypeNames = string.split(names, " ")
    for _, name in pairs(fruitTypeNames) do
        local fruitType = string.upper(name)
        local fruitType = self.nameToFruitType[fruitType]
        if fruitType == nil then
            if warning ~= nil then
                printWarning(string.format(warning, fruitType))
            end
        elseif ({})[fruitType] == nil then
            table.insert(fruitTypes, fruitType)
            alreadyAdded[fruitType] = true
        end
    end
    return fruitTypes
end
function FruitTypeManager:getFruitTypeIndicesByNames(names, warning)
    local fruitTypes = self:getFruitTypesByNames(names, warning)
    for index, fruitType in ipairs(fruitTypes) do
        fruitTypes[index] = fruitType.index
    end
    return fruitTypes
end
function FruitTypeManager:getFillTypesByFruitTypeNames(names, warning)
    local fillTypes = {}
    local fruitTypeNames = string.split(names, " ")
    for _, name in pairs(fruitTypeNames) do
        local fillType = nil
        local fruitType = self:getFruitTypeByName(name)
        if fruitType ~= nil then
            fillType = self:getFillTypeByFruitTypeIndex(fruitType.index)
        end
        if fillType == nil then
            if warning ~= nil then
                printWarning(string.format(warning, name))
            end
        elseif ({})[fillType] == nil then
            table.insert(fillTypes, fillType)
            alreadyAdded[fillType] = true
        end
    end
    return fillTypes
end
function FruitTypeManager:getFillTypeIndicesByFruitTypeNames(names, warning)
    local fillTypes = self:getFillTypesByFruitTypeNames(names, warning)
    for index, fillType in ipairs(fillTypes) do
        fillTypes[index] = fillType.index
    end
    return fillTypes
end
function FruitTypeManager:getFillTypesByFruitTypeCategoryNames(fruitTypeCategoryNames, warning)
    local fillTypes = {}
    local categories = string.split(fruitTypeCategoryNames, " ")
    for _, categoryName in pairs(categories) do
        local category = string.upper(categoryName)
        local category = self.categories[category]
        if category == nil then
            if warning ~= nil then
                printWarning(string.format(warning, category))
            end
        else
            for _, fruitTypeIndex in ipairs(self.categoryIndexToFruitTypeIndex[category]) do
                local fillType = self:getFillTypeByFruitTypeIndex(fruitTypeIndex)
                if fillType ~= nil and ({})[fillType] == nil then
                    table.insert(fillTypes, fillType)
                    alreadyAdded[fillType] = true
                end
            end
        end
    end
    return fillTypes
end
function FruitTypeManager:getFillTypeIndicesByFruitTypeCategoryName(fruitTypeCategoryNames, warning)
    local fillTypes = self:getFillTypesByFruitTypeCategoryNames(fruitTypeCategoryNames, warning)
    for index, fillType in ipairs(fillTypes) do
        fillTypes[index] = fillType.index
    end
    return fillTypes
end
function FruitTypeManager:isFillTypeWindrow(index)
    if index == nil then
        return false
    end
    return self.windrowFillTypes[index] == true
end
function FruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(index)
    return self.fruitTypeIndexToWindrowFillTypeIndex[index]
end
function FruitTypeManager:getFillTypeLiterPerSqm(fillTypeIndex, defaultValue)
    local fruitType = self.fruitTypes[self:getFruitTypeIndexByFillTypeIndex(fillTypeIndex)]
    if fruitType == nil then
        return defaultValue
    elseif fruitType.hasWindrow then
        return fruitType.windrowLiterPerSqm
    else
        return fruitType.literPerSqm
    end
end
function FruitTypeManager:getCutWindrowHarvestFillLevel(fillTypeIndex, liters)
    local fruitTypeIndex = self.windrowCutFillTypeIndexToFruitTypeIndex[fillTypeIndex]
    if fruitTypeIndex ~= nil then
        local fruitType = self.indexToFruitType[fruitTypeIndex]
        if fruitType ~= nil then
            if fruitType.windrowLiterPerSqm ~= nil then
            end
            return liters * fruitType.literPerSqm * fruitType.windrowCutFactor
        end
    end
    return liters
end
function FruitTypeManager:addFruitTypeConverter(name, isBaseType)
    if not ClassUtil.getIsValidIndexName(name) then
        printWarning("Warning: \'" .. tostring(name) .. "\' is not a valid name for a fruitTypeConverter. Ignoring fruitTypeConverter!")
        return nil
    end
    local index = string.upper(name)
    if isBaseType and self.converterNameToIndex[index] ~= nil then
        printWarning("Warning: FruitTypeConverter \'" .. tostring(index) .. "\' already exists. Ignoring fruitTypeConverter!")
        return nil
    end
    local index = self.converterNameToIndex[index]
    if index == nil then
        local converter = {}
        table.insert(self.fruitTypeConverters, converter)
        self.converterNameToIndex[index] = #self.fruitTypeConverters
        self.nameToConverter[index] = converter
        index = #self.fruitTypeConverters
    end
    return index
end
function FruitTypeManager:addFruitTypeConversion(converter, fruitTypeName, fillTypeName, conversionFactor)
    if converter ~= nil then
        if self.fruitTypeConverterLoadData[converter] == nil then
            self.fruitTypeConverterLoadData[converter] = {}
        end
        table.insert(self.fruitTypeConverterLoadData[converter], {
            ["fruitTypeName"] = fruitTypeName,
            ["fillTypeName"] = fillTypeName,
            ["conversionFactor"] = conversionFactor
        })
    end
end
function FruitTypeManager:getConverterDataByName(converterName)
    if converterName then
        converterName = string.upper(converterName)
    end
    return self.nameToConverter[converterName]
end
function FruitTypeManager:addModFoliageType(name, filename)
    table.insert(self.modFoliageTypesToLoad, {
        ["name"] = name,
        ["filename"] = filename
    })
end
function FruitTypeManager:getDefaultDataPlaneId()
    return self.defaultDataPlaneId
end
function FruitTypeManager:addTerrainDataPlane(dataPlaneId)
    if self.defaultDataPlaneId == nil then
        self.defaultDataPlaneId = dataPlaneId
    end
end
function FruitTypeManager:getFirstHaulmFruitType()
    return self.firstHaulmFruitTypeDesc
end
function FruitTypeManager:addHaulmFruitType(fruitTypeDesc)
    if self.firstHaulmFruitTypeDesc == nil then
        self.firstHaulmFruitTypeDesc = fruitTypeDesc
    end
end
function FruitTypeManager:setTerrainDataPlaneIndex(fruitType, terrainDataPlaneIndex)
    self.densityTypeIndexToFruitType[terrainDataPlaneIndex] = fruitType
end
function FruitTypeManager:getFruitTypeByDensityTypeIndex(densityTypeIndex)
    return self.densityTypeIndexToFruitType[densityTypeIndex]
end
function FruitTypeManager:consoleCommandExportStats()
    local content = ""
    for _, fruitTypeDesc in ipairs(self.fruitTypes) do
        content = content .. fruitTypeDesc:getStatsText() .. "\n"
    end
    local content = (((content .. "\n") .. "\n") .. "Weeder / How States\n") .. " Name          "
    local i = 1
    for i = i, 9 do
        content = content .. string.format("[  %d  ] ", i)
    end
    local content = content .. "\n"
    for _, fruitTypeDesc in ipairs(self.fruitTypes) do
        content = content .. fruitTypeDesc:getWeedingStateText() .. "\n"
    end
    local i = io.open(getUserProfileAppPath() .. "fruitTypeStats.txt", "w")
    i:write(content)
    i:close()
    Logging.info("Fruit type stats exported to %s", filename)
end
function FruitTypeManager.convert(xmlFile, key)
    local name = xmlFile:getString(key .. "#name")
    if name == "meadow" then
        local foliageXml = XMLFile.load("foliage", "data/foliage/" .. name .. "/" .. name .. "DLC.xml")
        if foliageXml ~= nil then
            FruitTypeManager.convertFruitType(name, xmlFile, key, foliageXml, false)
            foliageXml:save()
            foliageXml:delete()
        end
        local foliageXml = XMLFile.load("foliage", "data/foliage/" .. name .. "/" .. name .. "US.xml")
        if foliageXml ~= nil then
            FruitTypeManager.convertFruitType(name, xmlFile, key, foliageXml, false)
            foliageXml:save()
            foliageXml:delete()
        end
        local foliageXml = XMLFile.load("foliage", "data/foliage/" .. name .. "/" .. name .. "FR.xml")
        if foliageXml ~= nil then
            FruitTypeManager.convertFruitType(name, xmlFile, key, foliageXml, true)
            foliageXml:save()
            foliageXml:delete()
        end
    else
        local foliageXml = XMLFile.load("foliage", "data/foliage/" .. name .. "/" .. name .. ".xml")
        if foliageXml ~= nil then
            FruitTypeManager.convertFruitType(name, xmlFile, key, foliageXml, true)
            foliageXml:save()
            foliageXml:delete()
        end
    end
    xmlFile:setString(key .. "#filename", "$data/foliage/" .. name .. "/" .. name .. ".xml")
    xmlFile:save()
end
function FruitTypeManager.convertFruitType(_, _, xmlFile, key, foliageXMLFile, removeProperties)
    local hasCultivationStates = false
    for k, cultivationKey in xmlFile:iterator(key .. ".cultivation.state") do
        ({})[xmlFile:getInt(cultivationKey .. "#state")] = true
        hasCultivationStates = true
    end
    for cultivationKey, cultivationState in foliageXMLFile:iterator("foliageType.foliageLayer.foliageState") do
        local stateName = foliageXMLFile:getString(cultivationState .. "#name")
        local parts = string.split(stateName, " ")
        local newName = table.remove(parts, 1)
        for i = 1, #parts do
            local nextPart = table.remove(parts, 1)
            local firstChar = string.sub(nextPart, 1, 1)
            local remainingChars = string.sub(nextPart, 2)
            newName = newName .. string.upper(firstChar) .. remainingChars
        end
        ({})[cultivationKey] = newName
        foliageXMLFile:setString(cultivationState .. "#name", newName)
        if hasCultivationStates and not cultivationStates[cultivationKey] then
            foliageXMLFile:setBool(cultivationState .. "#isCultivatable", false)
        end
    end
    local k = key .. "#name"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType#name", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".cultivation#alignsToSun"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.foliageLayer(0)#alignsToSun", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. "#shownOnMap"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType#shownOnMap", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. "#useForFieldJob"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType#useForFieldMissions", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".mapColors#default"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.mapColors#default", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".mapColors#colorBlind"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.mapColors#colorBlind", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".windrow#name"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.windrow#fillType", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".windrow#litersPerSqm"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.windrow#litersPerSqm", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".harvest#literPerSqm"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.harvest#litersPerSqm", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".harvest#cutHeight"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.harvest#cutHeight", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".harvest#chopperTypeName"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.harvest#chopperTypeName", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".growth#resetsSpray"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.growth#resetsSpray", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".growth#growthRequiresLime"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.growth#growthRequiresLime", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".options#lowSoilDensityRequired"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.soil#lowDensityRequired", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".options#increasesSoilDensity"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.soil#increasesDensity", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".options#consumesLime"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.soil#consumesLime", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".cultivation#directionSnapAngle"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.seeding#directionSnapAngle", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".cultivation#needsRolling"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.seeding#needsRolling", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".cultivation#seedUsagePerSqm"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.seeding#litersPerSqm", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".cultivation#allowsSeeding"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.seeding#isAvailable", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".cultivation#plantsWeed"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.seeding#plantsWeed", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".harvest#forageCutHeight"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.harvest#forageCutHeight", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".harvest#beeYieldBonusPercentage"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.harvest#beeYieldBonusPercentage", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".harvest#chopperType"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.harvest#chopperGroundType", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".destruction#canBeDestroyed"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.cultivation#isAllowed", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".mulcher#chopperTypeName"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.mulcher#chopperType", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".options#startSprayState"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.soil#startSprayLevel", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".harvestGroundTypeChange#groundType"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.harvest#groundType", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local k = key .. ".preparing#outputName"
    if xmlFile:hasProperty(k) then
        foliageXMLFile:setString("foliageType.fruitType.haulm#layerName", xmlFile:getString(k))
        if removeProperties then
            xmlFile:removeProperty(k)
        end
    end
    local function k(startIndex, endIndex, attributeName, value)
        -- upvalues: (copy) foliageXMLFile
        for k, stateKey in foliageXMLFile:iterator("foliageType.foliageLayer.foliageState") do
            if startIndex <= k and k <= endIndex then
                foliageXMLFile:setString(stateKey .. "#" .. attributeName, value)
            end
        end
    end
    local cultivationKey = xmlFile:getInt(key .. ".growth#numGrowthStates")
    if cultivationKey ~= nil then
        k(1, cultivationKey, "isGrowing", "true")
        if removeProperties then
            xmlFile:removeProperty(key .. ".growth#numGrowthStates")
        end
    end
    local cultivationState = xmlFile:getInt(key .. ".cropCare#maxWeederState")
    if cultivationState ~= nil then
        k(1, cultivationState, "allowsWeeding", "true")
        if removeProperties then
            xmlFile:removeProperty(key .. ".cropCare#maxWeederState")
        end
    end
    local stateName = xmlFile:getInt(key .. ".cropCare#maxWeederHoeState")
    if stateName ~= nil then
        k(1, stateName, "allowsHoeing", "true")
        if removeProperties then
            xmlFile:removeProperty(key .. ".cropCare#maxWeederHoeState")
        end
    end
    local parts = xmlFile:getInt(key .. ".growth#witheredState")
    if parts ~= nil then
        k(parts, parts, "isWithered", "true")
        if removeProperties then
            xmlFile:removeProperty(key .. ".growth#witheredState")
        end
    end
    local newName = xmlFile:getInt(key .. ".harvest#cutState")
    if newName ~= nil then
        k(newName, newName, "isCut", "true")
        if removeProperties then
            xmlFile:removeProperty(key .. ".harvest#cutState")
        end
    end
    local numParts = xmlFile:getInt(key .. ".harvest#minForageGrowthState")
    if numParts ~= nil then
        k(numParts, numParts, "isForageReady", "true")
        if removeProperties then
            xmlFile:removeProperty(key .. ".harvest#minForageGrowthState")
        end
    end
    local path = xmlFile:getInt(key .. ".growth#firstRegrowthState")
    if path ~= nil then
        k(path, path, "regrowthStart", "true")
        local path = key .. ".growth#firstRegrowthState"
        if removeProperties then
            xmlFile:removeProperty(path)
        end
    end
    local path = xmlFile:getInt(key .. ".mulcher#state")
    if path ~= nil then
        k(path, path, "isMulched", "true")
        if removeProperties then
            xmlFile:removeProperty(key .. ".mulcher#state")
        end
    end
    local i = xmlFile:getInt(key .. ".harvest#weedState")
    if i ~= nil then
        k(i, i, "isWeed", "true")
        if removeProperties then
            xmlFile:removeProperty(key .. ".harvest#weedState")
        end
    end
    local nextPart = xmlFile:getInt(key .. ".destruction#filterStart")
    local firstChar = xmlFile:getInt(key .. ".destruction#filterEnd")
    if nextPart ~= nil then
        k(nextPart, firstChar, "isDestructibleByWheel", "true")
        if removeProperties then
            xmlFile:removeProperty(key .. ".destruction#filterStart")
        end
        if removeProperties then
            xmlFile:removeProperty(key .. ".destruction#filterEnd")
        end
    end
    local remainingChars = xmlFile:getInt(key .. ".destruction#state")
    if remainingChars == nil then
        if newName ~= nil then
            k(newName, newName, "isDestructedByWheel", "true")
        end
    else
        k(remainingChars, remainingChars, "isDestructedByWheel", "true")
        if removeProperties then
            xmlFile:removeProperty(key .. ".destruction#state")
        end
    end
    local path = xmlFile:getInt(key .. ".harvest#minHarvestingGrowthState")
    local maxHarvest = xmlFile:getInt(key .. ".harvest#maxHarvestingGrowthState")
    if path ~= nil then
        k(path, maxHarvest, "isHarvestReady", "true")
        local path = key .. ".harvest#minHarvestingGrowthState"
        if removeProperties then
            xmlFile:removeProperty(path)
        end
        local path = key .. ".harvest#maxHarvestingGrowthState"
        if removeProperties then
            xmlFile:removeProperty(path)
        end
    end
    local path = xmlFile:getInt(key .. ".preparing#minGrowthState")
    local maxPrepareState = xmlFile:getInt(key .. ".preparing#maxGrowthState")
    if path ~= nil then
        k(path, maxPrepareState, "isPreparable", "true")
        local path = key .. ".preparing#minGrowthState"
        if removeProperties then
            xmlFile:removeProperty(path)
        end
        local path = key .. ".preparing#maxGrowthState"
        if removeProperties then
            xmlFile:removeProperty(path)
        end
    end
    local path = xmlFile:getInt(key .. ".preparing#preparedGrowthState")
    if path ~= nil then
        k(path, path, "isPrepared", "true")
        local path = key .. ".preparing#preparedGrowthState"
        if removeProperties then
            xmlFile:removeProperty(path)
        end
    end
    local path = xmlFile:getInt(key .. ".growthGroundTypeChange#state")
    local groundType = xmlFile:getString(key .. ".growthGroundTypeChange#groundType")
    local groundTypeMask = xmlFile:getString(key .. ".growthGroundTypeChange#groundTypeMask")
    if path ~= nil and groundType ~= nil then
        k(path, path, "groundType", groundType)
        if groundTypeMask ~= nil then
            k(path, path, "groundTypeMask", groundTypeMask)
        end
        local path = key .. ".growthGroundTypeChange#state"
        if removeProperties then
            xmlFile:removeProperty(path)
        end
        local path = key .. ".growthGroundTypeChange#groundType"
        if removeProperties then
            xmlFile:removeProperty(path)
        end
        local path = key .. ".growthGroundTypeChange#groundTypeMask"
        if removeProperties then
            xmlFile:removeProperty(path)
        end
    end
    for k, harvestKey in xmlFile:iterator(key .. ".harvest.transition") do
        local srcState = xmlFile:getInt(harvestKey .. "#srcState")
        local targetState = xmlFile:getInt(harvestKey .. "#targetState")
        local newKey = string.format("foliageType.fruitType.harvest.transition(%d)", k - 1)
        foliageXMLFile:setString(newKey .. "#src", stateNames[srcState])
        foliageXMLFile:setString(newKey .. "#target", stateNames[targetState])
    end
    local path = key .. ".general#startStateChannel"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".general#numStateChannels"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".growth#growthStateTime"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".growth#regrows"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".growth#numGrowthStates"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".cultivation#needsSeeding"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".mulcher#hasChopperGroundLayer"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. "#name"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".harvest#allowsPartialGrowthState"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".general"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".harvest"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".growth"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".growthGroundTypeChange"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".harvestGroundTypeChange"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".windrow"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".cropCare"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".options"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".destruction"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".mapColors"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".mulcher"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".cultivation"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
    local path = key .. ".preparing"
    if removeProperties then
        xmlFile:removeProperty(path)
    end
end
g_fruitTypeManager = FruitTypeManager.new()