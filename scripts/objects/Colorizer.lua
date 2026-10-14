Colorizer = {}
local Colorizer_mt = Class(Colorizer)
function Colorizer.onCreate(_, id)
    g_currentMission:addNonUpdateable(Colorizer.new(id))
    print("function Colorizer:onCreate(id)")
end
function Colorizer.new(name)
    -- upvalues: (copy) Colorizer_mt
    local self = setmetatable({}, Colorizer_mt)
    self.me = name
    local xmlFile = Utils.getFilename(Utils.getNoNil(getUserAttribute(name, "xmlFile"), ""), g_currentMission.loadingMapBaseDirectory)
    if xmlFile ~= "" then
        local xmlFile = loadXMLFile("colors.xml", xmlFile)
        local i = 0
        while true do
            local key = string.format("colors.color(%d)", i)
            local colorName = getXMLString(xmlFile, key .. "#colorName")
            local rgb = getXMLString(xmlFile, key .. "#color")
            if rgb == nil then
                break
            end
            local color = string.getVector(rgb, 3)
            if color ~= nil then
                table.insert({}, {
                    ["color"] = color,
                    ["colorName"] = colorName
                })
            end
            i = i + 1
        end
        delete(xmlFile)
        local key = getNumOfChildren(name)
        local color = 1
        local rgb = 1
        for color = color, key, rgb do
            local currentColorObject = getChildAt(name, color - 1)
            local colorIndex = math.random(1, #colors)
            setShaderParameter(currentColorObject, "colorTint", colors[colorIndex][1], colors[colorIndex][2], colors[colorIndex][3], 1, false)
        end
    end
    return self
end
function Colorizer:delete() end