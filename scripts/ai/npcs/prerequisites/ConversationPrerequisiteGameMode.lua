ConversationPrerequisiteGameMode = {}
ConversationPrerequisiteGameMode.NAME = "gameMode"
local ConversationPrerequisiteGameMode_mt = Class(ConversationPrerequisiteGameMode)
function ConversationPrerequisiteGameMode.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. "#singleplayer", "Is available in singleplayer", true, false)
    schema:register(XMLValueType.BOOL, basePath .. "#multiplayer", "Is available in multiplayer", true, false)
end
function ConversationPrerequisiteGameMode.new(singleplayer, multiplayer, customMt)
    -- upvalues: (copy) ConversationPrerequisiteGameMode_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteGameMode_mt)
    self.singleplayer = singleplayer
    self.multiplayer = multiplayer
    return self
end
function ConversationPrerequisiteGameMode:getIsValid(_, _)
    if g_currentMission.missionDynamicInfo.isMultiplayer then
        return self.multiplayer
    else
        return self.singleplayer
    end
end
function ConversationPrerequisiteGameMode.createFromXML(xmlFile, key, _, _, _)
    local singleplayer = xmlFile:getValue(key .. "#singleplayer", true)
    local multiplayer = xmlFile:getValue(key .. "#multiplayer", true)
    return ConversationPrerequisiteGameMode.new(singleplayer, multiplayer)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteGameMode.NAME, ConversationPrerequisiteGameMode)