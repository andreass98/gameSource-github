IndexChangeSubjectMixin = {}
local IndexableElementMixin_mt = Class(IndexChangeSubjectMixin, GuiMixin)
function IndexChangeSubjectMixin.new()
    -- upvalues: (copy) IndexableElementMixin_mt
    local self = GuiMixin.new(IndexableElementMixin_mt, IndexChangeSubjectMixin)
    self.callbacks = {}
    return self
end
function IndexChangeSubjectMixin:addTo(guiElement)
    if not IndexChangeSubjectMixin:superClass().addTo(self, guiElement) then
        return false
    end
    guiElement.addIndexChangeObserver = IndexChangeSubjectMixin.addIndexChangeObserver
    guiElement.notifyIndexChange = IndexChangeSubjectMixin.notifyIndexChange
    return true
end
function IndexChangeSubjectMixin.addIndexChangeObserver(guiElement, observer, indexChangeCallback)
    guiElement[IndexChangeSubjectMixin].callbacks[observer] = indexChangeCallback
end
function IndexChangeSubjectMixin.notifyIndexChange(guiElement, index, count)
    for observer, callback in pairs(guiElement[IndexChangeSubjectMixin].callbacks) do
        callback(observer, index, count)
    end
end
function IndexChangeSubjectMixin.clone(_, srcGuiElement, dstGuiElement)
    if srcGuiElement[IndexChangeSubjectMixin].callbacks ~= nil then
        dstGuiElement[IndexChangeSubjectMixin].callbacks = table.clone(srcGuiElement[IndexChangeSubjectMixin].callbacks)
    end
end