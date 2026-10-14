WildlifeInstanceSounds = {}
local WildlifeInstanceSounds_mt = Class(WildlifeInstanceSounds)
function WildlifeInstanceSounds.registerXMLPaths(xmlSchema)
    xmlSchema:register(XMLValueType.STRING, "species.sounds.sound(?)#name", "The name of the sound group", nil, true)
    xmlSchema:register(XMLValueType.FLOAT, "species.sounds.sound(?)#cooldown", "The time in seconds in which the same sound group cannot be played more than once", 0, false)
    xmlSchema:register(XMLValueType.FLOAT, "species.sounds.sound(?)#chance", "The chance of the sound playing", 1, false)
end
function WildlifeInstanceSounds.new(instance)
    -- upvalues: (copy) WildlifeInstanceSounds_mt
    local self = setmetatable({}, WildlifeInstanceSounds_mt)
    self.instance = instance
    self.soundPlayedTimestamps = {}
    self.currentSample = nil
    return self
end
function WildlifeInstanceSounds:delete()
    table.clear(self.soundPlayedTimestamps)
    self:deleteCurrentSample(true)
end
function WildlifeInstanceSounds:deleteCurrentSample(skipPlayingCheck)
    if self.currentSample == nil then
        return false
    end
    if not skipPlayingCheck and g_soundManager:getIsSamplePlaying(self.currentSample) then
        return false
    end
    g_soundManager:deleteSample(self.currentSample)
    self.currentSample = nil
    return true
end
function WildlifeInstanceSounds:onInstanceSpawned(_)
    table.clear(self.soundPlayedTimestamps)
    self:deleteCurrentSample(true)
end
function WildlifeInstanceSounds:playSound(soundGroupName, chanceOverride)
    if self.currentSample == nil or self:deleteCurrentSample() then
        local soundGroup = self.instance.species.soundAttributes.soundGroups[soundGroupName]
        if soundGroup == nil or #soundGroup == 0 then
            return
        elseif g_time - (self.soundPlayedTimestamps[soundGroupName] or 0) < soundGroup.cooldown then
            return
        elseif (chanceOverride or (soundGroup.chance or 1)) >= math.random() then
            self.currentSample = g_soundManager:cloneSample(soundGroup[math.random(#soundGroup)], self.instance.rootNode)
            g_soundManager:playSample(self.currentSample)
            self.soundPlayedTimestamps[soundGroupName] = g_time
        end
    else
        return
    end
end
function WildlifeInstanceSounds.loadAttributesTable(xmlFile)
    local attributes = {
        ["linkNode"] = createTransformGroup("soundNode")
    }
    local _modName, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFile:getFilename())
    attributes.soundGroups = {}
    for soundGroupIndex, soundGroupKey in xmlFile:iterator("species.sounds.sound") do
        local soundGroup = {
            ["name"] = xmlFile:getValue(soundGroupKey .. "#name"),
            ["cooldown"] = xmlFile:getValue(soundGroupKey .. "#cooldown", 0),
            ["chance"] = xmlFile:getValue(soundGroupKey .. "#chance", 1)
        }
        attributes.soundGroups[soundGroup.name] = soundGroup
        for sampleIndex, sampleKey in xmlFile:iterator(soundGroupKey .. ".sample") do
            local sample = g_soundManager:loadSampleFromXML(xmlFile, soundGroupKey, string.format("sample(%d)", sampleIndex), baseDirectory, attributes.linkNode, 1, AudioGroup.ENVIRONMENT, nil, nil)
            table.insert(soundGroup, sample)
        end
    end
    return attributes
end
function WildlifeInstanceSounds.deleteAttributesTable(attributes)
    for _, soundGroup in ipairs(attributes) do
        for _, sound in ipairs(soundGroup) do
            g_soundManager:deleteSample(sound.sample)
        end
    end
    delete(attributes.linkNode)
end