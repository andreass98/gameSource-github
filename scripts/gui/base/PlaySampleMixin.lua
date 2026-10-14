PlaySampleMixin = {}
local PlaySampleMixin_mt = Class(PlaySampleMixin, GuiMixin)
local function NO_CALLBACK() end
function PlaySampleMixin.new()
    -- upvalues: (copy) PlaySampleMixin_mt
    return GuiMixin.new(PlaySampleMixin_mt, PlaySampleMixin)
end
function PlaySampleMixin:addTo(guiElement)
    -- upvalues: (copy) NO_CALLBACK
    if not PlaySampleMixin:superClass().addTo(self, guiElement) then
        return false
    end
    guiElement.setPlaySampleCallback = PlaySampleMixin.setPlaySampleCallback
    guiElement.playSample = PlaySampleMixin.playSample
    guiElement.disablePlaySample = PlaySampleMixin.disablePlaySample
    guiElement[PlaySampleMixin].playSampleCallback = NO_CALLBACK
    return true
end
function PlaySampleMixin.setPlaySampleCallback(guiElement, callback)
    guiElement[PlaySampleMixin].playSampleCallback = callback
end
function PlaySampleMixin.playSample(guiElement, sampleName)
    if not guiElement.soundDisabled then
        guiElement[PlaySampleMixin].playSampleCallback(sampleName)
    end
end
function PlaySampleMixin.disablePlaySample(guiElement)
    -- upvalues: (copy) NO_CALLBACK
    guiElement[PlaySampleMixin].playSampleCallback = NO_CALLBACK
end
function PlaySampleMixin.clone(_, srcGuiElement, dstGuiElement)
    dstGuiElement[PlaySampleMixin].playSampleCallback = srcGuiElement[PlaySampleMixin].playSampleCallback
end