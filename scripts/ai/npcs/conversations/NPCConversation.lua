NPCConversation = {}
local NPCConversation_mt = Class(NPCConversation)
g_xmlManager:addCreateSchemaFunction(function()
    NPCConversation.xmlSchema = XMLSchema.new("npcConversation")
end)
g_xmlManager:addInitSchemaFunction(function()
    local schema = NPCConversation.xmlSchema
    schema:register(XMLValueType.BOOL, "conversation.isActive", "If conversation is active", nil, false)
    schema:register(XMLValueType.STRING, "conversation.class", "Class name of the npc conversation controller", "NPCConversation", false)
    NPCConversationType.registerXMLPath(schema, "conversation.type", "Type of the conversation", "DEFAULT", false)
    schema:register(XMLValueType.INT, "conversation.probability", "Default probability of the conversation", 1, false)
    schema:register(XMLValueType.STRING, "conversation.textFlow#startId", "Start unique id of the conversation", nil, false)
    local prerequisiteClasses = g_npcManager:getAllConverationPrerequisiteClasses()
    for name, class in pairs(prerequisiteClasses) do
        class.registerXMLPaths(schema, string.format("conversation.prerequisites.%s(?)", name))
    end
    NPCConversationItem.registerXMLPaths(schema, "conversation.textFlow.item(?)")
end)
function NPCConversation.registerSavegameXMLPaths(xmlSchema, key)
    xmlSchema:register(XMLValueType.INT, key .. "#numTriggered", "How often this conversation was trigged")
    xmlSchema:register(XMLValueType.INT, key .. "#lastMonotonicDay", "Last ingame monotonic day since last occurrence")
    xmlSchema:register(XMLValueType.STRING, key .. "#lastDate", "Real date since last occurrence")
    local prerequisiteClasses = g_npcManager:getAllConverationPrerequisiteClasses()
    for name, class in pairs(prerequisiteClasses) do
        if class.registerSavegameXMLPaths ~= nil then
            class.registerSavegameXMLPaths(xmlSchema, string.format("%s.%s", key, name))
        end
    end
end
function NPCConversation.new(npc, uniqueId, customMt)
    -- upvalues: (copy) NPCConversation_mt
    local self = setmetatable({}, customMt or NPCConversation_mt)
    self.isActive = nil
    self.npc = npc
    self.uniqueId = uniqueId
    self.typeId = nil
    self.probability = 1
    self.index = 0
    self.conversationItems = {}
    self.idToConversationItem = {}
    self.isLoaded = false
    return self
end
function NPCConversation:load(xmlFilename)
    local xmlFile = XMLFile.load("NPCConversation", xmlFilename, NPCConversation.xmlSchema)
    if xmlFile == nil then
        return nil
    end
    local customEnv, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFile:getFilename())
    self.xmlFilename = xmlFilename
    self.baseDirectory = baseDirectory
    self.customEnvironment = customEnv
    self.isActive = xmlFile:getValue("conversation.isActive", nil)
    self.typeId = NPCConversationType.loadFromXMLFile(xmlFile, "conversation.type")
    if self.typeId == nil then
        Logging.xmlWarning(xmlFile, "Invalid converation type! Resetting to DEFAULT")
        self.typeId = NPCConversationType.DEFAULT
    end
    self.probability = xmlFile:getValue("conversation.probability", 1)
    if not self.isActive or self:loadPrerequisites(xmlFile) then
        xmlFile:delete()
        return true
    end
    Logging.xmlWarning(xmlFile, "Could not load prerequisites")
    xmlFile:delete()
    return false
end
function NPCConversation:loadPrerequisites(xmlFile)
    local prerequisiteClasses = g_npcManager:getAllConverationPrerequisiteClasses()
    for name, prerequisiteClass in pairs(prerequisiteClasses) do
        for _, prerequisiteKey in xmlFile:iterator("conversation.prerequisites." .. name) do
            local prerequisite = prerequisiteClass.createFromXML(xmlFile, prerequisiteKey, self, self.baseDirectory, self.customEnvironment)
            if prerequisite == nil then
                Logging.xmlWarning(xmlFile, "Could not create conversation prerequisite in \'%s\'", prerequisiteKey)
            else
                if self.prerequisites == nil then
                    self.prerequisites = {}
                end
                table.insert(self.prerequisites, prerequisite)
            end
        end
    end
    return true
end
function NPCConversation:loadTexts()
    if self.isLoaded then
        return
    else
        local xmlFile = XMLFile.load("NPCConversation", self.xmlFilename, NPCConversation.xmlSchema)
        if xmlFile == nil then
            return nil
        elseif self:loadConversationItems(xmlFile, "conversation.textFlow") then
            xmlFile:delete()
            self.isLoaded = true
            return true
        else
            Logging.xmlWarning(xmlFile, "Could not load textFlow")
            xmlFile:delete()
            return false
        end
    end
end
function NPCConversation:unloadTexts()
    for _, conversationItem in pairs(self.idToConversationItem) do
        conversationItem:delete()
    end
    self.idToConversationItem = {}
    self.conversationItems = {}
    self.isLoaded = false
end
function NPCConversation:loadConversationItems(xmlFile, key)
    for _, itemKey in xmlFile:iterator(key .. ".item") do
        local conversationItem = NPCConversationItem.new(self)
        if not conversationItem:loadFromXML(xmlFile, itemKey, self.baseDirectory, self.customEnvironment) then
            return false
        end
        local id = conversationItem:getId()
        if self.idToConversationItem[id] ~= nil then
            Logging.xmlWarning(xmlFile, "Item with id \'%s\' already exists in text flow for \'%s\'", id, itemKey)
            return false
        end
        self.idToConversationItem[id] = conversationItem
        table.insert(self.conversationItems, conversationItem)
        conversationItem:setIndex(#self.conversationItems)
        if self.startId == nil then
            self.startId = id
        end
    end
    local startId = xmlFile:getValue(key .. "#startId")
    if startId ~= nil then
        if self.idToConversationItem[startId] == nil then
            Logging.xmlWarning(xmlFile, "Given startId \'%s\' is not defined", startId)
        else
            self.startId = startId
        end
    end
    for itemKey, conversationItem in pairs(self.idToConversationItem) do
        if not conversationItem:validateXML(xmlFile) then
            return false
        end
    end
    return true
end
function NPCConversation:delete()
    self:unloadTexts()
end
function NPCConversation:getUniqueId()
    return self.uniqueId
end
function NPCConversation:setIndex(index)
    self.index = index
end
function NPCConversation:getIndex()
    return self.index
end
function NPCConversation:getType()
    return self.typeId
end
function NPCConversation:getNPC()
    return self.npc
end
function NPCConversation:getConversationItemById(id)
    return self.idToConversationItem[id]
end
function NPCConversation:getConversationItemByIndex(index)
    return self.conversationItems[index]
end
function NPCConversation:compare(conversation)
    return self:getWeight() < conversation:getWeight()
end
function NPCConversation:getWeight()
    return 1
end
function NPCConversation:getProbability()
    return self.probability
end
function NPCConversation:getIsAvailable(player, userData)
    if not self.isActive then
        return false
    end
    if self.prerequisites ~= nil then
        for _, prerequisite in ipairs(self.prerequisites) do
            if not prerequisite:getIsValid(player, userData) then
                return false
            end
        end
    end
    return true
end
function NPCConversation:getCanBeCanceled()
    return false
end
function NPCConversation:init(player) end
function NPCConversation:start(_, userData)
    assert(g_server ~= nil, "NPCConversation:start is a server only function")
    self:updateUserData(userData)
    if self.prerequisites ~= nil then
        for _, prerequisite in ipairs(self.prerequisites) do
            if prerequisite.onConversationStart ~= nil then
                prerequisite:onConversationStart()
            end
        end
    end
end
function NPCConversation:reset()
    self:unloadTexts()
end
function NPCConversation:updateUserData(userData)
    userData.lastTriggedMonotonicDay = g_currentMission.environment.currentMonotonicDay
    userData.lastTriggedDate = getDate("%Y/%m/%d %H:%M")
    userData.numTriggered = (userData.numTriggered or 0) + 1
    if self.prerequisites ~= nil then
        for _, prerequisite in ipairs(self.prerequisites) do
            if prerequisite.updateUserData ~= nil then
                local prerequisiteData = userData[prerequisite.NAME] or {}
                prerequisite:updateUserData(prerequisiteData)
                if next(prerequisiteData) ~= nil then
                    userData[prerequisite.NAME] = prerequisiteData
                end
            end
        end
    end
end
function NPCConversation:saveToSavegameXMLFile(xmlFile, key, userData)
    if userData.numTriggered ~= nil then
        xmlFile:setValue(key .. "#numTriggered", userData.numTriggered)
    end
    if userData.lastTriggedMonotonicDay ~= nil then
        xmlFile:setValue(key .. "#lastMonotonicDay", userData.lastTriggedMonotonicDay)
    end
    if userData.lastTriggedDate ~= nil then
        xmlFile:setValue(key .. "#lastDate", userData.lastTriggedDate)
    end
    if self.prerequisites ~= nil then
        for _, prerequisite in ipairs(self.prerequisites) do
            if prerequisite.saveToSavegameXMLFile ~= nil then
                prerequisite:saveToSavegameXMLFile(xmlFile, string.format("%s.%s", key, prerequisite.NAME), userData[prerequisite.NAME])
            end
        end
    end
end
function NPCConversation:loadFromSavegameXMLFile(xmlFile, key, userData)
    userData.numTriggered = xmlFile:getValue(key .. "#numTriggered")
    userData.lastTriggedMonotonicDay = xmlFile:getValue(key .. "#lastMonotonicDay")
    userData.lastTriggedDate = xmlFile:getValue(key .. "#lastDate")
    if self.prerequisites ~= nil then
        for _, prerequisite in ipairs(self.prerequisites) do
            if prerequisite.loadFromSavegameXMLFile ~= nil then
                local prerequisiteData = {}
                prerequisite:loadFromSavegameXMLFile(xmlFile, string.format("%s.%s", key, prerequisite.NAME), prerequisiteData)
                if next(prerequisiteData) ~= nil then
                    userData[prerequisite.NAME] = prerequisiteData
                end
            end
        end
    end
end
function NPCConversation:getHasUserData()
    return next(self.userData) ~= nil
end
function NPCConversation:validate()
    self:loadTexts()
    for _, item in ipairs(self.conversationItems) do
        item:validate()
    end
    self:unloadTexts()
end