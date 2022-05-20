local Server = {RBXSignals = {}}
Server.__index = Server

local S = setmetatable({},{__index = function(_,v) return game:GetService(v) end})
local Storage = S.ReplicatedStorage
local Players = S.Players
local RS = S.RunService

local char, rep = string.char, string.rep
local rand = math.random
local insert = table.insert

local Chars = {}
local ChatCompiler = require(script.ChatCompiler)

function Server.new(Host, UseR6)
	local self = {}
	self.Host = Host
	self.UseR6 = UseR6
	return setmetatable(self, Server)
end

local function WaitForChildOfClass(Parent, Class)
    local c = Parent:FindFirstChildOfClass(Class)
    while not c or c.ClassName ~= Class do
        c = Parent.ChildAdded:Wait()
    end
    return c
end

local function SetAttributes(Inst, Attrs)
	for AT_Name, AT_Value in next, Attrs do
		Inst:SetAttribute(AT_Name, AT_Value)
	end
end

local function LoadClient(self, Client)
	coroutine.wrap(function()
		local Package = script:WaitForChild("Player"):Clone()
		Package.Name = Client.Name
		SetAttributes(Package, {
			Target = self.Host.Name,
			TargetID = self.Host.UserId,
			Standing = self.StandingRoot
		})
		Package.Parent = WaitForChildOfClass(Client, "PlayerGui")

		if Client.UserId == self.Host.UserId then
			local Chat = ChatCompiler.new(Client, self.Remote)
			Client.Chatted:Connect(function(str)
				Chat:CompileString(str)
			end)
		end
	end)()
end

local function LogSignal(self, RBXSignal)
	insert(self.RBXSignals, RBXSignal)
end

local function ServerRemotes(self, Remote, Function)
	local RemoteActions, FunctionActions = {}, {}
	function RemoteActions.Move(...)
		self.Root.CFrame = ({...})[1].__c
		Remote:FireAllClients("Move", ...)
	end
	function RemoteActions.OccupieSeat(Seat, Sitting)
		if Seat then
			Seat.Disabled = Sitting
		end
	end

	LogSignal(self, Remote.OnServerEvent:Connect(function(Player, Action, ...)
		if Player.UserId == self.Host.UserId then
			local custom_ACT = RemoteActions[Action]
			if custom_ACT then
				custom_ACT(...)
			else
				Remote:FireAllClients(Action, ...)
			end
		end
	end))
	self.Remote = Remote
end

function Server:init()
	assert(self.Host, "No host is specified for :init")
	local HostCharacter = self.Host.Character
	insert(Chars, HostCharacter)

	local function r_str(rep)
	    local s = ''
	    for i = 1, rep or rand(10, 30) do
	        s = s .. char(({rand(48, 57),rand(65, 90),rand(97, 122)})[rand(1, 3)])
	    end
	    return s
	end
	local function fakeName()
	    return rep("\n", rand(10, 100)) .. "\t"
	end

	local function Character(self)
		if self.UseR6 then
			local function GenerateHdescription()
				local b, M = pcall(Players.CreateHumanoidModelFromUserId, Players, self.Host.UserId)
			    if not b then
			        warn(M)
			    end
			    return M
			end
			local Humanoid = HostCharacter:FindFirstChildOfClass("Humanoid")
			if Humanoid and Humanoid.RigType ~= Enum.HumanoidRigType.R6 then
				local Description = Humanoid:GetAppliedDescription() or GenerateHdescription()
				local b, M = pcall(Players.CreateHumanoidModelFromDescription, Players, Description, Enum.HumanoidRigType.R6)
			    if not b then
			        warn(M)
			    else
			    	return M:Clone()
			    end
			    return nil
			end
		end
		if not HostCharacter then
			self.Host:LoadCharacter()
			HostCharacter = self.Host.Character
		end
		HostCharacter.Archivable = true
		return HostCharacter:Clone()
	end

	local function new(inst, parent, props)
		local newInst = Instance.new(inst)
		for prop, value in next, props or {} do
			newInst[prop] = value
		end
		newInst.Parent = parent
		return newInst
	end

	local function fakePath()
	    local t = Storage:WaitForChild("DefaultChatSystemChatEvents", 3)
	    local tc = t and t:GetChildren()
	    return t and tc[rand(1, #tc)]
	end

	local Path, StorageChar = fakePath(), Character(self)
	local FlushChar = StorageChar:GetDescendants()
	for i = 1, #FlushChar do
		if FlushChar[i]:IsA("LuaSourceContainer") or FlushChar[i]:IsA("ForceField") then
			FlushChar[i]:Destroy()
		end
	end

	local Root = StorageChar:WaitForChild("HumanoidRootPart")
	self.Root = Root
	self.StandingRoot = self.Root.Position
	HostCharacter.Archivable = false

	local Actor = new("Actor", Path, {Name = fakeName(), Archivable = false})
	local Remote = new("RemoteEvent", Actor, {Name = fakeName(), Archivable = false})
	local Function = new("RemoteFunction", Actor, {Name = fakeName(), Archivable = false})
	Actor:SetAttribute(r_str(), self.Host.UserId)
	StorageChar.Name = fakeName()
	StorageChar.Parent = Actor

	ServerRemotes(self, Remote, Function)

	local PlayersList = Players:GetPlayers()
	LogSignal(self, Players.PlayerAdded:Connect(function(client)
		LoadClient(self, client)
	end))
	for i = 1, #PlayersList do
		LoadClient(self, PlayersList[i])
	end
end

RS.Heartbeat:Connect(function()
	pcall(function()
		for i = 1, #Chars do
			pcall(function()
				Chars[i]:MoveTo(Vector3.new(9e5, 9e5, 9e5))
				Chars[i].HumanoidRootPart.Anchored = true
			end)
		end
	end)
end)

return Server