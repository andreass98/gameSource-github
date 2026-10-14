CameraManager = {}
local CameraManager_mt = Class(CameraManager)
local setCameraLocal = setCamera
function setCamera(cameraNode)
    Logging.warning("Use g_cameraManager:setActiveCamera(cameraNode) instead of setCamera(cameraNode)!")
    g_cameraManager:setActiveCamera(cameraNode)
end
function CameraManager.new(customMt)
    -- upvalues: (copy) CameraManager_mt
    local self = setmetatable({}, customMt or CameraManager_mt)
    self.cameraInfo = {}
    self.originDebugCamera = nil
    self.activeCameraNode = nil
    self.defaultCameraNode = nil
    self.lowResColHandlerHighPrioActive = false
    self.virtualTerrainUpdateEnabled = true
    addConsoleCommand("gsCameraFovSet", "Sets camera field of view angle", "consoleCommandSetFOV", self)
    addConsoleCommand("gsCameraManagerDebug", "Toggle camera manager debug mode", "consoleCommandToggleDebug", self)
    return self
end
function CameraManager:delete()
    if self.originDebugCamera ~= nil then
        delete(self.originDebugCamera)
        self.originDebugCamera = nil
    end
    for cameraNode, info in pairs(self.cameraInfo) do
        if not info.isDefaultCamera then
            Logging.devWarning("CameraManager: Camera \'%s\' was not removed! \n%s", info.name, info.callstack)
        end
    end
end
function CameraManager:init()
    if g_isDevelopmentVersion then
        self.originDebugCamera = createCamera("originDebugCamera", 1.0471975511965976, 0.15, 10000)
        link(getRootNode(), self.originDebugCamera)
        local dirX, dirY, dirZ = MathUtil.vector3Normalize(-20, 10, 20)
        setWorldTranslation(self.originDebugCamera, -20, 10, 20)
        setDirection(self.originDebugCamera, dirX, dirY, dirZ, 0, 1, 0)
    end
end
function CameraManager:addCamera(cameraNode, shadowFocusBoxNode, isDefaultCamera, colHandlerHighPrio, dofInfo, virtualTerrainUpdateEnabled)
    if self.cameraInfo[cameraNode] == nil then
        if isDefaultCamera then
            if self.defaultCameraNode == nil then
                self.defaultCameraNode = cameraNode
            elseif g_showDevelopmentWarnings then
                Logging.devWarning("Try to set an already existing default camera")
                printCallstack()
            end
        end
        self.cameraInfo[cameraNode] = {
            ["node"] = cameraNode,
            ["shadowFocusBoxNode"] = shadowFocusBoxNode,
            ["isDefaultCamera"] = isDefaultCamera,
            ["colHandlerHighPrio"] = colHandlerHighPrio,
            ["dofInfo"] = dofInfo,
            ["name"] = getName(cameraNode),
            ["virtualTerrainUpdateEnabled"] = Utils.getNoNil(virtualTerrainUpdateEnabled, true)
        }
        if g_isDevelopmentVersion and (debug ~= nil and debug.traceback ~= nil) then
            self.cameraInfo[cameraNode].callstack = debug.traceback()
        end
    elseif g_showDevelopmentWarnings then
        Logging.devWarning("Try to add an already existing camera")
        printCallstack()
    end
end
function CameraManager:removeCamera(cameraNode)
    local cameraInfo = self.cameraInfo[cameraNode]
    if cameraInfo == nil then
        if g_showDevelopmentWarnings then
            Logging.devWarning("Try to remove an undefined camera")
            printCallstack()
        end
        return
    elseif cameraInfo.isDefaultCamera then
        if g_showDevelopmentWarnings then
            Logging.devWarning("Cannot remove default camera")
            printCallstack()
        end
    else
        if cameraNode == self.activeCameraNode then
            if g_showDevelopmentWarnings then
                Logging.devWarning("Trying to remove active camera. Disable camera first!")
                printCallstack()
            end
            self:setDefaultCamera()
        end
        self.cameraInfo[cameraNode] = nil
    end
end
function CameraManager:setDefaultCamera()
    if self.defaultCameraNode == nil then
        if g_showDevelopmentWarnings then
            Logging.devWarning("No default camera set")
            printCallstack()
        end
    else
        self:setActiveCamera(self.defaultCameraNode)
    end
end
function CameraManager:setActiveCamera(cameraNode)
    -- upvalues: (copy) setCameraLocal
    if cameraNode == nil then
        if g_showDevelopmentWarnings then
            Logging.devWarning("Try to set nil as a camera")
            printCallstack()
        end
        return
    else
        local cameraInfo = self.cameraInfo[cameraNode]
        if cameraInfo == nil then
            if g_showDevelopmentWarnings then
                Logging.devWarning("Try to set an undefined camera \'%s\'", getName(cameraNode))
                printCallstack()
            end
            return
        elseif self.activeCameraNode == cameraNode then
            Logging.devWarning("Try to set the active camera \'%s\' again", getName(cameraNode))
        else
            if g_terrainNode ~= nil and not cameraInfo.virtualTerrainUpdateEnabled then
                setVirtualTerrainUpdateEnabled(g_terrainNode, false)
                self.virtualTerrainUpdateEnabled = false
            end
            setCameraLocal(cameraNode)
            setShadowFocusBox(cameraInfo.shadowFocusBoxNode or 0)
            if g_terrainNode ~= nil and cameraInfo.virtualTerrainUpdateEnabled then
                setVirtualTerrainUpdateEnabled(g_terrainNode, true)
                self.virtualTerrainUpdateEnabled = true
            end
            if cameraInfo.colHandlerHighPrio then
                setLowResCollisionHandlerHighPrioriyUpdateArea(2)
                self.lowResColHandlerHighPrioActive = true
            else
                setLowResCollisionHandlerHighPrioriyUpdateArea(0)
                self.lowResColHandlerHighPrioActive = false
            end
            if cameraInfo.dofInfo == nil then
                g_depthOfFieldManager:reset()
            else
                g_depthOfFieldManager:applyInfo(cameraInfo.dofInfo)
            end
            self.activeCameraNode = cameraNode
        end
    end
end
function CameraManager:getActiveCamera()
    if g_isDevelopmentVersion and not entityExists(self.activeCameraNode) then
        local cameraInfo = self.cameraInfo[self.activeCameraNode]
        if cameraInfo == nil then
            Logging.devError("Trying to get already deleted camera node. Camera was not added to camera manager")
        else
            Logging.devError("Trying to get already deleted camera node (%s)\n\n%s", cameraInfo.name, cameraInfo.callstack)
        end
    end
    return self.activeCameraNode
end
function CameraManager:drawDebug()
    local shadowFocusBoxNode = self.cameraInfo[self.activeCameraNode]
    if shadowFocusBoxNode then
        shadowFocusBoxNode = self.cameraInfo[self.activeCameraNode].shadowFocusBoxNode
    end
    if shadowFocusBoxNode ~= nil then
        DebugSphere.renderShapeBoundingSphere(shadowFocusBoxNode, nil, nil, nil, getName(shadowFocusBoxNode) .. " (BV)")
    end
    renderText(0.45, 0.09, 0.01, string.format("Active: %s | Current: %s", getName(self.activeCameraNode), getName(getCamera())))
    renderText(0.45, 0.08, 0.01, string.format("shadowFocusBox: %s", shadowFocusBoxNode and getName(shadowFocusBoxNode) or "None"))
    renderText(0.45, 0.07, 0.01, string.format("lowResColHandlerHighPrio: %s", self.lowResColHandlerHighPrioActive))
    renderText(0.45, 0.06, 0.01, string.format("virtualTerrainUpdateEnabled: %s", self.virtualTerrainUpdateEnabled))
end
function CameraManager:consoleCommandToggleDebug()
    if g_debugManager:hasDrawable(self) then
        g_debugManager:removeDrawable(self)
        return "CameraManager debug mode: disabled"
    else
        g_debugManager:addDrawable(self)
        return "CameraManager debug mode: enabled"
    end
end
function CameraManager:consoleCommandSetFOV(fovYDeg)
    local camera = tonumber(fovYDeg)
    if camera == nil then
        return "Error: Command needs number argument. gsCameraFovSet fieldOfViewAngle (-1 to reset to default)"
    end
    local camera = self.activeCameraNode
    local cameraInfo = self.cameraInfo[camera]
    if cameraInfo == nil then
        return "Error: current camera not registered in camera manager"
    end
    if camera >= 0 then
        if cameraInfo.fovBackup ~= nil then
            ::l18::
            setFovY(camera, (math.rad(camera)))
            return string.format("Set camera %q fov to %.1f\194\176", getName(camera), camera)
        end
        if g_currentMission and g_localPlayer:getCurrentVehicle() ~= nil then
            local cameraBase = g_localPlayer:getCurrentVehicle():getActiveCamera()
            if cameraBase ~= nil then
                ::l23::
                cameraInfo.fovBackup = cameraBase.fovY or getFovY(camera)
                goto l18
            end
        end
        local fovYBackup = nil
        goto l23
    end
    if g_currentMission and g_localPlayer:getCurrentVehicle() ~= nil then
        local cameraBase = g_localPlayer:getCurrentVehicle():getActiveCamera()
        if cameraBase ~= nil then
            ::l11::
            cameraInfo.fovBackup = nil
            local cameraBase = getFovY(camera)
            if (cameraBase.fovY or cameraInfo.fovBackup) == nil or (cameraBase.fovY or cameraInfo.fovBackup) == cameraBase then
                return string.format("Camera %q still on original fov %.1f\194\176", getName(camera), (math.deg(cameraBase)))
            end
            setFovY(camera, fovYBackup)
            return string.format("Reset camera %q fov to original %.1f\194\176", getName(camera), (math.deg(fovYBackup)))
        end
    end
    local fovYBackup = nil
    goto l11
end
g_cameraManager = CameraManager.new()