PlaceableIncomePerHour = {}
function PlaceableIncomePerHour.prerequisitesPresent(specializations)
    return true
end
function PlaceableIncomePerHour.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "getIncomePerHour", PlaceableIncomePerHour.getIncomePerHour)
end
function PlaceableIncomePerHour.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedHourChanged", PlaceableIncomePerHour.getNeedHourChanged)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "finalizeConstruction", PlaceableIncomePerHour.finalizeConstruction)
end
function PlaceableIncomePerHour.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableIncomePerHour)
    SpecializationUtil.registerEventListener(placeableType, "onHourChanged", PlaceableIncomePerHour)
end
function PlaceableIncomePerHour.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("IncomePerHour")
    schema:register(XMLValueType.FLOAT, basePath .. ".incomePerHour.incomePerHourConfigurations.incomePerHourConfiguration(?)#incomePerHour", "Income per hour")
    schema:register(XMLValueType.FLOAT, basePath .. ".incomePerHour", "Income per hour")
    schema:setXMLSpecializationType()
end
function PlaceableIncomePerHour.initSpecialization()
    g_storeManager:addSpecType("incomePerHour", "shopListAttributeIconIncomePerHour", PlaceableIncomePerHour.loadSpecValueIncomePerHour, PlaceableIncomePerHour.getSpecValueIncomePerHour, StoreSpecies.PLACEABLE)
    g_placeableConfigurationManager:addConfigurationType("incomePerHour", g_i18n:getText("configuration_incomePerHour"), "incomePerHour", PlaceableConfigurationItem)
end
function PlaceableIncomePerHour:onLoad(_)
    local spec = self.spec_incomePerHour
    local xmlFile = self.xmlFile
    spec.incomePerHour = xmlFile:getValue((string.format("placeable.incomePerHour.incomePerHourConfigurations.incomePerHourConfiguration(%d)#incomePerHour", (self.configurations.incomePerHour or 1) - 1))) or xmlFile:getValue("placeable.incomePerHour", 0)
    spec.incomePerHourFactor = 1
    spec.isFinished = self.getNumFinishedConstructibleStates ~= nil
end
function PlaceableIncomePerHour:finalizeConstruction(superFunc)
    superFunc(self)
    self.spec_incomePerHour.isFinished = true
end
function PlaceableIncomePerHour:getNeedHourChanged(superFunc)
    return true
end
function PlaceableIncomePerHour:onHourChanged()
    if self.isServer then
        local ownerFarmId = self:getOwnerFarmId()
        if ownerFarmId == FarmlandManager.NO_OWNER_FARM_ID then
            return
        elseif self.spec_incomePerHour.isFinished then
            local incomePerHour = self:getIncomePerHour() * g_currentMission.environment.timeAdjustment
            if incomePerHour ~= 0 then
                g_currentMission:addMoney(incomePerHour, ownerFarmId, MoneyType.PROPERTY_INCOME, true)
            end
        end
    else
        return
    end
end
function PlaceableIncomePerHour:getIncomePerHour()
    return self.spec_incomePerHour.incomePerHour
end
function PlaceableIncomePerHour.loadSpecValueIncomePerHour(xmlFile, _, _)
    local incomePerHour = xmlFile:getValue("placeable.incomePerHour.incomePerHourConfigurations.incomePerHourConfiguration(0)#incomePerHour", xmlFile:getValue("placeable.incomePerHour", 0))
    local windTurbineIncomePerHour = xmlFile:getValue("placeable.windTurbine#incomePerHour", 0)
    local solarPanelsDefaultConfigIncomePerHour = xmlFile:getValue("placeable.solarPanels.solarPanelsConfigurations.solarPanelsConfiguration(0)#incomePerHour", 0)
    return (incomePerHour ~= 0 or (windTurbineIncomePerHour ~= 0 or solarPanelsDefaultConfigIncomePerHour ~= 0)) and { incomePerHour, windTurbineIncomePerHour + solarPanelsDefaultConfigIncomePerHour } or nil
end
function PlaceableIncomePerHour.getSpecValueIncomePerHour(storeItem, _)
    if storeItem.specs.incomePerHour == nil then
        return nil
    end
    local fixedIncome, variableIncome = unpack(storeItem.specs.incomePerHour)
    local fixedIncome = fixedIncome * 24
    if variableIncome == 0 then
        return string.format("%s / %s", g_i18n:formatMoney(fixedIncome), g_i18n:getText("ui_month"))
    end
    return string.format("%s - %s / %s", g_i18n:formatMoney(fixedIncome, nil, false), g_i18n:formatMoney(fixedIncome + variableIncome * 24), g_i18n:getText("ui_month"))
end