local Tracker = {init = false}
Tracker.__index = Tracker
Tracker.__metatable = nil

local S = setmetatable({},{__index = function(_,v) return game:GetService(v) end})
local RS = S.RunService
local UIS = S.UserInputService

local NetworkGate = require(script.Parent.NetworkGate)
local Step_Connection

function Tracker.newHost(Patches)
    assert(not Tracker.init, "Tracking is already initialized")
    Tracker.init = true
    local self = {}
    self.PreConfiged_Patches = Patches
    self.Host = self.PreConfiged_Patches.Host
    self.Character = self.PreConfiged_Patches.Character
    self.Root = self.PreConfiged_Patches.Root
    self.Humanoid = self.PreConfiged_Patches.Humanoid
    return setmetatable(self, Tracker)
end

function Tracker:ApplyNewRig(Patches)
    self.PreConfiged_Patches = Patches
    self.Host = self.PreConfiged_Patches.Host
    self.Character = self.PreConfiged_Patches.Character
    self.Root = self.PreConfiged_Patches.Root
    self.Humanoid = self.PreConfiged_Patches.Humanoid
end

function Tracker:StreamToServer()
    assert(self.Character, "No character is initialized")
    local function HostMove(self)
        NetworkGate:Out("Move", {
            __v = self.Root:GetVelocityAtPosition(self.Root.Position),
            __c = self.Root.CFrame
        })
    end
    if Step_Connection then
        Step_Connection:Disconnect()
    end
    --[[
    https://devforum.roblox.com/t/runservicenetworkstepped-event/12154
    https://devforum.roblox.com/t/release-notes-for-337/125038/16
    ]]
    Step_Connection = RS.Heartbeat:Connect(function()
        --Customize your options if needed
        self.PreConfiged_Patches:VoidRespawn()
        --Disabled for the sandboxed branch.
        --self.PreConfiged_Patches:SitMechanics()
        --
        HostMove(self)
    end)
end

return Tracker