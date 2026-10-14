PlayerHUDUpdater = {}
local PlayerHUDUpdater_mt = Class(PlayerHUDUpdater)
function PlayerHUDUpdater.new()
    -- upvalues: (copy) PlayerHUDUpdater_mt
    local self = setmetatable({}, PlayerHUDUpdater_mt)
    self.object = nil
    self.splitShape = nil
    self.isBale = false
    self.isVehicle = false
    self.isPallet = false
    self.isSplitShape = false
    self.isAnimal = false
    if Platform.isMobile then
        self.fieldBox = g_currentMission.hud.infoDisplay:createBox(InfoDisplayKeyValueBoxMobile)
        self.objectBox = infoDisplay:createBox(InfoDisplayKeyValueBoxMobile)
    else
        self.fieldBox = infoDisplay:createBox(InfoDisplayKeyValueBox)
        self.objectBox = infoDisplay:createBox(InfoDisplayKeyValueBox)
    end
    self.fieldInfo = FieldState.new()
    return self
end
function PlayerHUDUpdater:delete()
    local infoDisplay = g_currentMission.hud.infoDisplay
    infoDisplay:destroyBox(self.fieldBox)
    infoDisplay:destroyBox(self.objectBox)
end
function PlayerHUDUpdater:update(_, x, _, z, rotY)
    self:showFieldInfo(x, z, rotY)
    if Platform.playerInfo.showVehicleInfo then
        if self.isVehicle then
            self:showVehicleInfo(self.object)
            return
        end
        if self.isBale then
            self:showBaleInfo(self.object)
            return
        end
        if self.isPallet then
            self:showPalletInfo(self.object)
            return
        end
        if self.isSplitShape and self.splitShape ~= nil then
            self:showSplitShapeInfo(self.splitShape)
            return
        end
        if self.isAnimal then
            self:showAnimalInfo(self.object)
        end
    end
end
function PlayerHUDUpdater:setCurrentRaycastTarget(node)
    if self.currentRaycastTarget ~= node then
        self.currentRaycastTarget = node
        self:updateRaycastObject()
    end
end
function PlayerHUDUpdater:updateRaycastObject()
    if self.object ~= nil and self.object.removeDeleteListener ~= nil then
        self.object:removeDeleteListener(self, PlayerHUDUpdater.onDeleteObject)
    end
    self.isBale = false
    self.isVehicle = false
    self.isPallet = false
    self.isSplitShape = false
    self.isAnimal = false
    self.object = nil
    self.splitShape = nil
    if self.currentRaycastTarget == nil or not entityExists(self.currentRaycastTarget) then
        return
    else
        local object = g_currentMission:getNodeObject(self.currentRaycastTarget)
        if object == nil then
            if getHasClassId(self.currentRaycastTarget, ClassIds.MESH_SPLIT_SHAPE) then
                self.isSplitShape = true
                self.splitShape = self.currentRaycastTarget
            else
                local husbandryId, animalId = getAnimalFromCollisionNode(self.currentRaycastTarget)
                if husbandryId ~= nil and husbandryId ~= 0 then
                    local clusterHusbandry = g_currentMission.husbandrySystem:getClusterHusbandryById(husbandryId)
                    if clusterHusbandry ~= nil then
                        local cluster = clusterHusbandry:getClusterByAnimalId(animalId)
                        if cluster ~= nil then
                            self.isAnimal = true
                            self.object = cluster
                            return
                        end
                    end
                end
            end
        else
            self.object = object
            if object:isa(Vehicle) then
                if object.isPallet then
                    self.isPallet = true
                else
                    self.isVehicle = true
                end
            elseif object:isa(Bale) then
                self.isBale = true
            end
            if self.object ~= nil and self.object.addDeleteListener ~= nil then
                self.object:addDeleteListener(self, PlayerHUDUpdater.onDeleteObject)
            end
            return
        end
    end
end
function PlayerHUDUpdater:onDeleteObject(object)
    if object == self.object then
        self.isBale = false
        self.isVehicle = false
        self.isPallet = false
        self.isSplitShape = false
        self.isAnimal = false
        self.object = nil
    end
end
function PlayerHUDUpdater.convertFarmToName(_, farm)
    if g_currentMission.missionDynamicInfo.isMultiplayer then
        return farm.name
    else
        return g_i18n:getText("fieldInfo_ownerYou")
    end
end
function PlayerHUDUpdater:showVehicleInfo(vehicle)
    local name = vehicle:getFullName()
    local farmId = vehicle:getOwnerFarmId()
    if farmId ~= FarmManager.SPECTATOR_FARM_ID then
        local box = self.objectBox
        box:clear()
        box:setTitle(name)
        local farm = g_farmManager:getFarmById(farmId)
        if farm ~= nil then
            if vehicle:getPropertyState() == VehiclePropertyState.OWNED then
                box:addLine(g_i18n:getText("fieldInfo_ownedBy"), self:convertFarmToName(farm))
            else
                box:addLine(g_i18n:getText("infohud_rentedBy"), self:convertFarmToName(farm))
            end
        end
        vehicle:showInfo(box)
        box:showNextFrame()
    end
end
function PlayerHUDUpdater:showBaleInfo(bale)
    local farm = g_farmManager:getFarmById(bale:getOwnerFarmId())
    local box = self.objectBox
    box:clear()
    box:setTitle(g_i18n:getText("infohud_bale"))
    if farm ~= nil then
        box:addLine(g_i18n:getText("fieldInfo_ownedBy"), self:convertFarmToName(farm))
    end
    bale:showInfo(box)
    box:showNextFrame()
end
function PlayerHUDUpdater:showPalletInfo(pallet)
    local mass = pallet:getTotalMass()
    local farm = g_farmManager:getFarmById(pallet:getOwnerFarmId())
    local box = self.objectBox
    box:clear()
    if pallet.getInfoBoxTitle == nil then
        box:setTitle(g_i18n:getText("infohud_pallet"))
    else
        box:setTitle(pallet:getInfoBoxTitle())
    end
    if farm ~= nil then
        box:addLine(g_i18n:getText("fieldInfo_ownedBy"), self:convertFarmToName(farm))
    end
    box:addLine(g_i18n:getText("infohud_mass"), g_i18n:formatMass(mass))
    pallet:showInfo(box)
    box:showNextFrame()
end
function PlayerHUDUpdater:showSplitShapeInfo(shape)
    if entityExists(shape) and getHasClassId(shape, ClassIds.MESH_SPLIT_SHAPE) then
        local splitTypeId = getSplitType(shape)
        if splitTypeId == 0 then
            return
        else
            local isSplit = getIsSplitShapeSplit(shape)
            local isStatic = getRigidBodyType(shape) == RigidBodyType.STATIC
            if isSplit and isStatic then
                return
            else
                local sizeX, sizeY, sizeZ, numConvexes, numAttachments = getSplitShapeStats(shape)
                local splitType = g_splitShapeManager:getSplitTypeByIndex(splitTypeId)
                if splitType then
                end
                local length = math.max(sizeX, sizeY, sizeZ)
                if math.abs(length) ~= math.huge then
                    local box = self.objectBox
                    box:clear()
                    if isSplit then
                        box:setTitle(g_i18n:getText("infohud_wood"))
                    else
                        box:setTitle(g_i18n:getText("infohud_tree"))
                    end
                    if splitType ~= nil then
                        box:addLine(g_i18n:getText("infohud_type"), splitType)
                    end
                    box:addLine(g_i18n:getText("infohud_length"), g_i18n:formatNumber(length, 1) .. " m")
                    if g_currentMission:getIsServer() and not isStatic then
                        local mass = getMass(shape)
                        box:addLine(g_i18n:getText("infohud_mass"), g_i18n:formatMass(mass))
                    end
                    box:showNextFrame()
                end
            end
        end
    else
        return
    end
end
function PlayerHUDUpdater:showAnimalInfo(cluster)
    local box = self.objectBox
    box:clear()
    box:setTitle(g_i18n:getText("infohud_animal"))
    cluster:showInfo(box)
    box:showNextFrame()
end
function PlayerHUDUpdater:onFieldDataUpdateFinished(data)
    if self.requestedFieldData then
        self.fieldData = data
        self.fieldInfoNeedsRebuild = true
    end
    self.requestedFieldData = false
end
function PlayerHUDUpdater:showFieldInfo(posX, posZ, rotY)
    local fieldInfo = self.fieldInfo
    local dirX, dirZ = MathUtil.getDirectionFromYRotation(rotY)
    fieldInfo:update(posX + dirX * 2, posZ + dirZ * 2)
    if fieldInfo.groundType ~= FieldGroundType.NONE then
        local box = self.fieldBox
        box:clear()
        box:setTitle(g_i18n:getText("ui_fieldInfo"))
        self:fieldAddFarmland(fieldInfo, box)
        self:fieldAddField(fieldInfo, box)
        self:fieldAddWeed(fieldInfo, box)
        self:fieldAddFieldActions(fieldInfo, box)
        self.fieldInfoNeedsRebuild = false
        box:showNextFrame()
    end
end
function PlayerHUDUpdater.fieldAddFarmland(_, fieldInfo, box)
    local ownedByYou = false
    local ownerFarmId = fieldInfo.ownerFarmId
    local farmName
    if ownerFarmId == g_currentMission:getFarmId() and ownerFarmId ~= FarmManager.SPECTATOR_FARM_ID then
        farmName = g_i18n:getText("fieldInfo_ownerYou")
        ownedByYou = true
    elseif ownerFarmId == AccessHandler.EVERYONE or ownerFarmId == AccessHandler.NOBODY then
        local farmland = g_farmlandManager:getFarmlandById(fieldInfo.farmlandId)
        if farmland == nil then
            farmName = g_i18n:getText("fieldInfo_ownerNobody")
        else
            local npc = farmland:getNPC()
            farmName = npc ~= nil and npc.title or "Unknown"
        end
    else
        local farmland = g_farmManager:getFarmById(ownerFarmId)
        farmName = farmland == nil and "Unknown" or farmland.name
    end
    box:addLine(g_i18n:getText("fieldInfo_farmland"), (tostring(fieldInfo.farmlandId)))
    if Platform.playerInfo.showNPCNames then
        box:addLine(g_i18n:getText("fieldInfo_ownedBy"), farmName)
        return
    elseif ownedByYou then
        box:addLine(g_i18n:getText("fieldInfo_owned"))
    else
        box:addLine(g_i18n:getText("fieldInfo_notOwned"))
    end
end
function PlayerHUDUpdater.fieldAddField(_, fieldInfo, box)
    local fruitTypeIndex = fieldInfo.fruitTypeIndex
    local isGrowing = false
    if fruitTypeIndex ~= FruitType.UNKNOWN then
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
        box:addLine(g_i18n:getText("statistic_fillType"), fruitTypeDesc.fillType.title)
        local text = nil
        if fruitTypeDesc:getIsCut(fieldInfo.growthState) then
            text = g_i18n:getText("ui_growthMapCut")
        elseif fruitTypeDesc:getIsWithered(growthState) then
            text = g_i18n:getText("ui_growthMapWithered")
        elseif fruitTypeDesc:getIsGrowing(growthState) then
            text = g_i18n:getText("ui_growthMapGrowing")
            isGrowing = true
        elseif fruitTypeDesc:getIsPreparable(growthState) then
            text = g_i18n:getText("ui_growthMapReadyToPrepareForHarvest")
            isGrowing = true
        elseif fruitTypeDesc:getIsHarvestable(growthState) then
            text = g_i18n:getText("ui_growthMapReadyToHarvest")
            isGrowing = true
        end
        if text ~= nil then
            box:addLine(g_i18n:getText("ui_mapOverviewGrowth"), text)
        end
    end
    local fruitTypeDesc = g_currentMission.fieldGroundSystem
    if isGrowing then
        local text = fieldInfo:getHarvestScaleMultiplier() - 1
        local sprayFactor = MathUtil.round(text * 100)
        box:addLine(g_i18n:getText("fieldInfo_yieldBonus"), string.format("+ %d %%", sprayFactor))
    end
    if fieldInfo.sprayLevel >= 0 then
        local text = fruitTypeDesc:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
        box:addLine(g_i18n:getText("ui_growthMapFertilized"), string.format("%d %%", fieldInfo.sprayLevel / text * 100))
    end
end
function PlayerHUDUpdater.fieldAddFieldActions(_, fieldInfo, box)
    local missionInfo = g_currentMission.missionInfo
    if Platform.gameplay.useLimeCounter and (missionInfo.limeRequired and fieldInfo.limeLevel == 0) then
        box:addLine(g_i18n:getText("ui_growthMapNeedsLime"), nil, true)
    end
    if fieldInfo.plowLevel == 0 and missionInfo.plowingRequiredEnabled then
        box:addLine(g_i18n:getText("ui_growthMapNeedsPlowing"), nil, true)
    end
    if Platform.gameplay.useRolling and fieldInfo.rollerLevel > 0 then
        box:addLine(g_i18n:getText("ui_growthMapNeedsRolling"), nil, true)
    end
end
function PlayerHUDUpdater.fieldAddWeed(_, fieldInfo, box)
    if g_currentMission.missionInfo.weedsEnabled then
        local weedSystem = g_currentMission.weedSystem
        local fieldInfoStates = weedSystem:getFieldInfoStates()
        local weedState = fieldInfo.weedState
        local toolName = nil
        if weedState ~= 0 then
            local fruitTypeDesc = nil
            if (fieldInfo.fruitTypeIndex or FruitType.UNKNOWN) ~= nil then
                fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
            end
            if Platform.gameplay.hasWeeder then
                if (fruitTypeDesc == nil or fruitTypeDesc:getIsWeedable(fieldInfo.growthState or 0)) and weedSystem:getWeederReplacements(false).weed.replacements[weedState] == 0 then
                    toolName = g_i18n:getText("weed_destruction_weeder")
                end
                if toolName == nil and (fruitTypeDesc == nil or fruitTypeDesc:getIsHoeable(growthState)) and weedSystem:getWeederReplacements(true).weed.replacements[weedState] == 0 then
                    toolName = g_i18n:getText("weed_destruction_hoe")
                end
            end
            if toolName == nil and (fruitTypeDesc == nil or fruitTypeDesc:getIsGrowing(growthState)) then
                toolName = g_i18n:getText("weed_destruction_herbicide")
            end
            local weederReplacements = fieldInfoStates[weedState]
            if weederReplacements ~= nil then
                box:addLine(weederReplacements, toolName or "", true)
            end
        end
    else
        return
    end
end