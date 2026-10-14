YarderTowerSetupActivatable = {}
local YarderTowerSetupActivatable_mt = Class(YarderTowerSetupActivatable)
function YarderTowerSetupActivatable.new(vehicle)
    -- upvalues: (copy) YarderTowerSetupActivatable_mt
    local self = {}
    setmetatable(self, YarderTowerSetupActivatable_mt)
    self.vehicle = vehicle
    self.activateText = ""
    return self
end
function YarderTowerSetupActivatable:registerCustomInput(_)
    _, self.actionEventIdToggle = g_inputBinding:registerActionEvent(InputAction.ACTIVATE_OBJECT, self, self.onToggleSetupMode, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(self.actionEventIdToggle, GS_PRIO_VERY_HIGH)
    _, self.actionEventIdSetTarget = g_inputBinding:registerActionEvent(InputAction.YARDER_SETUP_ROPE, self, self.onSetTarget, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(self.actionEventIdSetTarget, GS_PRIO_VERY_HIGH)
    self:updateActionEventTexts()
end
function YarderTowerSetupActivatable:removeCustomInput(_)
    g_inputBinding:removeActionEventsByTarget(self)
end
function YarderTowerSetupActivatable:onToggleSetupMode()
    if self.vehicle.spec_yarderTower.mainRope.isActive then
        self.vehicle:setYarderTargetActive(false)
        return
    else
        local isAllowed, warning = self.vehicle:getIsSetupModeChangeAllowed()
        if isAllowed then
            self.vehicle:setYarderSetupModeState(nil, true)
        elseif warning ~= nil then
            g_currentMission:showBlinkingWarning(warning, 2000)
        end
    end
end
function YarderTowerSetupActivatable:onSetTarget()
    self.vehicle:setYarderTargetActive(true)
end
function YarderTowerSetupActivatable:updateActionEventTexts()
    local spec = self.vehicle.spec_yarderTower
    local setTargetIsActive
    if spec.setupModeState then
        setTargetIsActive = spec.mainRope.isValid
        g_inputBinding:setActionEventText(self.actionEventIdToggle, spec.texts.actionCancelSetup)
        g_inputBinding:setActionEventText(self.actionEventIdSetTarget, spec.texts.actionSetTargetTree)
    else
        setTargetIsActive = false
        if spec.mainRope.isActive then
            g_inputBinding:setActionEventText(self.actionEventIdToggle, spec.texts.actionRemoveYarder)
        else
            g_inputBinding:setActionEventText(self.actionEventIdToggle, spec.texts.actionStartSetup)
        end
    end
    g_inputBinding:setActionEventActive(self.actionEventIdSetTarget, setTargetIsActive)
end
function YarderTowerSetupActivatable:getIsActivatable()
    return self.vehicle:getIsPlayerInYarderRange()
end
function YarderTowerSetupActivatable:activate() end
function YarderTowerSetupActivatable:deactivate() end
function YarderTowerSetupActivatable:getDistance(x, y, z)
    if self.vehicle.spec_yarderTower.controlTriggerNode == nil then
        return math.huge
    end
    local tx, ty, tz = getWorldTranslation(self.vehicle.spec_yarderTower.controlTriggerNode)
    return MathUtil.vector3Length(x - tx, y - ty, z - tz)
end
function YarderTowerSetupActivatable:draw() end