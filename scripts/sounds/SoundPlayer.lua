SoundPlayer = {}
local SoundPlayer_mt = Class(SoundPlayer)
function SoundPlayer.new(appBasePath, webDataXMLFile, localDataXMLFilename, localFolder, userLocalFolder, languageShort, soundGroup)
    -- upvalues: (copy) SoundPlayer_mt
    local self = setmetatable({}, SoundPlayer_mt)
    self.soundPlayerId = createSoundPlayer("SoundPlayer", appBasePath, webDataXMLFile, localDataXMLFilename, localFolder, userLocalFolder, languageShort, soundGroup)
    if self.soundPlayerId == nil or self.soundPlayerId == 0 then
        print("Could not create sound player")
        return nil
    end
    self.channelNameReplacements = {}
    self.channelIcons = {}
    self:loadReplacements({ localFolder, userLocalFolder })
    self.currentChannel = 0
    self.currentItem = 0
    self.initialized = false
    self.currentChannelName = ""
    self.currentItemName = ""
    self.updateTimer = 0
    self.switchInNextFrame = false
    self.channelItemMapping = {}
    self.eventListener = {}
    self.streamingAccessOwner = nil
    return self
end
function SoundPlayer:delete()
    self.channelNameReplacements = {}
    self.channelIcons = {}
    if self.soundPlayerId ~= nil then
        delete(self.soundPlayerId)
    end
end
function SoundPlayer:update(dt)
    if isSoundPlayerLoaded(self.soundPlayerId) and self.isPlaying then
        if isSoundPlayerPlaying(self.soundPlayerId) then
            self.updateTimer = self.updateTimer + dt
            if self.updateTimer > 500 then
                local channelName = self:getChannelName()
                local itemName = self:getItemName()
                if channelName ~= nil and (itemName ~= nil and (channelName ~= self.currentChannelName or itemName ~= self.currentItemName)) then
                    self:onChange(channelName, itemName, (getIsSoundPlayerChannelStreamed(self.soundPlayerId, self.currentChannel)))
                    self.currentChannelName = channelName
                    self.currentItemName = itemName
                end
                self.updateTimer = 0
            end
            self.switchInNextFrame = false
            return
        end
        if not getIsSoundPlayerChannelStreamed(self.soundPlayerId, self.currentChannel) then
            if self.switchInNextFrame then
                self:nextItem()
                self.switchInNextFrame = false
                return
            end
            self.switchInNextFrame = true
        end
    end
end
function SoundPlayer:loadReplacements(folders)
    for _, folder in ipairs(folders) do
        local filename = folder .. "/music.xml"
        if fileExists(filename) then
            local xmlFile = XMLFile.load("music", filename)
            xmlFile:iterate("music.radio.channels.channel", function(_, key)
                -- upvalues: (copy) xmlFile, (copy) self
                local name = xmlFile:getString(key .. "#name")
                local replacement = xmlFile:getString(key .. "#replacement")
                local icon = Utils.getFilename(xmlFile:getString(key .. "#icon"))
                if name ~= nil and replacement ~= nil then
                    self.channelNameReplacements[string.lower(name)] = replacement
                    if icon ~= nil then
                        self.channelIcons[string.lower(name)] = icon
                    end
                end
            end)
            xmlFile:delete()
        end
    end
end
function SoundPlayer:onChange(channelName, itemName, isOnlineStream)
    local name = string.lower(channelName)
    channelName = self.channelNameReplacements[name] or channelName
    for _, eventListener in ipairs(self.eventListener) do
        eventListener:onSoundPlayerChange(channelName, itemName, isOnlineStream, self.channelIcons[name])
    end
end
function SoundPlayer:addEventListener(listener)
    if listener ~= nil then
        table.addElement(self.eventListener, listener)
    end
end
function SoundPlayer:removeEventListener(listener)
    if listener ~= nil then
        table.removeElement(self.eventListener, listener)
    end
end
function SoundPlayer:setStreamingAccessOwner(owner)
    self.streamingAccessOwner = owner
end
function SoundPlayer:updateMetaData()
    local channelName = getSoundPlayerChannelName(self.soundPlayerId, self.currentChannel)
    local itemName = getSoundPlayerItemName(self.soundPlayerId)
    self.currentChannelName = channelName
    self.currentItemName = itemName
    self:onChange(channelName, itemName, (getIsSoundPlayerChannelStreamed(self.soundPlayerId, self.currentChannel)))
end
function SoundPlayer:previousChannel()
    if isSoundPlayerLoaded(self.soundPlayerId) then
        local lastChannel = self.currentChannel
        self.currentChannel = self.currentChannel - 1
        if self.currentChannel < 0 then
            self.currentChannel = getNumSoundPlayerChannels(self.soundPlayerId) - 1
        end
        if lastChannel ~= self.currentChannel then
            self:changeChannel(lastChannel)
            return true
        end
    end
    return false
end
function SoundPlayer:nextChannel()
    if isSoundPlayerLoaded(self.soundPlayerId) then
        local lastChannel = self.currentChannel
        self.currentChannel = self.currentChannel + 1
        if self.currentChannel >= getNumSoundPlayerChannels(self.soundPlayerId) then
            self.currentChannel = 0
        end
        if lastChannel ~= self.currentChannel then
            self:changeChannel(lastChannel)
            return true
        end
    end
    return false
end
function SoundPlayer:startChannel()
    self.currentItem = Utils.getNoNil(self.channelItemMapping[self.currentChannel], 0)
    setSoundPlayerChannel(self.soundPlayerId, self.currentChannel)
    setSoundPlayerItem(self.soundPlayerId, self.currentItem)
    self:play()
    self:updateMetaData()
end
function SoundPlayer:changeChannel(lastChannel)
    if self.streamingAccessOwner == nil or not getIsSoundPlayerChannelStreamed(self.soundPlayerId, self.currentChannel) then
        self:startChannel()
    else
        if getIsSoundPlayerChannelStreamed(self.soundPlayerId, lastChannel) then
            self:pause()
        end
        self.streamingAccessOwner:onSoundPlayerStreamAccess()
    end
end
function SoundPlayer:setStreamAccessAllowed(yes)
    if not yes then
        while getIsSoundPlayerChannelStreamed(self.soundPlayerId, self.currentChannel) do
            self.currentChannel = self.currentChannel + 1
            if self.currentChannel >= getNumSoundPlayerChannels(self.soundPlayerId) then
                self.currentChannel = 0
            end
        end
    end
    self:startChannel()
end
function SoundPlayer:nextItem()
    if isSoundPlayerLoaded(self.soundPlayerId) then
        self.currentItem = self.currentItem + 1
        if self.currentItem >= getNumSoundPlayerItems(self.soundPlayerId) then
            self.currentItem = 0
        end
        if self.currentItem ~= self.currentItem or getNumSoundPlayerItems(self.soundPlayerId) == 1 then
            setSoundPlayerItem(self.soundPlayerId, self.currentItem)
            self.channelItemMapping[self.currentChannel] = self.currentItem
            self:play()
            self:updateMetaData()
            return true
        end
    end
    return false
end
function SoundPlayer:previousItem()
    if isSoundPlayerLoaded(self.soundPlayerId) then
        self.currentItem = self.currentItem - 1
        if self.currentItem < 0 then
            self.currentItem = getNumSoundPlayerItems(self.soundPlayerId) - 1
        end
        if self.currentItem ~= self.currentItem or getNumSoundPlayerItems(self.soundPlayerId) == 1 then
            setSoundPlayerItem(self.soundPlayerId, self.currentItem)
            self.channelItemMapping[self.currentChannel] = self.currentItem
            self:play()
            self:updateMetaData()
            return true
        end
    end
    return false
end
function SoundPlayer:play()
    if not isSoundPlayerLoaded(self.soundPlayerId) then
        return false
    end
    self:initializeSoundPlayer()
    playSoundPlayer(self.soundPlayerId)
    self:updateMetaData()
    self.isPlaying = true
    return true
end
function SoundPlayer:pause()
    if isSoundPlayerLoaded(self.soundPlayerId) then
        self.isPlaying = false
        self.switchInNextFrame = false
        self.currentChannelName = ""
        self.currentItemName = ""
        if isSoundPlayerPlaying(self.soundPlayerId) then
            pauseSoundPlayer(self.soundPlayerId)
            return true
        end
    end
    return false
end
function SoundPlayer:getIsPlaying()
    return self.isPlaying
end
function SoundPlayer:getChannelName()
    if isSoundPlayerLoaded(self.soundPlayerId) then
        return getSoundPlayerChannelName(self.soundPlayerId, self.currentChannel)
    else
        return nil
    end
end
function SoundPlayer:getItemName()
    if isSoundPlayerLoaded(self.soundPlayerId) then
        return getSoundPlayerItemName(self.soundPlayerId)
    else
        return nil
    end
end
function SoundPlayer:initializeSoundPlayer()
    if not self.initialized and isSoundPlayerLoaded(self.soundPlayerId) then
        local i = 0
        for i = i, 3 do
            setSoundPlayerChannel(self.soundPlayerId, i)
            local numSoundPlayerItems = getNumSoundPlayerItems(self.soundPlayerId) - 1
            if numSoundPlayerItems >= 0 then
                self.channelItemMapping[i] = math.random(0, numSoundPlayerItems)
            else
                self.channelItemMapping[i] = 0
            end
        end
        self.currentChannel = math.random(0, 3)
        setSoundPlayerChannel(self.soundPlayerId, self.currentChannel)
        self.currentItem = self.channelItemMapping[self.currentChannel]
        setSoundPlayerItem(self.soundPlayerId, self.currentItem)
        self.initialized = true
    end
end