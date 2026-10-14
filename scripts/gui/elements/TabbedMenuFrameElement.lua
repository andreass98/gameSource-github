TabbedMenuFrameElement = {}
local TabbedMenuFrameElement_mt = Class(TabbedMenuFrameElement, FrameElement)
local function NO_CALLBACK() end
function TabbedMenuFrameElement.new(target, customMt)
    -- upvalues: (copy) TabbedMenuFrameElement_mt, (copy) NO_CALLBACK
    local self = FrameElement.new(target, customMt or TabbedMenuFrameElement_mt)
    self.hasCustomMenuButtons = false
    self.menuButtonInfo = {}
    self.menuButtonsDirty = false
    self.title = nil
    self.tabbingMenuVisibleDirty = false
    self.tabbingMenuVisible = true
    self.currentPage = 1
    self:setNumberOfPages(1)
    self.requestCloseCallback = NO_CALLBACK
    return self
end
function TabbedMenuFrameElement:initialize(...) end
function TabbedMenuFrameElement:getHasCustomMenuButtons()
    return self.hasCustomMenuButtons
end
function TabbedMenuFrameElement:getMenuButtonInfo()
    return self.menuButtonInfo
end
function TabbedMenuFrameElement:setMenuButtonInfo(menuButtonInfo)
    self.menuButtonInfo = menuButtonInfo
    self.hasCustomMenuButtons = menuButtonInfo ~= nil
end
function TabbedMenuFrameElement:setMenuButtonInfoDirty()
    self.menuButtonsDirty = true
end
function TabbedMenuFrameElement:isMenuButtonInfoDirty()
    return self.menuButtonsDirty
end
function TabbedMenuFrameElement:clearMenuButtonInfoDirty()
    self.menuButtonsDirty = false
end
function TabbedMenuFrameElement:getMainElementSize()
    return { 1, 1 }
end
function TabbedMenuFrameElement:getMainElementPosition()
    return { 0, 0 }
end
function TabbedMenuFrameElement:requestClose(callback)
    -- upvalues: (copy) NO_CALLBACK
    self.requestCloseCallback = callback or NO_CALLBACK
    return true
end
function TabbedMenuFrameElement:onFrameOpen()
    TabbedMenuFrameElement:superClass().onOpen(self)
    self:updatePagingButtons()
end
function TabbedMenuFrameElement:onFrameClose()
    TabbedMenuFrameElement:superClass().onClose(self)
end
function TabbedMenuFrameElement:setTitle(title)
    self.title = title
    if self.pagingTitle ~= nil then
        self.pagingTitle:setText(title)
    end
end
function TabbedMenuFrameElement:getTitle()
    return self.title
end
function TabbedMenuFrameElement:setTabbingMenuVisible(visible)
    self.tabbingMenuVisible = visible
    self.tabbingMenuVisibleDirty = true
end
function TabbedMenuFrameElement:getTabbingMenuVisible()
    return self.tabbingMenuVisible and not GS_IS_MOBILE_VERSION
end
function TabbedMenuFrameElement:isTabbingMenuVisibleDirty()
    return self.tabbingMenuVisibleDirty
end
function TabbedMenuFrameElement:onNextPage()
    if Platform.isMobile then
        local pagingElement = self.parent
        pagingElement.target:onClickPageSelection(#pagingElement.pageMapping < pagingElement.currentPageMappingIndex + 1 and 1 or pagingElement.currentPageMappingIndex + 1)
    elseif self.currentPage < self.numberOfPages then
        self.currentPage = self.currentPage + 1
        self:onPageChanged(self.currentPage, self.currentPage - 1)
    end
end
function TabbedMenuFrameElement:onPreviousPage()
    if Platform.isMobile then
        local pagingElement = self.parent
        local index = pagingElement.currentPageMappingIndex - 1
        if index < 1 then
            index = pagingElement.pageMapping[#pagingElement.pageMapping]
        end
        pagingElement.target:onClickPageSelection(index)
    elseif self.currentPage > 1 then
        self.currentPage = self.currentPage - 1
        self:onPageChanged(self.currentPage, self.currentPage + 1)
    end
end
function TabbedMenuFrameElement:getHasNextPage()
    if Platform.isMobile then
        return #self.parent.pageMapping > 1
    else
        return self.currentPage < self.numberOfPages
    end
end
function TabbedMenuFrameElement:getHasPreviousPage()
    if Platform.isMobile then
        return #self.parent.pageMapping > 1
    else
        return self.currentPage > 1
    end
end
function TabbedMenuFrameElement:setNumberOfPages(num)
    self.numberOfPages = math.max(num, 1)
    self.currentPage = math.max(math.min(self.currentPage, num), 1)
    if self.pagingIndexState ~= nil then
        self.pagingIndexState:setPageCount(self.numberOfPages, self.currentPage)
    end
    if self.currentPage == self.currentPage then
        self:updatePagingButtons()
    else
        self:onPageChanged(self.currentPage, self.currentPage)
    end
end
function TabbedMenuFrameElement:onPageChanged(page, _)
    if self.pagingIndexState ~= nil then
        self.pagingIndexState:setPageIndex(page)
    end
    self:updatePagingButtons()
end
function TabbedMenuFrameElement:updatePagingButtons()
    if self.subPagingButtonLeft ~= nil then
        local showButtons = false
        if self.numberOfPages ~= 1 then
            showButtons = not self.pagingButtonsDisabled
        end
        self.subPagingButtonLeft:setDisabled(not showButtons or self.currentPage == 1)
        self.subPagingButtonRight:setDisabled(not showButtons or self.currentPage == self.numberOfPages)
    end
end
function TabbedMenuFrameElement:setPagingButtonsDisabled(disabled)
    self.pagingButtonsDisabled = disabled
    self:updatePagingButtons()
end
function TabbedMenuFrameElement:setPagingButtonsDirty()
    self:updatePagingButtons()
end
function TabbedMenuFrameElement:getCurrentPage()
    return self.currentPage
end