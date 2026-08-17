local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local BusinessService = {}
local playerDataService
local cashService
local plotService
local customerService
local feedbackEvent
local managementEvent
local purchaseLocks = {}

local function makePart(parent, name, size, position, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Parent = parent
	return part
end

local function createFacility(parent, origin, bayCount)
	local old = parent:FindFirstChild("DrivingRangeFacility")
	if old then
		old:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "DrivingRangeFacility"
	model.Parent = parent
	for bayIndex = 1, bayCount do
		local xOffset = if bayCount == 1 then 0 else (if bayIndex == 1 then -8 else 8)
		local bayOrigin = origin + Vector3.new(xOffset, 0, 0)
		local bay = Instance.new("Model")
		bay.Name = `Bay{bayIndex}`
		bay.Parent = model
		makePart(bay, "HittingMat", Vector3.new(10, 0.5, 8), bayOrigin + Vector3.new(0, 1, 8), Color3.fromRGB(35, 105, 45))
		makePart(bay, "Roof", Vector3.new(14, 1, 11), bayOrigin + Vector3.new(0, 9, 8), Color3.fromRGB(45, 55, 60))
		makePart(bay, "LeftDivider", Vector3.new(1, 8, 10), bayOrigin + Vector3.new(-6.5, 5, 8), Color3.fromRGB(210, 210, 200))
		makePart(bay, "RightDivider", Vector3.new(1, 8, 10), bayOrigin + Vector3.new(6.5, 5, 8), Color3.fromRGB(210, 210, 200))
	end
end

local function addPrompt(parent, actionText, objectText, callback)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	prompt.Triggered:Connect(callback)
	return prompt
end

function BusinessService:Init(dataService, cash, plots, customers, remote, managementRemote)
	playerDataService = dataService
	cashService = cash
	plotService = plots
	customerService = customers
	feedbackEvent = remote
	managementEvent = managementRemote
	managementEvent.OnServerEvent:Connect(function(player, action, value)
		if action ~= "SetPricing" or typeof(value) ~= "string" or not Config.DrivingRange.PricingStrategies[value] then return end
		local data = playerDataService:Get(player)
		if not data or not data.OwnedBuildings.DrivingRangeBay or not plotService:GetPlayerPlot(player) then return end
		data.PricingStrategy = value
		player:SetAttribute("PricingStrategy", value)
		feedbackEvent:FireClient(player, `{value} pricing selected.`)
	end)
end

function BusinessService:_createManagementControls(player, content, plot)
	local data = playerDataService:Get(player)
	if not data then
		return
	end
	local kiosk = makePart(content, "ManagementKiosk", Vector3.new(6, 5, 4), plot.Origin + Vector3.new(26, 3, -18), Color3.fromRGB(25, 75, 45))
	addPrompt(kiosk, "Open Dashboard", "Golf Business Management", function(triggeringPlayer)
		if triggeringPlayer ~= player or not plotService:OwnsPlot(player, plot.Id) then
			feedbackEvent:FireClient(triggeringPlayer, "You can only manage your own property.")
			return
		end
		managementEvent:FireClient(player, "Open")
	end)

	if data.BayCount < Config.DrivingRange.MaxBayCount then
		local upgradePad = makePart(content, "SecondBayUpgradePad", Vector3.new(12, 1, 12), plot.Origin + Vector3.new(-26, 1, -18), Color3.fromRGB(70, 160, 220))
		addPrompt(upgradePad, `Build Second Bay - ${Config.DrivingRange.SecondBayPrice}`, "Driving Range Expansion", function(triggeringPlayer)
			self:PurchaseSecondBay(triggeringPlayer, plot.Id)
		end)
	end
	self:RefreshProgression(player)
end

local function createPuttingGreen(content, origin)
	if content:FindFirstChild("PuttingGreen") then return end
	local model = Instance.new("Model")
	model.Name = "PuttingGreen"
	model.Parent = content
	local green = makePart(model, "Green", Vector3.new(28, 0.6, 22), origin + Vector3.new(26, 1, 25), Color3.fromRGB(48, 145, 62))
	green.Shape = Enum.PartType.Block
	makePart(model, "Cup", Vector3.new(1.2, 0.2, 1.2), origin + Vector3.new(29, 1.4, 27), Color3.fromRGB(20, 20, 20))
	makePart(model, "FlagPole", Vector3.new(0.25, 8, 0.25), origin + Vector3.new(29, 5, 27), Color3.fromRGB(235, 235, 235))
	makePart(model, "Flag", Vector3.new(3, 2, 0.2), origin + Vector3.new(30.5, 8, 27), Color3.fromRGB(225, 55, 45))
end

function BusinessService:RefreshProgression(player)
	local data = playerDataService:Get(player)
	local plot = plotService:GetPlayerPlot(player)
	local content = plot and plot.Model:FindFirstChild("PlayerBusiness")
	if not data or not content or not data.OwnedBuildings.DrivingRangeBay then return end
	if data.PuttingGreenOwned then
		createPuttingGreen(content, plot.Origin)
		return
	end
	local unlocked = data.CustomersServed >= Config.PuttingGreen.UnlockCustomers and data.LifetimeRevenue >= Config.PuttingGreen.UnlockRevenue
	if unlocked and not content:FindFirstChild("PuttingGreenPurchasePad") then
		local pad = makePart(content, "PuttingGreenPurchasePad", Vector3.new(12, 1, 12), plot.Origin + Vector3.new(26, 1, 25), Color3.fromRGB(180, 120, 220))
		addPrompt(pad, `Build Putting Green - ${Config.PuttingGreen.Price}`, "Course Development", function(triggeringPlayer)
			self:PurchasePuttingGreen(triggeringPlayer, plot.Id)
		end)
		feedbackEvent:FireClient(player, "Putting Green unlocked!")
	end
end

function BusinessService:PurchasePuttingGreen(player, plotId)
	if purchaseLocks[player] then return end
	purchaseLocks[player] = true
	local data = playerDataService:Get(player)
	local unlocked = data and data.CustomersServed >= Config.PuttingGreen.UnlockCustomers and data.LifetimeRevenue >= Config.PuttingGreen.UnlockRevenue
	local message
	if not data or not plotService:OwnsPlot(player, plotId) or not unlocked then message = "Putting Green is not unlocked."
	elseif data.PuttingGreenOwned then message = "You already own the Putting Green."
	elseif not cashService:SpendCash(player, Config.PuttingGreen.Price) then message = "Not enough cash for the Putting Green."
	else
		data.PuttingGreenOwned = true
		player:SetAttribute("PuttingGreenOwned", true)
		local plot = plotService:GetPlayerPlot(player)
		local content = plot.Model:FindFirstChild("PlayerBusiness")
		local pad = content and content:FindFirstChild("PuttingGreenPurchasePad")
		if pad then pad:Destroy() end
		if content then createPuttingGreen(content, plot.Origin) end
		message = "Putting Green opened!"
	end
	feedbackEvent:FireClient(player, message)
	purchaseLocks[player] = nil
end

function BusinessService:PurchaseSecondBay(player: Player, plotId: number)
	if purchaseLocks[player] then
		return
	end
	purchaseLocks[player] = true
	local data = playerDataService:Get(player)
	local message
	if not data or not plotService:OwnsPlot(player, plotId) then
		message = "You can only expand your own property."
	elseif not data.OwnedBuildings.DrivingRangeBay or data.BayCount ~= 1 then
		message = "This expansion is not available."
	elseif not cashService:SpendCash(player, Config.DrivingRange.SecondBayPrice) then
		message = "Not enough cash for the second bay."
	else
		data.BayCount = 2
		player:SetAttribute("BayCount", 2)
		local plot = plotService:GetPlayerPlot(player)
		local content = plot and plot.Model:FindFirstChild("PlayerBusiness")
		if content then
			local pad = content:FindFirstChild("SecondBayUpgradePad")
			if pad then pad:Destroy() end
			createFacility(content, plot.Origin, data.BayCount)
		end
		message = "Second Driving Range Bay opened!"
	end
	feedbackEvent:FireClient(player, message)
	purchaseLocks[player] = nil
end

function BusinessService:Purchase(player: Player, plotId: number, buildingId: string)
	if purchaseLocks[player] then return end
	purchaseLocks[player] = true
	local data = playerDataService:Get(player)
	local config = typeof(buildingId) == "string" and Config.Buildings[buildingId] or nil
	local message
	if not data or typeof(plotId) ~= "number" then message = "Invalid purchase."
	elseif not plotService:OwnsPlot(player, plotId) then message = "You can only buy on your own property."
	elseif not config then message = "Invalid building."
	elseif data.OwnedBuildings[buildingId] then message = "You already own this building."
	elseif not cashService:SpendCash(player, config.Price) then message = "Not enough cash."
	else
		data.OwnedBuildings[buildingId] = true
		data.BayCount = 1
		local plot = plotService:GetPlayerPlot(player)
		local content = plot and plot.Model:FindFirstChild("PlayerBusiness")
		if content then
			local pad = content:FindFirstChild("PurchasePad")
			if pad then pad:Destroy() end
			createFacility(content, plot.Origin, data.BayCount)
			self:_createManagementControls(player, content, plot)
		end
		customerService:StartForPlayer(player, buildingId)
		message = `Purchased {config.DisplayName}!`
	end
	feedbackEvent:FireClient(player, message)
	purchaseLocks[player] = nil
end

function BusinessService:SetupPlot(player: Player)
	local plot = plotService:GetPlayerPlot(player)
	local data = playerDataService:Get(player)
	if not plot or not data then return false end
	local content = Instance.new("Folder")
	content.Name = "PlayerBusiness"
	content.Parent = plot.Model
	if data.OwnedBuildings.DrivingRangeBay then
		createFacility(content, plot.Origin, data.BayCount)
		self:_createManagementControls(player, content, plot)
		customerService:StartForPlayer(player, "DrivingRangeBay")
		return true
	end
	local pad = makePart(content, "PurchasePad", Vector3.new(14, 1, 14), plot.Origin + Vector3.new(0, 1, 8), Color3.fromRGB(255, 200, 45))
	addPrompt(pad, "Buy Driving Range Bay - $250", "Golf Property", function(triggeringPlayer)
		self:Purchase(triggeringPlayer, plot.Id, "DrivingRangeBay")
	end)
	return true
end

function BusinessService:CleanupPlayer(player: Player)
	purchaseLocks[player] = nil
end

return BusinessService
