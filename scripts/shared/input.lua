Input = {}
Input.keyPressedState = {}
Input.mouseButtonPressedState = {}
Input.keyPressedThisFrame = {}
Input.mouseButtonPressedThisFrame = {}
function Input.updateFrameEnd()
    for key, _ in pairs(Input.keyPressedThisFrame) do
        Input.keyPressedThisFrame[key] = false
    end
    for key, _ in pairs(Input.mouseButtonPressedThisFrame) do
        Input.mouseButtonPressedThisFrame[key] = false
    end
end
function Input.updateKeyState(key, isDown)
    if isDown then
        Input.keyPressedState[key] = true
        Input.keyPressedThisFrame[key] = true
    else
        Input.keyPressedState[key] = false
    end
end
function Input.isKeyPressed(key)
    return Input.keyPressedState[key] or Input.keyPressedThisFrame[key]
end
function Input.updateMouseButtonState(button, isDown)
    if isDown then
        Input.mouseButtonPressedState[button] = true
        Input.mouseButtonPressedThisFrame[button] = true
    else
        Input.mouseButtonPressedState[button] = false
    end
end
function Input.isMouseButtonPressed(button)
    return Input.mouseButtonPressedState[button] or Input.mouseButtonPressedThisFrame[button]
end
Input.MOD_LSHIFT = 1
Input.MOD_RSHIFT = 2
Input.MOD_LCTRL = 64
Input.MOD_RCTRL = 128
Input.MOD_LALT = 256
Input.MOD_RALT = 512
Input.MOD_LMETA = 1024
Input.MOD_RMETA = 2048
Input.MOD_NUM = 4096
Input.MOD_CAPS = 8192
Input.MOD_MODE = 16384
Input.MOD_SHIFT = 3
Input.MOD_CTRL = 192
Input.MOD_ALT = 768
Input.MOD_META = 3072
Input.keyIdToIdName = {}
Input.keyIdIsModifier = {}
function Input.addKeyDefine(idName, id, isModifier)
    if Input[idName] == nil and Input.keyIdToIdName[id] == nil then
        Input.keyIdToIdName[id] = idName
        Input.keyIdIsModifier[id] = isModifier
        return id
    end
    printError("Error: Duplicate key define " .. idName .. " = " .. id)
end
Input.mouseButtonIdToIdName = {}
function Input.addMouseButtonDefine(idName, id)
    if Input[idName] == nil and Input.mouseButtonIdToIdName[id] == nil then
        Input.mouseButtonIdToIdName[id] = idName
        return id
    end
    printError("Error: Duplicate mouse button define " .. idName .. " = " .. id)
end
Input.axisIdToIdName = {}
Input.axisIdNameToId = {}
function Input.addFullAxisDefine(idName, id, isOverwrite)
    if Input[idName] == nil and (isOverwrite or Input.axisIdToIdName[id] == nil) then
        if isOverwrite and Input.axisIdToIdName[id] == nil then
            printError("Error: Missing axis define to overwrite  for " .. idName .. " = " .. id)
        end
        Input.axisIdNameToId[idName] = id
        Input.axisIdToIdName[id] = idName
        Input[idName .. "-"] = id
        Input.axisIdNameToId[idName .. "-"] = id
        Input[idName .. "+"] = id
        Input.axisIdNameToId[idName .. "+"] = id
        return id
    end
    printError("Error: Duplicate axis define " .. idName .. " = " .. id)
end
function Input.addHalfAxisDefine(idName, id, isOverwrite)
    if Input[idName] == nil and (isOverwrite or Input.axisIdToIdName[id] == nil) then
        if isOverwrite and Input.axisIdToIdName[id] == nil then
            printError("Error: Missing axis define to overwrite  for " .. idName .. " = " .. id)
        end
        Input.axisIdNameToId[idName] = id
        Input.axisIdToIdName[id] = idName
        return id
    end
    printError("Error: Duplicate axis define " .. idName .. " = " .. id)
end
Input.buttonIdToIdName = {}
Input.buttonIdNameToId = {}
function Input.addButtonDefine(idName, id)
    if Input[idName] == nil and Input.buttonIdToIdName[id] == nil then
        Input[idName] = id
        Input.buttonIdNameToId[idName] = id
        Input.buttonIdToIdName[id] = idName
        return id
    end
    printError("Error: Duplicate button define " .. idName .. " = " .. id)
end
Input.KEY_backspace = Input.addKeyDefine("KEY_backspace", 8)
Input.KEY_tab = Input.addKeyDefine("KEY_tab", 9)
Input.KEY_clear = Input.addKeyDefine("KEY_clear", 12)
Input.KEY_return = Input.addKeyDefine("KEY_return", 13)
Input.KEY_pause = Input.addKeyDefine("KEY_pause", 19)
Input.KEY_esc = Input.addKeyDefine("KEY_esc", 27)
Input.KEY_space = Input.addKeyDefine("KEY_space", 32)
Input.KEY_exclaim = Input.addKeyDefine("KEY_exclaim", 33)
Input.KEY_quotedbl = Input.addKeyDefine("KEY_quotedbl", 34)
Input.KEY_hash = Input.addKeyDefine("KEY_hash", 35)
Input.KEY_dollar = Input.addKeyDefine("KEY_dollar", 36)
Input.KEY_ampersand = Input.addKeyDefine("KEY_ampersand", 38)
Input.KEY_quote = Input.addKeyDefine("KEY_quote", 39)
Input.KEY_leftparen = Input.addKeyDefine("KEY_leftparen", 40)
Input.KEY_rightparen = Input.addKeyDefine("KEY_rightparen", 41)
Input.KEY_asterisk = Input.addKeyDefine("KEY_asterisk", 42)
Input.KEY_plus = Input.addKeyDefine("KEY_plus", 43)
Input.KEY_comma = Input.addKeyDefine("KEY_comma", 44)
Input.KEY_minus = Input.addKeyDefine("KEY_minus", 45)
Input.KEY_period = Input.addKeyDefine("KEY_period", 46)
Input.KEY_slash = Input.addKeyDefine("KEY_slash", 47)
Input.KEY_0 = Input.addKeyDefine("KEY_0", 48)
Input.KEY_1 = Input.addKeyDefine("KEY_1", 49)
Input.KEY_2 = Input.addKeyDefine("KEY_2", 50)
Input.KEY_3 = Input.addKeyDefine("KEY_3", 51)
Input.KEY_4 = Input.addKeyDefine("KEY_4", 52)
Input.KEY_5 = Input.addKeyDefine("KEY_5", 53)
Input.KEY_6 = Input.addKeyDefine("KEY_6", 54)
Input.KEY_7 = Input.addKeyDefine("KEY_7", 55)
Input.KEY_8 = Input.addKeyDefine("KEY_8", 56)
Input.KEY_9 = Input.addKeyDefine("KEY_9", 57)
Input.KEY_colon = Input.addKeyDefine("KEY_colon", 58)
Input.KEY_semicolon = Input.addKeyDefine("KEY_semicolon", 59)
Input.KEY_less = Input.addKeyDefine("KEY_less", 60)
Input.KEY_equals = Input.addKeyDefine("KEY_equals", 61)
Input.KEY_greater = Input.addKeyDefine("KEY_greater", 62)
Input.KEY_question = Input.addKeyDefine("KEY_question", 63)
Input.KEY_at = Input.addKeyDefine("KEY_at", 64)
Input.KEY_leftbracket = Input.addKeyDefine("KEY_leftbracket", 91)
Input.KEY_backslash = Input.addKeyDefine("KEY_backslash", 92)
Input.KEY_rightbracket = Input.addKeyDefine("KEY_rightbracket", 93)
Input.KEY_caret = Input.addKeyDefine("KEY_caret", 94)
Input.KEY_underscore = Input.addKeyDefine("KEY_underscore", 95)
Input.KEY_backquote = Input.addKeyDefine("KEY_backquote", 96)
Input.KEY_a = Input.addKeyDefine("KEY_a", 97)
Input.KEY_b = Input.addKeyDefine("KEY_b", 98)
Input.KEY_c = Input.addKeyDefine("KEY_c", 99)
Input.KEY_d = Input.addKeyDefine("KEY_d", 100)
Input.KEY_e = Input.addKeyDefine("KEY_e", 101)
Input.KEY_f = Input.addKeyDefine("KEY_f", 102)
Input.KEY_g = Input.addKeyDefine("KEY_g", 103)
Input.KEY_h = Input.addKeyDefine("KEY_h", 104)
Input.KEY_i = Input.addKeyDefine("KEY_i", 105)
Input.KEY_j = Input.addKeyDefine("KEY_j", 106)
Input.KEY_k = Input.addKeyDefine("KEY_k", 107)
Input.KEY_l = Input.addKeyDefine("KEY_l", 108)
Input.KEY_m = Input.addKeyDefine("KEY_m", 109)
Input.KEY_n = Input.addKeyDefine("KEY_n", 110)
Input.KEY_o = Input.addKeyDefine("KEY_o", 111)
Input.KEY_p = Input.addKeyDefine("KEY_p", 112)
Input.KEY_q = Input.addKeyDefine("KEY_q", 113)
Input.KEY_r = Input.addKeyDefine("KEY_r", 114)
Input.KEY_s = Input.addKeyDefine("KEY_s", 115)
Input.KEY_t = Input.addKeyDefine("KEY_t", 116)
Input.KEY_u = Input.addKeyDefine("KEY_u", 117)
Input.KEY_v = Input.addKeyDefine("KEY_v", 118)
Input.KEY_w = Input.addKeyDefine("KEY_w", 119)
Input.KEY_x = Input.addKeyDefine("KEY_x", 120)
Input.KEY_y = Input.addKeyDefine("KEY_y", 121)
Input.KEY_z = Input.addKeyDefine("KEY_z", 122)
Input.KEY_delete = Input.addKeyDefine("KEY_delete", 127)
Input.KEY_KP_0 = Input.addKeyDefine("KEY_KP_0", 256)
Input.KEY_KP_1 = Input.addKeyDefine("KEY_KP_1", 257)
Input.KEY_KP_2 = Input.addKeyDefine("KEY_KP_2", 258)
Input.KEY_KP_3 = Input.addKeyDefine("KEY_KP_3", 259)
Input.KEY_KP_4 = Input.addKeyDefine("KEY_KP_4", 260)
Input.KEY_KP_5 = Input.addKeyDefine("KEY_KP_5", 261)
Input.KEY_KP_6 = Input.addKeyDefine("KEY_KP_6", 262)
Input.KEY_KP_7 = Input.addKeyDefine("KEY_KP_7", 263)
Input.KEY_KP_8 = Input.addKeyDefine("KEY_KP_8", 264)
Input.KEY_KP_9 = Input.addKeyDefine("KEY_KP_9", 265)
Input.KEY_KP_period = Input.addKeyDefine("KEY_KP_period", 266)
Input.KEY_KP_divide = Input.addKeyDefine("KEY_KP_divide", 267)
Input.KEY_KP_multiply = Input.addKeyDefine("KEY_KP_multiply", 268)
Input.KEY_KP_minus = Input.addKeyDefine("KEY_KP_minus", 269)
Input.KEY_KP_plus = Input.addKeyDefine("KEY_KP_plus", 270)
Input.KEY_KP_enter = Input.addKeyDefine("KEY_KP_enter", 271)
Input.KEY_KP_equals = Input.addKeyDefine("KEY_KP_equals", 272)
Input.KEY_up = Input.addKeyDefine("KEY_up", 273)
Input.KEY_down = Input.addKeyDefine("KEY_down", 274)
Input.KEY_right = Input.addKeyDefine("KEY_right", 275)
Input.KEY_left = Input.addKeyDefine("KEY_left", 276)
Input.KEY_insert = Input.addKeyDefine("KEY_insert", 277)
Input.KEY_home = Input.addKeyDefine("KEY_home", 278)
Input.KEY_end = Input.addKeyDefine("KEY_end", 279)
Input.KEY_pageup = Input.addKeyDefine("KEY_pageup", 280)
Input.KEY_pagedown = Input.addKeyDefine("KEY_pagedown", 281)
Input.KEY_f1 = Input.addKeyDefine("KEY_f1", 282)
Input.KEY_f2 = Input.addKeyDefine("KEY_f2", 283)
Input.KEY_f3 = Input.addKeyDefine("KEY_f3", 284)
Input.KEY_f4 = Input.addKeyDefine("KEY_f4", 285)
Input.KEY_f5 = Input.addKeyDefine("KEY_f5", 286)
Input.KEY_f6 = Input.addKeyDefine("KEY_f6", 287)
Input.KEY_f7 = Input.addKeyDefine("KEY_f7", 288)
Input.KEY_f8 = Input.addKeyDefine("KEY_f8", 289)
Input.KEY_f9 = Input.addKeyDefine("KEY_f9", 290)
Input.KEY_f10 = Input.addKeyDefine("KEY_f10", 291)
Input.KEY_f11 = Input.addKeyDefine("KEY_f11", 292)
Input.KEY_f12 = Input.addKeyDefine("KEY_f12", 293)
Input.KEY_f13 = Input.addKeyDefine("KEY_f13", 294)
Input.KEY_f14 = Input.addKeyDefine("KEY_f14", 295)
Input.KEY_f15 = Input.addKeyDefine("KEY_f15", 296)
Input.KEY_rshift = Input.addKeyDefine("KEY_rshift", 303, true)
Input.KEY_lshift = Input.addKeyDefine("KEY_lshift", 304, true)
Input.KEY_rctrl = Input.addKeyDefine("KEY_rctrl", 305, true)
Input.KEY_lctrl = Input.addKeyDefine("KEY_lctrl", 306, true)
Input.KEY_ralt = Input.addKeyDefine("KEY_ralt", 307, true)
Input.KEY_lalt = Input.addKeyDefine("KEY_lalt", 308, true)
Input.KEY_print = Input.addKeyDefine("KEY_print", 316)
Input.KEY_scrolllock = Input.addKeyDefine("KEY_scrolllock", 302)
Input.KEY_lwin = Input.addKeyDefine("KEY_lwin", 311)
Input.KEY_rwin = Input.addKeyDefine("KEY_rwin", 312)
Input.KEY_menu = Input.addKeyDefine("KEY_menu", 319)
Input.MOUSE_BUTTON_NONE = Input.addMouseButtonDefine("MOUSE_BUTTON_NONE", 0)
Input.MOUSE_BUTTON_LEFT = Input.addMouseButtonDefine("MOUSE_BUTTON_LEFT", 1)
Input.MOUSE_BUTTON_MIDDLE = Input.addMouseButtonDefine("MOUSE_BUTTON_MIDDLE", 2)
Input.MOUSE_BUTTON_RIGHT = Input.addMouseButtonDefine("MOUSE_BUTTON_RIGHT", 3)
Input.MOUSE_BUTTON_WHEEL_UP = Input.addMouseButtonDefine("MOUSE_BUTTON_WHEEL_UP", 4)
Input.MOUSE_BUTTON_WHEEL_DOWN = Input.addMouseButtonDefine("MOUSE_BUTTON_WHEEL_DOWN", 5)
Input.MOUSE_BUTTON_X1 = Input.addMouseButtonDefine("MOUSE_BUTTON_X1", 6)
Input.MOUSE_BUTTON_X2 = Input.addMouseButtonDefine("MOUSE_BUTTON_X2", 7)
Input.AXIS_X = Input.addFullAxisDefine("AXIS_X", 0)
Input.AXIS_1 = Input.addFullAxisDefine("AXIS_1", 0, true)
Input.AXIS_Y = Input.addFullAxisDefine("AXIS_Y", 1)
Input.AXIS_2 = Input.addFullAxisDefine("AXIS_2", 1, true)
Input.AXIS_Z = Input.addFullAxisDefine("AXIS_Z", 2)
Input.AXIS_3 = Input.addFullAxisDefine("AXIS_3", 2, true)
Input.AXIS_W = Input.addFullAxisDefine("AXIS_W", 3)
Input.AXIS_4 = Input.addFullAxisDefine("AXIS_4", 3, true)
Input.AXIS_5 = Input.addFullAxisDefine("AXIS_5", 4)
Input.AXIS_6 = Input.addFullAxisDefine("AXIS_6", 5)
Input.AXIS_7 = Input.addFullAxisDefine("AXIS_7", 6)
Input.AXIS_8 = Input.addFullAxisDefine("AXIS_8", 7)
Input.AXIS_9 = Input.addFullAxisDefine("AXIS_9", 8)
Input.AXIS_10 = Input.addFullAxisDefine("AXIS_10", 9)
Input.AXIS_11 = Input.addFullAxisDefine("AXIS_11", 10)
Input.AXIS_12 = Input.addFullAxisDefine("AXIS_12", 11)
Input.AXIS_13 = Input.addFullAxisDefine("AXIS_13", 12)
Input.AXIS_14 = Input.addFullAxisDefine("AXIS_14", 13)
Input.MAX_NUM_AXES = 14
function Input.isHalfAxis(axis)
    return axis ~= nil and Input.HALF_AXIS_1 <= axis
end
Input.HALF_AXIS_1 = Input.addHalfAxisDefine("HALF_AXIS_1", Input.AXIS_11, true)
Input.HALF_AXIS_2 = Input.addHalfAxisDefine("HALF_AXIS_2", Input.AXIS_12, true)
Input.HALF_AXIS_3 = Input.addHalfAxisDefine("HALF_AXIS_3", Input.AXIS_13, true)
Input.HALF_AXIS_4 = Input.addHalfAxisDefine("HALF_AXIS_4", Input.AXIS_14, true)
Input.MAX_NUM_BUTTONS = 128
Input.BUTTON_1 = Input.addButtonDefine("BUTTON_1", 0)
Input.BUTTON_2 = Input.addButtonDefine("BUTTON_2", 1)
Input.BUTTON_3 = Input.addButtonDefine("BUTTON_3", 2)
Input.BUTTON_4 = Input.addButtonDefine("BUTTON_4", 3)
Input.BUTTON_5 = Input.addButtonDefine("BUTTON_5", 4)
Input.BUTTON_6 = Input.addButtonDefine("BUTTON_6", 5)
Input.BUTTON_7 = Input.addButtonDefine("BUTTON_7", 6)
Input.BUTTON_8 = Input.addButtonDefine("BUTTON_8", 7)
Input.BUTTON_9 = Input.addButtonDefine("BUTTON_9", 8)
Input.BUTTON_10 = Input.addButtonDefine("BUTTON_10", 9)
Input.BUTTON_11 = Input.addButtonDefine("BUTTON_11", 10)
Input.BUTTON_12 = Input.addButtonDefine("BUTTON_12", 11)
Input.BUTTON_13 = Input.addButtonDefine("BUTTON_13", 12)
Input.BUTTON_14 = Input.addButtonDefine("BUTTON_14", 13)
Input.BUTTON_15 = Input.addButtonDefine("BUTTON_15", 14)
Input.BUTTON_16 = Input.addButtonDefine("BUTTON_16", 15)
Input.BUTTON_17 = Input.addButtonDefine("BUTTON_17", 16)
Input.BUTTON_18 = Input.addButtonDefine("BUTTON_18", 17)
Input.BUTTON_19 = Input.addButtonDefine("BUTTON_19", 18)
Input.BUTTON_20 = Input.addButtonDefine("BUTTON_20", 19)
Input.BUTTON_21 = Input.addButtonDefine("BUTTON_21", 20)
Input.BUTTON_22 = Input.addButtonDefine("BUTTON_22", 21)
Input.BUTTON_23 = Input.addButtonDefine("BUTTON_23", 22)
Input.BUTTON_24 = Input.addButtonDefine("BUTTON_24", 23)
Input.BUTTON_25 = Input.addButtonDefine("BUTTON_25", 24)
Input.BUTTON_26 = Input.addButtonDefine("BUTTON_26", 25)
Input.BUTTON_27 = Input.addButtonDefine("BUTTON_27", 26)
Input.BUTTON_28 = Input.addButtonDefine("BUTTON_28", 27)
Input.BUTTON_29 = Input.addButtonDefine("BUTTON_29", 28)
Input.BUTTON_30 = Input.addButtonDefine("BUTTON_30", 29)
Input.BUTTON_31 = Input.addButtonDefine("BUTTON_31", 30)
Input.BUTTON_32 = Input.addButtonDefine("BUTTON_32", 31)
Input.BUTTON_33 = Input.addButtonDefine("BUTTON_33", 32)
Input.BUTTON_34 = Input.addButtonDefine("BUTTON_34", 33)
Input.BUTTON_35 = Input.addButtonDefine("BUTTON_35", 34)
Input.BUTTON_36 = Input.addButtonDefine("BUTTON_36", 35)
Input.BUTTON_37 = Input.addButtonDefine("BUTTON_37", 36)
Input.BUTTON_38 = Input.addButtonDefine("BUTTON_38", 37)
Input.BUTTON_39 = Input.addButtonDefine("BUTTON_39", 38)
Input.BUTTON_40 = Input.addButtonDefine("BUTTON_40", 39)
Input.BUTTON_41 = Input.addButtonDefine("BUTTON_41", 40)
Input.BUTTON_42 = Input.addButtonDefine("BUTTON_42", 41)
Input.BUTTON_43 = Input.addButtonDefine("BUTTON_43", 42)
Input.BUTTON_44 = Input.addButtonDefine("BUTTON_44", 43)
Input.BUTTON_45 = Input.addButtonDefine("BUTTON_45", 44)
Input.BUTTON_46 = Input.addButtonDefine("BUTTON_46", 45)
Input.BUTTON_47 = Input.addButtonDefine("BUTTON_47", 46)
Input.BUTTON_48 = Input.addButtonDefine("BUTTON_48", 47)
Input.BUTTON_49 = Input.addButtonDefine("BUTTON_49", 48)
Input.BUTTON_50 = Input.addButtonDefine("BUTTON_50", 49)
Input.BUTTON_51 = Input.addButtonDefine("BUTTON_51", 50)
Input.BUTTON_52 = Input.addButtonDefine("BUTTON_52", 51)
Input.BUTTON_53 = Input.addButtonDefine("BUTTON_53", 52)
Input.BUTTON_54 = Input.addButtonDefine("BUTTON_54", 53)
Input.BUTTON_55 = Input.addButtonDefine("BUTTON_55", 54)
Input.BUTTON_56 = Input.addButtonDefine("BUTTON_56", 55)
Input.BUTTON_57 = Input.addButtonDefine("BUTTON_57", 56)
Input.BUTTON_58 = Input.addButtonDefine("BUTTON_58", 57)
Input.BUTTON_59 = Input.addButtonDefine("BUTTON_59", 58)
Input.BUTTON_60 = Input.addButtonDefine("BUTTON_60", 59)
Input.BUTTON_61 = Input.addButtonDefine("BUTTON_61", 60)
Input.BUTTON_62 = Input.addButtonDefine("BUTTON_62", 61)
Input.BUTTON_63 = Input.addButtonDefine("BUTTON_63", 62)
Input.BUTTON_64 = Input.addButtonDefine("BUTTON_64", 63)
Input.BUTTON_65 = Input.addButtonDefine("BUTTON_65", 64)
Input.BUTTON_66 = Input.addButtonDefine("BUTTON_66", 65)
Input.BUTTON_67 = Input.addButtonDefine("BUTTON_67", 66)
Input.BUTTON_68 = Input.addButtonDefine("BUTTON_68", 67)
Input.BUTTON_69 = Input.addButtonDefine("BUTTON_69", 68)
Input.BUTTON_70 = Input.addButtonDefine("BUTTON_70", 69)
Input.BUTTON_71 = Input.addButtonDefine("BUTTON_71", 70)
Input.BUTTON_72 = Input.addButtonDefine("BUTTON_72", 71)
Input.BUTTON_73 = Input.addButtonDefine("BUTTON_73", 72)
Input.BUTTON_74 = Input.addButtonDefine("BUTTON_74", 73)
Input.BUTTON_75 = Input.addButtonDefine("BUTTON_75", 74)
Input.BUTTON_76 = Input.addButtonDefine("BUTTON_76", 75)
Input.BUTTON_77 = Input.addButtonDefine("BUTTON_77", 76)
Input.BUTTON_78 = Input.addButtonDefine("BUTTON_78", 77)
Input.BUTTON_79 = Input.addButtonDefine("BUTTON_79", 78)
Input.BUTTON_80 = Input.addButtonDefine("BUTTON_80", 79)
Input.BUTTON_81 = Input.addButtonDefine("BUTTON_81", 80)
Input.BUTTON_82 = Input.addButtonDefine("BUTTON_82", 81)
Input.BUTTON_83 = Input.addButtonDefine("BUTTON_83", 82)
Input.BUTTON_84 = Input.addButtonDefine("BUTTON_84", 83)
Input.BUTTON_85 = Input.addButtonDefine("BUTTON_85", 84)
Input.BUTTON_86 = Input.addButtonDefine("BUTTON_86", 85)
Input.BUTTON_87 = Input.addButtonDefine("BUTTON_87", 86)
Input.BUTTON_88 = Input.addButtonDefine("BUTTON_88", 87)
Input.BUTTON_89 = Input.addButtonDefine("BUTTON_89", 88)
Input.BUTTON_90 = Input.addButtonDefine("BUTTON_90", 89)
Input.BUTTON_91 = Input.addButtonDefine("BUTTON_91", 90)
Input.BUTTON_92 = Input.addButtonDefine("BUTTON_92", 91)
Input.BUTTON_93 = Input.addButtonDefine("BUTTON_93", 92)
Input.BUTTON_94 = Input.addButtonDefine("BUTTON_94", 93)
Input.BUTTON_95 = Input.addButtonDefine("BUTTON_95", 94)
Input.BUTTON_96 = Input.addButtonDefine("BUTTON_96", 95)
Input.BUTTON_97 = Input.addButtonDefine("BUTTON_97", 96)
Input.BUTTON_98 = Input.addButtonDefine("BUTTON_98", 97)
Input.BUTTON_99 = Input.addButtonDefine("BUTTON_99", 98)
Input.BUTTON_100 = Input.addButtonDefine("BUTTON_100", 99)
Input.BUTTON_101 = Input.addButtonDefine("BUTTON_101", 100)
Input.BUTTON_102 = Input.addButtonDefine("BUTTON_102", 101)
Input.BUTTON_103 = Input.addButtonDefine("BUTTON_103", 102)
Input.BUTTON_104 = Input.addButtonDefine("BUTTON_104", 103)
Input.BUTTON_105 = Input.addButtonDefine("BUTTON_105", 104)
Input.BUTTON_106 = Input.addButtonDefine("BUTTON_106", 105)
Input.BUTTON_107 = Input.addButtonDefine("BUTTON_107", 106)
Input.BUTTON_108 = Input.addButtonDefine("BUTTON_108", 107)
Input.BUTTON_109 = Input.addButtonDefine("BUTTON_109", 108)
Input.BUTTON_110 = Input.addButtonDefine("BUTTON_110", 109)
Input.BUTTON_111 = Input.addButtonDefine("BUTTON_111", 110)
Input.BUTTON_112 = Input.addButtonDefine("BUTTON_112", 111)
Input.BUTTON_113 = Input.addButtonDefine("BUTTON_113", 112)
Input.BUTTON_114 = Input.addButtonDefine("BUTTON_114", 113)
Input.BUTTON_115 = Input.addButtonDefine("BUTTON_115", 114)
Input.BUTTON_116 = Input.addButtonDefine("BUTTON_116", 115)
Input.BUTTON_117 = Input.addButtonDefine("BUTTON_117", 116)
Input.BUTTON_118 = Input.addButtonDefine("BUTTON_118", 117)
Input.BUTTON_119 = Input.addButtonDefine("BUTTON_119", 118)
Input.BUTTON_120 = Input.addButtonDefine("BUTTON_120", 119)
Input.BUTTON_121 = Input.addButtonDefine("BUTTON_121", 120)
Input.BUTTON_122 = Input.addButtonDefine("BUTTON_122", 121)
Input.BUTTON_123 = Input.addButtonDefine("BUTTON_123", 122)
Input.BUTTON_124 = Input.addButtonDefine("BUTTON_124", 123)
Input.BUTTON_125 = Input.addButtonDefine("BUTTON_125", 124)
Input.BUTTON_126 = Input.addButtonDefine("BUTTON_126", 125)
Input.BUTTON_127 = Input.addButtonDefine("BUTTON_127", 126)
Input.BUTTON_128 = Input.addButtonDefine("BUTTON_128", 127)
Input.MOD_BUTTON_1 = Input.BUTTON_5
Input.MOD_BUTTON_2 = Input.BUTTON_6