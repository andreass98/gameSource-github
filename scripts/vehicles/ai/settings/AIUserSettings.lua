AIUserSettings = {}
local AIUserSettings_mt = Class(AIUserSettings)
source("dataS/scripts/vehicles/ai/settings/AIUserSetting.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingCruiseControl.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingHeadlandFirst.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingImplementWidth.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingNumHeadlands.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingShowLines.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingSideOffset.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingSkipNumLines.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingWorkDirection.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingWorkHeadlands.lua")
AIUserSettings.SETTINGS = {}
AIUserSettings.SETTINGS[AIModeSelection.MODE.WORKER] = {
    AIUserSettingImplementWidth.new(),
    AIUserSettingNumHeadlands.new(),
    AIUserSettingWorkDirection.new(),
    AIUserSettingWorkHeadlands.new(),
    AIUserSettingHeadlandFirst.new(),
    AIUserSettingSkipNumLines.new()
}
AIUserSettings.SETTINGS[AIModeSelection.MODE.STEERING_ASSIST] = {
    AIUserSettingImplementWidth.new(),
    AIUserSettingNumHeadlands.new(),
    AIUserSettingWorkDirection.new(),
    AIUserSettingSideOffset.new(),
    AIUserSettingShowLines.new(),
    AIUserSettingCruiseControl.new()
}
function AIUserSettings.new(fieldCourseSettings)
    -- upvalues: (copy) AIUserSettings_mt
    local self = setmetatable({}, AIUserSettings_mt)
    self.settings = {}
    for mode, settings in pairs(AIUserSettings.SETTINGS) do
        self.settings[mode] = {}
        for settingIndex, setting in ipairs(settings) do
            self.settings[mode][settingIndex] = setting:init(nil, fieldCourseSettings, mode, true)
        end
    end
    return self
end
function AIUserSettings:reinitialize(fieldCourseSettings, usesDefaultFieldCourseSettings)
    for mode, settings in pairs(self.settings) do
        for settingIndex, settingData in ipairs(settings) do
            settings[settingIndex] = settingData.setting:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
        end
    end
end
function AIUserSettings:apply(fieldCourseSettings, mode)
    for settingMode, settings in pairs(self.settings) do
        if settingMode ~= mode then
            for settingIndex, settingData in ipairs(settings) do
                settingData.setting:apply(settingData, fieldCourseSettings, mode)
            end
        end
    end
    for settingMode, settings in ipairs(self.settings[mode]) do
        settings.setting:apply(settings, fieldCourseSettings, mode)
    end
end
function AIUserSettings:adjustToCourse(fieldCourse, mode)
    for settingIndex, settingData in ipairs(self.settings[mode]) do
        if settingData.setting.adjustToCourse ~= nil then
            settingData.setting:adjustToCourse(settingData, fieldCourse, mode)
        end
    end
end
function AIUserSettings:loadFromXML(xmlFile, basePath)
    for mode, settings in pairs(self.settings) do
        local key = basePath .. string.format(".%s", string.lower(AIModeSelection.MODE.getName(mode)))
        for _, settingData in ipairs(settings) do
            settingData.setting:loadFromXML(xmlFile, key, settingData)
        end
    end
end
function AIUserSettings:saveToXML(xmlFile, basePath)
    for mode, settings in pairs(self.settings) do
        local key = basePath .. string.format(".%s", string.lower(AIModeSelection.MODE.getName(mode)))
        for _, settingData in ipairs(settings) do
            settingData.setting:saveToXML(xmlFile, key, settingData)
        end
    end
end
function AIUserSettings.registerXMLPaths(schema, basePath)
    for mode, settings in pairs(AIUserSettings.SETTINGS) do
        local key = basePath .. string.format(".%s", string.lower(AIModeSelection.MODE.getName(mode)))
        for _, setting in ipairs(settings) do
            setting:registerXMLPath(schema, key)
        end
    end
end