ConversationActionNavigateToNPC = {}
ConversationActionNavigateToNPC.NAME = "navigateToNPC"
local ConversationActionNavigateToNPC_mt = Class(ConversationActionNavigateToNPC)
function ConversationActionNavigateToNPC.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#npcName", "Name of the npc", nil, true)
end
function ConversationActionNavigateToNPC.new(npcName, customMt)
    -- upvalues: (copy) ConversationActionNavigateToNPC_mt
    local self = setmetatable({}, customMt or ConversationActionNavigateToNPC_mt)
    self.npcName = npcName
    return self
end
function ConversationActionNavigateToNPC:run()
    local npc = g_npcManager:getNPCByName(self.npcName)
    if npc == nil then
        Logging.error("ConversationActionNavigateToNPC.run: NPC \'%s\' not defined", self.npcName)
        return false
    end
    local mapHotspot = npc:getMapHotspot()
    if mapHotspot == nil then
        return false
    end
    g_currentMission:setMapTargetHotspot(mapHotspot)
    return true
end
function ConversationActionNavigateToNPC.createFromXML(xmlFile, key, _, _, _)
    local npcName = xmlFile:getValue(key .. "#npcName")
    if npcName ~= nil then
        return ConversationActionNavigateToNPC.new(npcName)
    end
    Logging.xmlWarning(xmlFile, "Missing \'npcName\' for \'%s\'", key)
    return nil
end
g_npcManager:registerConversationActionClass(ConversationActionNavigateToNPC.NAME, ConversationActionNavigateToNPC)