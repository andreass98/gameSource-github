SlotSystemUpdateEvent = {}
local SlotSystemUpdateEvent_mt = Class(SlotSystemUpdateEvent, Event)
InitStaticEventClass(SlotSystemUpdateEvent, "SlotSystemUpdateEvent")
function SlotSystemUpdateEvent.emptyNew()
    -- upvalues: (copy) SlotSystemUpdateEvent_mt
    return Event.new(SlotSystemUpdateEvent_mt)
end
function SlotSystemUpdateEvent.new(slotLimit)
    local self = SlotSystemUpdateEvent.emptyNew()
    self.slotLimit = slotLimit
    assert(g_server ~= nil, "Server->client event")
    return self
end
function SlotSystemUpdateEvent:readStream(streamId, connection)
    local slotLimit = streamReadUInt16(streamId)
    self.slotLimit = slotLimit == 0 and math.huge or slotLimit
    self:run(connection)
end
function SlotSystemUpdateEvent:writeStream(streamId, _)
    streamWriteUInt16(streamId, self.slotLimit == math.huge and 0 or self.slotLimit)
end
function SlotSystemUpdateEvent:run(_)
    g_currentMission.slotSystem:setSlotLimit(self.slotLimit)
end