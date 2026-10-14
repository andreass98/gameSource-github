ConversationActionStartFromList = {}
ConversationActionStartFromList.NAME = "startConversationFromList"
local ConversationActionStartFromList_mt = Class(ConversationActionStartFromList)
function ConversationActionStartFromList.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".conversation(?)#uniqueId", "Unique id of the conversation", nil, true)
    schema:register(XMLValueType.STRING, basePath .. ".failConversation(?)#uniqueId", "Unique id of the fail conversation", nil, true)
end
function ConversationActionStartFromList.new(conversation, uniqueIds, failUniqueIds, customMt)
    -- upvalues: (copy) ConversationActionStartFromList_mt
    local self = setmetatable({}, customMt or ConversationActionStartFromList_mt)
    self.conversation = conversation
    self.uniqueIds = uniqueIds
    self.failUniqueIds = failUniqueIds
    return self
end
function ConversationActionStartFromList:run()
    local npc = self.conversation:getNPC()
    if npc == nil then
        Logging.error("ConversationActionStartFromList.run: No NPC set!")
        return false
    else
        local player = npc:getInteractingPlayer()
        if player == nil then
            Logging.error("ConversationActionStartFromList.run: No player set!")
            return false
        else
            local conversation = npc:getRandomConversationFromUniqueIds(player, self.uniqueIds)
            if conversation == nil then
                conversation = npc:getRandomConversationFromUniqueIds(player, self.failUniqueIds)
            end
            if conversation == nil then
                Logging.error("ConversationActionStartFromList.run: No conversation currently available for npc \'%s\'!", npc:getName())
                return false
            else
                if g_server ~= nil then
                    npc:setFollowUpConversation(conversation)
                end
                return true
            end
        end
    end
end
function ConversationActionStartFromList.createFromXML(xmlFile, key, conversation, _, _)
    local uniqueIds = {}
    for _, conversationKey in xmlFile:iterator(key .. ".conversation") do
        local uniqueId = xmlFile:getValue(conversationKey .. "#uniqueId")
        if uniqueId == nil then
            Logging.xmlWarning(xmlFile, "Missing \'uniqueId\' for \'%s\'", key)
            return nil
        end
        table.addElement(uniqueIds, uniqueId)
    end
    if #uniqueIds == 0 then
        return nil
    end
    local failUniqueIds = {}
    for conversationKey, uniqueId in xmlFile:iterator(key .. ".failConversation") do
        local uniqueId = xmlFile:getValue(uniqueId .. "#uniqueId")
        if uniqueId == nil then
            Logging.xmlWarning(xmlFile, "Missing \'uniqueId\' for \'%s\'", key)
            return nil
        end
        table.addElement(failUniqueIds, uniqueId)
    end
    return ConversationActionStartFromList.new(conversation, uniqueIds, failUniqueIds)
end
g_npcManager:registerConversationActionClass(ConversationActionStartFromList.NAME, ConversationActionStartFromList)