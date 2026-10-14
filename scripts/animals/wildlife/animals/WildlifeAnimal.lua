WildlifeAnimal = {}
local WildlifeAnimal_mt = Class(WildlifeAnimal)
function WildlifeAnimal.new(customMt)
    -- upvalues: (copy) WildlifeAnimal_mt
    local self = setmetatable({}, customMt or WildlifeAnimal_mt)
    self.rootNode = createTransformGroup("WildlifeAnimal")
    link(getRootNode(), self.rootNode)
    return self
end
function WildlifeAnimal:delete()
    delete(self.rootNode)
end
function WildlifeAnimal:calculateDistanceFrom(positionX, positionZ)
    local x, _, z = getWorldTranslation(self.rootNode)
    return MathUtil.vector2Length(positionX - x, positionZ - z)
end
function WildlifeAnimal:spawnAt(x, y, z)
    setWorldTranslation(self.rootNode, x, y, z)
    setVisibility(self.rootNode, true)
end
function WildlifeAnimal:despawn()
    setVisibility(self.rootNode, false)
end
function WildlifeAnimal:update(dt) end
function WildlifeAnimal:drawDebug() end