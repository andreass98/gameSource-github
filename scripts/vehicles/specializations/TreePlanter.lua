source("dataS/scripts/vehicles/specializations/events/TreePlanterCreateTreeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TreePlanterLoadPalletEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TreePlanterTreeTypeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/PlantLimitToFieldEvent.lua")
TreePlanter = {}
TreePlanter.AI_REQUIRED_GROUND_TYPES = {
    FieldGroundType.STUBBLE_TILLAGE,
    FieldGroundType.CULTIVATED,
    FieldGroundType.SEEDBED,
    FieldGroundType.PLOWED,
    FieldGroundType.ROLLED_SEEDBED,
    FieldGroundType.RIDGE,
    FieldGroundType.SOWN,
    FieldGroundType.DIRECT_SOWN,
    FieldGroundType.PLANTED,
    FieldGroundType.RIDGE_SOWN,
    FieldGroundType.ROLLER_LINES,
    FieldGroundType.HARVEST_READY,
    FieldGroundType.HARVEST_READY_OTHER,
    FieldGroundType.GRASS,
    FieldGroundType.GRASS_CUT
}
function TreePlanter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations) and SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(GroundReference, specializations)
end
function TreePlanter.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("TreePlanter")
    schema:register(XMLValueType.STRING, "vehicle.treePlanter#inputAction", "Name of the input action to plant a tree manually (If set, the trees are planted manual only)")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.treePlanter#node", "Node index")
    schema:register(XMLValueType.FLOAT, "vehicle.treePlanter#minDistance", "Min. distance between trees", 20)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.treePlanter#palletTrigger", "Pallet trigger")
    schema:register(XMLValueType.INT, "vehicle.treePlanter#refNodeIndex", "Ground reference node index", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.treePlanter#saplingPalletGrabNode", "Sapling pallet grab node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.treePlanter#saplingPalletMountNode", "Sapling pallet mount node")
    schema:register(XMLValueType.INT, "vehicle.treePlanter#fillUnitIndex", "Fill unit index")
    schema:register(XMLValueType.FLOAT, "vehicle.treePlanter#palletMountingRange", "Min. distance from saplingPalletGrabNode to pallet to mount it", 6)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.treePlanter.saplingNodes.saplingNode(?)#node", "Link node for tree sapling (will be hidden based on fill level)")
    schema:register(XMLValueType.STRING, "vehicle.treePlanter.plantAnimation#name", "Name of plant animation")
    schema:register(XMLValueType.FLOAT, "vehicle.treePlanter.plantAnimation#speedScale", "Speed scale of animation", 1)
    schema:register(XMLValueType.STRING, "vehicle.treePlanter.magazineAnimation#name", "Name of magazine animation (updated based on fill level)")
    schema:register(XMLValueType.FLOAT, "vehicle.treePlanter.magazineAnimation#speedScale", "Speed scale of animation", 1)
    schema:register(XMLValueType.INT, "vehicle.treePlanter.magazineAnimation#numRows", "Number of rows on the magazine", 1)
    SoundManager.registerSampleXMLPaths(schema, "vehicle.treePlanter.sounds", "work")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.treePlanter.animationNodes")
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.VECTOR_TRANS, "vehicles.vehicle(?).treePlanter#lastTreePos", "Position of last tree")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).treePlanter#palletHadBeenMounted", "Pallet is mounted")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).treePlanter#currentTreeType", "Name of currently loaded tree type")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).treePlanter#currentTreeVariation", "Name of currently loaded tree stage variation")
end
function TreePlanter.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "removeMountedObject", TreePlanter.removeMountedObject)
    SpecializationUtil.registerFunction(vehicleType, "setPlantLimitToField", TreePlanter.setPlantLimitToField)
    SpecializationUtil.registerFunction(vehicleType, "createTree", TreePlanter.createTree)
    SpecializationUtil.registerFunction(vehicleType, "loadPallet", TreePlanter.loadPallet)
    SpecializationUtil.registerFunction(vehicleType, "palletTriggerCallback", TreePlanter.palletTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "onDeleteTreePlanterObject", TreePlanter.onDeleteTreePlanterObject)
    SpecializationUtil.registerFunction(vehicleType, "getCanPlantOutsideSeason", TreePlanter.getCanPlantOutsideSeason)
    SpecializationUtil.registerFunction(vehicleType, "setTreePlanterTreeTypeIndex", TreePlanter.setTreePlanterTreeTypeIndex)
    SpecializationUtil.registerFunction(vehicleType, "onTreePlanterSaplingLoaded", TreePlanter.onTreePlanterSaplingLoaded)
    SpecializationUtil.registerFunction(vehicleType, "updateTreePlanterFillLevel", TreePlanter.updateTreePlanterFillLevel)
end
function TreePlanter.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", TreePlanter.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", TreePlanter.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", TreePlanter.getIsSpeedRotatingPartActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", TreePlanter.getIsWorkAreaActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", TreePlanter.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", TreePlanter.getCanBeSelected)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsOnField", TreePlanter.getIsOnField)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", TreePlanter.addFillUnitFillLevel)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitFillLevel", TreePlanter.getFillUnitFillLevel)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitFillLevelPercentage", TreePlanter.getFillUnitFillLevelPercentage)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitFillType", TreePlanter.getFillUnitFillType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitCapacity", TreePlanter.getFillUnitCapacity)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitAllowsFillType", TreePlanter.getFillUnitAllowsFillType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitFreeCapacity", TreePlanter.getFillUnitFreeCapacity)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", TreePlanter.getFillLevelInformation)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getHasObjectMounted", TreePlanter.getHasObjectMounted)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitHasMountedPalletsToUnload", TreePlanter.getFillUnitHasMountedPalletsToUnload)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitUnloadPalletFilename", TreePlanter.getFillUnitUnloadPalletFilename)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitMountedPalletsToUnload", TreePlanter.getFillUnitMountedPalletsToUnload)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getImplementAllowAutomaticSteering", TreePlanter.getImplementAllowAutomaticSteering)
end
function TreePlanter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", TreePlanter)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", TreePlanter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", TreePlanter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", TreePlanter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", TreePlanter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", TreePlanter)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", TreePlanter)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", TreePlanter)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", TreePlanter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", TreePlanter)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", TreePlanter)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", TreePlanter)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitIsFillingStateChanged", TreePlanter)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", TreePlanter)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitUnloadPallet", TreePlanter)
end
function TreePlanter:onLoad(savegame)
    local spec = self.spec_treePlanter
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.treePlanterSound", "vehicle.treePlanter.sounds.work")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode(0)", "vehicle.treePlanter.animationNodes.animationNode")
    if self.isClient then
        spec.samples = {}
        spec.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.treePlanter.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.isWorkSamplePlaying = false
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.treePlanter.animationNodes", self.components, self, self.i3dMappings)
    end
    spec.inputAction = InputAction[self.xmlFile:getValue("vehicle.treePlanter#inputAction")]
    spec.node = self.xmlFile:getValue("vehicle.treePlanter#node", nil, self.components, self.i3dMappings)
    spec.minDistance = self.xmlFile:getValue("vehicle.treePlanter#minDistance", 20)
    spec.palletTrigger = self.xmlFile:getValue("vehicle.treePlanter#palletTrigger", nil, self.components, self.i3dMappings)
    if spec.palletTrigger == nil then
        Logging.xmlWarning(self.xmlFile, "TreePlanter requires a palletTrigger!")
    else
        addTrigger(spec.palletTrigger, "palletTriggerCallback", self)
        g_currentMission:addNodeObject(spec.palletTrigger, self)
    end
    spec.palletsInTrigger = {}
    spec.groundReferenceNode = self:getGroundReferenceNodeFromIndex((self.xmlFile:getValue("vehicle.treePlanter#refNodeIndex", 1)))
    if spec.groundReferenceNode == nil then
        Logging.xmlWarning(self.xmlFile, "No groundReferenceNode specified or invalid groundReferenceNode index in \'%s\'", "vehicle.treePlanter#refNodeIndex")
    end
    spec.currentTreeTypeIndex = nil
    spec.currentTreeVariationIndex = nil
    spec.saplingNodes = {}
    self.xmlFile:iterate("vehicle.treePlanter.saplingNodes.saplingNode", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        if node ~= nil then
            table.insert(spec.saplingNodes, node)
        end
    end)
    spec.plantAnimation = {}
    spec.plantAnimation.name = self.xmlFile:getValue("vehicle.treePlanter.plantAnimation#name")
    spec.plantAnimation.speedScale = self.xmlFile:getValue("vehicle.treePlanter.plantAnimation#speedScale", 1)
    spec.magazineAnimation = {}
    spec.magazineAnimation.name = self.xmlFile:getValue("vehicle.treePlanter.magazineAnimation#name")
    spec.magazineAnimation.speedScale = self.xmlFile:getValue("vehicle.treePlanter.magazineAnimation#speedScale", 1)
    spec.magazineAnimation.numRows = self.xmlFile:getValue("vehicle.treePlanter.magazineAnimation#numRows", 1)
    spec.activatable = TreePlanterActivatable.new(self)
    spec.saplingPalletGrabNode = self.xmlFile:getValue("vehicle.treePlanter#saplingPalletGrabNode", self.rootNode, self.components, self.i3dMappings)
    spec.saplingPalletMountNode = self.xmlFile:getValue("vehicle.treePlanter#saplingPalletMountNode", self.rootNode, self.components, self.i3dMappings)
    spec.mountedSaplingPallet = nil
    spec.fillUnitIndex = self.xmlFile:getValue("vehicle.treePlanter#fillUnitIndex", 1)
    spec.nearestPalletDistance = self.xmlFile:getValue("vehicle.treePlanter#palletMountingRange", 6)
    spec.currentTree = 1
    spec.lastTreePos = nil
    spec.showFieldNotOwnedWarning = false
    spec.showRestrictedZoneWarning = false
    spec.showTooManyTreesWarning = false
    spec.hasGroundContact = false
    spec.showWrongPlantingTimeWarning = false
    spec.limitToField = true
    spec.forceLimitToField = false
    if self.addAIGroundTypeRequirements ~= nil then
        self:addAIGroundTypeRequirements(TreePlanter.AI_REQUIRED_GROUND_TYPES)
        if self.setAIFruitProhibitions ~= nil then
            self:setAIFruitProhibitions(FruitType.POPLAR, 1, 5)
        end
    end
    spec.dirtyFlag = self:getNextDirtyFlag()
    if savegame ~= nil and not savegame.resetVehicles then
        spec.lastTreePos = savegame.xmlFile:getValue(savegame.key .. ".treePlanter#lastTreePos", nil, true)
        spec.palletHadBeenMounted = savegame.xmlFile:getValue(savegame.key .. ".treePlanter#palletHadBeenMounted")
        local treeTypeName = savegame.xmlFile:getValue(savegame.key .. ".treePlanter#currentTreeType")
        local variationName = savegame.xmlFile:getValue(savegame.key .. ".treePlanter#currentTreeVariation")
        if treeTypeName ~= nil then
            local treeTypeIndex, variationIndex = g_treePlantManager:getTreeTypeIndexAndVariationFromName(treeTypeName, 1, variationName)
            self:setTreePlanterTreeTypeIndex(treeTypeIndex, variationIndex, true)
        end
    end
end
function TreePlanter:onDelete()
    local spec = self.spec_treePlanter
    g_soundManager:deleteSamples(spec.samples)
    g_animationManager:deleteAnimations(spec.animationNodes)
    if spec.activatable ~= nil then
        g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    end
    if spec.mountedSaplingPallet ~= nil then
        spec.mountedSaplingPallet:unmount(true)
        spec.mountedSaplingPallet = nil
    end
    if spec.palletTrigger ~= nil then
        removeTrigger(spec.palletTrigger)
        g_currentMission:removeNodeObject(spec.palletTrigger)
    end
    if spec.saplingSharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(spec.saplingSharedLoadRequestId)
        spec.saplingSharedLoadRequestId = nil
    end
end
function TreePlanter:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_treePlanter
    if spec.lastTreePos ~= nil then
        xmlFile:setValue(key .. "#lastTreePos", unpack(spec.lastTreePos))
    end
    if spec.mountedSaplingPallet ~= nil then
        xmlFile:setValue(key .. "#palletHadBeenMounted", true)
    end
    if spec.currentTreeTypeIndex ~= nil then
        local treeTypeName, variationName = g_treePlantManager:getTreeTypeNameAndVariationByIndex(spec.currentTreeTypeIndex, 1, spec.currentTreeVariationIndex)
        if treeTypeName ~= nil then
            xmlFile:setValue(key .. "#currentTreeType", treeTypeName)
        end
        if variationName ~= nil then
            xmlFile:setValue(key .. "#currentTreeVariation", variationName)
        end
    end
end
function TreePlanter:removeMountedObject(object, _)
    local spec = self.spec_treePlanter
    if spec.mountedSaplingPallet == object then
        spec.mountedSaplingPallet:unmount()
        spec.mountedSaplingPallet = nil
    end
end
function TreePlanter:onReadStream(streamId, _)
    if streamReadBool(streamId) then
        self.spec_treePlanter.palletIdToMount = NetworkUtil.readNodeObjectId(streamId)
    end
    if streamReadBool(streamId) then
        self:setTreePlanterTreeTypeIndex(streamReadUInt32(streamId), streamReadUIntN(streamId, TreePlantManager.VARIATION_NUM_BITS), true)
    end
    if streamReadBool(streamId) then
        local treeTypeIndex = g_currentMission.vehicleXZPosCompressionParams
        spec.lastTreePos = { NetworkUtil.readCompressedWorldPosition(streamId, treeTypeIndex), NetworkUtil.readCompressedWorldPosition(streamId, g_currentMission.vehicleYPosCompressionParams), (NetworkUtil.readCompressedWorldPosition(streamId, treeTypeIndex)) }
    end
end
function TreePlanter:onWriteStream(streamId, _)
    local spec = self.spec_treePlanter
    local palletId = streamWriteBool
    palletId(streamId, spec.mountedSaplingPallet ~= nil)
    if spec.mountedSaplingPallet ~= nil then
        local palletId = NetworkUtil.getObjectId(spec.mountedSaplingPallet)
        NetworkUtil.writeNodeObjectId(streamId, palletId)
    end
    local palletId = streamWriteBool
    if palletId(streamId, spec.currentTreeTypeIndex ~= nil) then
        streamWriteUInt32(streamId, spec.currentTreeTypeIndex)
        streamWriteUIntN(streamId, spec.currentTreeVariationIndex or 1, TreePlantManager.VARIATION_NUM_BITS)
    end
    local palletId = streamWriteBool
    if palletId(streamId, spec.lastTreePos ~= nil) then
        local palletId = g_currentMission.vehicleXZPosCompressionParams
        NetworkUtil.writeCompressedWorldPosition(streamId, spec.lastTreePos[1], palletId)
        NetworkUtil.writeCompressedWorldPosition(streamId, spec.lastTreePos[2], g_currentMission.vehicleYPosCompressionParams)
        NetworkUtil.writeCompressedWorldPosition(streamId, spec.lastTreePos[3], palletId)
    end
end
function TreePlanter:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            self.spec_treePlanter.hasGroundContact = streamReadBool(streamId)
            spec.showFieldNotOwnedWarning = streamReadBool(streamId)
            spec.showRestrictedZoneWarning = streamReadBool(streamId)
        end
    end
end
function TreePlanter:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_treePlanter
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
            streamWriteBool(streamId, spec.hasGroundContact)
            streamWriteBool(streamId, spec.showFieldNotOwnedWarning)
            streamWriteBool(streamId, spec.showRestrictedZoneWarning)
        end
    end
end
function TreePlanter:onUpdate(_, _, _, _)
    local spec = self.spec_treePlanter
    if self.finishedFirstUpdate then
        local pallet = nil
        if spec.palletIdToMount == nil then
            if spec.palletHadBeenMounted then
                spec.palletHadBeenMounted = nil
                pallet = TreePlanter.getSaplingPalletInRange(self, spec.saplingPalletMountNode, spec.palletsInTrigger)
            end
        else
            pallet = NetworkUtil.getObject(spec.palletIdToMount)
        end
        if pallet ~= nil and pallet:getIsSynchronized() then
            pallet:mount(self, spec.saplingPalletMountNode, 0, 0, 0, 0, 0, 0)
            spec.mountedSaplingPallet = pallet
            g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
            spec.palletIdToMount = nil
            if self.isServer and pallet.getTreeSaplingPalletType ~= nil then
                local treeTypeName, variationName = pallet:getTreeSaplingPalletType()
                local treeTypeIndex, variationIndex = g_treePlantManager:getTreeTypeIndexAndVariationFromName(treeTypeName, 1, variationName)
                self:setTreePlanterTreeTypeIndex(treeTypeIndex, variationIndex)
            end
            FillUnit.updateUnloadActionDisplay(self)
        end
    end
    if self.isClient then
        local pallet = nil
        if spec.mountedSaplingPallet == nil then
            pallet = TreePlanter.getSaplingPalletInRange(self, spec.saplingPalletGrabNode, spec.palletsInTrigger)
        end
        if spec.nearestSaplingPallet ~= pallet then
            spec.nearestSaplingPallet = pallet
            if pallet == nil then
                g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
            else
                g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
            end
        end
    end
    if spec.mountedSaplingPallet ~= nil then
        if spec.mountedSaplingPallet.isDeleted then
            spec.palletsInTrigger[spec.mountedSaplingPallet] = nil
            spec.mountedSaplingPallet = nil
            return
        end
        spec.mountedSaplingPallet:raiseActive()
    end
end
function TreePlanter:onUpdateTick(dt, _, isActiveForInputIgnoreSelection, _)
    local spec = self.spec_treePlanter
    spec.showTooManyTreesWarning = false
    local showFieldNotOwnedWarning = false
    local showRestrictedZoneWarning = false
    if self.isServer then
        local hasGroundContact = false
        if spec.groundReferenceNode ~= nil then
            hasGroundContact = self:getIsGroundReferenceNodeActive(spec.groundReferenceNode)
        end
        if spec.hasGroundContact ~= hasGroundContact then
            self:raiseDirtyFlags(spec.dirtyFlag)
            spec.hasGroundContact = hasGroundContact
        end
    end
    if self:getIsAIActive() and (not g_currentMission.missionInfo.helperBuySeeds and spec.mountedSaplingPallet == nil) then
        self.rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())
    end
    spec.showWrongPlantingTimeWarning = false
    if spec.hasGroundContact and self:getIsTurnedOn() then
        local hasGroundContact = true
        if not self:getCanPlantOutsideSeason() then
            local fillType = self:getFillUnitFillType(spec.fillUnitIndex)
            local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByFillTypeIndex(fillType)
            hasGroundContact = true
            if fruitTypeDesc ~= nil then
                hasGroundContact = fruitTypeDesc:getIsPlantableInPeriod(g_currentMission.missionInfo.growthMode, g_currentMission.environment.currentPeriod)
            end
        end
        spec.showWrongPlantingTimeWarning = not hasGroundContact
        if self.isServer and hasGroundContact then
            local fillType = self:getFillUnitFillLevel(spec.fillUnitIndex)
            local fruitTypeDesc = self:getFillUnitFillType(spec.fillUnitIndex)
            if g_currentMission.missionInfo.helperBuySeeds and self:getIsAIActive() then
                if spec.mountedSaplingPallet == nil then
                    fruitTypeDesc = FillType.POPLAR
                else
                    fruitTypeDesc = spec.mountedSaplingPallet:getFillUnitFillType(1)
                end
            end
            if fillType == 0 and not (self:getIsAIActive() and g_currentMission.missionInfo.helperBuySeeds) then
                fruitTypeDesc = FillType.UNKNOWN
            end
            if fruitTypeDesc == FillType.TREESAPLINGS then
                if self:getLastSpeed() > 1 then
                    local x, y, z = getWorldTranslation(spec.node)
                    if g_currentMission.accessHandler:canFarmAccessLand(self:getActiveFarm(), x, z) then
                        if PlacementUtil.isInsideRestrictedZone(g_currentMission.restrictedZones, x, y, z, true) then
                            showRestrictedZoneWarning = true
                        elseif spec.lastTreePos == nil then
                            self:createTree()
                        elseif MathUtil.vector3Length(x - spec.lastTreePos[1], y - spec.lastTreePos[2], z - spec.lastTreePos[3]) > spec.minDistance then
                            self:createTree()
                        end
                    else
                        showFieldNotOwnedWarning = true
                    end
                end
            elseif fruitTypeDesc ~= FillType.UNKNOWN then
                local x, y, z = getWorldTranslation(spec.node)
                if g_currentMission.accessHandler:canFarmAccessLand(self:getActiveFarm(), x, z) then
                    local distance = math.sqrt((g_currentMission:getFruitPixelsToSqm())) * 0.5
                    local sx, _, sz = localToWorld(spec.node, -distance, 0, distance)
                    local wx, _, wz = localToWorld(spec.node, distance, 0, distance)
                    local hx, _, hz = localToWorld(spec.node, -distance, 0, 3 * distance)
                    local fruitType = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(fruitTypeDesc)
                    local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)
                    local dx, _, dz = localDirectionToWorld(spec.node, 0, 0, 1)
                    local angleRad = MathUtil.getYRotationFromDirection(dx, dz)
                    if fruitDesc ~= nil and fruitDesc.directionSnapAngle ~= 0 then
                        angleRad = math.floor(angleRad / fruitDesc.directionSnapAngle + 0.5) * fruitDesc.directionSnapAngle
                    end
                    local angle = FSDensityMapUtil.convertToDensityMapAngle(angleRad, g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
                    local limitToField = spec.limitToField or spec.forceLimitToField
                    FSDensityMapUtil.updateCultivatorArea(sx, sz, wx, wz, hx, hz, not limitToField, spec.limitToField or spec.forceLimitToField, angle, nil)
                    FSDensityMapUtil.eraseTireTrack(sx, sz, wx, wz, hx, hz)
                    local sowingValue, area, _ = localToWorld(spec.node, -distance, 0, -3 * distance)
                    local sowingValue, area, _ = localToWorld(spec.node, distance, 0, -3 * distance)
                    local sowingValue, area, _ = localToWorld(spec.node, -distance, 0, -distance)
                    local sowingValue = FieldGroundType.getValueByType(FieldGroundType.SOWN)
                    local area, _ = FSDensityMapUtil.updateSowingArea(fruitType, sowingValue, _, sowingValue, _, sowingValue, _, sowingValue, false, angle, 2)
                    local usage = fruitDesc.seedUsagePerSqm * area
                    local farmId = self:getActiveFarm()
                    if self:getIsAIActive() and g_currentMission.missionInfo.helperBuySeeds then
                        local price = usage * g_currentMission.economyManager:getCostPerLiter(FillType.SEEDS, false) * 1.5
                        g_farmManager:updateFarmStats(farmId, "expenses", price)
                        g_currentMission:addMoney(-price, self:getActiveFarm(), MoneyType.PURCHASE_SEEDS)
                    else
                        self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -usage, fruitTypeDesc, ToolType.UNDEFINED)
                    end
                    local price = MathUtil.areaToHa(area, g_currentMission:getFruitPixelsToSqm())
                    g_farmManager:updateFarmStats(farmId, "seedUsage", usage)
                    g_farmManager:updateFarmStats(farmId, "sownHectares", price)
                    g_farmManager:updateFarmStats(farmId, "sownTime", dt / 60000)
                    self:updateLastWorkedArea(area)
                else
                    showFieldNotOwnedWarning = true
                end
            end
        end
    end
    if self.isServer and (spec.showFieldNotOwnedWarning ~= showFieldNotOwnedWarning or spec.showRestrictedZoneWarning ~= showRestrictedZoneWarning) then
        spec.showFieldNotOwnedWarning = showFieldNotOwnedWarning
        spec.showRestrictedZoneWarning = showRestrictedZoneWarning
        self:raiseDirtyFlags(spec.dirtyFlag)
    end
    if self.isClient then
        if self:getIsTurnedOn() and (spec.hasGroundContact and self:getLastSpeed() > 1) then
            if not spec.isWorkSamplePlaying then
                g_soundManager:playSample(spec.samples.work)
                spec.isWorkSamplePlaying = true
            end
        elseif spec.isWorkSamplePlaying then
            g_soundManager:stopSample(spec.samples.work)
            spec.isWorkSamplePlaying = false
        end
        local hasGroundContact = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]
        if hasGroundContact ~= nil then
            local fillType = false
            if isActiveForInputIgnoreSelection then
                local fruitTypeDesc = self:getFillUnitFillType(spec.fillUnitIndex)
                fillType = fruitTypeDesc ~= FillType.UNKNOWN and (fruitTypeDesc ~= FillType.TREESAPLINGS and (g_currentMission:getHasPlayerPermission("createFields", self:getOwnerConnection()) and not spec.forceLimitToField)) and true or fillType
                if fillType then
                    if spec.limitToField then
                        g_inputBinding:setActionEventText(hasGroundContact.actionEventId, g_i18n:getText("action_allowCreateFields"))
                    else
                        g_inputBinding:setActionEventText(hasGroundContact.actionEventId, g_i18n:getText("action_limitToFields"))
                    end
                end
            end
            g_inputBinding:setActionEventActive(hasGroundContact.actionEventId, fillType)
        end
        if spec.inputAction ~= nil then
            local fillType = spec.actionEvents[spec.inputAction]
            if fillType ~= nil then
                local fruitTypeDesc = true
                if spec.lastTreePos ~= nil then
                    local x, y, z = getWorldTranslation(spec.node)
                    fruitTypeDesc = MathUtil.vector3Length(x - spec.lastTreePos[1], y - spec.lastTreePos[2], z - spec.lastTreePos[3]) > spec.minDistance
                end
                local x = g_inputBinding
                local z = fillType.actionEventId
                if fruitTypeDesc then
                    fruitTypeDesc = self:getFillUnitFillLevel(spec.fillUnitIndex) > 0
                end
                x:setActionEventActive(z, fruitTypeDesc)
            end
        end
    end
end
function TreePlanter:onDraw(_, isActiveForInputIgnoreSelection, _)
    local spec = self.spec_treePlanter
    if isActiveForInputIgnoreSelection then
        if self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 then
            g_currentMission:addExtraPrintText(g_i18n:getText("info_firstFillTheTool"))
        end
        if spec.currentTreeTypeIndex ~= nil and (self:getFillUnitFillLevel(spec.fillUnitIndex) > 0 and spec.treeTypeExtraPrintText ~= nil) then
            g_currentMission:addExtraPrintText(spec.treeTypeExtraPrintText)
        end
    end
    if spec.showFieldNotOwnedWarning then
        g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"))
    end
    if spec.showRestrictedZoneWarning then
        g_currentMission:showBlinkingWarning(g_i18n:getText("warning_actionNotAllowedHere"))
    end
    if spec.showTooManyTreesWarning then
        g_currentMission:showBlinkingWarning(g_i18n:getText("warning_tooManyTrees"))
    end
    if spec.showWrongPlantingTimeWarning then
        g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("warning_theSelectedFruitTypeCantBePlantedInThisPeriod"), g_i18n:formatPeriod()), 100)
    end
end
function TreePlanter:onTurnedOn()
    if self.isClient then
        g_animationManager:startAnimations(self.spec_treePlanter.animationNodes)
    end
end
function TreePlanter:onTurnedOff()
    if self.isClient then
        local spec = self.spec_treePlanter
        g_animationManager:stopAnimations(spec.animationNodes)
        g_soundManager:stopSamples(spec.samples)
        spec.isWorkSamplePlaying = false
    end
end
function TreePlanter:onFillUnitIsFillingStateChanged(isFilling)
    if self.isServer and isFilling then
        local trigger = self.spec_fillUnit.fillTrigger.currentTrigger
        if trigger ~= nil and (trigger.sourceObject ~= nil and trigger.sourceObject.getTreeSaplingPalletType ~= nil) then
            local treeTypeName, variationName = trigger.sourceObject:getTreeSaplingPalletType()
            local treeTypeIndex, variationIndex = g_treePlantManager:getTreeTypeIndexAndVariationFromName(treeTypeName, 1, variationName)
            self:setTreePlanterTreeTypeIndex(treeTypeIndex, variationIndex)
        end
    end
end
function TreePlanter:onFillUnitFillLevelChanged(fillUnitIndex, _, _, _, _, _)
    if fillUnitIndex == self.spec_treePlanter.fillUnitIndex then
        self:updateTreePlanterFillLevel()
    end
end
function TreePlanter:onFillUnitUnloadPallet(pallet)
    local spec = self.spec_treePlanter
    if pallet.setTreeSaplingPalletType ~= nil then
        local treeTypeName, variationName = g_treePlantManager:getTreeTypeNameAndVariationByIndex(spec.currentTreeTypeIndex, 1, spec.currentTreeVariationIndex)
        pallet:setTreeSaplingPalletType(treeTypeName, variationName)
    end
    if spec.mountedSaplingPallet == pallet then
        spec.mountedSaplingPallet = nil
    end
end
function TreePlanter:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
    local spec = self.spec_treePlanter
    if fillUnitIndex == spec.fillUnitIndex then
        local pallet = spec.mountedSaplingPallet
        if pallet ~= nil then
            local fillUnits = pallet:getFillUnits()
            for palletFillUnitIndex, _ in pairs(fillUnits) do
                if pallet:getFillUnitFillType(fillUnitIndex) == fillTypeIndex then
                    return pallet:addFillUnitFillLevel(self:getOwnerFarmId(), palletFillUnitIndex, fillLevelDelta, fillTypeIndex, ToolType.UNDEFINED)
                end
            end
        end
    end
    return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
end
function TreePlanter:getFillUnitFillLevel(superFunc, fillUnitIndex)
    local spec = self.spec_treePlanter
    if fillUnitIndex == spec.fillUnitIndex then
        local pallet = spec.mountedSaplingPallet
        if pallet ~= nil then
            local fillLevel = 0
            local fillUnits = pallet:getFillUnits()
            for palletFillUnitIndex, _ in pairs(fillUnits) do
                fillLevel = fillLevel + pallet:getFillUnitFillLevel(palletFillUnitIndex)
            end
            return fillLevel
        end
    end
    return superFunc(self, fillUnitIndex)
end
function TreePlanter:getFillUnitFillLevelPercentage(superFunc, fillUnitIndex)
    local spec = self.spec_treePlanter
    if fillUnitIndex == spec.fillUnitIndex and spec.mountedSaplingPallet ~= nil then
        local capacity = self:getFillUnitCapacity(fillUnitIndex)
        local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)
        if capacity > 0 then
            return fillLevel / capacity
        end
    end
    return superFunc(self, fillUnitIndex)
end
function TreePlanter:getFillUnitFillType(superFunc, fillUnitIndex)
    local spec = self.spec_treePlanter
    if fillUnitIndex == spec.fillUnitIndex then
        local pallet = spec.mountedSaplingPallet
        if pallet ~= nil then
            local fillUnits = pallet:getFillUnits()
            for palletFillUnitIndex, _ in pairs(fillUnits) do
                if pallet:getFillUnitFillLevel(palletFillUnitIndex) > 0 then
                    return pallet:getFillUnitFillType(palletFillUnitIndex)
                end
            end
        end
    end
    return superFunc(self, fillUnitIndex)
end
function TreePlanter:getFillUnitCapacity(superFunc, fillUnitIndex)
    local spec = self.spec_treePlanter
    if fillUnitIndex == spec.fillUnitIndex then
        local pallet = spec.mountedSaplingPallet
        if pallet ~= nil then
            local capacity = 0
            local fillUnits = pallet:getFillUnits()
            for palletFillUnitIndex, _ in pairs(fillUnits) do
                capacity = capacity + pallet:getFillUnitCapacity(palletFillUnitIndex)
            end
            return capacity
        end
    end
    return superFunc(self, fillUnitIndex)
end
function TreePlanter:getFillUnitAllowsFillType(superFunc, fillUnitIndex, fillType)
    local spec = self.spec_treePlanter
    if fillUnitIndex == spec.fillUnitIndex and spec.mountedSaplingPallet ~= nil then
        return false
    else
        return superFunc(self, fillUnitIndex, fillType)
    end
end
function TreePlanter:getFillUnitFreeCapacity(superFunc, fillUnitIndex, fillTypeIndex, farmId)
    local spec = self.spec_treePlanter
    return fillUnitIndex == spec.fillUnitIndex and spec.mountedSaplingPallet ~= nil and 0 or superFunc(self, fillUnitIndex, fillTypeIndex, farmId)
end
function TreePlanter:getFillLevelInformation(superFunc, display)
    local spec = self.spec_treePlanter
    if spec.mountedSaplingPallet ~= nil then
        local capacity = self:getFillUnitCapacity(spec.fillUnitIndex)
        local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)
        display:addFillLevel(self:getFillUnitFillType(spec.fillUnitIndex), fillLevel, capacity)
    end
    superFunc(self, display)
end
function TreePlanter:getHasObjectMounted(superFunc, object)
    if superFunc(self, object) then
        return true
    end
    local pallet = self.spec_treePlanter.mountedSaplingPallet
    if pallet ~= nil then
        if pallet == object then
            return true
        end
        if pallet.getHasObjectMounted ~= nil and pallet:getHasObjectMounted(object) then
            return true
        end
    end
    return false
end
function TreePlanter:getFillUnitUnloadPalletFilename(_, _)
    local spec = self.spec_treePlanter
    if spec.mountedSaplingPallet == nil and spec.currentTreeTypeIndex ~= nil then
        return g_treePlantManager:getPalletStoreItemFilenameByIndex(spec.currentTreeTypeIndex, 1, spec.currentTreeVariationIndex)
    end
end
function TreePlanter:getFillUnitHasMountedPalletsToUnload(_)
    return self.spec_treePlanter.mountedSaplingPallet ~= nil
end
function TreePlanter:getFillUnitMountedPalletsToUnload(_)
    return { self.spec_treePlanter.mountedSaplingPallet }
end
function TreePlanter:getImplementAllowAutomaticSteering(superFunc)
    return true
end
function TreePlanter:getCanPlantOutsideSeason()
    return false
end
function TreePlanter:setTreePlanterTreeTypeIndex(treeTypeIndex, treeVariationIndex, noEventSend)
    local spec = self.spec_treePlanter
    if treeTypeIndex ~= spec.currentTreeTypeIndex or treeVariationIndex ~= spec.currentTreeVariationIndex then
        spec.currentTreeTypeIndex = treeTypeIndex
        spec.currentTreeVariationIndex = treeVariationIndex
        local treeTypeDesc = g_treePlantManager:getTreeTypeDescFromIndex(spec.currentTreeTypeIndex)
        if treeTypeDesc ~= nil then
            spec.treeTypeExtraPrintText = string.format("%s: %s", g_i18n:getText("configuration_treeType"), treeTypeDesc.title)
        end
        if #spec.saplingNodes > 0 then
            if spec.saplingSharedLoadRequestId ~= nil then
                g_i3DManager:releaseSharedI3DFile(spec.saplingSharedLoadRequestId)
                spec.saplingSharedLoadRequestId = nil
            end
            local treeSaplingFilename = nil
            if treeTypeDesc ~= nil then
                local variations = treeTypeDesc.stages[1]
                if variations ~= nil then
                    local variation = variations[treeVariationIndex]
                    if variation ~= nil then
                        treeSaplingFilename = variation.planterFilename or variation.filename
                    end
                end
            end
            if treeSaplingFilename ~= nil then
                spec.saplingSharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(treeSaplingFilename, false, false, self.onTreePlanterSaplingLoaded, self)
            end
        end
        TreePlanterTreeTypeEvent.sendEvent(self, treeTypeIndex, treeVariationIndex, noEventSend)
    end
end
function TreePlanter:onTreePlanterSaplingLoaded(i3dNode, _, _)
    if i3dNode ~= 0 then
        local sourceSapling = getChildAt(i3dNode, 0)
        local spec = self.spec_treePlanter
        local i = 1
        for i = i, #spec.saplingNodes do
            local sapling = clone(sourceSapling, false, false, false)
            link(spec.saplingNodes[i], sapling)
        end
        self:updateTreePlanterFillLevel(true)
        delete(i3dNode)
    end
end
function TreePlanter:updateTreePlanterFillLevel(onLoad)
    local spec = self.spec_treePlanter
    local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)
    local capacity = self:getFillUnitCapacity(spec.fillUnitIndex)
    local i = 1
    local targetAnimationTime = #spec.saplingNodes
    local animationTime = 1
    for i = i, targetAnimationTime, animationTime do
        local node = spec.saplingNodes[i]
        setVisibility(node, i <= MathUtil.round(fillLevel))
        I3DUtil.setShaderParameterRec(node, "hideByIndex", capacity - fillLevel, 0, 0, 0)
    end
    if spec.magazineAnimation.name ~= nil then
        local targetAnimationTime = math.ceil((fillLevel - 1) / capacity * spec.magazineAnimation.numRows) / spec.magazineAnimation.numRows
        local animationTime = self:getAnimationTime(spec.magazineAnimation.name)
        if targetAnimationTime ~= animationTime then
            self:setAnimationStopTime(spec.magazineAnimation.name, targetAnimationTime)
            self:playAnimation(spec.magazineAnimation.name, spec.magazineAnimation.speedScale * math.sign(targetAnimationTime - animationTime), animationTime, true)
            if onLoad then
                AnimatedVehicle.updateAnimationByName(self, spec.magazineAnimation.name, 999999, true)
            end
        end
    end
    if spec.unloadActionEventId ~= nil then
        g_inputBinding:setActionEventActive(spec.unloadActionEventId, fillLevel > 0)
    end
end
function TreePlanter:setPlantLimitToField(plantLimitToField, noEventSend)
    local spec = self.spec_treePlanter
    if spec.limitToField ~= plantLimitToField then
        spec.limitToField = plantLimitToField
        PlantLimitToFieldEvent.sendEvent(self, plantLimitToField, noEventSend)
    end
end
function TreePlanter:createTree(noEventSend)
    if g_treePlantManager:canPlantTree() then
        if self.isServer then
            local x, y, z = getWorldTranslation(self.spec_treePlanter.node)
            local yRot = math.random() * 2 * 3.141592653589793
            local treeTypeIndex = spec.currentTreeTypeIndex
            local variationIndex = spec.currentTreeVariationIndex
            if treeTypeIndex == nil or variationIndex == nil then
                Logging.error("Failed to plant tree. Tree type not found. (treeType %s, variation %s)", treeTypeIndex, variationIndex)
                return
            end
            g_treePlantManager:plantTree(treeTypeIndex, x, y, z, 0, yRot, 0, 1, variationIndex)
            if spec.lastTreePos == nil then
                spec.lastTreePos = { x, y, z }
            else
                spec.lastTreePos[1] = x
                spec.lastTreePos[2] = y
                spec.lastTreePos[3] = z
            end
            local farmId = self:getActiveFarm()
            if g_currentMission.missionInfo.helperBuySeeds and self:getIsAIActive() then
                local pallet = spec.mountedSaplingPallet
                if pallet ~= nil then
                    local pricePerSapling = 1.5 * (g_storeManager:getItemByXMLFilename(pallet.configFileName).price / pallet:getFillUnitCapacity(1))
                    g_farmManager:updateFarmStats(farmId, "expenses", pricePerSapling)
                    g_currentMission:addMoney(-pricePerSapling, self:getActiveFarm(), MoneyType.PURCHASE_SEEDS)
                end
            else
                local pallet = self:getFillUnitFillLevel(spec.fillUnitIndex) < 1.5 and -math.huge or -0.9999
                self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, pallet, self:getFillUnitFillType(spec.fillUnitIndex), ToolType.UNDEFINED)
            end
            g_farmManager:updateFarmStats(farmId, "plantedTreeCount", 1)
        else
            local x, y, z = getWorldTranslation(spec.node)
            if spec.lastTreePos == nil then
                spec.lastTreePos = { x, y, z }
            else
                spec.lastTreePos[1] = x
                spec.lastTreePos[2] = y
                spec.lastTreePos[3] = z
            end
        end
        if self.isClient and spec.plantAnimation.name ~= nil then
            self:setAnimationTime(spec.plantAnimation.name, 0, true)
            self:playAnimation(spec.plantAnimation.name, spec.plantAnimation.speedScale, 0, true)
        end
        TreePlanterCreateTreeEvent.sendEvent(self, noEventSend)
    else
        spec.showTooManyTreesWarning = true
    end
end
function TreePlanter:loadPallet(palletObjectId, noEventSend)
    TreePlanterLoadPalletEvent.sendEvent(self, palletObjectId, noEventSend)
    self.spec_treePlanter.palletIdToMount = palletObjectId
end
function TreePlanter:getDirtMultiplier(superFunc)
    local multiplier = superFunc(self)
    if self.spec_treePlanter.hasGroundContact then
        multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
    end
    return multiplier
end
function TreePlanter:getWearMultiplier(superFunc)
    local multiplier = superFunc(self)
    if self.spec_treePlanter.hasGroundContact then
        multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
    end
    return multiplier
end
function TreePlanter:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
    if self.spec_treePlanter.hasGroundContact then
        return superFunc(self, speedRotatingPart)
    else
        return false
    end
end
function TreePlanter:getIsWorkAreaActive(superFunc, workArea)
    local isActive = superFunc(self, workArea)
    if workArea.groundReferenceNode == self.spec_treePlanter.groundReferenceNode and not self:getIsTurnedOn() then
        isActive = false
    end
    return isActive
end
function TreePlanter:doCheckSpeedLimit(superFunc)
    return not superFunc(self) and self:getIsTurnedOn() and self:getIsImplementChainLowered()
end
function TreePlanter:getCanBeSelected(superFunc)
    return true
end
function TreePlanter:onDeleteTreePlanterObject(object)
    local spec = self.spec_treePlanter
    if spec.mountedSaplingPallet == object then
        spec.mountedSaplingPallet = nil
    end
    spec.palletsInTrigger[object] = nil
end
function TreePlanter:getIsOnField(superFunc)
    return superFunc(self) and true or (self.spec_treePlanter.hasGroundContact and true or false)
end
function TreePlanter:palletTriggerCallback(_, otherId, onEnter, onLeave, _, _)
    if otherId ~= 0 then
        local object = g_currentMission:getNodeObject(otherId)
        if object ~= nil and (object.isa ~= nil and (object:isa(Vehicle) and (object.isPallet and g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), object)))) then
            local currentValue = Utils.getNoNil(self.spec_treePlanter.palletsInTrigger[object], 0)
            if onEnter then
                spec.palletsInTrigger[object] = currentValue + 1
                if currentValue == 0 and object.addDeleteListener ~= nil then
                    object:addDeleteListener(self, "onDeleteTreePlanterObject")
                end
            elseif onLeave then
                spec.palletsInTrigger[object] = math.max(currentValue - 1, 0)
            end
            if spec.palletsInTrigger[object] == 0 then
                spec.palletsInTrigger[object] = nil
            end
        end
    end
end
function TreePlanter:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_treePlanter
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            if not spec.forceLimitToField then
                local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, TreePlanter.actionEventToggleTreePlanterFieldLimitation, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            end
            if spec.inputAction ~= nil then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, spec.inputAction, self, TreePlanter.actionEventPlant, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
                g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_plantTree"))
            end
        end
    end
end
function TreePlanter:actionEventToggleTreePlanterFieldLimitation(_, _, _, _)
    self:setPlantLimitToField(not self.spec_treePlanter.limitToField)
end
function TreePlanter:actionEventPlant(_, _, _, _)
    local spec = self.spec_treePlanter
    if spec.hasGroundContact then
        if g_treePlantManager:canPlantTree() then
            local x, y, z = getWorldTranslation(spec.node)
            if g_currentMission.accessHandler:canFarmAccessLand(self:getActiveFarm(), x, z) then
                if PlacementUtil.isInsideRestrictedZone(g_currentMission.restrictedZones, x, y, z, true) then
                    g_currentMission:showBlinkingWarning(g_i18n:getText("warning_actionNotAllowedHere"))
                else
                    self:createTree()
                end
            else
                g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"))
                return
            end
        else
            g_currentMission:showBlinkingWarning(g_i18n:getText("warning_tooManyTrees"))
            return
        end
    else
        g_currentMission:showBlinkingWarning(g_i18n:getText("warning_treePlanterNoGroundContact"))
        return
    end
end
function TreePlanter.getDefaultSpeedLimit()
    return 5
end
function TreePlanter:getSaplingPalletInRange(refNode, palletsInTrigger)
    local spec = self.spec_treePlanter
    local nearestSaplingPallet = nil
    for object, state in pairs(palletsInTrigger) do
        if state ~= nil and (state > 0 and (object ~= spec.mountedSaplingPallet and calcDistanceFrom(refNode, object.rootNode) < spec.nearestPalletDistance)) then
            local validPallet = false
            local fillUnits = object:getFillUnits()
            for fillUnitIndex, _ in pairs(fillUnits) do
                local filltype = object:getFillUnitFillType(fillUnitIndex)
                if filltype ~= FillType.UNKNOWN and (self:getFillUnitSupportsFillType(spec.fillUnitIndex, filltype) and object:getFillUnitFillLevel(fillUnitIndex) > 0) then
                    validPallet = true
                    break
                end
            end
            if validPallet then
                nearestSaplingPallet = object
            end
        end
    end
    return nearestSaplingPallet
end
TreePlanterActivatable = {}
local TreePlanterActivatable_mt = Class(TreePlanterActivatable)
function TreePlanterActivatable.new(treePlanterVehicle)
    -- upvalues: (copy) TreePlanterActivatable_mt
    local self = setmetatable({}, TreePlanterActivatable_mt)
    self.treePlanterVehicle = treePlanterVehicle
    self.activateText = string.format(g_i18n:getText("action_refillOBJECT"), self.treePlanterVehicle.typeDesc)
    return self
end
function TreePlanterActivatable:getIsActivatable()
    if self.treePlanterVehicle.rootVehicle == g_localPlayer:getCurrentVehicle() then
        return self.treePlanterVehicle.spec_treePlanter.mountedSaplingPallet == nil and self.treePlanterVehicle.spec_treePlanter.nearestSaplingPallet ~= nil
    else
        return false
    end
end
function TreePlanterActivatable:run()
    self.treePlanterVehicle:loadPallet(NetworkUtil.getObjectId(self.treePlanterVehicle.spec_treePlanter.nearestSaplingPallet))
end