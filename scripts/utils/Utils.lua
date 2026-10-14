Utils = {}
function Utils.getNoNil(value, setTo)
    if value == nil then
        return setTo
    else
        return value
    end
end
function Utils.getNoNilRad(valueDeg, defaultRad)
    if valueDeg == nil then
        return defaultRad
    else
        return math.rad(valueDeg)
    end
end
function Utils.limitTextToWidth(text, textSize, width, trimFront, trimReplaceText)
    local replaceTextWidth = getTextWidth(textSize, trimReplaceText)
    local indexOfFirstCharacter = 1
    local indexOfLastCharacter = utf8Strlen(text)
    if width >= 0 then
        local totalWidth = getTextWidth(textSize, text)
        if width < totalWidth then
            if trimFront then
                indexOfFirstCharacter = getTextLineLength(textSize, text, totalWidth - width + replaceTextWidth)
                text = trimReplaceText .. utf8Substr(text, indexOfFirstCharacter)
            else
                indexOfLastCharacter = getTextLineLength(textSize, text, width - replaceTextWidth)
                text = utf8Substr(text, 0, indexOfLastCharacter) .. trimReplaceText
            end
        end
    end
    return text, indexOfFirstCharacter, indexOfLastCharacter
end
function Utils.getMovedLimitedValue(curVal, maxVal, minVal, speed, dt, inverted)
    local limitF = math.min
    local limitF2 = math.max
    if inverted then
    end
    if maxVal < minVal then
        limitF = math.max
        limitF2 = math.min
    elseif maxVal == minVal then
        return minVal
    end
    return limitF2(limitF(curVal + (maxVal - minVal) / speed * dt, maxVal), minVal)
end
function Utils.getMovedLimitedValues(currentValues, maxValues, minValues, numValues, speed, dt, inverted)
    local ret = table.create(numValues)
    local i = 1
    for i = i, numValues do
        ret[i] = Utils.getMovedLimitedValue(currentValues[i], maxValues[i], minValues[i], speed, dt, inverted)
    end
    return ret
end
function Utils.setMovedLimitedValues(values, maxValues, minValues, numValues, speed, dt, inverted)
    local changed = false
    local i = 1
    for i = i, numValues do
        local newValue = Utils.getMovedLimitedValue(values[i], maxValues[i], minValues[i], speed, dt, inverted)
        if newValue ~= values[i] then
            changed = true
            values[i] = newValue
        end
    end
    return changed
end
function Utils.removeModDirectory(filename)
    local isMod = false
    if filename == nil then
        printCallstack()
    end
    local filenameLower = string.lower(filename)
    if g_modsDirectory then
        local modsDirLen = g_modsDirectory:len()
        if string.lower(g_modsDirectory) == filenameLower:sub(1, modsDirLen) then
            filename = filename:sub(modsDirLen + 1)
            isMod = true
        end
        if not (isMod or string.isNilOrWhitespace(g_internalModsDirectory)) then
            local internalModsDirLen = g_internalModsDirectory:len()
            if filenameLower:sub(1, internalModsDirLen) == string.lower(g_internalModsDirectory) then
                filename = filename:sub(internalModsDirLen + 1)
                isMod = true
            end
        end
    end
    if not isMod and g_dlcsDirectories ~= nil then
        for i, dlcDirectory in ipairs(g_dlcsDirectories) do
            local dlcsDir = string.lower(dlcDirectory.path)
            local dlcsDirLen = dlcsDir:len()
            if filenameLower:sub(1, dlcsDirLen) == dlcsDir then
                return filename:sub(dlcsDirLen + 1), isMod, true, i
            end
        end
    end
    return filename, isMod, false, 0
end
function Utils.getUniqueId(value, mappingTable, prefix, md5Length)
    if type(md5Length) ~= "number" or (md5Length <= 0 or md5Length >= 32) then
        md5Length = nil
    end
    prefix = prefix or ""
    local i = 0
    while true do
        local md5 = getMD5
        local md5 = md5(tostring(value) .. tostring(getTime()) .. tostring(i))
        local uniqueId
        if md5Length == nil then
            uniqueId = prefix .. md5
        else
            uniqueId = prefix .. string.sub(md5, 1, md5Length)
        end
        i = i + 1
        if mappingTable == nil or mappingTable[uniqueId] == nil then
            return uniqueId
        end
    end
end
function Utils.getModNameAndBaseDirectory(filename)
    local modName = nil
    local baseDirectory = ""
    local modFilename, isMod, isDlc, dlcsDirectoryIndex = Utils.removeModDirectory(filename)
    if isMod or isDlc then
        local f, l = modFilename:find("/")
        if f ~= nil and (l ~= nil and f > 1) then
            modName = modFilename:sub(1, f - 1)
            if isDlc then
                if g_dlcModNameHasPrefix[modName] then
                    return g_uniqueDlcNamePrefix .. modName, g_dlcsDirectories[dlcsDirectoryIndex].path .. modName .. "/"
                end
            else
                baseDirectory = g_modNameToDirectory[modName] or g_modsDirectory .. modName .. "/"
            end
        end
    end
    return modName, baseDirectory
end
function Utils.getVersatileRotation(repr, componentNode, dt, posX, posY, posZ, currentAngle, minAngle, maxAngle)
    local vx, vy, vz = getVelocityAtLocalPos(componentNode, posX, posY, posZ)
    local x, _, z = worldDirectionToLocal(getParent(repr), vx, vy, vz)
    local length = MathUtil.vector2Length(x, z)
    local steeringAngle
    if length > 0.15 then
        steeringAngle = math.atan2(x / length, z / length)
        if steeringAngle < -1.5707963267948966 then
        end
    else
        steeringAngle = currentAngle
    end
    if minAngle == nil or (minAngle == 0 or (maxAngle == nil or maxAngle == 0)) then
        minAngle = steeringAngle
    elseif maxAngle < steeringAngle then
        minAngle = maxAngle
    elseif steeringAngle >= minAngle then
        minAngle = steeringAngle
    end
    local steeringAngle = MathUtil.normalizeRotationForShortestPath(minAngle, currentAngle)
    if currentAngle < steeringAngle then
        return math.min(currentAngle + 0.003 * dt, steeringAngle)
    else
        return math.max(currentAngle - 0.003 * dt, steeringAngle)
    end
end
function Utils.getYRotationBetweenNodes(node1, node2, offset1, offset2, wrapRotation)
    local dirX1 = 0
    local dirZ1 = 1
    local dirX2 = 0
    local dirZ2 = 1
    if offset1 ~= nil and offset1 ~= 0 then
        dirX1, dirZ1 = MathUtil.getDirectionFromYRotation(offset1)
    end
    if offset2 ~= nil and offset2 ~= 0 then
        dirX2, dirZ2 = MathUtil.getDirectionFromYRotation(offset2)
    end
    local wDirX1, _, wDirZ1 = localDirectionToWorld(node1, dirX1, 0, dirZ1)
    local wDirX2, _, wDirZ2 = localDirectionToWorld(node2, dirX2, 0, dirZ2)
    local dir, angle, wDirZ1 = worldDirectionToLocal(node1, wDirX1, 0, wDirZ1)
    local dir, angle, wDirZ2 = worldDirectionToLocal(node1, wDirX2, 0, wDirZ2)
    local dir = 1
    if dir - dir > 0 then
    end
    local angle = MathUtil.getVectorAngleDifference(dir, 0, wDirZ1, dir, 0, wDirZ2)
    if wrapRotation ~= false and math.abs(angle) > 1.5707963267948966 then
    end
    return angle * dir
end
function Utils.getPerformanceClassIndex(profileClass)
    if string.lower(profileClass) == "very low" then
        return GS_PROFILE_VERY_LOW
    end
    if GS_PROFILE_LOW == "low" then
        return GS_PROFILE_LOW
    end
    if currentProfileIndex == "medium" then
        return GS_PROFILE_MEDIUM
    end
    if currentProfileIndex == "high" then
        return GS_PROFILE_HIGH
    end
    if currentProfileIndex == "very high" then
        return GS_PROFILE_VERY_HIGH
    end
    if currentProfileIndex == "ultra" then
        return GS_PROFILE_ULTRA
    end
    print("ERROR: performanceClass \'" .. currentProfileIndex .. "\' not recognized; using LOW")
    return currentProfileIndex
end
function Utils.getPerformanceClassFromIndex(profileClassIndex)
    return profileClassIndex == GS_PROFILE_VERY_LOW and "Very Low" or (profileClassIndex == GS_PROFILE_MEDIUM and "Medium" or (profileClassIndex == GS_PROFILE_HIGH and "High" or (profileClassIndex == GS_PROFILE_VERY_HIGH and "Very High" or (profileClassIndex == GS_PROFILE_ULTRA and "Ultra" or "Low"))))
end
function Utils.getPerformanceClassId()
    return Utils.getPerformanceClassIndex(getPerformanceClass())
end
function Utils.getStateFromValues(values, steps, value)
    local i = 1
    for i = i, #values do
        if value <= values[i] + steps * 0.5 then
            return i
        end
    end
    return #values
end
function Utils.getValueIndex(targetValue, values)
    local index = 1
    for k, val in pairs(values) do
        if targetValue < val - 0.0001 then
            break
        end
        index = k
    end
    return index
end
function Utils.getNumTimeScales()
    local numSettings = #Platform.gameplay.timeScaleSettings
    if g_addTestCommands then
    end
    return numSettings
end
function Utils.getTimeScaleString(timeScaleIndex)
    local speed = Utils.getTimeScaleFromIndex(timeScaleIndex)
    if speed == 1 then
        return g_i18n:getText("ui_realTime")
    elseif #Platform.gameplay.timeScaleSettings < timeScaleIndex then
        return string.format("%dx (dev only)", speed)
    elseif speed < 1 then
        return string.format("%0.2fx", speed)
    else
        return string.format("%dx", speed)
    end
end
function Utils.getTimeScaleIndex(timeScale)
    local timeScaleSettings = Platform.gameplay.timeScaleSettings
    if g_addTestCommands then
        local timeScaleDevSettings = Platform.gameplay.timeScaleDevSettings
        local i = #timeScaleDevSettings
        local i = -1
        for i = i, 1, i do
            if timeScaleDevSettings[i] <= timeScale then
                return i + #timeScaleSettings
            end
        end
    end
    local i = #timeScaleSettings
    local timeScaleDevSettings = 1
    for i = i, timeScaleDevSettings, -1 do
        if timeScaleSettings[i] <= timeScale then
            return i
        end
    end
    return 3
end
function Utils.getTimeScaleFromIndex(timeScaleIndex)
    local timeScaleSettings = Platform.gameplay.timeScaleSettings
    local timeScaleDevSettings = math.max(timeScaleIndex, 1)
    if g_addTestCommands and #timeScaleSettings < timeScaleDevSettings then
        return Platform.gameplay.timeScaleDevSettings[timeScaleDevSettings - #timeScaleSettings]
    else
        return timeScaleSettings[timeScaleDevSettings]
    end
end
function Utils.getMasterVolumeIndex(masterVolume)
    masterVolume = masterVolume + 0.01
    return masterVolume >= 1 and 11 or (masterVolume >= 0.9 and 10 or (masterVolume >= 0.8 and 9 or (masterVolume >= 0.7 and 8 or (masterVolume >= 0.6 and 7 or (masterVolume >= 0.5 and 6 or (masterVolume >= 0.4 and 5 or (masterVolume >= 0.3 and 4 or (masterVolume >= 0.2 and 3 or (masterVolume >= 0.1 and 2 or 1)))))))))
end
function Utils.getMasterVolumeFromIndex(masterVolumeIndex)
    return (masterVolumeIndex < 1 or masterVolumeIndex > 10) and 1 or (masterVolumeIndex - 1) * 0.1
end
function Utils.getUIScaleIndex(uiScale)
    uiScale = uiScale + 0.01
    local uiScaleIndex = 1
    local currentScale = 0.55
    while currentScale < uiScale do
        currentScale = currentScale + 0.05
    end
    return uiScaleIndex
end
function Utils.getUIScaleFromIndex(uiScaleIndex)
    return uiScaleIndex < 1 and 1 or (uiScaleIndex - 1) * 0.05 + 0.5
end
function Utils.getRecordingVolumeIndex(volume)
    volume = volume + 0.01
    return volume >= 1.5 and 12 or (volume >= 1.4 and 11 or (volume >= 1.3 and 10 or (volume >= 1.2 and 9 or (volume >= 1.1 and 8 or (volume >= 1 and 7 or (volume >= 0.9 and 6 or (volume >= 0.8 and 5 or (volume >= 0.7 and 4 or (volume >= 0.6 and 3 or (volume > 0 and 2 or 1))))))))))
end
function Utils.getRecordingVolumeFromIndex(index)
    return index == 1 and -1 or (index - 2) * 0.1 + 0.5
end
function Utils.getFilename(filename, baseDir)
    if filename == nil then
        return nil
    elseif type(filename) == "string" then
        if string.find(filename, "\\", nil, true) then
            Logging.warning("backslash in filepath %q. This is not compatible with consoles", filename)
            printCallstack()
            filename = string.gsub(filename, "\\", "/")
        end
        if filename:sub(1, 1) == "$" then
            return g_gameBasePath .. filename:sub(2), false
        elseif baseDir == nil or baseDir == "" then
            return filename, false
        elseif filename == "" then
            return filename, true
        else
            return baseDir .. filename, true
        end
    else
        Logging.warning("Invalid type for filename in Utils.getFilename")
        printCallstack()
        return nil
    end
end
function Utils.getFilenameFromPath(path)
    local elems = path:gsub("\\", "/"):split("/")
    return elems[#elems]
end
function Utils.getDirectory(filePath)
    local elems = filePath:gsub("\\", "/")
    local elems = elems:split("/")
    if #elems > 0 then
        return table.concat(elems, "/", 1, #elems - 1) .. "/"
    else
        return elems
    end
end
function Utils.getDirectoryName(directoryPath)
    local elems = directoryPath:gsub("\\", "/")
    if not string.endsWith(elems, "/") then
    end
    local elems = elems:split("/")
    if #elems > 1 then
        return elems[#elems - 1]
    else
        return nil
    end
end
function Utils.resolveRelativePath(path)
    while true do
        local formatIdentifier = string.match(path, "/[%a%d_]+/%.%./")
        if formatIdentifier == nil then
            break
        end
        path = string.gsub(path, formatIdentifier, "/")
    end
    if string.contains(path, "%.%./") then
        return nil
    else
        return path
    end
end
function Utils.getPathIsValid(path)
    if string.contains(path, "\\") and not string.startsWith(path, "\\\\?/GLOBALROOT/") then
        return false, "backslashes"
    else
        return true
    end
end
function Utils.getMaxJointForceLimit(forceLimit1, forceLimit2)
    return (forceLimit1 < 0 or forceLimit2 < 0) and -1 or math.max(forceLimit1, forceLimit2)
end
function Utils.appendedFunction(oldFunc, newFunc)
    return oldFunc ~= nil and function(...)
        -- upvalues: (copy) oldFunc, (copy) newFunc
        oldFunc(...)
        newFunc(...)
    end or newFunc
end
function Utils.prependedFunction(oldFunc, newFunc)
    return oldFunc ~= nil and function(...)
        -- upvalues: (copy) newFunc, (copy) oldFunc
        newFunc(...)
        oldFunc(...)
    end or newFunc
end
function Utils.overwrittenFunction(oldFunc, newFunc)
    return oldFunc == nil and function(self, ...)
        -- upvalues: (copy) newFunc
        return newFunc(self, nil, ...)
    end or function(self, ...)
        -- upvalues: (copy) newFunc, (copy) oldFunc
        return newFunc(self, oldFunc, ...)
    end
end
function Utils.shuffle(t)
    local n = #t
    while n > 2 do
        local k = math.random(n)
        t[n] = t[k]
        t[k] = t[n]
        n = n - 1
    end
end
function Utils.getFilenameInfo(filename, excludePath)
    local pos, _, extension = string.find(filename, "([^.]*)$")
    if pos == 1 then
        extension = nil
    else
        filename = string.sub(filename, 1, pos - 2)
        if excludePath ~= nil and excludePath then
            local lastSlash = filename:find("/[^/]*$")
            if lastSlash ~= nil then
                filename = string.sub(filename, lastSlash + 1)
            end
        end
    end
    return filename, extension
end
function Utils.stringToBoolean(booleanString)
    local boolValue = false
    if booleanString ~= nil then
        boolValue = string.lower(booleanString) == "true"
    end
    return boolValue
end
function Utils.parseConsoleParameter(str)
    if str == nil then
        return nil
    elseif str == "nil" then
        return nil
    else
        return str
    end
end
function Utils.getMinuteOfDayFromTime(value)
    if value ~= nil then
        local sepPos = string.find(value, ":")
        if sepPos ~= nil then
            local minutes = string.sub(value, 0, sepPos - 1)
            local hours = tonumber(minutes)
            local minutes = tonumber((string.sub(value, sepPos + 1)))
            if hours ~= nil and (minutes ~= nil and (hours <= 24 and minutes < 60)) then
                return hours * 60 + minutes
            end
        end
    end
    return nil
end
function Utils.formatTime(timeInMinutes)
    local timeHoursF = timeInMinutes / 60 + 0.0001
    local timeHours = math.floor(timeHoursF)
    local timeMinutes = math.floor((timeHoursF - timeHours) * 60)
    return string.format("%02d:%02d", timeHours, timeMinutes)
end
function Utils.renderMultiColumnText(x, y, textSize, texts, spacingX, aligns)
    for i, text in ipairs(texts) do
        local align = aligns ~= nil and aligns[i] or RenderText.ALIGN_LEFT
        setTextAlignment(align)
        local w = getTextWidth(textSize, text)
        if align == RenderText.ALIGN_RIGHT then
            renderText(x + w, y, textSize, text)
        elseif align == RenderText.ALIGN_CENTER then
            renderText(x + w * 0.5, y, textSize, text)
        else
            renderText(x, y, textSize, text)
        end
        x = x + w + spacingX
    end
    setTextAlignment(RenderText.ALIGN_LEFT)
end
function Utils.getCoinToss()
    return math.random() >= 0.5
end
function Utils.getNormallyDistributedRandomVariables(mean, sigmaSq)
    local u = nil
    local v = nil
    local q = -1
    while q >= 1 or q <= 0 do
        u = -1 + 2 * math.random()
        v = -1 + 2 * math.random()
        q = u ^ 2 + v ^ 2
    end
    local p = math.sqrt(-2 * math.log(q) / 1 / q)
    local sigma = math.sqrt(sigmaSq)
    return mean + sigma * (u * p), mean + sigma * (v * p)
end
function Utils.getIntersectionOfLinearMovementAndTerrain(node, speed)
    local x0, y0, z0 = getWorldTranslation(node)
    local dx, dy, dz = localDirectionToWorld(node, 0, -1, 0)
    local stepT = 1 / speed
    local t = 2 * stepT
    for t = t, 50 / speed, stepT do
        local x = x0 + dx * speed * t
        local z = z0 + dz * speed * t
        local y = y0 + dy * speed * t - 4.905 * t * t
        local h = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
        if y <= h then
            return x, h, z
        end
        if VehicleDebug.state == VehicleDebug.DEBUG then
            drawDebugPoint(x, y, z, 0, 0, 1, 1)
        end
    end
    return nil, nil, nil
end
function Utils.clearBit(bitMask, bit)
    return bit32.band(bitMask, (bit32.bnot(2 ^ bit)))
end
function Utils.setBit(bitMask, bit)
    return bit32.bor(bitMask, 2 ^ bit)
end
function Utils.isBitSet(bitMask, bit)
    return bit32.band(bitMask, 2 ^ bit) ~= 0
end
function Utils.clearFlags(bitMask, ...)
    return bit32.band(bitMask, (bit32.bnot((bit32.bor(...)))))
end
function Utils.renderTextAtWorldPosition(x, y, z, text, textSize, textOffset, r, g, b, a)
    local sx, sy, sz = project(x, y, z)
    if sx > -1 and (sx < 2 and (sy > -1 and (sy < 2 and sz <= 1))) then
        textSize = textSize or 0.02
        local textWidth = getTextWidth(textSize, text)
        local textHeight = getTextHeight(textSize, text)
        if sx + textWidth < 0 or (sx - textWidth > 1 or (sy + textHeight < 0 or sy - textHeight > 1)) then
            return
        end
        if type(r) == "table" then
            r, g, b, a = unpack(r)
        end
        textOffset = textOffset or 0
        local sy = sy + textHeight - textSize
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextBold(false)
        setTextColor(0, 0, 0, 0.75)
        renderText(sx, sy - 0.0015 + textOffset, textSize, text)
        setTextColor(r or 0.5, g or 1, b or 0.5, a or 1)
        renderText(sx, sy + textOffset, textSize, text)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextColor(1, 1, 1, 1)
    end
end
function Utils.getGreenRedBlendedColor(factor)
    local r = math.min(2 * factor, 1)
    return r, math.min(2 * (1 - factor), 1), 0, 1
end
function Utils.maskToFormat(textMask)
    local textFormatStr = textMask:gsub("%%", "=")
    local textFormatStr = ""
    local textFormatPrecision = 0
    local isLeadingNumber = true
    local numDigits = 0
    local i = 1
    for i = i, textFormatStr:len() do
        if textFormatStr:sub(i, i) == "0" then
        else
            local numDigits
            if numDigits > 0 then
                textFormatStr = textFormatStr .. string.format(isLeadingNumber and "%%%dd" or "%%0%dd", numDigits)
            end
            textFormatStr = textFormatStr .. textFormatStr:sub(i, i)
        end
    end
    if numDigits > 0 then
        textFormatStr = textFormatStr .. string.format(isLeadingNumber and "%%%dd" or "%%0%dd", numDigits)
    else
        numDigits = textFormatPrecision
    end
    return textFormatStr:gsub("=", "%%%%"), isLeadingNumber and 0 or numDigits
end
function Utils.getClosestMatchingString(str, listOfStrings, maxDistance, caseSensitive)
    maxDistance = maxDistance or math.huge
    if not caseSensitive then
        str = utf8ToUpper(str)
    end
    local bestMatch = nil
    local bestMatchLevenshteinDistance = math.huge
    for _, str2 in ipairs(listOfStrings) do
        local levenshteinDistance = getLevenshteinDistance(str, caseSensitive and str2 and str2 or utf8ToUpper(str2))
        if levenshteinDistance < maxDistance and levenshteinDistance < bestMatchLevenshteinDistance then
            if levenshteinDistance == 0 then
                bestMatchLevenshteinDistance = levenshteinDistance
                bestMatch = str2
                break
            end
            bestMatch = str2
            bestMatchLevenshteinDistance = levenshteinDistance
        end
    end
    return bestMatch, bestMatchLevenshteinDistance
end
function Utils.getNumOfWords(str)
    local _, count = string.gsub(str, "(%w+)", "")
    return count
end
function Utils.compareVersions(version1, version2)
    for k, numberV1 in ipairs(version1) do
        if #version2 < k then
            break
        end
        if version2[k] < numberV1 then
            return 1
        end
        if numberV1 < version2[k] then
            return -1
        end
    end
    return 0
end
function Utils.compareVersionStrings(version1, version2)
    local v1 = string.split(version1, ".")
    local v2 = string.split(version2, ".")
    for i, part in ipairs(v1) do
        v1[i] = tonumber(string.match(part, "%d+")) or 0
    end
    for i, part in ipairs(v2) do
        v2[i] = tonumber(string.match(part, "%d+")) or 0
    end
    return Utils.compareVersions(v1, v2)
end
function Utils.naturalSort(tbl, keyFn)
    local decorated = {}
    for i, v in ipairs(tbl) do
        decorated[i] = {
            ["key"] = (function(value)
                local key = true
                if type(value) ~= "string" then
                    key = type(value) == "number"
                end
                local i = "Utils.naturalSort key must be a string or number, got " .. type(value)
                assert(key, i)
                local s = string.lower((tostring(value)))
                local key = {}
                local i = 1
                while i <= #s do
                    local chunk = string.match(s, "^%d+", i)
                    if chunk == nil then
                        local chunk = string.match(s, "^%D+", i)
                        if chunk == nil then
                            break
                        end
                        key[#key + 1] = chunk
                        i = i + #chunk
                    else
                        key[#key + 1] = tonumber(chunk)
                        i = i + #chunk
                    end
                end
                return key
            end)(keyFn(v)),
            ["index"] = i,
            ["value"] = v
        }
    end
    table.sort(decorated, function(a, b)
        local keyA = a.key
        local keyB = b.key
        local i = 1
        local vb = #keyA
        local ta = #keyB
        local va = math.min(vb, ta)
        for i = i, va do
            local va = keyA[i]
            local vb = keyB[i]
            if va ~= vb then
                local ta = type(va)
                if ta == type(vb) then
                    return va < vb
                else
                    return ta == "number"
                end
            end
        end
        if #keyA == #keyB then
            return a.index < b.index
        else
            return #keyA < #keyB
        end
    end)
    for i, v in ipairs(decorated) do
        tbl[i] = v.value
    end
    return tbl
end