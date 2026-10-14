AudioGroup = {}
AudioGroup.groups = {}
function AudioGroup.getAudioGroupIndexByName(name)
    if name == nil then
        return nil
    end
    name = string.upper(name)
    return AudioGroup[name]
end
function AudioGroup.getAudioGroupNameByIndex(index)
    if index ~= nil then
        for name, id in pairs(AudioGroup) do
            if index == id then
                return name
            end
        end
    end
    return nil
end
function AudioGroup.getIsValidAudioGroup(audioGroupIndex)
    for _, index in pairs(AudioGroup) do
        if index == audioGroupIndex then
            return true
        end
    end
    return false
end
function AudioGroup.addGroup(name, id)
    local found = string.upper(name)
    if AudioGroup[found] ~= nil then
        Logging.error("AudioGroup \'%s\' already defined!", found)
        return
    end
    local found = false
    for k, v in pairs(AudioGroup) do
        if v == id then
            found = true
            break
        end
    end
    if found then
        Logging.error("AudioGroup id \'%d\' already defined", id)
    else
        AudioGroup[found] = id
        table.insert(AudioGroup.groups, AudioGroup[found])
    end
end
function AudioGroup.getNextId()
    local nextFreeId = -1
    for _, index in pairs(AudioGroup.groups) do
        nextFreeId = math.max(index + 1, nextFreeId)
    end
    if nextFreeId == -1 or nextFreeId > 255 then
        return nil
    else
        return nextFreeId
    end
end
function AudioGroup.loadGroups()
    local xmlFile = loadXMLFile("AudioGroups", "shared/audioGroups.xml")
    if xmlFile == 0 then
        Logging.error("Failed to load audio groups!")
        return
    end
    local i = 0
    while true do
        local key = string.format("audioGroups.audioGroup(%d)", i)
        if not hasXMLProperty(xmlFile, key) then
            delete(xmlFile)
            return
        end
        local id = getXMLInt(xmlFile, key .. "#id")
        local name = getXMLString(xmlFile, key .. "#name")
        if id == nil then
            Logging.xmlError(xmlFile, "Missing id for audio group \'%s\'!", key)
        elseif name == nil then
            Logging.xmlError(xmlFile, "Missing name for audio group \'%s\'!", key)
        else
            local found = string.upper(name)
            if AudioGroup[found] == nil then
                local found = false
                for k, v in pairs(AudioGroup) do
                    if v == id then
                        found = true
                        break
                    end
                end
                if found then
                    Logging.xmlError(xmlFile, "AudioGroup id \'%d\' already defined in \'%s\'!", id, key)
                else
                    AudioGroup[found] = id
                    table.insert(AudioGroup.groups, AudioGroup[found])
                end
            else
                Logging.xmlError(xmlFile, "AudioGroup \'%s\' already defined in \'%s\'!", found, key)
            end
        end
        i = i + 1
    end
end