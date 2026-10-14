ExtraContentSystem = {}
ExtraContentSystem.PROFILE_FILENAME = "extraContent.xml"
ExtraContentSystem.VALID_CHARS_STRING = "ABCDEFHJKLMNPQRSTWXYZ123456789"
ExtraContentSystem.VALID_CHARS_PATTERN = "[" .. ExtraContentSystem.VALID_CHARS_STRING .. "]"
ExtraContentSystem.VALID_CHARS_NOT_PATTERN = "[^" .. ExtraContentSystem.VALID_CHARS_STRING .. "]"
ExtraContentSystem.VALID_CHARS = string.split(ExtraContentSystem.VALID_CHARS_STRING, "")
ExtraContentSystem.KEY_LENGTH = 8
ExtraContentSystem.NUM_ITEM_CHARACTERS = 3
ExtraContentSystem.ITEM_INDEX_1 = 1
ExtraContentSystem.ITEM_INDEX_2 = 4
ExtraContentSystem.ITEM_INDEX_3 = 6
ExtraContentSystem.UNLOCKED = 0
ExtraContentSystem.ERROR_KEY_INVALID = 1
ExtraContentSystem.ERROR_ALREADY_UNLOCKED = 2
ExtraContentSystem.ERROR_KEY_INVALID_FORMAT = 3
local ExtraContentSystem_mt = Class(ExtraContentSystem)
function ExtraContentSystem.new(_, customMt)
    -- upvalues: (copy) ExtraContentSystem_mt
    local self = setmetatable({}, customMt or ExtraContentSystem_mt)
    self.items = {}
    self.idToItem = {}
    if g_isDevelopmentVersion then
        addConsoleCommand("gsExtraContentSystemCreateKeys", "Create keys for a given item code", "consoleCommandCreateKeys", self)
        addConsoleCommand("gsExtraContentSystemCreateKeysAll", "Create keys for all items", "consoleCommandCreateKeysAll", self)
        addConsoleCommand("gsExtraContentSystemUnlockAll", "Unlocks all items", "consoleCommandUnlockAll", self)
        return self
    end
    ExtraContentSystem.consoleCommandCreateKeys = nil
    ExtraContentSystem.consoleCommandCreateKeysAll = nil
    ExtraContentSystem.consoleCommandUnlockAll = nil
    ExtraContentSystem.createKeyItem = nil
    self.consoleCommandCreateKeys = nil
    self.consoleCommandCreateKeysAll = nil
    self.consoleCommandUnlockAll = nil
    self.createKeyItem = nil
    return self
end
function ExtraContentSystem:delete()
    self.items = {}
    self.idToItem = {}
    removeConsoleCommand("gsExtraContentSystemCreateKeys")
    removeConsoleCommand("gsExtraContentSystemCreateKeysAll")
    removeConsoleCommand("gsExtraContentSystemUnlockAll")
end
function ExtraContentSystem:loadFromXML(xmlFilename)
    local xmlFile = XMLFile.load("extraContentSystem", xmlFilename, nil)
    if xmlFile ~= nil then
        xmlFile:iterate("extraContent.item", function(_, itemKey)
            -- upvalues: (copy) xmlFile, (copy) self
            local id = xmlFile:getString(itemKey .. "#id")
            local code = xmlFile:getString(itemKey .. "#code")
            local title = xmlFile:getString(itemKey .. ".title")
            local description = xmlFile:getString(itemKey .. ".description")
            local imageFilename = xmlFile:getString(itemKey .. ".imageFilename")
            local isAutoUnlocked = xmlFile:getBool(itemKey .. "#isAutoUnlocked", false)
            if id == nil then
                Logging.xmlWarning(xmlFile, "Extra content item id is missing for \'%s\'", itemKey)
                return
            elseif code == nil then
                Logging.xmlWarning(xmlFile, "Extra content item code is missing for \'%s\'", itemKey)
                return
            else
                local isValid = string.upper(code)
                local isValid, invalidChar = self:getStringHasValidCharacters(isValid)
                if isValid then
                    local chars = string.split(isValid, "")
                    if #chars == ExtraContentSystem.NUM_ITEM_CHARACTERS then
                        if imageFilename == nil then
                            Logging.xmlWarning(xmlFile, "Extra content item imageFilename is missing for \'%s\'", itemKey)
                            return
                        elseif title == nil then
                            Logging.xmlWarning(xmlFile, "Extra content item title is missing for \'%s\'", itemKey)
                            return
                        elseif description == nil then
                            Logging.xmlWarning(xmlFile, "Extra content item description is missing for \'%s\'", itemKey)
                        else
                            self:addItem(id, g_i18n:convertText(title), g_i18n:convertText(description), imageFilename, chars, isAutoUnlocked)
                        end
                    else
                        Logging.xmlWarning(xmlFile, "Extra content item code needs to have %d characters for \'%s\'", ExtraContentSystem.NUM_ITEM_CHARACTERS, itemKey)
                        return
                    end
                else
                    Logging.xmlWarning(xmlFile, "Extra content item code contains invalid charater \'%s\' for \'%s\'!", invalidChar, itemKey)
                    return
                end
            end
        end)
        xmlFile:delete()
    end
end
function ExtraContentSystem:addItem(id, title, description, imageFilename, charList, isAutoUnlocked)
    if self.idToItem[id] ~= nil then
        Logging.warning("Extra content item with id \'%s\' already exists!", id)
        return
    end
    table.sort(charList, function(a, b)
        return a < b
    end)
    local code = table.concat(charList, "")
    local alreadyExists = true
    for _, existingItem in ipairs(self.items) do
        for k, existingChar in ipairs(existingItem.charList) do
            if existingChar ~= charList[k] then
                alreadyExists = false
                break
            end
        end
    end
    if #self.items > 0 and alreadyExists then
        Logging.warning("Extra content code for \'%s\' is already used!", id)
    else
        local item = {
            ["id"] = id,
            ["title"] = title,
            ["description"] = description,
            ["imageFilename"] = imageFilename,
            ["charList"] = charList,
            ["code"] = code,
            ["isAutoUnlocked"] = isAutoUnlocked,
            ["isUnlocked"] = false,
            ["unlockedByDLC"] = false
        }
        table.insert(self.items, item)
        self.idToItem[id] = item
    end
end
function ExtraContentSystem:loadFromProfile()
    local xmlFilename = getUserProfileAppPath() .. ExtraContentSystem.PROFILE_FILENAME
    if fileExists(xmlFilename) then
        local hasChanges = false
        local xmlFile = XMLFile.load("extraContentProfile", xmlFilename, nil)
        if xmlFile ~= nil then
            xmlFile:iterate("extraContent.usedKey", function(_, xmlKey)
                -- upvalues: (copy) xmlFile, (ref) hasChanges, (copy) self
                local usedKey = xmlFile:getString(xmlKey)
                local unlockedByDLC = xmlFile:getBool(xmlKey .. "#unlockedByDLC")
                if unlockedByDLC == nil then
                    hasChanges = true
                end
                if usedKey ~= nil and unlockedByDLC == false then
                    local item, _ = self:unlockItem(usedKey, unlockedByDLC)
                    if item ~= nil then
                        print("Extra Content: Unlocked \'" .. item.id .. "\'")
                    end
                end
            end)
            xmlFile:delete()
        end
        if hasChanges then
            self:saveToProfile()
        end
    end
end
function ExtraContentSystem:saveToProfile()
    local filename = getUserProfileAppPath() .. ExtraContentSystem.PROFILE_FILENAME
    local xmlFile = XMLFile.create("extraContentProfile", filename, "extraContent", nil)
    local i = 0
    for _, item in ipairs(self.items) do
        if item.isUnlocked and item.usedKey ~= nil then
            xmlFile:setString(string.format("extraContent.usedKey(%d)", i), item.usedKey)
            xmlFile:setBool(string.format("extraContent.usedKey(%d)#unlockedByDLC", i), Utils.getNoNil(item.unlockedByDLC, false))
            i = i + 1
        end
    end
    xmlFile:save()
    xmlFile:delete()
    syncProfileFiles()
end
function ExtraContentSystem:reset()
    for _, item in ipairs(self.items) do
        item.isUnlocked = false
        item.unlockedByDLC = false
        item.usedKey = nil
    end
end
function ExtraContentSystem:getItemByKey(key)
    if key == nil or utf8Strlen(key) ~= ExtraContentSystem.KEY_LENGTH then
        return nil, ExtraContentSystem.ERROR_KEY_INVALID_FORMAT
    else
        local isValid, _ = self:getStringHasValidCharacters(key)
        if isValid then
            local charList = string.split(key, "")
            if #charList == ExtraContentSystem.KEY_LENGTH then
                local itemChars = { charList[ExtraContentSystem.ITEM_INDEX_1], charList[ExtraContentSystem.ITEM_INDEX_2], charList[ExtraContentSystem.ITEM_INDEX_3] }
                table.sort(itemChars, function(a, b)
                    return a < b
                end)
                local foundItem = self:getItemByCode(itemChars)
                if foundItem == nil then
                    return nil, ExtraContentSystem.ERROR_KEY_INVALID
                elseif charList[ExtraContentSystem.KEY_LENGTH] == self:getChecksumChar(charList) then
                    return foundItem
                else
                    return nil, ExtraContentSystem.ERROR_KEY_INVALID
                end
            else
                return nil, ExtraContentSystem.ERROR_KEY_INVALID_FORMAT
            end
        else
            return nil, ExtraContentSystem.ERROR_KEY_INVALID
        end
    end
end
function ExtraContentSystem:getItemByCode(charList)
    for _, item in ipairs(self.items) do
        local found = true
        for k, char in ipairs(item.charList) do
            if char ~= charList[k] then
                found = false
                break
            end
        end
        if found then
            return item
        end
    end
    return nil
end
function ExtraContentSystem:unlockItem(key, unlockedByDLC)
    local item, errorCode = self:getItemByKey(key)
    if item == nil then
        return nil, errorCode
    end
    if item.isUnlocked then
        return item, ExtraContentSystem.ERROR_ALREADY_UNLOCKED
    end
    item.isUnlocked = true
    item.usedKey = key
    item.unlockedByDLC = unlockedByDLC
    self:saveToProfile()
    return item, ExtraContentSystem.UNLOCKED
end
function ExtraContentSystem:getIsItemIdUnlocked(id)
    local item = self.idToItem[id]
    if item ~= nil then
        return self:getIsItemUnlocked(item)
    end
    Logging.warning("ExtraContent item \'%s\' does not exist!", (tostring(id)))
    return false
end
function ExtraContentSystem.getIsItemUnlocked(_, item)
    if item == nil then
        return false
    else
        return item.isAutoUnlocked and true or item.isUnlocked
    end
end
function ExtraContentSystem:getUnlockedItems()
    local unlockedItems = {}
    for _, item in ipairs(self.items) do
        if self:getIsItemUnlocked(item) then
            table.insert(unlockedItems, item)
        end
    end
    return unlockedItems
end
function ExtraContentSystem:getHasLockedItems()
    for _, item in ipairs(self.items) do
        if not self:getIsItemUnlocked(item) then
            return true
        end
    end
    return false
end
function ExtraContentSystem.getStringHasValidCharacters(_, text)
    local res = text:match(ExtraContentSystem.VALID_CHARS_NOT_PATTERN)
    return res ~= nil, res
end
function ExtraContentSystem.getChecksumChar(_, charList)
    local sum = 0
    local char = ExtraContentSystem.KEY_LENGTH - 1
    for i = 1, char do
        sum = sum + string.byte(charList[1])
    end
    local sum = sum % #ExtraContentSystem.VALID_CHARS + 1
    return ExtraContentSystem.VALID_CHARS[sum]
end
function ExtraContentSystem:consoleCommandUnlockAll()
    for _, item in ipairs(self.items) do
        self:unlockItem((self:createItemKey(item, (table.copyIndex(item.charList)))))
    end
end
function ExtraContentSystem:consoleCommandCreateKeysAll(numKeys)
    numKeys = tonumber(numKeys) or 1
    setFileLogPrefixTimestamp(false)
    for _, item in ipairs(self.items) do
        print(string.format("Generating keys for item \'%s\':", g_i18n:convertText(item.title)))
        local itemChars = table.copyIndex(item.charList)
        while numKeys > 0 do
            local key = self:createItemKey(item, itemChars)
            if key == nil then
                return
            end
            if ({})[key] == nil then
                print("    " .. key)
                generatedKeys[key] = true
                numKeys = numKeys - 1
            end
        end
    end
    setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
    return "Finished"
end
function ExtraContentSystem:consoleCommandCreateKeys(itemCode, numKeys, file)
    numKeys = tonumber(numKeys) or 1
    if itemCode == nil then
        return "Invalid item code"
    end
    local generatedKeys = {}
    if file ~= nil then
        local xmlFile = XMLFile.load("keys", file)
        if xmlFile == nil then
            return "Could not load given existing key file"
        end
        local i = 0
        xmlFile:iterate("keys.key", function(_, key)
            -- upvalues: (copy) xmlFile, (copy) generatedKeys, (ref) i
            local value = xmlFile:getString(key)
            if value ~= nil then
                generatedKeys[string.trim(value)] = true
            end
        end)
        print(string.format("Loaded %d existing keys from file...", i))
    end
    local xmlFile = string.upper(itemCode)
    local xmlFile, i = self:getStringHasValidCharacters(xmlFile)
    if not xmlFile then
        return "Invalid item code"
    end
    local itemChars = string.split(xmlFile, "")
    if #itemChars ~= ExtraContentSystem.NUM_ITEM_CHARACTERS then
        return "Invalid item code"
    end
    table.sort(itemChars, function(a, b)
        return a < b
    end)
    local foundItem = self:getItemByCode(itemChars)
    if foundItem == nil then
        return "Item not found in extra content system"
    end
    setFileLogPrefixTimestamp(false)
    print(string.format("Generating keys for item \'%s\':", g_i18n:convertText(foundItem.title)))
    while numKeys > 0 do
        local key = self:createItemKey(foundItem, itemChars)
        if key == nil then
            return
        end
        if generatedKeys[key] == nil then
            print("    " .. key)
            generatedKeys[key] = true
            numKeys = numKeys - 1
        end
    end
    setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
    return "Finished"
end
function ExtraContentSystem:createItemKey(item, itemChars)
    local keyChars = {}
    local key = 1
    for i = 1, ExtraContentSystem.KEY_LENGTH - ExtraContentSystem.NUM_ITEM_CHARACTERS - 1, key do
        local charIndex = math.random(1, #ExtraContentSystem.VALID_CHARS)
        table.insert(keyChars, ExtraContentSystem.VALID_CHARS[charIndex])
    end
    Utils.shuffle(itemChars)
    local charIndex = itemChars[1]
    table.insert(keyChars, ExtraContentSystem.ITEM_INDEX_1, charIndex)
    local charIndex = itemChars[2]
    table.insert(keyChars, ExtraContentSystem.ITEM_INDEX_2, charIndex)
    local charIndex = itemChars[3]
    table.insert(keyChars, ExtraContentSystem.ITEM_INDEX_3, charIndex)
    table.insert(keyChars, (self:getChecksumChar(keyChars)))
    local key = table.concat(keyChars, "")
    local i, charIndex = self:getItemByKey(key)
    if i ~= nil and item == i then
        return key
    end
    Logging.error("Created invalid product key (error code: %s) - %s", tostring(charIndex), key)
    return nil
end