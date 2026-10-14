ConsoleValueToggle = {}
local ConsoleValueToggle_mt = Class(ConsoleValueToggle)
function ConsoleValueToggle.new(commandName, commandDescription, startingValue, outputFunctionOrString, argumentNames, excludeFromHistory)
    -- upvalues: (copy) ConsoleValueToggle_mt
    local self = setmetatable({}, ConsoleValueToggle_mt)
    if startingValue == nil or not startingValue then
        startingValue = false
    end
    self.value = startingValue
    self.commandName = commandName
    self.onEnabled = ListenerList.new()
    self.onDisabled = ListenerList.new()
    self.onDeleted = ListenerList.new()
    self.outputFunctionOrString = outputFunctionOrString or function(_, enabledString)
        return enabledString
    end
    addConsoleCommand(self.commandName, commandDescription, "consoleCommandToggleValue", self, argumentNames, excludeFromHistory)
    return self
end
function ConsoleValueToggle:delete()
    removeConsoleCommand(self.commandName)
    self.onDeleted()
end
function ConsoleValueToggle:consoleCommandToggleValue(...)
    if self.value then
        self:disableValue(...)
    else
        self:enableValue(...)
    end
    if type(self.outputFunctionOrString) ~= "function" then
        return type(self.outputFunctionOrString) ~= "string" and "Toggled" or self.outputFunctionOrString
    end
    return self.outputFunctionOrString(self.value, self.value and "enabled" or "disabled", ...)
end
function ConsoleValueToggle:enableValue(...)
    if not self.value then
        self.value = true
        self.onEnabled(...)
    end
end
function ConsoleValueToggle:disableValue(...)
    if self.value then
        self.value = false
        self.onDisabled(...)
    end
end