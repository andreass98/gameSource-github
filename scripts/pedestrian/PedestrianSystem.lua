PedestrianSystem = {}
local PedestrianSystem_mt = Class(PedestrianSystem)
g_xmlManager:addCreateSchemaFunction(function()
    PedestrianSystem.xmlSchema = XMLSchema.new("pedestrianSystem")
end)
g_xmlManager:addInitSchemaFunction(function()
    local schema = PedestrianSystem.xmlSchema
    PlayerStyle.registerSavegameXMLPaths(schema, "pedestrianSystem.pedestrians.pedestrian(?).style")
    schema:register(XMLValueType.STRING, "pedestrianSystem.pedestrians.pedestrian(?)#variation", "Name of the variation", nil, false, { "male", "female", "unisex" })
    schema:register(XMLValueType.DAY_TIME, "pedestrianSystem.pedestrians.pedestrian(?)#timeFrom", "Start day time of pedestrian visibility")
    schema:register(XMLValueType.DAY_TIME, "pedestrianSystem.pedestrians.pedestrian(?)#timeTo", "End day time of pedestrian visibility")
    schema:register(XMLValueType.STRING, "pedestrianSystem.pedestrians.pedestrian(?).groups.group(?)#name", "Name of the pedestrian group")
    schema:register(XMLValueType.STRING, "pedestrianSystem.pedestrians.pedestrian(?).idleAnimation#animationName", "Name of the idle animation")
    schema:register(XMLValueType.STRING, "pedestrianSystem.pedestrians.pedestrian(?).staticIdleAnimation(?)#animationName", "Name of the static idle animation")
    schema:register(XMLValueType.STRING, "pedestrianSystem.pedestrians.pedestrian(?).walkAnimation#animationName", "Name of the walk animation")
    schema:register(XMLValueType.STRING, "pedestrianSystem.pedestrians.pedestrian(?).walkAnimation#blendWithAnimationName", "Name of the blend animation")
    schema:register(XMLValueType.FLOAT, "pedestrianSystem.pedestrians.pedestrian(?).walkAnimation#distance", "Animatio distance")
    schema:register(XMLValueType.FLOAT, "pedestrianSystem.pedestrians.pedestrian(?).walkAnimation#speedScaleMin", "Min speed scale of the animation")
    schema:register(XMLValueType.FLOAT, "pedestrianSystem.pedestrians.pedestrian(?).walkAnimation#speedScaleMax", "Max speed scale of the animation")
    schema:register(XMLValueType.FLOAT, "pedestrianSystem.pedestrians.pedestrian(?).walkAnimation.stepSoundTrigger(?)#time", "Time of the step sound trigger")
    schema:register(XMLValueType.STRING, "pedestrianSystem.groups.group(?)#name", "Name of the group")
    schema:register(XMLValueType.FLOAT, "pedestrianSystem.groups.group(?)#spawnWeight", "Weight of the group")
    schema:register(XMLValueType.BOOL, "pedestrianSystem.groups.group(?)#allowHeadTurn", "If the pedestrian can turn the head to the player")
    schema:register(XMLValueType.DAY_TIME, "pedestrianSystem.groups.group(?)#timeFrom", "Start day time of pedestrian visibility")
    schema:register(XMLValueType.DAY_TIME, "pedestrianSystem.groups.group(?)#timeTo", "End day time of pedestrian visibility")
    schema:register(XMLValueType.STRING, "pedestrianSystem.groups.group(?).sounds.sound(?)#name", "Name of the sound")
    schema:register(XMLValueType.STRING, "pedestrianSystem.groups.group(?).sounds.sound(?)#filename", "Filename of the sound")
    schema:register(XMLValueType.FLOAT, "pedestrianSystem.groups.group(?).sounds.sound(?)#volume", "Volume of the sound")
    schema:register(XMLValueType.FLOAT, "pedestrianSystem.groups.group(?).sounds.sound(?)#indoorVolume", "Indoor volume of the sound")
    schema:register(XMLValueType.BOOL, "pedestrianSystem.groups.group(?).sounds.sound(?)#isWalkSound", "If sound is a walking sound")
end)
function PedestrianSystem.onCreate(_, transformId)
    if g_dedicatedServer == nil then
        local xmlFilename = getUserAttribute(transformId, "xmlFile")
        if xmlFilename == nil then
            Logging.error("Missing \'xmlFile\' user-attribute for pedestrian system in \'%s\'", I3DUtil.getNodePath(transformId))
        else
            local xmlFilename = Utils.getFilename(xmlFilename, g_currentMission.loadedMapBaseDirectory)
            PedestrianSystem.createFromXmlAndNode(xmlFilename, transformId)
        end
    else
        Logging.devInfo("PedestrianSystem not available on Dedicated Server Host")
        return
    end
end
function PedestrianSystem.createFromXmlAndNode(xmlFilename, transformId)
    local mission = g_currentMission
    local existingPedestrianSystem = mission:getPedestrianSystem()
    if existingPedestrianSystem ~= nil and existingPedestrianSystem.pedestrianSystemId ~= nil then
        Logging.error("Pedestrian system already present")
        return false
    end
    local pedestrianSystem = PedestrianSystem.new()
    if not pedestrianSystem:load(xmlFilename, transformId) then
        pedestrianSystem:delete()
        return false
    end
    if not mission:setPedestrianSystem(pedestrianSystem) then
        pedestrianSystem:delete()
        return false
    end
    mission:addUpdateable(pedestrianSystem)
    g_messageCenter:publish(MessageType.PEDESTRIAN_SYSTEM_LOADED, pedestrianSystem)
    return true
end
function PedestrianSystem.new()
    -- upvalues: (copy) PedestrianSystem_mt
    local self = setmetatable({}, PedestrianSystem_mt)
    self.pedestrianSystemId = nil
    self.isEnabled = false
    self.xmlFilename = nil
    self.transformId = nil
    self.baseDirectory = g_currentMission.loadingMapBaseDirectory
    return self
end
function PedestrianSystem:load(xmlFilename, transformId)
    local pedestrianSystemId = createPedestrianSystem(xmlFilename, transformId, CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT + CollisionFlag.ROAD, CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.TRAFFIC_VEHICLE, AudioGroup.ENVIRONMENT)
    if pedestrianSystemId == 0 then
        Logging.error("Unable to create PedestrianSystem from \'%s\' and \'%s\'", xmlFilename, I3DUtil.getNodePath(transformId))
        return false
    end
    local xmlFile = XMLFile.load("pedestrianSystem", xmlFilename, PedestrianSystem.xmlSchema)
    if xmlFile == nil then
        return false
    end
    self.pedestrianSystemId = pedestrianSystemId
    self.xmlFilename = xmlFilename
    self.transformId = transformId
    self.conditionFlags = ConditionFlags.new()
    self.conditionFlags:registerModifier("sun", nil)
    self.conditionFlags:registerModifier("rain", nil)
    self.conditionFlags:registerModifier("cloudy", nil)
    self.conditionFlags:registerModifier("snow", nil)
    self.conditionFlags:registerModifier("spring", nil)
    self.conditionFlags:registerModifier("summer", nil)
    self.conditionFlags:registerModifier("autumn", nil)
    self.conditionFlags:registerModifier("winter", nil)
    self.conditionFlags:registerXMLPaths(PedestrianSystem.xmlSchema, "pedestrianSystem.groups.group(?)")
    self.conditionFlags:registerXMLPaths(PedestrianSystem.xmlSchema, "pedestrianSystem.pedestrians.pedestrian(?)")
    self.groupNameToGroup = {}
    self.soundNameToId = {}
    for _, soundKey in xmlFile:iterator("pedestrianSystem.sounds.sound") do
        local soundName = xmlFile:getValue(soundKey .. "#name")
        local filename = xmlFile:getValue(soundKey .. "#filename")
        if filename == nil then
            Logging.xmlWarning(xmlFile, "Missing \'filename\' for pedestrian sound \'%s\'", soundKey)
        elseif soundName == nil then
            Logging.xmlWarning(xmlFile, "Missing \'name\' for pedestrian sound \'%s\'", soundKey)
        elseif self.soundNameToId[soundName] == nil then
            local volume = xmlFile:getValue(soundKey .. "#volume", 1)
            local indoorVolume = xmlFile:getValue(soundKey .. "#indoorVolume", 1)
            local isWalkSound = xmlFile:getValue(soundKey .. "#isWalkSound", true)
            local soundId = addPedestrianSound(pedestrianSystemId, filename, soundName, volume, indoorVolume, isWalkSound)
            self.soundNameToId[soundName] = soundId
        else
            Logging.xmlWarning(xmlFile, "Pedestrian sound name \'%s\' already used in \'%s\'", soundName, soundKey)
        end
    end
    for soundKey, soundName in xmlFile:iterator("pedestrianSystem.groups.group") do
        local filename = xmlFile:getValue(soundName .. "#name")
        if filename == nil then
            Logging.xmlWarning(xmlFile, "Missing \'name\' for pedestrian group \'%s\'", soundName)
        elseif self.groupNameToGroup[filename] == nil then
            local volume = xmlFile:getValue(soundName .. "#spawnWeight", 1)
            local indoorVolume = xmlFile:getValue(soundName .. "#allowHeadTurn", true)
            local isWalkSound = xmlFile:getValue(soundName .. "#timeFrom") or 0
            local soundId = xmlFile:getValue(soundName .. "#timeTo") or 86400000
            local requiredFlags, preventFlags = self.conditionFlags:loadFlagsFromXMLFile(xmlFile, soundName)
            local groupId = addPedestrianGroup(pedestrianSystemId, filename, volume, indoorVolume, requiredFlags, preventFlags, isWalkSound, soundId)
            self.groupNameToGroup[filename] = {
                ["groupId"] = groupId,
                ["timeFrom"] = isWalkSound,
                ["timeTo"] = soundId,
                ["requiredFlags"] = requiredFlags,
                ["preventFlags"] = preventFlags
            }
            for _, groupSoundKey in xmlFile:iterator(soundName .. ".sounds.sound") do
                local soundName = xmlFile:getValue(groupSoundKey .. "#name")
                local filename = xmlFile:getValue(groupSoundKey .. "#filename")
                if filename == nil then
                    Logging.xmlWarning(xmlFile, "Missing \'filename\' for pedestrian sound \'%s\'", groupSoundKey)
                elseif soundName == nil then
                    Logging.xmlWarning(xmlFile, "Missing \'name\' for pedestrian sound \'%s\'", groupSoundKey)
                elseif self.soundNameToId[soundName] == nil then
                    local volume = Utils.getFilename(filename, self.baseDirectory)
                    local volume = xmlFile:getValue(groupSoundKey .. "#volume", 1)
                    local indoorVolume = xmlFile:getValue(groupSoundKey .. "#indoorVolume", 1)
                    local isWalkSound = xmlFile:getValue(groupSoundKey .. "#isWalkSound", true)
                    local soundId = addPedestrianSound(pedestrianSystemId, volume, soundName, volume, indoorVolume, isWalkSound)
                    assignSoundToPedestrianGroup(pedestrianSystemId, groupId, soundId)
                else
                    Logging.xmlWarning(xmlFile, "Pedestrian sound name \'%s\' already used in \'%s\'", soundName, groupSoundKey)
                end
            end
        else
            Logging.xmlWarning(xmlFile, "Pedestrian group name \'%s\' already used in \'%s\'", filename, soundName)
        end
    end
    self.pedestrians = {}
    self.pedestrianNodes = {}
    self.pendingPedestrians = {}
    for soundKey, soundName in xmlFile:iterator("pedestrianSystem.pedestrians.pedestrian") do
        local filename = HumanGraphicsComponent.new()
        filename:initialize()
        filename.model.initIKChains = false
        link(getRootNode(), filename.graphicsRootNode)
        local volume, indoorVolume = self.conditionFlags:loadFlagsFromXMLFile(xmlFile, soundName)
        local isWalkSound = xmlFile:getValue(soundName .. "#timeFrom") or 0
        local soundId = xmlFile:getValue(soundName .. "#timeTo") or maxTime
        local requiredFlags = {
            ["graphics"] = filename,
            ["variationName"] = xmlFile:getValue(soundName .. "#variation", "male"),
            ["requiredFlags"] = volume,
            ["preventFlags"] = indoorVolume,
            ["timeFrom"] = isWalkSound,
            ["timeTo"] = soundId,
            ["groups"] = {},
            ["idleAnimationId"] = 0,
            ["staticIdleAnimationIds"] = {},
            ["walkAnimationId"] = 0
        }
        local preventFlags = xmlFile:getValue(soundName .. ".idleAnimation#animationName")
        if preventFlags ~= nil then
            requiredFlags.idleAnimationId = addPedestrianIdleAnimation(pedestrianSystemId, preventFlags)
        end
        for _, _ in xmlFile:iterator(soundName .. ".staticIdleAnimation") do
            local groupSoundKey = xmlFile:getValue(_ .. "#animationName")
            if groupSoundKey ~= nil then
                local soundName = addPedestrianIdleAnimation(pedestrianSystemId, groupSoundKey)
                table.insert(requiredFlags.staticIdleAnimationIds, soundName)
            end
        end
        local groupId = xmlFile:getValue(soundName .. ".walkAnimation#animationName")
        local blendWithAnimationName = xmlFile:getValue(soundName .. ".walkAnimation#blendWithAnimationName")
        local distance = xmlFile:getValue(soundName .. ".walkAnimation#distance")
        local _ = xmlFile:getValue(soundName .. ".walkAnimation#speedScaleMin")
        local _ = xmlFile:getValue(soundName .. ".walkAnimation#speedScaleMax")
        local groupSoundKey = {}
        for indoorVolume, isWalkSound in xmlFile:iterator(soundName .. ".walkAnimation.stepSoundTrigger") do
            local soundId = xmlFile:getValue(isWalkSound .. "#time")
            table.insert(groupSoundKey, soundId)
        end
        requiredFlags.walkAnimationId = addPedestrianWalkAnimation(pedestrianSystemId, groupId, blendWithAnimationName, distance, _, _, groupSoundKey)
        for indoorVolume, isWalkSound in xmlFile:iterator(soundName .. ".groups.group") do
            local soundId = xmlFile:getValue(isWalkSound .. "#name")
            if soundId == nil then
                Logging.xmlWarning(xmlFile, "Missing \'name\' for pedestrian group \'%s\'", isWalkSound)
            else
                local group = self.groupNameToGroup[soundId]
                if group == nil then
                    Logging.xmlWarning(xmlFile, "Pedestrian group name \'%s\' is not defined in \'%s\'", soundId, isWalkSound)
                else
                    table.insert(requiredFlags.groups, group.groupId)
                end
            end
        end
        local soundName = PlayerStyle.new()
        soundName:loadFromXMLFile(xmlFile, soundName .. ".style")
        filename:setStyleAsync(soundName, self.loadCharacterFinished, self, requiredFlags)
        self.pendingPedestrians[filename] = true
    end
    xmlFile:delete()
    addConsoleCommand("gsPedestrianSystemToggle", "Toggle pedestrian system", "consoleCommandPedestrianSystemToggle", self)
    addConsoleCommand("gsPedestrianSystemReload", "Reload pedestrian system xml", "consoleCommandPedestrianSystemReload", self)
    addConsoleCommand("gsPedestrianSystemDebug", "Debug pedestrian system", "consoleCommandPedestrianSystemDebug", self)
    g_soundManager:addIndoorStateChangedListener(self)
    setPedestrianSystemUseOutdoorAudioSetup(self.pedestrianSystemId, not g_soundManager:getIsIndoor())
    return true
end
function PedestrianSystem:loadCharacterFinished(loadingState, _, arguments)
    local graphics = arguments.graphics
    if loadingState == HumanModelLoadingState.OK then
        local pedestrianSystemId = self.pedestrianSystemId
        local rootNode = graphics.model:getRootNode()
        local skeletonNode = graphics.model:getSkeletonNode()
        local skeletonPathIndices = I3DUtil.getRelativeNodePathIndices(skeletonNode, rootNode)
        local headPathIndices = I3DUtil.getRelativeNodePathIndices(graphics.model.i3dMappings.head.nodeId, rootNode)
        local pedestrianNode = clone(rootNode, false, false, false)
        link(getRootNode(), pedestrianNode)
        setName(pedestrianNode, getName(pedestrianNode) .. "_pedestrian")
        setVisibility(pedestrianNode, false)
        local pedestrianId = addPedestrian(pedestrianSystemId, pedestrianNode, skeletonPathIndices, headPathIndices, arguments.variationName, arguments.requiredFlags, arguments.preventFlags, arguments.timeFrom, arguments.timeTo)
        assignWalkAnimationToPedestrian(pedestrianSystemId, pedestrianId, arguments.walkAnimationId, arguments.idleAnimationId or 0)
        for _, groupId in ipairs(arguments.groups) do
            assignPedestrianToPedestrianGroup(pedestrianSystemId, groupId, pedestrianId)
        end
        for _, groupId in ipairs(arguments.staticIdleAnimationIds) do
            assignIdleAnimationToPedestrian(pedestrianSystemId, pedestrianId, groupId)
        end
        table.insert(self.pedestrians, pedestrianId)
        table.insert(self.pedestrianNodes, pedestrianNode)
        graphics:delete()
    end
    self.pendingPedestrians[graphics] = nil
end
function PedestrianSystem:delete()
    local mission = g_currentMission
    if self.pedestrianSystemId ~= nil then
        for _, pedestrian in ipairs(self.pedestrians) do
            removePedestrian(self.pedestrianSystemId, pedestrian)
        end
        for _, pedestrian in pairs(self.pendingPedestrians) do
            _:delete()
        end
        setPedestrianSystemEnabled(self.pedestrianSystemId, false)
        if mission:getHasUpdateable(self) then
            mission:removeUpdateable(self)
        end
        mission:setPedestrianSystem(nil)
        delete(self.pedestrianSystemId)
        self.pedestrianSystemId = nil
        for _, pedestrian in ipairs(self.pedestrianNodes) do
            delete(pedestrian)
        end
        self.conditionFlags:delete()
    end
    g_messageCenter:unsubscribeAll(self)
    g_soundManager:removeIndoorStateChangedListener(self)
    mission:removeDrawable(self)
    removeConsoleCommand("gsPedestrianSystemToggle")
    removeConsoleCommand("gsPedestrianSystemReload")
    removeConsoleCommand("gsPedestrianSystemDebug")
end
function PedestrianSystem:update(_)
    if self.pedestrianSystemId ~= nil then
        self:updateMask()
        local mask = self.conditionFlags:getMask()
        setPedestrianSystemMask(self.pedestrianSystemId, mask)
        setPedestrianSystemDaytime(self.pedestrianSystemId, g_currentMission.environment.dayTime)
    end
end
function PedestrianSystem:draw()
    if self.debugEnabled then
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextColor(1, 1, 1, 1)
        setTextBold(true)
        renderText(0.1, 0.72, getCorrectTextSize(0.014), "Groups:")
        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_LEFT)
        local posY = 0.7
        local textSize = getCorrectTextSize(0.012)
        local textOffset = getCorrectTextSize(0.001)
        for name, group in pairs(self.groupNameToGroup) do
            renderText(0.1, posY, textSize, name)
            renderText(0.2, posY, textSize, (tostring(self:isGroupPossible(group))))
            posY = posY - textSize - textOffset
        end
        self.conditionFlags:drawDebug(0.7, 0.72)
    end
end
function PedestrianSystem:updateMask()
    local conditionFlags = self.conditionFlags
    local environment = g_currentMission.environment
    local weather = environment.weather
    local typeIndex = weather:getCurrentWeatherType()
    local rainFallScale = weather:getRainFallScale()
    local snowFallScale = weather:getSnowFallScale()
    conditionFlags:setModifierValue("spring", environment.currentVisualSeason == Season.SPRING)
    conditionFlags:setModifierValue("summer", environment.currentVisualSeason == Season.SUMMER)
    conditionFlags:setModifierValue("autumn", environment.currentVisualSeason == Season.AUTUMN)
    conditionFlags:setModifierValue("winter", environment.currentVisualSeason == Season.WINTER)
    conditionFlags:setModifierValue("sun", typeIndex == WeatherType.SUN)
    conditionFlags:setModifierValue("cloudy", typeIndex == WeatherType.CLOUDY)
    conditionFlags:setModifierValue("rain", rainFallScale > 0)
    conditionFlags:setModifierValue("snow", snowFallScale > 0)
end
function PedestrianSystem:setEnabled(state)
    if self.pedestrianSystemId ~= nil then
        setPedestrianSystemEnabled(self.pedestrianSystemId, state)
        self.isEnabled = state
    end
end
function PedestrianSystem:isGroupPossible(group)
    local mask = self.conditionFlags:getMask()
    local match = false
    local timeFrom = group.preventFlags
    if bit32.band(mask, timeFrom) == 0 then
        match = bit32.band(mask, group.requiredFlags) == group.requiredFlags
    end
    if not match then
        return false
    end
    local timeFrom = group.timeFrom
    return not MathUtil.getIsOutOfBounds(g_currentMission.environment.dayTime, timeFrom, group.timeTo)
end
function PedestrianSystem.consoleCommandPedestrianSystemToggle(_, state)
    local pedestrianSystem = g_currentMission:getPedestrianSystem()
    if pedestrianSystem == nil or pedestrianSystem.pedestrianSystemId == nil then
        return "Error: No pedestrian system available"
    end
    state = Utils.stringToBoolean(state) or not pedestrianSystem.isEnabled
    pedestrianSystem:setEnabled(state)
    return "setPedestrianSystemEnabled=" .. tostring(state)
end
function PedestrianSystem:consoleCommandPedestrianSystemReload()
    local mission = g_currentMission
    local oldPedestrianSystem = mission:getPedestrianSystem()
    if oldPedestrianSystem == nil or oldPedestrianSystem.pedestrianSystemId == nil then
        return "Error: No pedestrian system to reload"
    end
    local xmlFilename = oldPedestrianSystem.xmlFilename
    oldPedestrianSystem:delete()
    if not PedestrianSystem.createFromXmlAndNode(xmlFilename, oldPedestrianSystem.transformId) then
        return "Error while reloading pedestrian system"
    end
    mission:getPedestrianSystem():setEnabled(oldPedestrianSystem.isEnabled)
    return string.format("Reloaded pedestrian system from \'%s\'", xmlFilename)
end
function PedestrianSystem:consoleCommandPedestrianSystemDebug()
    local mission = g_currentMission
    local pedestrianSystem = mission:getPedestrianSystem()
    if pedestrianSystem == nil or pedestrianSystem.pedestrianSystemId == nil then
        return "Error: No pedestrian system available"
    end
    self.debugEnabled = not self.debugEnabled
    if self.debugEnabled then
        mission:addDrawable(self)
        I3DUtil.iterateRecursively(self.transformId, function(child)
            if I3DUtil.getIsSpline(child) then
                g_debugManager:addElement(DebugSpline.new():createWithNode(child), "pedestrianSystem")
            end
        end)
    else
        mission:removeDrawable(self)
        g_debugManager:removeGroup("pedestrianSystem")
    end
    return string.format("PedestrianSystem debugEnabled=%s", (tostring(self.debugEnabled)))
end
function PedestrianSystem:onIndoorStateChanged(_)
    setPedestrianSystemUseOutdoorAudioSetup(self.pedestrianSystemId, not g_soundManager:getIsIndoor())
end