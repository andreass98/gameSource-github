ConversationPrerequisiteRetriggerTypeDelayIngameDays = {}
ConversationPrerequisiteRetriggerTypeDelayIngameDays.NAME = "retriggerTypeDelayIngameDays"
local ConversationPrerequisiteRetriggerTypeDelayIngameDays_mt = Class(ConversationPrerequisiteRetriggerTypeDelayIngameDays)
function ConversationPrerequisiteRetriggerTypeDelayIngameDays.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#minDays", "Min number of ingame days since last occurrence", 0, false)
    NPCConversationType.registerXMLPath(schema, basePath .. "#type", "Type of the conversation", nil, true)
end
function ConversationPrerequisiteRetriggerTypeDelayIngameDays.new(conversation, typeId, minIngameDays, customMt)
    -- upvalues: (copy) ConversationPrerequisiteRetriggerTypeDelayIngameDays_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteRetriggerTypeDelayIngameDays_mt)
    self.typeId = typeId
    self.conversation = conversation
    self.minIngameDays = minIngameDays
    return self
end
function ConversationPrerequisiteRetriggerTypeDelayIngameDays:getIsValid(player, _)
    local npc = self.conversation:getNPC()
    if npc == nil then
        Logging.error("ConversationPrerequisiteRetriggerTypeDelayIngameDays.run: No NPC set!")
        return false
    end
    local conversations = npc.typeToConversations[self.typeId]
    if conversations == nil then
        Logging.error("ConversationPrerequisiteRetriggerTypeDelayIngameDays.run: No conversations for type defined!")
        return false
    end
    local playerUserData = npc.userData[player:getUniqueUserId()]
    if playerUserData == nil then
        return true
    end
    local wasTriggered = false
    for _, conversation in ipairs(conversations) do
        local conversationData = playerUserData.conversations[conversation:getUniqueId()]
        if conversationData ~= nil then
            local lastMonotonicDay = conversationData.lastTriggedMonotonicDay
            if lastMonotonicDay ~= nil and g_currentMission.environment.currentMonotonicDay - lastMonotonicDay < self.minIngameDays then
                wasTriggered = true
                break
            end
        end
    end
    return not wasTriggered
end
function ConversationPrerequisiteRetriggerTypeDelayIngameDays.createFromXML(xmlFile, key, conversation, _, _)
    local minIngameDays = xmlFile:getValue(key .. "#minDays", 0)
    if minIngameDays < 0 then
        Logging.xmlWarning(xmlFile, "Min number of ingame days may not be smaller than 0 for \'%s\'", key)
        return nil
    end
    local typeId = NPCConversationType.loadFromXMLFile(xmlFile, key .. "#type")
    if typeId ~= nil then
        return ConversationPrerequisiteRetriggerTypeDelayIngameDays.new(conversation, typeId, minIngameDays)
    end
    Logging.xmlWarning(xmlFile, "NPCConversationType not defined for \'%s\'", key)
    return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteRetriggerTypeDelayIngameDays.NAME, ConversationPrerequisiteRetriggerTypeDelayIngameDays)