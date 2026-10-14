VehicleStateRecorder = {}
VehicleStateRecorder.currentInstance = nil
local VehicleStateRecorder_mt = Class(VehicleStateRecorder)
function VehicleStateRecorder.new(vehicle, name, duration, animationName)
    -- upvalues: (copy) VehicleStateRecorder_mt
    local self = setmetatable({}, VehicleStateRecorder_mt)
    self.vehicle = vehicle
    self.name = name or animationName
    self.duration = (duration or math.huge) * 1000
    if self.name == nil then
        self.name = "vehicleState_" .. getDate("%Y_%m_%d_%H_%M")
    end
    self.nodeState = {}
    if animationName == nil then
        g_currentMission:addUpdateable(self)
        self.isActive = true
        self.startTime = g_time
        self:recordVehicle()
        Logging.info("Start vehicle state recording for \'%s\'", self.vehicle.configFileNameClean)
        return self
    end
    if VehicleStateRecorder.defaultRaiseEvent == nil then
        VehicleStateRecorder.defaultRaiseEvent = SpecializationUtil.raiseEvent
        function SpecializationUtil.raiseEvent(_self, eventName, animName, ...)
            -- upvalues: (copy) self, (copy) animationName
            VehicleStateRecorder.defaultRaiseEvent(_self, eventName, animName, ...)
            if _self == self.vehicle and animName == animationName then
                if eventName == "onPlayAnimation" then
                    if not self.isActive then
                        g_currentMission:addUpdateable(self)
                        self.isActive = true
                        self.startTime = g_time
                        self:recordVehicle()
                        Logging.info("Start vehicle state recording for \'%s\'", self.vehicle.configFileNameClean)
                        return
                    end
                elseif eventName == "onFinishAnimation" and self.isActive then
                    self:finish()
                end
            end
        end
        return self
    end
    Logging.warning("VehicleStateRecorder is already active. Only one recording at a time is supported.")
end
function VehicleStateRecorder:update(_)
    if g_time - self.startTime > self.duration then
        self:finish()
    else
        self:recordVehicle()
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextColor(1, 1, 1, 0.5)
        renderText(0.5, 0.03, 0.03, string.format("Vehicle State Recording for \'%s\' (%.1f sec)", self.vehicle.configFileNameClean, (g_time - self.startTime) * 0.001))
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextColor(1, 1, 1, 1)
    end
end
function VehicleStateRecorder:finish()
    Logging.info("Finish vehicle state recording for \'%s\' (%.1fsec)", self.vehicle.configFileNameClean, (g_time - (self.startTime or 0)) * 0.001)
    local directory = Utils.getDirectory(self.vehicle.configFileName)
    if string.startsWith(directory, "data/") then
        directory = getAppBasePath() .. directory
    end
    local directory = directory .. "giantsTools"
    createFolder(directory)
    local filename = string.format(directory .. "/%s.xml", self.name)
    local xmlFile = XMLFile.create("vehicleState", filename, "vehicleState", nil)
    local lineIndex = 0
    for indexPath, states in pairs(self.nodeState) do
        if #states > 0 then
            local key = string.format("vehicleState.node(%d)", lineIndex)
            xmlFile:setString(key .. "#name", states[1].name)
            xmlFile:setString(key .. "#className", states[1].className)
            xmlFile:setString(key .. "#indexPath", indexPath)
            for i, state in ipairs(states) do
                local stateKey = string.format("%s.s(%d)", key, i - 1)
                xmlFile:setFloat(stateKey .. "#t", state.time * 0.001)
                local lastState = states[i - 1]
                if lastState == nil or (lastState.translation[1] ~= state.translation[1] or (lastState.translation[2] ~= state.translation[2] or lastState.translation[3] ~= state.translation[3])) then
                    xmlFile:setString(stateKey .. "#tr", string.format("%.5f %.5f %.5f", state.translation[1], state.translation[2], state.translation[3]))
                end
                if lastState == nil or (lastState.rotation[1] ~= state.rotation[1] or (lastState.rotation[2] ~= state.rotation[2] or lastState.rotation[3] ~= state.rotation[3])) then
                    xmlFile:setString(stateKey .. "#ro", string.format("%.4f %.4f %.4f", math.deg(state.rotation[1]), math.deg(state.rotation[2]), (math.deg(state.rotation[3]))))
                end
                if lastState == nil or lastState.visibility ~= state.visibility then
                    xmlFile:setBool(stateKey .. "#vi", state.visibility)
                end
            end
            lineIndex = lineIndex + 1
        end
    end
    xmlFile:save()
    xmlFile:delete()
    Logging.info("Save recording to \'%s\'", filename)
    g_currentMission:removeUpdateable(VehicleStateRecorder.currentInstance)
    if VehicleStateRecorder.defaultRaiseEvent ~= nil then
        SpecializationUtil.raiseEvent = VehicleStateRecorder.defaultRaiseEvent
        VehicleStateRecorder.defaultRaiseEvent = nil
    end
end
function VehicleStateRecorder:recordVehicle()
    for i, component in ipairs(self.vehicle.components) do
        self:recordNode(component.node, tostring(i - 1), ">")
    end
end
function VehicleStateRecorder:recordNode(node, indexPath, separator)
    if self.vehicle.i3dMappings[getName(node)] ~= nil then
        local x, y, z = getTranslation(node)
        local rx, ry, rz = getRotation(node)
        local visibility = getVisibility(node)
        local doRecordState = false
        local doRecordState
        if self.nodeState[indexPath] == nil then
            doRecordState = true
            self.nodeState[indexPath] = {}
        else
            local states = self.nodeState[indexPath]
            local lastState = states[#states]
        end
        if doRecordState then
            local states = {
                ["translation"] = { x, y, z },
                ["rotation"] = { rx, ry, rz },
                ["visibility"] = visibility,
                ["time"] = g_time - self.startTime
            }
            if #self.nodeState[indexPath] == 0 then
                states.name = getName(node)
                for className, classId in pairs(ClassIds) do
                    if getHasClassId(node, classId) then
                        states.className = className
                        break
                    end
                end
            end
            table.insert(self.nodeState[indexPath], states)
        end
    end
    local z = 1
    local rx = getNumOfChildren(node)
    local y = 1
    for z = z, rx, y do
        self:recordNode(getChildAt(node, z - 1), indexPath .. (separator or "|") .. z - 1)
    end
end
function VehicleStateRecorder.consoleCommand(_, name, duration)
    if VehicleStateRecorder.currentInstance == nil then
        if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
            local vehicle = g_localPlayer:getCurrentVehicle()
            local selectedVehicle = vehicle:getSelectedVehicle() or vehicle
            VehicleStateRecorder.currentInstance = VehicleStateRecorder.new(selectedVehicle, name, duration)
            return
        end
    else
        VehicleStateRecorder.currentInstance:finish()
        VehicleStateRecorder.currentInstance = nil
    end
end
function VehicleStateRecorder.consoleCommandAnimation(_, animationName)
    if VehicleStateRecorder.currentInstance == nil then
        if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
            local vehicle = g_localPlayer:getCurrentVehicle()
            local selectedVehicle = vehicle:getSelectedVehicle() or vehicle
            VehicleStateRecorder.currentInstance = VehicleStateRecorder.new(selectedVehicle, nil, nil, animationName)
            return
        end
    else
        VehicleStateRecorder.currentInstance:finish()
        VehicleStateRecorder.currentInstance = nil
    end
end
addConsoleCommand("gsVehicleRecordState", "Starts and stops vehicle state recording", "VehicleStateRecorder.consoleCommand", nil)
addConsoleCommand("gsVehicleRecordAnimation", "Turns on the state recording for the given animationName", "VehicleStateRecorder.consoleCommandAnimation", nil)