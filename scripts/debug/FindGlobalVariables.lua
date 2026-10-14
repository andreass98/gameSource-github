g_globalsNameCheckDisabled = false
local allowlist = {
    ["io"] = true,
    ["modOnCreate"] = true,
    ["debug"] = true,
    ["masterServerConnectFront"] = true,
    ["masterServerConnectBack"] = true,
    ["masterServerAddServer"] = true,
    ["masterServerAddServerModStart"] = true,
    ["masterServerAddServerMod"] = true,
    ["masterServerAddServerModEnd"] = true,
    ["masterServerRequestConnectionToServer"] = true,
    ["netConnect"] = true
}
setmetatable(_G, {
    ["__newindex"] = function(t, key, value)
        -- upvalues: (copy) allowlist
        if not g_globalsNameCheckDisabled and (type(key) == "string" and (type(value) ~= "function" and (allowlist[key] == nil and (key < "A" or key > "Z")))) and not string.startsWith(key, "g_") then
            printWarning("Warning: Global variable name does not match naming convention: " .. key)
            printCallstack()
        end
        rawset(t, key, value)
    end
})
printWarning("\n\n  ##################   Warning: Globals name check active!   ##################\n\n")