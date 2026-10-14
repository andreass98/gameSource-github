SystemConsoleCommands = {}
function SystemConsoleCommands.init()
    addConsoleCommand("gsGuiDrawHelper", "", "drawGuiHelper", SystemConsoleCommands, "[lineSpacing [0..1]]")
    addConsoleCommand("gsI3DCacheClean", "Removes all cached i3d files to ensure the latest versions are loaded from disk", "cleanI3DCache", SystemConsoleCommands)
    addConsoleCommand("gsSetHighQuality", "Increase draw and LOD distances of foliage, terrain and objects", "setHighQuality", SystemConsoleCommands, "coeff;[foliageCoeff: default=coeff*0.5]")
    addConsoleCommand("gsGuiSafeFrameShow", "", "showSafeFrame", SystemConsoleCommands)
    addConsoleCommand("gsGuiDebug", "", "toggleUiDebug", SystemConsoleCommands)
    addConsoleCommand("gsGuiFocusDebug", "", "toggleUiFocusDebug", SystemConsoleCommands)
    addConsoleCommand("gsRenderColorAndDepthScreenShot", "", "renderColorAndDepthScreenShot", SystemConsoleCommands)
    addConsoleCommand("gsCustomEnvMapList", "", "listCustomEnvMaps", SystemConsoleCommands)
    addConsoleCommand("gsCustomEnvMapSet", "", "setCustomEnvMap", SystemConsoleCommands, "index")
    if g_addCheatCommands then
        addConsoleCommand("gsRenderingDebugMode", "", "setDebugRenderingMode", SystemConsoleCommands)
        addConsoleCommand("gsInputDrawRaw", "", "drawRawInput", SystemConsoleCommands)
        addConsoleCommand("gsTextureStreamingSetBudget", "", "setTextureStreamingBudget", SystemConsoleCommands)
    end
    if g_addTestCommands then
        addConsoleCommand("gsLanguageSet", "Set active language", "changeLanguage", SystemConsoleCommands)
        addConsoleCommand("gsGuiReloadCurrent", "", "reloadCurrentGui", SystemConsoleCommands)
        addConsoleCommand("gsGuiReloadCurrentDialog", "", "reloadCurrentDialog", SystemConsoleCommands)
        addConsoleCommand("gsHudResetHelpSystem", "", "resetHelpSystem", SystemConsoleCommands)
        addConsoleCommand("gsHudResetHelpSystemWithDraw", "", "resetHelpSystemWithDraw", SystemConsoleCommands)
        addConsoleCommand("gsSuspendApp", "", "suspendApp", SystemConsoleCommands)
        addConsoleCommand("gsUpdateDownloadFinished", "", "updateDownloadFinished", SystemConsoleCommands)
        addConsoleCommand("gsRenderingFidelityFxSRSet", "", "setFidelityFxSR", SystemConsoleCommands)
        addConsoleCommand("gsSoftRestart", "", "softRestart", SystemConsoleCommands, nil, true)
    end
end
function SystemConsoleCommands.delete()
    removeConsoleCommand("gsGuiDrawHelper")
    removeConsoleCommand("gsI3DCacheClean")
    removeConsoleCommand("gsSetHighQuality")
    removeConsoleCommand("gsGuiSafeFrameShow")
    removeConsoleCommand("gsGuiDebug")
    removeConsoleCommand("gsGuiFocusDebug")
    removeConsoleCommand("gsRenderColorAndDepthScreenShot")
    removeConsoleCommand("gsCustomEnvMapList")
    removeConsoleCommand("gsCustomEnvMapSet")
    removeConsoleCommand("gsRenderingDebugMode")
    removeConsoleCommand("gsInputDrawRaw")
    removeConsoleCommand("gsTextureStreamingSetBudget")
    removeConsoleCommand("gsLanguageSet")
    removeConsoleCommand("gsGuiReloadCurrent")
    removeConsoleCommand("gsGuiReloadCurrentDialog")
    removeConsoleCommand("gsSuspendApp")
    removeConsoleCommand("gsUpdateDownloadFinished")
    removeConsoleCommand("gsRenderingFidelityFxSRSet")
    removeConsoleCommand("gsSoftRestart")
end
function SystemConsoleCommands.drawGuiHelper(_, steps)
    steps = tonumber(steps)
    if steps == nil then
        g_guiHelperSteps = 0.1
        g_drawGuiHelper = false
    else
        g_guiHelperSteps = math.max(steps, 0.001)
        g_drawGuiHelper = true
    end
    return not g_drawGuiHelper and "DrawGuiHelper = false" or "DrawGuiHelper = true (step = " .. g_guiHelperSteps .. ")"
end
function SystemConsoleCommands:showSafeFrame()
    g_showSafeFrame = not g_showSafeFrame
    return string.format("showSafeFrame = %s", g_showSafeFrame)
end
function SystemConsoleCommands:drawRawInput()
    g_showRawInput = not g_showRawInput
    return string.format("showRawInput = %s", g_showRawInput)
end
function SystemConsoleCommands.setTextureStreamingBudget(_, sizeInMB)
    sizeInMB = tonumber(sizeInMB)
    if sizeInMB == nil then
        setTextureStreamingMemoryBudget(0)
        return "Reset Texture Streaming Memory Budget to default"
    else
        setTextureStreamingMemoryBudget(sizeInMB)
        return "Set Texture Streaming Memory Budget to " .. sizeInMB .. " MB"
    end
end
function SystemConsoleCommands.cleanI3DCache(_, verbose)
    local ret = Utils.stringToBoolean(verbose)
    g_i3DManager:clearEntireSharedI3DFileCache(ret)
    local ret = "I3D cache cleaned."
    if not ret then
    end
    return ret
end
function SystemConsoleCommands.setHighQuality(_, coeffOverride, foliageCoeff)
    local usage = string.format("Usage \'gsSetHighQuality <factor (default=%d)>\'", 5)
    local coeff = math.clamp(tonumber(coeffOverride) or 5, 1e-6, 10)
    foliageCoeff = tonumber(foliageCoeff) or coeff * 0.5
    setViewDistanceCoeff(coeff)
    setLODDistanceCoeff(coeff)
    setTerrainLODDistanceCoeff((math.clamp(coeff, 0, 2.5)))
    setFoliageViewDistanceCoeff((math.max(1, foliageCoeff)))
    return string.format("High quality activated, used factor=%f\n%s", MathUtil.round(coeff, 8), coeffOverride == nil and " " .. usage or "")
end
function SystemConsoleCommands.renderColorAndDepthScreenShot(_, inWidth, inHeight)
    local colorScreenShot, depthScreenShot
    if inWidth == nil or inHeight == nil then
        local curScrMode = getScreenMode()
        colorScreenShot, depthScreenShot = getScreenModeInfo(curScrMode)
    else
        colorScreenShot = tonumber(inWidth)
        depthScreenShot = tonumber(inHeight)
    end
    setDebugRenderingMode(DebugRendering.NONE)
    local curScrMode = getDate("%Y_%m_%d_%H_%M_%S") .. ".hdr"
    local colorScreenShot = g_screenshotsDirectory .. "fsScreen_color_" .. curScrMode
    print("Saving color screenshot: " .. colorScreenShot)
    renderScreenshot(colorScreenShot, colorScreenShot, depthScreenShot, colorScreenShot / depthScreenShot, "raw_hdr", 1, 0, 0, 0, 0, 0, 15, false)
    setDebugRenderingMode(DebugRendering.DEPTH)
    local depthScreenShot = g_screenshotsDirectory .. "fsScreen_depth_" .. curScrMode
    print("Saving depth screenshot: " .. depthScreenShot)
    renderScreenshot(depthScreenShot, colorScreenShot, depthScreenShot, colorScreenShot / depthScreenShot, "raw_hdr", 1, 0, 0, 0, 0, 0, 15, false)
    setDebugRenderingMode(DebugRendering.NONE)
end
local DEBUG_RENDERING_ALIASES = {
    ["AO"] = DebugRendering.AMBIENT_OCCLUSION,
    ["BAKEDAO"] = DebugRendering.BAKED_AMBIENT_OCCLUSION,
    ["SSAO"] = DebugRendering.SCREEN_SPACE_AMBIENT_OCCLUSION,
    ["DIFFUSE"] = DebugRendering.DIFFUSE_LIGHTING,
    ["SPECULAR"] = DebugRendering.SPECULAR_LIGHTING,
    ["INDIRECT"] = DebugRendering.INDIRECT_LIGHTING,
    ["DEPTH"] = DebugRendering.DEPTH_SCALED,
    ["MIPS"] = DebugRendering.MIP_LEVELS,
    ["VRS"] = DebugRendering.SHADING_RATE,
    ["LOD"] = DebugRendering.MESH_LOD
}
for mode, v in pairs(DebugRendering) do
    if string.contains(mode, "_") then
        DEBUG_RENDERING_ALIASES[string.gsub(mode, "_", "")] = v
    end
end
function SystemConsoleCommands.setDebugRenderingMode(_, newModeStr)
    -- upvalues: (copy) DEBUG_RENDERING_ALIASES
    if newModeStr == nil or newModeStr == "" then
        if getDebugRenderingMode() == DebugRendering.NONE then
            printError("Error: No debug mode given")
            return (function()
                -- upvalues: (ref) DEBUG_RENDERING_ALIASES
                local modesWithAliases = {}
                for name, mode in pairs(DebugRendering) do
                    modesWithAliases[name] = true
                    for alias, modeAlias in pairs(DEBUG_RENDERING_ALIASES) do
                        if mode == modeAlias then
                            modesWithAliases[name] = nil
                            modesWithAliases[alias] = true
                        end
                    end
                end
                local modesSorted = table.toList(modesWithAliases)
                table.sort(modesSorted)
                return "Possible modes: " .. table.concat(modesSorted, ", ")
            end)()
        else
            setDebugRenderingMode(DebugRendering.NONE)
            return "Changed debug rendering mode to NONE"
        end
    end
    local newModeStrNoUnderscore = string.upper(newModeStr)
    local newModeStrNoUnderscore = string.gsub(newModeStrNoUnderscore, "_", "")
    local debugMode = DebugRendering[newModeStrNoUnderscore] or DebugRendering[newModeStrNoUnderscore] or (DEBUG_RENDERING_ALIASES[newModeStrNoUnderscore] or DEBUG_RENDERING_ALIASES[newModeStrNoUnderscore])
    if debugMode == nil then
        printError(string.format("Error: Unknown DebugRendering mode %q", newModeStrNoUnderscore))
        return listModes()
    end
    setDebugRenderingMode(debugMode)
    local modeName = ""
    for name, mode in pairs(DebugRendering) do
        if mode == debugMode then
            modeName = name
            break
        end
    end
    return "Changed debug rendering mode to " .. modeName
end
function SystemConsoleCommands.changeLanguage(_, newCode)
    local numLanguages = getNumOfLanguages()
    local newLang = -1
    if newCode == nil then
        newLang = g_availableLanguagesTable[(#g_availableLanguagesTable <= g_settingsLanguageGUI + 1 and 0 or g_settingsLanguageGUI + 1) + 1]
    else
        local i = 0
        for i = i, numLanguages - 1 do
            if getLanguageCode(i) == newCode then
                newLang = i
                break
            end
        end
        if newLang < 0 then
            return "Invalid language parameter " .. tostring(newCode)
        end
    end
    if not setLanguage(newLang) then
        return "Invalid language parameter " .. tostring(newCode)
    end
    local newIndex = XMLFile.load("SettingsFile", "dataS/settings.xml")
    loadLanguageSettings(newIndex)
    newIndex:delete()
    g_i18n:load()
    return string.format("Changed language to \'%s\'. Note that many texts are loaded on game start and need a reboot to be updated.", getLanguageCode(newLang))
end
function SystemConsoleCommands:reloadCurrentGui()
    if g_gui.currentGuiName == nil or g_gui.currentGuiName == "" then
        return "No GUI active!"
    end
    g_gui.currentlyReloading = true
    local guiName = g_gui.currentGuiName
    g_gui:showGui("")
    g_i18n:delete()
    g_i18n:load()
    if not g_gui:loadProfiles("dataS/guiProfiles.xml") then
        g_gui.currentlyReloading = false
        return "Failed to reload profiles"
    end
    local class = ClassUtil.getClassObject(guiName)
    if class == nil then
        for customEnv, _ in pairs(g_modIsLoaded) do
            for k, v in pairs(_G[customEnv]) do
                if k == guiName then
                    class = v
                end
            end
        end
    end
    if class == nil then
        return "Given GUI class not found"
    end
    g_dummyGui = nil
    if class.createFromExistingGui == nil then
        g_dummyGui = class.new()
        g_gui.guis[guiName]:delete()
        g_gui.guis[guiName].target:delete()
        g_gui:loadGui(g_gui.currentGui.target.xmlFilename, guiName, g_dummyGui)
    else
        g_dummyGui = class.createFromExistingGui(guiController, guiName)
    end
    g_gui:showGui(guiName)
    g_gui.currentlyReloading = false
    return "Reloaded gui " .. tostring(guiName)
end
function SystemConsoleCommands:reloadCurrentDialog()
    if g_gui.currentDialogName == nil or g_gui.currentDialogName == "" then
        return "No Dialog active!"
    end
    g_gui.currentlyReloading = true
    local guiName = g_gui.currentDialogName
    local currentListener = g_gui.currentListener
    g_gui:closeDialog(currentListener)
    g_i18n:delete()
    g_i18n:load()
    if not g_gui:loadProfiles("dataS/guiProfiles.xml") then
        g_gui.currentlyReloading = false
        return "Failed to reload profiles"
    end
    local class = ClassUtil.getClassObject(guiName)
    if class == nil then
        for customEnv, _ in pairs(g_modIsLoaded) do
            for k, v in pairs(_G[customEnv]) do
                if k == guiName then
                    class = v
                end
            end
        end
    end
    if class == nil then
        return "Given GUI Dialog class not found"
    end
    g_dummyGui = nil
    if class.createFromExistingGui == nil then
        g_dummyGui = class.new()
        g_gui.guis[guiName]:delete()
        g_gui.guis[guiName].target:delete()
        g_gui:loadGui(currentListener.target.xmlFilename, guiName, g_dummyGui)
    else
        g_dummyGui = class.createFromExistingGui(guiController, guiName)
    end
    g_gui.currentlyReloading = false
    return "Reloaded dialog " .. tostring(guiName)
end
function SystemConsoleCommands:resetHelpSystem()
    if g_currentMission == nil or g_currentMission.introductionHelpSystem == nil then
        return "Not currently in a mission"
    end
    g_currentMission.introductionHelpSystem:resetHelpSystem()
    return "Reset Introduction Help System"
end
function SystemConsoleCommands:resetHelpSystemWithDraw()
    if g_currentMission == nil or g_currentMission.introductionHelpSystem == nil then
        return "Not currently in a mission"
    end
    g_currentMission.introductionHelpSystem:resetHelpSystemWithDraw()
    return "Reset Introduction Help System"
end
function SystemConsoleCommands:toggleUiDebug()
    if g_uiDebugEnabled then
        g_uiDebugEnabled = false
        return "UI Debug disabled"
    else
        g_uiDebugEnabled = true
        return "UI Debug enabled"
    end
end
function SystemConsoleCommands:toggleUiFocusDebug()
    if g_uiFocusDebugEnabled then
        g_uiFocusDebugEnabled = false
        return "UI Focus Debug disabled"
    else
        g_uiFocusDebugEnabled = true
        return "UI Focus Debug enabled"
    end
end
function SystemConsoleCommands:suspendApp()
    if g_appIsSuspended then
        notifyAppResumed()
    else
        notifyAppSuspended()
    end
    return "App Suspended: " .. tostring(g_appIsSuspended)
end
function SystemConsoleCommands:softRestart()
    if g_currentMission == nil then
        RestartManager:setStartScreen(RestartManager.START_SCREEN_MAIN)
        doRestart(false, "")
    else
        OnInGameMenuMenu()
    end
end
function SystemConsoleCommands:updateDownloadFinished()
    g_updateDownloadFinished = true
    log("g_updateDownloadFinished = true")
end
function SystemConsoleCommands.setFidelityFxSR(_, newQuality)
    local currentQuality = tonumber(newQuality)
    local currentQuality = getFidelityFxSRQuality()
    print(string.format("current setting: %s (%d)", getFidelityFxSRQualityName(currentQuality), currentQuality))
    print("Available settings:")
    local i = 0
    for i = i, FidelityFxSRQuality.NUM - 1 do
        local name = getFidelityFxSRQualityName(i)
        print(string.format("    %d | %s | supported=%s", i, name, (tostring(getSupportsFidelityFxSRQuality(i)))))
    end
    if currentQuality == nil then
        return "Usage: gsRenderingFidelityFxSRSet <qualityNumber>"
    end
    if currentQuality < 0 or (currentQuality >= FidelityFxSRQuality.NUM or not getSupportsFidelityFxSRQuality(currentQuality)) then
        return string.format("Error: Given quality \'%d\' not supported\n%s", currentQuality, "Usage: gsRenderingFidelityFxSRSet <qualityNumber>")
    end
    setFidelityFxSRQuality(currentQuality)
    local effectiveQuality = getFidelityFxSRQuality()
    return string.format("new setting: %s (%d)", getFidelityFxSRQualityName(effectiveQuality), effectiveQuality)
end
local customEnvMaps = {}
local setEnvMapFunc = setEnvMap
function SystemConsoleCommands.registerCustomEnvMap(filepath)
    -- upvalues: (copy) customEnvMaps
    table.addElement(customEnvMaps, filepath)
end
function SystemConsoleCommands:listCustomEnvMaps()
    -- upvalues: (copy) customEnvMaps
    if #customEnvMaps == 0 then
        print("No custom env maps registered")
    else
        for index, path in ipairs(customEnvMaps) do
            print(string.format("%d - %s", index, path))
        end
    end
end
function SystemConsoleCommands.setCustomEnvMap(_, index, weight)
    -- upvalues: (copy) setEnvMapFunc, (copy) customEnvMaps
    local filename = tonumber(index)
    if filename == 0 then
        setEnvMap = setEnvMapFunc
        print("reset custom env map")
        return
    elseif filename == nil then
        printError("Error: no index given")
        print("Usage: gsCustomEnvMapSet index")
        print("Use gsCustomEnvMapList to see available env maps")
    else
        local filename = customEnvMaps[filename]
        if filename == nil then
            printError("Error: no env map for index %d", filename)
        end
        weight = tonumber(weight) or 1
        function setEnvMap() end
        setEnvMapFunc(filename, filename, filename, filename, weight, 0, 0, 0, true, true)
        print(string.format("set custom env map to %q with a weight of %.2f", filename, weight))
    end
end