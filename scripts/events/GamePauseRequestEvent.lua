GamePauseRequestEvent = {}
local GamePauseRequestEvent_mt = Class(GamePauseRequestEvent, Event)
InitStaticEventClass(GamePauseRequestEvent, "GamePauseRequestEvent")
function GamePauseRequestEvent.emptyNew()
    -- upvalues: (copy) GamePauseRequestEvent_mt
    return Event.new(GamePauseRequestEvent_mt)
end
function GamePauseRequestEvent.new(pause)
    local self = GamePauseRequestEvent.emptyNew()
    self.pause = pause
    return self
end
function GamePauseRequestEvent:readStream(streamId, connection)
    self.pause = streamReadBool(streamId)
    self:run(connection)
end
function GamePauseRequestEvent:writeStream(streamId, _)
    streamWriteBool(streamId, self.pause)
end
function GamePauseRequestEvent:run(_)
    g_currentMission:setManualPause(self.pause)
end