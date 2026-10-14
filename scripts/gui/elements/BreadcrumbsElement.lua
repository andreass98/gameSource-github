BreadcrumbsElement = {}
local BreadcrumbsElement_mt = Class(BreadcrumbsElement, BoxLayoutElement)
Gui.registerGuiElement("Breadcrumbs", BreadcrumbsElement)
function BreadcrumbsElement.new(target, custom_mt)
    -- upvalues: (copy) BreadcrumbsElement_mt
    local self = BoxLayoutElement.new(target, custom_mt or BreadcrumbsElement_mt)
    self.crumbs = {}
    return self
end
function BreadcrumbsElement:copyAttributes(src)
    BreadcrumbsElement:superClass().copyAttributes(self, src)
    self.textTemplate = src.textTemplate
    self.arrowTemplate = src.arrowTemplate
    self.ownsTemplates = false
end
function BreadcrumbsElement:onGuiSetupFinished()
    BreadcrumbsElement:superClass().onGuiSetupFinished(self)
    if self.textTemplate == nil or self.arrowTemplate == nil then
        self.ownsTemplates = true
        self.textTemplate = self:getFirstDescendant(function(element)
            return element:isa(TextBackdropElement)
        end)
        if self.textTemplate ~= nil then
            self.textTemplate:unlinkElement()
        end
        self.arrowTemplate = self:getFirstDescendant(function(element)
            return element:isa(BitmapElement)
        end)
        if self.arrowTemplate ~= nil then
            self.arrowTemplate:unlinkElement()
        end
    end
end
function BreadcrumbsElement:delete()
    if self.ownsTemplates then
        if self.textTemplate ~= nil then
            self.textTemplate:delete()
        end
        if self.arrowTemplate ~= nil then
            self.arrowTemplate:delete()
        end
    end
    BreadcrumbsElement:superClass().delete(self)
end
function BreadcrumbsElement:setBreadcrumbs(crumbs)
    self.crumbs = crumbs
    self:updateElements()
end
function BreadcrumbsElement:updateElements()
    for _ = 1, #self.elements do
        self.elements[1]:delete()
    end
    local numCrumbs = #self.crumbs
    local index = 1
    for index = index, numCrumbs do
        local profile, arrowProfile
        if index == numCrumbs then
            profile = "shopItemsNavItemTextBackdropActive"
            arrowProfile = "shopItemsNavArrow"
        elseif index == numCrumbs - 1 then
            profile = "shopItemsNavItemTextBackdrop"
            arrowProfile = "shopItemsNavFilledArrowActive"
        else
            profile = "shopItemsNavItemTextBackdrop"
            arrowProfile = "shopItemsNavFilledArrow"
        end
        local backdrop = self.textTemplate:clone(self)
        backdrop:applyProfile(profile)
        backdrop.textElement:setText(self.crumbs[index])
        self.arrowTemplate:clone(self):applyProfile(arrowProfile)
    end
    self:invalidateLayout()
end