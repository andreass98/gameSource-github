NPCUtil = {}
function NPCUtil.createFromXML(xmlFilename)
    local xmlFile = XMLFile.load("NPC", xmlFilename, NPC.xmlSchema)
    if xmlFile == nil then
        return nil
    end
    local requiredDLC = xmlFile:getString("npc#requiredDLC")
    if requiredDLC ~= nil and g_modIsLoaded[g_uniqueDlcNamePrefix .. requiredDLC] == nil then
        xmlFile:delete()
        return nil, true
    end
    local className = xmlFile:getValue("npc.class", "NPC")
    xmlFile:delete()
    local class = ClassUtil.getClassObject(className)
    if class == nil then
        Logging.xmlWarning(xmlFile, "NPC controller class \'%s\' not found!", className)
        return nil
    end
    local npc = class.new
    local npc = npc(g_server ~= nil, g_client ~= nil)
    if npc:load(xmlFilename) then
        return npc
    end
    npc:delete()
    return nil
end
function NPCUtil.createConversationFromXML(npc, xmlFilename, uniqueId)
    local xmlFile = XMLFile.load("NPCConversation", xmlFilename, NPCConversation.xmlSchema)
    if xmlFile == nil then
        return nil
    end
    local className = xmlFile:getValue("conversation.class", "NPCConversation")
    xmlFile:delete()
    local class = ClassUtil.getClassObject(className)
    if class == nil then
        Logging.xmlWarning(xmlFile, "NPC Conversation class \'%s\' not found!", className)
        return nil
    end
    local conversation = class.new(npc, uniqueId)
    if conversation:load(xmlFilename) then
        return conversation
    end
    Logging.warning("Could not load NPC conversation \'%s\'!", xmlFilename)
    conversation:delete()
    return nil
end
function NPCUtil.createTextFromPath(path, isOption, isActive)
    local xmlFile = XMLFile.load("NPCText", path .. "_en.xml", NPCText.xmlSchema)
    if xmlFile == nil then
        return nil
    end
    xmlFile:delete()
    local text = NPCText.new(isActive)
    text:load(path, isOption)
    return text
end
function NPCUtil.loadActionsFromXMLFile(xmlFile, key, conversation, baseDirectory, customEnvironment)
    local actions = nil
    local actionClasses = g_npcManager:getAllConverationActionClasses()
    for name, actionClass in pairs(actionClasses) do
        for _, actionKey in xmlFile:iterator(key .. ".actions." .. name) do
            local action = actionClass.createFromXML(xmlFile, actionKey, conversation, baseDirectory, customEnvironment)
            if action == nil then
                Logging.xmlWarning(xmlFile, "Could not create conversation action in \'%s\'", actionKey)
            else
                actions = actions == nil and {} or actions
                table.insert(actions, action)
            end
        end
    end
    return actions
end
function NPCUtil.loadInputsFromXMLFile(xmlFile, key, conversation, baseDirectory, customEnvironment)
    local inputs = nil
    local inputClasses = g_npcManager:getAllConverationInputClasses()
    for name, inputClass in pairs(inputClasses) do
        for _, inputKey in xmlFile:iterator(key .. ".inputs." .. name) do
            local input = inputClass.createFromXML(xmlFile, inputKey, conversation, baseDirectory, customEnvironment)
            if input == nil then
                Logging.xmlWarning(xmlFile, "Could not create conversation input in \'%s\'", inputKey)
            else
                inputs = inputs == nil and {} or inputs
                table.insert(inputs, input)
            end
        end
    end
    return inputs
end
function NPCUtil.loadOptionPrerequisitesFromXMLFile(xmlFile, key, conversation, baseDirectory, customEnvironment)
    local prerequisites = nil
    local optionPrerequisiteClasses = g_npcManager:getAllConverationOptionPrerequisiteClasses()
    for name, class in pairs(optionPrerequisiteClasses) do
        for _, prerequisiteKey in xmlFile:iterator(key .. ".prerequisites." .. name) do
            local prerequisite = class.createFromXML(xmlFile, prerequisiteKey, conversation, baseDirectory, customEnvironment)
            if prerequisite == nil then
                Logging.xmlWarning(xmlFile, "Could not create conversation option prerequisite in \'%s\'", prerequisiteKey)
            else
                prerequisites = prerequisites == nil and {} or prerequisites
                table.insert(prerequisites, prerequisite)
            end
        end
    end
    return prerequisites
end
function NPCUtil.cleanEmotionalText(text)
    text = string.gsub(text, "(%[[%w, ]*%])", "")
    return string.gsub(text, "(%[/[%w ]*%])", "")
end