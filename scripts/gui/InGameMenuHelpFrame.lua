InGameMenuHelpFrame = {}
local InGameMenuHelpFrame_mt = Class(InGameMenuHelpFrame, TabbedMenuFrameElement)
function InGameMenuHelpFrame.register()
    local inGameMenuHelpFrame = InGameMenuHelpFrame.new()
    g_gui:loadGui("dataS/gui/InGameMenuHelpFrame.xml", "HelpFrame", inGameMenuHelpFrame, true)
end
function InGameMenuHelpFrame.new(target, custom_mt)
    -- upvalues: (copy) InGameMenuHelpFrame_mt
    return TabbedMenuFrameElement.new(target, custom_mt or InGameMenuHelpFrame_mt)
end
function InGameMenuHelpFrame.createFromExistingGui(gui, guiName)
    local newGui = InGameMenuHelpFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function InGameMenuHelpFrame:initialize()
    InGameMenuHelpFrame:superClass().initialize(self)
    self.helpLineDotTemplate:unlinkElement()
    FocusManager:removeElement(self.helpLineDotTemplate)
end
function InGameMenuHelpFrame:delete()
    self.helpLineContentItem:delete()
    self.helpLineContentItemTitle:delete()
    for k, clone in pairs(self.helpLineDotBox.elements) do
        clone:delete()
        self.helpLineDotBox.elements[k] = nil
    end
    self.helpLineDotTemplate:delete()
    InGameMenuHelpFrame:superClass().delete(self)
end
function InGameMenuHelpFrame:onFrameOpen()
    InGameMenuHelpFrame:superClass().onFrameOpen(self)
    self.customEnvironments = g_helpLineManager:getCustomEnvironmentNames()
    local texts = {}
    for index, env in ipairs(self.customEnvironments) do
        if string.isNilOrWhitespace(env) then
            table.insert(texts, g_i18n:getText("ui_helpLine_baseGame"))
        else
            local mod = g_modManager:getModByName(env)
            if mod == nil then
                table.insert(texts, "Unknown")
            else
                table.insert(texts, mod.title)
            end
        end
    end
    self.helpLineSelector:setTexts(texts)
    for index, env in pairs(self.helpLineDotBox.elements) do
        env:delete()
        self.helpLineDotBox.elements[index] = nil
    end
    if #self.helpLineSelector.texts > 1 then
        for index, env in ipairs(self.helpLineSelector.texts) do
            local index
            self.helpLineDotTemplate:clone(self.helpLineDotBox).getIsSelected = function()
                -- upvalues: (copy) self, (copy) index
                return self.helpLineSelector:getState() == index
            end
        end
        self.helpLineDotBox:invalidateLayout()
        FocusManager:linkElements(self.helpLineSelector, FocusManager.TOP, self.helpLineList)
        FocusManager:linkElements(self.helpLineSelector, FocusManager.BOTTOM, self.helpLineList)
        FocusManager:linkElements(self.helpLineSelector, FocusManager.LEFT, self.helpLineList)
        FocusManager:linkElements(self.helpLineSelector, FocusManager.RIGHT, self.helpLineList)
        FocusManager:linkElements(self.helpLineList, FocusManager.TOP, self.helpLineSelector)
        FocusManager:linkElements(self.helpLineList, FocusManager.BOTTOM, self.helpLineSelector)
        FocusManager:linkElements(self.helpLineList, FocusManager.LEFT, self.helpLineSelector)
        FocusManager:linkElements(self.helpLineList, FocusManager.RIGHT, self.helpLineSelector)
    else
        FocusManager:linkElements(self.helpLineList, FocusManager.TOP, nil)
        FocusManager:linkElements(self.helpLineList, FocusManager.BOTTOM, nil)
    end
    self.helpLineList:reloadData()
    self:setSoundSuppressed(true)
    FocusManager:setFocus(self.helpLineList)
    self:setSoundSuppressed(false)
    self.helpLineContentBox:registerActionEvents()
end
function InGameMenuHelpFrame:onFrameClose()
    self.helpLineContentBox:removeActionEvents()
    InGameMenuHelpFrame:superClass().onFrameClose(self)
end
function InGameMenuHelpFrame:updateContents(page)
    self.helpLineContentItem:unlinkElement()
    self.helpLineContentItemTitle:unlinkElement()
    local i = #self.helpLineContentBox.elements
    for i = i, 1, -1 do
        self.helpLineContentBox.elements[i]:delete()
    end
    if page ~= nil then
        self.helpLineTitleElement:setText(g_helpLineManager:convertText(page.title, page.customEnvironment))
        for _, paragraph in ipairs(page.paragraphs) do
            if paragraph.title ~= nil then
                self.helpLineContentItemTitle:clone(self.helpLineContentBox):setText(g_helpLineManager:convertText(paragraph.title, paragraph.customEnvironment))
            end
            local titleElement = self.helpLineContentItem:clone(self.helpLineContentBox)
            local textElement = titleElement:getDescendantByName("text")
            local textFullElement = titleElement:getDescendantByName("textFullWidth")
            local imageElement = titleElement:getDescendantByName("image")
            local textHeight = 0
            local textHeightFullHeight = 0
            if paragraph.noSpacing then
                titleElement.margin = {
                    0,
                    0,
                    0,
                    0
                }
            end
            if paragraph.image == nil then
                textElement:setVisible(false)
                imageElement:setVisible(false)
                if paragraph.text ~= nil then
                    textFullElement:setText(g_helpLineManager:convertText(paragraph.text, paragraph.customEnvironment))
                end
                textHeightFullHeight = textFullElement:getTextHeight(true)
                textFullElement:setSize(nil, textHeightFullHeight)
            else
                textFullElement:setVisible(false)
                if paragraph.text ~= nil then
                    textElement:setText(g_helpLineManager:convertText(paragraph.text, paragraph.customEnvironment))
                    textHeight = textElement:getTextHeight(true)
                    textElement:setSize(nil, textHeight)
                end
                imageElement:setImageFilename((Utils.getFilename(paragraph.image.filename, page.baseDirectory)))
                imageElement:setImageUVs(nil, unpack(paragraph.image.uvs))
                if imageElement.originalWidth == nil then
                    imageElement.originalWidth = imageElement.absSize[1]
                end
                if paragraph.image.displaySize == nil then
                    if paragraph.text == nil then
                        imageElement:setSize(titleElement.absSize[1], titleElement.absSize[1] * paragraph.image.aspectRatio * g_screenAspectRatio)
                    else
                        imageElement:setSize(imageElement.originalWidth, nil)
                    end
                else
                    imageElement:setSize(paragraph.image.displaySize[1], paragraph.image.displaySize[2])
                end
                if paragraph.text ~= nil and paragraph.alignToImage then
                    textElement:setSize(nil, imageElement.size[2])
                    textElement.textVerticalAlignment = TextElement.VERTICAL_ALIGNMENT.MIDDLE
                end
            end
            titleElement:setSize(nil, (math.max(textHeight, textHeightFullHeight, paragraph.image ~= nil and imageElement.absSize[2] or 0)))
            titleElement:invalidateLayout()
        end
        self.helpLineContentBox:invalidateLayout()
    end
end
function InGameMenuHelpFrame:onListSelectionChanged(_, section, index)
    if self.helpLineContentItem ~= nil then
        self:updateContents(self:getPage(section, index))
    end
end
function InGameMenuHelpFrame:onSelectorChanged()
    self.helpLineList:reloadData()
    self.helpLineList:setSelectedItem(1, 1)
end
function InGameMenuHelpFrame:getNumberOfSections()
    local customEnvironment = self.customEnvironments[self.helpLineSelector:getState()]
    return #g_helpLineManager:getCategories(customEnvironment)
end
function InGameMenuHelpFrame:getNumberOfItemsInSection(_, section)
    local customEnvironment = self.customEnvironments[self.helpLineSelector:getState()]
    return #g_helpLineManager:getCategory(customEnvironment, section).pages
end
function InGameMenuHelpFrame:getTitleForSectionHeader(_, section)
    local customEnvironment = self.customEnvironments[self.helpLineSelector:getState()]
    local category = g_helpLineManager:getCategory(customEnvironment, section)
    return g_i18n:convertText(category.title, category.customEnvironment)
end
function InGameMenuHelpFrame:populateCellForItemInSection(_, section, index, cell)
    local page = self:getPage(section, index)
    cell:getAttribute("title"):setText(g_i18n:convertText(page.title, page.customEnvironment))
    local icon = cell:getAttribute("icon")
    if page.iconSliceId == nil then
        icon:setVisible(false)
    else
        icon:setVisible(true)
        icon:setImageSlice(nil, page.iconSliceId)
    end
end
function InGameMenuHelpFrame:getPage(categoryIndex, pageIndex)
    local customEnvironment = self.customEnvironments[self.helpLineSelector:getState()]
    return g_helpLineManager:getCategory(customEnvironment, categoryIndex).pages[pageIndex]
end
function InGameMenuHelpFrame:openPage(categoryIndex, pageIndex, customEnvironment)
    local customEnvironmentIndex = 1
    if self.customEnvironments ~= nil then
        for i, env in ipairs(self.customEnvironments) do
            if env == customEnvironment then
                customEnvironmentIndex = i
                break
            end
        end
    end
    self.helpLineSelector:setState(customEnvironmentIndex)
    self.helpLineList:reloadData()
    self:setSoundSuppressed(true)
    self.helpLineList:setSelectedItem(categoryIndex, pageIndex, true, 1)
    self:setSoundSuppressed(false)
end