StoreManager = {}
local StoreManager_mt = Class(StoreManager, AbstractManager)
StoreManager.CATEGORY_TYPE = {
    ["NONE"] = "",
    ["VEHICLE"] = "VEHICLE",
    ["TOOL"] = "TOOL",
    ["OBJECT"] = "OBJECT",
    ["PLACEABLE"] = "PLACEABLE"
}
function StoreManager.new(customMt)
    -- upvalues: (copy) StoreManager_mt
    local self = AbstractManager.new(customMt or StoreManager_mt)
    self.speciesToSchema = {}
    self.indexedSearch = IndexedSearch.new({
        ["title"] = 10,
        ["brand"] = 5,
        ["author"] = 3,
        ["dlcTitle"] = 3
    })
    return self
end
function StoreManager:initDataStructures()
    self.numOfCategories = 0
    self.numOfPacks = 0
    self.categories = {}
    self.categoryByName = {}
    self.categoryTypes = {}
    self.categoryTypesByName = {}
    self.packs = {}
    self.items = {}
    self.xmlFilenameToItem = {}
    self.modStoreItems = {}
    self.modStorePacks = {}
    self.modConstructionTabs = {}
    self.modCategoryTypes = {}
    self.specTypes = {}
    self.nameToSpecType = {}
    self.vramUsageFunctions = {}
    self.constructionCategoriesByName = {}
    self.constructionCategories = {}
    if self.indexedSearch ~= nil then
        self.indexedSearch:clear()
    end
end
function StoreManager:addSpeciesXMLSchema(species, xmlSchema)
    self.speciesToSchema[species] = xmlSchema
end
function StoreManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    StoreManager:superClass().loadMapData(self)
    local categoryXMLFile = XMLFile.load("storeCategoriesXML", "dataS/storeCategories.xml")
    for _, key in categoryXMLFile:iterator("categories.types.type") do
        self:loadCategoryType(categoryXMLFile, key, nil)
    end
    for _, key in categoryXMLFile:iterator("categories.category") do
        self:loadCategoryFromXML(categoryXMLFile, key, "", false)
    end
    categoryXMLFile:delete()
    for _, key in ipairs(self.modCategoryTypes) do
        self:addCategory(key.name, key.title, key.imageFilename, key.categoryType, key.baseDir, key.insertAfter)
    end
    local packsXMLFile = XMLFile.load("storePacksXML", "dataS/storePacks.xml")
    for key, key in packsXMLFile:iterator("storePacks.storePack") do
        local name = packsXMLFile:getString(key .. "#name")
        local title = packsXMLFile:getString(key .. "#title")
        local imageFilename = packsXMLFile:getString(key .. "#image")
        if title ~= nil and title:sub(1, 6) == "$l10n_" then
            title = g_i18n:getText(title:sub(7))
        end
        local requiredDLC = packsXMLFile:getString(key .. "#requiredDLC")
        if requiredDLC == nil or g_modIsLoaded[g_uniqueDlcNamePrefix .. requiredDLC] ~= nil then
            self:addPack(name, title, imageFilename, "")
            packsXMLFile:iterate(key .. ".storeItem", function(_, storeItemKey)
                -- upvalues: (copy) packsXMLFile, (copy) self, (copy) name, (copy) baseDirectory
                local xmlFilename = packsXMLFile:getString(storeItemKey)
                self:addPackItem(name, Utils.getFilename(xmlFilename, baseDirectory))
            end)
        else
            Logging.devInfo("Ignore storepack \'%s\' because DLC \'%s\' is not loaded", title, requiredDLC)
        end
    end
    packsXMLFile:delete()
    for key, key in ipairs(self.modStorePacks) do
        self:addPack(key.name, key.title, key.imageFilename, key.baseDir)
        for requiredDLC, storeItem in ipairs(key.storeItems) do
            self:addPackItem(key.name, storeItem)
        end
    end
    if Platform.hasContruction then
        local constructionXMLFile = XMLFile.load("constructionXML", "dataS/constructionCategories.xml")
        if constructionXMLFile ~= nil then
            local defaultIconFilename = constructionXMLFile:getString("constructionCategories#defaultIconFilename")
            local _ = constructionXMLFile:getVector("constructionCategories#refSize", nil, 2) or { 1024, 1024 }
            for title, imageFilename in constructionXMLFile:iterator("constructionCategories.category") do
                local requiredDLC = constructionXMLFile:getString(imageFilename .. "#name")
                local storeItem = g_i18n:convertText(constructionXMLFile:getString(imageFilename .. "#title"))
                local iconFilename = constructionXMLFile:getString(imageFilename .. "#iconFilename") or defaultIconFilename
                local refSize = constructionXMLFile:getVector(imageFilename .. "#refSize", _, 2)
                self:addConstructionCategory(requiredDLC, storeItem, iconFilename, GuiUtils.getUVs(constructionXMLFile:getString(imageFilename .. "#iconUVs", "0 0 1 1"), refSize), "", (constructionXMLFile:getString(imageFilename .. "#iconSliceId")))
                for _, tKey in constructionXMLFile:iterator(imageFilename .. ".tab") do
                    local tabName = constructionXMLFile:getString(tKey .. "#name")
                    local tabTitle = g_i18n:convertText(constructionXMLFile:getString(tKey .. "#title"))
                    local tabIconFilename = constructionXMLFile:getString(tKey .. "#iconFilename") or defaultIconFilename
                    local tabRefSize = constructionXMLFile:getVector(tKey .. "#refSize", _, 2)
                    self:addConstructionTab(requiredDLC, tabName, tabTitle, tabIconFilename, GuiUtils.getUVs(constructionXMLFile:getString(tKey .. "#iconUVs", "0 0 1 1"), tabRefSize), "", (constructionXMLFile:getString(tKey .. "#iconSliceId")))
                end
            end
            constructionXMLFile:delete()
        end
        for key, name in ipairs(self.modConstructionTabs) do
            self:addConstructionTab(name.categoryName, name.tabName, name.tabTitle, name.tabIconFilename, name.tabIconUVs, "", name.tabIconSliceId)
        end
    end
    self:loadItemsFromXML(self:getDefaultStoreItemsFilename(), "", nil)
    if xmlFile ~= nil then
        local defaultIconFilename = getXMLString(xmlFile, "map.storeItems#filename")
        if defaultIconFilename ~= nil then
            self:loadItemsFromXML(Utils.getFilename(defaultIconFilename, baseDirectory), baseDirectory, missionInfo.customEnvironment)
        end
    end
    for key, name in ipairs(self.modStoreItems) do
        local name
        g_asyncTaskManager:addSubtask(function()
            -- upvalues: (copy) self, (copy) name
            self:loadItem(name.xmlFilename, name.baseDir, name.customEnvironment, name.isMod, name.isBundleItem, name.dlcTitle, name.extraContentId)
        end)
    end
    g_asyncTaskManager:addSubtask(function()
        -- upvalues: (copy) self
        self.indexedSearch:build()
    end)
    addConsoleCommand("gsStoreItemsReload", "Reloads storeItem data", "consoleCommandReloadStoreItems", self)
    return true
end
function StoreManager:unloadMapData()
    StoreManager:superClass().unloadMapData(self)
    removeConsoleCommand("gsStoreItemsReload")
end
function StoreManager:getDefaultStoreItemsFilename()
    return "dataS/storeItems.xml"
end
function StoreManager:loadItemsFromXML(filename, baseDirectory, customEnvironment)
    local xmlFile = XMLFile.load("storeItemsXML", filename)
    if xmlFile ~= nil then
        xmlFile:iterate("storeItems.storeItem", function(_, key)
            -- upvalues: (copy) xmlFile, (copy) baseDirectory, (copy) self, (copy) customEnvironment
            local xmlFilename = xmlFile:getString(key .. "#xmlFilename")
            local extraContentId = xmlFile:getString(key .. "#extraContentId")
            g_asyncTaskManager:addSubtask(function()
                -- upvalues: (copy) xmlFilename, (ref) baseDirectory, (ref) self, (ref) customEnvironment, (copy) extraContentId
                local isMod = false
                local dlcTitle = ""
                local absFilename = Utils.getFilename(xmlFilename, baseDirectory)
                local modName, _ = Utils.getModNameAndBaseDirectory(absFilename)
                if modName ~= nil then
                    local modItem = g_modManager:getModByName(modName)
                    if modItem ~= nil then
                        dlcTitle = modItem.title
                    end
                    isMod = not modItem.isDLC
                end
                self:loadItem(xmlFilename, baseDirectory, customEnvironment, isMod, false, dlcTitle, extraContentId)
            end, string.format("StoreManager-loadItemsFromXML \'%s\'", xmlFilename))
        end)
        xmlFile:delete()
    end
end
function StoreManager:loadCategoryType(xmlFile, key, customEnv)
    local name = xmlFile:getString(key .. "#name")
    local title = xmlFile:getString(key .. "#title")
    local insertAfter = xmlFile:getString(key .. "#insertAfter")
    if title ~= nil then
        title = g_i18n:convertText(title, customEnv)
    end
    self:addCategoryType(name, title, insertAfter)
end
function StoreManager:addCategoryType(name, title, insertAfter)
    if string.isNilOrWhitespace(name) then
        Logging.warning("Could not register store category type. Name is missing or empty!")
        return false
    end
    if not ClassUtil.getIsValidIndexName(name) then
        Logging.warning("Could not register store category type \'%s\'. Invalid name for a category type!", name)
        return false
    end
    if string.isNilOrWhitespace(title) then
        Logging.warning("Could not register store category type \'%s\'. Title is missing or empty!", name)
        return false
    end
    local nameUpper = string.upper(name)
    if self.categoryTypesByName[nameUpper] ~= nil then
        Logging.warning("Could not register store category type \'%s\'. Already exists!", name)
        return false
    end
    local categoryType = {
        ["name"] = nameUpper,
        ["title"] = title
    }
    local needsInsert = true
    if insertAfter ~= nil then
        local insertAfterUpper = string.upper(insertAfter)
        for k, existingType in ipairs(self.categoryTypes) do
            if existingType.name == insertAfterUpper then
                table.insert(self.categoryTypes, k + 1, categoryType)
                needsInsert = false
                break
            end
        end
    end
    if needsInsert then
        table.insert(self.categoryTypes, categoryType)
    end
    self.categoryTypesByName[nameUpper] = categoryType
    return true
end
function StoreManager:getCategoryTypes()
    return self.categoryTypes
end
function StoreManager:loadCategoryFromXML(xmlFile, key, baseDir, customEnv, isMod)
    local name = xmlFile:getString(key .. "#name")
    local title = xmlFile:getString(key .. "#title")
    local imageFilename = xmlFile:getString(key .. "#image")
    local categoryType = xmlFile:getString(key .. "#type")
    local insertAfter = xmlFile:getString(key .. "#insertAfter")
    if title ~= nil then
        title = g_i18n:convertText(title, customEnv)
    end
    if isMod then
        table.insert(self.modCategoryTypes, {
            ["name"] = name,
            ["title"] = title,
            ["imageFilename"] = imageFilename,
            ["categoryType"] = categoryType,
            ["baseDir"] = baseDir,
            ["insertAfter"] = insertAfter
        })
    else
        self:addCategory(name, title, imageFilename, categoryType, baseDir, insertAfter)
    end
end
function StoreManager:addCategory(name, title, imageFilename, categoryTypeName, baseDir, insertAfter)
    if string.isNilOrWhitespace(name) then
        Logging.warning("Could not register store category. Name is missing or empty!")
        return false
    end
    if not ClassUtil.getIsValidIndexName(name) then
        Logging.warning("Could not register store category \'%s\'. Invalid name for a category!", name)
        return false
    end
    if string.isNilOrWhitespace(title) then
        Logging.warning("Could not register store category \'%s\'. Title is missing or empty!", name)
        return false
    end
    if string.isNilOrWhitespace(imageFilename) then
        Logging.warning("Could not register store category \'%s\'. Image is missing or empty!", name)
        return false
    end
    if baseDir == nil then
        Logging.warning("Could not register store category \'%s\'. Basedirectory not defined!", name)
        return false
    end
    if string.isNilOrWhitespace(categoryTypeName) then
        Logging.warning("Could not register store category \'%s\'. CategoryType is missing or empty!", name)
        return false
    end
    local categoryTypeNameUpper = string.upper(categoryTypeName)
    if self.categoryTypesByName[categoryTypeNameUpper] == nil then
        Logging.warning("Could not register store category \'%s\'. CategoryType \'%s\' is not defined!", name, categoryTypeName)
        return false
    end
    local nameUpper = string.upper(name)
    if GS_PLATFORM_SWITCH and name == "COINS" then
        return false
    end
    if self.categoryByName[nameUpper] ~= nil then
        Logging.warning("Could not register store category \'%s\'. Already exists!", name)
        return false
    end
    local category = {
        ["name"] = nameUpper,
        ["title"] = title,
        ["image"] = Utils.getFilename(imageFilename, baseDir),
        ["type"] = categoryTypeNameUpper,
        ["orderId"] = #self.categories
    }
    local needsInsert = true
    if insertAfter ~= nil then
        local insertAfterUpper = string.upper(insertAfter)
        for k, existingCategory in ipairs(self.categories) do
            if existingCategory.name == insertAfterUpper then
                table.insert(self.categories, k + 1, category)
                needsInsert = false
                for index, _category in ipairs(self.categories) do
                    _category.orderId = index
                end
                break
            end
        end
    end
    if needsInsert then
        table.insert(self.categories, category)
    end
    self.categoryByName[nameUpper] = category
    return true
end
function StoreManager:getCategoryByName(name)
    if name == nil then
        return nil
    else
        return self.categoryByName[string.upper(name)]
    end
end
function StoreManager:addConstructionCategory(name, title, iconFilename, iconUVs, baseDir, iconSliceId)
    local category = string.upper(name)
    if self.constructionCategoriesByName[category] == nil then
        local category = {
            ["name"] = category,
            ["title"] = title,
            ["iconFilename"] = Utils.getFilename(iconFilename, baseDir),
            ["iconUVs"] = iconUVs,
            ["iconSliceId"] = iconSliceId,
            ["tabs"] = {},
            ["index"] = #self.constructionCategories + 1
        }
        table.insert(self.constructionCategories, category)
        self.constructionCategoriesByName[category] = category
    else
        Logging.warning("Construction category \'%s\' already exists.", category)
    end
end
function StoreManager:getConstructionCategoryByName(name)
    if name == nil then
        return nil
    else
        return self.constructionCategoriesByName[string.upper(name)]
    end
end
function StoreManager:addConstructionTab(categoryName, name, title, iconFilename, iconUVs, baseDir, iconSliceId)
    local category = self:getConstructionCategoryByName(categoryName)
    if category ~= nil then
        table.insert(category.tabs, {
            ["name"] = string.upper(name),
            ["title"] = title,
            ["iconFilename"] = Utils.getFilename(iconFilename, baseDir),
            ["iconUVs"] = iconUVs,
            ["iconSliceId"] = iconSliceId,
            ["index"] = #category.tabs + 1
        })
    end
end
function StoreManager:getConstructionTabByName(name, categoryName)
    local category = self:getConstructionCategoryByName(categoryName)
    if category == nil or name == nil then
        return nil
    end
    name = string.upper(name)
    for i, tab in ipairs(category.tabs) do
        if tab.name == name then
            return tab
        end
    end
    return nil
end
function StoreManager:getConstructionCategories()
    return self.constructionCategories
end
function StoreManager:addVRamUsageFunction(func)
    table.insert(self.vramUsageFunctions, func)
end
function StoreManager:addSpecType(name, profile, loadFunc, getValueFunc, species, relatedConfigurations, configDataFunc)
    if ClassUtil.getIsValidIndexName(name) then
        if self.nameToSpecType == nil then
            printCallstack()
        end
        if self.nameToSpecType[name] == nil then
            local specType = {
                ["name"] = name,
                ["profile"] = profile,
                ["loadFunc"] = loadFunc,
                ["getValueFunc"] = getValueFunc,
                ["species"] = species or StoreSpecies.VEHICLE,
                ["relatedConfigurations"] = relatedConfigurations,
                ["configDataFunc"] = configDataFunc
            }
            self.nameToSpecType[name] = specType
            table.insert(self.specTypes, specType)
        else
            printError("Error: spec type name \'" .. name .. "\' is already in use!")
        end
    else
        printWarning("Warning: \'" .. tostring(name) .. "\' is no valid name for a spec type!")
        return
    end
end
function StoreManager:getSpecTypes()
    return self.specTypes
end
function StoreManager:getSpecTypeByName(name)
    if ClassUtil.getIsValidIndexName(name) then
        return self.nameToSpecType[name]
    end
    printWarning("Warning: \'" .. tostring(name) .. "\' is no valid name for a spec type!")
end
function StoreManager:getSpecTypeByProfile(profile)
    local i = 1
    for i = i, #self.specTypes do
        if self.specTypes[i].profile == profile then
            return self.specTypes[i]
        end
    end
    return nil
end
function StoreManager:addItem(storeItem)
    local otherItem = self.xmlFilenameToItem[storeItem.xmlFilenameLower]
    if otherItem ~= nil then
        if otherItem.isBundleItem and not storeItem.isBundleItem then
            otherItem.isBundleItem = storeItem.isBundleItem
            otherItem.showInStore = storeItem.showInStore
        end
        return false
    end
    local author = self.items
    table.insert(author, storeItem)
    storeItem.id = #self.items
    self.xmlFilenameToItem[storeItem.xmlFilenameLower] = storeItem
    local isUnlocked = true
    if storeItem.extraContentId ~= nil then
        isUnlocked = true
        if g_extraContentSystem ~= nil then
            isUnlocked = g_extraContentSystem:getIsItemIdUnlocked(storeItem.extraContentId)
        end
    end
    if not storeItem.isBundleItem and (isUnlocked and (storeItem.showInStore and (storeItem.species == StoreSpecies.VEHICLE or storeItem.species == StoreSpecies.HANDTOOL))) then
        local author = ""
        if storeItem.isMod then
            local mod = g_modManager.nameToMod[storeItem.customEnvironment]
            if mod ~= nil and mod.author ~= nil then
                author = mod.author
            end
        end
        local mod = g_brandManager:getBrandByIndex(storeItem.brandIndex)
        local brandName = storeItem.brandNameRaw or ""
        if mod ~= nil and mod.name ~= "NONE" then
            brandName = mod.title
        end
        self.indexedSearch:addDocument({
            ["title"] = storeItem.name,
            ["brand"] = brandName,
            ["author"] = author,
            ["dlcTitle"] = storeItem.dlcTitle
        }, storeItem)
    end
    return true
end
function StoreManager:removeItemByIndex(index)
    local item = self.items[index]
    if item ~= nil then
        self.xmlFilenameToItem[item.xmlFilenameLower] = nil
        local numItems = #self.items
        if index < numItems then
            self.items[index] = self.items[numItems]
            self.items[index].id = index
        end
        table.remove(self.items, numItems)
    end
end
function StoreManager:getItems()
    return self.items
end
function StoreManager:getItemByIndex(index)
    if index == nil then
        return nil
    else
        return self.items[index]
    end
end
function StoreManager:getItemByXMLFilename(xmlFilename)
    if xmlFilename == nil then
        return nil
    else
        return self.xmlFilenameToItem[string.lower(xmlFilename)]
    end
end
function StoreManager.getIsItemUnlocked(_, storeItem)
    return storeItem ~= nil and (storeItem.extraContentId == nil or g_extraContentSystem:getIsItemIdUnlocked(storeItem.extraContentId)) and true or false
end
function StoreManager:getItemsByCombinationData(combinationData)
    local items = {}
    if combinationData.xmlFilename == nil then
        for _, storeItem in ipairs(self.items) do
            if self:getIsItemUnlocked(storeItem) then
                local categoryAllowed = true
                if combinationData.filterCategories ~= nil then
                    categoryAllowed = false
                    if storeItem.categoryNames ~= nil then
                        for _, filterCategoryName in ipairs(combinationData.filterCategories) do
                            for _, storeItemCategoryName in ipairs(storeItem.categoryNames) do
                                if string.upper(filterCategoryName) == storeItemCategoryName then
                                    categoryAllowed = true
                                    break
                                end
                            end
                        end
                    end
                end
                if categoryAllowed then
                    if combinationData.filterSpec == nil then
                        table.insert(items, {
                            ["storeItem"] = storeItem
                        })
                    else
                        local desc = self:getSpecTypeByName(combinationData.filterSpec)
                        if desc ~= nil and desc.species == storeItem.species then
                            StoreItemUtil.loadSpecsFromXML(storeItem)
                            local value, _maxValue = desc.getValueFunc(storeItem, nil, nil, nil, true, true)
                            if value ~= nil then
                                local _ = combinationData.filterSpecMin
                                local filterCategoryName = combinationData.filterSpecMax
                                if combinationData.filterSpec == "weight" then
                                end
                                if _ <= value and value <= filterCategoryName then
                                    table.insert(items, {
                                        ["storeItem"] = storeItem
                                    })
                                elseif desc.configDataFunc == nil then
                                    if desc.relatedConfigurations ~= nil and storeItem.configurations ~= nil then
                                        for _, storeItemCategoryName in ipairs(desc.relatedConfigurations) do
                                            if storeItem.configurations[storeItemCategoryName] ~= nil then
                                                local configIndex = 1
                                                for configIndex = configIndex, #storeItem.configurations[storeItemCategoryName] do
                                                    local configData = {
                                                        [storeItemCategoryName] = configIndex
                                                    }
                                                    local value = desc.getValueFunc(storeItem, nil, configData, nil, true, true)
                                                    if _ <= value and value <= filterCategoryName then
                                                        table.insert(items, {
                                                            ["storeItem"] = storeItem,
                                                            ["configData"] = configData
                                                        })
                                                    end
                                                end
                                            end
                                        end
                                    end
                                else
                                    local configDatas = desc.configDataFunc(storeItem)
                                    if configDatas ~= nil then
                                        for storeItemCategoryName, configData in ipairs(configDatas) do
                                            if _ <= configData.value and configData.value <= filterCategoryName then
                                                table.insert(items, {
                                                    ["storeItem"] = storeItem,
                                                    ["configData"] = {
                                                        [configData.name] = configData.index
                                                    }
                                                })
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        local storeItem = self.xmlFilenameToItem[string.lower(combinationData.customXMLFilename)]
        if storeItem == nil then
            storeItem = self.xmlFilenameToItem[string.lower(combinationData.xmlFilename)]
            if storeItem == nil then
                Logging.warning("Could not find combination vehicle \'%s\'", combinationData.xmlFilename)
            end
        end
        if self:getIsItemUnlocked(storeItem) then
            table.insert(items, {
                ["storeItem"] = storeItem
            })
            return items
        end
    end
    return items
end
function StoreManager:getItemByCustomEnvironment(customEnvironment)
    local items = {}
    for _, item in ipairs(self.items) do
        if item.customEnvironment == customEnvironment then
            table.insert(items, item)
        end
    end
    return items
end
function StoreManager:addModStoreItem(xmlFilename, baseDir, customEnvironment, isMod, isBundleItem, dlcTitle)
    table.insert(self.modStoreItems, {
        ["xmlFilename"] = xmlFilename,
        ["baseDir"] = baseDir,
        ["customEnvironment"] = customEnvironment,
        ["isMod"] = isMod,
        ["isBundleItem"] = isBundleItem,
        ["dlcTitle"] = dlcTitle
    })
end
function StoreManager:loadItem(rawXMLFilename, baseDir, customEnvironment, isMod, isBundleItem, dlcTitle, extraContentId, ignoreAdd)
    local xmlFilename = Utils.getFilename(rawXMLFilename, baseDir)
    local xmlFile = loadXMLFile("storeItemXML", xmlFilename)
    if xmlFile == 0 then
        return nil
    end
    local baseXMLName = getXMLRootName(xmlFile)
    local storeDataXMLKey = baseXMLName .. ".storeData"
    local speciesStr = getXMLString(xmlFile, storeDataXMLKey .. ".species")
    local species = StoreSpecies.getByName(speciesStr) or StoreSpecies.VEHICLE
    local xmlSchema = self.speciesToSchema[species]
    if xmlSchema == nil then
        Logging.xmlError(xmlFile, "Unable to get xml schema for species \'%s\' in \'%s\'", species, xmlFilename)
        return nil
    end
    delete(xmlFile)
    local xmlFile = XMLFile.load("storeManagerLoadItemXml", xmlFilename, xmlSchema)
    local xmlName = Utils.getFilenameInfo(xmlFilename, true)
    local firstLetter = string.sub(xmlName, 1, 1)
    if firstLetter ~= string.lower(firstLetter) then
        Logging.xmlDevWarning(xmlFile, "Filename is starting with upper case character. Please follow the lower camel case naming convention.")
    end
    if tonumber(firstLetter) ~= nil then
        Logging.xmlDevWarning(xmlFile, "Filename is starting with a number. Please start always with a character.")
    end
    local xmlPathPaths = xmlFilename:split("/")
    local numParts = #xmlPathPaths
    if numParts >= 4 and (xmlPathPaths[numParts - 3] == "vehicles" and string.startsWith(string.lower(xmlPathPaths[numParts]), string.lower(xmlPathPaths[numParts - 2]))) then
        Logging.xmlDevWarning(xmlFile, "Vehicle filename \'%s\' starts with brand name \'%s\'.", xmlName, xmlPathPaths[numParts - 2])
    end
    if not xmlFile:hasProperty(storeDataXMLKey) then
        Logging.xmlError(xmlFile, "No storeData found. StoreItem will be ignored!")
        xmlFile:delete()
        return nil
    end
    local isValid = true
    local name = xmlFile:getValue(storeDataXMLKey .. ".name", nil, customEnvironment, true)
    if name == nil then
        Logging.xmlWarning(xmlFile, "Name missing for storeitem. Ignoring store item!")
        isValid = false
    end
    if name ~= nil then
        local params = xmlFile:getValue(storeDataXMLKey .. ".name#params")
        if params ~= nil then
            name = g_i18n:insertTextParams(name, params, customEnvironment, xmlFile)
        end
    end
    local params = xmlFile:getValue(storeDataXMLKey .. ".image", "")
    if params == "" then
        params = nil
    end
    if params == nil and xmlFile:getValue(storeDataXMLKey .. ".showInStore", true) then
        Logging.xmlWarning(xmlFile, "Image icon is missing for storeitem. Ignoring store item!")
        isValid = false
    end
    if not isValid then
        xmlFile:delete()
        return nil
    end
    local storeItem = {
        ["name"] = name,
        ["extraContentId"] = extraContentId,
        ["rawXMLFilename"] = rawXMLFilename,
        ["baseDir"] = baseDir,
        ["xmlSchema"] = xmlSchema,
        ["xmlFilename"] = xmlFilename,
        ["xmlFilenameLower"] = string.lower(xmlFilename)
    }
    if params then
        params = Utils.getFilename(params, baseDir)
    end
    storeItem.imageFilename = params
    storeItem.species = species
    storeItem.functions = StoreItemUtil.getFunctionsFromXML(xmlFile, storeDataXMLKey, customEnvironment)
    storeItem.specs = nil
    storeItem.brandIndex = StoreItemUtil.getBrandIndexFromXML(xmlFile, storeDataXMLKey)
    storeItem.brandNameRaw = xmlFile:getValue(storeDataXMLKey .. ".brand", "")
    storeItem.customBrandIcon = xmlFile:getValue(storeDataXMLKey .. ".brand#customIcon")
    storeItem.customBrandIconOffset = xmlFile:getValue(storeDataXMLKey .. ".brand#imageOffset")
    if storeItem.customBrandIcon ~= nil then
        storeItem.customBrandIcon = Utils.getFilename(storeItem.customBrandIcon, baseDir)
    end
    storeItem.canBeSold = xmlFile:getValue(storeDataXMLKey .. ".canBeSold", true)
    storeItem.showInStore = xmlFile:getValue(storeDataXMLKey .. ".showInStore", not isBundleItem)
    storeItem.isBundleItem = isBundleItem
    storeItem.allowLeasing = xmlFile:getValue(storeDataXMLKey .. ".allowLeasing", true)
    storeItem.maxItemCount = xmlFile:getValue(storeDataXMLKey .. ".maxItemCount")
    storeItem.rotation = xmlFile:getValue(storeDataXMLKey .. ".rotation", 0)
    storeItem.spawnRotationOffset = xmlFile:getValue(storeDataXMLKey .. ".spawnRotationOffset", nil, true)
    storeItem.spawnSizeOffset = xmlFile:getValue(storeDataXMLKey .. ".spawnSizeOffset", nil, true)
    storeItem.shopDynamicTitle = xmlFile:getValue(storeDataXMLKey .. ".shopDynamicTitle", false)
    storeItem.shopTranslationOffset = xmlFile:getValue(storeDataXMLKey .. ".shopTranslationOffset", nil, true)
    storeItem.shopRotationOffset = xmlFile:getValue(storeDataXMLKey .. ".shopRotationOffset", nil, true)
    storeItem.shopIgnoreLastComponentPositions = xmlFile:getValue(storeDataXMLKey .. ".shopIgnoreLastComponentPositions", false)
    storeItem.shopInitialLoadingDelay = xmlFile:getValue(storeDataXMLKey .. ".shopLoadingDelay#initial")
    storeItem.shopConfigLoadingDelay = xmlFile:getValue(storeDataXMLKey .. ".shopLoadingDelay#config")
    storeItem.shopHeight = xmlFile:getValue(storeDataXMLKey .. ".shopHeight", 0)
    storeItem.financeCategory = xmlFile:getValue(storeDataXMLKey .. ".financeCategory")
    storeItem.shopFoldingState = xmlFile:getValue(storeDataXMLKey .. ".shopFoldingState", 0)
    storeItem.shopFoldingTime = xmlFile:getValue(storeDataXMLKey .. ".shopFoldingTime")
    local sharedVramUsage, perInstanceVramUsage, ignoreVramUsage = StoreItemUtil.getVRamUsageFromXML(xmlFile, storeDataXMLKey)
    for _, func in ipairs(self.vramUsageFunctions) do
        local customSharedVramUsage, customPerInstanceVramUsage = func(xmlFile)
    end
    storeItem.sharedVramUsage = sharedVramUsage
    storeItem.perInstanceVramUsage = perInstanceVramUsage
    storeItem.ignoreVramUsage = ignoreVramUsage
    storeItem.dlcTitle = dlcTitle
    storeItem.isMod = isMod
    storeItem.customEnvironment = customEnvironment
    storeItem.categoryNames = {}
    local categoryNames = xmlFile:getValue(storeDataXMLKey .. ".category")
    if categoryNames ~= nil then
        for _ = 1, #categoryNames do
            local func = self:getCategoryByName(categoryNames[_])
            if func == nil then
                Logging.xmlWarning(xmlFile, "Invalid category \'%s\' in store data!", (tostring(categoryNames[_])))
            else
                table.insert(storeItem.categoryNames, func.name)
            end
        end
    end
    if #storeItem.categoryNames == 0 then
        if storeItem.showInStore then
            Logging.xmlWarning(xmlFile, "No categories defined in store data! Using \'misc\' instead!")
        end
        table.insert(storeItem.categoryNames, "MISC")
    end
    storeItem.categoryName = storeItem.categoryNames[1]
    if species == StoreSpecies.VEHICLE then
        local bundleItemsToAdd, bundleInfo = ConfigurationUtil.getConfigurationsFromXML(g_vehicleConfigurationManager, xmlFile, baseXMLName, baseDir, customEnvironment, isMod, storeItem)
        storeItem.configurations = bundleItemsToAdd
        storeItem.defaultConfigurationIds = bundleInfo
        storeItem.subConfigurations = ConfigurationUtil.getSubConfigurationsFromConfigurations(g_vehicleConfigurationManager, storeItem.configurations)
        storeItem.configurationSets = ConfigurationUtil.getConfigurationSetsFromXML(storeItem, xmlFile, baseXMLName, baseDir, customEnvironment, isMod)
        storeItem.hasLicensePlates = xmlFile:hasProperty("vehicle.licensePlates.licensePlate(0)")
    elseif species == StoreSpecies.PLACEABLE then
        local bundleItemsToAdd, bundleInfo = ConfigurationUtil.getConfigurationsFromXML(g_placeableConfigurationManager, xmlFile, baseXMLName, baseDir, customEnvironment, isMod, storeItem)
        storeItem.configurations = bundleItemsToAdd
        storeItem.defaultConfigurationIds = bundleInfo
    end
    storeItem.price = xmlFile:getValue(storeDataXMLKey .. ".price", 0)
    if storeItem.price < 0 then
        Logging.xmlWarning(xmlFile, "Price has to be greater than 0. Using default 10.000 instead!")
        storeItem.price = 10000
    end
    storeItem.dailyUpkeep = xmlFile:getValue(storeDataXMLKey .. ".dailyUpkeep", 0)
    storeItem.runningLeasingFactor = xmlFile:getValue(storeDataXMLKey .. ".runningLeasingFactor", EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR)
    storeItem.lifetime = xmlFile:getValue(storeDataXMLKey .. ".lifetime", 600)
    if storeItem.lifetime <= 0 then
        Logging.xmlWarning(xmlFile, "Lifetime has to be greater than 0. Using default 600 instead!")
        storeItem.lifetime = 600
    end
    xmlFile:iterate("handTool.storeData.storePacks.storePack", function(_, key)
        -- upvalues: (ref) xmlFile, (copy) self, (copy) xmlFilename
        self:addPackItem(xmlFile:getValue(key), xmlFilename)
    end)
    xmlFile:iterate("vehicle.storeData.storePacks.storePack", function(_, key)
        -- upvalues: (ref) xmlFile, (copy) self, (copy) xmlFilename
        self:addPackItem(xmlFile:getValue(key), xmlFilename)
    end)
    local bundleItemsToAdd = {}
    if xmlFile:hasProperty(storeDataXMLKey .. ".bundleElements") then
        local bundleInfo = {
            ["bundleItems"] = {},
            ["attacherInfo"] = {}
        }
        local _ = 0
        local func = math.huge
        local customSharedVramUsage = 0
        local customPerInstanceVramUsage = 0
        for bundleIndex, bundleKey in xmlFile:iterator(storeDataXMLKey .. ".bundleElements.bundleElement") do
            local bundleXmlFile = xmlFile:getValue(bundleKey .. ".xmlFilename")
            local offset = xmlFile:getValue(bundleKey .. ".offset", "0 0 0", true)
            local rotationOffset = xmlFile:getValue(bundleKey .. ".rotationOffset", "0 0 0", true)
            local rotation = xmlFile:getValue(bundleKey .. ".yRotation", 0)
            rotationOffset[2] = rotationOffset[2] + rotation
            if bundleXmlFile ~= nil then
                local item = self:getItemByXMLFilename((Utils.getFilename(bundleXmlFile, baseDir)))
                if item == nil then
                    item = self:loadItem(bundleXmlFile, baseDir, customEnvironment, isMod, true, dlcTitle, nil, true)
                    table.insert(bundleItemsToAdd, item)
                end
                if item ~= nil then
                    func = math.min(func, item.lifetime)
                    if item.configurations ~= nil then
                        storeItem.configurations = storeItem.configurations or {}
                        for configName, configOptions in pairs(item.configurations) do
                            if storeItem.configurations[configName] == nil then
                                storeItem.configurations[configName] = table.clone(configOptions, 5)
                            else
                                local j = 1
                                for j = j, #configOptions do
                                    if storeItem.configurations[configName][j] == nil then
                                        itemConfigOptions[j] = configOptions[j]
                                    else
                                        itemConfigOptions[j].price = itemConfigOptions[j].price + configOptions[j].price
                                    end
                                end
                            end
                        end
                    end
                    if item.defaultConfigurationIds ~= nil then
                        storeItem.defaultConfigurationIds = storeItem.defaultConfigurationIds or {}
                    end
                    if item.subConfigurations ~= nil then
                        storeItem.subConfigurations = storeItem.subConfigurations or {}
                        for configName, configOptions in pairs(item.subConfigurations) do
                            storeItem.subConfigurations[configName] = configOptions
                        end
                    end
                    if item.configurationSets ~= nil then
                        storeItem.configurationSets = storeItem.configurationSets or {}
                        for configName, configOptions in pairs(item.configurationSets) do
                            storeItem.configurationSets[configName] = configOptions
                        end
                    end
                    local preSelectedConfigurations = {}
                    xmlFile:iterate(bundleKey .. ".configurations.configuration", function(_, configKey)
                        -- upvalues: (ref) xmlFile, (ref) item, (copy) preSelectedConfigurations, (copy) storeItem
                        local configName = xmlFile:getValue(configKey .. "#name")
                        local configValue = xmlFile:getValue(configKey .. "#value")
                        if configValue == nil then
                            local configSaveId = xmlFile:getValue(configKey .. "#saveId")
                            if item.configurations ~= nil then
                                local configs = item.configurations[configName]
                                if configs ~= nil then
                                    local j = 1
                                    for j = j, #configs do
                                        if configs[j].saveId == configSaveId then
                                            configValue = configs[j].index
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        if configName ~= nil and configValue ~= nil then
                            local configSaveId = xmlFile:getValue(configKey .. "#allowChange", false)
                            local configs = xmlFile:getValue(configKey .. "#hideOption", false)
                            if not xmlFile:getValue(configKey .. "#disableOption", false) then
                                preSelectedConfigurations[configName] = {
                                    ["configValue"] = configValue,
                                    ["allowChange"] = configSaveId,
                                    ["hideOption"] = configs
                                }
                                return
                            end
                            local configElements = storeItem.configurations[configName]
                            if configElements ~= nil then
                                local j = 1
                                local j = #configElements
                                for j = j, j do
                                    if j == configValue then
                                        configElements[j].isSelectable = not configElements[j].isSelectable
                                    end
                                end
                            end
                        end
                    end)
                    storeItem.hasLicensePlates = storeItem.hasLicensePlates or item.hasLicensePlates
                    local configName = {
                        ["item"] = item,
                        ["xmlFilename"] = item.xmlFilename,
                        ["offset"] = offset,
                        ["rotationOffset"] = rotationOffset,
                        ["rotation"] = 0,
                        ["price"] = item.price,
                        ["preSelectedConfigurations"] = preSelectedConfigurations
                    }
                    table.insert(bundleInfo.bundleItems, configName)
                end
            end
        end
        for bundleIndex, bundleKey in xmlFile:iterator(storeDataXMLKey .. ".attacherInfo.attach") do
            local bundleXmlFile = xmlFile:getValue(bundleKey .. "#bundleElement0")
            local offset = xmlFile:getValue(bundleKey .. "#bundleElement1")
            local rotationOffset = xmlFile:getValue(bundleKey .. "#attacherJointIndex")
            local rotation = xmlFile:getValue(bundleKey .. "#inputAttacherJointIndex")
            if bundleXmlFile ~= nil and (offset ~= nil and (rotationOffset ~= nil and rotation ~= nil)) then
                table.insert(bundleInfo.attacherInfo, {
                    ["bundleElement0"] = bundleXmlFile,
                    ["bundleElement1"] = offset,
                    ["attacherJointIndex"] = rotationOffset,
                    ["inputAttacherJointIndex"] = rotation
                })
            end
        end
        storeItem.price = _
        storeItem.dailyUpkeep = customSharedVramUsage
        storeItem.runningLeasingFactor = customPerInstanceVramUsage
        storeItem.lifetime = func
        storeItem.bundleInfo = bundleInfo
    end
    if Platform.hasContruction then
        if xmlFile:hasProperty(storeDataXMLKey .. ".brush") and storeItem.showInStore then
            local bundleInfo = xmlFile:getValue(storeDataXMLKey .. ".brush.type")
            if bundleInfo ~= nil and bundleInfo ~= "none" then
                if g_constructionBrushTypeManager:getClassObjectByTypeName(bundleInfo) == nil then
                    Logging.xmlError(xmlFile, "Unknown brush type %q", bundleInfo)
                    printf("Available brush types: %s", table.concat(table.toList(g_constructionBrushTypeManager:getBrushTypes()), ", "))
                end
                local _ = {}
                xmlFile:iterate(storeDataXMLKey .. ".brush.parameters.parameter", function(index, key)
                    -- upvalues: (ref) xmlFile, (copy) baseDir, (copy) _
                    local value = xmlFile:getValue(key)
                    if xmlFile:getValue(key .. "#isFilename", false) then
                        value = Utils.getFilename(value, baseDir)
                    end
                    _[index] = value
                end)
                local func = xmlFile:getValue(storeDataXMLKey .. ".brush.category")
                if func == nil then
                    Logging.xmlWarning(xmlFile, "Unknown brush category \'%s\'", func)
                else
                    local customSharedVramUsage = self:getConstructionCategoryByName(func)
                    if customSharedVramUsage == nil then
                        Logging.xmlWarning(xmlFile, "Missing brush category: %s", storeDataXMLKey .. ".brush.category")
                    else
                        local customPerInstanceVramUsage = self:getConstructionTabByName(xmlFile:getValue(storeDataXMLKey .. ".brush.tab"), customSharedVramUsage.name)
                        if customPerInstanceVramUsage == nil then
                            Logging.xmlWarning(xmlFile, "Missing brush tab")
                        else
                            storeItem.brush = {
                                ["type"] = bundleInfo,
                                ["parameters"] = _,
                                ["category"] = customSharedVramUsage,
                                ["tab"] = customPerInstanceVramUsage
                            }
                        end
                    end
                end
            end
        elseif storeItem.species == StoreSpecies.PLACEABLE and storeItem.showInStore then
            local bundleInfo = self.constructionCategories[1]
            if bundleInfo == nil then
                Logging.xmlDevWarning(xmlFile, "Construction category not found for \'%s\'", storeDataXMLKey)
            else
                storeItem.brush = {
                    ["type"] = "placeable",
                    ["parameters"] = {},
                    ["category"] = bundleInfo,
                    ["tab"] = bundleInfo.tabs[1]
                }
            end
        end
    end
    if not ignoreAdd then
        self:addItem(storeItem)
        local func = 1
        for func = func, #bundleItemsToAdd do
            self:addItem(bundleItemsToAdd[func])
        end
    end
    xmlFile:delete()
    return storeItem
end
function StoreManager:addPack(name, title, imageFilename, baseDir)
    if name == nil or name == "" then
        printWarning("Warning: Could not register store pack. Name is missing or empty!")
        return false
    end
    if not ClassUtil.getIsValidIndexName(name) then
        printWarning("Warning: \'" .. tostring(name) .. "\' is no valid name for a store pack!")
        return false
    end
    if title == nil or title == "" then
        printWarning("Warning: Could not register store pack. Title is missing or empty!")
        return false
    end
    if imageFilename == nil or imageFilename == "" then
        printWarning("Warning: Could not register store pack. Image is missing or empty!")
        return false
    end
    if baseDir == nil then
        printWarning("Warning: Could not register store pack. Basedirectory not defined!")
        return false
    end
    name = string.upper(name)
    if self.packs[name] ~= nil then
        return false
    end
    self.numOfPacks = self.numOfPacks + 1
    self.packs[name] = {
        ["name"] = name,
        ["title"] = title,
        ["image"] = Utils.getFilename(imageFilename, baseDir),
        ["baseDir"] = baseDir,
        ["orderId"] = self.numOfPacks,
        ["items"] = {}
    }
    return true
end
function StoreManager:addModConstructionTab(categoryName, tabName, tabTitle, tabIconFilename, tabRefSize, tabIconUVs, baseDir, tabIconSliceId)
    table.insert(self.modConstructionTabs, {
        ["categoryName"] = categoryName,
        ["tabName"] = tabName,
        ["tabTitle"] = tabTitle,
        ["tabIconFilename"] = tabIconFilename,
        ["tabRefSize"] = tabRefSize,
        ["tabIconUVs"] = tabIconUVs,
        ["tabIconSliceId"] = tabIconSliceId,
        ["baseDir"] = baseDir
    })
end
function StoreManager:addModStorePack(name, title, imageFilename, baseDir, storeItems)
    table.insert(self.modStorePacks, {
        ["name"] = name,
        ["title"] = title,
        ["imageFilename"] = imageFilename,
        ["baseDir"] = baseDir,
        ["storeItems"] = storeItems or {}
    })
end
function StoreManager:addPackItem(name, itemFilename)
    if name == nil or name == "" then
        Logging.warning("Could not add pack item. Name is missing or empty.")
        return
    elseif self.packs[name] == nil then
        Logging.warning("Could not add pack item. Pack \'%s\' does not exist.", name)
        return
    elseif itemFilename == nil or itemFilename == "" then
        Logging.warning("Could not add pack item to \'%s\'. Item filename is missing.", name)
    else
        table.insert(self.packs[name].items, itemFilename)
    end
end
function StoreManager:getPacks()
    return self.packs
end
function StoreManager:getPackItems(name)
    local pack = self.packs[name]
    if pack == nil then
        return nil
    else
        return pack.items
    end
end
function StoreManager:search(text, callback)
    return self.indexedSearch:search(text, callback)
end
function StoreManager:consoleCommandReloadStoreItems()
    for i, item in ipairs(self.items) do
        self.items[i] = self:loadItem(item.rawXMLFilename, item.baseDir, item.customEnvironment, item.isMod, item.isBundleItem, item.dlcTitle, item.extraContentId, true)
        if self.items[i] ~= nil then
            self.xmlFilenameToItem[self.items[i].xmlFilenameLower] = self.items[i]
        end
    end
    g_messageCenter:publish(MessageType.STORE_ITEMS_RELOADED)
end
function StoreManager.registerStoreCategoriesXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#name", "Store category name identifier")
    schema:register(XMLValueType.STRING, basePath .. "#title", "Store category title")
    schema:register(XMLValueType.STRING, basePath .. "#image", "Store category image")
    schema:register(XMLValueType.STRING, basePath .. "#type", "Store category type")
    schema:register(XMLValueType.STRING, basePath .. "#insertAfter", "Store category should be inserted after this category")
end
function StoreManager.registerStoreDataXMLPaths(schema, basePath)
    schema:register(XMLValueType.L10N_STRING, basePath .. ".storeData.name", "Name of store item", nil, true)
    schema:register(XMLValueType.STRING, basePath .. ".storeData.name#params", "Parameters to add to name")
    local speciesDefaultValue = StoreSpecies.getName(StoreSpecies.VEHICLE)
    local speciesDefaultValues = StoreSpecies.getAllOrderedByName()
    schema:register(XMLValueType.STRING, basePath .. ".storeData.species", "Store species", speciesDefaultValue, false, speciesDefaultValues)
    schema:register(XMLValueType.STRING, basePath .. ".storeData.image", "Path to store icon", nil, true)
    schema:register(XMLValueType.STRING, basePath .. ".storeData.brand", "Brand identifier", "LIZARD")
    schema:registerAutoCompletionDataSource(basePath .. ".storeData.brand", "$dataS/brands.xml", "brands.brand#name")
    schema:register(XMLValueType.STRING, basePath .. ".storeData.brand#customIcon", "Custom brand icon to display in the shop config screen")
    schema:register(XMLValueType.STRING, basePath .. ".storeData.brand#imageOffset", "Offset of custom brand icon")
    schema:register(XMLValueType.BOOL, basePath .. ".storeData.canBeSold", "Defines of the vehicle can be sold", true)
    schema:register(XMLValueType.BOOL, basePath .. ".storeData.showInStore", "Defines of the vehicle is shown in shop", true)
    schema:register(XMLValueType.BOOL, basePath .. ".storeData.allowLeasing", "Defines of the vehicle can be leased", true)
    schema:register(XMLValueType.INT, basePath .. ".storeData.maxItemCount", "Defines the max. amount vehicle of this type")
    schema:register(XMLValueType.ANGLE, basePath .. ".storeData.rotation", "Y rotation of the vehicle", 0)
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".storeData.spawnRotationOffset", "Y rotation of the vehicle when spawned at the shop loading places")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".storeData.spawnSizeOffset", "Additional size that is reserved for the tool when spawned at the shop loading places (width, height, length)")
    schema:register(XMLValueType.STRING_LIST, basePath .. ".storeData.category", "Store category name or names (space separated)", "misc")
    schema:registerAutoCompletionDataSource(basePath .. ".storeData.category", "$dataS/storeCategories.xml", "categories.category#name")
    schema:register(XMLValueType.STRING, basePath .. ".storeData.storePacks.storePack(?)", "Store pack")
    schema:register(XMLValueType.FLOAT, basePath .. ".storeData.price", "Store price", 10000)
    schema:register(XMLValueType.FLOAT, basePath .. ".storeData.dailyUpkeep", "Daily up keep", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".storeData.runningLeasingFactor", "Running leasing factor", EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR)
    schema:register(XMLValueType.FLOAT, basePath .. ".storeData.lifetime", "Lifetime of vehicle used to calculate price drop, in months", 600)
    schema:register(XMLValueType.BOOL, basePath .. ".storeData.shopDynamicTitle", "Vehicle brand icon and vehicle name is dynamically updated based on the selected configuration in the shop", false)
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".storeData.shopTranslationOffset", "Translation offset for shop spawning and store icon", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".storeData.shopRotationOffset", "Rotation offset for shop spawning and store icon", "0 0 0")
    schema:register(XMLValueType.BOOL, basePath .. ".storeData.shopIgnoreLastComponentPositions", "If set to true the component positions from last spawning are now reused", false)
    schema:register(XMLValueType.TIME, basePath .. ".storeData.shopLoadingDelay#initial", "Delay of initial shop loading until the vehicle is displayed. (Used e.g. to hide vehicle while components still moving)")
    schema:register(XMLValueType.TIME, basePath .. ".storeData.shopLoadingDelay#config", "Delay of shop loading after config change until the vehicle is displayed. (Used e.g. to hide vehicle while components still moving)")
    schema:register(XMLValueType.FLOAT, basePath .. ".storeData.shopHeight", "Height of vehicle for shop placement", 0)
    schema:register(XMLValueType.STRING, basePath .. ".storeData.financeCategory", "Finance category name")
    schema:register(XMLValueType.INT, basePath .. ".storeData.shopFoldingState", "Inverts the shop folding state if set to \'1\'", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".storeData.shopFoldingTime", "Defines a custom folding time for the shop")
    schema:register(XMLValueType.INT, basePath .. ".storeData.vertexBufferMemoryUsage", "Vertex buffer memory usage", 0)
    schema:register(XMLValueType.INT, basePath .. ".storeData.indexBufferMemoryUsage", "Index buffer memory usage", 0)
    schema:register(XMLValueType.INT, basePath .. ".storeData.textureMemoryUsage", "Texture memory usage", 0)
    schema:register(XMLValueType.INT, basePath .. ".storeData.instanceVertexBufferMemoryUsage", "Instance vertex buffer memory usage", 0)
    schema:register(XMLValueType.INT, basePath .. ".storeData.instanceIndexBufferMemoryUsage", "Instance index buffer memory usage", 0)
    schema:register(XMLValueType.BOOL, basePath .. ".storeData.ignoreVramUsage", "Ignore VRAM usage", false)
    schema:register(XMLValueType.INT, basePath .. ".storeData.audioMemoryUsage", "Audio memory usage", 0)
    schema:register(XMLValueType.STRING, basePath .. ".storeData.bundleElements.bundleElement(?).xmlFilename", "XML filename")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".storeData.bundleElements.bundleElement(?).offset", "Translation offset of vehicle")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".storeData.bundleElements.bundleElement(?).rotationOffset", "Rotation offset of vehicle")
    schema:register(XMLValueType.ANGLE, basePath .. ".storeData.bundleElements.bundleElement(?).yRotation", "Y rotation of vehicle")
    schema:register(XMLValueType.STRING, basePath .. ".storeData.bundleElements.bundleElement(?).configurations.configuration(?)#name", "Name of configuration")
    schema:register(XMLValueType.INT, basePath .. ".storeData.bundleElements.bundleElement(?).configurations.configuration(?)#value", "Configuration index that is forced for this config")
    schema:register(XMLValueType.STRING, basePath .. ".storeData.bundleElements.bundleElement(?).configurations.configuration(?)#saveId", "Configuration save id that is forced for this config")
    schema:register(XMLValueType.BOOL, basePath .. ".storeData.bundleElements.bundleElement(?).configurations.configuration(?)#allowChange", "Allow change of option", false)
    schema:register(XMLValueType.BOOL, basePath .. ".storeData.bundleElements.bundleElement(?).configurations.configuration(?)#hideOption", "Hide the option completely", false)
    schema:register(XMLValueType.BOOL, basePath .. ".storeData.bundleElements.bundleElement(?).configurations.configuration(?)#disableOption", "Disabled this particular config option", false)
    schema:register(XMLValueType.INT, basePath .. ".storeData.attacherInfo.attach(?)#bundleElement0", "First bundle element")
    schema:register(XMLValueType.INT, basePath .. ".storeData.attacherInfo.attach(?)#bundleElement1", "Second bundle element")
    schema:register(XMLValueType.INT, basePath .. ".storeData.attacherInfo.attach(?)#attacherJointIndex", "Attacher joint index")
    schema:register(XMLValueType.INT, basePath .. ".storeData.attacherInfo.attach(?)#inputAttacherJointIndex", "Input attacher joint index")
    schema:register(XMLValueType.L10N_STRING, basePath .. ".storeData.functions.function(?)", "Function description text")
    schema:registerAutoCompletionDataSource(basePath .. ".storeData.functions.function(?)", "dataS/l10n/l10n_en.xml", "l10n.elements.e#k", "$l10n_")
    schema:register(XMLValueType.STRING, basePath .. ".storeData.brush.type", "Brush type")
    schema:register(XMLValueType.STRING, basePath .. ".storeData.brush.category", "Brush category")
    schema:register(XMLValueType.STRING, basePath .. ".storeData.brush.tab", "Brush tab")
    schema:register(XMLValueType.STRING, basePath .. ".storeData.brush.parameters.parameter(?)", "Brush parameter value")
    schema:register(XMLValueType.STRING, basePath .. ".storeData.brush.parameters.parameter(?)#isFilename", "Whether the parameter is a filename")
    schema:register(XMLValueType.ANGLE, basePath .. ".storeData.storeIconRendering.settings#cameraYRot", "Y Rot of camera", "Setting from Icon Generator")
    schema:register(XMLValueType.ANGLE, basePath .. ".storeData.storeIconRendering.settings#cameraXRot", "X Rot of camera", "Setting from Icon Generator")
    schema:register(XMLValueType.BOOL, basePath .. ".storeData.storeIconRendering.settings#advancedBoundingBox", "Advanced BB is used for icon placement", "Setting from Icon Generator")
    schema:register(XMLValueType.BOOL, basePath .. ".storeData.storeIconRendering.settings#centerIcon", "Center item on icon", "Setting from Icon Generator")
    schema:register(XMLValueType.FLOAT, basePath .. ".storeData.storeIconRendering.settings#zoomFactor", "Camera zoom factor")
    schema:register(XMLValueType.FLOAT, basePath .. ".storeData.storeIconRendering.settings#lightIntensity", "Intensity of light sources", "Setting from Icon Generator")
    schema:register(XMLValueType.BOOL, basePath .. ".storeData.storeIconRendering.settings#showTriggerMarkers", "Show trigger markers on icon (for placeables)", false)
    schema:register(XMLValueType.BOOL, basePath .. ".storeData.storeIconRendering.objectBundle#useClipPlane", "Clip plane is used")
    schema:register(XMLValueType.STRING, basePath .. ".storeData.storeIconRendering.objectBundle.object(?)#filename", "Path to i3d file")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".storeData.storeIconRendering.objectBundle.object(?).node(?)#node", "Index Path of node to load")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".storeData.storeIconRendering.objectBundle.object(?).node(?)#translation", "Translation", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".storeData.storeIconRendering.objectBundle.object(?).node(?)#rotation", "Rotation", "0 0 0")
    schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".storeData.storeIconRendering.objectBundle.object(?).node(?)#scale", "Scale", "1 1 1")
    schema:register(XMLValueType.STRING, basePath .. ".storeData.storeIconRendering.shaderParameter(?)#name", "Name if shader parameter")
    schema:register(XMLValueType.STRING, basePath .. ".storeData.storeIconRendering.shaderParameter(?)#values", "Values of shader parameter")
end
g_storeManager = StoreManager.new()