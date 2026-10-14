InputHelpDisplayExtension = {}
InputHelpDisplayExtension.MOD_NAME = g_currentModName
InputHelpDisplayExtension.MOD_DIR = g_currentModDirectory
local InputHelpDisplayExtension_mt = Class(InputHelpDisplayExtension)
function InputHelpDisplayExtension.new(precisionFarming, customMt)
    -- upvalues: (copy) InputHelpDisplayExtension_mt
    local self = setmetatable({}, customMt or InputHelpDisplayExtension_mt)
    self.isEnabled = true
    self.precisionFarming = precisionFarming
    self.headline = utf8ToUpper(g_i18n:getText("ui_header"))
    self.precisionFarming:addSetting("inputHelpDisplay", g_i18n:getText("settingTitle_inputHelpDisplay"), g_i18n:getText("settingDescription_inputHelpDisplay"), self.onInputHelpDisplaySettingChanged, self, self.isEnabled, true)
    return self
end
function InputHelpDisplayExtension:onInputHelpDisplaySettingChanged(state)
    self.isEnabled = state
end
function InputHelpDisplayExtension:overwriteGameFunctions(pfModule)
    pfModule:overwriteGameFunction(InputHelpDisplay, "draw", function(superFunc, _self, offsetX, offsetY)
        -- upvalues: (copy) self
        if self.isEnabled then
            if _self:getVisible() then
                superFunc(_self, offsetX, offsetY)
            else
                local posX, posY = _self:getPosition()
                local numElements = 0
                local posX = posX + (offsetX or 0)
                local helpExtensionTotalHeight, _ = _self:drawVehicleSchema(posX, posY + (offsetY or 0), false)
                table.sort(_self.helpExtensions, function(a, b)
                    return a.priority < b.priority
                end)
                local helpExtensionTotalHeight = 0
                local i = #_self.helpExtensions
                for i = i, 1, -1 do
                    local height = _self.helpExtensions[i]:getHeight()
                    if height > 0 then
                    else
                        table.remove(_self.helpExtensions, i)
                    end
                end
                for helpExtension, height in pairs(_self.helpExtensions) do
                    if numElements < (height.priority <= GS_PRIO_HIGH and InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY or InputHelpDisplay.MAX_NUM_ELEMENTS) then
                        helpExtensionTotalHeight = height:draw(_self, posX, helpExtensionTotalHeight) - _self.lineOffsetY
                    end
                    _self.helpExtensions[helpExtension] = nil
                end
            end
        else
            superFunc(_self, offsetX, offsetY)
            return
        end
    end)
    pfModule:overwriteGameFunction(InputHelpDisplay, "addHelpExtension", function(superFunc, _self, extension)
        -- upvalues: (copy) self
        if self.isEnabled and not _self:getVisible() then
            if extension:isa(ExtendedSowingMachineHUDExtension) or (extension:isa(ExtendedSprayerHUDExtension) or extension:isa(ExtendedCombineHUDExtension)) then
                table.insert(_self.helpExtensions, extension)
            else
                superFunc(_self, extension)
            end
        else
            superFunc(_self, extension)
            return
        end
    end)
end