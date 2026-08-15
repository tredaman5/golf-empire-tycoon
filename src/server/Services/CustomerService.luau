local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local CustomerService = {}
local playerDataService
local cashService
local plotService
local feedbackEvent
local states = {}
local nextCustomerId = 0

local CUSTOMER_COLORS = {
	Color3.fromRGB(52, 120, 185),
	Color3.fromRGB(190, 80, 70),
	Color3.fromRGB(235, 160, 55),
	Color3.fromRGB(110, 80, 155),
}

local function makePart(parent, name, size, offset, color, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.Size = size
	part.CFrame = CFrame.new(offset)
	part.Color = color
	part.Transparency = transparency or 0
	part.Parent = parent
	return part
end

local function createCustomer(parent)
	nextCustomerId += 1
	local model = Instance.new("Model")
	model.Name = `Customer{nextCustomerId}`

	local shirtColor = CUSTOMER_COLORS[(nextCustomerId - 1) % #CUSTOMER_COLORS + 1]
	local root = makePart(model, "Root", Vector3.new(1, 1, 1), Vector3.new(0, 3, 0), Color3.new(0, 0, 0), 1)
	makePart(model, "Torso", Vector3.new(2, 2.5, 1), Vector3.new(0, 3.5, 0), shirtColor)
	local head = makePart(model, "Head", Vector3.new(1.5, 1.5, 1.5), Vector3.new(0, 5.5, 0), Color3.fromRGB(224, 184, 145))
	head.Shape = Enum.PartType.Ball
	makePart(model, "LeftLeg", Vector3.new(0.8, 2, 0.8), Vector3.new(-0.55, 1.25, 0), Color3.fromRGB(45, 50, 60))
	makePart(model, "RightLeg", Vector3.new(0.8, 2, 0.8), Vector3.new(0.55, 1.25, 0), Color3.fromRGB(45, 50, 60))

	model.PrimaryPart = root
	model.Parent = parent
	return model
end

local function isActive(state)
	return states[state.Player] == state and state.Player.Parent ~= nil
end

local function waitWhileActive(state, duration)
	local deadline = os.clock() + duration
	while isActive(state) and os.clock() < deadline do
		task.wait(math.max(0, math.min(0.25, deadline - os.clock())))
	end
	return isActive(state)
end

local function moveCustomer(state, customer, destination)
	if not customer.Parent then
		return false
	end
	local startPosition = customer:GetPivot().Position
	local distance = (destination - startPosition).Magnitude
	if distance < 0.1 then
		customer:PivotTo(CFrame.new(destination))
		return true
	end

	local duration = distance / Config.Customers.WalkSpeed
	local startedAt = os.clock()
	while isActive(state) and customer.Parent do
		local elapsed = os.clock() - startedAt
		local alpha = math.min(elapsed / duration, 1)
		local position = startPosition:Lerp(destination, alpha)
		local direction = destination - startPosition
		local facing = if direction.Magnitude > 0 then direction.Unit else Vector3.zAxis
		local bob = math.abs(math.sin(elapsed * 9)) * 0.15
		customer:PivotTo(CFrame.lookAt(position + Vector3.new(0, bob, 0), position + facing + Vector3.new(0, bob, 0)))
		if alpha >= 1 then
			return true
		end
		RunService.Heartbeat:Wait()
	end
	return false
end

local function getQueuePosition(state, queueIndex)
	return state.Plot.Origin + Vector3.new(0, 3, 1 - (queueIndex - 1) * 7)
end

local function dequeueCustomer(state, customer)
	local index = table.find(state.Queue, customer)
	if index then
		table.remove(state.Queue, index)
	end
end

local function findAvailableBay(state)
	local data = playerDataService:Get(state.Player)
	local bayCount = if data then data.BayCount else 0
	for bayIndex = 1, bayCount do
		if not state.BayBusy[bayIndex] then
			return bayIndex
		end
	end
	return nil
end

local function getBayPosition(state, bayIndex)
	local data = playerDataService:Get(state.Player)
	local bayCount = if data then data.BayCount else 1
	local xOffset = if bayCount == 1 then 0 else (if bayIndex == 1 then -8 else 8)
	return state.Plot.Origin + Vector3.new(xOffset, 3, 8)
end

local function runCustomer(state, customer)
	while isActive(state) and customer.Parent do
		local queueIndex = table.find(state.Queue, customer)
		if not queueIndex then
			return
		end
		if not moveCustomer(state, customer, getQueuePosition(state, queueIndex)) then
			break
		end
		local bayIndex = if queueIndex == 1 then findAvailableBay(state) else nil
		if bayIndex then
			state.BayBusy[bayIndex] = true
			dequeueCustomer(state, customer)
			local servicePosition = getBayPosition(state, bayIndex)
			local reachedBay = moveCustomer(state, customer, servicePosition)
			local status
			if reachedBay then
				status = Instance.new("BillboardGui")
				status.Name = "CustomerStatus"
				status.Size = UDim2.fromOffset(140, 32)
				status.StudsOffset = Vector3.new(0, 4, 0)
				status.AlwaysOnTop = true
				status.Parent = customer.PrimaryPart
				local statusLabel = Instance.new("TextLabel")
				statusLabel.Size = UDim2.fromScale(1, 1)
				statusLabel.BackgroundColor3 = Color3.fromRGB(25, 55, 30)
				statusLabel.BackgroundTransparency = 0.15
				statusLabel.TextColor3 = Color3.new(1, 1, 1)
				statusLabel.Font = Enum.Font.GothamSemibold
				statusLabel.TextScaled = true
				statusLabel.Text = "Practicing..."
				statusLabel.Parent = status
			end
			if reachedBay and waitWhileActive(state, Config.Customers.ServiceDuration) then
				local data = playerDataService:Get(state.Player)
				local strategy = data and Config.DrivingRange.PricingStrategies[data.PricingStrategy]
				if data and data.OwnedBuildings[state.BuildingId] and strategy then
					if cashService:AddCash(state.Player, strategy.CustomerPayment) then
						feedbackEvent:FireClient(state.Player, `Customer paid ${strategy.CustomerPayment}.`)
					end
				end
			end
			if status then
				status:Destroy()
			end
			state.BayBusy[bayIndex] = false
			if isActive(state) and customer.Parent then
				moveCustomer(state, customer, state.Plot.Origin + Vector3.new(28, 3, -25))
			end
			if customer.Parent then
				customer:Destroy()
			end
			return
		end
		task.wait(0.25)
	end
	dequeueCustomer(state, customer)
	if customer.Parent then
		customer:Destroy()
	end
end

function CustomerService:Init(dataService, cash, plots, remote)
	playerDataService = dataService
	cashService = cash
	plotService = plots
	feedbackEvent = remote
end

function CustomerService:StartForPlayer(player: Player, buildingId: string)
	self:CleanupPlayer(player)
	local plot = plotService:GetPlayerPlot(player)
	if not plot or not Config.Buildings[buildingId] then
		return false
	end

	local folder = Instance.new("Folder")
	folder.Name = "Customers"
	folder.Parent = plot.Model
	local state = {
		Player = player,
		Plot = plot,
		BuildingId = buildingId,
		Folder = folder,
		Queue = {},
		BayBusy = {},
	}
	states[player] = state

	task.spawn(function()
		while isActive(state) do
			if #state.Queue < Config.Customers.MaxQueueSize then
				local customer = createCustomer(folder)
				customer:PivotTo(CFrame.new(plot.Origin + Vector3.new(-28, 3, -25)))
				table.insert(state.Queue, customer)
				task.spawn(runCustomer, state, customer)
			end
			local data = playerDataService:Get(player)
			local strategy = data and Config.DrivingRange.PricingStrategies[data.PricingStrategy]
			local spawnInterval = if strategy then strategy.SpawnInterval else Config.Customers.SpawnInterval
			if not waitWhileActive(state, spawnInterval) then
				break
			end
		end
	end)
	return true
end

function CustomerService:CleanupPlayer(player: Player)
	local state = states[player]
	if not state then
		return
	end
	states[player] = nil
	if state.Folder.Parent then
		state.Folder:Destroy()
	end
end

return CustomerService
