PlaceableHusbandryMilk = {}
source("dataS/scripts/animals/husbandry/objects/MilkingRobot.lua")
function PlaceableHusbandryMilk.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableHusbandry, specializations) and SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, specializations)
end
function PlaceableHusbandryMilk.initSpecialization()
    g_placeableConfigurationManager:addConfigurationType("milk", g_i18n:getText("configuration_milk"), "husbandry.milk", PlaceableConfigurationItem)
end
function PlaceableHusbandryMilk.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onMilkingRobotLoaded", PlaceableHusbandryMilk.onMilkingRobotLoaded)
end
function PlaceableHusbandryMilk.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryMilk.updateOutput)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateProduction", PlaceableHusbandryMilk.updateProduction)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryMilk.updateInfo)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryMilk.getConditionInfos)
end
function PlaceableHusbandryMilk.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryMilk)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryMilk)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryMilk)
    SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryMilk)
end
function PlaceableHusbandryMilk.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    PlaceableHusbandryMilk.registerMilkXMLPaths(schema, basePath .. ".husbandry.milk")
    PlaceableHusbandryMilk.registerMilkXMLPaths(schema, basePath .. ".husbandry.milk.milkConfigurations.milkConfiguration(?)")
    schema:setXMLSpecializationType()
end
function PlaceableHusbandryMilk.registerMilkXMLPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. "#hasMilkProduction", "If milk production is available")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".milkingRobots.milkingRobot(?)#linkNode", "Milkingrobot link node")
    schema:register(XMLValueType.STRING, basePath .. ".milkingRobots.milkingRobot(?)#class", "Milkingrobot class name")
    schema:register(XMLValueType.STRING, basePath .. ".milkingRobots.milkingRobot(?)#filename", "Milkingrobot config file")
end
function PlaceableHusbandryMilk:onLoad(_)
    local spec = self.spec_husbandryMilk
    local milkConfigurationId = Utils.getNoNil(self.configurations.milk, 1)
    local configKey = string.format("placeable.husbandry.milk.milkConfigurations.milkConfiguration(%d)", milkConfigurationId - 1)
    local configKey = not self.xmlFile:hasProperty(configKey) and "placeable.husbandry.milk" or configKey
    spec.hasMilkProduction = self.xmlFile:getBool(configKey .. "#hasMilkProduction", true)
    if spec.hasMilkProduction then
        local animalTypeIndex = self:getAnimalTypeIndex()
        local animalType = g_currentMission.animalSystem:getTypeByIndex(animalTypeIndex)
        spec.litersPerHour = {}
        spec.fillTypes = {}
        spec.infos = {}
        spec.activeFillTypes = {}
        if animalType ~= nil then
            for _, subTypeIndex in ipairs(animalType.subTypes) do
                local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
                if subType.output ~= nil then
                    local milk = subType.output.milk
                    if milk ~= nil then
                        spec.litersPerHour[milk.fillType] = 0
                        table.addElement(spec.fillTypes, milk.fillType)
                        spec.infos[milk.fillType] = {
                            ["title"] = g_fillTypeManager:getFillTypeTitleByIndex(milk.fillType),
                            ["text"] = ""
                        }
                    end
                end
            end
        end
        spec.milkingRobots = {}
        for _, subTypeIndex in self.xmlFile:iterator(configKey .. ".milkingRobots.milkingRobot") do
            local subType = Utils.getFilename(self.xmlFile:getValue(subTypeIndex .. "#filename", nil), self.baseDirectory)
            if subType == nil then
                Logging.xmlWarning(self.xmlFile, "Milkingrobot filename missing for \'%s\'", subTypeIndex)
            else
                local milk = self.xmlFile:getValue(subTypeIndex .. "#class", "")
                local class = ClassUtil.getClassObject(milk)
                if class == nil then
                    Logging.xmlWarning(self.xmlFile, "Milkingrobot class \'%s\' not defined for \'%s\'", milk, subTypeIndex)
                else
                    local linkNode = self.xmlFile:getValue(subTypeIndex .. "#linkNode", nil, self.components, self.i3dMappings)
                    if linkNode == nil then
                        Logging.xmlWarning(self.xmlFile, "Milkingrobot linkNode not defined for \'%s\'", subTypeIndex)
                    else
                        local args = {
                            ["loadingTask"] = self:createLoadingTask(self)
                        }
                        local robot = class.new(self, self.baseDirectory)
                        if robot:load(linkNode, subType, self.onMilkingRobotLoaded, self, args) then
                            table.insert(spec.milkingRobots, robot)
                        else
                            self:finishLoadingTask(args.loadingTask)
                            robot:delete()
                        end
                    end
                end
            end
        end
    end
end
function PlaceableHusbandryMilk:onMilkingRobotLoaded(_, args)
    self:finishLoadingTask(args.loadingTask)
end
function PlaceableHusbandryMilk:onDelete()
    local spec = self.spec_husbandryMilk
    if spec.milkingRobots ~= nil then
        for _, robot in ipairs(spec.milkingRobots) do
            robot:delete()
        end
        spec.milkingRobots = {}
    end
end
function PlaceableHusbandryMilk:onFinalizePlacement()
    local spec = self.spec_husbandryMilk
    if spec.hasMilkProduction then
        for _, fillTypeIndex in ipairs(spec.fillTypes) do
            if not self:getHusbandryIsFillTypeSupported(fillTypeIndex) then
                local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
                Logging.xmlWarning(self.xmlFile, "Missing filltype \'%s\' in husbandry storage!", fillTypeName)
            end
        end
        for _, fillTypeIndex in ipairs(spec.milkingRobots) do
            fillTypeIndex:finalizePlacement()
        end
    end
end
function PlaceableHusbandryMilk:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
    local spec = self.spec_husbandryMilk
    if spec.hasMilkProduction and (self.isServer and #spec.fillTypes > 0) then
        for _, fillTypeIndex in ipairs(spec.fillTypes) do
            self:addHusbandryFillLevelFromTool(self:getOwnerFarmId(), productionFactor * globalProductionFactor * spec.litersPerHour[fillTypeIndex] * g_currentMission.environment.timeAdjustment, fillTypeIndex, nil, nil, nil)
        end
    end
    superFunc(self, foodFactor, productionFactor, globalProductionFactor)
end
function PlaceableHusbandryMilk:updateProduction(superFunc, foodFactor)
    local spec = self.spec_husbandryMilk
    local factor = superFunc(self, foodFactor)
    if spec.hasMilkProduction then
        for _, fillTypeIndex in ipairs(spec.fillTypes) do
            if self:getHusbandryFreeCapacity(fillTypeIndex) <= 0 then
                return 0
            end
        end
    end
    return factor
end
function PlaceableHusbandryMilk:onHusbandryAnimalsUpdate(clusters)
    local spec = self.spec_husbandryMilk
    if spec.hasMilkProduction then
        for fillType, _ in pairs(spec.litersPerHour) do
            spec.litersPerHour[fillType] = 0
        end
        spec.activeFillTypes = {}
        for fillType, _ in ipairs(clusters) do
            local subType = g_currentMission.animalSystem:getSubTypeByIndex(_.subTypeIndex)
            if subType ~= nil then
                local milk = subType.output.milk
                if milk ~= nil then
                    local age = _:getAge()
                    local litersPerDay = milk.curve:get(age) * _:getNumAnimals()
                    spec.litersPerHour[milk.fillType] = spec.litersPerHour[milk.fillType] + litersPerDay / 24
                    table.addElement(spec.activeFillTypes, milk.fillType)
                end
            end
        end
    end
end
function PlaceableHusbandryMilk:updateInfo(superFunc, infoTable)
    local spec = self.spec_husbandryMilk
    superFunc(self, infoTable)
    if spec.hasMilkProduction then
        for k, fillTypeIndex in ipairs(spec.activeFillTypes) do
            local info = spec.infos[fillTypeIndex]
            local fillLevel = self:getHusbandryFillLevel(fillTypeIndex)
            info.text = string.format("%d l", fillLevel)
            table.insert(infoTable, info)
        end
    end
end
function PlaceableHusbandryMilk:getConditionInfos(superFunc)
    local spec = self.spec_husbandryMilk
    local infos = superFunc(self)
    if spec.hasMilkProduction then
        for _, fillTypeIndex in ipairs(spec.activeFillTypes) do
            local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
            if fillType ~= nil then
                ({}).title = fillType.title
                info.value = self:getHusbandryFillLevel(fillTypeIndex)
                local capacity = self:getHusbandryCapacity(fillTypeIndex)
                local ratio = 0
                if capacity > 0 then
                    ratio = info.value / capacity
                end
                info.ratio = math.clamp(ratio, 0, 1)
                info.invertedBar = true
                table.insert(infos, info)
            end
        end
    end
    return infos
end