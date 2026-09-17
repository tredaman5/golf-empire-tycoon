local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "GolfEmpireUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local Theme = {
	Panel = Color3.fromRGB(22, 30, 27),
	PanelBorder = Color3.fromRGB(70, 150, 95),
	Accent = Color3.fromRGB(225, 190, 65),
	Button = Color3.fromRGB(35, 95, 55),
	ButtonClose = Color3.fromRGB(60, 68, 66),
	Text = Color3.new(1, 1, 1),
	TextDark = Color3.fromRGB(20, 20, 20),
	CornerRadius = UDim.new(0, 10),
	HeaderFont = Enum.Font.GothamBold,
	BodyFont = Enum.Font.GothamSemibold,
}

local function applyPanelStyle(instance, borderColor)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.CornerRadius
	corner.Parent = instance
	local stroke = Instance.new("UIStroke")
	stroke.Color = borderColor or Theme.PanelBorder
	stroke.Thickness = 2
	stroke.Parent = instance
end

-- Sound Ids come from Config.Sounds (see Config.luau) so swapping in real
-- Toolbox assets never requires touching this file.
local activeSoundCounts = {}

local function playSound(name, parent)
	local settings = Config.Sounds[name]
	if not settings or not settings.Id or settings.Id == "rbxassetid://0" then
		return nil
	end
	local cap = settings.MaxConcurrent
	if cap then
		local active = activeSoundCounts[name] or 0
		if active >= cap then
			return nil
		end
		activeSoundCounts[name] = active + 1
	end
	local sound = Instance.new("Sound")
	sound.SoundId = settings.Id
	sound.Volume = settings.Volume or 0.5
	sound.Looped = settings.Looped or false
	sound.Parent = parent or SoundService
	sound:Play()
	if not settings.Looped then
		sound.Ended:Connect(function()
			if cap then
				activeSoundCounts[name] = math.max((activeSoundCounts[name] or 1) - 1, 0)
			end
			sound:Destroy()
		end)
	end
	return sound
end

playSound("Ambient", SoundService)
playSound("Music", SoundService)

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Position = UDim2.fromOffset(20, 20)
cashLabel.Size = UDim2.fromOffset(230, 54)
cashLabel.BackgroundColor3 = Theme.Panel
cashLabel.BackgroundTransparency = 0.05
cashLabel.TextColor3 = Theme.Accent
cashLabel.Font = Theme.HeaderFont
cashLabel.TextScaled = true
cashLabel.Parent = gui
applyPanelStyle(cashLabel)
local cashPadding = Instance.new("UIPadding")
cashPadding.PaddingLeft = UDim.new(0, 14)
cashPadding.PaddingRight = UDim.new(0, 14)
cashPadding.Parent = cashLabel

local feedbackLabel = Instance.new("TextLabel")
feedbackLabel.Name = "FeedbackLabel"
feedbackLabel.AnchorPoint = Vector2.new(0.5, 0)
feedbackLabel.Position = UDim2.fromScale(0.5, 0.08)
feedbackLabel.Size = UDim2.fromOffset(380, 0)
feedbackLabel.AutomaticSize = Enum.AutomaticSize.Y
feedbackLabel.BackgroundColor3 = Theme.Panel
feedbackLabel.BackgroundTransparency = 0.05
feedbackLabel.TextColor3 = Theme.Text
feedbackLabel.Font = Theme.BodyFont
feedbackLabel.TextSize = 20
feedbackLabel.TextWrapped = true
feedbackLabel.Visible = false
feedbackLabel.Parent = gui
applyPanelStyle(feedbackLabel)
local feedbackPadding = Instance.new("UIPadding")
feedbackPadding.PaddingTop = UDim.new(0, 8)
feedbackPadding.PaddingBottom = UDim.new(0, 8)
feedbackPadding.PaddingLeft = UDim.new(0, 16)
feedbackPadding.PaddingRight = UDim.new(0, 16)
feedbackPadding.Parent = feedbackLabel

local promptGui = Instance.new("BillboardGui")
promptGui.Name = "PromptGui"
promptGui.Size = UDim2.fromOffset(260, 86)
promptGui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
promptGui.AlwaysOnTop = true
promptGui.Enabled = false
promptGui.Parent = gui

local promptFrame = Instance.new("Frame")
promptFrame.Size = UDim2.fromScale(1, 1)
promptFrame.BackgroundColor3 = Theme.Panel
promptFrame.BackgroundTransparency = 0.05
promptFrame.Parent = promptGui
applyPanelStyle(promptFrame)

local promptPadding = Instance.new("UIPadding")
promptPadding.PaddingTop = UDim.new(0, 10)
promptPadding.PaddingBottom = UDim.new(0, 10)
promptPadding.PaddingLeft = UDim.new(0, 14)
promptPadding.PaddingRight = UDim.new(0, 14)
promptPadding.Parent = promptFrame

local promptObjectText = Instance.new("TextLabel")
promptObjectText.Position = UDim2.fromOffset(0, 0)
promptObjectText.Size = UDim2.new(1, 0, 0, 20)
promptObjectText.BackgroundTransparency = 1
promptObjectText.Font = Theme.BodyFont
promptObjectText.TextColor3 = Color3.fromRGB(200, 205, 195)
promptObjectText.TextScaled = true
promptObjectText.TextXAlignment = Enum.TextXAlignment.Left
promptObjectText.Parent = promptFrame

local promptActionText = Instance.new("TextLabel")
promptActionText.Position = UDim2.fromOffset(0, 22)
promptActionText.Size = UDim2.new(1, 0, 0, 28)
promptActionText.BackgroundTransparency = 1
promptActionText.Font = Theme.HeaderFont
promptActionText.TextColor3 = Theme.Text
promptActionText.TextScaled = true
promptActionText.TextXAlignment = Enum.TextXAlignment.Left
promptActionText.Parent = promptFrame

local promptBarTrack = Instance.new("Frame")
promptBarTrack.Position = UDim2.new(0, 0, 1, -8)
promptBarTrack.Size = UDim2.new(1, 0, 0, 6)
promptBarTrack.BackgroundColor3 = Color3.fromRGB(50, 58, 55)
promptBarTrack.BorderSizePixel = 0
promptBarTrack.Parent = promptFrame
local barTrackCorner = Instance.new("UICorner")
barTrackCorner.CornerRadius = UDim.new(1, 0)
barTrackCorner.Parent = promptBarTrack

local promptBarFill = Instance.new("Frame")
promptBarFill.Size = UDim2.new(0, 0, 1, 0)
promptBarFill.BackgroundColor3 = Theme.Accent
promptBarFill.BorderSizePixel = 0
promptBarFill.Parent = promptBarTrack
local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(1, 0)
barFillCorner.Parent = promptBarFill

local activePrompt = nil
local holdConnection = nil

local function stopHoldAnimation()
	if holdConnection then
		holdConnection:Disconnect()
		holdConnection = nil
	end
	promptBarFill.Size = UDim2.new(0, 0, 1, 0)
end

ProximityPromptService.PromptShown:Connect(function(prompt)
	activePrompt = prompt
	promptObjectText.Text = prompt.ObjectText
	promptActionText.Text = prompt.ActionText
	promptGui.Adornee = prompt.Parent
	promptGui.Enabled = true
	stopHoldAnimation()
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	if activePrompt == prompt then
		promptGui.Enabled = false
		promptGui.Adornee = nil
		activePrompt = nil
		stopHoldAnimation()
	end
end)

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	if prompt ~= activePrompt then
		return
	end
	local duration = prompt.HoldDuration
	local startedAt = os.clock()
	holdConnection = RunService.RenderStepped:Connect(function()
		local alpha = if duration > 0 then math.min((os.clock() - startedAt) / duration, 1) else 1
		promptBarFill.Size = UDim2.new(alpha, 0, 1, 0)
	end)
end)

ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
	if prompt == activePrompt then
		stopHoldAnimation()
	end
end)

local lastCash = nil
local function updateCash()
	local cash = player:GetAttribute("Cash")
	cashLabel.Text = `Cash: ${if typeof(cash) == "number" then cash else 0}`
	if typeof(cash) == "number" then
		if lastCash ~= nil and cash ~= lastCash then
			playSound("CashChime")
		end
		lastCash = cash
	end
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
	local impactPart = customer:FindFirstChild("HumanoidRootPart") or customer:FindFirstChildWhichIsA("BasePart")
	playSound(if isPutter then "PuttTap" else "SwingWhoosh", impactPart)
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
dashboard.Size = UDim2.fromOffset(330, 380)
dashboard.BackgroundColor3 = Theme.Panel
dashboard.BackgroundTransparency = 0.05
dashboard.Visible = false
dashboard.Parent = gui
applyPanelStyle(dashboard, Theme.Accent)

local dashboardPadding = Instance.new("UIPadding")
dashboardPadding.PaddingTop = UDim.new(0, 16)
dashboardPadding.PaddingBottom = UDim.new(0, 16)
dashboardPadding.PaddingLeft = UDim.new(0, 16)
dashboardPadding.PaddingRight = UDim.new(0, 16)
dashboardPadding.Parent = dashboard

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = dashboard

local function makeDashboardText(text, height)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, height)
	label.BackgroundTransparency = 1
	label.TextColor3 = Theme.Text
	label.Font = Theme.BodyFont
	label.TextScaled = true
	label.Text = text
	label.Parent = dashboard
	return label
end

local header = makeDashboardText("GOLF BUSINESS", 40)
header.Font = Theme.HeaderFont
header.TextColor3 = Theme.Accent
local statsLabel = makeDashboardText("", 110)
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
local pricingHeader = makeDashboardText("Pricing Strategy", 26)
pricingHeader.TextColor3 = Color3.fromRGB(200, 205, 195)

local pricingButtons = {}
for _, strategyName in { "Value", "Standard", "Premium" } do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 42)
	button.BackgroundColor3 = Theme.Button
	button.TextColor3 = Theme.Text
	button.Font = Theme.HeaderFont
	button.TextScaled = true
	button.AutoButtonColor = false
	button.Text = strategyName
	button.Parent = dashboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.CornerRadius
	corner.Parent = button
	button.Activated:Connect(function()
		playSound("UIClick")
		managementEvent:FireServer("SetPricing", strategyName)
	end)
	pricingButtons[strategyName] = button
end

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(1, 0, 0, 36)
closeButton.BackgroundColor3 = Theme.ButtonClose
closeButton.TextColor3 = Theme.Text
closeButton.Font = Theme.BodyFont
closeButton.TextScaled = true
closeButton.AutoButtonColor = false
closeButton.Text = "Close"
closeButton.Parent = dashboard
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = Theme.CornerRadius
closeCorner.Parent = closeButton
closeButton.Activated:Connect(function()
	playSound("UIClick")
	dashboard.Visible = false
end)

local function updateDashboard()
	local strategy = player:GetAttribute("PricingStrategy") or "Standard"
	statsLabel.Text = `Strategy: {strategy}\nCustomers: {player:GetAttribute("CustomersServed") or 0}\nLifetime Revenue: ${player:GetAttribute("LifetimeRevenue") or 0}\nQueue: {player:GetAttribute("QueueLength") or 0} | Bays Busy: {player:GetAttribute("BaysOccupied") or 0}`
	for strategyName, button in pricingButtons do
		local active = strategyName == strategy
		button.BackgroundColor3 = active and Theme.Accent or Theme.Button
		button.TextColor3 = active and Theme.TextDark or Theme.Text
	end
end
for _, attribute in { "PricingStrategy", "CustomersServed", "LifetimeRevenue", "QueueLength", "BaysOccupied" } do
	player:GetAttributeChangedSignal(attribute):Connect(updateDashboard)
end
managementEvent.OnClientEvent:Connect(function(action)
	if action == "Open" then
		playSound("UIClick")
		updateDashboard()
		dashboard.Visible = true
	end
end)
updateDashboard()
