AIUserSettingHeadlandFirst = {}
local AIUserSettingHeadlandFirst_mt = Class(AIUserSettingHeadlandFirst, AIUserSetting)
function AIUserSettingHeadlandFirst.new(customMt)
    -- upvalues: (copy) AIUserSettingHeadlandFirst_mt
    local self = AIUserSetting.new(customMt or AIUserSettingHeadlandFirst_mt)
    self.identifier = "headlandFirst"
    self.title = g_i18n:getText("ai_settingHeadlandFirst")
    self.texts = {}
    table.insert(self.texts, g_i18n:getText("ai_settingHeadlandFirstValue1"))
    table.insert(self.texts, g_i18n:getText("ai_settingHeadlandFirstValue2"))
    self.textMapping = {}
    self.textMapping[1] = false
    self.textMapping[2] = true
    return self
end
function AIUserSettingHeadlandFirst:getIsDisabled(settings)
    for _, settingData in pairs(settings) do
        if settingData.setting.identifier == "workHeadlands" and not settingData.value then
            return true
        end
    end
    return AIUserSettingHeadlandFirst:superClass().getIsDisabled(self, settings)
end
function AIUserSettingHeadlandFirst:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
    settingData = AIUserSettingHeadlandFirst:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
    function settingData.callback(_, _, index)
        -- upvalues: (ref) settingData
        settingData.value = settingData.setting.textMapping[index]
        return false
    end
    if fieldCourseSettings == nil then
        settingData.value = Utils.getNoNil(settingData.loadedValue, false)
    else
        settingData.value = Utils.getNoNil(settingData.loadedValue, fieldCourseSettings.headlandsFirst)
        if usesDefaultFieldCourseSettings then
            settingData.defaultValue = fieldCourseSettings.headlandsFirst
        end
    end
    settingData.loadedValue = nil
    return settingData
end
function AIUserSettingHeadlandFirst.apply(_, settingData, fieldCourseSettings, mode)
    if mode == AIModeSelection.MODE.WORKER then
        fieldCourseSettings.headlandsFirst = settingData.value
    end
end
function AIUserSettingHeadlandFirst:registerXMLPath(schema, path)
    schema:register(XMLValueType.BOOL, string.format("%s#%s", path, self.identifier), self.title)
end