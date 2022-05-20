local Gate = {Clients = {}}
Gate.__index = Gate
Gate.__metatable = nil

function Gate.new(Path)
    Gate.Remote = Path:FindFirstChildOfClass("RemoteEvent")
    Gate.Invoker = Path:FindFirstChildOfClass("RemoteFunction")
    return setmetatable({}, Gate)
end

function Gate:Out(...)
    assert(self.Remote, "Please create a new network gate before calling :Out")
    self.Remote:FireServer(...)
end

function Gate:Out_Return(...)
    assert(self.Invoker, "Please create a new network gate before calling :Out_Return")
    return self.Invoker:InvokeServer(...)
end

return Gate