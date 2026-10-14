AnimalHusbandryNoMorePalletSpaceEvent = {}
local AnimalHusbandryNoMorePalletSpaceEvent_mt = Class(AnimalHusbandryNoMorePalletSpaceEvent, Event)
InitStaticEventClass(AnimalHusbandryNoMorePalletSpaceEvent, "AnimalHusbandryNoMorePalletSpaceEvent")
function AnimalHusbandryNoMorePalletSpaceEvent.emptyNew()
    -- upvalues: (copy) AnimalHusbandryNoMorePalletSpaceEvent_mt
    return Event.new(AnimalHusbandryNoMorePalletSpaceEvent_mt)
end
function AnimalHusbandryNoMorePalletSpaceEvent.new(animalHusbandry, fillTypeIndex)
    local self = AnimalHusbandryNoMorePalletSpaceEvent.emptyNew()
    self.animalHusbandry = animalHusbandry
    self.fillTypeIndex = fillTypeIndex
    return self
end
function AnimalHusbandryNoMorePalletSpaceEvent:readStream(streamId, connection)
    self.animalHusbandry = NetworkUtil.readNodeObject(streamId)
    self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
    self:run(connection)
end
function AnimalHusbandryNoMorePalletSpaceEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.animalHusbandry)
    streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
end
function AnimalHusbandryNoMorePalletSpaceEvent:run(connection)
    if connection:getIsServer() and self.animalHusbandry ~= nil then
        self.animalHusbandry:showPalletBlockedWarning(self.fillTypeIndex)
    end
end