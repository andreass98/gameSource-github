PlaceablePreplacedInfoEvent = {}
local PlaceablePreplacedInfoEvent_mt = Class(PlaceablePreplacedInfoEvent, Event)
InitStaticEventClass(PlaceablePreplacedInfoEvent, "PlaceablePreplacedInfoEvent")
function PlaceablePreplacedInfoEvent.emptyNew()
    -- upvalues: (copy) PlaceablePreplacedInfoEvent_mt
    return Event.new(PlaceablePreplacedInfoEvent_mt)
end
function PlaceablePreplacedInfoEvent.new()
    return PlaceablePreplacedInfoEvent.emptyNew()
end
function PlaceablePreplacedInfoEvent.readStream(_, streamId, connection)
    g_currentMission.placeableSystem:readStreamPreplacedInfo(streamId, connection)
end
function PlaceablePreplacedInfoEvent.writeStream(_, streamId, connection)
    g_currentMission.placeableSystem:writeStreamPreplacedInfo(streamId, connection)
end