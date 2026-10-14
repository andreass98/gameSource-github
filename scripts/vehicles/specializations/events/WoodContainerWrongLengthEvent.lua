WoodContainerWrongLengthEvent = {}
local WoodContainerWrongLengthEvent_mt = Class(WoodContainerWrongLengthEvent, Event)
InitStaticEventClass(WoodContainerWrongLengthEvent, "WoodContainerWrongLengthEvent")
function WoodContainerWrongLengthEvent.emptyNew()
    -- upvalues: (copy) WoodContainerWrongLengthEvent_mt
    return Event.new(WoodContainerWrongLengthEvent_mt)
end
function WoodContainerWrongLengthEvent.new(object, _, _, _, _)
    local self = WoodContainerWrongLengthEvent.emptyNew()
    self.object = object
    return self
end
function WoodContainerWrongLengthEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function WoodContainerWrongLengthEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
end
function WoodContainerWrongLengthEvent:run(_)
    if self.object ~= nil and (self.object:getIsSynchronized() and (g_currentMission:getFarmId() == self.object:getOwnerFarmId() and calcDistanceFrom(getCamera(), self.object.rootNode) < 40)) then
        local spec = self.object.spec_woodContainer
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(spec.texts.warningWoodContainerWrongLength, spec.targetLength))
    end
end