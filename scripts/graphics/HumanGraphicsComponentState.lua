HumanGraphicsComponentState = {}
local HumanGraphicsComponentState_mt = Class(HumanGraphicsComponentState)
function HumanGraphicsComponentState.new(customMt)
    -- upvalues: (copy) HumanGraphicsComponentState_mt
    local self = setmetatable({}, customMt or HumanGraphicsComponentState_mt)
    self:setDefault()
    return self
end
function HumanGraphicsComponentState:setDefault()
    self.absSpeed = 0
    self.relativeVelocityX = 0
    self.relativeVelocityY = 0
    self.relativeVelocityZ = 0
    self.rotationVelocity = 0
    self.movementDirX = 0
    self.movementDirZ = 1
    self.distanceToGround = 0
    self.isCloseToGround = true
    self.isIdling = true
    self.isWalking = false
    self.isRunning = false
    self.isCrouching = false
    self.isGrounded = true
    self.isInWater = false
    self.isSwimming = false
    self.isFirstPerson = false
    self.isNPC = false
    self.isHoldingChainsaw = false
    self.isCutting = false
    self.isVerticalCut = false
    self.isStrafeWalkMode = false
end
function HumanGraphicsComponentState:drawDebug(posX, posY, textSize)
    local function renderValue(key)
        -- upvalues: (copy) self, (copy) posX, (ref) posY, (copy) textSize
        local value = self[key]
        local str
        if type(value) == "boolean" then
            str = tostring(value)
        else
            str = string.format("%.4f", value)
        end
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(posX, posY, textSize, key .. " : ")
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(posX, posY, textSize, str)
        posY = posY - textSize - 2 * g_pixelSizeY
    end
    renderValue("absSpeed")
    renderValue("movementDirX")
    renderValue("movementDirZ")
    renderValue("relativeVelocityX")
    renderValue("relativeVelocityY")
    renderValue("relativeVelocityZ")
    renderValue("rotationVelocity")
    renderValue("distanceToGround")
    renderValue("isCloseToGround")
    renderValue("isIdling")
    renderValue("isWalking")
    renderValue("isRunning")
    renderValue("isCrouching")
    renderValue("isGrounded")
    renderValue("isInWater")
    renderValue("isSwimming")
    renderValue("isStrafeWalkMode")
    renderValue("isNPC")
    renderValue("isFirstPerson")
    renderValue("isHoldingChainsaw")
    renderValue("isCutting")
    renderValue("isVerticalCut")
end