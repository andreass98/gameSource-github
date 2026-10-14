InputHelpElement = {}
local InputHelpElement_mt = Class(InputHelpElement)
InputHelpElement.SEPARATOR = {
    ["NONE"] = 1,
    ["COMBO_INPUT"] = 2,
    ["ANY_INPUT"] = 3
}
InputHelpElement.NO_DATA = {}
function InputHelpElement.new(actionName, actionName2, buttonOverlays, keyLabels, separators, isComboButtonMapping, text, inlineModifierButtons, iconOverlay, priority)
    -- upvalues: (copy) InputHelpElement_mt
    local self = setmetatable({}, InputHelpElement_mt)
    self.actionName = actionName or ""
    self.actionName2 = actionName2 or ""
    self.buttons = buttonOverlays or InputHelpElement.NO_DATA
    self.separators = separators or InputHelpElement.NO_DATA
    self.isComboButtonMapping = isComboButtonMapping or InputHelpElement.NO_DATA
    self.keys = keyLabels or InputHelpElement.NO_DATA
    self.text = text or ""
    self.inlineModifierButtons = inlineModifierButtons
    self.iconOverlay = iconOverlay
    self.priority = priority or GS_PRIO_NORMAL
    return self
end
function InputHelpElement:getActionNames()
    local actionNames = {}
    if self.actionName ~= "" then
        table.insert(actionNames, self.actionName)
    end
    if self.actionName2 ~= "" then
        table.insert(actionNames, self.actionName2)
    end
    return actionNames
end
InputHelpElement.AXIS_ICON = {}
InputHelpElement.AXIS_ICON.CRANE_ARM1_ROTATE_X = "CRANE_ARM1_ROTATE_X"
InputHelpElement.AXIS_ICON.CRANE_ARM1_ROTATE_Y = "CRANE_ARM1_ROTATE_Y"
InputHelpElement.AXIS_ICON.CRANE_ARM1_TRANSLATE = "CRANE_ARM1_TRANSLATE"
InputHelpElement.AXIS_ICON.CRANE_ARM2_ROTATE_X = "CRANE_ARM2_ROTATE_X"
InputHelpElement.AXIS_ICON.CRANE_ARM2_ROTATE_TOOL = "CRANE_ARM2_ROTATE_TOOL"
InputHelpElement.AXIS_ICON.CRANE_ARM2_TRANSLATE = "CRANE_ARM2_TRANSLATE"
InputHelpElement.AXIS_ICON.DRAWBAR_ROTATE_X = "DRAWBAR_ROTATE_X"
InputHelpElement.AXIS_ICON.FRONTLOADER_ARM_ROTATE = "FRONTLOADER_ARM_ROTATE"
InputHelpElement.AXIS_ICON.FRONTLOADER_ARM_ROTATE_TOOL = "FRONTLOADER_ARM_ROTATE_TOOL"
InputHelpElement.AXIS_ICON.GRABBER_OPEN_CLOSE = "GRABBER_OPEN_CLOSE"
InputHelpElement.AXIS_ICON.GRABBER_ROTATE_Y = "GRABBER_ROTATE_Y"
InputHelpElement.AXIS_ICON.IMPLEMENT_ATTACHER_ROTX = "IMPLEMENT_ATTACHER_ROTX"
InputHelpElement.AXIS_ICON.IMPLEMENT_ATTACHER_TRANS = "IMPLEMENT_ATTACHER_TRANS"
InputHelpElement.AXIS_ICON.IMPLEMENT_TRANS_X = "IMPLEMENT_TRANS_X"
InputHelpElement.AXIS_ICON.IMPLEMENT_TRANS_Y = "IMPLEMENT_TRANS_Y"
InputHelpElement.AXIS_ICON.PIPE_END_ROTATE = "PIPE_END_ROTATE"
InputHelpElement.AXIS_ICON.PIPE_ROTATE_X = "PIPE_ROTATE_X"
InputHelpElement.AXIS_ICON.PIPE_ROTATE_Y = "PIPE_ROTATE_Y"
InputHelpElement.AXIS_ICON.REEL_TRANSLATE_X = "REEL_TRANSLATE_X"
InputHelpElement.AXIS_ICON.REEL_TRANSLATE_Y = "REEL_TRANSLATE_Y"
InputHelpElement.AXIS_ICON.SPRAYER_ARM_TRANSLATE_Y = "SPRAYER_ARM_TRANSLATE_Y"
InputHelpElement.AXIS_ICON.SUPPORT_ARM_TRANSLATE_Y = "SUPPORT_ARM_TRANSLATE_Y"
InputHelpElement.AXIS_ICON.TOOL_OPEN_CLOSE = "TOOL_OPEN_CLOSE"
InputHelpElement.AXIS_ICON.TOP_DOOR_ROTATE = "TOP_DOOR_ROTATE"
InputHelpElement.AXIS_ICON.WHEEL_BASE_TRANSLATE_X = "WHEEL_BASE_TRANSLATE_X"
InputHelpElement.AXIS_ICON.CHASSIS_HEIGHT = "CHASSIS_HEIGHT"
InputHelpElement.AXIS_ICON.WORKING_WIDTH_TRANSLATE_X = "WORKING_WIDTH_TRANSLATE_X"
InputHelpElement.AXIS_ICON.CRANE_EC_TRANSLATE_Y = "CRANE_EC_TRANSLATE_Y"
InputHelpElement.AXIS_ICON.CRANE_EC_TRANSLATE_Z = "CRANE_EC_TRANSLATE_Z"
InputHelpElement.AXIS_ICON.BEET_PICKUP_TRANS_X = "BEET_PICKUP_TRANS_X"
InputHelpElement.AXIS_ICON.BEET_PICKUP_TRANS_Y = "BEET_PICKUP_TRANS_Y"
InputHelpElement.AXIS_ICON.SEAT_ROT_Y = "SEAT_ROT_Y"
InputHelpElement.AXIS_ICON.SNOW_PLOW_ROT_LEFT = "SNOW_PLOW_ROT_LEFT"
InputHelpElement.AXIS_ICON.SNOW_PLOW_ROT_CENTER = "SNOW_PLOW_ROT_CENTER"
InputHelpElement.AXIS_ICON.SNOW_PLOW_ROT_RIGHT = "SNOW_PLOW_ROT_RIGHT"
InputHelpElement.AXIS_ICON.FORKLIFT_ROTATE_X = "FORKLIFT_ROTATE_X"
InputHelpElement.AXIS_ICON.FORKLIFT_TRANSLATE_Y = "FORKLIFT_TRANSLATE_Y"