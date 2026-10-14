DebugCameraClone = {}
DebugCameraClone.MAX_CAMERAS = 16
local DebugCameraClone_mt = Class(DebugCameraClone, Object)
InitStaticObjectClass(DebugCameraClone, "DebugCameraClone")
function DebugCameraClone.new(isServer, isClient, customMt)
    -- upvalues: (copy) DebugCameraClone_mt
    local self = Object.new(isServer, isClient, customMt or DebugCameraClone_mt)
    if isServer then
        self.cameras = {}
        local i = 0
        for i = i, DebugCameraClone.MAX_CAMERAS + 1 do
            self.cameras[i] = {
                ["x"] = 0,
                ["y"] = 0,
                ["z"] = 0,
                ["qx"] = 0,
                ["qy"] = 0,
                ["qz"] = 0,
                ["qw"] = 1,
                ["fovY"] = 1.0471975511965976,
                ["nearClip"] = 0.1,
                ["farClip"] = 5000
            }
        end
    end
    self.interpolatorPosition = InterpolatorPosition.new(0, 0, 0)
    self.interpolatorQuaternion = InterpolatorQuaternion.new(0, 0, 0, 1)
    self.interpolatorTime = InterpolationTime.new(1.2)
    self.fovY = 1.0471975511965976
    self.nearClip = 0.1
    self.farClip = 5000
    self.dirtyFlag = self:getNextDirtyFlag()
    self.camera = createCamera("DebugCameraClone", 1.0471975511965976, 1, 10000)
    self.cameraIndex = tonumber(StartParams.getValue("debugCameraCloneIndex"))
    g_cameraManager:addCamera(self.camera, nil, false)
    self.connectionToCameraIndex = {}
    self.lastCamera = g_cameraManager:getActiveCamera()
    addConsoleCommand("gsDebugCameraCloneSetIndex", "Sets the camera clone index", "consoleCommandSetCameraCloneIndex", self)
    return self
end
function DebugCameraClone:delete()
    removeConsoleCommand("gsDebugCameraCloneSetIndex")
end
function DebugCameraClone:readUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            local x = streamReadFloat32(streamId)
            local y = streamReadFloat32(streamId)
            local z = streamReadFloat32(streamId)
            local qx = streamReadFloat32(streamId)
            local qy = streamReadFloat32(streamId)
            local qz = streamReadFloat32(streamId)
            local qw = streamReadFloat32(streamId)
            local fovY = streamReadFloat32(streamId)
            local nearClip = streamReadFloat32(streamId)
            local farClip = streamReadFloat32(streamId)
            self.interpolatorPosition:setTargetPosition(x, y, z)
            self.interpolatorQuaternion:setTargetQuaternion(qx, qy, qz, qw)
            self.interpolatorTime:startNewPhaseNetwork()
            self.fovY = fovY
            self.nearClip = nearClip
            self.farClip = farClip
            return
        end
    else
        local x = 1
        for qy, qz in ipairs(g_server.clients) do
            if qz == streamId then
                x = qy
                break
            end
        end
        if streamReadBool(streamId) then
            self.connectionToCameraIndex[connection] = streamReadUIntN(streamId, 5)
        else
            self.connectionToCameraIndex[connection] = nil
        end
        local y = self.cameras[x]
        y.x = streamReadFloat32(streamId)
        y.y = streamReadFloat32(streamId)
        y.z = streamReadFloat32(streamId)
        y.qx = streamReadFloat32(streamId)
        y.qy = streamReadFloat32(streamId)
        y.qz = streamReadFloat32(streamId)
        y.qw = streamReadFloat32(streamId)
        y.fovY = streamReadFloat32(streamId)
        y.nearClip = streamReadFloat32(streamId)
        y.farClip = streamReadFloat32(streamId)
    end
end
function DebugCameraClone:writeUpdateStream(streamId, connection, _)
    if connection:getIsServer() then
        local cameraIndex = g_cameraManager:getActiveCamera()
        local data, y, z = getWorldTranslation(cameraIndex)
        local qx, qy, qz, qw = getWorldQuaternion(cameraIndex)
        local fovY = getFovY(cameraIndex)
        local nearClip = getNearClip(cameraIndex)
        local farClip = getFarClip(cameraIndex)
        if streamWriteBool(streamId, self.cameraIndex ~= nil) then
            streamWriteUIntN(streamId, self.cameraIndex, 5)
        end
        streamWriteFloat32(streamId, data)
        streamWriteFloat32(streamId, y)
        streamWriteFloat32(streamId, z)
        streamWriteFloat32(streamId, qx)
        streamWriteFloat32(streamId, qy)
        streamWriteFloat32(streamId, qz)
        streamWriteFloat32(streamId, qw)
        streamWriteFloat32(streamId, fovY)
        streamWriteFloat32(streamId, nearClip)
        streamWriteFloat32(streamId, farClip)
    else
        local data = self.cameras[self.connectionToCameraIndex[connection]]
        if streamWriteBool(streamId, data ~= nil) then
            streamWriteFloat32(streamId, data.x)
            streamWriteFloat32(streamId, data.y)
            streamWriteFloat32(streamId, data.z)
            streamWriteFloat32(streamId, data.qx)
            streamWriteFloat32(streamId, data.qy)
            streamWriteFloat32(streamId, data.qz)
            streamWriteFloat32(streamId, data.qw)
            streamWriteFloat32(streamId, data.fovY)
            streamWriteFloat32(streamId, data.nearClip)
            streamWriteFloat32(streamId, data.farClip)
            return
        end
    end
end
function DebugCameraClone:update(dt)
    self:raiseDirtyFlags(self.dirtyFlag)
    self:raiseActive()
    if self.isServer then
        local data = self.cameras[0]
        local camera = g_cameraManager:getActiveCamera()
        local x, y, z = getWorldTranslation(camera)
        data.x = x
        data.y = y
        data.z = z
        local x, y, z, qx = getWorldQuaternion(camera)
        data.qx = x
        data.qy = y
        data.qz = z
        data.qw = qx
        data.fovY = getFovY(camera)
        data.nearClip = getNearClip(camera)
        data.farClip = getFarClip(camera)
    end
    local data = g_cameraManager:getActiveCamera()
    if data ~= self.camera then
        self.lastCamera = data
    end
    if self.cameraIndex ~= nil then
        self.interpolatorTime:update(dt)
        local camera = self.interpolatorTime:getAlpha()
        local x, y, z = self.interpolatorPosition:getInterpolatedValues(camera)
        local qx, qy, qz, qw = self.interpolatorQuaternion:getInterpolatedValues(camera)
        setWorldTranslation(self.camera, x, y, z)
        setWorldQuaternion(self.camera, qx, qy, qz, qw)
        setFovY(self.camera, self.fovY)
        setNearClip(self.camera, self.nearClip)
        setFarClip(self.camera, self.farClip)
        g_cameraManager:setActiveCamera(self.camera)
    end
    local camera, x, y = getWorldTranslation(g_cameraManager:getActiveCamera())
    for qz, qw in pairs(g_currentMission.players) do
        if qw ~= g_localPlayer then
            local a, _, c = getWorldTranslation(qw.graphicsRootNode)
            local distance = MathUtil.vector2Length(camera - a, y - c)
            local shouldHide = false
            if self.cameraIndex ~= nil then
                shouldHide = distance < 1
            end
            setVisibility(qw.graphicsRootNode, not shouldHide)
        end
    end
end
function DebugCameraClone:consoleCommandSetCameraCloneIndex(index)
    index = tonumber(index)
    if index ~= nil and (index < 0 or DebugCameraClone.MAX_CAMERAS < index) then
        index = nil
    end
    self.cameraIndex = index
    if self.lastCamera ~= nil and entityExists(self.lastCamera) then
        g_cameraManager:setActiveCamera(self.lastCamera)
    end
end