AIDebugDump = {}
local AIDebugDump_mt = Class(AIDebugDump)
AIDebugDump.SAVE_DIRECTORY = getUserProfileAppPath() .. "aiSystem/"
function AIDebugDump.new(vehicle, agentId, customMt)
    -- upvalues: (copy) AIDebugDump_mt
    local self = setmetatable({}, customMt or AIDebugDump_mt)
    self.vehicle = vehicle
    self.agentId = agentId
    self.dumpedAgent = false
    self.plannedTargetIndex = nil
    return self
end
function AIDebugDump:delete()
    self:stopRecording()
end
function AIDebugDump:setTarget(x, y, z, dirX, dirY, dirZ, cx, cy, cz, cDirX, cDirY, cDirZ)
    if self.dump ~= nil then
        table.insert(self.dump.targets, {
            ["frames"] = {},
            ["target"] = {
                x,
                y,
                z,
                dirX,
                dirY,
                dirZ
            },
            ["start"] = {
                cx,
                cy,
                cz,
                cDirX,
                cDirY,
                cDirZ
            }
        })
    end
end
function AIDebugDump:addData(dt, x, y, z, dirX, dirY, dirZ, lastSpeed, curvature, maxSpeed, status)
    if self.dump ~= nil then
        table.insert(self.dump.targets[#self.dump.targets].frames, {
            ["dt"] = dt,
            ["pos"] = { x, y, z },
            ["dir"] = { dirX, dirY, dirZ },
            ["lastSpeed"] = lastSpeed,
            ["curvature"] = curvature,
            ["speed"] = maxSpeed,
            ["status"] = status
        })
        if not self.dumpedAgent then
            self.dumpedAgent = true
            dumpVehicleNavigationAgent(self.agentId, AIDebugDump.SAVE_DIRECTORY .. self.filename .. "_target" .. tostring(self.plannedTargetIndex or -1) .. ".dat")
        end
    end
end
function AIDebugDump:startRecording(minTurningRadius, allowBackwards, width, length, lengthOffset, frontOffset, maxBrakeAcceleration, maxCentripetalAcceleration)
    if self.dump == nil then
        self.dumpedAgent = false
        createFolder(AIDebugDump.SAVE_DIRECTORY)
        self.filename = getDate("%Y_%m_%d_%H_%M_%S") .. "_dump"
        self.dump = {
            ["minTurningRadius"] = minTurningRadius,
            ["allowBackwards"] = allowBackwards,
            ["width"] = width,
            ["length"] = length,
            ["lengthOffset"] = lengthOffset,
            ["frontOffset"] = frontOffset,
            ["maxBrakeAcceleration"] = maxBrakeAcceleration,
            ["maxCentripetalAcceleration"] = maxCentripetalAcceleration,
            ["targets"] = {}
        }
    end
end
function AIDebugDump:stopRecording()
    if self.dump ~= nil then
        Logging.info("Writing debug dump...")
        self:stopPlanningRecording()
        local xmlFile = createXMLFile("dumpData", AIDebugDump.SAVE_DIRECTORY .. self.filename .. ".xml", "dumpData")
        if xmlFile == 0 then
            Logging.error("Failed to create ai dumpdata xml file")
            return
        end
        setXMLString(xmlFile, "dumpData.vehicle", self.vehicle.configFileName)
        setXMLFloat(xmlFile, "dumpData.settings#minTurningRadius", self.dump.minTurningRadius)
        setXMLBool(xmlFile, "dumpData.settings#allowBackwards", self.dump.allowBackwards)
        setXMLFloat(xmlFile, "dumpData.settings#width", self.dump.width)
        setXMLFloat(xmlFile, "dumpData.settings#length", self.dump.length)
        setXMLFloat(xmlFile, "dumpData.settings#lengthOffset", self.dump.lengthOffset)
        setXMLFloat(xmlFile, "dumpData.settings#frontOffset", self.dump.frontOffset)
        setXMLFloat(xmlFile, "dumpData.settings#maxBrakeAcceleration", self.dump.maxBrakeAcceleration)
        setXMLFloat(xmlFile, "dumpData.settings#maxCentripetalAcceleration", self.dump.maxCentripetalAcceleration)
        for k, target in ipairs(self.dump.targets) do
            local key = string.format("dumpData.targets.target(%d)", k - 1)
            setXMLFloat(xmlFile, key .. ".start#x", target.start[1])
            setXMLFloat(xmlFile, key .. ".start#y", target.start[2])
            setXMLFloat(xmlFile, key .. ".start#z", target.start[3])
            setXMLFloat(xmlFile, key .. ".start#xDir", target.start[4])
            setXMLFloat(xmlFile, key .. ".start#yDir", target.start[5])
            setXMLFloat(xmlFile, key .. ".start#zDir", target.start[6])
            setXMLFloat(xmlFile, key .. ".target#x", target.target[1])
            setXMLFloat(xmlFile, key .. ".target#y", target.target[2])
            setXMLFloat(xmlFile, key .. ".target#z", target.target[3])
            setXMLFloat(xmlFile, key .. ".target#xDir", target.target[4])
            setXMLFloat(xmlFile, key .. ".target#yDir", target.target[5])
            setXMLFloat(xmlFile, key .. ".target#zDir", target.target[6])
            for j, frameData in ipairs(target.frames) do
                local frameKey = string.format("%s.frames.frame(%d)", key, j - 1)
                local stateName = ({})[frameData.status]
                if stateName == nil then
                    stateName = AISystem.getAgentStateName(frameData.status)
                    stateCache[frameData.status] = stateName
                end
                setXMLString(xmlFile, frameKey .. "#status", stateName)
                setXMLFloat(xmlFile, frameKey .. "#speed", frameData.speed)
                setXMLFloat(xmlFile, frameKey .. "#curvature", frameData.curvature)
                setXMLFloat(xmlFile, frameKey .. "#dt", frameData.dt)
                setXMLFloat(xmlFile, frameKey .. "#x", frameData.pos[1])
                setXMLFloat(xmlFile, frameKey .. "#y", frameData.pos[2])
                setXMLFloat(xmlFile, frameKey .. "#z", frameData.pos[3])
                setXMLFloat(xmlFile, frameKey .. "#dirX", frameData.dir[1])
                setXMLFloat(xmlFile, frameKey .. "#dirY", frameData.dir[2])
                setXMLFloat(xmlFile, frameKey .. "#dirZ", frameData.dir[3])
                setXMLFloat(xmlFile, frameKey .. "#lastSpeed", frameData.lastSpeed)
            end
        end
        saveXMLFile(xmlFile)
        delete(xmlFile)
    end
end
function AIDebugDump:startPlanningRecording()
    beginVehicleNavigationDebugLogging(self.agentId)
    beginVehicleNavigationPlannerRecording(self.agentId)
    self.plannedTargetIndex = #self.dump.targets + 1
    self.dumpedAgent = false
end
function AIDebugDump:stopPlanningRecording()
    if self.plannedTargetIndex ~= nil then
        Logging.info("Writing Planning Data...")
        local folder = AIDebugDump.SAVE_DIRECTORY
        local filename = self.filename
        local logFilename = folder .. filename .. "_target" .. tostring(self.plannedTargetIndex) .. ".log"
        endVehicleNavigationDebugLogging(self.agentId, logFilename)
        local bitmapFilename = filename .. "_target" .. tostring(self.plannedTargetIndex) .. "_bitmap"
        local entityId = endVehicleNavigationPlannerRecording(self.agentId, bitmapFilename)
        saveBitVectorMapToFile(entityId, folder .. filename .. "_target" .. tostring(self.plannedTargetIndex) .. ".grle")
        g_currentMission.aiSystem:setPlanningBitVectorMap(entityId)
        self.plannedTargetIndex = nil
    end
end