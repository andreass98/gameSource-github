PlayerStyle = {}
local PlayerStyle_mt = Class(PlayerStyle)
PlayerStyle.ATLAS_COLUMNS = 16
PlayerStyle.ATLAS_ROWS = 16
PlayerStyle.SEND_NUM_BITS = 7
PlayerStyle.CONFIG_COUNT_NUM_BITS = 4
function PlayerStyle.regsterIconGenerationXMLPaths(xmlSchema, key)
    xmlSchema:register(XMLValueType.FLOAT, key .. ".iconGeneration#cameraZoom", "")
    xmlSchema:register(XMLValueType.ANGLE, key .. ".iconGeneration#cameraRotX", "")
    xmlSchema:register(XMLValueType.ANGLE, key .. ".iconGeneration#cameraRotY", "")
    xmlSchema:register(XMLValueType.VECTOR_3, key .. ".iconGeneration#cameraOffset", "")
    xmlSchema:register(XMLValueType.BOOL, key .. ".iconGeneration#ignoreOneSide", "")
    xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration#animation", "")
    xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.top#name", "")
    xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.hairStyle#name", "")
    xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.face#name", "")
    xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.bottom#name", "")
    xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.beard#name", "")
    xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.glasses#name", "")
    xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.headgear#name", "")
    xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.gloves#name", "")
    xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.footwear#name", "")
    xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.onepieces#name", "")
end
function PlayerStyle.registerXMLPaths(xmlSchema)
    PlayerStyle.regsterIconGenerationXMLPaths(xmlSchema, "player.playerStyle")
    PlayerStyle.registerXMLColorNode(xmlSchema, "player.playerStyle.colors.clothing")
    PlayerStyle.registerXMLColorNode(xmlSchema, "player.playerStyle.colors.hair")
    xmlSchema:register(XMLValueType.STRING, "player.playerStyle.filename", "The filename of the player\'s i3d file", nil, false)
    xmlSchema:register(XMLValueType.STRING, "player.playerStyle#neutralDiffuse", "The color applied to the player\'s skin color", nil, false)
    xmlSchema:register(XMLValueType.STRING, "player.playerStyle.bodyParts.bodyPart(?)#name", "The name of the body part", nil, false)
    xmlSchema:register(XMLValueType.STRING, "player.playerStyle.bodyParts.bodyPart(?)#node", "The body part node", nil, false)
    xmlSchema:register(XMLValueType.STRING, "player.playerStyle.attachPoints.attachPoint(?)#name", "The name of the attachment point", nil, false)
    xmlSchema:register(XMLValueType.STRING, "player.playerStyle.attachPoints.attachPoint(?)#node", "The attachment node", nil, false)
    xmlSchema:register(XMLValueType.STRING, "player.filename", "The filename of the player\'s i3d file", nil, false)
    PlayerStyleConfig.registerXMLPaths(xmlSchema)
    PlayerStylePreset.registerXMLPaths(xmlSchema)
end
function PlayerStyle.registerXMLColorNode(xmlSchema, baseKey)
    xmlSchema:register(XMLValueType.STRING, baseKey .. ".color(?)#primary", "The primary color value", nil, false)
    xmlSchema:register(XMLValueType.STRING, baseKey .. ".color(?)#secondary", "The secondary color value", nil, false)
    xmlSchema:register(XMLValueType.BOOL, baseKey .. ".color(?)#default", "True if this color is the default; otherwise false", nil, false)
end
function PlayerStyle.registerSavegameXMLPaths(savegameXMLSchema, baseKey)
    savegameXMLSchema:register(XMLValueType.STRING, baseKey .. "#filename", "The filename of the style", nil, true)
    for configName, _ in pairs(PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME) do
        PlayerStyleConfig.registerSavegameXMLPaths(savegameXMLSchema, baseKey, configName)
    end
end
function PlayerStyle.defaultStyle(oldStyle)
    local style = PlayerStyle.new()
    local xmlFile
    if oldStyle == nil or oldStyle.xmlFilename == nil then
        xmlFile = next(PlayerSystem.PLAYER_STYLES_BY_FILENAME)
    else
        xmlFile = oldStyle.xmlFilename
    end
    style.xmlFilename = xmlFile
    style:copyConfigurationFrom(PlayerSystem.PLAYER_STYLES_BY_FILENAME[style.xmlFilename].style)
    style.configs.bottom.selectedItemIndex = 1
    style.configs.top.selectedItemIndex = 4
    style.configs.footwear.selectedItemIndex = 1
    style.configs.hairStyle.selectedItemIndex = 2
    style.configs.hairStyle:setSelectedColorIndex(6)
    style.configs.face.selectedItemIndex = 1
    return style
end
function PlayerStyle.new(customMt)
    -- upvalues: (copy) PlayerStyle_mt
    local self = setmetatable({}, customMt or PlayerStyle_mt)
    self.disabledOptionsForSelection = {}
    self.presets = {}
    self.presetsByName = {}
    self.attachPoints = {}
    self.bodyParts = {}
    self.bodyPartIndexByName = {}
    self.facesByName = {}
    self.isConfigurationLoaded = false
    self.configs = {}
    self.orderedConfigs = {}
    self:addConfig(PlayerStyleConfig.new(self, "hairStyle", { PlayerStyleConfig.NOT_FOR_HAT_GETTER_FILTER }, false, true, true))
    self:addConfig(PlayerStyleConfig.new(self, "glasses", { PlayerStyleConfig.ENABLED_GETTER_FILTER, PlayerStyleConfig.SELECTED_GETTER_FILTER }, true))
    self:addConfig(PlayerStyleConfig.new(self, "headgear", { PlayerStyleConfig.ENABLED_GETTER_FILTER, PlayerStyleConfig.NOT_HIDDEN_GETTER_FILTER }))
    self:addConfig(PlayerStyleConfig.new(self, "facegear"))
    self:addConfig(PlayerStyleConfig.new(self, "face"))
    self:addConfig(PlayerStyleConfig.new(self, "beard", { PlayerStyleConfig.ENABLED_GETTER_FILTER, PlayerStyleConfig.BEARD_FACE_GETTER_FILTER }, false, false, true))
    self:addConfig(PlayerStyleConfig.new(self, "top", { PlayerStyleConfig.ENABLED_GETTER_FILTER, PlayerStyleConfig.NO_ONEPIECE_GETTER_FILTER }))
    self:addConfig(PlayerStyleConfig.new(self, "gloves", { PlayerStyleConfig.ENABLED_GETTER_FILTER, PlayerStyleConfig.NOT_HIDDEN_GETTER_FILTER }))
    self:addConfig(PlayerStyleConfig.new(self, "bottom", { PlayerStyleConfig.ENABLED_GETTER_FILTER, PlayerStyleConfig.NO_ONEPIECE_GETTER_FILTER }))
    self:addConfig(PlayerStyleConfig.new(self, "footwear", { PlayerStyleConfig.ENABLED_GETTER_FILTER }))
    self:addConfig(PlayerStyleConfig.new(self, "onepiece", { PlayerStyleConfig.ENABLED_GETTER_FILTER, PlayerStyleConfig.SELECTED_GETTER_FILTER }, true))
    self.configs.hairStyle:setSelectedColorIndex(self.configs.hairStyle:getSelectedColorIndex())
    self.configs.face.selectedItemIndex = 1
    self.configs.hairStyle.selectedItemIndex = 2
    return self
end
function PlayerStyle:delete() end
function PlayerStyle:writeStream(streamId, connection)
    streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.xmlFilename))
    for _, config in ipairs(self.orderedConfigs) do
        config:writeStream(streamId, connection)
    end
end
function PlayerStyle:readStream(streamId, connection)
    self.xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
    self:loadConfigurationIfRequired()
    for _, config in ipairs(self.orderedConfigs) do
        config:readStream(streamId, connection)
    end
    self:updateDisabledOptions()
    self.configs.hairStyle:setSelectedColorIndex(self.configs.hairStyle:getSelectedColorIndex())
end
function PlayerStyle:addConfig(config)
    self.configs[config.name] = config
    table.insert(self.orderedConfigs, config)
end
function PlayerStyle:copyFrom(other)
    if other == self then
        return
    else
        self.xmlFilename = other.xmlFilename
        self.filename = other.filename
        self.attachPoints = other.attachPoints
        for configName, config in pairs(other.configs) do
            self.configs[configName]:copyConfigurationFrom(config)
            self.configs[configName]:copySelectionFrom(config)
        end
        self.configs.hairStyle:setSelectedColorIndex(self.configs.hairStyle:getSelectedColorIndex())
        if other.isConfigurationLoaded then
            self.faceNeutralDiffuseColor = other.faceNeutralDiffuseColor
            self.bodyParts = other.bodyParts
            self.bodyPartIndexByName = other.bodyPartIndexByName
            self.hatHairstyleIndex = other.hatHairstyleIndex
            self.presets = other.presets
            self.presetsByName = other.presetsByName
            self.isConfigurationLoaded = true
            self:updateDisabledOptions()
        else
            self.isConfigurationLoaded = false
        end
    end
end
function PlayerStyle:copyConfigurationFrom(other)
    if other == self then
        return
    elseif other.isConfigurationLoaded then
        self.xmlFilename = other.xmlFilename
        self.filename = other.filename
        self.hatHairstyleIndex = other.hatHairstyleIndex
        self.faceNeutralDiffuseColor = other.faceNeutralDiffuseColor
        self.attachPoints = other.attachPoints
        self.bodyParts = other.bodyParts
        self.bodyPartIndexByName = other.bodyPartIndexByName
        self.presets = other.presets
        self.presetsByName = other.presetsByName
        for configName, config in pairs(other.configs) do
            self.configs[configName]:copyConfigurationFrom(config)
        end
        self.isConfigurationLoaded = true
        self:updateDisabledOptions()
    else
        Logging.error("Cannot copy configuration from style that has not yet loaded its own configuration!")
        printCallstack()
    end
end
function PlayerStyle:copySelectionFrom(other)
    if other ~= self then
        self.isConfigurationLoaded = self.xmlFilename == other.xmlFilename and self.isConfigurationLoaded
        self.xmlFilename = other.xmlFilename
        for configName, config in pairs(other.configs) do
            self.configs[configName]:copySelectionFrom(config)
        end
        self.configs.hairStyle:setSelectedColorIndex(self.configs.hairStyle:getSelectedColorIndex())
    end
end
function PlayerStyle:loadConfigurationIfRequired()
    if not self.isConfigurationLoaded then
        self:loadConfigurationXML(self.xmlFilename)
    end
end
function PlayerStyle:loadConfigurationXML(xmlFilename)
    local xmlFile = Utils.getFilename(xmlFilename)
    if PlayerSystem.PLAYER_STYLES_BY_FILENAME[xmlFile] ~= nil then
        self:copyConfigurationFrom(PlayerSystem.PLAYER_STYLES_BY_FILENAME[xmlFile].style)
        return
    end
    local xmlFile = XMLFile.loadIfExists("player", xmlFile, PlayerSystem.xmlSchema)
    if xmlFile == nil then
        Logging.error("Player config does not exist at %s. Loading default instead", xmlFile)
        xmlFile = next(PlayerSystem.PLAYER_STYLES_BY_FILENAME)
        xmlFile = XMLFile.loadIfExists("player", xmlFile, PlayerSystem.xmlSchema)
        if xmlFile == nil then
            Logging.fatal("Default player config does not exist at %s", xmlFile)
        end
    end
    self.xmlFilename = xmlFile
    self.filename = xmlFile:getValue("player.filename", nil)
    self.hairColors = PlayerStyle.loadColors(xmlFile, "player.playerStyle.colors.hair")
    self.defaultClothingColors = PlayerStyle.loadColors(xmlFile, "player.playerStyle.colors.clothing")
    table.clear(self.attachPoints)
    for _, key in xmlFile:iterator("player.playerStyle.attachPoints.attachPoint") do
        local nodeName = xmlFile:getValue(key .. "#node")
        local name = xmlFile:getValue(key .. "#name", nodeName)
        self.attachPoints[name] = nodeName
    end
    local restoreFaceSelection = nil
    if self.configs.face.selectedItemIndex ~= 0 and self.configs.face:getSelectedItem() ~= nil then
        restoreFaceSelection = self.configs.face:getSelectedItem().name
    end
    for key, nodeName in pairs(PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME) do
        local name = self.configs[key]
        local selectedItem = name:getSelectedItem()
        local restoreSelectionName = selectedItem ~= nil and selectedItem.name or nil
        name:reset()
        name:loadFromXMLNode(xmlFile, "player.playerStyle", self.defaultClothingColors, self.hairColors, self.attachPoints)
        if restoreSelectionName == nil or name.itemsByName[restoreSelectionName] == nil then
            if name.selectedItemIndex > 0 and name.selectedItemIndex <= #name.items then
                name:setSelectedItemIndex(restoreSelectionIndex)
            end
        else
            name:setSelectedItemName(restoreSelectionName)
        end
    end
    for _ = #self.configs.hairStyle.items, 1, -1 do
        if self.configs.hairStyle.items[_].forHat then
            self.hatHairstyleIndex = _
            break
        end
    end
    table.clear(self.facesByName)
    for key, nodeName in pairs(self.configs.face.items) do
        self.facesByName[nodeName.name] = nodeName
    end
    if restoreFaceSelection ~= nil then
        self.configs.face:setSelectedItemName(restoreFaceSelection)
    end
    table.clear(self.bodyParts)
    table.clear(self.bodyPartIndexByName)
    for key, nodeName in xmlFile:iterator("player.playerStyle.bodyParts.bodyPart") do
        local name = xmlFile:getValue(nodeName .. "#node")
        local selectedItem = xmlFile:getValue(nodeName .. "#name", name)
        if self.bodyPartIndexByName[selectedItem] == nil then
            table.insert(self.bodyParts, {
                ["nodeName"] = name,
                ["name"] = selectedItem
            })
            self.bodyPartIndexByName[selectedItem] = #self.bodyParts
        else
            Logging.devError("Wardrobe body part name \'%s\' already used, skipping!", selectedItem)
        end
    end
    table.clear(self.presets)
    table.clear(self.presetsByName)
    for key, nodeName in xmlFile:iterator("player.playerStyle.presets.preset") do
        local name = PlayerStylePreset.new(self.xmlFilename)
        name:loadFromXMLNode(xmlFile, nodeName)
        local selectedItem = true
        for configName, configData in pairs(name.configs) do
            local itemName = configData.selectionName
            if itemName ~= "keepCurrent" and self.configs[configName].itemsByName[itemName] == nil then
                selectedItem = false
                Logging.xmlWarning(xmlFile, "Style preset with name \'%s\' uses item \'%s\' for \'%s\' which does not exist!", name.name, itemName, configName)
            end
        end
        if selectedItem then
            if self.presetsByName[name.name] == nil then
                table.insert(self.presets, name)
                self.presetsByName[name.name] = name
            else
                Logging.xmlError(xmlFile, "Style preset with name \'%s\' has already been defined!", name.name)
            end
        end
    end
    self.isConfigurationLoaded = true
    xmlFile:delete()
end
function PlayerStyle.loadColors(xmlFile, rootKey)
    local colors = {}
    for index, key in xmlFile:iterator(rootKey .. ".color") do
        local primary = Color.parseFromString(xmlFile:getValue(key .. "#primary", nil))
        if primary ~= nil then
            local color = {
                ["primary"] = primary,
                ["secondary"] = Color.parseFromString(xmlFile:getValue(key .. "#secondary", nil)),
                ["isDefault"] = xmlFile:getValue(key .. "#default", nil)
            }
            table.insert(colors, color)
        end
    end
    return colors
end
function PlayerStyle:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. "#filename", self.xmlFilename)
    self:loadConfigurationIfRequired()
    for configName, config in pairs(self.configs) do
        config:saveToSavegame(xmlFile, key)
    end
end
function PlayerStyle:loadFromXMLFile(xmlFile, key)
    local xmlFilename = xmlFile:getValue(key .. "#filename")
    if string.isNilOrWhitespace(xmlFilename) then
        Logging.xmlError(xmlFile, "Filename could not be read from %s!", key .. "#filename")
    end
    if PlayerSystem.PLAYER_STYLES_BY_FILENAME[xmlFilename] == nil then
        Logging.xmlError(xmlFile, "PlayerStyle filename \'%s\' not available anymore!", xmlFilename)
        return false
    end
    self.xmlFilename = xmlFilename
    self:loadConfigurationIfRequired()
    for configName, config in pairs(self.configs) do
        config:loadFromSavegame(xmlFile, key)
    end
    self.configs.hairStyle:setSelectedColorIndex(self.configs.hairStyle:getSelectedColorIndex())
    return true
end
function PlayerStyle:getRequiredNodeFiles()
    local list = {}
    if self.xmlFilename == nil then
        return list
    end
    self:loadConfigurationIfRequired()
    for configName, config in pairs(self.configs) do
        local item = config:getSelectedItem()
        if item ~= nil and not string.isNilOrWhitespace(item.filename) then
            table.insert(list, item.filename)
        end
    end
    local onepieceItem = self.configs.onepiece:getSelectedItem()
    if self.hatHairstyleIndex ~= nil and (self.configs.headgear.selectedItemIndex ~= 0 or self.configs.onepiece.selectedItemIndex ~= 0 and onepieceItem.disabledOptions.headgear) then
        table.insert(list, self.configs.hairStyle.items[self.hatHairstyleIndex].filename)
    end
    return list
end
function PlayerStyle:getPresets()
    return self.presets
end
function PlayerStyle:getPresetByName(presetName)
    return self.presetsByName[presetName]
end
function PlayerStyle:updateDisabledOptions()
    local onepiece = self.configs.onepiece:getSelectedItem()
    if onepiece == nil then
        self.disabledOptionsForSelection = {}
    else
        self.disabledOptionsForSelection = onepiece.disabledOptions
    end
end
function PlayerStyle:convertSkinColorToScreenColor(r, g, b)
    return r * self.faceNeutralDiffuseColor.r, g * self.faceNeutralDiffuseColor.g, b * self.faceNeutralDiffuseColor.b
end
function PlayerStyle:getIsMale()
    return PlayerSystem.PLAYER_STYLES_BY_FILENAME[self.xmlFilename].gender == "male"
end
function PlayerStyle:isValid()
    if self.xmlFilename == nil then
        Logging.warning("PlayerStyle.isValid: Missing xmlFilename")
        return false
    end
    if self.configs.footwear.selectedItemIndex == 0 and self.configs.onepiece.selectedItemIndex > 0 then
        self:loadConfigurationIfRequired()
    end
    local isHairStyleValid = false
    if self.configs.hairStyle.selectedItemIndex > 0 then
        isHairStyleValid = self.configs.hairStyle:getSelectedItem() ~= nil
    end
    if not isHairStyleValid then
        Logging.warning("PlayerStyle.isValid: Missing hairstyle")
        return false
    end
    local isFaceValid = false
    if self.configs.face.selectedItemIndex > 0 then
        isFaceValid = self.configs.face:getSelectedItem() ~= nil
    end
    if not isFaceValid then
        Logging.warning("PlayerStyle.isValid: Missing face")
        return false
    end
    if self.configs.onepiece.selectedItemIndex > 0 then
        local isOnepieceValid = self.configs.onepiece:getSelectedItem() ~= nil
        if not isOnepieceValid then
            Logging.warning("PlayerStyle.isValid: Missing onepiece")
            return false
        end
    else
        local isOnepieceValid = false
        if self.configs.bottom.selectedItemIndex > 0 then
            isOnepieceValid = self.configs.bottom:getSelectedItem() ~= nil
        end
        if not isOnepieceValid then
            Logging.warning("PlayerStyle.isValid: Missing bottom")
            return false
        end
        local isTopValid = false
        if self.configs.top.selectedItemIndex > 0 then
            isTopValid = self.configs.top:getSelectedItem() ~= nil
        end
        if not isTopValid then
            Logging.warning("PlayerStyle.isValid: Missing top")
            return false
        end
    end
    local isOnepieceValid = self.configs.onepiece:getSelectedItem()
    local isTopValid = true
    if isOnepieceValid ~= nil then
        isTopValid = not isOnepieceValid.disabledOptions.footwear
    end
    local isFootwearValid = false
    if self.configs.footwear.selectedItemIndex > 0 then
        isFootwearValid = self.configs.footwear:getSelectedItem() ~= nil
    end
    if isTopValid and not isFootwearValid then
        Logging.warning("PlayerStyle.isValid: Missing footwear")
        return false
    end
    local disabledOptions = {}
    for configName, config in pairs(self.configs) do
        local item = config:getSelectedItem()
        if item ~= nil then
            for name, isDisabled in pairs(item.disabledOptions) do
                if isDisabled then
                    disabledOptions[name] = configName
                end
            end
        end
    end
    for configName, config in pairs(disabledOptions) do
        local item = self.configs[configName]
        if item ~= nil and (item.selectedItemIndex > 0 and item:getSelectedItem() ~= nil) then
            Logging.warning("PlayerStyle.isValid: \'%s\' is not allowed because it is disabled by \'%s\'!", configName, config)
            return false
        end
    end
    return true
end
function PlayerStyle:debugDraw(x, y, textSize)
    local startX = DebugUtil.renderTextLine(x, y, textSize * 1.25, "Style", nil, true)
    local startX = DebugUtil.renderTextLine(x, startX, textSize, string.format("Is loaded: %s", self.isConfigurationLoaded))
    if self.isConfigurationLoaded then
        startX = DebugUtil.renderTextLine(x, startX, textSize, self.xmlFilename)
    end
    y = DebugUtil.renderTextLine(x, startX, textSize, "Config name, item id, color id:")
    local startX = x
    for configName, config in pairs(self.configs) do
        DebugUtil.renderTextLine(x, y, textSize, string.format("%s: %d %d", string.sub(configName, 1, 4), config.selectedItemIndex, config.selectedColorIndex))
        x = x + 80 * g_pixelSizeX
        if (x - startX) / g_pixelSizeX > 250 then
            x = startX
        end
    end
    return y
end