PlaceableHusbandryStraw = {}
function PlaceableHusbandryStraw.prerequisitesPresent(specializations)
    return true
end
function PlaceableHusbandryStraw.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "updateStrawPlane", PlaceableHusbandryStraw.updateStrawPlane)
end
function PlaceableHusbandryStraw.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryStraw.updateOutput)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateProduction", PlaceableHusbandryStraw.updateProduction)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryStraw.getConditionInfos)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryStraw.updateInfo)
end
function PlaceableHusbandryStraw.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryStraw)
    SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableHusbandryStraw)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryStraw)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryStraw)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryStraw)
    SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryStraw)
    SpecializationUtil.registerEventListener(placeableType, "onHusbandryFillLevelChanged", PlaceableHusbandryStraw)
end
function PlaceableHusbandryStraw.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    basePath = basePath .. ".husbandry.straw"
    FillPlane.registerXMLPaths(schema, basePath .. ".strawPlane")
    schema:register(XMLValueType.FLOAT, basePath .. ".manure#factor", "Factor to transform straw to manure", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".manure#active", "Enable manure production", true)
    schema:setXMLSpecializationType()
end
function PlaceableHusbandryStraw:onLoad(_)
    local spec = self.spec_husbandryStraw
    spec.manureFactor = self.xmlFile:getValue("placeable.husbandry.straw.manure#factor", 1)
    spec.isManureActive = self.xmlFile:getValue("placeable.husbandry.straw.manure#active", true)
    spec.strawPlane = FillPlane.new()
    if spec.strawPlane:load(self.components, self.xmlFile, "placeable.husbandry.straw.strawPlane", self.i3dMappings) then
        spec.strawPlane:setState(0)
    else
        spec.strawPlane:delete()
        spec.strawPlane = nil
    end
    spec.inputFillType = FillType.STRAW
    spec.outputFillType = FillType.MANURE
    spec.inputLitersPerHour = 0
    spec.outputLitersPerHour = 0
    spec.info = {
        ["title"] = g_i18n:getText("fillType_straw"),
        ["text"] = ""
    }
    spec.outputInfo = {
        ["title"] = g_i18n:getText("fillType_manure"),
        ["text"] = ""
    }
end
function PlaceableHusbandryStraw:onPostFinalizePlacement()
    self:updateStrawPlane()
end
function PlaceableHusbandryStraw:onDelete()
    local spec = self.spec_husbandryStraw
    if spec.strawPlane ~= nil then
        spec.strawPlane:delete()
        spec.strawPlane = nil
    end
end
function PlaceableHusbandryStraw:onFinalizePlacement()
    local spec = self.spec_husbandryStraw
    if not self:getHusbandryIsFillTypeSupported(spec.inputFillType) then
        Logging.xmlWarning(self.xmlFile, "Missing filltype \'straw\' in husbandry storage!")
    end
    if self.isManureActive and not self:getHusbandryIsFillTypeSupported(spec.outputFillType) then
        Logging.xmlWarning(self.xmlFile, "Missing filltype \'manure\' in husbandry storage!")
    end
end
function PlaceableHusbandryStraw:onReadStream(_, _)
    self:updateStrawPlane()
end
function PlaceableHusbandryStraw:updateStrawPlane()
    local spec = self.spec_husbandryStraw
    if spec.strawPlane ~= nil then
        local capacity = self:getHusbandryCapacity(spec.inputFillType, nil)
        local fillLevel = self:getHusbandryFillLevel(spec.inputFillType, nil)
        local factor = 0
        if capacity > 0 then
            factor = fillLevel / capacity
        end
        spec.strawPlane:setState(factor)
    end
end
function PlaceableHusbandryStraw:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
    if self.isServer then
        local spec = self.spec_husbandryStraw
        if spec.inputLitersPerHour > 0 then
            local amount = spec.inputLitersPerHour * g_currentMission.environment.timeAdjustment
            local delta = amount - self:removeHusbandryFillLevel(self:getOwnerFarmId(), amount, spec.inputFillType)
            if spec.outputLitersPerHour > 0 and delta > 0 then
                local liters = foodFactor * spec.outputLitersPerHour * (delta / amount) * g_currentMission.environment.timeAdjustment
                if liters > 0 then
                    self:addHusbandryFillLevelFromTool(self:getOwnerFarmId(), liters, spec.outputFillType, nil, nil, nil)
                end
            end
            self:updateStrawPlane()
        end
    end
    superFunc(self, foodFactor, productionFactor, globalProductionFactor)
end
function PlaceableHusbandryStraw:updateProduction(superFunc, foodFactor)
    local factor = superFunc(self, foodFactor)
    if self.isServer then
        local spec = self.spec_husbandryStraw
        if self:getHusbandryFillLevel(spec.inputFillType) > 0 then
            if self:getHusbandryFreeCapacity(spec.outputFillType) <= 0 then
                return factor * 0.75
            end
        end
    end
    return factor
end
function PlaceableHusbandryStraw:onHusbandryAnimalsUpdate(clusters)
    local spec = self.spec_husbandryStraw
    spec.inputLitersPerHour = 0
    spec.outputLitersPerHour = 0
    for _, cluster in ipairs(clusters) do
        local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex)
        if subType ~= nil then
            local straw = subType.input.straw
            if straw ~= nil then
                local litersPerDay = straw:get((cluster:getAge())) * cluster:getNumAnimals()
                spec.inputLitersPerHour = spec.inputLitersPerHour + litersPerDay / 24
            end
            local age = subType.output.manure
            if age ~= nil then
                local litersPerDay = age:get((cluster:getAge())) * cluster:getNumAnimals()
                spec.outputLitersPerHour = spec.outputLitersPerHour + litersPerDay / 24
            end
        end
    end
end
function PlaceableHusbandryStraw:onHusbandryFillLevelChanged(fillTypeIndex, _)
    if fillTypeIndex == self.spec_husbandryStraw.inputFillType then
        self:updateStrawPlane()
    end
end
function PlaceableHusbandryStraw:getConditionInfos(superFunc)
    local infos = superFunc(self)
    local spec = self.spec_husbandryStraw
    local fillType = g_fillTypeManager:getFillTypeByIndex(spec.inputFillType)
    if fillType ~= nil then
        local info = {
            ["title"] = fillType.title,
            ["value"] = self:getHusbandryFillLevel(spec.inputFillType)
        }
        local capacity = self:getHusbandryCapacity(spec.inputFillType)
        local ratio = 0
        if capacity > 0 then
            ratio = info.value / capacity
        end
        info.ratio = math.clamp(ratio, 0, 1)
        info.invertedBar = false
        table.insert(infos, info)
    end
    local info = g_fillTypeManager:getFillTypeByIndex(spec.outputFillType)
    if info ~= nil then
        local capacity = {
            ["title"] = info.title,
            ["value"] = self:getHusbandryFillLevel(spec.outputFillType)
        }
        local ratio = self:getHusbandryCapacity(spec.outputFillType)
        local ratio = 1
        if ratio > 0 then
        else
            capacity.disabled = true
            capacity.title = string.format("%s (%s)", capacity.title, g_i18n:getText("info_husbandryMissingManureHeap"))
        end
        capacity.ratio = math.clamp(ratio, 0, 1)
        capacity.invertedBar = true
        table.insert(infos, capacity)
    end
    return infos
end
function PlaceableHusbandryStraw:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)
    local spec = self.spec_husbandryStraw
    local fillLevel = self:getHusbandryFillLevel(spec.inputFillType)
    spec.info.text = string.format("%d l", fillLevel)
    table.insert(infoTable, spec.info)
    local outputFillLevel = self:getHusbandryFillLevel(spec.outputFillType)
    spec.outputInfo.text = string.format("%d l", outputFillLevel)
    table.insert(infoTable, spec.outputInfo)
end