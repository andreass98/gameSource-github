Event = {}
local Event_mt = Class(Event)
function Event.new(customMt, networkChannel)
    -- upvalues: (copy) Event_mt
    local self = setmetatable({}, customMt or Event_mt)
    self.networkChannel = networkChannel or NetworkNode.CHANNEL_SECONDARY
    self.queueCount = 0
    return self
end
function Event:delete() end
function Event:readStream(streamId, connection) end
function Event:writeStream(streamId, connection) end
function Event:run(connection) end