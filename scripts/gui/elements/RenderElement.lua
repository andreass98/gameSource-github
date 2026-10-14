RenderElement = {}
local RenderElement_mt = Class(RenderElement, GuiElement)
Gui.registerGuiElement("Render", RenderElement)
function RenderElement.new(target, custom_mt)
    -- upvalues: (copy) RenderElement_mt
    local self = GuiElement.new(target, custom_mt or RenderElement_mt)
    self.cameraPath = nil
    self.overlay = nil
    self.useAlpha = true
    self.shapesMask = 255
    self.lightMask = 67108864
    self.renderShadows = false
    self.bloomQuality = 0
    self.enableDof = false
    self.ssaoQuality = 0
    self.asyncShaderCompilation = false
    self.atmosphereQuality = AtmosphereQuality.OFF
    self.isRenderDirty = false
    return self
end
function RenderElement:delete()
    self:destroyScene()
    RenderElement:superClass().delete(self)
end
function RenderElement:loadFromXML(xmlFile, key)
    RenderElement:superClass().loadFromXML(self, xmlFile, key)
    self.filename = getXMLString(xmlFile, key .. "#filename") or self.filename
    self.cameraPath = getXMLString(xmlFile, key .. "#cameraNode") or self.cameraPath
    self.superSamplingFactor = getXMLInt(xmlFile, key .. "#superSamplingFactor") or self.superSamplingFactor
    self.shapesMask = getXMLInt(xmlFile, key .. "#shapesMask") or self.shapesMask
    self.lightMask = getXMLInt(xmlFile, key .. "#lightMask") or self.lightMask
    self.renderShadows = Utils.getNoNil(getXMLBool(xmlFile, key .. "#renderShadows"), self.renderShadows)
    self.bloomQuality = getXMLInt(xmlFile, key .. "#bloomQuality") or self.bloomQuality
    self.enableDof = Utils.getNoNil(getXMLBool(xmlFile, key .. "#enableDof"), self.enableDof)
    self.ssaoQuality = getXMLInt(xmlFile, key .. "#ssaoQuality") or self.ssaoQuality
    self.asyncShaderCompilation = Utils.getNoNil(getXMLBool(xmlFile, key .. "#asyncShaderCompilation"), self.asyncShaderCompilation)
    local atmosphereQualityName = getXMLString(xmlFile, key .. "#atmosphereQuality")
    if not string.isNilOrWhitespace(atmosphereQualityName) then
        local atmosphereQuality = AtmosphereQuality[atmosphereQualityName]
        if atmosphereQuality == nil then
            Logging.xmlWarning(xmlFile, "Invalid atmosphereQuality name \'%s\'", (tostring(atmosphereQualityName)))
        else
            self.atmosphereQuality = atmosphereQuality
        end
    end
    self:addCallback(xmlFile, key .. "#onRenderLoad", "onRenderLoadCallback")
end
function RenderElement:loadProfile(profile, applyProfile)
    RenderElement:superClass().loadProfile(self, profile, applyProfile)
    self.filename = profile:getValue("filename")
    self.cameraPath = profile:getValue("cameraNode")
    self.superSamplingFactor = profile:getNumber("superSamplingFactor")
    local atmosphereQualityName = profile:getValue("atmosphereQuality")
    if not string.isNilOrWhitespace(atmosphereQualityName) then
        local atmosphereQuality = AtmosphereQuality[atmosphereQualityName]
        if atmosphereQuality == nil then
            Logging.warning("Invalid atmosphereQuality name \'%s\'", (tostring(atmosphereQualityName)))
        else
            self.atmosphereQuality = atmosphereQuality
        end
    end
    if applyProfile then
        self:destroyScene()
        self:setScene(self.filename)
    end
end
function RenderElement:copyAttributes(src)
    RenderElement:superClass().copyAttributes(self, src)
    self.filename = src.filename
    self.cameraPath = src.cameraPath
    self.superSamplingFactor = src.superSamplingFactor
    self.atmosphereQuality = src.atmosphereQuality
    self.onRenderLoadCallback = src.onRenderLoadCallback
end
function RenderElement:createScene()
    self:setScene(self.filename)
end
function RenderElement:destroyScene()
    if self.loadingRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.loadingRequestId)
        self.loadingRequestId = nil
    end
    if self.overlay ~= nil then
        delete(self.overlay)
        self.overlay = nil
    end
    if self.scene then
        delete(self.scene)
        self.scene = nil
    end
end
function RenderElement:setScene(i3dFilename)
    if self.loadingRequestId == nil then
        self.isLoading = true
        self.filename = i3dFilename
        self.loadingRequestId = g_i3DManager:loadSharedI3DFileAsync(i3dFilename, false, false, RenderElement.onSceneLoaded, self, nil)
    else
        Logging.error("Could not create scene. Another scene is already loaded. Destroy the scene first!")
    end
end
function RenderElement:onSceneLoaded(node, failedReason, _)
    self.isLoading = false
    if failedReason == LoadI3DFailedReason.FILE_NOT_FOUND or failedReason == LoadI3DFailedReason.UNKNOWN then
        Logging.error("Failed to load RenderElement scene from \'%s\'", self.filename)
    end
    if failedReason == LoadI3DFailedReason.NONE then
        self.scene = node
        link(getRootNode(), node)
        setVisibility(node, false)
        self:createOverlay()
    elseif node ~= 0 then
        delete(node)
    end
end
function RenderElement:createOverlay()
    if self.overlay ~= nil then
        delete(self.overlay)
        self.overlay = nil
    end
    local aspectRatio = g_screenWidth * self.absSize[1]
    local resolutionX = math.ceil(aspectRatio) * self.superSamplingFactor
    local camera = g_screenHeight * self.absSize[2]
    local resolutionY = math.ceil(camera) * self.superSamplingFactor
    local aspectRatio = resolutionX / resolutionY
    local camera = I3DUtil.indexToObject(self.scene, self.cameraPath)
    if camera == nil then
        Logging.error("Could not find camera node \'%s\' in render overlay scene \'%s\'", self.cameraPath, self.filename)
        return
    else
        local overlay = createRenderOverlay(self.scene, camera, aspectRatio, resolutionX, resolutionY, self.useAlpha, self.shapesMask, self.lightMask, self.renderShadows, self.bloomQuality, self.enableDof, self.ssaoQuality, self.asyncShaderCompilation, self.atmosphereQuality)
        if overlay == 0 then
            Logging.error("Could not create render overlay for scene \'%s\'", self.filename)
        else
            self.overlay = overlay
            self.isRenderDirty = true
            self:raiseCallback("onRenderLoadCallback", self.scene, self.overlay)
        end
    end
end
function RenderElement:setVisible(visible)
    RenderElement:superClass().setVisible(self, visible)
    setVisibility(self.scene, visible)
end
function RenderElement:update(dt)
    RenderElement:superClass().update(self, dt)
    if self.isRenderDirty and self.overlay ~= nil then
        updateRenderOverlay(self.overlay)
        self.isRenderDirty = false
    end
end
function RenderElement:draw(clipX1, clipY1, clipX2, clipY2)
    if not self.isLoading and self.overlay ~= nil then
        local sizeX = self.size[1]
        local sizeY = self.size[2]
        local u1 = 0
        local v1 = 0
        local u2 = 0
        local v2 = 1
        local u3 = 1
        local v3 = 0
        local u4 = 1
        local v4 = 1
        local p1, p1
        if clipX1 == nil then
            p1 = self.absPosition[1]
            p1 = self.absPosition[2]
        else
            local oldX2 = sizeX + posX
            local oldY2 = sizeY + posY
            p1 = math.max(posX, clipX1)
            p1 = math.max(posY, clipY1)
            local p2 = math.min(posX + sizeX, clipX2) - p1
            sizeX = math.max(p2, 0)
            local p2 = math.min(posY + sizeY, clipY2) - p1
            sizeY = math.max(p2, 0)
            v3 = (p1 - posY) / (oldY2 - posY)
            v2 = (p1 + sizeY - posY) / (oldY2 - posY)
            u3 = (p1 + sizeX - posX) / (oldX2 - posX)
            u1 = (p1 - posX) / (oldX2 - posX)
        end
        if u1 ~= u3 and v1 ~= v2 then
            setOverlayUVs(self.overlay, u1, v1, u2, v2, u3, v3, u4, v4)
            renderOverlay(self.overlay, p1, p1, sizeX, sizeY)
        end
    end
    RenderElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end
function RenderElement:canReceiveFocus()
    return false
end
function RenderElement:getSceneRoot()
    return self.scene
end
function RenderElement:setRenderDirty()
    self.isRenderDirty = true
end