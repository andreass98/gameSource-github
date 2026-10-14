Wipers = {}
Wipers.forcedState = -1
function Wipers.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Enterable, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end
function Wipers.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Wipers")
    schema:register(XMLValueType.STRING, "vehicle.wipers.wiper(?)#animName", "Animation name")
    schema:register(XMLValueType.FLOAT, "vehicle.wipers.wiper(?).state(?)#animSpeed", "Animation speed")
    schema:register(XMLValueType.FLOAT, "vehicle.wipers.wiper(?).state(?)#animPause", "Animation pause time (sec.)")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.wipers.dashboards", { "state" })
    schema:setXMLSpecializationType()
end
function Wipers.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadWiperFromXML", Wipers.loadWiperFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getIsActiveForWipers", Wipers.getIsActiveForWipers)
end
function Wipers.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Wipers)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Wipers)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Wipers)
    SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", Wipers)
end
function Wipers:onLoad(_)
    local spec = self.spec_wipers
    spec.wipers = {}
    local i = 0
    while true do
        local key = string.format("vehicle.wipers.wiper(%d)", i)
        if not self.xmlFile:hasProperty(key) then
            break
        end
        local wiper = {}
        if self:loadWiperFromXML(self.xmlFile, key, wiper) then
            wiper.lastValidState = 1
            wiper.lastState = 0
            table.insert(spec.wipers, wiper)
        end
        i = i + 1
    end
    local key = #spec.wipers > 0
    spec.hasWipers = key
    spec.lastRainScale = 0
    spec.maxStateWiper = nil
    local key = 0
    for _, wiper in ipairs(spec.wipers) do
        local numStates = #wiper.states
        if key < numStates then
            spec.maxStateWiper = wiper
            key = numStates
        end
    end
    if not spec.hasWipers then
        SpecializationUtil.removeEventListener(self, "onUpdateTick", Wipers)
    end
end
function Wipers:onRegisterDashboardValueTypes()
    local spec = self.spec_wipers
    if spec.maxStateWiper ~= nil then
        local state = DashboardValueType.new("wipers", "state")
        state:setValue(spec.maxStateWiper, "lastState")
        state:setPollUpdate(false)
        self:registerDashboardValueType(state)
    end
end
function Wipers:onUpdateTick(_, _, _, _)
    if self:getIsControlled() then
        self.spec_wipers.lastRainScale = g_currentMission.environment.weather:getRainFallScale()
        for _, wiper in pairs(spec.wipers) do
            local stateIdToUse = 0
            if self:getIsActiveForWipers() and spec.lastRainScale > 0.01 then
                for stateIndex, state in ipairs(wiper.states) do
                    if spec.lastRainScale <= state.maxRainValue then
                        stateIdToUse = stateIndex
                        break
                    end
                end
            end
            if Wipers.forcedState ~= -1 then
                stateIdToUse = math.clamp(Wipers.forcedState, 0, #wiper.states)
            end
            if stateIdToUse > 0 then
                if (wiper.nextStartTime == nil or wiper.nextStartTime < g_currentMission.time) and not self:getIsAnimationPlaying(wiper.animName) then
                    self:playAnimation(wiper.animName, wiper.states[stateIdToUse].animSpeed, 0, true)
                    wiper.nextStartTime = nil
                end
                if wiper.nextStartTime == nil then
                    wiper.nextStartTime = g_currentMission.time + wiper.animDuration / currentState.animSpeed * 2 + currentState.animPause
                end
                wiper.lastValidState = stateIdToUse
            end
            if stateIdToUse ~= wiper.lastState then
                wiper.lastState = stateIdToUse
                if self.isClient and self.updateDashboardValueType ~= nil then
                    self:updateDashboardValueType("wipers.state")
                end
            end
        end
    end
end
function Wipers:onFinishAnimation(name)
    for _, wiper in pairs(self.spec_wipers.wipers) do
        if wiper.animName == name and self:getAnimationTime(wiper.animName) == 1 then
            self:playAnimation(wiper.animName, -wiper.states[wiper.lastValidState].animSpeed, 1, true)
        end
    end
end
function Wipers:loadWiperFromXML(xmlFile, key, wiper)
    local animName = xmlFile:getValue(key .. "#animName")
    if animName == nil then
        Logging.xmlWarning(self.xmlFile, "Missing animation for wiper \'%s\'!", key)
        return false
    end
    if not self:getAnimationExists(animName) then
        Logging.xmlWarning(self.xmlFile, "Animation \'%s\' not defined for wiper \'%s\'!", animName, key)
        return false
    end
    wiper.animName = animName
    wiper.animDuration = self:getAnimationDuration(animName)
    wiper.states = {}
    local j = 0
    while true do
        local stateKey = string.format("%s.state(%d)", key, j)
        if not xmlFile:hasProperty(stateKey) then
            break
        end
        local state = {
            ["animSpeed"] = xmlFile:getValue(stateKey .. "#animSpeed"),
            ["animPause"] = xmlFile:getValue(stateKey .. "#animPause")
        }
        if state.animSpeed ~= nil and state.animPause ~= nil then
            state.animPause = state.animPause * 1000
            table.insert(wiper.states, state)
        end
        j = j + 1
    end
    local j = #wiper.states
    if j <= 0 then
        Logging.xmlWarning(self.xmlFile, "No states defined for wiper \'%s\'!", key)
        return false
    end
    local stateKey = 1 / j
    for _, state in ipairs(wiper.states) do
        state.maxRainValue = stateKey
        stateKey = stateKey + stateKey
    end
    wiper.nextStartTime = nil
    return true
end
function Wipers:getIsActiveForWipers()
    return true
end
function Wipers.consoleSetWiperState(_, state)
    if state == nil then
        return "Error: No arguments given! Usage: gsWiperStateSet <state> (-1 = use state from weather; 0..n = force specific wiper state)"
    end
    state = tonumber(state)
    if state == nil then
        return "Error: Argument is not a number! Usage: gsWiperStateSet <state> (-1 = use state from weather; 0..n = force specific wiper state)"
    end
    Wipers.forcedState = math.clamp(state, -1, 999)
    return Wipers.forcedState == -1 and " Reset global wiper state, now using weather state" or string.format("Set global wiper states to %d.", Wipers.forcedState)
end
addConsoleCommand("gsWiperStateSet", "Sets the given wiper state for all vehicles", "consoleSetWiperState", Wipers)