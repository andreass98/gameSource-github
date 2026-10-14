PrecisionFarmingSettings = {}
PrecisionFarmingSettings.MOD_NAME = g_currentModName
source(g_currentModDirectory .. "scripts/events/PrecisionFarmingSettingsInitialEvent.lua")
source(g_currentModDirectory .. "scripts/events/PrecisionFarmingSettingsEvent.lua")
local PrecisionFarmingSettings_mt = Class(PrecisionFarmingSettings)
function PrecisionFarmingSettings.new(precisionFarming, customMt)
    -- upvalues: (copy) PrecisionFarmingSettings_mt
    local self = setmetatable({}, customMt or PrecisionFarmingSettings_mt)
    self.precisionFarming = precisionFarming
    self.elementsCreated = false
    self.settingsHeadline = g_i18n:getText("ui_header")
    self.settings = {}
    self.settingIndexNumBits = 1
    return self
end
function PrecisionFarmingSettings:addSetting(name, title, description, callback, callbackTarget, default, isCheckbox, optionTexts, isServerSetting)
    local setting = {
        ["name"] = name,
        ["title"] = title,
        ["description"] = description
    }
    if default == nil then
        if isCheckbox then
            setting.state = false
        else
            setting.state = 0
        end
    else
        setting.state = default
    end
    setting.callback = callback
    setting.callbackTarget = callbackTarget
    setting.isCheckbox = isCheckbox
    setting.optionTexts = optionTexts
    setting.isServerSetting = Utils.getNoNil(isServerSetting, false)
    setting.element = nil
    setting.index = #self.settings + 1
    table.insert(self.settings, setting)
    self.settingIndexNumBits = MathUtil.getNumRequiredBits(#self.settings)
    self:loadSettings()
    self:onSettingChanged(setting, true)
end
function PrecisionFarmingSettings:sendInitialClientState(connection, _, _)
    connection:sendEvent(PrecisionFarmingSettingsInitialEvent.new(self.settings))
end
function PrecisionFarmingSettings:onSettingChanged(setting, noEventSend)
    if setting.callback == nil or setting.callbackTarget ~= nil then
        if setting.callback ~= nil and setting.callbackTarget ~= nil then
            setting.callback(setting.callbackTarget, setting.state)
        end
    else
        setting.callback(setting.state)
    end
    self:saveSettings()
    if setting.isServerSetting then
        PrecisionFarmingSettingsEvent.sendEvent(setting, noEventSend)
    end
end
function PrecisionFarmingSettings:saveSettings()
    if g_savegameXML ~= nil then
        local i = 1
        for i = i, #self.settings do
            local setting = self.settings[i]
            if setting.isCheckbox then
                setXMLBool(g_savegameXML, string.format("gameSettings.precisionFarming.settings.%s#state", setting.name), setting.state)
            else
                setXMLInt(g_savegameXML, string.format("gameSettings.precisionFarming.settings.%s#state", setting.name), setting.state)
            end
        end
    end
    g_gameSettings:save()
end
function PrecisionFarmingSettings:loadSettings()
    if g_savegameXML ~= nil then
        local i = 1
        for i = i, #self.settings do
            local setting = self.settings[i]
            if setting.isCheckbox then
                setting.state = Utils.getNoNil(getXMLBool(g_savegameXML, string.format("gameSettings.precisionFarming.settings.%s#state", setting.name)), setting.state)
            else
                setting.state = Utils.getNoNil(getXMLInt(g_savegameXML, string.format("gameSettings.precisionFarming.settings.%s#state", setting.name)), setting.state)
            end
        end
    end
end
function PrecisionFarmingSettings:onClickCheckbox(state, checkboxElement)
    local i = 1
    for i = i, #self.settings do
        local setting = self.settings[i]
        if setting.element == checkboxElement then
            setting.state = state == CheckedOptionElement.STATE_CHECKED
            self:onSettingChanged(setting)
        end
    end
end
function PrecisionFarmingSettings:onClickMultiOption(state, optionElement)
    local i = 1
    for i = i, #self.settings do
        local setting = self.settings[i]
        if setting.element == optionElement then
            setting.state = state
            self:onSettingChanged(setting)
        end
    end
end
function PrecisionFarmingSettings:addSettingsToLayout(_, layout, settings, isServerSetting)
    local numSettings = 0
    local i = 1
    local binaryOptionElem = #settings
    local multiTextOptionElem = 1
    for i = i, binaryOptionElem, multiTextOptionElem do
        if settings[i].isServerSetting == isServerSetting then
        end
    end
    if numSettings > 0 then
        local i = 1
        local binaryOptionElem = #layout.elements
        local multiTextOptionElem = 1
        for i = i, binaryOptionElem, multiTextOptionElem do
            local setting = layout.elements[i]
            if setting:isa(TextElement) then
                setting:clone(layout):setText(self.settingsHeadline)
                break
            end
        end
        local binaryOptionElem = nil
        local multiTextOptionElem = nil
        local header = 1
        local i = #layout.elements
        local setting = 1
        for header = header, i, setting do
            local elem = layout.elements[header]
            if elem:isa(BitmapElement) and #elem.elements > 0 then
                if elem.elements[1]:isa(BinaryOptionElement) and binaryOptionElem == nil then
                    binaryOptionElem = elem
                elseif elem.elements[1]:isa(MultiTextOptionElement) then
                    if multiTextOptionElem ~= nil then
                        elem = multiTextOptionElem
                    end
                else
                    elem = multiTextOptionElem
                end
            else
                elem = multiTextOptionElem
            end
            if binaryOptionElem ~= nil and elem ~= nil then
                multiTextOptionElem = elem
                break
            end
            multiTextOptionElem = elem
        end
        local header = 1
        local i = #self.settings
        local setting = 1
        for header = header, i, setting do
            local elem = self.settings[header]
            if elem.isServerSetting == isServerSetting then
                if elem.isCheckbox then
                    if binaryOptionElem ~= nil then
                        elem.parent = binaryOptionElem:clone(layout, false)
                        elem.element = elem.parent.elements[1]
                        function elem.element.onClickCallback(_, ...)
                            -- upvalues: (copy) self
                            self:onClickCheckbox(...)
                        end
                        elem.element:setIsChecked(elem.state, true)
                        elem.element:setDisabled(false)
                        elem.element:updateSelection()
                        elem.parent.elements[2]:setText(elem.title)
                        elem.element.elements[1]:setText(elem.description)
                    end
                elseif multiTextOptionElem ~= nil then
                    elem.parent = multiTextOptionElem:clone(layout, false)
                    elem.element = elem.parent.elements[1]
                    elem.element:setTexts(elem.optionTexts)
                    function elem.element.onClickCallback(_, ...)
                        -- upvalues: (copy) self
                        self:onClickMultiOption(...)
                    end
                    elem.element:setState(elem.state)
                    elem.parent.elements[2]:setText(elem.title)
                    elem.element.elements[1]:setText(elem.description)
                end
            end
        end
        layout:invalidateLayout()
    end
end
function PrecisionFarmingSettings:overwriteGameFunctions(pfModule)
    pfModule:overwriteGameFunction(InGameMenuSettingsFrame, "onFrameOpen", function(superFunc, frame, element)
        -- upvalues: (copy) self
        superFunc(frame, element)
        if not self.elementsCreated then
            self:addSettingsToLayout(frame, frame.generalSettingsLayout, self.settings, false)
            self:addSettingsToLayout(frame, frame.gameSettingsLayout, self.settings, true)
            self.elementsCreated = true
            if frame.checkLimeRequired ~= nil then
                frame.checkLimeRequired.parent:setVisible(false)
                frame.gameSettingsLayout:invalidateLayout()
            end
        end
    end)
end