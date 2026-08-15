local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local BusinessService = {}
local playerDataService
local cashService
local plotService
local customerService
local feedbackEvent
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

local function createBay(parent, origin)
	local model = Instance.new("Model")
	model.Name = "DrivingRangeBay"
	model.Parent = parent
	makePart(model, "HittingMat", Vector3.new(10, 0.5, 8), origin + Vector3.new(0, 1, 8), Color3.fromRGB(35, 105, 45))
	makePart(model, "Roof", Vector3.new(14, 1, 11), origin + Vector3.new(0, 9, 8), Color3.fromRGB(55, 60, 65))
	makePart(model, "LeftDivider", Vector3.new(1, 8, 10), origin + Vector3.new(-6.5, 5, 8), Color3.fromRGB(195, 195, 195))
	makePart(model, "RightDivider", Vector3.new(1, 8, 10), origin + Vector3.new(6.5, 5, 8), Color3.fromRGB(195, 195, 195))
end

function BusinessService:Init(dataService, cash, plots, customers, remote)
	playerDataService = dataService
	cashService = cash
	plotService = plots
	customerService = customers
	feedbackEvent = remote
end

function BusinessService:Purchase(player: Player, plotId: number, buildingId: string)
	if purchaseLocks[player] then
		return
	end
	purchaseLocks[player] = true

	local data = playerDataService:Get(player)
	local config = typeof(buildingId) == "string" and Config.Buildings[buildingId] or nil
	local message
	if not data or typeof(plotId) ~= "number" then
		message = "Invalid purchase."
	elseif not plotService:OwnsPlot(player, plotId) then
		message = "You can only buy on your own property."
	elseif not config then
		message = "Invalid building."
	elseif data.OwnedBuildings[buildingId] then
		message = "You already own this building."
	elseif not cashService:SpendCash(player, config.Price) then
		message = "Not enough cash."
	else
		data.OwnedBuildings[buildingId] = true
		local plot = plotService:GetPlayerPlot(player)
		if plot then
			local content = plot.Model:FindFirstChild("PlayerBusiness")
			if content then
				local purchasePad = content:FindFirstChild("PurchasePad")
				if purchasePad then
					purchasePad:Destroy()
				end
				createBay(content, plot.Origin)
			end
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
	if not plot or not data then
		return false
	end
	local content = Instance.new("Folder")
	content.Name = "PlayerBusiness"
	content.Parent = plot.Model
	if data.OwnedBuildings.DrivingRangeBay then
		createBay(content, plot.Origin)
		customerService:StartForPlayer(player, "DrivingRangeBay")
		return true
	end
	local pad = makePart(content, "PurchasePad", Vector3.new(14, 1, 14), plot.Origin + Vector3.new(0, 1, 8), Color3.fromRGB(255, 200, 45))
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy Driving Range Bay - $250"
	prompt.ObjectText = "Golf Property"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad
	prompt.Triggered:Connect(function(triggeringPlayer)
		self:Purchase(triggeringPlayer, plot.Id, "DrivingRangeBay")
	end)
	return true
end

function BusinessService:CleanupPlayer(player: Player)
	purchaseLocks[player] = nil
end

return BusinessService
