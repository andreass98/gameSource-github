DogPetEvent = {}
local DogPetEvent_mt = Class(DogPetEvent, Event)
InitStaticEventClass(DogPetEvent, "DogPetEvent")
function DogPetEvent.emptyNew()
    -- upvalues: (copy) DogPetEvent_mt
    return Event.new(DogPetEvent_mt)
end
function DogPetEvent.new(dog)
    local self = DogPetEvent.emptyNew()
    self.dog = dog
    return self
end
function DogPetEvent:readStream(streamId, connection)
    self.dog = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function DogPetEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.dog)
end
function DogPetEvent:run(_)
    if self.dog ~= nil then
        self.dog:pet()
    end
end