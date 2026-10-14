IndexedSearch = {}
local IndexedSearch_mt = Class(IndexedSearch)
function IndexedSearch.new(fieldWeights)
    -- upvalues: (copy) IndexedSearch_mt
    local self = setmetatable({}, IndexedSearch_mt)
    self.documents = {}
    self.index = {}
    self.fieldWeights = fieldWeights or {}
    self.isDirty = true
    self.minTextLength = 2
    self.minTokenLength = 4
    self.maxTokenLength = 8
    self.ignoreCharacterPattern = "[%(%)%/%\\%[%]%{%}%-%.%_%\'%+%,%\"%$%&]"
    return self
end
function IndexedSearch:clear()
    self:reset()
    table.clear(self.documents)
    table.clear(self.index)
    self.isDirty = true
end
function IndexedSearch:cancel()
    if self.callbackFunc ~= nil then
        self.callbackFunc(nil)
    end
    self:reset()
end
function IndexedSearch:reset()
    self.callbackFunc = nil
    self.words = nil
    self.results = nil
    self.scoreMap = nil
    removeGlobalUpdateable(self)
end
function IndexedSearch:cleanSpecialCharacters(text)
    return string.gsub(text, self.ignoreCharacterPattern, " ")
end
function IndexedSearch:tokenize(text, tokenCallback)
    text = self:cleanSpecialCharacters(text)
    for number in string.gmatch(text, "%d+") do
        tokenCallback(number)
    end
    text = string.gsub(text, "%d+", " ")
    for number, raw in string.split(text, " ") do
        local word = string.trim(utf8ToLower(raw))
        local textLength = utf8Strlen(word)
        if textLength >= self.minTextLength then
            local minLen = self.minTokenLength
            local maxLen = math.min(textLength, self.maxTokenLength)
            local i = 0
            for i = i, textLength - minLen do
                local substr = math.min(maxLen, textLength - i)
                for minLen = minLen, substr do
                    tokenCallback((utf8Substr(word, i, minLen)))
                end
            end
            tokenCallback(word)
        end
    end
end
function IndexedSearch:build()
    local startTime = getTimeSec()
    table.clear(self.index)
    for documentId, data in ipairs(self.documents) do
        self:indexDocument(documentId, data)
    end
    Logging.devInfo("Build index in %.3f seconds", getTimeSec() - startTime)
    self.isDirty = false
end
function IndexedSearch:indexDocument(documentId, documentData)
    for field, text in pairs(documentData.document) do
        local field
        self:tokenize(utf8ToLower(text), function(word)
            -- upvalues: (copy) self, (copy) field, (copy) documentId
            self.index[word] = self.index[word] or {}
            local data = self.index[word][field]
            if data == nil then
                self.index[word][field] = documentId
                return
            elseif type(data) == "number" then
                self.index[word][field] = {}
                self.index[word][field][data] = true
                self.index[word][field][documentId] = true
            else
                self.index[word][field][documentId] = true
            end
        end)
    end
end
function IndexedSearch:addDocument(document, ref)
    for field, _ in pairs(self.fieldWeights) do
        if document[field] == nil then
            Logging.devError("Missing field \'%s\' in document", field)
            printCallstack()
            return false
        end
    end
    table.insert(self.documents, {
        ["document"] = document,
        ["ref"] = ref
    })
    self.isDirty = true
    return true
end
function IndexedSearch:search(text, callbackFunc)
    if text == nil then
        return false
    end
    if self.isDirty then
        return false
    end
    if string.isNilOrWhitespace(text) then
        return false
    end
    local words = string.trim(text)
    if utf8Strlen(words) < self.minTextLength then
        return false
    end
    local words = {}
    for _, raw in string.split(words, " ") do
        local raw = self:cleanSpecialCharacters((string.trim(utf8ToLower(raw))))
        if utf8Strlen(raw) >= self.minTextLength then
            table.insert(words, raw)
        end
    end
    if #words == 0 then
        return false
    end
    self:cancel()
    addGlobalUpdateable(self)
    self.results = nil
    self.words = words
    self.currentWordIndex = 1
    self.lastIndexWord = nil
    self.callbackFunc = callbackFunc
    return true
end
function IndexedSearch:update(_)
    if self.callbackFunc then
        if self.results == nil then
            if self.isDirty then
                self:sendCallback()
                return
            end
            self.results = {}
            self.scoreMap = {}
        end
        local word = self.words[self.currentWordIndex]
        if word ~= nil then
            local matches = {}
            if self.index[word] then
                matches[word] = 0
            else
                for indexedWord in pairs(self.index) do
                    local dist = getLevenshteinDistance(word, indexedWord)
                    if dist <= 2 then
                        matches[indexedWord] = dist
                    end
                end
            end
            for indexedWord, dist in pairs(matches) do
                local dist = dist * 0.5
                for field, docs in pairs(self.index[indexedWord]) do
                    local positionBonus = 0
                    local pos = string.find(indexedWord, word, 1, true)
                    if pos then
                        positionBonus = math.max(0, 10 - (pos - 1))
                    end
                    if type(docs) == "number" then
                        self.scoreMap[docs] = (self.scoreMap[docs] or 0) + ((self.fieldWeights[field] or 1) * #indexedWord - dist + positionBonus + (indexedWord == word and 20 or 0))
                    else
                        for documentId, _ in pairs(docs) do
                            self.scoreMap[documentId] = (self.scoreMap[documentId] or 0) + (weight * wordLen - dist + positionBonus + exactBonus)
                        end
                    end
                end
            end
            self.currentWordIndex = self.currentWordIndex + 1
        end
        if word == nil or self.currentWordIndex > #self.words then
            local matches = {}
            for indexedWord, dist in pairs(self.scoreMap) do
                local dist = self.documents[indexedWord]
                table.insert(matches, {
                    ["document"] = dist.document,
                    ["ref"] = dist.ref,
                    ["score"] = dist
                })
            end
            table.sort(matches, function(a, b)
                return a.score > b.score
            end)
            for indexedWord, dist in ipairs(matches) do
                table.insert(self.results, {
                    ["document"] = dist.document,
                    ["ref"] = dist.ref,
                    ["score"] = dist.score
                })
            end
            self:sendCallback()
        end
    end
end
function IndexedSearch:sendCallback()
    self.callbackFunc(self.results)
    self:reset()
end