ConversationActionStartById = {}
ConversationActionStartById.NAME = "startConversationById"
local ConversationActionStartById_mt = Class(ConversationActionStartById)
function ConversationActionStartById.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#uniqueId", "Unique id of the conversation", nil, true)
end
function ConversationActionStartById.new(conversation, uniqueId, customMt)
    -- upvalues: (copy) ConversationActionStartById_mt
    local self = setmetatable({}, customMt or ConversationActionStartById_mt)
    self.conversation = conversation
    self.uniqueId = uniqueId
    return self
end
function ConversationActionStartById:run()
    local npc = self.conversation:getNPC()
    if npc == nil then
        Logging.error("ConversationActionStartById.run: No NPC set!")
        return false
    else
        local conversation = npc:getConversationById(self.uniqueId)
        if conversation == nil then
            Logging.error("ConversationActionStartById.run: No conversation with unique id \'%s\' defined for npc \'%s\'!", self.uniqueId, npc:getName())
            return false
        else
            if g_server ~= nil then
                npc:setFollowUpConversation(conversation)
            end
            return true
        end
    end
end
function ConversationActionStartById.createFromXML(xmlFile, key, conversation, _, _)
    local uniqueId = xmlFile:getValue(key .. "#uniqueId")
    if uniqueId ~= nil then
        return ConversationActionStartById.new(conversation, uniqueId)
    end
    Logging.xmlWarning(xmlFile, "Missing \'uniqueId\' for \'%s\'", key)
    return nil
end
g_npcManager:registerConversationActionClass(ConversationActionStartById.NAME, ConversationActionStartById)