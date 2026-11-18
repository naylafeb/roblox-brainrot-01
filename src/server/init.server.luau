-- Brainrot Bay server entry: start the game server. Every other server
-- module is wired up from GameServer.

local GameServer = require(script:WaitForChild("GameServer"))

GameServer.init()
print("Brainrot Bay server started.")
