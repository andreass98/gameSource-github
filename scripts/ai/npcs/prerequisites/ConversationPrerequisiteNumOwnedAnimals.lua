ConversationPrerequisiteNumOwnedAnimals = {}
ConversationPrerequisiteNumOwnedAnimals.NAME = "numOwnedAnimals"
local ConversationPrerequisiteNumOwnedAnimals_mt = Class(ConversationPrerequisiteNumOwnedAnimals)
function ConversationPrerequisiteNumOwnedAnimals.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#min", "Min number of owned animals", 0, false)
    schema:register(XMLValueType.INT, basePath .. "#max", "Max number of owned animals", 9999999999, false)
    schema:register(XMLValueType.STRING, basePath .. "#type", "Animal type", nil, false)
end
function ConversationPrerequisiteNumOwnedAnimals.new(minNumOwnedAnimals, maxNumOwnedAnimals, animalTypeName, customMt)
    -- upvalues: (copy) ConversationPrerequisiteNumOwnedAnimals_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteNumOwnedAnimals_mt)
    self.minNumOwnedAnimals = minNumOwnedAnimals
    self.maxNumOwnedAnimals = maxNumOwnedAnimals
    self.animalTypeName = animalTypeName
    return self
end
function ConversationPrerequisiteNumOwnedAnimals:getIsValid(player, _)
    if player == nil then
        return false
    end
    local farm = g_farmManager:getFarmByUserId(player.userId)
    if farm == nil then
        return false
    end
    local animalTypeIndex = nil
    if self.animalTypeName ~= nil then
        animalTypeIndex = g_currentMission.animalSystem:getTypeIndexByName(self.animalTypeName)
    end
    local placeables = g_currentMission.husbandrySystem:getPlaceablesByFarm(farm.farmId, animalTypeIndex)
    local numAnimals = 0
    for _, placeable in ipairs(placeables) do
        numAnimals = numAnimals + placeable:getNumOfAnimals()
    end
    return not MathUtil.getIsOutOfBounds(numAnimals, self.minNumOwnedAnimals, self.maxNumOwnedAnimals)
end
function ConversationPrerequisiteNumOwnedAnimals.createFromXML(xmlFile, key, _, _, _)
    local minNumOwnedAnimals = xmlFile:getValue(key .. "#min", 0)
    local maxNumOwnedAnimals = xmlFile:getValue(key .. "#max", math.huge)
    local animalTypeName = xmlFile:getValue(key .. "#type")
    return ConversationPrerequisiteNumOwnedAnimals.new(minNumOwnedAnimals, maxNumOwnedAnimals, animalTypeName)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteNumOwnedAnimals.NAME, ConversationPrerequisiteNumOwnedAnimals)