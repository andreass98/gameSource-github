TransportMissionTrigger = {}
local TransportMissionTrigger_mt = Class(TransportMissionTrigger)
function TransportMissionTrigger.onCreate(_, id)
    g_currentMission:addNonUpdateable(TransportMissionTrigger.new(id))
end
function TransportMissionTrigger.new(id)
    -- upvalues: (copy) TransportMissionTrigger_mt
    local self = setmetatable({}, TransportMissionTrigger_mt)
    self.triggerId = id
    self.index = getUserAttribute(self.triggerId, "index")
    addTrigger(id, "triggerCallback", self)
    self.isEnabled = true
    g_missionManager:addTransportMissionTrigger(self)
    self:setMission(nil)
    return self
end
function TransportMissionTrigger:delete()
    removeTrigger(self.triggerId)
    g_missionManager:removeTransportMissionTrigger(self)
end
function TransportMissionTrigger:setMission(mission)
    self.mission = mission
    self:onMissionUpdated()
end
function TransportMissionTrigger:onMissionUpdated()
    setVisibility(self.triggerId, self.mission ~= nil and self.mission.status == MissionStatus.RUNNING)
end
function TransportMissionTrigger:triggerCallback(_, otherId, onEnter, onLeave, _)
    if self.isEnabled and self.mission ~= nil then
        if onEnter then
            self.mission:objectEnteredTrigger(self, otherId)
            return
        end
        if onLeave then
            self.mission:objectLeftTrigger(self, otherId)
        end
    end
end