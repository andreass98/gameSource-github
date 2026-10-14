ConversationActionStartMissionSelection = {}
ConversationActionStartMissionSelection.NAME = "startMissionSelectionByType"
local ConversationActionStartMissionSelection_mt = Class(ConversationActionStartMissionSelection)
function ConversationActionStartMissionSelection.registerXMLPaths(schema, basePath)
    NPCConversationType.registerXMLPath(schema, basePath .. "#typeMissionAvailable", "Type of the conversation that should be started if missions are available", nil, true)
    NPCConversationType.registerXMLPath(schema, basePath .. "#typeMissionUnavailable", "Type of the conversation that should be started if no missions are available", nil, true)
end
function ConversationActionStartMissionSelection.new(conversation, typeMissionAvailable, typeMissionUnavailable, customMt)
    -- upvalues: (copy) ConversationActionStartMissionSelection_mt
    local self = setmetatable({}, customMt or ConversationActionStartMissionSelection_mt)
    self.conversation = conversation
    self.typeMissionAvailable = typeMissionAvailable
    self.typeMissionUnavailable = typeMissionUnavailable
    return self
end
function ConversationActionStartMissionSelection:run()
    local npc = self.conversation:getNPC()
    if npc == nil then
        Logging.error("ConversationActionStartMissionSelection.run: No NPC set!")
        return false
    end
    local isMissionReady = false
    local missions = g_missionManager:getMissions()
    for _, mission in ipairs(missions) do
        local missionNpc = mission:getNPC()
        local isSameNPC = false
        if missionNpc ~= nil then
            isSameNPC = missionNpc == npc
        end
        if isSameNPC and mission:getIsReadyToStart() then
            isMissionReady = true
            break
        end
    end
    local player = npc:getInteractingPlayer()
    if player == nil then
        Logging.error("ConversationActionStartMissionSelection.run: No player set!")
        return false
    end
    local nextConversation
    if isMissionReady then
        nextConversation = npc:getRandomConversation(player, self.typeMissionAvailable)
        if nextConversation == nil then
            Logging.error("ConversationActionStartMissionSelection.run: No conversation available of type \'%s\' for npc \'%s\'!", NPCConversationType.getName(self.typeMissionAvailable), npc:getName())
            return false
        end
    else
        nextConversation = npc:getRandomConversation(player, self.typeMissionUnavailable)
        if nextConversation == nil then
            Logging.error("ConversationActionStartMissionSelection.run: No conversation available of type \'%s\' for npc \'%s\'!", NPCConversationType.getName(self.typeMissionUnavailable), npc:getName())
            return false
        end
    end
    if g_server ~= nil then
        npc:setFollowUpConversation(nextConversation)
    end
    return true
end
function ConversationActionStartMissionSelection.createFromXML(xmlFile, key, conversation, _, _)
    local typeMissionAvailable = NPCConversationType.loadFromXMLFile(xmlFile, key .. "#typeMissionAvailable")
    if typeMissionAvailable == nil then
        Logging.xmlWarning(xmlFile, "NPCConversationType not defined for \'%s#typeMissionAvailable\'", key)
        return nil
    end
    local typeMissionUnavailable = NPCConversationType.loadFromXMLFile(xmlFile, key .. "#typeMissionUnavailable")
    if typeMissionUnavailable ~= nil then
        return ConversationActionStartMissionSelection.new(conversation, typeMissionAvailable, typeMissionUnavailable)
    end
    Logging.xmlWarning(xmlFile, "NPCConversationType not defined for \'%s#typeMissionUnavailable\'", key)
    return nil
end
g_npcManager:registerConversationActionClass(ConversationActionStartMissionSelection.NAME, ConversationActionStartMissionSelection)