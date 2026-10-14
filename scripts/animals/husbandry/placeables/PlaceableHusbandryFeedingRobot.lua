PlaceableHusbandryFeedingRobot = {}
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobot.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotState.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateLoading.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStatePaused.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateFilling.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateStarting.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateDriving.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateFinished.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateReset.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateWait.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateEvent.lua")
function PlaceableHusbandryFeedingRobot.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableHusbandryFood, specializations)
end
function PlaceableHusbandryFeedingRobot.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onFeedingRobotLoaded", PlaceableHusbandryFeedingRobot.onFeedingRobotLoaded)
end
function PlaceableHusbandryFeedingRobot.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableHusbandryFeedingRobot.setOwnerFarmId)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateFeeding", PlaceableHusbandryFeedingRobot.updateFeeding)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableHusbandryFeedingRobot.collectPickObjects)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryFeedingRobot.updateInfo)
end
function PlaceableHusbandryFeedingRobot.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryFeedingRobot)
    SpecializationUtil.registerEventListener(placeableType, "onPostLoad", PlaceableHusbandryFeedingRobot)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryFeedingRobot)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryFeedingRobot)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryFeedingRobot)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryFeedingRobot)
end
function PlaceableHusbandryFeedingRobot.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    basePath = basePath .. ".husbandry.feedingRobot"
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#linkNode", "Feedingrobot link node")
    schema:register(XMLValueType.STRING, basePath .. "#class", "Feedingrobot class name")
    schema:register(XMLValueType.STRING, basePath .. "#filename", "Feedingrobot config file")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".splines.spline(?)#node", "Feedingrobot spline")
    schema:register(XMLValueType.INT, basePath .. ".splines.spline(?)#direction", "Feedingrobot spline direction")
    schema:register(XMLValueType.BOOL, basePath .. ".splines.spline(?)#isFeeding", "Feedingrobot spline feeding part")
    schema:register(XMLValueType.FLOAT, basePath .. ".splines.spline(?)#fakeLength", "Fake length of spline for simulating a waiting point")
    schema:register(XMLValueType.BOOL, basePath .. ".splines.spline(?)#stopAtEnd", "If robot should stop at the end of the spline and switch to next state")
    schema:register(XMLValueType.INT, basePath .. ".animatedObjects.animatedObject(?)#index", "Dependent animated object index")
    schema:register(XMLValueType.INT, basePath .. ".animatedObjects.animatedObject(?)#direction", "Dependent animated object direction")
    schema:setXMLSpecializationType()
end
function PlaceableHusbandryFeedingRobot.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    FeedingRobot.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType()
end
function PlaceableHusbandryFeedingRobot:onLoad(_)
    local spec = self.spec_husbandryFeedingRobot
    if not self.xmlFile:hasProperty("placeable.husbandry.feedingRobot") then
        return
    end
    local filename = self.xmlFile:getValue("placeable.husbandry.feedingRobot#filename")
    if filename == nil then
        Logging.xmlError(self.xmlFile, "Feedingrobot filename missing")
        self:setLoadingState(PlaceableLoadingState.ERROR)
        return
    end
    local className = Utils.getFilename(filename, self.baseDirectory)
    local className = self.xmlFile:getValue("placeable.husbandry.feedingRobot#class", "")
    local class = ClassUtil.getClassObject(className)
    if class == nil then
        Logging.xmlError(self.xmlFile, "Feedingrobot class \'%s\' not defined", className)
        self:setLoadingState(PlaceableLoadingState.ERROR)
        return
    end
    local linkNode = self.xmlFile:getValue("placeable.husbandry.feedingRobot#linkNode", nil, self.components, self.i3dMappings)
    if linkNode == nil then
        Logging.xmlError(self.xmlFile, "Feedingrobot linkNode not defined")
        self:setLoadingState(PlaceableLoadingState.ERROR)
        return
    end
    local loadingTask = self:createLoadingTask(self)
    spec.feedingRobot = class.new(self.isServer, self.isClient, self, self.baseDirectory)
    spec.feedingRobot:load(linkNode, className, self.onFeedingRobotLoaded, self, {
        ["loadingTask"] = loadingTask
    })
    spec.feedingRobot:register(true)
    for _, splineKey in self.xmlFile:iterator("placeable.husbandry.feedingRobot.splines.spline") do
        local fakeLength = self.xmlFile:getFloat(splineKey .. "#fakeLength", nil)
        local stopAtEnd = self.xmlFile:getBool(splineKey .. "#stopAtEnd", false)
        if fakeLength == nil then
            local spline = self.xmlFile:getValue(splineKey .. "#node", nil, self.components, self.i3dMappings)
            if spline == nil then
                Logging.xmlWarning(self.xmlFile, "Feedingrobot spline not defined for \'%s\'", splineKey)
                break
            end
            if not getHasClassId(getGeometry(spline), ClassIds.SPLINE) then
                Logging.xmlWarning(self.xmlFile, "Given node is not a spline for \'%s\'", splineKey)
                break
            end
            local direction = self.xmlFile:getValue(splineKey .. "#direction", 1)
            local isFeeding = self.xmlFile:getValue(splineKey .. "#isFeeding", false)
            spec.feedingRobot:addSpline(spline, direction, isFeeding, stopAtEnd)
        else
            spec.feedingRobot:addSplineWaitingPoint(fakeLength)
        end
    end
    spec.feedingRobot:finishSplines()
    spec.dependedAnimatedObjects = {}
    self.xmlFile:iterate("placeable.husbandry.feedingRobot.animatedObjects.animatedObject", function(_, animationObjectKey)
        -- upvalues: (copy) self, (copy) spec
        local animatedObjectIndex = self.xmlFile:getInt(animationObjectKey .. "#index")
        local direction = self.xmlFile:getInt(animationObjectKey .. "#direction", 1)
        table.insert(spec.dependedAnimatedObjects, {
            ["animatedObjectIndex"] = animatedObjectIndex,
            ["direction"] = direction
        })
    end)
end
function PlaceableHusbandryFeedingRobot:onPostLoad(_)
    local spec = self.spec_husbandryFeedingRobot
    if spec.dependedAnimatedObjects ~= nil and self.spec_animatedObjects ~= nil then
        for _, data in ipairs(spec.dependedAnimatedObjects) do
            local animatedObject = self.spec_animatedObjects.animatedObjects[data.animatedObjectIndex]
            if animatedObject ~= nil then
                animatedObject.getCanBeTriggered = Utils.overwrittenFunction(animatedObject.getCanBeTriggered, function(_, superFunc)
                    -- upvalues: (copy) animatedObject, (copy) spec
                    if superFunc(animatedObject) then
                        return not spec.feedingRobot:getIsDriving()
                    else
                        return false
                    end
                end)
                local data
                spec.feedingRobot:addStateChangedListener(function(state)
                    -- upvalues: (copy) spec, (copy) animatedObject, (copy) data
                    if spec.feedingRobot:getIsDriving() and animatedObject.animation.direction ~= data.direction then
                        animatedObject:setDirection(data.direction)
                    end
                end)
            end
        end
    end
end
function PlaceableHusbandryFeedingRobot:onFeedingRobotLoaded(_, args)
    self:finishLoadingTask(args.loadingTask)
end
function PlaceableHusbandryFeedingRobot:onDelete()
    local spec = self.spec_husbandryFeedingRobot
    if spec.feedingRobot ~= nil then
        spec.feedingRobot:delete()
        spec.feedingRobot = nil
    end
end
function PlaceableHusbandryFeedingRobot:onFinalizePlacement()
    local spec = self.spec_husbandryFeedingRobot
    if spec.feedingRobot ~= nil then
        spec.feedingRobot:finalizePlacement()
    end
end
function PlaceableHusbandryFeedingRobot:onReadStream(streamId, connection)
    local spec = self.spec_husbandryFeedingRobot
    if spec.feedingRobot ~= nil then
        local feedingRobotId = NetworkUtil.readNodeObjectId(streamId)
        spec.feedingRobot:readStream(streamId, connection)
        g_client:finishRegisterObject(spec.feedingRobot, feedingRobotId)
    end
end
function PlaceableHusbandryFeedingRobot:onWriteStream(streamId, connection)
    local spec = self.spec_husbandryFeedingRobot
    if spec.feedingRobot ~= nil then
        NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.feedingRobot))
        spec.feedingRobot:writeStream(streamId, connection)
        g_server:registerObjectInStream(connection, spec.feedingRobot)
    end
end
function PlaceableHusbandryFeedingRobot:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_husbandryFeedingRobot
    if spec.feedingRobot ~= nil then
        spec.feedingRobot:loadFromXMLFile(xmlFile, key)
    end
end
function PlaceableHusbandryFeedingRobot:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_husbandryFeedingRobot
    if spec.feedingRobot ~= nil then
        spec.feedingRobot:saveToXMLFile(xmlFile, key, usedModNames)
    end
end
function PlaceableHusbandryFeedingRobot:setOwnerFarmId(superFunc, farmId)
    superFunc(self, farmId)
    local spec = self.spec_husbandryFeedingRobot
    if spec.feedingRobot ~= nil then
        spec.feedingRobot:setOwnerFarmId(farmId, true)
    end
end
function PlaceableHusbandryFeedingRobot:updateFeeding(superFunc)
    local spec = self.spec_husbandryFeedingRobot
    if self.isServer and spec.feedingRobot ~= nil then
        local litersPerHour = self:getFoodLitersPerHour() * g_currentMission.environment.timeAdjustment
        spec.feedingRobot:createFoodMixture(litersPerHour * 1.5)
    end
    return superFunc(self)
end
function PlaceableHusbandryFeedingRobot:collectPickObjects(superFunc, node)
    local spec = self.spec_husbandryFeedingRobot
    if spec.feedingRobot == nil or not spec.feedingRobot:getIsNodeUsed(node) then
        superFunc(self, node)
    end
end
function PlaceableHusbandryFeedingRobot:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)
    local spec = self.spec_husbandryFeedingRobot
    if spec.feedingRobot ~= nil then
        spec.feedingRobot:updateInfo(infoTable)
    end
end