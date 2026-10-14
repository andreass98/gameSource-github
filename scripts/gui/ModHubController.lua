ModHubController = {}
local ModHubController_mt = Class(ModHubController)
ModHubController.CATEGORY_ID_CONTEST = 8
ModHubController.CATEGORY_ID_DOWNLOAD = 2
ModHubController.CATEGORY_ID_UPDATE = 3
ModHubController.HIDDEN_CATEGORY = "hidden"
local setModHubRatingLocal = setModHubRating
local getModHubRatingLocal = getModHubRating
function ModHubController.new()
    -- upvalues: (copy) ModHubController_mt
    local self = setmetatable({}, ModHubController_mt)
    self.isInitialized = false
    self.categories = {}
    self.modIdToInfo = {}
    self.categoryTypeMapping = {}
    self.categoryNameMapping = {}
    self.hasChanges = false
    self.hasTriggedUUIDInEngine = false
    self.priceMapping = {
        ["en"] = "DLCPriceEUR",
        ["de"] = "DLCPriceEUR",
        ["pl"] = "DLCPriceEUR",
        ["cz"] = "DLCPriceEUR",
        ["fr"] = "DLCPriceEUR",
        ["es"] = "DLCPriceEUR",
        ["it"] = "DLCPriceEUR",
        ["pt"] = "DLCPriceEUR",
        ["hu"] = "DLCPriceEUR",
        ["nl"] = "DLCPriceEUR",
        ["da"] = "DLCPriceEUR",
        ["fi"] = "DLCPriceEUR",
        ["no"] = "DLCPriceEUR",
        ["sv"] = "DLCPriceEUR",
        ["jp"] = "DLCPriceUSD",
        ["ru"] = "DLCPriceUSD",
        ["cs"] = "DLCPriceUSD",
        ["ct"] = "DLCPriceUSD",
        ["br"] = "DLCPriceUSD",
        ["tr"] = "DLCPriceUSD",
        ["ro"] = "DLCPriceUSD",
        ["kr"] = "DLCPriceUSD",
        ["ea"] = "DLCPriceUSD",
        ["fc"] = "DLCPriceUSD",
        ["uk"] = "DLCPriceUSD",
        ["vi"] = "DLCPriceUSD",
        ["id"] = "DLCPriceUSD"
    }
    local i = 0
    for i = i, getNumOfLanguages() - 1 do
        local code = getLanguageCode(i)
        if self.priceMapping[code] == nil then
            Logging.devError("ModHubController: Missing price mapping for \'%s\'", code)
            self.priceMapping[g_languageShort] = "DLCPriceUSD"
        end
    end
    g_messageCenter:subscribe(MessageType.USER_PROFILE_CHANGED, self.userProfileChanged, self)
    self.categoryTypeNameMapping = {}
    self.localCategories = {}
    self.categoryTypes = {}
    self.localCategoriesSorted = {}
    self:loadCategoriesFromXML()
    return self
end
function ModHubController:loadCategoriesFromXML()
    local xmlFile = loadXMLFile("configFile", "dataS/modHub.xml")
    local i = 0
    while true do
        local key = string.format("modHub.categories.types.type(%d)", i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local name = getXMLString(xmlFile, key .. "#name")
        local title = getXMLString(xmlFile, key .. "#title")
        if title ~= nil then
            title = g_i18n:convertText(title)
        end
        self.categoryTypeNameMapping[name] = title
        i = i + 1
    end
    local i = 0
    while true do
        local key = string.format("modHub.categories.category(%d)", i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local name = getXMLString(xmlFile, key .. "#name")
        local title = getXMLString(xmlFile, key .. "#type") or name
        local imageFilename = getXMLString(xmlFile, key .. "#imageFilename")
        if name ~= nil and imageFilename ~= nil then
            local localCategory = {
                ["name"] = name,
                ["categoryType"] = title,
                ["imageFilename"] = imageFilename,
                ["isTab"] = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isTab"), false),
                ["isHidden"] = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isHidden"), false),
                ["title"] = getXMLString(xmlFile, key .. "#title")
            }
            self.localCategories[name] = localCategory
            if localCategory.isTab or localCategory.isHidden then
                title = ModHubController.HIDDEN_CATEGORY
            end
            if self.localCategoriesSorted[title] == nil then
                self.localCategoriesSorted[title] = {}
                table.insert(self.categoryTypes, title)
            end
            table.insert(self.localCategoriesSorted[title], name)
        end
        i = i + 1
    end
    delete(xmlFile)
end
function ModHubController:reset()
    self.isInitialized = false
    self.categories = {}
    self.modIdToInfo = {}
    self.categoryNameMapping = {}
    self.categoryTypeMapping = {}
end
function ModHubController:delete()
    g_messageCenter:unsubscribeAll(self)
end
function ModHubController:startModification()
    self.hasChanges = false
end
function ModHubController:endModification()
    if self.hasChanges then
        reloadDlcsAndMods()
    end
    self.hasChanges = false
end
function ModHubController:load()
    if not self.isInitialized then
        local numCategories = getNumModCategories()
        if g_isDevelopmentVersion then
            ModHubController.CATEGORY_ID_TESTING = numCategories + 1
            numCategories = numCategories + 1
        end
        local i = 1
        for i = i, numCategories do
            self:loadCategory(i)
        end
        for typeIndex, categoryType in ipairs(self.categoryTypes) do
            local typeTable = {}
            for _, categoryName in ipairs(self.localCategoriesSorted[categoryType]) do
                local categoryInfo = self.categoryNameMapping[categoryName]
                if categoryInfo ~= nil then
                    table.insert(typeTable, categoryInfo)
                end
            end
            self.categoryTypeMapping[categoryType] = typeIndex
            table.insert(self.categories, typeTable)
        end
        self.isInitialized = true
    end
end
function ModHubController:loadCategory(categoryId)
    local isTestingCategory = g_isDevelopmentVersion
    if isTestingCategory then
        isTestingCategory = categoryId == ModHubController.CATEGORY_ID_TESTING
    end
    if categoryId ~= ModHubController.CATEGORY_ID_CONTEST or not GS_IS_CONSOLE_VERSION and getNumOfMods(categoryId - 1) > 0 or isTestingCategory then
        local categoryName = isTestingCategory and "testing" or getModCategoryName(categoryId - 1)
        local localCategory = self.localCategories[categoryName]
        if localCategory ~= nil then
            local title = nil
            if localCategory.title ~= nil then
                title = g_i18n:convertText(localCategory.title)
            end
            if title == nil then
                title = g_i18n:getText("modHub_" .. categoryName)
            end
            local numNewItems, numAvailableUpdates, numConflictedItems = self:getCategoryData(categoryId)
            local categoryInfo = self.categoryNameMapping[categoryName]
            if categoryInfo == nil then
                categoryInfo = ModCategoryInfo.new(categoryId, title, localCategory.imageFilename, categoryName, localCategory.isTab or localCategory.isHidden)
                self.categoryNameMapping[categoryName] = categoryInfo
            else
                categoryInfo:updateInfo(categoryId, title, iconFilename, categoryName, isHidden)
            end
            categoryInfo:setNumAvailableUpdates(numAvailableUpdates)
            categoryInfo:setNumNewItems(numNewItems)
            categoryInfo:setNumConflictedItems(numConflictedItems)
            return
        end
        Logging.warning("Could not find modhub category %s in modHub.xml", categoryName)
    end
end
function ModHubController:reload()
    self.categoryNameMapping = {}
    self.categories = {}
    self.isInitialized = false
    self:load()
end
function ModHubController:getCategories()
    return self.categories
end
function ModHubController:getCategoryTypes()
    local visibleTypes = {}
    for typeIndex, categoryType in pairs(self.categoryTypes) do
        if categoryType ~= ModHubController.HIDDEN_CATEGORY then
            for _, categoryName in pairs(self.localCategoriesSorted[categoryType]) do
                local category = self.categoryNameMapping[categoryName]
                if category ~= nil and (not category.isHidden and category:getNumMods() > 0) then
                    table.insert(visibleTypes, categoryType)
                    break
                end
            end
        end
    end
    return visibleTypes
end
function ModHubController:getVisibleCategories()
    local list = {}
    for typeIndex, categoryType in pairs(self.categoryTypes) do
        if categoryType ~= ModHubController.HIDDEN_CATEGORY then
            local typeList = {}
            for _, categoryName in pairs(self.localCategoriesSorted[categoryType]) do
                local category = self.categoryNameMapping[categoryName]
                if category ~= nil and (not category.isHidden and category:getNumMods() > 0) then
                    table.insert(typeList, category)
                end
            end
            if #typeList > 0 then
                table.insert(list, typeList)
            end
        end
    end
    return list
end
function ModHubController:getCategoryData(categoryId)
    if categoryId == ModHubController.CATEGORY_ID_TESTING then
        return 0, 0, 0
    end
    local numOfMods = 0
    if categoryId > 0 then
        numOfMods = getNumOfMods(categoryId - 1)
    end
    local numNewItems = 0
    local numUpdates = 0
    local numConflicts = 0
    if categoryId == ModHubController.CATEGORY_ID_DOWNLOAD then
        return numOfMods, numUpdates, numConflicts
    end
    if categoryId == ModHubController.CATEGORY_ID_UPDATE then
        return numNewItems, numOfMods, numConflicts
    end
    if numOfMods > 0 then
        local i = 0
        for i = i, numOfMods - 1 do
            local modInfo = self:getModInfo((getModId(categoryId - 1, i)))
            if not modInfo:getIsDLC() or (modInfo:getPriceString():len() > 1 or modInfo:getIsInstalled()) then
                numUpdates = numUpdates + modInfo:getNumUpdates()
                numConflicts = numConflicts + modInfo:getNumConflicts()
                numNewItems = numNewItems + modInfo:getNumNew()
            end
        end
    end
    return numNewItems, numUpdates, numConflicts
end
function ModHubController:getModsByCategory(categoryId, visibleOnly)
    if g_isDevelopmentVersion then
        if categoryId == ModHubController.CATEGORY_ID_TESTING then
            local testingMods = {}
            for _, modInfo in pairs(self.modIdToInfo) do
                if modInfo:getIsTesting() then
                    table.insert(testingMods, modInfo)
                end
            end
            table.sort(testingMods, function(a, b)
                return a:getName() < b:getName()
            end)
            return testingMods
        end
    end
    if categoryId == ModHubController.CATEGORY_ID_UPDATE then
        local isTestingCategory = {}
        local testingMods = getNumOfMods(categoryId - 1)
        if testingMods > 0 then
            local i = 0
            for i = i, testingMods - 1 do
                local _ = getModId(categoryId - 1, i)
                local modInfo = self:getModInfo(_)
                if _ < 0 then
                    Logging.devError("external/non-modhub mod included in \'UPDATE\' category: id:%d %s %s size:%d", modInfo:getId(), modInfo:getName(), modInfo:getFilename(), modInfo:getFilesize())
                end
                table.insert(isTestingCategory, modInfo)
            end
        end
        return isTestingCategory
    else
        local isTestingCategory = {}
        local testingMods = getNumOfMods(categoryId - 1)
        if testingMods > 0 then
            local i = 0
            for i = i, testingMods - 1 do
                local modInfo = self:getModInfo((getModId(categoryId - 1, i)))
                if not visibleOnly or (not modInfo:getIsDLC() or (modInfo:getPriceString():len() > 1 or modInfo:getIsInstalled())) then
                    table.insert(isTestingCategory, modInfo)
                end
            end
        end
        return isTestingCategory
    end
end
function ModHubController:getCategory(name)
    return self.categoryNameMapping[name]
end
function ModHubController:getModInfo(modId)
    local modInfo = self.modIdToInfo[modId]
    if modInfo == nil then
        if type(modId) ~= "number" then
            return nil
        end
        modInfo = ModInfo.new(modId, self:getPostFix(), self.priceMapping[g_languageShort])
        self.modIdToInfo[modId] = modInfo
    end
    return modInfo
end
function ModHubController:getDependentMods(modId)
    local dependendMods = {}
    local i = 0
    for i = i, getModNumDependencies(modId) - 1 do
        local modInfo = self:getModInfo((getModDependency(modId, i)))
        table.insert(dependendMods, modInfo)
    end
    return dependendMods
end
function ModHubController:getPostFix()
    return g_languageShort ~= "de" and g_languageShort ~= "fr" and "en" or g_languageShort
end
function ModHubController:getTotalFilesizeKb(modId)
    local modInfo = self:getModInfo(modId)
    local dependendMods = self:getDependentMods(modId)
    local totalFilesizeKb = math.floor((modInfo:getFilesize() + 1023) / 1024)
    for _, dependendMod in ipairs(dependendMods) do
        if not dependendMod.isInstalled then
            totalFilesizeKb = totalFilesizeKb + math.floor((dependendMod:getFilesize() + 1023) / 1024)
        end
    end
    return totalFilesizeKb
end
function ModHubController:getFreeModSpaceKb()
    return getModFreeSpaceKb()
end
function ModHubController:getUsedModSpaceKb()
    return getModUsedSpaceKb()
end
function ModHubController:getTotalModSpaceKb()
    return getModFreeSpaceKb() + getModUsedSpaceKb()
end
function ModHubController:isContestEnabled()
    if not self.isInitialized then
        return false
    end
    if self.isContestEnabledStored == nil then
        self.isContestEnabledStored = getNumOfMods(ModHubController.CATEGORY_ID_CONTEST - 1) > 0
    end
    return self.isContestEnabledStored
end
function ModHubController:install(modId)
    if installMod(modId) then
        local dependendMods = self:getDependentMods(modId)
        for _, dependendMod in ipairs(dependendMods) do
            if not (dependendMod.isInstalled or installMod(dependendMod.modId)) then
                table.insert({}, dependendMod)
            end
        end
        self.addedToDownloadCallback()
    else
        self.modInstallFailedCallback()
    end
    if self.discSpaceChangedCallback ~= nil then
        self.discSpaceChangedCallback()
    end
end
function ModHubController:setModInstallFailedCallback(callback, target)
    function self.modInstallFailedCallback()
        -- upvalues: (copy) callback, (copy) target
        callback(target)
    end
end
function ModHubController:setDependentModInstallFailedCallback(callback, target)
    function self.dependendModInstallFailedCallback(failedDependentMods)
        -- upvalues: (copy) callback, (copy) target
        callback(target, failedDependentMods)
    end
end
function ModHubController:setAddedToDownloadCallback(callback, target)
    function self.addedToDownloadCallback()
        -- upvalues: (copy) callback, (copy) target
        callback(target)
    end
end
function ModHubController:installOrUpdateMods(modIds, finishCallback)
    self:startModification()
    local numToGo = #modIds
    local numFailed = 0
    local function failure()
        -- upvalues: (ref) numToGo, (ref) numFailed, (copy) finishCallback
        numToGo = numToGo - 1
        numFailed = numFailed + 1
        if numToGo == 0 then
            finishCallback(numFailed)
        end
    end
    self:setModInstallFailedCallback(failure, self)
    self:setDependentModInstallFailedCallback(failure, self)
    self:setAddedToDownloadCallback(function()
        -- upvalues: (ref) numToGo, (copy) finishCallback, (ref) numFailed
        numToGo = numToGo - 1
        if numToGo == 0 then
            finishCallback(numFailed)
        end
    end, self)
    for _, modId in ipairs(modIds) do
        if getModMetaAttributeBool(modId, "isUpdate") then
            self:update(modId)
        else
            self:install(modId)
        end
    end
end
function ModHubController:update(modId)
    if updateMod(modId) then
        local dependendMods = self:getDependentMods(modId)
        for _, dependendMod in ipairs(dependendMods) do
            if dependendMod.isUpdate and not updateMod(modId) then
                table.insert({}, dependendMod)
            end
        end
        self.addedToDownloadCallback()
    else
        self.modInstallFailedCallback()
    end
    if self.discSpaceChangedCallback ~= nil then
        self.discSpaceChangedCallback()
    end
end
function ModHubController:uninstall(modId)
    local hash = self:getModInfo(modId).hash
    if uninstallMod(modId) then
        self.hasChanges = true
        local mod = g_modManager:getModByFileHash(hash)
        if mod ~= nil then
            g_modManager:removeMod(mod)
        end
        self.uninstalledCallback()
    else
        self.uninstallFailedCallback()
    end
    if self.discSpaceChangedCallback ~= nil then
        self.discSpaceChangedCallback()
    end
end
function ModHubController:setUninstallFailedCallback(callback, target)
    function self.uninstallFailedCallback()
        -- upvalues: (copy) callback, (copy) target
        callback(target)
    end
end
function ModHubController:setUninstalledCallback(callback, target)
    function self.uninstalledCallback()
        -- upvalues: (copy) callback, (copy) target
        callback(target)
    end
end
function ModHubController:setDiscSpaceChangedCallback(callback, target)
    function self.discSpaceChangedCallback()
        -- upvalues: (copy) callback, (copy) target
        callback(target, getModFreeSpaceKb(), (getModUsedSpaceKb()))
    end
end
function ModHubController:vote(modId, value)
    -- upvalues: (copy) setModHubRatingLocal
    if not self.hasTriggedUUIDInEngine then
        getUniqueUserId()
        self.hasTriggedUUIDInEngine = true
    end
    setModHubRatingLocal(modId, value)
    if self.votedCallback ~= nil then
        self.votedCallback()
    end
end
function ModHubController:setVotedCallback(callback, target)
    function self.votedCallback()
        -- upvalues: (copy) callback, (copy) target
        callback(target)
    end
end
function ModHubController:getVote(modId)
    -- upvalues: (copy) getModHubRatingLocal
    if not self.hasTriggedUUIDInEngine then
        getUniqueUserId()
        self.hasTriggedUUIDInEngine = true
    end
    local ratingValue, httpReturnCode = getModHubRatingLocal(modId)
    return httpReturnCode == 0 and 0 or ratingValue
end
function ModHubController.setShowAllMods(_, showAll)
    setEnableBetaMods(showAll)
end
function ModHubController:searchMods(categoryId, text)
    local hits = string.lower(text)
    local hits = {}
    if categoryId == nil then
        for _, categories in ipairs(self.categories) do
            for _, category in ipairs(categories) do
                if self:isCategorySearchable(category) then
                    hits = self:searchInCategory(hits, category.id, hits)
                end
            end
        end
    else
        self:searchInCategory(hits, categoryId, hits)
    end
    local list = {}
    for categories, info in pairs(hits) do
        table.insert(list, info)
    end
    table.sort(list, function(a, b)
        return a[2] > b[2]
    end)
    for categories, info in ipairs(list) do
        list[categories] = info[1]
    end
    return list
end
function ModHubController.isCategorySearchable(_, category)
    return not category.isHidden or (category.name == "contest" or category.name == "dlc")
end
function ModHubController:searchInCategory(list, categoryId, text)
    local numOfMods = getNumOfMods(categoryId - 1)
    local postFix = self:getPostFix()
    if numOfMods > 0 then
        local i = 0
        for i = i, numOfMods - 1 do
            local modId = getModId(categoryId - 1, i)
            if list[modId] == nil then
                local hit = false
                local score = 0
                local title = getModMetaAttributeString(modId, "title_" .. postFix)
                local titleLower = utf8ToLower(title)
                local sStart, sEnd = string.find(titleLower, text, nil, true)
                if sStart == nil then
                    local author = getModMetaAttributeString(modId, "author")
                    local authorLower = utf8ToLower(author)
                    local sStart, sEnd = string.find(authorLower, text, nil, true)
                    if sStart ~= nil then
                        score = self:generateSearchScore(text, author, sStart, sEnd)
                        hit = true
                    end
                else
                    score = self:generateSearchScore(text, title, sStart, sEnd)
                    hit = true
                end
                if hit then
                    list[modId] = { self:getModInfo(modId), score }
                end
            end
        end
    end
    return list
end
function ModHubController.generateSearchScore(_, input, result, start, _)
    local resultLength = utf8Strlen(result)
    return 0.8 * (utf8Strlen(input) / resultLength) + 0.2 * (1 - start / resultLength)
end
function ModHubController:userProfileChanged()
    self.hasTriggedUUIDInEngine = false
    self:updateRecommendationSystem()
end
function ModHubController:updateRecommendationSystem()
    local usesHelpWindow = g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU)
    local isLastUsedCharacterMale = g_gameSettings:getValue(GameSettings.SETTING.LAST_PLAYER_STYLE_MALE)
    local playedMultiplayer = g_gameSettings:getValue(GameSettings.SETTING.PLAYED_MULTIPLAYER)
    local numTutorialsPlayed = math.floor(g_gameSettings:getValue(GameSettings.SETTING.TOTAL_PLAYED_SECONDS) / 3600)
    local totalPlayedHours = math.max(0, numTutorialsPlayed)
    local numTutorialsPlayed = g_gameSettings:getValue(GameSettings.SETTING.STARTED_GUIDED_TOUR) and 1 or 0
    setModDownloadManagerRecommenderParams(usesHelpWindow, playedMultiplayer, isLastUsedCharacterMale, totalPlayedHours, numTutorialsPlayed)
end