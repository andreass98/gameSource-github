SimpleHusbandry = {}
SimpleHusbandry.MAX_NUM_ANIMALS = 8
local SimpleHusbandry_mt = Class(SimpleHusbandry)
function SimpleHusbandry.onCreate(_, node)
    if g_dedicatedServer == nil then
        local husbandry = SimpleHusbandry.new()
        if husbandry:load(node) then
            g_currentMission:addUpdateable(husbandry)
        else
            husbandry:delete()
        end
    else
        Logging.devInfo("SimpleHusbandry not available on Dedicated Server Host")
        return
    end
end
function SimpleHusbandry.new(customMt)
    -- upvalues: (copy) SimpleHusbandry_mt
    local self = setmetatable({}, customMt or SimpleHusbandry_mt)
    self.husbandryId = nil
    self.animalIds = {}
    return self
end
function SimpleHusbandry:load(node)
    if not getHasClassId(node, ClassIds.NAVIGATION_MESH) then
        Logging.error("Given node \'%s\' is not a navigation mesh!", getName(node))
        return false
    end
    local animalTypeName = getUserAttribute(node, "animalType")
    local animalType = g_currentMission.animalSystem:getTypeByName(animalTypeName)
    if animalType == nil then
        Logging.error("Animal type \'%s\' not defined!", animalTypeName)
        return false
    end
    local collisionMaskFilter = tonumber(getUserAttribute(node, "maxNumberOfAnimals")) or 5
    self.maxNumberOfAnimals = math.clamp(collisionMaskFilter, 1, SimpleHusbandry.MAX_NUM_ANIMALS)
    local raycastDistance = tonumber(getUserAttribute(node, "raycastDistance")) or 10
    self.animalType = animalType
    self.subTypeIndex = getUserAttribute(node, "subTypeIndex")
    local collisionMaskFilter = CollisionMask.ANIMAL_SINGLEPLAYER
    if g_currentMission.missionDynamicInfo.isMultiplayer then
        collisionMaskFilter = CollisionMask.ANIMAL_MULTIPLAYER
    end
    self.husbandryId = createAnimalHusbandry(animalTypeName, node, animalType.configFilename, raycastDistance, CollisionMask.ANIMAL_POSITIONING, collisionMaskFilter, AudioGroup.ENVIRONMENT)
    if self.husbandryId == 0 then
        self.husbandryId = nil
        Logging.error("Unable to create animal husbandry for animal type %q with nav mesh %q and config xml %q", animalTypeName, I3DUtil.getNodePath(node), animalType.configFilename)
        return false
    end
    g_soundManager:addIndoorStateChangedListener(self)
    setAnimalUseOutdoorAudioSetup(self.husbandryId, not g_soundManager:getIsIndoor())
    self.needsAnimals = true
    return true
end
function SimpleHusbandry:delete()
    g_currentMission:removeUpdateable(self)
    if self.husbandryId ~= nil then
        for animalId, _ in pairs(self.animalIds) do
            removeHusbandryAnimal(self.husbandryId, animalId)
        end
        g_soundManager:removeIndoorStateChangedListener(self)
        delete(self.husbandryId)
        self.husbandryId = nil
    end
end
function SimpleHusbandry:update(_)
    if self.husbandryId ~= nil then
        setAnimalDaytime(self.husbandryId, g_currentMission.environment.dayTime)
        if self.needsAnimals and isHusbandryReady(self.husbandryId) then
            self:addAnimals()
            self.needsAnimals = false
        end
    end
end
function SimpleHusbandry:onIndoorStateChanged(_)
    setAnimalUseOutdoorAudioSetup(self.husbandryId, not g_soundManager:getIsIndoor())
end
function SimpleHusbandry:addAnimals()
    for i = 1, math.random(math.min(self.maxNumberOfAnimals, 2), self.maxNumberOfAnimals) do
        local subType = nil
        if self.subTypeIndex ~= nil then
            subType = g_currentMission.animalSystem:getSubTypeByIndex(self.subTypeIndex)
        end
        if subType == nil then
            local subTypes = self.animalType.subTypes
            local subTypeIndex = subTypes[math.random(1, #subTypes)]
            subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
        end
        local subTypes = subType.visuals
        local subTypeIndex = subTypes[#subTypes]
        local animalId = addHusbandryAnimal(self.husbandryId, subTypeIndex.visualAnimalIndex - 1)
        table.insert(self.animalIds, animalId)
        local animalRootNode = getAnimalRootNode(self.husbandryId, animalId)
        I3DUtil.setShaderParameterRec(animalRootNode, "dirt", math.random(0, 0.7), nil, nil, nil)
        local x, y, z, w = getAnimalShaderParameter(self.husbandryId, animalId, "atlasInvSizeAndOffsetUV")
        I3DUtil.setShaderParameterRec(animalRootNode, "atlasInvSizeAndOffsetUV", x, y, z, w)
    end
end