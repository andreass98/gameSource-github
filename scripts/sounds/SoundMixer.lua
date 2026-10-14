SoundMixer = {}
local SoundMixer_mt = Class(SoundMixer)
function SoundMixer.new(customMt)
    -- upvalues: (copy) SoundMixer_mt
    local self = setmetatable({}, customMt or SoundMixer_mt)
    g_messageCenter:subscribe(MessageType.GAME_STATE_CHANGED, self.onGameStateChanged, self)
    self.masterVolume = 1
    self.gameStates = {}
    self.volumes = {}
    self.volumeFactors = {}
    self.volumeChangedListeners = {}
    for _, groupIndex in pairs(AudioGroup.groups) do
        self.volumeFactors[groupIndex] = 1
        self.volumeChangedListeners[groupIndex] = {}
    end
    addConsoleCommand("gsSoundMixerDebug", "Toggle sound mixer debug mode", "consoleCommandToggleDebug", self)
    return self
end
function SoundMixer:loadFromXML(xmlFilepath)
    for _, groupIndex in pairs(AudioGroup.groups) do
        self.volumeFactors[groupIndex] = self.volumeFactors[groupIndex] or 1
        self.volumeChangedListeners[groupIndex] = self.volumeChangedListeners[groupIndex] or {}
    end
    local xmlFile = loadXMLFile("soundMixerXML", xmlFilepath)
    if xmlFile ~= nil and xmlFile ~= 0 then
        local i = 0
        while true do
            local gameStateKey = string.format("soundMixer.gameState(%d)", i)
            if not hasXMLProperty(xmlFile, gameStateKey) then
                break
            end
            local _ = getXMLString(xmlFile, gameStateKey .. "#name")
            local groupIndex = g_gameStateManager:getGameStateIndexByName(_)
            if groupIndex == nil then
                Logging.xmlWarning(xmlFile, "Game-State \'%s\' is not defined for state \'%s\'!", _, gameStateKey)
            else
                local gameState = {}
                local j = 0
                while true do
                    local audioGroupKey = string.format("%s.audioGroup(%d)", gameStateKey, j)
                    if not hasXMLProperty(xmlFile, audioGroupKey) then
                        break
                    end
                    local name = getXMLString(xmlFile, audioGroupKey .. "#name")
                    local volume = getXMLFloat(xmlFile, audioGroupKey .. "#volume") or 1
                    local fadeInDuration = (getXMLFloat(xmlFile, audioGroupKey .. "#fadeOutDuration") or 0.5) * 1000
                    local fadeOutDuration = (getXMLFloat(xmlFile, audioGroupKey .. "#fadeOutDuration") or 0.5) * 1000
                    local audioGroupIndex = AudioGroup.getAudioGroupIndexByName(name)
                    if audioGroupIndex == nil then
                        Logging.xmlWarning(xmlFile, "Audio-Group \'%s\' in game state \'%s\' (%s) is not defined!", name, _, gameStateKey)
                    else
                        gameState[audioGroupIndex] = {
                            ["volume"] = volume,
                            ["fadeInDuration"] = fadeInDuration,
                            ["fadeOutDuration"] = fadeOutDuration
                        }
                    end
                    j = j + 1
                end
                self.gameStates[groupIndex] = gameState
            end
            i = i + 1
        end
        delete(xmlFile)
    end
    local i = g_gameStateManager:getGameState()
    local gameStateKey = self.gameStates[i] or self.gameStates[GameState.LOADING]
    for j, audioGroupKey in ipairs(AudioGroup.groups) do
        if gameStateKey then
            local name = gameStateKey[audioGroupKey]
        end
        self.volumes[audioGroupKey] = 0
        setAudioGroupVolume(audioGroupKey, 0)
    end
end
function SoundMixer:delete()
    g_messageCenter:unsubscribeAll(self)
    removeConsoleCommand("gsSoundMixerDebug")
end
function SoundMixer:update(dt)
    if self.isDirty then
        local gameStateIndex = g_gameStateManager:getGameState()
        local gameState = self.gameStates[gameStateIndex]
        if gameState ~= nil then
            local isDone = true
            for audioGroupIndex, data in pairs(gameState) do
                local currentVolume = self.volumes[audioGroupIndex]
                local target = data.volume * self.volumeFactors[audioGroupIndex]
                if currentVolume ~= target then
                    isDone = false
                    local dir = 1
                    local func = math.min
                    local fadeDuration = data.fadeInDuration
                    if target < currentVolume then
                        dir = -1
                        func = math.max
                        fadeDuration = data.fadeOutDuration
                    end
                    local changePerFrame = 1
                    if fadeDuration > 0 then
                        changePerFrame = dt / fadeDuration
                    end
                    local currentVolume = func(currentVolume + dir * changePerFrame, target)
                    setAudioGroupVolume(audioGroupIndex, currentVolume)
                    self.volumes[audioGroupIndex] = currentVolume
                    for _, listener in ipairs(self.volumeChangedListeners[audioGroupIndex]) do
                        listener.func(listener.target, audioGroupIndex, currentVolume)
                    end
                end
            end
            if isDone then
                self.isDirty = false
            end
        end
    end
end
function SoundMixer:immediateUpdate()
    self:update(99999)
end
function SoundMixer:drawDebug()
    local gameStateIndex = g_gameStateManager:getGameState()
    local gameStateName = "None"
    for stateName, stateValue in pairs(GameState) do
        if stateValue == gameStateIndex then
            gameStateName = stateName
            break
        end
    end
    renderText(0.8, 0.7, 0.015, string.format("current GameState: %s (%d)", gameStateName, gameStateIndex or -1))
    local lineIndex = 1
    setTextAlignment(RenderText.ALIGN_RIGHT)
    renderText(0.83, 0.7 - lineIndex * 0.015, 0.015, "AudioGroup")
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(0.85, 0.7 - lineIndex * 0.015, 0.015, "curVol")
    renderText(0.9, 0.7 - lineIndex * 0.015, 0.015, "targetVol")
    renderText(0.95, 0.7 - lineIndex * 0.015, 0.015, "volFactor")
    local lineIndex = lineIndex + 1
    for audioGroupIndex, audioGroupData in pairs(self.gameStates[gameStateIndex]) do
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(0.83, 0.7 - lineIndex * 0.015, 0.015, string.format("%s (%d)", AudioGroup.getAudioGroupNameByIndex(audioGroupIndex), audioGroupIndex))
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(0.85, 0.7 - lineIndex * 0.015, 0.015, string.format("%.2f", self.volumes[audioGroupIndex]))
        renderText(0.9, 0.7 - lineIndex * 0.015, 0.015, string.format("%.2f", audioGroupData.volume * self.volumeFactors[audioGroupIndex]))
        renderText(0.95, 0.7 - lineIndex * 0.015, 0.015, string.format("%.2f", self.volumeFactors[audioGroupIndex]))
        lineIndex = lineIndex + 1
    end
end
function SoundMixer:setAudioGroupVolumeFactor(audioGroupIndex, factor)
    if audioGroupIndex ~= nil and self.volumeFactors[audioGroupIndex] ~= nil then
        self.volumeFactors[audioGroupIndex] = factor
        self.isDirty = true
    end
end
function SoundMixer:getAudioGroupVolume(audioGroupIndex)
    return self.volumes[audioGroupIndex]
end
function SoundMixer:setMasterVolume(masterVolume)
    self.masterVolume = masterVolume
    setMasterVolume(masterVolume)
end
function SoundMixer:onGameStateChanged(gameStateId, _)
    if self.gameStates[gameStateId] ~= nil then
        self.isDirty = true
    end
end
function SoundMixer:addVolumeChangedListener(audioGroupIndex, func, target)
    if self.volumeChangedListeners[audioGroupIndex] == nil then
        self.volumeChangedListeners[audioGroupIndex] = {}
    end
    table.addElement(self.volumeChangedListeners[audioGroupIndex], {
        ["func"] = func,
        ["target"] = target
    })
end
function SoundMixer:consoleCommandToggleDebug()
    self.debugEnabled = not self.debugEnabled
    if g_debugManager ~= nil then
        if self.debugEnabled then
            g_debugManager:addDrawable(self)
        else
            g_debugManager:removeDrawable(self)
        end
    end
    return string.format("SoundMixer debugEnabled = %s", self.debugEnabled)
end