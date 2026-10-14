GuiOverlay = {}
GuiOverlay.STATE_NORMAL = 1
GuiOverlay.STATE_DISABLED = 2
GuiOverlay.STATE_FOCUSED = 3
GuiOverlay.STATE_PRESSED = 4
GuiOverlay.STATE_SELECTED = 5
GuiOverlay.STATE_HIGHLIGHTED = 6
GuiOverlay.OVERLAY_STATE_SUFFIXES = {
    [GuiOverlay.STATE_NORMAL] = "",
    [GuiOverlay.STATE_DISABLED] = "Disabled",
    [GuiOverlay.STATE_FOCUSED] = "Focused",
    [GuiOverlay.STATE_PRESSED] = "Pressed",
    [GuiOverlay.STATE_SELECTED] = "Selected",
    [GuiOverlay.STATE_HIGHLIGHTED] = "Highlighted"
}
function GuiOverlay.loadOverlay(_, overlay, overlayName, imageSize, profile, xmlFile, key)
    if overlay.uvs == nil then
        overlay.uvs = Overlay.DEFAULT_UVS
    end
    if overlay.color == nil then
        overlay.color = {
            1,
            1,
            1,
            1
        }
    end
    if xmlFile == nil then
        if profile ~= nil then
            GuiOverlay.loadProfileFilenames(profile, overlay, overlayName)
            GuiOverlay.loadProfileUVs(profile, overlay, overlayName, imageSize)
            GuiOverlay.loadProfileColors(profile, overlay, overlayName)
            overlay.sdfWidth = profile:getNumber(overlayName .. "SdfWidth", overlay.sdfWidth)
        end
    else
        GuiOverlay.loadXMLFilenames(xmlFile, key, overlay, overlayName)
        GuiOverlay.loadXMLUVs(xmlFile, key, overlay, overlayName, imageSize)
        GuiOverlay.loadXMLColors(xmlFile, key, overlay, overlayName)
        overlay.sdfWidth = getXMLInt(xmlFile, key .. "#" .. overlayName .. "SdfWidth") or overlay.sdfWidth
    end
    if overlay.filename == nil then
        return nil
    end
    if overlay.previewFilename == nil then
        overlay.previewFilename = "dataS/menu/black.png"
    end
    return overlay
end
function GuiOverlay.loadXMLUVs(xmlFile, key, overlay, overlayName, imageSize)
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local uvs = getXMLString(xmlFile, key .. "#" .. overlayName .. stateName .. "UVs")
        local sliceId = getXMLString(xmlFile, key .. "#" .. overlayName .. stateName .. "SliceId")
        if sliceId == nil or sliceId == "noSlice" then
            if uvs ~= nil then
                overlay["uvs" .. stateName] = GuiUtils.getUVs(uvs, imageSize, overlay["uvs" .. stateName], getXMLInt(xmlFile, key .. "#" .. overlayName .. stateName .. "UVRotation"))
            end
        else
            local slice = g_overlayManager:getSliceInfoById(sliceId)
            if slice ~= nil then
                overlay["uvs" .. stateName] = table.clone(slice.uvs)
                overlay["filename" .. stateName] = slice.filename
                overlay["sliceId" .. stateName] = sliceId
                local rotation = getXMLInt(xmlFile, key .. "#" .. overlayName .. stateName .. "UVRotation")
                if rotation ~= nil then
                    GuiUtils.rotateUVs(overlay["uvs" .. stateName], rotation)
                end
                if getXMLBool(xmlFile, key .. "#" .. overlayName .. stateName .. "InvertX") then
                    GuiUtils.invertUVs(overlay["uvs" .. stateName], true)
                end
            end
        end
    end
end
function GuiOverlay.loadProfileUVs(profile, overlay, overlayName, imageSize)
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local uvs = profile:getValue(overlayName .. stateName .. "UVs")
        local sliceId = profile:getValue(overlayName .. stateName .. "SliceId")
        if sliceId == nil or sliceId == "noSlice" then
            if uvs ~= nil then
                overlay["uvs" .. stateName] = GuiUtils.getUVs(uvs, imageSize, overlay["uvs" .. stateName], profile:getNumber(overlayName .. "UVRotation"))
                if profile.filename == g_baseUIFilename then
                    Logging.warning("Profile %s does not use new slice format", profile.name)
                end
            end
        else
            local slice = g_overlayManager:getSliceInfoById(sliceId)
            if slice ~= nil then
                overlay["uvs" .. stateName] = table.clone(slice.uvs)
                overlay["filename" .. stateName] = slice.filename
                overlay["sliceId" .. stateName] = sliceId
                local rotation = profile:getNumber(overlayName .. stateName .. "UVRotation")
                if rotation ~= nil then
                    GuiUtils.rotateUVs(overlay["uvs" .. stateName], rotation)
                end
                if profile:getBool(overlayName .. stateName .. "InvertX") == true then
                    GuiUtils.invertUVs(overlay["uvs" .. stateName], true)
                end
                if profile:getBool(overlayName .. stateName .. "InvertY") == true then
                    GuiUtils.invertUVs(overlay["uvs" .. stateName], false)
                end
            end
        end
    end
end
function GuiOverlay.loadXMLColors(xmlFile, key, overlay, overlayName)
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        overlay["color" .. stateName] = GuiUtils.getColorGradientArray(getXMLString(xmlFile, key .. "#" .. overlayName .. stateName .. "Color")) or overlay["color" .. stateName]
    end
    local rotation = getXMLFloat(xmlFile, key .. "#" .. overlayName .. "Rotation")
    if rotation ~= nil then
        overlay.rotation = math.rad(rotation)
    end
    overlay.isWebOverlay = getXMLBool(xmlFile, key .. "#" .. overlayName .. "IsWebOverlay") or overlay.isWebOverlay
end
function GuiOverlay.loadProfileColors(profile, overlay, overlayName)
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        overlay["color" .. stateName] = GuiUtils.getColorGradientArray(profile:getValue(overlayName .. stateName .. "Color")) or overlay["color" .. stateName]
    end
    local rotation = profile:getNumber(overlayName .. "Rotation")
    if rotation ~= nil then
        overlay.rotation = math.rad(rotation)
    end
    overlay.isWebOverlay = profile:getBool(overlayName .. "IsWebOverlay") or overlay.isWebOverlay
end
function GuiOverlay.loadXMLFilenames(xmlFile, key, overlay, overlayName)
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local filename = getXMLString(xmlFile, key .. "#" .. (overlayName .. "Filename") .. stateName)
        if filename ~= nil then
            overlay["filename" .. stateName] = GuiOverlay.resolveFilename(filename)
        end
    end
    for stateName, filename in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local filename = getXMLString(xmlFile, key .. "#" .. (overlayName .. "PreviewFilename") .. filename)
        if filename ~= nil then
            overlay["previewFilename" .. filename] = GuiOverlay.resolveFilename(filename)
        end
    end
    for filename, filename in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local filename = getXMLString(xmlFile, key .. "#" .. (overlayName .. "MaskFilename") .. filename)
        if filename ~= nil then
            overlay["maskFilename" .. filename] = GuiOverlay.resolveFilename(filename)
        end
    end
end
function GuiOverlay.loadProfileFilenames(profile, overlay, overlayName)
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local filename = profile:getValue((overlayName .. "Filename") .. stateName)
        if filename ~= nil then
            overlay["filename" .. stateName] = GuiOverlay.resolveFilename(filename)
        end
    end
    for stateName, filename in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local filename = profile:getValue((overlayName .. "PreviewFilename") .. filename)
        if filename ~= nil then
            overlay["previewFilename" .. filename] = GuiOverlay.resolveFilename(filename)
        end
    end
    for filename, filename in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local filename = profile:getValue((overlayName .. "MaskFilename") .. filename)
        if filename ~= nil then
            overlay["maskFilename" .. filename] = GuiOverlay.resolveFilename(filename)
        end
    end
end
function GuiOverlay.resolveFilename(filename)
    if filename == "g_baseUIFilename" then
        filename = g_baseUIFilename
    elseif filename == "g_baseHUDFilename" then
        filename = g_baseHUDFilename
    elseif filename == "g_iconsUIFilename" then
        filename = g_iconsUIFilename
    end
    if filename ~= nil then
        filename = string.gsub(filename, "$l10nSuffix", g_languageSuffix)
    end
    return filename
end
function GuiOverlay.createOverlay(overlay, filename)
    if overlay.overlay ~= nil and (overlay.filename == filename or filename == nil) then
        return overlay
    end
    GuiOverlay.deleteOverlay(overlay)
    if filename ~= nil then
        overlay.filename = filename
    end
    if overlay.filename ~= nil then
        local imageOverlay
        if overlay.isWebOverlay == nil or (not overlay.isWebOverlay or overlay.isWebOverlay and not overlay.filename:startsWith("http")) then
            imageOverlay = createImageOverlay(overlay.filename)
        else
            imageOverlay = createWebImageOverlay(overlay.filename, overlay.previewFilename)
        end
        if imageOverlay ~= 0 then
            overlay.overlay = imageOverlay
            GuiOverlay.createStateOverlays(overlay)
            if overlay.sdfWidth ~= nil then
                setOverlaySignedDistanceFieldWidth(imageOverlay, overlay.sdfWidth)
            end
        end
    end
    overlay.rotation = overlay.rotation or 0
    overlay.alpha = overlay.alpha or 1
    return overlay
end
function GuiOverlay.createStateOverlays(overlay)
    for state, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local imageOverlay = nil
        local overlayMask = nil
        if state ~= GuiOverlay.STATE_NORMAL then
            if overlay["filename" .. stateName] ~= nil then
                if overlay.isWebOverlay and (overlay.filename:startsWith("http") and overlay["previewFilename" .. stateName] ~= nil) then
                    imageOverlay = createWebImageOverlay(overlay["filename" .. stateName], overlay["previewFilename" .. stateName])
                else
                    imageOverlay = createImageOverlay(overlay["filename" .. stateName])
                end
            end
            if imageOverlay ~= 0 then
                overlay["overlay" .. stateName] = imageOverlay
            end
        end
        if overlay["maskFilename" .. stateName] ~= nil then
            overlayMask = createOverlayTextureFromFile(overlay["maskFilename" .. stateName])
        end
        if overlayMask ~= nil and overlayMask ~= 0 then
            overlay["overlayMask" .. stateName] = overlayMask
        end
    end
end
function GuiOverlay.copyOverlay(overlay, overlaySrc, overrideFilename)
    overlay.alpha = overlaySrc.alpha
    overlay.isWebOverlay = overlaySrc.isWebOverlay
    overlay.sdfWidth = overlaySrc.sdfWidth
    for state, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        overlay["filename" .. stateName] = overlaySrc["filename" .. stateName]
        overlay["maskFilename" .. stateName] = overlaySrc["maskFilename" .. stateName]
        overlay["previewFilename" .. stateName] = overlaySrc["previewFilename" .. stateName]
        overlay["rotation" .. stateName] = overlaySrc["rotation" .. stateName]
        overlay["uvs" .. stateName] = overlaySrc["uvs" .. stateName] and table.clone(overlaySrc["uvs" .. stateName])
        overlay["color" .. stateName] = overlaySrc["color" .. stateName] and table.copyIndex(overlaySrc["color" .. stateName])
    end
    overlay.sliceId = overlaySrc.sliceId
    overlay.filename = overrideFilename or overlay.filename
    return GuiOverlay.createOverlay(overlay)
end
function GuiOverlay.deleteOverlay(overlay)
    if overlay ~= nil then
        for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
            if overlay["overlay" .. stateName] ~= nil then
                delete(overlay["overlay" .. stateName])
                overlay["overlay" .. stateName] = nil
            end
            if overlay["overlayMask" .. stateName] ~= nil then
                delete(overlay["overlayMask" .. stateName])
                overlay["overlayMask" .. stateName] = nil
            end
        end
    end
end
function GuiOverlay.getOverlayColor(overlay, state)
    local color = overlay.color
    if state == GuiOverlay.STATE_DISABLED then
        color = overlay.colorDisabled
    elseif state == GuiOverlay.STATE_FOCUSED then
        color = overlay.colorFocused
    elseif state == GuiOverlay.STATE_SELECTED then
        color = overlay.colorSelected
    elseif state == GuiOverlay.STATE_HIGHLIGHTED then
        color = overlay.colorHighlighted
    elseif state == GuiOverlay.STATE_PRESSED then
        color = overlay.colorPressed
        if color == nil then
            color = overlay.colorFocused
        end
    end
    if color == nil then
        color = overlay.color
    end
    return color
end
function GuiOverlay.getOverlayUVs(overlay, state)
    local uvs = overlay.uvs
    if state == GuiOverlay.STATE_DISABLED then
        uvs = overlay.uvsDisabled
    elseif state == GuiOverlay.STATE_PRESSED then
        uvs = overlay.uvsPressed
    elseif state == GuiOverlay.STATE_FOCUSED then
        uvs = overlay.uvsFocused
    elseif state == GuiOverlay.STATE_SELECTED then
        uvs = overlay.uvsSelected
    elseif state == GuiOverlay.STATE_HIGHLIGHTED then
        uvs = overlay.uvsHighlighted
    end
    if uvs == nil then
        uvs = overlay.uvs
    end
    return uvs
end
function GuiOverlay.getOverlay(overlay, currentState)
    local currentOverlay = overlay.overlay
    for state, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        if currentState == state then
            currentOverlay = overlay["overlay" .. stateName]
            if state == GuiOverlay.STATE_PRESSED and currentOverlay == nil then
                currentOverlay = overlay["overlay" .. GuiOverlay.OVERLAY_STATE_SUFFIXES[GuiOverlay.STATE_FOCUSED]]
            end
            break
        end
    end
    if currentOverlay == nil then
        currentOverlay = overlay.overlay
    end
    return currentOverlay
end
function GuiOverlay.getMaskOverlay(overlay, currentState)
    local currentOverlay = nil
    for state, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        if currentState == state then
            currentOverlay = overlay["overlayMask" .. stateName]
            if state == GuiOverlay.STATE_PRESSED and currentOverlay == nil then
                currentOverlay = overlay["overlayMask" .. GuiOverlay.OVERLAY_STATE_SUFFIXES[GuiOverlay.STATE_FOCUSED]]
            end
            break
        end
    end
    if currentOverlay == nil then
        currentOverlay = overlay.overlayMask
    end
    return currentOverlay
end
function GuiOverlay.renderOverlay(overlay, posX, posY, sizeX, sizeY, state, clipX1, clipY1, clipX2, clipY2, maskPosX, maskPosY, maskSizeX, maskSizeY)
    local currentOverlay = GuiOverlay.getOverlay(overlay, state)
    if currentOverlay ~= nil then
        local colors = GuiOverlay.getOverlayColor(overlay, state)
        if colors[4] ~= 0 or colors[8] ~= nil and (colors[8] ~= 0 or (colors[12] ~= 0 or colors[16] ~= 0)) then
            if not overlay.hasCustomRotation then
                local pivotX = sizeX / 2
                local pivotY = sizeY / 2
                if overlay.customPivot ~= nil then
                    pivotX = overlay.customPivot[1]
                    pivotY = overlay.customPivot[2]
                end
                setOverlayRotation(currentOverlay, overlay.rotation, pivotX, pivotY)
            end
            local pivotY = GuiOverlay.getOverlayUVs
            local pivotX, pivotY, u2, v2, u3, v3, u4, v4 = unpack(pivotY(overlay, state))
            local u2, pivotY, pivotX, ou1, ou1, ou1, ou1, v3, v2
            if clipX1 == nil then
                ou1 = posX
                ou1 = sizeY
                ou1 = sizeX
                ou1 = posY
            else
                ou1 = math.max(posX, clipX1)
                ou1 = math.max(posY, clipY1)
                local ov1 = math.min(posX + sizeX, clipX2) - ou1
                ou1 = math.max(ov1, 0)
                local ov1 = math.min(posY + sizeY, clipY2) - ou1
                ou1 = math.max(ov1, 0)
                if ou1 == 0 or ou1 == 0 then
                    return
                end
                local p1 = (ou1 - posX) / (sizeX + posX - posX)
                local p2 = (ou1 - posY) / (sizeY + posY - posY)
                local p3 = (ou1 + ou1 - posX) / (oldX2 - posX)
                local p4 = (ou1 + ou1 - posY) / (oldY2 - posY)
                pivotX = (u3 - pivotX) * p1 + pivotX
                pivotY = (v2 - pivotY) * p2 + pivotY
                u2 = (u3 - pivotX) * p1 + pivotX
                v2 = (v4 - v3) * p4 + v3
                u3 = (u3 - pivotX) * p3 + pivotX
                v3 = (v2 - pivotY) * p2 + pivotY
                v4 = (v4 - v3) * p4 + v3
            end
            setOverlayUVs(currentOverlay, pivotX, pivotY, u2, v2, u3, v3, u4, v4)
            local posX2 = GuiOverlay.getMaskOverlay(overlay, state)
            if posX2 ~= nil then
                if maskPosX ~= nil then
                    posX = posX + maskPosX or posX
                end
                if maskPosY ~= nil then
                    posY = posY + maskPosY or posY
                end
                if posX ~= nil and maskSizeX then
                    sizeX = maskSizeX
                end
                if posY ~= nil and maskSizeY then
                    sizeY = maskSizeY
                end
                set2DMaskFromTexture(posX2, true, posX, posY, sizeX, sizeY)
            end
            if colors[5] == nil then
                local posY2, ou1, ov1, ou2 = unpack(colors)
                setOverlayColor(currentOverlay, posY2, ou1, ov1, ou2 * overlay.alpha)
            else
                setOverlayCornerColor(currentOverlay, 0, colors[1], colors[2], colors[3], colors[4] * overlay.alpha)
                setOverlayCornerColor(currentOverlay, 1, colors[5], colors[6], colors[7], colors[8] * overlay.alpha)
                setOverlayCornerColor(currentOverlay, 2, colors[9], colors[10], colors[11], colors[12] * overlay.alpha)
                setOverlayCornerColor(currentOverlay, 3, colors[13], colors[14], colors[15], colors[16] * overlay.alpha)
            end
            renderOverlay(currentOverlay, ou1, ou1, ou1, ou1)
            if posX2 ~= nil then
                set2DMaskFromTexture(0, true, 0, 0, 0, 0)
            end
        end
    end
end
function GuiOverlay.copyColors(overlay, source)
    overlay.color = source.color
    overlay.colorDisabled = source.colorDisabled
    overlay.colorFocused = source.colorFocused
    overlay.colorSelected = source.colorSelected
    overlay.colorHighlighted = source.colorHighlighted
    overlay.colorPressed = source.colorPressed
end
function GuiOverlay.setRotation(overlay, rotation, centerX, centerY)
    if overlay.overlay ~= nil then
        setOverlayRotation(overlay.overlay, rotation, centerX, centerY)
        overlay.hasCustomRotation = true
    end
end
function GuiOverlay.setColor(overlay, r, g, b, a)
    overlay.color = {
        r,
        g,
        b,
        a
    }
end
function GuiOverlay.setSelectedColor(overlay, r, g, b, a)
    overlay.colorSelected = {
        r,
        g,
        b,
        a
    }
end