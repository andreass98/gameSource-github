source("dataS/scripts/vehicles/specializations/events/VehicleSettingsChangeEvent.lua")
VehicleSettings = {}
function VehicleSettings.prerequisitesPresent(specializations)
    return true
end
function VehicleSettings.initSpecialization() end
function VehicleSettings.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "registerVehicleSetting", VehicleSettings.registerVehicleSetting)
    SpecializationUtil.registerFunction(vehicleType, "setVehicleSettingState", VehicleSettings.setVehicleSettingState)
    SpecializationUtil.registerFunction(vehicleType, "getVehicleSettingState", VehicleSettings.getVehicleSettingState)
    SpecializationUtil.registerFunction(vehicleType, "forceVehicleSettingsUpdate", VehicleSettings.forceVehicleSettingsUpdate)
end
function VehicleSettings.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onVehicleSettingChanged")
end
function VehicleSettings.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", VehicleSettings)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", VehicleSettings)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", VehicleSettings)
    SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", VehicleSettings)
end
function VehicleSettings:onPreLoad(_)
    local spec = self.spec_vehicleSettings
    spec.isDirty = false
    spec.settings = {}
    if self.isServer then
        SpecializationUtil.removeEventListener(self, "onUpdateTick", VehicleSettings)
    end
end
function VehicleSettings:onUpdateTick(_, _, _, _)
    local spec = self.spec_vehicleSettings
    if spec.isDirty then
        local hasDirtyValue = false
        local i = 1
        for i = i, #spec.settings do
            if spec.settings[i].isDirty then
                hasDirtyValue = true
                break
            end
        end
        if hasDirtyValue and (g_server == nil and g_client ~= nil) then
            g_client:getServerConnection():sendEvent(VehicleSettingsChangeEvent.new(self, spec.settings))
        end
        spec.isDirty = false
    end
end
function VehicleSettings:registerVehicleSetting(gameSettingId, isBool)
    local spec = self.spec_vehicleSettings
    local setting = {
        ["index"] = #spec.settings + 1,
        ["gameSettingId"] = gameSettingId,
        ["isBool"] = isBool,
        ["callback"] = function(_, state)
            -- upvalues: (copy) self, (copy) setting
            if self:getIsActiveForInput(true, true) then
                self:setVehicleSettingState(setting.index, state)
            end
        end
    }
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[gameSettingId], setting.callback, self)
    table.insert(spec.settings, setting)
end
function VehicleSettings:forceVehicleSettingsUpdate()
    local spec = self.spec_vehicleSettings
    local i = 1
    for i = i, #spec.settings do
        local setting = spec.settings[i]
        self:setVehicleSettingState(setting.index, g_gameSettings:getValue(setting.gameSettingId), true)
    end
end
function VehicleSettings:setVehicleSettingState(settingIndex, state, noEventSend)
    local spec = self.spec_vehicleSettings
    local setting = spec.settings[settingIndex]
    if setting ~= nil then
        if (noEventSend == nil or noEventSend == false) and (g_server == nil and g_client ~= nil) then
            g_client:getServerConnection():sendEvent(VehicleSettingsChangeEvent.new(self, spec.settings))
        end
        setting.state = state
        setting.isDirty = true
        spec.isDirty = true
        SpecializationUtil.raiseEvent(self, "onVehicleSettingChanged", setting.gameSettingId, state)
    end
end
function VehicleSettings:getVehicleSettingState(gameSettingId)
    local spec = self.spec_vehicleSettings
    local i = 1
    for i = i, #spec.settings do
        local setting = spec.settings[i]
        if setting.gameSettingId == gameSettingId then
            return setting.state
        end
    end
end
function VehicleSettings:onStateChange(state, _, isControlling)
    if isControlling and state == VehicleStateChange.ENTER_VEHICLE then
        self:forceVehicleSettingsUpdate()
    end
end
function VehicleSettings:onPreAttach(_, _, _)
    self:forceVehicleSettingsUpdate()
end