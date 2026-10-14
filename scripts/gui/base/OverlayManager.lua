OverlayManager = {}
local OverlayManager_mt = Class(OverlayManager)
function OverlayManager.new()
    -- upvalues: (copy) OverlayManager_mt
    local self = setmetatable({}, OverlayManager_mt)
    self.textureConfigs = {}
    addConsoleCommand("gsOverlayManagerReset", "Deletes all currently loaded texture configurations", "resetConfigurations", self)
    g_plainColorSliceId = "gui.colorPreset"
    return self
end
function OverlayManager:addTextureConfigFile(filename, prefix, customEnv)
    if customEnv ~= nil then
    end
    if filename == nil then
        Logging.warning("Filename for texture config file is empty")
        return
    elseif self.textureConfigs[prefix] == nil or g_gui.currentlyReloading then
        local xmlFile = XMLFile.load("TextureConfig", filename)
        local directory = Utils.getDirectory(filename)
        if xmlFile == nil then
            Logging.warning("Failed to load XML file from path \'%s\'", filename)
            return
        else
            local textureConfig = {
                ["xmlFilename"] = filename
            }
            local imageFilename = xmlFile:getString("texture.meta.filename")
            if imageFilename == nil then
                Logging.xmlWarning(xmlFile, "Missing filename in meta data")
                return
            else
                textureConfig.imageFilename = directory .. imageFilename
                local imageWidth = xmlFile:getInt("texture.meta.size#width")
                if imageWidth == nil then
                    Logging.xmlWarning(xmlFile, "Missing imageWidth in meta data")
                    return
                else
                    local imageHeight = xmlFile:getInt("texture.meta.size#height")
                    if imageHeight == nil then
                        Logging.xmlWarning(xmlFile, "Missing imageHeight in meta data")
                    else
                        textureConfig.imageSize = { imageWidth, imageHeight }
                        textureConfig.slices = {}
                        xmlFile:iterate("texture.slices.slice", function(num, key)
                            -- upvalues: (copy) xmlFile, (ref) prefix, (copy) textureConfig
                            local id = xmlFile:getString(key .. "#id")
                            if id == nil then
                                Logging.xmlWarning(xmlFile, "Missing ID for slice nr. %i", num)
                                return
                            else
                                ({}).sliceId = prefix .. "." .. id
                                local uvsStr = xmlFile:getString(key .. "#uvs")
                                if uvsStr == nil then
                                    Logging.xmlWarning(xmlFile, "Missing UVs for slice with ID %s", slice.sliceId)
                                else
                                    local _, _, width, height = unpack(GuiUtils.getNormalizedScreenValues(uvsStr))
                                    if width == nil then
                                        slice.width = 0
                                        Logging.xmlWarning(xmlFile, "Missing width for slice with ID %s", slice.sliceId)
                                    else
                                        slice.width = GuiUtils.getNormalizedXValue(width)
                                    end
                                    if height == nil then
                                        slice.height = 0
                                        Logging.xmlWarning(xmlFile, "Missing height for slice with ID %s", slice.sliceId)
                                    else
                                        slice.height = GuiUtils.getNormalizedYValue(height)
                                    end
                                    local _, _, widthStr, heightStr = unpack(string.split(uvsStr, " "))
                                    slice.uvsStr = uvsStr
                                    slice.size = { width, height }
                                    slice.sizeStr = widthStr .. " " .. heightStr
                                    slice.imageSize = textureConfig.imageSize
                                    slice.filename = textureConfig.imageFilename
                                    slice.uvs = GuiUtils.getUVs(uvsStr, textureConfig.imageSize, {
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0
                                    })
                                    if textureConfig.slices[id] ~= nil then
                                        Logging.xmlWarning(xmlFile, "Duplicate slice ID %s", slice.sliceId)
                                    end
                                    textureConfig.slices[id] = slice
                                end
                            end
                        end)
                        self.textureConfigs[prefix] = textureConfig
                        xmlFile:delete()
                    end
                end
            end
        end
    else
        Logging.warning("Texture config file with prefix \'%s\' already exists", prefix)
        return
    end
end
function OverlayManager:resetConfigurations()
    self.textureConfigs = {}
    Logging.info("OverlayManager: Deleted all texture configurations")
end
function OverlayManager:createOverlay(identifier, posX, posY, width, height, customEnv)
    local identifierSplit = string.split(identifier, ".")
    local prefix = identifierSplit[1]
    local sliceId = identifierSplit[2]
    if prefix == nil or sliceId == nil then
        Logging.warning("Identifier \'%s\' does not contain prefix or slice ID", identifier)
        return nil
    end
    if customEnv ~= nil then
    end
    local textureConfig = self.textureConfigs[prefix]
    if textureConfig == nil then
        Logging.warning("No texture config with prefix \'%s\' found", prefix)
        return nil
    end
    local slice = textureConfig.slices[sliceId]
    if slice == nil then
        Logging.xmlWarning(textureConfig.xmlFilename, "No slice with ID \'%s\' found in texture config \'%s\'", sliceId, prefix)
        return nil
    end
    Overlay.new(textureConfig.imageFilename, posX or 0, posY or 0, width or slice.width, height or slice.height):setUVs(slice.uvs)
    return overlay
end
function OverlayManager:getSliceInfoById(identifier, customEnv)
    if identifier == nil then
        return nil
    end
    local identifierSplit = string.split(identifier, ".")
    local prefix = identifierSplit[1]
    local sliceId = identifierSplit[2]
    if prefix == nil or sliceId == nil then
        Logging.warning("Identifier \'%s\' does not contain prefix or slice ID", identifier)
        return nil
    end
    if customEnv ~= nil then
    end
    local textureConfig = self.textureConfigs[prefix]
    if textureConfig == nil then
        Logging.warning("No texture config with prefix \'%s\' found", prefix)
        return nil
    end
    local slice = textureConfig.slices[sliceId]
    if slice ~= nil then
        return slice
    end
    Logging.warning("No slice with ID \'%s\' found in texture config \'%s\'", sliceId, prefix)
    return nil
end
function OverlayManager:getConfigMetaData(configPrefix, customEnv)
    if configPrefix == nil then
        Logging.warning("Texture config prefix is empty")
        return nil
    end
    if customEnv ~= nil then
    end
    local textureConfig = self.textureConfigs[configPrefix]
    if textureConfig ~= nil then
        return {
            ["filename"] = textureConfig.imageFilename,
            ["imageSize"] = textureConfig.imageSize
        }
    end
    Logging.warning("No texture config with prefix \'%s\' found", configPrefix)
    return nil
end