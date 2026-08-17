local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
feedbackLabel.Size = UDim2.fromOffset(360, 40)
feedbackLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
feedbackLabel.BackgroundTransparency = 0.15
feedbackLabel.TextColor3 = Color3.new(1, 1, 1)
feedbackLabel.Font = Enum.Font.GothamSemibold
feedbackLabel.TextSize = 22
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
local customerAnimationEvent = remotes:WaitForChild("CustomerAnimation")
local customerAnimationVersions = setmetatable({}, { __mode = "k" })

local function animateCustomer(customer, action, version)
	if typeof(customer) ~= "Instance" or not customer:IsA("Model") or not customer.Parent then return end
	local clubGrip = customer:FindFirstChild("GolfClubGrip", true)
	local rightShoulder = customer:FindFirstChild("RightShoulder", true)
	local leftShoulder = customer:FindFirstChild("LeftShoulder", true)
	local waist = customer:FindFirstChild("Waist", true)
	if not clubGrip then return end
	if action == "Reset" then
		clubGrip.Transform = CFrame.identity
		if rightShoulder then rightShoulder.Transform = CFrame.identity end
		if leftShoulder then leftShoulder.Transform = CFrame.identity end
		if waist then waist.Transform = CFrame.identity end
		return
	end
	local isPutter = action == "Putt"
	local targets = {
		Back = {
			Club = if isPutter then CFrame.Angles(math.rad(-20), 0, math.rad(-45)) else CFrame.Angles(math.rad(-50), math.rad(35), math.rad(-145)),
			Right = CFrame.Angles(if isPutter then math.rad(-25) else math.rad(-80), 0, math.rad(-25)),
			Left = CFrame.Angles(if isPutter then math.rad(-18) else math.rad(-55), 0, math.rad(20)),
			Waist = CFrame.Angles(0, if isPutter then math.rad(10) else math.rad(35), 0),
		},
		Follow = {
			Club = if isPutter then CFrame.Angles(math.rad(20), 0, math.rad(45)) else CFrame.Angles(math.rad(45), math.rad(-30), math.rad(135)),
			Right = CFrame.Angles(if isPutter then math.rad(25) else math.rad(70), 0, math.rad(30)),
			Left = CFrame.Angles(if isPutter then math.rad(18) else math.rad(50), 0, math.rad(-20)),
			Waist = CFrame.Angles(0, if isPutter then math.rad(-10) else math.rad(-35), 0),
		},
	}
	local function pose(target, duration)
		local starts = {
			Club = clubGrip.Transform,
			Right = rightShoulder and rightShoulder.Transform,
			Left = leftShoulder and leftShoulder.Transform,
			Waist = waist and waist.Transform,
		}
		local startedAt = os.clock()
		while customer.Parent and customerAnimationVersions[customer] == version do
			local alpha = math.min((os.clock() - startedAt) / duration, 1)
			clubGrip.Transform = starts.Club:Lerp(target.Club, alpha)
			if rightShoulder then rightShoulder.Transform = starts.Right:Lerp(target.Right, alpha) end
			if leftShoulder then leftShoulder.Transform = starts.Left:Lerp(target.Left, alpha) end
			if waist then waist.Transform = starts.Waist:Lerp(target.Waist, alpha) end
			if alpha >= 1 then break end
			RunService.RenderStepped:Wait()
		end
	end
	pose(targets.Back, if isPutter then 0.6 else 0.8)
	pose(targets.Follow, if isPutter then 0.4 else 0.32)
	pose({ Club = CFrame.identity, Right = CFrame.identity, Left = CFrame.identity, Waist = CFrame.identity }, 0.5)
end

customerAnimationEvent.OnClientEvent:Connect(function(customer, action)
	local version = (customerAnimationVersions[customer] or 0) + 1
	customerAnimationVersions[customer] = version
	task.spawn(animateCustomer, customer, action, version)
end)

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
