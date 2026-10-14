NPCConversationItem = {}
local NPCConversationItem_mt = Class(NPCConversationItem)
function NPCConversationItem.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#id", "Unique id of the conversation text flow item", nil, true)
    schema:register(XMLValueType.BOOL, basePath .. "#isActive", "If the item is active", nil, false)
    schema:register(XMLValueType.STRING, basePath .. "#nextId", "Unique id of the next converstion flow item", nil, false)
    schema:register(XMLValueType.STRING, basePath .. "#animationType", "Name of the animation that should be played", nil, false)
    schema:register(XMLValueType.STRING, basePath .. ".text", "Path to the conversation text flow item text", nil, true)
    local optionPath = basePath .. ".next.option(?)"
    local actionClasses = g_npcManager:getAllConverationActionClasses()
    for name, class in pairs(actionClasses) do
        class.registerXMLPaths(schema, string.format("%s.actions.%s(?)", basePath, name))
        class.registerXMLPaths(schema, string.format("%s.actions.%s(?)", optionPath, name))
    end
    local inputClasses = g_npcManager:getAllConverationInputClasses()
    for class, class in pairs(inputClasses) do
        class.registerXMLPaths(schema, string.format("%s.inputs.%s(?)", basePath, class))
        class.registerXMLPaths(schema, string.format("%s.inputs.%s(?)", optionPath, class))
    end
    local optionPrerequisiteClasses = g_npcManager:getAllConverationOptionPrerequisiteClasses()
    for class, class in pairs(optionPrerequisiteClasses) do
        class.registerXMLPaths(schema, string.format("%s.prerequisites.%s(?)", optionPath, class))
    end
    schema:register(XMLValueType.STRING, optionPath .. "#id", "Unique id of the conversation flow item. Used for Dialog Editor only", nil, true)
    schema:register(XMLValueType.BOOL, optionPath .. "#isActive", "If the item is active. Used for Dialog Editor only", nil, false)
    schema:register(XMLValueType.STRING, optionPath .. "#nextId", "Unique id of the next converstion flow item", nil, false)
    schema:register(XMLValueType.STRING, optionPath .. ".text", "Path to the conversation text flow item option text", nil, true)
end
function NPCConversationItem.new(conversation, customMt)
    -- upvalues: (copy) NPCConversationItem_mt
    local self = setmetatable({}, customMt or NPCConversationItem_mt)
    self.conversation = conversation
    self.index = 0
    self.id = nil
    self.text = nil
    self.nextId = nil
    self.options = nil
    self.actions = nil
    return self
end
function NPCConversationItem:loadFromXML(xmlFile, key, baseDirectory, customEnvironment)
    self.id = xmlFile:getValue(key .. "#id")
    if self.id == nil then
        Logging.xmlWarning(xmlFile, "Missing id for npc conversation item \'%s\'", key)
        return false
    end
    local path = xmlFile:getValue(key .. ".text")
    if path == nil then
        Logging.xmlWarning(xmlFile, "Missing text element for npc conversation item \'%s\'", key)
        return false
    end
    local animationTypeName = xmlFile:getValue(key .. "#animationType")
    if animationTypeName ~= nil then
        if NPCAnimationType.getByName(animationTypeName) == nil then
            Logging.xmlWarning(xmlFile, "Animation type \'%s\' not defined for npc conversation item \'%s\'", key)
        else
            self.animationType = animationTypeName
        end
    end
    local animationType = Utils.getFilename(path, baseDirectory)
    self.isActive = xmlFile:getValue(key .. "#isActive", true)
    self.text = NPCUtil.createTextFromPath(animationType, false, self.isActive)
    if self.text == nil then
        Logging.xmlWarning(xmlFile, "Could not create text for npc conversation item \'%s\'", key)
        return false
    end
    for _, optionKey in xmlFile:iterator(key .. ".next.option") do
        local nextId = xmlFile:getValue(optionKey .. "#nextId")
        local isActive = xmlFile:getValue(optionKey .. "#isActive", true)
        local optionPath = xmlFile:getValue(optionKey .. ".text")
        if optionPath == nil then
            Logging.xmlWarning(xmlFile, "Missing text element for npc conversation item option \'%s\'", optionKey)
            return false
        end
        local fullOptionPath = Utils.getFilename(optionPath, baseDirectory)
        local optionText = NPCUtil.createTextFromPath(fullOptionPath, true, isActive)
        if optionText == nil then
            Logging.xmlWarning(xmlFile, "Could not create text for npc conversation item option \'%s\'", optionKey)
            return false
        end
        local option = {
            ["nextId"] = nextId,
            ["isActive"] = isActive,
            ["text"] = optionText,
            ["inputs"] = NPCUtil.loadInputsFromXMLFile(xmlFile, optionKey, self.conversation, baseDirectory, customEnvironment),
            ["actions"] = NPCUtil.loadActionsFromXMLFile(xmlFile, optionKey, self.conversation, baseDirectory, customEnvironment),
            ["prerequisites"] = NPCUtil.loadOptionPrerequisitesFromXMLFile(xmlFile, optionKey, self.conversation, baseDirectory, customEnvironment)
        }
        if self.options == nil then
            self.options = {}
        end
        table.insert(self.options, option)
    end
    if self.options == nil or #self.options == 0 then
        self.nextId = xmlFile:getValue(key .. "#nextId")
    end
    self.inputs = NPCUtil.loadInputsFromXMLFile(xmlFile, key, self.conversation, baseDirectory, customEnvironment)
    self.actions = NPCUtil.loadActionsFromXMLFile(xmlFile, key, self.conversation, baseDirectory, customEnvironment)
    return true
end
function NPCConversationItem:delete()
    self.text:delete()
    if self.options ~= nil then
        for _, option in ipairs(self.options) do
            option.text:delete()
        end
    end
end
function NPCConversationItem:init()
    self.text:init()
    if self.options ~= nil then
        for _, option in ipairs(self.options) do
            option.text:init()
        end
    end
end
function NPCConversationItem:reset()
    self.text:reset()
    if self.options ~= nil then
        for _, option in ipairs(self.options) do
            option.text:reset()
        end
    end
end
function NPCConversationItem:activate()
    if self.inputs ~= nil then
        for _, input in ipairs(self.inputs) do
            input:run()
        end
    end
    if self.actions ~= nil then
        for _, input in ipairs(self.actions) do
            input:run()
        end
    end
end
function NPCConversationItem:activateOption(index)
    if self.options == nil then
        Logging.devWarning("Cannot activate conversation item option. No options available!")
        return
    elseif index == nil then
        Logging.devWarning("Cannot activate conversation item option. Invalid option index \'%s\'!", index)
        return
    elseif self.options[index].isActive then
        if option.inputs ~= nil then
            for _, input in ipairs(option.inputs) do
                input:run()
            end
        end
        if option.actions ~= nil then
            for _, input in ipairs(option.actions) do
                input:run()
            end
        end
    else
        Logging.devWarning("Cannot activate conversation item option \'%s\'. Option is inactive!", index)
    end
end
function NPCConversationItem:getId()
    return self.id
end
function NPCConversationItem:setIndex(index)
    self.index = index
end
function NPCConversationItem:getIndex()
    return self.index
end
function NPCConversationItem:getIsActive()
    return self.isActive
end
function NPCConversationItem:getText()
    return self.text
end
function NPCConversationItem:getOptions()
    return self.options
end
function NPCConversationItem:getNextId()
    return self.nextId
end
function NPCConversationItem:getOptionByIndex(index)
    if self.options == nil then
        return nil
    else
        return self.options[index]
    end
end
function NPCConversationItem:validateXML(xmlFile)
    if self.nextId == nil or self.conversation:getConversationItemById(self.nextId) ~= nil then
        if self.options ~= nil then
            for k, option in ipairs(self.options) do
                if option.nextId ~= nil and self.conversation:getConversationItemById(option.nextId) == nil then
                    Logging.xmlWarning(xmlFile, "NextId \'%s\' of npc conversation item \'%s\' option \'%d\' not defined!", option.nextId, self.id, k)
                    return false
                end
            end
        end
        return true
    else
        Logging.xmlWarning(xmlFile, "NextId \'%s\' of npc conversation item \'%s\' not defined!", self.nextId, self.id)
        return false
    end
end
function NPCConversationItem:validate()
    self:init()
    self:reset()
end