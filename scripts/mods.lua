g_modDescSchema = nil
g_uniqueDlcNamePrefix = "pdlc_"
g_modEventListeners = {}
g_dlcsDirectories = {}
g_forceNeedsDlcsAndModsReload = false
g_lastCheckDlcPaths = {}
g_modIsLoaded = {}
g_globalMods = {}
g_modNameToDirectory = {}
local isReloadingDlcs = false
g_dlcModNameHasPrefix = {}
g_internalModsDirectory = "internalMods/"
local internalMods = {}
local internalScriptMods = { "FS25_precisionFarming" }
g_outdatedMods = {
    ["FS25_SelectableBaleCapacity"] = {
        1,
        0,
        0,
        0
    },
    ["FS25_seeds_addon_crossplay"] = {
        1,
        0,
        0,
        1
    },
    ["FS25_SchwesingBahnhof"] = {
        1,
        0,
        0,
        2
    },
    ["FS25_simpleIC"] = {
        9,
        0,
        0,
        0
    },
    ["FS25_simpleIC_fs25planet"] = {
        9,
        0,
        0,
        0
    },
    ["FS25_JohnDeere7030"] = {
        1,
        1,
        0,
        0
    },
    ["FS25_InfoDisplayExtension"] = {
        1,
        1,
        1,
        9
    },
    ["FS25_Courseplay"] = {
        8,
        0,
        1,
        1
    },
    ["Courseplay"] = {
        8,
        0,
        1,
        1
    },
    ["FS25_Courseplay_FS25_main"] = {
        8,
        0,
        1,
        1
    },
    ["FS25_UniversalAutoload"] = {
        0,
        4,
        5,
        7
    },
    ["UniversalAutoload"] = {
        0,
        4,
        5,
        7
    },
    ["FS25_UniversalAutoload_main"] = {
        0,
        4,
        5,
        8
    },
    ["FS25_MUD_PARTICULES"] = {
        1,
        0,
        0,
        0
    },
    ["FS25_MUD_PARTICULES__1_"] = {
        1,
        0,
        0,
        0
    },
    ["FS25_MapObjectsHider"] = {
        1,
        0,
        9,
        0
    },
    ["FS25_PerfectEdge"] = {
        1,
        0,
        9,
        0
    },
    ["FS25_AutoDrive"] = {
        3,
        0,
        0,
        3
    },
    ["FS25_ContractBoost"] = {
        1,
        0,
        9,
        0
    },
    ["FS25_Financing"] = {
        1,
        0,
        0,
        1
    },
    ["FS25_exhaustExtension"] = {
        1,
        0,
        0,
        2
    },
    ["FS25_Contracts_Plus"] = {
        1,
        0,
        0,
        0
    },
    ["FS25_precisionFarming"] = {
        1,
        3,
        1,
        0
    }
}
modOnCreate = {}
function loadDlcs()
    storeHaveDlcsChanged()
    g_modDescSchema = g_modDescSchema or createModDescSchema()
    if Platform.verboseDLCLoading then
        Logging.info("Start loading DLCs...")
    end
    local i = 1
    for i = i, #g_dlcsDirectories do
        local dir = g_dlcsDirectories[i]
        if dir.isLoaded then
            loadDlcsFromDirectory(dir.path, {})
        end
    end
    if Platform.verboseDLCLoading then
        Logging.info("Finished loading DLCs.")
    end
end
function loadDlcsFromDirectory(dlcsDir, _)
    if Platform.verboseDLCLoading then
        Logging.info("Try to load dlcs from directory \'%s\'", dlcsDir)
    end
    local appBasePath = getAppBasePath()
    if isAbsolutePath(dlcsDir) and (appBasePath:len() == 0 or not string.startsWith(dlcsDir, appBasePath)) then
        createFolder(dlcsDir)
    end
    local files = Files.new(dlcsDir)
    for _, v in pairs(files.files) do
        if Platform.verboseDLCLoading then
            Logging.info("Trying to load dlc file %s", v.filename)
        end
        local addDLCPrefix = false
        local dlcFileHash = nil
        local dlcName = nil
        local xmlFilename = nil
        if v.isDirectory then
            if g_isDevelopmentVersion or not GS_PLATFORM_PC then
                xmlFilename = "dlcDesc.xml"
                addDLCPrefix = true
                if not GS_PLATFORM_PC then
                    dlcFileHash = getFileMD5(dlcsDir .. v.filename, v.filename)
                end
                if dlcFileHash == nil and g_isDevelopmentVersion then
                    dlcFileHash = getMD5("Dev_" .. v.filename)
                end
            end
        else
            local len = v.filename:len()
            if len > 4 then
                local ext = v.filename:sub(len - 3)
                if ext == ".dlc" then
                    dlcName = v.filename:sub(1, len - 4)
                    dlcFileHash = getFileMD5(dlcsDir .. v.filename, dlcName)
                    xmlFilename = "dlcDesc.xml"
                    addDLCPrefix = true
                elseif ext == ".zip" or ext == ".gar" then
                    dlcName = v.filename:sub(1, len - 4)
                    dlcFileHash = getFileMD5(dlcsDir .. v.filename, dlcName)
                    xmlFilename = "modDesc.xml"
                    addDLCPrefix = false
                end
            end
        end
        if dlcName ~= nil and (xmlFilename ~= nil and g_dlcModNameHasPrefix[dlcName] == nil) then
            local len = dlcsDir .. dlcName .. "/"
            g_dlcModNameHasPrefix[dlcName] = addDLCPrefix
            loadModDesc(dlcName, len, len .. xmlFilename, dlcFileHash, dlcsDir .. v.filename, v.isDirectory, addDLCPrefix, false)
        end
    end
end
function loadAllMods()
    loadInternalMods()
    loadMods()
    haveModsChanged()
end
function loadMods()
    local modsDir = g_modsDirectory
    g_showIllegalActivityInfo = false
    local files = Files.new(modsDir)
    for _, v in pairs(files.files) do
        local modFileHash = nil
        local modName = nil
        if v.isDirectory then
            modName = v.filename
            if g_isDevelopmentVersion then
                modFileHash = getMD5("DevMod_" .. v.filename)
            end
        else
            local len = v.filename:len()
            if len > 4 then
                local ext = v.filename:sub(len - 3)
                if ext == ".zip" or ext == ".gar" then
                    modName = v.filename:sub(1, len - 4)
                    modFileHash = getFileMD5(modsDir .. v.filename, modName)
                end
            end
        end
        if modName ~= nil then
            local len = modsDir .. modName .. "/"
            local ext = len .. "modDesc.xml"
            if ({})[ext] == nil then
                loadModDesc(modName, len, ext, modFileHash, modsDir .. v.filename, v.isDirectory, false, false)
                loadedMods[ext] = true
            end
        end
    end
    if g_showIllegalActivityInfo then
        print("Info: This game protects you from illegal activity")
    end
    g_showIllegalActivityInfo = nil
end
function loadInternalMods()
    -- upvalues: (copy) internalMods
    for _, modInfo in ipairs(internalMods) do
        local modName = modInfo.name
        local modDir = g_internalModsDirectory .. modName .. "/"
        local modFileHash = nil
        local garFile = g_internalModsDirectory .. modName .. ".gar"
        if fileExists(garFile) then
            modFileHash = getFileMD5(garFile, modName)
        elseif (g_isDevelopmentVersion or GS_IS_CONSOLE_VERSION) and fileExists(modDir .. "modDesc.xml") then
            modFileHash = getFileMD5(modFile, modName)
        end
        if modFileHash ~= nil then
            loadModDesc(modName, modDir, modFile, modFileHash, g_internalModsDirectory .. modName, true, false, true)
        end
    end
end
function postInitMods()
    for _, v in ipairs(g_modEventListeners) do
        if v.onPostInit ~= nil then
            v:onPostInit()
        end
    end
end
local function getIsValidModDir(modDir)
    if modDir:len() == 0 then
        return false
    elseif string.startsWith(modDir, g_uniqueDlcNamePrefix) then
        return false
    elseif modDir:find("%d") == 1 then
        return false
    else
        return modDir:find("[^%w_]") == nil
    end
end
local function getIsInternalScriptMod(modName)
    -- upvalues: (copy) internalScriptMods
    local i = 1
    for i = i, #internalScriptMods do
        local internalModName = internalScriptMods[i]
        if modName == internalModName or modName == internalModName .. "_update" then
            return true
        end
    end
    return false
end
local function getIsInternalMod(modName)
    -- upvalues: (copy) internalMods
    for _, modInfo in ipairs(internalMods) do
        local internalModName = modInfo.name
        if modName == internalModName or modName == internalModName .. "_update" then
            return true
        end
    end
    return false
end
local function getIsInternalModInfo(modName)
    -- upvalues: (copy) internalMods
    for _, modInfo in ipairs(internalMods) do
        local internalModName = modInfo.name
        if modName == internalModName or modName == internalModName .. "_update" then
            return modInfo
        end
    end
    return nil
end
local function resolveInternalScriptModFilename(filename, modName, modDir)
    -- upvalues: (copy) internalScriptMods
    if filename:sub(1, modDir:len()) == modDir then
        local i = 1
        for i = i, #internalScriptMods do
            local internalModName = internalScriptMods[i]
            if (modName == internalModName or modName == internalModName .. "_update") and (not fileExists(filename) or GS_IS_CONSOLE_VERSION) then
                return "dataS/scripts/internalMods/" .. internalModName .. "/" .. filename:sub(modDir:len() + 1)
            end
        end
    end
    return filename
end
function loadModDesc(modName, modDir, modFile, modFileHash, absBaseFilename, isDirectory, addDLCPrefix, isInternalMod)
    -- upvalues: (copy) getIsValidModDir, (copy) getIsInternalModInfo, (ref) isReloadingDlcs, (copy) resolveInternalScriptModFilename, (copy) getIsInternalScriptMod
    if not getIsValidModDir(modName) then
        printError("Error: Invalid mod name \'" .. modName .. "\'! Characters allowed: (_, A-Z, a-z, 0-9). The first character must not be a digit")
        return
    end
    if addDLCPrefix then
    end
    if g_modNameToDirectory[modName] ~= nil then
        Logging.error("Mod name \'" .. modName .. "\' already in use. Ignore it!")
        return
    end
    g_modNameToDirectory[modName] = modDir
    local isDLCFile = false
    local revision = nil
    if string.endsWith(modFile, "dlcDesc.xml") then
        isDLCFile = true
        if not fileExists(modFile) then
            if GS_IS_EPIC_VERSION and string.startsWith(modDir, getAppBasePath() .. "pdlc/") then
                print("Info: No license for dlc " .. modName .. ".")
            else
                printError("Error: No license for dlc " .. modName .. ". Please reinstall.")
            end
            return
        end
        local settingsXML = XMLFile.loadIfExists("DLC SettingsFile", modDir .. "settings.xml")
        if settingsXML ~= nil then
            revision = settingsXML:getString("settings#revision", "Unknown")
            settingsXML:delete()
        end
    end
    setModInstalled(absBaseFilename, addDLCPrefix)
    local settingsXML = XMLFile.load("ModFile", modFile, g_modDescSchema)
    if settingsXML == nil then
        return
    end
    local modVersion = settingsXML:getString("modDesc.version")
    local versionStr = ""
    if modVersion ~= nil and modVersion ~= "" then
        versionStr = " (Version: " .. modVersion .. ")"
    end
    if isInternalMod and modVersion ~= getIsInternalModInfo(modName).version then
        printError("Error: Outdated mod version in mod " .. modName)
        settingsXML:delete()
        return
    end
    local modInfo = ""
    if modFileHash ~= nil then
        modInfo = "(Hash: " .. modFileHash .. ")"
    end
    if isDLCFile then
        local revisionStr = ""
        if revision ~= nil then
            revisionStr = string.format(" (Revision: %s)", revision)
        end
        print("Available dlc: " .. modInfo .. versionStr .. " " .. modName .. revisionStr)
    else
        print("Available mod: " .. modInfo .. versionStr .. " " .. modName)
    end
    local revisionStr = settingsXML:getInt("modDesc#descVersion")
    if revisionStr == nil then
        printError("Error: Missing descVersion attribute in mod " .. modName)
        settingsXML:delete()
        return
    end
    if revisionStr < g_minModDescVersion or g_maxModDescVersion < revisionStr then
        printError("Error: Unsupported mod description version in mod " .. modName)
        settingsXML:delete()
        return
    end
    if _G[modName] ~= nil and not isReloadingDlcs then
        printError("Error: Invalid mod name \'" .. modName .. "\'")
        settingsXML:delete()
        return
    end
    if isDLCFile then
        local requiredModName = settingsXML:getString("modDesc.multiplayer#requiredModName")
        if requiredModName ~= nil and requiredModName ~= modName then
            printError("Error: Do not rename dlcs. Name: \'" .. modName .. "\'. Expect: \'" .. requiredModName .. "\'")
            settingsXML:delete()
            return
        end
    end
    local requiredModName = settingsXML:getBool("modDesc.isSelectable", true)
    local modEnv = {}
    if GS_IS_CONSOLE_VERSION then
        modEnv = Utils.getNoNil(_G[modName], modEnv)
    end
    g_globalsNameCheckDisabled = true
    _G[modName] = modEnv
    g_globalsNameCheckDisabled = false
    setmetatable(modEnv, {
        ["__index"] = _G
    })
    if not (isDLCFile or isInternalMod) then
        modEnv._G = modEnv
    end
    local gEnv = _G
    local orgGetfenv = getfenv
    function modEnv.getfenv(obj)
        -- upvalues: (copy) orgGetfenv, (copy) gEnv, (ref) modEnv
        local ret = orgGetfenv(obj)
        if ret == gEnv then
            return modEnv
        else
            return ret
        end
    end
    modEnv.g_i18n = g_i18n:addModI18N(modName)
    function modEnv.loadstring(str, chunkname)
        -- upvalues: (ref) modName
        return loadstring("setfenv(1," .. modName .. "); " .. str, chunkname)
    end
    function modEnv.source(filename, _)
        -- upvalues: (copy) isInternalMod, (ref) resolveInternalScriptModFilename, (ref) modName, (copy) modDir
        if isAbsolutePath(filename) or isInternalMod then
            filename = resolveInternalScriptModFilename(filename, modName, modDir)
            source(filename, modName)
        else
            source(filename)
        end
    end
    function modEnv.InitEventClass(classObject, className)
        -- upvalues: (ref) modName
        InitEventClass(classObject, modName .. "." .. className)
    end
    function modEnv.InitObjectClass(classObject, className)
        -- upvalues: (ref) modName
        InitObjectClass(classObject, modName .. "." .. className)
    end
    function modEnv.registerObjectClassName(object, className)
        -- upvalues: (ref) modName
        registerObjectClassName(object, modName .. "." .. className)
    end
    modEnv.g_constructionBrushTypeManager = {}
    local function userProfilePath(_, typeName, className, filename, customEnvironment)
        -- upvalues: (copy) isInternalMod, (ref) resolveInternalScriptModFilename, (ref) modName, (copy) modDir
        if isAbsolutePath(filename) or isInternalMod then
            filename = resolveInternalScriptModFilename(filename, modName, modDir)
            customEnvironment = modName
        end
        g_constructionBrushTypeManager:addBrushType(typeName, className, filename, customEnvironment)
    end
    modEnv.g_constructionBrushTypeManager.addBrushType = userProfilePath
    function modEnv.g_constructionBrushTypeManager.getClassObjectByTypeName(_, typeName)
        -- upvalues: (ref) modName
        local classObj = g_constructionBrushTypeManager:getClassObjectByTypeName(typeName)
        if classObj == nil then
            classObj = g_constructionBrushTypeManager:getClassObjectByTypeName(modName .. "." .. typeName)
        end
        return classObj
    end
    local sub = modEnv.g_constructionBrushTypeManager
    local len = {
        ["__index"] = g_constructionBrushTypeManager
    }
    setmetatable(sub, len)
    modEnv.g_specializationManager = {}
    local function userProfilePath(self, name, className, filename, customEnvironment, ...)
        -- upvalues: (copy) isInternalMod, (ref) resolveInternalScriptModFilename, (ref) modName, (copy) modDir
        if type(self) ~= "table" then
            Logging.error("Invalid self object given for (Vehicle) SpecializationManager.addSpecialization. Usage: \'g_specializationManager:addSpecialization(name, className, filename, customEnvironment)\'")
            printCallstack()
        end
        if customEnvironment ~= nil and type(customEnvironment) ~= "string" then
            Logging.error("Invalid customEnvironment given for (Vehicle) SpecializationManager.addSpecialization. Should be a string or nil.")
            printCallstack()
        end
        if select("#", ...) > 0 then
            Logging.error("Too many arguments for (Vehicle) SpecializationManager.addSpecialization. (Arguments should be: name, className, filename, customEnvironment)")
            printCallstack()
        end
        if isAbsolutePath(filename) or isInternalMod then
            filename = resolveInternalScriptModFilename(filename, modName, modDir)
            customEnvironment = modName
        end
        local file = Utils.getFilenameFromPath(filename)
        if file == "AddConfig.lua" and customEnvironment ~= nil then
            Logging.error("Loading file \'%s\' of mod \'%s\' was blocked because it is not compatible with Farming Simulator 25", file, customEnvironment)
        else
            g_specializationManager:addSpecialization(name, className, filename, customEnvironment)
        end
    end
    modEnv.g_specializationManager.addSpecialization = userProfilePath
    function modEnv.g_specializationManager.getSpecializationByName(_, name)
        -- upvalues: (ref) modName
        local spec = g_specializationManager:getSpecializationByName(name)
        if spec == nil then
            spec = g_specializationManager:getSpecializationByName(modName .. "." .. name)
        end
        return spec
    end
    function modEnv.g_specializationManager.getSpecializationObjectByName(_, name)
        -- upvalues: (ref) modName
        local spec = g_specializationManager:getSpecializationObjectByName(name)
        if spec == nil then
            spec = g_specializationManager:getSpecializationObjectByName(modName .. "." .. name)
        end
        return spec
    end
    local sub = modEnv.g_specializationManager
    local len = {
        ["__index"] = g_specializationManager
    }
    setmetatable(sub, len)
    modEnv.g_placeableSpecializationManager = {}
    local function userProfilePath(self, name, className, filename, customEnvironment, ...)
        -- upvalues: (copy) isInternalMod, (ref) resolveInternalScriptModFilename, (ref) modName, (copy) modDir
        if type(self) ~= "table" then
            Logging.error("Invalid self object given for (Placeable) SpecializationManager.addSpecialization. Usage: \'g_placeableSpecializationManager:addSpecialization(name, className, filename, customEnvironment)\'")
            printCallstack()
        end
        if customEnvironment ~= nil and type(customEnvironment) ~= "string" then
            Logging.error("Invalid customEnvironment given for (Placeable) SpecializationManager.addSpecialization. Should be a string or nil.")
            printCallstack()
        end
        if select("#", ...) > 0 then
            Logging.error("Too many arguments for (Placeable) SpecializationManager.addSpecialization. (Arguments should be: name, className, filename, customEnvironment)")
            printCallstack()
        end
        if isAbsolutePath(filename) or isInternalMod then
            filename = resolveInternalScriptModFilename(filename, modName, modDir)
            customEnvironment = modName
        end
        g_placeableSpecializationManager:addSpecialization(name, className, filename, customEnvironment)
    end
    modEnv.g_placeableSpecializationManager.addSpecialization = userProfilePath
    function modEnv.g_placeableSpecializationManager.getSpecializationByName(_, name)
        -- upvalues: (ref) modName
        local spec = g_placeableSpecializationManager:getSpecializationByName(name)
        if spec == nil then
            spec = g_placeableSpecializationManager:getSpecializationByName(modName .. "." .. name)
        end
        return spec
    end
    local sub = modEnv.g_placeableSpecializationManager
    local len = {
        ["__index"] = g_placeableSpecializationManager
    }
    setmetatable(sub, len)
    modEnv.g_handToolSpecializationManager = {}
    local function userProfilePath(self, name, className, filename, customEnvironment, ...)
        -- upvalues: (copy) isInternalMod, (ref) resolveInternalScriptModFilename, (ref) modName, (copy) modDir
        if type(self) ~= "table" then
            Logging.error("Invalid self object given for SpecializationManager.addSpecialization. Usage: \'g_handToolSpecializationManager:addSpecialization(name, className, filename, customEnvironment)\'")
            printCallstack()
        end
        if customEnvironment ~= nil and type(customEnvironment) ~= "string" then
            Logging.error("Invalid customEnvironment given for (HandTool) SpecializationManager.addSpecialization. Should be a string or nil.")
            printCallstack()
        end
        if select("#", ...) > 0 then
            Logging.error("Too many arguments for (HandTool) SpecializationManager.addSpecialization. (Arguments should be: name, className, filename, customEnvironment)")
            printCallstack()
        end
        if isAbsolutePath(filename) or isInternalMod then
            filename = resolveInternalScriptModFilename(filename, modName, modDir)
            customEnvironment = modName
        end
        g_handToolSpecializationManager:addSpecialization(name, className, filename, customEnvironment)
    end
    modEnv.g_handToolSpecializationManager.addSpecialization = userProfilePath
    function modEnv.g_handToolSpecializationManager.getSpecializationByName(_, name)
        -- upvalues: (ref) modName
        local spec = g_handToolSpecializationManager:getSpecializationByName(name)
        if spec == nil then
            spec = g_handToolSpecializationManager:getSpecializationByName(modName .. "." .. name)
        end
        return spec
    end
    local sub = modEnv.g_handToolSpecializationManager
    local len = {
        ["__index"] = g_handToolSpecializationManager
    }
    setmetatable(sub, len)
    modEnv.g_vehicleTypeManager = {}
    local function userProfilePath(_, typeName, className, filename, customEnvironment)
        -- upvalues: (copy) isInternalMod, (ref) resolveInternalScriptModFilename, (ref) modName, (copy) modDir
        if isAbsolutePath(filename) or isInternalMod then
            filename = resolveInternalScriptModFilename(filename, modName, modDir)
            customEnvironment = modName
        end
        g_vehicleTypeManager:addType(typeName, className, filename, customEnvironment)
    end
    modEnv.g_vehicleTypeManager.addType = userProfilePath
    function modEnv.g_vehicleTypeManager.addSpecialization(_, typeName, specName)
        -- upvalues: (ref) modName
        if g_specializationManager:getSpecializationByName(specName) == nil and g_specializationManager:getSpecializationByName(modName .. "." .. specName) ~= nil then
        end
        g_vehicleTypeManager:addSpecialization(typeName, specName)
    end
    local sub = modEnv.g_vehicleTypeManager
    local len = {
        ["__index"] = g_vehicleTypeManager
    }
    setmetatable(sub, len)
    modEnv.g_placeableTypeManager = {}
    local function userProfilePath(_, typeName, className, filename, customEnvironment)
        -- upvalues: (copy) isInternalMod, (ref) resolveInternalScriptModFilename, (ref) modName, (copy) modDir
        if isAbsolutePath(filename) or isInternalMod then
            filename = resolveInternalScriptModFilename(filename, modName, modDir)
            customEnvironment = modName
        end
        g_placeableTypeManager:addType(typeName, className, filename, customEnvironment)
    end
    modEnv.g_placeableTypeManager.addType = userProfilePath
    function modEnv.g_placeableTypeManager.addSpecialization(_, typeName, specName)
        -- upvalues: (ref) modName
        if g_placeableSpecializationManager:getSpecializationByName(specName) == nil and g_placeableSpecializationManager:getSpecializationByName(modName .. "." .. specName) ~= nil then
        end
        g_placeableTypeManager:addSpecialization(typeName, specName)
    end
    local sub = modEnv.g_placeableTypeManager
    local len = {
        ["__index"] = g_placeableTypeManager
    }
    setmetatable(sub, len)
    modEnv.g_handToolTypeManager = {}
    local function userProfilePath(_, typeName, className, filename, customEnvironment)
        -- upvalues: (copy) isInternalMod, (ref) resolveInternalScriptModFilename, (ref) modName, (copy) modDir
        if isAbsolutePath(filename) or isInternalMod then
            filename = resolveInternalScriptModFilename(filename, modName, modDir)
            customEnvironment = modName
        end
        g_handToolTypeManager:addType(typeName, className, filename, customEnvironment)
    end
    modEnv.g_handToolTypeManager.addType = userProfilePath
    function modEnv.g_handToolTypeManager.addSpecialization(_, typeName, specName)
        -- upvalues: (ref) modName
        if g_handToolSpecializationManager:getSpecializationByName(specName) == nil and g_handToolSpecializationManager:getSpecializationByName(modName .. "." .. specName) ~= nil then
        end
        g_handToolTypeManager:addSpecialization(typeName, specName)
    end
    local sub = modEnv.g_handToolTypeManager
    local len = {
        ["__index"] = g_handToolTypeManager
    }
    setmetatable(sub, len)
    modEnv.g_effectManager = {}
    function modEnv.g_effectManager.registerEffectClass(_, className, effectClass)
        -- upvalues: (ref) modName
        if ClassUtil.getIsValidClassName(className) then
            _G.g_effectManager:registerEffectClass(modName .. "." .. className, effectClass)
        else
            printError("Error: Invalid effect class name: " .. className)
        end
    end
    function modEnv.g_effectManager.getEffectClass(_, className)
        -- upvalues: (ref) modName
        local effectClass = _G.g_effectManager:getEffectClass(className)
        if effectClass == nil then
            effectClass = _G.g_effectManager:getEffectClass(modName .. "." .. className)
        end
        return effectClass
    end
    local sub = modEnv.g_effectManager
    local len = {
        ["__index"] = _G.g_effectManager
    }
    setmetatable(sub, len)
    local userProfilePath = getUserProfileAppPath()
    local sub = string.sub
    local len = string.len
    local function protectedDelete(func)
        -- upvalues: (copy) userProfilePath, (ref) modName, (copy) len, (copy) sub
        return function(filename)
            -- upvalues: (ref) userProfilePath, (ref) modName, (ref) len, (ref) sub, (copy) func
            local modSettingsDirectory = userProfilePath .. "modSettings/" .. modName
            if sub(filename, 1, (len(modSettingsDirectory))) == modSettingsDirectory then
                func(filename)
            else
                printError(string.format("Error: No access to folder \'%s\'", filename))
                print(string.format("Info: Mod has full access in \'%s\'", modSettingsDirectory))
                printCallstack()
            end
        end
    end
    modEnv.g_adsSystem = {}
    modEnv.InitStaticEventClass = ""
    modEnv.InitStaticObjectClass = ""
    modEnv.loadMod = ""
    modEnv.loadModDesc = ""
    modEnv.loadDlcs = ""
    modEnv.loadDlcsFromDirectory = ""
    modEnv.loadMods = ""
    modEnv.reloadDlcsAndMods = ""
    modEnv.verifyDlcs = ""
    modEnv.deleteFile = protectedDelete(deleteFile)
    modEnv.deleteFolder = protectedDelete(deleteFolder)
    modEnv.isAbsolutePath = isAbsolutePath
    modEnv.g_isDevelopmentVersion = g_isDevelopmentVersion
    modEnv.GS_IS_CONSOLE_VERSION = GS_IS_CONSOLE_VERSION
    if not (isDLCFile or isInternalMod) then
        modEnv.ClassUtil = {}
        function modEnv.ClassUtil.getClassModName(_, className)
            -- upvalues: (ref) modName
            local classModName = _G.ClassUtil.getClassModName(className)
            if classModName == nil then
                classModName = _G.ClassUtil.getClassModName(modName .. "." .. className)
            end
            return classModName
        end
    end
    local onCreateUtil = {
        ["onCreateFunctions"] = {}
    }
    modEnv.g_onCreateUtil = onCreateUtil
    function onCreateUtil.addOnCreateFunction(name, func)
        -- upvalues: (copy) onCreateUtil
        onCreateUtil.onCreateFunctions[name] = func
    end
    function onCreateUtil.activateOnCreateFunctions()
        -- upvalues: (copy) onCreateUtil
        for name, func in pairs(onCreateUtil.onCreateFunctions) do
            local func
            modOnCreate[name] = function(_, id)
                -- upvalues: (copy) func
                func(id)
            end
        end
    end
    function onCreateUtil.deactivateOnCreateFunctions()
        -- upvalues: (copy) onCreateUtil
        for name, _ in pairs(onCreateUtil.onCreateFunctions) do
            modOnCreate[name] = nil
        end
    end
    for _, baseName in settingsXML:iterator("modDesc.l10n.text") do
        local name = settingsXML:getString(baseName .. "#name")
        local text = settingsXML:getString(baseName .. "." .. g_languageShort) or (settingsXML:getString(baseName .. ".en") or settingsXML:getString(baseName .. ".de"))
        if text == nil or name == nil then
            printWarning("Warning: No l10n text found for entry \'" .. name .. "\' in mod \'" .. modName .. "\'")
        elseif modEnv.g_i18n:hasModText(name) then
            printWarning("Warning: Duplicate l10n entry \'" .. name .. "\' in mod \'" .. modName .. "\'. Ignoring this definition.")
        else
            modEnv.g_i18n:setText(name, text)
        end
    end
    local l10nFilenamePrefix = settingsXML:getString("modDesc.l10n#filenamePrefix")
    if l10nFilenamePrefix ~= nil then
        local l10nFilenamePrefixFull = Utils.getFilename(l10nFilenamePrefix, modDir)
        local l10nXmlFile = nil
        local _ = nil
        for _, lang in ipairs({ g_languageShort, "en", "de" }) do
            _ = l10nFilenamePrefixFull .. "_" .. lang .. ".xml"
            if fileExists(_) then
                l10nXmlFile = XMLFile.load("modL10n", _)
                break
            end
        end
        if l10nXmlFile == nil then
            printWarning(string.format("Warning: No l10n file(s) found for prefix %q\' (e.g. \'%sen.xml\') in mod %q", l10nFilenamePrefix, l10nFilenamePrefix, modName))
        else
            for _, lang in l10nXmlFile:iterator("l10n.texts.text") do
                local name = l10nXmlFile:getString(lang .. "#name")
                local text = l10nXmlFile:getString(lang .. "#text")
                if name ~= nil and text ~= nil then
                    if modEnv.g_i18n:hasModText(name) then
                        printWarning("Warning: Duplicate l10n entry \'" .. name .. "\' in \'" .. _ .. "\'. Ignoring this definition.")
                    else
                        modEnv.g_i18n:setText(name, text:gsub("\r\n", "\n"))
                    end
                end
            end
            for _, lang in l10nXmlFile:iterator("l10n.elements.e") do
                local name = l10nXmlFile:getString(lang .. "#k")
                local text = l10nXmlFile:getString(lang .. "#v")
                if name ~= nil and text ~= nil then
                    if modEnv.g_i18n:hasModText(name) then
                        printWarning("Warning: Duplicate l10n entry \'" .. name .. "\' in \'" .. _ .. "\'. Ignoring this definition.")
                    else
                        modEnv.g_i18n:setText(name, text:gsub("\r\n", "\n"))
                    end
                end
            end
            l10nXmlFile:delete()
        end
    end
    local l10nFilenamePrefixFull = settingsXML:getI18NValue("modDesc.title", "", modName, true)
    local l10nXmlFile = settingsXML:getI18NValue("modDesc.description", "", modName, true)
    local _ = settingsXML:getI18NValue("modDesc.iconFilename", "", modName, true)
    if l10nFilenamePrefixFull == "" then
        printError("Error: Missing title in mod " .. modName)
        settingsXML:delete()
        return
    elseif l10nXmlFile == "" then
        printError("Error: Missing description in mod " .. modName)
        settingsXML:delete()
        return
    else
        local baseName = settingsXML:getBool("modDesc.multiplayer#supported", false)
        local name = settingsXML:getBool("modDesc.multiplayer#only", false)
        if modFileHash == nil then
            if Platform.supportsMultiplayer and baseName then
                printWarning("Warning: Only zip mods are supported in multiplayer. You need to zip the mod " .. modName .. " to use it in multiplayer.")
            end
        end
        if baseName or not name then
            if baseName and _ == "" then
                printError("Error: Missing icon filename in mod " .. modName)
                settingsXML:delete()
            else
                for lang, name in settingsXML:iterator("modDesc.maps.map") do
                    g_mapManager:loadMapFromXML(settingsXML, name, modDir, modName, baseName, isDLCFile, true, isInternalMod)
                end
                local text = settingsXML:getI18NValue("modDesc.author", "", modName, true)
                if isDLCFile then
                    local dlcProductId = settingsXML:getString("modDesc.productId")
                    if dlcProductId == nil or modVersion == nil then
                        printError("Error: invalid product id or version in DLC " .. modName)
                    else
                        addNotificationFilter(dlcProductId, modVersion)
                    end
                end
                local dlcProductId = settingsXML:hasProperty("modDesc.extraSourceFiles.sourceFile(0)") or settingsXML:hasProperty("modDesc.specializations.specialization(0)")
                local _ = nil
                if settingsXML:hasProperty("modDesc.dependencies.dependency(0)") then
                    for index, key in settingsXML:iterator("modDesc.dependencies.dependency") do
                        local name = settingsXML:getString(key)
                        if string.isNilOrWhitespace(name) then
                            printWarning(string.format("Warning: mod %q has empty dependency at %q", modName, key))
                        elseif string.endsWith(name, ".zip") then
                            printWarning(string.format("Warning: mod %q dependency %q at %q should not include \'.zip\' in its name", modName, name, key))
                        elseif not table.addElement({}, name) then
                            printWarning(string.format("Warning: mod %q has duplicate dependency %q at %q", modName, name, key))
                        end
                    end
                end
                local lang = settingsXML:getString("modDesc.uniqueType")
                for key, name in settingsXML:iterator("modDesc.extraContent.key") do
                    local key = settingsXML:getString(name)
                    if key ~= nil then
                        local item, errorCode = g_extraContentSystem:unlockItem(key, true)
                        if item ~= nil and errorCode == ExtraContentSystem.UNLOCKED then
                            print("ExtraContent: Unlocked \'" .. item.id .. "\'")
                            g_extraContentSystem:saveToProfile()
                        end
                    end
                end
                if isInternalMod then
                    g_currentModDirectory = modDir
                    g_currentModName = modName
                    for key, name in settingsXML:iterator("modDesc.preLoadSourceFiles.sourceFile") do
                        local key = settingsXML:getString(name .. "#filename")
                        if key ~= nil then
                            modEnv.source(modDir .. key, modName)
                        end
                    end
                    g_currentModDirectory = nil
                    g_currentModName = nil
                end
                local name = Utils.getFilename(_, modDir)
                g_modManager:addMod(l10nFilenamePrefixFull, l10nXmlFile, modVersion, revisionStr, text, name, modName, modDir, modFile, baseName, modFileHash, absBaseFilename, isDirectory, isDLCFile, dlcProductId, _, name, requiredModName, lang, getIsInternalScriptMod(modName))
                settingsXML:delete()
            end
        else
            printError("Error: Both multiplayer and singleplayer are unsupported in mod " .. modName)
            settingsXML:delete()
            return
        end
    end
end
function resetModOnCreateFunctions()
    modOnCreate = {}
end
function loadMod(modName, modDir, modFile, modTitle)
    -- upvalues: (copy) getIsInternalScriptMod, (copy) getIsInternalMod
    if g_modIsLoaded[modName] then
        return
    else
        g_modIsLoaded[modName] = true
        g_modNameToDirectory[modName] = modDir
        local modEnv = _G[modName]
        if modEnv ~= nil then
            local xmlFile = XMLFile.load("ModFile", modFile, g_modDescSchema)
            local isDLCFile = string.endsWith(modFile, "dlcDesc.xml") and true or false
            if isDLCFile then
                print("  Load dlc: " .. modName)
            else
                print("  Load mod: " .. modName)
            end
            local allowScripts = not GS_IS_CONSOLE_VERSION or (isDLCFile or g_isDevelopmentConsoleScriptModTesting) or (getIsInternalScriptMod(modName) or getIsInternalMod(modName))
            g_currentModDirectory = modDir
            g_currentModName = modName
            if g_modSettingsDirectory ~= nil then
                g_currentModSettingsDirectory = g_modSettingsDirectory .. modName .. "/"
            end
            if allowScripts then
                for _, key in xmlFile:iterator("modDesc.extraSourceFiles.sourceFile") do
                    local filename = xmlFile:getString(key .. "#filename")
                    if filename ~= nil then
                        modEnv.source(modDir .. filename, modName)
                    end
                end
            end
            for _, key in xmlFile:iterator("modDesc.brands.brand") do
                local filename = xmlFile:getString(key .. "#name")
                local title = xmlFile:getString(key .. "#title")
                local image = xmlFile:getString(key .. "#image")
                local offset = xmlFile:getFloat(key .. "#imageOffset")
                g_brandManager:addBrand(filename, title, image, modDir, true, nil, offset)
            end
            for _, key in xmlFile:iterator("modDesc.helpLines.category") do
                g_helpLineManager:addModCategory(xmlFile, key, modDir, modName)
            end
            if isDLCFile then
                for _, key in xmlFile:iterator("modDesc.storeCategories.storeCategory") do
                    g_storeManager:loadCategoryFromXML(xmlFile, key, modDir, modName, true)
                end
            end
            for _, key in xmlFile:iterator("modDesc.specializations.specialization") do
                local filename = xmlFile:getString(key .. "#name")
                local title = xmlFile:getString(key .. "#className")
                local image = xmlFile:getString(key .. "#filename")
                if filename ~= nil and (title ~= nil and image ~= nil) then
                    local image = modDir .. image
                    if allowScripts then
                        modEnv.g_specializationManager:addSpecialization(filename, title, image, modName)
                    else
                        printError("Error: Can\'t register specialization " .. filename .. " with scripts on consoles.")
                    end
                end
            end
            for _, key in xmlFile:iterator("modDesc.vehicleTypes.type") do
                g_vehicleTypeManager:loadTypeFromXML(xmlFile.handle, key, isDLCFile, modDir, modName)
            end
            for _, key in xmlFile:iterator("modDesc.placeableSpecializations.specialization") do
                local filename = xmlFile:getString(key .. "#name")
                local title = xmlFile:getString(key .. "#className")
                local image = xmlFile:getString(key .. "#filename")
                if filename ~= nil and (title ~= nil and image ~= nil) then
                    local image = modDir .. image
                    if allowScripts then
                        modEnv.g_placeableSpecializationManager:addSpecialization(filename, title, image, modName)
                    else
                        printError("Error: Can\'t register placeable specialization " .. filename .. " with scripts on consoles.")
                    end
                end
            end
            for _, key in xmlFile:iterator("modDesc.placeableTypes.type") do
                g_placeableTypeManager:loadTypeFromXML(xmlFile.handle, key, isDLCFile, modDir, modName)
            end
            for _, key in xmlFile:iterator("modDesc.handToolSpecializations.specialization") do
                local filename = xmlFile:getString(key .. "#name")
                local title = xmlFile:getString(key .. "#className")
                local image = xmlFile:getString(key .. "#filename")
                if filename ~= nil and (title ~= nil and image ~= nil) then
                    local image = modDir .. image
                    if allowScripts then
                        modEnv.g_handToolSpecializationManager:addSpecialization(filename, title, image, modName)
                    else
                        printError("Error: Can\'t register handTool specialization " .. filename .. " with scripts on consoles.")
                    end
                end
            end
            for _, key in xmlFile:iterator("modDesc.handToolTypes.type") do
                g_handToolTypeManager:loadTypeFromXML(xmlFile.handle, key, isDLCFile, modDir, modName)
            end
            for _, key in xmlFile:iterator("modDesc.bales.bale") do
                g_baleManager:loadModBaleFromXML(xmlFile, key, modDir, modName)
            end
            for _, key in xmlFile:iterator("modDesc.jointTypes.jointType") do
                local filename = xmlFile:getString(key .. "#name")
                if filename ~= nil then
                    AttacherJoints.registerJointType(filename)
                end
            end
            for _, key in xmlFile:iterator("modDesc.materialHolders.materialHolder") do
                local filename = xmlFile:getString(key .. "#filename")
                if filename ~= nil then
                    local title = Utils.getFilename(filename, g_currentModDirectory)
                    g_materialManager:addModMaterialHolder(title)
                end
            end
            g_vehicleMaterialManager:addModMaterialTemplatesToLoad(modFile, "modDesc.materialTemplates", g_currentModDirectory, modName)
            for _, key in xmlFile:iterator("modDesc.connectionHoses.connectionHose") do
                local filename = xmlFile:getString(key .. "#xmlFilename")
                if filename ~= nil then
                    local title = Utils.getFilename(filename, g_currentModDirectory)
                    g_connectionHoseManager:addModConnectionHoses(title, modName, g_currentModDirectory)
                end
            end
            for _, key in xmlFile:iterator("modDesc.consumables.consumable") do
                local filename = xmlFile:getString(key .. "#xmlFilename")
                if filename ~= nil then
                    local title = Utils.getFilename(filename, g_currentModDirectory)
                    g_consumableManager:addModConsumable(title, modName, g_currentModDirectory)
                end
            end
            for _, key in xmlFile:iterator("modDesc.storeItems.storeItem") do
                local filename = xmlFile:getString(key .. "#xmlFilename")
                if filename ~= nil then
                    g_storeManager:addModStoreItem(filename, modDir, modName, not isDLCFile, false, modTitle)
                end
            end
            for _, key in xmlFile:iterator("modDesc.storePacks.storePack") do
                local filename = xmlFile:getString(key .. "#name")
                local title = xmlFile:getString(key .. "#title")
                local image = xmlFile:getString(key .. "#image")
                if title ~= nil and title:sub(1, 6) == "$l10n_" then
                    title = g_i18n:getText(title:sub(7))
                end
                local offset = {}
                for _, storeItemKey in xmlFile:iterator(key .. ".storeItem") do
                    local xmlFilename = xmlFile:getString(storeItemKey)
                    local fullXmlFilename = Utils.getFilename(xmlFilename, g_currentModDirectory)
                    if fileExists(fullXmlFilename) then
                        table.insert(offset, fullXmlFilename)
                    else
                        Logging.xmlWarning(xmlFile, "StoreItem \'%s\' not found for storepack \'%s\'", xmlFilename, filename)
                    end
                end
                g_storeManager:addModStorePack(filename, title, image, modDir, offset)
            end
            local defaultIconFilename = xmlFile:getString("modDesc.constructionCategories#defaultIconFilename")
            local defaultRefSize = xmlFile:getVector("modDesc.constructionCategories#refSize", nil, 2) or { 1024, 1024 }
            for filename, title in xmlFile:iterator("modDesc.constructionCategories.tab") do
                local image = xmlFile:getString(title .. "#categoryName")
                local offset = xmlFile:getString(title .. "#name")
                local tabTitle = g_i18n:convertText(xmlFile:getString(title .. "#title"), modName)
                local tabIconFilename = xmlFile:getString(title .. "#iconFilename") or defaultIconFilename
                local tabRefSize = xmlFile:getVector(title .. "#refSize", defaultRefSize, 2)
                local storeItemKey = xmlFile:getString(title .. "#iconSliceId")
                g_storeManager:addModConstructionTab(image, offset, tabTitle, tabIconFilename, tabRefSize, GuiUtils.getUVs(xmlFile:getString(title .. "#iconUVs", "0 0 1 1"), tabRefSize), g_currentModDirectory, storeItemKey)
            end
            local fillTypesFilename = xmlFile:getString("modDesc.fillTypes#filename")
            if fillTypesFilename ~= nil then
                local _, key = Utils.getFilename(fillTypesFilename, g_currentModDirectory)
                g_fillTypeManager:addModWithFillTypes(_, g_currentModDirectory, modName)
            end
            local _ = xmlFile:getString("modDesc.densityMapHeightTypes#filename")
            if _ ~= nil then
                local key = Utils.getFilename(_, g_currentModDirectory)
                g_densityMapHeightManager:addModDensityMapHeightTypes(key)
            end
            local key = xmlFile:getString("modDesc.motionPathEffects#filename")
            if key ~= nil then
                local filename = Utils.getFilename(key, g_currentModDirectory)
                g_motionPathEffectManager:loadModMotionPathEffects(filename, g_currentModDirectory, modName)
            end
            if isDLCFile then
                for offset, tabTitle in xmlFile:iterator("modDesc.foliageTypes.foliageType") do
                    local tabIconFilename = xmlFile:getString(tabTitle .. "#name")
                    local tabRefSize = xmlFile:getString(tabTitle .. "#filename")
                    if tabIconFilename ~= nil and tabRefSize ~= nil then
                        g_fruitTypeManager:addModFoliageType(tabIconFilename, (Utils.getFilename(tabRefSize, g_currentModDirectory)))
                    end
                end
            end
            local filename = xmlFile:getString("modDesc.missionVehicles#filename")
            if filename ~= nil then
                local title = Utils.getFilename(filename, g_currentModDirectory)
                g_missionManager:addPendingMissionVehiclesFile(title, g_currentModDirectory)
            end
            for tabTitle, tabIconFilename in xmlFile:iterator("modDesc.wildlife.species") do
                local tabRefSize = xmlFile:getString(tabIconFilename .. "#filename")
                g_wildlifeManager:registerModWildlifeFile(tabRefSize, g_currentModDirectory, (string.split(xmlFile:getString(tabIconFilename .. "#groups") or "", " ")))
            end
            xmlFile:delete()
            g_currentModDirectory = nil
            g_currentModName = nil
        end
    end
end
function reloadDlcsAndMods()
    -- upvalues: (ref) isReloadingDlcs
    if g_currentMission == nil then
        local i = g_mapManager:getNumOfMaps()
        local startedRepeat = 1
        for i = i, startedRepeat, -1 do
            if g_mapManager:getMapDataByIndex(i).isModMap then
                g_mapManager:removeMapItem(i)
            end
        end
        while g_modManager:getNumOfMods() > 0 do
            g_modManager:removeMod(g_modManager:getModByIndex(1))
        end
        g_modIsLoaded = {}
        g_modNameToDirectory = {}
        g_dlcModNameHasPrefix = {}
        g_globalMods = {}
        isReloadingDlcs = true
        startUpdatePendingMods()
        loadDlcsDirectories()
        loadDlcs()
        if isModUpdateRunning() then
            local startedRepeat = startFrameRepeatMode()
            while isModUpdateRunning() do
                usleep(16000)
            end
            if startedRepeat then
                endFrameRepeatMode()
            end
        end
        if Platform.supportsMods then
            loadAllMods()
        end
        g_inputBinding:reloadModActions()
        isReloadingDlcs = false
    else
        print("Dlc reloading is not supported during gameplay")
    end
end
function verifyDlcs()
    local missingMods = {}
    for _, mod in ipairs(g_modManager:getMods()) do
        if not fileExists(mod.modFile) then
            table.insert(missingMods, mod)
        end
    end
    return #missingMods == 0, missingMods
end
function checkForNewDlcs()
    if not Platform.isXbox then
        return true
    end
    local hasNewPaths = false
    local newDlcPaths = {}
    local i = 0
    for i = i, getNumDlcPaths() - 1 do
        local path = getDlcPath(i)
        if path ~= nil then
            newDlcPaths[path] = true
            if g_lastCheckDlcPaths[path] == nil then
                hasNewPaths = true
            end
        end
    end
    g_lastCheckDlcPaths = newDlcPaths
    return hasNewPaths
end
checkForNewDlcs()
function loadDlcsDirectories()
    g_dlcsDirectories = {}
    local numDlcPaths = getNumDlcPaths()
    local i = 0
    for i = i, numDlcPaths - 1 do
        local path = getDlcPath(i)
        if path == nil then
            if Platform.verboseDLCLoading then
                Logging.error("Could not retrieve dlc path %d of %d", i + 1, numDlcPaths)
            end
        else
            table.insert(g_dlcsDirectories, {
                ["path"] = path,
                ["isLoaded"] = true
            })
            if path == getAppBasePath() .. "pdlc/" then
                table.insert(g_dlcsDirectories, {
                    ["path"] = "pdlc/",
                    ["isLoaded"] = false
                })
            end
        end
    end
end
loadDlcsDirectories()
function addModEventListener(listener)
    table.insert(g_modEventListeners, listener)
end
function removeModEventListener(listener)
    for i, listenerI in ipairs(g_modEventListeners) do
        if listenerI == listener then
            table.remove(g_modEventListeners, i)
            return
        end
    end
end
function createModDescSchema()
    local schema = XMLSchema.new("modDesc")
    schema:register(XMLValueType.INT, "modDesc#descVersion", "Version of the modDesc, can be used to enforce a specific game version or patch level for a mod to load", nil, true)
    schema:register(XMLValueType.STRING, "modDesc.author", "Author(s) of the mod", nil, true)
    schema:register(XMLValueType.STRING, "modDesc.version", "Version number of the mod, format \'a.b.c.d\'", nil, true)
    schema:register(XMLValueType.BOOL, "modDesc.isSelectable", "If the mod is selectable in the mod selection screen", true, false)
    schema:register(XMLValueType.STRING, "modDesc.uniqueType", "A unique type of the mod. Only one mod of this type may be selected", nil, false)
    local numLangs = getNumOfLanguages()
    local i = 0
    for i = i, numLangs - 1 do
        local langName = getLanguageCode(i)
        schema:register(XMLValueType.STRING, string.format("modDesc.title.%s", langName), "localized title", nil, false)
        schema:register(XMLValueType.STRING, string.format("modDesc.description.%s", langName), "localized description", nil, false)
    end
    schema:register(XMLValueType.STRING, "modDesc.l10n#filenamePrefix", "prefix for external loca file. Supported xml format: l10n.texts.text#name + l10n.texts.text#text or l10n.elements.e#k + l10n.elements.e#v")
    local i = 0
    for i = i, numLangs - 1 do
        local langName = getLanguageCode(i)
        schema:register(XMLValueType.STRING, "modDesc.l10n.text(?)#name", "loca entry name/key", nil, false)
        schema:register(XMLValueType.STRING, string.format("modDesc.l10n.text(?).%s", langName), "localized text", nil, false)
    end
    schema:register(XMLValueType.FILENAME, "modDesc.iconFilename", "Path to the icon used for the whole mod", nil, true)
    schema:register(XMLValueType.FILENAME, "modDesc.storeItems.storeItem(?)#xmlFilename", "Path to xml file of a individual store item", nil, false)
    schema:register(XMLValueType.BOOL, "modDesc.multiplayer#supported", "Mod supports multiplayer", false, false)
    schema:register(XMLValueType.BOOL, "modDesc.multiplayer#only", "Mod is only available for multiplayer games", false, false)
    schema:register(XMLValueType.FILENAME, "modDesc.wildlife.species(?)#filename", "Mods wildlife species xml path", false, false)
    schema:register(XMLValueType.STRING, "modDesc.extraSourceFiles.sourceFile(?)#filename", "additional lua file to source", nil, false)
    SpecializationManager.registerXMLPaths(schema, "modDesc.specializations.specialization(?)")
    SpecializationManager.registerXMLPaths(schema, "modDesc.placeableSpecializations.specialization(?)")
    SpecializationManager.registerXMLPaths(schema, "modDesc.handToolSpecializations.specialization(?)")
    schema:register(XMLValueType.FILENAME, "modDesc.bales.bale(?)#filename")
    schema:register(XMLValueType.FILENAME, "modDesc.jointTypes.jointType(?)#name")
    schema:register(XMLValueType.FILENAME, "modDesc.materialHolders.materialHolder(?)#filename")
    schema:register(XMLValueType.STRING, "modDesc.maps.map(?)#id", "map id", nil, false)
    schema:register(XMLValueType.STRING, "modDesc.maps.map(?)#className", "name of the lua class to initialize for this map", nil, false)
    schema:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#filename", "path to the lua file to source/load for this map", nil, false)
    schema:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#configFilename", "path to the xml config file", nil, false)
    schema:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#defaultVehiclesXMLFilename", "path to default vehicle xml config file", nil, false)
    schema:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#defaultHandToolsXMLFilename", "path to default handtool xml config file", nil, false)
    schema:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#defaultPlaceablesXMLFilename", "path to default placeable xml config file", nil, false)
    schema:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#defaultItemsXMLFilename", "path to default items xml config file", nil, false)
    schema:register(XMLValueType.FILENAME, "modDesc.maps.map(?).iconFilename", "path to map icon file", nil, false)
    local i = 0
    for i = i, numLangs - 1 do
        local langName = getLanguageCode(i)
        schema:register(XMLValueType.STRING, string.format("modDesc.maps.map(?).title.%s", langName), "localized title", nil, false)
        schema:register(XMLValueType.STRING, string.format("modDesc.maps.map(?).description.%s", langName), "localized description", nil, false)
    end
    TypeManager.registerTypeXMLPath(schema, "modDesc.vehicleTypes.type(?)")
    TypeManager.registerTypeXMLPath(schema, "modDesc.placeableTypes.type(?)")
    TypeManager.registerTypeXMLPath(schema, "modDesc.handToolTypes.type(?)")
    schema:register(XMLValueType.STRING, "modDesc.brands.brand(?)#name")
    schema:register(XMLValueType.STRING, "modDesc.brands.brand(?)#title")
    schema:register(XMLValueType.FILENAME, "modDesc.brands.brand(?)#image")
    schema:register(XMLValueType.FLOAT, "modDesc.brands.brand(?)#imageOffset")
    schema:register(XMLValueType.FILENAME, "modDesc.connectionHoses.connectionHose(?)#xmlFilename")
    schema:register(XMLValueType.FILENAME, "modDesc.consumables.consumable(?)#xmlFilename")
    schema:register(XMLValueType.FILENAME, "modDesc.fillTypes#filename", "file path to additional fillTypes xml file", nil, false)
    schema:register(XMLValueType.FILENAME, "modDesc.missionVehicles#filename", "file path to mission vehicles xml file for he included", nil, false)
    schema:register(XMLValueType.FILENAME, "modDesc.densityMapHeightTypes#filename")
    HelpLineManager.registerCategoryXMLPaths(schema, "modDesc.helpLines.category(?)")
    VehicleMaterialManager.registerXMLPaths(schema, "modDesc.materialTemplates")
    schema:register(XMLValueType.STRING, "modDesc.actions.action(?)#name")
    schema:register(XMLValueType.STRING, "modDesc.actions.action(?)#category")
    schema:register(XMLValueType.STRING, "modDesc.actions.action(?)#displayCategory")
    schema:register(XMLValueType.STRING, "modDesc.actions.action(?)#axisType")
    schema:register(XMLValueType.BOOL, "modDesc.actions.action(?)#ignoreComboMask")
    schema:register(XMLValueType.STRING, "modDesc.inputBinding.actionBinding(?)#action")
    schema:register(XMLValueType.STRING, "modDesc.inputBinding.actionBinding(?).binding(?)#device")
    schema:register(XMLValueType.STRING, "modDesc.inputBinding.actionBinding(?).binding(?)#input")
    schema:register(XMLValueType.STRING, "modDesc.inputBinding.actionBinding(?).binding(?)#axisComponent")
    schema:register(XMLValueType.STRING, "modDesc.inputBinding.actionBinding(?).binding(?)#inputComponent")
    schema:register(XMLValueType.INT, "modDesc.inputBinding.actionBinding(?).binding(?)#neutralInput")
    schema:register(XMLValueType.INT, "modDesc.inputBinding.actionBinding(?).binding(?)#index")
    schema:register(XMLValueType.STRING, "modDesc.dependencies.dependency(?)", "filename of the mod (without \'.zip\') to be installed for this mod to be used")
    StoreManager.registerStoreCategoriesXMLPaths(schema, "modDesc.storeCategories.storeCategory(?)")
    return schema
end