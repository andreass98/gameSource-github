source("dataS/scripts/gui/hud/ingameMap/IngameMapLayoutMobile.lua")
source("dataS/scripts/gui/hud/ingameMap/IngameMapLayoutFullscreenMobile.lua")
IngameMapMobile = {}
local IngameMapMobile_mt = Class(IngameMapMobile, IngameMap)
IngameMapMobile.STATE_HIDDEN = 3
function IngameMapMobile.new(hud, hudAtlasPath, controlHudAtlasPath, inputDisplayManager, customMt)
    -- upvalues: (copy) IngameMapMobile_mt
    local self = IngameMap:superClass().new(nil, nil, customMt or IngameMapMobile_mt)
    IngameMapMobile.POSITION.SELF[2] = g_screenHeight * IngameMapMobile.HEIGHT_FACTOR
    self.overlay = self:createBackground(hudAtlasPath)
    self.hud = hud
    self.hudAtlasPath = hudAtlasPath
    self.controlHudAtlasPath = controlHudAtlasPath
    self.inputDisplayManager = inputDisplayManager
    self.uiScale = 1
    self.isVisible = true
    self.mobileLayout = IngameMapLayoutMobile.new()
    self.layouts = { self.mobileLayout }
    self.fullScreenLayout = IngameMapLayoutFullscreenMobile.new()
    self.state = 1
    self.layout = self.layouts[self.state]
    self.mapOverlay = Overlay.new(nil, 0, 0, 1, 1)
    self.mapElement = HUDElement.new(self.mapOverlay)
    self:createComponents(hudAtlasPath)
    for _, layout in ipairs(self.layouts) do
        layout:createComponents(self, hudAtlasPath)
    end
    self.filter = {}
    self.filter[MapHotspot.CATEGORY_FIELD] = true
    self.filter[MapHotspot.CATEGORY_ANIMAL] = true
    self.filter[MapHotspot.CATEGORY_MISSION] = true
    self.filter[MapHotspot.CATEGORY_TOUR] = true
    self.filter[MapHotspot.CATEGORY_STEERABLE] = true
    self.filter[MapHotspot.CATEGORY_COMBINE] = true
    self.filter[MapHotspot.CATEGORY_TRAILER] = true
    self.filter[MapHotspot.CATEGORY_TOOL] = true
    self.filter[MapHotspot.CATEGORY_UNLOADING] = true
    self.filter[MapHotspot.CATEGORY_LOADING] = true
    self.filter[MapHotspot.CATEGORY_PRODUCTION] = true
    self.filter[MapHotspot.CATEGORY_SHOP] = true
    self.filter[MapHotspot.CATEGORY_OTHER] = true
    self.filter[MapHotspot.CATEGORY_AI] = true
    self.filter[MapHotspot.CATEGORY_PLAYER] = true
    self.currentFilter = self.filter
    self:setWorldSize(2048, 2048)
    self.hotspots = {}
    self.selectedHotspot = nil
    self.allowToggle = true
    self.topDownCamera = nil
    self.isMapVisible = false
    self.toggleSizeAfterDialog = false
    self.mapExtensionOffsetX = 0
    self.mapExtensionOffsetZ = 0
    self.mapExtensionScaleFactor = 1
    self.isDrawing = false
    g_messageCenter:subscribe(MessageType.INSETS_CHANGED, self.updateInsets, self)
    return self
end
function IngameMapMobile:delete()
    g_messageCenter:unsubscribe(MessageType.INSETS_CHANGED, self)
    IngameMapMobile:superClass().delete(self)
end
function IngameMapMobile:loadMap(filename, worldSizeX, worldSizeZ, _, _)
    self.mapElement:delete()
    self:setWorldSize(worldSizeX, worldSizeZ)
    self.mapOverlay = Overlay.new(filename, 0, 0, 1, 1)
    self.mapElement = HUDElement.new(self.mapOverlay)
    self:addChild(self.mapElement)
    self:setScale(self.uiScale)
end
function IngameMapMobile:createComponents(hudAtlasPath)
    local baseX, baseY = self:getPosition()
    self:createFrame(hudAtlasPath, baseX, baseY, self:getWidth(), (self:getHeight()))
    self.buttonUVs = GuiUtils.getUVs(IngameMapMobile.UV.BUTTON)
    self.buttonUVsDisabled = GuiUtils.getUVs(IngameMapMobile.UV.BUTTON_DISABLED)
    self.buttonExtensionUVs = GuiUtils.getUVs(IngameMapMobile.UV.BUTTON_EXTENSION)
    self.buttonExtensionUVsDisabled = GuiUtils.getUVs(IngameMapMobile.UV.BUTTON_EXTENSION_DISABLED)
    self.buttonElement = self:createOverlayElement(IngameMapMobile.POSITION.BUTTON, IngameMapMobile.SIZE.BUTTON, IngameMapMobile.UV.BUTTON, IngameMapMobile.COLOR.MAP_ICON)
    self:addChild(self.buttonElement)
    local posX, posY = self.buttonElement:getPosition()
    local sizeX, sizeY = getNormalizedScreenValues(unpack(IngameMapMobile.SIZE.BUTTON_EXTENSION))
    Overlay.new(self.hudAtlasPath, posX - sizeX, posY, sizeX, sizeY):setUVs(GuiUtils.getUVs(IngameMapMobile.UV.BUTTON_EXTENSION))
    self.buttonExtensionElement = HUDElement.new(overlay)
    self:addChild(self.buttonExtensionElement)
    self.buttonIconElement = self:createOverlayElement(IngameMapMobile.POSITION.BUTTON_ICON, IngameMapMobile.SIZE.BUTTON_ICON, IngameMapMobile.UV.ARROW_RIGHT, IngameMapMobile.COLOR.MAP_ICON, true)
    self:addChild(self.buttonIconElement)
    self.rightBorderElement = self:createOverlayElement(IngameMapMobile.POSITION.RIGHT_BORDER, IngameMapMobile.SIZE.RIGHT_BORDER, HUDElement.UV.FILL, IngameMapMobile.COLOR.RIGHT_BORDER)
    self:addChild(self.rightBorderElement)
    self.toggleButton = self.hud:addTouchButton(self.buttonElement.overlay, 1, 0.4, self.onClickToggleButton, self, TouchHandler.TRIGGER_UP)
    g_touchHandler:setAreaPressedSizeGain(self.toggleButton, 3.5)
    local offsetX, offsetY = getNormalizedScreenValues(unpack(IngameMapMobile.POSITION.INPUT_GLYPH_OFFSET))
    local circlePosX, circlePosY = self.buttonElement:getPosition()
    self.glyphElement = InputGlyphMobileElement.new(g_inputDisplayManager)
    self.glyphElement:setAction(InputAction.TOGGLE_MAP_SIZE)
    self.glyphElement:setButtonGlyphColor(HUDButtonElement.COLOR.INPUT_GLYPH)
    self.glyphElement:setPosition(circlePosX + offsetX, circlePosY + offsetY)
    self.buttonIconElement:addChild(self.glyphElement)
end
function IngameMapMobile:getHeight()
    return self.overlay.height
end
function IngameMapMobile:setPlayer(player)
    self.player = player
end
function IngameMapMobile:onClickToggleButton(_, _)
    if self.isActive then
        self:toggleSize(not self.isMapVisible)
    end
end
function IngameMapMobile:createOverlayElement(pos, size, uvs, color, isIcon)
    local baseX, baseY = self:getPosition()
    local posX, posY = getNormalizedScreenValues(unpack(pos))
    local sizeX, sizeY = getNormalizedScreenValues(unpack(size))
    local overlay
    if isIcon then
        overlay = Overlay.new(self.controlHudAtlasPath, baseX + posX, baseY + posY, sizeX, sizeY)
    else
        overlay = Overlay.new(self.hudAtlasPath, baseX + posX, baseY + posY, sizeX, sizeY)
    end
    overlay:setUVs(GuiUtils.getUVs(uvs))
    overlay:setColor(unpack(color))
    return HUDElement.new(overlay)
end
function IngameMapMobile:storeScaledValues(uiScale)
    IngameMapMobile:superClass().storeScaledValues(self, uiScale)
    self.mapWidth, self.mapHeight = self:scalePixelToScreenVector(IngameMapMobile.SIZE.MAP)
    self.mapSizeX, self.mapSizeY = self:scalePixelToScreenVector(IngameMapMobile.SIZE.MAP)
    self.mapOffsetX, self.mapOffsetY = self:scalePixelToScreenVector(IngameMapMobile.POSITION.MAP)
    self.mapHideWidth = self:scalePixelToScreenVector(IngameMapMobile.SIZE.MAP_HIDE_WIDTH)
    self.mapToFrameDiffX = self:scalePixelToScreenWidth(IngameMapMobile.SIZE.SELF[1] - IngameMapMobile.SIZE.MAP[1])
    self.mapToFrameDiffY = self:scalePixelToScreenHeight(IngameMapMobile.SIZE.SELF[2] - IngameMapMobile.SIZE.MAP[2])
end
function IngameMapMobile:resetSettings()
    IngameMapMobile:superClass().resetSettings(self)
    if self.overlay ~= nil then
        if not self.isMapVisible then
            self:setPosition(self.mapHideWidth, nil)
        end
    end
end
function IngameMapMobile:updateButton()
    self.isActive = not g_gui:getIsGuiVisible() and true
    if self.isActive ~= self.isActive then
        self.glyphElement:setVisible(self.isActive)
        if self.isActive then
            self.buttonElement:setUVs(self.buttonUVs)
            self.buttonExtensionElement:setUVs(self.buttonExtensionUVs)
            return
        end
        self.buttonElement:setUVs(self.buttonUVsDisabled)
        self.buttonExtensionElement:setUVs(self.buttonExtensionUVsDisabled)
    end
end
function IngameMapMobile:update(dt)
    IngameMapMobile:superClass().update(self, dt)
    if g_gui:getIsDialogVisible() and (self.isMapVisible and not g_inGameMenu.showMap) then
        self:toggleSize(false)
    end
    self:updateButton()
end
function IngameMapMobile:draw()
    if self.isMapVisible then
        IngameMapMobile:superClass().draw(self)
    end
    if self.overlay.visible then
        if self.isMapVisible then
            self.mapFrameElement:draw()
            self.rightBorderElement:draw()
        else
            self.buttonExtensionElement:draw()
        end
        self.buttonElement:draw()
        self.buttonIconElement:draw()
        self.glyphElement:draw()
    end
end
function IngameMapMobile:toggleSize(state, force)
    if g_sleepManager:getIsSleeping() then
        return
    elseif self.isActive then
        IngameMapMobile:superClass().toggleSize(self, 1, force)
        if state == nil then
            state = not self.isMapVisible
        end
        self.isMapVisible = state
        self:setPosition(state and 0 or self.mapHideWidth, nil)
    end
end
function IngameMapMobile:toggleDrawing()
    self.isDrawing = not self.isDrawing
end
function IngameMapMobile:setPosition(x, y)
    local leftInset, _, _, _ = getSafeFrameInsets()
    x = x + leftInset
    IngameMapMobile:superClass().setPosition(self, x, y)
    self.mobileLayout:setOffset(x or 0)
end
function IngameMapMobile:setScale(uiScale)
    IngameMapMobile:superClass().setScale(self, uiScale, uiScale)
    local posX, posY = self:getBackgroundPosition(uiScale)
    self:setPosition(posX, posY)
end
function IngameMapMobile:updateInsets()
    self:setScale(self.uiScale)
end
function IngameMapMobile:getBackgroundPosition(scale)
    local widthOffset = getNormalizedScreenValues
    local widthOffset, _ = widthOffset(unpack(IngameMapMobile.SIZE.MAP_HIDE_WIDTH))
    if self.isMapVisible then
    end
    local _, height = getNormalizedScreenValues(unpack(IngameMapMobile.SIZE.SELF))
    local x, y = GuiUtils.alignToScreenPixels(widthOffset * scale, IngameMapMobile.HEIGHT_FACTOR - height * 0.5 * scale)
    return x, y
end
function IngameMapMobile:createBackground()
    local width, height = getNormalizedScreenValues(unpack(IngameMapMobile.SIZE.SELF))
    local posX, posY = self:getBackgroundPosition(1)
    return Overlay.new(nil, posX, posY, width, height)
end
function IngameMapMobile:createFrame(hudAtlasPath, baseX, baseY, width, height)
    local frame = HUDFrameElement.new(hudAtlasPath, baseX, baseY, width, height, nil, false, IngameMapMobile.FRAME_THICKNESS)
    frame:setFrameColor(unpack(IngameMapMobile.COLOR.FRAME))
    self.mapFrameElement = frame
    self:addChild(frame)
end
function IngameMapMobile:drawPlayersCoordinates() end
IngameMapMobile.MIN_MAP_WIDTH = 464
IngameMapMobile.MIN_MAP_HEIGHT = 470
IngameMapMobile.FRAME_THICKNESS = 2
IngameMapMobile.HEIGHT_FACTOR = 0.55
IngameMapMobile.SIZE = {
    ["MAP"] = { IngameMapMobile.MIN_MAP_WIDTH, IngameMapMobile.MIN_MAP_HEIGHT },
    ["SELF"] = { IngameMapMobile.MIN_MAP_WIDTH + IngameMapMobile.FRAME_THICKNESS * 2, IngameMapMobile.MIN_MAP_HEIGHT + IngameMapMobile.FRAME_THICKNESS },
    ["RIGHT_BORDER"] = { IngameMapMobile.FRAME_THICKNESS, IngameMapMobile.MIN_MAP_HEIGHT + IngameMapMobile.FRAME_THICKNESS },
    ["BUTTON"] = { 86, 106 },
    ["BUTTON_EXTENSION"] = { 150, 106 },
    ["BUTTON_ICON"] = { 96, 96 },
    ["MAP_HIDE_WIDTH"] = { -IngameMapMobile.MIN_MAP_WIDTH - IngameMapMobile.FRAME_THICKNESS * 2 - 4, 0 }
}
IngameMapMobile.POSITION = {
    ["INPUT_GLYPH_OFFSET"] = { 103, 81 },
    ["SELF"] = { 0, 540 },
    ["MAP"] = { IngameMapMobile.FRAME_THICKNESS, IngameMapMobile.FRAME_THICKNESS },
    ["RIGHT_BORDER"] = { IngameMapMobile.FRAME_THICKNESS + IngameMapMobile.MIN_MAP_WIDTH, 0 },
    ["BUTTON"] = { IngameMapMobile.SIZE.RIGHT_BORDER[1] + IngameMapMobile.MIN_MAP_WIDTH, IngameMapMobile.MIN_MAP_HEIGHT / 2 - IngameMapMobile.SIZE.BUTTON[2] / 2 },
    ["BUTTON_ICON"] = { IngameMapMobile.SIZE.RIGHT_BORDER[1] + IngameMapMobile.MIN_MAP_WIDTH - 5, IngameMapMobile.MIN_MAP_HEIGHT / 2 - IngameMapMobile.SIZE.BUTTON_ICON[2] / 2 }
}
IngameMapMobile.UV = {
    ["BUTTON"] = {
        152,
        908,
        86,
        106
    },
    ["BUTTON_EXTENSION"] = {
        160,
        908,
        10,
        106
    },
    ["BUTTON_DISABLED"] = {
        364,
        908,
        86,
        106
    },
    ["BUTTON_EXTENSION_DISABLED"] = {
        372,
        908,
        10,
        106
    },
    ["BUTTON_ICON"] = {
        504,
        96,
        48,
        96
    },
    ["ARROW_RIGHT"] = {
        96,
        96,
        -96,
        96
    }
}
IngameMapMobile.COLOR = {
    ["RIGHT_BORDER"] = {
        0.098039,
        0.098039,
        0.098039,
        1
    },
    ["MAP_ICON"] = {
        1,
        1,
        1,
        1
    },
    ["FRAME"] = {
        0.098039,
        0.098039,
        0.098039,
        1
    }
}