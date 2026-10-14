ModManager = {}
local ModManager_mt = Class(ModManager, AbstractManager)
function ModManager.new(customMt)
    -- upvalues: (copy) ModManager_mt
    return AbstractManager.new(customMt or ModManager_mt)
end
function ModManager:initDataStructures()
    self.hashToMod = {}
    self.nameToMod = {}
    self.titleToMod = {}
    self.validMods = {}
    self.multiplayerMods = {}
    self.mods = {}
    self.numMods = 0
end
function ModManager:addMod(title, description, version, modDescVersion, author, iconFilename, modName, modDir, modFile, isMultiplayerSupported, fileHash, absBaseFilename, isDirectory, isDLC, hasScripts, dependencies, multiplayerOnly, isSelectable, uniqueType, isInternalScriptMod)
    if fileHash ~= nil and self.hashToMod[fileHash] ~= nil then
        printError("Error: Adding mod with same file hash twice. Title is " .. title .. " filehash: " .. fileHash)
        return nil
    end
    self.numMods = self.numMods + 1
    local mod = {
        ["id"] = self.numMods,
        ["title"] = title,
        ["description"] = description,
        ["version"] = version,
        ["modDescVersion"] = modDescVersion,
        ["author"] = author,
        ["iconFilename"] = iconFilename,
        ["isDLC"] = isDLC
    }
    mod.isFreeDLC = isInternalScriptMod and author == "GIANTS Software"
    mod.fileHash = fileHash
    mod.modName = modName
    mod.modDir = modDir
    mod.modFile = modFile
    mod.absBaseFilename = absBaseFilename
    mod.isDirectory = isDirectory
    mod.isMultiplayerSupported = isMultiplayerSupported
    mod.isSelectable = isSelectable
    mod.hasScripts = hasScripts
    mod.isInternalScriptMod = isInternalScriptMod
    mod.dependencies = dependencies
    mod.multiplayerOnly = multiplayerOnly
    mod.uniqueType = uniqueType
    table.insert(self.mods, mod)
    self.nameToMod[modName] = mod
    self.titleToMod[title] = mod
    if fileHash ~= nil then
        table.insert(self.validMods, mod)
        self.hashToMod[fileHash] = mod
        if isMultiplayerSupported then
            table.insert(self.multiplayerMods, mod)
        end
    end
    return mod
end
function ModManager:removeMod(mod)
    if mod == nil then
        return false
    end
    self.nameToMod[mod.modName] = nil
    if mod.fileHash ~= nil then
        self.hashToMod[mod.fileHash] = nil
    end
    for index, modItem in ipairs(self.mods) do
        if modItem == mod then
            table.remove(self.mods, index)
            break
        end
    end
    for index, modItem in ipairs(self.validMods) do
        if modItem == mod then
            table.remove(self.validMods, index)
            break
        end
    end
    for index, modItem in ipairs(self.multiplayerMods) do
        if modItem == mod then
            table.remove(self.multiplayerMods, index)
            break
        end
    end
    return true
end
function ModManager:getModByFileHash(fileHash)
    return self.hashToMod[fileHash]
end
function ModManager:getModByName(modName)
    return self.nameToMod[modName]
end
function ModManager:getModByTitle(modName)
    return self.titleToMod[modName]
end
function ModManager:getModIconByName(modName)
    local mod = self.nameToMod[modName]
    if mod == nil then
        return nil
    else
        return mod.iconFilename
    end
end
function ModManager:getModByIndex(index)
    return self.mods[index]
end
function ModManager:getMods()
    return self.mods
end
function ModManager:getMultiplayerMods()
    return self.multiplayerMods
end
function ModManager:getActiveMods()
    local mods = {}
    for _, mod in ipairs(self.mods) do
        if g_modIsLoaded[mod.modName] then
            table.insert(mods, mod)
        end
    end
    return mods
end
function ModManager:getNumOfMods()
    return #self.mods
end
function ModManager:getHasSelectableMod()
    for _, modItem in ipairs(self.mods) do
        if modItem.isSelectable then
            return true
        end
    end
    return false
end
function ModManager:getNumOfValidMods()
    return #self.validMods
end
function ModManager:getHasSelectableValidMod()
    for _, modItem in ipairs(self.validMods) do
        if modItem.isSelectable then
            return true
        end
    end
    return false
end
function ModManager:getAreAllModsAvailable(modHashes)
    for _, modHash in pairs(modHashes) do
        if not self:getIsModAvailable(modHash) then
            return false
        end
    end
    return true
end
function ModManager:getIsModAvailable(modHash)
    local modItem = self.hashToMod[modHash]
    return modItem ~= nil and modItem.isMultiplayerSupported and true or false
end
function ModManager.isModMap(_, modName)
    for mapId, _ in pairs(g_mapManager.idToMap) do
        if g_mapManager:getModNameFromMapId(mapId) == modName then
            return true
        end
    end
    return false
end
g_modManager = ModManager.new()