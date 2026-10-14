FoldableStepsChangeStateEvent = {}
local FoldableStepsChangeStateEvent_mt = Class(FoldableStepsChangeStateEvent, Event)
InitStaticEventClass(FoldableStepsChangeStateEvent, "FoldableStepsChangeStateEvent")
function FoldableStepsChangeStateEvent.emptyNew()
    -- upvalues: (copy) FoldableStepsChangeStateEvent_mt
    return Event.new(FoldableStepsChangeStateEvent_mt)
end
function FoldableStepsChangeStateEvent.new(object, targetState)
    local self = FoldableStepsChangeStateEvent.emptyNew()
    self.object = object
    self.targetState = targetState
    return self
end
function FoldableStepsChangeStateEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.targetState = streamReadUIntN(streamId, FoldableSteps.STATE_NUM_BITS)
    self:run(connection)
end
function FoldableStepsChangeStateEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.targetState, FoldableSteps.STATE_NUM_BITS)
end
function FoldableStepsChangeStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setFoldableStepsFoldState(self.targetState, true)
    end
end
function FoldableStepsChangeStateEvent.sendEvent(vehicle, targetState, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(FoldableStepsChangeStateEvent.new(vehicle, targetState), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(FoldableStepsChangeStateEvent.new(vehicle, targetState))
    end
end