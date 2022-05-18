task.wait()
script.Parent = nil
if not game:IsLoaded() then
    game.Loaded:Wait()
end
local Settings = {Target = script:GetAttribute("Target"), TargetID = script:GetAttribute("TargetID"), Standing = script:GetAttribute("Standing")}
require(script.Sandbox)(Settings)(Settings)