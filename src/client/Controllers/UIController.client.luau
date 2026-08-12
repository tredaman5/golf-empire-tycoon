local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "GolfEmpireUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Position = UDim2.fromOffset(20, 20)
cashLabel.Size = UDim2.fromOffset(230, 54)
cashLabel.BackgroundColor3 = Color3.fromRGB(20, 55, 30)
cashLabel.BackgroundTransparency = 0.1
cashLabel.TextColor3 = Color3.new(1, 1, 1)
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextScaled = true
cashLabel.Parent = gui

local feedbackLabel = Instance.new("TextLabel")
feedbackLabel.Name = "FeedbackLabel"
feedbackLabel.AnchorPoint = Vector2.new(0.5, 0)
feedbackLabel.Position = UDim2.fromScale(0.5, 0.08)
feedbackLabel.Size = UDim2.fromOffset(440, 48)
feedbackLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
feedbackLabel.BackgroundTransparency = 0.15
feedbackLabel.TextColor3 = Color3.new(1, 1, 1)
feedbackLabel.Font = Enum.Font.GothamSemibold
feedbackLabel.TextScaled = true
feedbackLabel.Visible = false
feedbackLabel.Parent = gui

local function updateCash()
	local cash = player:GetAttribute("Cash")
	cashLabel.Text = `Cash: ${if typeof(cash) == "number" then cash else 0}`
end

local feedbackVersion = 0
local function showFeedback(message)
	if typeof(message) ~= "string" then
		return
	end
	feedbackVersion += 1
	local version = feedbackVersion
	feedbackLabel.Text = message
	feedbackLabel.Visible = true
	task.delay(3, function()
		if feedbackVersion == version then
			feedbackLabel.Visible = false
		end
	end)
end

player:GetAttributeChangedSignal("Cash"):Connect(updateCash)
updateCash()

player:GetAttributeChangedSignal("StatusMessage"):Connect(function()
	showFeedback(player:GetAttribute("StatusMessage"))
end)
local initialStatus = player:GetAttribute("StatusMessage")
if initialStatus then
	showFeedback(initialStatus)
end

local remotes = ReplicatedStorage:WaitForChild("GolfEmpireRemotes")
remotes:WaitForChild("Feedback").OnClientEvent:Connect(showFeedback)
