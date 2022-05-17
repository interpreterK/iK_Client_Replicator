local Patches = {}
Patches.__index = Patches
Patches.__metatable = nil

local rand, randomseed = math.random, math.randomseed
local insert = table.insert

local S = setmetatable({},{__index = function(_,v) return game:GetService(v) end})
local DEB = S.Debris
local UIS = S.UserInputService

local CharacterModule = require(script.Parent)
local NetworkGate = require(script.Parent.NetworkGate)

function Patches.new(lazy_DataTable)
	local self = {}
    self.Root = lazy_DataTable.Root
    self.Humanoid = lazy_DataTable.Humanoid
	self.Player = lazy_DataTable.Host
	self.Character = lazy_DataTable.Character
	self.TeamSpawns = lazy_DataTable.TeamSpawns
	return setmetatable(self, Patches)
end

local function new(inst, parent, props)
    local newInst = Instance.new(inst)
    for prop, value in next, props or {} do
        newInst[prop] = value
    end
    newInst.Parent = parent
    return newInst
end

local function GetMapSpawnLocation(self)
    if self.Player.RespawnLocation then
    	return self.Player.RespawnLocation
    end
    local game_space, spawns = workspace:GetDescendants(), {}
    for i = 1, #game_space do
        if game_space[i]:IsA("SpawnLocation") then
            if self.TeamSpawns then
                if self.Player.Team then
                    if game_space[i].TeamColor == self.Player.TeamColor then
                        insert(spawns, game_space[i])
                    end
                else
                    if game_space[i].Neutral then
                        insert(spawns, game_space[i])
                    end
                end
            else
                if game_space[i].Neutral then
                    insert(spawns, game_space[i])
                end
            end
        end
    end
    randomseed(tick())
    return #spawns ~= 0 and spawns[rand(1, #spawns)]
end

local JumpRequest, OccupiedSeat
local Sticks = {}
local SitDebounce = false
local sParams = RaycastParams.new()
sParams.FilterType = Enum.RaycastFilterType.Blacklist
local function FakeSitting(self, Root, Humanoid)
    local P = self.Root.Position
    local function Sit(Seat)
        if not SitDebounce and not self.Humanoid.Sit then
            local Soffset, X = Vector3.new(0, Seat.Size.Y + 1, 0), CFrame.new(Seat.Position)
            local Face = CFrame.lookAt(Seat.Position, Seat.Position + Seat.CFrame.LookVector)
            local Stick = Instance.new("Weld")
            Stick.Part0 = Seat
            Stick.Part1 = self.Root
            Stick.C0 = Seat.CFrame:Inverse() * X
            Stick.C1 = Face:Inverse() * X - Soffset
            Stick.Parent = self.Root
            insert(Sticks, Stick)

            self.Humanoid.Sit = true
            SitDebounce = true
            NetworkGate:Out("OccupieSeat", Seat, true)
            OccupiedSeat = Seat
        end
    end

    sParams.FilterDescendantsInstances = {self.Character}
    --Let's fix the raycast for legs soon if there are not any
    local sitRay = workspace:Raycast(P, Vector3.new(0, -3, 0), sParams)
    if sitRay then
        local i = sitRay.Instance
        if i and (i:IsA("Seat") or i:IsA("VehicleSeat")) and not i.Disabled then
            Sit(i)
        end
    end
end

function Patches:MapRespawn()
    local Spawn = GetMapSpawnLocation(self)
    if Spawn then
        DEB:AddItem(new("ForceField", self.Character, {Visible = true}), Spawn.Duration)
    end
    return Spawn and Spawn.CFrame or CFrame.new(0, 100, 0)
end

function Patches:SitMechanics()
	if not Patches.Sit_init then
		Patches.Sit_init = true
		JumpRequest = UIS.JumpRequest:Connect(function()
			if SitDebounce then
                pcall(function()
                    for i = 1, #Sticks do
                        Sticks[i].Enabled = false
                        pcall(game.Destroy, Sticks[i])
                    end
                end)
                NetworkGate:Out("OccupieSeat", OccupiedSeat, false)
                OccupiedSeat = nil
                task.wait(3)
                SitDebounce = false
            end
        end)
	end
	FakeSitting(self, CharacterModule.HumanoidRootPart, CharacterModule.Humanoid)
end

function Patches:VoidRespawn()
    if self.Root.Position.Y <= workspace.FallenPartsDestroyHeight / 1.1 then
        CharacterModule:LoadCharacter(true)
    end
end

return Patches