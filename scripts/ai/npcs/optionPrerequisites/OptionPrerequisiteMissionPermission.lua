OptionPrerequisiteMissionPermission = {}
OptionPrerequisiteMissionPermission.NAME = "missionPermission"
local OptionPrerequisiteMissionPermission_mt = Class(OptionPrerequisiteMissionPermission)
function OptionPrerequisiteMissionPermission.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath, "Mission Permission", nil, true)
end
function OptionPrerequisiteMissionPermission.new(customMt)
    -- upvalues: (copy) OptionPrerequisiteMissionPermission_mt
    return setmetatable({}, customMt or OptionPrerequisiteMissionPermission_mt)
end
function OptionPrerequisiteMissionPermission.getIsValid(_, player)
    return g_currentMission:getHasPlayerPermission(Farm.PERMISSION.MANAGE_CONTRACTING, player ~= nil and player.connection or nil) and true or false
end
function OptionPrerequisiteMissionPermission.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
    return OptionPrerequisiteMissionPermission.new()
end
g_npcManager:registerConversationOptionPrerequisiteClass(OptionPrerequisiteMissionPermission.NAME, OptionPrerequisiteMissionPermission)