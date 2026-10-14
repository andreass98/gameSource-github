AIUserSettingSkipNumLines = {}
local AIUserSettingSkipNumLines_mt = Class(AIUserSettingSkipNumLines, AIUserSetting)
function AIUserSettingSkipNumLines.new(customMt)
    -- upvalues: (copy) AIUserSettingSkipNumLines_mt
    local self = AIUserSetting.new(customMt or AIUserSettingSkipNumLines_mt)
    self.identifier = "skipNumLines"
    self.title = g_i18n:getText("ai_settingSkipNumLines")
    return self
end
function AIUserSettingSkipNumLines:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
    settingData = AIUserSettingSkipNumLines:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
    function settingData.callback(_, value, _)
        -- upvalues: (ref) settingData
        settingData.value = tonumber(value)
        return false
    end
    if fieldCourseSettings == nil then
        settingData.value = settingData.loadedValue or 0
    else
        settingData.value = settingData.loadedValue or (fieldCourseSettings.skipNumLines or 0)
    end
    settingData.min = 0
    settingData.max = 5
    settingData.step = 1
    settingData.loadedValue = nil
    return settingData
end
function AIUserSettingSkipNumLines.apply(_, settingData, fieldCourseSettings, mode)
    if mode == AIModeSelection.MODE.WORKER then
        fieldCourseSettings.skipNumLines = settingData.value
    else
        fieldCourseSettings.skipNumLines = 0
    end
end
function AIUserSettingSkipNumLines:registerXMLPath(schema, path)
    schema:register(XMLValueType.INT, string.format("%s#%s", path, self.identifier), self.title)
end