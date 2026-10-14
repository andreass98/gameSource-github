GameplayHintManager = {}
local GameplayHintManager_mt = Class(GameplayHintManager, AbstractManager)
function GameplayHintManager.new(customMt)
    -- upvalues: (copy) GameplayHintManager_mt
    return AbstractManager.new(customMt or GameplayHintManager_mt)
end
function GameplayHintManager:initDataStructures()
    self.gameplayHints = {}
    self.isLoaded = false
end
function GameplayHintManager:loadMapData(xmlFile, _)
    GameplayHintManager:superClass().loadMapData(self)
    local filenameStr = getXMLString(xmlFile, "map.gameplayHints#filename")
    if filenameStr == nil then
        Logging.xmlInfo(xmlFile, "No gameplay hints defined for map")
        return false
    end
    local filename = Utils.getFilename(filenameStr, g_currentMission.baseDirectory)
    if filename == nil or (filename == "" or not fileExists(filename)) then
        Logging.xmlError(xmlFile, "Could not load gameplayHint config file \'" .. tostring(filenameStr) .. "\'!")
        return false
    end
    local customEnvironment, _ = Utils.getModNameAndBaseDirectory(filename)
    local gameplayHintXmlFile = loadXMLFile("gameplayHints", filename)
    if gameplayHintXmlFile ~= 0 then
        local i = 0
        while true do
            local key = string.format("gameplayHints.gameplayHint(%d)", i)
            if not hasXMLProperty(gameplayHintXmlFile, key) then
                break
            end
            local text = getXMLString(gameplayHintXmlFile, key)
            if text:sub(1, 6) == "$l10n_" then
                text = g_i18n:getText(text:sub(7), customEnvironment)
            end
            table.insert(self.gameplayHints, text)
            i = i + 1
        end
        delete(gameplayHintXmlFile)
    end
    self.isLoaded = true
    return true
end
function GameplayHintManager:getRandomGameplayHint(numberOfHints)
    local hints = {}
    if #self.gameplayHints <= numberOfHints then
        return self.gameplayHints
    end
    while #hints < numberOfHints do
        local hintId = math.random(1, #self.gameplayHints)
        if ({})[hintId] == nil then
            table.insert(hints, self.gameplayHints[hintId])
            addedHints[hintId] = hintId
        end
    end
    return hints
end
function GameplayHintManager:getIsLoaded()
    return self.isLoaded
end
g_gameplayHintManager = GameplayHintManager.new()