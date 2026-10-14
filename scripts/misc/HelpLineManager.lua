HelpLineManager = {}
HelpLineManager.helpLineXMLSchema = nil
source("dataS/scripts/misc/HelpLineActivatable.lua")
local HelpLineManager_mt = Class(HelpLineManager, AbstractManager)
HelpLineManager.ITEM_TYPE = {
    ["TEXT"] = "text",
    ["IMAGE"] = "image"
}
HelpLineManager.SLICE_PREFIX = "helpline"
HelpLineManager.CUSTOMENV_BASEGAME = ""
function HelpLineManager.new(customMt)
    -- upvalues: (copy) HelpLineManager_mt
    local self = AbstractManager.new(customMt or HelpLineManager_mt)
    HelpLineManager.helpLineXMLSchema = XMLSchema.new("helpLine")
    HelpLineManager.registerHelplineXMLPaths(HelpLineManager.helpLineXMLSchema)
    return self
end
function HelpLineManager.registerCategoryXMLPaths(schema, basePath)
    schema:register(XMLValueType.L10N_STRING, basePath .. "#title", "category title l10n key")
    schema:register(XMLValueType.L10N_STRING, basePath .. ".page(?)#title", "page title l10n key")
    schema:register(XMLValueType.STRING, basePath .. ".page(?)#id", "page title l10n key")
    schema:register(XMLValueType.FILENAME, basePath .. ".page(?)#iconFilename", "page icon filepath")
    schema:register(XMLValueType.STRING, basePath .. ".page(?)#iconSliceId", "page icon slice id")
    schema:register(XMLValueType.BOOL, basePath .. ".page(?).paragraph(?)#noSpacing", "")
    schema:register(XMLValueType.L10N_STRING, basePath .. ".page(?).paragraph(?).title#text", "paragraph title l10n key")
    schema:register(XMLValueType.L10N_STRING, basePath .. ".page(?).paragraph(?).text#text", "paragraph text l10n key")
    schema:register(XMLValueType.BOOL, basePath .. ".page(?).paragraph(?).text#alignToImage", "")
    schema:register(XMLValueType.FILENAME, basePath .. ".page(?).paragraph(?).image#filename", "paragraph image filepath")
    schema:register(XMLValueType.STRING_LIST, basePath .. ".page(?).paragraph(?).image#uvs", "image uvs")
    schema:register(XMLValueType.VECTOR_2, basePath .. ".page(?).paragraph(?).image#size", "image size", "1024 1024")
    schema:register(XMLValueType.STRING, basePath .. ".page(?).paragraph(?).image#displaySize", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".page(?).paragraph(?).image#heightScale", "", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".page(?).paragraph(?).image#aspectRatio", "", 1)
end
function HelpLineManager.registerHelplineXMLPaths(schema)
    HelpLineManager.registerCategoryXMLPaths(schema, "helpLines.category(?)")
end
function HelpLineManager:initDataStructures()
    self.customEnvironmentNames = { HelpLineManager.CUSTOMENV_BASEGAME }
    self.customEnvironmentToCategory = {}
    self.customEnvironmentToCategory[HelpLineManager.CUSTOMENV_BASEGAME] = {}
    self.idToCategoryPageIndex = {}
    self.categoryNames = {}
    self.triggers = {}
    self.triggerNodeToData = {}
    self.zones = {}
    self.sharedLoadingIds = {}
    self.helpData = nil
    self.idToIndices = {}
end
function HelpLineManager:loadMapData(xmlFile, missionInfo)
    HelpLineManager:superClass().loadMapData(self)
    local filenameStr = getXMLString(xmlFile, "map.helpline#filename")
    if filenameStr == nil then
        Logging.xmlInfo(xmlFile, "No helpline defined for map")
        return false
    end
    local filename = Utils.getFilename(filenameStr, g_currentMission.baseDirectory)
    if filename == nil or (filename == "" or not fileExists(filename)) then
        Logging.xmlError(xmlFile, "Could not load helpline config file \'" .. tostring(filenameStr) .. "\'!")
        return false
    end
    self:loadFromXML(filename, missionInfo)
    local additionalFilename = getXMLString(xmlFile, "map.helpline#additionalFilename")
    if additionalFilename ~= nil then
        self:loadFromXML(Utils.getFilename(additionalFilename, g_currentMission.baseDirectory), missionInfo)
    end
    for customEnvironment, categories in pairs(self.customEnvironmentToCategory) do
        local prefix = ""
        if not string.isNilOrWhitespace(customEnvironment) then
            prefix = customEnvironment .. "."
        end
        for categoryIndex, category in ipairs(categories) do
            local categoryId = category.id
            if categoryId ~= nil then
                local categoryId = prefix .. categoryId
                if self.idToCategoryPageIndex[categoryId] == nil then
                    self.idToCategoryPageIndex[categoryId] = {
                        ["customEnvironment"] = customEnvironment,
                        ["categoryIndex"] = categoryIndex,
                        ["pageIndex"] = 0
                    }
                else
                    Logging.xmlWarning(xmlFile, "Category Id \'%s\' already used. Ignoring id for category name \'%s\'!", categoryId, category.title)
                end
            end
            for pageIndex, page in ipairs(category.pages) do
                local pageId = page.id
                if pageId ~= nil then
                    local pageId = prefix .. pageId
                    if self.idToCategoryPageIndex[pageId] == nil then
                        self.idToCategoryPageIndex[pageId] = {
                            ["customEnvironment"] = customEnvironment,
                            ["categoryIndex"] = categoryIndex,
                            ["pageIndex"] = pageIndex
                        }
                    else
                        Logging.xmlWarning(xmlFile, "Page Id \'%s\' already used. Ignoring id for page name \'%s\'!", pageId, page.title)
                    end
                end
            end
        end
    end
    local xmlObject = XMLFile.wrap(xmlFile, nil)
    for prefix, key in xmlObject:iterator("map.helpline.trigger") do
        local position = xmlObject:getVector(key .. "#position", nil, 3)
        if position == nil then
            Logging.xmlWarning(xmlObject, "Missing helpline trigger position for \'%s\'", key)
        else
            local categoryIndex, categoryIndex, category = (function(xmlObj, key)
                -- upvalues: (copy) self
                local mapXMLFilename = xmlObj:getFilename()
                local customEnvironment, _ = Utils.getModNameAndBaseDirectory(mapXMLFilename)
                local helpId = xmlObj:getString(key .. "#helpId")
                if helpId ~= nil then
                    local data = self.idToCategoryPageIndex[helpId]
                    if data == nil and customEnvironment ~= nil then
                        data = self.idToCategoryPageIndex[customEnvironment .. "." .. helpId]
                    end
                    if data ~= nil then
                        return data.categoryIndex, data.pageIndex, customEnvironment
                    end
                    Logging.xmlWarning(xmlObj, "No help line item defined for helpId \'%s\'", helpId)
                    return 1, 1
                end
                local modId = xmlObj:getString(key .. "#categoryId")
                if modId == nil then
                    return xmlObj:getInt(key .. "#categoryIndex", 1), xmlObj:getInt(key .. "#pageIndex", 1), customEnvironment
                end
                local data = self.idToCategoryPageIndex[modId]
                if data == nil and customEnvironment ~= nil then
                    data = self.idToCategoryPageIndex[customEnvironment .. "." .. modId]
                end
                if data ~= nil then
                    return data.categoryIndex, data.pageIndex, customEnvironment
                end
                Logging.xmlWarning(xmlObj, "No help line item defined for categoryId \'%s\'", modId)
                return 1, 1
            end)(xmlObject, key)
            local categories = self.customEnvironmentToCategory[category]
            if categories == nil then
                Logging.xmlWarning(xmlObject, "No categories found for custom environment \'%s\' for \'%s\'", category, key)
            else
                local category = categories[({
                    ["position"] = position,
                    ["categoryIndex"] = categoryIndex,
                    ["pageIndex"] = categoryIndex
                }).categoryIndex]
                if category == nil then
                    Logging.xmlWarning(xmlObject, "Invalid helpline trigger category index \'%d\' for \'%s\'", categoryIndex, key)
                elseif category.pages[categoryId.pageIndex] == nil then
                    Logging.xmlWarning(xmlObject, "Invalid helpline trigger page index \'%d\' for category \'%d\' for \'%s\'", categoryId.pageIndex, categoryIndex, key)
                else
                    local pageIndex = g_i3DManager:loadSharedI3DFileAsync("data/objects/helpIcon/icon.i3d", false, false, HelpLineManager.onIconLoaded, self, categoryId)
                    table.insert(self.sharedLoadingIds, pageIndex)
                end
            end
        end
    end
    for prefix, key in xmlObject:iterator("map.helpline.zone") do
        local position = xmlObject:getVector(key .. "#position", nil, 3)
        if position ~= nil then
            local categoryIndex, categoryIndex, category = getCategoryAndPageIndex(xmlObject, key)
            local categoryId = {
                ["position"] = position,
                ["radius"] = xmlObject:getFloat(key .. "#radius", 50),
                ["categoryIndex"] = categoryIndex,
                ["pageIndex"] = categoryIndex,
                ["customEnvironment"] = category
            }
            table.insert(self.zones, categoryId)
        end
    end
    xmlObject:delete()
    self.activatable = HelpLineActivatable.new()
    return true
end
function HelpLineManager:unloadMapData()
    self.helpData = nil
    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    for _, sharedLoadingId in ipairs(self.sharedLoadingIds) do
        g_i3DManager:releaseSharedI3DFile(sharedLoadingId)
    end
    for _, sharedLoadingId in ipairs(self.triggers) do
        g_currentMission:removeHelpTrigger(sharedLoadingId.node)
        removeTrigger(sharedLoadingId.triggerNode)
        delete(sharedLoadingId.node)
    end
    HelpLineManager:superClass().unloadMapData(self)
end
function HelpLineManager:onIconLoaded(i3dNode, _, trigger)
    if i3dNode ~= 0 then
        trigger.node = i3dNode
        trigger.triggerNode = getChildAt(getChildAt(i3dNode, 0), 0)
        self.triggerNodeToData[trigger.triggerNode] = trigger
        link(getRootNode(), i3dNode)
        addTrigger(trigger.triggerNode, "onIconTrigger", self)
        setWorldTranslation(i3dNode, trigger.position[1], trigger.position[2], trigger.position[3])
        addToPhysics(i3dNode)
        table.insert(self.triggers, trigger)
        g_currentMission:addHelpTrigger(trigger.node)
    end
end
function HelpLineManager:onIconTrigger(triggerId, _, onEnter, onLeave, _)
    local data = self.triggerNodeToData[triggerId]
    if data ~= nil then
        if onEnter then
            self.helpData = data
            g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
            return
        end
        if onLeave then
            self.helpData = nil
            g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
        end
    end
end
function HelpLineManager:loadFromXML(filename, missionInfo)
    local customEnvironment, baseDirectory = Utils.getModNameAndBaseDirectory(filename)
    local xmlFile = XMLFile.load("helpLineViewContentXML", filename)
    if xmlFile ~= nil then
        for _, key in xmlFile:iterator("helpLines.category") do
            local category = self:loadCategory(xmlFile, key, missionInfo, customEnvironment, baseDirectory)
            if category ~= nil then
                customEnvironment = customEnvironment or HelpLineManager.CUSTOMENV_BASEGAME
                local categories = self.customEnvironmentToCategory[customEnvironment]
                if categories == nil then
                    self.customEnvironmentToCategory[customEnvironment] = {}
                    table.insert(self.customEnvironmentNames, customEnvironment)
                end
                table.insert(categories, category)
            end
        end
        xmlFile:delete()
    end
end
function HelpLineManager:addModCategory(xmlFile, key, baseDirectory, customEnvironment)
    local category = self:loadCategory(xmlFile, key, nil, customEnvironment, baseDirectory)
    if category ~= nil then
        local categories = self.customEnvironmentToCategory[customEnvironment]
        if categories == nil then
            self.customEnvironmentToCategory[customEnvironment] = {}
            table.insert(self.customEnvironmentNames, customEnvironment)
        end
        table.insert(categories, category)
    end
end
function HelpLineManager:loadCategory(xmlFile, key, missionInfo, customEnvironment, baseDirectory)
    local category = {
        ["title"] = xmlFile:getString(key .. "#title"),
        ["customEnvironment"] = customEnvironment,
        ["pages"] = {}
    }
    local id = xmlFile:getString(key .. "#id")
    if id ~= nil then
        if not string.isNilOrWhitespace(customEnvironment) then
        end
        category.id = id
    end
    for _, pageKey in xmlFile:iterator(key .. ".page") do
        local page = self:loadPage(xmlFile, pageKey, missionInfo, customEnvironment, baseDirectory)
        table.insert(category.pages, page)
    end
    return category
end
function HelpLineManager.loadPage(_, xmlFile, key, _, customEnvironment, baseDirectory)
    local page = {
        ["title"] = xmlFile:getString(key .. "#title"),
        ["customEnvironment"] = customEnvironment,
        ["baseDirectory"] = baseDirectory,
        ["iconFilename"] = xmlFile:getString(key .. "#iconFilename")
    }
    local iconSliceId = xmlFile:getString(key .. "#iconSliceId")
    if iconSliceId ~= nil and iconSliceId ~= "" then
        if not string.contains(iconSliceId, "%.") then
        end
        page.iconSliceId = iconSliceId
    end
    local id = xmlFile:getString(key .. "#id")
    if id ~= nil then
        if customEnvironment ~= nil then
        end
        page.id = id
    end
    page.paragraphs = {}
    for _, paragraphKey in xmlFile:iterator(key .. ".paragraph") do
        local paragraph = {
            ["title"] = xmlFile:getString(paragraphKey .. ".title#text"),
            ["text"] = xmlFile:getString(paragraphKey .. ".text#text"),
            ["alignToImage"] = xmlFile:getBool(paragraphKey .. ".text#alignToImage"),
            ["customEnvironment"] = customEnvironment,
            ["noSpacing"] = xmlFile:getBool(paragraphKey .. "#noSpacing")
        }
        local filename = xmlFile:getString(paragraphKey .. ".image#filename")
        if filename ~= nil then
            local heightScale = xmlFile:getFloat(paragraphKey .. ".image#heightScale", 1)
            local aspectRatio = xmlFile:getFloat(paragraphKey .. ".image#aspectRatio", 1)
            local size = string.getVector(xmlFile:getString(paragraphKey .. ".image#size"), 2) or { 1024, 1024 }
            paragraph.image = {
                ["filename"] = filename,
                ["uvs"] = GuiUtils.getUVs(xmlFile:getString(paragraphKey .. ".image#uvs", "0 0 1 1"), size),
                ["size"] = size,
                ["heightScale"] = heightScale,
                ["aspectRatio"] = aspectRatio,
                ["displaySize"] = GuiUtils.getNormalizedScreenValues(xmlFile:getString(paragraphKey .. ".image#displaySize"))
            }
        end
        local aspectRatio = page.paragraphs
        table.insert(aspectRatio, paragraph)
    end
    return page
end
function HelpLineManager.convertText(_, text, customEnv)
    local translated = g_i18n:convertText(text, customEnv)
    return string.gsub(translated, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
end
function HelpLineManager:getCategories(customEnvironment)
    return self.customEnvironmentToCategory[customEnvironment or HelpLineManager.CUSTOMENV_BASEGAME]
end
function HelpLineManager:getCustomEnvironmentNames()
    return self.customEnvironmentNames
end
function HelpLineManager:getCategory(customEnvironment, categoryIndex)
    if categoryIndex == nil then
        return nil
    else
        local categories = customEnvironment or HelpLineManager.CUSTOMENV_BASEGAME
        local categories = self.customEnvironmentToCategory[categories]
        if categories == nil then
            return nil
        else
            return categories[categoryIndex]
        end
    end
end
function HelpLineManager:getContextBasedHelp(x, y, z)
    local categoryIndex = nil
    local pageIndex = nil
    for _, zone in ipairs(self.zones) do
        local a, b, c = unpack(zone.position)
        local distance = MathUtil.vector3Length(a - x, b - y, c - z)
        if distance <= zone.radius and distance < math.huge then
            categoryIndex = zone.categoryIndex
            pageIndex = zone.pageIndex
        end
    end
    return categoryIndex, pageIndex
end
function HelpLineManager:getIsContextBasedHelpAvailable(x, y, z)
    local categoryIndex, _ = self:getContextBasedHelp(x, y, z)
    return categoryIndex ~= nil
end
function HelpLineManager:openContextBasedHelp(x, y, z)
    local categoryIndex, pageIndex = self:getContextBasedHelp(x, y, z)
    g_gui:showGui("InGameMenu")
    g_messageCenter:publish(MessageType.GUI_INGAME_OPEN_HELP_SCREEN, categoryIndex, pageIndex)
end
g_helpLineManager = HelpLineManager.new()