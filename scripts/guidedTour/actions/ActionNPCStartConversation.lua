ActionNPCStartConversation = {}
ActionNPCStartConversation.NAME = "npcStartConversation"
local ActionNPCStartConversation_mt = Class(ActionNPCStartConversation)
function ActionNPCStartConversation.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#npc", "Name of the npc", nil, true)
    schema:register(XMLValueType.STRING, basePath, "Filename of the conversation", nil, true)
    schema:register(XMLValueType.BOOL, basePath .. "#isPhoneConversation", "If the conversation should is a phone conversation", nil, false)
end
function ActionNPCStartConversation.new(npcName, filename, isPhoneConversation, customMt)
    -- upvalues: (copy) ActionNPCStartConversation_mt
    local self = setmetatable({}, customMt or ActionNPCStartConversation_mt)
    self.npcName = npcName
    self.filename = filename
    self.isPhoneConversation = isPhoneConversation
    return self
end
function ActionNPCStartConversation:run(_, _)
    local npc = g_npcManager:getNPCByName(self.npcName)
    if npc == nil then
        Logging.warning("ActionNPCStartConversation.run: NPC \'%s\' not found", self.npcName)
        return false
    else
        local conversation = npc:getConversationByFilename(self.filename)
        if conversation == nil then
            Logging.warning("ActionNPCStartConversation.run: Conversation \'%s\' not defined for NPC \'%s\'", self.filename, self.npcName)
            return false
        else
            npc:startConversation(g_localPlayer, conversation, true, self.isPhoneConversation)
            return true
        end
    end
end
function ActionNPCStartConversation.createFromXML(xmlFile, key, _, _)
    local npcName = xmlFile:getValue(key .. "#npc")
    local filename = xmlFile:getValue(key)
    local isPhoneConversation = xmlFile:getValue(key .. "#isPhoneConversation", true)
    if npcName == nil or filename == nil then
        return nil
    else
        return ActionNPCStartConversation.new(npcName, filename, isPhoneConversation)
    end
end
g_guidedTourManager:registerActionClass(ActionNPCStartConversation.NAME, ActionNPCStartConversation)