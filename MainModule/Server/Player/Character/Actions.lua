local Actions = {
    Guest = {},
    Host = {},
    Parallel = {},
    --ETC zone
    __char = {}
}
Actions.__index = Actions
Actions.__metatable = nil

local S = setmetatable({},{__index = function(_,v) return game:GetService(v) end})
local TS = S.TweenService

local Character = require(script.Parent)

function Actions.init(VelocityMover, RootPart, Humanoid, EmoteBind)
    Actions.__char.VelocityMover = VelocityMover
    Actions.__char.RootPart = RootPart
    Actions.__char.Humanoid = Humanoid
    Actions.__char.Emote = EmoteBind
end

function Actions.Guest.Move(Meta)
    local self, FrameSmoothing = Actions.__char, 0.1
    self.VelocityMover.Velocity = Meta.__v
    TS:Create(self.RootPart, TweenInfo.new(FrameSmoothing, Enum.EasingStyle.Linear), {CFrame = Meta.__c}):Play()
end

function Actions.Guest.Health(Health)
    local self = Actions.__char
    self.Humanoid.Health = Health
end

function Actions.Guest.Respawn()
    Character:LoadCharacter(true)
end

function Actions.Parallel.Emote(emote)
    local self = Actions.__char
    return self.Emote:Invoke(emote) 
end

return Actions