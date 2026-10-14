DogPetActivatable = {}
local DogPetActivatable_mt = Class(DogPetActivatable)
function DogPetActivatable.new(dog)
    -- upvalues: (copy) DogPetActivatable_mt
    local self = setmetatable({}, DogPetActivatable_mt)
    self.dog = dog
    self.activateText = g_i18n:getText("action_petAnimal")
    return self
end
function DogPetActivatable:getIsActivatable()
    return true
end
function DogPetActivatable:getDistance(posX, posY, posZ)
    return self.dog:getDistanceTo(posX, posY, posZ)
end
function DogPetActivatable:run()
    self.dog:pet()
end