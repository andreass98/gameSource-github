NPCConversationGuidedTour = {}
local NPCConversationGuidedTour_mt = Class(NPCConversationGuidedTour, NPCConversation)
function NPCConversationGuidedTour.new(npc, uniqueId, customMt)
    -- upvalues: (copy) NPCConversationGuidedTour_mt
    return NPCConversation.new(npc, uniqueId, customMt or NPCConversationGuidedTour_mt)
end
function NPCConversationGuidedTour:updateUserData(userData) end
function NPCConversationGuidedTour:saveToSavegameXMLFile(xmlFile, key, userData) end
function NPCConversationGuidedTour:loadFromSavegameXMLFile(xmlFile, key, userData) end
function NPCConversationGuidedTour:getCanBeCanceled()
    return false
end