AbstractFieldMission = {}
source("dataS/scripts/missions/field/AbstractFieldMissionHotspot.lua")
local AbstractFieldMission_mt = Class(AbstractFieldMission, AbstractMission)
InitStaticObjectClass(AbstractFieldMission, "AbstractFieldMission")
AbstractFieldMission.FIELD_SIZE_MEDIUM = 1.5
AbstractFieldMission.FIELD_SIZE_LARGE = 4
AbstractFieldMission.SQM_PER_PARTITION = 2500
function AbstractFieldMission.registerSavegameXMLPaths(schema, key)
    AbstractFieldMission:superClass().registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. ".field#id", "Field id")
    schema:register(XMLValueType.STRING, key .. ".field.preparingTask#className")
    FieldUpdateTask.registerXMLPaths(schema, key .. ".field.preparingTask")
end
function AbstractFieldMission.new(isServer, isClient, title, description, customMt)
    -- upvalues: (copy) AbstractFieldMission_mt
    local self = AbstractMission.new(isServer, isClient, title, description, customMt or AbstractFieldMission_mt)
    self.workAreaTypes = {}
    self.moneyMultiplier = 1
    self.isInMissionMap = false
    self.fieldPercentageDone = 0
    self.completionModifier = nil
    self.completionFilter = nil
    self.isHotspotAdded = false
    self.mapHotspot = nil
    return self
end
function AbstractFieldMission:init(field)
    self:setField(field)
    return AbstractFieldMission:superClass().init(self)
end
function AbstractFieldMission:setField(field)
    self.field = field
    field:setMission(self)
    local fieldId = field:getId()
    if fieldId ~= nil then
        self.progressTitle = string.format("%s (%s %d)", self.title, g_i18n:getText("contract_details_field"), fieldId)
    end
    g_fieldManager:onFieldMissionStarted()
    self:createMapHotspot()
end
function AbstractFieldMission:createMapHotspot()
    if self.mapHotspot == nil then
        self.mapHotspot = AbstractFieldMissionHotspot.new()
    end
    self.mapHotspot:setField(self.field)
    self.mapHotspots = { self.mapHotspot }
end
function AbstractFieldMission:getField()
    return self.field
end
function AbstractFieldMission:getMapHotspots()
    return self.mapHotspots
end
function AbstractFieldMission:getWorldPosition()
    return self.field:getIndicatorPosition()
end
function AbstractFieldMission:getLocation()
    local name = self.field:getName()
    return string.format(g_i18n:getText("contract_farmland"), name)
end
function AbstractFieldMission:reactivate()
    self:createModifier()
    AbstractFieldMission:superClass().reactivate(self)
end
function AbstractFieldMission:delete()
    self:removeFromMissionMap()
    self:removeHotspot()
    if self.mapHotspot ~= nil then
        self.mapHotspot:delete()
        self.mapHotspot = nil
    end
    self.mapHotspots = nil
    if self.field ~= nil then
        self.field:setMission(nil)
        g_fieldManager:onFieldMissionDeleted()
    end
    AbstractFieldMission:superClass().delete(self)
end
function AbstractFieldMission:saveToXMLFile(xmlFile, key)
    AbstractFieldMission:superClass().saveToXMLFile(self, xmlFile, key)
    xmlFile:setValue(key .. ".field#id", self.field:getId())
    if self.status == MissionStatus.PREPARING and (self.fieldPreparingTask ~= nil and self.fieldPreparingTask:getIsFinished()) then
        local taskKey = key .. ".field.preparingTask"
        xmlFile:setValue(taskKey .. "#className", ClassUtil.getClassNameByObject(self.fieldPreparingTask))
        self.fieldPreparingTask:saveToXMLFile(xmlFile, taskKey)
    end
end
function AbstractFieldMission:loadFromXMLFile(xmlFile, key)
    local fieldId = xmlFile:getValue(key .. ".field#id")
    local field = g_fieldManager:getFieldById(fieldId)
    if field == nil then
        Logging.xmlWarning(xmlFile, "Mission \'%s\' field \'%s\' is not available.", key, fieldId)
        return false
    end
    self:setField(field)
    if not AbstractFieldMission:superClass().loadFromXMLFile(self, xmlFile, key) then
        return false
    end
    local fieldPreparingTaskKey = key .. ".field.preparingTask"
    if xmlFile:hasProperty(fieldPreparingTaskKey) then
        local className = xmlFile:getValue(fieldPreparingTaskKey .. "#className", "FieldUpdateTask")
        local class = ClassUtil.getClassObject(className)
        if class == nil then
            Logging.xmlWarning(xmlFile, "Class \'%s\' not defined for update task \'%s\'", className, fieldPreparingTaskKey)
        else
            local fieldPreparingTask = class.new()
            if fieldPreparingTask:loadFromXMLFile(xmlFile, fieldPreparingTaskKey) then
                fieldPreparingTask:setNeedsSaving(false)
                fieldPreparingTask:enqueue()
                self.fieldPreparingTask = fieldPreparingTask
            end
        end
    end
    if self.status == MissionStatus.PREPARING or self.status == MissionStatus.RUNNING then
        self:addToMissionMap()
    end
    return true
end
function AbstractFieldMission:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.field:getId())
    AbstractFieldMission:superClass().writeStream(self, streamId, connection)
end
function AbstractFieldMission:readStream(streamId, connection)
    local fieldId = streamReadInt32(streamId)
    self:setField((g_fieldManager:getFieldById(fieldId)))
    AbstractFieldMission:superClass().readStream(self, streamId, connection)
    if self.status == MissionStatus.PREPARING or self.status == MissionStatus.RUNNING then
        self:addToMissionMap()
    end
end
function AbstractFieldMission:update(dt)
    AbstractFieldMission:superClass().update(self, dt)
    if self.status == MissionStatus.RUNNING and (g_localPlayer ~= nil and (g_localPlayer.farmId == self.farmId and not self.isHotspotAdded)) then
        self:addHotspots()
    end
end
function AbstractFieldMission:start(spawnVehicles)
    if not AbstractFieldMission:superClass().start(self, spawnVehicles) then
        return false
    end
    self:addToMissionMap()
    return true
end
function AbstractFieldMission:prepare(spawnVehicles)
    AbstractFieldMission:superClass().prepare(self, spawnVehicles)
    self:prepareField()
    self:createModifier()
end
function AbstractFieldMission:prepareField()
    if self.isServer then
        self.fieldPreparingTask = self:getFieldPreparingTask()
        if self.fieldPreparingTask ~= nil then
            self.fieldPreparingTask:setNeedsSaving(false)
            g_fieldManager:addFieldUpdateTask(self.fieldPreparingTask)
        end
    end
end
function AbstractFieldMission:getFieldPreparingTask()
    local fieldState = self.field:getFieldState()
    if fieldState.isValid then
        local fieldPreparingTask = fieldState:createFieldUpdateTask()
        fieldPreparingTask:clearHeight()
        fieldPreparingTask:setField(self.field)
        return fieldPreparingTask
    end
end
function AbstractFieldMission:getIsPrepared()
    if AbstractFieldMission:superClass().getIsPrepared(self) then
        return self.fieldPreparingTask == nil and true or self.fieldPreparingTask:getIsFinished()
    else
        return false
    end
end
function AbstractFieldMission:finishField()
    if self.isServer then
        local task = self:getFieldFinishTask()
        if task ~= nil then
            task:setField(self.field)
            g_fieldManager:addFieldUpdateTask(task)
        end
    end
end
function AbstractFieldMission:getFieldFinishTask()
    local fieldState = self.field:getFieldState()
    if fieldState.isValid then
        return fieldState:createFieldUpdateTask()
    else
        return nil
    end
end
function AbstractFieldMission:started()
    self:addToMissionMap()
end
function AbstractFieldMission:finish(finishState)
    AbstractFieldMission:superClass().finish(self, finishState)
    self:removeHotspot()
    local mission = g_currentMission
    if mission:getFarmId() == self.farmId then
        if finishState == MissionFinishState.SUCCESS then
            mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("contract_field_finished"), self.field:getId()))
            return
        end
        if finishState == MissionFinishState.FAILED then
            mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_field_failed"), self.field:getId()))
            return
        end
        if finishState == MissionFinishState.TIMED_OUT then
            mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_field_timedOut"), self.field:getId()))
        end
    end
end
function AbstractFieldMission:dismiss()
    self:finishField()
    AbstractFieldMission:superClass().dismiss(self)
end
function AbstractFieldMission:removeAccess()
    self:removeFromMissionMap()
    AbstractFieldMission:superClass().removeAccess(self)
end
function AbstractFieldMission:validate()
    if AbstractFieldMission:superClass().validate(self) then
        if self.field == nil then
            return false
        else
            return not self.field:getHasOwner()
        end
    else
        return false
    end
end
function AbstractFieldMission:createModifier() end
function AbstractFieldMission:initializeModifier()
    if self.completionModifier == nil then
        ::l2::
    else
        self.field:getDensityMapPolygon():applyToModifier(self.completionModifier)
        self.completionPartitions = {}
        local minZ, maxZ = self.completionModifier:getPolygonMinMaxZ()
        if minZ == nil then
            table.insert(self.completionPartitions, {
                ["wasCalculated"] = false,
                ["percentageDone"] = 0,
                ["sumPixels"] = 0,
                ["area"] = 0,
                ["totalArea"] = 0
            })
            goto l2
        end
        local currentMaxZ = MathUtil.haToSqm(self.field:getAreaHa()) / AbstractFieldMission.SQM_PER_PARTITION
        local currentMinZ = math.ceil(currentMaxZ)
        local currentMinZ = nil
        local currentMaxZ = nil
        for i = 1, currentMinZ do
            if currentMinZ == nil then
                currentMaxZ = minZ
            end
            local partition = math.ceil(currentMaxZ + (maxZ - minZ) / currentMinZ)
            local partition = {
                ["wasCalculated"] = false,
                ["percentageDone"] = 0,
                ["sumPixels"] = 0,
                ["area"] = 0,
                ["totalArea"] = 0,
                ["minZ"] = currentMaxZ,
                ["maxZ"] = math.min(partition, maxZ)
            }
            table.insert(self.completionPartitions, partition)
            if currentMaxZ == nil or maxZ <= partition then
                goto l2
            end
            currentMaxZ = partition
        end
    end
end
function AbstractFieldMission:setPartitionRegion(partitionIndex)
    if self.completionPartitions ~= nil and #self.completionPartitions ~= 1 then
        if self.completionModifier ~= nil then
            local partition = self.completionPartitions[partitionIndex]
            self.completionModifier:setPolygonClipRegion(partition.minZ, partition.maxZ)
        end
    end
end
function AbstractFieldMission:getPartitionCompletion(partitionIndex)
    self:setPartitionRegion(partitionIndex)
    if self.completionModifier == nil then
        return 0, 0, 0
    end
    local sumPixels, area, totalArea = self.completionModifier:executeGet(self.completionFilter)
    return sumPixels, area, totalArea
end
function AbstractFieldMission:getCompletion()
    return self:getFieldCompletion() / AbstractMission.SUCCESS_FACTOR
end
function AbstractFieldMission:getFieldCompletion()
    if not self.isFieldCompletionInitialized then
        self:initializeModifier()
        self.isFieldCompletionInitialized = true
    end
    if self.currentPartitionCompletionIndex == nil then
        self.currentPartitionCompletionIndex = 1
    end
    local sumPixels, area, totalArea = self:getPartitionCompletion(self.currentPartitionCompletionIndex)
    if area ~= nil then
        local partition = self.completionPartitions[self.currentPartitionCompletionIndex]
        partition.wasCalculated = true
        partition.sumPixels = sumPixels
        partition.area = area
        partition.totalArea = totalArea
    end
    self:updateFieldPercentageDone(totalArea)
    self.currentPartitionCompletionIndex = self.currentPartitionCompletionIndex + 1
    if self.currentPartitionCompletionIndex > #self.completionPartitions then
        self.currentPartitionCompletionIndex = 1
    end
    return self.fieldPercentageDone
end
function AbstractFieldMission:updateFieldPercentageDone(totalArea)
    local areaDone = 0
    local areaTotal = 0
    local allCalculated = true
    for _, partition in ipairs(self.completionPartitions) do
        if not partition.wasCalculated then
            allCalculated = false
        end
        if totalArea > 0 then
        end
    end
    if allCalculated then
        if areaTotal == 0 then
            self:finish(MissionFinishState.FAILED)
            return
        end
        self.fieldPercentageDone = areaDone / areaTotal
    end
end
function AbstractFieldMission:getVehicleSize()
    local areaHa = self.field:getAreaHa()
    return AbstractFieldMission.FIELD_SIZE_LARGE < areaHa and "large" or (AbstractFieldMission.FIELD_SIZE_MEDIUM < areaHa and "medium" or "small")
end
function AbstractFieldMission:getDetails()
    local details = AbstractFieldMission:superClass().getDetails(self)
    table.insert(details, {
        ["title"] = g_i18n:getText("contract_details_field"),
        ["value"] = self.field:getName()
    })
    table.insert(details, {
        ["title"] = g_i18n:getText("contract_details_fieldSize"),
        ["value"] = g_i18n:formatArea(self.field:getAreaHa(), 2)
    })
    return details
end
function AbstractFieldMission:getRewardPerHa()
    return 1
end
function AbstractFieldMission:getReward()
    local area = self.field:getAreaHa()
    return AbstractFieldMission:superClass().getReward(self) + self:getRewardPerHa() * area * (1.3 - 0.1 * g_currentMission.missionInfo.economicDifficulty)
end
function AbstractFieldMission:getFarmlandId()
    local field = self.field
    if field == nil then
        return nil
    else
        return field:getId()
    end
end
function AbstractFieldMission:addToMissionMap()
    if not self.isInMissionMap then
        self:updateMissionMap(self.activeMissionId)
        self.isInMissionMap = true
    end
end
function AbstractFieldMission:removeFromMissionMap()
    if self.isInMissionMap then
        self:updateMissionMap(0)
        self.isInMissionMap = false
    end
end
function AbstractFieldMission:updateMissionMap(missionId)
    local polygon = self.field:getDensityMapPolygon()
    g_missionManager:setMissionMapActiveMissionId(polygon, missionId)
end
function AbstractFieldMission:getNPC()
    return self.field.farmland:getNPC()
end
function AbstractFieldMission:getIsWorkAllowed(_, _, _, workAreaType, _)
    return self:getIsRunning() and (workAreaType == nil or self.workAreaTypes[workAreaType])
end
function AbstractFieldMission:addHotspots()
    if self.mapHotspot ~= nil then
        self.isHotspotAdded = true
        g_currentMission:addMapHotspot(self.mapHotspot)
    end
end
function AbstractFieldMission:removeHotspot()
    if self.mapHotspot ~= nil then
        g_currentMission:removeMapHotspot(self.mapHotspot)
        self.isHotspotAdded = false
    end
end