GameStateManager = {}
local GameStateManager_mt = Class(GameStateManager)
function GameStateManager.new(customMt)
    -- upvalues: (copy) GameStateManager_mt
    local self = setmetatable({}, customMt or GameStateManager_mt)
    self.gameState = GameState.STARTING
    return self
end
function GameStateManager.getGameStateIndexByName(_, name)
    if name == nil then
        return nil
    end
    name = string.upper(name)
    return GameState[name]
end
function GameStateManager:setGameState(newState)
    if newState ~= nil and self.gameState ~= newState then
        g_messageCenter:publish(MessageType.GAME_STATE_CHANGED, newState, self.gameState)
        self.gameState = newState
    end
end
function GameStateManager:getGameState()
    return self.gameState
end
g_gameStateManager = GameStateManager.new()