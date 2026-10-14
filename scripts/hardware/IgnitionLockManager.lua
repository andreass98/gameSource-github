IgnitionLockManager = {}
IgnitionLockManager.DEVICE_NAME = "Ignition Lock"
IgnitionLockManager.DEBUG_ENABLED = false
local IgnitionLockManager_mt = Class(IgnitionLockManager, AbstractManager)
function IgnitionLockManager.new(customMt)
    -- upvalues: (copy) IgnitionLockManager_mt
    local self = setmetatable({}, customMt or IgnitionLockManager_mt)
    self:reset()
    addConsoleCommand("gsIgnitionLockDebug", "Toggles the iginition lock debug view", "consoleCommandToggleDebug", self, nil, false)
    self.state = IgnitionLockState.UNKNOWN
    self.initialized = false
    return self
end
function IgnitionLockManager:reset()
    self.ignitionLocks = {}
    self.initialized = false
end
function IgnitionLockManager:tryToAddDevice(internalId, engineDeviceId, deviceName)
    if deviceName ~= IgnitionLockManager.DEVICE_NAME then
        return false
    end
    setGamepadDeadzone(0, internalId, 0)
    table.insert(self.ignitionLocks, {
        ["internalId"] = internalId,
        ["engineDeviceId"] = engineDeviceId
    })
    return true
end
function IgnitionLockManager:initializeState()
    local ignitionLock = self.ignitionLocks[1]
    setGamepadDeadzone(0, ignitionLock.internalId, 0)
    local axisValue = getInputAxis(0, ignitionLock.internalId)
    local sign = math.sign(axisValue)
    if sign ~= 0 and axisValue <= 0.1 then
        if sign <= 0 then
            self:setState(IgnitionLockState.OFF)
        elseif axisValue < 0.01 then
            self:setState(IgnitionLockState.IGNITION)
        elseif axisValue >= 0.01 and axisValue < 0.1 then
            self:setState(IgnitionLockState.START)
        end
        self.initialized = true
    end
end
function IgnitionLockManager:update(_)
    local ignitionLock = self.ignitionLocks[1]
    if ignitionLock ~= nil then
        if not self.initialized then
            self:initializeState()
        end
        local offToIgnition = getInputButton(0, ignitionLock.internalId) > 0
        local ignitionToOff = getInputButton(1, ignitionLock.internalId) > 0
        local ignitionToStart = getInputButton(2, ignitionLock.internalId) > 0
        local startToIgnition = getInputButton(3, ignitionLock.internalId) > 0
        if offToIgnition or startToIgnition then
            self:setState(IgnitionLockState.IGNITION)
            return
        end
        if ignitionToOff then
            self:setState(IgnitionLockState.OFF)
            return
        end
        if ignitionToStart then
            self:setState(IgnitionLockState.START)
        end
    end
end
function IgnitionLockManager:setState(state)
    if state ~= self.state then
        self.state = state
    end
end
function IgnitionLockManager:getState()
    return self.state
end
function IgnitionLockManager:getIsAvailable()
    return #self.ignitionLocks > 0
end
function IgnitionLockManager:drawDebug()
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(true)
    renderText(0.025, 0.93, 0.015, string.format("Ignition Lock - Global State: %s", IgnitionLockState.getName(self.state)))
    setTextBold(false)
    local posY = 0.91
    for k, ignitionLock in ipairs(self.ignitionLocks) do
        renderText(0.025, posY - 0, 0.012, string.format("Ignition Lock %s", ignitionLock.engineDeviceId));
        (function(x, y, size, internalId, buttonId)
            local value = getInputButton(buttonId, internalId)
            local physical = getGamepadButtonPhysicalName(buttonId, internalId)
            renderText(x, y, size, string.format("Button %d: %s | %s", buttonId, physical, (tostring(value > 0))))
        end)(0.03, posY - 0.016, 0.012, ignitionLock.internalId, 0)
        renderButton(0.03, posY - 0.032, 0.012, ignitionLock.internalId, 1)
        renderButton(0.03, posY - 0.048, 0.012, ignitionLock.internalId, 2)
        renderButton(0.03, posY - 0.064, 0.012, ignitionLock.internalId, 3)
        renderText(0.03, posY - 0.08 - 0.002, 0.012, string.format("Axis 0: %1.4f", getInputAxis(0, ignitionLock.internalId)))
        posY = posY - 0.12
    end
end
function IgnitionLockManager:consoleCommandToggleDebug()
    IgnitionLockManager.DEBUG_ENABLED = not IgnitionLockManager.DEBUG_ENABLED
    if IgnitionLockManager.DEBUG_ENABLED then
        g_debugManager:addDrawable(self)
    else
        g_debugManager:removeDrawable(self)
    end
end
g_ignitionLockManager = IgnitionLockManager.new()