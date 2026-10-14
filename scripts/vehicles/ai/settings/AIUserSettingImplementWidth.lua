AIUserSettingImplementWidth = {}
local AIUserSettingImplementWidth_mt = Class(AIUserSettingImplementWidth, AIUserSetting)
function AIUserSettingImplementWidth.new(customMt)
    -- upvalues: (copy) AIUserSettingImplementWidth_mt
    local self = AIUserSetting.new(customMt or AIUserSettingImplementWidth_mt)
    self.identifier = "implementWidth"
    self.title = g_i18n:getText("ai_settingImplementWidth")
    self.unitText = g_i18n:getText("unit_mShort")
    self.defaultPostFix = g_i18n:getText("ai_settingDefaultPostFix")
    self.valueTexts = {}
    self.valueToTextIndex = {}
    self.min = 5
    self.max = 600
    self.step = 1
    local i = self.min
    for i = i, self.max, self.step do
        table.insert(self.valueTexts, string.format("%.1f m", i * 0.1))
        self.valueToTextIndex[i] = #self.valueTexts
    end
    self.inputDelay = 1
    return self
end
function AIUserSettingImplementWidth:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
    settingData = AIUserSettingImplementWidth:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
    function settingData.callback(_, value, _)
        -- upvalues: (ref) settingData
        settingData.value = (tonumber(string.split(value, " ")[1]) or 1) * 10
        return true
    end
    if fieldCourseSettings == nil then
        settingData.value = settingData.loadedValue or 30
        settingData.min = self.min
        settingData.max = self.max
    else
        local implementWidth = math.clamp(MathUtil.round(fieldCourseSettings.implementWidth * 10), self.min, self.max)
        settingData.value = MathUtil.round(settingData.loadedValue or implementWidth)
        if usesDefaultFieldCourseSettings then
            settingData.defaultValue = implementWidth
        end
        settingData.min = self.min
        settingData.max = self.max
    end
    settingData.loadedValue = nil
    return settingData
end
function AIUserSettingImplementWidth.apply(_, settingData, fieldCourseSettings, _)
    fieldCourseSettings.implementWidth = settingData.value * 0.1
end