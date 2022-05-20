local Players = game:GetService("Players")
local Server = require(script:WaitForChild("Server"))

return function (Player, ConvertToR6)
    Player = Players:FindFirstChild(Player)
    if Player then
        local Replicator = Server.new(Player, ConvertToR6)
        Replicator:init()
    end
end