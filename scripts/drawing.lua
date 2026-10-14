local overlays = {}
local loadedOverlays = false
local PIXEL = 1
local TOUCH_LEFT = 2
local TOUCH_MIDDLE = 3
local TOUCH_RIGHT = 4
local ROUND_CORNER_TOP_LEFT = 5
local ROUND_CORNER_TOP_RIGHT = 6
local ROUND_CORNER_BOTTOM_LEFT = 7
local ROUND_CORNER_BOTTOM_RIGHT = 8
local PIXEL_X_SIZE = nil
local PIXEL_Y_SIZE = nil
local TOUCH_HEIGHT = nil
local TOUCH_SIDE_WIDTH = nil
function onProfileUiResolutionScalingChanged()
    -- upvalues: (ref) PIXEL_X_SIZE, (ref) PIXEL_Y_SIZE, (ref) TOUCH_SIDE_WIDTH, (ref) TOUCH_HEIGHT
    local resScale = 1
    PIXEL_X_SIZE = 1 / (resScale * g_screenWidth)
    PIXEL_Y_SIZE = 1 / (resScale * g_screenHeight)
    TOUCH_SIDE_WIDTH, TOUCH_HEIGHT = getNormalizedScreenValues(53, 103)
    CORNER_WIDTH, CORNER_HEIGHT = getNormalizedScreenValues(20, 20)
end
local function loadOverlays()
    -- upvalues: (copy) overlays, (ref) loadedOverlays, (copy) PIXEL, (copy) TOUCH_LEFT, (copy) TOUCH_RIGHT, (copy) TOUCH_MIDDLE, (copy) ROUND_CORNER_TOP_LEFT, (copy) ROUND_CORNER_TOP_RIGHT, (copy) ROUND_CORNER_BOTTOM_LEFT, (copy) ROUND_CORNER_BOTTOM_RIGHT
    overlays[1] = createImageOverlay("dataS/menu/base/graph_pixel.png")
    if Platform.isMobile then
        overlays[2] = Overlay.new(g_baseUIFilename, 0, 0, 0, 0)
        overlays[2]:setUVs(GuiUtils.getUVs({
            229,
            388,
            53,
            103
        }))
        overlays[4] = Overlay.new(g_baseUIFilename, 0, 0, 0, 0)
        overlays[4]:setUVs(GuiUtils.getUVs({
            282,
            388,
            -53,
            103
        }))
        overlays[3] = Overlay.new(g_baseUIFilename, 0, 0, 0, 0)
        overlays[3]:setUVs(GuiUtils.getUVs({
            284,
            388,
            1,
            103
        }))
    end
    overlays[5] = Overlay.new("dataS/menu/base/roundCorner.png", 0, 0, 0, 0)
    overlays[5]:setUVs(GuiUtils.getUVs({
        7,
        7,
        20,
        20
    }, { 64, 64 }))
    overlays[6] = Overlay.new("dataS/menu/base/roundCorner.png", 0, 0, 0, 0)
    overlays[6]:setUVs(GuiUtils.getUVs({
        37,
        7,
        20,
        20
    }, { 64, 64 }))
    overlays[7] = Overlay.new("dataS/menu/base/roundCorner.png", 0, 0, 0, 0)
    overlays[7]:setUVs(GuiUtils.getUVs({
        7,
        37,
        20,
        20
    }, { 64, 64 }))
    overlays[8] = Overlay.new("dataS/menu/base/roundCorner.png", 0, 0, 0, 0)
    overlays[8]:setUVs(GuiUtils.getUVs({
        37,
        37,
        20,
        20
    }, { 64, 64 }))
    onProfileUiResolutionScalingChanged()
    loadedOverlays = true
end
function deleteDrawingOverlays()
    -- upvalues: (copy) overlays, (ref) loadedOverlays
    for _, overlay in pairs(overlays) do
        if type(overlay) == "table" then
            overlay:delete()
        else
            delete(overlay)
        end
    end
    loadedOverlays = false
end
function drawFilledRect(x, y, width, height, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
    -- upvalues: (ref) loadedOverlays, (copy) loadOverlays, (copy) overlays, (ref) PIXEL_X_SIZE, (ref) PIXEL_Y_SIZE, (copy) PIXEL
    if not loadedOverlays then
        loadOverlays()
    end
    if width ~= 0 and height ~= 0 then
        local posX2, posY2 = GuiUtils.alignToScreenPixels(x, y)
        local posX2, posY2 = GuiUtils.alignToScreenPixels(width, height)
        local posX2 = math.max(posX2, PIXEL_X_SIZE)
        local posX2 = math.max(posY2, PIXEL_Y_SIZE)
        if clipX1 ~= nil then
            posX2 = math.max(posX2, clipX1)
            posY2 = math.max(posY2 + (posX2 + posX2), clipY1)
            posX2 = math.max(math.min(posX2, clipX2) - posX2, 0)
            posX2 = math.max(math.min(posY2, clipY2) - posY2, 0)
            if posX2 == 0 or posX2 == 0 then
                return
            end
        end
        setOverlayColor(overlays[1], r, g, b, a)
        renderOverlay(overlay, posX2, posY2, posX2, posX2)
    end
end
function drawOutlineRect(x, y, width, height, lineWidth, lineHeight, r, g, b, a)
    -- upvalues: (ref) loadedOverlays, (copy) loadOverlays, (copy) overlays, (copy) PIXEL
    if not loadedOverlays then
        loadOverlays()
    end
    local overlay = overlays[1]
    setOverlayColor(overlay, r, g, b, a)
    renderOverlay(overlay, x, y, width, lineHeight)
    renderOverlay(overlay, x, y, lineWidth, height)
    renderOverlay(overlay, x + width - lineWidth, y, lineWidth, height)
    renderOverlay(overlay, x, y + height - lineHeight, width, lineHeight)
end
function drawPoint(x, y, width, height, r, g, b, a)
    -- upvalues: (ref) loadedOverlays, (copy) loadOverlays, (copy) overlays, (copy) PIXEL
    if not loadedOverlays then
        loadOverlays()
    end
    local overlay = overlays[1]
    setOverlayColor(overlay, r, g, b, a)
    renderOverlay(overlay, x - width / 2, y - height / 2, width, height)
end
function drawTouchButton(x, y, width, isPressed, _, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
    -- upvalues: (ref) loadedOverlays, (copy) loadOverlays, (ref) PIXEL_X_SIZE, (ref) TOUCH_HEIGHT, (copy) overlays, (ref) TOUCH_SIDE_WIDTH, (copy) TOUCH_LEFT, (copy) TOUCH_MIDDLE, (copy) TOUCH_RIGHT
    if not loadedOverlays then
        loadOverlays()
    end
    local overlayRight = x / PIXEL_X_SIZE
    x = math.floor(overlayRight) * PIXEL_X_SIZE
    local overlayRight = width / PIXEL_X_SIZE
    width = math.floor(overlayRight) * PIXEL_X_SIZE
    y = y - TOUCH_HEIGHT * 0.5
    if isPressed then
        r = math.min(1, r * 0.8)
        g = math.min(1, g * 0.8)
        b = math.min(1, b * 0.8)
    end
    local x = overlays[2]
    x:setPosition(x, y)
    x:setDimension(TOUCH_SIDE_WIDTH, TOUCH_HEIGHT)
    x:setColor(r, g, b, a)
    x:render(clipX1, clipY1, clipX2, clipY2)
    local overlayMiddle = overlays[3]
    overlayMiddle:setPosition(x + TOUCH_SIDE_WIDTH, y)
    overlayMiddle:setDimension(width - 2 * TOUCH_SIDE_WIDTH, TOUCH_HEIGHT)
    overlayMiddle:setColor(r, g, b, a)
    overlayMiddle:render(clipX1, clipY1, clipX2, clipY2)
    local overlayRight = overlays[4]
    overlayRight:setPosition(x + width - TOUCH_SIDE_WIDTH, y)
    overlayRight:setDimension(TOUCH_SIDE_WIDTH, TOUCH_HEIGHT)
    overlayRight:setColor(r, g, b, a)
    overlayRight:render(clipX1, clipY1, clipX2, clipY2)
end
function drawLine2D(startX, startY, endX, endY, thickness, r, g, b, a)
    -- upvalues: (ref) loadedOverlays, (copy) loadOverlays, (copy) overlays, (copy) PIXEL
    if not loadedOverlays then
        loadOverlays()
    end
    local deltaX = endX - startX
    local deltaY = (endY - startY) / g_screenAspectRatio
    local angle = deltaX * deltaX + deltaY * deltaY
    local length = math.sqrt(angle)
    if length ~= 0 then
        local angle = math.acos(deltaX / length)
        if deltaY < 0 then
        end
        setOverlayColor(overlays[1], r, g, b, a)
        setOverlayRotation(overlay, angle, 0, 0)
        renderOverlay(overlay, startX, startY, length, thickness)
        setOverlayRotation(overlay, 0, 0, 0)
    end
end
function drawOutlineCircle2D(x, y, radius, thickness, numSegments, r, g, b, a)
    drawPoint(x, y, 4 * g_pixelSizeX, 4 * g_pixelSizeY, 0, 0, 1, 1)
    local startX = x + radius
    local i = 1
    local startY = y
    for i = i, numSegments do
        local endX = x + radius * math.cos(6.283185307179586 / numSegments * i)
        local endY = y + radius * g_screenAspectRatio * math.sin(angle * i)
        drawLine2D(startX, startY, endX, endY, thickness, r, g, b, a)
    end
end
function drawFilledRectRound(x, y, width, height, scale, r, g, b, a, clipX1, clipY1, clipX2, clipY2, skipScreenPixelAlign)
    -- upvalues: (ref) loadedOverlays, (copy) loadOverlays, (copy) overlays, (copy) ROUND_CORNER_TOP_LEFT, (copy) ROUND_CORNER_TOP_RIGHT, (copy) ROUND_CORNER_BOTTOM_LEFT, (copy) ROUND_CORNER_BOTTOM_RIGHT
    if not loadedOverlays then
        loadOverlays()
    end
    if width ~= 0 and height ~= 0 then
        local cornerWidth = CORNER_WIDTH * scale
        local cornerHeight = CORNER_HEIGHT * scale
        if not skipScreenPixelAlign then
            cornerWidth, cornerHeight = GuiUtils.alignToScreenPixels(CORNER_WIDTH * scale, CORNER_HEIGHT * scale)
            x, y = GuiUtils.alignToScreenPixels(x, y)
            width, height = GuiUtils.alignToScreenPixels(width, height)
        end
        local cornerTopLeft = math.max(width, cornerWidth * 2)
        local cornerTopLeft = math.max(height, cornerHeight * 2)
        drawFilledRect(x, y + cornerHeight, cornerWidth, cornerTopLeft - 2 * cornerHeight, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
        drawFilledRect(x + cornerWidth, y, cornerTopLeft - 2 * cornerWidth, cornerTopLeft, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
        drawFilledRect(x + cornerTopLeft - cornerWidth, y + cornerHeight, cornerWidth, cornerTopLeft - 2 * cornerHeight, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
        local cornerTopLeft = overlays[5]
        cornerTopLeft:setPosition(x, y + cornerTopLeft - cornerHeight)
        cornerTopLeft:setDimension(cornerWidth, cornerHeight)
        cornerTopLeft:setColor(r, g, b, a)
        cornerTopLeft:render(clipX1, clipY1, clipX2, clipY2)
        local cornerTopRight = overlays[6]
        cornerTopRight:setPosition(x + cornerTopLeft - cornerWidth, y + cornerTopLeft - cornerHeight)
        cornerTopRight:setDimension(cornerWidth, cornerHeight)
        cornerTopRight:setColor(r, g, b, a)
        cornerTopRight:render(clipX1, clipY1, clipX2, clipY2)
        overlays[7]:setPosition(x, y)
        cornerBottomLeft:setDimension(cornerWidth, cornerHeight)
        cornerBottomLeft:setColor(r, g, b, a)
        cornerBottomLeft:render(clipX1, clipY1, clipX2, clipY2)
        local cornerBottomRight = overlays[8]
        cornerBottomRight:setPosition(x + cornerTopLeft - cornerWidth, y)
        cornerBottomRight:setDimension(cornerWidth, cornerHeight)
        cornerBottomRight:setColor(r, g, b, a)
        cornerBottomRight:render(clipX1, clipY1, clipX2, clipY2)
    end
end
function drawDashedLine(x, y, width, height, dashLength, gapLength, r, g, b, a, isHorizontal)
    local startPos = 0
    if not isHorizontal then
        while math.abs(startPos) < height do
            if dashLength <= 0 then
                ::l11::
                endPos = math.max(startPos + dashLength, -height)
                goto l12
            end
            local endPos = math.min(startPos + dashLength, height)
            if not endPos then
                goto l11
            end
            ::l12::
            drawLine2D(x, y + startPos, x, y + endPos, width * g_screenAspectRatio, r, g, b, a)
            startPos = endPos + gapLength
        end
        goto l4
    end
    while true do
        if math.abs(startPos) >= width then
            ::l4::
            return
        end
        if dashLength <= 0 then
            break
        end
        endPos = math.min(startPos + dashLength, width)
        if not endPos then
            break
        end
        ::l7::
        drawLine2D(x + startPos, y, x + endPos, y, height, r, g, b, a)
        startPos = endPos + gapLength
    end
    local endPos = math.max(startPos + dashLength, -width)
    goto l7
end