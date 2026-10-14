ConversationPrerequisiteNumOwnedVehicles = {}
ConversationPrerequisiteNumOwnedVehicles.NAME = "numOwnedVehicles"
local ConversationPrerequisiteNumOwnedVehicles_mt = Class(ConversationPrerequisiteNumOwnedVehicles)
function ConversationPrerequisiteNumOwnedVehicles.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#min", "Min number of owned vehicles", 0, false)
    schema:register(XMLValueType.INT, basePath .. "#max", "Max number of owned vehicles", 9999999999, false)
end
function ConversationPrerequisiteNumOwnedVehicles.new(minNumOwnedVehicles, maxNumOwnedVehicles, customMt)
    -- upvalues: (copy) ConversationPrerequisiteNumOwnedVehicles_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteNumOwnedVehicles_mt)
    self.minNumOwnedVehicles = minNumOwnedVehicles
    self.maxNumOwnedVehicles = maxNumOwnedVehicles
    return self
end
function ConversationPrerequisiteNumOwnedVehicles:getIsValid(player, _)
    if player == nil then
        return false
    end
    local farm = g_farmManager:getFarmByUserId(player.userId)
    if farm == nil then
        return false
    end
    local numVehicles = 0
    for _, vehicle in ipairs(g_currentMission.vehicleSystem.vehicles) do
        if vehicle:getOwnerFarmId() == farm.farmId then
        end
    end
    return not MathUtil.getIsOutOfBounds(numVehicles, self.minNumOwnedVehicles, self.maxNumOwnedVehicles)
end
function ConversationPrerequisiteNumOwnedVehicles.createFromXML(xmlFile, key, _, _, _)
    local minNumOwnedVehicles = xmlFile:getValue(key .. "#min", 0)
    local maxNumOwnedVehicles = xmlFile:getValue(key .. "#max", math.huge)
    return ConversationPrerequisiteNumOwnedVehicles.new(minNumOwnedVehicles, maxNumOwnedVehicles)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteNumOwnedVehicles.NAME, ConversationPrerequisiteNumOwnedVehicles)