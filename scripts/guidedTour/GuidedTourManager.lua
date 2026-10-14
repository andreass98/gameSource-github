GuidedTourManager = {}
local GuidedTourManager_mt = Class(GuidedTourManager, AbstractManager)
g_xmlManager:addCreateSchemaFunction(function()
    GuidedTourManager.xmlSchema = XMLSchema.new("savegame_guidedTour")
end)
g_xmlManager:addInitSchemaFunction(function()
    local schema = Mission00.xmlSchema
    schema:register(XMLValueType.STRING, "map.guidedTours.guidedTour(?)#name", "Name identifier of the guided tour", nil, true)
    schema:register(XMLValueType.STRING, "map.guidedTours.guidedTour(?)#filename", "Path to guided tour config file", nil, true)
    local savegameSchema = GuidedTourManager.xmlSchema
    savegameSchema:register(XMLValueType.STRING, "guidedTour.tour#name", "Name identifier of the guided tour", nil, true)
    GuidedTour.registerSavegameXMLPaths(savegameSchema, "guidedTour.tour")
end)
function GuidedTourManager.new(customMt)
    -- upvalues: (copy) GuidedTourManager_mt
    return AbstractManager.new(customMt or GuidedTourManager_mt)
end
function GuidedTourManager:initDataStructures()
    self.guidedTours = {}
    self.nameToGuidedTour = {}
    self.nameToVehicle = {}
    self.nameToPlaceable = {}
    self.goalClasses = {}
    self.actionClasses = {}
    self.progressClasses = {}
end
function GuidedTourManager:unloadMapData()
    g_messageCenter:unsubscribeAll(self)
    GuidedTourManager:superClass().unloadMapData(self)
end
function GuidedTourManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    GuidedTourManager:superClass().loadMapData(self)
    local success = XMLUtil.loadDataFromMapXML(xmlFile, "guidedTours", baseDirectory, self, self.loadGuidedTours, missionInfo, baseDirectory)
    if success then
        GuidedTourHelp.init()
    end
    return success
end
function GuidedTourManager:loadGuidedTours(xmlFileHandle, _, baseDirectory, _)
    local xmlFile = XMLFile.wrap(xmlFileHandle, Mission00.xmlSchema)
    for _, key in xmlFile:iterator("map.guidedTours.guidedTour") do
        local xmlFilename = xmlFile:getValue(key .. "#filename")
        if xmlFilename == nil then
            Logging.xmlWarning(xmlFile, "Missing filename for guidedTour \'%s\'", key)
        else
            local name = xmlFile:getValue(key .. "#name")
            if name == nil then
                Logging.xmlWarning(xmlFile, "Missing name for guidedTour \'%s\'", key)
            else
                local upperName = Utils.getFilename(xmlFilename, baseDirectory)
                local upperName = string.upper(name)
                if self.nameToGuidedTour[upperName] == nil then
                    local guidedTour = GuidedTourUtil.createFromXML(upperName)
                    if guidedTour ~= nil then
                        table.insert(self.guidedTours, guidedTour)
                        self.nameToGuidedTour[upperName] = guidedTour
                        guidedTour.name = upperName
                        guidedTour.index = #self.guidedTours
                    end
                else
                    Logging.xmlWarning(xmlFile, "GuidedTour with name \'%s\' already exists for \'%s\'!", name, key)
                end
            end
        end
    end
    g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, GuidedTourManager.onMissionStarted, self)
    xmlFile:delete()
    return true
end
function GuidedTourManager:saveToXMLFile(xmlFilename)
    local xmlFile = XMLFile.create("guidedTourXML", xmlFilename, "guidedTour", GuidedTourManager.xmlSchema)
    if xmlFile == nil then
        Logging.error("Failed to create guidedTour xml file")
        return false
    end
    local tour = self.activeTour
    if tour ~= nil then
        xmlFile:setValue("guidedTour.tour#name", tour.name)
        tour:saveToXMLFile(xmlFile, "guidedTour.tour")
    end
    xmlFile:save()
    xmlFile:delete()
    return true
end
function GuidedTourManager:loadFromXMLFile(xmlFilename)
    if xmlFilename == nil then
        return false
    end
    local xmlFile = XMLFile.load("guidedTourXML", xmlFilename, GuidedTourManager.xmlSchema)
    if xmlFile == nil then
        return false
    end
    local tourName = xmlFile:getValue("guidedTour.tour#name")
    local tour = self.nameToGuidedTour[tourName]
    if tour ~= nil then
        if tour:loadFromXMLFile(xmlFile, "guidedTour.tour") then
            self.pendingStartTour = tour
        else
            Logging.xmlWarning(xmlFile, "Could not load guided tour from savegame!")
        end
    end
    xmlFile:delete()
    return true
end
function GuidedTourManager:onMissionStarted(isNewSavegame)
    if g_server ~= nil then
        local tour = self.pendingStartTour
        if isNewSavegame and g_currentMission:getIsTourSupported() then
            tour = self:getTourByName("INTRO")
            if tour == nil then
                g_currentMission.hud:showInGameMessage(nil, g_i18n:getText("guidedTour_intro_notAvailable"), 0)
                return
            end
        end
        if g_currentMission.missionDynamicInfo.isMultiplayer then
            if self.pendingStartTour ~= nil then
                self:abortTour(self.pendingStartTour)
                self.pendingStartTour:delete()
            end
        elseif tour ~= nil then
            self:startTour(tour)
            return
        end
    end
end
function GuidedTourManager:update(dt)
    if self.pendingTour ~= nil then
        self:startPendingTour()
    end
    if self.activeTour ~= nil then
        self.activeTour:update(dt)
    end
end
function GuidedTourManager:draw()
    if self.activeTour ~= nil then
        self.activeTour:draw()
    end
end
function GuidedTourManager:startPendingTour()
    local tour = self.pendingTour
    self.pendingTour = nil
    self.activeTour = tour
    tour:start(function(success)
        -- upvalues: (copy) self
        if success then
            self:onTourFinished()
        else
            self:onTourCanceled()
        end
    end)
end
function GuidedTourManager:startTour(tour)
    self.pendingTour = tour
end
function GuidedTourManager:abortTour(tour)
    tour = tour or self.activeTour
    if tour ~= nil then
        tour:cancel()
        g_currentMission.hud:showInGameMessage(nil, g_i18n:getText("guidedTour_aborted"), 0, nil, nil, nil)
    end
end
function GuidedTourManager:onTourFinished()
    self.activeTour = nil
    g_currentMission.hud:showInGameMessage(nil, g_i18n:getText("guidedTour_finished"), 0, nil, nil, nil)
end
function GuidedTourManager:onTourCanceled()
    self.activeTour = nil
end
function GuidedTourManager:getTourByName(name)
    if name == nil then
        return nil
    end
    name = string.upper(name)
    return self.nameToGuidedTour[name]
end
function GuidedTourManager:getIsTourRunning()
    return self.activeTour ~= nil
end
function GuidedTourManager:getActiveTour()
    return self.activeTour
end
function GuidedTourManager:getVehicleByName(name)
    return self.nameToVehicle[name]
end
function GuidedTourManager:addVehicle(vehicle, name)
    self.nameToVehicle[name] = vehicle
end
function GuidedTourManager:removeVehicle(name)
    if name ~= nil then
        self.nameToVehicle[name] = nil
    end
end
function GuidedTourManager:getPlaceableByName(name)
    return self.nameToPlaceable[name]
end
function GuidedTourManager:addPlaceable(placeable, name)
    self.nameToPlaceable[name] = placeable
end
function GuidedTourManager:removePlaceable(name)
    self.nameToPlaceable[name] = nil
end
function GuidedTourManager:registerGoalClass(name, class)
    self.goalClasses[name] = class
end
function GuidedTourManager:getAllGoalClasses()
    return self.goalClasses
end
function GuidedTourManager:registerActionClass(name, class)
    self.actionClasses[name] = class
end
function GuidedTourManager:getAllActionClasses()
    return self.actionClasses
end
function GuidedTourManager:registerProgressClass(name, class)
    self.progressClasses[name] = class
end
function GuidedTourManager:getAllProgressClasses()
    return self.progressClasses
end
g_guidedTourManager = GuidedTourManager.new()