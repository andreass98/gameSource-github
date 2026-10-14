source("dataS/scripts/fillTypes/FillTypeDesc.lua")
FillType = nil
FillTypeCategory = nil
FillTypeManager = {}
FillTypeManager.FILLTYPE_START_TOTAL_AMOUNT = 50000
FillTypeManager.SEND_NUM_BITS = 8
FillTypeManager.MASS_SCALE = 1
g_xmlManager:addCreateSchemaFunction(function()
    FillTypeManager.xmlSchema = XMLSchema.new("fillTypes")
end)
g_xmlManager:addInitSchemaFunction(function()
    FillTypeManager.registerXMLPaths(FillTypeManager.xmlSchema, "map")
end)
function FillTypeManager.registerXMLPaths(schema, basePath)
    FillTypeDesc.registerXMLPaths(schema, basePath .. ".fillTypes.fillType(?)")
    local fillTypeCategoryKey = basePath .. ".fillTypeCategories.fillTypeCategory(?)"
    schema:register(XMLValueType.STRING, fillTypeCategoryKey .. "#name", "Name of category")
    schema:register(XMLValueType.STRING_LIST, fillTypeCategoryKey, "list of fillTypes, space separated")
    local fillTypeConverterKey = basePath .. ".fillTypeConverters.fillTypeConverter(?)"
    schema:register(XMLValueType.STRING, fillTypeConverterKey .. "#name", "Converter name")
    schema:register(XMLValueType.STRING, fillTypeConverterKey .. ".converter(?)#from", "From fill type")
    schema:register(XMLValueType.STRING, fillTypeConverterKey .. ".converter(?)#to", "To fill type")
    schema:register(XMLValueType.FLOAT, fillTypeConverterKey .. ".converter(?)#factor", "Multiplied by factor")
    local fillTypeSoundKey = basePath .. ".fillTypeSounds.fillTypeSound(?)"
    SoundManager.registerSampleXMLPaths(schema, fillTypeSoundKey, "sound")
    schema:register(XMLValueType.STRING_LIST, fillTypeSoundKey .. "#fillTypes", "list of fillTypes, space separated")
    schema:register(XMLValueType.BOOL, fillTypeSoundKey .. "#isDefault", "Is default sound", false)
end
function FillTypeManager.registerConfigXMLFilltypes(schema, basePath, fillTypesKey, fillTypeCategoriesKey, fillTypesExcludeKey)
    schema:register(XMLValueType.STRING_LIST, basePath .. (fillTypesKey or "#fillTypes"), "list of fillTypes, space separated")
    schema:register(XMLValueType.STRING_LIST, basePath .. (fillTypeCategoriesKey or "#fillTypeCategories"), "list of fillType category names, space separated")
    schema:register(XMLValueType.STRING_LIST, basePath .. (fillTypesExcludeKey or "#fillTypesExclude"), "list of fillType category names, space separated")
end
local FillTypeManager_mt = Class(FillTypeManager, AbstractManager)
function FillTypeManager.new(customMt)
    -- upvalues: (copy) FillTypeManager_mt
    return AbstractManager.new(customMt or FillTypeManager_mt)
end
function FillTypeManager:initDataStructures()
    self.fillTypes = {}
    self.nameToFillType = {}
    self.indexToFillType = {}
    self.nameToIndex = {}
    self.indexToName = {}
    self.indexToTitle = {}
    self.fillTypeConverters = {}
    self.converterNameToIndex = {}
    self.nameToConverter = {}
    self.categories = {}
    self.nameToCategoryIndex = {}
    self.categoryIndexToFillTypes = {}
    self.categoryNameToFillTypes = {}
    self.fillTypeIndexToCategories = {}
    self.fillTypeSamples = {}
    self.fillTypeToSample = {}
    self.modsToLoad = {}
    FillType = self.nameToIndex
    FillTypeCategory = self.categories
end
function FillTypeManager:loadDefaultTypes()
    local xmlFile = loadXMLFile("fillTypes", "data/maps/maps_fillTypes.xml")
    self:loadFillTypes(xmlFile, nil, true, nil, false)
    delete(xmlFile)
end
function FillTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    FillTypeManager:superClass().loadMapData(self)
    self:loadDefaultTypes()
    if not XMLUtil.loadDataFromMapXML(xmlFile, "fillTypes", baseDirectory, self, self.loadFillTypes, baseDirectory, false, missionInfo.customEnvironment, false) then
        return false
    end
    for _, fillType in ipairs(self.fillTypes) do
        fillType:finalize()
    end
    return true
end
function FillTypeManager:addModWithFillTypes(xmlFilename, baseDirectory, customEnvironment)
    table.insert(self.modsToLoad, { xmlFilename, baseDirectory, customEnvironment })
end
function FillTypeManager:loadModFillTypes()
    if #self.modsToLoad > 0 then
        for _, data in ipairs(self.modsToLoad) do
            local xmlFilename, baseDirectoryMod, customEnvironment = unpack(data)
            local fillTypesXMLFile = XMLFile.load("fillTypes", xmlFilename, FillTypeManager.xmlSchema)
            if fillTypesXMLFile ~= nil then
                g_fillTypeManager:loadFillTypes(fillTypesXMLFile, baseDirectoryMod, false, customEnvironment, false)
                fillTypesXMLFile:delete()
                local numLoadedFillTypes = #self.fillTypes - #self.fillTypes
                if numLoadedFillTypes > 0 then
                    Logging.info("Loaded %d fill types from mod: %s", numLoadedFillTypes, customEnvironment)
                end
            end
        end
        for _, data in ipairs(self.fillTypes) do
            data:finalize()
        end
    end
end
function FillTypeManager:unloadMapData()
    for _, sample in pairs(self.fillTypeSamples) do
        g_soundManager:deleteSample(sample.sample)
    end
    for _, sample in pairs(self.fillTypes) do
        sample:delete()
    end
    FillTypeManager:superClass().unloadMapData(self)
end
function FillTypeManager:loadFillTypes(xmlFile, baseDirectory, isBaseType, customEnv, finalizeType)
    if xmlFile == nil or xmlFile == 0 then
        return false
    end
    if type(xmlFile) ~= "table" then
        xmlFile = XMLFile.wrap(xmlFile, FillTypeManager.xmlSchema)
    end
    local rootName = xmlFile:getRootName()
    if isBaseType then
        local unknownFillType = FillTypeDesc.new()
        unknownFillType.economy.sychronizeData = false
        self:addFillType(unknownFillType)
    end
    for _, ftKey in xmlFile:iterator(rootName .. ".fillTypes.fillType") do
        local name = xmlFile:getValue(ftKey .. "#name")
        if name ~= nil then
            local fillTypeDesc = string.upper(name)
            if isBaseType and self.nameToFillType[fillTypeDesc] ~= nil then
                Logging.warning("FillType \'%s\' already exists. Ignoring fillType!", fillTypeDesc)
            else
                local fillTypeDesc = self.nameToFillType[fillTypeDesc]
                if fillTypeDesc == nil then
                    fillTypeDesc = FillTypeDesc.new()
                end
                if fillTypeDesc:loadFromXMLFile(xmlFile, ftKey, baseDirectory, customEnv) then
                    if self.nameToFillType[fillTypeDesc] == nil then
                        self:addFillType(fillTypeDesc)
                    end
                    if finalizeType == true then
                        fillTypeDesc:finalize()
                    end
                end
            end
        end
    end
    for _, ftKey in xmlFile:iterator(rootName .. ".fillTypeCategories.fillTypeCategory") do
        local name = xmlFile:getValue(ftKey .. "#name")
        local fillTypeDesc = xmlFile:getValue(ftKey)
        local fillTypeCategoryIndex = self:addFillTypeCategory(name, isBaseType)
        if fillTypeDesc ~= nil and fillTypeCategoryIndex ~= nil then
            for _, fillTypeName in ipairs(fillTypeDesc) do
                local fillType = self:getFillTypeByName(fillTypeName)
                if fillType == nil then
                    Logging.warning("Unknown FillType \'" .. tostring(fillTypeName) .. "\' in fillTypeCategory \'" .. tostring(name) .. "\'!")
                elseif not self:addFillTypeToCategory(fillType.index, fillTypeCategoryIndex) then
                    Logging.warning("Could not add fillType \'" .. tostring(fillTypeName) .. "\' to fillTypeCategory \'" .. tostring(name) .. "\'!")
                end
            end
        end
    end
    for _, ftKey in xmlFile:iterator(rootName .. ".fillTypeConverters.fillTypeConverter") do
        local fillTypeDesc = self:addFillTypeConverter(xmlFile:getValue(ftKey .. "#name"), isBaseType)
        if fillTypeDesc ~= nil then
            for _, _ in xmlFile:iterator(ftKey .. ".converter") do
                local fillTypeName = xmlFile:getValue(_ .. "#from")
                local fillType = xmlFile:getValue(_ .. "#to")
                local factor = xmlFile:getValue(_ .. "#factor")
                local sourceFillType = g_fillTypeManager:getFillTypeByName(fillTypeName)
                local targetFillType = g_fillTypeManager:getFillTypeByName(fillType)
                if sourceFillType ~= nil and (targetFillType ~= nil and factor ~= nil) then
                    self:addFillTypeConversion(fillTypeDesc, sourceFillType.index, targetFillType.index, factor)
                end
            end
        end
    end
    for _, ftKey in xmlFile:iterator(rootName .. ".fillTypeSounds.fillTypeSound") do
        local name = g_soundManager:loadSampleFromXML(xmlFile, ftKey, "sound", baseDirectory, getRootNode(), 0, AudioGroup.VEHICLE, nil, nil)
        if name ~= nil then
            local fillTypeDesc = {
                ["sample"] = name,
                ["fillTypes"] = {}
            }
            local fillTypeCategoryIndex = xmlFile:getValue(ftKey .. "#fillTypes")
            if fillTypeCategoryIndex ~= nil then
                for _, fillTypeName in ipairs(fillTypeCategoryIndex) do
                    local fillType = self:getFillTypeIndexByName(fillTypeName)
                    if fillType == nil then
                        Logging.xmlWarning(xmlFile, "Unable to load fill type \'%s\' for fillTypeSound \'%s\'", fillTypeName, ftKey)
                    else
                        table.insert(fillTypeDesc.fillTypes, fillType)
                        self.fillTypeToSample[fillType] = name
                    end
                end
            end
            if xmlFile:getValue(ftKey .. "#isDefault") then
                for _, fillTypeName in ipairs(self.fillTypes) do
                    if self.fillTypeToSample[_] == nil then
                        self.fillTypeToSample[_] = name
                    end
                end
            end
            table.insert(self.fillTypeSamples, fillTypeDesc)
        end
    end
    return true
end
function FillTypeManager:addFillType(fillTypeDesc)
    local maxNumFillTypes = 2 ^ FillTypeManager.SEND_NUM_BITS - 1
    if maxNumFillTypes <= #self.fillTypes then
        Logging.error("FillTypeManager.addFillType too many fill types. Only %d fill types are supported. Ignoring \'%s\'.", maxNumFillTypes, fillTypeDesc.name)
        return false
    end
    fillTypeDesc.index = #self.fillTypes + 1
    self.nameToFillType[fillTypeDesc.name] = fillTypeDesc
    self.nameToIndex[fillTypeDesc.name] = fillTypeDesc.index
    self.indexToName[fillTypeDesc.index] = fillTypeDesc.name
    self.indexToTitle[fillTypeDesc.index] = fillTypeDesc.title
    self.indexToFillType[fillTypeDesc.index] = fillTypeDesc
    table.insert(self.fillTypes, fillTypeDesc)
    return true
end
function FillTypeManager.assignFillTypeTextureArraysFromTerrain(_, nodeId, terrainRootNodeId, diffuse, normal, height)
    local material = getMaterial(nodeId, 0)
    local material = setTerrainFillPlanesToMaterial(terrainRootNodeId, material, diffuse, normal, height)
    if material ~= nil then
        setMaterial(nodeId, material, 0)
    end
end
function FillTypeManager.assignCustomFillTypeTextureArraysFromTerrain(_, nodeId, terrainRootNodeId, diffuse, normal, height)
    local material = getMaterial(nodeId, 0)
    local material = setTerrainFillPlanesToMaterialCustom(terrainRootNodeId, material, diffuse, normal, height)
    if material ~= nil then
        setMaterial(nodeId, material, 0)
    end
end
function FillTypeManager:constructTerrainFillLayers(heightTypes, terrainRootNodeId)
    clearTerrainFillLayers(terrainRootNodeId)
    local curIndex = 1
    local i = 1
    for i = i, #heightTypes do
        local heightType = heightTypes[i]
        local fillType = self.fillTypes[heightType.fillTypeIndex]
        if fillType ~= nil and fillType:addTerrainFillLayer(terrainRootNodeId, curIndex) then
            if heightType.visualHeightMapping ~= nil then
                local i = 1
                for i = i, #heightType.visualHeightMapping do
                    local nextMapping = heightType.visualHeightMapping[i + 1]
                    if nextMapping == nil then
                        setTerrainFillVisualHeight(g_currentMission.terrainDetailHeightId, fillType.textureArrayIndex, heightType.visualHeightMapping[i].realValue, heightType.visualHeightMapping[i].visualValue, nil, nil)
                    else
                        setTerrainFillVisualHeight(g_currentMission.terrainDetailHeightId, fillType.textureArrayIndex, mapping.realValue, mapping.visualValue, nextMapping.realValue, nextMapping.visualValue)
                    end
                end
            end
        end
    end
    finalizeTerrainFillLayers(terrainRootNodeId)
    return true
end
function FillTypeManager:constructFillTypeDistanceTextureArray(terrainDetailHeightId, typeFirstChannel, typeNumChannels, heightTypes)
    local distanceConstr = TerrainDetailDistanceConstructor.new(typeFirstChannel, typeNumChannels)
    local i = 1
    for i = i, #heightTypes do
        local fillType = self.fillTypes[heightTypes[i].fillTypeIndex]
        if fillType ~= nil then
            fillType:addDistanceTexture(distanceConstr, i - 1)
        end
    end
    return distanceConstr:finalize(terrainDetailHeightId)
end
function FillTypeManager:getTextureArrayIndexByFillTypeIndex(index)
    local fillType = self.fillTypes[index]
    if fillType then
    end
    return fillType
end
function FillTypeManager:getPrioritizedEffectTypeByFillTypeIndex(index)
    local fillType = self.fillTypes[index]
    if fillType then
    end
    return fillType
end
function FillTypeManager:getSmokeColorByFillTypeIndex(index, fruitColor)
    local fillType = self.fillTypes[index]
    if fillType == nil then
        return nil
    elseif fruitColor then
        return fillType.fruitSmokeColor or fillType.fillSmokeColor
    else
        return fillType.fillSmokeColor
    end
end
function FillTypeManager:getFillTypeByIndex(index)
    return self.fillTypes[index]
end
function FillTypeManager:getFillTypeNameByIndex(index)
    return self.indexToName[index]
end
function FillTypeManager:getFillTypeTitleByIndex(index)
    return self.indexToTitle[index]
end
function FillTypeManager:getFillTypeNamesByIndices(indices)
    local names = {}
    for fillTypeIndex in pairs(indices) do
        table.insert(names, self.indexToName[fillTypeIndex])
    end
    return names
end
function FillTypeManager:getFillTypeIndexByName(name)
    if name then
        name = string.upper(name)
    end
    return self.nameToIndex[name]
end
function FillTypeManager:getFillTypeByName(name)
    if ClassUtil.getIsValidIndexName(name) then
        return self.nameToFillType[string.upper(name)]
    else
        return nil
    end
end
function FillTypeManager:getFillTypes()
    return self.fillTypes
end
function FillTypeManager:addFillTypeCategory(name, isBaseType)
    if not ClassUtil.getIsValidIndexName(name) then
        printWarning("Warning: \'" .. tostring(name) .. "\' is not a valid name for a fillTypeCategory. Ignoring fillTypeCategory!")
        return nil
    end
    local index = string.upper(name)
    if isBaseType and self.nameToCategoryIndex[index] ~= nil then
        printWarning("Warning: FillTypeCategory \'" .. tostring(index) .. "\' already exists. Ignoring fillTypeCategory!")
        return nil
    end
    local index = self.nameToCategoryIndex[index]
    if index == nil then
        local categoryFillTypes = {}
        index = #self.categories + 1
        table.insert(self.categories, index)
        self.categoryNameToFillTypes[index] = categoryFillTypes
        self.categoryIndexToFillTypes[index] = categoryFillTypes
        self.nameToCategoryIndex[index] = index
    end
    return index
end
function FillTypeManager:addFillTypeToCategory(fillTypeIndex, categoryIndex)
    if categoryIndex == nil or (fillTypeIndex == nil or self.categoryIndexToFillTypes[categoryIndex] == nil) then
        return false
    end
    self.categoryIndexToFillTypes[categoryIndex][fillTypeIndex] = true
    if self.fillTypeIndexToCategories[fillTypeIndex] == nil then
        self.fillTypeIndexToCategories[fillTypeIndex] = {}
    end
    self.fillTypeIndexToCategories[fillTypeIndex][categoryIndex] = true
    return true
end
function FillTypeManager:getFillTypesByCategoryNames(names, warning, fillTypes)
    fillTypes = fillTypes or {}
    if names == nil then
        return fillTypes
    else
        return self:getFillTypesByCategoryNamesList(string.split(names, " "), warning, fillTypes)
    end
end
function FillTypeManager:getFillTypesByCategoryNamesList(categoryNamesList, warning, fillTypes)
    fillTypes = fillTypes or {}
    if categoryNamesList ~= nil then
        for _, categoryName in pairs(categoryNamesList) do
            local categoryFillTypes = string.upper(categoryName)
            local categoryFillTypes = self.categoryNameToFillTypes[categoryFillTypes]
            if categoryFillTypes == nil then
                if warning ~= nil then
                    printWarning(string.format(warning, categoryFillTypes))
                end
            else
                for fillType, _ in pairs(categoryFillTypes) do
                    if not table.hasElement(fillTypes, fillType) then
                        table.insert(fillTypes, fillType)
                    end
                end
            end
        end
    end
    return fillTypes
end
function FillTypeManager:getFillTypeNamesByCategoryNamesList(categoryNamesList, warning)
    local fillTypeNames = {}
    if categoryNamesList ~= nil then
        for _, categoryName in pairs(categoryNamesList) do
            local categoryFillTypeIndices = string.upper(categoryName)
            local categoryFillTypeIndices = self.categoryNameToFillTypes[categoryFillTypeIndices]
            if categoryFillTypeIndices == nil then
                if warning ~= nil then
                    printWarning(string.format(warning, categoryFillTypeIndices))
                end
            else
                for fillTypeIndex, _ in pairs(categoryFillTypeIndices) do
                    local fillType = self.indexToFillType[fillTypeIndex]
                    if not table.hasElement(fillTypeNames, fillType.name) then
                        table.insert(fillTypeNames, fillType.name)
                    end
                end
            end
        end
    end
    return fillTypeNames
end
function FillTypeManager:getIsFillTypeInCategory(fillTypeIndex, categoryName)
    local catgegoy = self.nameToCategoryIndex[categoryName]
    if catgegoy == nil or not self.fillTypeIndexToCategories[fillTypeIndex] then
        return false
    end
    return self.fillTypeIndexToCategories[fillTypeIndex][catgegoy] ~= nil
end
function FillTypeManager:getFillTypesByNames(names, warning, fillTypes)
    local fillTypeNames = fillTypes or {}
    if names ~= nil then
        local fillTypeNames = string.split(names, " ")
        for _, name in pairs(fillTypeNames) do
            local fillTypeIndex = string.upper(name)
            local fillTypeIndex = self.nameToIndex[fillTypeIndex]
            if fillTypeIndex == nil then
                if warning ~= nil then
                    printWarning(string.format(warning, fillTypeIndex))
                end
            elseif fillTypeIndex ~= FillType.UNKNOWN and not table.hasElement(fillTypeNames, fillTypeIndex) then
                table.insert(fillTypeNames, fillTypeIndex)
            end
        end
    end
    return fillTypeNames
end
function FillTypeManager.getFillTypesFromXML(_, xmlFile, categoryKey, namesKey, requiresFillTypes)
    local fillTypeCategories = xmlFile:getValue(categoryKey)
    local fillTypeNames = xmlFile:getValue(namesKey)
    if fillTypeCategories == nil or fillTypeNames ~= nil then
        if fillTypeCategories == nil and fillTypeNames ~= nil then
            return g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: \'" .. xmlFile:getFilename() .. "\' has invalid fillType \'%s\'.")
        elseif fillTypeCategories == nil or fillTypeNames == nil then
            if requiresFillTypes ~= nil and requiresFillTypes then
                Logging.xmlWarning(xmlFile, "either the \'%s\' or \'%s\' attribute has to be set", categoryKey, namesKey)
            end
            return {}
        else
            Logging.xmlWarning(xmlFile, "fillTypeCategories and fillTypeNames are both set, only one of the two allowed")
            return fillTypes
        end
    else
        return g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: \'" .. xmlFile:getFilename() .. "\' has invalid fillTypeCategory \'%s\'.")
    end
end
function FillTypeManager:loadCombinedFillTypesFromConfig(xmlFile, key, fillTypesKey, fillTypeCategoriesKey, fillTypesExcludeKey)
    local fillTypeNames = xmlFile:getValue(key .. (fillTypesKey or "#fillTypes")) or {}
    local fillTypeCategories = xmlFile:getValue(key .. (fillTypeCategoriesKey or "#fillTypeCategories"))
    local fillTypeNamesExclude = xmlFile:getValue(key .. (fillTypesExcludeKey or "#fillTypesExclude"))
    if fillTypeCategories ~= nil then
        local fillTypeNamesFromCategories = self:getFillTypeNamesByCategoryNamesList(fillTypeCategories)
        fillTypeNames = table.getListUnion(fillTypeNames, fillTypeNamesFromCategories)
    end
    if #fillTypeNames == 0 then
        return nil
    end
    local fillTypeNamesFromCategories = table.toSet(fillTypeNames)
    if fillTypeNamesExclude ~= nil then
        fillTypeNamesFromCategories = table.getSetSubtraction(fillTypeNamesFromCategories, table.toSet(fillTypeNamesExclude))
    end
    if table.size(fillTypeNamesFromCategories) == 0 then
        return nil
    end
    local fillTypes = {}
    for fillTypeName in pairs(fillTypeNamesFromCategories) do
        table.insert(fillTypes, g_fillTypeManager:getFillTypeIndexByName(fillTypeName, "Warning: invalid fillType %q at \'" .. key .. "\'"))
    end
    return fillTypes
end
function FillTypeManager:addFillTypeConverter(name, isBaseType)
    if not ClassUtil.getIsValidIndexName(name) then
        printWarning("Warning: \'" .. tostring(name) .. "\' is not a valid name for a fillTypeConverter. Ignoring fillTypeConverter!")
        return nil
    end
    local index = string.upper(name)
    if isBaseType and self.nameToConverter[index] ~= nil then
        printWarning("Warning: FillTypeConverter \'" .. tostring(index) .. "\' already exists. Ignoring FillTypeConverter!")
        return nil
    end
    local index = self.converterNameToIndex[index]
    if index == nil then
        local converter = {}
        table.insert(self.fillTypeConverters, converter)
        self.converterNameToIndex[index] = #self.fillTypeConverters
        self.nameToConverter[index] = converter
        index = #self.fillTypeConverters
    end
    return index
end
function FillTypeManager:addFillTypeConversion(converter, sourceFillTypeIndex, targetFillTypeIndex, conversionFactor)
    if converter ~= nil and (self.fillTypeConverters[converter] ~= nil and (sourceFillTypeIndex ~= nil and targetFillTypeIndex ~= nil)) then
        self.fillTypeConverters[converter][sourceFillTypeIndex] = {
            ["targetFillTypeIndex"] = targetFillTypeIndex,
            ["conversionFactor"] = conversionFactor
        }
    end
end
function FillTypeManager:getConverterDataByName(converterName)
    if converterName then
        converterName = string.upper(converterName)
    end
    return self.nameToConverter[converterName]
end
function FillTypeManager:getSampleByFillType(fillType)
    return self.fillTypeToSample[fillType]
end
g_fillTypeManager = FillTypeManager.new()