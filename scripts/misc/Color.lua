Color = {}
local Color_mt = Class(Color)
function Color_mt.__index(color, key)
    local value = rawget(color, key)
    if value == nil then
        local value = Color[key]
        if value == nil then
            if type(key) == "number" and (key > 0 and key <= 4) then
                if key == 1 then
                    return color.r
                elseif key == 2 then
                    return color.g
                elseif key == 3 then
                    return color.b
                else
                    return color.a
                end
            else
                return Color.swizzle(color, key)
            end
        else
            return value
        end
    else
        return value
    end
end
function Color_mt.__mul(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then
        if type(left) == "number" then
            local g = math.clamp(right[1] * left, 0, 1)
            return Color.new(g, math.clamp(right[2] * left, 0, 1), math.clamp(right[3] * left, 0, 1), (math.clamp((right[4] or 1) * left, 0, 1)))
        end
        if type(right) ~= "number" then
            Assert.fail("attempt to perform arithmetic (mul) on %s and %s", type(left), (type(right)))
            return nil
        end
        local r = Color.new
        local i = left[1] * right
        local g = math.clamp(i, 0, 1)
        local a = left[2] * right
        local i = math.clamp(a, 0, 1)
        local a = math.clamp(left[3] * right, 0, 1)
        return r(g, i, a, (math.clamp((left[4] or 1) * right, 0, 1)))
    end
    local i = 1
    local r = 3
    local g = 1
    for i = i, r, g do
        if left[i] == nil or right[i] == nil then
            Assert.fail("Cannot multiply between two tables that do not both have indices 1, 2, and 3!")
        end
    end
    local a = math.clamp(left[1] * right[1], 0, 1)
    local a = math.clamp(left[2] * right[2], 0, 1)
    local a = left[3] * right[3]
    local i = math.clamp(a, 0, 1)
    local a
    if left[4] == nil or right[4] == nil then
        a = left[4] or (right[4] or 1)
    else
        a = math.clamp(left[4] * right[4], 0, 1)
    end
    return Color.new(a, a, i, a)
end
function Color.new(r, g, b, a)
    -- upvalues: (copy) Color_mt
    local self = setmetatable({}, Color_mt)
    self.r = r or 0
    self.g = g or 0
    self.b = b or 0
    self.a = a or 1
    return self
end
function Color:copy()
    return Color.new(self.r, self.g, self.b, self.a)
end
function Color:copyTo(color)
    color.r = self.r
    color.g = self.g
    color.b = self.b
    color.a = self.a
end
function Color.parseFromString(inputString, ignoreAlpha)
    if type(inputString) == "string" then
        if string.startsWith(inputString, "#") then
            return Color.fromHex(inputString)
        else
            local color = Color.fromPackedValue(inputString)
            if color == nil then
                local vector = string.split(inputString, " ", tonumber)
                if #vector >= 3 then
                    if ignoreAlpha then
                        return Color.new(vector[1], vector[2], vector[3])
                    else
                        return Color.new(vector[1], vector[2], vector[3], vector[4])
                    end
                else
                    if g_vehicleMaterialManager ~= nil then
                        local color = Color.fromVector(g_vehicleMaterialManager:getMaterialTemplateColorByName(inputString), nil, 3)
                        if color ~= nil then
                            if ignoreAlpha then
                                color.a = 1
                            end
                            return color
                        end
                    end
                    local color = Color.fromPresetName(inputString)
                    if color == nil then
                        return nil
                    end
                    if ignoreAlpha then
                        color.a = 1
                    end
                    return color
                end
            else
                if ignoreAlpha then
                    color.a = 1
                end
                return color
            end
        end
    else
        return nil
    end
end
function Color.fromPresetName(presetName)
    if type(presetName) == "string" then
        return Color.PRESETS[string.upper(presetName)]
    else
        return nil
    end
end
function Color.fromPackedValue(packedValue)
    if type(packedValue) == "string" then
        packedValue = tonumber(packedValue)
    end
    if type(packedValue) ~= "number" then
        return nil
    end
    local r = bit32.band(packedValue, 255) / 255
    local a = bit32.band(packedValue, 65280)
    local g = bit32.rshift(a, 8) / 255
    local b = bit32.rshift(bit32.band(packedValue, 16711680), 16) / 255
    local a = bit32.rshift(bit32.band(packedValue, 4278190080), 24) / 255
    return Color.new(r, g, b, a)
end
function Color:toPackedValue()
    local packedValue = math.ceil(self.r * 255)
    local packedValue = bit32.bor(packedValue, (bit32.lshift(math.ceil(self.g * 255), 8)))
    local packedValue = bit32.bor(packedValue, (bit32.lshift(math.ceil(self.b * 255), 16)))
    return bit32.bor(packedValue, (bit32.lshift(math.ceil(self.a * 255), 24)))
end
function Color.fromHex(hexString)
    if type(hexString) == "string" then
        if type(hexString) == "string" and string.startsWith(hexString, "#") then
            hexString = string.sub(hexString, 2)
        end
        local packedValue = tonumber(hexString, 16)
        if packedValue == nil then
            return nil
        else
            return Color.fromPackedValue(packedValue)
        end
    else
        return nil
    end
end
function Color:toHex(includeHash)
    local packedValue = self:toPackedValue()
    return string.format("%s%x", includeHash and "#" or "", packedValue)
end
function Color.fromVector(vector, minLength, maxLength)
    if type(vector) ~= "table" or minLength ~= nil and #vector < minLength then
        return nil
    end
    maxLength = maxLength or #vector
    return Color.new(maxLength >= 1 and vector[1] or 0, maxLength >= 2 and vector[2] or 0, maxLength >= 3 and vector[3] or 0, maxLength >= 4 and vector[4] or 1)
end
function Color:unpack()
    return self.r, self.g, self.b, self.a
end
function Color:unpack3()
    return self.r, self.g, self.b
end
function Color:toVector3()
    return { self.r, self.g, self.b }
end
function Color:toVector4()
    return {
        self.r,
        self.g,
        self.b,
        self.a
    }
end
function Color.fromRGBA(r, g, b, a)
    return Color.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255, (a or 255) / 255)
end
function Color:unpackRGBA()
    return math.ceil(self.r * 255), math.ceil(self.g * 255), math.ceil(self.b * 255), math.ceil(self.a * 255)
end
function Color.fromVectorRGBA(vector, minLength, maxLength)
    if type(vector) ~= "table" or minLength ~= nil and #vector < minLength then
        return nil
    end
    maxLength = maxLength or #vector
    return Color.fromRGBA(maxLength >= 1 and vector[1] or 0, maxLength >= 2 and vector[2] or 0, maxLength >= 3 and vector[3] or 0, maxLength >= 4 and vector[4] or 255)
end
function Color:toVectorRGB()
    return { math.ceil(self.r * 255), math.ceil(self.g * 255), (math.ceil(self.b * 255)) }
end
function Color:toVectorRGBA()
    return {
        math.ceil(self.r * 255),
        math.ceil(self.g * 255),
        math.ceil(self.b * 255),
        (math.ceil(self.a * 255))
    }
end
function Color.blend(first, second, alpha)
    return Color.new(MathUtil.lerp(first.r, second.r, alpha), MathUtil.lerp(first.g, second.g, alpha), MathUtil.lerp(first.b, second.b, alpha), MathUtil.lerp(first.a, second.a, alpha))
end
function Color:swizzle(key)
    if type(key) ~= "string" then
        return nil
    end
    local swizzleLength = string.len(key)
    if swizzleLength > 4 or swizzleLength <= 0 then
        return nil
    end
    local swizzleVector = {}
    local i = 1
    for i = i, swizzleLength do
        local swizzleValue = rawget(self, (string.sub(key, i, i)))
        if swizzleValue == nil then
            return nil
        end
        swizzleVector[i] = swizzleValue
    end
    return swizzleVector
end
function Color.writeStreamRGB(streamId, r, g, b)
    streamWriteUIntN(streamId, math.clamp(r, 0, 1) * 1023, 10)
    streamWriteUIntN(streamId, math.clamp(g, 0, 1) * 1023, 10)
    streamWriteUIntN(streamId, math.clamp(b, 0, 1) * 1023, 10)
end
function Color.readStreamRGB(streamId)
    return streamReadUIntN(streamId, 10) / 1023, streamReadUIntN(streamId, 10) / 1023, streamReadUIntN(streamId, 10) / 1023
end
function Color.rgbToHsl(r, g, b, offset)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local l = (max + min) / 2
    local h, s
    if max == min then
        h = 0
        s = 0
    else
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)
        local h
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end
    local d = h - (offset or 0)
    if d < 0 then
    end
    return d * 2 - 1, s * 4, l * 2
end
Color.PRESETS = {
    ["TRANSPARENT"] = Color.fromPackedValue(0),
    ["ALICEBLUE"] = Color.fromPackedValue(4294965488),
    ["ANTIQUEWHITE"] = Color.fromPackedValue(4292340730),
    ["AQUA"] = Color.fromPackedValue(4294967040),
    ["AQUAMARINE"] = Color.fromPackedValue(4292149119),
    ["AZURE"] = Color.fromPackedValue(4294967280),
    ["BEIGE"] = Color.fromPackedValue(4292670965),
    ["BISQUE"] = Color.fromPackedValue(4291093759),
    ["BLACK"] = Color.fromPackedValue(4278190080),
    ["BLANCHEDALMOND"] = Color.fromPackedValue(4291685375),
    ["BLUE"] = Color.fromPackedValue(4294901760),
    ["BLUEVIOLET"] = Color.fromPackedValue(4293012362),
    ["BROWN"] = Color.fromPackedValue(4280953509),
    ["BURLYWOOD"] = Color.fromPackedValue(4287084766),
    ["CADETBLUE"] = Color.fromPackedValue(4288716383),
    ["CHARTREUSE"] = Color.fromPackedValue(4278255487),
    ["CHOCOLATE"] = Color.fromPackedValue(4280183250),
    ["CORAL"] = Color.fromPackedValue(4283465727),
    ["CORNFLOWERBLUE"] = Color.fromPackedValue(4293760356),
    ["CORNSILK"] = Color.fromPackedValue(4292671743),
    ["CRIMSON"] = Color.fromPackedValue(4282127580),
    ["CYAN"] = Color.fromPackedValue(4294967040),
    ["DARKBLUE"] = Color.fromPackedValue(4287299584),
    ["DARKCYAN"] = Color.fromPackedValue(4287335168),
    ["DARKGOLDENROD"] = Color.fromPackedValue(4278945464),
    ["DARKGRAY"] = Color.fromPackedValue(4289309097),
    ["DARKGREEN"] = Color.fromPackedValue(4278215680),
    ["DARKKHAKI"] = Color.fromPackedValue(4285249469),
    ["DARKMAGENTA"] = Color.fromPackedValue(4287299723),
    ["DARKOLIVEGREEN"] = Color.fromPackedValue(4281297749),
    ["DARKORANGE"] = Color.fromPackedValue(4278226175),
    ["DARKORCHID"] = Color.fromPackedValue(4291572377),
    ["DARKRED"] = Color.fromPackedValue(4278190219),
    ["DARKSALMON"] = Color.fromPackedValue(4286224105),
    ["DARKSEAGREEN"] = Color.fromPackedValue(4287347855),
    ["DARKSLATEBLUE"] = Color.fromPackedValue(4287315272),
    ["DARKSLATEGRAY"] = Color.fromPackedValue(4283387695),
    ["DARKTURQUOISE"] = Color.fromPackedValue(4291939840),
    ["DARKVIOLET"] = Color.fromPackedValue(4292018324),
    ["DEEPPINK"] = Color.fromPackedValue(4287829247),
    ["DEEPSKYBLUE"] = Color.fromPackedValue(4294950656),
    ["DIMGRAY"] = Color.fromPackedValue(4285098345),
    ["DODGERBLUE"] = Color.fromPackedValue(4294938654),
    ["FIREBRICK"] = Color.fromPackedValue(4280427186),
    ["FLORALWHITE"] = Color.fromPackedValue(4293982975),
    ["FORESTGREEN"] = Color.fromPackedValue(4280453922),
    ["FUCHSIA"] = Color.fromPackedValue(4294902015),
    ["GAINSBORO"] = Color.fromPackedValue(4292664540),
    ["GHOSTWHITE"] = Color.fromPackedValue(4294965496),
    ["GOLD"] = Color.fromPackedValue(4278245375),
    ["GOLDENROD"] = Color.fromPackedValue(4280329690),
    ["GRAY"] = Color.fromPackedValue(4286611584),
    ["GREEN"] = Color.fromPackedValue(4278222848),
    ["GREENYELLOW"] = Color.fromPackedValue(4281335725),
    ["HONEYDEW"] = Color.fromPackedValue(4293984240),
    ["HOTPINK"] = Color.fromPackedValue(4290013695),
    ["INDIANRED"] = Color.fromPackedValue(4284243149),
    ["INDIGO"] = Color.fromPackedValue(4286709835),
    ["IVORY"] = Color.fromPackedValue(4293984255),
    ["KHAKI"] = Color.fromPackedValue(4287424240),
    ["LAVENDER"] = Color.fromPackedValue(4294633190),
    ["LAVENDERBLUSH"] = Color.fromPackedValue(4294308095),
    ["LAWNGREEN"] = Color.fromPackedValue(4278254716),
    ["LEMONCHIFFON"] = Color.fromPackedValue(4291689215),
    ["LIGHTBLUE"] = Color.fromPackedValue(4293318829),
    ["LIGHTCORAL"] = Color.fromPackedValue(4286611696),
    ["LIGHTCYAN"] = Color.fromPackedValue(4294967264),
    ["LIGHTGOLDENRODYELLOW"] = Color.fromPackedValue(4292016890),
    ["LIGHTGRAY"] = Color.fromPackedValue(4292072403),
    ["LIGHTGREEN"] = Color.fromPackedValue(4287688336),
    ["LIGHTPINK"] = Color.fromPackedValue(4290885375),
    ["LIGHTSALMON"] = Color.fromPackedValue(4286226687),
    ["LIGHTSEAGREEN"] = Color.fromPackedValue(4289376800),
    ["LIGHTSKYBLUE"] = Color.fromPackedValue(4294626951),
    ["LIGHTSLATEGRAY"] = Color.fromPackedValue(4288252023),
    ["LIGHTSTEELBLUE"] = Color.fromPackedValue(4292789424),
    ["LIGHTYELLOW"] = Color.fromPackedValue(4292935679),
    ["LIME"] = Color.fromPackedValue(4278255360),
    ["LIMEGREEN"] = Color.fromPackedValue(4281519410),
    ["LINEN"] = Color.fromPackedValue(4293325050),
    ["MAGENTA"] = Color.fromPackedValue(4294902015),
    ["MAROON"] = Color.fromPackedValue(4278190208),
    ["MEDIUMAQUAMARINE"] = Color.fromPackedValue(4289383782),
    ["MEDIUMBLUE"] = Color.fromPackedValue(4291624960),
    ["MEDIUMORCHID"] = Color.fromPackedValue(4292040122),
    ["MEDIUMPURPLE"] = Color.fromPackedValue(4292571283),
    ["MEDIUMSEAGREEN"] = Color.fromPackedValue(4285641532),
    ["MEDIUMSLATEBLUE"] = Color.fromPackedValue(4293814395),
    ["MEDIUMSPRINGGREEN"] = Color.fromPackedValue(4288346624),
    ["MEDIUMTURQUOISE"] = Color.fromPackedValue(4291613000),
    ["MEDIUMVIOLETRED"] = Color.fromPackedValue(4286911943),
    ["MIDNIGHTBLUE"] = Color.fromPackedValue(4285536537),
    ["MINTCREAM"] = Color.fromPackedValue(4294639605),
    ["MISTYROSE"] = Color.fromPackedValue(4292994303),
    ["MOCCASIN"] = Color.fromPackedValue(4290110719),
    ["NAVAJOWHITE"] = Color.fromPackedValue(4289584895),
    ["NAVY"] = Color.fromPackedValue(4286578688),
    ["OLDLACE"] = Color.fromPackedValue(4293326333),
    ["OLIVE"] = Color.fromPackedValue(4278222976),
    ["OLIVEDRAB"] = Color.fromPackedValue(4280520299),
    ["ORANGE"] = Color.fromPackedValue(4278232575),
    ["ORANGERED"] = Color.fromPackedValue(4278207999),
    ["ORCHID"] = Color.fromPackedValue(4292243674),
    ["PALEGOLDENROD"] = Color.fromPackedValue(4289390830),
    ["PALEGREEN"] = Color.fromPackedValue(4288215960),
    ["PALETURQUOISE"] = Color.fromPackedValue(4293848751),
    ["PALEVIOLETRED"] = Color.fromPackedValue(4287852763),
    ["PAPAYAWHIP"] = Color.fromPackedValue(4292210687),
    ["PEACHPUFF"] = Color.fromPackedValue(4290370303),
    ["PERU"] = Color.fromPackedValue(4282353101),
    ["PINK"] = Color.fromPackedValue(4291543295),
    ["PLUM"] = Color.fromPackedValue(4292714717),
    ["POWDERBLUE"] = Color.fromPackedValue(4293320880),
    ["PURPLE"] = Color.fromPackedValue(4286578816),
    ["RED"] = Color.fromPackedValue(4278190335),
    ["ROSYBROWN"] = Color.fromPackedValue(4287598524),
    ["ROYALBLUE"] = Color.fromPackedValue(4292962625),
    ["SADDLEBROWN"] = Color.fromPackedValue(4279453067),
    ["SALMON"] = Color.fromPackedValue(4285694202),
    ["SANDYBROWN"] = Color.fromPackedValue(4284523764),
    ["SEAGREEN"] = Color.fromPackedValue(4283927342),
    ["SEASHELL"] = Color.fromPackedValue(4293850623),
    ["SIENNA"] = Color.fromPackedValue(4281160352),
    ["SILVER"] = Color.fromPackedValue(4290822336),
    ["SKYBLUE"] = Color.fromPackedValue(4293643911),
    ["SLATEBLUE"] = Color.fromPackedValue(4291648106),
    ["SLATEGRAY"] = Color.fromPackedValue(4287660144),
    ["SNOW"] = Color.fromPackedValue(4294638335),
    ["SPRINGGREEN"] = Color.fromPackedValue(4286578432),
    ["STEELBLUE"] = Color.fromPackedValue(4290019910),
    ["TAN"] = Color.fromPackedValue(4287411410),
    ["TEAL"] = Color.fromPackedValue(4286611456),
    ["THISTLE"] = Color.fromPackedValue(4292394968),
    ["TOMATO"] = Color.fromPackedValue(4282868735),
    ["TURQUOISE"] = Color.fromPackedValue(4291878976),
    ["VIOLET"] = Color.fromPackedValue(4293821166),
    ["WHEAT"] = Color.fromPackedValue(4289978101),
    ["WHITE"] = Color.fromPackedValue(4294967295),
    ["WHITESMOKE"] = Color.fromPackedValue(4294309365),
    ["YELLOW"] = Color.fromPackedValue(4278255615),
    ["YELLOWGREEN"] = Color.fromPackedValue(4281519514)
}