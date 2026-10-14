VideoElement = {}
local VideoElement_mt = Class(VideoElement, GuiElement)
Gui.registerGuiElement("Video", VideoElement)
function VideoElement.new(target, custom_mt)
    -- upvalues: (copy) VideoElement_mt
    local self = VideoElement:superClass().new(target, custom_mt or VideoElement_mt)
    self.videoFilename = nil
    self.allowStop = true
    self.isLooping = false
    self.volume = 1
    self.duration = 0
    self.subtitles = {}
    self.subtitlesElement = nil
    self.subtitleElementId = nil
    self.currentSubtitleIndex = 0
    self.playbackBarElement = nil
    self.playbackBarElementId = nil
    self.timeLeftElement = nil
    self.timeLeftElementId = nil
    return self
end
function VideoElement:loadFromXML(xmlFile, key)
    VideoElement:superClass().loadFromXML(self, xmlFile, key)
    self.videoFilename = getXMLString(xmlFile, key .. "#videoFilename") or self.videoFilename
    self.volume = getXMLFloat(xmlFile, key .. "#volume") or self.volume
    self.allowStop = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowStop"), self.allowStop)
    self.isLooping = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isLooping"), self.isLooping)
    self.subtitleElementId = getXMLString(xmlFile, key .. "#subtitleElementId") or self.subtitleElementId
    self.playbackBarElementId = Utils.getNoNil(getXMLString(xmlFile, key .. "#playbackBarElementId"), self.playbackBarElementId)
    self.timeLeftElementId = Utils.getNoNil(getXMLString(xmlFile, key .. "#timeLeftElementId"), self.timeLeftElementId)
    self:addCallback(xmlFile, key .. "#onEndVideo", "onEndVideoCallback")
    self:changeVideo(self.videoFilename)
end
function VideoElement:loadProfile(profile, applyProfile)
    VideoElement:superClass().loadProfile(self, profile, applyProfile)
    self.videoFilename = profile:getValue("videoFilename", self.videoFilename)
    self.volume = profile:getNumber("volume", self.volume)
    self.allowStop = profile:getBool("allowStop", self.allowStop)
    self.isLooping = profile:getBool("isLooping", self.isLooping)
    self.subtitleElementId = profile:getValue("subtitleElementId", self.subtitleElementId)
    self.playbackBarElementId = profile:getValue("playbackBarElementId", self.playbackBarElementId)
    self.timeLeftElementId = profile:getValue("timeLeftElementId", self.timeLeftElementId)
end
function VideoElement:copyAttributes(src)
    VideoElement:superClass().copyAttributes(self, src)
    self:changeVideo(src.videoFilename)
    self.volume = src.volume
    self.allowStop = src.allowStop
    self.isLooping = src.isLooping
    self.onEndVideoCallback = src.onEndVideoCallback
    self.subtitles = src.subtitles
    self.subtitleElementId = src.subtitleElementId
    self.playbackBarElementId = src.playbackBarElementId
    self.timeLeftElementId = src.timeLeftElementId
end
function VideoElement:onGuiSetupFinished()
    VideoElement:superClass().onGuiSetupFinished(self)
    if self.subtitleElementId ~= nil then
        local subtitlesElement = self.parent:getDescendantById(self.subtitleElementId)
        if subtitlesElement == nil then
            Logging.warning("subtitleElementId \'%s\' not found for \'%s\'!", self.subtitleElementId, self.parent.name)
        else
            self.subtitlesElement = subtitlesElement
        end
    end
    if self.playbackBarElementId ~= nil then
        local subtitlesElement = self.parent:getDescendantById(self.playbackBarElementId)
        if subtitlesElement == nil then
            Logging.warning("playbackBarElementId \'%s\' not found for \'%s\'!", self.playbackBarElementId, self.parent.name)
        else
            self.playbackBarElement = subtitlesElement
        end
    end
    if self.timeLeftElementId ~= nil then
        local subtitlesElement = self.parent:getDescendantById(self.timeLeftElementId)
        if subtitlesElement ~= nil then
            self.timeLeftElement = subtitlesElement
            return
        end
        Logging.warning("timeLeftElementId \'%s\' not found for \'%s\'!", self.timeLeftElementId, self.parent.name)
    end
end
function VideoElement:delete()
    self:disposeVideo()
    VideoElement:superClass().delete(self)
end
function VideoElement:loadSubtitles(filename)
    if filename ~= nil then
        local cleanName = Utils.getFilenameInfo(self.videoFilename)
        if cleanName ~= nil then
            local xmlFile = XMLFile.loadIfExists("Subtitles", cleanName .. ".xml")
            if xmlFile ~= nil then
                self.subtitles = {}
                xmlFile:iterate("Subtitles.Subtitle", function(_, key)
                    -- upvalues: (copy) xmlFile, (copy) self
                    local subtitle = {
                        ["startTime"] = xmlFile:getFloat(key .. "#startTime"),
                        ["endTime"] = xmlFile:getFloat(key .. "#endTime"),
                        ["text"] = g_i18n:convertText(xmlFile:getString(key .. "#text"))
                    }
                    if subtitle.startTime ~= nil and (subtitle.endTime ~= nil and subtitle.text ~= nil) then
                        table.insert(self.subtitles, subtitle)
                    end
                end)
            end
        end
    end
end
function VideoElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    if self:getIsActive() then
        eventUsed = VideoElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) and true or eventUsed
        if not eventUsed and self.allowStop then
            if isDown and self.overlay ~= nil then
                self:disposeVideo()
                self:onEndVideo()
            end
            return true
        end
    end
    return eventUsed
end
function VideoElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
    if not self:getIsActive() then
        return eventUsed
    end
    VideoElement:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed)
    if isDown and self.overlay ~= nil then
        self:disposeVideo()
        self:onEndVideo()
    end
    return true
end
function VideoElement:update(dt)
    VideoElement:superClass().update(self, dt)
    if self.overlay == nil then
        return
    end
    if not isVideoOverlayReadyToPlay(self.overlay) then
        return
    end
    if self.playPending then
        playVideoOverlay(self.overlay)
        self.playPending = false
    end
    if isVideoOverlayPlaying(self.overlay) then
        updateVideoOverlay(self.overlay)
        if self.subtitlesElement ~= nil then
            local videoCurrentTime = getVideoOverlayCurrentTime(self.overlay)
            local currentSubtitle = self.subtitles[self.currentSubtitleIndex]
            if videoCurrentTime ~= nil and (currentSubtitle ~= nil and currentSubtitle.endTime <= videoCurrentTime) then
                self.subtitlesElement:setText("")
            end
            if currentSubtitle == nil or currentSubtitle.endTime <= videoCurrentTime then
                local index = self.currentSubtitleIndex + 1
                for index = index, #self.subtitles do
                    local subtitle = self.subtitles[index]
                    if subtitle.startTime <= videoCurrentTime and videoCurrentTime <= subtitle.endTime then
                        self.subtitlesElement:setText(subtitle.text)
                        self.currentSubtitleIndex = index
                        break
                    end
                end
            end
        end
        if self.playbackBarElement ~= nil then
            local timeLeftMinutes = (getVideoOverlayCurrentTime(self.overlay) or 1) / self.duration
            local currentSubtitle = math.min(timeLeftMinutes, 1)
            self.playbackBarElement.absSize[1] = self.playbackBarElement.size[1] * currentSubtitle
        end
        if self.timeLeftElement ~= nil then
            local videoCurrentTime = getVideoOverlayCurrentTime(self.overlay) or 1
            local currentSubtitle = math.max(0, self.duration - videoCurrentTime)
            local timeLeftMinutes = math.floor(currentSubtitle / 60)
            self.timeLeftElement:setText(string.format("-%02d:%02d", timeLeftMinutes, currentSubtitle % 60))
            return
        end
    else
        self:disposeVideo()
        self:onEndVideo()
    end
end
function VideoElement:draw(clipX1, clipY1, clipX2, clipY2)
    if self.overlay ~= nil then
        if isVideoOverlayReadyToPlay(self.overlay) then
            if isVideoOverlayPlaying(self.overlay) then
                renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
            end
        else
            setTextColor(1, 1, 1, 1)
            setTextBold(true)
            setTextAlignment(RenderText.ALIGN_CENTER)
            local textSize = getCorrectTextSize(0.02)
            renderText(self.absPosition[1] + self.size[1] * 0.5, self.absPosition[2] + self.size[2] * 0.5, textSize, g_i18n:getText("ui_loading"))
            setTextBold(false)
            setTextAlignment(RenderText.ALIGN_LEFT)
        end
    end
    VideoElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end
function VideoElement:onEndVideo()
    if self.onEndVideoCallback ~= nil then
        if self.target ~= nil then
            self.onEndVideoCallback(self.target)
            return
        end
        self.onEndVideoCallback()
    end
end
function VideoElement:disposeVideo()
    if self.overlay ~= nil then
        self:stopVideo()
        delete(self.overlay)
        self.overlay = nil
    end
    if self.subtitlesElement ~= nil then
        self.subtitlesElement:setText("")
    end
end
function VideoElement:getIsActive()
    return self:getIsVisible()
end
function VideoElement:playVideo()
    if self.overlay ~= nil then
        self.playPending = true
        self.currentSubtitleIndex = 0
    end
end
function VideoElement:stopVideo()
    self.playPending = false
    if self.overlay ~= nil and isVideoOverlayPlaying(self.overlay) then
        stopVideoOverlay(self.overlay)
    end
end
function VideoElement:changeVideo(newVideoFilename, volume, duration)
    self:disposeVideo()
    self.videoFilename = newVideoFilename
    if self.videoFilename ~= nil then
        local videoFilename = string.gsub(self.videoFilename, "$l10nSuffix", g_languageSuffix)
        self.overlay = createVideoOverlay(videoFilename, self.isLooping, volume or self.volume)
        self.duration = duration
        self:loadSubtitles(videoFilename)
    end
end