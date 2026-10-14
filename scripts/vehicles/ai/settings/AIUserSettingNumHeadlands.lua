AIUserSettingNumHeadlands = {}
local AIUserSettingNumHeadlands_mt = Class(AIUserSettingNumHeadlands, AIUserSetting)
function AIUserSettingNumHeadlands.new(customMt)
    -- upvalues: (copy) AIUserSettingNumHeadlands_mt
    local self = AIUserSetting.new(customMt or AIUserSettingNumHeadlands_mt)
    self.identifier = "numHeadlands"
    self.title = g_i18n:getText("ai_settingNumHeadlands")
    self.defaultPostFix = g_i18n:getText("ai_settingDefaultPostFix")
    return self
end
function AIUserSettingNumHeadlands:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
    local numHeadlands = AIUserSettingNumHeadlands:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
    if fieldCourseSettings == nil then
        numHeadlands.value = numHeadlands.loadedValue or 1
        numHeadlands.min = 1
        numHeadlands.max = 5
        numHeadlands.step = 1
    else
        numHeadlands.value = numHeadlands.loadedValue or fieldCourseSettings.numHeadlands
        if usesDefaultFieldCourseSettings then
            numHeadlands.defaultValue = fieldCourseSettings.numHeadlands
        end
        if mode == AIModeSelection.MODE.WORKER then
            local numHeadlands = numHeadlands.defaultValue or fieldCourseSettings.numHeadlands
            numHeadlands.min = numHeadlands
            numHeadlands.max = math.ceil(numHeadlands * 2)
        else
            numHeadlands.min = 1
            numHeadlands.max = math.ceil((numHeadlands.defaultValue or fieldCourseSettings.numHeadlands) * 2)
        end
        numHeadlands.step = 1
    end
    numHeadlands.useSlider = true
    numHeadlands.loadedValue = nil
    return numHeadlands
end
function AIUserSettingNumHeadlands.apply(_, settingData, fieldCourseSettings, _)
    fieldCourseSettings.numHeadlands = settingData.value
end
function AIUserSettingNumHeadlands.adjustToCourse(_, settingData, fieldCourse, _)
    local numCreatedBoundaries = #fieldCourse.courseField.headlandBoundaries
    if numCreatedBoundaries < settingData.value then
        settingData.value = numCreatedBoundaries
    end
end
function AIUserSettingNumHeadlands:registerXMLPath(schema, path)
    schema:register(XMLValueType.INT, string.format("%s#%s", path, self.identifier), self.title)
end