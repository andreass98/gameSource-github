WorkArea = {}
WorkArea.WORK_AREA_XML_KEY = "vehicle.workAreas.workArea(?)"
WorkArea.WORK_AREA_XML_CONFIG_KEY = "vehicle.workAreas.workAreaConfigurations.workAreaConfiguration(?).workArea(?)"
function WorkArea.initSpecialization()
    g_workAreaTypeManager:addWorkAreaType("default", false, false, false)
    g_workAreaTypeManager:addWorkAreaType("auxiliary", false, false, false)
    g_vehicleConfigurationManager:addConfigurationType("workArea", g_i18n:getText("configuration_workArea"), "workAreas", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("WorkArea")
    WorkArea.registerWorkAreaXMLPaths(schema, WorkArea.WORK_AREA_XML_KEY)
    WorkArea.registerWorkAreaXMLPaths(schema, WorkArea.WORK_AREA_XML_CONFIG_KEY)
    schema:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#workAreaIndex", "Work area index")
    schema:setXMLSpecializationType()
end
function WorkArea.registerWorkAreaXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#type", "Work area type", "DEFAULT")
    schema:register(XMLValueType.BOOL, basePath .. "#requiresGroundContact", "Requires ground contact to work", true)
    schema:register(XMLValueType.BOOL, basePath .. "#disableBackwards", "Area is disabled while driving backwards", true)
    schema:register(XMLValueType.BOOL, basePath .. "#requiresOwnedFarmland", "Requires owned farmland", true)
    schema:register(XMLValueType.STRING, basePath .. "#functionName", "Work area script function")
    schema:register(XMLValueType.STRING, basePath .. "#preprocessFunctionName", "Pre process work area script function")
    schema:register(XMLValueType.STRING, basePath .. "#postprocessFunctionName", "Post process work area script function")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#startNode", "Start node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#widthNode", "Width node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#heightNode", "Height node")
    schema:register(XMLValueType.INT, basePath .. ".groundReferenceNode#index", "Ground reference node index")
    schema:register(XMLValueType.BOOL, basePath .. ".onlyActiveWhenLowered#value", "Work area is only active when lowered", false)
end
function WorkArea.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(GroundReference, specializations)
end
function WorkArea.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onStartWorkAreaProcessing")
    SpecializationUtil.registerEvent(vehicleType, "onEndWorkAreaProcessing")
end
function WorkArea.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadWorkAreaFromXML", WorkArea.loadWorkAreaFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getWorkAreaByIndex", WorkArea.getWorkAreaByIndex)
    SpecializationUtil.registerFunction(vehicleType, "getIsWorkAreaActive", WorkArea.getIsWorkAreaActive)
    SpecializationUtil.registerFunction(vehicleType, "updateWorkAreaWidth", WorkArea.updateWorkAreaWidth)
    SpecializationUtil.registerFunction(vehicleType, "getWorkAreaWidth", WorkArea.getWorkAreaWidth)
    SpecializationUtil.registerFunction(vehicleType, "getIsWorkAreaProcessing", WorkArea.getIsWorkAreaProcessing)
    SpecializationUtil.registerFunction(vehicleType, "getTypedNetworkAreas", WorkArea.getTypedNetworkAreas)
    SpecializationUtil.registerFunction(vehicleType, "getTypedWorkAreas", WorkArea.getTypedWorkAreas)
    SpecializationUtil.registerFunction(vehicleType, "getIsTypedWorkAreaActive", WorkArea.getIsTypedWorkAreaActive)
    SpecializationUtil.registerFunction(vehicleType, "getIsFarmlandNotOwnedWarningShown", WorkArea.getIsFarmlandNotOwnedWarningShown)
    SpecializationUtil.registerFunction(vehicleType, "getLastTouchedFarmlandFarmId", WorkArea.getLastTouchedFarmlandFarmId)
    SpecializationUtil.registerFunction(vehicleType, "getIsAccessibleAtWorldPosition", WorkArea.getIsAccessibleAtWorldPosition)
    SpecializationUtil.registerFunction(vehicleType, "updateLastWorkedArea", WorkArea.updateLastWorkedArea)
    SpecializationUtil.registerFunction(vehicleType, "getMissionByWorkArea", WorkArea.getMissionByWorkArea)
    SpecializationUtil.registerFunction(vehicleType, "getAIWorkAreaWidth", WorkArea.getAIWorkAreaWidth)
end
function WorkArea.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", WorkArea.loadSpeedRotatingPartFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", WorkArea.getIsSpeedRotatingPartActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "checkMovingPartDirtyUpdateNode", WorkArea.checkMovingPartDirtyUpdateNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getImplementAllowAutomaticSteering", WorkArea.getImplementAllowAutomaticSteering)
end
function WorkArea.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", WorkArea)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WorkArea)
end
function WorkArea:onLoad(_)
    local spec = self.spec_workArea
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#startIndex", "vehicle.workAreas.workArea(0).area#startIndex")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#widthIndex", "vehicle.workAreas.workArea(0).area#widthIndex")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#heightIndex", "vehicle.workAreas.workArea(0).area#heightIndex")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#foldMinLimit", "vehicle.workAreas.workArea(0).folding#minLimit")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#foldMaxLimit", "vehicle.workAreas.workArea(0).folding#maxLimit")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#refNodeIndex", "vehicle.workAreas.workArea(0).groundReferenceNode#index")
    local configurationId = Utils.getNoNil(self.configurations.workArea, 1)
    local configKey = string.format("vehicle.workAreas.workAreaConfigurations.workAreaConfiguration(%d)", configurationId - 1)
    local configKey = not self.xmlFile:hasProperty(configKey) and "vehicle.workAreas" or configKey
    spec.workAreas = {}
    local i = 0
    while true do
        local key = string.format("%s.workArea(%d)", configKey, i)
        if not self.xmlFile:hasProperty(key) then
            break
        end
        local workArea = {}
        if self:loadWorkAreaFromXML(workArea, self.xmlFile, key) then
            table.insert(spec.workAreas, workArea)
            workArea.index = #spec.workAreas
            self:updateWorkAreaWidth(workArea.index)
        end
        i = i + 1
    end
    spec.workAreaByType = {}
    for _, area in pairs(spec.workAreas) do
        if spec.workAreaByType[area.type] == nil then
            spec.workAreaByType[area.type] = {}
        end
        table.insert(spec.workAreaByType[area.type], area)
    end
    spec.lastAccessedFarmlandOwner = 0
    spec.lastWorkedArea = -1
    spec.showFarmlandNotOwnedWarning = false
    spec.warningCantUseMissionVehiclesOnOtherLand = g_i18n:getText("warning_cantUseMissionVehiclesOnOtherLand")
    spec.warningYouDontHaveAccessToThisLand = g_i18n:getText("warning_youDontHaveAccessToThisLand")
end
function WorkArea:getIsAccessibleAtWorldPosition(farmId, x, z, workAreaType)
    if self.propertyState == VehiclePropertyState.MISSION then
        return g_missionManager:getIsMissionWorkAllowed(farmId, x, z, workAreaType, self), farmId, true
    end
    local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
    if farmlandId == nil then
        return false, nil, false
    end
    if farmlandId == FarmlandManager.NOT_BUYABLE_FARM_ID then
        return false, FarmlandManager.NO_OWNER_FARM_ID, false
    end
    local landOwner = g_farmlandManager:getFarmlandOwner(farmlandId)
    return landOwner ~= 0 and g_currentMission.accessHandler:canFarmAccessOtherId(farmId, landOwner) or g_missionManager:getIsMissionWorkAllowed(farmId, x, z, workAreaType, self), landOwner, true
end
function WorkArea:updateLastWorkedArea(area)
    local spec = self.spec_workArea
    spec.lastWorkedArea = math.max(area, spec.lastWorkedArea)
end
function WorkArea:getLastTouchedFarmlandFarmId()
    local spec = self.spec_workArea
    return spec.lastAccessedFarmlandOwner == 0 and 0 or spec.lastAccessedFarmlandOwner
end
function WorkArea:onUpdateTick(dt, isActiveForInput, _, _)
    local spec = self.spec_workArea
    SpecializationUtil.raiseEvent(self, "onStartWorkAreaProcessing", dt, spec.workAreas)
    spec.showFarmlandNotOwnedWarning = false
    local hasProcessed = false
    local farmId = self:getActiveFarm()
    if farmId == nil then
        farmId = AccessHandler.EVERYONE
    end
    local isOwned = false
    local isBuyable = false
    local allowWarning = false
    local i = 1
    local statsFarmId = #spec.workAreas
    local ha = 1
    for i = i, statsFarmId, ha do
        local workArea = spec.workAreas[i]
        if workArea.type ~= WorkAreaType.AUXILIARY then
            workArea.lastWorkedHectares = 0
            local isAreaActive = self:getIsWorkAreaActive(workArea)
            if isAreaActive and workArea.requiresOwnedFarmland then
                local xs, _, zs = getWorldTranslation(workArea.start)
                local isAccessible, farmlandOwner, buyable = self:getIsAccessibleAtWorldPosition(farmId, xs, zs, workArea.type)
                isBuyable = isBuyable or buyable
                if isAccessible then
                    if farmlandOwner ~= nil then
                        spec.lastAccessedFarmlandOwner = farmlandOwner
                    end
                    isOwned = true
                else
                    local xw, _, zw = getWorldTranslation(workArea.width)
                    local xh, _, zh = self:getIsAccessibleAtWorldPosition(farmId, xw, zw, workArea.type)
                    isBuyable = isBuyable or zh
                    if xh then
                        isOwned = true
                    else
                        local xh, _, zh = getWorldTranslation(workArea.height)
                        local x, z, buyable = self:getIsAccessibleAtWorldPosition(farmId, xh, zh, workArea.type)
                        isBuyable = isBuyable or buyable
                        if x then
                            isOwned = true
                        else
                            local isAccessible, _, buyable = self:getIsAccessibleAtWorldPosition(farmId, xw + (xh - xs), zw + (zh - zs), workArea.type)
                            if isAccessible then
                                isOwned = true
                            end
                        end
                    end
                end
                if not isOwned then
                    isAreaActive = false
                end
                allowWarning = isBuyable
            end
            if isAreaActive then
                if workArea.preprocessingFunction ~= nil then
                    workArea.preprocessingFunction(self, workArea, dt)
                end
                if workArea.processingFunction ~= nil then
                    local xs, _ = workArea.processingFunction(self, workArea, dt)
                    if xs > 0 then
                        workArea.lastWorkedHectares = MathUtil.areaToHa(xs, g_currentMission:getFruitPixelsToSqm())
                        workArea.lastProcessingTime = g_currentMission.time
                    else
                        workArea.lastWorkedHectares = 0
                    end
                end
                if workArea.postprocessingFunction ~= nil then
                    workArea.postprocessingFunction(self, workArea, dt)
                end
                hasProcessed = true
            end
        end
    end
    if allowWarning and (not isOwned and isActiveForInput) then
        spec.showFarmlandNotOwnedWarning = true
        if self.propertyState == VehiclePropertyState.MISSION then
            g_currentMission:showBlinkingWarning(spec.warningCantUseMissionVehiclesOnOtherLand)
        else
            g_currentMission:showBlinkingWarning(spec.warningYouDontHaveAccessToThisLand)
        end
    end
    SpecializationUtil.raiseEvent(self, "onEndWorkAreaProcessing", dt, hasProcessed)
    if spec.lastWorkedArea >= 0 then
        local statsFarmId = self:getLastTouchedFarmlandFarmId()
        local ha = MathUtil.areaToHa(spec.lastWorkedArea, g_currentMission:getFruitPixelsToSqm())
        g_farmManager:updateFarmStats(statsFarmId, "workedHectares", ha)
        g_farmManager:updateFarmStats(statsFarmId, "workedTime", dt / 60000)
        spec.lastWorkedArea = -1
    end
end
function WorkArea:loadWorkAreaFromXML(workArea, xmlFile, key)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".area#startIndex", key .. ".area#startNode")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".area#widthIndex", key .. ".area#widthNode")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".area#heightIndex", key .. ".area#heightNode")
    local start = xmlFile:getValue(key .. ".area#startNode", workArea.start, self.components, self.i3dMappings)
    local width = xmlFile:getValue(key .. ".area#widthNode", workArea.width, self.components, self.i3dMappings)
    local height = xmlFile:getValue(key .. ".area#heightNode", workArea.height, self.components, self.i3dMappings)
    if start == nil or (width == nil or height == nil) then
        return false
    end
    if calcDistanceFrom(start, width) < 0.001 then
        Logging.xmlError(xmlFile, "\'start\' and \'width\' have the same position for \'%s\'!", key)
        return false
    end
    if calcDistanceFrom(width, height) < 0.001 then
        Logging.xmlError(xmlFile, "\'width\' and \'height\' have the same position for \'%s\'!", key)
        return false
    end
    local areaTypeStr = xmlFile:getValue(key .. "#type")
    workArea.type = g_workAreaTypeManager:getWorkAreaTypeIndexByName(areaTypeStr) or WorkAreaType.DEFAULT
    if workArea.type == nil then
        Logging.xmlWarning(xmlFile, "Invalid workArea type \'%s\' for workArea \'%s\'!", areaTypeStr, key)
        return false
    end
    workArea.requiresGroundContact = xmlFile:getValue(key .. "#requiresGroundContact", true)
    if workArea.type ~= WorkAreaType.AUXILIARY then
        if workArea.requiresGroundContact then
            XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#refNodeIndex", key .. ".groundReferenceNode#index")
            local groundReferenceNodeIndex = xmlFile:getValue(key .. ".groundReferenceNode#index")
            if groundReferenceNodeIndex == nil then
                Logging.xmlWarning(xmlFile, "Missing groundReference \'groundReferenceNode#index\' for workArea \'%s\'. Add requiresGroundContact=\"false\" if groundContact is not required!", key)
                return false
            end
            local groundReferenceNode = self:getGroundReferenceNodeFromIndex(groundReferenceNodeIndex)
            if groundReferenceNode == nil then
                Logging.xmlWarning(xmlFile, "Invalid groundReferenceNode-index for workArea \'%s\'!", key)
                return false
            end
            workArea.groundReferenceNode = groundReferenceNode
        end
        workArea.disableBackwards = xmlFile:getValue(key .. "#disableBackwards", true)
        workArea.onlyActiveWhenLowered = xmlFile:getValue(key .. ".onlyActiveWhenLowered#value", false)
        workArea.functionName = xmlFile:getValue(key .. "#functionName")
        if workArea.functionName == nil then
            Logging.xmlWarning(xmlFile, "Missing \'functionName\' for workArea \'%s\'!", key)
            return false
        end
        if self[workArea.functionName] == nil then
            Logging.xmlWarning(xmlFile, "Given functionName \'%s\' not defined. Please add missing function or specialization!", (tostring(workArea.functionName)))
            return false
        end
        workArea.processingFunction = self[workArea.functionName]
        if g_isDevelopmentVersion and (not SpecializationUtil.hasSpecialization(Cutter, self.specializations) and (not SpecializationUtil.hasSpecialization(Pickup, self.specializations) and (not SpecializationUtil.hasSpecialization(Drivable, self.specializations) and xmlFile:getString(key .. ".onlyActiveWhenLowered#value") == nil))) then
            Logging.xmlDevWarning(xmlFile, "Work area has no \'onlyActiveWhenLowered\' attribute set! \'%s\'", key)
        end
        workArea.preprocessFunctionName = xmlFile:getValue(key .. "#preprocessFunctionName")
        if workArea.preprocessFunctionName ~= nil then
            if self[workArea.preprocessFunctionName] == nil then
                Logging.xmlWarning(xmlFile, "Given preprocessFunctionName \'%s\' not defined. Please add missing function or specialization!", (tostring(workArea.preprocessFunctionName)))
                return false
            end
            workArea.preprocessingFunction = self[workArea.preprocessFunctionName]
        end
        workArea.postprocessFunctionName = xmlFile:getValue(key .. "#postprocessFunctionName")
        if workArea.postprocessFunctionName ~= nil then
            if self[workArea.postprocessFunctionName] == nil then
                Logging.xmlWarning(xmlFile, "Given postprocessFunctionName \'%s\' not defined. Please add missing function or specialization!", (tostring(workArea.postprocessFunctionName)))
                return false
            end
            workArea.postprocessingFunction = self[workArea.postprocessFunctionName]
        end
        workArea.requiresOwnedFarmland = xmlFile:getValue(key .. "#requiresOwnedFarmland", true)
    end
    workArea.lastProcessingTime = 0
    workArea.start = start
    workArea.width = width
    workArea.height = height
    workArea.workWidth = -1
    return true
end
function WorkArea:getWorkAreaByIndex(workAreaIndex)
    return self.spec_workArea.workAreas[workAreaIndex]
end
function WorkArea:getIsWorkAreaActive(workArea)
    if workArea.requiresGroundContact == true and (workArea.groundReferenceNode ~= nil and not self:getIsGroundReferenceNodeActive(workArea.groundReferenceNode)) then
        return false
    elseif workArea.disableBackwards and self.movingDirection <= 0 then
        return false
    else
        return (not workArea.onlyActiveWhenLowered or (self.getIsLowered == nil or self:getIsLowered(false))) and true or false
    end
end
function WorkArea:updateWorkAreaWidth(workAreaIndex)
    local workArea = self.spec_workArea.workAreas[workAreaIndex]
    if workArea ~= nil then
        local x1, _, _ = localToLocal(self.components[1].node, workArea.start, 0, 0, 0)
        local x2, _, _ = localToLocal(self.components[1].node, workArea.width, 0, 0, 0)
        local x3, _, _ = localToLocal(self.components[1].node, workArea.height, 0, 0, 0)
        workArea.workWidth = math.max(x1, x2, x3) - math.min(x1, x2, x3)
    end
end
function WorkArea:getWorkAreaWidth(workAreaIndex)
    return self.spec_workArea.workAreas[workAreaIndex].workWidth
end
function WorkArea.getIsWorkAreaProcessing(_, workArea)
    return workArea.lastProcessingTime + 200 >= g_currentMission.time
end
function WorkArea:getTypedNetworkAreas(areaType, needsFieldProperty)
    local workAreasSend = {}
    local area = 0
    local typedWorkAreas = self:getTypedWorkAreas(areaType)
    local showFarmlandNotOwnedWarning = false
    for _, workArea in pairs(typedWorkAreas) do
        if self:getIsWorkAreaActive(workArea) then
            local x, _, z = getWorldTranslation(workArea.start)
            local isAccessible = not needsFieldProperty
            if needsFieldProperty then
                local farmId = g_currentMission:getFarmId()
                isAccessible = g_currentMission.accessHandler:canFarmAccessLand(farmId, x, z) or g_missionManager:getIsMissionWorkAllowed(farmId, x, z, areaType, self)
            end
            if isAccessible then
                local farmId, _, z1 = getWorldTranslation(workArea.width)
                local x2, _, z2 = getWorldTranslation(workArea.height)
                area = area + math.abs((z1 - z) * (x2 - x) - (farmId - x) * (z2 - z))
                table.insert(workAreasSend, {
                    x,
                    z,
                    farmId,
                    z1,
                    x2,
                    z2
                })
            else
                showFarmlandNotOwnedWarning = true
            end
        end
    end
    return workAreasSend, showFarmlandNotOwnedWarning, area
end
function WorkArea:getTypedWorkAreas(areaType)
    local workAreas = self.spec_workArea.workAreaByType[areaType]
    return workAreas == nil and {} or workAreas
end
function WorkArea:getIsTypedWorkAreaActive(areaType)
    local typedWorkAreas = self:getTypedWorkAreas(areaType)
    for _, workArea in pairs(typedWorkAreas) do
        if self:getIsWorkAreaActive(workArea) then
            return true, typedWorkAreas
        end
    end
    return false, typedWorkAreas
end
function WorkArea.getMissionByWorkArea(_, workArea)
    if workArea == nil then
        return nil
    else
        local x, _, z = getWorldTranslation(workArea.start)
        local mission = g_missionManager:getMissionAtWorldPosition(x, z)
        if mission == nil then
            local x, _, z = getWorldTranslation(workArea.width)
            local mission = g_missionManager:getMissionAtWorldPosition(x, z)
            if mission == nil then
                local x, _, z = getWorldTranslation(workArea.height)
                local mission = g_missionManager:getMissionAtWorldPosition(x, z)
                if mission == nil then
                    return nil
                else
                    return mission
                end
            else
                return mission
            end
        else
            return mission
        end
    end
end
function WorkArea:getAIWorkAreaWidth()
    local workingWidth = 0
    for _, workArea in pairs(self.spec_workArea.workAreas) do
        if g_workAreaTypeManager:getWorkAreaTypeIsAIArea(workArea.type) then
            workingWidth = math.max(workArea.workWidth, workingWidth)
        end
    end
    return workingWidth
end
function WorkArea:getIsFarmlandNotOwnedWarningShown()
    return self.spec_workArea.showFarmlandNotOwnedWarning
end
function WorkArea:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
    if not superFunc(self, speedRotatingPart, xmlFile, key) then
        return false
    end
    speedRotatingPart.workAreaIndex = xmlFile:getValue(key .. "#workAreaIndex")
    return true
end
function WorkArea:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
    if speedRotatingPart.workAreaIndex ~= nil then
        local spec = self.spec_workArea
        if spec.workAreas[speedRotatingPart.workAreaIndex] == nil then
            speedRotatingPart.workAreaIndex = nil
            Logging.xmlWarning(self.xmlFile, "Invalid workAreaIndex \'%s\'. Indexing starts with 1!", (tostring(speedRotatingPart.workAreaIndex)))
            return true
        end
        if not self:getIsWorkAreaProcessing(spec.workAreas[speedRotatingPart.workAreaIndex]) then
            return false
        end
    end
    return superFunc(self, speedRotatingPart)
end
function WorkArea:checkMovingPartDirtyUpdateNode(superFunc, node, movingPart)
    superFunc(self, node, movingPart)
    local spec = self.spec_workArea
    local i = 1
    for i = i, #spec.workAreas do
        local workArea = spec.workAreas[i]
        if node == workArea.start or (node == workArea.width or node == workArea.height) then
            Logging.xmlError(self.xmlFile, "Found work area node \'%s\' in active dirty moving part \'%s\' with limited update distance. Remove limit or adjust hierarchy for correct function. (maxUpdateDistance=\'-\')", getName(node), getName(movingPart.node))
        end
        if workArea.groundReferenceNode ~= nil and node == workArea.groundReferenceNode.node then
            Logging.xmlError(self.xmlFile, "Found ground reference node \'%s\' in active dirty moving part \'%s\' with limited update distance. Remove limit or adjust hierarchy for correct function. (maxUpdateDistance=\'-\')", getName(node), getName(movingPart.node))
        end
    end
end
function WorkArea:getImplementAllowAutomaticSteering(superFunc)
    for _, workArea in ipairs(self.spec_workArea.workAreas) do
        if g_workAreaTypeManager:getWorkAreaTypeIsSteeringAssistArea(workArea.type) then
            return true
        end
    end
    return superFunc(self)
end