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
local managementEvent = remotes:WaitForChild("Management")

local dashboard = Instance.new("Frame")
dashboard.Name = "BusinessDashboard"
dashboard.AnchorPoint = Vector2.new(1, 0.5)
dashboard.Position = UDim2.fromScale(0.98, 0.5)
dashboard.Size = UDim2.fromOffset(330, 360)
dashboard.BackgroundColor3 = Color3.fromRGB(20, 48, 30)
dashboard.Visible = false
dashboard.Parent = gui

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = dashboard

local function makeDashboardText(text, height)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, height)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamSemibold
	label.TextScaled = true
	label.Text = text
	label.Parent = dashboard
	return label
end

makeDashboardText("GOLF BUSINESS", 48)
local statsLabel = makeDashboardText("", 110)
makeDashboardText("Pricing Strategy", 30)
for _, strategyName in { "Value", "Standard", "Premium" } do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -30, 0, 42)
	button.BackgroundColor3 = Color3.fromRGB(45, 105, 60)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Text = strategyName
	button.Parent = dashboard
	button.Activated:Connect(function()
		managementEvent:FireServer("SetPricing", strategyName)
	end)
end
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(1, -30, 0, 36)
closeButton.Text = "Close"
closeButton.Parent = dashboard
closeButton.Activated:Connect(function() dashboard.Visible = false end)

local function updateDashboard()
	statsLabel.Text = `Strategy: {player:GetAttribute("PricingStrategy") or "Standard"}\nCustomers: {player:GetAttribute("CustomersServed") or 0}\nLifetime Revenue: ${player:GetAttribute("LifetimeRevenue") or 0}\nQueue: {player:GetAttribute("QueueLength") or 0} | Bays Busy: {player:GetAttribute("BaysOccupied") or 0}`
end
for _, attribute in { "PricingStrategy", "CustomersServed", "LifetimeRevenue", "QueueLength", "BaysOccupied" } do
	player:GetAttributeChangedSignal(attribute):Connect(updateDashboard)
end
managementEvent.OnClientEvent:Connect(function(action)
	if action == "Open" then updateDashboard(); dashboard.Visible = true end
end)
updateDashboard()
