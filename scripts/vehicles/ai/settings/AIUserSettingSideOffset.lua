AIUserSettingSideOffset = {}
local AIUserSettingSideOffset_mt = Class(AIUserSettingSideOffset, AIUserSetting)
function AIUserSettingSideOffset.new(customMt)
    -- upvalues: (copy) AIUserSettingSideOffset_mt
    local self = AIUserSetting.new(customMt or AIUserSettingSideOffset_mt)
    self.identifier = "sideOffset"
    self.title = g_i18n:getText("ai_settingSideOffset")
    self.unitText = g_i18n:getText("unit_mShort")
    self.defaultPostFix = g_i18n:getText("ai_settingDefaultPostFix")
    self.inputDelay = 100
    return self
end
function AIUserSettingSideOffset:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
    settingData = AIUserSettingSideOffset:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
    function settingData.callback(_, value, _)
        -- upvalues: (ref) settingData
        settingData.value = value
        if type(value) == "string" then
            settingData.value = tonumber(string.split(value, " ")[1])
        end
        return false
    end
    settingData.step = 0.1
    settingData.max = 5
    settingData.min = -settingData.max
    if fieldCourseSettings == nil then
        settingData.value = MathUtil.round(settingData.loadedValue or 0, 1)
    else
        settingData.value = MathUtil.round(settingData.loadedValue or fieldCourseSettings.sideOffset, 1)
        if usesDefaultFieldCourseSettings then
            settingData.defaultValue = fieldCourseSettings.sideOffset
        end
    end
    settingData.loadedValue = nil
    return settingData
end
function AIUserSettingSideOffset.apply(_, settingData, fieldCourseSettings, _)
    fieldCourseSettings.sideOffset = settingData.value
end