CameraFlightManager = {}
local CameraFlightManager_mt = Class(CameraFlightManager)
function CameraFlightManager.new()
    -- upvalues: (copy) CameraFlightManager_mt
    local self = setmetatable({}, CameraFlightManager_mt)
    self.cameraFlightIsActive = false
    self.abortCameraFlight = false
    return self
end
function CameraFlightManager:load(xmlFile)
    self.cameraFlights = {}
    local i = 0
    while true do
        local key = string.format("map.cameraFlights.cameraFlight(%d)", i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local flightType = getXMLString(xmlFile, key .. "#type")
        local speedScale = getXMLFloat(xmlFile, key .. "#speedScale")
        local filename = getXMLString(xmlFile, key .. "#filename")
        local i3dFilename = Utils.getFilename(filename, self.baseDirectory)
        local camera = createCamera("cameraFlight_" .. flightType, 1.0471975511965976, 1, 10000)
        local cameraFlight = CameraPath.createFromI3D(i3dFilename, speedScale, camera)
        if self.cameraFlights[flightType] == nil then
            self.cameraFlights[flightType] = cameraFlight
        end
        i = i + 1
    end
    g_inputBinding:registerActionEvent(InputAction.MENU, self, function()
        -- upvalues: (copy) self
        self.abortCameraFlight = true
        g_inputBinding:removeActionEventsByTarget(self)
    end, false, true, false, true)
end
function CameraFlightManager:delete()
    for _, cameraPath in pairs(self.cameraFlights) do
        cameraPath:delete()
    end
end
function CameraFlightManager:update(dt)
    if g_server ~= nil and (g_client ~= nil and (self.cameraFlights.careerStart ~= nil and not self.careerStartFlightPlayed)) then
        if g_localPlayer:getCurrentVehicle() ~= nil then
            self.abortCameraFlight = true
        end
        if self.abortCameraFlight then
            self.cameraFlights.careerStart:deactivate()
            self.careerStartFlightPlayed = true
            g_localPlayer.walkingIsLocked = false
            return
        end
        if not g_gui:getIsGuiVisible() then
            if cameraPath.time == 0 then
                cameraPath:activate()
            end
            cameraPath:update(dt)
            g_localPlayer.walkingIsLocked = true
            if cameraPath.time >= cameraPath.maxTime then
                self.careerStartFlightPlayed = true
                cameraPath:deactivate()
                g_localPlayer.walkingIsLocked = false
            end
        end
    end
end