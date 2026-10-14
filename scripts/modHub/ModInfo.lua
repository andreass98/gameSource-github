ModInfo = {}
local ModInfo_mt = Class(ModInfo)
function ModInfo.new(modId, postFix, priceString)
    -- upvalues: (copy) ModInfo_mt
    local self = setmetatable({}, ModInfo_mt)
    self.modId = modId
    self.postFix = postFix
    self.priceString = priceString
    return self
end
function ModInfo:getId()
    return self.modId
end
function ModInfo:getName()
    return getModMetaAttributeString(self.modId, "title_" .. self.postFix)
end
function ModInfo:getAuthor()
    return getModMetaAttributeString(self.modId, "author")
end
function ModInfo:getDescription()
    return getModMetaAttributeString(self.modId, "description_" .. self.postFix)
end
function ModInfo:getHash()
    return getModMetaAttributeString(self.modId, "hash")
end
function ModInfo:getPriceString()
    return getModMetaAttributeString(self.modId, self.priceString)
end
function ModInfo:getVersionString()
    return getModMetaAttributeString(self.modId, "versionString")
end
function ModInfo:getDLCLink()
    return getModMetaAttributeString(self.modId, "DLCLink")
end
function ModInfo:getDLCSteamLink()
    return getModMetaAttributeString(self.modId, "DLCSteamLink")
end
function ModInfo:getIconFilename()
    return getModMetaAttributeString(self.modId, "iconImage")
end
function ModInfo:getScreenshot(index)
    local url = getModMetaAttributeString(self.modId, "screenshot" .. index - 1)
    if url == "" then
        return nil
    else
        return url
    end
end
function ModInfo:getScreenshots()
    if self.screenshots == nil then
        local screenshots = {}
        local i = 1
        for i = i, 6 do
            table.insert(screenshots, self:getScreenshot(i))
        end
        self.screenshots = screenshots
    end
    return self.screenshots
end
function ModInfo:getFilesize()
    return getModMetaAttributeInt(self.modId, "filesize")
end
function ModInfo:getFilename()
    return getModMetaAttributeString(self.modId, "filename")
end
function ModInfo:getRatingScore()
    return getModMetaAttributeInt(self.modId, "ratingScore")
end
function ModInfo:getDownloadedBytes()
    return getModMetaAttributeInt(self.modId, "downloaded")
end
function ModInfo:getIsDLC()
    return getModMetaAttributeBool(self.modId, "isDLC")
end
function ModInfo:getIsExternal()
    return getModMetaAttributeBool(self.modId, "isExternal")
end
function ModInfo:getIsNew()
    return getModMetaAttributeBool(self.modId, "isNew")
end
function ModInfo:getIsFeatured()
    return getModMetaAttributeBool(self.modId, "isFeatured")
end
function ModInfo:getIsTesting()
    return getModMetaAttributeBool(self.modId, "isTesting")
end
function ModInfo:getIsInstalled()
    return getModMetaAttributeBool(self.modId, "isInstalled")
end
function ModInfo:getIsUpdate()
    return getModMetaAttributeBool(self.modId, "isUpdate")
end
function ModInfo:getIsDownload()
    return getModMetaAttributeBool(self.modId, "isDownload")
end
function ModInfo:getIsDownloading()
    return getModMetaAttributeBool(self.modId, "isDownloading")
end
function ModInfo:getHasConflict()
    return getModMetaAttributeBool(self.modId, "isConflict")
end
function ModInfo:getIsFailed()
    return getModMetaAttributeBool(self.modId, "isFailed")
end
function ModInfo:getIsIconLocal()
    return getModMetaAttributeBool(self.modId, "isIconImageLocal")
end
function ModInfo:getIsTop()
    return not self:getIsExternal() and not getModMetaAttributeBool(self.modId, "isBeta")
end
function ModInfo:getNumUpdates()
    return self:getIsInstalled() and self:getIsUpdate() and 1 or 0
end
function ModInfo:getNumConflicts()
    return self:getIsInstalled() and self:getHasConflict() and 1 or 0
end
function ModInfo:getNumNew()
    return self:getIsNew() and not (self:getIsInstalled() or (self:getIsDownload() or self:getIsDownloading())) and 1 or 0
end