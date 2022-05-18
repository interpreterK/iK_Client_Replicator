local _game = game
local Players = _game:GetService("Players")
local Player = Players.LocalPlayer

local new = {}
function new.Sandbox(fakes, real)
	return setmetatable(fakes, {
		__index = function(self,i)
			return rawget(self, i) or real[i]
		end,
		__newindex = function(self,i,v)
			real[i] = v
		end,
		__metatable = "The metatable is locked"
	})
end
function new.FakeEvent()
	return Instance.new("BindableEvent")
end

return function (Settings)
	local FakeCharacter = require(script.Character).new(Settings)
	FakeCharacter:LoadCharacter(CFrame.new(Settings.Standing))

	local Mouse = {}
	if Player.UserId == Settings.TargetID then
		Mouse.Button1Down:Connect(function()

		end)
	else
		Mouse.Button1Down = new.FakeEvent()
		Mouse.Button1Up = new.FakeEvent()
		Mouse.Button2Down = new.FakeEvent()
		Mouse.Button2U = new.FakeEvent()
	end
	local services = {
		Players = new.Sandbox({
			LocalPlayer = Players[Settings.Target],
			localPlayer = Players[Settings.Target]
		}, Players)
	}
	function game:GetService(service)
		return services[service] or _game:GetService(service)
	end
	function game:service(...) return self:GetService(...) end
	local env = {

	}
	for global, value in next, env do
		getfenv(2)[global] = value
	end
end