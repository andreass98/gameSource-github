PlaceableFarmhouse = {}
source("dataS/scripts/placeables/specializations/activatables/FarmhouseActivatable.lua")
function PlaceableFarmhouse.prerequisitesPresent(specializations)
    return true
end
function PlaceableFarmhouse.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "farmhouseSleepingTriggerCallback", PlaceableFarmhouse.farmhouseSleepingTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "getSleepCamera", PlaceableFarmhouse.getSleepCamera)
    SpecializationUtil.registerFunction(placeableType, "getSpawnWorldPosition", PlaceableFarmhouse.getSpawnWorldPosition)
    SpecializationUtil.registerFunction(placeableType, "getSpawnPoint", PlaceableFarmhouse.getSpawnPoint)
    SpecializationUtil.registerFunction(placeableType, "getIsAllowedToSleep", PlaceableFarmhouse.getIsAllowedToSleep)
end
function PlaceableFarmhouse.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "finalizeConstruction", PlaceableFarmhouse.finalizeConstruction)
end
function PlaceableFarmhouse.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableFarmhouse)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableFarmhouse)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableFarmhouse)
end
function PlaceableFarmhouse.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Farmhouse")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".farmhouse#spawnNode", "Player spawn node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".farmhouse.sleeping#triggerNode", "Sleeping trigger")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".farmhouse.sleeping#cameraNode", "Camera while sleeping")
    schema:register(XMLValueType.BOOL, basePath .. ".farmhouse.sleeping#isFreeForAll", "Marks if everybody can sleep there")
    schema:register(XMLValueType.BOOL, basePath .. ".farmhouse#isFinalized", "If the farmhouse is finalized and ready on start. E.g. constructible")
    schema:setXMLSpecializationType()
end
function PlaceableFarmhouse.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Farmhouse")
    schema:register(XMLValueType.BOOL, basePath .. "#isFreeForAll", "Marks if everybody can sleep there")
    schema:setXMLSpecializationType()
end
function PlaceableFarmhouse:onLoad(_)
    local spec = self.spec_farmhouse
    spec.activatable = FarmhouseActivatable.new(self)
    spec.spawnNode = self.xmlFile:getValue("placeable.farmhouse#spawnNode", nil, self.components, self.i3dMappings)
    if spec.spawnNode == nil then
        Logging.xmlError(self.xmlFile, "No spawn node defined for farmhouse")
        spec.spawnNode = self.rootNode
    end
    spec.sleepingTrigger = self.xmlFile:getValue("placeable.farmhouse.sleeping#triggerNode", nil, self.components, self.i3dMappings)
    if spec.sleepingTrigger ~= nil then
        if not CollisionFlag.getHasMaskFlagSet(spec.sleepingTrigger, CollisionFlag.PLAYER) then
            Logging.warning("%s sleep trigger \'%s\' does not have \'TRIGGER_PLAYER\' bit (%s) set", self.configFileName, "placeable.farmhouse.sleeping#triggerNode", CollisionFlag.getBit(CollisionFlag.PLAYER))
        end
        addTrigger(spec.sleepingTrigger, "farmhouseSleepingTriggerCallback", self)
    end
    local camera = self.xmlFile:getValue("placeable.farmhouse.sleeping#cameraNode", nil, self.components, self.i3dMappings)
    if camera then
        if getHasClassId(camera, ClassIds.CAMERA) then
            spec.sleepingCamera = camera
            g_cameraManager:addCamera(camera, nil, false)
        else
            Logging.xmlError(self.xmlFile, "Sleeping camera node \'%s\' (%s) is not a camera!", getName(camera), "placeable.farmhouse.sleeping#cameraNode")
        end
    end
    spec.isFreeForAll = self.xmlFile:getValue("placeable.farmhouse.sleeping#isFreeForAll", false)
    spec.isFinalized = self.xmlFile:getBool("placeable.farmhouse#isFinalized", true)
end
function PlaceableFarmhouse:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_farmhouse
    spec.isFreeForAll = xmlFile:getValue(key .. "#isFreeForAll") or spec.isFreeForAll
end
function PlaceableFarmhouse:saveToXMLFile(xmlFile, key, _)
    xmlFile:setValue(key .. "#isFreeForAll", self.spec_farmhouse.isFreeForAll)
end
function PlaceableFarmhouse:onFinalizePlacement()
    if self.spec_farmhouse.isFinalized then
        g_currentMission.placeableSystem:addFarmhouse(self)
    end
end
function PlaceableFarmhouse:finalizeConstruction(superFunc)
    superFunc(self)
    self.spec_farmhouse.isFinalized = true
    if self.propertyState ~= PlaceablePropertyState.CONSTRUCTION_PREVIEW then
        g_currentMission.placeableSystem:addFarmhouse(self)
    end
end
function PlaceableFarmhouse:onDelete()
    local spec = self.spec_farmhouse
    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    g_currentMission.placeableSystem:removeFarmhouse(self)
    if spec.sleepingTrigger ~= nil then
        removeTrigger(spec.sleepingTrigger)
    end
    if spec.sleepingCamera ~= nil then
        g_cameraManager:removeCamera(spec.sleepingCamera)
    end
end
function PlaceableFarmhouse:getSpawnPoint()
    local spec = self.spec_farmhouse
    if spec.isFinalized then
        return spec.spawnNode
    else
        return nil
    end
end
function PlaceableFarmhouse:getSpawnWorldPosition()
    local spec = self.spec_farmhouse
    if spec.isFinalized then
        return getWorldTranslation(spec.spawnNode)
    else
        return nil
    end
end
function PlaceableFarmhouse:getSleepCamera()
    return self.spec_farmhouse.sleepingCamera
end
function PlaceableFarmhouse:getIsAllowedToSleep(playerFarmId)
    if g_guidedTourManager:getIsTourRunning() then
        return false
    else
        return playerFarmId == self:getOwnerFarmId() and true or (self.spec_farmhouse.isFreeForAll and true or false)
    end
end
function PlaceableFarmhouse:farmhouseSleepingTriggerCallback(_, otherActorId, onEnter, onLeave, _, _)
    if (onEnter or onLeave) and (g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode) then
        local spec = self.spec_farmhouse
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
            return
        end
        g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    end
end