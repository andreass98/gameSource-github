DebugFlag = {}
local DebugFlag_mt = Class(DebugFlag, DebugElement)
function DebugFlag.new(customMt)
    -- upvalues: (copy) DebugFlag_mt
    local self = DebugFlag:superClass().new(customMt or DebugFlag_mt)
    self.dirX = 0
    self.dirZ = 1
    self.postHeight = 4
    self.flagHeight = 0.7
    self.flagLength = 1
    self.numSectionsY = 4
    self.numSectionsZ = 6
    self.text = nil
    return self
end
function DebugFlag:create(x, y, z, dirX, dirZ)
    self.x = x
    self.y = y
    self.z = z
    self.dirX = dirX
    self.dirZ = dirZ
    return self
end
function DebugFlag:createWithNode(node, alignToGround)
    local x, y, z = getWorldTranslation(node)
    if alignToGround and g_terrainNode ~= nil then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z)
    end
    local dirX, _, dirZ = localDirectionToWorld(node, 0, 0, 1)
    self:create(x, y, z, dirX, dirZ)
    return self
end
function DebugFlag:draw()
    DebugFlag.renderAtPosition(self.x, self.y, self.z, self.dirX, self.dirZ, self.color, self.text, self.postHeight, self.flagHeight, self.flagLength, self.numSectionsY, self.numSectionsZ)
end
function DebugFlag.renderAtNode(node, dirX, dirZ, color, text, postHeight, flagHeight, flagLength, numSectionsY, numSectionsZ)
    local x, y, z = getWorldTranslation(node)
    if dirX == nil or dirZ == nil then
        dirX, _, dirZ = localDirectionToWorld(node, 1, 0, 0)
    end
    DebugFlag.renderAtPosition(x, y, z, dirX, dirZ, color, text, postHeight, flagHeight, flagLength, numSectionsY, numSectionsZ)
end
function DebugFlag.renderAtPosition(x, y, z, dirX, dirZ, color, text, postHeight, flagHeight, flagLength, numSectionsY, numSectionsZ)
    dirX = dirX or 0
    dirZ = dirZ or 1
    local r, g, b, a = (color or Color.PRESETS.WHITE):unpack()
    postHeight = postHeight or 4
    flagHeight = flagHeight or 0.7
    flagLength = flagLength or 1
    numSectionsY = numSectionsY or 4
    numSectionsZ = numSectionsZ or 6
    drawDebugLine(x, y, z, r, g, b, x, y + postHeight, z, r, g, b)
    local i = 1
    for i = i, numSectionsZ do
        local offset = flagLength * (i / numSectionsZ)
        local lx = x + dirX * offset
        local lz = z + dirZ * offset
        drawDebugLine(lx, y + postHeight - flagHeight, lz, r, g, b, lx, y + postHeight, lz, r, g, b)
    end
    local i = 0
    for i = i, numSectionsY do
        local lx = posYStart + flagHeight * (i / numSectionsY)
        drawDebugLine(x, lx, z, r, g, b, x + dirX * flagLength, lx, z + dirZ * flagLength, r, g, b)
    end
    if text ~= nil then
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
        Utils.renderTextAtWorldPosition(x, y + postHeight * 1.05, z, text, 0.02, 0, r, g, b, a)
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
    end
end