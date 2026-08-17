local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local CustomerService = {}
local playerDataService
local cashService
local plotService
local feedbackEvent
local customerAnimationEvent
local states = {}
local nextCustomerId = 0
local visitCompletedCallback
local customerTracks = setmetatable({}, { __mode = "k" })

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

local function createBlockCustomer(parent)
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

local function createCustomer(parent)
	nextCustomerId += 1
	local description = Instance.new("HumanoidDescription")
	local shirtColor = CUSTOMER_COLORS[(nextCustomerId - 1) % #CUSTOMER_COLORS + 1]
	description.HeadColor = Color3.fromRGB(224, 184, 145)
	description.LeftArmColor = description.HeadColor
	description.RightArmColor = description.HeadColor
	description.TorsoColor = shirtColor
	description.LeftLegColor = Color3.fromRGB(45, 50, 60)
	description.RightLegColor = Color3.fromRGB(45, 50, 60)

	local success, model = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	end)
	if not success or not model then
		warn(`Could not create R15 golfer: {tostring(model)}`)
		return createBlockCustomer(parent)
	end
	model.Name = `Golfer{nextCustomerId}`
	model.Parent = parent
	local root = model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		model:Destroy()
		return createBlockCustomer(parent)
	end
	model.PrimaryPart = root
	root.Anchored = true
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
		end
	end
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local walkAnimation = Instance.new("Animation")
	walkAnimation.AnimationId = "rbxassetid://507777826"
	local loaded, walkTrack = pcall(function() return animator:LoadAnimation(walkAnimation) end)
	if loaded then customerTracks[model] = walkTrack end
	return model
end

local function setWalking(customer, walking)
	local track = customerTracks[customer]
	if not track then return end
	if walking and not track.IsPlaying then track:Play(0.2) end
	if not walking and track.IsPlaying then track:Stop(0.2) end
end

local function equipClub(customer, isPutter)
	local hand = customer:FindFirstChild("RightHand") or customer:FindFirstChild("Right Arm")
	if not hand or customer:FindFirstChild("GolfClub") then return end
	local club = Instance.new("Part")
	club.Name = "GolfClub"
	club.Size = Vector3.new(0.18, if isPutter then 3.8 else 4.5, 0.18)
	club.Color = Color3.fromRGB(65, 65, 70)
	club.Material = Enum.Material.Metal
	club.CanCollide = false
	club.Massless = true
	club.CFrame = hand.CFrame * CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.rad(8))
	club.Parent = customer
	local grip = Instance.new("Motor6D")
	grip.Name = "GolfClubGrip"
	grip.Part0 = hand
	grip.Part1 = club
	grip.C0 = CFrame.new(0, -0.35, 0) * CFrame.Angles(0, 0, math.rad(8))
	grip.C1 = CFrame.new(0, club.Size.Y / 2, 0)
	grip.Parent = hand
	local head = Instance.new("Part")
	head.Name = "ClubHead"
	head.Size = if isPutter then Vector3.new(0.8, 0.25, 0.3) else Vector3.new(0.75, 0.45, 0.55)
	head.Color = Color3.fromRGB(35, 35, 38)
	head.Material = Enum.Material.Metal
	head.CanCollide = false
	head.Massless = true
	head.CFrame = club.CFrame * CFrame.new(0, -club.Size.Y / 2, 0)
	head.Parent = customer
	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = club
	headWeld.Part1 = head
	headWeld.Parent = head
end

local function removeClub(customer)
	local grip = customer:FindFirstChild("GolfClubGrip", true)
	if grip then grip:Destroy() end
	local clubHead = customer:FindFirstChild("ClubHead")
	if clubHead then clubHead:Destroy() end
	local club = customer:FindFirstChild("GolfClub")
	if club then club:Destroy() end
end

local function playGolfMotion(customer, isPutter)
	customerAnimationEvent:FireAllClients(customer, if isPutter then "Putt" else "Swing")
	task.wait(if isPutter then 1.8 else 2.1)
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
	setWalking(customer, true)
	while isActive(state) and customer.Parent do
		local elapsed = os.clock() - startedAt
		local alpha = math.min(elapsed / duration, 1)
		local position = startPosition:Lerp(destination, alpha)
		local direction = destination - startPosition
		local facing = if direction.Magnitude > 0 then direction.Unit else Vector3.zAxis
		local bob = math.abs(math.sin(elapsed * 9)) * 0.15
		customer:PivotTo(CFrame.lookAt(position + Vector3.new(0, bob, 0), position + facing + Vector3.new(0, bob, 0)))
		if alpha >= 1 then
			setWalking(customer, false)
			return true
		end
		RunService.Heartbeat:Wait()
	end
	setWalking(customer, false)
	return false
end

local function playBallEffect(state, servicePosition, isPutter)
	local ball = Instance.new("Part")
	ball.Name = "PracticeBall"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(0.55, 0.55, 0.55)
	ball.Color = Color3.new(1, 1, 1)
	ball.Material = Enum.Material.SmoothPlastic
	ball.Anchored = true
	ball.CanCollide = false
	ball.Position = servicePosition + Vector3.new(0, -2.4, 2)
	ball.Parent = state.Folder
	local target = if isPutter then ball.Position + Vector3.new(3, 0, 5) else ball.Position + Vector3.new(0, 12, 42)
	local tween = TweenService:Create(ball, TweenInfo.new(if isPutter then 1.5 else 1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = target })
	tween:Play()
	tween.Completed:Connect(function() if ball.Parent then ball:Destroy() end end)
end

local function getFacilityQueue(state, facilityType)
	return if facilityType == "PuttingGreen" then state.PuttingQueue else state.RangeQueue
end

local function getQueuePosition(state, queueIndex, facilityType)
	if facilityType == "PuttingGreen" then
		return state.Plot.Origin + Vector3.new(42 - (queueIndex - 1) * 8, 3, -18)
	end
	return state.Plot.Origin + Vector3.new(0, 3, -4 - (queueIndex - 1) * 5.2)
end

local function dequeueCustomer(state, customer, facilityType)
	local queue = getFacilityQueue(state, facilityType)
	local index = table.find(queue, customer)
	if index then
		table.remove(queue, index)
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
	local xOffset = (bayIndex - (bayCount + 1) / 2) * 16
	return state.Plot.Origin + Vector3.new(xOffset, 3, 8)
end

local function getBayEntryPosition(state, bayIndex)
	local servicePosition = getBayPosition(state, bayIndex)
	return Vector3.new(servicePosition.X, 3, state.Plot.Origin.Z)
end

local function runCustomer(state, customer)
	while isActive(state) and customer.Parent do
		local facilityType = customer:GetAttribute("FacilityType")
		local queue = getFacilityQueue(state, facilityType)
		local queueIndex = table.find(queue, customer)
		if not queueIndex then
			return
		end
		if not moveCustomer(state, customer, getQueuePosition(state, queueIndex, facilityType)) then
			break
		end
		local serviceId
		if queueIndex == 1 then
			if facilityType == "PuttingGreen" then
				serviceId = if not state.GreenBusy then "Green" else nil
			else
				serviceId = findAvailableBay(state)
			end
		end
		if serviceId then
			if serviceId == "Green" then state.GreenBusy = true else state.BayBusy[serviceId] = true end
			dequeueCustomer(state, customer, facilityType)
			local servicePosition = if serviceId == "Green" then state.Plot.Origin + Vector3.new(50, 4, 25) else getBayPosition(state, serviceId)
			local reachedBay
			if serviceId == "Green" then
				local puttingJunction = state.Plot.Origin + Vector3.new(50, 3, -18)
				local exteriorWaypoint = state.Plot.Origin + Vector3.new(50, 3, -3)
				reachedBay = moveCustomer(state, customer, puttingJunction)
					and moveCustomer(state, customer, exteriorWaypoint)
					and moveCustomer(state, customer, servicePosition)
			else
				local centerGate = state.Plot.Origin + Vector3.new(0, 3, 0)
				local bayEntry = getBayEntryPosition(state, serviceId)
				reachedBay = moveCustomer(state, customer, centerGate)
					and moveCustomer(state, customer, bayEntry)
					and moveCustomer(state, customer, servicePosition)
			end
			local status
			if reachedBay then
				local isPutter = serviceId == "Green"
				equipClub(customer, isPutter)
				status = Instance.new("BillboardGui")
				status.Name = "CustomerStatus"
				status.Size = UDim2.fromOffset(110, 26)
				status.StudsOffset = Vector3.new(0, 4, 0)
				status.AlwaysOnTop = true
				status.MaxDistance = 55
				status.Parent = customer.PrimaryPart
				local statusLabel = Instance.new("TextLabel")
				statusLabel.Size = UDim2.fromScale(1, 1)
				statusLabel.BackgroundColor3 = Color3.fromRGB(25, 55, 30)
				statusLabel.BackgroundTransparency = 0.15
				statusLabel.TextColor3 = Color3.new(1, 1, 1)
				statusLabel.Font = Enum.Font.GothamSemibold
				statusLabel.TextScaled = true
				statusLabel.Text = if serviceId == "Green" then "Putting..." else "Practicing..."
				statusLabel.Parent = status
				task.spawn(function()
					local repetitions = 2
					for _ = 1, repetitions do
						if not isActive(state) or not customer.Parent then break end
						playGolfMotion(customer, isPutter)
						if isActive(state) and customer.Parent then playBallEffect(state, servicePosition, isPutter) end
						task.wait(0.5)
					end
				end)
			end
			local serviceDuration = if serviceId == "Green" then Config.PuttingGreen.ServiceDuration else Config.Customers.ServiceDuration
			if reachedBay and waitWhileActive(state, serviceDuration) then
				local data = playerDataService:Get(state.Player)
				local payment = customer:GetAttribute("VisitPayment")
				if data and data.OwnedBuildings[state.BuildingId] and typeof(payment) == "number" then
					if cashService:AddCash(state.Player, payment) then
						data.CustomersServed += 1
						data.LifetimeRevenue += payment
						state.Player:SetAttribute("CustomersServed", data.CustomersServed)
						state.Player:SetAttribute("LifetimeRevenue", data.LifetimeRevenue)
						feedbackEvent:FireClient(state.Player, `Customer paid ${payment}.`)
						if visitCompletedCallback then visitCompletedCallback(state.Player) end
					end
				end
			end
			if status then
				status:Destroy()
			end
			customerAnimationEvent:FireAllClients(customer, "Reset")
			removeClub(customer)
			if serviceId == "Green" then state.GreenBusy = false else state.BayBusy[serviceId] = false end
			if isActive(state) and customer.Parent then
				if serviceId == "Green" then
					moveCustomer(state, customer, state.Plot.Origin + Vector3.new(50, 3, -3))
					moveCustomer(state, customer, state.Plot.Origin + Vector3.new(60, 3, -3))
					moveCustomer(state, customer, state.Plot.Origin + Vector3.new(60, 3, -48))
				else
					moveCustomer(state, customer, getBayEntryPosition(state, serviceId))
					moveCustomer(state, customer, state.Plot.Origin + Vector3.new(-18, 3, 0))
					moveCustomer(state, customer, state.Plot.Origin + Vector3.new(-18, 3, -48))
				end
			end
			if customer.Parent then
				customer:Destroy()
			end
			return
		end
		task.wait(0.25)
	end
	dequeueCustomer(state, customer, customer:GetAttribute("FacilityType"))
	if customer.Parent then
		customer:Destroy()
	end
end

function CustomerService:Init(dataService, cash, plots, remote, animationRemote)
	playerDataService = dataService
	cashService = cash
	plotService = plots
	feedbackEvent = remote
	customerAnimationEvent = animationRemote
end

function CustomerService:SetVisitCompletedCallback(callback)
	visitCompletedCallback = callback
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
		RangeQueue = {},
		PuttingQueue = {},
		BayBusy = {},
		GreenBusy = false,
		SpawnedCount = 0,
	}
	states[player] = state

	task.spawn(function()
		while isActive(state) do
			state.SpawnedCount += 1
			local data = playerDataService:Get(player)
			local useGreen = data and data.PuttingGreenOwned and state.SpawnedCount % Config.PuttingGreen.VisitEvery == 0
			local queue = if useGreen then state.PuttingQueue else state.RangeQueue
			local queueLimit = if useGreen then Config.Customers.MaxPuttingQueueSize else Config.Customers.MaxQueueSize
			if #queue < queueLimit then
				local customer = createCustomer(folder)
				local strategy = data and Config.DrivingRange.PricingStrategies[data.PricingStrategy]
				customer:SetAttribute("FacilityType", if useGreen then "PuttingGreen" else "DrivingRange")
				local rangePayment = if strategy then strategy.CustomerPayment else Config.Buildings.DrivingRangeBay.CustomerPayment
				customer:SetAttribute("VisitPayment", if useGreen then Config.PuttingGreen.CustomerPayment else rangePayment)
				customer:PivotTo(CFrame.new(plot.Origin + Vector3.new(0, 3, -48)))
				table.insert(queue, customer)
				task.spawn(runCustomer, state, customer)
			end
			data = playerDataService:Get(player)
			local strategy = data and Config.DrivingRange.PricingStrategies[data.PricingStrategy]
			local baseSpawnInterval = if strategy then strategy.SpawnInterval else Config.Customers.SpawnInterval
			local bayCount = if data then math.max(1, data.BayCount) else 1
			local capacityMultiplier = 1 + (bayCount - 1) * Config.DrivingRange.ArrivalCapacityBoostPerBay
			local spawnInterval = baseSpawnInterval / capacityMultiplier
			player:SetAttribute("QueueLength", #state.RangeQueue + #state.PuttingQueue)
			local occupied = 0
			for _, busy in state.BayBusy do if busy then occupied += 1 end end
			player:SetAttribute("BaysOccupied", occupied)
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
