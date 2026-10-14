AIUserSettingCruiseControl = {}
local AIUserSettingCruiseControl_mt = Class(AIUserSettingCruiseControl, AIUserSetting)
function AIUserSettingCruiseControl.new(customMt)
    -- upvalues: (copy) AIUserSettingCruiseControl_mt
    local self = AIUserSetting.new(customMt or AIUserSettingCruiseControl_mt)
    self.identifier = "cruiseControl"
    self.title = g_i18n:getText("ai_settingCruiseControl")
    self.isVineyardSetting = true
    self.texts = {}
    table.insert(self.texts, g_i18n:getText("ai_settingManual"))
    table.insert(self.texts, g_i18n:getText("ai_settingAutomatic"))
    self.textMapping = {}
    self.textMapping[1] = false
    self.textMapping[2] = true
    return self
end
function AIUserSettingCruiseControl:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
    settingData = AIUserSettingCruiseControl:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
    function settingData.callback(_, value, _)
        -- upvalues: (ref) settingData
        settingData.value = value
        return false
    end
    settingData.value = g_gameSettings:getValue(GameSettings.SETTING.STEERING_ASSIST_CRUISE_CONTROL)
    return settingData
end
function AIUserSettingCruiseControl.apply(_, settingData, _, _)
    g_gameSettings:setValue(GameSettings.SETTING.STEERING_ASSIST_CRUISE_CONTROL, settingData.value, true)
end
function AIUserSettingCruiseControl:registerXMLPath(schema, path)
    schema:register(XMLValueType.BOOL, string.format("%s#%s", path, self.identifier), self.title)
end