SoundModifierType = nil
SoundManager = {}
SoundManager.DEFAULT_REVERB_EFFECT = 0
SoundManager.MAX_SAMPLES_PER_FRAME = 5
SoundManager.DEFAULT_SOUND_TEMPLATES = "data/sounds/soundTemplates.xml"
SoundManager.SAMPLE_MODIFIER_ATTRIBUTES = {
    "volume",
    "pitch",
    "lowpassGain",
    "loopSynthesisRpm",
    "loopSynthesisLoad"
}
SoundManager.SAMPLE_RANDOMIZATIONS = { "randomizationsIn", "randomizationsOut" }
SoundManager.GLOBAL_DEBUG_ENABLED = false
local SoundManager_mt = Class(SoundManager, AbstractManager)
function SoundManager.new(customMt)
    -- upvalues: (copy) SoundManager_mt
    local self = AbstractManager.new(customMt or SoundManager_mt)
    addConsoleCommand("gsSoundManagerDebug", "Toggle SoundManager global debug mode", "consoleCommandToggleDebug", self)
    return self
end
function SoundManager:initDataStructures()
    self.samples = {}
    self.orderedSamples = {}
    self.activeSamples = {}
    self.activeSamplesSet = {}
    self.debugSamplesFlagged = {}
    self.debugSamples = {}
    self.debugSamplesLinkNodes = {}
    self.currentSampleIndex = 1
    self.oldRandomizationIndex = 1
    self.isIndoor = false
    self.soundTemplates = {}
    self.soundTemplateXMLFile = nil
    self:loadSoundTemplates(SoundManager.DEFAULT_SOUND_TEMPLATES)
    self.modifierTypeNameToIndex = {}
    self.modifierTypeIndexToDesc = {}
    SoundModifierType = self.modifierTypeNameToIndex
    setReverbEffect(0, Reverb.GS_OPEN_FIELD, Reverb.GS_OPEN_FIELD, 1)
    self.indoorStateChangedListeners = {}
end
function SoundManager:delete()
    if self.soundTemplateXMLFile ~= nil then
        delete(self.soundTemplateXMLFile)
        self.soundTemplateXMLFile = nil
    end
end
function SoundManager:registerModifierType(typeName, func, minFunc, maxFunc)
    local desc = string.upper(typeName)
    if SoundModifierType[desc] == nil then
        if type(func) ~= "function" then
            Logging.error("SoundManager.registerModifierType: parameter \'func\' is of type \'%s\'. Possibly the registerModifierType is called before the definition of the function?", (type(func)))
            printCallstack()
            return
        end
        local desc = {
            ["name"] = desc,
            ["index"] = #self.modifierTypeIndexToDesc + 1,
            ["func"] = func,
            ["minFunc"] = minFunc,
            ["maxFunc"] = maxFunc
        }
        SoundModifierType[desc] = desc.index
        table.insert(self.modifierTypeIndexToDesc, desc)
    end
    return SoundModifierType[desc]
end
function SoundManager:loadSoundTemplates(xmlFilename)
    local xmlFile = loadXMLFile("soundTemplates", xmlFilename)
    if xmlFile == 0 then
        return false
    end
    local i = 0
    while true do
        local key = string.format("soundTemplates.template(%d)", i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local name = getXMLString(xmlFile, key .. "#name")
        if name ~= nil then
            if self.soundTemplates[name] == nil then
                self.soundTemplates[name] = key
            else
                Logging.xmlWarning(xmlFile, "Sound template \'%s\' already exists!", name)
            end
        end
        i = i + 1
    end
    self.soundTemplateXMLFile = xmlFile
    return true
end
function SoundManager:reloadSoundTemplates()
    for k, _ in pairs(self.soundTemplates) do
        self.soundTemplates[k] = nil
    end
    if entityExists(self.soundTemplateXMLFile) then
        delete(self.soundTemplateXMLFile)
        self.soundTemplateXMLFile = nil
    end
    self:loadSoundTemplates(SoundManager.DEFAULT_SOUND_TEMPLATES)
end
function SoundManager:cloneSample(sample, linkNode, modifierTargetObject)
    local newSample = table.clone(sample)
    newSample.modifiers = table.clone(sample.modifiers)
    if not sample.is2D then
        newSample.soundNode = createAudioSource(newSample.sampleName, newSample.filename, newSample.outerRadius, newSample.innerRadius, newSample.current.volume, newSample.loops)
        newSample.soundSample = getAudioSourceSample(newSample.soundNode)
        setAudioSourceAutoPlay(newSample.soundNode, false)
        link(linkNode, newSample.soundNode)
        newSample.linkNode = linkNode
        if newSample.linkNodeOffset == nil then
            setTranslation(newSample.soundNode, 0, 0, 0)
        else
            setTranslation(newSample.soundNode, newSample.linkNodeOffset[1], newSample.linkNodeOffset[2], newSample.linkNodeOffset[3])
        end
    end
    setSampleGroup(newSample.soundSample, sample.audioGroup)
    newSample.audioGroup = sample.audioGroup
    if sample.supportsReverb then
        addSampleEffect(newSample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
    else
        removeSampleEffect(sample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
    end
    if modifierTargetObject ~= nil then
        newSample.modifierTargetObject = modifierTargetObject
    end
    if sample.sourceRandomizations ~= nil then
        newSample.sourceRandomizations = {}
        for _, randomSample in ipairs(sample.sourceRandomizations) do
            local newRandomSample = self:getRandomSample(sample, randomSample.filename)
            table.insert(newSample.sourceRandomizations, newRandomSample)
        end
    end
    self.samples[newSample] = newSample
    table.insert(self.orderedSamples, newSample)
    return newSample
end
function SoundManager:cloneSample2D(sample, _, modifierTargetObject)
    local newSample = table.clone(sample)
    newSample.modifiers = table.clone(sample.modifiers)
    newSample.audioGroup = sample.audioGroup
    newSample.linkNode = nil
    newSample.soundNode = nil
    newSample.is2D = true
    newSample.soundSample = createSample(newSample.sampleName)
    newSample.orgSoundSample = newSample.soundSample
    loadSample(newSample.soundSample, newSample.filename, false)
    newSample.duration = getSampleDuration(newSample.soundSample)
    setSampleGroup(newSample.soundSample, sample.audioGroup)
    newSample.audioGroup = sample.audioGroup
    if modifierTargetObject ~= nil then
        newSample.modifierTargetObject = modifierTargetObject
    end
    if sample.sourceRandomizations ~= nil then
        newSample.sourceRandomizations = {}
        for _, randomSample in ipairs(sample.sourceRandomizations) do
            local newRandomSample = {
                ["filename"] = randomSample.filename,
                ["isEmpty"] = randomSample.isEmpty,
                ["is2D"] = true
            }
            if not randomSample.isEmpty then
                newRandomSample.soundSample = createSample(newSample.sampleName)
                loadSample(newRandomSample.soundSample, newRandomSample.filename, false)
            end
            table.insert(newSample.sourceRandomizations, newRandomSample)
        end
    end
    self.samples[newSample] = newSample
    table.insert(self.orderedSamples, newSample)
    return newSample
end
function SoundManager.validateSampleDefinition(_, xmlFile, baseKey, sampleName, _, audioGroup, is2D, components, i3dMappings, externalSoundsFile)
    local isValid = false
    local usedExternal = false
    local sampleKey = ""
    local linkNode = nil
    local actualXMLFile
    if sampleName == nil then
        actualXMLFile = xmlFile
    else
        if not AudioGroup.getIsValidAudioGroup(audioGroup) then
            printWarning("Warning: Invalid audioGroup index \'" .. tostring(audioGroup) .. "\'.")
        end
        sampleKey = baseKey .. "." .. sampleName
        if externalSoundsFile == nil or hasXMLProperty(xmlFile, sampleKey) then
            actualXMLFile = xmlFile
        else
            sampleKey = Vehicle.xmlSchemaSounds:replaceRootName(sampleKey)
            actualXMLFile = externalSoundsFile.handle
            usedExternal = true
        end
        local xmlFileObject = g_xmlManager:getFileByHandle(xmlFile)
        if xmlFileObject ~= nil then
            XMLUtil.checkDeprecatedXMLElements(xmlFileObject, baseKey .. "#externalSoundFile", "vehicle.base.sounds#filename")
        end
        if actualXMLFile == nil then
            Logging.warning("Unable to load sample \'%s\' from internal or given external sound file \'%s\'!", sampleName, externalSoundsFile)
        elseif hasXMLProperty(actualXMLFile, sampleKey) then
            if not is2D then
                linkNode = I3DUtil.indexToObject(components, getXMLString(actualXMLFile, sampleKey .. "#linkNode"), i3dMappings)
                if linkNode == nil then
                    if type(components) == "number" then
                        return true, usedExternal, actualXMLFile, sampleKey, components
                    end
                    if type(components) == "table" then
                        return isValid, usedExternal, actualXMLFile, sampleKey, components[1].node
                    end
                    printWarning("Warning: Could not find linkNode (" .. tostring(getXMLString(actualXMLFile, sampleKey .. "#linkNode")) .. ") for sample \'" .. tostring(sampleName) .. "\'. Ignoring it!")
                    return false, usedExternal, actualXMLFile, sampleKey, linkNode
                end
            end
        end
    end
    return isValid, usedExternal, actualXMLFile, sampleKey, linkNode
end
function SoundManager:loadSample2DFromXML(xmlFile, baseKey, sampleName, baseDir, loops, audioGroup, requiresFile)
    if type(xmlFile) == "table" then
    end
    local sample = nil
    local isValid, usedExternal, definitionXmlFile, sampleKey = self:validateSampleDefinition(xmlFile, baseKey, sampleName, baseDir, audioGroup, true)
    if isValid then
        sample = {
            ["is2D"] = true,
            ["sampleName"] = sampleName
        }
        local template = getXMLString(definitionXmlFile, sampleKey .. "#template")
        if template ~= nil then
            sample = self:loadSampleAttributesFromTemplate(sample, template, baseDir, loops, definitionXmlFile, sampleKey)
            if sample == nil then
                return nil
            end
        end
        if not self:loadSampleAttributesFromXML(sample, definitionXmlFile, sampleKey, baseDir, loops, requiresFile) then
            return nil
        end
        sample.filename = Utils.getFilename(sample.filename, baseDir)
        sample.linkNode = nil
        sample.current = sample.outdoorAttributes
        sample.audioGroup = audioGroup
        sample.supportsReverb = Utils.getNoNil(getXMLBool(xmlFile, sampleKey .. "#supportsReverb"), true)
        self:createAudio2d(sample, sample.filename)
        sample.offsets = {
            ["volume"] = 0,
            ["pitch"] = 0,
            ["lowpassGain"] = 0
        }
        self.samples[sample] = sample
        table.insert(self.orderedSamples, sample)
    end
    if usedExternal then
        delete(definitionXmlFile)
    end
    return sample
end
function SoundManager:loadSampleFromXML(xmlFile, baseKey, sampleName, baseDir, components, loops, audioGroup, i3dMappings, modifierTargetObject, requiresFile)
    local sample = nil
    if type(xmlFile) == "table" then
    end
    local externalSoundsFile = nil
    local volumeFactor = nil
    if modifierTargetObject ~= nil then
        externalSoundsFile = modifierTargetObject.externalSoundsFile
        volumeFactor = modifierTargetObject.soundVolumeFactor
    end
    local isValid, _, definitionXmlFile, sampleKey, linkNode = self:validateSampleDefinition(xmlFile, baseKey, sampleName, baseDir, audioGroup, false, components, i3dMappings, externalSoundsFile)
    if isValid then
        sample = {
            ["is2D"] = false,
            ["sampleName"] = sampleName
        }
        local template = getXMLString(definitionXmlFile, sampleKey .. "#template")
        if template ~= nil then
            sample = self:loadSampleAttributesFromTemplate(sample, template, baseDir, loops, definitionXmlFile, sampleKey)
            if sample == nil then
                return nil
            end
        end
        if not self:loadSampleAttributesFromXML(sample, definitionXmlFile, sampleKey, baseDir, loops, requiresFile) then
            return nil
        end
        sample.filename = Utils.getFilename(sample.filename, baseDir)
        sample.isGlsFile = sample.filename:find(".gls") ~= nil
        sample.linkNode = linkNode
        sample.modifierTargetObject = modifierTargetObject
        sample.current = sample.outdoorAttributes
        sample.audioGroup = audioGroup
        if volumeFactor ~= nil then
            sample.volumeScale = sample.volumeScale * volumeFactor
        end
        self:createAudioSource(sample, sample.filename)
        sample.offsets = {
            ["volume"] = 0,
            ["pitch"] = 0,
            ["lowpassGain"] = 0
        }
        self.samples[sample] = sample
        table.insert(self.orderedSamples, sample)
    end
    return sample
end
function SoundManager.loadSamplesFromXML(_, xmlFile, baseKey, sampleName, baseDir, components, loops, audioGroup, i3dMappings, modifierTargetObject, samples)
    local i = samples or {}
    local i = 0
    while true do
        local sample = g_soundManager:loadSampleFromXML(xmlFile, baseKey, string.format("%s(%d)", sampleName, i), baseDir, components, loops, audioGroup, i3dMappings, modifierTargetObject)
        if sample == nil then
            break
        end
        table.insert(i, sample)
        i = i + 1
    end
    return i
end
function SoundManager:createAudioSource(sample, filename)
    if sample.soundNode ~= nil then
        delete(sample.soundNode)
    end
    if not string.isNilOrWhitespace(filename) then
        sample.filename = filename
        local audioSourceName = string.format("%s - %s", sample.sampleName, filename)
        sample.soundNode = createAudioSource(audioSourceName, filename, sample.outerRadius, sample.innerRadius, sample.current.volume, sample.loops)
        sample.soundSample = getAudioSourceSample(sample.soundNode)
        self:onCreateAudioSource(sample)
    end
end
function SoundManager.onCreateAudioSource(_, sample, ignoreReverb)
    sample.soundSample = getAudioSourceSample(sample.soundNode)
    sample.duration = getSampleDuration(sample.soundSample)
    sample.outerRange = getAudioSourceRange(sample.soundNode)
    sample.innerRange = getAudioSourceInnerRange(sample.soundNode)
    sample.isDirty = true
    setSampleGroup(sample.soundSample, sample.audioGroup)
    setSampleVolume(sample.soundSample, sample.current.volume)
    setSamplePitch(sample.soundSample, sample.current.pitch)
    setSampleFrequencyFilter(sample.soundSample, 1, sample.current.lowpassGain, 0, sample.current.lowpassCutoffFrequency, 0, sample.current.lowpassResonance)
    if not ignoreReverb then
        if sample.supportsReverb then
            addSampleEffect(sample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
        else
            removeSampleEffect(sample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
        end
    end
    setAudioSourceAutoPlay(sample.soundNode, false)
    setAudioSourcePriority(sample.soundNode, sample.priority)
    link(sample.linkNode, sample.soundNode)
    if sample.linkNodeOffset == nil then
        setTranslation(sample.soundNode, 0, 0, 0)
    else
        setTranslation(sample.soundNode, sample.linkNodeOffset[1], sample.linkNodeOffset[2], sample.linkNodeOffset[3])
    end
end
function SoundManager:createAudio2d(sample, filename)
    if sample.soundSample ~= nil then
        delete(sample.soundSample)
    end
    if not string.isNilOrWhitespace(filename) then
        sample.soundSample = createSample(sample.sampleName)
        sample.orgSoundSample = sample.soundSample
        loadSample(sample.soundSample, filename, false)
        self:onCreateAudio2d(sample)
    end
end
function SoundManager.onCreateAudio2d(_, sample, ignoreReverb)
    sample.duration = getSampleDuration(sample.soundSample)
    setSampleGroup(sample.soundSample, sample.audioGroup)
    setSampleVolume(sample.soundSample, sample.current.volume)
    setSamplePitch(sample.soundSample, sample.current.pitch)
    setSampleFrequencyFilter(sample.soundSample, 1, sample.current.lowpassGain, 0, sample.current.lowpassCutoffFrequency, 0, sample.current.lowpassResonance)
    if not ignoreReverb then
        if sample.supportsReverb then
            addSampleEffect(sample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
            return
        end
        removeSampleEffect(sample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
    end
end
function SoundManager:loadSampleAttributesFromTemplate(sample, templateName, baseDir, defaultLoops, xmlFile, sampleKey)
    local xmlKey = self.soundTemplates[templateName]
    if xmlKey == nil then
        local templateSample = g_xmlManager:getFileByHandle(xmlFile)
        if templateSample == nil then
            Logging.error("Sound template \'%s\' was not found in %s", templateName, sampleKey)
            return nil
        else
            Logging.xmlError(templateSample, "Sound template \'%s\' was not found in %s", templateName, sampleKey)
            return nil
        end
    elseif self.soundTemplateXMLFile == nil then
        return sample
    else
        local templateSample = {
            ["is2D"] = sample.is2D,
            ["sampleName"] = sample.sampleName,
            ["templateName"] = templateName
        }
        if self:loadSampleAttributesFromXML(templateSample, self.soundTemplateXMLFile, xmlKey, baseDir, defaultLoops, false) then
            return templateSample
        else
            return nil
        end
    end
end
function SoundManager:loadSampleAttributesFromXML(sample, xmlFile, key, baseDir, defaultLoops, requiresFile)
    local parent = getXMLString(xmlFile, key .. "#parent")
    if parent ~= nil then
        local templateKey = self.soundTemplates[parent]
        if templateKey ~= nil then
            self:loadSampleAttributesFromXML(sample, self.soundTemplateXMLFile, templateKey, baseDir, defaultLoops, false)
        end
    end
    sample.filename = getXMLString(xmlFile, key .. "#file") or (sample.filename or "")
    if sample.filename == nil and (requiresFile == nil or requiresFile) then
        printWarning("Warning: Filename not defined in \'" .. tostring(key) .. "\'. Ignoring it!")
        return false
    end
    sample.linkNodeOffset = string.getVector(getXMLString(xmlFile, key .. "#linkNodeOffset"), 3)
    sample.innerRadius = getXMLFloat(xmlFile, key .. "#innerRadius") or (sample.innerRadius or 5)
    sample.outerRadius = getXMLFloat(xmlFile, key .. "#outerRadius") or (sample.outerRadius or 80)
    sample.volumeScale = getXMLFloat(xmlFile, key .. "#volumeScale") or (sample.volumeScale or 1)
    sample.pitchScale = getXMLFloat(xmlFile, key .. "#pitchScale") or (sample.pitchScale or 1)
    sample.lowpassGainScale = getXMLFloat(xmlFile, key .. "#lowpassGainScale") or (sample.lowpassGainScale or 1)
    sample.loopSynthesisRPMRatio = getXMLFloat(xmlFile, key .. "#loopSynthesisRPMRatio") or (sample.loopSynthesisRPMRatio or 1)
    sample.indoorAttributes = sample.indoorAttributes or {}
    sample.indoorAttributes.volume = getXMLFloat(xmlFile, key .. ".volume#indoor") or (sample.indoorAttributes.volume or 0.8)
    sample.indoorAttributes.pitch = getXMLFloat(xmlFile, key .. ".pitch#indoor") or (sample.indoorAttributes.pitch or 1)
    sample.indoorAttributes.lowpassGain = getXMLFloat(xmlFile, key .. ".lowpassGain#indoor") or (sample.indoorAttributes.lowpassGain or 0.8)
    sample.indoorAttributes.lowpassCutoffFrequency = getXMLFloat(xmlFile, key .. ".lowpassCutoffFrequency#indoor") or (sample.indoorAttributes.lowpassCutoffFrequency or 0)
    sample.indoorAttributes.lowpassResonance = getXMLFloat(xmlFile, key .. ".lowpassResonance#indoor") or (sample.indoorAttributes.lowpassResonance or 0)
    sample.outdoorAttributes = sample.outdoorAttributes or {}
    sample.outdoorAttributes.volume = getXMLFloat(xmlFile, key .. ".volume#outdoor") or (sample.outdoorAttributes.volume or 1)
    sample.outdoorAttributes.pitch = getXMLFloat(xmlFile, key .. ".pitch#outdoor") or (sample.outdoorAttributes.pitch or 1)
    sample.outdoorAttributes.lowpassGain = getXMLFloat(xmlFile, key .. ".lowpassGain#outdoor") or (sample.outdoorAttributes.lowpassGain or 1)
    sample.outdoorAttributes.lowpassCutoffFrequency = getXMLFloat(xmlFile, key .. ".lowpassCutoffFrequency#outdoor") or (sample.outdoorAttributes.lowpassCutoffFrequency or 0)
    sample.outdoorAttributes.lowpassResonance = getXMLFloat(xmlFile, key .. ".lowpassResonance#outdoor") or (sample.outdoorAttributes.lowpassResonance or 0)
    sample.loops = getXMLInt(xmlFile, key .. "#loops") or (sample.loops or (defaultLoops or 1))
    sample.supportsReverb = Utils.getNoNil(Utils.getNoNil(getXMLBool(xmlFile, key .. "#supportsReverb"), sample.supportsReverb), true)
    sample.isLocalSound = Utils.getNoNil(Utils.getNoNil(getXMLBool(xmlFile, key .. "#isLocalSound"), sample.isLocalSound), false)
    local templateKey = nil
    local priorityStr = getXMLString(xmlFile, key .. "#priority")
    if priorityStr ~= nil then
        templateKey = AudioSourcePriority[string.upper(priorityStr)]
    end
    sample.priority = templateKey or (sample.priority or AudioSourcePriority.MEDIUM)
    sample.debug = Utils.getNoNil(getXMLBool(xmlFile, key .. "#debug"), sample.debug)
    if sample.debug or SoundManager.GLOBAL_DEBUG_ENABLED then
        if sample.debug then
            table.insert(self.debugSamplesFlagged, sample)
        end
        self.debugSamples[sample] = true
        sample.debug = nil
    end
    local fadeIn = getXMLFloat(xmlFile, key .. "#fadeIn")
    if fadeIn ~= nil then
    end
    sample.fadeIn = fadeIn or (sample.fadeIn or 0)
    local fadeOut = getXMLFloat(xmlFile, key .. "#fadeOut")
    if fadeOut ~= nil then
    end
    sample.fadeOut = fadeOut or (sample.fadeOut or 0)
    sample.fade = 0
    sample.isIndoor = false
    self:loadModifiersFromXML(sample, xmlFile, key)
    self:loadRandomizationsFromXML(sample, xmlFile, key, baseDir)
    return true
end
function SoundManager.loadModifiersFromXML(_, sample, xmlFile, key)
    sample.modifiers = sample.modifiers or {}
    for _, attribute in pairs(SoundManager.SAMPLE_MODIFIER_ATTRIBUTES) do
        local modifier = sample.modifiers[attribute] or {}
        modifier.hasModification = Utils.getNoNil(modifier.hasModification, false)
        local i = 0
        while true do
            local modKey = string.format("%s.%s.modifier(%d)", key, attribute, i)
            if not hasXMLProperty(xmlFile, modKey) then
                break
            end
            local type = getXMLString(xmlFile, modKey .. "#type")
            local typeIndex = SoundModifierType[type]
            if typeIndex ~= nil then
                if modifier[typeIndex] == nil then
                    modifier[typeIndex] = AnimCurve.new(linearInterpolator1)
                end
                local value = getXMLFloat(xmlFile, modKey .. "#value")
                modifier[typeIndex]:addKeyframe({
                    getXMLFloat(xmlFile, modKey .. "#modifiedValue"),
                    ["time"] = value
                }, xmlFile, modKey)
                modifier.hasModification = true
            end
            i = i + 1
        end
        modifier.currentValue = nil
        sample.modifiers[attribute] = modifier
    end
end
function SoundManager:loadRandomizationsFromXML(sample, xmlFile, key, baseDir)
    local i = 0
    while true do
        local baseKey = string.format("%s.randomization(%d)", key, i)
        if not hasXMLProperty(xmlFile, baseKey) then
            break
        end
        local randomization = {
            ["minVolume"] = getXMLFloat(xmlFile, baseKey .. "#minVolume"),
            ["maxVolume"] = getXMLFloat(xmlFile, baseKey .. "#maxVolume"),
            ["minPitch"] = getXMLFloat(xmlFile, baseKey .. "#minPitch"),
            ["maxPitch"] = getXMLFloat(xmlFile, baseKey .. "#maxPitch"),
            ["minLowpassGain"] = getXMLFloat(xmlFile, baseKey .. "#minLowpassGain"),
            ["maxLowpassGain"] = getXMLFloat(xmlFile, baseKey .. "#maxLowpassGain"),
            ["isInside"] = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#isInside"), true),
            ["isOutside"] = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#isOutside"), true)
        }
        if randomization.isInside then
            if randomization.minVolume ~= nil and sample.indoorAttributes.volume + randomization.minVolume <= 0 then
                Logging.xmlWarning(xmlFile, "Invalid sample \'%s\' randomization found in %s. randomization#minVolume can result in negative volume (indoor)", sample.templateName or sample.sampleName, baseKey)
            end
            sample.randomizationsIn = sample.randomizationsIn or {}
            table.insert(sample.randomizationsIn, randomization)
        end
        if randomization.isOutside then
            if randomization.minVolume ~= nil and sample.outdoorAttributes.volume + randomization.minVolume <= 0 then
                Logging.xmlWarning(xmlFile, "Invalid sample \'%s\' randomization found in %s. randomization#minVolume can result in negative volume (outdoor)", sample.templateName or sample.sampleName, baseKey)
            end
            sample.randomizationsOut = sample.randomizationsOut or {}
            table.insert(sample.randomizationsOut, randomization)
        end
        i = i + 1
    end
    local i = 0
    while true do
        local baseKey = string.format("%s.sourceRandomization(%d)", key, i)
        if not hasXMLProperty(xmlFile, baseKey) then
            break
        end
        local randomization = getXMLString(xmlFile, baseKey .. "#file")
        if randomization ~= nil then
            if randomization ~= "-" then
                randomization = Utils.getFilename(randomization, baseDir)
            end
            local randomSample = self:getRandomSample(sample, randomization)
            sample.sourceRandomizations = sample.sourceRandomizations or {}
            table.insert(sample.sourceRandomizations, randomSample)
        end
        i = i + 1
    end
    if sample.sourceRandomizations ~= nil and (#sample.sourceRandomizations > 0 and not sample.addedBaseFileToRandomizations) then
        local randomization = self:getRandomSample(sample, (Utils.getFilename(sample.filename, baseDir)))
        table.insert(sample.sourceRandomizations, randomization)
        sample.addedBaseFileToRandomizations = true
    end
end
function SoundManager.getRandomSample(_, sample, filename)
    local randomSample = {
        ["filename"] = filename
    }
    if filename == "-" then
        randomSample.isEmpty = true
    elseif sample.is2D then
        local audioSourceName = createSample(sample.sampleName)
        if audioSourceName ~= 0 and loadSample(audioSourceName, filename, false) then
            randomSample.soundSample = audioSourceName
            randomSample.is2D = true
            return randomSample
        end
    else
        local audioSourceName = string.format("%s - %s", sample.sampleName, filename)
        local audioSource = createAudioSource(audioSourceName, filename, sample.outerRadius, sample.innerRadius, 1, sample.loops)
        if audioSource ~= 0 then
            randomSample.soundNode = audioSource
            local sampleId = getAudioSourceSample(randomSample.soundNode)
            if sample.supportsReverb then
                addSampleEffect(sampleId, SoundManager.DEFAULT_REVERB_EFFECT)
            else
                removeSampleEffect(sampleId, SoundManager.DEFAULT_REVERB_EFFECT)
            end
            setAudioSourcePriority(audioSource, sample.priority)
            return randomSample
        end
    end
    return randomSample
end
function SoundManager:update(dt)
    for i = 0, SoundManager.MAX_SAMPLES_PER_FRAME do
        local index = self.currentSampleIndex
        if #self.activeSamples < index then
            self.currentSampleIndex = 1
            return
        end
        local sample = self.activeSamples[index]
        if self:getIsSamplePlaying(sample) then
            self:updateSampleFade(sample, dt)
            self:updateSampleModifiers(sample)
            self:updateSampleAttributes(sample)
        else
            table.removeElement(self.activeSamples, sample)
            sample.fade = 0
        end
        self.currentSampleIndex = self.currentSampleIndex + 1
    end
end
function SoundManager:draw()
    if next(self.debugSamples) ~= nil then
        table.clear(self.debugSamplesLinkNodes)
        for sample in pairs(self.debugSamples) do
            if sample.soundNode ~= nil and entityExists(sample.soundNode) then
                local distanceToCam = calcDistanceFrom(g_cameraManager:getActiveCamera(), sample.soundNode)
                if sample.outerRadius * 2 >= distanceToCam or distanceToCam <= 15 then
                    self.debugSamplesLinkNodes[sample.linkNode] = self.debugSamplesLinkNodes[sample.linkNode] or {}
                    self.debugSamplesLinkNodes[sample.linkNode][sample] = true
                end
            end
        end
        local x = 0.01
        local y = 0.9
        local sample = 0
        local activeSoundIndex = 0
        for linkNode, linkNodeSamples in pairs(self.debugSamplesLinkNodes) do
            local isVisible = getEffectiveVisibility(linkNode)
            local linkNodeColor = not isVisible and Color.PRESETS.RED or Color.PRESETS.WHITE
            local activeSoundOffset = getName(linkNode)
            DebugPoint.renderAtNode(linkNode, nil, linkNodeColor, false, string.format("LinkNode %q%s", activeSoundOffset, isVisible and "" or " (hidden!)"), 0.012, 250, 150)
            setTextColor(linkNodeColor:unpack())
            setTextBold(true)
            renderText(x, y, 0.012, (getName(linkNode)))
            sample = math.max(sample, getTextWidth(0.012, linkNodeName))
            local y = y - 0.012
            setTextColor(1, 1, 1, 1)
            setTextBold(false)
            local activeSoundOffset = 0
            for sample in pairs(linkNodeSamples) do
                local isPlaying = self:getIsSamplePlaying(sample)
                local sampleName = sample.templateName or Utils.getFilenameFromPath(sample.filename)
                local sampleColor = Color.PRESETS.WHITE
                if isPlaying then
                    local sx, sy, sz = getWorldTranslation(sample.soundNode)
                    sampleColor = DebugUtil.getDebugColor(activeSoundIndex)
                    DebugSphere.renderAtPosition(sx, sy, sz, sample.outerRadius, sampleColor)
                    DebugPoint.renderAtPosition(sx, sy, sz, sampleColor, false)
                    DebugText.renderAtPosition(sx, sy, sz, sampleName, sampleColor, 0.012, 0.005 + 0.012 * (activeSoundOffset + 1))
                    activeSoundOffset = activeSoundOffset + 1
                    activeSoundIndex = activeSoundIndex + 1
                end
                local sx = string.format("%q  (%d-%d)", sampleName, sample.innerRadius, sample.outerRadius)
                setTextColor(sampleColor:unpack())
                renderText(x + 0.012, y, 0.012, sx)
                sample = math.max(sample, getTextWidth(0.012, sx) + 0.012)
                y = y - 0.012
                if y <= 0.02 then
                    y = 0.95
                end
            end
            y = y - 0.012
        end
        setTextColor(1, 1, 1, 1)
    end
end
function SoundManager.updateSampleFade(_, sample, dt)
    if sample ~= nil and sample.fadeIn ~= 0 then
        sample.fade = math.min(sample.fade + dt, sample.fadeIn)
    end
end
function SoundManager:updateSampleModifiers(sample)
    if sample ~= nil and sample.modifiers ~= nil then
        for attributeIndex, attribute in pairs(SoundManager.SAMPLE_MODIFIER_ATTRIBUTES) do
            local modifier = sample.modifiers[attribute]
            if modifier ~= nil then
                local value = 1
                for name, typeIndex in pairs(SoundModifierType) do
                    local changeValue, _, available = self:getSampleModifierValue(sample, attribute, typeIndex)
                    if available then
                    end
                end
                modifier.currentValue = value
            end
        end
    end
end
function SoundManager:updateSampleAttributes(sample, force)
    if sample ~= nil then
        if sample.isIndoor ~= self.isIndoor or force then
            self:setCurrentSampleAttributes(sample, self.isIndoor)
            sample.isIndoor = self.isIndoor
        end
        if sample.soundSample ~= nil then
            local volumeFactor = self:getModifierFactor(sample, "volume")
            local pitchFactor = self:getModifierFactor(sample, "pitch")
            local lowpassGainFactor = self:getModifierFactor(sample, "lowpassGain")
            setSampleVolume(sample.soundSample, volumeFactor * self:getCurrentSampleVolume(sample))
            setSamplePitch(sample.soundSample, pitchFactor * self:getCurrentSamplePitch(sample))
            setSampleFrequencyFilter(sample.soundSample, 1, lowpassGainFactor * self:getCurrentSampleLowpassGain(sample), 0, sample.current.lowpassCutoffFrequency, 0, sample.current.lowpassResonance)
            if sample.modifiers.loopSynthesisRpm.hasModification then
                local loopSynthesisRpmFactor = self:getModifierFactor(sample, "loopSynthesisRpm")
                setSampleLoopSynthesisRPM(sample.soundSample, math.clamp(loopSynthesisRpmFactor, 0, 1), true)
            end
            if sample.modifiers.loopSynthesisLoad.hasModification then
                local loopSynthesisRpmFactor = self:getModifierFactor(sample, "loopSynthesisLoad")
                setSampleLoopSynthesisLoadFactor(sample.soundSample, (math.clamp(loopSynthesisRpmFactor, 0, 1)))
            end
        end
    end
end
function SoundManager:updateSampleRandomizations(sample)
    if sample ~= nil then
        for _, name in ipairs(SoundManager.SAMPLE_RANDOMIZATIONS) do
            local numRandomizations = name == "randomizationsIn"
            if numRandomizations == sample.isIndoor then
                local numRandomizations = sample[name] and #sample[name] or 0
                if numRandomizations > 0 then
                    local randomizationToUse = math.floor((math.random(numRandomizations)))
                    local randomizationIndexToUse = math.max(randomizationToUse, 1)
                    local randomizationToUse = sample[name][randomizationIndexToUse]
                    if randomizationToUse.minVolume ~= nil and randomizationToUse.maxVolume then
                        sample[name].volume = math.random() * (randomizationToUse.maxVolume - randomizationToUse.minVolume) + randomizationToUse.minVolume
                    end
                    if randomizationToUse.minPitch ~= nil and randomizationToUse.maxPitch then
                        sample[name].pitch = math.random() * (randomizationToUse.maxPitch - randomizationToUse.minPitch) + randomizationToUse.minPitch
                    end
                    if randomizationToUse.minLowpassGain ~= nil and randomizationToUse.maxLowpassGain then
                        sample[name].lowpassGain = math.random() * (randomizationToUse.maxLowpassGain - randomizationToUse.minLowpassGain) + randomizationToUse.minLowpassGain
                    end
                end
            end
        end
        local numRandomizations = sample.sourceRandomizations and #sample.sourceRandomizations or 0
        if numRandomizations > 0 then
            local randomizationIndexToUse = 1
            local randomSample = 3
            for name = 1, randomSample do
                local randomizationToUse = math.random(numRandomizations)
                local randomizationIndexToUse = math.floor(randomizationToUse)
                randomizationIndexToUse = math.max(randomizationIndexToUse, 1)
                if self.oldRandomizationIndex ~= randomizationIndexToUse then
                    break
                end
            end
            self.oldRandomizationIndex = randomizationIndexToUse
            local randomSample = sample.sourceRandomizations[randomizationIndexToUse]
            if not sample.is2D then
                if sample.soundSample ~= nil then
                    stopSample(sample.soundSample, 0, sample.fadeOut)
                end
                if randomSample.isEmpty then
                    sample.isEmptySample = true
                else
                    sample.soundNode = randomSample.soundNode
                    self:onCreateAudioSource(sample, true)
                    sample.isEmptySample = false
                end
            end
            if sample.soundSample ~= nil then
                stopSample(sample.soundSample, 0, sample.fadeOut)
            end
            if not randomSample.isEmpty then
                sample.soundSample = randomSample.soundSample
                self:onCreateAudio2d(sample, true)
                sample.isEmptySample = false
                return
            end
            sample.isEmptySample = true
        end
    end
end
function SoundManager:getSampleModifierValue(sample, attribute, typeIndex)
    local modifier = sample.modifiers[attribute]
    if modifier ~= nil then
        local curve = modifier[typeIndex]
        if curve ~= nil then
            local typeData = self.modifierTypeIndexToDesc[typeIndex]
            local t = typeData.func(sample.modifierTargetObject)
            if typeData.maxFunc ~= nil and typeData.minFunc ~= nil then
                local min = typeData.minFunc(sample.modifierTargetObject)
                t = math.clamp((t - min) / (typeData.maxFunc(sample.modifierTargetObject) - min), 0, 1)
            end
            return curve:get(t), t, true
        end
    end
    return 0, 0, false
end
function SoundManager:deleteSample(sample)
    if sample ~= nil and sample.filename ~= nil then
        if self:getIsSamplePlaying(sample) then
            self:stopSample(sample)
        end
        self.samples[sample] = nil
        table.removeElement(self.activeSamples, sample)
        table.removeElement(self.orderedSamples, sample)
        self.debugSamples[sample] = nil
        table.removeElement(self.debugSamplesFlagged, sample)
        if sample.soundNode ~= nil then
            delete(sample.soundNode)
        end
        if sample.is2D and sample.orgSoundSample ~= nil then
            delete(sample.orgSoundSample)
        end
        if sample.sourceRandomizations ~= nil then
            for _, randomSample in ipairs(sample.sourceRandomizations) do
                if not randomSample.isEmpty then
                    if randomSample.soundNode ~= nil and randomSample.soundNode ~= sample.soundNode then
                        delete(randomSample.soundNode)
                    end
                    if randomSample.is2D then
                        delete(randomSample.soundSample)
                    end
                end
            end
            sample.sourceRandomizations = nil
        end
        sample.soundSample = nil
        sample.soundNode = nil
    end
end
function SoundManager:deleteSamples(samples, delay, afterSample)
    if samples ~= nil then
        for _, sample in pairs(samples) do
            self:deleteSample(sample, delay, afterSample)
        end
    end
end
function SoundManager:playSample(sample, delay, afterSample)
    if sample ~= nil and (not sample.isLocalSound or (sample.modifierTargetObject == nil or sample.isLocalSound and sample.modifierTargetObject.isActiveForLocalSound)) then
        self:updateSampleRandomizations(sample)
        self:updateSampleModifiers(sample)
        self:updateSampleAttributes(sample, true)
        if not sample.isEmptySample and sample.soundSample ~= nil then
            local afterSampleId = 0
            if afterSample ~= nil then
                afterSampleId = afterSample.soundSample
            end
            playSample(sample.soundSample, sample.loops, self:getModifierFactor(sample, "volume") * self:getCurrentSampleVolume(sample), 0, delay or 0, afterSampleId)
            table.addElement(self.activeSamples, sample)
        end
    end
end
function SoundManager:playSamples(samples, delay, afterSample)
    for _, sample in pairs(samples) do
        self:playSample(sample, delay, afterSample)
    end
end
function SoundManager.stopSample(_, sample, delay, fadeOut)
    if sample ~= nil and sample.soundSample ~= nil then
        stopSample(sample.soundSample, delay or getSampleLoopSynthesisStopDuration(sample.soundSample), fadeOut or sample.fadeOut)
    end
end
function SoundManager:stopSamples(samples)
    for _, sample in pairs(samples) do
        self:stopSample(sample)
    end
end
function SoundManager.setSampleVolumeOffset(_, sample, offset)
    if sample ~= nil then
        sample.offsets.volume = offset
    end
end
function SoundManager.setSamplePitchOffset(_, sample, offset)
    if sample ~= nil then
        sample.offsets.pitch = offset
    end
end
function SoundManager.setSampleLowpassGainOffset(_, sample, offset)
    if sample ~= nil then
        sample.offsets.lowpassGain = offset
    end
end
function SoundManager.setSampleVolume(_, sample, volume)
    if sample ~= nil and sample.soundSample ~= nil then
        setSampleVolume(sample.soundSample, volume)
    end
end
function SoundManager.setSampleVolumeScale(_, sample, volumeScale)
    if sample ~= nil then
        sample.volumeScale = volumeScale
    end
end
function SoundManager.getSampleVolumeScale(_, sample)
    return sample == nil and 1 or sample.volumeScale
end
function SoundManager.setSamplePitch(_, sample, pitch)
    if sample ~= nil and sample.soundSample ~= nil then
        setSamplePitch(sample.soundSample, pitch)
    end
end
function SoundManager.getIsSamplePlaying(_, sample)
    if sample == nil or sample.soundSample == nil then
        return false
    else
        return isSamplePlaying(sample.soundSample)
    end
end
function SoundManager.getSamplePlayOffset(_, sample)
    return (sample == nil or sample.soundSample == nil) and 0 or getSamplePlayOffset(sample.soundSample)
end
function SoundManager.setSampleLoopSynthesisParameters(_, sample, rpm, loadFactor)
    if sample ~= nil and sample.soundSample ~= nil then
        if rpm ~= nil then
            if sample.loopSynthesisRPMRatio ~= 1 then
                rpm = math.clamp(rpm / sample.loopSynthesisRPMRatio, 0, 1)
            end
            setSampleLoopSynthesisRPM(sample.soundSample, rpm, true)
        end
        if loadFactor ~= nil then
            setSampleLoopSynthesisLoadFactor(sample.soundSample, loadFactor)
        end
    end
end
function SoundManager:setSamplesLoopSynthesisParameters(samples, rpm, loadFactor)
    for _, sample in pairs(samples) do
        self:setSampleLoopSynthesisParameters(sample, rpm, loadFactor)
    end
end
function SoundManager.getSampleLoopSynthesisStartDuration(_, sample)
    return (sample == nil or (sample.soundSample == nil or not sample.isGlsFile)) and 0 or getSampleLoopSynthesisStartDuration(sample.soundSample)
end
function SoundManager.setCurrentSampleAttributes(_, sample, isIndoor)
    if isIndoor then
        sample.current = sample.indoorAttributes
        sample.randomizations = sample.randomizationsIn
    else
        sample.current = sample.outdoorAttributes
        sample.randomizations = sample.randomizationsOut
    end
end
function SoundManager:getCurrentSampleVolume(sample)
    return math.max((sample.current.volume + self:getCurrentRandomizationValue(sample, "volume")) * self:getCurrentFadeFactor(sample) * sample.volumeScale + sample.offsets.volume, 0)
end
function SoundManager:getCurrentSamplePitch(sample)
    return (sample.current.pitch + self:getCurrentRandomizationValue(sample, "pitch")) * sample.pitchScale + sample.offsets.pitch
end
function SoundManager:getCurrentSampleLowpassGain(sample)
    return (sample.current.lowpassGain + self:getCurrentRandomizationValue(sample, "lowpassGain")) * sample.lowpassGainScale + sample.offsets.lowpassGain
end
function SoundManager.getCurrentRandomizationValue(_, sample, attribute)
    return (sample.randomizations == nil or sample.randomizations[attribute] == nil) and 0 or sample.randomizations[attribute]
end
function SoundManager.getCurrentFadeFactor(_, sample)
    local fadeFactor = 1
    if sample.fadeIn ~= 0 then
        fadeFactor = sample.fade / sample.fadeIn
    end
    return fadeFactor
end
function SoundManager:setIsIndoor(isIndoor)
    if self.isIndoor ~= isIndoor then
        self.isIndoor = isIndoor
        local i = 1
        for i = i, #self.activeSamples do
            local sample = self.activeSamples[i]
            if self:getIsSamplePlaying(sample) then
                self:updateSampleAttributes(sample)
            end
        end
        for sample, target in ipairs(self.indoorStateChangedListeners) do
            target:onIndoorStateChanged(isIndoor)
        end
    end
end
function SoundManager:addIndoorStateChangedListener(target)
    table.addElement(self.indoorStateChangedListeners, target)
end
function SoundManager:removeIndoorStateChangedListener(target)
    table.removeElement(self.indoorStateChangedListeners, target)
end
function SoundManager:getIsIndoor()
    return self.isIndoor
end
function SoundManager.getModifierFactor(_, sample, modifierName)
    if sample.modifiers ~= nil then
        local modifier = sample.modifiers[modifierName]
        if modifier ~= nil and modifier.currentValue ~= nil then
            return modifier.currentValue
        end
    end
    return 1
end
function SoundManager:consoleCommandToggleDebug()
    SoundManager.GLOBAL_DEBUG_ENABLED = not SoundManager.GLOBAL_DEBUG_ENABLED
    if SoundManager.GLOBAL_DEBUG_ENABLED then
        for _, sample in pairs(self.orderedSamples) do
            if sample.linkNode ~= nil then
                self.debugSamples[sample] = true
            end
        end
    else
        table.clear(self.debugSamples)
        for _, sample in pairs(self.debugSamplesFlagged) do
            self.debugSamples[sample] = true
        end
    end
    return string.format("SoundManager.GLOBAL_DEBUG_ENABLED=%s", SoundManager.GLOBAL_DEBUG_ENABLED)
end
function SoundManager.registerModifierXMLPaths(schema, path)
    schema:register(XMLValueType.STRING, path .. ".modifier(?)#type", "Modifier type", nil, false, SoundModifierType and table.toList(SoundModifierType))
    schema:register(XMLValueType.FLOAT, path .. ".modifier(?)#value", "Source value of modifier type")
    schema:register(XMLValueType.FLOAT, path .. ".modifier(?)#modifiedValue", "Change that is applied on sample value")
end
function SoundManager.registerSampleXMLPaths(schema, basePath, xmlElementName)
    schema:setSubSchemaIdentifier("sounds")
    if xmlElementName == nil then
        Logging.error("Failed to register sound sample xml paths! No sound xml element name given.")
        printCallstack()
        return
    elseif string.contains(xmlElementName, " ") then
        Logging.error("Failed to register sound sample xml paths! XML element name cannot have spaces: \'%s\'", xmlElementName)
        printCallstack()
    else
        schema:setXMLSharedRegistration("SoundManager_sound", basePath)
        local soundPath = basePath .. "." .. xmlElementName
        schema:register(XMLValueType.NODE_INDEX, soundPath .. "#linkNode", "Link node for 3d sound")
        schema:register(XMLValueType.VECTOR_TRANS, soundPath .. "#linkNodeOffset", "Sound source will be offset by this value to the link node")
        schema:register(XMLValueType.STRING, soundPath .. "#template", "Sound template name")
        schema:registerAutoCompletionDataSource(soundPath .. "#template", "$data/sounds/soundTemplates.xml", "soundTemplates.template#name")
        SoundManager.registerGenericSampleXMLPaths(schema, soundPath)
        schema:resetXMLSharedRegistration("SoundManager_sound", basePath)
        schema:setSubSchemaIdentifier()
    end
end
function SoundManager.registerGenericSampleXMLPaths(schema, soundPath)
    schema:register(XMLValueType.STRING, soundPath .. "#parent", "Parent sample for inheritance")
    schema:register(XMLValueType.STRING, soundPath .. "#file", "Path to sound sample")
    schema:register(XMLValueType.FLOAT, soundPath .. "#outerRadius", "Outer radius", 5)
    schema:register(XMLValueType.FLOAT, soundPath .. "#innerRadius", "Inner radius", 80)
    schema:register(XMLValueType.INT, soundPath .. "#loops", "Number of loops (0 = infinite)", 1)
    schema:register(XMLValueType.BOOL, soundPath .. "#supportsReverb", "Flag to disable reverb", true)
    schema:register(XMLValueType.BOOL, soundPath .. "#isLocalSound", "While set for vehicle sounds it will only play for the player currently using the vehicle", false)
    schema:register(XMLValueType.STRING, soundPath .. "#priority", "Priority of the sound", "MEDIUM", false, EnumUtil.getKeys(AudioSourcePriority))
    schema:register(XMLValueType.BOOL, soundPath .. "#debug", "Flag to enable debug rendering", false)
    schema:register(XMLValueType.FLOAT, soundPath .. "#fadeIn", "Fade in time in seconds", 0)
    schema:register(XMLValueType.FLOAT, soundPath .. "#fadeOut", "Fade out time in seconds", 0)
    schema:register(XMLValueType.FLOAT, soundPath .. ".volume#indoor", "Indoor volume", 0.8)
    schema:register(XMLValueType.FLOAT, soundPath .. ".pitch#indoor", "Indoor pitch", 1)
    schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassGain#indoor", "Indoor lowpass gain", 0.8)
    schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassCutoffFrequency#indoor", "Indoor lowpass cutoff frequency", 5000)
    schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassResonance#indoor", "Indoor lowpass resonance", 2)
    schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassCutoffFrequency#outdoor", "Outdoor lowpass cutoff frequency", 5000)
    schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassResonance#outdoor", "Outdoor lowpass resonance", 2)
    schema:register(XMLValueType.FLOAT, soundPath .. ".volume#outdoor", "Outdoor volume", 1)
    schema:register(XMLValueType.FLOAT, soundPath .. ".pitch#outdoor", "Outdoor pitch", 1)
    schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassGain#outdoor", "Outdoor lowpass gain", 1)
    schema:register(XMLValueType.FLOAT, soundPath .. "#volumeScale", "Additional scale that is applied on the volume attributes", 1)
    schema:register(XMLValueType.FLOAT, soundPath .. "#pitchScale", "Additional pitch that is applied on the volume attributes", 1)
    schema:register(XMLValueType.FLOAT, soundPath .. "#lowpassGainScale", "Additional lowpass gain that is applied on the volume attributes", 1)
    schema:register(XMLValueType.FLOAT, soundPath .. "#loopSynthesisRPMRatio", "Ratio between rpm in the gls file and actual rpm of the motor (e.g. 0.9: max. rpm in the gls file will be reached at 90% of motor rpm)", 1)
    SoundManager.registerModifierXMLPaths(schema, soundPath .. ".volume")
    SoundManager.registerModifierXMLPaths(schema, soundPath .. ".pitch")
    SoundManager.registerModifierXMLPaths(schema, soundPath .. ".lowpassGain")
    SoundManager.registerModifierXMLPaths(schema, soundPath .. ".loopSynthesisRpm")
    SoundManager.registerModifierXMLPaths(schema, soundPath .. ".loopSynthesisLoad")
    schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#minVolume", "Min volume")
    schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#maxVolume", "Max volume")
    schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#minPitch", "Max pitch")
    schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#maxPitch", "Max pitch")
    schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#minLowpassGain", "Max lowpass gain")
    schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#maxLowpassGain", "Max lowpass gain")
    schema:register(XMLValueType.BOOL, soundPath .. ".randomization(?)#isInside", "Randomization is applied inside", true)
    schema:register(XMLValueType.BOOL, soundPath .. ".randomization(?)#isOutside", "Randomization is applied outside", true)
    schema:register(XMLValueType.STRING, soundPath .. ".sourceRandomization(?)#file", "Path to sound sample")
end
if g_xmlManager ~= nil then
    g_xmlManager:addCreateSchemaFunction(function()
        SoundManager.soundTemplatesXmlSchema = XMLSchema.new("soundTemplates")
        SoundManager.soundTemplatesXmlSchema.supportsParentFile = false
    end)
    g_xmlManager:addInitSchemaFunction(function()
        local schema = SoundManager.soundTemplatesXmlSchema
        schema:register(XMLValueType.STRING, "soundTemplates.template(?)#name", "Name of the sound template", nil, true)
        SoundManager.registerGenericSampleXMLPaths(schema, "soundTemplates.template(?)")
    end)
end