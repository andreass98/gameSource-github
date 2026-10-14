FillUnitUnloadedEvent = {}
local FillUnitUnloadedEvent_mt = Class(FillUnitUnloadedEvent, Event)
InitStaticEventClass(FillUnitUnloadedEvent, "FillUnitUnloadedEvent")
function FillUnitUnloadedEvent.emptyNew()
    -- upvalues: (copy) FillUnitUnloadedEvent_mt
    return Event.new(FillUnitUnloadedEvent_mt)
end
function FillUnitUnloadedEvent.new(object, pallet, showWarning, result)
    local self = FillUnitUnloadedEvent.emptyNew()
    self.object = object
    self.pallet = pallet
    self.showWarning = showWarning
    self.result = result
    return self
end
function FillUnitUnloadedEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    if streamReadBool(streamId) then
        self.pallet = NetworkUtil.readNodeObject(streamId)
        local paramsXZ = g_currentMission.vehicleXZPosHighPrecisionCompressionParams
        self.x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
        self.y = NetworkUtil.readCompressedWorldPosition(streamId, g_currentMission.vehicleYPosHighPrecisionCompressionParams)
        self.z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
        local x_rot = NetworkUtil.readCompressedAngle(streamId)
        local y_rot = NetworkUtil.readCompressedAngle(streamId)
        local z_rot = NetworkUtil.readCompressedAngle(streamId)
        self.qx, self.qy, self.qz, self.qw = mathEulerToQuaternion(x_rot, y_rot, z_rot)
    else
        self.showWarning = streamReadBool(streamId)
        local paramsXZ = streamReadUIntN(streamId, 2)
        if paramsXZ == 2 then
            self.result = true
        elseif paramsXZ == 1 then
            self.result = false
        end
    end
    self:run(connection)
end
function FillUnitUnloadedEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    local paramsXZ = streamWriteBool
    local component = self.pallet ~= nil
    if paramsXZ(streamId, component) then
        NetworkUtil.writeNodeObject(streamId, self.pallet)
        local paramsXZ = g_currentMission.vehicleXZPosHighPrecisionCompressionParams
        local component = self.pallet.components[1]
        local x, y, z = getWorldTranslation(component.node)
        local x_rot, y_rot, z_rot = getWorldRotation(component.node)
        NetworkUtil.writeCompressedWorldPosition(streamId, x, paramsXZ)
        NetworkUtil.writeCompressedWorldPosition(streamId, y, g_currentMission.vehicleYPosHighPrecisionCompressionParams)
        NetworkUtil.writeCompressedWorldPosition(streamId, z, paramsXZ)
        NetworkUtil.writeCompressedAngle(streamId, x_rot)
        NetworkUtil.writeCompressedAngle(streamId, y_rot)
        NetworkUtil.writeCompressedAngle(streamId, z_rot)
        return
    else
        local paramsXZ = streamWriteBool
        local component = self.showWarning == true
        paramsXZ(streamId, component)
        if self.result == nil then
            streamWriteUIntN(streamId, 0, 2)
        else
            streamWriteUIntN(streamId, self.result == true and 2 or 1, 2)
        end
    end
end
function FillUnitUnloadedEvent:run(_)
    if self.object ~= nil and self.object:getIsSynchronized() then
        if self.pallet ~= nil and self.pallet:getIsSynchronized() then
            if self.pallet.unmount ~= nil then
                self.pallet:unmount(true)
            end
            self.pallet:setWorldPositionQuaternion(self.x, self.y, self.z, self.qx, self.qy, self.qz, self.qw, 1, true)
            SpecializationUtil.raiseEvent(self.object, "onFillUnitUnloadPallet", self.pallet)
            return
        end
        if self.showWarning and self.object:getIsActiveForInput(true) then
            g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, g_i18n:getText("fillUnit_unload_nospace"))
        end
        if self.result ~= nil then
            SpecializationUtil.raiseEvent(self.object, "onFillUnitUnloaded", self.result)
        end
    end
end