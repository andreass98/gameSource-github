TableHeaderElement = {
    ["SORTING_OFF"] = 1,
    ["SORTING_ASC"] = 2,
    ["SORTING_DESC"] = 3,
    ["NAME_ASC_ICON"] = "iconAscending",
    ["NAME_DESC_ICON"] = "iconDescending"
}
local TableHeaderElement_mt = Class(TableHeaderElement, ButtonElement)
Gui.registerGuiElement("TableHeader", TableHeaderElement)
function TableHeaderElement.new(target, custom_mt)
    -- upvalues: (copy) TableHeaderElement_mt
    local self = ButtonElement.new(target, custom_mt or TableHeaderElement_mt)
    self.allowedSortingStates = {
        [TableHeaderElement.SORTING_OFF] = true,
        [TableHeaderElement.SORTING_ASC] = false,
        [TableHeaderElement.SORTING_DESC] = false
    }
    self.sortingOrder = TableHeaderElement.SORTING_OFF
    self.sortingIcons = {
        [TableHeaderElement.SORTING_OFF] = nil,
        [TableHeaderElement.SORTING_ASC] = nil,
        [TableHeaderElement.SORTING_DESC] = nil
    }
    self.targetTableId = ""
    self.columnName = ""
    return self
end
function TableHeaderElement:loadFromXML(xmlFile, key)
    TableHeaderElement:superClass().loadFromXML(self, xmlFile, key)
    self.targetTableId = getXMLString(xmlFile, key .. "#targetTableId") or self.targetTableId
    self.columnName = getXMLString(xmlFile, key .. "#columnName") or self.columnName
    local allowAscendingSort = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowSortingAsc"), self.allowedSortingStates[TableHeaderElement.SORTING_ASC])
    local allowDescendingSort = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowSortingDesc"), self.allowedSortingStates[TableHeaderElement.SORTING_DESC])
    self.allowedSortingStates[TableHeaderElement.SORTING_ASC] = allowAscendingSort
    self.allowedSortingStates[TableHeaderElement.SORTING_DESC] = allowDescendingSort
end
function TableHeaderElement:loadProfile(profile, applyProfile)
    TableHeaderElement:superClass().loadProfile(self, profile, applyProfile)
    self.columnName = profile:getValue("columnName", self.columnName)
    self.allowedSortingStates[TableHeaderElement.SORTING_ASC] = profile:getBool("allowSortingAsc", self.allowedSortingStates[TableHeaderElement.SORTING_ASC])
    self.allowedSortingStates[TableHeaderElement.SORTING_DESC] = profile:getBool("allowSortingDesc", self.allowedSortingStates[TableHeaderElement.SORTING_DESC])
end
function TableHeaderElement:copyAttributes(src)
    TableHeaderElement:superClass().copyAttributes(self, src)
    self.targetTableId = src.targetTableId
    self.columnName = src.columnName
    self.allowedSortingStates = { unpack(src.allowedSortingStates) }
end
function TableHeaderElement:onGuiSetupFinished()
    TableHeaderElement:superClass().onGuiSetupFinished(self)
    for _, child in pairs(self.elements) do
        if child.name == TableHeaderElement.NAME_ASC_ICON then
            self.sortingIcons[TableHeaderElement.SORTING_ASC] = child
        end
        if child.name == TableHeaderElement.NAME_DESC_ICON then
            self.sortingIcons[TableHeaderElement.SORTING_DESC] = child
        end
    end
end
function TableHeaderElement:toggleSorting()
    repeat
        self.sortingOrder = self.sortingOrder % #self.allowedSortingStates + 1
    until self.allowedSortingStates[self.sortingOrder]
    if self.sortingOrder ~= self.sortingOrder then
        self:updateSortingDisplay()
    end
    return self.sortingOrder
end
function TableHeaderElement:disableSorting()
    self.sortingOrder = TableHeaderElement.SORTING_OFF
    self:updateSortingDisplay()
end
function TableHeaderElement:updateSortingDisplay()
    for sortOrderIndex, icon in pairs(self.sortingIcons) do
        if sortOrderIndex == self.sortingOrder then
            icon:setVisible(true)
        else
            icon:setVisible(false)
        end
    end
end