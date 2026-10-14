AIUserSettingWorkHeadlands = {}
local AIUserSettingWorkHeadlands_mt = Class(AIUserSettingWorkHeadlands, AIUserSetting)
function AIUserSettingWorkHeadlands.new(customMt)
    -- upvalues: (copy) AIUserSettingWorkHeadlands_mt
    local self = AIUserSetting.new(customMt or AIUserSettingWorkHeadlands_mt)
    self.identifier = "workHeadlands"
    self.title = g_i18n:getText("ai_settingWorkHeadlands")
    return self
end
function AIUserSettingWorkHeadlands:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
    settingData = AIUserSettingWorkHeadlands:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
    function settingData.callback(_, value, _)
        -- upvalues: (ref) settingData
        settingData.value = value
        return false
    end
    if fieldCourseSettings == nil then
        settingData.value = Utils.getNoNil(settingData.loadedValue, true)
    else
        settingData.value = Utils.getNoNil(settingData.loadedValue, fieldCourseSettings.workHeadlands)
    end
    settingData.loadedValue = nil
    return settingData
end
function AIUserSettingWorkHeadlands.apply(_, settingData, fieldCourseSettings, mode)
    if mode == AIModeSelection.MODE.WORKER then
        fieldCourseSettings.workHeadlands = settingData.value
    else
        fieldCourseSettings.workHeadlands = true
    end
end
function AIUserSettingWorkHeadlands:onSettingsChanged(settingData, otherSettings)
    AIUserSettingWorkHeadlands:superClass().onSettingsChanged(self, settingData, otherSettings)
    for _, otherSettingData in pairs(otherSettings) do
        if otherSettingData.setting.identifier == "headlandFirst" then
            if settingData.value then
                otherSettingData.value = Utils.getNoNil(otherSettingData.defaultValue, false)
            else
                otherSettingData.value = false
            end
        end
    end
    return true
end
function AIUserSettingWorkHeadlands:registerXMLPath(schema, path)
    schema:register(XMLValueType.BOOL, string.format("%s#%s", path, self.identifier), self.title)
end