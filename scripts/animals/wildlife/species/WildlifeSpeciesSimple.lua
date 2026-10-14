WildlifeSpeciesSimple = {}
local WildlifeSpeciesSimple_mt = Class(WildlifeSpeciesSimple, WildlifeSpecies)
g_xmlManager:addInitSchemaFunction(function()
    local xmlSchema = WildlifeSpecies.xmlSchema
    WildlifeInstanceGraphics.registerXMLPaths(xmlSchema, "species")
    WildlifeInstanceSounds.registerXMLPaths(xmlSchema)
    WildlifeInstanceMover.registerXMLPaths(xmlSchema)
    WildlifeFollowState.registerXMLPaths(xmlSchema)
    WildlifeFleeState.registerXMLPaths(xmlSchema)
    WildlifeWanderState.registerXMLPaths(xmlSchema)
    WildlifeIdleState.registerXMLPaths(xmlSchema)
end)
function WildlifeSpeciesSimple.new(customMt)
    -- upvalues: (copy) WildlifeSpeciesSimple_mt
    local self = WildlifeSpecies.new(customMt or WildlifeSpeciesSimple_mt)
    self.movementAttributes = WildlifeInstanceMover.DEFAULT_ATTRIBUTES
    self.graphicalAttributes = nil
    self.soundAttributes = nil
    self.behaviourAttributes = {}
    return self
end
function WildlifeSpeciesSimple:getInstanceConstructor()
    return WildlifeInstanceSimple.new
end
function WildlifeSpeciesSimple:loadFromXML(xmlFile, baseDirectory)
    if not WildlifeSpeciesSimple:superClass().loadFromXML(self, xmlFile, baseDirectory) then
        return false
    end
    self.behaviourAttributes.flee = WildlifeFleeState.loadAttributesTable(xmlFile)
    self.behaviourAttributes.wander = WildlifeWanderState.loadAttributesTable(xmlFile)
    self.behaviourAttributes.idle = WildlifeIdleState.loadAttributesTable(xmlFile)
    self.behaviourAttributes.follow = WildlifeFollowState.loadAttributesTable(xmlFile)
    self.graphicalAttributes = WildlifeInstanceGraphics.loadAttributesTable(xmlFile)
    self.soundAttributes = WildlifeInstanceSounds.loadAttributesTable(xmlFile)
    self.movementAttributes = WildlifeInstanceMover.loadAttributesTable(xmlFile)
    return self.graphicalAttributes ~= nil and self.soundAttributes ~= nil
end
function WildlifeSpeciesSimple:delete()
    if self.soundAttributes ~= nil then
        WildlifeInstanceSounds.deleteAttributesTable(self.soundAttributes)
    end
    WildlifeSpeciesSimple:superClass().delete(self)
end