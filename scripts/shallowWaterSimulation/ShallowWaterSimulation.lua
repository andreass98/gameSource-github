ShallowWaterSimulation = {}
ShallowWaterSimulation.SHADER_CUSTOMMAP_NAME = "shallowWaterSimulationResult"
ShallowWaterSimulation.SHADER_CUSTOMMAP_VELOCITYU_NAME = "shallowWaterSimulationVelocityU"
ShallowWaterSimulation.SHADER_CUSTOMMAP_VELOCITYV_NAME = "shallowWaterSimulationVelocityV"
ShallowWaterSimulation.SHADER_PARAMETER_NAME = "simulationOffsetSize"
local ShallowWaterSimulation_mt = Class(ShallowWaterSimulation)
ShallowWaterSimulation.PROFILES = {
    ["HIGH"] = { 512, 96 },
    ["MEDIUM"] = { 256, 64 },
    ["LOW"] = { 128, 64 }
}
function ShallowWaterSimulation.new()
    -- upvalues: (copy) ShallowWaterSimulation_mt
    local self = setmetatable({}, ShallowWaterSimulation_mt)
    self.waterSim = nil
    self.waterSimPos = { 0, 0 }
    self.waterPlanes = {}
    self.areaGeometries = {}
    self.obstacles = {}
    self.numActiveObstacles = 0
    self.waterSimulationTexture = nil
    self.waterSimulationVelocityUTexture = nil
    self.waterSimulationVelocityVTexture = nil
    return self
end
function ShallowWaterSimulation:load()
    self.foamAccumulationRate = 0.35
    self.foamDecayRate = 0.05
    local profileClass = Utils.getPerformanceClassId()
    local profileSetting
    if profileClass <= GS_PROFILE_LOW then
        profileSetting = ShallowWaterSimulation.PROFILES.LOW
        if profileClass <= GS_PROFILE_MEDIUM then
            self.foamAccumulationRate = 0
        end
    elseif GS_PROFILE_HIGH <= profileClass then
        profileSetting = ShallowWaterSimulation.PROFILES.HIGH
    else
        profileSetting = ShallowWaterSimulation.PROFILES.MEDIUM
    end
    self.gridSizeX = profileSetting[1]
    self.gridSizeZ = profileSetting[1]
    self.sizeX = profileSetting[2]
    self.sizeZ = profileSetting[2]
    self.offsetDistance = self.sizeX / 3
    self.waterSim = createShallowWaterSimulation("shallowWaterSimulation", self.gridSizeX, self.gridSizeZ, self.sizeX, self.sizeZ, false)
    self.updateStepTime = 0.016666666666666666
    self.externalAcceleration = 1
    self.dampening = 0.998
    self.fakeExtraDepth = 5
    self.pmlDampeningFactor = 1
    self.pmlDampeningUpdateFactor = 0.5
    self.pmlDampeningDecay = 0.95
    self.pmlNumBorderCells = 16
    self:updateParameters()
    self.waterSimulationTexture = getShallowWaterSimulationOutputTexture(self.waterSim)
    self.waterSimulationVelocityUTexture = getShallowWaterSimulationOutputVelocityUTexture(self.waterSim)
    self.waterSimulationVelocityVTexture = getShallowWaterSimulationOutputVelocityVTexture(self.waterSim)
    addConsoleCommand("gsShallowWaterSimDebug", "Toggle shallow water simulation debug mode", "consoleCommandDebugToggle", self)
    addConsoleCommand("gsShallowWaterSimReset", "Reset water simulation", "consoleCommandReset", self)
    addConsoleCommand("gsShallowWaterSimParamSet", "Set water simulation parameters", "consoleCommandParamSet", self, "updateStepTime; externalAcceleration; dampening")
    addConsoleCommand("gsShallowWaterSimExtraDepthSet", "Set water simulation extra depth", "consoleCommandSetExtraDepth", self, "extraDepth")
    addConsoleCommand("gsShallowWaterSimPaint", "Paint shape on simulation", "consoleCommandPaint", self, "[circle|rect]; [velocityScale]; [radiusOrWidth]; [height]")
    addConsoleCommand("gsShallowWaterSimFoamParamSet", "Set water simulation foam parameters", "consoleCommandFoamParamSet", self, "accumulationRate; decayRate")
    addConsoleCommand("gsShallowWaterSimSizeSet", "Set water simulation size", "consoleCommandSizeSet", self, "simulation size in meters")
    addConsoleCommand("gsShallowWaterSimPMLParamSet", "Set perfectly matched layer boundary condition params", "consoleCommandPMLSet", self, "dampeningFactor; dampeningUpdateFactor; dampeningDecay; numBorderCells")
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.FRAME_LIMIT], self.updateParameters, self)
    return self
end
function ShallowWaterSimulation:updateParameters()
    self.updateStepTime = 1 / (g_gameSettings:getValue(GameSettings.SETTING.FRAME_LIMIT) or 60)
    if self.waterSim ~= nil then
        setShallowWaterSimulationParameters(self.waterSim, self.updateStepTime, self.externalAcceleration, self.dampening)
        setShallowWaterSimulationFakeExtraDepth(self.waterSim, self.fakeExtraDepth)
        setShallowWaterSimulationFoamAccumulationRate(self.waterSim, self.foamAccumulationRate)
        setShallowWaterSimulationFoamDecayRate(self.waterSim, self.foamDecayRate)
        setShallowWaterSimulationPerfectlyMatchedLayerParameters(self.waterSim, self.pmlDampeningFactor, self.pmlDampeningUpdateFactor, self.pmlDampeningDecay, self.pmlNumBorderCells, false, true, true, true, true)
    end
end
function ShallowWaterSimulation:delete()
    g_messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.FRAME_LIMIT], self)
    if self.waterSim ~= nil then
        delete(self.waterSim)
        self.waterSim = nil
    end
    removeConsoleCommand("gsShallowWaterSimDebug")
    removeConsoleCommand("gsShallowWaterSimReset")
    removeConsoleCommand("gsShallowWaterSimParamSet")
    removeConsoleCommand("gsShallowWaterSimExtraDepthSet")
    removeConsoleCommand("gsShallowWaterSimPaint")
    removeConsoleCommand("gsShallowWaterSimFoamParamSet")
    removeConsoleCommand("gsShallowWaterSimSizeSet")
    removeConsoleCommand("gsShallowWaterSimPMLParamSet")
end
function ShallowWaterSimulation:onTerrainLoad(terrainRootNode, _)
    setShallowWaterSimulationGroundHeightTextureFromTerrain(self.waterSim, terrainRootNode)
    Logging.devInfo("setShallowWaterSimulationGroundHeightTextureFromTerrain")
end
function ShallowWaterSimulation:update(dt)
    if self.waterSim ~= nil then
        local camera = g_cameraManager:getActiveCamera()
        local camX, _, camZ = getWorldTranslation(camera)
        local camDx, _, camDz = localDirectionToWorld(camera, 0, 0, -1)
        local offsetX = self.waterSimPos
        local offsetZ = self.waterSimPos
        offsetX[1], offsetZ[2] = setShallowWaterSimulationWorldPosition(self.waterSim, camX + self.offsetDistance * camDx, camZ + self.offsetDistance * camDz)
        local offsetX = self.waterSimPos[1] - self.sizeX / 2
        local offsetZ = self.waterSimPos[2] - self.sizeZ / 2
        for waterPlane in pairs(self.waterPlanes) do
            setShaderParameter(waterPlane, ShallowWaterSimulation.SHADER_PARAMETER_NAME, offsetX, offsetZ, self.sizeX, self.sizeZ, false)
        end
        self.numActiveObstacles = 0
        for waterPlane, obstacle in ipairs(self.obstacles) do
            if calcDistanceFrom(obstacle.node, camera) <= self.sizeX then
                local velocityX, velocityZ, obstacleHeight
                if obstacle.offset == nil then
                    velocityX, velocityZ, obstacleHeight = getWorldTranslation(obstacle.node)
                else
                    velocityX, velocityZ, obstacleHeight = localToWorld(obstacle.node, obstacle.offset[1] or 0, obstacle.offset[2] or 0, obstacle.offset[3] or 0)
                end
                local y = velocityZ - 0.05
                self.numActiveObstacles = self.numActiveObstacles + 1
                local velocityX = 0
                local velocityZ = 0
                local obstacleHeight = y - obstacle.sizeY / 2
                local rotY = obstacle.rotY
                if obstacle.getXZVelocityAndRotYFunc ~= nil then
                    velocityX, velocityZ, rotY = obstacle.getXZVelocityAndRotYFunc(obstacle.getXZVelocityAndRotYFuncTarget)
                end
                if rotY == nil then
                    local xDir, _, zDir = localDirectionToWorld(obstacle.node, 0, 0, 1)
                    rotY = MathUtil.getYRotationFromDirection(xDir, zDir)
                end
                if obstacle.obstacleType == ObstacleType.RECTANGLE then
                    shallowWaterSimulationPaintCustomObstacle(self.waterSim, waterPlane, velocityX, obstacleHeight, obstacle.sizeX, obstacle.sizeZ, rotY, velocityX, velocityZ, obstacleHeight)
                    if self.debugEnabled then
                        self.debugBox:createWithWorldPosAndRot(velocityX, y, obstacleHeight, 0, rotY, 0, obstacle.sizeX, obstacle.sizeY, obstacle.sizeZ)
                        local xDir = DebugUtil.isPositionInCameraRange
                        if xDir(velocityX, y, obstacleHeight, math.max(obstacle.sizeX * 2, obstacle.sizeZ * 2, 25), camera) then
                            local xDir = string.format("SWS obstacle %d %s\nvelX: %.3f velZ: %.3f\nrotY %d", waterPlane, getName(obstacle.node), velocityX, velocityZ, (math.deg(rotY)))
                            self.debugBox:setText(xDir):setTextSize(0.012)
                            DebugLine.renderBetweenPositions(velocityX, y, obstacleHeight, velocityX + velocityX / 2, y, obstacleHeight + velocityZ / 2, nil, false)
                        else
                            self.debugBox:setText(nil)
                        end
                        self.debugBox:draw()
                    end
                else
                    shallowWaterSimulationPaintCustomObstacleEllipse(self.waterSim, waterPlane, velocityX, obstacleHeight, obstacle.sizeX, obstacle.sizeZ, rotY, velocityX, velocityZ, obstacleHeight)
                    if self.debugEnabled then
                        self.debugCylinder:createWithWorldPos(velocityX, y, obstacleHeight, obstacle.sizeX * 0.5, obstacle.sizeY * 0.5, Axis.Y)
                        local xDir = DebugUtil.isPositionInCameraRange
                        if xDir(velocityX, y, obstacleHeight, math.max(obstacle.sizeX * 2, obstacle.sizeZ * 2, 25), camera) then
                            local xDir = string.format("SWS obstacle %d %s\nvelX: %.3f velZ: %.3f\nrotY %d", waterPlane, getName(obstacle.node), velocityX, velocityZ, (math.deg(rotY)))
                            self.debugCylinder:setText(xDir):setTextSize(0.012)
                            DebugLine.renderBetweenPositions(velocityX, y, obstacleHeight, velocityX + velocityX / 2, y, obstacleHeight + velocityZ / 2, nil, false)
                        else
                            self.debugCylinder:setText(nil)
                        end
                        self.debugCylinder:draw()
                    end
                end
            end
        end
        updateShallowWaterSimulation(self.waterSim, dt)
    end
end
function ShallowWaterSimulation:drawDebug()
    if not g_gui:getIsGuiVisible() then
        for waterPlane in pairs(self.waterPlanes) do
            local x, y, z, r = getShapeWorldBoundingSphere(waterPlane)
            if DebugUtil.isPositionInCameraRange(x, y, z, r + self.sizeX) then
                DebugShapeOutline.render(waterPlane)
            end
        end
        if g_terrainNode ~= nil then
            local text = string.format("water sim\ncenter %.2f %.2f", self.waterSimPos[1], self.waterSimPos[2])
            DebugPoint.renderAtPosition(self.waterSimPos[1], getTerrainHeightAtWorldPos(g_terrainNode, self.waterSimPos[1], 0, self.waterSimPos[2]), self.waterSimPos[2], nil, false, text)
            DebugPlane.renderWithPositions(self.waterSimPos[1] - self.sizeX / 2, self.waterSimPos[1] + self.sizeX / 2, self.waterSimPos[2] - self.sizeZ / 2, self.waterSimPos[1] - self.sizeX / 2, self.waterSimPos[1] + self.sizeX / 2, self.waterSimPos[2] + self.sizeZ / 2, y, self.waterSimPos[1] + self.sizeX / 2, self.waterSimPos[2] - self.sizeZ / 2, nil, false, false, false, false)
        end
        local y = 0.6
        renderText(0.01, y, 0.02, "ShallowWaterSimulation")
        y = y - 0.02
        local sx = string.format("entity:%d sim-texture:%d velU-texture:%d velV-texture:%d", self.waterSim, self.waterSimulationTexture, self.waterSimulationVelocityUTexture, self.waterSimulationVelocityVTexture)
        renderText(0.01, y, 0.016, sx)
        y = y - 0.016
        local sx = string.format("gridSize:%dx%d(pixels) size:%.1fx%.1f(m) => pixelSize:%.1fx%.1f(cm)", self.gridSizeX, self.gridSizeZ, self.sizeX, self.sizeZ, self.sizeX / self.gridSizeX * 100, self.sizeZ / self.gridSizeZ * 100)
        renderText(0.01, y, 0.016, sx)
        y = y - 0.016
        local sx = string.format("updateStepTime:%.2fms externalAcceleration:%.2fm/s\194\178 dampening:%.4f", self.updateStepTime * 1000, self.externalAcceleration, self.dampening)
        renderText(0.01, y, 0.016, sx)
        y = y - 0.016
        local sx = string.format("extraFakeDepth:%.3fm", getShallowWaterSimulationFakeExtraDepth(self.waterSim))
        renderText(0.01, y, 0.016, sx)
        y = y - 0.016
        local sx = string.format("foam accumulationRate:%.3f decayRate:%.3f", getShallowWaterSimulationFoamAccumulationRate(self.waterSim), getShallowWaterSimulationFoamDecayRate(self.waterSim))
        renderText(0.01, y, 0.016, sx)
        y = y - 0.016
        renderText(0.01, y, 0.016, "perfectlyMatchedLayerParameters:")
        y = y - 0.016
        local sx = string.format("    dampeningFactor: %.2f", self.pmlDampeningFactor)
        renderText(0.01, y, 0.016, sx)
        y = y - 0.016
        local sx = string.format("    dampeningUpdateFactor: %.2f", self.pmlDampeningUpdateFactor)
        renderText(0.01, y, 0.016, sx)
        y = y - 0.016
        local sx = string.format("    dampeningDecay: %.2f", self.pmlDampeningDecay)
        renderText(0.01, y, 0.016, sx)
        y = y - 0.016
        local sx = string.format("    numBorderCells: %d", self.pmlNumBorderCells)
        renderText(0.01, y, 0.016, sx)
        y = y - 0.016
        local sx = string.format("numObstacles: %d registered, %d active/in range", #self.obstacles, self.numActiveObstacles)
        renderText(0.01, y, 0.016, sx)
        y = y - 0.016
        local sx = string.format("numWaterPlanes: %d", table.size(self.waterPlanes))
        renderText(0.01, y, 0.016, sx)
        y = y - 0.016
        local sx = getTerrainDisplacementUploadInProgress()
        if sx then
            setTextColor(1, 0, 0, 1)
        end
        local waterPlane = string.format("terrainDisplacementUploadInProgress: %s", (tostring(sx)))
        renderText(0.01, y, 0.016, waterPlane)
        y = y - 0.016
        setTextColor(1, 1, 1, 1)
    end
end
function ShallowWaterSimulation:addWaterPlane(shapeId)
    if self.waterSimulationTexture == nil then
        Logging.error("ShallowWaterSimulation:addWaterPlane(): water simulation system / texture not initialized yet")
        return false
    end
    if self.waterSimulationVelocityUTexture == nil then
        Logging.error("ShallowWaterSimulation:addWaterPlane(): water simulation system / texture not initialized yet (velocity U texture missing)")
        return false
    end
    if self.waterSimulationVelocityVTexture == nil then
        Logging.error("ShallowWaterSimulation:addWaterPlane(): water simulation system / texture not initialized yet (velocity V texture missing)")
        return false
    end
    if not getHasShaderParameter(shapeId, ShallowWaterSimulation.SHADER_PARAMETER_NAME) then
        Logging.i3dWarning(shapeId, "ShallowWaterSimulation:addWaterPlane(): shape is missing \'%s\' shader parameter used by SWS. Ignoring", ShallowWaterSimulation.SHADER_PARAMETER_NAME)
        return false
    end
    local waterPlaneMat = getMaterial(shapeId, 0)
    setMaterialCustomMap(waterPlaneMat, ShallowWaterSimulation.SHADER_CUSTOMMAP_NAME, self.waterSimulationTexture, true)
    setMaterialCustomMap(waterPlaneMat, ShallowWaterSimulation.SHADER_CUSTOMMAP_VELOCITYU_NAME, self.waterSimulationVelocityUTexture, true)
    setMaterialCustomMap(waterPlaneMat, ShallowWaterSimulation.SHADER_CUSTOMMAP_VELOCITYV_NAME, self.waterSimulationVelocityVTexture, true)
    self.waterPlanes[shapeId] = true
    if self.debugEnabled then
        self:enableWaterPlaneDebugMode(shapeId)
    end
    return true
end
function ShallowWaterSimulation:removeWaterPlane(shape)
    if self.waterPlanes[shape] == nil then
        Logging.warning("Cannot remove water plane \'%s\' (%d), not registered in simulation or already removed", getName(shape), shape)
    else
        self.waterPlanes[shape] = nil
    end
end
function ShallowWaterSimulation:addAreaGeometry(shape)
    if self.areaGeometries[shape] ~= nil then
        Logging.warning("Shape \'%s\' (%d) was already to shallow water simulation", getName(shape), shape)
        return false
    end
    shallowWaterSimulationAddWaterPlaneGeometry(self.waterSim, shape)
    self.areaGeometries[shape] = true
    return true
end
function ShallowWaterSimulation:removeAreaGeometry(shape)
    if self.areaGeometries[shape] == nil then
        Logging.warning("Cannot remove water area geometry \'%s\' (%d), not registered in simulation or already removed", getName(shape), shape)
    else
        shallowWaterSimulationRemoveWaterPlaneGeometry(self.waterSim, shape)
        self.areaGeometries[shape] = nil
    end
end
function ShallowWaterSimulation:addObstacle(nodeId, sizeX, sizeY, sizeZ, getXZVelocityAndRotYFunc, getXZVelocityAndRotYFuncTarget, offset, rotY, obstacleType)
    if entityExists(nodeId) then
        if type(sizeX) == "number" and (type(sizeY) == "number" and type(sizeZ) == "number") then
            if offset == nil or type(offset) == "table" then
                local obstacle = {
                    ["obstacleType"] = obstacleType or ObstacleType.RECTANGLE,
                    ["node"] = nodeId,
                    ["sizeX"] = sizeX,
                    ["sizeY"] = sizeY,
                    ["sizeZ"] = sizeZ,
                    ["rotY"] = rotY,
                    ["getXZVelocityAndRotYFunc"] = getXZVelocityAndRotYFunc,
                    ["getXZVelocityAndRotYFuncTarget"] = getXZVelocityAndRotYFuncTarget,
                    ["offset"] = offset,
                    ["inRange"] = false
                }
                table.insert(self.obstacles, obstacle)
                return obstacle
            end
            Logging.error("ShallowWaterSimulation:addObstacle(): Invalid \'offset\' given, must be table")
        else
            Logging.error("ShallowWaterSimulation:addObstacle(): Invalid size given given: %s %s %s", sizeX, sizeY, sizeZ)
        end
    else
        Logging.error("ShallowWaterSimulation:addObstacle(): Given nodeId %q does not exist", nodeId)
        return
    end
end
function ShallowWaterSimulation:removeObstacle(obstacle)
    local success = table.removeElement(self.obstacles, obstacle)
    if not success then
        Logging.warning("Unable to remove obstacle, not found")
    end
    return success
end
function ShallowWaterSimulation:paintCircle(x, y, z, radius, velocityX, velocityZ)
    shallowWaterSimulationPaintVelocityCircle(self.waterSim, x, z, radius, velocityX, velocityZ, y)
end
function ShallowWaterSimulation:paintRectangle(x, y, z, width, height, velocityX, velocityZ)
    shallowWaterSimulationPaintVelocityRect(self.waterSim, x, z, width, height, velocityX, velocityZ, y)
end
function ShallowWaterSimulation:reset()
    shallowWaterSimulationResetSimulation(self.waterSim)
end
function ShallowWaterSimulation:enableWaterPlaneDebugMode(waterPlane)
    self.debugWaterPlaneAlphaBackup = self.debugWaterPlaneAlphaBackup or {}
    self.debugWaterPlaneAlphaBackup[waterPlane] = getShaderParameter(waterPlane, "alpha")
    setShaderParameter(waterPlane, "alpha", 0.9, 0, 0, 0, false)
end
function ShallowWaterSimulation:consoleCommandDebugToggle()
    self.debugEnabled = not self.debugEnabled
    if self.debugEnabled then
        self.debugBox = DebugBox.new()
        self.debugCylinder = DebugCylinder.new()
        g_debugManager:addDrawable(self)
        for waterPlane in pairs(self.waterPlanes) do
            self:enableWaterPlaneDebugMode(waterPlane)
        end
    else
        g_debugManager:removeDrawable(self)
        self.debugBox = nil
        self.debugCylinder = nil
        if self.debugWaterPlaneAlphaBackup ~= nil then
            for waterPlane, alpha in pairs(self.debugWaterPlaneAlphaBackup) do
                setShaderParameter(waterPlane, "alpha", alpha, 0, 0, 0, false)
            end
            self.debugWaterPlaneAlphaBackup = nil
        end
    end
end
function ShallowWaterSimulation:consoleCommandReset()
    self:reset()
    return "Reset shallow water simulation"
end
function ShallowWaterSimulation:consoleCommandFoamParamSet(accumulationRate, decayRate)
    self.foamAccumulationRate = tonumber(accumulationRate) or self.foamAccumulationRate
    self.foamDecayRate = tonumber(decayRate) or self.foamDecayRate
    setShallowWaterSimulationFoamAccumulationRate(self.waterSim, self.foamAccumulationRate)
    setShallowWaterSimulationFoamDecayRate(self.waterSim, self.foamDecayRate)
    return "Updated shallow water simulation foam parameters"
end
function ShallowWaterSimulation:consoleCommandParamSet(updateStepTime, externalAcceleration, dampening)
    self.updateStepTime = tonumber(updateStepTime) or self.updateStepTime
    self.externalAcceleration = tonumber(externalAcceleration) or self.externalAcceleration
    self.dampening = tonumber(dampening) or self.dampening
    setShallowWaterSimulationParameters(self.waterSim, self.updateStepTime, self.externalAcceleration, self.dampening)
    return "Updated shallow water simulation parameters"
end
function ShallowWaterSimulation:consoleCommandSetExtraDepth(extraDepth)
    extraDepth = tonumber(extraDepth)
    if extraDepth == nil then
        return string.format("Current shallow water simulation extraDepth %.3f", getShallowWaterSimulationFakeExtraDepth(self.waterSim))
    end
    setShallowWaterSimulationFakeExtraDepth(self.waterSim, extraDepth)
    return string.format("Updated shallow water simulation extraDepth %.3f", getShallowWaterSimulationFakeExtraDepth(self.waterSim))
end
function ShallowWaterSimulation:consoleCommandSizeSet(sizeM)
    sizeM = tonumber(sizeM)
    if sizeM == nil then
        return string.format("Current shallow water simulation size %dx%dm", self.sizeX, self.sizeZ)
    end
    setShallowWaterSimulationPhysicalGridSize(self.waterSim, sizeM, sizeM)
    self.sizeX = sizeM
    self.sizeZ = sizeM
    return string.format("Updated shallow water simulation size to %dx%dm", sizeM, sizeM)
end
function ShallowWaterSimulation:consoleCommandPMLSet(dampeningFactor, dampeningUpdateFactor, dampeningDecay, numBorderCells)
    dampeningFactor = tonumber(dampeningFactor)
    dampeningUpdateFactor = tonumber(dampeningUpdateFactor)
    dampeningDecay = tonumber(dampeningDecay)
    numBorderCells = tonumber(numBorderCells)
    if dampeningFactor == nil or (dampeningUpdateFactor == nil or (dampeningDecay == nil or numBorderCells == nil)) then
        return string.format("Current shallow water simulation pml settings: %.4f %.4f %.4f %d", self.pmlDampeningFactor, self.pmlDampeningUpdateFactor, self.pmlDampeningDecay, self.pmlNumBorderCells)
    end
    self.pmlDampeningFactor = dampeningFactor
    self.pmlDampeningUpdateFactor = dampeningUpdateFactor
    self.pmlDampeningDecay = dampeningDecay
    self.pmlNumBorderCells = numBorderCells
    setShallowWaterSimulationPerfectlyMatchedLayerParameters(self.waterSim, dampeningFactor, dampeningUpdateFactor, dampeningDecay, numBorderCells, false, true, true, true, true)
    return string.format("Current shallow water simulation pml settings: %.4f%.4f%.4f%d", dampeningFactor, dampeningUpdateFactor, dampeningDecay, numBorderCells)
end
function ShallowWaterSimulation:consoleCommandPaint(shapeType, velocityScale, radiusOrWidth, height)
    local shapeTypes = {
        ["circle"] = true,
        ["rect"] = true
    }
    velocityScale = tonumber(velocityScale) or 3
    shapeType = shapeType or "circle"
    if shapeTypes[shapeType] ~= nil then
        radiusOrWidth = tonumber(radiusOrWidth) or 2
        height = tonumber(height) or 2
        local x, y, z, dx, dy, dz = RaycastUtil.getCameraPickingRay(0.5, 0.6, g_cameraManager:getActiveCamera())
        local node, hx, hy, hz = RaycastUtil.raycastClosest(x, y, z, dx, dy, dz, 200, CollisionFlag.WATER)
        if node == nil then
            return "No water plane found"
        end
        if shapeType == "circle" then
            self:paintCircle(hx, hy - 0.1, hz, radiusOrWidth, dx * velocityScale, dz * velocityScale)
        else
            self:paintRectangle(hx, hy - 0.1, hz, radiusOrWidth, height, dx * velocityScale, dz * velocityScale)
        end
        return string.format("Painted \'%s\' at %f %f %f", shapeType, hx, hy, hz)
    end
    Logging.error("Error: unknown shapeType \'%s\', available shapes: %s", shapeType, table.concatKeys(shapeTypes, ", "))
    print("Usage: gsShallowWaterSimPaint circle|rect velocityScale radiusOrWidth height")
end