CameraPath = {}
local CameraPath_mt = Class(CameraPath)
function CameraPath.new(posAnimCurve, rotAnimCurve, speedAnimCurve, speedScale, camera, maxTime, finishedCallback)
    -- upvalues: (copy) CameraPath_mt
    local self = setmetatable({}, CameraPath_mt)
    self.posAnimCurve = posAnimCurve
    self.rotAnimCurve = rotAnimCurve
    self.speedAnimCurve = speedAnimCurve
    self.speedScale = speedScale
    self.time = 0
    self.camera = camera
    self.overriddenCamera = nil
    self.maxTime = maxTime
    self.finishedCallback = finishedCallback
    g_cameraManager:addCamera(camera, nil, false)
    return self
end
function CameraPath:delete()
    g_cameraManager:removeCamera(self.camera)
    delete(self.camera)
end
function CameraPath.createFromI3D(filename, speedScale, camera)
    local rootNode = g_i3DManager:loadI3DFile(filename, false, false)
    local positionNodes = getChild(rootNode, "positions")
    if positionNodes == 0 then
        printError("Error: failed to load camera path: " .. filename .. ". No positions found.")
        return nil
    end
    local posAnimCurve = AnimCurve.new(catmullRomInterpolator3, 3)
    local rotAnimCurve = AnimCurve.new(quaternionInterpolator2, 3)
    local speedAnimCurve = AnimCurve.new(catmullRomInterpolator1, 3)
    local t = 0
    local lastX = nil
    local lastY = nil
    local lastZ = nil
    local i = 0
    local numSegments = getNumOfChildren(positionNodes) - 1
    local segmentTimes = 1
    for i = i, numSegments, segmentTimes do
        local node = getChildAt(positionNodes, i)
        local x, y, z = getTranslation(node)
        local rx, ry, rz = getRotation(node)
        local speed, _, _ = getScale(node)
        if i > 0 then
            t = t + MathUtil.vector3Length(x - lastX, y - lastY, z - lastZ)
        end
        posAnimCurve:addKeyframe({
            ["time"] = t,
            ["x"] = x,
            ["y"] = y,
            ["z"] = z
        })
        local dist, qy, qz, qw = mathEulerToQuaternion(rx, ry, rz)
        rotAnimCurve:addKeyframe({
            ["time"] = t,
            ["x"] = dist,
            ["y"] = qy,
            ["z"] = qz,
            ["w"] = qw
        })
        speedAnimCurve:addKeyframe({
            ["time"] = t,
            ["v"] = speed
        })
    end
    local numSegments = 32
    local segmentTimes = {}
    local t = 0
    local x = 1
    local i = #posAnimCurve.keyframes - 1
    local node = 1
    for x = x, i, node do
        local y = posAnimCurve.keyframes[x]
        local z = posAnimCurve.keyframes[x + 1]
        local rx = 0
        local ry, rz, speed = posAnimCurve:getFromKeyframes(y, z, x, x + 1, 1)
        segmentTimes[_] = 0
        local qy = 1
        for qy = qy, (x - 1) * 33 + 1 do
            local qz, qw, z = posAnimCurve:getFromKeyframes(y, z, x, x + 1, 1 - qy / 32)
            rx = rx + MathUtil.vector3Length(qz - ry, qw - rz, z - speed)
            segmentTimes[_ + qy] = rx
        end
        t = t + rx
        posAnimCurve.keyframes[x + 1].time = t
        rotAnimCurve.keyframes[x + 1].time = t
        speedAnimCurve.keyframes[x + 1].time = t
    end
    posAnimCurve.segmentTimes = segmentTimes
    posAnimCurve.numTimesPerKeyframe = numSegments
    rotAnimCurve.segmentTimes = segmentTimes
    rotAnimCurve.numTimesPerKeyframe = numSegments
    speedAnimCurve.segmentTimes = segmentTimes
    speedAnimCurve.numTimesPerKeyframe = numSegments
    posAnimCurve.maxTime = t
    rotAnimCurve.maxTime = t
    speedAnimCurve.maxTime = t
    delete(rootNode)
    return CameraPath.new(posAnimCurve, rotAnimCurve, speedAnimCurve, speedScale, camera, t)
end
function CameraPath:update(dt)
    local speedScale = self.speedScale
    if self.speedAnimCurve ~= nil then
        speedScale = speedScale * self.speedAnimCurve:get(self.time)
    end
    self.time = self.time + dt * speedScale
    self:placeCamera()
    local currentCamera = g_cameraManager:getActiveCamera()
    if currentCamera ~= self.camera then
        self.overriddenCamera = currentCamera
        g_cameraManager:setActiveCamera(self.camera)
    end
    if self.finishedCallback ~= nil and self.time > self.maxTime then
        self.finishedCallback()
    end
end
function CameraPath:placeCamera()
    local x, y, z = self.posAnimCurve:get(self.time)
    local qx, qy, qz, qw = self.rotAnimCurve:get(self.time)
    setTranslation(self.camera, x, y, z)
    setQuaternion(self.camera, qx, qy, qz, qw)
end
function CameraPath:activate()
    self:placeCamera()
    self.overriddenCamera = g_cameraManager:getActiveCamera()
    g_cameraManager:setActiveCamera(self.camera)
end
function CameraPath:deactivate()
    self.time = 0
    if self.overriddenCamera ~= nil then
        g_cameraManager:setActiveCamera(self.overriddenCamera)
    end
    g_currentMission:removeUpdateable(self)
end