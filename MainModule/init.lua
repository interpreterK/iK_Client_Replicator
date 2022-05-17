local Players = game:GetService("Players")
local Server = require(script:WaitForChild("Server"))

return function (Player)
    Player = Players:FindFirstChild(Player)
    if Player then
        local Replicator = Server.new(Player)
        Replicator:init()
    end
end