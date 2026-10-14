ConstructibleStateFinalize = {}
local ConstructibleStateFinalize_mt = Class(ConstructibleStateFinalize, ConstructibleState)
function ConstructibleStateFinalize.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.L10N_STRING, basePath .. "#finalizeText")
    schema:register(XMLValueType.STRING, basePath .. ".extraContent#key")
    schema:register(XMLValueType.L10N_STRING, basePath .. ".extraContent#text")
end
function ConstructibleStateFinalize.new(constructible, dirtyFlag, customMt)
    -- upvalues: (copy) ConstructibleStateFinalize_mt
    return ConstructibleState.new(constructible, dirtyFlag, customMt or ConstructibleStateFinalize_mt)
end
function ConstructibleStateFinalize:load(xmlFile, key)
    ConstructibleStateFinalize:superClass().load(self, xmlFile, key)
    local finalizeText = xmlFile:getI18NValue(key .. "#finalizeText", nil, self.constructible.customEnvironment, false)
    if not string.isNilOrWhitespace(finalizeText) then
        self.finalizeText = finalizeText
    end
    self.extraContentKey = xmlFile:getString(key .. ".extraContent#key")
    local extraContentText = xmlFile:getI18NValue(key .. ".extraContent#text", nil, self.constructible.customEnvironment, false)
    if not string.isNilOrWhitespace(extraContentText) then
        self.extraContentText = extraContentText
    end
end
function ConstructibleStateFinalize:activate()
    ConstructibleStateFinalize:superClass().activate(self)
    if self.finalizeText ~= nil and self.extraContentText == nil then
        InfoDialog.show(g_i18n:getText(self.finalizeText))
    end
    if self.extraContentKey ~= nil then
        local item, errorCode = g_extraContentSystem:unlockItem(self.extraContentKey, false)
        if item ~= nil and (errorCode == ExtraContentSystem.UNLOCKED and g_currentMission.gameStarted) then
            if self.extraContentText ~= nil then
                local text = string.namedFormat(self.extraContentText, "contentName", item.title)
                InfoDialog.show(text)
            end
            Logging.info("ExtraContent: Unlock \'" .. item.id .. "\'")
        end
    end
end
function ConstructibleStateFinalize:isDone()
    return true
end
function ConstructibleStateFinalize:raiseActive()
    return true
end
function ConstructibleStateFinalize:deactivate()
    ConstructibleStateFinalize:superClass().deactivate(self)
    self.constructible:finalizeConstruction()
end