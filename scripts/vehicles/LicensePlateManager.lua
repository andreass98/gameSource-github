LicensePlateManager = {}
LicensePlateManager.PLATE_TYPE = {}
LicensePlateManager.PLATE_TYPE.SQUARISH = 0
LicensePlateManager.PLATE_TYPE.ELONGATED = 1
LicensePlateManager.PLATE_POSITION = {}
LicensePlateManager.PLATE_POSITION.NONE = 0
LicensePlateManager.PLATE_POSITION.FRONT = 1
LicensePlateManager.PLATE_POSITION.BACK = 2
LicensePlateManager.PLATE_POSITION.ANY = 3
LicensePlateManager.CHARACTER_TYPE = {}
LicensePlateManager.CHARACTER_TYPE.NUMERICAL = 0
LicensePlateManager.CHARACTER_TYPE.ALPHABETICAL = 1
LicensePlateManager.CHARACTER_TYPE.SPECIAL = 2
LicensePlateManager.PLACEMENT_OPTION = {}
LicensePlateManager.PLACEMENT_OPTION.NONE = 0
LicensePlateManager.PLACEMENT_OPTION.BOTH = 1
LicensePlateManager.PLACEMENT_OPTION.BACK_ONLY = 2
LicensePlateManager.PLACEMENT_OPTION_TEXT = {}
LicensePlateManager.PLACEMENT_OPTION_TEXT[LicensePlateManager.PLACEMENT_OPTION.NONE] = "ui_licensePlatePlacementNone"
LicensePlateManager.PLACEMENT_OPTION_TEXT[LicensePlateManager.PLACEMENT_OPTION.BOTH] = "ui_licensePlatePlacementBoth"
LicensePlateManager.PLACEMENT_OPTION_TEXT[LicensePlateManager.PLACEMENT_OPTION.BACK_ONLY] = "ui_licensePlatePlacementBackOnly"
LicensePlateManager.SEND_NUM_BITS_VARIATION = 4
LicensePlateManager.SEND_NUM_BITS_COLOR = 6
LicensePlateManager.SEND_NUM_BITS_CHARACTER = 8
LicensePlateManager.SEND_NUM_BITS_PLACEMENT = 2
LicensePlateManager.xmlSchema = nil
local LicensePlateManager_mt = Class(LicensePlateManager, AbstractManager)
g_xmlManager:addInitSchemaFunction(function()
    LicensePlateManager.createLicensePlateXMLSchema()
end)
function LicensePlateManager.new(customMt)
    -- upvalues: (copy) LicensePlateManager_mt
    return AbstractManager.new(customMt or LicensePlateManager_mt)
end
function LicensePlateManager:initDataStructures()
    self.licensePlates = {}
    self.colorConfigurations = {}
    self.licensePlatesAvailable = false
    self.sharedLoadRequestIds = {}
end
function LicensePlateManager:loadMapData(xmlFile, _, baseDirectory)
    LicensePlateManager:superClass().loadMapData(self)
    self.baseDirectory = baseDirectory
    local filename = getXMLString(xmlFile, "map.licensePlates#filename")
    if filename ~= nil then
        self.xmlFilename = Utils.getFilename(filename, baseDirectory)
        self.licensePlateXML = XMLFile.load("mapLicensePlates", self.xmlFilename, LicensePlateManager.xmlSchema)
        if self.licensePlateXML ~= nil then
            self.xmlReferences = 0
            self:loadLicensePlatesFromXML(self.licensePlateXML, baseDirectory)
            if self.licensePlateXML ~= nil and self.xmlReferences == 0 then
                self.licensePlateXML:delete()
                self.licensePlateXML = nil
            end
        end
    end
    return true
end
function LicensePlateManager:unloadMapData()
    local i = 1
    for i = i, #self.licensePlates do
        self.licensePlates[i]:delete()
    end
    if self.sharedLoadRequestIds ~= nil then
        for _, sharedLoadRequestId in ipairs(self.sharedLoadRequestIds) do
            g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
        end
        self.sharedLoadRequestIds = nil
    end
    if self.licensePlateXML ~= nil then
        self.licensePlateXML:delete()
        self.licensePlateXML = nil
    end
    LicensePlateManager:superClass().unloadMapData(self)
end
function LicensePlateManager:loadLicensePlatesFromXML(xmlFile, baseDirectory)
    local customEnvironment, _ = Utils.getModNameAndBaseDirectory(baseDirectory)
    self.fontName = xmlFile:getValue("licensePlates.font#name", "GENERIC")
    self.customEnvironment = customEnvironment
    xmlFile:iterate("licensePlates.licensePlate", function(_, plateKey)
        -- upvalues: (copy) xmlFile, (copy) self, (copy) baseDirectory, (copy) customEnvironment
        local filename = xmlFile:getValue(plateKey .. "#filename")
        if filename == nil then
            Logging.xmlError(xmlFile, "Missing filename for license plate \'%s\'", plateKey)
        else
            self.xmlReferences = self.xmlReferences + 1
            local arguments = {
                ["filename"] = Utils.getFilename(filename, baseDirectory),
                ["xmlFile"] = xmlFile,
                ["plateKey"] = plateKey,
                ["customEnvironment"] = customEnvironment
            }
            local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(arguments, false, false, self.licensePlateI3DFileLoaded, self, arguments)
            table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
        end
    end)
    self.materialNamePlate = xmlFile:getValue("licensePlates.colorConfigurations#materialName", "licensePlateColored_mat")
    self.shaderParameterCharacters = xmlFile:getValue("licensePlates.colorConfigurations#shaderParameterCharacters", "colorScale")
    self.useDefaultColors = xmlFile:getValue("licensePlates.colorConfigurations#useDefaultColors", false)
    self.defaultColorIndex = xmlFile:getValue("licensePlates.colorConfigurations#defaultColorIndex")
    self.defaultColorMaxBrightness = xmlFile:getValue("licensePlates.colorConfigurations#defaultColorMaxBrightness", 0.55)
    local defaultConfiguration = 1
    xmlFile:iterate("licensePlates.colorConfigurations.colorConfiguration", function(index, baseKey)
        -- upvalues: (copy) xmlFile, (copy) self, (ref) defaultConfiguration
        local name = xmlFile:getValue(baseKey .. "#name", "", self.customEnvironment, false)
        local color = xmlFile:getValue(baseKey .. "#color", nil, true)
        local isDefault = xmlFile:getValue(baseKey .. "#isDefault", false)
        if color ~= nil then
            if isDefault then
                defaultConfiguration = index
            end
            table.insert(self.colorConfigurations, {
                ["name"] = name,
                ["color"] = color,
                ["isDefault"] = isDefault
            })
        end
    end)
    if self.defaultColorIndex == nil then
        self.defaultColorIndex = defaultConfiguration
    else
        self.defaultColorIndex = self.defaultColorIndex + #self.colorConfigurations
    end
    self.colors = {}
    local j = 1
    local placementStr = #self.colorConfigurations
    for j = j, placementStr do
        table.insert(self.colors, self.colorConfigurations[j])
    end
    if self.useDefaultColors then
        local j = 1
        for j = j, #VehicleConfigurationItemColor.DEFAULT_COLORS do
            local color, title = g_vehicleMaterialManager:getMaterialTemplateColorAndTitleByName(VehicleConfigurationItemColor.DEFAULT_COLORS[j], customEnvironment)
            if color ~= nil then
                if MathUtil.getBrightnessFromColor(color[1], color[2], color[3]) < self.defaultColorMaxBrightness then
                    table.insert(self.colors, {
                        ["name"] = title or "",
                        ["color"] = color
                    })
                end
            end
        end
    end
    self.defaultPlacementIndex = LicensePlateManager.PLACEMENT_OPTION.BOTH
    local placementStr = xmlFile:getValue("licensePlates.placement#defaultType")
    if placementStr ~= nil then
        self.defaultPlacementIndex = LicensePlateManager.PLACEMENT_OPTION[string.upper(placementStr)] or self.defaultPlacementIndex
    end
end
function LicensePlateManager:licensePlateI3DFileLoaded(i3dNode, _, args)
    if i3dNode ~= nil and i3dNode ~= 0 then
        local node = args.xmlFile:getValue(args.plateKey .. "#node", nil, i3dNode)
        if node ~= nil then
            unlink(node)
            local licensePlate = LicensePlate.new()
            if licensePlate:loadFromXML(node, args.filename, args.customEnvironment, xmlFile, plateKey) then
                table.insert(self.licensePlates, licensePlate)
            end
        end
        delete(i3dNode)
    end
    self.xmlReferences = self.xmlReferences - 1
    if self.xmlReferences == 0 then
        xmlFile:delete()
        self.licensePlatesAvailable = #self.licensePlates > 0
        if xmlFile == self.licensePlateXML then
            self.licensePlateXML = nil
        end
    end
end
function LicensePlateManager:getAreLicensePlatesAvailable()
    return self.licensePlatesAvailable and g_materialManager:getFontMaterial(self.fontName, self.customEnvironment)
end
function LicensePlateManager:getLicensePlate(preferedType, includeFrame)
    local licensePlate = self.licensePlates[1]
    local i = 1
    for i = i, #self.licensePlates do
        if self.licensePlates[i].type == preferedType then
            licensePlate = self.licensePlates[i]
        end
    end
    if licensePlate == nil then
        return nil
    else
        return licensePlate:clone(includeFrame)
    end
end
function LicensePlateManager.getLicensePlateValues(_, licensePlate, variationIndex)
    local variation = licensePlate.variations[variationIndex]
    if variation == nil then
        return nil
    else
        return variation.values
    end
end
function LicensePlateManager:getRandomLicensePlateData()
    local licensePlate = self.licensePlates[1]
    return licensePlate == nil and {
        ["variation"] = 1,
        ["characters"] = nil,
        ["colorIndex"] = nil,
        ["placementIndex"] = self:getDefaultPlacementIndex()
    } or {
        ["variation"] = 1,
        ["characters"] = licensePlate:getRandomCharacters(1),
        ["colorIndex"] = self.defaultColorIndex,
        ["placementIndex"] = self:getDefaultPlacementIndex()
    }
end
function LicensePlateManager:getAvailableColors()
    return self.colors, self.defaultColorIndex
end
function LicensePlateManager:getDefaultPlacementIndex()
    return self.defaultPlacementIndex
end
function LicensePlateManager:getFont()
    return g_materialManager:getFontMaterial(self.fontName, self.customEnvironment)
end
function LicensePlateManager.readLicensePlateData(streamId, _)
    local licensePlateData = {
        ["variation"] = 1,
        ["characters"] = nil,
        ["colorIndex"] = nil,
        ["placementIndex"] = 1
    }
    if streamReadBool(streamId) then
        licensePlateData.variation = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_VARIATION)
        licensePlateData.colorIndex = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_COLOR)
        licensePlateData.placementIndex = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_PLACEMENT)
        local font = g_licensePlateManager:getFont()
        licensePlateData.characters = {}
        local numCharacters = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_CHARACTER)
        for i = 1, numCharacters do
            local character = font:getCharacterByCharacterIndex((streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_CHARACTER))) or "_"
            table.insert(licensePlateData.characters, character)
        end
    end
    return licensePlateData
end
function LicensePlateManager.writeLicensePlateData(streamId, _, licensePlateData)
    local font = streamWriteBool
    if font(streamId, licensePlateData ~= nil and licensePlateData.variation ~= nil and licensePlateData.characters ~= nil and licensePlateData.colorIndex ~= nil and licensePlateData.placementIndex ~= nil) then
        streamWriteUIntN(streamId, licensePlateData.variation, LicensePlateManager.SEND_NUM_BITS_VARIATION)
        streamWriteUIntN(streamId, licensePlateData.colorIndex, LicensePlateManager.SEND_NUM_BITS_COLOR)
        streamWriteUIntN(streamId, licensePlateData.placementIndex, LicensePlateManager.SEND_NUM_BITS_PLACEMENT)
        local font = g_licensePlateManager:getFont()
        streamWriteUIntN(streamId, #licensePlateData.characters, LicensePlateManager.SEND_NUM_BITS_CHARACTER)
        local i = 1
        for i = i, #licensePlateData.characters do
            local index = font:getCharacterIndexByCharacter(licensePlateData.characters[i])
            streamWriteUIntN(streamId, index, LicensePlateManager.SEND_NUM_BITS_CHARACTER)
        end
    end
end
function LicensePlateManager.loadLicensePlateDataFromXML(xmlFile, key, useAbsolutePaths)
    if not xmlFile:hasProperty(key .. "#variation") then
        return nil
    end
    local licensePlateData = {}
    if useAbsolutePaths then
        licensePlateData.xmlFilename = xmlFile:getString(key .. "#configuration")
    else
        licensePlateData.xmlFilename = NetworkUtil.convertFromNetworkFilename(xmlFile:getString(key .. "#configuration"))
    end
    licensePlateData.variation = xmlFile:getInt(key .. "#variation")
    licensePlateData.colorIndex = xmlFile:getInt(key .. "#color")
    licensePlateData.placementIndex = xmlFile:getInt(key .. "#placement")
    licensePlateData.characters = {}
    local characters = xmlFile:getString(key .. "#characters")
    local characterLength = characters:len()
    local i = 1
    for i = i, characterLength do
        table.insert(licensePlateData.characters, characters:sub(i, i))
    end
    return licensePlateData
end
function LicensePlateManager.saveLicensePlateDataToXML(xmlFile, key, licensePlateData, useAbsolutePaths)
    local valid = false
    if licensePlateData ~= nil then
        valid = false
        if licensePlateData.variation ~= nil then
            valid = false
            if licensePlateData.characters ~= nil then
                valid = false
                if licensePlateData.colorIndex ~= nil then
                    valid = licensePlateData.placementIndex ~= nil
                end
            end
        end
    end
    if valid then
        xmlFile:setInt(key .. "#variation", licensePlateData.variation)
        xmlFile:setInt(key .. "#color", licensePlateData.colorIndex)
        xmlFile:setInt(key .. "#placement", licensePlateData.placementIndex)
        xmlFile:setString(key .. "#characters", table.concat(licensePlateData.characters, ""))
        if useAbsolutePaths then
            xmlFile:setString(key .. "#configuration", licensePlateData.xmlFilename)
            return
        end
        xmlFile:setString(key .. "#configuration", NetworkUtil.convertToNetworkFilename(licensePlateData.xmlFilename))
    end
end
function LicensePlateManager.registerSavegameXMLpaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#variation", nil, "Variation of the license place")
    schema:register(XMLValueType.INT, basePath .. "#color", nil, "Color index of the license place")
    schema:register(XMLValueType.INT, basePath .. "#placement", nil, "Placement index of the license place")
    schema:register(XMLValueType.STRING, basePath .. "#characters", nil, "Used characters of the license place")
    schema:register(XMLValueType.STRING, basePath .. "#configuration", nil, "Configuration of the license place")
end
function LicensePlateManager.createLicensePlateAIIcons(_, numX, numY, variationIndex, positionStr)
    if LicensePlateManager.licensePlatesIconRootNode == nil then
        numX = tonumber(numX) or 3
        numY = tonumber(numY) or 10
        variationIndex = tonumber(variationIndex) or 1
        local position = nil
        if positionStr ~= nil then
            position = LicensePlateManager.PLATE_POSITION[string.upper(positionStr)]
        end
        LicensePlateManager.licensePlatesIconRootNode = createTransformGroup("licensePlatesIconRootNode")
        link(getRootNode(), LicensePlateManager.licensePlatesIconRootNode)
        setTranslation(LicensePlateManager.licensePlatesIconRootNode, 0, -10, 0)
        local rootPlate = g_licensePlateManager:getLicensePlate(LicensePlateManager.PLATE_TYPE.ELONGATED)
        if rootPlate ~= nil then
            local ratio = rootPlate.height / rootPlate.width
            local availableHeight = numY * rootPlate.height
            local row = 1
            for row = row, numY do
                ({})[row] = {}
                local useLastRowCharacters = false
                local rowPosition
                if position == nil then
                    if row % 2 == 0 then
                        rowPosition = LicensePlateManager.PLATE_POSITION.FRONT
                        useLastRowCharacters = true
                    else
                        rowPosition = LicensePlateManager.PLATE_POSITION.BACK
                    end
                else
                    rowPosition = position
                end
                local col = 1
                for col = col, numX do
                    local licensePlate = g_licensePlateManager:getLicensePlate(LicensePlateManager.PLATE_TYPE.ELONGATED)
                    if licensePlate == nil then
                    else
                        link(LicensePlateManager.licensePlatesIconRootNode, licensePlate.node)
                        setTranslation(licensePlate.node, (col - 1) * rootPlate.width + rootPlate.width * 0.5, (row - 1) * rootPlate.height + rootPlate.height * 0.5, 0)
                        setRotation(licensePlate.node, 0, 0, 0)
                        local characters
                        if useLastRowCharacters and row > 1 then
                            characters = charactersPerRow[row - 1][col]
                        else
                            characters = licensePlate:getRandomCharacters(variationIndex)
                        end
                        charactersPerRow[row][col] = characters
                        licensePlate:updateData(variationIndex, rowPosition, table.concat(characters, ""))
                    end
                end
            end
            local cameraNode = createCamera("licensePlatesIconCamera", 3437.746770784939, 0.1, 12)
            link(LicensePlateManager.licensePlatesIconRootNode, cameraNode)
            setTranslation(cameraNode, numX * rootPlate.width * 0.5, availableHeight * 0.5, 10)
            setIsOrthographic(cameraNode, true)
            setOrthographicHeight(cameraNode, availableHeight)
            LicensePlateManager.licensePlatesIconLastCamera = g_cameraManager:getActiveCamera()
            g_cameraManager:addCamera(cameraNode)
            g_cameraManager:setActiveCamera(cameraNode)
            g_currentMission.hud:setIsVisible(false)
            g_noHudModeEnabled = true
        end
    else
        delete(LicensePlateManager.licensePlatesIconRootNode)
        LicensePlateManager.licensePlatesIconRootNode = nil
        g_cameraManager:setActiveCamera(LicensePlateManager.licensePlatesIconLastCamera)
        LicensePlateManager.licensePlatesIconLastCamera = nil
        g_currentMission.hud:setIsVisible(true)
    end
end
addConsoleCommand("gsLicensePlateCreateAIIcons", "Create license plate icons for AI vehicles", "createLicensePlateAIIcons", LicensePlateManager, "numX; numY; variationIndex; position")
function LicensePlateManager.createLicensePlateXMLSchema()
    if LicensePlateManager.xmlSchema == nil then
        local schema = XMLSchema.new("mapLicensePlates")
        LicensePlate.registerXMLPaths(schema, "licensePlates.licensePlate(?)")
        schema:register(XMLValueType.STRING, "licensePlates.font#name", "License plate font name", "GENERIC")
        schema:register(XMLValueType.STRING, "licensePlates.colorConfigurations#materialName", "Name of colored license plate material", "licensePlateColored_mat")
        schema:register(XMLValueType.STRING, "licensePlates.colorConfigurations#shaderParameterCharacters", "Color shader parameter of characters", "colorSale")
        schema:register(XMLValueType.BOOL, "licensePlates.colorConfigurations#useDefaultColors", "License plate can be colored with all available default colors", false)
        schema:register(XMLValueType.INT, "licensePlates.colorConfigurations#defaultColorIndex", "Default selected color")
        schema:register(XMLValueType.FLOAT, "licensePlates.colorConfigurations#defaultColorMaxBrightness", "Default colors with higher brightness will be skipped", 0.55)
        schema:register(XMLValueType.L10N_STRING, "licensePlates.colorConfigurations.colorConfiguration(?)#name", "Name of color to display")
        schema:register(XMLValueType.COLOR, "licensePlates.colorConfigurations.colorConfiguration(?)#color", "Color values")
        schema:register(XMLValueType.BOOL, "licensePlates.colorConfigurations.colorConfiguration(?)#isDefault", "Color is default selected")
        schema:register(XMLValueType.STRING, "licensePlates.placement#defaultType", "Default type of placement (none/both/back_only)", "both")
        LicensePlateManager.xmlSchema = schema
    end
end
g_licensePlateManager = LicensePlateManager.new()