GuiUtils = {}
function GuiUtils.getNormalizedValues(data, refSize, defaultValue)
    if data == nil then
        return defaultValue
    end
    local isString = type(data) == "string"
    if isString then
        data = data:split(" ")
    end
    local values = {}
    for k, part in pairs(data) do
        local s
        if isString then
            local isPixelValue = false
            local isDisplayPixelValue = false
            local part
            if string.find(part, "px") == nil then
                if string.find(part, "dp") ~= nil then
                    isDisplayPixelValue = true
                    part = string.gsub(part, "dp", "")
                end
            else
                isPixelValue = true
                part = string.gsub(part, "px", "")
            end
            s = tonumber(part)
            if isDisplayPixelValue then
                if (k + 1) % 2 == 0 then
                end
            elseif isPixelValue then
            end
        else
            s = part / refSize[(k + 1) % 2 + 1]
        end
        table.insert(values, s)
    end
    if defaultValue ~= nil and #defaultValue > #data then
        local k = #data + 1
        for k = k, #defaultValue do
            table.insert(values, values[(k - 1) % #data + 1])
        end
    end
    return values
end
function GuiUtils.getNormalizedTextSize(str, refSize, defaultValue)
    if str ~= nil then
        local isPixelValue = false
        local isDisplayPixelValue = false
        if string.find(str, "px") == nil then
            if string.find(str, "dp") ~= nil then
                isDisplayPixelValue = true
                str = string.gsub(str, "dp", "")
            end
        else
            isPixelValue = true
            str = string.gsub(str, "px", "")
        end
        local value = tonumber(str)
        if value == nil then
            printCallstack()
        end
        if isPixelValue then
            return value / (refSize or g_screenHeight)
        end
        if isDisplayPixelValue then
            return value * g_pixelSizeY
        end
    end
    return defaultValue
end
function GuiUtils.getNormalizedValue(str, isXValue, default)
    if str == nil then
        return default
    end
    local isString = type(str) == "string"
    local isPixelSize = false
    local isDisplayPixel = false
    local screenSizeValue
    if isString then
        if string.find(str, "px") == nil then
            if string.find(str, "dp") ~= nil then
                str = string.gsub(str, "dp", "")
                isDisplayPixel = true
            end
        else
            str = string.gsub(str, "px", "")
            isPixelSize = true
        end
        screenSizeValue = tonumber(str)
        if screenSizeValue == nil then
            Logging.warning("GuiUtils.getNormalizedValue: String %q could not be converted to a number", str)
            return default
        end
    else
        screenSizeValue = str
    end
    local screenSizeValue = 1
    local scalingValue = 1
    if isPixelSize then
        screenSizeValue = isXValue and g_referenceScreenWidth or g_referenceScreenHeight
        scalingValue = isXValue and g_aspectScaleX or g_aspectScaleY
    elseif isDisplayPixel then
        screenSizeValue = isXValue and g_screenWidth or g_screenHeight
    end
    return screenSizeValue / screenSizeValue * scalingValue
end
function GuiUtils.getNormalizedScreenValues(values, default)
    if values == nil then
        return default
    end
    local normValues = {}
    local isString = type(values) == "string"
    if isString then
        values = string.split(values, " ")
    end
    local i = 1
    for i = i, #values do
        local defaultVal
        if default == nil then
            defaultVal = default
        else
            defaultVal = default[i] or default
        end
        normValues[i] = GuiUtils.getNormalizedValue(values[i], i % 2 == 1, defaultVal, true)
    end
    return normValues
end
function GuiUtils.getNormalizedXValue(x, default)
    return GuiUtils.getNormalizedValue(x, true, default)
end
function GuiUtils.getNormalizedYValue(y, default)
    return GuiUtils.getNormalizedValue(y, false, default)
end
function GuiUtils.getColorArray(colorStr, defaultValue)
    return string.getVector(colorStr, 4) or defaultValue
end
function GuiUtils.getColorGradientArray(colorStr, defaultValue)
    local data = string.getVector(colorStr)
    if data == nil or #data ~= 4 and #data ~= 16 then
        return defaultValue
    else
        return data
    end
end
function GuiUtils.validateUvs(str)
    local parts = string.split(str, " ")
    if #parts ~= 2 and #parts ~= 4 then
        return false, "Needs to be 2- or 4-vector"
    end
    for _, part in ipairs(parts) do
        local number = tonumber(part)
        if number == nil then
            if not (string.endsWith(part, "px") or string.endsWith(part, "dp")) then
                return false, "Invalid format"
            end
            local number = tonumber((string.sub(part, 1, #part - 2)))
            if number == nil then
                return false, "Missing or invalid number value for \'px\' or \'dp\' entry"
            end
            if number ~= math.floor(number) then
                return false, "px and dp values need to be integers"
            end
        elseif number < 0 or number > 1 then
            return false, "Normalized value (without \'px\' or \'dp\') needs to be between 0 and 1"
        end
    end
    return true
end
function GuiUtils.getUVs(str, ref, defaultValue, rotation)
    if str ~= nil then
        local uvs = GuiUtils.getNormalizedValues(str, ref or { 1024, 1024 })
        if uvs[1] ~= nil then
            local result = {
                uvs[1],
                1 - uvs[2] - uvs[4],
                uvs[1],
                1 - uvs[2],
                uvs[1] + uvs[3],
                1 - uvs[2] - uvs[4],
                uvs[1] + uvs[3],
                1 - uvs[2]
            }
            if rotation ~= nil then
                GuiUtils.rotateUVs(result, rotation)
            end
            return result
        end
        Logging.devError("GuiUtils.getUVs() Unable to get uvs for \'%s\'", str)
    end
    return defaultValue
end
function GuiUtils.checkOverlayOverlap(posX, posY, overlayX, overlayY, overlaySizeX, overlaySizeY, hotspot)
    if hotspot == nil or #hotspot ~= 4 then
        return overlaySizeX > 0 and overlaySizeY > 0 and overlayX <= posX and posX <= overlayX + overlaySizeX and overlayY <= posY and posY <= overlayY + overlaySizeY
    else
        return overlaySizeX > 0 and overlaySizeY > 0 and overlayX + hotspot[1] <= posX and posX <= overlayX + overlaySizeX + hotspot[3] and overlayY + hotspot[4] <= posY and posY <= overlayY + overlaySizeY + hotspot[2]
    end
end
function GuiUtils.rotateUVs(uvs, direction)
    local u1, v1, u2, v2, u3, v3, u4, v4 = unpack(uvs)
    if direction == 90 then
        uvs[1] = u3
        uvs[2] = v3
        uvs[3] = u1
        uvs[4] = v1
        uvs[5] = u4
        uvs[6] = v4
        uvs[7] = u2
        uvs[8] = v2
        return
    elseif direction == -90 then
        uvs[1] = u2
        uvs[2] = v2
        uvs[3] = u4
        uvs[4] = v4
        uvs[5] = u1
        uvs[6] = v1
        uvs[7] = u3
        uvs[8] = v3
        return
    elseif direction == 180 then
        uvs[1] = u4
        uvs[2] = v4
        uvs[3] = u3
        uvs[4] = v3
        uvs[5] = u2
        uvs[6] = v2
        uvs[7] = u1
        uvs[8] = v1
    elseif direction ~= 0 then
        Logging.warning("Wrong rotation parameter")
        printCallstack()
    end
end
function GuiUtils.invertUVs(uvs, isXDirection)
    local u1, v1, u2, v2, u3, v3, u4, v4 = unpack(uvs)
    if isXDirection then
        uvs[1] = u3
        uvs[3] = u4
        uvs[5] = u1
        uvs[7] = u2
    else
        uvs[2] = v2
        uvs[4] = v1
        uvs[6] = v4
        uvs[8] = v3
    end
end
function GuiUtils.alignToScreenPixels(x, y)
    return math.round(x / g_pixelSizeX) * g_pixelSizeX, math.round(y / g_pixelSizeY) * g_pixelSizeY
end
function GuiUtils.alignValueToScreenPixels(value, isXValue)
    if isXValue then
        return math.round(value / g_pixelSizeX) * g_pixelSizeX
    else
        return math.round(value / g_pixelSizeY) * g_pixelSizeY
    end
end
function GuiUtils.hsvToRGB(hue, saturation, value)
    saturation = saturation or 1
    value = value or 1
    local kr = (5 + hue * 6) % 6
    local kg = (3 + hue * 6) % 6
    local kb = (1 + hue * 6) % 6
    local r = value - value * saturation * math.max(math.min(kr, 4 - kr, 1), 0)
    local g = value - value * saturation * math.max(math.min(kg, 4 - kg, 1), 0)
    return r, g, value - value * saturation * math.max(math.min(kb, 4 - kb, 1), 0)
end
function GuiUtils.rgbToHSV(r, g, b)
    local min = math.min(r, g, b)
    local max = math.max(r, g, b)
    local chroma = max - min
    if chroma == 0 then
        return 0, 0, max
    end
    local saturation = chroma / max
    local hue = nil
    if max == min then
        return nil, saturation, max
    end
    if max == r then
        hue = ((max - b) / chroma - (max - g) / chroma) % 6
    elseif max == g then
        hue = (max - r) / chroma - bNew + 2
    elseif max == b then
        hue = gNew - rNew + 4
    end
    return hue / 6, saturation, max
end
function GuiUtils.linearSRGBToHSV(r, g, b)
    local hue = math.pow(r, 0.45454545454545453)
    local hue = math.pow(g, 0.45454545454545453)
    local hue = math.pow(b, 0.45454545454545453)
    local hue, saturation, value = GuiUtils.rgbToHSV(hue, hue, hue)
    return hue * 360, saturation * 100, value * 100
end