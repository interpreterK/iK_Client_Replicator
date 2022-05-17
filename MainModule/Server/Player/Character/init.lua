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

function Character.new(Settings, AnimateRig, TeamSpawns)
    Character.__t = Settings
    Character.AnimateRig = AnimateRig
    Character.TeamSpawns = TeamSpawns
    Character.IsTheReplicator = Player.UserId == Settings.TargetID
    Character.ReplicatorOBJ = GetTargeted(Character)
    Character.Model = WaitForChildOfClass(Character.ReplicatorOBJ, "Model"):Clone()
    return setmetatable({real = true}, Character)
end

local CurrentModel
local function RigAnimations(self, Humanoid)
    assert(Humanoid, "A humanoid is required to aniamte its rig")
    if CurrentModel then
        coroutine.wrap(function()
            if Packages then
                if not self.EmoteBind then
                    self.EmoteBind = new("BindableFunction")
                end
                require(Packages[Humanoid.RigType.Name])(CurrentModel, self.EmoteBind)
            end
        end)()
    else
        warn("No model for rig animations")
    end
end

function Character:LoadCharacter(Respawning, Standing)
    if CurrentModel then
        pcall(game.Destroy, CurrentModel)
    end
    local NetworkGate = require(script.NetworkGate)
    local Actions = require(script.Actions)
    if Respawning then
        if self.IsTheReplicator then
            NetworkGate:Out("Respawn")
        end
    else
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
    end

    local CharacterModel = self.Model:Clone()
    local HumanoidRootPart = CharacterModel:WaitForChild("HumanoidRootPart")
    local Humanoid = CharacterModel:WaitForChild("Humanoid")
    CharacterModel.Archivable = false
    CharacterModel.Name = self.__t.Target
    CurrentModel = CharacterModel

    local HostConnection = Players:FindFirstChild(self.__t.Target)
    if self.IsTheReplicator then
        --Some base roblox mechanics that get ignored for the client
        local Roblox_Patches = require(script.RobloxFunctions)
        local Patches = Roblox_Patches.new({
            Host = HostConnection,
            TeamSpawns = Use_Team_Spawns,
            Character = CharacterModel, 
            Root = HumanoidRootPart,
            Humanoid = Humanoid
        })
        --Configure the host
        local HostGate = require(script.HostGate)
        if not Respawning then
            HostTracking = HostGate.newHost(Patches)
            HostTracking:StreamToServer()
        else
            if HostGate.init and HostTracking then
                HostTracking:ApplyNewRig(Patches)
            else
                --For some reason if the tracker didn't initialize before
                HostTracking = HostGate.newHost(Patches)
                HostTracking:StreamToServer()
            end
        end
        if not Standing then
            Standing = Patches:MapRespawn()
        end
        HumanoidRootPart.CFrame = Standing
        workspace.CurrentCamera.CameraSubject = Humanoid
        Humanoid.Died:Connect(function()
            NetworkGate:Out("Health", 0)
            wait(Players.RespawnTime)
            self:LoadCharacter(true, Patches:MapRespawn())
        end)
    else
        self.Velocity = Instance.new("BodyVelocity")
        self.Velocity.MaxForce = Vector3.one * math.huge
        self.Velocity.Velocity = Vector3.zero
        self.Velocity.Parent = HumanoidRootPart
    end
    HostConnection.Character = CharacterModel
    CharacterModel.Parent = workspace
    if self.AnimateRig then
        RigAnimations(self, Humanoid)
    end
    Actions.init(self.Velocity, HumanoidRootPart, Humanoid, self.EmoteBind)
end

return Character