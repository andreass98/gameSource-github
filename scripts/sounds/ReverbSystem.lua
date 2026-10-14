ReverbSystem = {}
local ReverbSystem_mt = Class(ReverbSystem)
function ReverbSystem.getName(index)
    for name, id in pairs(Reverb) do
        if id == index then
            return name
        end
    end
    return nil
end
function ReverbSystem.new(mission, customMt)
    -- upvalues: (copy) ReverbSystem_mt
    local self = setmetatable({}, customMt or ReverbSystem_mt)
    self.mission = mission
    self.isDebugViewActive = false
    self.AREA_TYPE_TO_REVERB_TYPE = {}
    self.AREA_TYPE_TO_REVERB_TYPE[AreaType.OPEN_FIELD] = Reverb.GS_OPEN_FIELD
    self.AREA_TYPE_TO_REVERB_TYPE[AreaType.OPEN_WATER] = Reverb.GS_OPEN_FIELD
    self.AREA_TYPE_TO_REVERB_TYPE[AreaType.CITY] = Reverb.GS_CITY
    self.AREA_TYPE_TO_REVERB_TYPE[AreaType.VILLAGE] = Reverb.GS_CITY
    self.AREA_TYPE_TO_REVERB_TYPE[AreaType.HARBOR] = Reverb.GS_CITY
    self.AREA_TYPE_TO_REVERB_TYPE[AreaType.INDUSTRIAL] = Reverb.GS_CITY
    self.blendFactor = 0
    self.reverbType1 = Reverb.GS_OPEN_FIELD
    self.reverbType2 = Reverb.GS_OPEN_FIELD
    self.targetReverbTypes = {}
    self.targetReverbTypes[1] = {
        ["type"] = Reverb.GS_OPEN_FIELD,
        ["weight"] = 1
    }
    self.targetReverbTypes[2] = {
        ["type"] = Reverb.GS_OPEN_FIELD,
        ["weight"] = 0
    }
    return self
end
function ReverbSystem:loadMapData(mapXmlFile, _, baseDirectory)
    local xmlFilename = "data/sounds/reverbSettings.xml"
    local customXmlFilename = getXMLString(mapXmlFile, "map.sounds#reverbFilename")
    if customXmlFilename ~= nil then
        local customXmlFilename = Utils.getFilename(customXmlFilename, baseDirectory)
        if fileExists(customXmlFilename) then
            xmlFilename = customXmlFilename
        else
            Logging.warning("ReverbSystem custom config file not found!")
        end
    end
    self.xmlFilename = xmlFilename
    addConsoleCommand("gsReverbSystemToggleDebugView", "Toggles the reverb debug view", "consoleCommandToggleDebugView", self)
    addConsoleCommand("gsReverbSystemSettingsReload", "Reloads the reverb settings", "consoleCommandReloadSettings", self)
    return self:loadSettings()
end
function ReverbSystem:loadSettings()
    local xmlFile = XMLFile.load("ReverbSettings", self.xmlFilename, nil)
    if xmlFile == nil then
        Logging.xmlWarning(xmlFile, "ReverbSystem could not load configuration xml file!")
        return false
    end
    for _, settingKey in xmlFile:iterator("reverbSettings.reverbSetting") do
        local id = xmlFile:getString(settingKey .. "#id")
        if id == nil then
            Logging.warning("ReverbSystem: missing id for reverb setting \'%s\'!", settingKey)
        else
            local presetId = string.upper(id)
            if Reverb[presetId] == nil then
                Logging.warning("ReverbSystem: Invalid id \'%s\' for reverb setting \'%s\'!", presetId, settingKey)
            else
                local presetId = Reverb[presetId]
                local lateReverbGain, lateReverbDelay = getLateReverbGainPreset(presetId)
                local gain = xmlFile:getFloat(settingKey .. ".lateReverb#gain", lateReverbGain)
                local gain = xmlFile:getFloat(settingKey .. ".lateReverb#delay", lateReverbDelay)
                local gain, gainHF, gainLF = getReverbGainPreset(presetId)
                local decayTime = xmlFile:getFloat(settingKey .. ".gain#gain", gain)
                local decayTime = xmlFile:getFloat(settingKey .. ".gain#gainHF", gainHF)
                local decayTime = xmlFile:getFloat(settingKey .. ".gain#gainLF", gainLF)
                local decayTime, decayHFRatio = getReverbDecayPreset(presetId)
                local reflectionsGain = xmlFile:getFloat(settingKey .. ".decay#time", decayTime)
                local reflectionsGain = xmlFile:getFloat(settingKey .. ".decay#ratioHF", decayHFRatio)
                local reflectionsGain, reflectionsDelay = getReverbReflectionPreset(presetId)
                local referenceHF = xmlFile:getFloat(settingKey .. ".reflections#gain", reflectionsGain)
                local referenceHF = xmlFile:getFloat(settingKey .. ".reflections#delay", reflectionsDelay)
                local referenceHF, referenceLF = getReverbReferenceFrequenciesPreset(presetId)
                local referenceHF = xmlFile:getFloat(settingKey .. ".reference#referenceHF", referenceHF)
                local referenceLF = xmlFile:getFloat(settingKey .. ".reference#referenceLF", referenceLF)
                if referenceHF <= 0 then
                    Logging.xmlError(xmlFile, "Reverb setting \'referenceHF\' at \'%s\' needs to be bigger than 0", settingKey)
                elseif referenceLF <= 0 then
                    Logging.xmlError(xmlFile, "Reverb setting \'referenceLF\' at \'%s\' needs to be bigger than 0", settingKey)
                else
                    setReverbPreset(presetId, decayTime, decayTime, decayTime, reflectionsGain, reflectionsGain, referenceHF, referenceHF, gain, gain, referenceHF, referenceLF)
                end
            end
        end
    end
    xmlFile:delete()
    return true
end
function ReverbSystem:delete()
    g_debugManager:removeDrawable(self)
    removeConsoleCommand("gsReverbSystemToggleDebugView")
    removeConsoleCommand("gsReverbSystemSettingsReload")
    self.mission = nil
end
function ReverbSystem:update(dt)
    if self.mission == nil then
        return
    end
    local areaWeights = self.mission.environmentAreaSystem:getAreaWeights()
    local reverbType1 = nil
    local reverbType2 = nil
    local reverbType1Weight = 0
    local reverbType2Weight = 0
    for areaTypeIndex, weight in pairs(areaWeights.areaTypeWeights) do
        local reverbTypeIndex = self.AREA_TYPE_TO_REVERB_TYPE[areaTypeIndex]
        if reverbTypeIndex ~= nil then
            local weight
            if reverbType1 == nil then
                reverbType1Weight = weight
                reverbType1 = reverbTypeIndex
            elseif reverbType2 ~= nil and reverbType2Weight >= weight then
                weight = reverbType2Weight
                reverbTypeIndex = reverbType2
            end
            reverbType1, reverbType2, reverbType1Weight, reverbType2Weight = self:sortTypes(reverbType1, reverbTypeIndex, reverbType1Weight, weight)
        end
    end
    if reverbType2 == nil or reverbType2Weight < areaWeights.isInForestWeight then
        reverbType1, reverbType2, reverbType1Weight, reverbType2Weight = self:sortTypes(reverbType1, Reverb.GS_FOREST, reverbType1Weight, areaWeights.isInForestWeight)
    end
    if reverbType2 == nil or reverbType2Weight < areaWeights.isNearWallWeight then
        reverbType1, reverbType2, reverbType1Weight, reverbType2Weight = self:sortTypes(reverbType1, Reverb.GS_CITY, reverbType1Weight, areaWeights.isNearWallWeight)
    end
    if reverbType2 == nil or areaWeights.isUnderRoofWeight > 0.4 then
        reverbType1, reverbType2, reverbType1Weight, reverbType2Weight = self:sortTypes(reverbType1, Reverb.GS_INDOOR_HALL, reverbType1Weight, 1)
    end
    local sum = reverbType1 or Reverb.GS_OPEN_FIELD
    local sum = reverbType2 or Reverb.GS_OPEN_FIELD
    local sum = reverbType1Weight + reverbType2Weight
    local sum = sum == 0 and 1 or sum
    self.targetReverbTypes[1].type = sum
    self.targetReverbTypes[1].weight = reverbType1Weight / sum
    self.targetReverbTypes[1].name = ReverbSystem.getName(sum)
    self.targetReverbTypes[2].type = sum
    self.targetReverbTypes[2].name = ReverbSystem.getName(sum)
    self.targetReverbTypes[2].weight = reverbType2Weight / sum
    local areaTypeIndex = true
    if self.reverbType1 ~= self.targetReverbTypes[1].type then
        areaTypeIndex = self.reverbType1 == self.targetReverbTypes[2].type
    end
    local weight
    if not (self.reverbType1 == self.reverbType2) then
        if self.reverbType2 == self.targetReverbTypes[1].type then
            ::l36::
            local reverbTypeIndex = self.reverbType1
            local newReverbType2 = self.reverbType2
            if areaTypeIndex and true then
                local targetBlendFactor = 1 - self.targetReverbTypes[1].weight
                if self.reverbType1 ~= self.targetReverbTypes[1].type then
                    targetBlendFactor = self.targetReverbTypes[1].weight
                end
                if targetBlendFactor < self.blendFactor then
                    self.blendFactor = math.max(self.blendFactor - dt / 400, targetBlendFactor)
                else
                    self.blendFactor = math.min(self.blendFactor + fadeDelta, targetBlendFactor)
                end
            elseif areaTypeIndex then
                if self.blendFactor == 0 then
                    if self.reverbType1 == self.targetReverbTypes[1].type then
                        newReverbType2 = self.targetReverbTypes[2].type
                    else
                        newReverbType2 = self.targetReverbTypes[1].type
                    end
                end
                self.blendFactor = math.max(self.blendFactor - fadeDelta, 0)
            else
                if self.blendFactor == 1 then
                    if self.reverbType2 == self.targetReverbTypes[1].type then
                        reverbTypeIndex = self.targetReverbTypes[2].type
                    else
                        reverbTypeIndex = self.targetReverbTypes[1].type
                    end
                end
                self.blendFactor = math.min(self.blendFactor + fadeDelta, 1)
            end
            self.reverbType1 = reverbTypeIndex
            self.reverbType2 = newReverbType2
            setReverbEffect(SoundManager.DEFAULT_REVERB_EFFECT, self.reverbType1, self.reverbType2, self.blendFactor)
            return
        end
    end
    weight = self.reverbType2 == self.targetReverbTypes[2].type
    goto l36
end
function ReverbSystem.sortTypes(_, reverbType1, reverbType2, reverbType1Weight, reverbType2Weight)
    if reverbType1 == nil or reverbType2 == nil then
    elseif reverbType1Weight >= reverbType2Weight then
    end
    return reverbType2, reverbType1, reverbType2Weight, reverbType1Weight
end
function ReverbSystem:drawDebug()
    setTextBold(false)
    setTextColor(1, 1, 1, 1)
    renderText(0.7, 0.5, 0.012, string.format("Current: %s %.3f -> %s %.3f", ReverbSystem.getName(self.reverbType1), 1 - self.blendFactor, ReverbSystem.getName(self.reverbType2), self.blendFactor))
    renderText(0.7, 0.45, 0.012, string.format("Target: %s %.3f -> %s %.3f", self.targetReverbTypes[1].name, self.targetReverbTypes[1].weight, self.targetReverbTypes[2].name, self.targetReverbTypes[2].weight))
end
function ReverbSystem:consoleCommandToggleDebugView()
    self.isDebugViewActive = not self.isDebugViewActive
    if self.isDebugViewActive then
        g_debugManager:addDrawable(self)
    else
        g_debugManager:removeDrawable(self)
    end
end
function ReverbSystem:consoleCommandReloadSettings()
    self:loadSettings()
    return "Reloaded settings"
end