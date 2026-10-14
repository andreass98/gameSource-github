PlaceableAnimatedObjects = {}
function PlaceableAnimatedObjects.prerequisitesPresent(specializations)
    return true
end
function PlaceableAnimatedObjects.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "getCanTriggerAnimatedObject", PlaceableAnimatedObjects.getCanTriggerAnimatedObject)
    SpecializationUtil.registerFunction(placeableType, "getAnimatedObjectBySaveId", PlaceableAnimatedObjects.getAnimatedObjectBySaveId)
end
function PlaceableAnimatedObjects.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableAnimatedObjects.setOwnerFarmId)
end
function PlaceableAnimatedObjects.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableAnimatedObjects)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableAnimatedObjects)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableAnimatedObjects)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableAnimatedObjects)
    SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableAnimatedObjects)
end
function PlaceableAnimatedObjects.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("AnimatedObjects")
    AnimatedObject.registerXMLPaths(schema, basePath .. ".animatedObjects")
    schema:register(XMLValueType.INT, basePath .. ".animatedObjects.animatedObject(?).dependency(?)#animatedObjectIndex", "Animated object index")
    schema:register(XMLValueType.FLOAT, basePath .. ".animatedObjects.animatedObject(?).dependency(?)#minTime", "Min Time")
    schema:register(XMLValueType.FLOAT, basePath .. ".animatedObjects.animatedObject(?).dependency(?)#maxTime", "Max Time")
    schema:setXMLSpecializationType()
end
function PlaceableAnimatedObjects.registerSavegameXMLPaths(schema, basePath)
    AnimatedObject.registerSavegameXMLPaths(schema, basePath .. ".animatedObject(?)")
end
function PlaceableAnimatedObjects:onLoad(_)
    local spec = self.spec_animatedObjects
    local xmlFile = self.xmlFile
    spec.animatedObjects = {}
    for index, animationKey in xmlFile:iterator("placeable.animatedObjects.animatedObject") do
        local animatedObject = AnimatedObject.new(self.isServer, self.isClient)
        animatedObject.dependencies = {}
        for _, dependencyKey in xmlFile:iterator(animationKey .. ".dependency") do
            local dependendIndex = xmlFile:getInt(dependencyKey .. "#animatedObjectIndex")
            if dependendIndex == nil then
                Logging.xmlError(xmlFile, "Missing animatedObjectIndex for \'%s\'", dependencyKey)
            else
                local dependency = {
                    ["objectIndex"] = dependendIndex,
                    ["minTime"] = xmlFile:getValue(dependencyKey .. "#minTime", 0),
                    ["maxTime"] = xmlFile:getValue(dependencyKey .. "#maxTime", 0)
                }
                table.insert(animatedObject.dependencies, dependency)
            end
        end
        if animatedObject:load(self.components, xmlFile, animationKey, self.configFileName, self.i3dMappings) then
            table.insert(spec.animatedObjects, animatedObject)
        else
            Logging.xmlError(xmlFile, "Failed to load animated object %i", index)
        end
    end
    for index, animationKey in ipairs(spec.animatedObjects) do
        local animationKey
        animationKey.getCanBeTriggered = Utils.overwrittenFunction(animationKey.getCanBeTriggered, function(_, superFunc)
            -- upvalues: (copy) animationKey, (copy) self, (copy) spec, (copy) xmlFile
            if not superFunc(animationKey) then
                return false
            end
            if not self:getCanTriggerAnimatedObject(animationKey) then
                return false
            end
            if #animationKey.dependencies > 0 then
                for _, dependency in ipairs(animationKey.dependencies) do
                    local dependendObject = spec.animatedObjects[dependency.objectIndex]
                    if dependendObject == nil then
                        Logging.xmlWarning(xmlFile, "Invalid dependency animated object index \'%d\'", dependency.objectIndex)
                    else
                        local t = dependendObject.animation.time
                        if t < dependency.minTime or dependency.maxTime < t then
                            return false
                        end
                    end
                end
            end
            return true
        end)
    end
end
function PlaceableAnimatedObjects:onDelete()
    local spec = self.spec_animatedObjects
    if spec.animatedObjects ~= nil then
        for _, animatedObject in ipairs(spec.animatedObjects) do
            animatedObject:delete()
        end
        spec.animatedObjects = nil
    end
end
function PlaceableAnimatedObjects:onPostFinalizePlacement()
    for _, animatedObject in ipairs(self.spec_animatedObjects.animatedObjects) do
        animatedObject:register(true)
        animatedObject:setOwnerFarmId(self.ownerFarmId, true)
    end
end
function PlaceableAnimatedObjects:onReadStream(streamId, connection)
    if connection:getIsServer() then
        for _, animatedObject in ipairs(self.spec_animatedObjects.animatedObjects) do
            local animatedObjectId = NetworkUtil.readNodeObjectId(streamId)
            animatedObject:readStream(streamId, connection)
            g_client:finishRegisterObject(animatedObject, animatedObjectId)
        end
    end
end
function PlaceableAnimatedObjects:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        for _, animatedObject in ipairs(self.spec_animatedObjects.animatedObjects) do
            NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(animatedObject))
            animatedObject:writeStream(streamId, connection)
            g_server:registerObjectInStream(connection, animatedObject)
        end
    end
end
function PlaceableAnimatedObjects:loadFromXMLFile(xmlFile, key)
    for i, animatedObject in ipairs(self.spec_animatedObjects.animatedObjects) do
        animatedObject:loadFromXMLFile(xmlFile, string.format("%s.animatedObject(%d)", key, i - 1))
    end
end
function PlaceableAnimatedObjects:saveToXMLFile(xmlFile, key, usedModNames)
    for i, animatedObject in ipairs(self.spec_animatedObjects.animatedObjects) do
        animatedObject:saveToXMLFile(xmlFile, string.format("%s.animatedObject(%d)", key, i - 1), usedModNames)
    end
end
function PlaceableAnimatedObjects:getCanTriggerAnimatedObject(_)
    local ownerFarmId = self:getOwnerFarmId()
    return g_currentMission.accessHandler:canFarmAccessOtherId(g_currentMission:getFarmId(), ownerFarmId) and true or false
end
function PlaceableAnimatedObjects:getAnimatedObjectBySaveId(saveId)
    for i, animatedObject in ipairs(self.spec_animatedObjects.animatedObjects) do
        if animatedObject.saveId == saveId then
            return animatedObject
        end
    end
    return nil
end
function PlaceableAnimatedObjects:setOwnerFarmId(superFunc, ownerFarmId, noEventSend)
    superFunc(self, ownerFarmId, noEventSend)
    local spec = self.spec_animatedObjects
    if spec.animatedObjects ~= nil then
        for _, animatedObject in ipairs(spec.animatedObjects) do
            animatedObject:setOwnerFarmId(ownerFarmId, true)
        end
    end
end