OptionPrerequisiteMissionAvailable = {}
OptionPrerequisiteMissionAvailable.NAME = "missionAvailable"
local OptionPrerequisiteMissionAvailable_mt = Class(OptionPrerequisiteMissionAvailable)
function OptionPrerequisiteMissionAvailable.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#type", "Mission type", nil, true)
    schema:register(XMLValueType.STRING, basePath .. "#variant", "Variant name of the available mission", nil, false)
end
function OptionPrerequisiteMissionAvailable.new(conversation, missionTypeName, variantName, customMt)
    -- upvalues: (copy) OptionPrerequisiteMissionAvailable_mt
    local self = setmetatable({}, customMt or OptionPrerequisiteMissionAvailable_mt)
    self.conversation = conversation
    self.missionTypeName = missionTypeName
    self.variantName = variantName
    return self
end
function OptionPrerequisiteMissionAvailable:getIsValid(_)
    local selectedMission = nil
    local npc = self.conversation:getNPC()
    if npc == nil then
        Logging.error("OptionPrerequisiteMissionAvailable.getIsValid: No NPC set!")
        return false
    end
    local missionType = g_missionManager:getMissionType(self.missionTypeName)
    if missionType == nil then
        Logging.error("OptionPrerequisiteMissionAvailable.getIsValid: Mission type \'%s\' not defined!", self.missionTypeName)
        return false
    end
    local availableMissions = npc:getInputData(ConversationInputAvailableMissions.NAME)
    if availableMissions ~= nil then
        selectedMission = availableMissions[missionType.typeId]
        if selectedMission ~= nil and (self.variantName ~= nil and string.upper(selectedMission:getVariant()) ~= self.variantName) then
            selectedMission = nil
        end
    end
    return selectedMission ~= nil
end
function OptionPrerequisiteMissionAvailable.createFromXML(xmlFile, key, conversation, _, _)
    local missionTypeName = xmlFile:getValue(key .. "#type")
    if missionTypeName == nil then
        Logging.xmlWarning(xmlFile, "Missing type for \'%s\'", key)
        return nil
    end
    local variantName = xmlFile:getValue(key .. "#variant")
    local variantName
    if string.isNilOrWhitespace(variantName) then
        variantName = nil
    else
        variantName = string.upper(variantName)
    end
    return OptionPrerequisiteMissionAvailable.new(conversation, missionTypeName, variantName)
end
g_npcManager:registerConversationOptionPrerequisiteClass(OptionPrerequisiteMissionAvailable.NAME, OptionPrerequisiteMissionAvailable)