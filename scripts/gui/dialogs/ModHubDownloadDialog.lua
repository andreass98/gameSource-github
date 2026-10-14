ModHubDownloadDialog = {}
local ModHubDownloadDialog_mt = Class(ModHubDownloadDialog, MessageDialog)
function ModHubDownloadDialog.register()
    local modHubDownloadDialog = ModHubDownloadDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/ModHubDownloadDialog.xml", "ModHubDownloadDialog", modHubDownloadDialog)
    ModHubDownloadDialog.INSTANCE = modHubDownloadDialog
end
function ModHubDownloadDialog.show(downloads)
    if ModHubDownloadDialog.INSTANCE ~= nil then
        local dialog = ModHubDownloadDialog.INSTANCE
        g_gui:showDialog("ModHubDownloadDialog")
    end
end
function ModHubDownloadDialog.new(target, custom_mt)
    -- upvalues: (copy) ModHubDownloadDialog_mt
    local self = MessageDialog.new(target, custom_mt or ModHubDownloadDialog_mt)
    self.activeDownloads = nil
    self.updateTime = 200
    self.disableOpenSound = true
    return self
end
function ModHubDownloadDialog.createFromExistingGui(gui, guiName)
    ModHubDownloadDialog.register()
    ModHubDownloadDialog.show()
end
function ModHubDownloadDialog:onOpen()
    ModHubDownloadDialog:superClass().onOpen(self)
    self:updateActiveDownloads()
end
function ModHubDownloadDialog:updateActiveDownloads()
    local category = g_modHubController:getCategory("download")
    self.activeDownloads = {}
    if category ~= nil then
        self.activeDownloads = g_modHubController:getModsByCategory(category.id, true)
    end
    self.downloadList:reloadData()
end
function ModHubDownloadDialog.updateDownloadCell(_, cell, modInfo)
    local isDownloading = modInfo:getIsDownloading()
    local isInstalled = modInfo:getIsInstalled()
    local isDownload = modInfo:getIsDownload()
    local isFailed = modInfo:getIsFailed()
    local percent = 0
    local downloadedKBText = ""
    if isDownloading or isDownload then
        local downloaded = modInfo:getDownloadedBytes()
        local fileSize = modInfo:getFilesize()
        local fileSizeKB = fileSize / 1024
        local fileSizeMB = fileSizeKB / 1024
        local downloadedKB = downloaded / 1024
        local downloadedMB = downloadedKB / 1024
        local downloadedText
        if fileSizeMB < 1 then
            downloadedText = string.format("%d KB", fileSizeKB)
        else
            downloadedText = string.format("%d MB", fileSizeMB)
        end
        local downloadedText
        if downloadedMB < 1 then
            downloadedText = string.format("%d KB", downloadedKB)
        else
            downloadedText = string.format("%d MB", downloadedMB)
        end
        downloadedKBText = string.format("( %s / %s )", downloadedText, downloadedText)
        if fileSize ~= 0 then
            percent = math.clamp(downloaded / fileSize, 0, 1) or percent
        end
    elseif isInstalled then
        percent = 1
    end
    local downloaded = cell:getAttribute("statusBar")
    local fileSize = downloaded.startSize[1] + downloaded.endSize[1]
    local downloadedMB = downloaded.parent.size[1] * percent + g_pixelSizeX
    downloaded:setSize(math.max(downloadedMB, fileSize), nil)
    cell:getAttribute("percentage"):setText(downloadedKBText .. " " .. g_i18n:formatNumber(percent * 100, 0) .. "%")
    downloaded.parent:setVisible(not isFailed)
    cell:getAttribute("failed"):setVisible(isFailed)
end
function ModHubDownloadDialog:update(dt)
    ModHubDownloadDialog:superClass().update(self, dt)
    self.updateTime = self.updateTime - dt
    if self.updateTime < 0 then
        self:updateActiveDownloads()
        self.updateTime = 200
    end
end
function ModHubDownloadDialog:getNumberOfItemsInSection(_, _)
    return #self.activeDownloads
end
function ModHubDownloadDialog:populateCellForItemInSection(_, _, index, cell)
    local modInfo = self.activeDownloads[index]
    local iconElement = cell:getAttribute("icon")
    iconElement:setIsWebOverlay(not modInfo:getIsIconLocal())
    iconElement:setImageFilename(modInfo:getIconFilename())
    cell:getAttribute("name"):setText(modInfo:getName())
    self:updateDownloadCell(cell, modInfo)
end