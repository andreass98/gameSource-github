GuiElement = {}
local GuiElement_mt = Class(GuiElement)
Gui.registerGuiElement("GuiElement", GuiElement)
GuiElement.SCREEN_ALIGN_LEFT = 1
GuiElement.SCREEN_ALIGN_CENTER = 2
GuiElement.SCREEN_ALIGN_RIGHT = 4
GuiElement.SCREEN_ALIGN_BOTTOM = 8
GuiElement.SCREEN_ALIGN_MIDDLE = 16
GuiElement.SCREEN_ALIGN_TOP = 32
GuiElement.SCREEN_ALIGN_XNONE = 64
GuiElement.SCREEN_ALIGN_YNONE = 128
GuiElement.ORIGIN_LEFT = 1
GuiElement.ORIGIN_CENTER = 2
GuiElement.ORIGIN_RIGHT = 4
GuiElement.ORIGIN_BOTTOM = 8
GuiElement.ORIGIN_MIDDLE = 16
GuiElement.ORIGIN_TOP = 32
GuiElement.MARGIN_LEFT = 1
GuiElement.MARGIN_TOP = 2
GuiElement.MARGIN_RIGHT = 3
GuiElement.MARGIN_BOTTOM = 4
GuiElement.FRAME_LEFT = 1
GuiElement.FRAME_TOP = 2
GuiElement.FRAME_RIGHT = 3
GuiElement.FRAME_BOTTOM = 4
GuiElement.FRAME_DEFAULT_COLOR = {
    1,
    1,
    1,
    1
}
GuiElement.SCROLL_SPEED_PIXEL_PER_MS = 0.005
GuiElement.debugOverlay = createImageOverlay("dataS/menu/base/graph_pixel.png")
function GuiElement.new(target, custom_mt)
    -- upvalues: (copy) GuiElement_mt
    local self = setmetatable({}, custom_mt or GuiElement_mt)
    self:include(GuiMixin)
    self.elements = {}
    self.target = target
    self.profile = ""
    self.name = nil
    self.debugEnabled = false
    self.position = { 0, 0 }
    self.absPosition = { 0, 0 }
    self.size = { 1, 1 }
    self.absSize = { 1, 1 }
    self.sizeStr = "100% 100%"
    self.widthStr = nil
    self.heightStr = nil
    self.margin = {
        0,
        0,
        0,
        0
    }
    self.anchors = {
        0,
        1,
        0,
        1
    }
    self.anchorDeltas = {}
    self.pivot = { 0, 0 }
    self.absoluteSizeOffset = nil
    self.thinLineProtection = true
    self.disallowFlowCut = false
    self.visible = true
    self.disabled = false
    self.selected = false
    self.focused = false
    self.highlighted = false
    self.alpha = 1
    self.fadeInTime = 0
    self.fadeOutTime = 0
    self.fadeDirection = 0
    self.newLayer = false
    self.toolTipText = nil
    self.toolTipElementId = nil
    self.toolTipElement = nil
    self.layoutIgnore = false
    self.focusOnHighlight = false
    self.focusFallthrough = false
    self.clipping = false
    self.hotspot = nil
    self.hasFrame = false
    if self.hasFrame then
        self.frameThickness = {
            0,
            0,
            0,
            0
        }
        self.frameColors = {
            [GuiElement.FRAME_LEFT] = {
                1,
                1,
                1,
                1
            },
            [GuiElement.FRAME_TOP] = {
                1,
                1,
                1,
                1
            },
            [GuiElement.FRAME_RIGHT] = {
                1,
                1,
                1,
                1
            },
            [GuiElement.FRAME_BOTTOM] = {
                1,
                1,
                1,
                1
            }
        }
        self.frameOverlayVisible = {
            true,
            true,
            true,
            true
        }
    end
    self.updateChildrenState = true
    self.overlayState = GuiOverlay.STATE_NORMAL
    self.previousOverlayState = nil
    self.isSoundSuppressed = false
    self.soundDisabled = false
    self.handleFocus = true
    self.focusChangeData = {}
    self.focusId = nil
    return self
end
function GuiElement:loadFromXML(xmlFile, key)
    local profile = getXMLString(xmlFile, key .. "#profile")
    if profile ~= nil then
        self.profile = profile
        self:loadProfile((g_gui:getProfile(profile)))
    end
    self:setId(xmlFile, key)
    self.onCreateArgs = getXMLString(xmlFile, key .. "#onCreateArgs")
    self:addCallback(xmlFile, key .. "#onCreate", "onCreateCallback")
    self:addCallback(xmlFile, key .. "#onOpen", "onOpenCallback")
    self:addCallback(xmlFile, key .. "#onClose", "onCloseCallback")
    self:addCallback(xmlFile, key .. "#onDraw", "onDrawCallback")
    self.name = getXMLString(xmlFile, key .. "#name") or self.name
    self.pivot = string.getVector(getXMLString(xmlFile, key .. "#pivot"), 2) or self.pivot
    self.position = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#position"), self.position)
    self.sizeStr = getXMLString(xmlFile, key .. "#size") or self.sizeStr
    self.widthStr = getXMLString(xmlFile, key .. "#width") or self.widthStr
    self.heightStr = getXMLString(xmlFile, key .. "#height") or self.heightStr
    self.absoluteSizeOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#absoluteSizeOffset"), self.absoluteSizeOffset)
    self.margin = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#margin"), self.margin)
    self.anchors = string.getVector(getXMLString(xmlFile, key .. "#anchors"), 4) or self.anchors
    self.thinLineProtection = Utils.getNoNil(getXMLBool(xmlFile, key .. "#thinLineProtection"), self.thinLineProtection)
    self.visible = Utils.getNoNil(getXMLBool(xmlFile, key .. "#visible"), self.visible)
    self.disabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#disabled"), self.disabled)
    self.newLayer = Utils.getNoNil(getXMLBool(xmlFile, key .. "#newLayer"), self.newLayer)
    self.debugEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#debugEnabled"), self.debugEnabled)
    self.updateChildrenState = Utils.getNoNil(getXMLBool(xmlFile, key .. "#updateChildrenState"), self.updateChildrenState)
    self.toolTipText = getXMLString(xmlFile, key .. "#toolTipText")
    self.toolTipElementId = getXMLString(xmlFile, key .. "#toolTipElementId")
    self.layoutIgnore = Utils.getNoNil(getXMLBool(xmlFile, key .. "#layoutIgnore"), self.layoutIgnore)
    self.clipping = Utils.getNoNil(getXMLBool(xmlFile, key .. "#clipping"), self.clipping)
    self.hotspot = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#hotspot"), self.hotspot)
    self.handleFocus = Utils.getNoNil(getXMLBool(xmlFile, key .. "#handleFocus"), self.handleFocus)
    self.soundDisabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#soundDisabled"), self.soundDisabled)
    self.focusOnHighlight = Utils.getNoNil(getXMLBool(xmlFile, key .. "#focusOnHighlight"), self.focusOnHighlight)
    self.focusFallthrough = Utils.getNoNil(getXMLBool(xmlFile, key .. "#focusFallthrough"), self.focusFallthrough)
    self.disallowFlowCut = Utils.getNoNil(getXMLBool(xmlFile, key .. "#disallowFlowCut"), self.disallowFlowCut)
    self.hasFrame = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hasFrame"), self.hasFrame)
    if self.hasFrame then
        self.frameThickness = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#frameThickness"), self.frameThickness)
        local pro = self.frameColors or {}
        local color = getXMLString(xmlFile, key .. "#frameLeftColor")
        pro[GuiElement.FRAME_LEFT] = GuiUtils.getColorArray(color, pro[GuiElement.FRAME_LEFT])
        local color = getXMLString(xmlFile, key .. "#frameTopColor")
        pro[GuiElement.FRAME_TOP] = GuiUtils.getColorArray(color, pro[GuiElement.FRAME_TOP])
        local color = getXMLString(xmlFile, key .. "#frameRightColor")
        pro[GuiElement.FRAME_RIGHT] = GuiUtils.getColorArray(color, pro[GuiElement.FRAME_RIGHT])
        local color = getXMLString(xmlFile, key .. "#frameBottomColor")
        pro[GuiElement.FRAME_BOTTOM] = GuiUtils.getColorArray(color, pro[GuiElement.FRAME_BOTTOM])
        self.frameColors = table.size(pro) > 0 and pro and pro or nil
        self.frameOverlayVisible = self.frameOverlayVisible or {
            true,
            true,
            true,
            true
        }
    end
    local pro = getXMLFloat(xmlFile, key .. "#fadeInTime")
    if pro ~= nil then
        self.fadeInTime = pro * 1000
    end
    local color = getXMLFloat(xmlFile, key .. "#fadeOutTime")
    if color ~= nil then
        self.fadeOutTime = color * 1000
    end
    if self.toolTipText ~= nil and self.toolTipText:sub(1, 6) == "$l10n_" then
        self.toolTipText = g_i18n:getText(self.toolTipText:sub(7), self.customEnvironment)
    end
    FocusManager:loadElementFromXML(xmlFile, key, self)
    self:resolveSizeString()
    self:verifyConfiguration()
end
function GuiElement:loadProfile(profile, applyProfile)
    self.name = profile:getValue("name", self.name)
    self.pivot = string.getVector(profile:getValue("pivot"), 2) or self.pivot
    self.position = GuiUtils.getNormalizedScreenValues(profile:getValue("position"), self.position)
    self.sizeStr = profile:getValue("size", self.sizeStr)
    self.widthStr = profile:getValue("width", self.widthStr)
    self.heightStr = profile:getValue("height", self.heightStr)
    self.absoluteSizeOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("absoluteSizeOffset"), self.absoluteSizeOffset)
    self.margin = GuiUtils.getNormalizedScreenValues(profile:getValue("margin"), self.margin)
    self.anchors = string.getVector(profile:getValue("anchors"), 4) or self.anchors
    self.visible = profile:getBool("visible", self.visible)
    self.disabled = profile:getBool("disabled", self.disabled)
    self.newLayer = profile:getBool("newLayer", self.newLayer)
    self.debugEnabled = profile:getBool("debugEnabled", self.debugEnabled)
    self.updateChildrenState = profile:getBool("updateChildrenState", self.updateChildrenState)
    self.toolTipText = profile:getValue("toolTipText", self.toolTipText)
    self.layoutIgnore = profile:getBool("layoutIgnore", self.layoutIgnore)
    self.thinLineProtection = profile:getBool("thinLineProtection", self.thinLineProtection)
    self.clipping = profile:getBool("clipping", self.clipping)
    self.focusOnHighlight = profile:getBool("focusOnHighlight", self.focusOnHighlight)
    self.focusFallthrough = profile:getBool("focusFallthrough", self.focusFallthrough)
    self.disallowFlowCut = profile:getBool("disallowFlowCut", self.disallowFlowCut)
    self.hotspot = GuiUtils.getNormalizedScreenValues(profile:getValue("hotspot"), self.hotspot)
    self.hasFrame = profile:getBool("hasFrame", self.hasFrame)
    if self.hasFrame then
        self.frameThickness = GuiUtils.getNormalizedScreenValues(profile:getValue("frameThickness"), self.frameThickness)
        local frameColors = self.frameColors or {}
        frameColors[GuiElement.FRAME_LEFT] = GuiUtils.getColorArray(profile:getValue("frameLeftColor"), frameColors[GuiElement.FRAME_LEFT])
        frameColors[GuiElement.FRAME_TOP] = GuiUtils.getColorArray(profile:getValue("frameTopColor"), frameColors[GuiElement.FRAME_TOP])
        frameColors[GuiElement.FRAME_RIGHT] = GuiUtils.getColorArray(profile:getValue("frameRightColor"), frameColors[GuiElement.FRAME_RIGHT])
        frameColors[GuiElement.FRAME_BOTTOM] = GuiUtils.getColorArray(profile:getValue("frameBottomColor"), frameColors[GuiElement.FRAME_BOTTOM])
        self.frameColors = table.size(frameColors) > 0 and frameColors and frameColors or nil
        self.frameOverlayVisible = self.frameOverlayVisible or {
            true,
            true,
            true,
            true
        }
    end
    self.handleFocus = profile:getBool("handleFocus", self.handleFocus)
    self.soundDisabled = profile:getBool("soundDisabled", self.soundDisabled)
    local frameColors = profile:getValue("fadeInTime")
    if frameColors ~= nil then
        local fadeOutTime = tonumber(frameColors)
        if fadeOutTime == nil then
            Logging.devWarning("Invalid fadeInTime format for profile \'%s\'", self.profile)
        else
            self.fadeInTime = fadeOutTime * 1000
        end
    end
    local fadeOutTime = profile:getValue("fadeOutTime")
    if fadeOutTime ~= nil then
        local fadeOutTime = tonumber(fadeOutTime)
        if fadeOutTime == nil then
            Logging.devWarning("Invalid fadeOutTime format for profile \'%s\'", self.profile)
        else
            self.fadeOutTime = fadeOutTime * 1000
        end
    end
    if applyProfile then
        self:resolveSizeString()
        self:fixThinLines()
        self:updateAbsolutePosition()
    end
end
function GuiElement:applyProfile(profileName, blockSizeUpdate, ignoreSameProfile)
    if profileName and (ignoreSameProfile ~= true or profileName ~= self.profile) then
        local pro = g_gui:getProfile(profileName)
        if pro ~= nil then
            self.profile = profileName
            self:loadProfile(pro, not blockSizeUpdate)
        end
    end
end
function GuiElement:resolveSizeString()
    local sizes = string.split(self.sizeStr, " ")
    for i, str in pairs(sizes) do
        if not (function(str, isXVariable)
            -- upvalues: (copy) self
            if string.find(str, "%%") == nil then
                self.size[isXVariable and 1 or 2] = GuiUtils.getNormalizedValue(str, isXVariable) or self.size[isXVariable and 1 or 2]
            else
                local percent = string.gsub(str, "%%", "")
                local percent = tonumber(percent)
                if percent == nil then
                    Logging.warning("GuiElement:resolveSizeString: String %s could not be converted to a number", percent)
                    return false
                end
                local percent = percent / 100
                if self.parent == nil then
                    self.size[index] = 1 - (self.absoluteSizeOffset and self.absoluteSizeOffset[index] or 0)
                else
                    self.size[index] = percent * self.parent.size[index] - (self.absoluteSizeOffset and self.absoluteSizeOffset[index] or 0)
                end
            end
            return true
        end)(str, i % 2 == 1) then
            break
        end
    end
    if self.widthStr ~= nil then
        resolveFunc(self.widthStr, true)
    end
    if self.heightStr ~= nil then
        resolveFunc(self.heightStr, false)
    end
    self:updateAnchorDeltas()
end
function GuiElement:delete()
    local i = #self.elements
    for i = i, 1, -1 do
        self.elements[i].parent = nil
        self.elements[i]:delete()
    end
    table.clear(self.elements)
    if self.parent ~= nil then
        self.parent:removeElement(self)
    end
    FocusManager:removeElement(self)
end
function GuiElement:clone(parent, includeId, suppressOnCreate, blockFocusHandlingReload)
    local ret = self.new()
    if parent ~= nil then
        parent:addElement(ret)
    end
    ret:copyAttributes(self)
    local i = 1
    for i = i, #self.elements do
        local clonedChild = self.elements[i]:clone(ret, includeId, suppressOnCreate, true)
        if includeId then
            clonedChild.id = self.elements[i].id
        end
    end
    if not blockFocusHandlingReload then
        ret:reloadFocusHandling(true)
    end
    if not suppressOnCreate then
        ret:raiseCallback("onCreateCallback", ret, ret.onCreateArgs)
    end
    return ret
end
function GuiElement:copyAttributes(src)
    self.name = src.name
    self.typeName = src.typeName
    self.newLayer = src.newLayer
    self.debugEnabled = src.debugEnabled
    self.visible = src.visible
    self.focused = src.focused
    self.disabled = src.disabled
    self.selected = src.selected
    self.highlighted = src.highlighted
    self.size = table.clone(src.size)
    self.absoluteSizeOffset = src.absoluteSizeOffset and table.clone(src.absoluteSizeOffset) or nil
    self.margin = table.clone(src.margin)
    self.onCreateCallback = src.onCreateCallback
    self.onCreateArgs = src.onCreateArgs
    self.onCloseCallback = src.onCloseCallback
    self.onOpenCallback = src.onOpenCallback
    self.onDrawCallback = src.onDrawCallback
    self.target = src.target
    self.profile = src.profile
    self.fadeInTime = src.fadeInTime
    self.fadeOutTime = src.fadeOutTime
    self.alpha = src.alpha
    self.fadeDirection = src.fadeDirection
    self.updateChildrenState = src.updateChildrenState
    self.toolTipElementId = src.toolTipElementId
    self.toolTipText = src.toolTipText
    self.handleFocus = src.handleFocus
    self.clipping = src.clipping
    self.focusOnHighlight = src.focusOnHighlight
    self.focusFallthrough = src.focusFallthrough
    self.disallowFlowCut = src.disallowFlowCut
    self.ignoreLayout = src.ignoreLayout
    self.soundDisabled = src.soundDisabled
    self.hasFrame = src.hasFrame
    if self.hasFrame then
        self.frameThickness = table.clone(src.frameThickness)
        self.frameColors = src.frameColors ~= nil and table.clone(src.frameColors, math.huge) or nil
        self.frameOverlayVisible = table.clone(src.frameOverlayVisible)
    end
    self.focusId = src.focusId
    self.focusChangeData = table.clone(src.focusChangeData)
    self.isAlwaysFocusedOnOpen = src.isAlwaysFocusedOnOpen
    self.position = table.clone(src.position)
    self.absPosition = table.clone(src.absPosition)
    self.absSize = table.clone(src.absSize)
    self.anchors = table.clone(src.anchors)
    self.anchorDeltas = table.clone(src.anchorDeltas)
    self.pivot = table.clone(src.pivot)
    if src.hotspot ~= nil then
        self.hotspot = table.clone(src.hotspot)
    end
end
function GuiElement:onGuiSetupFinished()
    for _, elem in ipairs(self.elements) do
        elem:onGuiSetupFinished()
    end
    if self.toolTipElementId ~= nil then
        local toolTipElement = self.target:getDescendantById(self.toolTipElementId)
        if toolTipElement ~= nil then
            self.toolTipElement = toolTipElement
            return
        end
        Logging.warning("toolTipElementId \'%s\' not found for \'%s\'!", self.toolTipElementId, self.target.name)
    end
end
function GuiElement:toggleFrameSide(sideIndex, isVisible)
    if self.hasFrame then
        self.frameOverlayVisible[sideIndex] = isVisible
    end
end
function GuiElement:updateFramePosition()
    local x, y = unpack(self.absPosition)
    local width, height = unpack(self.absSize)
    local frameLeft = math.max(width, g_pixelSizeX)
    local frameLeft = math.max(height, g_pixelSizeY)
    if self.frameBounds == nil then
        self.frameBounds = {
            {},
            {},
            {},
            {}
        }
    end
    local frameLeft = GuiElement.FRAME_LEFT
    local frameRight = GuiElement.FRAME_RIGHT
    local frameBottom = GuiElement.FRAME_BOTTOM
    local left = self.frameBounds[frameLeft]
    left.x = x
    left.y = y
    left.width = self.frameThickness[frameLeft]
    left.height = frameLeft
    local top = self.frameBounds[GuiElement.FRAME_TOP]
    top.x = x
    top.y = y + frameLeft - self.frameThickness[frameTop]
    top.width = frameLeft
    top.height = self.frameThickness[frameTop]
    local right = self.frameBounds[frameRight]
    right.x = x + frameLeft - self.frameThickness[frameRight]
    right.y = y
    right.width = self.frameThickness[frameRight]
    right.height = frameLeft
    local bottom = self.frameBounds[frameBottom]
    bottom.x = x
    bottom.y = y
    bottom.width = frameLeft
    bottom.height = self.frameThickness[frameBottom]
    self:cutFrameBordersHorizontal(self.frameBounds[frameLeft], self.frameBounds[frameTop], true)
    self:cutFrameBordersHorizontal(self.frameBounds[frameLeft], self.frameBounds[frameBottom], true)
    self:cutFrameBordersHorizontal(self.frameBounds[frameRight], self.frameBounds[frameTop], false)
    self:cutFrameBordersHorizontal(self.frameBounds[frameRight], self.frameBounds[frameBottom], false)
    self:cutFrameBordersVertical(self.frameBounds[frameBottom], self.frameBounds[frameLeft], true)
    self:cutFrameBordersVertical(self.frameBounds[frameBottom], self.frameBounds[frameRight], true)
    self:cutFrameBordersVertical(self.frameBounds[frameTop], self.frameBounds[frameLeft], false)
    self:cutFrameBordersVertical(self.frameBounds[frameTop], self.frameBounds[frameRight], false)
end
function GuiElement.cutFrameBordersHorizontal(_, verticalPart, horizontalPart, isLeft)
    if verticalPart.width > horizontalPart.height then
        if isLeft then
            horizontalPart.x = horizontalPart.x + verticalPart.width
        end
        horizontalPart.width = horizontalPart.width - verticalPart.width
    end
end
function GuiElement.cutFrameBordersVertical(_, horizontalPart, verticalPart, isBottom)
    if horizontalPart.width >= verticalPart.height then
        if isBottom then
            verticalPart.y = verticalPart.y + horizontalPart.height
        end
        verticalPart.height = verticalPart.height - horizontalPart.height
    end
end
function GuiElement:updateAnchorDeltas(updateChildren)
    local orgMinX, orgMinY, orgMaxX, orgMaxY = self:getParentOriginalBorders()
    local parentWidth = orgMaxX - orgMinX
    local parentHeight = orgMaxY - orgMinY
    local posX = orgMinX + self.pivot[1] * (parentWidth - self.size[1]) + self.position[1]
    local posY = orgMinY + self.pivot[2] * (parentHeight - self.size[2]) + self.position[2]
    self.anchorDeltas[1] = -(orgMinX + parentWidth * self.anchors[1]) + posX
    self.anchorDeltas[2] = -(orgMinY + parentHeight * self.anchors[3]) + posY
    self.anchorDeltas[3] = -(orgMinX + parentWidth * self.anchors[2]) + (posX + self.size[1])
    self.anchorDeltas[4] = -(orgMinY + parentHeight * self.anchors[4]) + (posY + self.size[2])
    if updateChildren then
        local i = 1
        for i = i, #self.elements do
            self.elements[i]:updateAnchorDeltas()
        end
    end
end
function GuiElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    if eventUsed == nil then
        eventUsed = false
    end
    if self.visible then
        local i = #self.elements
        for i = i, 1, -1 do
            local v = self.elements[i]
            if v ~= nil and v:mouseEvent(posX, posY, isDown, isUp, button, eventUsed) then
                eventUsed = true
            end
        end
    end
    return eventUsed
end
function GuiElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
    if eventUsed == nil then
        eventUsed = false
    end
    if self.visible then
        local i = #self.elements
        for i = i, 1, -1 do
            if self.elements[i]:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed) then
                eventUsed = true
            end
        end
    end
    return eventUsed
end
function GuiElement:inputEvent(action, value, eventUsed)
    if eventUsed then
    else
        eventUsed = self.parent
        if eventUsed then
            eventUsed = self.parent:inputEvent(action, value, eventUsed)
        end
        if eventUsed == nil then
            eventUsed = false
        end
    end
    return eventUsed
end
function GuiElement:inputReleaseEvent(action, eventUsed)
    if eventUsed then
    else
        eventUsed = self.parent
        if eventUsed then
            eventUsed = self.parent:inputReleaseEvent(action, eventUsed)
        end
        if eventUsed == nil then
            eventUsed = false
        end
    end
    return eventUsed
end
function GuiElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
    if eventUsed == nil then
        eventUsed = false
    end
    if self.visible then
        local i = #self.elements
        for i = i, 1, -1 do
            if self.elements[i]:keyEvent(unicode, sym, modifier, isDown, eventUsed) then
                eventUsed = true
            end
        end
    end
    return eventUsed
end
function GuiElement:update(dt)
    if self.fadeDirection ~= 0 then
        if self.fadeDirection > 0 then
            self:setAlpha(self.alpha + self.fadeDirection * (dt / self.fadeInTime))
        else
            self:setAlpha(self.alpha + self.fadeDirection * (dt / self.fadeOutTime))
        end
    end
    for _, child in ipairs(self.elements) do
        if child:getIsActiveNonRec() then
            child:update(dt)
        end
    end
end
function GuiElement:draw(clipX1, clipY1, clipX2, clipY2)
    if self.newLayer then
        new2DLayer()
    end
    local xLeft, yTop, xRight, yBottom = self:getClipArea(clipX1, clipY1, clipX2, clipY2)
    self:raiseCallback("onDrawCallback", self)
    if self.debugEnabled or g_uiDebugEnabled then
        if self.hotspot == nil then
            drawFilledRect(self.absPosition[1] - g_pixelSizeX, self.absPosition[2] - g_pixelSizeY, self.absSize[1] + 2 * g_pixelSizeX, g_pixelSizeY, 1, 0, 0, 1)
            drawFilledRect(self.absPosition[1] - g_pixelSizeX, self.absPosition[2] + self.absSize[2], self.absSize[1] + 2 * g_pixelSizeX, g_pixelSizeY, 1, 0, 0, 1)
            drawFilledRect(self.absPosition[1] - g_pixelSizeX, self.absPosition[2], g_pixelSizeX, self.absSize[2], 1, 0, 0, 1)
            drawFilledRect(self.absPosition[1] + self.absSize[1], self.absPosition[2], g_pixelSizeX, self.absSize[2], 1, 0, 0, 1)
        else
            local xLeft = self.absPosition[1] + self.hotspot[1]
            local yTop = self.absPosition[2] + self.hotspot[2] + self.absSize[2]
            local xRight = self.absPosition[1] + self.hotspot[3] + self.absSize[1]
            local yBottom = self.absPosition[2] + self.hotspot[4]
            drawLine2D(xLeft, yBottom, xRight, yBottom, 2 * g_pixelSizeX, 1, 0, 1, 1)
            drawLine2D(xLeft, yTop, xRight, yTop, 2 * g_pixelSizeX, 1, 0, 1, 1)
            drawLine2D(xLeft, yBottom, xLeft, yTop, 2 * g_pixelSizeX, 1, 0, 1, 1)
            drawLine2D(xRight, yBottom, xRight, yTop, 2 * g_pixelSizeX, 1, 0, 1, 1)
        end
    end
    local xRight = 1
    local xLeft = #self.elements
    local yTop = 1
    for xRight = xRight, xLeft, yTop do
        local yBottom = self.elements[xRight]
        if yBottom:getIsVisibleNonRec() then
            yBottom:draw(yBottom:getClipArea(xLeft, yTop, xRight, yBottom))
        end
    end
    if self.hasFrame then
        local xRight = 1
        local xLeft = 4
        local yTop = 1
        for xRight = xRight, xLeft, yTop do
            if self.frameOverlayVisible[xRight] then
                local yBottom = self.frameBounds[xRight]
                local color = self.frameColors ~= nil and self.frameColors[xRight] or GuiElement.FRAME_DEFAULT_COLOR
                drawFilledRect(yBottom.x, yBottom.y, yBottom.width, yBottom.height, color[1], color[2], color[3], color[4], xLeft, yTop, xRight, yBottom)
            end
        end
    end
    if g_uiFocusDebugEnabled and (self.focusId ~= nil and self:canReceiveFocus()) then
        setTextColor(1, 0, 0, 1)
        local yTop = self.absPosition[2] + self.absSize[2]
        renderText(self.absPosition[1], yTop - 0.008, 0.008, " FocusId: " .. tostring(self.focusId) .. " " .. tostring(ClassUtil.getClassNameByObject(self)))
        renderText(self.absPosition[1], yTop - 0.016, 0.008, " T: " .. tostring(self.focusChangeData[FocusManager.TOP]))
        renderText(self.absPosition[1], yTop - 0.024, 0.008, " B: " .. tostring(self.focusChangeData[FocusManager.BOTTOM]))
        renderText(self.absPosition[1], yTop - 0.032, 0.008, " L: " .. tostring(self.focusChangeData[FocusManager.LEFT]))
        renderText(self.absPosition[1], yTop - 0.04, 0.008, " R: " .. tostring(self.focusChangeData[FocusManager.RIGHT]))
        setTextColor(1, 1, 1, 1)
    end
end
function GuiElement:onOpen()
    self:raiseCallback("onOpenCallback", self)
    local i = 1
    for i = i, #self.elements do
        self.elements[i]:onOpen()
    end
end
function GuiElement:onClose()
    self:raiseCallback("onCloseCallback", self)
    local i = 1
    for i = i, #self.elements do
        self.elements[i]:onClose()
    end
end
function GuiElement:shouldFocusChange(direction)
    for _, v in ipairs(self.elements) do
        if not v:shouldFocusChange(direction) then
            return false
        end
    end
    return true
end
function GuiElement:canReceiveFocus()
    return false
end
function GuiElement:onFocusLeave()
    self:setFocused(false, true)
    local i = 1
    for i = i, #self.elements do
        self.elements[i]:onFocusLeave()
    end
    if self.toolTipElement ~= nil and self.toolTipText ~= nil then
        self.toolTipElement:setText("")
    end
end
function GuiElement:onFocusEnter()
    self:setFocused(true, true)
    local i = 1
    for i = i, #self.elements do
        self.elements[i]:onFocusEnter()
    end
    if self.toolTipElement ~= nil and self.toolTipText ~= nil then
        self.toolTipElement:setText(self.toolTipText)
    end
end
function GuiElement:onFocusActivate()
    local i = 1
    for i = i, #self.elements do
        local child = self.elements[i]
        if child.handleFocus then
            child:onFocusActivate()
        end
    end
end
function GuiElement:onHighlight()
    self:setHighlighted(true, true)
    local i = 1
    for i = i, #self.elements do
        self.elements[i]:onHighlight()
    end
    if self.toolTipElement ~= nil and self.toolTipText ~= nil then
        self.toolTipElement:setText(self.toolTipText)
    end
    if self.focusOnHighlight then
        FocusManager:setFocus(self)
    end
end
function GuiElement:onHighlightRemove()
    self:setHighlighted(false, true)
    local i = 1
    for i = i, #self.elements do
        self.elements[i]:onHighlightRemove()
    end
    if self.toolTipElement ~= nil and self.toolTipText ~= nil then
        self.toolTipElement:setText("")
    end
end
function GuiElement:getHandleFocus()
    return self.handleFocus
end
function GuiElement:setHandleFocus(handleFocus)
    self.handleFocus = handleFocus
end
function GuiElement:addElement(element)
    if element.parent ~= nil then
        element.parent:removeElement(element)
    end
    table.insert(self.elements, element)
    element.parent = self
end
function GuiElement:removeElement(element)
    local i = 1
    for i = i, #self.elements do
        if self.elements[i] == element then
            table.remove(self.elements, i)
            element.parent = nil
            return
        end
    end
end
function GuiElement:unlinkElement()
    if self.parent ~= nil then
        self.parent:removeElement(self)
    end
end
function GuiElement:updateAbsolutePosition()
    if #self.anchorDeltas == 0 then
        self:updateAnchorDeltas()
    end
    local minX, minY, maxX, maxY = self:getParentBorders()
    self.absPosition[1] = minX + (maxX - minX) * self.anchors[1] + self.anchorDeltas[1]
    self.absPosition[2] = minY + (maxY - minY) * self.anchors[3] + self.anchorDeltas[2]
    self.absSize[1] = minX + (maxX - minX) * self.anchors[2] + self.anchorDeltas[3] - self.absPosition[1]
    self.absSize[2] = minY + (maxY - minY) * self.anchors[4] + self.anchorDeltas[4] - self.absPosition[2]
    local i = 1
    for i = i, #self.elements do
        self.elements[i]:updateAbsolutePosition()
    end
    if self.hasFrame then
        self:updateFramePosition()
    end
end
function GuiElement:reset()
    local i = 1
    for i = i, #self.elements do
        self.elements[i]:reset()
    end
end
function GuiElement:isChildOf(element)
    if element == self then
        return false
    end
    local p = self.parent
    while p do
        if p == self then
            return false
        end
        if p == element then
            return true
        end
        p = p.parent
    end
    return false
end
function GuiElement:getFocusTarget(_, _)
    return self
end
function GuiElement:setPosition(x, y)
    self.position[1] = x or self.position[1]
    self.position[2] = y or self.position[2]
    self:updateAnchorDeltas()
    self:updateAbsolutePosition()
end
function GuiElement:move(dx, dy)
    self.position[1] = self.position[1] + dx
    self.position[2] = self.position[2] + dy
    self:updateAbsolutePosition()
end
function GuiElement:setAbsolutePosition(x, y)
    local xDif = x or self.absPosition[1]
    local xDif = y or self.absPosition[2]
    local xDif = xDif - self.absPosition[1]
    self.absPosition[1] = xDif
    self.absPosition[2] = xDif
    local i = 1
    for i = i, #self.elements do
        local child = self.elements[i]
        child:setAbsolutePosition(child.absPosition[1] + xDif, child.absPosition[2] + (xDif - self.absPosition[2]))
    end
    if self.hasFrame then
        self:updateFramePosition()
    end
end
function GuiElement:setSize(x, y, updateChildAnchorDeltas)
    x = x or self.size[1]
    y = y or self.size[2]
    if self.thinLineProtection then
        if x ~= 0 then
            x = math.max(x, g_pixelSizeX)
        end
        if y ~= 0 then
            y = math.max(y, g_pixelSizeY)
        end
    end
    self.size[1] = x
    self.size[2] = y
    self:updateAnchorDeltas(updateChildAnchorDeltas)
    self:updateAbsolutePosition()
end
function GuiElement:setVisible(visible)
    self.visible = visible
end
function GuiElement:getIsVisible()
    if self.visible then
        return self.parent == nil and true or self.parent:getIsVisible()
    else
        return false
    end
end
function GuiElement:getIsVisibleNonRec()
    return self.visible and self.alpha > 0
end
function GuiElement:setDisabled(disabled, blockDelegate)
    self.disabled = disabled
    if self.updateChildrenState and not blockDelegate then
        for _, child in pairs(self.elements) do
            child:setDisabled(disabled)
        end
    end
end
function GuiElement:getIsDisabled()
    return self.disabled
end
function GuiElement:setSelected(selected, blockDelegate)
    self.selected = selected
    if self.updateChildrenState and not blockDelegate then
        for _, child in pairs(self.elements) do
            child:setSelected(selected)
        end
    end
end
function GuiElement:getIsSelected()
    return self.selected
end
function GuiElement:setFocused(focused, blockDelegate)
    self.focused = focused
    if self.updateChildrenState and not blockDelegate then
        for _, child in pairs(self.elements) do
            child:setFocused(focused)
        end
    end
end
function GuiElement:getIsFocused()
    return self.focused
end
function GuiElement:setHighlighted(highlighted, blockDelegate)
    self.highlighted = highlighted
    if self.updateChildrenState and not blockDelegate then
        for _, child in pairs(self.elements) do
            child:setHighlighted(highlighted)
        end
    end
end
function GuiElement:getIsHighlighted()
    return self.highlighted
end
function GuiElement:getOverlayState()
    if self:getIsDisabled() then
        return GuiOverlay.STATE_DISABLED
    elseif self:getIsSelected() then
        return GuiOverlay.STATE_SELECTED
    elseif self:getIsFocused() then
        return GuiOverlay.STATE_FOCUSED
    elseif self:getIsHighlighted() then
        return GuiOverlay.STATE_HIGHLIGHTED
    else
        return GuiOverlay.STATE_NORMAL
    end
end
function GuiElement:fadeIn(factor)
    if self.fadeInTime > 0 then
        self.fadeDirection = 1 * Utils.getNoNil(factor, 1)
        self:setAlpha((math.max(self.alpha, 0.0001)))
    else
        self.fadeDirection = 0
        self:setAlpha(1)
    end
end
function GuiElement:fadeOut(factor)
    if self.fadeOutTime > 0 then
        self.fadeDirection = -1 * Utils.getNoNil(factor, 1)
    else
        self.fadeDirection = 0
        self:setAlpha(0)
    end
end
function GuiElement:setAlpha(alpha)
    if alpha ~= self.alpha then
        self.alpha = math.clamp(alpha, 0, 1)
        for _, childElem in pairs(self.elements) do
            childElem:setAlpha(self.alpha)
        end
        if self.alpha == 1 or self.alpha == 0 then
            self.fadeDirection = 0
        end
    end
end
function GuiElement:getIsActive()
    return not self.disabled and self:getIsVisible()
end
function GuiElement:getIsActiveNonRec()
    return not self.disabled and self:getIsVisibleNonRec()
end
function GuiElement:getClipArea(clipX1, clipY1, clipX2, clipY2)
    if self.clipping then
        clipX1 = math.max(clipX1 or 0, self.absPosition[1])
        clipY1 = math.max(clipY1 or 0, self.absPosition[2])
        clipX2 = math.min(clipX2 or 1, self.absPosition[1] + self.absSize[1])
        clipY2 = math.min(clipY2 or 1, self.absPosition[2] + self.absSize[2])
    end
    return clipX1, clipY1, clipX2, clipY2
end
function GuiElement:setSoundSuppressed(doSuppress)
    self.isSoundSuppressed = doSuppress
    for _, child in pairs(self.elements) do
        child:setSoundSuppressed(doSuppress)
    end
end
function GuiElement:getSoundSuppressed()
    return self.isSoundSuppressed
end
function GuiElement:findDescendantsRec(accumulator, rootElement, predicateFunction)
    if rootElement then
        for _, element in ipairs(rootElement.elements) do
            self:findDescendantsRec(accumulator, element, predicateFunction)
            if not predicateFunction or predicateFunction(element) then
                table.insert(accumulator, element)
            end
        end
    end
end
function GuiElement:getDescendants(predicateFunction)
    local descendants = {}
    self:findDescendantsRec(descendants, self, predicateFunction)
    return descendants
end
function GuiElement:setTarget(target, originalTarget, callOnCreate)
    local i = 1
    for i = i, #self.elements do
        self.elements[i]:setTarget(target, originalTarget, callOnCreate)
    end
    if self.target == originalTarget then
        self.target = target
        if callOnCreate then
            self:raiseCallback("onCreateCallback", self, self.onCreateArgs)
        end
    end
end
function GuiElement:getFirstDescendant(predicateFunction)
    local element = nil
    local res = self:getDescendants(predicateFunction)
    if #res > 0 then
        element = res[1]
    end
    return element
end
function GuiElement:getDescendantById(id)
    local element = nil
    if id then
        element = self:getFirstDescendant(function(e)
            -- upvalues: (copy) id
            return e.id and e.id == id
        end)
    end
    return element
end
function GuiElement:getDescendantByName(name)
    local element = nil
    if name then
        element = self:getFirstDescendant(function(e)
            -- upvalues: (copy) name
            return e.name and e.name == name
        end)
    end
    return element
end
function GuiElement:setAnchor(x, y)
    return self:setAnchors(x, x, y, y)
end
function GuiElement:setAnchors(minX, maxX, minY, maxY)
    self.anchors[1] = minX or self.anchors[1]
    self.anchors[2] = maxX or self.anchors[2]
    self.anchors[3] = minY or self.anchors[3]
    self.anchors[4] = maxY or self.anchors[4]
    self:updateAnchorDeltas()
end
function GuiElement:setPivot(x, y)
    self.pivot[1] = x
    self.pivot[2] = y
    self:updateAnchorDeltas()
end
function GuiElement:fixThinLines()
    if self.thinLineProtection then
        if self.size[1] ~= 0 then
            self.size[1] = math.max(self.size[1], g_pixelSizeX)
        end
        if self.size[2] ~= 0 then
            self.size[2] = math.max(self.size[2], g_pixelSizeY)
        end
        self:updateAbsolutePosition()
    end
end
function GuiElement:getParentBorders()
    if self.parent == nil then
        return 0, 0, 1, 1
    else
        return self.parent:getBorders()
    end
end
function GuiElement:getBorders()
    return self.absPosition[1], self.absPosition[2], self.absPosition[1] + self.absSize[1], self.absPosition[2] + self.absSize[2]
end
function GuiElement:getParentOriginalBorders()
    if self.parent == nil then
        return 0, 0, 1, 1
    else
        return self.parent:getOriginalBorders()
    end
end
function GuiElement:getOriginalBorders()
    return self.position[1], self.position[2], self.position[1] + self.size[1], self.position[2] + self.size[2]
end
function GuiElement:getCenter()
    return self.absPosition[1] + self.absSize[1] * 0.5, self.absPosition[2] + self.absSize[2] * 0.5
end
function GuiElement:getAspectScale()
    return g_aspectScaleX, g_aspectScaleY
end
function GuiElement:addCallback(xmlFile, key, funcName)
    local callbackName = getXMLString(xmlFile, key)
    if callbackName ~= nil then
        if self.target ~= nil then
            self[funcName] = self.target[callbackName]
            return
        end
        self[funcName] = ClassUtil.getFunction(callbackName)
    end
end
function GuiElement:setCallback(funcName, callbackName)
    if self.target == nil then
        self[funcName] = ClassUtil.getFunction(callbackName)
    else
        self[funcName] = self.target[callbackName]
    end
end
function GuiElement:raiseCallback(name, ...)
    if self[name] == nil then
        return nil
    elseif self.target == nil then
        return self[name](...)
    else
        return self[name](self.target, ...)
    end
end
function GuiElement.extractIndexAndNameFromID(elementId)
    local len = elementId:len()
    local index = nil
    if len >= 4 and elementId:sub(len, len) == "]" then
        local startI = elementId:find("[", 1, true)
        if startI ~= nil and (startI > 1 and startI < len - 1) then
            index = tonumber(elementId:sub(startI + 1, len - 1))
            if index ~= nil then
                elementId = elementId:sub(1, startI - 1)
            end
        end
    end
    return index, elementId
end
function GuiElement:setId(xmlFile, key)
    local id = getXMLString(xmlFile, key .. "#id")
    if id ~= nil then
        local valid = true
        local _, varName = GuiElement.extractIndexAndNameFromID(id)
        if varName:find("[^%w_]") ~= nil then
            printError("Error: Invalid gui element id " .. id)
            valid = false
        end
        if valid then
            self.id = id
        end
    end
end
function GuiElement:include(guiMixinType)
    guiMixinType.new():addTo(self)
end
function GuiElement:verifyConfiguration() end
function GuiElement.reloadFocusHandling(e, reloadIds)
    if reloadIds then
        local function trash(e)
            -- upvalues: (copy) trash
            e.focusId = nil
            local i = 1
            for i = i, #e.elements do
                trash(e.elements[i])
            end
        end
        e.focusId = nil
        local i = 1
        for i = i, #e.elements do
            trash(e.elements[i])
        end
    end
    FocusManager:loadElementFromCustomValues(e)
end
local function findFirstFocusableSearch(element, checkReceiveFocus)
    -- upvalues: (copy) findFirstFocusableSearch
    if not element.focusFallthrough and (element:getIsVisibleNonRec() and (not checkReceiveFocus or element:canReceiveFocus())) then
        return element
    end
    local i = 1
    for i = i, #element.elements do
        if element.elements[i]:getIsVisibleNonRec() then
            local result = findFirstFocusableSearch(element.elements[i], checkReceiveFocus)
            if result ~= nil then
                return result
            end
        end
    end
    return nil
end
function GuiElement:findFirstFocusable(checkReceiveFocus)
    -- upvalues: (copy) findFirstFocusableSearch
    local element = findFirstFocusableSearch(self, checkReceiveFocus)
    if element == nil then
        element = self
    end
    return element
end
local function findLastFocusableSearch(element, checkReceiveFocus)
    -- upvalues: (copy) findLastFocusableSearch
    if not element.focusFallthrough and (element:getIsVisibleNonRec() and (not checkReceiveFocus or element:canReceiveFocus())) then
        return element
    end
    local i = #element.elements
    for i = i, 1, -1 do
        if element.elements[i]:getIsVisibleNonRec() then
            local result = findLastFocusableSearch(element.elements[i], checkReceiveFocus)
            if result ~= nil then
                return result
            end
        end
    end
    return nil
end
function GuiElement:findLastFocusable(checkReceiveFocus)
    -- upvalues: (copy) findLastFocusableSearch
    local element = findLastFocusableSearch(self, checkReceiveFocus)
    if element == nil then
        element = self
    end
    return element
end
function GuiElement:toString()
    return string.format("[ID: %s, FocusID: %s, GuiProfile: %s, Position: %g, %g]", tostring(self.id), tostring(self.focusId), tostring(self.profile), self.absPosition[1], self.absPosition[2])
end