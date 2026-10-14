ConstructionSound = {}
local ConstructionSound_mt = Class(ConstructionSound)
ConstructionSound.ID = {}
ConstructionSound.ID.NONE = 0
ConstructionSound.ID.TREE = 1
ConstructionSound.ID.SCULPT = 2
ConstructionSound.ID.PAINT = 3
ConstructionSound.ID.FOLIAGE = 4
function ConstructionSound.new(subclass_mt)
    -- upvalues: (copy) ConstructionSound_mt
    local self = setmetatable({}, subclass_mt or ConstructionSound_mt)
    self.currentActiveSoundId = ConstructionSound.ID.NONE
    self.samples = self:loadSamples("dataS/constructionSoundSamples.xml")
    return self
end
function ConstructionSound.loadSamples(_, xmlPath)
    local samples = {}
    local xmlFile = XMLFile.load("constructionSound", xmlPath)
    if xmlFile == nil then
        return samples
    end
    for key, id in pairs(ConstructionSound.ID) do
        if id ~= ConstructionSound.ID.NONE then
            local loops = xmlFile:getInt("constructionSoundSamples." .. key .. "#loops", 0)
            local sample = g_soundManager:loadSample2DFromXML(xmlFile.handle, "constructionSoundSamples", string.lower(key), "", loops, AudioGroup.GUI)
            if sample == nil then
                Logging.warning("Could not load construction sound sample [%s]", key)
            else
                samples[id] = sample
            end
        end
    end
    xmlFile:delete()
    return samples
end
function ConstructionSound:delete()
    for k, sample in pairs(self.samples) do
        g_soundManager:deleteSample(sample)
        self.samples[k] = nil
    end
end
function ConstructionSound:setActiveSound(soundId, pitchModifier)
    local isOneOff = false
    if soundId ~= self.currentActiveSoundId then
        if soundId == ConstructionSound.ID.NONE and not self.silenceQueued then
            self.silenceQueued = true
            return
        end
        self.silenceQueued = false
        local oldSample = self.samples[self.currentActiveSoundId]
        local newSample = self.samples[soundId]
        local isOldOneOff = false
        if oldSample ~= nil then
            isOldOneOff = oldSample.loops == 1
        end
        isOneOff = false
        if newSample ~= nil then
            isOneOff = newSample.loops == 1
        end
        if not isOldOneOff then
            g_soundManager:stopSample(oldSample)
        end
        g_soundManager:playSample(newSample)
        self.currentActiveSoundId = soundId
    end
    local oldSample = self.samples[self.currentActiveSoundId]
    if oldSample ~= nil then
        local newSample = 1
        if pitchModifier ~= nil then
            newSample = MathUtil.smoothstep(0, 1, pitchModifier) + 0.5
        end
        oldSample.current.pitch = newSample
    end
    return isOneOff
end