local Character = {}
Character.__index = Character
Character.__metatable = nil

-- Customizing variables
local Use_Team_Spawns = true --Is spawning at a location based on team assignment relevant?
--

local S = setmetatable({},{__index = function(_,v) return game:GetService(v) end})
local Storage = S.ReplicatedStorage
local Players = S.Players

local rand = math.random
local insert = table.insert
local wait = task.wait

local Player = Players.LocalPlayer
local Packages = script:FindFirstChild("Rigs")
local HostTracking

local function GetTargeted(self)
    local function GetRealPath()
        local DCSCE = Storage:WaitForChild("DefaultChatSystemChatEvents", 1.5)
        assert(DCSCE, "Couldn't get the real path. DCSCE="..tostring(DCSCE))
        return DCSCE
    end
    local Path = GetRealPath()
    local DE = Path:GetDescendants()
    for i = 1, #DE do
        if DE[i]:IsA("Actor") then
            self.RealPath = DE[i]
            break
        end
    end
    assert(self.RealPath, "RealPath does not exist or is in the wrong context. RealPath="..tostring(self.RealPath))
    
    local function GetAssignedActor()
        for _,v in next, self.RealPath:GetAttributes() do
            if v == self.__t.TargetID then
                return self.RealPath
            end
        end
        return nil
    end
    local ReplicatorOBJ = GetAssignedActor()
    assert(ReplicatorOBJ, "ReplicatorOBJ is not present. ReplicatorOBJ="..tostring(ReplicatorOBJ))
    return ReplicatorOBJ
end

local function new(inst, parent, props)
    local newInst = Instance.new(inst)
    for prop, value in next, props or {} do
        newInst[prop] = value
    end
    newInst.Parent = parent
    return newInst
end

local function WaitForChildOfClass(Parent, Class)
    local c = Parent:FindFirstChildOfClass(Class)
    while not c or c.ClassName ~= Class do
        c = Parent.ChildAdded:Wait()
    end
    return c
end

function Character.new(Settings)
    Character.__t = Settings
    Character.IsTheReplicator = Player.UserId == Settings.TargetID
    Character.ReplicatorOBJ = GetTargeted(Character)
    Character.Model = WaitForChildOfClass(Character.ReplicatorOBJ, "Model"):Clone()
    return setmetatable({real = true}, Character)
end

local CurrentModel

function Character:LoadCharacter(Standing)
    local NetworkGate, Actions = require(script.NetworkGate), require(script.Actions)
    local Network = NetworkGate.new(Character.ReplicatorOBJ)

    Network.Remote.OnClientEvent:Connect(function(Action, ...)
        local Par_Act = Actions.Parallel[Action]
        if Par_Act then
            Par_Act(...)
        else
            local Type = not self.IsTheReplicator and "Guest" or "Host"
            local Act = Actions[Type][Action]
            if Act then
                Act(...)
            end
        end
    end)

    local CharacterModel = self.Model:Clone()
    local HumanoidRootPart = CharacterModel:WaitForChild("HumanoidRootPart")
    local Humanoid = CharacterModel:WaitForChild("Humanoid")
    CharacterModel.Archivable = false
    CharacterModel.Name = self.__t.Target
    CurrentModel = CharacterModel

    local HostConnection = Players:FindFirstChild(self.__t.Target)
    if self.IsTheReplicator then
        local Roblox_Patches, HostGate = require(script.RobloxFunctions), require(script.HostGate)
        local Patches = Roblox_Patches.new({
            Host = HostConnection,
            TeamSpawns = nil,
            Character = CharacterModel, 
            Root = HumanoidRootPart,
            Humanoid = Humanoid
        })
        --Configure the host
        HostTracking = HostGate.newHost(Patches)
        HostTracking:StreamToServer()
        HumanoidRootPart.CFrame = Standing
        workspace.CurrentCamera.CameraSubject = Humanoid
    else
        self.Velocity = Instance.new("BodyVelocity")
        self.Velocity.MaxForce = Vector3.one * math.huge
        self.Velocity.Velocity = Vector3.zero
        self.Velocity.Parent = HumanoidRootPart
    end
    if HostConnection then
        HostConnection.Character = CharacterModel
    end
    CharacterModel.Parent = workspace
    Actions.init(self.Velocity, HumanoidRootPart, Humanoid, self.EmoteBind)
end

return Character