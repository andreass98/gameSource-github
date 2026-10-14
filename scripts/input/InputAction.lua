InputAction = {}
local InputAction_mt = Class(InputAction)
InputAction.AXIS_TYPE = {
    ["HALF"] = "HALF",
    ["FULL"] = "FULL"
}
InputAction.CATEGORY = {
    ["SYSTEM"] = 1,
    ["ONFOOT"] = 2,
    ["VEHICLE"] = 3
}
function InputAction.new(name, categories, displayCategory, axisType, isLocked, ignoreComboMask, displayNamePositive, displayNameNegative, isBaseAction, isConsoleAction, isMobileAction)
    -- upvalues: (copy) InputAction_mt
    local self = setmetatable({}, InputAction_mt)
    self.name = name
    self.displayNamePositive = displayNamePositive
    self.displayNameNegative = displayNameNegative
    self.categories = categories
    self.axisType = axisType
    self.isLocked = isLocked
    self.ignoreComboMask = ignoreComboMask
    self.displayCategory = displayCategory
    self.isBaseAction = Utils.getNoNil(isBaseAction, true)
    self.isConsoleAction = Utils.getNoNil(isConsoleAction, true)
    self.isMobileAction = Utils.getNoNil(isMobileAction, true)
    self.bindingsKnown = false
    self.bindings = {}
    self.activeBindings = {}
    self.isConsumed = false
    self.comboMaskGamepad = 0
    self.comboMaskMouse = 0
    self.primaryKeyboardInput = nil
    return self
end
function InputAction.createFromXML(xmlFile, elementTag)
    local name = getXMLString(xmlFile, elementTag .. "#name")
    local categoryNames = (getXMLString(xmlFile, elementTag .. "#category") or ""):split(" ")
    local categories = {}
    for _, categoryName in ipairs(categoryNames) do
        categories[cat] = InputAction.CATEGORY[categoryName] or categories[cat]
    end
    local displayCategory = getXMLString(xmlFile, elementTag .. "#displayCategory")
    if displayCategory ~= nil then
    end
    local axisType = getXMLString(xmlFile, elementTag .. "#axisType")
    if axisType ~= InputAction.AXIS_TYPE.FULL and axisType ~= InputAction.AXIS_TYPE.HALF then
        axisType = InputAction.AXIS_TYPE.HALF
    end
    local isLocked = Utils.getNoNil(getXMLBool(xmlFile, elementTag .. "#locked"), false)
    local _ = Utils.getNoNil(getXMLBool(xmlFile, elementTag .. "#ignoreComboMask"), false)
    local categoryName = getXMLBool(xmlFile, elementTag .. "#isBaseAction")
    local cat = getXMLBool(xmlFile, elementTag .. "#isConsoleAction")
    local isMobileAction = getXMLBool(xmlFile, elementTag .. "#isMobileAction")
    local isLocked = table.hasElement(Platform.lockedInputActionNames, name) and true or isLocked
    if name and not InputAction[name] then
        InputAction[name] = name
    end
    return InputAction.new(name, categories, displayCategory, axisType, isLocked, _, nil, nil, categoryName, cat, isMobileAction)
end
function InputAction:getIsSupportedOnCurrentPlatform()
    return (self.isBaseAction or not GS_PLATFORM_PC) and ((self.isConsoleAction or not GS_IS_CONSOLE_VERSION) and (self.isMobileAction or not GS_IS_MOBILE_VERSION)) and true or false
end
function InputAction:addBinding(binding)
    for _, existingBinding in pairs(self.bindings) do
        if existingBinding.id == binding.id then
            return
        end
    end
    table.insert(self.bindings, binding)
    self:resetActiveBindings()
end
function InputAction:removeBinding(binding)
    for i, existingBinding in ipairs(self.bindings) do
        if existingBinding.id == binding.id then
            table.remove(self.bindings, i)
            return
        end
    end
    self:resetActiveBindings()
end
function InputAction:disableBinding(binding)
    for i, existingBinding in ipairs(self.activeBindings) do
        if existingBinding.id == binding.id then
            table.remove(self.activeBindings, i)
            return
        end
    end
end
function InputAction:enableBinding(binding)
    for _, existingBinding in ipairs(self.bindings) do
        if existingBinding.id == binding.id then
            table.addElement(self.activeBindings, binding)
        end
    end
end
function InputAction:getBindings()
    return self.bindings
end
function InputAction:getActiveBindings()
    return self.activeBindings
end
function InputAction:getNumActiveBindings(ignoreDeviceState)
    local num = 0
    local i = 1
    for i = i, #self.activeBindings do
        if g_inputBinding.deviceIdToInternal[self.activeBindings[i].deviceId] ~= nil or ignoreDeviceState then
        end
    end
    return num
end
function InputAction:resetActiveBindings()
    for k in pairs(self.activeBindings) do
        self.activeBindings[k] = nil
    end
    for k, binding in ipairs(self.bindings) do
        table.insert(self.activeBindings, binding)
    end
end
function InputAction:clearBindings()
    self.bindings = {}
    self.activeBindings = {}
end
function InputAction:getBindingAtSlot(axisComponent, isKbMouse, slotIndex)
    for _, binding in pairs(self.bindings) do
        if binding:isSameSlotWithParams(axisComponent, isKbMouse, slotIndex) then
            return binding
        end
    end
    return nil
end
function InputAction:setPrimaryKeyboardBinding(binding)
    self.primaryKeyboardInput = table.concat(binding.axisNames, " ")
end
function InputAction:isFullAxis()
    return self.axisType == InputAction.AXIS_TYPE.FULL
end
function InputAction:getIgnoreComboMask()
    return self.ignoreComboMask
end
function InputAction:clone()
    return InputAction.new(self.name, self.categories, self.displayCategory, self.axisType, self.isLocked, self.ignoreComboMask, self.displayNamePositive, self.displayNameNegative)
end
function InputAction:toString()
    local categories = ""
    for cat in pairs(self.categories) do

    end
    local cat = self.name
    return string.format("[%s: categories=%s, axisType=%s, isLocked=%s]", tostring(cat), categories, tostring(self.axisType), (tostring(self.isLocked)))
end
InputAction_mt.__tostring = InputAction.toString
InputAction.JUMP = "JUMP"
InputAction.ACTIVATE_HANDTOOL = "ACTIVATE_HANDTOOL"
InputAction.ACTIVATE_HANDTOOL_SECONDARY = "ACTIVATE_HANDTOOL_SECONDARY"
InputAction.INTERACT = "INTERACT"
InputAction.THROW_OBJECT = "THROW_OBJECT"
InputAction.ROTATE_OBJECT_LEFT_RIGHT = "ROTATE_OBJECT_LEFT_RIGHT"
InputAction.ROTATE_OBJECT_UP_DOWN = "ROTATE_OBJECT_UP_DOWN"
InputAction.ENTER = "ENTER"
InputAction.CROUCH = "CROUCH"
InputAction.TOGGLE_LIGHTS_FPS = "TOGGLE_LIGHTS_FPS"
InputAction.CAMERA_SWITCH = "CAMERA_SWITCH"
InputAction.ACTIVATE_OBJECT = "ACTIVATE_OBJECT"
InputAction.ANIMAL_PET = "ANIMAL_PET"
InputAction.SPRAYCAN_CHANGE_MARKER = "SPRAYCAN_CHANGE_MARKER"
InputAction.HANDS_LEVEL_ITEM = "HANDS_LEVEL"
InputAction.PAUSE = "PAUSE"
InputAction.SKIP_MESSAGE_BOX = "SKIP_MESSAGE_BOX"
InputAction.CAMERA_ZOOM_IN_OUT = "CAMERA_ZOOM_IN_OUT"
InputAction.SWITCH_VEHICLE = "SWITCH_VEHICLE"
InputAction.SWITCH_VEHICLE_BACK = "SWITCH_VEHICLE_BACK"
InputAction.SWITCH_SEAT = "SWITCH_SEAT"
InputAction.MENU = "MENU"
InputAction.TOGGLE_STORE = "TOGGLE_STORE"
InputAction.TOGGLE_MAP = "TOGGLE_MAP"
InputAction.TOGGLE_HELP = "TOGGLE_HELP"
InputAction.TOGGLE_CHARACTER_CREATION = "TOGGLE_CHARACTER_CREATION"
InputAction.TOGGLE_CONSTRUCTION = "TOGGLE_CONSTRUCTION"
InputAction.ATTACH = "ATTACH"
InputAction.DETACH = "DETACH"
InputAction.SWITCH_IMPLEMENT = "SWITCH_IMPLEMENT"
InputAction.SWITCH_IMPLEMENT_BACK = "SWITCH_IMPLEMENT_BACK"
InputAction.TOGGLE_AI = "TOGGLE_AI"
InputAction.TOGGLE_AI_STEERING = "TOGGLE_AI_STEERING"
InputAction.HONK = "HONK"
InputAction.MOTOR_STATE_IGNITION = "MOTOR_STATE_IGNITION"
InputAction.MOTOR_STATE_ON = "MOTOR_STATE_ON"
InputAction.MOTOR_STATE_OFF = "MOTOR_STATE_OFF"
InputAction.TOGGLE_MOTOR_STATE = "TOGGLE_MOTOR_STATE"
InputAction.SHIFT_GEAR_UP = "SHIFT_GEAR_UP"
InputAction.SHIFT_GEAR_DOWN = "SHIFT_GEAR_DOWN"
InputAction.SHIFT_GEAR_SELECT_1 = "SHIFT_GEAR_SELECT_1"
InputAction.SHIFT_GEAR_SELECT_2 = "SHIFT_GEAR_SELECT_2"
InputAction.SHIFT_GEAR_SELECT_3 = "SHIFT_GEAR_SELECT_3"
InputAction.SHIFT_GEAR_SELECT_4 = "SHIFT_GEAR_SELECT_4"
InputAction.SHIFT_GEAR_SELECT_5 = "SHIFT_GEAR_SELECT_5"
InputAction.SHIFT_GEAR_SELECT_6 = "SHIFT_GEAR_SELECT_6"
InputAction.SHIFT_GEAR_SELECT_7 = "SHIFT_GEAR_SELECT_7"
InputAction.SHIFT_GEAR_SELECT_8 = "SHIFT_GEAR_SELECT_8"
InputAction.SHIFT_GROUP_UP = "SHIFT_GROUP_UP"
InputAction.SHIFT_GROUP_DOWN = "SHIFT_GROUP_DOWN"
InputAction.SHIFT_GROUP_SELECT_1 = "SHIFT_GROUP_SELECT_1"
InputAction.SHIFT_GROUP_SELECT_2 = "SHIFT_GROUP_SELECT_2"
InputAction.SHIFT_GROUP_SELECT_3 = "SHIFT_GROUP_SELECT_3"
InputAction.SHIFT_GROUP_SELECT_4 = "SHIFT_GROUP_SELECT_4"
InputAction.AXIS_CLUTCH_VEHICLE = "AXIS_CLUTCH_VEHICLE"
InputAction.DIRECTION_CHANGE = "DIRECTION_CHANGE"
InputAction.DIRECTION_CHANGE_POS = "DIRECTION_CHANGE_POS"
InputAction.DIRECTION_CHANGE_NEG = "DIRECTION_CHANGE_NEG"
InputAction.TOGGLE_TIPSTATE = "TOGGLE_TIPSTATE"
InputAction.TOGGLE_LIGHTS = "TOGGLE_LIGHTS"
InputAction.TOGGLE_LIGHTS_EXTERNAL = "TOGGLE_LIGHTS_EXTERNAL"
InputAction.TOGGLE_BEACON_LIGHTS = "TOGGLE_BEACON_LIGHTS"
InputAction.TOGGLE_TIPSIDE = "TOGGLE_TIPSIDE"
InputAction.TOGGLE_TURNLIGHT_LEFT = "TOGGLE_TURNLIGHT_LEFT"
InputAction.TOGGLE_TURNLIGHT_RIGHT = "TOGGLE_TURNLIGHT_RIGHT"
InputAction.TOGGLE_CRABSTEERING = "TOGGLE_CRABSTEERING"
InputAction.TOGGLE_CRABSTEERING_BACK = "TOGGLE_CRABSTEERING_BACK"
InputAction.TOGGLE_TENSION_BELTS = "TOGGLE_TENSION_BELTS"
InputAction.LOWER_IMPLEMENT = "LOWER_IMPLEMENT"
InputAction.IMPLEMENT_EXTRA = "IMPLEMENT_EXTRA"
InputAction.IMPLEMENT_EXTRA2 = "IMPLEMENT_EXTRA2"
InputAction.IMPLEMENT_EXTRA3 = "IMPLEMENT_EXTRA3"
InputAction.IMPLEMENT_EXTRA4 = "IMPLEMENT_EXTRA4"
InputAction.UNLOAD_FORK = "UNLOAD_FORK"
InputAction.FOLDABLESTEPS_NEXT_POS = "FOLDABLESTEPS_NEXT_POS"
InputAction.FOLDABLESTEPS_NEXT_NEG = "FOLDABLESTEPS_NEXT_NEG"
InputAction.TOGGLE_PIPE = "TOGGLE_PIPE"
InputAction.TOGGLE_COVER = "TOGGLE_COVER"
InputAction.TOGGLE_CHOPPER = "TOGGLE_CHOPPER"
InputAction.TOGGLE_MAP_SIZE = "TOGGLE_MAP_SIZE"
InputAction.CHANGE_DRIVING_DIRECTION = "CHANGE_DRIVING_DIRECTION"
InputAction.TOGGLE_TIPSTATE_GROUND = "TOGGLE_TIPSTATE_GROUND"
InputAction.TOGGLE_CRUISE_CONTROL = "TOGGLE_CRUISE_CONTROL"
InputAction.RADIO_TOGGLE = "RADIO_TOGGLE"
InputAction.RADIO_NEXT_CHANNEL = "RADIO_NEXT_CHANNEL"
InputAction.RADIO_PREVIOUS_CHANNEL = "RADIO_PREVIOUS_CHANNEL"
InputAction.RADIO_NEXT_ITEM = "RADIO_NEXT_ITEM"
InputAction.RADIO_PREVIOUS_ITEM = "RADIO_PREVIOUS_ITEM"
InputAction.INGAMEMAP_ACCEPT = "INGAMEMAP_ACCEPT"
InputAction.MENU_ACCEPT = "MENU_ACCEPT"
InputAction.MENU_ACTIVATE = "MENU_ACTIVATE"
InputAction.MENU_CANCEL = "MENU_CANCEL"
InputAction.MENU_BACK = "MENU_BACK"
InputAction.MENU_PAGE_PREV = "MENU_PAGE_PREV"
InputAction.MENU_PAGE_NEXT = "MENU_PAGE_NEXT"
InputAction.MENU_LIST_PAGE_START = "MENU_LIST_PAGE_START"
InputAction.MENU_LIST_PAGE_END = "MENU_LIST_PAGE_END"
InputAction.MENU_LIST_PAGE_PREV = "MENU_LIST_PAGE_PREV"
InputAction.MENU_LIST_PAGE_NEXT = "MENU_LIST_PAGE_NEXT"
InputAction.MENU_LIST_PAGE_START_GAMEPAD = "MENU_LIST_PAGE_START_GAMEPAD"
InputAction.MENU_LIST_PAGE_END_GAMEPAD = "MENU_LIST_PAGE_END_GAMEPAD"
InputAction.MENU_MAP_ACTION_1 = "MENU_MAP_ACTION_1"
InputAction.TAKE_SCREENSHOT = "TAKE_SCREENSHOT"
InputAction.ADD_NOTE = "ADD_NOTE"
InputAction.CHAT = "CHAT"
InputAction.PUSH_TO_TALK = "PUSH_TO_TALK"
InputAction.TOGGLE_TURNLIGHT_HAZARD = "TOGGLE_TURNLIGHT_HAZARD"
InputAction.TOGGLE_WORK_LIGHT_BACK = "TOGGLE_WORK_LIGHT_BACK"
InputAction.TOGGLE_WORK_LIGHT_FRONT = "TOGGLE_WORK_LIGHT_FRONT"
InputAction.TOGGLE_HIGH_BEAM_LIGHT = "TOGGLE_HIGH_BEAM_LIGHT"
InputAction.TOGGLE_LIGHT_FRONT = "TOGGLE_LIGHT_FRONT"
InputAction.LOWER_ALL_IMPLEMENTS = "LOWER_ALL_IMPLEMENTS"
InputAction.TOGGLE_HELP_TEXT = "TOGGLE_HELP_TEXT"
InputAction.INCREASE_TIMESCALE = "INCREASE_TIMESCALE"
InputAction.DECREASE_TIMESCALE = "DECREASE_TIMESCALE"
InputAction.CRABSTEERING_ALLWHEEL = "CRABSTEERING_ALLWHEEL"
InputAction.CRABSTEERING_CRABLEFT = "CRABSTEERING_CRABLEFT"
InputAction.CRABSTEERING_CRABRIGHT = "CRABSTEERING_CRABRIGHT"
InputAction.RESET_HEAD_TRACKING = "RESET_HEAD_TRACKING"
InputAction.MENU_AXIS_UP_DOWN = "MENU_AXIS_UP_DOWN"
InputAction.MENU_AXIS_UP_DOWN_SECONDARY = "MENU_AXIS_UP_DOWN_SECONDARY"
InputAction.MENU_AXIS_LEFT_RIGHT = "MENU_AXIS_LEFT_RIGHT"
InputAction.AXIS_RUN = "AXIS_RUN"
InputAction.AXIS_MOVE_FORWARD_PLAYER = "AXIS_MOVE_FORWARD_PLAYER"
InputAction.AXIS_MOVE_SIDE_PLAYER = "AXIS_MOVE_SIDE_PLAYER"
InputAction.AXIS_LOOK_UPDOWN_PLAYER = "AXIS_LOOK_UPDOWN_PLAYER"
InputAction.AXIS_LOOK_LEFTRIGHT_PLAYER = "AXIS_LOOK_LEFTRIGHT_PLAYER"
InputAction.AXIS_PICK_COLOR_UPDOWN = "AXIS_PICK_COLOR_UPDOWN"
InputAction.AXIS_PICK_COLOR_LEFTRIGHT = "AXIS_PICK_COLOR_LEFTRIGHT"
InputAction.AXIS_ROTATE_HANDTOOL = "AXIS_ROTATE_HANDTOOL"
InputAction.AXIS_PITCH_HANDTOOL = "AXIS_PITCH_HANDTOOL"
InputAction.AXIS_DOOR = "AXIS_DOOR"
InputAction.AXIS_MAP_SCROLL_LEFT_RIGHT = "AXIS_MAP_SCROLL_LEFT_RIGHT"
InputAction.AXIS_MAP_SCROLL_UP_DOWN = "AXIS_MAP_SCROLL_UP_DOWN"
InputAction.AXIS_MAP_ZOOM_OUT = "AXIS_MAP_ZOOM_OUT"
InputAction.AXIS_MAP_ZOOM_IN = "AXIS_MAP_ZOOM_IN"
InputAction.AXIS_CONSTRUCTION_CAMERA_ZOOM = "AXIS_CONSTRUCTION_CAMERA_ZOOM"
InputAction.AXIS_CONSTRUCTION_CAMERA_ROTATE = "AXIS_CONSTRUCTION_CAMERA_ROTATE"
InputAction.AXIS_CONSTRUCTION_CAMERA_TILT = "AXIS_CONSTRUCTION_CAMERA_TILT"
InputAction.CONSTRUCTION_ACTION_PRIMARY = "CONSTRUCTION_ACTION_PRIMARY"
InputAction.CONSTRUCTION_ACTION_SECONDARY = "CONSTRUCTION_ACTION_SECONDARY"
InputAction.CONSTRUCTION_ACTION_TERTIARY = "CONSTRUCTION_ACTION_TERTIARY"
InputAction.CONSTRUCTION_ACTION_FOURTH = "CONSTRUCTION_ACTION_FOURTH"
InputAction.AXIS_CONSTRUCTION_ACTION_PRIMARY = "AXIS_CONSTRUCTION_ACTION_PRIMARY"
InputAction.AXIS_CONSTRUCTION_ACTION_SECONDARY = "AXIS_CONSTRUCTION_ACTION_SECONDARY"
InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN = "AXIS_CONSTRUCTION_MENU_UP_DOWN"
InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT = "AXIS_CONSTRUCTION_MENU_LEFT_RIGHT"
InputAction.CONSTRUCTION_DESTRUCT_TOGGLE = "CONSTRUCTION_DESTRUCT_TOGGLE"
InputAction.CONSTRUCTION_SHOW_CONFIGS = "CONSTRUCTION_SHOW_CONFIGS"
InputAction.AXIS_BRAKE_VEHICLE = "AXIS_BRAKE_VEHICLE"
InputAction.AXIS_ACCELERATE_VEHICLE = "AXIS_ACCELERATE_VEHICLE"
InputAction.AXIS_MOVE_SIDE_VEHICLE = "AXIS_MOVE_SIDE_VEHICLE"
InputAction.AXIS_LOOK_UPDOWN_VEHICLE = "AXIS_LOOK_UPDOWN_VEHICLE"
InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE = "AXIS_LOOK_LEFTRIGHT_VEHICLE"
InputAction.AXIS_HYDRAULICATTACHER1 = "AXIS_HYDRAULICATTACHER1"
InputAction.AXIS_HYDRAULICATTACHER2 = "AXIS_HYDRAULICATTACHER2"
InputAction.AXIS_FRONTLOADER_ARM = "AXIS_FRONTLOADER_ARM"
InputAction.AXIS_FRONTLOADER_ARM2 = "AXIS_FRONTLOADER_ARM2"
InputAction.AXIS_FRONTLOADER_TOOL = "AXIS_FRONTLOADER_TOOL"
InputAction.AXIS_FRONTLOADER_TOOL2 = "AXIS_FRONTLOADER_TOOL2"
InputAction.AXIS_FRONTLOADER_TOOL3 = "AXIS_FRONTLOADER_TOOL3"
InputAction.AXIS_FRONTLOADER_TOOL4 = "AXIS_FRONTLOADER_TOOL4"
InputAction.AXIS_FRONTLOADER_TOOL5 = "AXIS_FRONTLOADER_TOOL5"
InputAction.AXIS_CRANE_ARM = "AXIS_CRANE_ARM"
InputAction.AXIS_CRANE_ARM2 = "AXIS_CRANE_ARM2"
InputAction.AXIS_CRANE_ARM3 = "AXIS_CRANE_ARM3"
InputAction.AXIS_CRANE_ARM4 = "AXIS_CRANE_ARM4"
InputAction.AXIS_CRANE_TOOL = "AXIS_CRANE_TOOL"
InputAction.AXIS_CRANE_TOOL2 = "AXIS_CRANE_TOOL2"
InputAction.AXIS_CRANE_TOOL3 = "AXIS_CRANE_TOOL3"
InputAction.AXIS_CUTTER_REEL = "AXIS_CUTTER_REEL"
InputAction.AXIS_CUTTER_REEL2 = "AXIS_CUTTER_REEL2"
InputAction.AXIS_PIPE = "AXIS_PIPE"
InputAction.AXIS_PIPE2 = "AXIS_PIPE2"
InputAction.AXIS_DRAWBAR = "AXIS_DRAWBAR"
InputAction.AXIS_DRAWBAR2 = "AXIS_DRAWBAR2"
InputAction.AXIS_SPRAYER_ARM = "AXIS_SPRAYER_ARM"
InputAction.AXIS_WHEEL_BASE = "AXIS_WHEEL_BASE"
InputAction.AXIS_CRUISE_CONTROL = "AXIS_CRUISE_CONTROL"
InputAction.CYCLE_HANDTOOL = "CYCLE_HANDTOOL"
InputAction.TOGGLE_HANDTOOL = "TOGGLE_HANDTOOL"
InputAction.AXIS_LOOK_LEFTRIGHT_DRAG = "AXIS_LOOK_LEFTRIGHT_DRAG"
InputAction.AXIS_LOOK_UPDOWN_DRAG = "AXIS_LOOK_UPDOWN_DRAG"
InputAction.MENU_EXTRA_1 = "MENU_EXTRA_1"
InputAction.MENU_EXTRA_2 = "MENU_EXTRA_2"
InputAction.CONSOLE_ALT_COMMAND_BUTTON = "CONSOLE_ALT_COMMAND_BUTTON"
InputAction.CONSOLE_ALT_COMMAND2_BUTTON = "CONSOLE_ALT_COMMAND2_BUTTON"
InputAction.CONSOLE_ALT_COMMAND3_BUTTON = "CONSOLE_ALT_COMMAND3_BUTTON"
InputAction.MOUSE_ALT_COMMAND_BUTTON = "MOUSE_ALT_COMMAND_BUTTON"
InputAction.MOUSE_ALT_COMMAND2_BUTTON = "MOUSE_ALT_COMMAND2_BUTTON"
InputAction.MOUSE_ALT_COMMAND3_BUTTON = "MOUSE_ALT_COMMAND3_BUTTON"
InputAction.MOUSE_ALT_COMMAND4_BUTTON = "MOUSE_ALT_COMMAND4_BUTTON"
InputAction.AXIS_MTO_SCROLL = "AXIS_MTO_SCROLL"
InputAction.INTRODUCTION_HELP_SKIP = "INTRODUCTION_HELP_SKIP"
InputAction.UNLOAD = "UNLOAD"
InputAction.KIOSK_MODE_RESET_FILES = "KIOSK_MODE_RESET_FILES"
InputAction.KIOSK_MODE_RELOAD_GAME = "KIOSK_MODE_RELOAD_GAME"
InputAction.KIOSK_MODE_START_VIDEOS = "KIOSK_MODE_START_VIDEOS"
InputAction.KIOSK_MODE_TOGGLE_LANGUAGE = "KIOSK_MODE_TOGGLE_LANGUAGE"
InputAction.KIOSK_MODE_START_VIDEOS = "KIOSK_MODE_START_VIDEOS"
InputAction.DEBUG_PLAYER_ENABLE = "DEBUG_PLAYER_ENABLE"
InputAction.DEBUG_PLAYER_UP_DOWN = "DEBUG_PLAYER_UP_DOWN"
InputAction.CONSOLE_DEBUG_TOGGLE_FPS = "CONSOLE_DEBUG_TOGGLE_FPS"
InputAction.CONSOLE_DEBUG_TOGGLE_STATS = "CONSOLE_DEBUG_TOGGLE_STATS"
InputAction.CONVERSATION_SKIP = "CONVERSATION_SKIP"
InputAction.TOGGLE_WORKMODE = "TOGGLE_WORKMODE"
InputAction.PALLET_FILLER_BUY_PALLETS = "PALLET_FILLER_BUY_PALLETS"
InputAction.AXIS_CONSTRUCTION_CURSOR_ROTATE = "AXIS_CONSTRUCTION_CURSOR_ROTATE"
InputAction.CONSTRUCTION_ACTION_SNAPPING = "CONSTRUCTION_ACTION_SNAPPING"
InputAction.VEHICLE_ACTION_CONTROL = "VEHICLE_ACTION_CONTROL"
InputAction.TOGGLE_SEEDS = "TOGGLE_SEEDS"
InputAction.WINCH_ATTACH_MODE = "WINCH_ATTACH_MODE"
InputAction.WINCH_ATTACH = "WINCH_ATTACH"
InputAction.WINCH_CONTROL = "WINCH_CONTROL"
InputAction.WINCH_DETACH = "WINCH_DETACH"
InputAction.WINCH_CONTROL_VEHICLE = "WINCH_CONTROL_VEHICLE"
InputAction.YARDER_FOLLOW_ME = "YARDER_FOLLOW_ME"
InputAction.YARDER_FOLLOW_HOME = "YARDER_FOLLOW_HOME"
InputAction.YARDER_FOLLOW_PICKUP = "YARDER_FOLLOW_PICKUP"
InputAction.YARDER_CONTROL_LEFTRIGHT = "YARDER_CONTROL_LEFTRIGHT"
InputAction.YARDER_CONTROL_UPDOWN = "YARDER_CONTROL_UPDOWN"
InputAction.YARDER_ATTACH = "YARDER_ATTACH"
InputAction.YARDER_DETACH = "YARDER_DETACH"
InputAction.YARDER_SETUP_ROPE = "YARDER_SETUP_ROPE"
InputAction.TOGGLE_AI_STEERING_LINES = "TOGGLE_AI_STEERING_LINES"
InputAction.TREE_AUTOMATIC_ALIGN = "TREE_AUTOMATIC_ALIGN"
InputAction.BALE_COUNTER_RESET = "BALE_COUNTER_RESET"
InputAction.TOGGLE_BALE_TYPES = "TOGGLE_BALE_TYPES"
InputAction.CONSOLE_DEBUG_FILLUNIT_NEXT = "CONSOLE_DEBUG_FILLUNIT_NEXT"
InputAction.CONSOLE_DEBUG_FILLUNIT_INC = "CONSOLE_DEBUG_FILLUNIT_INC"
InputAction.CONSOLE_DEBUG_FILLUNIT_DEC = "CONSOLE_DEBUG_FILLUNIT_DEC"
InputAction.FOLD_ALL_IMPLEMENTS = "FOLD_ALL_IMPLEMENTS"
InputAction.TOGGLE_LIGHTS_BACK = "TOGGLE_LIGHTS_BACK"
InputAction.TOGGLE_SEEDS_BACK = "TOGGLE_SEEDS_BACK"
InputAction.DOUBLED_SPRAY_AMOUNT = "DOUBLED_SPRAY_AMOUNT"
InputAction.TURN_ON_ALL_IMPLEMENTS = "TURN_ON_ALL_IMPLEMENTS"
InputAction.VARIABLE_WORK_WIDTH_LEFT = "VARIABLE_WORK_WIDTH_LEFT"
InputAction.VARIABLE_WORK_WIDTH_RIGHT = "VARIABLE_WORK_WIDTH_RIGHT"
InputAction.VARIABLE_WORK_WIDTH_TOGGLE = "VARIABLE_WORK_WIDTH_TOGGLE"
InputAction.WOOD_HARVESTER_DROP = "WOOD_HARVESTER_DROP"
InputAction.TOGGLE_CUT_LENGTH_BACK = "TOGGLE_CUT_LENGTH_BACK"
InputAction.TOGGLE_WOOD_HARVESTER_TILT = "TOGGLE_WOOD_HARVESTER_TILT"
InputAction.LINKED_ACTIONS = {
    [InputAction.AXIS_LOOK_LEFTRIGHT_PLAYER] = InputAction.AXIS_LOOK_UPDOWN_PLAYER,
    [InputAction.AXIS_LOOK_UPDOWN_PLAYER] = InputAction.AXIS_LOOK_LEFTRIGHT_PLAYER,
    [InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE] = InputAction.AXIS_LOOK_UPDOWN_VEHICLE,
    [InputAction.AXIS_LOOK_UPDOWN_VEHICLE] = InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE
}
InputAction.EXCLUSIVE_ACTION_GROUPS = {
    ["MENU"] = {
        InputAction.MENU_ACCEPT,
        InputAction.MENU_ACTIVATE,
        InputAction.MENU_BACK,
        InputAction.MENU_CANCEL,
        InputAction.MENU_EXTRA_1,
        InputAction.MENU_EXTRA_2,
        InputAction.MENU_AXIS_LEFT_RIGHT,
        InputAction.MENU_AXIS_UP_DOWN
    }
}