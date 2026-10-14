PagingElement = {}
local PagingElement_mt = Class(PagingElement, GuiElement)
Gui.registerGuiElement("Paging", PagingElement)
function PagingElement.new(target, custom_mt)
    -- upvalues: (copy) PagingElement_mt
    if custom_mt == nil then
        custom_mt = PagingElement_mt
    end
    local self = GuiElement.new(target, custom_mt)
    self:include(IndexChangeSubjectMixin)
    self.pageIdCount = 1
    self.pages = {}
    self.idPageHash = {}
    self.pageMapping = {}
    self.currentPageIndex = 1
    self.currentPageMappingIndex = 1
    return self
end
function PagingElement:loadFromXML(xmlFile, key)
    PagingElement:superClass().loadFromXML(self, xmlFile, key)
    self:addCallback(xmlFile, key .. "#onPageChange", "onPageChangeCallback")
    self:addCallback(xmlFile, key .. "#onPageUpdate", "onPageUpdateCallback")
end
function PagingElement:copyAttributes(src)
    PagingElement:superClass().copyAttributes(self, src)
    self.onPageChangeCallback = src.onPageChangeCallback
    self.onPageUpdateCallback = src.onPageUpdateCallback
    GuiMixin.cloneMixin(IndexChangeSubjectMixin, src, self)
end
function PagingElement:onGuiSetupFinished()
    PagingElement:superClass().onGuiSetupFinished(self)
    self:updatePageMapping()
end
function PagingElement:setPage(pageMappingIndex)
    for _, page in pairs(self.pages) do
        page.element:setVisible(false)
    end
    self.currentPageMappingIndex = math.clamp(pageMappingIndex, 1, #self.pageMapping)
    self.currentPageIndex = self.pageMapping[self.currentPageIndex]
    self.pages[self.currentPageIndex].element:setVisible(true)
    self:raiseCallback("onPageChangeCallback", self.currentPageIndex, self.currentPageMappingIndex, self)
    self:notifyIndexChange(self.currentPageMappingIndex, #self.pageMapping)
    return prevIndex ~= self.currentPageIndex
end
function PagingElement:addElement(element)
    PagingElement:superClass().addElement(self, element)
    if element.name == nil or not g_i18n:hasText("ui_" .. element.name) then
        self:addPage(tostring(element), element, "")
    else
        self:addPage(string.upper(element.name), element, g_i18n:getText("ui_" .. element.name))
    end
end
function PagingElement:getNextID()
    self.pageIdCount = self.pageIdCount + 1
    return self.pageIdCount
end
function PagingElement:addPage(id, element, title, index)
    local newIndex = self:getNextID()
    if self.currentPageIndex == nil then
        self.currentPageIndex = newIndex
        self.currentPageMappingIndex = self.currentPageIndex
    end
    local page = {
        ["id"] = newIndex,
        ["mappingIndex"] = 0,
        ["idName"] = id,
        ["element"] = element,
        ["title"] = title,
        ["disabled"] = false
    }
    table.insert(self.pages, index or #self.pages + 1, page)
    self.idPageHash[page.id] = page
    element:setVisible(false)
    self:updatePageMapping()
    return page
end
function PagingElement:getVisiblePagesCount()
    return #self.pageMapping
end
function PagingElement:getPageIdByElement(element)
    for _, page in pairs(self.pages) do
        if page.element == element then
            return page.id
        end
    end
    return nil
end
function PagingElement:getPageElementByIndex(pageIndex)
    local element = nil
    local page = self.pages[pageIndex]
    if page then
        element = page.element
    end
    return element
end
function PagingElement:getPageIndexByElement(element)
    for i, page in ipairs(self.pages) do
        if page.element == element then
            return i
        end
    end
    return nil
end
function PagingElement:getPageMappingIndexByElement(element)
    for _, page in ipairs(self.pages) do
        if page.element == element then
            return page.mappingIndex
        end
    end
    return nil
end
function PagingElement:removePageByElement(pageElement)
    local removeIndex = -1
    local removeId = -1
    for i, page in ipairs(self.pages) do
        if page.element == pageElement then
            removeId = page.id
            removeIndex = i
            break
        end
    end
    if table.remove(self.pages, removeIndex) then
        self.currentPageIndex = 1
        self.idPageHash[removeId] = nil
        self:updatePageMapping()
    end
end
function PagingElement:removeElement(element)
    PagingElement:superClass().removeElement(self, element)
    self:removePageByElement(element)
end
function PagingElement:getCurrentPageId()
    return self.pages[self.currentPageIndex].id
end
function PagingElement:getPageMappingIndex(pageId)
    return self.idPageHash[pageId].mappingIndex
end
function PagingElement:getIsPageDisabled(pageId)
    return self.idPageHash[pageId].disabled
end
function PagingElement:getPageById(pageId)
    return self.idPageHash[pageId]
end
function PagingElement:setPageDisabled(page, disabled)
    if page ~= nil then
        page.disabled = disabled
        self:updatePageMapping()
        self:raiseCallback("onPageUpdateCallback", page, self)
    end
end
function PagingElement:setPageIdDisabled(pageId, disabled)
    if self.idPageHash[pageId] ~= nil then
        self:setPageDisabled(self.idPageHash[pageId], disabled)
    end
end
function PagingElement:updatePageMapping()
    self.pageMapping = {}
    self.pageTitles = {}
    local currentPage = self.pages[self.currentPageIndex]
    for i, page in ipairs(self.pages) do
        if page.disabled then
            if page == currentPage then
                currentPage = nil
            end
            page.mappingIndex = 1
        else
            table.insert(self.pageMapping, i)
            table.insert(self.pageTitles, page.title)
            page.mappingIndex = #self.pageMapping
        end
    end
    if currentPage == nil then
        if not self.neuterPageUpdates and #self.pageMapping > 0 then
            self.currentPageMappingIndex = math.clamp(self.currentPageMappingIndex, 1, #self.pageMapping)
            self:setPage(self.currentPageMappingIndex)
            return
        end
    else
        self:notifyIndexChange(self.currentPageMappingIndex, #self.pageMapping)
    end
end
function PagingElement:getPageTitles()
    return self.pageTitles
end
function PagingElement:onOpen()
    self:raiseCallback("onOpenCallback", self)
    self.pages[self.currentPageIndex].element:onOpen()
end
function PagingElement:onClose()
    self:raiseCallback("onCloseCallback", self)
    self.pages[self.currentPageIndex].element:onClose()
end