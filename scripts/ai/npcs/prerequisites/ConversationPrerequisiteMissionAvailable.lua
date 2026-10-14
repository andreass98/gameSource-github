ConversationPrerequisiteMissionAvailable = {}
ConversationPrerequisiteMissionAvailable.NAME = "missionAvailable"
local ConversationPrerequisiteMissionAvailable_mt = Class(ConversationPrerequisiteMissionAvailable)
function ConversationPrerequisiteMissionAvailable.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".type(?)#name", "Type name of the available mission", nil, false)
    schema:register(XMLValueType.STRING, basePath .. ".type(?)#variant", "Variant name of the available mission", nil, false)
end
function ConversationPrerequisiteMissionAvailable.new(conversation, missionTypes, customMt)
    -- upvalues: (copy) ConversationPrerequisiteMissionAvailable_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteMissionAvailable_mt)
    self.conversation = conversation
    self.missionTypes = missionTypes
    self.availableMissions = {}
    return self
end
function ConversationPrerequisiteMissionAvailable:getIsValid(player, _)
    if g_server == nil then
        return false
    end
    local npc = self.conversation:getNPC()
    if npc == nil then
        Logging.error("ConversationPrerequisiteMissionAvailable.run: No NPC set!")
        return false
    end
    local missionManager = g_missionManager
    if missionManager:hasFarmReachedMissionLimit(player.farmId) then
        Logging.devInfo("ConversationPrerequisiteMissionAvailable.run: Mission limit reached!")
        return false
    end
    self.availableMissions = {}
    local hasMission = false
    Utils.shuffle(self.missionTypes)
    for _, setting in ipairs(self.missionTypes) do
        local typeName = setting.name
        local missionType = missionManager:getMissionType(typeName)
        if missionType == nil then
            Logging.error("ConversationPrerequisiteMissionAvailable.getIsValid: Mission type \'%s\' not defined!", typeName)
        elseif self.availableMissions[missionType.typeId] == nil then
            local missions = missionManager:getMissionsByType(missionType.typeId)
            Utils.shuffle(missions)
            for _, mission in ipairs(missions) do
                local missionNPC = mission:getNPC()
                local isSameNPC = false
                if missionNPC ~= nil then
                    isSameNPC = missionNPC == npc
                end
                local isMissionReady = mission:getIsReadyToStart()
                local isSameVariant = true
                if not string.isNilOrWhitespace(setting.variantName) then
                    local variant = mission:getVariant()
                    if string.upper(variant) ~= string.upper(setting.variantName) then
                        isSameVariant = false
                    end
                end
                if isSameNPC and (isSameVariant and isMissionReady) then
                    self.availableMissions[missionType.typeId] = mission
                    hasMission = true
                    break
                end
            end
        end
    end
    return hasMission
end
function ConversationPrerequisiteMissionAvailable:onConversationStart()
    local npc = self.conversation:getNPC()
    if npc == nil then
        Logging.error("ConversationPrerequisiteMissionAvailable.run: No NPC set!")
    else
        npc:setInputData(ConversationInputAvailableMissions.NAME, self.availableMissions)
    end
end
function ConversationPrerequisiteMissionAvailable.createFromXML(xmlFile, key, conversation, _, _)
    local missionTypes = {}
    for _, typeKey in xmlFile:iterator(key .. ".type") do
        local typeName = xmlFile:getValue(typeKey .. "#name")
        if not string.isNilOrWhitespace(typeName) then
            local setting = {
                ["name"] = typeName,
                ["variantName"] = xmlFile:getValue(typeKey .. "#variant")
            }
            table.addElement(missionTypes, setting)
        end
    end
    if #missionTypes ~= 0 then
        return ConversationPrerequisiteMissionAvailable.new(conversation, missionTypes)
    end
    Logging.xmlWarning(xmlFile, "No mission types defined for \'%s\'", key)
    return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteMissionAvailable.NAME, ConversationPrerequisiteMissionAvailable)