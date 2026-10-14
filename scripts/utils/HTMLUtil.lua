HTMLUtil = {}
HTMLUtil.encodeEntities = {
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ["\195\164"] = "&auml;",
    ["\195\160"] = "&agrave;",
    ["\195\162"] = "&acirc;",
    ["\195\169"] = "&eacute;",
    ["\195\168"] = "&egrave;",
    ["\195\170"] = "&ecirc;",
    ["\195\171"] = "&euml;",
    ["\195\174"] = "&icirc;",
    ["\195\175"] = "&iuml;",
    ["\195\180"] = "&ocirc;",
    ["\195\182"] = "&ouml;",
    ["\195\185"] = "&ugrave;",
    ["\195\187"] = "&ucirc;",
    ["\195\188"] = "&uuml;",
    ["\195\191"] = "&yuml;",
    ["\195\128"] = "&Agrave;",
    ["\195\130"] = "&Acirc;",
    ["\195\137"] = "&Eacute;",
    ["\195\136"] = "&Egrave;",
    ["\195\138"] = "&Ecirc;",
    ["\195\139"] = "&Euml;",
    ["\195\142"] = "&Icirc;",
    ["\195\143"] = "&Iuml;",
    ["\195\148"] = "&Ocirc;",
    ["\195\150"] = "&Ouml;",
    ["\195\153"] = "&Ugrave;",
    ["\195\155"] = "&Ucirc;",
    ["\195\167"] = "&ccedil;",
    ["\195\135"] = "&Ccedil;",
    ["\197\184"] = "&Yuml;",
    ["\194\171"] = "&laquo;",
    ["\194\187"] = "&raquo;",
    ["\194\169"] = "&copy;",
    ["\194\174"] = "&reg;",
    ["\195\166"] = "&aelig;",
    ["\195\134"] = "&AElig;",
    ["\197\146"] = "&OElig;",
    ["\197\147"] = "&oelig;"
}
HTMLUtil.decodeEntities = {
    ["amp"] = "&",
    ["auml"] = "\195\164",
    ["agrave"] = "\195\160",
    ["acirc"] = "\195\162",
    ["eacute"] = "\195\169",
    ["egrave"] = "\195\168",
    ["ecirc"] = "\195\170",
    ["euml"] = "\195\171",
    ["icirc"] = "\195\174",
    ["iuml"] = "\195\175",
    ["ocirc"] = "\195\180",
    ["ouml"] = "\195\182",
    ["ugrave"] = "\195\185",
    ["ucirc"] = "\195\187",
    ["uuml"] = "\195\188",
    ["yuml"] = "\195\191",
    ["Agrave"] = "\195\128",
    ["Acirc"] = "\195\130",
    ["Eacute"] = "\195\137",
    ["Egrave"] = "\195\136",
    ["Ecirc"] = "\195\138",
    ["Euml"] = "\195\139",
    ["Icirc"] = "\195\142",
    ["Iuml"] = "\195\143",
    ["Ocirc"] = "\195\148",
    ["Ouml"] = "\195\150",
    ["Ugrave"] = "\195\153",
    ["Ucirc"] = "\195\155",
    ["ccedil"] = "\195\167",
    ["Ccedil"] = "\195\135",
    ["Yuml"] = "\197\184",
    ["laquo"] = "\194\171",
    ["raquo"] = "\194\187",
    ["copy"] = "\194\169",
    ["reg"] = "\194\174",
    ["aelig"] = "\195\166",
    ["AElig"] = "\195\134",
    ["OElig"] = "\197\146",
    ["oelig"] = "\197\147"
}
function HTMLUtil.encodeToHTML(str, inCData)
    if inCData then
        return string.gsub(str, "]]>", "]]]]><![CDATA[>")
    end
    local encodedString = string.gsub(str, "&", "&amp;")
    local encodedString = string.gsub(encodedString, "\"", "&quot;")
    local encodedString = string.gsub(encodedString, "]", "&#93;")
    local encodedString = string.gsub(encodedString, "<", "&lt;")
    local encodedString = string.gsub(encodedString, ">", "&gt;")
    local encodedString = string.gsub(encodedString, "\n", "&#10;")
    return string.gsub(encodedString, "\r", "&#13;")
end
function HTMLUtil.decodeFromHTML(str)
    return string.gsub(str, "&%a+;", function(entity)
        return HTMLUtil.decodeEntities[string.sub(entity, 2, -2)] or entity
    end)
end