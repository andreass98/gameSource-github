GoalDialogShown = {}
GoalDialogShown.NAME = "dialogShown"
local GoalDialogShown_mt = Class(GoalDialogShown)
function GoalDialogShown.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.L10N_STRING, basePath .. "#text", "Text of the dialog", nil, true)
    schema:register(XMLValueType.L10N_STRING, basePath .. "#title", "Title of the dialog", nil, false)
    schema:register(XMLValueType.STRING, basePath .. ".input(?)#name", "Name of the input action", nil, false)
    schema:register(XMLValueType.STRING, basePath .. ".input(?)#name2", "Name of the second input action", nil, false)
    schema:register(XMLValueType.L10N_STRING, basePath .. ".input(?)#text", "Text of the action", nil, false)
    schema:register(XMLValueType.BOOL, basePath .. ".input(?)#keyboardOnly", "If the input should only be visible if keyboard input is active", false, false)
    schema:register(XMLValueType.BOOL, basePath .. ".input(?)#gamepadOnly", "If the input should only be visible if gamepad input is active", false, false)
end
function GoalDialogShown.new(title, text, inputs, customMt)
    -- upvalues: (copy) GoalDialogShown_mt
    local self = setmetatable({}, customMt or GoalDialogShown_mt)
    self.title = title
    self.text = text
    self.inputs = inputs
    self.wasShown = false
    return self
end
function GoalDialogShown:activate(_, _)
    self.wasShown = false
    local controls = {}
    local useGamepadButtons = g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD
    for _, input in ipairs(self.inputs) do
        if not (input.keyboardOnly and useGamepadButtons) and (Platform.isMobile or (not input.gamepadOnly or useGamepadButtons)) then
            table.insert(controls, input)
        end
    end
    g_currentMission.hud:showInGameMessage(self.title, self.text, -1, controls, function(target)
        -- upvalues: (copy) self
        self.wasShown = true
    end, nil)
end
function GoalDialogShown:isAchieved()
    return self.wasShown
end
function GoalDialogShown.createFromXML(xmlFile, key, _, customEnvironment)
    local text = xmlFile:getValue(key .. "#text", nil, customEnvironment, false)
    if text == nil then
        Logging.xmlWarning(xmlFile, "Missing \'text\' for \'%s\'", key)
        return nil
    end
    local title = xmlFile:getValue(key .. "#title", g_i18n:getText("ui_tour"), customEnvironment, false)
    local inputs = {}
    for _, inputKey in xmlFile:iterator(key .. ".input") do
        local actionName = xmlFile:getValue(inputKey .. "#name")
        if actionName ~= nil then
            local input = {
                ["actionName"] = actionName,
                ["actionName2"] = xmlFile:getValue(inputKey .. "#name2"),
                ["text"] = xmlFile:getValue(inputKey .. "#text", nil, customEnvironment, false),
                ["keyboardOnly"] = xmlFile:getValue(inputKey .. "#keyboardOnly", false),
                ["gamepadOnly"] = xmlFile:getValue(inputKey .. "#gamepadOnly", false)
            }
            table.insert(inputs, input)
        end
    end
    return GoalDialogShown.new(title, text, inputs)
end
g_guidedTourManager:registerGoalClass(GoalDialogShown.NAME, GoalDialogShown)