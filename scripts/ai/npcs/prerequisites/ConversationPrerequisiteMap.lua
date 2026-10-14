ConversationPrerequisiteMap = {}
ConversationPrerequisiteMap.NAME = "map"
local ConversationPrerequisiteMap_mt = Class(ConversationPrerequisiteMap)
function ConversationPrerequisiteMap.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#mapId", "Map id", nil, false)
end
function ConversationPrerequisiteMap.new(mapId, customMt)
    -- upvalues: (copy) ConversationPrerequisiteMap_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteMap_mt)
    self.mapId = mapId
    return self
end
function ConversationPrerequisiteMap:getIsValid(_, _)
    return self.mapId == g_currentMission.missionInfo.mapId
end
function ConversationPrerequisiteMap.createFromXML(xmlFile, key, _, _, _)
    local mapId = xmlFile:getValue(key .. "#mapId", nil)
    if mapId ~= nil then
        return ConversationPrerequisiteMap.new(mapId)
    end
    Logging.xmlWarning(xmlFile, "Missing \'mapId\' for \'%s\'", key)
    return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteMap.NAME, ConversationPrerequisiteMap)