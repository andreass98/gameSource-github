MotorGearShiftEvent = {}
MotorGearShiftEvent.TYPE_SHIFT_UP = 1
MotorGearShiftEvent.TYPE_SHIFT_DOWN = 2
MotorGearShiftEvent.TYPE_SELECT_GEAR = 3
MotorGearShiftEvent.TYPE_SHIFT_GROUP_UP = 4
MotorGearShiftEvent.TYPE_SHIFT_GROUP_DOWN = 5
MotorGearShiftEvent.TYPE_SELECT_GROUP = 6
MotorGearShiftEvent.TYPE_DIRECTION_CHANGE = 7
MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_POS = 8
MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_NEG = 9
local MotorGearShiftEvent_mt = Class(MotorGearShiftEvent, Event)
InitStaticEventClass(MotorGearShiftEvent, "MotorGearShiftEvent")
function MotorGearShiftEvent.emptyNew()
    -- upvalues: (copy) MotorGearShiftEvent_mt
    return Event.new(MotorGearShiftEvent_mt)
end
function MotorGearShiftEvent.new(vehicle, shiftType, shiftValue)
    local self = MotorGearShiftEvent.emptyNew()
    self.vehicle = vehicle
    self.shiftType = shiftType
    self.shiftValue = shiftValue
    return self
end
function MotorGearShiftEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.shiftType = streamReadUIntN(streamId, 4)
    if self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR or self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GROUP then
        self.shiftValue = streamReadUIntN(streamId, 5)
    end
    self:run(connection)
end
function MotorGearShiftEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.shiftType, 4)
    if self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR or self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GROUP then
        streamWriteUIntN(streamId, self.shiftValue, 5)
    end
end
function MotorGearShiftEvent:run(_)
    local vehicle = self.vehicle
    if vehicle ~= nil and vehicle:getIsSynchronized() then
        local spec = vehicle.spec_motorized
        if spec ~= nil then
            if self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_UP then
                spec.motor:shiftGear(true)
                return
            end
            if self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_DOWN then
                spec.motor:shiftGear(false)
                return
            end
            if self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR then
                spec.motor:selectGear(self.shiftValue, self.shiftValue ~= 0)
                return
            end
            if self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_GROUP_UP then
                spec.motor:shiftGroup(true)
                return
            end
            if self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_GROUP_DOWN then
                spec.motor:shiftGroup(false)
                return
            end
            if self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GROUP then
                spec.motor:selectGroup(self.shiftValue, self.shiftValue ~= 0)
                return
            end
            if self.shiftType == MotorGearShiftEvent.TYPE_DIRECTION_CHANGE then
                spec.motor:changeDirection()
                return
            end
            if self.shiftType == MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_POS then
                spec.motor:changeDirection(1)
                return
            end
            if self.shiftType == MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_NEG then
                spec.motor:changeDirection(-1)
            end
        end
    end
end
function MotorGearShiftEvent.sendToServer(vehicle, shiftType, shiftValue)
    if g_client ~= nil then
        g_client:getServerConnection():sendEvent(MotorGearShiftEvent.new(vehicle, shiftType, shiftValue))
    end
end