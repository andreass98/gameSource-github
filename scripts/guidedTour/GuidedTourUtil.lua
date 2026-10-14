GuidedTourUtil = {}
function GuidedTourUtil.createFromXML(xmlFilename)
    local xmlFile = XMLFile.load("guidedTour", xmlFilename, GuidedTour.xmlSchema)
    if xmlFile == nil then
        return nil
    end
    local className = xmlFile:getValue("guidedTour.class", "GuidedTour")
    xmlFile:delete()
    local class = ClassUtil.getClassObject(className)
    if class == nil then
        Logging.xmlWarning(xmlFile, "GuidedTour controller class \'%s\' not found!", className)
        return nil
    end
    local guidedTour = class.new()
    if guidedTour:load(xmlFilename) then
        return guidedTour
    end
    guidedTour:delete()
    return nil
end
function GuidedTourUtil.loadActionsFromXMLFile(xmlFile, key, baseDirectory, customEnvironment, stepIndex)
    local actions = nil
    local actionClasses = g_guidedTourManager:getAllActionClasses()
    for name, actionClass in pairs(actionClasses) do
        for _, actionKey in xmlFile:iterator(key .. ".actions." .. name) do
            local action = actionClass.createFromXML(xmlFile, actionKey, baseDirectory, customEnvironment, stepIndex)
            if action == nil then
                Logging.xmlWarning(xmlFile, "Could not create guided tour action in \'%s\'", actionKey)
            else
                actions = actions == nil and {} or actions
                table.insert(actions, action)
            end
        end
    end
    return actions
end
function GuidedTourUtil.loadGoalsFromXMLFile(xmlFile, key, baseDirectory, customEnvironment)
    local goals = nil
    local goalClasses = g_guidedTourManager:getAllGoalClasses()
    for name, goalClass in pairs(goalClasses) do
        for _, goalKey in xmlFile:iterator(key .. ".goals." .. name) do
            local goal = goalClass.createFromXML(xmlFile, goalKey, baseDirectory, customEnvironment)
            if goal == nil then
                Logging.xmlWarning(xmlFile, "Could not create guided tour goal in \'%s\'", goalKey)
            else
                goals = goals == nil and {} or goals
                goal.name = name
                table.insert(goals, goal)
            end
        end
    end
    return goals
end
function GuidedTourUtil.loadProgressesFromXMLFile(xmlFile, key, baseDirectory, customEnvironment)
    local progresses = nil
    local progressClasses = g_guidedTourManager:getAllProgressClasses()
    for name, progressClass in pairs(progressClasses) do
        for _, progressKey in xmlFile:iterator(key .. ".progresses." .. name) do
            local progress = progressClass.createFromXML(xmlFile, progressKey, baseDirectory, customEnvironment)
            if progress == nil then
                Logging.xmlWarning(xmlFile, "Could not create guided tour progress in \'%s\'", progressKey)
            else
                progresses = progresses == nil and {} or progresses
                progress.name = name
                table.insert(progresses, progress)
            end
        end
    end
    return progresses
end